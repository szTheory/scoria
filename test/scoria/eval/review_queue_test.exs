defmodule Scoria.Eval.ReviewQueueTest do
  use ExUnit.Case, async: false

  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Workflows.{Run, Step}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  test "projection filters and orders review candidates by severity and queue state" do
    low_quality = candidate_fixture(%{status: "needs_review", score_status: "failed", score_explanation: "Low quality"})

    _dismissed =
      candidate_fixture(%{
        status: "dismissed",
        review_status: "dismissed",
        score_status: "failed",
        score_explanation: "Dismissed"
      })

    policy_triggered =
      candidate_fixture(%{
        status: "needs_review",
        sampling_metadata: %{"sample_reason" => "policy_trigger", "sample_window" => "2026-05-23T22"}
      })

    promotion_candidate =
      candidate_fixture(%{
        status: "promotion_candidate",
        score_status: "passed",
        score_explanation: "Promote this"
      })

    rows = Eval.list_review_queue()

    assert Enum.map(rows, & &1.id) == [
             policy_triggered.id,
             low_quality.id,
             promotion_candidate.id
           ]

    assert [promotion_only] = Eval.list_review_queue(%{promotion_state: "promotion_candidate"})
    assert promotion_only.id == promotion_candidate.id

    assert Enum.all?(Eval.list_review_queue(%{review_status: "pending"}), &(&1.review_status == "pending"))
  end

  test "projection exposes summary counts, deep links, and promotion context DTOs" do
    candidate =
      candidate_fixture(%{
        status: "promotion_candidate",
        score_status: "passed",
        score_explanation: "Ready for promotion",
        promotion_snapshot: %{
          "source_variant" => "replay",
          "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "ready"}},
          "replay_reason_code" => "historical_stub"
        }
      })

    summary = Eval.summarize_review_queue()
    detail = Eval.get_review_candidate(candidate.id)

    assert summary.total_flagged == 1
    assert summary.promotion_candidate_count == 1
    assert detail.workflow_path =~ candidate.workflow_run_id
    assert detail.workflow_path =~ "review_candidate_id=#{candidate.id}"
    assert detail.runtime_path =~ "runtime=session-"
    assert detail.promotion_context.source_variant == "replay"
    assert detail.promotion_context.provenance.source_run_id
    assert detail.promotion_context.checkpoint_output["recorded_outcome"]["value"]["answer"] == "ready"
  end

  defp candidate_fixture(overrides) do
    %{trace: trace, run: run, step: step} = workflow_trace_fixture()

    attrs =
      Map.merge(
        %{
          tenant_id: "tenant-review",
          trace_id: trace.id,
          workflow_run_id: run.id,
          workflow_step_id: step.id,
          dedupe_key: "tenant-review:#{trace.id}:#{System.unique_integer([:positive])}",
          status: "needs_review",
          review_status: "pending",
          score: 0.2,
          score_status: "failed",
          score_explanation: "Needs review",
          scorer_kind: "deterministic_rule",
          scorer_version: "policy-rules@2026.05.23",
          sampling_metadata: %{"sample_reason" => "production_sample", "sample_window" => "2026-05-23T22"},
          evidence_refs: %{"trace_id" => trace.id},
          promotion_snapshot: %{
            "source_variant" => "original",
            "recorded_outcome" => %{"kind" => "result", "value" => %{"answer" => "world"}}
          }
        },
        overrides
      )

    Repo.insert!(OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, attrs))
  end

  defp workflow_trace_fixture do
    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "session-#{System.unique_integer([:positive])}",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: "tenant-review",
        session_id: trace.session_id,
        status: "running",
        execution_mode: "replay",
        source_run_id: Ecto.UUID.generate(),
        source_checkpoint_id: Ecto.UUID.generate()
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
end
