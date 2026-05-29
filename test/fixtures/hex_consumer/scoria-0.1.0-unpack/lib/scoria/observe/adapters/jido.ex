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
    span = %{
      name: "jido_action",
      span_kind: "INTERNAL",
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      attributes: %{
        "jido.action_name" => metadata[:action_name],
        "jido.status" => metadata[:status],
        "duration_ms" => measurements[:duration]
      }
    }
    
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end