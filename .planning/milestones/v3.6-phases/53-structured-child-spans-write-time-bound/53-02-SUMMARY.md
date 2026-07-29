---
phase: 53-structured-child-spans-write-time-bound
plan: 02
subsystem: observability
tags: [semconv, telemetry, security, elixir, otel-genai, openinference]

# Dependency graph
requires:
  - phase: 51-foundation-fix-key-convention-span-kind-taxonomy
    provides: "SpanKind.normalize/2 fallback+telemetry pattern, Semconv single-origin key ownership"
  - phase: 52-retriever-span-host-declared-attributes
    provides: "Semconv retrieval_config_keys/0, host_declared_keys/0, merge_host_declared/2, prompt_context/1 no-passthrough discipline"
provides:
  - "Semconv.attribute_registry/0 — closed %{key => class} registry, single origin of every attribute key Scoria may persist (SEC-01)"
  - "Semconv.attribute_classes/0 — closed 6-value class vocabulary with no free-text class"
  - "Semconv.vendor_key_prefixes/0, denied_exact_keys/0, denied_key_segments/0, bounds_marker_keys/0 — the vendor/deny surfaces plan 53-04's Bounds will enforce"
  - "Semconv.guardrail_keys/0, guardrail_names/0, guardrail_decisions/0, guardrail_reason_codes/0, normalize_reason_code/1, guardrail_attributes/1 — the closed guardrail vocabulary + fixed-key projector (D-05f/D-05g)"
  - "Semconv.error_attributes/1 — type-only exception projection (D-06g)"
affects: [53-03-span-primitive-and-error-status, 53-04-bounds-write-time-enforcement, 53-05-mcp-tool-adapter, 53-07-guardrail-spans]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Closed compile-time-constant enum lists (~w(...)a), never Ecto.Enum — mirrors SpanKind.@kinds"
    - "Fixed-key projection with no host-map spread (merge_host_declared/2 / prompt_context/1 / guardrail_attributes/1 all share this no-passthrough shape)"
    - "SpanKind.normalize/2-style fallback: closed-list membership check -> Logger.warning -> defensively try/rescue-wrapped :telemetry.execute -> deterministic default"

key-files:
  created: []
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "attribute_registry/0 is a module attribute built at compile time by merging a literal base map with derived entries from the already-existing @host_declared_keys and @retrieval_config_keys module attributes — ties registry entries to their existing single-origin sources instead of hand-duplicating key strings a second time."
  - "Registry classes assigned per plan guidance: tenant_id/workflow_run_id/session_id/args_fingerprint/guardrail.subject_ref/guardrail.policy_key = :id; duration_ms/scoria.attributes.dropped = :count; feature/route/archetype/intent/openinference.span.kind/retrieval.*/tool_ref/tool_name/status/exception.type/error.type/guardrail.name/guardrail.decision/guardrail.reason_code = :enum; scoria.prompt.context/scoria.attributes.dropped_keys/scoria.attributes.truncated_keys = :structured. No key uses :flag or :timestamp (both remain valid, unused-so-far members of the closed vocabulary)."
  - "error_attributes/1 accepts both an exception struct (%{__exception__: true}) and a {kind, reason} catch tuple ({:throw|:exit|:error, _}) per the plan's stated dual input shape, even though only the exception-struct path is exercised by Test 8."

requirements-completed: [SEC-01, EVENT-01]

coverage:
  - id: D1
    description: "Semconv.attribute_registry/0 returns a flat %{key_string => class} map, canaried by a hand-written literal sorted 27-key list, and is the single origin of every attribute key Scoria itself may persist"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#attribute_registry/0 registry canary (SEC-01 Test 1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "attribute_classes/0 is exactly the 6-member closed vocabulary [:id, :count, :enum, :flag, :timestamp, :structured] and every registry value is a member of it"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#attribute_classes/0 exhaustiveness (SEC-01 Test 2)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Registry is pre-seeded with the 8 bare dashboard-critical keys (tenant_id, workflow_run_id, session_id, duration_ms, feature, route, archetype, intent)"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#dashboard pre-seed (SEC-01 Test 3)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every Semconv-owned key (openinference_span_kind_key/0, prompt_context_key/0, retrieval_config_keys/0 values) is registered — the drift guard against a future Semconv key silently dropping under Bounds"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#Semconv-owned keys are registered (SEC-01 Test 4)"
        status: pass
    human_judgment: false
  - id: D5
    description: "guardrail_names/0, guardrail_decisions/0 (\"modify\" absent/reserved), guardrail_reason_codes/0 return the three closed enums exactly as specified"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#guardrail enums (SEC-01 Test 5)"
        status: pass
    human_judgment: false
  - id: D6
    description: "normalize_reason_code/1 normalizes an unrecognized value to \"unknown\" and emits [:scoria, :observe, :guardrail, :fallback] telemetry; a recognized atom round-trips silently"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#normalize_reason_code/1 fallback (SEC-01 Test 6)"
        status: pass
    human_judgment: false
  - id: D7
    description: "guardrail_attributes/1 projects onto exactly the five scoria.guardrail.* keys, no host-map spread, no smuggled extra key"
    requirement: "EVENT-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#guardrail_attributes/1 fixed-key projection (SEC-01 Test 7)"
        status: pass
    human_judgment: false
  - id: D8
    description: "error_attributes/1 returns exactly exception.type/error.type (both the module name), never the exception message"
    requirement: "SEC-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#error_attributes/1 type-only projection (SEC-01 Test 8)"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 02: Semconv Closed Key Registry + Guardrail Vocabulary + Type-Only Errors Summary

**`Scoria.Observe.Semconv` now owns a closed, canaried `%{key => class}` attribute registry over a 6-value class vocabulary with no free-text class, the closed guardrail decision/reason-code enums with a fixed-key projector, and a type-only exception projection — the structural SEC-01 tollbooth plans 53-03/53-04/53-05/53-07 will consume.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-13T13:15:00-04:00 (approx.)
- **Completed:** 2026-07-13T13:29:34-04:00
- **Tasks:** 2 (TDD RED/GREEN)
- **Files modified:** 2

## Accomplishments
- `Semconv.attribute_registry/0` + `attribute_classes/0`: a closed, hand-canaried 27-key `%{key => class}` registry over the six-value class vocabulary `[:id, :count, :enum, :flag, :timestamp, :structured]` — no class represents arbitrary prose, so a Scoria developer cannot register a free-text key without inventing (and testing) a seventh class.
- Registry pre-seeded with every bare key the operator dashboard already reads (`tenant_id`, `workflow_run_id`, `session_id`, `duration_ms`, `feature`, `route`, `archetype`, `intent`) and every existing Semconv-owned dotted key (`openinference.span.kind`, the three `scoria.retrieval.*` keys, `scoria.prompt.context`) so `Bounds` (plan 53-04) cannot silently blank the dashboard.
- `vendor_key_prefixes/0`, `denied_exact_keys/0`, `denied_key_segments/0`, `bounds_marker_keys/0` — the vendor-prefix admission list, the four req_llm content-promotion exact-key denials, the dot-segment denylist, and the three bounds-marker registry keys `Bounds` will consume.
- Closed guardrail vocabulary (D-05f): `guardrail_names/0` (4 values), `guardrail_decisions/0` (`allow`/`block`/`escalate`, `"modify"` deliberately absent/reserved per D-05h), `guardrail_reason_codes/0` (6 values sourced from `ReleaseGate`/`BreakerRegistry`, not invented).
- `normalize_reason_code/1` mirrors `SpanKind.normalize/2`'s fallback discipline exactly: closed-list membership check, `Logger.warning`, a defensively `try/rescue`-wrapped `[:scoria, :observe, :guardrail, :fallback]` telemetry emit, deterministic `"unknown"` default.
- `guardrail_attributes/1` — a fixed five-key projector with no host-map spread, the structural reason a caller cannot smuggle a free-text `reason` key onto a guardrail span (D-05g).
- `error_attributes/1` — type-only exception projection (`exception.type`/`error.type`, both the module name), never `Exception.message/1` or `__STACKTRACE__` (D-06g); inverts OpenInference's capture-by-default posture.

## Task Commits

Each task was committed atomically (TDD RED then GREEN):

1. **Task 1: Wave-0 test — registry canary, class exhaustiveness, guardrail enums, type-only errors** - `bd1e4a86` (test) — RED: 12 failures (`UndefinedFunctionError`), all 22 pre-existing tests green.
2. **Task 2: Extend Semconv with the closed registry, guardrail vocabulary, type-only error attributes** - `7d0199b5` (feat) — GREEN: 34/34 tests pass.

**Plan metadata:** committed as part of this SUMMARY commit.

## Files Created/Modified
- `lib/scoria/observe/semconv.ex` - extended with `attribute_classes/0`, `attribute_registry/0`, `vendor_key_prefixes/0`, `denied_exact_keys/0`, `denied_key_segments/0`, `bounds_marker_keys/0`, `guardrail_keys/0`, `guardrail_names/0`, `guardrail_decisions/0`, `guardrail_reason_codes/0`, `normalize_reason_code/1`, `guardrail_attributes/1`, `error_attributes/1` (13 new public functions, all `@spec`'d and `@doc`'d); `require Logger` added; moduledoc extended to document the closed-registry/guardrail/error-projection ownership and INV-SEC01.
- `test/scoria/observe/semconv_test.exs` - extended with 8 new `describe` blocks (13 test cases) covering the registry canary, class exhaustiveness, dashboard pre-seed, Semconv-owned-key registration, guardrail enums, `normalize_reason_code/1` fallback, `guardrail_attributes/1` projection, and `error_attributes/1` type-only projection. All pre-existing Phase-51/52 tests (22) left intact.

## Decisions Made
- `attribute_registry/0` is built at compile time as a module attribute, merging a literal base map (bespoke keys: tenant/session/duration/tool/error/guardrail/marker keys) with entries derived from the already-existing `@host_declared_keys` and `@retrieval_config_keys` module attributes via `Map.new/2` — this ties registry entries to their existing single-origin sources rather than hand-duplicating key strings a second time, while keeping the whole thing a flat compile-time constant (no runtime recomputation cost on the eventual `Bounds` hot path).
- Class assignments per key follow the plan's explicit guidance (id-like identifiers -> `:id`, numeric/count -> `:count`, closed short vocabularies -> `:enum`, nested/structured payloads -> `:structured`); no registry entry uses `:flag` or `:timestamp` — both remain valid unused members of the closed six-value vocabulary, available for future entries without widening the class list.
- `error_attributes/1` accepts both an exception struct (`%{__exception__: true}`) and a `{kind, reason}` catch tuple (`{:throw | :exit | :error, _}`), per the plan's action item describing both input shapes, even though the RED/GREEN test suite (Test 8) only exercises the exception-struct clause. This keeps the function usable from `span/4`'s planned `try/rescue` **and** `catch` branches (plan 53-03) without a follow-up signature change.

## Deviations from Plan

None — plan executed exactly as written. One environment-only adjustment (not a deviation from plan content): this git worktree had no `deps`/`_build` directories, so dependencies were compiled into a local `_build` using `MIX_DEPS_PATH` pointed at the main checkout's already-fetched `deps/` (read-only, no `mix deps.get` performed) to avoid re-downloading ~40 Hex packages. This is a one-time local test-runner setup and produced no source changes.

## Issues Encountered
- `mix format --check-formatted` flagged pre-existing wrapping on two lines this plan's edits touched (one in the untouched `prompt_context/1` helper, one in the new `attribute_registry/0` construction, plus two lines in the new test file). Ran `mix format` on both changed files and re-verified `mix test test/scoria/observe/ --warnings-as-errors` stayed green (128/128) before committing — purely cosmetic, no behavior change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Semconv.attribute_registry/0` and `attribute_classes/0` are ready for plan 53-04 (`Bounds.enforce/2`) to use as its admission tollbooth.
- `Semconv.vendor_key_prefixes/0`, `denied_exact_keys/0`, `denied_key_segments/0`, `bounds_marker_keys/0` are ready for the same plan.
- `Semconv.guardrail_keys/0`/`guardrail_names/0`/`guardrail_decisions/0`/`guardrail_reason_codes/0`/`normalize_reason_code/1`/`guardrail_attributes/1` are ready for plan 53-07 (`Guardrail.emit/1`).
- `Semconv.error_attributes/1` is ready for plan 53-03's `span/4` ERROR-status branch.
- No blockers. This plan has no dependencies on any other Phase 53 plan (`depends_on: []`, wave 1) and unblocks four downstream plans.

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: lib/scoria/observe/semconv.ex
- FOUND: test/scoria/observe/semconv_test.exs
- FOUND: .planning/phases/53-structured-child-spans-write-time-bound/53-02-SUMMARY.md
- FOUND commit: bd1e4a86 (test)
- FOUND commit: 7d0199b5 (feat)
- FOUND commit: 725583e5 (docs)
