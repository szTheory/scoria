---
phase: 53-structured-child-spans-write-time-bound
plan: 03
subsystem: observability
tags: [elixir, telemetry, otel-genai, openinference, error-handling]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    plan: "53-01"
    provides: "Scoria.Observe.Buffer boot wiring + Scoria.Observe.Telemetry.attach/1 at boot"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "53-02"
    provides: "Semconv.attribute_registry/0 closed registry, Semconv.error_attributes/1 type-only exception projection"
provides:
  - "Scoria.Observe.span/4 -- the single transparent span primitive every producer in plans 53-05/53-07/53-08 funnels through"
  - "Scoria.Observe.with_tool/3, with_prompt/3, with_guardrail/3 -- thin kind wrappers over span/4"
  - "Scoria.Observe.trace_id_for_run/1 -- a run IS a trace (D-03a)"
  - "emit_retriever_span/1 and emit_prompt_span/1 refactored onto the shared span-map builder, now double-writing tenant_id/workflow_run_id/session_id"
affects: [53-04-bounds-write-time-enforcement, 53-05-mcp-tool-adapter, 53-06, 53-07-guardrail-spans, 53-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "try/rescue/catch/else span wrapper: __STACKTRACE__ only bound inside its matching rescue/catch clause, so the reraise/raise call MUST live inside that branch -- the shared-post-try-emit refactor is the double-emit footgun this shape structurally prevents."
    - "Single private span-map builder (build_span_map/7) as the one origin every emitter (span/4's three outcome branches + both legacy emitters) calls -- OpenInference kind derivation and the tenant_id/workflow_run_id/session_id double-write live in exactly one place."
    - "Monotonic-clock-derived end_time (DateTime.add(start_wall, max(elapsed_us, 1), :microsecond)) instead of two back-to-back DateTime.utc_now() reads -- guarantees end_time is strictly after start_time even for a near-instant fun."

key-files:
  created:
    - test/scoria/observe/span_test.exs
  modified:
    - lib/scoria/observe.ex

key-decisions:
  - "span/4 uses try/rescue/catch/else (not try/rescue/catch alone) so the success path's emit call is also scoped to its own branch -- mirrors the discipline that makes the failure branches double-emit-safe, and reads as a single decision tree with three mutually exclusive branches rather than a try/rescue with a trailing shared emit."
  - "opts (map() | keyword() per the artifact spec) is normalized to a map once at the top of span/4 via normalize_opts/1, because Semconv.merge_host_declared/2 uses Map.get/2 internally and would raise on a raw keyword list."
  - "monotonic_end_time/2 floors elapsed at 1 microsecond (max(elapsed_us, 1)) so end_time is provably strictly-after start_time even when a fun completes in under 1us of wall-clock-observable time -- otherwise a genuinely near-instant ERROR span could tie start_time == end_time and misrepresent a real function call as zero-width."
  - "emit_retriever_span/1's :id now falls back to a fresh Ecto.UUID.generate() when opts[:span_id] is omitted (via the shared build_span_map/7), extending the fallback emit_prompt_span/1 already had. Previously a caller that omitted :span_id would silently persist id: nil. This is a superset of the old behavior (no existing caller omits span_id) and does not change the documented :ok return or opts shape."
  - "emit_outcome_span/7 (span/4's per-branch emit helper) also runs opts through Semconv.merge_host_declared/2, extending ATTR-01 host-declared key support (feature/route/archetype/intent) to every span/4-based producer, matching the plan's explicit opts vocabulary for span/4."

patterns-established:
  - "Every future span-kind producer (53-05 MCP tool adapter, 53-07 guardrail spans) calls span/4 or one of with_tool/3 / with_prompt/3 / with_guardrail/3 -- no producer builds its own span map or calls :telemetry.execute directly."

requirements-completed: []

coverage:
  - id: D1
    description: "span/4 runs fun, measures duration from System.monotonic_time, and returns fun's value verbatim (transparent, D-01a)"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/span_test.exs#Test 1: transparency span/4 returns fun's value verbatim, never transforms it"
        status: pass
    human_judgment: false
  - id: D2
    description: "A persisted span has a real, monotonic-clock-derived duration (end_time strictly after start_time, >= 40ms for a 50ms sleep) -- not a zero-width back-to-back-DateTime.utc_now() span"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 2: real duration a sleeping fun yields a persisted span with a real, monotonic-derived duration"
        status: pass
    human_judgment: false
  - id: D3
    description: "A raising fun produces exactly one ERROR span with a real duration, and the host's exception (type, message, stacktrace) reaches the caller unchanged (SC#3)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 3: ERROR + reraise (SC#3) a raising fun produces one ERROR span with a real duration and reraises the host exception unchanged"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 4: stacktrace fidelity reraise preserves the original stacktrace: the top frame is the raise site, not Scoria.Observe"
        status: pass
    human_judgment: false
  - id: D4
    description: "Exactly one span is emitted per span/4 call on every outcome branch -- success, rescue, and catch (RESEARCH Pitfall 1, no double-emit)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 5: single emit (RESEARCH Pitfall 1) a raising span/4 call persists EXACTLY ONE span row, never two"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 6: throw/exit a throwing fun propagates the throw unchanged and persists exactly one ERROR span"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 6: throw/exit an exiting fun propagates the exit unchanged and persists exactly one ERROR span"
        status: pass
    human_judgment: false
  - id: D5
    description: "The persisted ERROR span's attributes carry only type-only exception info (exception.type/error.type, module name) -- never the raw exception message (T-53-05 mitigation, SC#4)"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 7: no message leak (SC#4, T-53-05) the persisted ERROR span's attributes carry only type-only exception info, never the message"
        status: pass
    human_judgment: false
  - id: D6
    description: "Every span emitted through span/4 writes tenant_id both top-level (driving a real ReviewerBroadcast tenant-topic fan-out) and into attributes (D-00c/D-01e)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 8: tenant_id double-write (D-00c) tenant_id lands in attributes AND drives a real ReviewerBroadcast fan-out"
        status: pass
    human_judgment: false
  - id: D7
    description: "parent_id persists exactly as given; nil roots the trace"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 9: parent linkage parent_id persists exactly as given; nil roots the trace"
        status: pass
    human_judgment: false
  - id: D8
    description: "with_tool/3, with_prompt/3, with_guardrail/3 produce spans with the normalized kind and correct OpenInference span-kind mapping"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 10: kind wrappers with_tool/3, with_prompt/3, with_guardrail/3 produce spans with the normalized kind and OpenInference mapping"
        status: pass
    human_judgment: false
  - id: D9
    description: "emit_retriever_span/1 and emit_prompt_span/1 keep their exact public signatures and :ok return, still carrying all their documented Semconv attributes, after being refactored onto span/4's shared builder (D-ATTR02-1 zero contract change)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 11: emit_retriever_span/1 and emit_prompt_span/1 contract preservation (D-ATTR02-1) emit_retriever_span/1 still returns :ok and carries all three retrieval_config_keys/0 values"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/span_test.exs#Test 11: emit_retriever_span/1 and emit_prompt_span/1 contract preservation (D-ATTR02-1) emit_prompt_span/1 still returns :ok and carries scoria.prompt.context for a non-empty pack"
        status: pass
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs and test/scoria/observe/observe_test.exs (unchanged, 0 edits)"
        status: pass
    human_judgment: false

# Metrics
duration: 18min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 03: Span Primitive + Error Status + Reraise Fidelity Summary

**`Scoria.Observe.span/4` is now the single transparent span primitive (mint, run, time, mark ERROR-on-failure, reraise unchanged) that `with_tool/3`/`with_prompt/3`/`with_guardrail/3` wrap and both Phase-52 emitters (`emit_retriever_span/1`, `emit_prompt_span/1`) now share via one private span-map builder that double-writes `tenant_id`/`workflow_run_id`/`session_id`.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-13T13:44:13-04:00 (base commit)
- **Completed:** 2026-07-13T14:02:27-04:00
- **Tasks:** 2 (TDD RED then GREEN)
- **Files modified:** 2 (`lib/scoria/observe.ex`, `test/scoria/observe/span_test.exs`)

## Accomplishments

- `span(kind, name, opts, fun)` is the single transparent span primitive (D-01a): runs `fun.()` inside `try/rescue/catch/else`, times it from `System.monotonic_time/0`, and returns `fun`'s value verbatim on success.
- Exactly one span is emitted per outcome — success (`else`), a raised exception (`rescue e -> reraise e, __STACKTRACE__`), or a thrown/exited value (`catch kind, reason -> :erlang.raise(kind, reason, __STACKTRACE__)`) — with no emit call reachable after the `try` block, structurally preventing the double-emit footgun (RESEARCH Pitfall 1).
- A raising `fun` produces one `status_code: "ERROR"` span with a real (monotonic-clock-derived, never zero-width) duration, and the host's exception reaches the caller with its original type, message, and stacktrace intact (SC#3) — proven end-to-end against real Postgres.
- The persisted ERROR span's attributes carry only `exception.type`/`error.type` (module name) via `Semconv.error_attributes/1` — never the raw exception message (T-53-05, SC#4).
- `with_tool/3`, `with_prompt/3`, `with_guardrail/3` are thin kind wrappers over `span/4` (D-01b); no `with_agent/3` (deliberately cut, no producer).
- `trace_id_for_run/1` returns a `%Scoria.Workflows.Run{}`'s (or raw run id binary's) id verbatim — a run IS a trace (D-03a) — replacing the prior per-adapter `metadata[:trace_id] || Ecto.UUID.generate()` orphan-trace fallback with an FK-safe, collision-free run↔trace join.
- A new private `build_span_map/7` is the single origin of every emitted span's shape: `span/4`'s three outcome branches and both legacy emitters (`emit_retriever_span/1`, `emit_prompt_span/1`) all call it. It owns the OpenInference span-kind attribute derivation and the `tenant_id`/`workflow_run_id`/`session_id` double-write — a top-level span-map field (consumed by `ReviewerBroadcast.span_stopped/1`, which fail-closes without it, and the future `Bounds` tollbooth) AND an `attributes` entry (consumed by `OrchestratorLive`'s `attributes->>'tenant_id'` SQL filter).
- `emit_retriever_span/1` and `emit_prompt_span/1` are refactored onto the shared builder with their exact public signatures and `:ok` return unchanged (D-01c/D-ATTR02-1) — `test/scoria/observe/prompt_span_test.exs` and `test/scoria/observe/observe_test.exs` needed zero edits and stay green.
- Moduledoc documents the `:telemetry.span/3` prior art (same catch-mark-reraise contract, cited from hexdocs.pm/telemetry), notes Scoria's shape is strictly stronger than OpenTelemetry's `try...after`-only `with_span/3`, and states the deliberate D-02b deferral of an implicit process-local span context (no producer in this phase runs in a process where it would resolve correctly).

## Task Commits

1. **Task 1: Wave-0 test — span/4 duration, single-emit, ERROR status, reraise fidelity, tenant_id double-write** - `5817bf4b` (test, RED — 11/13 tests failed on undefined `span/4`/`with_tool/3`, 2 contract-preservation tests already green)
2. **Task 2: Implement span/4 + kind wrappers + trace_id_for_run/1; refactor both Phase-52 emitters onto it** - `18b9d0b9` (feat, GREEN — 13/13 span tests, 141/141 `test/scoria/observe/`)

**Plan metadata:** this SUMMARY commit.

## Files Created/Modified

- `test/scoria/observe/span_test.exs` — 13 tests covering the plan's 11 required behaviors (transparency, real duration, ERROR+reraise, stacktrace fidelity, single-emit, throw/exit propagation as two separate tests, no-message-leak, tenant_id double-write + real ReviewerBroadcast fan-out, parent linkage, kind wrappers, and emit_retriever_span/1+emit_prompt_span/1 contract preservation). Reuses the real-Postgres scoped-Buffer + `Telemetry.attach` scaffold from `prompt_span_test.exs` (D-ATTR01-6); `on_exit` restores the default boot-attached handler since plan 53-01 now attaches it at boot.
- `lib/scoria/observe.ex` — `span/4`, `with_tool/3`, `with_prompt/3`, `with_guardrail/3`, `trace_id_for_run/1`, private `build_span_map/7`/`emit_outcome_span/7`/`monotonic_end_time/2`/`normalize_opts/1`/`merge_scoped_ids/2`/`maybe_put_scoped_id/3`. `emit_retriever_span/1` and `emit_prompt_span/1` refactored to call the shared builder. Moduledoc rewritten to document `span/4` as the primary primitive, the `:telemetry.span/3`/OpenTelemetry `with_span/3` comparison, and the D-02b explicit-context deferral.

## Decisions Made

- `span/4` uses `try/rescue/catch/else` (not bare `try/rescue/catch`) so the success path's emit is scoped to its own branch too, matching the failure branches' discipline exactly and making the "no emit reachable after the try block" invariant visually obvious in the code (three mutually exclusive branches, three emits, one per branch).
- `opts` (documented as `map() | keyword()`) is normalized to a map once at the top of `span/4` via `normalize_opts/1` — `Semconv.merge_host_declared/2` uses `Map.get/2` internally and would raise `FunctionClauseError`/`BadMapError` on a raw keyword list otherwise.
- `monotonic_end_time/2` floors elapsed time at 1 microsecond (`max(elapsed_us, 1)`) so `end_time` is provably strictly after `start_time` even for a near-instant `fun` — matches Test 2/3's literal `DateTime.compare(...) == :gt` assertions and avoids a genuinely zero-width span misrepresenting a real function call.
- `emit_retriever_span/1`'s `:id` now falls back to a fresh `Ecto.UUID.generate()` when `opts[:span_id]` is omitted (inherited from the shared `build_span_map/7`, which already had this fallback for `emit_prompt_span/1`). Previously an omitted `:span_id` on the retriever emitter would silently persist `id: nil`. This is a strict superset of the documented behavior (`:span_id` was already required per the docstring) and does not change the function's signature, opts shape, or `:ok` return.
- `emit_outcome_span/7` (span/4's per-outcome-branch emit helper) also merges `Semconv.merge_host_declared/2` over `opts`, extending ATTR-01 host-declared key support (`feature`/`route`/`archetype`/`intent`) to every `span/4`-based producer — matching the plan's explicit statement that `span/4`'s `opts` accepts "the four `Semconv.host_declared_keys/0`" alongside `:trace_id`/`:parent_id`/etc.

## Deviations from Plan

None — plan executed exactly as written. Environment-only setup notes (not plan-content deviations):

- This git worktree had no `deps`/`_build`. Initially symlinked `deps/` from the sibling main-repo checkout to avoid a redundant fetch (matching plan 53-01/53-02's approach), but a concurrent full-suite `mix test` run against that shared symlinked directory (likely racing a sibling parallel-wave worktree agent also using the main checkout's `deps/`) produced a transient `mix.lock` mismatch error on a second concurrent invocation. Switched to an `rsync`-copied, worktree-local `deps/` (gitignored, not a symlink) and a fresh worktree-local `_build/test`, eliminating the shared-state race. No `deps/`/`_build/` artifacts were staged or committed.
- One full-suite run reported a single failure: `Scoria.WarningInventory.CaptureParityTest` "optimized compile-only capture catches high-signal unclassified warning (injected)" — this is the exact pre-existing SEED-004-class subprocess-race flake already documented in `.planning/phases/53-structured-child-spans-write-time-bound/deferred-items.md` from plan 53-01. Re-ran in isolation immediately after: 2 tests, 0 failures. Confirmed unrelated to this plan's files (not `lib/scoria/observe.ex` or `test/scoria/observe/span_test.exs`). Not fixed — out of scope, already logged.
- The vendored `examples/support_copilot/deps/**` rebar compiler-cache files (`_build/prod/lib/.rebar3/rebar_compiler_erl/source.dag`) were dirtied by the full-suite run (a support_copilot host-proof test compiles that example app). Restored via `git checkout -- examples/support_copilot/deps/` before finalizing, per this worktree's stated invariant.

## Issues Encountered

None beyond the environment-only setup notes above (both resolved, neither caused by this plan's source changes).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

`Scoria.Observe.span/4`, `with_tool/3`, `with_prompt/3`, `with_guardrail/3`, and `trace_id_for_run/1` are ready for plan 53-05 (MCP tool adapter), 53-06, 53-07 (guardrail spans), and 53-08 to call directly — no producer in this phase needs to build its own span map or call `:telemetry.execute/3` directly. `Scoria.Observe.Bounds` (plan 53-04) can rely on every span reaching `Telemetry.handle_event/4` with a consistent shape (built by the single `build_span_map/7` origin) regardless of which emitter produced it. Phase SC#3 is satisfied at the seam level: a step that raises produces a persisted child span with `status_code: "ERROR"` and a real duration, and the host's exception is reraised unchanged. No blockers.

**Note on `requirements-completed`:** left empty in this SUMMARY's frontmatter, mirroring plan 53-01's explicit decision. `EVENT-01` and `SEC-01` appear in this plan's frontmatter `requirements` alongside 5+ other Phase 53 plans; this plan delivers the write-side primitive but not the full EVENT-01/SEC-01 surface (e.g. `Bounds` write-time enforcement is plan 53-04). Marking either requirement complete here would prematurely flip its checkbox while sibling plans still land. Left for the phase-close reconciliation or the plan that delivers the last piece of each requirement.

## Self-Check: PASSED

- FOUND: lib/scoria/observe.ex
- FOUND: test/scoria/observe/span_test.exs
- FOUND: .planning/phases/53-structured-child-spans-write-time-bound/53-03-SUMMARY.md
- FOUND commit: 5817bf4b (test, RED)
- FOUND commit: 18b9d0b9 (feat, GREEN)

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*
