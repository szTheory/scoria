defmodule Scoria.Eval.CampaignWorkerTest do
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Scoria.Repo

  import Ecto.Query

  alias Oban.Job
  alias Scoria.Eval

  alias Scoria.Eval.{
    CampaignWorker,
    EvalCampaign,
    EvalCampaignTarget,
    EvalRun,
    OnlineScoreCandidate,
    Score
  }

  alias Scoria.Repo.Trace
  alias Scoria.Repo
  alias Scoria.Workflows.{Run, Step}

  defmodule OrchestratorStub do
    def generate_object(model_spec, prompt, schema, opts) do
      send(self(), {:orchestrator_called, model_spec, prompt, schema, opts})

      case Process.get({__MODULE__, :mode}, :success) do
        :success ->
          {:ok,
           %{
             object: %{
               "score" => 1.0,
               "status" => "passed",
               "explanation" => "Stubbed judge verdict",
               "evidence_refs" => %{"judge" => "stub"}
             }
           }}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    previous_orchestrator = Application.get_env(:scoria, :orchestrator_module)
    Application.put_env(:scoria, :orchestrator_module, OrchestratorStub)
    Process.delete({OrchestratorStub, :mode})

    on_exit(fn ->
      if previous_orchestrator do
        Application.put_env(:scoria, :orchestrator_module, previous_orchestrator)
      else
        Application.delete_env(:scoria, :orchestrator_module)
      end

      Process.delete({OrchestratorStub, :mode})
    end)

    :ok
  end

  describe "new_job/2" do
    test "normalizes identity args and always enqueues on :evals" do
      job =
        CampaignWorker.new_job(
          %{
            "campaign_id" => "campaign-1",
            :campaign_target_id => "target-1",
            "eval_run_id" => "run-1",
            :tenant_id => "tenant-1",
            "eval_spec_id" => "spec-1",
            :provider => "openai",
            "model" => "gpt-4o-mini",
            :metadata => %{lane: "nightly"}
          },
          queue: :default,
          priority: 4
        )

      assert job.changes.queue == "evals"
      assert job.changes.priority == 4

      assert job.changes.args == %{
               "campaign_id" => "campaign-1",
               "campaign_target_id" => "target-1",
               "eval_run_id" => "run-1",
               "tenant_id" => "tenant-1",
               "eval_spec_id" => "spec-1",
               "provider" => "openai",
               "model" => "gpt-4o-mini",
               "metadata" => %{"lane" => "nightly"}
             }
    end
  end

  describe "perform/1" do
    test "executes through the orchestrator path, persists durable truth, and completes the campaign" do
      %{
        campaign: campaign,
        target: target,
        eval_run: eval_run,
        job: job,
        dataset_item: dataset_item
      } =
        seeded_campaign()

      assert :ok = CampaignWorker.perform(%Job{args: job.args})

      assert_received {:orchestrator_called, "openai:gpt-4o-mini", _prompt, _schema, _opts}

      target = Repo.get!(EvalCampaignTarget, target.id)
      eval_run = Repo.get!(EvalRun, eval_run.id)
      campaign = Repo.get!(EvalCampaign, campaign.id)

      scores = Repo.all(from(score in Score, where: score.eval_run_id == ^eval_run.id))
      assert [%Score{} = score] = scores

      assert score.dataset_item_id == dataset_item.id
      assert score.status == "passed"
      assert score.explanation == "Stubbed judge verdict"
      assert score.evidence_refs["judge"] == "stub"

      assert target.status == "completed"
      assert target.started_at
      assert target.finished_at
      assert target.last_error == %{}

      assert eval_run.status == "completed"
      assert eval_run.tenant_id == "tenant-alpha"
      assert eval_run.total_items == 1
      assert eval_run.passed_items == 1
      assert eval_run.failed_items == 0
      assert eval_run.threshold_verdict == "passed"

      assert campaign.status == "completed"
      assert campaign.total_targets == 1
      assert campaign.queued_targets == 0
      assert campaign.running_targets == 0
      assert campaign.completed_targets == 1
      assert campaign.failed_targets == 0
      assert campaign.cancelled_targets == 0
      assert campaign.started_at
      assert campaign.finished_at
      assert campaign.last_progress_at
    end

    test "keeps failures shard-local and rolls the campaign to completed_partial when peers succeed" do
      %{
        campaign: campaign,
        jobs: [job_1, job_2],
        targets: [target_1, target_2],
        eval_runs: [run_1, run_2]
      } =
        seeded_campaign(target_count: 2)

      assert :ok = CampaignWorker.perform(%Job{args: job_1.args})

      Process.put({OrchestratorStub, :mode}, {:error, :transient_provider_failure})

      assert {:error, :transient_provider_failure} =
               CampaignWorker.perform(%Job{args: job_2.args})

      campaign = Repo.get!(EvalCampaign, campaign.id)
      target_1 = Repo.get!(EvalCampaignTarget, target_1.id)
      target_2 = Repo.get!(EvalCampaignTarget, target_2.id)
      run_1 = Repo.get!(EvalRun, run_1.id)
      run_2 = Repo.get!(EvalRun, run_2.id)

      assert target_1.status == "completed"
      assert target_2.status == "failed"
      assert target_2.last_error["reason"] == "transient_provider_failure"
      assert run_1.status == "completed"
      assert run_2.status == "failed"

      assert campaign.status == "completed_partial"
      assert campaign.completed_targets == 1
      assert campaign.failed_targets == 1
      assert campaign.running_targets == 0
      assert campaign.queued_targets == 0
      assert campaign.finished_at

      assert Repo.aggregate(from(score in Score, where: score.eval_run_id == ^run_1.id), :count) ==
               1

      assert Repo.aggregate(from(score in Score, where: score.eval_run_id == ^run_2.id), :count) ==
               0
    end

    test "marks explicit fatal classes as failed_fatal" do
      %{campaign: campaign, job: job, target: target, eval_run: eval_run} = seeded_campaign()

      Process.put({OrchestratorStub, :mode}, {:error, {:invalid_credentials, :missing_api_key}})

      assert {:error, {:invalid_credentials, :missing_api_key}} =
               CampaignWorker.perform(%Job{args: job.args})

      campaign = Repo.get!(EvalCampaign, campaign.id)
      target = Repo.get!(EvalCampaignTarget, target.id)
      eval_run = Repo.get!(EvalRun, eval_run.id)

      assert target.status == "failed"
      assert target.last_error["class"] == "fatal"
      assert eval_run.status == "failed"
      assert campaign.status == "failed_fatal"
      assert campaign.failed_targets == 1
      assert campaign.finished_at
    end

    test "is idempotent across worker replay and does not double-count counters or scores" do
      %{campaign: campaign, job: job, target: target, eval_run: eval_run} = seeded_campaign()

      assert :ok = CampaignWorker.perform(%Job{args: job.args})
      assert :ok = CampaignWorker.perform(%Job{args: job.args})

      campaign = Repo.get!(EvalCampaign, campaign.id)
      target = Repo.get!(EvalCampaignTarget, target.id)
      eval_run = Repo.get!(EvalRun, eval_run.id)

      assert target.status == "completed"
      assert eval_run.status == "completed"
      assert campaign.status == "completed"
      assert campaign.completed_targets == 1
      assert campaign.failed_targets == 0

      assert Repo.aggregate(
               from(score in Score, where: score.eval_run_id == ^eval_run.id),
               :count
             ) == 1
    end

    test "uses persisted lineage over mismatched envelope tenant data and refuses cross-tenant retargeting" do
      %{campaign: campaign, target: target, eval_run: eval_run, job: job} = seeded_campaign()

      replayed_job = Map.put(job.args, "tenant_id", "tenant-evil")

      assert :ok = CampaignWorker.perform(%Job{args: replayed_job})

      assert_received {:orchestrator_called, "openai:gpt-4o-mini", _prompt, _schema, _opts}

      campaign = Repo.get!(EvalCampaign, campaign.id)
      target = Repo.get!(EvalCampaignTarget, target.id)
      eval_run = Repo.get!(EvalRun, eval_run.id)

      assert campaign.tenant_id == "tenant-root"
      assert target.tenant_id == "tenant-alpha"
      assert eval_run.tenant_id == "tenant-alpha"
      assert target.status == "completed"
      assert eval_run.status == "completed"
      assert campaign.completed_targets == 1
      assert campaign.failed_targets == 0
    end
  end

  describe "phase 40 persistence contracts" do
    test "record_eval_scores persists additive scorer evidence without dropping provenance fields" do
      {:ok, _dataset, eval_spec, dataset_item} = seeded_eval_contract()

      assert {:ok, eval_run} =
               Eval.create_eval_run(%{
                 eval_spec_id: eval_spec.id,
                 runner_mode: :live_judge,
                 tenant_id: "tenant-score",
                 provider: "openai",
                 model: "gpt-4o-mini",
                 judge_provider: "openai",
                 judge_model: "gpt-4o"
               })

      assert {:ok, updated_run, [%Score{} = score]} =
               Eval.record_eval_scores(eval_run, [
                 %{
                   dataset_item_id: dataset_item.id,
                   score: 0.42,
                   status: "failed",
                   scorer_kind: "deterministic_rule",
                   scorer_version: "policy-rules@2026.05.23",
                   explanation: "Missing required policy disclaimer",
                   judge_model: "gpt-4o",
                   rubric_version: "online-feedback-v1",
                   evidence_refs: %{
                     "trace_id" => Ecto.UUID.generate(),
                     "workflow_run_id" => Ecto.UUID.generate()
                   },
                   metadata: %{"sample_rate" => 0.05, "latency_ms" => 12, "cost_usd" => "0.0001"}
                 }
               ])

      assert updated_run.total_items == 1
      assert updated_run.failed_items == 1
      assert updated_run.avg_latency_ms == 12
      assert score.status == "failed"
      assert score.scorer_kind == "deterministic_rule"
      assert score.scorer_version == "policy-rules@2026.05.23"
      assert score.explanation == "Missing required policy disclaimer"
      assert score.judge_model == "gpt-4o"
      assert score.rubric_version == "online-feedback-v1"
      assert score.evidence_refs["trace_id"]
      assert score.metadata["sample_rate"] == 0.05
    end

    test "online score candidates persist durable review lineage with dedupe defaults" do
      {:ok, trace} =
        %Trace{}
        |> Trace.changeset(%{session_id: "sess-online-score", attributes: %{"env" => "prod"}})
        |> Repo.insert()

      {:ok, workflow_run} =
        %Run{}
        |> Run.changeset(%{
          root_role_id: "assistant",
          tenant_id: "tenant-alpha",
          session_id: "sess-online-score",
          status: "running",
          execution_mode: "live"
        })
        |> Repo.insert()

      {:ok, workflow_step} =
        %Step{}
        |> Step.changeset(%{
          run_id: workflow_run.id,
          sequence: 1,
          kind: "llm_call",
          role_id: "assistant",
          status: "completed"
        })
        |> Repo.insert()

      dedupe_key = "tenant-alpha:#{trace.id}:window-2026-05-23T00"

      assert {:ok, candidate} =
               %OnlineScoreCandidate{}
               |> OnlineScoreCandidate.changeset(%{
                 tenant_id: "tenant-alpha",
                 trace_id: trace.id,
                 workflow_run_id: workflow_run.id,
                 workflow_step_id: workflow_step.id,
                 dedupe_key: dedupe_key,
                 sampling_metadata: %{"sampler" => "phase40", "window" => "2026-05-23T00"},
                 score: 0.18,
                 score_status: "failed",
                 score_explanation: "Needs operator review",
                 scorer_kind: "deterministic_rule",
                 scorer_version: "policy-rules@2026.05.23",
                 promotion_snapshot: %{
                   "dataset_name" => "prod-feedback",
                   "dataset_version" => "draft"
                 }
               })
               |> Repo.insert()

      assert candidate.status == "queued"
      assert candidate.review_status == "pending"
      assert candidate.trace_id == trace.id
      assert candidate.workflow_run_id == workflow_run.id
      assert candidate.workflow_step_id == workflow_step.id
      assert candidate.sampling_metadata["sampler"] == "phase40"
      assert candidate.score_status == "failed"
      assert candidate.score == 0.18
      assert candidate.scorer_kind == "deterministic_rule"
      assert candidate.promotion_snapshot["dataset_name"] == "prod-feedback"

      assert {:error, changeset} =
               %OnlineScoreCandidate{}
               |> OnlineScoreCandidate.changeset(%{
                 tenant_id: "tenant-alpha",
                 trace_id: trace.id,
                 workflow_run_id: workflow_run.id,
                 workflow_step_id: workflow_step.id,
                 dedupe_key: dedupe_key
               })
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).dedupe_key
    end
  end

  defp seeded_campaign(opts \\ []) do
    target_count = Keyword.get(opts, :target_count, 1)
    {:ok, _dataset, eval_spec, dataset_item} = seeded_eval_contract()

    targets =
      Enum.map(0..(target_count - 1), fn idx ->
        %{
          tenant_id: if(idx == 0, do: "tenant-alpha", else: "tenant-beta-#{idx}"),
          provider: "openai",
          model: "gpt-4o-mini",
          queue: "evals",
          priority: idx + 1,
          metadata: %{"lane" => "nightly-#{idx + 1}"}
        }
      end)

    assert {:ok, result} =
             Eval.create_and_enqueue_campaign(%{
               tenant_id: "tenant-root",
               eval_spec_id: eval_spec.id,
               targets: targets
             })

    campaign = result.campaign
    targets = Eval.list_campaign_targets(campaign.id)

    eval_runs =
      Repo.all(
        from(run in EvalRun,
          where: run.campaign_id == ^campaign.id,
          order_by: [asc: run.inserted_at, asc: run.id]
        )
      )

    jobs_by_target =
      all_enqueued(worker: CampaignWorker)
      |> Map.new(fn job -> {job.args["campaign_target_id"], job} end)

    jobs = Enum.map(targets, &Map.fetch!(jobs_by_target, &1.id))

    base = %{
      campaign: campaign,
      dataset_item: dataset_item,
      jobs: jobs,
      targets: targets,
      eval_runs: eval_runs
    }

    case {targets, eval_runs, jobs} do
      {[target], [eval_run], [job]} ->
        Map.merge(base, %{target: target, eval_run: eval_run, job: job})

      _ ->
        base
    end
  end

  defp seeded_eval_contract do
    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "campaign-worker-dataset",
        version: "2026.05.21",
        items: [
          %{
            input: %{"question" => "What is Scoria?"},
            expected_output: %{"answer" => "An embedded Phoenix AI runtime"},
            metadata: %{}
          }
        ]
      })

    {:ok, dataset} = Eval.seal_dataset(dataset)
    [dataset_item] = Eval.list_dataset_items(dataset.id)

    {:ok, eval_spec} =
      Eval.create_eval_spec(%{
        name: "campaign-worker-spec",
        description: "Campaign worker contract",
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
          pass_rate_gte: 1.0,
          mean_score_gte: 1.0,
          max_latency_ms: 100
        }
      })

    {:ok, dataset, eval_spec, dataset_item}
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r/%{(\w+)}/, message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
