---
phase: 49-support-truth-and-adoption-closeout
plan: 02
subsystem: testing
tags: [mix, verification, adoption, compatibility]
requires:
  - phase: 49-support-truth-and-adoption-closeout
    provides: canonical public verifier hierarchy for docs and support language
provides:
  - Installer output that keeps the default lane visually primary
  - Canonical `mix test.knowledge` task naming with compatibility alias retention
  - Source-adjacent tests that pin installer and knowledge-task wording
affects: [49-03, adoption, support]
tech-stack:
  added: []
  patterns: [canonical mix test lane naming, compatibility alias retained but unpromoted]
key-files:
  created: []
  modified: [lib/mix/tasks/scoria.install.ex, lib/mix/tasks/scoria.test.knowledge.ex, test/mix/tasks/scoria.install_test.exs, test/mix/tasks/scoria.test_knowledge_test.exs]
key-decisions:
  - "Kept the installer's optional-lane inventory compact while adding an explicit `Default lane verifier: mix test.adoption` line."
  - "Preserved `mix scoria.test.knowledge` as a working alias but made `mix test.knowledge` the public name in code copy and tests."
patterns-established:
  - "Mix task copy follows the same four-tier support hierarchy as the public docs."
  - "Task tests assert discoverability and public naming drift without widening runtime behavior."
requirements-completed: [DOCS-01, DOCS-02]
duration: 15min
completed: 2026-05-26
---

# Phase 49: Support truth and adoption closeout Summary

**Installer and knowledge-task surfaces now reinforce `mix test.adoption` first and treat `mix test.knowledge` as the public optional-lane verifier**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-26T12:40:00Z
- **Completed:** 2026-05-26T12:55:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Updated installer output so the default lane verifier is explicit before the optional later lanes list.
- Switched the optional knowledge lane inventory and task shortdocs to the canonical `mix test.knowledge` naming.
- Tightened task tests so both `test.knowledge` and `scoria.test.knowledge` stay discoverable while only the canonical name is promoted.

## Task Commits

No new commits were created during this Codex run. The executed changes remain in the local working tree alongside pre-existing user changes.

## Files Created/Modified
- `lib/mix/tasks/scoria.install.ex` - Installer summary now names the default verifier and lists `mix test.knowledge`.
- `lib/mix/tasks/scoria.test.knowledge.ex` - Task shortdocs now frame `mix test.knowledge` as canonical and the namespaced form as compatibility-only.
- `test/mix/tasks/scoria.install_test.exs` - Output assertions now pin the default verifier line and canonical knowledge command.
- `test/mix/tasks/scoria.test_knowledge_test.exs` - Discoverability assertions now cover both task names and the updated shortdoc posture.

## Decisions Made

- Keep runtime behavior unchanged; Phase 49 only adjusts wording and drift-prevention tests.
- Use task shortdocs as a public support seam, not just an implementation detail.

## Deviations from Plan

None - the plan closed by updating copy and assertions without widening task behavior.

## Issues Encountered

The first shortdoc assertion expected charlists, but Elixir exposes them as strings in `module_info(:attributes)`. The test was corrected and rerun successfully.

## User Setup Required

None - both task names still work, with `mix test.knowledge` now serving as the canonical public lane.

## Next Phase Readiness

The Wave 2 adoption-surface and task-boundary tests now have a stable command-family contract to enforce.

---
*Phase: 49-support-truth-and-adoption-closeout*
*Completed: 2026-05-26*
