defmodule Scoria.Observe.Adapters.MCP do
  @moduledoc """
  Telemetry adapter that turns `Scoria.MCP.Executor`'s
  `[:scoria, :tool, :started | :completed | :timeout | :failed]` four-event
  tool lifecycle into duration- and failure-bearing TOOL child spans (SC#1's
  `tool` leg, D-04a). Gives the tool leg a live production producer --
  `Scoria.MCP.Executor` already emits this lifecycle and nothing listened
  to it before this adapter.

  Terminal events only. `:started` carries no duration and produces no
  span -- a span needs a duration and there is none yet. `:completed`,
  `:timeout`, and `:failed` each carry `%{duration: duration}` and are
  independently mapped to a `status_code` (`"OK"` for `:completed`,
  `"ERROR"` for `:timeout`/`:failed`, SC#3).

  PROJECTS the executor's telemetry metadata onto exactly five named
  fields; it never spreads that metadata map wholesale (D-04b).
  `Scoria.MCP.Executor` merges the RAW tool argument values into that
  metadata (`executor.ex:37`) and puts a RAW failure term on the `:failed`
  event (`:63`, `:69`). This adapter reads:

    * `"tool_ref"` -- `metadata[:tool_ref]` (the executor already sets it)
    * `"tool_name"` -- derived from the tool module (low-cardinality,
      enum-like)
    * `"status"` -- the closed value `"completed"` / `"timeout"` /
      `"failed"`
    * `"duration_ms"` -- the millisecond conversion of the terminal
      event's `%{duration: duration}` measurement
    * `"args_fingerprint"` -- `:erlang.phash2(metadata[:args])`, never the
      args themselves. Mirrors the house rule already followed by
      `Scoria.SRE.AuditOutboxEvent.args_fingerprint` (a column with no
      sibling `args` column) and the existing `executor.ex:228`
      `:erlang.phash2` budget-reservation hash.

  `metadata[:reason]` (the raw failure term on `:failed`) is NEVER read.
  It is an arbitrary Elixir term that can embed anything the tool touched
  -- the closed `status` enum is the entire failure vocabulary this span
  carries.

  If `metadata[:trace_id]` is absent, a fresh id is minted as a
  last-resort fallback -- this produces an ORPHAN single-span trace, not
  the intended path. Plan 53-08 threads the real `trace_id` from the
  workflow runtime into the MCP call context.
  """

  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  @doc """
  Attaches the four-event MCP tool lifecycle handler under its own handler
  id (`"scoria-observe-mcp"`), distinct from `"scoria-observe-telemetry"`
  so the two attach/detach lifecycles never collide.
  """
  @spec attach() :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.attach_many(
      "scoria-observe-mcp",
      [
        [:scoria, :tool, :started],
        [:scoria, :tool, :completed],
        [:scoria, :tool, :timeout],
        [:scoria, :tool, :failed]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  # A span needs a duration and there is none yet on :started -- the
  # terminal events all carry %{duration: duration}.
  def handle_event([:scoria, :tool, :started], _measurements, _metadata, _config), do: :ok

  def handle_event([:scoria, :tool, :completed], measurements, metadata, _config) do
    emit_tool_span("completed", "OK", measurements, metadata)
  end

  def handle_event([:scoria, :tool, :timeout], measurements, metadata, _config) do
    emit_tool_span("timeout", "ERROR", measurements, metadata)
  end

  def handle_event([:scoria, :tool, :failed], measurements, metadata, _config) do
    emit_tool_span("failed", "ERROR", measurements, metadata)
  end

  defp emit_tool_span(status, status_code, measurements, metadata) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]
    session_id = metadata[:session_id]
    duration_ms = System.convert_time_unit(measurements[:duration] || 0, :native, :millisecond)

    span_kind = SpanKind.normalize("mcp")

    attributes =
      %{
        "tool_ref" => metadata[:tool_ref],
        "tool_name" => tool_name(metadata[:tool]),
        "status" => status,
        "duration_ms" => duration_ms,
        "args_fingerprint" => Integer.to_string(:erlang.phash2(metadata[:args])),
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id,
        "session_id" => session_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))
      |> Semconv.merge_host_declared(metadata)

    now = DateTime.utc_now()

    span = %{
      id: Ecto.UUID.generate(),
      name: "mcp_tool_call",
      span_kind: span_kind,
      status_code: status_code,
      start_time: DateTime.add(now, -duration_ms, :millisecond),
      end_time: now,
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      parent_id: metadata[:parent_id],
      tenant_id: tenant_id,
      workflow_run_id: workflow_run_id,
      session_id: session_id,
      attributes: attributes
    }

    try do
      :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
    rescue
      _ -> :ok
    end

    :ok
  end

  defp tool_name(nil), do: nil
  defp tool_name(tool_module), do: inspect(tool_module)
end
