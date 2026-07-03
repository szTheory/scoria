defmodule ScoriaWeb.ConnectorCopy do
  @moduledoc """
  Operator-facing copy for connectors and runtime presence, branching on
  connector/runtime status.

  Templated on `ScoriaWeb.ApprovalCopy` (D-24c) — pure functions returning
  strings only, zero `~H`. Every branch has a safe `_ ->` fallback so an
  unseen status never raises inside `render/1`.

  `runtime_status_label/1` is the operator label for a connector runtime
  status (`Scoria.Runtime`'s `online`/`offline` presence), replacing the raw
  `runtime.status` string rendered at `connectors_live/index.ex` (D-23/D-26).
  """

  def runtime_status_label(nil), do: "Status not recorded"

  def runtime_status_label(status) do
    case status_value(status) do
      "online" -> "Connected"
      "offline" -> "Disconnected"
      "idle" -> "Idle"
      other when is_binary(other) -> humanize(other)
      _ -> "Status not recorded"
    end
  end

  def status_label(nil), do: "Status not recorded"

  def status_label(connector) do
    case status_value(field(connector, :status) || connector) do
      "registered" -> "Registered"
      "discovering" -> "Discovering"
      "ready" -> "Ready"
      "degraded" -> "Degraded"
      "disabled" -> "Disabled"
      "error" -> "Error"
      other when is_binary(other) -> humanize(other)
      _ -> "Status not recorded"
    end
  end

  def health_label(nil), do: "Health not recorded"

  def health_label(connector) do
    case status_value(field(connector, :health_state) || connector) do
      "unknown" -> "Unknown"
      "healthy" -> "Healthy"
      "degraded" -> "Degraded"
      "failing" -> "Failing"
      "unreachable" -> "Unreachable"
      other when is_binary(other) -> humanize(other)
      _ -> "Health not recorded"
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
