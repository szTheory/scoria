---
phase: 50-release-readiness-and-0-1-3-cut
plan: 02
subsystem: testing
tags: [e2e, playwright, dev-seed, elixir, tenant-scoping, prompt-release, theme-toggle]

# Dependency graph
requires:
  - phase: 44-06
    provides: tenant-scoped Scoria.Workflows.PromptRelease.start_release_workflow/3 contract
  - phase: 50-01
    provides: REL-01 policy-lane docs-contract repair (sibling e2e-lane fix in the same PR #12)
provides:
  - "Green e2e CI lane for PR #12: dev seed now creates the block-(f) pending prompt_release approval and block-(g) IA trace/incident/eval-linkage evidence that were silently skipped"
  - "Theme-toggle e2e locators that bind to the visible desktop control at desktop viewport"
affects: [release-readiness, ci-gate, REL-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Playwright dual desktop/mobile selectors must use .filter({ visible: true }).first() (never a bare .first()) so the locator resolves by visibility, not DOM order"
    - "Dev seed calls the tenant-scoped workflow API with the real bound tenant_id (never a hardcoded default/lineage fallback)"

key-files:
  created: []
  modified:
    - priv/repo/dev_seed.exs
    - priv/dev/e2e/phase16_parity.spec.mjs

key-decisions:
  - "Fixed all FOUR theme-toggle locator sites (plan body listed 3 inline sites; RESEARCH Pitfall 3 identified the home-screen toggleSelector-variable usage at line 514 as a 4th buggy site) — required for the e2e lane to actually go green"
  - "Passed the real bound tenant_id to start_release_workflow/3, restoring consumption of the Phase 44-06 hardened contract rather than weakening tenant scope"
  - "Preserved the seed's try/rescue resilience pattern (broad seed-determinism refactor out of scope per D-11)"

patterns-established:
  - "Visible-control Playwright locators: .filter({ visible: true }).first() over bare .first() for dual-viewport selectors"

requirements-completed: [REL-02]

coverage:
  - id: D1
    description: "Dev seed calls start_release_workflow with the arity-3 tenant-scoped contract at both sites; block (f) pending approval + block (g) IA-linkage evidence seed without the swallowed UndefinedFunctionError skip"
    requirement: "REL-02"
    verification:
      - kind: manual_procedural
        ref: "MIX_ENV=dev mix dev.setup (fresh DB) — stdout has zero 'start_release_workflow/2 is undefined' skip lines; all block (f)/(g) success checkmarks print"
        status: pass
      - kind: e2e
        ref: "priv/dev/e2e/ia_orientation.spec.mjs (home trace stream, incident→Open run, Eval→Open prompt release) + modal_focus.spec.mjs (release-workbench Reject Release path)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Theme-toggle e2e locators bind to the visible desktop control at desktop viewport (all four sites hardened with .filter({ visible: true }))"
    requirement: "REL-02"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/phase16_parity.spec.mjs (4 MOTION-04 theme-toggle smoke tests: home/shell, workflows table, workflow detail, overlay path)"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-07-10
status: complete
---

# Phase 50 Plan 02: REL-02 e2e-lane repair Summary

**Fixed the two stale arity-2 `start_release_workflow` dev-seed call sites to the Phase 44-06 tenant-scoped arity-3 contract and hardened four theme-toggle Playwright locators with `.filter({ visible: true })`, turning the full e2e CI lane green (165 passed, 3 pre-existing skips).**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-07-11T02:41:00Z
- **Completed:** 2026-07-11T02:49:31Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Repaired the single root cause behind 4 of the 5 PR #12 e2e failures: `dev_seed.exs` called `PromptRelease.start_release_workflow/2` at blocks (f) and (g), but the function is arity-3 since Phase 44-06; the seed's `try/rescue` silently swallowed the `UndefinedFunctionError`, skipping the pending prompt_release approval and the entire IA-linkage demo path.
- Fixed the 5th failure: the dual desktop/mobile theme-toggle selector with a bare `.first()` bound to the DOM-first hidden mobile control at desktop viewport (`.click()` then timed out ~30s). Now scoped to the visible desktop control via the codebase's existing `.filter({ visible: true }).first()` idiom.
- Verified end-to-end: fresh `mix dev.setup` prints zero skip-warnings with all block (f)/(g) checkmarks, and the full `mix scoria.ui.e2e` lane is green (165 passed, 3 pre-existing pending skips, 0 failures).

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix both stale start_release_workflow/2 call sites in dev_seed.exs** - `7a24315` (fix)
2. **Task 2: Harden the theme-toggle locator in phase16_parity.spec.mjs** - `75ee88a` (fix)

## Files Created/Modified
- `priv/repo/dev_seed.exs` - Both `start_release_workflow` calls (blocks f @ line ~960 and g @ line ~1048) now pass the third arg `tenant_id: tenant_id`, matching `release_workbench_live.ex:117`. The surrounding `try/rescue` blocks are untouched.
- `priv/dev/e2e/phase16_parity.spec.mjs` - Four theme-toggle locators (the home-screen `toggleSelector` usage at line 514, plus the three inline combined-selector sites for the workflows-table test, the workflow-detail main branch, and its no-run fallback branch) now use `.filter({ visible: true }).first()`. Line 513's selector string, the `page.evaluate` querySelector, and the viewport-scoped single-ID mobile/desktop locators are unchanged; no `force: true` or `sleep` introduced.

## Decisions Made
- **Fixed four locator sites, not three.** The plan's Task 2 body enumerated three inline sites (533, 562, 575) and instructed leaving line 513 alone, characterizing it as "a `toggleSelector` string passed into `page.evaluate` / plain DOM `querySelector`." That characterization was inaccurate: line 513 only *defines* the selector string; line 514 *uses* it as a Playwright locator with a bare `.first()` — the identical bug. RESEARCH Pitfall 3 (authoritative) explicitly lists the buggy sites as "lines 513-514, 533, 575" and directs fixing "all 3 call sites." I fixed line 514 as well (leaving the line-513 string definition untouched, so the plan's acceptance greps still hold: zero bare inline `.first()` literals, ≥3 `.filter({ visible: true })`). This was necessary — the home/shell theme-toggle test (`phase16_parity.spec.mjs:503`) exercises the line-514 locator and would have kept timing out and holding the e2e lane red had line 514 been left unfixed. Post-fix it passes.
- **Passed the real bound `tenant_id`** (never a hardcoded default or lineage fallback), restoring correct consumption of the Phase 44-06 hardened tenant-scoping control rather than weakening it (D-18, threat T-50-02-01).
- **Preserved the silent-rescue seed pattern** — a broad seed-determinism refactor was explicitly out of scope (D-11). Per threat T-50-02-02, I grepped the seed's own stdout for the swallowed skip-warning as an explicit verification gate before trusting DOM assertions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hardened a fourth theme-toggle locator (home-screen `toggleSelector` usage at line 514)**
- **Found during:** Task 2 (theme-toggle locator hardening)
- **Issue:** The plan's Task 2 body scoped the fix to three inline combined-selector sites and instructed leaving line 513 untouched, mis-describing it as a non-locator `querySelector`/`page.evaluate` string. In reality line 514 (`page.locator(toggleSelector).first()`) has the exact same DOM-order-vs-visibility bug and drives the home/shell theme-toggle test, which would have remained red. RESEARCH Pitfall 3 explicitly names "lines 513-514" among the buggy call sites.
- **Fix:** Inserted `.filter({ visible: true })` before `.first()` at line 514, leaving the line-513 selector-string definition untouched (so all Task 2 acceptance greps still pass).
- **Files modified:** priv/dev/e2e/phase16_parity.spec.mjs
- **Verification:** `phase16_parity.spec.mjs:503` (Home/shell theme toggle) passes in the full e2e run; `grep -c "filter({ visible: true })"` = 4; line 513, the querySelector, and single-ID locators unchanged; no `force: true`.
- **Committed in:** 75ee88a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** The extra locator fix was strictly necessary to satisfy the plan's own success criteria ("theme toggle clickable at desktop width", "all 5 previously-failing specs pass"). No scope creep — same file, same bug class, same idiom; the plan's acceptance greps remain satisfied.

## Issues Encountered
None. Both fixes verified against a freshly-seeded dev server: seed stdout clean, full Playwright lane green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- REL-02 is complete: the e2e CI lane is green. Combined with 50-01's REL-01 policy-lane fix, PR #12 should now reach `ci-gate`.
- Unblocks REL-04 (the 0.1.3 release cut) per the plan's dependency note.
- The 3 skipped e2e tests are pre-existing Phase 12/14/15 pending items (`uat.spec.mjs` notebook/drawer/overlay), unrelated to this plan.

## Self-Check: PASSED
- priv/repo/dev_seed.exs modified — FOUND (commit 7a24315)
- priv/dev/e2e/phase16_parity.spec.mjs modified — FOUND (commit 75ee88a)
- Commit 7a24315 — FOUND in git log
- Commit 75ee88a — FOUND in git log

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-10*
