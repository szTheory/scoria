defmodule ScoriaWeb.IncidentCopy do
  @moduledoc """
  Operator-facing copy for incidents, branching on incident severity/status.

  Templated on `ScoriaWeb.ApprovalCopy` (D-24c) — pure functions returning
  strings only, zero `~H`. Every branch has a safe `_ ->` fallback so an
  unseen severity/status never raises inside `render/1`.
  """

  def orientation(nil), do: "Incident details not available."

  def orientation(incident) do
    status = status_label(field(incident, :status))

    case field(incident, :severity) do
      "critical" ->
        "Critical incident #{String.downcase(status)} — investigate immediately."

      "warning" ->
        "Warning incident #{String.downcase(status)} — review when able."

      severity when is_binary(severity) ->
        "#{severity_label(severity)} incident #{String.downcase(status)}."

      _ ->
        "Incident #{String.downcase(status)}."
    end
  end

  def severity_label(nil), do: "Severity not recorded"

  def severity_label(severity) when is_binary(severity) do
    case severity do
      "critical" -> "Critical"
      "warning" -> "Warning"
      "info" -> "Info"
      other -> humanize(other)
    end
  end

  def severity_label(_severity), do: "Severity not recorded"

  def status_label(nil), do: "Status not recorded"

  def status_label(status) when is_binary(status) do
    case status do
      "open" -> "Open"
      "acknowledged" -> "Acknowledged"
      "resolved" -> "Resolved"
      "closed" -> "Closed"
      other -> humanize(other)
    end
  end

  def status_label(_status), do: "Status not recorded"

  def field(nil, _key), do: nil

  def field(record, key) when is_map(record),
    do: Map.get(record, key) || Map.get(record, Atom.to_string(key))

  def field(_record, _key), do: nil

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()
end
