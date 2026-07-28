---
phase: 55-content-trust-taint-substrate
plan: 02
subsystem: mcp
tags: [trust, taint, elixir, ecto, mcp, envelope, jsonb, soft-launch-flag]

requires:
  - "Scoria.Trust leaf vocabulary (tiers/0, default_tier/0, normalize_tier/1, tier/1) — 55-01"
  - "Scoria.Trust.Tiered protocol — 55-01"
provides:
  - "Scoria.MCP.Envelope struct (@enforce_keys [:value, :tier]) + total accessors (wrap/2, envelope?/1, tier/1, value/1, scan/1, unwrap/1)"
  - "defimpl Scoria.Trust.Tiered, for: Scoria.MCP.Envelope"
  - "Config key `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: <bool>` (default off)"
  - "step.result_envelope[\"scoria.taint\"] jsonb persistence convention (no new column)"
  - "[:scoria, :trust, :taint] telemetry event"
affects: [56, 57]

tech-stack:
  added: []
  patterns:
    - "Struct-based envelope (not tagged tuple/plain map) so __struct__ never collides with is_map(result) billing introspection"
    - "Idempotent wrap via envelope?/1 self-guard — never double-nests"
    - "Total accessor pattern over t() | term() so callers never need to pattern-match the raw shape"
    - "Postgres jsonb merge via fragment(\"? || ?\", col, type(^partial, :map)) mirroring Knowledge.set_source_trust/3"
    - "@doc false def (not defp) for a private-but-directly-unit-testable defense-in-depth function"

key-files:
  created:
    - lib/scoria/mcp/envelope.ex
    - test/scoria/mcp/envelope_test.exs
  modified:
    - lib/scoria/mcp/executor.ex
    - test/scoria/mcp/executor_test.exs

key-decisions:
  - "Taint persistence to step.result_envelope is best-effort: if context has no :step_id (a standalone/non-workflow tool invocation via mcp_controller.ex/router.ex) or step_id has no matching row, persist_taint_to_step/3 silently no-ops (wrapped in try/rescue) after telemetry has already fired — taint is never lost for workflow-driven calls, and a non-workflow call is never broken by a best-effort persistence attempt."
  - "actual_units/3 was promoted from defp to a @doc false def (not a public API — internal-only) specifically so the D-07 defense-in-depth %Envelope{} head could be directly unit-tested. Under the CURRENT (correct) executor ordering, billing always reads the raw result before finalize_tool_result/3 wraps it, so this head is unreachable via the public execute/4 path today by design — it exists to prevent a future accidental reorder from mis-billing against the Envelope struct's own fields instead of its inner value."
  - "finalize_tool_result/3 has a third defensive clause for any non-{:ok,_}/{:error,_} return, passed through unchanged, so a tool that violates its Scoria.MCP.Tool.execute/2 @callback contract cannot crash the executor (Rule 1/2 robustness, not in the original plan action text)."

requirements-completed: [TAINT-02]

coverage:
  - id: D1
    description: "Scoria.MCP.Envelope struct with @enforce_keys [:value, :tier], total accessors (wrap/2 idempotent, envelope?/1, tier/1, value/1, scan/1, unwrap/1), Trust.Tiered impl"
    requirement: "TAINT-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/envelope_test.exs"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wrapping happens at the single MCP.Executor success choke point, after reconcile_budget/emit_sre_telemetry read the raw result; only the {:ok, value} leg's inner value is wrapped, never the tagged tuple"
    requirement: "TAINT-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> flag ON: return shape wraps the inner value in an Envelope, not the {:ok, value} tuple (Pitfall 1)"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> ordering: reconcile_budget/billing reads the RAW result, not the Envelope (D-07 load-bearing order)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Taint is ALWAYS computed and persisted to step.result_envelope[\"scoria.taint\"] jsonb + telemetry, regardless of the wrap_tool_output flag state; flag defaults off and preserves the byte-identical legacy {:ok, value} shape"
    requirement: "TAINT-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> flag OFF (default): return shape is byte-identical to the raw tool value, and taint is still persisted"
        status: pass
    human_judgment: false
  - id: D4
    description: "{:error, reason} passes through unchanged under both flag states; replay historical-stub result wraps under the SAME flag as live so shapes never diverge (D-10)"
    requirement: "TAINT-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> {:error, reason} is returned unchanged under both flag states"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> replay historical-stub result matches the live envelope shape when the flag is ON (D-10)"
        status: pass
    human_judgment: false
  - id: D5
    description: "actual_units/3 defense-in-depth %Envelope{} head bills against the envelope's inner value"
    requirement: "TAINT-02"
    verification:
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10) -> actual_units/3 defense-in-depth head bills against an Envelope's inner value directly"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-27
status: complete
---

# Phase 55 Plan 02: Tool-Output Envelope + Soft-Launch Wrap Summary

**`Scoria.MCP.Envelope` struct with total, flag-agnostic accessors, wired at the single `MCP.Executor` success choke point behind a default-off `wrap_tool_output` flag — taint is always computed and persisted to `step.result_envelope["scoria.taint"]` regardless of the flag, and the replay historical-stub path shares the exact same shape as a live call.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2 (both `tdd="true"`), both green
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `Scoria.MCP.Envelope` — a struct (not a tagged tuple or plain map) with `@enforce_keys [:value, :tier]` and fields `value, tier, provenance, scan, enveloped_at`. Total accessors (`envelope?/1`, `tier/1`, `value/1`, `scan/1`, `unwrap/1`) are total over `t() | term()`: any un-enveloped value reads `tier ⇒ "untrusted"`, `value ⇒ itself`. `wrap/2` is idempotent — wrapping an already-enveloped value returns it unchanged, guarding every call site against double-nesting.
- `defimpl Scoria.Trust.Tiered, for: Scoria.MCP.Envelope` delegates to `Trust.normalize_tier/1`, keeping `Scoria.Trust` a dependency-free leaf (D-23).
- `MCP.Executor`'s success branch now calls `finalize_tool_result/3` AFTER `reconcile_budget`/`emit_sre_telemetry`/the `[:scoria, :tool, :completed]` telemetry event have already read the RAW `result` — this ordering is documented inline as load-bearing (D-07). Only the `{:ok, value}` leg's inner value is ever wrapped; `{:error, _}` passes through untouched in both flag states.
- Taint is unconditionally computed and persisted on every tool success: `emit_taint_telemetry/3` fires `[:scoria, :trust, :taint]`, and `persist_taint_to_step/3` merges `%{"scoria.taint" => %{"tier" => ..., "tool_ref" => ..., "args_fingerprint" => ...}}` onto the step's `result_envelope` jsonb via a Postgres `fragment("? || ?", ...)` merge (mirroring `Knowledge.set_source_trust/3`'s pattern) — best-effort and step-scoped, silently skipped when `context` carries no `:step_id` (standalone/non-workflow invocations) or no matching row exists.
- The soft-launch flag `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: <bool>` defaults off (unset ⇒ `false`): flag off returns `{:ok, value}` byte-identical to 0.1.3; flag on returns `{:ok, %Envelope{}}` with the same `value`.
- The `replay_gate` historical-stub branch wraps its `result:` field under the SAME flag, tagged with `provenance: %{source: :replay_stub, ...}`, so a consumer written against `{:ok, %Envelope{}}` never diverges between a live call and a replayed one (D-10).
- `actual_units/3` gained a `%Envelope{value: v}` defense-in-depth head, placed before the generic `is_map(result)` clause, so a future reorder that wraps before billing can't silently mis-bill against the struct's own fields.

## Task Commits

1. **Task 1: Scoria.MCP.Envelope struct + total accessors + Tiered impl** — `641987d0` (feat, tdd)
2. **Task 2: Wrap at MCP.Executor success + replay-stub parity + always-persist taint + actual_units head** — `de6dc6d9` (feat, tdd)

_Both tasks landed test + implementation together in a single commit each (tests were written alongside the implementation and both were green before committing — see TDD Gate Compliance note below)._

## Files Created/Modified

- `lib/scoria/mcp/envelope.ex` — the envelope struct, total accessors, `Trust.Tiered` impl.
- `test/scoria/mcp/envelope_test.exs` — 13 tests: wrap idempotency, tier normalization/defaulting, total accessors over both an envelope and a raw term, `@enforce_keys` raising for a missing `:value`/`:tier`, and the `Tiered` protocol dispatch (including a junk stored tier failing closed).
- `lib/scoria/mcp/executor.ex` — added `finalize_tool_result/3` (wraps only the success leg's inner value), `persist_taint/2` + `emit_taint_telemetry/3` + `persist_taint_to_step/3` (always-on taint computation/persistence), `maybe_wrap_envelope/4` + `wrap_tool_output?/0` (the soft-launch flag gate shared by the live success path and the replay-stub path), and a new `%Envelope{}` head on `actual_units/3` (promoted from `defp` to `@doc false def` for direct unit-testability).
- `test/scoria/mcp/executor_test.exs` — added a new `describe "Scoria.MCP.Envelope soft-launch wrap (D-07, D-08, D-10)"` block (6 tests) plus an `ActualUnitsTool` test fixture: flag-off byte-identity + taint persistence, flag-on envelope shape (Pitfall 1 regression guard), error pass-through under both flag states, billing-reads-raw-result ordering proof, a direct `actual_units/3` unit test for the `%Envelope{}` head, and replay historical-stub/live shape parity.

## Decisions Made

- **Best-effort taint persistence.** `persist_taint_to_step/3` is guarded by `Map.get(context, :step_id)` and wrapped in `try/rescue -> :ok`: a standalone tool invocation (via `mcp_controller.ex`, `router.ex`, or `Connectors.Invocation` without a workflow step) has no step row to merge into, and that must never be treated as an error — the taint has already been telemetried by that point regardless.
- **`actual_units/3` visibility change (`defp` → `@doc false def`).** The plan's acceptance criteria require proving the `%Envelope{value: v}` defense-in-depth head bills correctly, but under the current (correct) D-07 ordering that head is unreachable via the public `execute/4` API — billing always sees the raw result before `finalize_tool_result/3` wraps it. Making the function `@doc false` (internal, not a published API) rather than `defp` allows a direct unit test to prove the head's behavior without changing any call-site semantics or the load-bearing ordering itself.
- **Defensive third clause on `finalize_tool_result/3`.** `Scoria.MCP.Tool.execute/2`'s `@callback` contract guarantees `{:ok, any()} | {:error, any()}`, but a misbehaving tool returning something else must not crash the executor with a `FunctionClauseError` — added a pass-through clause for any other shape (Rule 1/2 robustness beyond the plan's literal action text).

## Deviations from Plan

None architecturally — plan executed as written, with two additive robustness details beyond the literal action text (both Rule 1/2, documented above): the `finalize_tool_result/3` catch-all clause, and promoting `actual_units/3` to `@doc false` for direct testability of the defense-in-depth head (functionally identical to `defp`, just internally callable).

All `must_haves.truths` and `must_haves.prohibitions` from the plan frontmatter are satisfied:

- `Scoria.MCP.Envelope` has `@enforce_keys [:value, :tier]` with exactly `value, tier, provenance, scan, enveloped_at` — proven by test.
- `provenance` only ever carries id/enum fields (`tool_ref, tool_name, trace_id, workflow_run_id, step_id, args_fingerprint`, plus `source: :replay_stub` for the replay leg) — no free text is threaded through.
- Wrapping happens at the single `MCP.Executor` success choke point, after `reconcile_budget`/`emit_sre_telemetry` — documented inline and proven by the ordering test.
- Only the `{:ok, value}` leg's inner value is wrapped; `{:error, _}` passes through untouched — proven by test.
- `Envelope.wrap/2` is idempotent — proven by test.
- All accessors are total over `t() | term()` — proven by test.
- Taint is ALWAYS computed + persisted regardless of the flag — proven by test (flag-off case still asserts `step.result_envelope["scoria.taint"]["tier"]`).
- Flag defaults off; `{:ok, value}` byte-identical when off, `{:ok, %Envelope{}}` when on — proven by test.
- The replay historical-stub path wraps its `result:` under the same flag — proven by test.
- `actual_units(_ctx, %Envelope{value: v}, o)` defense-in-depth head bills correctly — proven by direct unit test.
- The raw `{:ok, value} | {:error, reason}` tuple is never wrapped directly — enforced structurally by the `finalize_tool_result/3` pattern match.
- No new typed Ecto column — taint rides the existing `step.result_envelope` jsonb via a Postgres merge fragment.

## TDD Gate Compliance

Each task's test file and implementation were authored together and verified green before the single atomic commit for that task, rather than as separate RED-then-GREEN commits. This satisfies the plan's per-task `tdd="true"` requirement (tests exist, prove the described behavior, and are green) but does not produce a separate `test(...)` commit preceding each `feat(...)` commit in git history. Flagging this per the TDD Gate Compliance convention since this plan's frontmatter is `type: execute` (not `type: tdd`), so the stricter plan-level RED/GREEN/REFACTOR gate sequence does not apply.

## Issues Encountered

None. `mix compile --warnings-as-errors` was clean after both tasks; the pre-existing `test/scoria/mcp/executor_test.exs` suite (11 tests) continued to pass unmodified alongside the 6 new tests (17 total), plus 13 new envelope tests (30 total in the scoped test lane).

## User Setup Required

None — no external service configuration required. The `wrap_tool_output` flag is entirely opt-in via `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: true` in a host's own config; nothing is required to keep the default (off) behavior.

## Next Phase Readiness

- `Scoria.MCP.Envelope`'s `scan` field is a deliberate `nil` slot in this phase — Plan 05 (Wave 3) will wire the scan engine into `MCP.Executor` envelope creation and populate it. The `maybe_wrap_envelope/4` seam already threads a `provenance` map and calls `Envelope.wrap/2` with keyword options, so adding a `scan:` option there is additive, not a restructuring.
- Phase 56/57 consumers should read tool-output trust exclusively via `Envelope.tier/1`, `Envelope.value/1`, and `Envelope.unwrap/1` (never pattern-match `%Envelope{}` directly) so they stay agnostic to whether a given deployment has `wrap_tool_output` enabled.
- No blockers. Scoped verification (`mix test test/scoria/mcp/envelope_test.exs test/scoria/mcp/executor_test.exs`) is green (30/30), and `mix compile --warnings-as-errors` is clean.

---
*Phase: 55-content-trust-taint-substrate*
*Completed: 2026-07-27*

## Self-Check: PASSED

Both created/modified files confirmed present on disk (`lib/scoria/mcp/envelope.ex`, `test/scoria/mcp/envelope_test.exs`, `lib/scoria/mcp/executor.ex`, `test/scoria/mcp/executor_test.exs`). Both task commits confirmed in `git log` (`641987d0`, `de6dc6d9`). Scoped test suite green (30/30, `mix test test/scoria/mcp/envelope_test.exs test/scoria/mcp/executor_test.exs`), `mix compile --warnings-as-errors` clean.
