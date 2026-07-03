---
phase: 40-accessibility-motion-and-responsive-proof
plan: 01
subsystem: testing
tags: [playwright, axe-core, a11y, e2e-harness, wcag]

# Dependency graph
requires: []
provides:
  - "@axe-core/playwright pinned dev-only devDependency (4.12.1) with transitive axe-core override, resolvable via npm ci"
  - "priv/dev/e2e/lib/axe.mjs — single shared axe scan builder (WCAG tags + target-size rule override)"
  - "priv/dev/e2e/lib/boxes_intersect.mjs — single shared boxesIntersect(a,b) geometry primitive"
  - "40-GAP-REGISTER.md — opened working gap-register artifact with D-20 pre-seed row"
affects: [40-02-motion-drift-guard, 40-03-drawer-modal-focus, 40-04-axe-scan-and-responsive-scan, 40-05-consistency-sweep]

# Tech tracking
tech-stack:
  added: ["@axe-core/playwright@4.12.1 (dev-only, priv/dev/package.json)"]
  patterns:
    - "Shared axe-run helper: .options({rules}) called BEFORE .withTags([...]) — AxeBuilder#options() replaces the whole internal option object while #withTags() only merges runOnly, so reversing the order silently drops the tag filter."
    - "Shared boxesIntersect(a,b,tolerance=1) axis-aligned overlap primitive with 1px edge tolerance, matching the phase16_parity.spec.mjs idiom."

key-files:
  created:
    - priv/dev/e2e/lib/axe.mjs
    - priv/dev/e2e/lib/boxes_intersect.mjs
    - .planning/phases/40-accessibility-motion-and-responsive-proof/40-GAP-REGISTER.md
  modified:
    - priv/dev/package.json

key-decisions:
  - "priv/dev/package-lock.json is NOT committed, despite the plan/research assuming lockfile-commit discipline — the repo's own .gitignore (commit 7e1cde4b) explicitly excludes it as a local install artifact, and CI's `npm ci || npm install` fallback + package.json-only cache key already assume no committed lockfile. The exact-pin devDependency + overrides entries are the real reproducibility contract."
  - "buildAxeScan() calls .options({rules: {target-size: {enabled: true}}}) BEFORE .withTags(WCAG_TAGS) — verified live against a real Chromium page that this ordering enables target-size while still excluding best-practice-tagged rules (e.g. region); the reverse order would silently drop the tag filter per AxeBuilder's internal implementation."

requirements-completed: [A11Y-01, A11Y-02, RESP-01]

coverage:
  - id: D1
    description: "@axe-core/playwright pinned exact 4.12.1 as a dev-only devDependency with axe-core pinned via overrides"
    requirement: "A11Y-02"
    verification:
      - kind: unit
        ref: "node -e package.json/package-lock.json assertion (devDependency not dependency, exact 4.12.1, overrides.axe-core=4.12.1)"
        status: pass
      - kind: integration
        ref: "npm --prefix priv/dev ci resolves node_modules/axe-core to exactly 4.12.1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Shared axe.mjs helper builds a scan with the five locked WCAG tags (never best-practice) and enables target-size via a rules override"
    requirement: "A11Y-02"
    verification:
      - kind: integration
        ref: "live Chromium scan via buildAxeScan(page).analyze(): target-size present in results, region (best-practice) absent"
        status: pass
    human_judgment: false
  - id: D3
    description: "Shared boxesIntersect(a,b) geometry primitive for occlusion checks (D-17)"
    requirement: "A11Y-01"
    verification:
      - kind: unit
        ref: "node --input-type=module smoke test: overlapping rects detected true, disjoint rects false"
        status: pass
    human_judgment: false
  - id: D4
    description: "Working gap register opened with schema + D-20 prefers-contrast/forced-colors non-goal pre-seed row"
    requirement: "A11Y-02"
    verification:
      - kind: other
        ref: "test -f + grep -qi 'forced-colors|prefers-contrast' + grep -qi 'boundary' on 40-GAP-REGISTER.md"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-03
status: complete
---

# Phase 40 Plan 01: Shared Accessibility/Motion Proof Infrastructure Summary

**Dev-only `@axe-core/playwright@4.12.1` pin (exact + transitive `axe-core` override) plus two shared harness modules — a single axe-run builder that correctly threads the WCAG tag list and the `target-size` rule override, and a single `boxesIntersect(a,b)` geometry primitive — so no later Phase 40 spec re-pins, re-derives, or drifts on either.**

## Performance

- **Duration:** 3 min (fast, wall-clock between first and last task commit; infra-only, no runtime code touched)
- **Started:** 2026-07-03T16:28:00Z (approx, first task commit)
- **Completed:** 2026-07-03T16:30:45Z (last task commit)
- **Tasks:** 3 completed
- **Files modified:** 4 (1 modified, 3 created)

## Accomplishments
- `@axe-core/playwright` added as an exact-pinned (`4.12.1`), dev-only `devDependency` in `priv/dev/package.json`, with an `overrides.axe-core = "4.12.1"` entry so the transitive dependency can't drift on its own tilde range. Verified resolving to exactly `4.12.1` via `npm ci` in a fresh install.
- Created `priv/dev/e2e/lib/axe.mjs`: the single shared axe scan builder every later axe spec (full-lab report-only + curated real-page assert-zero) must import. Fixes the five locked WCAG tags and explicitly re-enables `target-size` (axe-core 4.12.1 ships it disabled by default — confirmed by live scan, not assumed).
- Created `priv/dev/e2e/lib/boxes_intersect.mjs`: the single shared `boxesIntersect(a,b)` axis-aligned overlap primitive for both the upcoming drawer-focus dynamic-occlusion check and the responsive-scan static-occlusion check.
- Opened `.planning/phases/40-accessibility-motion-and-responsive-proof/40-GAP-REGISTER.md` as a working artifact with the required schema (defect id, requirement, surface/page, viewport/AT, repro, boundary crossed, status) and pre-seeded the `prefers-contrast`/`forced-colors` D-20 non-goal row.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin @axe-core/playwright dev-only with transitive axe-core override** - `715cb721` (feat)
2. **Task 2: Create shared axe-run helper and boxesIntersect geometry helper** - `9d8d0dbf` (feat)
3. **Task 3: Open the running gap register working artifact** - `64a9cdb0` (docs)

**Plan metadata:** (this commit, see final_commit step)

## Files Created/Modified
- `priv/dev/package.json` - Added `@axe-core/playwright@4.12.1` devDependency + `overrides.axe-core` pin
- `priv/dev/e2e/lib/axe.mjs` - Shared `buildAxeScan(page)`/`runAxeScan(page)` helper, fixed WCAG tag list + `target-size` rules override
- `priv/dev/e2e/lib/boxes_intersect.mjs` - Shared `boxesIntersect(a, b, tolerance=1)` geometry helper
- `.planning/phases/40-accessibility-motion-and-responsive-proof/40-GAP-REGISTER.md` - Working gap register, schema + D-20 pre-seed

## Decisions Made
- **`priv/dev/package-lock.json` stays uncommitted.** The plan (following 40-RESEARCH.md) assumed the lockfile is git-tracked and instructed committing it alongside the pin. On inspection, `priv/dev/package-lock.json` has never been tracked in this repo's git history — it's explicitly gitignored (`.gitignore:41`, dating to commit `7e1cde4b`, comment: "node_modules + lockfile are local install artifacts, not committed"). `git add` on the file confirms git refuses it ("ignored by one of your .gitignore files"). The CI e2e job (`.github/workflows/ci.yml:94`) already runs `npm --prefix priv/dev ci || npm --prefix priv/dev install` — a ci-or-fallback-to-install pattern that only makes sense if no lockfile is expected in a fresh checkout — and its cache key hashes only `package.json`, not the lockfile. D-05's actual intent ("pin transitive axe-core too so a floating release can't flip CI") is fully satisfied by the exact `devDependencies` pin + `overrides` entry in `package.json` itself; the lockfile's role is purely local install-speed/reproducibility, regenerated fresh on every `npm install`/`npm ci` run (verified: `npm ci` in a clean local run resolves `axe-core` to exactly `4.12.1` from the pinned `package.json`, with no committed lockfile required). This is a Rule 1 (research/plan factual correction), not a scope change — no new dependency, no drift risk introduced; the plan's `files_modified` listed `package-lock.json` under an incorrect premise inherited from 40-RESEARCH.md.
- **`.options()` called before `.withTags()`** in `axe.mjs`'s `buildAxeScan`. `AxeBuilder#options()` performs a wholesale replace of the builder's internal option object, while `#withTags()` only merges its `runOnly` key onto whatever is already set. Calling them in the reverse order would silently wipe the `target-size` rules override the moment `.withTags()` ran. Verified directly by reading the installed `@axe-core/playwright@4.12.1` dist source and by a live Chromium scan (target-size fires, best-practice-tagged `region` does not).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Plan/research factual correction] `package-lock.json` is gitignored, not git-tracked**
- **Found during:** Task 1 (pin `@axe-core/playwright`)
- **Issue:** The plan's Task 1 action and `files_modified` frontmatter both assumed `priv/dev/package-lock.json` is git-tracked ("matching the existing `playwright: 1.60.0` lockfile discipline") and instructed committing it. `git ls-files` and `git log -- priv/dev/package-lock.json` both confirm it has never been tracked; `.gitignore:41` explicitly excludes it (deliberate decision, commit `7e1cde4b`, 2026-06-04).
- **Fix:** Ran `npm install` (which regenerates the local, gitignored lockfile with the new pins, satisfying local `npm ci` reproducibility) but did NOT force-add or commit `package-lock.json`. Committed only `package.json` for Task 1.
- **Files modified:** `priv/dev/package.json` only (not `package-lock.json`)
- **Verification:** `npm --prefix priv/dev ci` resolves `axe-core` to exactly `4.12.1` locally; `git add priv/dev/package-lock.json` explicitly refused by git with an "ignored by .gitignore" message, confirming the convention is real and intentional, not an oversight.
- **Committed in:** `715cb721` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 — plan/research factual correction, no code/behavior change)
**Impact on plan:** No scope creep; the underlying D-05 intent (exact-pin + no-drift) is fully met via `package.json`. The plan's stated `files_modified`/`must_haves.artifacts` list for `package-lock.json` is technically not satisfied as a *committed* file, but is satisfied as an *on-disk, npm-ci-reproducible* file, which is what D-05 actually needs from it.

## Issues Encountered
None beyond the deviation above.

## User Setup Required
None - no external service configuration required. `@axe-core/playwright` is a dev-only devDependency; no host-facing changes.

## Next Phase Readiness
- `priv/dev/e2e/lib/axe.mjs` and `priv/dev/e2e/lib/boxes_intersect.mjs` are ready for Wave 2 plans (motion drift guard, drawer/modal focus spec, axe scan spec, responsive scan spec) to import directly — no re-pinning or re-deriving needed.
- `40-GAP-REGISTER.md` is open and ready to accumulate out-of-scope findings from Plans 40-02 through 40-05.
- No blockers for Wave 2.

---
*Phase: 40-accessibility-motion-and-responsive-proof*
*Completed: 2026-07-03*
