defmodule Scoria.Eval.JudgeRunner do
  @moduledoc false

  alias Scoria.Eval
  alias Scoria.Eval.EvalRun
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
             threshold_verdict: threshold_verdict(eval_spec, scores)
           }) do
      {:ok, %{eval_run: completed_run, scores: scores}}
    end
  end

  def run_existing(%EvalRun{} = eval_run, attrs) when is_map(attrs) do
    eval_spec = fetch!(attrs, :eval_spec)
    dataset = fetch!(attrs, :dataset) || Eval.get_dataset!(eval_run.dataset_id)

    if dataset.state != :sealed do
      raise ArgumentError, "live judge runs require sealed datasets"
    end

    with {:ok, eval_run, scores} <- judge_dataset(eval_run, eval_spec, dataset, attrs),
         {:ok, completed_run} <-
           Eval.complete_eval_run(eval_run, %{
             status: "completed",
             duration_ms: Enum.sum(Enum.map(scores, &latency_ms/1)),
             threshold_verdict: threshold_verdict(eval_spec, scores)
           }) do
      {:ok, %{eval_run: completed_run, scores: scores}}
    end
  end

  defp judge_dataset(eval_run, eval_spec, dataset, attrs) do
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
      case Eval.replace_eval_scores(eval_run, score_attrs) do
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
      subject_output = build_subject_output(dataset_item)
      prompt = build_judge_prompt(dataset_item, subject_output)

      case orchestrator_module.generate_object(model_spec, prompt, judge_schema(), opts) do
        {:ok, response} ->
          verdict = extract_object(response)
          scorer = eval_spec.scorers |> List.first() || %{}

          score_attrs = %{
            dataset_item_id: dataset_item.id,
            scorer_kind: scorer |> fetch(:scorer_kind) |> to_string(),
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
    end)
    |> case do
      {:ok, score_attrs} -> {:ok, Enum.reverse(score_attrs)}
      error -> error
    end
  end

  defp build_subject_output(dataset_item) do
    get_in(dataset_item.expected_output || %{}, ["answer"]) || ""
  end

  defp build_judge_prompt(dataset_item, subject_output) do
    """
    Evaluate whether the response matches the sealed expectation.

    Input: #{Jason.encode!(dataset_item.input || %{})}
    Expected: #{Jason.encode!(dataset_item.expected_output || %{})}
    Actual: #{subject_output}
    """
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

  defp threshold_verdict(eval_spec, scores) do
    total = length(scores)
    pass_rate = if total == 0, do: 0.0, else: Enum.count(scores, &(&1.status == "passed")) / total
    mean_score = if total == 0, do: 0.0, else: Enum.sum(Enum.map(scores, & &1.score)) / total
    avg_latency = if total == 0, do: 0, else: Enum.sum(Enum.map(scores, &latency_ms/1)) / total

    pass_rate_gte = fetch(eval_spec.threshold_policy, :pass_rate_gte) || 0.0
    mean_score_gte = fetch(eval_spec.threshold_policy, :mean_score_gte) || 0.0
    max_latency_ms = fetch(eval_spec.threshold_policy, :max_latency_ms) || 0

    if pass_rate >= pass_rate_gte and
         mean_score >= mean_score_gte and
         avg_latency <= max_latency_ms do
      "passed"
    else
      "failed"
    end
  end

  defp latency_ms(score) do
    score.metadata
    |> Map.get("latency_ms", 0)
    |> case do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      _ -> 0
    end
  end

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
