defmodule Scoria.Observe.Telemetry do
  alias Scoria.Observe.Redactor
  alias Scoria.Observe.Buffer

  @events [
    [:scoria, :observe, :span, :stop]
  ]

  def attach(buffer_name \\ Buffer) do
    :telemetry.attach_many(
      "scoria-observe-telemetry",
      @events,
      &__MODULE__.handle_event/4,
      %{buffer_name: buffer_name}
    )
  end

  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{buffer_name: buffer_name}) do
    redacted_metadata = Redactor.redact(metadata)
    Buffer.cast_span(redacted_metadata, buffer_name)
  end
end