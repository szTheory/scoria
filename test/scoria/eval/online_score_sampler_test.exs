defmodule Scoria.Eval.OnlineScoreSamplerTest do
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Scoria.Repo

  alias Scoria.Eval
  alias Scoria.Eval.{CampaignWorker, EvalRun, OnlineScoreCandidate}
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows.{Run, Step}

  defmodule CoordinatorStub do
    def enqueue_sampled_trace(payload, opts) do
      send(Keyword.fetch!(opts, :notify), {:coordinator_called, self(), payload})
      {:ok, payload}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    previous = Application.get_env(:scoria, :online_scoring_module)
    Application.put_env(:scoria, :online_scoring_module, CoordinatorStub)

    on_exit(fn ->
      if previous do
        Application.put_env(:scoria, :online_scoring_module, previous)
      else
        Application.delete_env(:scoria, :online_scoring_module)
      end
    end)

    :ok
  end

  describe "sample_trace_for_online_scoring/2" do
    test "schedules only eligible persisted production traces off-path" do
      %{trace: prod_trace, run: prod_run, step: prod_step} = persisted_trace_fixture(%{"env" => "prod"})
      %{trace: dev_trace, run: dev_run, step: dev_step} = persisted_trace_fixture(%{"env" => "dev"})

      assert {:ok, scheduled} =
               Eval.sample_trace_for_online_scoring(
                 sampler_attrs(prod_trace, prod_run, prod_step),
                 notify: self(),
                 sandbox_repo: Repo
               )

      assert scheduled.status == :scheduled
      assert scheduled.trace_id == prod_trace.id

      assert {:ok, ignored} =
               Eval.sample_trace_for_online_scoring(
                 sampler_attrs(dev_trace, dev_run, dev_step),
                 notify: self(),
                 sandbox_repo: Repo
               )

      assert ignored.status == :ignored
      assert ignored.reason == :ineligible_trace

      assert_receive {:coordinator_called, pid, payload}
      assert is_pid(pid)
      refute pid == self()
      assert payload.trace_id == prod_trace.id
      assert payload.workflow_run_id == prod_run.id
      assert payload.workflow_step_id == prod_step.id
      assert payload.tenant_id == "tenant-prod"
      dev_trace_id = dev_trace.id
      refute_receive {:coordinator_called, ^pid, %{trace_id: ^dev_trace_id}}
    end

    test "normalizes sampler provenance before handing off to the coordinator" do
      %{trace: trace, run: run, step: step} = persisted_trace_fixture(%{"env" => "prod"})

      assert {:ok, _scheduled} =
               Eval.sample_trace_for_online_scoring(
                 sampler_attrs(trace, run, step, %{
                   sample_reason: "policy_trigger",
                   sample_window: "2026-05-23T20",
                   sampler_version: "online-score-sampler@v1"
                 }),
                 notify: self(),
                 sandbox_repo: Repo
               )

      assert_receive {:coordinator_called, _pid, payload}

      assert payload.sampling_metadata == %{
               "sample_reason" => "policy_trigger",
               "sample_window" => "2026-05-23T20",
               "sampler_version" => "online-score-sampler@v1",
               "dedupe_key" => "tenant-prod:#{trace.id}:2026-05-23T20"
             }

      assert payload.dedupe_key == "tenant-prod:#{trace.id}:2026-05-23T20"
      assert payload.scorer["eval_spec_id"]
      assert payload.scorer["provider"] == "openai"
      assert payload.scorer["model"] == "gpt-4o-mini"
      assert payload.evidence_refs["trace_id"] == trace.id
      assert payload.evidence_refs["workflow_run_id"] == run.id
    end

    test "persists one candidate and enqueues scoring work only once per active dedupe key" do
      Application.put_env(:scoria, :online_scoring_module, Scoria.Eval.OnlineScoring)
      {:ok, dataset} = create_sealed_dataset()
      {:ok, eval_spec} = create_eval_spec(dataset)
      %{trace: trace, run: run, step: step} = persisted_trace_fixture(%{"env" => "prod"})

      attrs =
        sampler_attrs(trace, run, step, %{
          scorer: %{
            eval_spec_id: eval_spec.id,
            provider: "openai",
            model: "gpt-4o-mini",
            priority: 4,
            metadata: %{"lane" => "online"}
          }
        })

      assert {:ok, %{status: :scheduled}} =
               Eval.sample_trace_for_online_scoring(attrs,
                 notify: self(),
                 sandbox_repo: Repo
               )

      assert_receive {:online_scoring_result,
                      {:ok, %{candidate: candidate, campaign: campaign, eval_runs: [eval_run]}}},
                     1_000

      candidate = Repo.get!(OnlineScoreCandidate, candidate.id)
      [target] = Eval.list_campaign_targets(campaign.id)
      persisted_run = Repo.get!(EvalRun, eval_run.id)

      assert candidate.campaign_id == campaign.id
      assert candidate.eval_run_id == persisted_run.id
      assert candidate.metadata["scorer"]["eval_spec_id"] == eval_spec.id
      assert candidate.sampling_metadata["sample_reason"] == "production_sample"
      assert target.metadata["candidate_id"] == candidate.id
      assert target.metadata["dedupe_key"] == "tenant-prod:#{trace.id}:2026-05-23T19"
      assert persisted_run.campaign_target_id == target.id

      assert_enqueued(
        worker: CampaignWorker,
        queue: :evals,
        priority: 4,
        args: %{
          "campaign_id" => campaign.id,
          "campaign_target_id" => target.id,
          "eval_run_id" => persisted_run.id,
          "tenant_id" => "tenant-prod",
          "eval_spec_id" => eval_spec.id,
          "provider" => "openai",
          "model" => "gpt-4o-mini"
        }
      )

      assert {:ok, %{status: :scheduled}} =
               Eval.sample_trace_for_online_scoring(attrs,
                 notify: self(),
                 sandbox_repo: Repo
               )

      assert_receive {:online_scoring_result,
                      {:ok, %{candidate: reused_candidate, reused?: true, enqueued?: false}}},
                     1_000

      assert reused_candidate.id == candidate.id
      assert Repo.aggregate(OnlineScoreCandidate, :count) == 1
      assert Repo.aggregate(Scoria.Eval.EvalCampaign, :count) == 1
      assert Repo.aggregate(EvalRun, :count) == 1
      assert length(all_enqueued(worker: CampaignWorker)) == 1
    end
  end

  defp sampler_attrs(trace, run, step, overrides \\ %{}) do
    Map.merge(
      %{
        trace_id: trace.id,
        tenant_id: "tenant-prod",
        workflow_run_id: run.id,
        workflow_step_id: step.id,
        sample_reason: "production_sample",
        sample_window: "2026-05-23T19",
        sampler_version: "online-score-sampler@v1",
        scorer: %{
          eval_spec_id: Ecto.UUID.generate(),
          provider: "openai",
          model: "gpt-4o-mini",
          metadata: %{"lane" => "online"}
        },
        evidence_refs: %{
          "trace_id" => trace.id,
          "workflow_run_id" => run.id,
          "workflow_step_id" => step.id
        },
        promotion_snapshot: %{
          "frozen_evidence_refs" => %{"trace_id" => trace.id}
        }
      },
      overrides
    )
  end

  defp persisted_trace_fixture(trace_attributes) do
    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{session_id: "sess-#{System.unique_integer([:positive])}", attributes: trace_attributes})
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: "tenant-prod",
        session_id: trace.session_id,
        status: "running",
        execution_mode: "live"
      })
      |> Repo.insert()

    {:ok, step} =
      %Step{}
      |> Step.changeset(%{
        run_id: run.id,
        sequence: 1,
        kind: "llm_call",
        role_id: "assistant",
        status: "completed"
      })
      |> Repo.insert()

    %{trace: trace, run: run, step: step}
  end

  defp create_sealed_dataset do
    Eval.create_dataset(%{
      name: "online-scoring-dataset",
      version: "2026.05.23",
      items: [
        %{
          input: %{"question" => "What is Scoria?"},
          expected_output: %{"answer" => "An embedded Phoenix AI runtime"}
        }
      ]
    })
    |> then(fn {:ok, dataset} -> Eval.seal_dataset(dataset) end)
  end

  defp create_eval_spec(dataset) do
    Eval.create_eval_spec(%{
      name: "online-scoring-spec",
      description: "Online scoring contract",
      dataset_id: dataset.id,
      dataset_version: dataset.version,
      eval_mode: :live_judge,
      subject: %{
        subject_kind: :prompt_template,
        prompt_template_id: Ecto.UUID.generate(),
        prompt_entity_id: Ecto.UUID.generate(),
        prompt_version: 1
      },
      scorers: [
        %{
          metric_key: "correctness",
          scorer_kind: :llm_judge,
          judge_prompt_template_id: Ecto.UUID.generate(),
          judge_prompt_version: 1,
          judge_provider: "openai",
          judge_model: "gpt-4o-mini",
          weight: 1.0
        }
      ],
      threshold_policy: %{
        pass_rate_gte: 0.8,
        mean_score_gte: 0.8,
        max_latency_ms: 500
      }
    })
  end
end
