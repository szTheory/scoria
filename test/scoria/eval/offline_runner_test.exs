defmodule Scoria.Eval.OfflineRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.Runner

  @moduletag :eval
  @moduletag dataset: "offline-replay"

  test "run_offline/1 replays the committed cassette and persists eval evidence" do
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
    assert [score] = result.scores
    assert score.status == "passed"
    assert score.evidence_refs["fixture_key"] == result.fixture_key
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

  defp seeded_eval_contract do
    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "offline-replay-dataset",
        version: "1",
        items: [
          %{
            input: %{"request_kind" => "prompt"},
            expected_output: %{"answer" => "Scoria is an embedded Phoenix AI runtime"},
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
            scorer_kind: :llm_judge,
            judge_prompt_template_id: Ecto.UUID.generate(),
            judge_prompt_version: 1,
            judge_provider: "openai",
            judge_model: "gpt-4o",
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
