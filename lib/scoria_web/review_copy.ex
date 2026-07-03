defmodule ScoriaWeb.ReviewCopy do
  @moduledoc """
  Operator-facing copy for the eval review queue, branching on review-candidate
  status/severity.

  Templated on `ScoriaWeb.ApprovalCopy` (D-24c) — pure functions returning
  strings only, zero `~H`. Every branch has a safe `_ ->` fallback so an
  unseen status/severity never raises inside `render/1`.

  `status_label/1` is the operator label for the review row status atom
  (`Scoria.Eval.OnlineScoreCandidate.status`), replacing the raw atom rendered
  at `review_queue_live.ex` (D-23).
  """

  def status_label(nil), do: "Status not recorded"

  def status_label(status) do
    case status_value(status) do
      "queued" -> "Queued"
      "scored" -> "Scored"
      "needs_review" -> "Needs review"
      "promotion_candidate" -> "Promotion candidate"
      "approval_requested" -> "Approval requested"
      "reviewing" -> "Reviewing"
      "promoted" -> "Promoted"
      "dismissed" -> "Dismissed"
      "superseded" -> "Superseded"
      other when is_binary(other) -> humanize(other)
      _ -> "Status not recorded"
    end
  end

  def review_status_label(nil), do: "Review state not recorded"

  def review_status_label(review_status) do
    case status_value(review_status) do
      "pending" -> "Needs review"
      "in_review" -> "In review"
      "approved" -> "Approved"
      "dismissed" -> "Dismissed"
      "promoted" -> "Promoted"
      other when is_binary(other) -> humanize(other)
      _ -> "Review state not recorded"
    end
  end

  def severity_label(nil), do: "Severity not recorded"

  def severity_label(candidate) do
    case status_value(field(candidate, :severity) || candidate) do
      "policy_triggered" -> "Policy triggered"
      "low_quality" -> "Low quality"
      "promotion_candidate" -> "Promotion candidate"
      other when is_binary(other) -> humanize(other)
      _ -> "Severity not recorded"
    end
  end

  def field(nil, _key), do: nil

  def field(record, key) when is_map(record),
    do: Map.get(record, key) || Map.get(record, Atom.to_string(key))

  def field(_record, _key), do: nil

  defp status_value(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp status_value(value) when is_binary(value), do: value
  defp status_value(_value), do: nil

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()
end
