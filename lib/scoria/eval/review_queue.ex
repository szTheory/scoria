defmodule Scoria.Eval.ReviewQueue do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Scoria.Eval
  alias Scoria.Eval.DatasetPromotion
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Workflows.Run

  @default_filters %{
    review_status: "pending"
  }

  def list_candidates(filters \\ %{}) do
    filters = normalize_filters(filters)

    OnlineScoreCandidate
    |> apply_filters(filters)
    |> order_by([candidate], asc: candidate.inserted_at, asc: candidate.id)
    |> Repo.all()
    |> Enum.map(&project_summary/1)
    |> sort_rows()
  end

  def summary(filters \\ %{}) do
    rows = list_candidates(filters)

    %{
      total_flagged: length(rows),
      low_quality_count: Enum.count(rows, &(&1.severity == "low_quality")),
      policy_triggered_count: Enum.count(rows, &(&1.severity == "policy_triggered")),
      promotion_candidate_count: Enum.count(rows, &(&1.status == "promotion_candidate"))
    }
  end

  def get_candidate(nil), do: nil

  def get_candidate(candidate_id) do
    case Repo.get(OnlineScoreCandidate, candidate_id) do
      nil -> nil
      candidate -> project_detail(candidate)
    end
  end

  def dismiss_candidate(candidate_id) do
    candidate = Repo.get!(OnlineScoreCandidate, candidate_id)

    candidate
    |> OnlineScoreCandidate.changeset(%{
      status: "dismissed",
      review_status: "dismissed",
      reviewed_at: now()
    })
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, project_detail(updated)}
      error -> error
    end
  end

  def promote_candidate(candidate_id, attrs) when is_map(attrs) do
    candidate = Repo.get!(OnlineScoreCandidate, candidate_id)
    detail = project_detail(candidate)
    dataset_id = attrs["dataset_id"] || attrs[:dataset_id]
    notes = attrs["notes"] || attrs[:notes] || ""
    expected_output = attrs["expected_output"] || attrs[:expected_output] || %{}

    promotion_attrs =
      DatasetPromotion.build_promotion_attrs(
        detail.promotion_context,
        dataset_id,
        notes,
        expected_output
      )

    with {:ok, item} <- Eval.promote_workflow_source(promotion_attrs),
         {:ok, updated} <- mark_promoted(candidate, item) do
      {:ok, project_detail(updated)}
    end
  end

  def request_baseline_approval(candidate_id, attrs) when is_map(attrs) do
    candidate = Repo.get!(OnlineScoreCandidate, candidate_id)
    detail = project_detail(candidate)
    dataset_id = attrs["dataset_id"] || attrs[:dataset_id]
    notes = attrs["notes"] || attrs[:notes] || ""
    expected_output = attrs["expected_output"] || attrs[:expected_output] || %{}

    request_attrs =
      DatasetPromotion.build_promotion_attrs(
        detail.promotion_context,
        dataset_id,
        notes,
        expected_output
      )

    with {:ok, approval} <- Scoria.Workflows.request_baseline_promotion(request_attrs),
         {:ok, updated} <- mark_approval_requested(candidate, approval) do
      {:ok, project_detail(updated)}
    end
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {_key, nil}, query ->
        query

      {:review_status, nil}, query ->
        where(query, [candidate], candidate.review_status not in ["dismissed", "promoted"])

      {:review_status, review_status}, query ->
        where(query, [candidate], candidate.review_status == ^review_status)

      {:severity, severity}, query ->
        severity_statuses = severity_statuses(severity)

        where(query, [candidate], candidate.status in ^severity_statuses)

      {:scorer_kind, scorer_kind}, query ->
        where(query, [candidate], candidate.scorer_kind == ^scorer_kind)

      {:promotion_state, promotion_state}, query ->
        where(query, [candidate], candidate.status == ^promotion_state)

      {_key, _value}, query ->
        query
    end)
  end

  defp normalize_filters(filters) when is_map(filters) do
    filters
    |> Enum.reduce(@default_filters, fn
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_atom(key), blank_to_nil(value))
      {key, value}, acc -> Map.put(acc, key, blank_to_nil(value))
    end)
  rescue
    ArgumentError -> @default_filters
  end

  defp normalize_filters(_filters), do: @default_filters

  defp project_summary(candidate) do
    run = Repo.get(Run, candidate.workflow_run_id)
    severity = severity(candidate)
    sample_reason = map_value(candidate.sampling_metadata, "sample_reason")

    %{
      id: candidate.id,
      status: candidate.status,
      review_status: candidate.review_status,
      severity: severity,
      score: candidate.score,
      score_status: candidate.score_status,
      rationale: candidate.score_explanation,
      scorer_kind: candidate.scorer_kind,
      scorer_version: candidate.scorer_version,
      sample_reason: sample_reason,
      trace_id: candidate.trace_id,
      workflow_run_id: candidate.workflow_run_id,
      workflow_step_id: candidate.workflow_step_id,
      runtime_id: run && run.session_id,
      workflow_path: "/scoria/workflows/#{candidate.workflow_run_id}?review_candidate_id=#{candidate.id}",
      runtime_path: runtime_path(run && run.session_id, candidate.id),
      inserted_at: candidate.inserted_at,
      promotion_state: candidate.status,
      dataset_ref: promoted_dataset_ref(candidate)
    }
  end

  defp project_detail(candidate) do
    run = Repo.get(Run, candidate.workflow_run_id)
    approval = find_approval(candidate)

    %{
      id: candidate.id,
      status: candidate.status,
      review_status: candidate.review_status,
      severity: severity(candidate),
      score: candidate.score,
      score_status: candidate.score_status,
      rationale: candidate.score_explanation,
      scorer_kind: candidate.scorer_kind,
      scorer_version: candidate.scorer_version,
      judge_model: candidate.judge_model,
      rubric_version: candidate.rubric_version,
      trace_id: candidate.trace_id,
      workflow_run_id: candidate.workflow_run_id,
      workflow_step_id: candidate.workflow_step_id,
      runtime_id: run && run.session_id,
      workflow_path: "/scoria/workflows/#{candidate.workflow_run_id}?review_candidate_id=#{candidate.id}",
      runtime_path: runtime_path(run && run.session_id, candidate.id),
      sampling_provenance: candidate.sampling_metadata || %{},
      evidence_refs: candidate.evidence_refs || %{},
      promotion_snapshot: candidate.promotion_snapshot || %{},
      promotion_context: build_promotion_context(candidate, run),
      dataset_ref: promoted_dataset_ref(candidate),
      approval_lineage: approval && %{
        id: approval.id,
        status: approval.status,
        tool_name: approval.tool_name
      },
      inserted_at: candidate.inserted_at
    }
  end

  defp build_promotion_context(candidate, run) do
    source_variant = map_value(candidate.promotion_snapshot, "source_variant") || "original"
    replay_reason_code = map_value(candidate.promotion_snapshot, "replay_reason_code")
    replay_disposition = if(run && run.execution_mode == "replay", do: "blocked", else: nil)

    %{
      workflow_run_id: candidate.workflow_run_id,
      workflow_step_id: candidate.workflow_step_id,
      source_variant: source_variant,
      provenance: %{
        workflow_run_id: candidate.workflow_run_id,
        workflow_step_id: candidate.workflow_step_id,
        source_variant: source_variant,
        execution_mode: run && run.execution_mode || "live",
        source_run_id: run && run.source_run_id,
        source_checkpoint_id: run && run.source_checkpoint_id,
        replay_disposition: replay_disposition,
        replay_reason_code: replay_reason_code
      },
      checkpoint_output: %{
        "projected_context" => %{"review_candidate_id" => candidate.id},
        "recorded_outcome" => map_value(candidate.promotion_snapshot, "recorded_outcome")
      },
      safety: %{
        "replay_scope" => if(run && run.execution_mode == "replay", do: "replay_live", else: nil),
        "replay_disposition" => replay_disposition,
        "replay_reason_code" => replay_reason_code
      },
      promotion_snapshot: candidate.promotion_snapshot || %{},
      notes: "",
      expected_output: %{}
    }
  end

  defp sort_rows(rows) do
    Enum.sort_by(rows, fn row ->
      {severity_rank(row.severity), DateTime.to_unix(row.inserted_at, :microsecond), row.id}
    end)
  end

  defp severity(%OnlineScoreCandidate{} = candidate) do
    cond do
      map_value(candidate.sampling_metadata, "sample_reason") == "policy_trigger" -> "policy_triggered"
      candidate.status == "promotion_candidate" -> "promotion_candidate"
      candidate.score_status == "failed" or candidate.status == "needs_review" -> "low_quality"
      true -> "needs_review"
    end
  end

  defp severity_rank("policy_triggered"), do: 0
  defp severity_rank("low_quality"), do: 1
  defp severity_rank("promotion_candidate"), do: 2
  defp severity_rank(_severity), do: 3

  defp severity_statuses("policy_triggered"), do: ["needs_review"]
  defp severity_statuses("low_quality"), do: ["needs_review"]
  defp severity_statuses("promotion_candidate"), do: ["promotion_candidate"]
  defp severity_statuses(_severity), do: ["queued", "needs_review", "promotion_candidate", "approval_requested"]

  defp promoted_dataset_ref(candidate) do
    metadata = candidate.metadata || %{}

    case map_value(metadata, "promoted_dataset") do
      %{} = dataset -> dataset
      _ -> nil
    end
  end

  defp mark_promoted(candidate, item) do
    dataset = Eval.get_dataset!(item.dataset_id)
    metadata = (candidate.metadata || %{}) |> normalize_map()

    candidate
    |> OnlineScoreCandidate.changeset(%{
      status: "promoted",
      review_status: "promoted",
      promoted_at: now(),
      reviewed_at: now(),
      metadata:
        Map.put(metadata, "promoted_dataset", %{
          "dataset_id" => dataset.id,
          "dataset_name" => dataset.name,
          "dataset_version" => dataset.version,
          "dataset_item_id" => item.id
        })
    })
    |> Repo.update()
  end

  defp mark_approval_requested(candidate, approval) do
    metadata = (candidate.metadata || %{}) |> normalize_map()

    candidate
    |> OnlineScoreCandidate.changeset(%{
      status: "approval_requested",
      review_status: "in_review",
      reviewed_at: now(),
      metadata: Map.put(metadata, "approval_id", approval.id)
    })
    |> Repo.update()
  end

  defp find_approval(candidate) do
    Repo.one(
      from(approval in Approval,
        where:
          approval.workflow_run_id == ^candidate.workflow_run_id and
            approval.step_id == ^candidate.workflow_step_id and
            approval.tool_name == "dataset_baseline_promotion",
        order_by: [desc: approval.inserted_at, desc: approval.id],
        limit: 1
      )
    )
  end

  defp runtime_path(nil, candidate_id), do: "/scoria?review_candidate_id=#{candidate_id}"
  defp runtime_path(runtime_id, candidate_id), do: "/scoria?runtime=#{runtime_id}&review_candidate_id=#{candidate_id}"

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp map_value(map, key) when is_map(map) do
    Map.get(map, key, Map.get(map, String.to_atom(key), nil))
  rescue
    ArgumentError -> Map.get(map, key)
  end

  defp map_value(_map, _key), do: nil

  defp normalize_map(nil), do: %{}

  defp normalize_map(value) when is_map(value) do
    Map.new(value, fn {key, nested} ->
      {to_string(key), if(is_map(nested), do: normalize_map(nested), else: nested)}
    end)
  end

  defp normalize_map(_value), do: %{}

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
