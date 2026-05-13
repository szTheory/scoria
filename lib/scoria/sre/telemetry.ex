defmodule Scoria.SRE.Telemetry do
  @moduledoc """
  Public Phase 7 telemetry helpers for SLI and breaker evidence.
  """

  alias Scoria.SRE.TelemetryIdentity

  @runtime_prefix [:scoria, :sre, :runtime]
  @incident_prefix [:scoria, :sre, :incident]

  def emit_latency(attrs), do: emit(:latency, attrs, [:duration_ms, :threshold_ms])
  def emit_cost(attrs), do: emit(:cost, attrs, [:cost_usd, :budget_usd, :token_count])
  def emit_quality(attrs), do: emit(:quality, attrs, [:score, :threshold])
  def emit_budget_burn(attrs), do: emit(:budget_burn, attrs, [:burn_rate, :budget_remaining, :threshold])
  def emit_breaker_state(attrs), do: emit(:breaker_state, attrs, [:trip_count, :threshold])

  def emit_tool_reliability(attrs) do
    attrs = Map.new(attrs)

    measurements =
      attrs
      |> take_measurements([:duration_ms])
      |> Map.put(:success_count, if(Map.get(attrs, :success, true), do: 1, else: 0))
      |> Map.put(:failure_count, if(Map.get(attrs, :success, true), do: 0, else: 1))

    :telemetry.execute(@runtime_prefix ++ [:tool_reliability], measurements, TelemetryIdentity.runtime_metadata(attrs))
    :ok
  end

  def emit_incident_lifecycle(category, attrs) when is_atom(category) do
    attrs = Map.new(attrs)

    measurements =
      attrs
      |> take_measurements([:delivery_count, :measured_value, :threshold_value])
      |> Map.put_new(:count, 1)

    :telemetry.execute(@incident_prefix ++ [category], measurements, TelemetryIdentity.incident_metadata(attrs))
    :ok
  end

  defp emit(kind, attrs, measurement_keys) do
    attrs = Map.new(attrs)
    :telemetry.execute(
      @runtime_prefix ++ [kind],
      take_measurements(attrs, measurement_keys),
      TelemetryIdentity.runtime_metadata(attrs)
    )

    :ok
  end

  defp take_measurements(attrs, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      case Map.fetch(attrs, key) do
        {:ok, value} -> Map.put(acc, key, value)
        :error -> acc
      end
    end)
  end

end
