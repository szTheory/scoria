defmodule Scoria.Observe.Telemetry do
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.OperatorBroadcast
  alias Scoria.Observe.Redactor

  @events [
    [:scoria, :observe, :span, :stop],
    [:scoria, :observe, :span, :delta]
  ]

  def attach(buffer_name \\ Buffer) do
    :telemetry.attach_many(
      "scoria-observe-telemetry",
      @events,
      &__MODULE__.handle_event/4,
      %{buffer_name: buffer_name}
    )
  end

  def handle_event([:scoria, :observe, :span, :delta], _measurements, metadata, _config) do
    OperatorBroadcast.span_delta(metadata)
  end

  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
        buffer_name: buffer_name
      }) do
    redacted = Redactor.redact(metadata)
    OperatorBroadcast.span_stopped(redacted)
    Buffer.cast_span(buffer_span(redacted), buffer_name)
  end

  @span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a

  defp buffer_span(redacted) do
    Map.take(redacted, @span_buffer_fields)
  end
end
