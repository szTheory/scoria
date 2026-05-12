defmodule Scoria.SRE.Adapters.Parapet do
  @moduledoc """
  Translates Scoria telemetry envelopes into dependency-free Parapet-facing maps.
  """

  @label_keys [
    :identity_key,
    :tenant_id,
    :subject_kind,
    :reason_code,
    :severity,
    :policy_key,
    :window_bucket,
    :provider,
    :model,
    :tool_name,
    :integration_kind,
    :breaker_key,
    :state
  ]

  @ref_keys [:trace_id, :run_id, :workflow_run_id, :scorer_version, :baseline_version]

  def translate([:scoria, :sre, :sli, category], measurements, metadata) do
    %{
      metric: "scoria.sli.#{category}",
      category: category,
      value: metric_value(category, measurements),
      measurements: Map.new(measurements),
      labels: take_keys(metadata, @label_keys),
      refs: take_keys(metadata, @ref_keys)
    }
  end

  def translate([:scoria, :sre, :incident, :lifecycle], measurements, metadata) do
    %{
      metric: "scoria.incident.lifecycle",
      category: :incident_lifecycle,
      value: Map.get(measurements, :count, 1),
      measurements: Map.new(measurements),
      labels: take_keys(metadata, [:incident_key | @label_keys]),
      refs: take_keys(metadata, @ref_keys)
    }
  end

  defp metric_value(:tool_reliability, measurements), do: Map.get(measurements, :failure_count, 0)
  defp metric_value(:latency, measurements), do: Map.get(measurements, :duration_ms)
  defp metric_value(:cost, measurements), do: Map.get(measurements, :cost_usd)
  defp metric_value(:quality, measurements), do: Map.get(measurements, :score)
  defp metric_value(:budget_burn, measurements), do: Map.get(measurements, :burn_rate)
  defp metric_value(:breaker_state, measurements), do: Map.get(measurements, :trip_count)

  defp take_keys(metadata, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      case Map.fetch(metadata, key) do
        {:ok, value} -> Map.put(acc, key, value)
        :error -> acc
      end
    end)
  end
end
