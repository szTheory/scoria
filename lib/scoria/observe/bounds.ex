defmodule Scoria.Observe.Bounds do
  @moduledoc """
  The single write-time choke point every span/event attribute payload
  passes through (SEC-01, D-06a). Enforces the closed key registry plan
  53-02 built (`Semconv.attribute_registry/0`), plus size/count/depth caps,
  and fails closed on any input it cannot make sense of.

  **Placement.** `Scoria.Observe.Telemetry.handle_event/4` calls
  `enforce/2` immediately after `Redactor.redact/1` and BEFORE both
  `ReviewerBroadcast.span_stopped/1` and `Buffer.cast_span/2` (D-06a). A
  `:drop` result short-circuits BOTH sinks -- a dropped span reaches
  neither the operator's browser nor Postgres.

  Deliberately NOT part of `Scoria.Observe.Redactor`: `Redactor`'s `:mfa`
  config hook replaces redaction wholesale, so a bound living there would
  be silently removable by adopter config. SEC-01's promise is to the
  ADOPTER'S END USERS, not to the adopter.

  **The guarantee is the registry, not the size cap.** A size bound alone
  does not stop raw text -- a 200-byte completion fits any cap. Only
  closing the key space is structural (D-06b). Admission runs three tiers,
  in order:

    1. **Registry exact match** -- `Semconv.attribute_registry/0`.
       Admitted, bounded per its class.
    2. **Vendor prefixes** -- `Semconv.vendor_key_prefixes/0` (`gen_ai.`,
       `server.`, `openai.`, `req_llm.`, `error.`). Admitted as a bounded
       scalar UNLESS the key is in `Semconv.denied_exact_keys/0` or any of
       its dot-segments equals a member of `Semconv.denied_key_segments/0`.
    3. **Host prefixes** -- `config :scoria, #{inspect(__MODULE__)},
       allowed_key_prefixes: [...]` (default `[]`).

  `scoria.`, `openinference.`, `jido.`, and ALL bare keys are
  REGISTRY-ONLY -- there is no prefix escape into Scoria's own namespaces.
  A Scoria developer therefore cannot persist a new key without editing
  `Semconv.attribute_registry/0`, and that edit trips the registry canary
  test. That is the SEC-01 guarantee: two deliberate red-test edits between
  an unbounded attribute assignment and an adopter's Postgres.

  **Segment matching** splits a candidate key on `"."` and compares
  dot-segments for EXACT equality against `Semconv.denied_key_segments/0`
  -- never a substring-containment check, never a whole-key regex.
  Substring matching would drop `args_fingerprint` (it contains `args`)
  and kill the field the MCP tool span relies on to avoid persisting raw
  tool arguments (D-06c-2, D-04b).

  **Violation behavior (D-06e):**

    - unregistered / denied key -> DROP the key (never truncated -- a
      256-byte prefix of a leaked prompt is still a leaked prompt).
    - oversized ADMITTED value -> truncate to `max_attribute_bytes` plus a
      `…[TRUNCATED]` suffix.
    - over-count -> drop beyond `max_attribute_count`, in deterministic
      sorted-key order.
    - over the flat `max_total_bytes` budget -> evict admitted keys (in
      the same deterministic sorted-key order) until under budget.

  Markers are written back into the bounded attribute map (themselves
  registry keys, from `Semconv.bounds_marker_keys/0`):
  `scoria.attributes.dropped` (integer count), `scoria.attributes.dropped_keys`
  (at most 10 names, each capped at 64 bytes), `scoria.attributes.truncated_keys`.
  OTel only records a COUNT of dropped attributes; shipping the NAMES is
  strictly better operator UX. Residual: a host that puts PII in a key
  NAME leaks it here -- the 10-name / 64-byte cap bounds the blast radius.

  **No disable switch.** Limits tune upward only; raising a byte cap never
  relaxes key admission.

  **Performance.** No JSON-encoding call on the hot path -- `enforce/2` runs
  synchronously in the caller's process on EVERY span. Byte accounting is
  approximate, computed during the same recursive traversal that applies
  the bound (sum of `byte_size/1` over binary leaves plus a small constant
  per container). The exact serialized-size assertion lives in the test
  suite, not in production.

  **Observability (D-06f).** Any drop/truncate emits
  `[:scoria, :observe, :bounds, :exceeded]` with measurements
  (`dropped_count`, `truncated_count`) and metadata (`reason`, `keys`,
  `kind`) -- the SEC-01 counterpart of `[:scoria, :observe, :buffer,
  :flush_error]`, so an SRE can alert on "my instrumentation is trying to
  log prompts." The emit is wrapped `try/rescue -> :ok`. A `Logger.warning`
  is deduped once per distinct dropped/denied key per node via
  `:ets.insert_new/2` against a `:scoria_observe_bounds_warned_keys` named
  table (mirrors `ReviewerBroadcast`'s once-per-trace dedupe idiom).

  **D-06j -- never an SRE metric dimension.** `reason_code`, `subject_ref`,
  `policy_key`, or any decision id must NEVER be placed on an SRE metric
  dimension. `Scoria.SRE.Telemetry` already emits guardrail-adjacent
  metrics carrying `policy_key`/`trace_id`/`run_id`/`actor_id`. OTel's
  Metrics SDK has a default cardinality limit of 2000 and on overflow
  SILENTLY folds into a synthetic overflow bucket -- dashboards start
  lying rather than erroring. These fields belong on the durable span
  attribute only, never on a metric dimension.

  **D-06i -- the `:event` clause.** `enforce(metadata, :event)` is built
  and unit-tested in this phase; it applies the identical registry
  admission as `:span`. It is activated (given a real caller) in Phase
  53b, alongside `emit_event/1`.
  """

  require Logger

  alias Scoria.Observe.Semconv

  @truncated_suffix "…[TRUNCATED]"
  @warned_table :scoria_observe_bounds_warned_keys

  @defaults [
    max_attribute_bytes: 256,
    max_attribute_count: 128,
    max_depth: 5,
    max_list_length: 100,
    max_total_bytes: 16_384,
    max_delta_chunk_bytes: 2_048,
    allowed_key_prefixes: [],
    capture_error_messages: false
  ]

  @doc """
  Enforces the closed key registry plus size/count/depth caps on
  `metadata[:attributes]`, leaving every other top-level key of `metadata`
  (`:id`, `:trace_id`, `:name`, `:span_kind`, `:tenant_id`, etc.)
  completely untouched -- `Bounds` only touches the `attributes` sub-map's
  key space, never the structural span/event fields
  `Scoria.Observe.Telemetry`'s `@span_buffer_fields` whitelist governs.

  Returns `{:ok, bounded_metadata}` on success, or `:drop` when `metadata`
  itself is not a usable map (fail-closed, D-06h) -- this can legitimately
  happen because `Redactor.redact/1`'s `:mfa` config hook has no
  return-type contract and MAY return a non-map.

  `enforce/2` never raises: the whole body is wrapped `try/rescue -> :drop`
  so a bug here can never crash the caller's synchronous telemetry
  handler. An enforcement point that can be crashed into silence is not an
  enforcement point.
  """
  @spec enforce(term(), :span | :event) :: {:ok, map()} | :drop
  def enforce(metadata, kind) when kind in [:span, :event] do
    do_enforce(metadata, kind)
  rescue
    _ -> fail_closed(kind, :exception)
  end

  defp do_enforce(metadata, kind) when is_map(metadata) and not is_struct(metadata) do
    case Map.get(metadata, :attributes) do
      nil ->
        {:ok, metadata}

      attrs when is_map(attrs) and not is_struct(attrs) ->
        opts = config()
        {bounded_attrs, stats} = bound_attributes(attrs, opts)
        maybe_report_exceeded(stats, kind)
        {:ok, Map.put(metadata, :attributes, bounded_attrs)}

      _not_a_map ->
        fail_closed(kind, :attributes_not_a_map)
    end
  end

  defp do_enforce(_metadata, kind), do: fail_closed(kind, :not_a_map)

  @doc """
  Returns the configured `max_delta_chunk_bytes` cap (default `2_048`).
  `Scoria.Observe.Telemetry`'s delta arm uses this to cap streaming chunk
  egress -- delta persistence stays out of scope (verified absent: the
  delta arm only broadcasts, there is no `Buffer.cast_span/2` on it), but
  EGRESS is in scope (T-53-03).
  """
  @spec max_delta_chunk_bytes() :: pos_integer()
  def max_delta_chunk_bytes, do: config().max_delta_chunk_bytes

  defp config do
    configured = Application.get_env(:scoria, __MODULE__, [])
    @defaults |> Keyword.merge(configured) |> Map.new()
  end

  defp fail_closed(kind, reason) do
    safe_emit_exceeded(%{dropped_count: 1, truncated_count: 0}, %{
      reason: reason,
      keys: [],
      kind: kind
    })

    Logger.warning(
      "Scoria.Observe.Bounds.enforce/2 failed closed (kind=#{kind}, reason=#{inspect(reason)})"
    )

    :drop
  end

  # -- attribute-map bounding ------------------------------------------

  defp bound_attributes(attrs, opts) do
    {admitted, denied_keys} =
      Enum.reduce(attrs, {[], []}, fn {key, value}, {acc, denied} ->
        case classify_key(key, opts) do
          :ok -> {[{key, value} | acc], denied}
          :denied -> {acc, [key | denied]}
        end
      end)

    sorted_admitted = Enum.sort_by(admitted, fn {key, _value} -> key end)
    {kept, overflow} = Enum.split(sorted_admitted, opts.max_attribute_count)
    overflow_keys = Enum.map(overflow, fn {key, _value} -> key end)

    {bounded_pairs, truncated_keys} =
      Enum.reduce(kept, {%{}, []}, fn {key, value}, {acc, trunc_keys} ->
        {new_value, truncated?} = bound_value(value, 0, opts)
        trunc_keys = if truncated?, do: [key | trunc_keys], else: trunc_keys
        {Map.put(acc, key, new_value), trunc_keys}
      end)

    {bounded_pairs, budget_evicted_keys} = evict_over_budget(bounded_pairs, opts.max_total_bytes)

    all_dropped_keys = Enum.sort(denied_keys ++ overflow_keys ++ budget_evicted_keys)
    sorted_truncated_keys = Enum.sort(truncated_keys)

    final =
      bounded_pairs
      |> put_dropped_marker(length(all_dropped_keys))
      |> put_dropped_keys_marker(all_dropped_keys)
      |> put_truncated_keys_marker(sorted_truncated_keys)

    stats = %{
      dropped_count: length(all_dropped_keys),
      truncated_count: length(sorted_truncated_keys),
      dropped_keys: all_dropped_keys
    }

    {final, stats}
  end

  defp classify_key(key, opts) do
    cond do
      Map.has_key?(Semconv.attribute_registry(), key) -> :ok
      vendor_admitted?(key) -> :ok
      host_admitted?(key, opts) -> :ok
      true -> :denied
    end
  end

  defp vendor_admitted?(key) do
    Enum.any?(Semconv.vendor_key_prefixes(), &String.starts_with?(key, &1)) and
      key not in Semconv.denied_exact_keys() and
      not denied_segment?(key)
  end

  # Split on "." and compare dot-SEGMENTS for exact equality -- never a
  # substring-containment check, never a whole-key regex (D-06c-2).
  defp denied_segment?(key) do
    key
    |> String.split(".")
    |> Enum.any?(&(&1 in Semconv.denied_key_segments()))
  end

  defp host_admitted?(key, opts) do
    Enum.any?(opts.allowed_key_prefixes, &String.starts_with?(key, &1))
  end

  # Recursively bounds a value (scalar or nested), returning
  # `{new_value, truncated?}`. `depth` is 0 for the attribute's own value.
  defp bound_value(_value, depth, opts) when depth > opts.max_depth do
    {"[SCORIA_BOUNDS_DEPTH_EXCEEDED]", true}
  end

  defp bound_value(value, _depth, opts) when is_binary(value) do
    if byte_size(value) > opts.max_attribute_bytes do
      truncated = binary_part(value, 0, opts.max_attribute_bytes) <> @truncated_suffix
      {truncated, true}
    else
      {value, false}
    end
  end

  defp bound_value(value, depth, opts) when is_list(value) do
    capped = Enum.take(value, opts.max_list_length)
    {items, flags} = capped |> Enum.map(&bound_value(&1, depth + 1, opts)) |> Enum.unzip()
    truncated? = Enum.any?(flags) or length(value) > opts.max_list_length
    {items, truncated?}
  end

  defp bound_value(value, depth, opts) when is_map(value) and not is_struct(value) do
    {pairs, flags} =
      value
      |> Enum.map(fn {k, v} ->
        {new_v, trunc?} = bound_value(v, depth + 1, opts)
        {{k, new_v}, trunc?}
      end)
      |> Enum.unzip()

    {Map.new(pairs), Enum.any?(flags)}
  end

  defp bound_value(value, _depth, _opts), do: {value, false}

  defp approx_size(value) when is_binary(value), do: byte_size(value)

  defp approx_size(value)
       when is_integer(value) or is_float(value) or is_boolean(value) or is_nil(value),
       do: 8

  defp approx_size(value) when is_list(value) do
    Enum.reduce(value, 8, fn item, acc -> acc + approx_size(item) end)
  end

  defp approx_size(value) when is_map(value) and not is_struct(value) do
    Enum.reduce(value, 8, fn {k, v}, acc -> acc + approx_size(k) + approx_size(v) end)
  end

  defp approx_size(_value), do: 8

  defp evict_over_budget(attrs, max_total_bytes) do
    if approx_total_bytes(attrs) <= max_total_bytes do
      {attrs, []}
    else
      do_evict(attrs, max_total_bytes, [])
    end
  end

  defp do_evict(attrs, max_total_bytes, evicted) do
    if map_size(attrs) == 0 or approx_total_bytes(attrs) <= max_total_bytes do
      {attrs, evicted}
    else
      last_key = attrs |> Map.keys() |> Enum.sort() |> List.last()
      do_evict(Map.delete(attrs, last_key), max_total_bytes, [last_key | evicted])
    end
  end

  defp approx_total_bytes(attrs) do
    Enum.reduce(attrs, 0, fn {k, v}, acc -> acc + byte_size(k) + approx_size(v) end)
  end

  defp put_dropped_marker(attrs, 0), do: attrs

  defp put_dropped_marker(attrs, count),
    do: Map.put(attrs, Semconv.bounds_marker_keys().dropped, count)

  defp put_dropped_keys_marker(attrs, []), do: attrs

  defp put_dropped_keys_marker(attrs, keys) do
    sample = keys |> Enum.take(10) |> Enum.map(&cap_marker_name/1)
    Map.put(attrs, Semconv.bounds_marker_keys().dropped_keys, sample)
  end

  defp put_truncated_keys_marker(attrs, []), do: attrs

  defp put_truncated_keys_marker(attrs, keys) do
    sample = Enum.map(keys, &cap_marker_name/1)
    Map.put(attrs, Semconv.bounds_marker_keys().truncated_keys, sample)
  end

  defp cap_marker_name(key) do
    if byte_size(key) > 64, do: binary_part(key, 0, 64), else: key
  end

  # -- observability (D-06f) -------------------------------------------

  defp maybe_report_exceeded(%{dropped_count: 0, truncated_count: 0}, _kind), do: :ok

  defp maybe_report_exceeded(stats, kind) do
    log_once(stats.dropped_keys)

    safe_emit_exceeded(
      %{dropped_count: stats.dropped_count, truncated_count: stats.truncated_count},
      %{reason: :bound_exceeded, keys: stats.dropped_keys, kind: kind}
    )
  end

  defp safe_emit_exceeded(measurements, metadata) do
    :telemetry.execute([:scoria, :observe, :bounds, :exceeded], measurements, metadata)
  rescue
    _ -> :ok
  end

  defp log_once(keys) do
    Enum.each(keys, fn key ->
      if first_warning_for_key?(key) do
        Logger.warning(
          "Scoria.Observe.Bounds dropped unregistered/denied attribute key #{inspect(key)}"
        )
      end
    end)
  end

  defp first_warning_for_key?(key) do
    ensure_warned_table()
    :ets.insert_new(@warned_table, {key, true})
  end

  defp ensure_warned_table do
    case :ets.whereis(@warned_table) do
      :undefined -> :ets.new(@warned_table, [:named_table, :set, :public, read_concurrency: true])
      _table -> :ok
    end
  end
end
