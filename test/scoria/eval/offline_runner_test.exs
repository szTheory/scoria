defmodule Scoria.Eval.OfflineRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.Runner

  @moduletag :eval
  @moduletag dataset: "offline-replay"

  test "run_offline/1 passes when exact_match sees a matching captured output" do
    {:ok, dataset, eval_spec} = seeded_eval_contract()

    assert {:ok, result} =
             Runner.run_offline(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               provider: "openai",
               model: "gpt-4o-mini"
             })

    assert result.fixture_key ==
             "scoria_eval_fixture_prompt-v1_dataset-v1_eval-spec-v1_openai-gpt-4o-mini"

    assert result.threshold_verdict == "passed"
    assert result.eval_run.runner_mode == :offline_replay
    assert result.eval_run.status == "completed"
    assert result.eval_run.total_items == 1
    assert is_integer(result.eval_run.duration_ms)
    assert result.eval_run.duration_ms >= 0
    assert [score] = result.scores
    assert score.status == "passed"
    assert score.score == 1.0
    assert score.scorer_kind == "exact_match"
    assert score.evidence_refs["fixture_key"] == result.fixture_key
    assert is_integer(score.metadata["latency_ms"])
    assert score.metadata["latency_ms"] >= 0
    assert score.metadata["cost_usd"] == "0.0"
  end

  test "run_offline/1 fails when exact_match sees a real mismatch" do
    {:ok, dataset, eval_spec} =
      seeded_eval_contract(captured_output: %{"answer" => "A different runtime answer"})

    assert {:ok, result} = run_offline(dataset, eval_spec)

    assert result.threshold_verdict == "failed"
    assert [score] = result.scores
    assert score.status == "failed"
    assert score.score == 0.0
    assert score.scorer_kind == "exact_match"
  end

  test "run_offline/1 marks empty captures not_scored and leaves the run inconclusive" do
    {:ok, dataset, eval_spec} = seeded_eval_contract(captured_output: nil)

    assert {:ok, result} = run_offline(dataset, eval_spec)

    assert result.threshold_verdict == "inconclusive"
    assert [score] = result.scores
    assert score.status == "not_scored"
    assert is_nil(score.score)
    assert score.details["reason"] == "empty_capture"
  end

  test "run_offline/1 marks unknown scorer kinds not_scored and leaves the run inconclusive" do
    {:ok, dataset, eval_spec} = seeded_eval_contract(scorer_kind: "unknown_scorer")

    assert {:ok, result} = run_offline(dataset, eval_spec)

    assert result.threshold_verdict == "inconclusive"
    assert [score] = result.scores
    assert score.status == "not_scored"
    assert is_nil(score.score)
    assert score.scorer_kind == "unknown_scorer"
    assert score.details["reason"] == "unknown_scorer"
  end

  test "assert_dataset/1 returns :ok for a sealed dataset and matching cassette" do
    {:ok, dataset, eval_spec} = seeded_eval_contract()

    assert :ok =
             Runner.assert_dataset(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               provider: "openai",
               model: "gpt-4o-mini"
             })
  end

  defp run_offline(dataset, eval_spec) do
    Runner.run_offline(%{
      dataset_id: dataset.id,
      eval_spec_id: eval_spec.id,
      provider: "openai",
      model: "gpt-4o-mini"
    })
  end

  defp seeded_eval_contract(opts \\ []) do
    expected_answer =
      Keyword.get(opts, :expected_answer, "Scoria is an embedded Phoenix AI runtime")

    captured_output = Keyword.get(opts, :captured_output, %{"answer" => expected_answer})
    scorer_kind = Keyword.get(opts, :scorer_kind, :exact_match)

    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "offline-replay-dataset",
        version: "1",
        items: [
          %{
            input: %{"request_kind" => "prompt"},
            expected_output: %{"answer" => expected_answer},
            captured_output: captured_output,
            metadata: %{}
          }
        ]
      })

    {:ok, dataset} = Eval.seal_dataset(dataset)

    {:ok, eval_spec} =
      Eval.create_eval_spec(%{
        name: "offline-replay-spec",
        description: "Offline replay spec",
        dataset_id: dataset.id,
        eval_mode: :offline_replay,
        subject: %{
          subject_kind: :prompt_template,
          prompt_template_id: Ecto.UUID.generate(),
          prompt_entity_id: Ecto.UUID.generate(),
          prompt_version: 1
        },
        scorers: [
          %{
            metric_key: "correctness",
            scorer_kind: scorer_kind,
            field: "answer",
            weight: 1.0
          }
        ],
        threshold_policy: %{
          pass_rate_gte: 1.0,
          mean_score_gte: 1.0,
          max_latency_ms: 100
        }
      })

    {:ok, dataset, eval_spec}
  end
end
