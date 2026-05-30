defmodule Scoria.Observe.Adapters.Jido do
  def attach do
    :telemetry.attach_many(
      "scoria-observe-jido",
      [[:jido, :action, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:jido, :action, :stop], measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    attributes =
      %{
        "jido.action_name" => metadata[:action_name],
        "jido.status" => metadata[:status],
        "duration_ms" => measurements[:duration],
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    span = %{
      name: "jido_action",
      span_kind: "INTERNAL",
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      parent_id: metadata[:parent_id],
      tenant_id: tenant_id,
      workflow_run_id: workflow_run_id,
      session_id: metadata[:session_id],
      attributes: attributes
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end
