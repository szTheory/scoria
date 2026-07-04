defmodule Scoria.Eval.OnlineScoringTest do
  use Scoria.EvalCase, async: false

  import Ecto.Query

  alias Scoria.Eval

  alias Scoria.Eval.{
    EvalCampaign,
    EvalCampaignTarget,
    EvalRun,
    OnlineScoreCandidate,
    OnlineScoring,
    Score
  }

  alias Scoria.Repo
  alias Scoria.Repo.{Span, Trace}
  alias Scoria.Workflows.{Run, Step}

  defmodule OrchestratorStub do
    def generate_object(model_spec, prompt, schema, opts) do
      send(self(), {:orchestrator_called, model_spec, prompt, schema, opts})

      {:ok,
       %{
         object: %{
           "score" => 1.0,
           "status" => "passed",
           "explanation" => "Stubbed judge verdict",
           "evidence_refs" => %{"judge" => "stub"}
         }
       }}
    end
  end

  setup do
    previous_orchestrator = Application.get_env(:scoria, :orchestrator_module)
    Application.put_env(:scoria, :orchestrator_module, OrchestratorStub)

    on_exit(fn ->
      if previous_orchestrator do
        Application.put_env(:scoria, :orchestrator_module, previous_orchestrator)
      else
        Application.delete_env(:scoria, :orchestrator_module)
      end
    end)

    :ok
  end

  describe "execute_candidate/2 negative-signal classifier" do
    test "policy trigger emits a terminal failed deterministic signal and skips the judge" do
      result =
        execute_online_fixture(
          sample_reason: "policy_trigger",
          span_status: "OK",
          step_result_envelope: %{"output" => %{"answer" => "runtime output"}}
        )

      assert_terminal_negative(result, "policy_trigger")
    end

    test "ERROR span emits a terminal failed deterministic signal and skips the judge" do
      result =
        execute_online_fixture(
          sample_reason: "production_sample",
          span_status: "ERROR",
          step_result_envelope: %{"output" => %{"answer" => "runtime output"}}
        )

      assert_terminal_negative(result, "span_error")
    end

    test "absent step output emits a terminal failed deterministic signal and skips the judge" do
      result =
        execute_online_fixture(
          sample_reason: "production_sample",
          span_status: "OK",
          step_result_envelope: %{}
        )

      assert_terminal_negative(result, "empty_output")
    end
  end

  defp assert_terminal_negative(%{candidate: candidate, eval_run: eval_run}, negative_signal) do
    refute_received {:orchestrator_called, _, _, _, _}

    candidate = Repo.get!(OnlineScoreCandidate, candidate.id)
    eval_run = Repo.get!(EvalRun, eval_run.id)
    scores = Repo.all(from(score in Score, where: score.eval_run_id == ^eval_run.id))

    assert candidate.status == "needs_review"
    assert candidate.review_status == "pending"
    assert candidate.score_status == "failed"
    assert candidate.scorer_kind == "deterministic_rule"
    assert eval_run.threshold_verdict == "failed"

    assert [%Score{} = score] = scores
    assert score.scorer_kind == "deterministic_rule"
    assert score.scorer_version == "policy-rules@2026.05.23"
    assert score.status == "failed"
    assert score.score == 0.0
    assert score.metadata["negative_signal"] == negative_signal
    assert score.evidence_refs["candidate_id"] == candidate.id
    assert score.evidence_refs["workflow_step_id"] == candidate.workflow_step_id
  end

  defp execute_online_fixture(opts) do
    tenant_id = "tenant-online"
    sample_reason = Keyword.fetch!(opts, :sample_reason)
    step_result_envelope = Keyword.fetch!(opts, :step_result_envelope)
    span_status = Keyword.get(opts, :span_status)

    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "online-scoring-dataset",
        version: "1",
        items: [
          %{
            input: %{"question" => "What is Scoria?"},
            expected_output: %{"answer" => "An embedded Phoenix AI runtime"},
            captured_output: %{"answer" => "An embedded Phoenix AI runtime"},
            metadata: %{}
          }
        ]
      })

    {:ok, dataset} = Eval.seal_dataset(dataset)

    {:ok, eval_spec} =
      Eval.create_eval_spec(%{
        name: "online-scoring-spec",
        description: "Online scoring regression contract",
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

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "sess-#{System.unique_integer([:positive])}",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    maybe_insert_span(trace, span_status)

    {:ok, workflow_run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: tenant_id,
        session_id: trace.session_id,
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
        status: "completed",
        result_envelope: step_result_envelope
      })
      |> Repo.insert()

    {:ok, candidate} =
      %OnlineScoreCandidate{}
      |> OnlineScoreCandidate.changeset(%{
        tenant_id: tenant_id,
        trace_id: trace.id,
        workflow_run_id: workflow_run.id,
        workflow_step_id: workflow_step.id,
        dedupe_key: "#{tenant_id}:#{trace.id}:#{sample_reason}",
        sampling_metadata: %{"sample_reason" => sample_reason},
        evidence_refs: %{
          "trace_id" => trace.id,
          "workflow_run_id" => workflow_run.id,
          "workflow_step_id" => workflow_step.id
        }
      })
      |> Repo.insert()

    {:ok, campaign} =
      %EvalCampaign{}
      |> EvalCampaign.changeset(%{
        tenant_id: tenant_id,
        eval_spec_id: eval_spec.id,
        status: "running",
        total_targets: 1,
        queued_targets: 0,
        running_targets: 1,
        metadata: %{"source" => "online_scoring", "candidate_id" => candidate.id}
      })
      |> Repo.insert()

    {:ok, target} =
      %EvalCampaignTarget{}
      |> EvalCampaignTarget.changeset(%{
        campaign_id: campaign.id,
        eval_spec_id: eval_spec.id,
        tenant_id: tenant_id,
        provider: "openai",
        model: "gpt-4o-mini",
        queue: "evals",
        priority: 1,
        status: "running",
        metadata: %{"source" => "online_scoring", "candidate_id" => candidate.id}
      })
      |> Repo.insert()

    {:ok, eval_run} =
      Eval.create_eval_run(%{
        eval_spec_id: eval_spec.id,
        runner_mode: :live_judge,
        status: "running",
        tenant_id: tenant_id,
        campaign_id: campaign.id,
        campaign_target_id: target.id,
        provider: target.provider,
        model: target.model
      })

    {:ok, _candidate} =
      candidate
      |> OnlineScoreCandidate.changeset(%{campaign_id: campaign.id, eval_run_id: eval_run.id})
      |> Repo.update()

    assert {:ok, result} =
             OnlineScoring.execute_candidate(eval_run, %{
               target: target,
               eval_spec: eval_spec,
               dataset: dataset
             })

    result
  end

  defp maybe_insert_span(_trace, nil), do: :ok

  defp maybe_insert_span(trace, status_code) do
    {:ok, _span} =
      %Span{}
      |> Span.changeset(%{
        trace_id: trace.id,
        name: "llm.call",
        span_kind: "CLIENT",
        status_code: status_code,
        start_time: DateTime.utc_now()
      })
      |> Repo.insert()

    :ok
  end
end
