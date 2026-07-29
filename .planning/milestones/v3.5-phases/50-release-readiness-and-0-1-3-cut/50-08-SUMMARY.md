---
phase: 50-release-readiness-and-0-1-3-cut
plan: 08
subsystem: testing
tags: [elixir, exunit, docs-ssot, dev-lab, ci-gap-closure]

# Dependency graph
requires:
  - phase: 50-release-readiness-and-0-1-3-cut
    provides: "50-01 relocated maintainer docs SSOT from docs/MAINTAINERS.md to guides/maintainers.md and restored dropped CI/release content"
provides:
  - "ui_component_test.exs maintainer-doc reads repointed to canonical guides/maintainers.md"
  - "guides/maintainers.md restored 'Design-system component conventions' section (BEM/CSS-selector rule + canonical compact scan density rule) dropped during the docs/MAINTAINERS.md stub conversion"
  - "dev_lab_boundary_test.exs guard #7 repointed to the archived 36-inventory.json path under .planning/milestones/v3.3-phases/"
affects: [ci-verify-lane, docs-maintenance, dev-lab-boundary]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repoint stale File.read! source paths to the current canonical location (relocated doc, archived milestone directory) rather than restoring content into a compat stub or loosening an assertion"

key-files:
  created: []
  modified:
    - test/scoria_web/ui_component_test.exs
    - test/scoria_web/dev_lab_boundary_test.exs
    - guides/maintainers.md
    - docs/design_system.md

key-decisions:
  - "Restored the two dropped 'Design-system component catalog' convention paragraphs (BEM/CSS-selector rule, canonical compact scan density rule) into guides/maintainers.md as a new section, rather than restoring them into the docs/MAINTAINERS.md compat stub — the c9958ab1 stub conversion deleted this content wholesale and 50-01 only restored the CI/release sections, so it was genuinely missing from the canonical SSOT, not intentionally reworded elsewhere"
  - "Repointed dev_lab_boundary_test.exs guard #7's canonical inventory read from .planning/phases/36-baseline-and-inventory/36-inventory.json to .planning/milestones/v3.3-phases/36-baseline-and-inventory/36-inventory.json (archived during milestone cleanup); verified all 46 canonical PRIM-*/GROUP-* IDs are still referenced under dev/lab/**, so this is a stale-path fix, not a coverage-floor weakening"
  - "Also fixed docs/design_system.md's now-stale docs/MAINTAINERS.md cross-references (BEM & CSS selectors section) to point at guides/maintainers.md's new section, since the old target no longer carries that content"

requirements-completed: []

coverage:
  - id: D1
    description: "ui_component_test.exs flush-panel-gutters test (:286) and table-density-out-of-public-API test (:1289) read guides/maintainers.md instead of the docs/MAINTAINERS.md compat stub, and pass"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#flush panel gutters use component variables instead of deep structural selectors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ui_component_test.exs#table source and CSS keep density out of the public API"
        status: pass
    human_judgment: false
  - id: D2
    description: "dev_lab_boundary_test.exs guard #7 (canonical PRIM-*/GROUP-* inventory-ID coverage floor) reads the archived 36-inventory.json path and passes with all 46 canonical IDs still covered under dev/lab/**"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs#guard #7: every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/** (D-08/D-32)"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 08: Bucket-D UI component / dev-lab contract repointing Summary

**Repointed 3 stale-path CI failures (2 in ui_component_test.exs, 1 in dev_lab_boundary_test.exs) to their current canonical sources without weakening any assertion.**

## Performance

- **Duration:** 20 min
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `ui_component_test.exs`'s two `docs/MAINTAINERS.md` reads (`:286` flush-panel gutters, `:1289` table density-out-of-public-API) now read the canonical `guides/maintainers.md`
- Restored the dropped "Design-system component conventions" content (BEM/CSS-selector rule, canonical compact scan density rule) into `guides/maintainers.md`, closing a real documentation gap left by the docs/MAINTAINERS.md stub conversion
- `dev_lab_boundary_test.exs` guard #7 now reads the archived canonical inventory JSON path and its "every canonical PRIM-*/GROUP-* inventory ID is referenced under dev/lab/**" contract still passes with full (46/46) coverage

## Task Commits

Each task was committed atomically:

1. **Task 1: Repoint ui_component_test maintainer-doc reads to guides/maintainers.md** - `72fa708f` (fix)
2. **Task 2: Restore the guard #7 canonical PRIM-*/GROUP-* inventory-ID reference under dev/lab/**** - `8e019e70` (fix)

_Note: both tasks required restoring/repointing content discovered missing from the canonical SSOT rather than a pure read-path swap; see Deviations below._

## Files Created/Modified
- `test/scoria_web/ui_component_test.exs` - two `File.read!("docs/MAINTAINERS.md")` calls repointed to `File.read!("guides/maintainers.md")`; no assertion fragment altered
- `test/scoria_web/dev_lab_boundary_test.exs` - guard #7's canonical inventory JSON path repointed from `.planning/phases/36-baseline-and-inventory/36-inventory.json` to `.planning/milestones/v3.3-phases/36-baseline-and-inventory/36-inventory.json`
- `guides/maintainers.md` - new "Design-system component conventions" section restoring the BEM/CSS-selector convention paragraph and the canonical compact scan density paragraph, dropped during the docs/MAINTAINERS.md stub conversion (`c9958ab1`) and not carried forward by 50-01's partial restoration
- `docs/design_system.md` - two stale `docs/MAINTAINERS.md` cross-references in the "BEM & CSS selectors" section repointed to `guides/maintainers.md`

## Decisions Made
- Restoring dropped canonical convention content into `guides/maintainers.md` (rather than into the `docs/MAINTAINERS.md` compat stub, and rather than treating the fragments as "genuinely absent" and stopping) is the root-cause fix here: git history (`c9958ab1`) shows the content was deleted wholesale during the stub conversion and 50-01 only restored the CI/release subset, so this is a documentation regression, not a deliberate content redesign.
- The dev-lab guard #7 failure was a plain `File.Error` (missing file), not a coverage-floor assertion failure — the canonical 36-inventory.json was archived to `.planning/milestones/v3.3-phases/` during milestone cleanup. Repointing the read path is the correct fix; all 46 canonical IDs remain fully covered under `dev/lab/**`, so guard strictness is unchanged.
- Also fixed `docs/design_system.md`'s now-stale `docs/MAINTAINERS.md` cross-references while in the area, since they pointed at content that no longer exists there post-restoration (low-risk, directly-related correctness fix; `design_system_doc_contract_test.exs` re-verified green).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/2 - Bug / Missing critical functionality] Restored dropped "Design-system component conventions" content into guides/maintainers.md**
- **Found during:** Task 1 (repoint ui_component_test maintainer-doc reads)
- **Issue:** The plan's read_first step assumed the BEM/CSS-selector and canonical-compact-scan-density fragments were already present in `guides/maintainers.md` (or `docs/design_system.md`) and just needed a read-path repoint. Investigation (via `git log -S` on the fragment text) showed the content was deleted wholesale from `docs/MAINTAINERS.md` in `c9958ab1` (stub conversion) and never carried forward — `docs/design_system.md` paraphrases the convention but doesn't preserve the exact wording, and 50-01's restoration only covered CI/release sections.
- **Fix:** Added a new "Design-system component conventions" section to `guides/maintainers.md` restoring the two dropped paragraphs verbatim (CSS-selector/BEM convention; canonical compact scan density convention), matching the pre-`c9958ab1` wording exactly so the test assertions remain byte-for-byte unchanged.
- **Files modified:** `guides/maintainers.md`
- **Verification:** `mix test test/scoria_web/ui_component_test.exs` — 126 tests, 0 failures
- **Committed in:** `72fa708f` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed stale docs/MAINTAINERS.md cross-references in docs/design_system.md**
- **Found during:** Task 1 (repoint ui_component_test maintainer-doc reads)
- **Issue:** `docs/design_system.md`'s "BEM & CSS selectors" section cited `docs/MAINTAINERS.md`'s "Design-system component catalog" section (`:262-273`) as the SSOT for the convention — a dangling reference since that section no longer exists at that path.
- **Fix:** Repointed both cross-references to `guides/maintainers.md`'s new "Design-system component conventions" section.
- **Files modified:** `docs/design_system.md`
- **Verification:** `mix test test/scoria_web/design_system_doc_contract_test.exs test/scoria_web/ui_component_test.exs` — 129 tests, 0 failures
- **Committed in:** `72fa708f` (Task 1 commit)

**3. [Rule 1 - Bug] Repointed dev_lab_boundary guard #7 to the archived 36-inventory.json path**
- **Found during:** Task 2 (restore guard #7 canonical inventory-ID reference)
- **Issue:** Guard #7 raised `File.Error` (no such file) reading `.planning/phases/36-baseline-and-inventory/36-inventory.json` — that phase directory was archived to `.planning/milestones/v3.3-phases/` during milestone cleanup, so the failure was a stale path, not a real missing-reference regression.
- **Fix:** Repointed the `File.read!` call to `.planning/milestones/v3.3-phases/36-baseline-and-inventory/36-inventory.json`. Confirmed via a standalone script that all 46 canonical `PRIM-*`/`GROUP-*` IDs from that file are still referenced under `dev/lab/**/*.ex` before making the change, so the fix is a pure path repoint with the coverage-floor contract fully intact.
- **Files modified:** `test/scoria_web/dev_lab_boundary_test.exs`
- **Verification:** `mix test test/scoria_web/dev_lab_boundary_test.exs` — 9 tests, 0 failures
- **Committed in:** `8e019e70` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bug/missing-content restorations, 1 stale-path repoint)
**Impact on plan:** All three were required to make the fix a genuine root-cause fix rather than a superficial read-path swap over content that didn't actually exist yet. No assertion was weakened; no scope creep beyond the doc/test files directly implicated by the two failing contracts.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Bucket D (UI component / dev-lab contracts) is fully closed: `mix test test/scoria_web/ui_component_test.exs test/scoria_web/dev_lab_boundary_test.exs` exits 0 (135 tests, 0 failures).
- No known follow-up required for this bucket.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED

- FOUND: test/scoria_web/ui_component_test.exs
- FOUND: test/scoria_web/dev_lab_boundary_test.exs
- FOUND: guides/maintainers.md
- FOUND: docs/design_system.md
- FOUND: .planning/phases/50-release-readiness-and-0-1-3-cut/50-08-SUMMARY.md
- FOUND commit: 72fa708f
- FOUND commit: 8e019e70
