---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
plan: 01
subsystem: observability
tags: [elixir, phoenix-liveview, telemetry, css, span-kind, openinference]

# Dependency graph
requires: []
provides:
  - "Scoria.Observe.SpanKind — single shared 8-value span_kind taxonomy module (kinds/0, kind?/1, normalize/2, to_openinference/1)"
  - "Both trace-rendering UI components (workflow_tree_component.ex, trace_tree_component.ex) delegate to SpanKind.normalize/1-2, no independent inline whitelists"
  - "CSS .scoria-span--status-error overlay class replacing the stale .scoria-span--error rail (D-12: error is a status, not a kind)"
  - "[:scoria, :observe, :span_kind, :fallback] telemetry event contract, named and locked"
  - "D-15 drift-guard test suite (canary, exhaustiveness, CSS coherence, anti-inline guard, fallback observability)"
affects: [51-02, 51-03, 51-04, 51-05, 52, 53, 54]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Plain compile-time-constant module (not Ecto.Enum) for a bounded taxonomy consumed at multiple write/read sites — mirrors circuit_breaker.ex shape"
    - "normalize/2 fail-closed-to-default with defensive telemetry emit (try/rescue around :telemetry.execute so a raising host handler cannot crash the caller)"
    - "Status is a CSS overlay class composed alongside a kind rail, never a standalone kind value (error != kind)"

key-files:
  created:
    - lib/scoria/observe/span_kind.ex
    - test/scoria/observe/span_kind_test.exs
  modified:
    - lib/scoria_web/components/workflow_tree_component.ex
    - lib/scoria_web/components/trace_tree_component.ex
    - assets/css/04-components.css
    - test/scoria_web/components/trace_tree_component_test.exs
    - test/scoria_web/components/workflow_tree_component_test.exs

key-decisions:
  - "Fallback telemetry event name locked as [:scoria, :observe, :span_kind, :fallback] (metadata %{value:, default:}) per RESEARCH.md Open Question 3, documented in the SpanKind moduledoc"
  - "SpanKind.normalize/2's :telemetry.execute/3 call is wrapped in try/rescue (T-51-01 mitigation) so a misbehaving host telemetry handler cannot crash the normalize caller"
  - "workflow_tree_component.ex keeps its 3 step-vocab mapping clauses (approval->guardrail, handoff->agent, answer->llm) since it maps a different input (workflow-step kind) than trace_tree_component.ex (real ai_spans.span_kind); only the final fallback routes through SpanKind.normalize/1"
  - "CSS status-error overlay implemented as a left-border + alert-icon badge (::after, non-color-only per WCAG), reusing existing --scoria-span-error and --scoria-text-onaccent tokens rather than introducing new ones"

patterns-established:
  - "Shared taxonomy module pattern: @kinds/@map constants + kinds/0, kind?/1, normalize/2, to_*/1 — reusable shape for future Semconv module (Phase 51 Plan 02+)"
  - "Drift-guard source-scan test suite style (CANARY/EXHAUSTIVENESS/CSS-COHERENCE/ANTI-INLINE-GUARD) mirrors single_header_guard_test.exs conventions"

requirements-completed: [FOUND-02, SPAN-02]

coverage:
  - id: D1
    description: "Scoria.Observe.SpanKind module exists with kinds/0, kind?/1, normalize/2, to_openinference/1; not Ecto.Enum; 8-value canonical list"
    requirement: FOUND-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#kinds/0 returns exactly the 8-value canonical list, in order"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#to_openinference/1 maps every native kind to the correct UPPERCASE OpenInference value"
        status: pass
    human_judgment: false
  - id: D2
    description: "normalize/2 fails closed to a default and emits [:scoria,:observe,:span_kind,:fallback] telemetry + Logger.warning on an unrecognized value (never silent)"
    requirement: FOUND-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#normalize/2 returns the supplied default and emits telemetry + logs a warning on fallback"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#D-15 drift guard FALLBACK OBSERVABILITY: normalize/1 on an unrecognized value emits the fallback telemetry event and returns the default \"agent\""
        status: pass
    human_judgment: false
  - id: D3
    description: "Both trace-rendering UI components (workflow_tree_component.ex, trace_tree_component.ex) delegate to Scoria.Observe.SpanKind.normalize/1-2 instead of independent inline ~w(...) whitelists"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#D-15 drift guard ANTI-INLINE GUARD: no residual span-kind ~w(...) whitelist literal remains in either UI component"
        status: pass
      - kind: unit
        ref: "test/scoria_web/components/trace_tree_component_test.exs#renders the lowercase-native scoria-span--llm rail class regardless of stored casing"
        status: pass
      - kind: unit
        ref: "test/scoria_web/components/workflow_tree_component_test.exs#renders the lowercase-native scoria-span--llm rail class for the answer step vocab"
        status: pass
    human_judgment: false
  - id: D4
    description: "CSS ships every kind rail (scoria-span--<kind> for all 8 canonical kinds) plus a .scoria-span--status-error overlay class; the stale .scoria-span--error rail is removed"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/span_kind_test.exs#D-15 drift guard CSS COHERENCE: every kind has a matching scoria-span--<kind> rail, and the status-error overlay replaces the error rail"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-12
status: complete
---

# Phase 51 Plan 01: Foundation Fix + Key Convention + Span-Kind Taxonomy Summary

**Shared `Scoria.Observe.SpanKind` taxonomy module (8 canonical kinds, observable normalize/2 fallback, mcp/eval OpenInference mapping) now drives both trace-rendering UI components, replacing two independently-drifted inline whitelists and the stale `error`-as-kind entry with a CSS status overlay.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-12T14:38:00Z (approx)
- **Completed:** 2026-07-12T14:44:00Z
- **Tasks:** 3
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- Created `Scoria.Observe.SpanKind`, a plain compile-time-constant module (not `Ecto.Enum` per D-14) exposing `kinds/0`, `kind?/1`, `normalize/2`, `to_openinference/1` — the single source of truth for the 8-kind taxonomy (`agent/llm/prompt/tool/mcp/retriever/guardrail/eval`), with `error` removed (D-12: it's a status, not a kind)
- Fixed the live casing bug: `trace_tree_component.ex` previously downcased+matched inline and silently defaulted everything unrecognized to `agent`; it now delegates wholly to `SpanKind.normalize/1`
- `workflow_tree_component.ex` kept its distinct step-vocabulary mapping (`approval`→`guardrail`, `handoff`→`agent`, `answer`→`llm`) but routes its fallback through the shared module instead of a duplicated inline `~w(...)` guard
- Repurposed CSS `.scoria-span--error` into `.scoria-span--status-error`, a non-color-only (left-border + alert-icon) overlay class composed alongside a span's real kind rail, per D-12 and WCAG 1.4.1 — the 8 kind rails and `.scoria-span--redacted` are unchanged
- Locked the `[:scoria, :observe, :span_kind, :fallback]` telemetry event name + metadata contract in the module moduledoc (per RESEARCH.md Open Question 3), with the emit defensively wrapped (T-51-01) so a raising host handler can't crash the normalize caller
- Shipped the mandatory D-15 drift-guard test suite: canary (exact kind list), exhaustiveness (every kind maps to a non-raising UPPERCASE OpenInference value), CSS coherence (every kind has a rail; status-error overlay present, stale error rail absent), anti-inline guard (source-scan proves neither component retains a `~w(...)` span-kind literal), and fallback observability (telemetry event + default return proven)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Scoria.Observe.SpanKind taxonomy module** - `04ea551b` (feat)
2. **Task 2: Route both UI components through SpanKind; convert CSS `--error` rail into a `--status-error` overlay** - `4d2dbc29` (feat)
3. **Task 3: SpanKind drift-guard test suite (D-15, FOUND-02 mandatory)** - `1947e263` (test)

**Plan metadata:** (final docs commit, see below)

## Files Created/Modified
- `lib/scoria/observe/span_kind.ex` - New shared taxonomy module (kinds/0, kind?/1, normalize/2, to_openinference/1)
- `test/scoria/observe/span_kind_test.exs` - Behavior tests (Task 1) + D-15 drift-guard suite (Task 3)
- `lib/scoria_web/components/trace_tree_component.ex` - `span_kind/1` now delegates wholly to `SpanKind.normalize/1`
- `lib/scoria_web/components/workflow_tree_component.ex` - kept step-vocab mapping clauses; fallback now routes through `SpanKind.normalize/1`
- `assets/css/04-components.css` - `.scoria-span--error` → `.scoria-span--status-error` overlay (left-border + icon); 8 kind rails + redacted unchanged
- `test/scoria_web/components/trace_tree_component_test.exs` - added lowercase-native `scoria-span--llm` rail assertion
- `test/scoria_web/components/workflow_tree_component_test.exs` - added lowercase-native `scoria-span--llm` rail assertion for the `answer` step vocab

## Decisions Made
- Fallback telemetry event name locked as `[:scoria, :observe, :span_kind, :fallback]` with metadata `%{value:, default:}`, documented in the `SpanKind` moduledoc (resolves RESEARCH.md Open Question 3)
- `normalize/2`'s `:telemetry.execute/3` emit is wrapped in `try/rescue` (T-51-01 mitigation) — a raising host-attached handler cannot crash the caller or interrupt the normalize return path
- CSS status-error overlay reuses the existing `--scoria-span-error` and `--scoria-text-onaccent` design tokens rather than introducing new ones, keeping the change additive to the token system
- `workflow_tree_component.ex` retains its 3 step-vocab mapping clauses because its input (`step.kind`: `approval`/`handoff`/`answer`) is a different data source than the real `ai_spans.span_kind` value `trace_tree_component.ex` reads — only the shared fallback/validation logic is unified

## Deviations from Plan

None - plan executed exactly as written. The two lowercase-native rail-class assertions added to the component test files were explicitly called for by Task 2's acceptance criteria ("component tests render an `llm` span with the `scoria-span--llm` rail class") and Task 2's done criteria ("component tests updated to lowercase-native assertions pass"), not unplanned scope.

## Issues Encountered
None. One syntax fix was needed while authoring `kind?/1` (Elixir requires explicit parens around a piped expression before `in`, e.g. `(to_string(value) |> String.downcase()) in @kinds`) — caught immediately by the compiler on first test run and corrected before any commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Scoria.Observe.SpanKind` is now available for Plan 02+ (adapters: `req_llm.ex`, `jido.ex`) to set native `span_kind` values and mirror `openinference.span.kind` via `to_openinference/1`
- The `Scoria.Observe.Semconv` module (D-16, FOUND-03) referenced by later plans in this phase is NOT created by this plan — it is out of this plan's `files_modified` scope and remains a Wave 2 dependency
- No blockers for subsequent Phase 51 plans; the shared taxonomy + drift guard are locked and green

---
*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Completed: 2026-07-12*
