---
phase: 46-terminology-and-public-vocabulary-migration
plan: 04
subsystem: web/components
tags: [terminology, trace, components, compatibility, storage-guard]

requires: [46-01, 46-02, 46-03]
provides:
  - ScoriaWeb.DelegatedTraceComponent final-vocabulary delegated run trace surface
  - ScoriaWeb.ReplayTraceNotebookComponent final-vocabulary replay trace notebook
  - ScoriaWeb.SemanticCacheTraceNotebookComponent final-vocabulary semantic cache trace notebook
  - 0.1.x compatibility wrappers for previous private evidence component names
affects: [phase-46, dashboard, workflow-detail, workflow-live, run-inspection-components]

tech-stack:
  added: []
  patterns:
    - Private component compatibility wrappers delegate to final-vocabulary modules
    - Reviewer-facing run inspection copy uses trace and scoped context language

key-files:
  created:
    - lib/scoria_web/components/delegated_trace_component.ex
    - lib/scoria_web/components/replay_trace_notebook_component.ex
    - lib/scoria_web/components/semantic_cache_trace_notebook_component.ex
    - test/scoria_web/components/delegated_trace_component_test.exs
    - test/scoria_web/components/replay_trace_notebook_component_test.exs
    - test/scoria_web/components/semantic_cache_trace_notebook_component_test.exs
  modified:
    - lib/scoria_web/components/delegated_evidence_component.ex
    - lib/scoria_web/components/replay_evidence_notebook_component.ex
    - lib/scoria_web/components/semantic_evidence_notebook_component.ex
    - lib/scoria_web/components/workflow_detail_panel_component.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - test/scoria_web/components/semantic_evidence_notebook_component_test.exs
    - test/scoria_web/live/workflow_live_test.exs

key-decisions:
  - "Trace-named components own reviewer-facing run-inspection copy while prior evidence-named private modules remain loadable wrappers for 0.1.x compatibility."
  - "Delegated handoff display copy now says scoped context, but stored handoff fields remain projected_context."
  - "Semantic cache trace copy uses trace groups and cache execution details without renaming lane_key or evidence_refs storage keys."

patterns-established:
  - "Private UI adapter renames should preserve old module names as wrappers until the compatibility window closes."
  - "Terminology migrations should update reviewer-visible labels and call sites without touching durable schema names."

requirements-completed: [TERM-02, TERM-03]

duration: 7 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 04: Trace Component Summary

**Workflow run-inspection UI now uses trace vocabulary while preserving legacy private component module names.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-09T22:22:00Z
- **Completed:** 2026-07-09T22:29:00Z
- **Tasks:** 1
- **Files modified:** 13

## Accomplishments

- Added `ScoriaWeb.DelegatedTraceComponent` with `delegated-trace`, `Delegated Trace`, `Inspect Delegated Trace`, and scoped context labels.
- Added `ScoriaWeb.ReplayTraceNotebookComponent` with `replay-trace-notebook`, replay trace notebook labels, and the existing empty-state behavior.
- Added `ScoriaWeb.SemanticCacheTraceNotebookComponent` with `semantic-cache-trace-notebook`, semantic cache trace inspection labels, trace groups, and cache execution details.
- Replaced previous private evidence component files with 0.1.x compatibility wrappers delegating to the new trace modules.
- Updated workflow detail and workflow show call sites to render the trace-named components.
- Updated focused component and LiveView tests to prove new module names, reviewer-visible copy, call-site wiring, and wrapper compatibility.

## Task Commits

1. **Task 1 RED: Trace component contracts** - `d6ef881e` (test)
2. **Task 1 GREEN: Workflow trace components** - `7dba6b32` (feat)

## Files Created/Modified

- `lib/scoria_web/components/delegated_trace_component.ex` - Canonical delegated run trace component.
- `lib/scoria_web/components/replay_trace_notebook_component.ex` - Canonical replay trace notebook component.
- `lib/scoria_web/components/semantic_cache_trace_notebook_component.ex` - Canonical semantic cache trace notebook component.
- `lib/scoria_web/components/delegated_evidence_component.ex` - Legacy compatibility wrapper for delegated trace rendering.
- `lib/scoria_web/components/replay_evidence_notebook_component.ex` - Legacy compatibility wrapper for replay trace notebook rendering.
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex` - Legacy compatibility wrapper for semantic cache trace notebook rendering.
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - Workflow detail wiring for replay and semantic cache trace modules.
- `lib/scoria_web/live/workflow_live/show.ex` - Delegated handoff wiring for `DelegatedTraceComponent`.
- `test/scoria_web/components/delegated_trace_component_test.exs` - Delegated trace component copy and wrapper coverage.
- `test/scoria_web/components/replay_trace_notebook_component_test.exs` - Replay trace notebook copy and wrapper coverage.
- `test/scoria_web/components/semantic_cache_trace_notebook_component_test.exs` - Semantic cache trace notebook copy and grouping coverage.
- `test/scoria_web/components/semantic_evidence_notebook_component_test.exs` - Legacy semantic evidence wrapper compatibility coverage.
- `test/scoria_web/live/workflow_live_test.exs` - Workflow show delegated trace rendering coverage.

## Decisions Made

- Kept the existing flat `ScoriaWeb.*` component namespace for the new trace modules.
- Kept old private component module names as wrappers instead of aliases so wrapper module docs and direct render delegation are explicit.
- Preserved storage-facing vocabulary for `evidence_refs`, `projected_context`, and `lane_key`; only reviewer-facing labels and private module call sites changed.

## Deviations from Plan

None - plan executed as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- Initial workflow test expectations still asserted the previous semantic evidence and delegated evidence copy. Those expectations were updated to the final trace labels after the component tests proved the new behavior.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/components/delegated_trace_component_test.exs test/scoria_web/components/replay_trace_notebook_component_test.exs test/scoria_web/components/semantic_cache_trace_notebook_component_test.exs test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/live/workflow_live_test.exs` - PASS, 27 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` - PASS, 4 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - PASS.
- `rg -n "ReplayTraceNotebookComponent|SemanticCacheTraceNotebookComponent" lib/scoria_web/components/workflow_detail_panel_component.ex` - PASS.
- `rg -n "DelegatedTraceComponent" lib/scoria_web/live/workflow_live/show.ex` - PASS.
- `rg -n "defmodule ScoriaWeb\\.(DelegatedTraceComponent|ReplayTraceNotebookComponent|SemanticCacheTraceNotebookComponent)" lib/scoria_web/components/delegated_trace_component.ex lib/scoria_web/components/replay_trace_notebook_component.ex lib/scoria_web/components/semantic_cache_trace_notebook_component.ex` - PASS.
- `rg -n "0\\.1\\.x compatibility|defmodule ScoriaWeb\\.(DelegatedEvidenceComponent|ReplayEvidenceNotebookComponent|SemanticEvidenceNotebookComponent)" lib/scoria_web/components/delegated_evidence_component.ex lib/scoria_web/components/replay_evidence_notebook_component.ex lib/scoria_web/components/semantic_evidence_notebook_component.ex` - PASS.
- `git diff --name-only HEAD -- priv lib | rg -n "priv/repo/migrations|schema|schemas"` - PASS, no schema or migration paths changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can continue with `46-05-PLAN.md`; trace component vocabulary is in place and legacy private module names remain compileable.

## Self-Check: PASSED

- Verified trace-named components exist and render the expected labels and DOM ids.
- Verified workflow detail and workflow show call sites use the new trace modules.
- Verified old private component names remain compatibility wrappers.
- Verified focused plan tests, terminology storage guard, and compile check pass with warnings as errors.
- Verified no schema or storage key rename was introduced.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
