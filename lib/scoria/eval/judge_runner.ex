defmodule Scoria.Eval.JudgeRunner do
  @moduledoc false

  alias Scoria.Eval
  alias Scoria.Eval.EvalRun
  alias Scoria.Eval.SubjectOutput
  alias Scoria.Eval.Verdict
  alias ReqLLM.Response

  def run_live(attrs) when is_map(attrs) do
    eval_spec = Eval.get_eval_spec!(fetch!(attrs, :eval_spec_id))
    dataset = Eval.get_dataset!(fetch!(attrs, :dataset_id))

    if dataset.state != :sealed do
      raise ArgumentError, "live judge runs require sealed datasets"
    end

    judge_provider = fetch(attrs, :judge_provider) || fetch!(attrs, :provider)
    judge_model = fetch(attrs, :judge_model) || fetch!(attrs, :model)

    with {:ok, eval_run} <-
           Eval.create_eval_run(%{
             eval_spec_id: eval_spec.id,
             runner_mode: :live_judge,
             status: "running",
             provider: fetch!(attrs, :provider),
             model: fetch!(attrs, :model),
             judge_provider: judge_provider,
             judge_model: judge_model,
             baseline_eval_run_id: fetch(attrs, :baseline_eval_run_id)
           }),
         {:ok, eval_run, scores} <- judge_dataset(eval_run, eval_spec, dataset, attrs),
         {:ok, completed_run} <-
           Eval.complete_eval_run(eval_run, %{
             status: "completed",
             duration_ms: 0,
             threshold_verdict:
               eval_spec.threshold_policy
               |> then(&Verdict.compute(scores, &1))
               |> Atom.to_string()
           }) do
      {:ok, %{eval_run: completed_run, scores: scores}}
    end
  end

  def run_existing(%EvalRun{} = eval_run, attrs) when is_map(attrs) do
    eval_spec = fetch!(attrs, :eval_spec)
    dataset = fetch!(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)
    base_score_attrs = fetch(attrs, :base_score_attrs) || []

    if dataset.state != :sealed do
      raise ArgumentError, "live judge runs require sealed datasets"
    end

    with {:ok, eval_run, scores} <-
           judge_dataset(eval_run, eval_spec, dataset, attrs, base_score_attrs),
         {:ok, completed_run} <-
           Eval.complete_eval_run(eval_run, %{
             status: "completed",
             duration_ms: 0,
             threshold_verdict:
               eval_spec.threshold_policy
               |> then(&Verdict.compute(scores, &1))
               |> Atom.to_string()
           }) do
      {:ok, %{eval_run: completed_run, scores: scores}}
    end
  end

  defp judge_dataset(eval_run, eval_spec, dataset, attrs, base_score_attrs \\ []) do
    orchestrator_module =
      fetch(attrs, :orchestrator_module) ||
        Application.get_env(:scoria, :orchestrator_module, Scoria.Orchestrator)

    opts =
      if rlm = fetch(attrs, :req_llm_module),
        do: [req_llm_module: rlm],
        else: []

    model_spec =
      "#{fetch(attrs, :judge_provider) || fetch!(attrs, :provider)}:#{fetch(attrs, :judge_model) || fetch!(attrs, :model)}"

    with {:ok, score_attrs} <-
           build_score_attrs(
             eval_run,
             eval_spec,
             dataset,
             attrs,
             model_spec,
             orchestrator_module,
             opts
           ) do
      case Eval.replace_eval_scores(eval_run, List.wrap(base_score_attrs) ++ score_attrs) do
        {:ok, updated_run, scores} -> {:ok, updated_run, scores}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp build_score_attrs(
         _eval_run,
         eval_spec,
         dataset,
         attrs,
         model_spec,
         orchestrator_module,
         opts
       ) do
    dataset_items =
      dataset.id
      |> Eval.list_dataset_items()
      |> Enum.sort_by(& &1.id)

    Enum.reduce_while(dataset_items, {:ok, []}, fn dataset_item, {:ok, acc} ->
      case SubjectOutput.resolve(dataset_item, :live_judge) do
        {:ok, actual_output} ->
          prompt = build_judge_prompt(dataset_item, actual_output)

          case orchestrator_module.generate_object(model_spec, prompt, judge_schema(), opts) do
            {:ok, response} ->
              verdict = extract_object(response)
              scorer = eval_spec.scorers |> List.first() || %{}

              score_attrs = %{
                dataset_item_id: dataset_item.id,
                scorer_kind: scorer_kind(scorer),
                status: Map.get(verdict, "status", "failed"),
                score: Map.get(verdict, "score", 0.0),
                explanation: Map.get(verdict, "explanation", "Judge verdict unavailable"),
                judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
                rubric_version: "eval-spec-v#{eval_spec.version}",
                evidence_refs: Map.get(verdict, "evidence_refs", %{}),
                metadata: %{"cost_usd" => "0.0", "latency_ms" => 0}
              }

              {:cont, {:ok, [score_attrs | acc]}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end

        {:not_scored, reason} ->
          score_attrs = not_scored_score_attrs(dataset_item, eval_spec, attrs, reason)
          {:cont, {:ok, [score_attrs | acc]}}
      end
    end)
    |> case do
      {:ok, score_attrs} -> {:ok, Enum.reverse(score_attrs)}
      error -> error
    end
  end

  defp build_judge_prompt(dataset_item, subject_output) do
    """
    Evaluate whether the response matches the sealed expectation.

    Input: #{Jason.encode!(dataset_item.input || %{})}
    Expected: #{Jason.encode!(dataset_item.expected_output || %{})}
    Actual: #{Jason.encode!(subject_output)}
    """
  end

  defp not_scored_score_attrs(dataset_item, eval_spec, attrs, reason) do
    reason = to_string(reason)
    scorer = eval_spec.scorers |> List.first() || %{}

    %{
      dataset_item_id: dataset_item.id,
      scorer_kind: scorer_kind(scorer),
      status: "not_scored",
      score: nil,
      explanation: "Live judge could not score the sealed dataset item: #{reason}",
      judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
      rubric_version: "eval-spec-v#{eval_spec.version}",
      evidence_refs: %{},
      details: %{"reason" => reason},
      metadata: %{"cost_usd" => "0.0", "latency_ms" => 0, "not_scored_reason" => reason}
    }
  end

  defp scorer_kind(scorer) do
    scorer
    |> fetch(:scorer_kind)
    |> case do
      nil -> "llm_judge"
      kind -> to_string(kind)
    end
  end

  defp judge_schema do
    [
      score: [type: :float, required: true],
      status: [type: :string, required: true],
      explanation: [type: :string, required: true],
      evidence_refs: [type: :map, required: true]
    ]
  end

  defp extract_object(%Response{} = response), do: Response.object(response) || %{}
  defp extract_object(%{object: object}) when is_map(object), do: object
  defp extract_object(object) when is_map(object), do: object

  defp fetch!(attrs, key) do
    case fetch(attrs, key) do
      nil -> raise ArgumentError, "missing live eval option #{key}"
      value -> value
    end
  end

  defp fetch(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
