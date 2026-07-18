defmodule Scoria.Observe.Telemetry do
  require Logger

  alias Scoria.Observe.Bounds
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Redactor
  alias Scoria.Observe.ReviewerBroadcast
  alias Scoria.Observe.Semconv

  @events [
    [:scoria, :observe, :span, :stop],
    [:scoria, :observe, :span, :delta],
    [:scoria, :observe, :event, :emit]
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
      |> redact()
      |> scrub_delta_chunk()
      |> cap_delta_chunk()

    ReviewerBroadcast.span_delta(redacted)
  end

  def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
        buffer_name: buffer_name
      }) do
    redacted = redact(metadata)

    case Bounds.enforce(redacted, :span) do
      {:ok, bounded} ->
        ReviewerBroadcast.span_stopped(bounded)
        Buffer.cast_span(buffer_span(bounded), buffer_name)

      :drop ->
        :ok
    end
  end

  # The [:scoria, :observe, :event, :emit] handler is the boundary of
  # record (D-03b/D-05/D-06) -- the ONLY gate that matters, because a raw
  # `:telemetry.execute([:scoria, :observe, :event, :emit], ...)` call can
  # always bypass `Scoria.Observe.emit_event/1`'s up-front check. Order
  # matters: (1) independently re-check the allow-list -- never trust that
  # emit_event/1 already checked it; (2) redact through the single shared
  # `redact/1` call site; (3) the fail-closed seam -- default a missing/nil
  # OR type-invalid `time` to `DateTime.utc_now()`, and drop (never persist)
  # a `nil` OR non-UUID-castable `span_id` BEFORE Bounds, since both are
  # NOT NULL columns and a type-invalid (not just nil) value would otherwise
  # reach `Buffer.cast_event/2` -> `Repo.insert_all` and raise, poisoning the
  # whole co-flushed batch (CR-01); (4) Bounds.enforce(_, :event) -- the same
  # {:ok, _} | :drop contract as :span; (5) cast to the Buffer's fixed-key
  # event projection.
  def handle_event([:scoria, :observe, :event, :emit], _measurements, metadata, %{
        buffer_name: buffer_name
      }) do
    name = Map.get(metadata, :name)

    if Semconv.event_name?(name) do
      metadata
      |> redact()
      |> default_time()
      |> reject_if_nil_span_id(name)
      |> case do
        {:reject, reason} ->
          reject_event(name, reason)

        {:ok, safe} ->
          case Bounds.enforce(safe, :event) do
            {:ok, bounded} -> Buffer.cast_event(buffer_event(bounded), buffer_name)
            :drop -> reject_event(name, :bounds)
          end
      end
    else
      reject_event(name, :unknown_name)
    end
  end

  @span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a

  defp buffer_span(bounded) do
    Map.take(bounded, @span_buffer_fields)
  end

  @event_buffer_fields ~w(span_id name time attributes)a

  # `ai_span_events.name` is a :string column (`Scoria.Repo.SpanEvent`) but
  # `Semconv.event_names/0` is an ATOM vocabulary (D-03a) -- `name` arrives
  # here as an atom via `metadata[:name]`. `Buffer.cast_event/2` feeds
  # straight into `Repo.insert_all/2`, which bypasses changeset casting
  # entirely, so an un-stringified atom would raise a type-mismatch at
  # flush time instead of persisting. Stringify here, at the single fixed-
  # key projection, rather than at every call site.
  defp buffer_event(bounded) do
    bounded
    |> Map.take(@event_buffer_fields)
    |> Map.update(:name, nil, &to_string/1)
  end

  # The single collapsed redaction call site (D-03d) -- span, delta, and
  # event handler clauses all route through this one function, so exactly
  # one Redactor.redact/1 call remains in this file.
  defp redact(metadata), do: Redactor.redact(metadata)

  # Defaults a missing, present-but-nil, OR type-invalid `:time` to
  # `DateTime.utc_now()` (D-05a, CR-01). Only a real `%DateTime{}` survives
  # unchanged -- `ai_span_events.time` is `:utc_datetime_usec` and NOT NULL,
  # so a string/integer timestamp (e.g. `System.system_time()`) would
  # otherwise clear this seam untouched and raise `Ecto.ChangeError` at
  # `Repo.insert_all/2`, poisoning the whole co-flushed batch.
  defp default_time(metadata) do
    case Map.get(metadata, :time) do
      %DateTime{} = time -> Map.put(metadata, :time, time)
      _invalid -> Map.put(metadata, :time, DateTime.utc_now())
    end
  end

  # A nil OR non-UUID-castable span_id is dropped BEFORE Bounds.enforce/2
  # (D-05a, CR-01) -- span_id is `:binary_id` and NOT NULL on
  # ai_span_events, so letting a `""`/`"not-a-uuid"`/non-binary value reach
  # Buffer.cast_event/2 would raise `Ecto.ChangeError` at flush time instead
  # of failing closed here. `Ecto.UUID.cast/1` is the same well-formedness
  # check the schema's `:binary_id` type applies, so this seam and the
  # column type agree by construction.
  defp reject_if_nil_span_id(metadata, _name) do
    case Map.get(metadata, :span_id) do
      nil ->
        {:reject, :nil_span_id}

      span_id when is_binary(span_id) ->
        case Ecto.UUID.cast(span_id) do
          {:ok, _} -> {:ok, metadata}
          :error -> {:reject, :invalid_span_id}
        end

      _non_binary ->
        {:reject, :invalid_span_id}
    end
  end

  # Never persists a rejected event (D-03e). The telemetry emit is
  # UNCONDITIONAL every time; the Logger.warning is deduped once per
  # distinct event name per node via the same lazy-create ETS
  # :ets.insert_new idiom ReviewerBroadcast/Bounds already use.
  @rejected_warned_table :scoria_observe_event_rejected_warned_names

  defp reject_event(name, reason) do
    :telemetry.execute([:scoria, :observe, :event, :rejected], %{}, %{
      name: name,
      reason: reason
    })

    if first_warning_for_rejected_name?(name) do
      Logger.warning(
        "Scoria.Observe.Telemetry rejected event #{inspect(name)} (reason=#{inspect(reason)}) -- " <>
          "if this is a real event name, edit Semconv @event_names"
      )
    end

    :ok
  end

  defp first_warning_for_rejected_name?(name) do
    ensure_rejected_warned_table()
    :ets.insert_new(@rejected_warned_table, {name, true})
  end

  defp ensure_rejected_warned_table do
    case :ets.whereis(@rejected_warned_table) do
      :undefined ->
        :ets.new(@rejected_warned_table, [:named_table, :set, :public, read_concurrency: true])

      _table ->
        :ok
    end
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
