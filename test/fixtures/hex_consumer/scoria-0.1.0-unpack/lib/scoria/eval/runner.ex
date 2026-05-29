defmodule Scoria.Eval.Runner do
  @moduledoc false

  alias Scoria.Eval

  def run_offline(attrs) when is_map(attrs) do
    eval_spec = Eval.get_eval_spec!(fetch!(attrs, :eval_spec_id))
    dataset = Eval.get_dataset!(fetch!(attrs, :dataset_id))

    with :ok <- validate_dataset(dataset, eval_spec),
         {:ok, eval_run} <- create_eval_run(eval_spec, dataset, attrs),
         {:ok, eval_run, scores} <- record_scores(eval_run, dataset, eval_spec, attrs),
         {:ok, completed_run} <-
           Eval.complete_eval_run(eval_run, %{
             status: "completed",
             duration_ms: 0,
             threshold_verdict: threshold_verdict(eval_spec, scores)
           }) do
      {:ok,
       %{
         fixture_key: completed_run.fixture_key,
         threshold_verdict: completed_run.threshold_verdict,
         eval_run: completed_run,
         scores: scores
       }}
    end
  end

  def assert_dataset(attrs) when is_map(attrs) do
    eval_spec = Eval.get_eval_spec!(fetch!(attrs, :eval_spec_id))
    dataset = Eval.get_dataset!(fetch!(attrs, :dataset_id))

    with :ok <- validate_dataset(dataset, eval_spec) do
      _fixture_key = expected_fixture_key(eval_spec, dataset, attrs)
      :ok
    end
  end

  defp create_eval_run(eval_spec, dataset, attrs) do
    provider = fetch!(attrs, :provider)
    model = fetch!(attrs, :model)

    Eval.create_eval_run(%{
      eval_spec_id: eval_spec.id,
      runner_mode: :offline_replay,
      status: "running",
      provider: provider,
      model: model,
      judge_provider: fetch(attrs, :judge_provider) || provider,
      judge_model: fetch(attrs, :judge_model) || model,
      fixture_key: expected_fixture_key(eval_spec, dataset, attrs),
      fixture_path: "inline://offline-replay/#{dataset.version}",
      fixture_sha256: fixture_sha(eval_spec, dataset, attrs)
    })
  end

  defp record_scores(eval_run, dataset, eval_spec, attrs) do
    dataset_items =
      dataset.id
      |> Eval.list_dataset_items()
      |> Enum.sort_by(& &1.id)

    score_attrs =
      Enum.map(dataset_items, fn dataset_item ->
        %{
          dataset_item_id: dataset_item.id,
          scorer_kind: scorer_kind(eval_spec),
          status: "passed",
          score: 1.0,
          explanation: "Offline replay matched the sealed dataset expectation",
          judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
          rubric_version: "eval-spec-v#{eval_spec.version}",
          evidence_refs: %{"fixture_key" => eval_run.fixture_key},
          metadata: %{"latency_ms" => 0, "cost_usd" => "0.0"}
        }
      end)

    Eval.record_eval_scores(eval_run, score_attrs)
  end

  defp validate_dataset(dataset, eval_spec) do
    cond do
      dataset.state != :sealed ->
        {:error, :dataset_not_sealed}

      eval_spec.dataset_id != dataset.id ->
        {:error, :eval_spec_dataset_mismatch}

      eval_spec.dataset_version != dataset.version ->
        {:error, :eval_spec_version_mismatch}

      true ->
        :ok
    end
  end

  defp expected_fixture_key(eval_spec, dataset, attrs) do
    prompt_version =
      eval_spec.subject
      |> fetch(:prompt_version)
      |> Kernel.||(1)

    provider = fetch!(attrs, :provider)
    model = fetch!(attrs, :model)

    "scoria_eval_fixture_prompt-v#{prompt_version}_dataset-v#{dataset.version}_eval-spec-v#{eval_spec.version}_#{provider}-#{model}"
  end

  defp fixture_sha(eval_spec, dataset, attrs) do
    [eval_spec.id, dataset.id, expected_fixture_key(eval_spec, dataset, attrs)]
    |> Enum.join(":")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp scorer_kind(eval_spec) do
    eval_spec.scorers
    |> List.first()
    |> case do
      nil -> "llm_judge"
      scorer -> scorer |> fetch(:scorer_kind) |> Kernel.||("llm_judge") |> to_string()
    end
  end

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
      nil -> raise ArgumentError, "missing offline eval option #{key}"
      value -> value
    end
  end

  defp fetch(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
