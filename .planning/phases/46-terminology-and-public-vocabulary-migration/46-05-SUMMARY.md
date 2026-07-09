---
phase: 46-terminology-and-public-vocabulary-migration
plan: 05
subsystem: web/components
tags: [terminology, trace, evidence-boundary, reviewer-copy, storage-guard]

requires: [46-01, 46-02, 46-03]
provides:
  - remote invocation top-level trace copy
  - incident top-level trace and reviewer persona copy
  - preserved evidence wording for incident support proof sections
affects: [phase-46, dashboard, remote-invocation, incidents, support-proof-copy]

tech-stack:
  added: []
  patterns:
    - Top-level run inspection copy uses trace vocabulary
    - Proof-material sections retain evidence vocabulary

key-files:
  modified:
    - lib/scoria_web/components/remote_invocation_evidence_component.ex
    - lib/scoria_web/components/incident_evidence_component.ex
    - test/scoria_web/components/incident_evidence_component_test.exs

key-decisions:
  - "Remote invocation notebook title and eyebrow now use trace vocabulary because they describe reviewer-facing run inspection."
  - "Incident header copy now uses incident trace and reviewer-facing language, while incident support sections retain evidence labels."
  - "Component names and proof helper primitives were left unchanged because this plan is a copy-boundary correction, not a schema or adapter rename."

patterns-established:
  - "When evidence is support proof, keep evidence labels even inside trace-oriented UI."
  - "Focused component tests should assert both sides of the evidence/trace boundary to avoid future global find/replace regressions."

requirements-completed: [TERM-02, TERM-03]

duration: 2 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 05: Remote Invocation And Incident Boundary Summary

**Remote invocation and incident top-level copy now uses trace and reviewer language while support proof sections keep evidence vocabulary.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-09T22:29:00Z
- **Completed:** 2026-07-09T22:31:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Updated `RemoteInvocationEvidenceComponent` top-level notebook title and eyebrow from remote evidence language to remote trace language.
- Updated `IncidentEvidenceComponent` top-level header from incident evidence to incident trace language.
- Replaced operator persona copy in the incident support section with reviewer-facing copy.
- Preserved `Budget evidence`, `Breaker evidence`, delivery/audit evidence detail, and shared evidence primitives where the component describes proof material.
- Added component tests that prove remote top-level trace copy, incident reviewer copy, and preserved evidence support labels.

## Task Commits

1. **Task 1 RED: Trace/evidence boundary contract** - `7c95ce9c` (test)
2. **Task 1 GREEN: Trace/evidence copy boundary** - `59190886` (feat)

## Files Created/Modified

- `lib/scoria_web/components/remote_invocation_evidence_component.ex` - Remote invocation notebook title and eyebrow now use trace vocabulary.
- `lib/scoria_web/components/incident_evidence_component.ex` - Incident top-level copy now uses trace and reviewer vocabulary while support proof sections keep evidence vocabulary.
- `test/scoria_web/components/incident_evidence_component_test.exs` - Focused boundary tests for remote trace copy, incident reviewer copy, and preserved proof labels.

## Decisions Made

- Kept `RemoteInvocationEvidenceComponent` and `IncidentEvidenceComponent` module names unchanged because the plan only targeted top-level copy and evidence-domain labels, not adapter renames.
- Kept `incident-evidence-notebook` DOM id unchanged so existing CSS/tests and evidence-domain styling remain stable.
- Kept raw actor reference values untouched; only authored persona copy changed from operator to reviewer.

## Deviations from Plan

None - plan executed as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- None.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/components/incident_evidence_component_test.exs` - PASS, 9 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` - PASS, 4 tests, 0 failures.
- `rg -n "Incident trace|Trace-first incident review|Reviewer-facing incident facts|Budget evidence|Breaker evidence|Audit and delivery|audit evidence" lib/scoria_web/components/incident_evidence_component.ex` - PASS.
- `rg -n "Remote invocation trace|Remote trace notebook" lib/scoria_web/components/remote_invocation_evidence_component.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 is complete. Wave 3 can start with `46-06-PLAN.md`, where glossary and documentation wiring can rely on the trace/reviewer copy boundary being established.

## Self-Check: PASSED

- Verified remote invocation top-level copy uses trace vocabulary.
- Verified incident top-level copy uses trace and reviewer vocabulary.
- Verified evidence labels remain for incident support proof sections.
- Verified focused component and terminology guard tests pass.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
