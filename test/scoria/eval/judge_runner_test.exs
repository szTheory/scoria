defmodule Scoria.Eval.JudgeRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner
  alias Scoria.Eval.Verdict

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

  test "run_live/1 sends frozen captured output as the judge Actual" do
    expected_answer = "Sealed expectation that must not become Actual"
    captured_answer = "Workflow output captured before the dataset was sealed"

    {:ok, dataset, eval_spec, prompt_entity_id} =
      seeded_eval_contract(
        expected_answer: expected_answer,
        captured_output: %{"answer" => captured_answer}
      )

    assert {:ok, result} =
             JudgeRunner.run_live(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               prompt: prompt_entity_id,
               provider: "openai",
               model: "gpt-4o-mini",
               req_llm_module: ReqLLMStub
             })

    assert_received {:req_llm_called, "openai:gpt-4o-mini", prompt}
    assert prompt =~ ~s(Actual: {"answer":"#{captured_answer}"})
    refute prompt =~ ~s(Actual: #{expected_answer})

    assert result.eval_run.runner_mode == :live_judge
    assert result.eval_run.threshold_verdict == "passed"
    assert is_integer(result.eval_run.duration_ms)
    assert result.eval_run.duration_ms >= 0

    assert result.eval_run.threshold_verdict ==
             Verdict.compute(result.scores, eval_spec.threshold_policy) |> Atom.to_string()

    assert [score] = result.scores
    assert score.scorer_kind == "llm_judge"
    assert score.status == "passed"
    assert score.explanation =~ "Stubbed judge"
    assert score.judge_model == "gpt-4o-mini"
    assert score.evidence_refs["judge"] == "stub"
    assert is_integer(score.metadata["latency_ms"])
    assert score.metadata["latency_ms"] >= 0
    assert score.metadata["cost_usd"] == "0.0"
  end

  test "run_live/1 marks empty capture not_scored without invoking the judge" do
    {:ok, dataset, eval_spec, prompt_entity_id} = seeded_eval_contract(captured_output: nil)

    assert {:ok, result} =
             JudgeRunner.run_live(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               prompt: prompt_entity_id,
               provider: "openai",
               model: "gpt-4o-mini",
               req_llm_module: ReqLLMStub
             })

    refute_received {:req_llm_called, _, _}
    assert result.eval_run.runner_mode == :live_judge
    assert result.eval_run.threshold_verdict == "inconclusive"

    assert result.eval_run.threshold_verdict ==
             Verdict.compute(result.scores, eval_spec.threshold_policy) |> Atom.to_string()

    assert [score] = result.scores
    assert score.scorer_kind == "llm_judge"
    assert score.status == "not_scored"
    assert is_nil(score.score)
    assert score.details["reason"] == "empty_capture"
    assert score.metadata["not_scored_reason"] == "empty_capture"
  end

  defp seeded_eval_contract(opts) do
    expected_answer =
      Keyword.get(opts, :expected_answer, "Scoria is an embedded Phoenix AI runtime")

    captured_output = Keyword.get(opts, :captured_output, %{"answer" => expected_answer})

    item_attrs =
      %{
        input: %{"request_kind" => "prompt"},
        expected_output: %{"answer" => expected_answer},
        metadata: %{}
      }
      |> maybe_put_capture(captured_output)

    {:ok, dataset} =
      Eval.create_dataset(%{
        name: "judge-dataset",
        version: "1",
        items: [item_attrs]
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

  defp maybe_put_capture(attrs, nil), do: attrs

  defp maybe_put_capture(attrs, captured_output),
    do: Map.put(attrs, :captured_output, captured_output)
end
