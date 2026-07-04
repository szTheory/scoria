---
phase: 41-proof-docs-and-regression-guardrails
plan: 03
subsystem: testing
tags: [docs, ci-contract, exunit, drift-guard, design-system]

# Dependency graph
requires:
  - phase: 41-proof-docs-and-regression-guardrails (plan 01)
    provides: D-18 aria-label on .scoria-table__viewport (cited in the Accessibility section)
  - phase: 41-proof-docs-and-regression-guardrails (plan 02)
    provides: single_header_rendered_guard_test.exs (cited in the Page headers section)
provides:
  - docs/design_system.md — 11-section maintainer conventions doc, each section naming a real, verified drift guard
  - MAINTAINERS.md cross-link into the design-system catalog section
  - design_system_doc_contract_test.exs — anti-drift contract keeping the doc and guards a matched pair
  - CI policy lane-contract wiring (ci-verify.yml + ci_policy_contract_test.exs) making the doc contract merge-blocking
affects: [41-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc-contract precedent (File.read! + String.contains?/Regex.scan, no DB, async: true) reused 1:1 from docker_dx_doc_contract_test.exs"
    - "Rule -> SSOT -> Guard -> Example fixed 4-part doc section shape (D-11), each section naming a real existing test/guard"

key-files:
  created:
    - docs/design_system.md
    - test/scoria_web/design_system_doc_contract_test.exs
  modified:
    - docs/MAINTAINERS.md
    - .github/workflows/ci-verify.yml
    - test/scoria/ci_policy_contract_test.exs

key-decisions:
  - "Guard-path regex in the doc contract (`~r/(test\\/[^\\s\\x60]+_test\\.exs)/`) scans for the `test/..._test.exs` substring anywhere in the doc rather than requiring the backtick span to start exactly at `test/` — the doc cites guards both as bare filenames (roster list) and as full `mix test test/...` invocations (per-section Guard lines), and only the latter form carries a checkable path."
  - "Token sample for the doc contract's check 2 is the three concrete tokens actually cited with full names in the doc (--scoria-text-subtle, --scoria-surface-app, --scoria-text) — the doc's `--scoria-dur-*`/`--scoria-ease-*`/`--scoria-toast-*` wildcard mentions are intentionally excluded since they are not full token names."
  - "Overlays section names a11y_structural_guard_test.exs (static role=dialog/aria-modal pairing) plus the e2e modal_focus.spec.mjs/drawer_focus.spec.mjs specs (browser-proven trap+restore) as its guard pair, since no single ExUnit test owns focus trap/restore end-to-end."
  - "BEM/selectors section states plainly per D-10 that no test enforces BEM structure directly — it is convention, guarded only for palette leakage via ds06_drift_guard_test.exs — rather than implying a structural enforcement that does not exist."
  - "Screenshot-proof section's Guard line documents that no automated pixel-diff gates screenshots by design (D-13/VISUAL-CI-01 deferred), and instead lists the full roster of blocking browserless drift guards named elsewhere in the doc, satisfying the 'drift-guard roster' half of the section."

patterns-established:
  - "A maintainer conventions doc's killer feature is naming the real enforcing guard per section, then locking that pairing with a 1:1 doc-contract test clone of a proven precedent (docker-DX) wired into the same CI policy lane."

requirements-completed: [PROOF-02]

coverage:
  - id: D1
    description: "docs/design_system.md documents 11 existing design-system conventions (BEM/selectors, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, screenshot-proof + drift-guard roster), each in Rule -> SSOT -> Guard -> Example shape naming a real, verified guard/token/SSOT; excluded from mix.exs extras and package.files."
    requirement: "PROOF-02"
    verification:
      - kind: unit
        ref: "grep -c '^## ' docs/design_system.md returns 11; every named guard path verified File.exists? during authoring"
        status: pass
    human_judgment: false
  - id: D2
    description: "One cross-link line added to docs/MAINTAINERS.md's design-system catalog section pointing at docs/design_system.md, mirroring the :3 docker-DX cross-link phrasing."
    requirement: "PROOF-02"
    verification:
      - kind: manual_procedural
        ref: "docs/MAINTAINERS.md diff — one new line before the 'ScoriaWeb.UI is the single enforced token gateway' paragraph"
        status: pass
    human_judgment: false
  - id: D3
    description: "test/scoria_web/design_system_doc_contract_test.exs — 3 checks (guard-path existence, token-name sample, section-heading pins), async: true, File.read! only, no DB, modeled 1:1 on docker_dx_doc_contract_test.exs."
    requirement: "PROOF-02"
    verification:
      - kind: unit
        ref: "mix test test/scoria_web/design_system_doc_contract_test.exs — 3 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "design_system_doc_contract_test.exs wired into the CI policy lane-contract step (ci-verify.yml) and asserted present (with ordering) in ci_policy_contract_test.exs, mirroring @docker_dx_doc_contract; no CI topology/job-name change."
    requirement: "PROOF-02"
    verification:
      - kind: unit
        ref: "mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria_web/design_system_doc_contract_test.exs — lane-contract-step test (line 654) passes; only the pre-existing unrelated v2.15 roadmap-ledger failure (D-21, deferred-items.md) remains red"
        status: pass
    human_judgment: false

# Metrics
duration: 45min
completed: 2026-07-04
status: complete
---

# Phase 41 Plan 03: Design-System Conventions Doc + Anti-Drift Contract Summary

**New `docs/design_system.md` (11 sections, Rule -> SSOT -> Guard -> Example) pairs every named dashboard design-system convention with the real, existing drift guard that enforces it, locked by a 1:1 clone of the docker-DX doc-contract precedent wired into the CI-gated policy lane — completing PROOF-02 as a matched pair with PROOF-03.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-07-04
- **Tasks:** 3
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments
- Authored `docs/design_system.md`: 11 sections (BEM & CSS selectors, tokens, page headers, stats, overlays, evidence & code, copy controls, fixtures, motion, accessibility, screenshot-proof + drift-guard roster). Every section names a real, verified guard test path, a real cited token, or a real code snippet pulled directly from `lib/scoria_web/ui.ex`, `assets/css/02-tokens.css`, `assets/css/05-motion.css`, `dev/lab/fixtures.ex`, and the existing guard suite — nothing invented. Kept the doc out of `mix.exs` ExDoc `extras` and `package.files`, mirroring the `docker_dev_dx.md`/`uat_automation.md` exclusion.
- Added one cross-link line to `docs/MAINTAINERS.md`'s "Design-system component catalog" section, mirroring the `:3` docker-DX cross-link's phrasing.
- Authored `test/scoria_web/design_system_doc_contract_test.exs`, modeled 1:1 on `test/scoria/docker_dx_doc_contract_test.exs`: `async: true`, `File.read!` only, no DB. Three checks: (1) every `test/..._test.exs` path the doc names resolves via `File.exists?`; (2) a 3-token sample (`--scoria-text-subtle`, `--scoria-surface-app`, `--scoria-text`) still appears in `02-tokens.css`; (3) all 11 section headings are pinned present.
- Wired the new contract test into the CI policy lane-contract step: added its path to `.github/workflows/ci-verify.yml`'s `mix test --no-start --warnings-as-errors` file list (adjacent to `docker_dx_doc_contract_test.exs`), and added `@design_system_doc_contract` + an ordering-aware assertion to `test/scoria/ci_policy_contract_test.exs`'s existing lane-contract-step test. No CI job name, topology, or matrix changed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author docs/design_system.md (11 sections) + MAINTAINERS.md cross-link** - `3a46a30e` (docs)
2. **Task 2: Author design_system_doc_contract_test.exs (3 checks, 1:1 on docker-DX precedent)** - `82746042` (test)
3. **Task 3: Wire the doc-contract test into the CI policy lane-contract step** - `ee5f296b` (test)

**Plan metadata:** (recorded below after STATE/ROADMAP update)

## Files Created/Modified
- `docs/design_system.md` - New maintainer conventions doc: 11 sections, each Rule -> SSOT -> Guard -> Example, naming a real guard/token/SSOT.
- `docs/MAINTAINERS.md` - One cross-link line added in the design-system catalog section.
- `test/scoria_web/design_system_doc_contract_test.exs` - New anti-drift contract: guard-path existence, token-name sample, section-heading pins.
- `.github/workflows/ci-verify.yml` - Added the new test path to the policy job's lane-contract step.
- `test/scoria/ci_policy_contract_test.exs` - Added `@design_system_doc_contract` module attr + extended lane-contract-step assertion (with ordering).

## Decisions Made
- Guard-path extraction regex in the contract test scans for `test/..._test.exs` substrings anywhere in backtick-fenced text (not just backtick-anchored-at-`test/`), since the doc cites guards both as bare filenames in the roster and as full `mix test test/...` command lines per section.
- Token sample uses three concrete full token names actually cited in the doc (`--scoria-text-subtle`, `--scoria-surface-app`, `--scoria-text`); the doc's wildcard-form mentions (`--scoria-dur-*`, `--scoria-ease-*`, `--scoria-toast-*`) are excluded from the sample since they are not complete token names.
- The Overlays section pairs a static ExUnit guard (`a11y_structural_guard_test.exs`, role=dialog/aria-modal presence) with the browser-proven e2e specs (`modal_focus.spec.mjs`, `drawer_focus.spec.mjs`) for focus trap/restore, since no single ExUnit test owns that behavior end-to-end.
- BEM/selectors section states plainly (per D-10) that no test enforces BEM structure directly — "convention, guarded only for palette leakage via `ds06_drift_guard_test.exs`" — rather than implying an enforcement that doesn't exist.
- Screenshot-proof section documents, per D-13, that no automated pixel-diff gate exists by design, and instead lists the full roster of blocking browserless drift guards named earlier in the doc, satisfying the "drift-guard roster" half of the section honestly.

## Deviations from Plan

None - plan executed exactly as written. All acceptance criteria met on first pass: 11 `## ` sections confirmed via `grep -c`, every named guard path verified with `File.exists?` before landing (none invented), the MAINTAINERS.md cross-link is a single new line, `docs/design_system.md` is absent from both `mix.exs` `extras` and `package.files`, and the 3 doc-contract tests plus the extended CI policy lane-contract assertion all pass.

## Issues Encountered
None. The full `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria_web/design_system_doc_contract_test.exs` run shows exactly one failure — `ci_policy_contract_test.exs:692`'s stale `assert roadmap =~ "v2.15"` — which is a pre-existing, unrelated red test documented in Phase 40's `deferred-items.md` (D-21: the roadmap is now v3.3 and legitimately has zero `v2.15` occurrences; confirmed pre-existing at baseline commit `bc22ffa8`). Not touched, per D-21's "record, do not fix" instruction (that fix belongs to `/gsd-complete-milestone` bookkeeping).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PROOF-02 is now satisfied: `docs/design_system.md` documents all 11 named conventions, each paired to a real, verified guard, kept honest by a CI-gated anti-drift contract test.
- PROOF-02 and PROOF-03 are now a matched pair as intended by D-10: every guard the design-system doc names is a real, existing, blocking test; the doc-contract test itself is merge-blocking in the same policy lane as the docker-DX precedent.
- Plan 05 (final gap register + verification-evidence manifest) can reference `docs/design_system.md`, its 11 section headings, and the guard/token roster this plan pins as the PROOF-02 artifact.

---
*Phase: 41-proof-docs-and-regression-guardrails*
*Completed: 2026-07-04*
