defmodule ScoriaWeb.DatasetCopy do
  @moduledoc """
  Operator-facing copy for datasets, branching on dataset state (`:open`/`:sealed`).

  Templated on `ScoriaWeb.ApprovalCopy` (D-24c) — pure functions returning
  strings only, zero `~H`. Every branch has a safe `_ ->` fallback so an
  unseen state never raises inside `render/1`.
  """

  def orientation(nil), do: "Dataset details not available."

  def orientation(dataset) do
    case state_value(field(dataset, :state)) do
      "open" ->
        "Open dataset — can still accept promoted examples from reviews and runs."

      "sealed" ->
        "Sealed dataset — ready to anchor evals or baseline approval requests."

      other when is_binary(other) ->
        "#{state_label(other)} dataset."

      _ ->
        "Dataset state not recorded."
    end
  end

  def state_label(nil), do: "State not recorded"

  def state_label(state) do
    case state_value(state) do
      "open" -> "Open"
      "sealed" -> "Sealed"
      other when is_binary(other) -> humanize(other)
      _ -> "State not recorded"
    end
  end

  def version_label(dataset) do
    case field(dataset, :version) do
      version when is_binary(version) and version != "" -> "v#{version}"
      _ -> "No version recorded"
    end
  end

  def field(nil, _key), do: nil

  def field(record, key) when is_map(record),
    do: Map.get(record, key) || Map.get(record, Atom.to_string(key))

  def field(_record, _key), do: nil

  defp state_value(state) when is_atom(state) and not is_nil(state), do: Atom.to_string(state)
  defp state_value(state) when is_binary(state), do: state
  defp state_value(_state), do: nil

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()
end
