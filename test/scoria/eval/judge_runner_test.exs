defmodule Scoria.Eval.JudgeRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner

  defmodule ReqLLMStub do
    def generate_object(model_spec, prompt, _schema, _opts) do
      send(self(), {:req_llm_called, model_spec, prompt})

      {:ok,
       %{
         object: %{
           "score" => 1.0,
           "status" => "passed",
           "explanation" => "Stubbed judge marked the sealed expectation as correct",
           "evidence_refs" => %{"judge" => "stub"}
         }
       }}
    end
  end

  test "run_live/1 persists structured judge verdicts through the canonical eval APIs" do
    {:ok, dataset, eval_spec, prompt_entity_id} = seeded_eval_contract()

    assert {:ok, result} =
             JudgeRunner.run_live(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               prompt: prompt_entity_id,
               provider: "openai",
               model: "gpt-4o-mini",
               req_llm_module: ReqLLMStub
             })

    assert_received {:req_llm_called, "openai:gpt-4o-mini", _prompt}
    assert result.eval_run.runner_mode == :live_judge
    assert result.eval_run.threshold_verdict == "passed"
    assert [score] = result.scores
    assert score.scorer_kind == "llm_judge"
    assert score.status == "passed"
    assert score.explanation =~ "Stubbed judge"
    assert score.judge_model == "gpt-4o-mini"
    assert score.evidence_refs["judge"] == "stub"
  end

  defp seeded_eval_contract do
    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "judge-dataset",
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
    prompt_entity_id = Ecto.UUID.generate()

    {:ok, eval_spec} =
      Eval.create_eval_spec(%{
        name: "judge-spec",
        description: "Judge spec",
        dataset_id: dataset.id,
        eval_mode: :live_judge,
        subject: %{
          subject_kind: :prompt_template,
          prompt_template_id: Ecto.UUID.generate(),
          prompt_entity_id: prompt_entity_id,
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

    {:ok, dataset, eval_spec, prompt_entity_id}
  end
end
