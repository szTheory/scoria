---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 15
subsystem: documentation
tags: [guides, compatibility-stubs, reviewer-verification, maintainers, exdoc]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 through 48-05 canonical guide bodies
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-06 README links and 48-12/48-13 public docs vocabulary
provides:
  - Compatibility source stub for old docs/operator_verification.md links
  - Compatibility source stub for old docs/MAINTAINERS.md links
  - Canonical cross-links to guides/reviewer-verification.md and guides/maintainers.md
affects: [phase-48, guide-ladder, exdoc, adopter-docs, package-surface]

tech-stack:
  added: []
  patterns:
    - Old docs/*.md source paths are thin compatibility stubs only.
    - Canonical reviewer verification and maintainer guide content lives under guides/.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-15-SUMMARY.md
  modified:
    - docs/operator_verification.md
    - docs/MAINTAINERS.md

key-decisions:
  - "Kept old operate and maintainer source paths as compatibility stubs rather than duplicating canonical guide bodies."
  - "Named Reviewer Verification as the current guide name and used operator verification only as compatibility context."
  - "Left dev-only docs and ExDoc/package configuration untouched because this plan owns only the two old source paths."

patterns-established:
  - "Compatibility stubs should state their canonical guides/ target and explicitly avoid ExDoc canonical-source status."

requirements-completed: [DOCS-03]

duration: 1m 12s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 15: Reviewer and Maintainer Compatibility Stubs Summary

**Old reviewer verification and maintainer source links now land on thin compatibility pages that point to the canonical guides ladder.**

## Performance

- **Duration:** 1m 12s
- **Started:** 2026-07-10T22:21:12Z
- **Completed:** 2026-07-10T22:22:24Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Replaced `docs/operator_verification.md` with a compatibility page that names **Reviewer Verification** as the current guide and links to `guides/reviewer-verification.md`.
- Replaced `docs/MAINTAINERS.md` with a compatibility page that links to `guides/maintainers.md`.
- Explicitly marked both old `docs/` files as compatibility source stubs that should not be treated as ExDoc canonical extras.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert reviewer verification and maintainer docs to compatibility stubs** - `c9958ab1` (`docs`)

## Files Created/Modified

- `docs/operator_verification.md` - Compatibility stub for old copied reviewer/operator verification source links.
- `docs/MAINTAINERS.md` - Compatibility stub for old copied maintainer source links.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-15-SUMMARY.md` - Records plan completion.

## Verification

- `rg -n "Compatibility note|guides/reviewer-verification\\.md|guides/maintainers\\.md" docs/operator_verification.md docs/MAINTAINERS.md` - PASS.
- `git diff --exit-code -- docs/design_system.md docs/docker_dev_dx.md docs/uat_automation.md` - PASS; the dev-only docs named in the plan were untouched.
- `git diff --check -- docs/operator_verification.md docs/MAINTAINERS.md` - PASS.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - PARTIAL / expected out-of-scope failures: 39 tests ran, 7 failures remain in `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, and `guides/capabilities/bounded-handoffs.md`. These match the residual guide-fragment failures recorded by Plans 48-12 and 48-13 and are outside this plan's files.
- `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` - PARTIAL / expected out-of-scope failures: 9 tests ran, 8 failures remain because `mix.exs` and release-preview inventory still reflect the older flat docs setup. This is outside the 48-15 two-file compatibility-stub scope and corresponds to remaining incomplete Phase 48 package/ExDoc work.

## Decisions Made

- Kept the old docs pages intentionally short so copied source links remain useful without duplicating canonical guide bodies.
- Used relative Markdown links to the canonical `guides/` files while also spelling the canonical paths literally for source assertions.
- Did not edit `docs/design_system.md`, `docs/docker_dev_dx.md`, `docs/uat_automation.md`, package inventory, or ExDoc extras.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Broad docs/package contract commands are still red outside this plan's file set. The direct source assertions for the two compatibility stubs passed, and no unrelated docs were modified.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `docs/operator_verification.md` | 7 | Intentional compatibility source stub required by Phase 48 D-02. |
| `docs/MAINTAINERS.md` | 7 | Intentional compatibility source stub required by Phase 48 D-02. |

## Threat Flags

None. This plan changed Markdown documentation only and introduced no runtime endpoint, auth path, file-access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Old copied reviewer verification and maintainer source links now point users to the canonical guide ladder. Remaining Phase 48 package/ExDoc inventory work should continue to own the broader red package-surface contracts.

## Self-Check: PASSED

- Found modified files: `docs/operator_verification.md` and `docs/MAINTAINERS.md`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-15-SUMMARY.md`.
- Found task commit: `c9958ab1`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
