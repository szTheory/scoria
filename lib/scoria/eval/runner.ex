defmodule Scoria.Eval.Runner do
  @moduledoc false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner
  alias Scoria.Eval.Scorers.ExactMatch
  alias Scoria.Eval.SubjectOutput
  alias Scoria.Eval.Timing
  alias Scoria.Eval.Verdict

  def run_offline(attrs) when is_map(attrs) do
    run_started_at = Timing.mark()
    eval_spec = Eval.get_eval_spec!(fetch!(attrs, :eval_spec_id))
    dataset = Eval.get_dataset!(fetch!(attrs, :dataset_id))

    with :ok <- validate_dataset(dataset, eval_spec),
         {:ok, eval_run} <- create_eval_run(eval_spec, dataset, attrs),
         {:ok, eval_run, scores} <- record_scores(eval_run, dataset, eval_spec, attrs),
         {:ok, completed_run} <-
           Eval.complete_eval_run(eval_run, %{
             status: "completed",
             duration_ms: Timing.elapsed_ms(run_started_at),
             threshold_verdict:
               eval_spec.threshold_policy
               |> then(&Verdict.compute(scores, &1))
               |> Atom.to_string()
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
    scorer = primary_scorer(eval_spec)
    scorer_kind = scorer_kind(scorer)

    if scorer_kind == "llm_judge" and judge_seam_supplied?(attrs) do
      eval_run
      |> JudgeRunner.run_existing(
        attrs
        |> Map.put(:eval_spec, eval_spec)
        |> Map.put(:dataset, dataset)
      )
      |> case do
        {:ok, %{eval_run: updated_run, scores: scores}} -> {:ok, updated_run, scores}
        {:error, reason} -> {:error, reason}
      end
    else
      record_offline_scores(eval_run, dataset, eval_spec, attrs, scorer, scorer_kind)
    end
  end

  defp record_offline_scores(eval_run, dataset, eval_spec, attrs, scorer, scorer_kind) do
    dataset_items =
      dataset.id
      |> Eval.list_dataset_items()
      |> Enum.sort_by(& &1.id)

    score_attrs =
      Enum.map(dataset_items, fn dataset_item ->
        {score_attrs, latency_ms} =
          Timing.measure(fn ->
            score_dataset_item(dataset_item, eval_run, eval_spec, attrs, scorer, scorer_kind)
          end)

        put_score_latency(score_attrs, latency_ms)
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

  defp score_dataset_item(dataset_item, eval_run, eval_spec, attrs, scorer, "exact_match") do
    base_attrs = base_score_attrs(dataset_item, eval_run, eval_spec, attrs, "exact_match")

    case SubjectOutput.resolve(dataset_item, :offline_replay) do
      {:ok, actual_output} ->
        actual = exact_match_actual(actual_output, scorer)

        case ExactMatch.score(actual, dataset_item.expected_output || %{}, scorer) do
          %{
            status: status,
            score: score,
            scorer_kind: kind,
            scorer_version: version,
            details: details
          } ->
            Map.merge(base_attrs, %{
              scorer_kind: kind,
              scorer_version: version,
              status: status,
              score: score,
              details: details,
              explanation: exact_match_explanation(status)
            })

          {:not_scored, reason} ->
            not_scored_score_attrs(base_attrs, reason)
        end

      {:not_scored, reason} ->
        not_scored_score_attrs(base_attrs, reason)
    end
  end

  defp score_dataset_item(dataset_item, eval_run, eval_spec, attrs, _scorer, "llm_judge") do
    dataset_item
    |> base_score_attrs(eval_run, eval_spec, attrs, "llm_judge")
    |> not_scored_score_attrs(:llm_judge_unavailable)
  end

  defp score_dataset_item(dataset_item, eval_run, eval_spec, attrs, _scorer, scorer_kind) do
    normalized_kind = scorer_kind || "unknown"

    reason =
      case scorer_kind do
        nil -> :missing_scorer_kind
        "" -> :missing_scorer_kind
        _ -> :unknown_scorer
      end

    dataset_item
    |> base_score_attrs(eval_run, eval_spec, attrs, normalized_kind)
    |> not_scored_score_attrs(reason)
  end

  defp exact_match_actual(actual_output, scorer) do
    if match_mode(scorer) in ["map", :map] do
      actual_output
    else
      field = fetch(scorer, :field) || "answer"
      fetch(actual_output, field)
    end
  end

  defp base_score_attrs(dataset_item, eval_run, eval_spec, attrs, scorer_kind) do
    %{
      dataset_item_id: dataset_item.id,
      scorer_kind: scorer_kind,
      judge_model: fetch(attrs, :judge_model) || fetch!(attrs, :model),
      rubric_version: "eval-spec-v#{eval_spec.version}",
      evidence_refs: %{"fixture_key" => eval_run.fixture_key},
      metadata: %{"cost_usd" => "0.0"}
    }
  end

  defp put_score_latency(score_attrs, latency_ms) do
    Map.update(score_attrs, :metadata, %{"latency_ms" => latency_ms}, fn metadata ->
      Map.put(metadata, "latency_ms", latency_ms)
    end)
  end

  defp not_scored_score_attrs(base_attrs, reason) do
    reason = to_string(reason)

    Map.merge(base_attrs, %{
      status: "not_scored",
      score: nil,
      explanation: "Offline replay could not score the sealed dataset item: #{reason}",
      details: %{"reason" => reason},
      metadata: Map.put(base_attrs.metadata, "not_scored_reason", reason)
    })
  end

  defp exact_match_explanation("passed"),
    do: "Offline replay captured output matched the sealed dataset expectation"

  defp exact_match_explanation("failed"),
    do: "Offline replay captured output differed from the sealed dataset expectation"

  defp primary_scorer(eval_spec) do
    eval_spec.scorers
    |> List.first()
    |> case do
      nil -> %{}
      scorer -> scorer
    end
  end

  defp scorer_kind(scorer) do
    scorer
    |> fetch(:scorer_kind)
    |> case do
      nil -> nil
      kind -> to_string(kind)
    end
  end

  defp match_mode(scorer), do: fetch(scorer, :match)

  defp judge_seam_supplied?(attrs) do
    not is_nil(fetch(attrs, :orchestrator_module)) or not is_nil(fetch(attrs, :req_llm_module))
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
