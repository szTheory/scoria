defmodule Scoria.SRE.TelemetryIdentity do
  @moduledoc """
  Builds the canonical low-cardinality SRE identity contract.
  """

  @label_keys [
    :tenant_id,
    :subject_kind,
    :policy_key,
    :reason_code,
    :window_bucket,
    :provider,
    :model,
    :tool_name,
    :integration_kind,
    :breaker_key,
    :state,
    :severity
  ]

  @ref_keys [:trace_id, :run_id, :workflow_run_id, :scorer_version, :baseline_version]

  def labels(attrs) do
    attrs = normalize(attrs)

    @label_keys
    |> Enum.reduce(%{identity_key: build_identity_key(attrs)}, fn key, acc ->
      put_if_present(acc, key, Map.get(attrs, key))
    end)
  end

  def refs(attrs) do
    attrs = normalize(attrs)

    Enum.reduce(@ref_keys, %{}, fn key, acc ->
      put_if_present(acc, key, Map.get(attrs, key))
    end)
  end

  def runtime_metadata(attrs) do
    attrs
    |> normalize()
    |> build_metadata(false)
  end

  def incident_metadata(attrs) do
    attrs
    |> normalize()
    |> build_metadata(true)
  end

  def identity_key(attrs) do
    attrs
    |> normalize()
    |> build_identity_key()
  end

  defp build_metadata(attrs, include_incident_key?) do
    metadata =
      attrs
      |> labels()
      |> Map.merge(refs(attrs))

    if include_incident_key? do
      put_if_present(metadata, :incident_key, Map.get(attrs, :incident_key))
    else
      metadata
    end
  end

  defp build_identity_key(attrs) do
    [
      Map.get(attrs, :tenant_id, "system"),
      Map.get(attrs, :subject_kind, "workflow"),
      Map.get(attrs, :policy_key, "policy"),
      Map.get(attrs, :reason_code, "unknown"),
      Map.get(attrs, :window_bucket, "global"),
      Map.get(attrs, :provider),
      Map.get(attrs, :model),
      Map.get(attrs, :tool_name),
      Map.get(attrs, :integration_kind),
      Map.get(attrs, :breaker_key),
      Map.get(attrs, :state)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(":")
  end

  defp normalize(attrs) do
    attrs
    |> Map.new()
    |> Map.put_new_lazy(:run_id, fn -> Map.get(attrs, :workflow_run_id) end)
    |> Map.put_new(:tenant_id, "system")
    |> Map.put_new(:subject_kind, "workflow")
    |> Map.put_new(:policy_key, "policy")
    |> Map.put_new(:reason_code, "unknown")
    |> Map.put_new(:window_bucket, "global")
  end

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
