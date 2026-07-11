---
phase: 50-release-readiness-and-0-1-3-cut
plan: 10
subsystem: testing
tags: [hex, mix, exdoc, warning-inventory, ci]

requires:
  - phase: 50-release-readiness-and-0-1-3-cut
    provides: "REL-03 HexDocs subdomain migration (@hexdocs_url = https://scoria.hexdocs.pm) in mix.exs"
provides:
  - "package_surface_test.exs one-publish-surface assertion tracks the REL-03 subdomain SSOT"
  - "capture_parity_test.exs confirmed green on the release head (verify-first, no change needed)"
affects: [50-11-PLAN.md]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - test/scoria/package_surface_test.exs

key-decisions:
  - "package_surface_test :79 homepage_url assertion updated from https://hexdocs.pm/scoria to https://scoria.hexdocs.pm to track mix.exs @hexdocs_url (REL-03/D-14); one-publish-surface invariant preserved (no second URL added)"
  - "capture_parity_test.exs left unchanged — verify-first reproduction on the release head passed (2 tests, 0 failures), confirming CI run 29137880790's finding that it did not fail in any partition; local-env-only artifact, not a real contract break"

patterns-established: []

requirements-completed: [REL-04]

coverage:
  - id: D1
    description: "package_surface_test.exs one-publish-surface assertion aligned to the REL-03 HexDocs subdomain SSOT (https://scoria.hexdocs.pm), sourced from mix.exs @hexdocs_url"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria/package_surface_test.exs#project metadata describes one publish surface"
        status: pass
    human_judgment: false
  - id: D2
    description: "capture_parity_test.exs (Bucket F) verify-first reconciliation — confirmed passing on the release head, no code change required"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria/warning_inventory/capture_parity_test.exs#optimized compile-only capture catches high-signal unclassified warning (injected)"
        status: pass
      - kind: unit
        ref: "test/scoria/warning_inventory/capture_parity_test.exs#optimized compile-only capture yields zero high-signal unclassified offenders on clean tree"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 10: Bucket B + F gap-closure Summary

**Aligned package_surface_test's one-publish-surface assertion to the REL-03 HexDocs subdomain SSOT (https://scoria.hexdocs.pm) and confirmed capture_parity_test:53 is a local-env-only artifact that passes clean on the release head.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-11
- **Completed:** 2026-07-11
- **Tasks:** 2 completed (1 code change, 1 verify-only no-op)
- **Files modified:** 1

## Accomplishments
- `test/scoria/package_surface_test.exs`'s "project metadata describes one publish surface" test now asserts `homepage_url == "https://scoria.hexdocs.pm"`, matching mix.exs `@hexdocs_url` (the REL-03/D-14 canonical publish surface). No second URL was added — the single-publish-surface contract stays intact.
- Confirmed by direct reproduction that `test/scoria/warning_inventory/capture_parity_test.exs:53` passes on the current release head (2 tests, 0 failures, ~10.4s). This matches the CI gap inventory's finding (run 29137880790: did not fail in any partition) — Bucket F was verify-first and required no change.
- Both target files verified together: `mix test test/scoria/package_surface_test.exs test/scoria/warning_inventory/capture_parity_test.exs` → 12 tests, 0 failures.

## Task Commits

1. **Task 1: Align package_surface_test to the REL-03 HexDocs subdomain SSOT** - `5258266d` (fix)
2. **Task 2: Verify-first reconcile capture_parity_test against the release head** - no commit (verify-only; reproduction passed, no file changes made)

**Plan metadata:** (recorded below, in the final docs commit)

## Files Created/Modified
- `test/scoria/package_surface_test.exs` - `homepage_url` assertion at line 84 updated from the legacy path-style `https://hexdocs.pm/scoria` to the canonical subdomain `https://scoria.hexdocs.pm`, tracking mix.exs `@hexdocs_url` (REL-03). Scanned the rest of the file for any other `hexdocs.pm/scoria` path-style expectations — none found; this was the only occurrence.

## Decisions Made
- Confirmed the canonical publish surface is the subdomain (`https://scoria.hexdocs.pm`, mix.exs `@hexdocs_url`, set by REL-03/D-14) before editing the test, per plan instruction. The value is asserted directly (matching the SSOT), not hardcoded to a divergent string.
- For Bucket F, followed the plan's verify-first mandate literally: ran the test on the current tree before touching anything. It passed (0 failures), so per plan instruction "make NO change" — left the file byte-identical to plan start.

## Deviations from Plan

None - plan executed exactly as written. Both tasks followed their prescribed verify-first/fix-if-needed paths with no need to invoke deviation Rules 1-4.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Bucket B (package/publish surface) and Bucket F (warning inventory) are both closed. Combined with 50-05..50-09, this closes all default-lane CI gap buckets from `50-CI-GAP-INVENTORY.md` except Bucket G (DashboardScope mount-halt regression), which is 50-11's scope.
- `test/scoria/package_surface_test.exs` and `test/scoria/warning_inventory/capture_parity_test.exs` are both green; no known blockers carried forward from this plan.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED
- FOUND: test/scoria/package_surface_test.exs
- FOUND: .planning/phases/50-release-readiness-and-0-1-3-cut/50-10-SUMMARY.md
- FOUND: 5258266d (git log)
