defmodule Scoria.Observe.Telemetry do
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Redactor
  alias Scoria.Observe.ReviewerBroadcast

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

  @doc """
  Emits a span delta telemetry event for streaming token chunks.

  Future ReqLLM streaming adapters should call this instead of raw
  `:telemetry.execute/3`. Integration tests must use this for delta proof
  (not raw `:telemetry.execute` on `[:scoria, :observe, :span, :delta]`).
  """
  def emit_span_delta(metadata) when is_map(metadata) do
    :telemetry.execute([:scoria, :observe, :span, :delta], %{}, metadata)
  end

  def handle_event([:scoria, :observe, :span, :delta], _measurements, metadata, _config) do
    redacted =
      metadata
      |> Redactor.redact()
      |> scrub_delta_chunk()

    ReviewerBroadcast.span_delta(redacted)
  end

  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
        buffer_name: buffer_name
      }) do
    redacted = Redactor.redact(metadata)
    ReviewerBroadcast.span_stopped(redacted)
    Buffer.cast_span(buffer_span(redacted), buffer_name)
  end

  @span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a

  defp buffer_span(redacted) do
    Map.take(redacted, @span_buffer_fields)
  end

  defp scrub_delta_chunk(%{chunk: chunk} = metadata) when is_binary(chunk) do
    Map.put(metadata, :chunk, Redactor.scrub_text(chunk))
  end

  defp scrub_delta_chunk(metadata), do: metadata
end
