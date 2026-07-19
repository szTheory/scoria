---
phase: 53-structured-child-spans-write-time-bound
plan: 05
subsystem: observability
tags: [elixir, otp, telemetry, mcp, security, ecto]

# Dependency graph
requires:
  - phase: 53-01
    provides: "Scoria.Observe.Buffer supervised child, Scoria.Observe.Telemetry.attach/1 at boot, observe_children/0 seam"
  - phase: 53-02
    provides: "Semconv.attribute_registry/0 closed key registry, merge_host_declared/2, openinference_span_kind_key/0"
provides:
  - "Scoria.Observe.Adapters.MCP -- attach/0 + handle_event/4 turning [:scoria, :tool, :started|:completed|:timeout|:failed] into duration- and failure-bearing TOOL child spans"
  - "Live production producer for SC#1's tool leg (Scoria.MCP.Executor's telemetry had no listener before this plan)"
  - "Scoria.Application boots the MCP adapter (handler id \"scoria-observe-mcp\") alongside Scoria.Observe.Telemetry"
affects: [53-06, 53-07, 53-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PROJECT-not-merge telemetry metadata: read exactly N named fields into span attributes, never Map.merge the raw metadata map (D-04b)"
    - "args_fingerprint via :erlang.phash2 as the house rule for never-persist-raw-args (mirrors Scoria.SRE.AuditOutboxEvent.args_fingerprint and executor.ex's existing budget-reservation hash)"
    - "Terminal-event-only span emission: a lifecycle's :started event is a no-op handler clause because a span needs a duration and there is none yet"

key-files:
  created:
    - lib/scoria/observe/adapters/mcp.ex
    - test/scoria/observe/adapters/mcp_test.exs
  modified:
    - lib/scoria/application.ex

key-decisions:
  - "emit_tool_span/4 writes tenant_id/workflow_run_id/session_id into attributes (in addition to top-level on the span map) per the plan's explicit D-00c/D-01e instruction for this adapter -- broader than req_llm.ex/jido.ex's sibling adapters, which only include tenant_id/workflow_run_id in attributes."
  - "metadata[:reason] (the raw failure term on :failed) is never read by the adapter at all -- not redacted, not fingerprinted, simply absent from the five-field projection. The closed status enum (completed/timeout/failed) is the entire failure vocabulary the span carries."
  - "Duration-based start_time back-dating (DateTime.add(now, -duration_ms, :millisecond)) gives the span a real width in the trace tree instead of a zero-width bar, matching the pattern documented in 53-PATTERNS.md for this adapter."

requirements-completed: [EVENT-01, SEC-01]

coverage:
  - id: D1
    description: "Scoria.Observe.Adapters.MCP consumes the 4-event MCP tool lifecycle and produces duration-bearing TOOL spans; :completed -> OK, :timeout/:failed -> ERROR with a real duration"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/adapters/mcp_test.exs#Test 1/2/3"
        status: pass
    human_judgment: false
  - id: D2
    description: "A :started event alone produces no persisted span (a span needs a duration and there is none yet)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/adapters/mcp_test.exs#Test 4"
        status: pass
    human_judgment: false
  - id: D3
    description: "Raw tool args and the raw failure term never reach persisted attributes; args_fingerprint (erlang.phash2) is present instead, stable for identical args and discriminating for different args"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/adapters/mcp_test.exs#Test 5/6/7"
        status: pass
    human_judgment: false
  - id: D4
    description: "trace_id/parent_id/tenant_id from metadata are read explicitly (D-02a); parent_id persists on the span and tenant_id lands in attributes"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/adapters/mcp_test.exs#Test 8"
        status: pass
    human_judgment: false
  - id: D5
    description: "Scoria.Application boots Adapters.MCP.attach/0 (idempotent, tolerates {:error, :already_exists}), giving SC#1's tool leg a live production producer"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/adapters/mcp_test.exs#Test 9"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 05: MCP Tool Adapter Summary

**`Scoria.Observe.Adapters.MCP` turns the 4-event `[:scoria, :tool, :*]` lifecycle `Scoria.MCP.Executor` already emits into duration- and failure-bearing TOOL child spans, giving SC#1's `tool` leg a live production producer while projecting only `tool_ref`/`tool_name`/`status`/`duration_ms`/`args_fingerprint` -- never the raw tool args or the raw failure term.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-13T13:44:13-04:00 (approx, base commit)
- **Completed:** 2026-07-13T14:02:04-04:00
- **Tasks:** 2 (TDD RED/GREEN)
- **Files modified:** 3

## Accomplishments

- `Scoria.Observe.Adapters.MCP.attach/0` registers `:telemetry.attach_many/4` under `"scoria-observe-mcp"` against all four `[:scoria, :tool, :*]` events, distinct from `"scoria-observe-telemetry"` so the two attach/detach lifecycles never collide.
- `:started` produces no span (no duration exists yet); `:completed` -> `status_code: "OK"`; `:timeout`/`:failed` -> `status_code: "ERROR"`, all with a real millisecond duration derived from the terminal event's `%{duration: duration}` measurement.
- PROJECTS the executor's telemetry metadata onto exactly five named attribute fields (`tool_ref`, `tool_name`, `status`, `duration_ms`, `args_fingerprint`) and never spreads the raw metadata map -- `Scoria.MCP.Executor` merges raw tool `args` into that metadata (`executor.ex:37`) and puts a raw failure term on `:failed` (`:63`, `:69`); neither reaches a persisted span. `args_fingerprint` is `Integer.to_string(:erlang.phash2(metadata[:args]))`, mirroring the house rule already followed by `Scoria.SRE.AuditOutboxEvent.args_fingerprint` (a column with no sibling `args` column).
- `trace_id`/`parent_id` are read explicitly only (D-02a, with a last-resort fresh-id fallback documented as producing an orphan trace); `tenant_id`/`workflow_run_id`/`session_id` are written both top-level on the span map and into attributes.
- `Scoria.Application.observe_children/0` now also attaches the MCP adapter right after `Scoria.Observe.Telemetry.attach/0`, inside the same `enabled: false`-gated block 53-01 established, with the same match-and-ignore `{:error, :already_exists}` discipline (T-53-08).

## Task Commits

Each task was committed atomically (TDD RED then GREEN):

1. **Task 1: Wave-0 test -- the 4-event MCP lifecycle produces child spans; args are fingerprinted, never persisted** - `db205415` (test, RED)
2. **Task 2: Implement Scoria.Observe.Adapters.MCP and attach it on boot** - `275ed5f1` (feat, GREEN)

**Plan metadata:** pending (this SUMMARY commit)

## Files Created/Modified

- `test/scoria/observe/adapters/mcp_test.exs` - 9 behaviors driving REAL `[:scoria, :tool, :*]` events through the real adapter -> span-stop -> Buffer -> Postgres pipeline (D-ATTR01-6, no hand-synthesized span-stop event)
- `lib/scoria/observe/adapters/mcp.ex` - `Scoria.Observe.Adapters.MCP`, modeled on `Scoria.Observe.Adapters.ReqLLM`
- `lib/scoria/application.ex` - `safe_attach_observe_mcp/0` added to `observe_children/0`

## Decisions Made

- Included `session_id` in the projected attributes (in addition to top-level on the span map), per the plan's explicit instruction for this adapter -- the sibling `req_llm.ex`/`jido.ex` adapters only carry `tenant_id`/`workflow_run_id` in attributes.
- `metadata[:reason]` (the raw failure term) is never read by the adapter at all, not even for redaction -- the closed `status` enum is the entire failure vocabulary this span carries, per the plan's explicit prohibition.
- Start-time back-dated from the terminal event's duration (`DateTime.add(now, -duration_ms, :millisecond)`) so the span has a real width in the trace tree rather than a zero-width bar.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Worktree had no `deps`/`_build` for this Elixir project.** Symlinked `deps/` from the sibling main-repo checkout (`mix.lock` verified byte-identical via `diff`) to avoid a redundant network fetch, ran `mix deps.get`/`mix compile` to build a worktree-local `_build/test`. The symlink is removed before returning; no `deps`/`_build` artifacts were staged or committed (both gitignored).
- **Full-suite `mix test --warnings-as-errors` showed transient failures from concurrent sibling worktree agents sharing that same symlinked `deps`/`mix.lock`.** A full-suite run mid-session reported 13 failures, all traced to either (a) `mix scoria.install*` tests spawning a subprocess `mix` invocation that hit a `lock mismatch` error because a sibling worktree agent was mid-`mix deps.get` on the shared symlink target at that exact moment, or (b) the pre-existing `Scoria.WarningInventory.CaptureParityTest` subprocess-warning-capture flake already documented in 53-01's SUMMARY. Re-ran `mix deps.get` to resync the lock, then re-ran the plan-scoped lane (`mcp_test.exs` + `application_test.exs` + `test/scoria/mcp/`, 46 tests) clean with 0 failures. None of the 13 failures touched this plan's files (`lib/scoria/observe/adapters/mcp.ex`, `lib/scoria/application.ex`, or any `test/scoria/observe/` or `test/scoria/mcp/` file). Not fixed (out of scope, pre-existing/environmental, matches the documented SEED-004 test-code-determinism debt class).
- `examples/support_copilot/deps/**/_build/prod/lib/.rebar3/rebar_compiler_erl/source.dag` vendored rebar3 compiler caches were dirtied by concurrent test-suite compilation (unrelated to this plan's file scope) and restored via `git checkout --` before finishing, per the worktree hygiene requirement.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

SC#1's `tool` leg now has a live production producer end-to-end: `Scoria.MCP.Executor`'s existing telemetry lifecycle flows through `Adapters.MCP` into real TOOL child spans persisted to Postgres, with `Scoria.Application` attaching it automatically on boot. Plan 53-08 (workflow-runtime `trace_id`/`parent_id` threading) can now rely on this adapter reading those fields explicitly from MCP call context metadata rather than falling back to an orphan trace. No blockers for 53-06/53-07/53-08.

## Self-Check: PASSED

- FOUND: lib/scoria/observe/adapters/mcp.ex
- FOUND: test/scoria/observe/adapters/mcp_test.exs
- FOUND: lib/scoria/application.ex
- FOUND commit: db205415 (test, RED)
- FOUND commit: 275ed5f1 (feat, GREEN)

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*
