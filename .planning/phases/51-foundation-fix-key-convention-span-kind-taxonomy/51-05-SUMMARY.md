---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
plan: 05
subsystem: observability
tags: [otel-genai, openinference, jido, elixir, telemetry]

# Dependency graph
requires:
  - phase: 51-01
    provides: Scoria.Observe.SpanKind (canonical 8-value span_kind taxonomy module)
  - phase: 51-02
    provides: Scoria.Observe.Semconv (openinference_span_kind_key/0)
  - phase: 51-04
    provides: The established host-override + flat-default span_kind seam and openinference mirror pattern (ReqLLM adapter), mirrored here
provides:
  - "Scoria.Observe.Adapters.Jido.handle_event/4 sets span_kind via SpanKind.normalize(metadata[:span_kind] || \"tool\") (D-13 host-declared override only, replacing the INTERNAL category error) with a mirrored openinference.span.kind attribute via Semconv"
affects: [52-retriever-span-and-host-declared-attributes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Adapter-layer span_kind seam: metadata[:span_kind] || \"<adapter's natural kind>\" piped through SpanKind.normalize/2, with the mirror written via Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind)) -- now consistently applied across both write-side adapters (ReqLLM: 51-04, Jido: 51-05)"

key-files:
  created: []
  modified:
    - lib/scoria/observe/adapters/jido.ex
    - test/scoria/observe/adapters/jido_test.exs
    - .planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/deferred-items.md

key-decisions:
  - "No deviations from the plan's literal instruction -- unlike Plan 51-04 (which had to correct the plan-literal metadata[:operation] source to metadata[:span_kind]), 51-05's plan already specified the correct metadata[:span_kind] || \"tool\" seam, so it was implemented as written."

patterns-established: []

requirements-completed: [SPAN-02]

coverage:
  - id: D1
    description: "A Jido action-stop event with no metadata[:span_kind] produces span.span_kind == \"tool\" (default, no action-name inference — D-13)"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/jido_test.exs#SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind#no metadata[:span_kind] defaults to native-lowercase \"tool\""
        status: pass
    human_judgment: false
  - id: D2
    description: "A host-declared metadata[:span_kind] override (e.g. \"agent\") is honored verbatim, with no action-name-based inference"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/jido_test.exs#SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind#metadata[:span_kind] == \"agent\" is honored (host override, no action-name inference)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every produced Jido span carries a mirrored openinference.span.kind attribute (UPPERCASE, via Semconv.openinference_span_kind_key/0 + SpanKind.to_openinference/1); mcp collapses to TOOL per D-11"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/jido_test.exs#SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind#metadata[:span_kind] == \"mcp\" mirrors to openinference \"TOOL\" (D-11)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/adapters/jido_test.exs#SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind#every produced span carries an openinference.span.kind attribute"
        status: pass
    human_judgment: false
  - id: D4
    description: "The INTERNAL category-error literal is gone and span_kind is drawn exclusively from the shared SpanKind whitelist -- no inline literal in jido.ex"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "source assertion: grep -c 'span_kind: \"INTERNAL\"' lib/scoria/observe/adapters/jido.ex == 0 && grep -c 'SpanKind.normalize' lib/scoria/observe/adapters/jido.ex >= 1 && grep -c '\"openinference.span.kind\"' lib/scoria/observe/adapters/jido.ex == 0"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-12
status: complete
---

# Phase 51 Plan 05: Jido Adapter Span-Kind Fix (INTERNAL to Host-Declared Tool) Summary

**`Scoria.Observe.Adapters.Jido` now sets `span_kind` via `SpanKind.normalize(metadata[:span_kind] || "tool")` (host-declared override, default `"tool"`, no action-name inference) with a mirrored `openinference.span.kind` attribute via `Semconv`/`SpanKind` — replacing the `"INTERNAL"` OTel category-error literal, mirroring the ReqLLM adapter's established pattern exactly.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-12T11:32:10-04:00
- **Completed:** 2026-07-12T11:41:54-04:00
- **Tasks:** 2
- **Files modified:** 2 (1 lib, 1 test) plus 1 deferred-items.md doc note

## Accomplishments
- Rewrote `Scoria.Observe.Adapters.Jido.handle_event/4`: `span_kind: "INTERNAL"` (an OTel `SpanKind` category, not an OpenInference kind — the root bug this plan fixes) replaced with `span_kind: Scoria.Observe.SpanKind.normalize(metadata[:span_kind] || "tool")`. Per D-13, this is host-declared override only — no action-name classifier was added, matching the sibling ReqLLM adapter's already-established convention (51-04).
- Added the `openinference.span.kind` mirror to the `attributes` map via `Scoria.Observe.Semconv.openinference_span_kind_key/0` + `Scoria.Observe.SpanKind.to_openinference/1` — zero inline `"openinference.span.kind"` string literal or hardcoded UPPERCASE value anywhere in the adapter.
- Restructured `test/scoria/observe/adapters/jido_test.exs` into `"span shape"` and `"SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind"` describe blocks (mirroring `req_llm_test.exs`'s shape), covering: no-override default `"tool"`, host override to `"agent"`, `"mcp"` mirroring to openinference `"TOOL"` (D-11), and a sweep asserting every produced span carries the mirror attribute.
- Left all Jido-specific attributes (`jido.action_name`, `jido.status`, `duration_ms`, `tenant_id`/`workflow_run_id`, `trace_id` fallback, the final `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`) untouched — no `gen_ai.*` set merged (Jido spans are not LLM-model spans, per the plan's explicit instruction).

## Task Commits

Each task was committed atomically (TDD RED/GREEN for Task 1):

1. **Task 1: Jido adapter — span_kind via SpanKind.normalize (host-declared, default tool) + openinference mirror** (TDD)
   - `983ffb4f` (test) — add failing test for span_kind tool default + openinference mirror
   - `ff216eca` (feat) — Jido adapter span_kind via SpanKind.normalize + openinference mirror
2. **Task 2: Update jido_test.exs — tool default, host override, openinference mirror**
   - `9ea1bf76` (test) — restructure jido_test.exs into span-shape/SPAN-02 describe blocks

**Plan metadata:** (final docs commit, see below)

## Files Created/Modified
- `lib/scoria/observe/adapters/jido.ex` — `span_kind` now computed via `SpanKind.normalize/2` (aliased), mirror written via `Semconv.openinference_span_kind_key/0` + `SpanKind.to_openinference/1`; `INTERNAL` literal removed.
- `test/scoria/observe/adapters/jido_test.exs` — restructured into `describe` blocks; tool-default, host-override, mcp-mirror, and every-span-carries-mirror cases added; no `INTERNAL` assertion remains.
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/deferred-items.md` — logged the Plan 51-05 recurrence of the pre-existing `capture_parity_test.exs` flake (see Issues Encountered).

## Decisions Made
- None beyond the plan's literal instruction. Unlike Plan 51-04 (where `metadata[:operation]` had to be corrected to `metadata[:span_kind]` as a Rule 1 auto-fix), this plan's `<action>` text already specified the correct `metadata[:span_kind] || "tool"` seam directly — no deviation required.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Full-suite `mix test` (1163 tests + 3 doctests) reported `1 failure` — re-confirmed as the exact same pre-existing, environment-dependent flake already logged under Plans 51-03/51-04 in `deferred-items.md` (`test/scoria/warning_inventory/capture_parity_test.exs:53`, passes standalone via `mix test --failed`, only fails under full-suite parallel `--only __ratchet_compile_only__` subprocess isolation, zero relationship to `lib/scoria/observe/adapters/*`). Logged a Plan 51-05 recurrence note in `deferred-items.md`; not fixed (out of this plan's scope boundary). This plan's own verification lanes are all green:
- `mix test test/scoria/observe/adapters/jido_test.exs` — 5 tests, 0 failures
- `mix test test/scoria/observe/adapters/jido_test.exs test/scoria/observe/` (regression) — 80 tests, 0 failures

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- SPAN-02 is now complete for both write-side adapters (ReqLLM: 51-04, Jido: 51-05). Both emit a native-lowercase `span_kind` from the shared `Scoria.Observe.SpanKind` whitelist with a mirrored `openinference.span.kind` attribute via `Scoria.Observe.Semconv`.
- Phase 51's SPAN-01/SPAN-02/COMPAT-01/FOUND-01 requirements are now fully addressed across plans 51-01 through 51-05. Phase 52 (RETRIEVER span + host-declared attributes) can proceed using the same established `SpanKind`/`Semconv` seams.
- No blockers.

---
*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files (`lib/scoria/observe/adapters/jido.ex`, `test/scoria/observe/adapters/jido_test.exs`, `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/deferred-items.md`, this SUMMARY.md) verified present on disk; all 4 task/docs commit hashes (`983ffb4f`, `ff216eca`, `9ea1bf76`, `881b67b5`) verified present in `git log`.
