defmodule Scoria.Eval.JudgeRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner
  alias Scoria.Eval.Verdict
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.Telemetry, as: ObserveTelemetry
  alias Scoria.Repo
  alias Scoria.Repo.SpanEvent

  @distinctive_explanation "Stubbed judge marked the sealed expectation as correct"

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

  # Task 3 (SC#3): real-call-site proof scaffold -- scoped Buffer + real
  # Telemetry.attach/1 + flush_now, mirroring prompt_span_test.exs
  # (D-ATTR01-6). Scoria.EvalCase's own `setup` already checks out the DB
  # sandbox; this setup only adds the observability wiring.
  setup do
    buffer_name = :"judge_runner_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
          id: buffer_name
        )
      )

    :telemetry.detach("scoria-observe-telemetry")
    ObserveTelemetry.attach(buffer_name)

    on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

    %{buffer: buffer_name, buffer_pid: pid}
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

  # Task 3 (SC#3): drives the REAL judge render path (run_live/1 ->
  # judge_dataset/4 -> score_dataset_item/6 -> build_judge_prompt_span/4),
  # not a hand-synthesized :telemetry.execute (D-ATTR01-6).
  test "run_live/1's real judge render persists a prompt_rendered event with template_ref and no explanation/verdict leak",
       %{buffer: buffer_name} do
    {:ok, dataset, eval_spec, prompt_entity_id} =
      seeded_eval_contract(captured_output: %{"answer" => "Captured judge subject output"})

    assert {:ok, _result} =
             JudgeRunner.run_live(%{
               dataset_id: dataset.id,
               eval_spec_id: eval_spec.id,
               prompt: prompt_entity_id,
               provider: "openai",
               model: "gpt-4o-mini",
               req_llm_module: ReqLLMStub
             })

    :ok = Buffer.flush_now(buffer_name)

    assert [event] = Repo.all(SpanEvent)
    assert event.name == "prompt_rendered"

    template_ref_key = Semconv.prompt_template_ref_key()
    assert event.attributes[template_ref_key] == "eval-spec-v#{eval_spec.version}"

    # Fixed-key projection: template_ref only, nothing else -- and
    # certainly never the judge's free-text explanation/verdict text
    # (structurally impossible anyway, since the event fires at render
    # time, before the judge produces any explanation, D-04b).
    assert map_size(event.attributes) == 1

    encoded = Jason.encode!(event.attributes)
    refute encoded =~ @distinctive_explanation
    refute encoded =~ "explanation"
    refute encoded =~ "verdict"
  end

  # WR-03 regression: `run_existing/2` previously used
  # `fetch!(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)`, but
  # `fetch!/2` raises ArgumentError instead of returning a falsy value on a
  # missing/nil key -- the `||` fallback was dead code, and omitting
  # `:dataset` from `attrs` always raised instead of loading the dataset by
  # `eval_run.dataset_id`. Proves the fallback now actually fires.
  test "run_existing/2 falls back to loading the dataset by eval_run.dataset_id when :dataset is absent from attrs" do
    {:ok, dataset, eval_spec, _prompt_entity_id} =
      seeded_eval_contract(captured_output: %{"answer" => "Scoria is an embedded Phoenix AI runtime"})

    {:ok, eval_run} =
      Eval.create_eval_run(%{
        eval_spec_id: eval_spec.id,
        runner_mode: :live_judge,
        status: "running",
        provider: "openai",
        model: "gpt-4o-mini"
      })

    assert eval_run.dataset_id == dataset.id

    assert {:ok, result} =
             JudgeRunner.run_existing(eval_run, %{
               eval_spec: eval_spec,
               provider: "openai",
               model: "gpt-4o-mini",
               req_llm_module: ReqLLMStub
             })

    assert result.eval_run.runner_mode == :live_judge
    assert [score] = result.scores
    assert score.status == "passed"
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
