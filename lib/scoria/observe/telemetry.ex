defmodule Scoria.Observe.Telemetry do
  alias Scoria.Observe.Bounds
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

  @doc """
  Emits a buffer flush-error telemetry event for non-fatal persistence failures.

  `Scoria.Observe.Buffer` calls this instead of raw `:telemetry.execute/3`.
  Integration tests must use this for flush-error proof (not raw
  `:telemetry.execute` on `[:scoria, :observe, :buffer, :flush_error]`).

  Expects a map carrying `:dropped_count`, `:buffer`, `:max_size`, `:kind`,
  `:error`, and `:stacktrace`. Counts + error identity only -- never include
  raw span `entries`/`attributes` (may carry prompt content).
  """
  def emit_flush_error(metadata) when is_map(metadata) do
    measurements = %{
      dropped_count: Map.get(metadata, :dropped_count, 0),
      system_time: System.system_time()
    }

    :telemetry.execute([:scoria, :observe, :buffer, :flush_error], measurements, metadata)
  end

  def handle_event([:scoria, :observe, :span, :delta], _measurements, metadata, _config) do
    redacted =
      metadata
      |> Redactor.redact()
      |> scrub_delta_chunk()
      |> cap_delta_chunk()

    ReviewerBroadcast.span_delta(redacted)
  end

  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
        buffer_name: buffer_name
      }) do
    redacted = Redactor.redact(metadata)

    case Bounds.enforce(redacted, :span) do
      {:ok, bounded} ->
        ReviewerBroadcast.span_stopped(bounded)
        Buffer.cast_span(buffer_span(bounded), buffer_name)

      :drop ->
        :ok
    end
  end

  @span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a

  defp buffer_span(bounded) do
    Map.take(bounded, @span_buffer_fields)
  end

  defp scrub_delta_chunk(%{chunk: chunk} = metadata) when is_binary(chunk) do
    Map.put(metadata, :chunk, Redactor.scrub_text(chunk))
  end

  defp scrub_delta_chunk(metadata), do: metadata

  # Delta persistence stays out of scope (verified absent -- the delta arm
  # only broadcasts, there is no Buffer.cast_span/2 on it), but EGRESS is
  # in scope (T-53-03): cap the streaming chunk before it reaches the
  # operator's browser via ReviewerBroadcast.span_delta/1.
  defp cap_delta_chunk(%{chunk: chunk} = metadata) when is_binary(chunk) do
    max_bytes = Bounds.max_delta_chunk_bytes()

    if byte_size(chunk) > max_bytes do
      Map.put(metadata, :chunk, binary_part(chunk, 0, max_bytes) <> "…[TRUNCATED]")
    else
      metadata
    end
  end

  defp cap_delta_chunk(metadata), do: metadata
end
