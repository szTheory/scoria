defmodule Scoria.Eval.OnlineScoring do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Eval.EvalRun
  alias Scoria.Eval.EvalSpec
  alias Scoria.Eval.EvalCampaignTarget
  alias Scoria.Repo
  alias Scoria.Repo.Trace

  def enqueue_sampled_trace(attrs, opts \\ []) when is_map(attrs) do
    payload = normalize_payload(attrs)

    result =
      case get_or_create_candidate(payload) do
        {:ok, %OnlineScoreCandidate{campaign_id: campaign_id} = candidate, :existing}
        when not is_nil(campaign_id) ->
          {:ok, %{candidate: candidate, reused?: true, enqueued?: false}}

        {:ok, %OnlineScoreCandidate{} = candidate, _source} ->
          enqueue_candidate(candidate, payload)

        {:error, _} = error ->
          error
      end

    notify(opts, result)
    result
  end

  def execute_candidate(
        %EvalRun{} = eval_run,
        %{
          target: %EvalCampaignTarget{} = target,
          eval_spec: %EvalSpec{} = eval_spec,
          dataset: dataset
        } = _context
      ) do
    with {:ok, candidate} <- fetch_candidate(target),
         {:ok, trace} <- fetch_trace(candidate.trace_id),
         {:ok, deterministic_scores, terminal?} <- deterministic_scores(candidate, trace, dataset),
         {:ok, result} <- maybe_run_judge(eval_run, eval_spec, dataset, target, deterministic_scores, terminal?),
         {:ok, candidate} <- sync_candidate(candidate.id, result.scores) do
      {:ok, Map.put(result, :candidate, candidate)}
    end
  end

  defp enqueue_candidate(%OnlineScoreCandidate{} = candidate, payload) do
    campaign_attrs = campaign_attrs(candidate, payload)

    with {:ok, enqueue_result} <- Eval.create_and_enqueue_campaign(campaign_attrs),
         [eval_run | _] = eval_runs <- enqueue_result.eval_runs,
         {:ok, candidate} <- update_candidate_lineage(candidate, enqueue_result.campaign.id, eval_run.id) do
      {:ok,
       %{
         candidate: candidate,
         campaign: enqueue_result.campaign,
         eval_runs: eval_runs,
         reused?: false,
         enqueued?: true
       }}
    end
  end

  defp get_or_create_candidate(payload) do
    attrs = candidate_attrs(payload)

    Multi.new()
    |> Multi.insert(
      :candidate,
      OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, attrs)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{candidate: candidate}} ->
        {:ok, candidate, :inserted}

      {:error, :candidate, changeset, _changes} ->
        if duplicate_candidate?(changeset) do
          {:ok, fetch_existing_candidate!(payload), :existing}
        else
          {:error, changeset}
        end
    end
  end

  defp update_candidate_lineage(candidate, campaign_id, eval_run_id) do
    candidate
    |> OnlineScoreCandidate.changeset(%{
      campaign_id: campaign_id,
      eval_run_id: eval_run_id
    })
    |> Repo.update()
  end

  defp fetch_existing_candidate!(payload) do
    Repo.one!(
      from(candidate in OnlineScoreCandidate,
        where:
          candidate.tenant_id == ^payload.tenant_id and
            candidate.dedupe_key == ^payload.dedupe_key and
            candidate.review_status in ["pending", "in_review"],
        order_by: [desc: candidate.inserted_at, desc: candidate.id],
        limit: 1
      )
    )
  end

  defp campaign_attrs(candidate, payload) do
    scorer = payload.scorer

    %{
      tenant_id: payload.tenant_id,
      eval_spec_id: Map.fetch!(scorer, "eval_spec_id"),
      metadata: %{
        "source" => "online_scoring",
        "candidate_id" => candidate.id,
        "trace_id" => payload.trace_id,
        "workflow_run_id" => payload.workflow_run_id,
        "workflow_step_id" => payload.workflow_step_id,
        "sampling_metadata" => payload.sampling_metadata
      },
      targets: [
        %{
          tenant_id: payload.tenant_id,
          provider: Map.fetch!(scorer, "provider"),
          model: Map.fetch!(scorer, "model"),
          queue: Map.get(scorer, "queue", "evals"),
          priority: Map.get(scorer, "priority", 1),
          metadata: %{
            "source" => "online_scoring",
            "candidate_id" => candidate.id,
            "trace_id" => payload.trace_id,
            "workflow_run_id" => payload.workflow_run_id,
            "workflow_step_id" => payload.workflow_step_id,
            "dedupe_key" => payload.dedupe_key,
            "sampling_metadata" => payload.sampling_metadata,
            "scorer" => scorer,
            "evidence_refs" => payload.evidence_refs,
            "promotion_snapshot" => payload.promotion_snapshot
          }
        }
      ]
    }
  end

  defp candidate_attrs(payload) do
    %{
      tenant_id: payload.tenant_id,
      trace_id: payload.trace_id,
      workflow_run_id: payload.workflow_run_id,
      workflow_step_id: payload.workflow_step_id,
      dedupe_key: payload.dedupe_key,
      status: "queued",
      review_status: "pending",
      sampling_metadata: payload.sampling_metadata,
      evidence_refs: payload.evidence_refs,
      promotion_snapshot: payload.promotion_snapshot,
      metadata: %{"scorer" => payload.scorer},
      sampled_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    }
  end

  defp duplicate_candidate?(changeset) do
    Enum.any?(changeset.errors, fn
      {:dedupe_key, {_message, metadata}} -> metadata[:constraint] == :unique
      _ -> false
    end)
  end

  defp notify(opts, result) do
    case Keyword.get(opts, :notify) do
      pid when is_pid(pid) -> send(pid, {:online_scoring_result, result})
      _ -> :ok
    end
  end

  defp normalize_payload(attrs) do
    %{
      trace_id: fetch_attr!(attrs, :trace_id),
      tenant_id: fetch_attr!(attrs, :tenant_id),
      workflow_run_id: fetch_attr!(attrs, :workflow_run_id),
      workflow_step_id: fetch_attr!(attrs, :workflow_step_id),
      dedupe_key: fetch_attr!(attrs, :dedupe_key),
      scorer: attrs |> fetch_attr!(:scorer) |> normalize_map(),
      evidence_refs: attrs |> fetch_attr(:evidence_refs, %{}) |> normalize_map(),
      promotion_snapshot: attrs |> fetch_attr(:promotion_snapshot, %{}) |> normalize_map(),
      sampling_metadata: attrs |> fetch_attr(:sampling_metadata, %{}) |> normalize_map()
    }
  end

  defp fetch_attr!(attrs, key) do
    case fetch_attr(attrs, key) do
      nil -> raise ArgumentError, "missing required online scoring attribute #{key}"
      value -> value
    end
  end

  defp fetch_attr(attrs, key, default \\ nil) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key)) || default
  end

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value), do: value

  defp fetch_candidate(%EvalCampaignTarget{} = target) do
    case candidate_id(target) do
      nil -> {:error, {:invalid_campaign_contract, :missing_online_score_candidate}}
      candidate_id -> {:ok, Repo.get!(OnlineScoreCandidate, candidate_id)}
    end
  rescue
    Ecto.NoResultsError -> {:error, {:invalid_campaign_contract, :missing_online_score_candidate}}
  end

  defp fetch_trace(trace_id) do
    case Repo.get(Trace, trace_id) do
      %Trace{} = trace -> {:ok, trace}
      nil -> {:error, {:invalid_campaign_contract, :missing_online_score_trace}}
    end
  end

  defp deterministic_scores(candidate, %Trace{} = trace, dataset) do
    dataset_items = dataset.id |> Eval.list_dataset_items() |> Enum.sort_by(& &1.id)
    sample_reason = Map.get(candidate.sampling_metadata || %{}, "sample_reason", "production_sample")
    policy_triggered? = sample_reason == "policy_trigger"
    trace_env = trace.attributes |> normalize_map() |> Map.get("env", "unknown")
    score_status = if(policy_triggered?, do: "failed", else: "passed")
    score_value = if(policy_triggered?, do: 0.0, else: 1.0)

    explanation =
      if policy_triggered? do
        "Policy trigger requires operator review"
      else
        "Deterministic online checks passed for #{trace_env} trace"
      end

    score_attrs =
      Enum.map(dataset_items, fn dataset_item ->
        %{
          dataset_item_id: dataset_item.id,
          scorer_kind: "deterministic_rule",
          scorer_version: "policy-rules@2026.05.23",
          status: score_status,
          score: score_value,
          explanation: explanation,
          rubric_version: "online-feedback-v1",
          evidence_refs: evidence_refs(candidate, trace, sample_reason),
          metadata: %{
            "candidate_id" => candidate.id,
            "sample_reason" => sample_reason,
            "trace_env" => trace_env,
            "latency_ms" => 0,
            "cost_usd" => "0.0"
          }
        }
      end)

    {:ok, score_attrs, policy_triggered?}
  end

  defp maybe_run_judge(eval_run, _eval_spec, _dataset, _target, deterministic_scores, true) do
    with {:ok, updated_run, scores} <- Eval.replace_eval_scores(eval_run, deterministic_scores),
         {:ok, completed_run} <-
           Eval.complete_eval_run(updated_run, %{
             status: "completed",
             duration_ms: 0,
             threshold_verdict: threshold_verdict(scores)
           }) do
      {:ok, %{eval_run: completed_run, scores: scores}}
    end
  end

  defp maybe_run_judge(eval_run, eval_spec, dataset, target, deterministic_scores, false) do
    Scoria.Eval.JudgeRunner.run_existing(eval_run, %{
      eval_spec: eval_spec,
      dataset: dataset,
      provider: target.provider,
      model: target.model,
      judge_provider: target.provider,
      judge_model: target.model,
      base_score_attrs: deterministic_scores
    })
  end

  defp sync_candidate(candidate_id, scores) do
    candidate = Repo.get!(OnlineScoreCandidate, candidate_id)
    summary = summarize_scores(scores)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    candidate
    |> OnlineScoreCandidate.changeset(%{
      status: summary.status,
      review_status: summary.review_status,
      score: summary.score,
      score_status: summary.score_status,
      score_explanation: summary.score_explanation,
      scorer_kind: summary.scorer_kind,
      scorer_version: summary.scorer_version,
      judge_model: summary.judge_model,
      rubric_version: summary.rubric_version,
      reviewed_at: now
    })
    |> Repo.update()
  end

  defp summarize_scores(scores) do
    failed_score = Enum.find(scores, &(&1.status == "failed"))
    last_score = List.last(scores)
    mean_score = scores |> Enum.map(& &1.score) |> average_score()

    if failed_score do
      %{
        status: "needs_review",
        review_status: "pending",
        score: mean_score,
        score_status: failed_score.status,
        score_explanation: failed_score.explanation,
        scorer_kind: failed_score.scorer_kind,
        scorer_version: failed_score.scorer_version,
        judge_model: failed_score.judge_model,
        rubric_version: failed_score.rubric_version
      }
    else
      %{
        status: "promotion_candidate",
        review_status: "pending",
        score: mean_score,
        score_status: last_score && last_score.status,
        score_explanation: last_score && last_score.explanation,
        scorer_kind: last_score && last_score.scorer_kind,
        scorer_version: last_score && last_score.scorer_version,
        judge_model: last_score && last_score.judge_model,
        rubric_version: last_score && last_score.rubric_version
      }
    end
  end

  defp average_score([]), do: nil
  defp average_score(scores), do: Enum.sum(scores) / length(scores)

  defp threshold_verdict(scores) do
    if Enum.all?(scores, &(&1.status == "passed")), do: "passed", else: "failed"
  end

  defp candidate_id(%EvalCampaignTarget{} = target) do
    target.metadata
    |> normalize_map()
    |> Map.get("candidate_id")
  end

  defp evidence_refs(candidate, trace, sample_reason) do
    candidate.evidence_refs
    |> normalize_map()
    |> Map.merge(%{
      "candidate_id" => candidate.id,
      "trace_id" => trace.id,
      "workflow_run_id" => candidate.workflow_run_id,
      "workflow_step_id" => candidate.workflow_step_id,
      "sample_reason" => sample_reason
    })
  end
end
