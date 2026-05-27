---
phase: 53-operator-evidence-and-lane-guidance
plan: 03
subsystem: testing
tags: [docs, drift-checks, source-fragments, adoption, exunit]

requires:
  - phase: 53-operator-evidence-and-lane-guidance
    provides: Default-to-handoff wording updates from Plan 53-02
provides:
  - Explicit docs drift assertions for default-first lane wording and forbidden command/internal references
  - Expanded shared source fragments covering facade arities and run/session semantics
  - Source-alignment coverage for bounded handoff escalation wording
affects: [phase-53, docs-guardrails, adoption-tests, source-tests]

tech-stack:
  added: []
  patterns:
    - Docs drift tests pin required adoption phrasing and refute unsupported proof/internal strings
    - Shared source fragments include facade arity signatures and handoff readback handles

key-files:
  created:
    - .planning/phases/53-operator-evidence-and-lane-guidance/53-03-SUMMARY.md
  modified:
    - test/scoria/adoption_surface_test.exs
    - test/support/scoria/adoption_example.ex
    - docs/phoenix_runtime_example.md

key-decisions:
  - "Added a dedicated Phase 53 drift test to keep lane wording and forbidden command strings locked."
  - "Expanded fragment helper entries (including arity signatures) instead of adding new source-test files."

patterns-established:
  - "Adoption/source fragment helpers should carry explicit `Scoria.*/*` API signatures used in docs."

requirements-completed: [EVID-01, DOCS-01]

duration: 12m
completed: 2026-05-27
---

# Phase 53 Plan 03: Docs/Source Drift Guard Summary

**Phase 53 now has executable drift guards that fail when docs regress default-first lane wording, expose internals, or drop key public facade/readback fragments.**

## Performance

- **Duration:** 12m
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added Phase 53-specific invariant assertions to `test/scoria/adoption_surface_test.exs`.
- Expanded `Scoria.TestSupport.AdoptionExample` fragment sets with explicit facade arities and run/session semantics.
- Updated runtime example wording to include explicit `Scoria.start_handoff_run/3` branch phrasing required by fragment checks.

## Task Commits

1. **Task 53-03-01: Pin broad docs invariants for Phase 53 lane wording** - `ea6d1a1` (test)
2. **Task 53-03-02: Pin source fragments for public facade and ID semantics** - `c08ada1` (test)

## Verification

- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` (pass)
- `MIX_ENV=test mix test test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` (pass)
- `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria_web/live/workflow_live_test.exs:130 test/scoria_web/live/workflow_live_test.exs:188` (pass)

## Deviations from Plan

None - plan executed as written.

## Self-Check: PASSED

- Found `test/scoria/adoption_surface_test.exs`.
- Found `test/support/scoria/adoption_example.ex`.
- Found `docs/phoenix_runtime_example.md`.
- Found commit `ea6d1a1`.
- Found commit `c08ada1`.
