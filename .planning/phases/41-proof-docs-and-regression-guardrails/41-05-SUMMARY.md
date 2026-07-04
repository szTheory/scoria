---
phase: 41-proof-docs-and-regression-guardrails
plan: 05
subsystem: testing
tags: [gap-register, verification-evidence, milestone-closeout, docs]

# Dependency graph
requires:
  - phase: 41-proof-docs-and-regression-guardrails (plan 01)
    provides: "CR-01(39-review) + WR-04 crash fixes + D-18 aria-label, each locked by a regression test"
  - phase: 41-proof-docs-and-regression-guardrails (plan 02)
    provides: "single_header_rendered_guard_test.exs closing the D-06 GAP-A self-declared coverage deferral"
  - phase: 41-proof-docs-and-regression-guardrails (plan 03)
    provides: "docs/design_system.md (11 sections) + design_system_doc_contract_test.exs + CI policy-lane wiring"
  - phase: 41-proof-docs-and-regression-guardrails (plan 04)
    provides: "/_lab/overlays screenshot coverage, updated contact_sheet_index.md, D-04/D-13 collector flip, deferred-items.md (6 pre-existing e2e failures)"
provides:
  - "41-GAP-REGISTER.md — the final three-part gap register (Section A fixed-in-v3.3, Section B deferred future work, Section B2 surfaced-but-unfixed)"
  - "The D-19 verification-evidence manifest (this SUMMARY's own section) mapping PROOF-01/02/03 to real green artifacts, citing the 3 pre-existing red mix test failures per D-21"
affects: [milestone-close, gsd-audit-milestone, gsd-complete-milestone]

tech-stack:
  added: []
  patterns:
    - "Fixed-vs-deferred-vs-surfaced three-part gap register (mirrors v3.0's gaps_found precedent) as the durable proof-of-record a milestone audit consumes"
    - "Verification-evidence manifest as a manifest of pointers (not a re-proof) — cites the exact existing green artifacts and names pre-existing red tests by identity, never claiming an unqualified 'suite green'"

key-files:
  created:
    - .planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md
  modified: []

key-decisions:
  - "D-06's guard, PROOF-02's doc+contract, the D-14/D-15 screenshot additions, and the D-04/D-13 collector flip were placed in Section A (not treated as separate 'fixes') since each closes a previously self-declared or explicitly-open item and was delivered in-milestone — labeled distinctly from the CRASH-class fixes as 'Phase 41's own PROOF-01/02/03 lock-and-document deliverables' so the register stays honest about what kind of item each row is."
  - "Kept the 6 pre-existing e2e failures (command_palette, drawer_focus's different CR-01 test, modal_focus, phase16_parity x3) in Section B (deferred future work), separate from the 3 pre-existing red mix test failures (D-21), since they are a different lane (Playwright e2e vs ExUnit) with a different verified-pre-existing basis (deferred-items.md, this phase, vs 40-.../deferred-items.md, Phase 40)."
  - "D-16-shots (optional shots-manifest coverage guard) recorded in Section B as genuinely optional/nice-to-have, not built — dev_lab_boundary_test.exs already owns PROOF-03's 'untested component states' item, so it does not double as a required PROOF-03 guard."

requirements-completed: [PROOF-01, PROOF-02, PROOF-03]

coverage:
  - id: D1
    description: "41-GAP-REGISTER.md authored with the D-17 three-part structure (Section A fixed-in-v3.3 incl. both crash fixes + D-18 each citing its locking test and the two DELIVERED ROADMAP todos; Section B deferred future work; Section B2 surfaced-but-unfixed WR-01/WR-02/IN-* with live file:line proof re-verified against current source)."
    requirement: "PROOF-03"
    verification:
      - kind: other
        ref: "test -f .planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md && grep -Eic 'section a|section b2|CR-01|WR-04|WR-01|WR-02' .planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "Verification Evidence Manifest (D-19) section authored in this SUMMARY, mapping PROOF-01/PROOF-02/PROOF-03 to the real green artifacts Phases 36-41 produced, and explicitly naming the 3 confirmed pre-existing red mix test failures as pre-existing/unrelated/not-fixed per D-21."
    requirement: "PROOF-01"
    verification:
      - kind: other
        ref: "grep -Eic 'verification evidence manifest|PROOF-01|PROOF-02|PROOF-03|pre-existing' .planning/phases/41-proof-docs-and-regression-guardrails/41-05-SUMMARY.md"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-04
status: complete
---

# Phase 41 Plan 05: Final Gap Register + Verification Evidence Manifest Summary

**Authored the milestone-closing bookkeeping: `41-GAP-REGISTER.md`'s three-part fixed/deferred/surfaced-unfixed structure (mirroring the v3.0 `gaps_found` precedent) and this SUMMARY's D-19 verification-evidence manifest, which maps PROOF-01/02/03 to the real green artifacts Phases 36-41 produced and names all 9 confirmed pre-existing red tests (3 ExUnit + 6 Playwright) so no "suite green" claim in the milestone record is false.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-04T17:33:32Z (baseline: STATE.md session marker after Plan 41-04)
- **Completed:** 2026-07-04T17:50:10Z
- **Tasks:** 2 completed
- **Files modified:** 1 created (`41-GAP-REGISTER.md`), 1 created (this SUMMARY)

## Accomplishments

- Authored `41-GAP-REGISTER.md` with the D-17-mandated three-part structure: **Section A** (fixed-in-v3.3 — the two D-16b crash fixes + D-18, each citing its locking regression test; already-fixed swept items from Phases 37/39/40; the two ROADMAP pending todos recorded as DELIVERED, not deferred; and Phase 41's own PROOF-01/02/03 lock-and-document deliverables), **Section B** (explicitly-deferred future work — STORYBOOK-01/UNDO-01/AXE-PIPELINE-01/VISUAL-CI-01, GAP-40-000, SEED-004, the 6 pre-existing e2e failures, the optional D-16-shots guard), and **Section B2** (surfaced-but-unfixed — WR-01, WR-02, and the minor IN-* items, each re-verified live against current source with `file:line` proof and an escalation note).
- Re-verified every Section B2 finding directly against current source before recording: `approvals_live/index.ex:663-689` (WR-01, still returns the misleading "could not record" toast on resume failure with no reload/patch), `approvals_live/index.ex:250` (WR-02, `has_more` off-by-one still present), `approval_copy.ex:369-370` (IN-01, float-division `money_amount/1` unchanged), `approvals_live/index.ex:434` (IN-02, pending-scope `reload_inbox/1` clause still does not reset `:decision_receipts`), and `assets/css/04-components.css:432-441` (`.scoria-kbd` still `min-height: 22px`, 2px short of the 24px WCAG 2.5.8 floor). None was fixed — all recorded as accepted debt per the owner's D-16b(a) bounded-lane decision.
- Authored the **Verification Evidence Manifest (D-19)** below, mapping PROOF-01/02/03 to real, existing green artifacts (a manifest of pointers, not a re-proof of Phases 36-40), and explicitly naming the 3 confirmed pre-existing red `mix test` failures (per D-21) plus the 6 confirmed pre-existing `mix scoria.ui.e2e` failures (per Plan 41-04's `deferred-items.md`) as pre-existing/unrelated/not-fixed-in-this-phase.
- Touched no milestone-archival files (`MILESTONES.md`, `v3.3-MILESTONE-AUDIT.md`, `REQUIREMENTS.md` untouched) per D-20.

## Task Commits

1. **Task 1: Author 41-GAP-REGISTER.md (Sections A / B / B2)** - `aa0e3371` (docs)
2. **Task 2: Author the D-19 verification-evidence manifest** - (this SUMMARY's own commit, below)

**Plan metadata:** captured in the final metadata commit alongside STATE.md/ROADMAP.md updates.

## Files Created/Modified

- `.planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md` — the final three-part gap register (Sections A/B/B2).
- `.planning/phases/41-proof-docs-and-regression-guardrails/41-05-SUMMARY.md` — this file, carrying the D-19 evidence manifest.

## Verification Evidence Manifest (D-19)

**Purpose:** map PROOF-01/PROOF-02/PROOF-03 to the real, existing green artifacts Phases 36-41
produced. This is a manifest of pointers — it does **not** re-prove 36-40's work, and it does
**not** claim an unqualified "suite green" (D-21: 3 confirmed pre-existing red `mix test` failures
and 6 confirmed pre-existing `mix scoria.ui.e2e` failures are named explicitly below, not hidden).

### PROOF-01 — Focused tests + browser proofs (component-lab states, theme switching, overlays, mobile shell, copy affordances, toast legibility, core operator flows)

| Artifact | Status | Evidence |
|---|---|---|
| Crash-free core operator flows (Review Queue, Prompt Release Workbench) | GREEN | `test/scoria_web/live/review_queue_live_test.exs` (CR-01(39-review) regression) + `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` (WR-04 regression) — both pass; `41-01-SUMMARY.md` confirms 21/21 tests across the three touched files |
| Existing operator-flow ExUnit suites (already satisfied PROOF-01's focused-test half per D-07 — no net-new suites needed) | GREEN | `approvals_live_test.exs`, `approvals_live_integration_test.exs`, `incidents_live_test.exs`, `dataset_live/*`, `approval_copy_test.exs` — pre-existing, unchanged this phase, part of the full `mix test` green baseline (modulo the 3 named pre-existing failures below) |
| Component-lab states + theme switching + overlays + mobile shell + copy affordances (browser proof) | GREEN (dated run) | `priv/shots/contact_sheet_index.md` "Phase 41 Update (2026-07-04)" addendum — real `mix scoria.ui.shots` run against a local dev server, all screens across 2 themes × 6 viewports |
| Toast legibility (the one real screenshot-matrix gap this phase closed, D-14/D-15) | GREEN (dated run, human-spot-checked) | `/_lab/overlays` added to `shots.mjs`/`contact_sheet.mjs` `SCREENS`; 2026-07-04 run: `lab_overlays` 12/12 captures, 0 toast-sanity warnings; 3 of 12 PNGs manually eyeballed (`populated_dark_w1440`, `populated_light_w1440`, `populated_dark_w320`) — both `warn`/`fail` tone toasts legible in both themes at desktop and narrow-mobile width, over the stacked drawer/modal overlay probe |
| `mix scoria.ui.e2e` (the required browser-proof gate) | GREEN except 6 confirmed pre-existing failures (named below) | Full run during Plan 41-04 Task 3: 159 passed, 6 failed, 3 skipped, 1.6m — the D-13 live-PubSub focus-survival test itself passed cleanly with zero warnings (basis for the D-04 flip decision) |
| D-13 drawer live-patch focus-survival collector | GREEN, now a hard gate | `priv/dev/e2e/drawer_focus.spec.mjs` — flipped from `console.warn`+`testInfo.attach` to a throwing `expect()` after the verify-then-defer run above observed zero warnings (D-04) |

### PROOF-02 — Maintainer docs define conventions (BEM, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, screenshot proof)

| Artifact | Status | Evidence |
|---|---|---|
| `docs/design_system.md` (11 sections, Rule→SSOT→Guard→Example) | GREEN | Authored in Plan 41-03; every section names a real, verified guard/token/SSOT (none invented); excluded from `mix.exs` ExDoc `extras` and `package.files` (mirrors `docker_dev_dx.md`/`uat_automation.md`) |
| `docs/MAINTAINERS.md` cross-link | GREEN | One new line in the existing design-system catalog section (`:255-336`), mirroring the docker-DX `:3` cross-link precedent |
| `test/scoria_web/design_system_doc_contract_test.exs` (anti-drift contract, 1:1 modeled on `docker_dx_doc_contract_test.exs`) | GREEN | 3 checks (guard-path `File.exists?`, token-name sample, section-heading pins) — all pass |
| CI policy lane-contract wiring | GREEN (except the 1 pre-existing failure named below) | `.github/workflows/ci-verify.yml` + `test/scoria/ci_policy_contract_test.exs`'s `@design_system_doc_contract` assertion — `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria_web/design_system_doc_contract_test.exs` passes except the pre-existing stale `v2.15` assertion (named below, D-21) |

### PROOF-03 — Drift guards prevent regressions (duplicate density controls, inconsistent stats, redundant single-region headers, raw palette leakage, inaccessible icon buttons, unreadable toasts, oversized copy buttons, untested component states)

All 8 named regressions now have a live, blocking guard (7 already did per D-05; this phase closed the 8th, D-06):

| Named regression | Guard | Status |
|---|---|---|
| Redundant single-region headers (static-literal) | `test/scoria_web/single_header_guard_test.exs` | GREEN (pre-existing) |
| Redundant single-region headers (rendered-DOM, the D-06 GAP-A closure) | `test/scoria_web/single_header_rendered_guard_test.exs` | GREEN (net-new, Plan 41-02 — 9 parameterized route tests) |
| Raw palette leakage | `test/scoria_web/ds06_drift_guard_test.exs` | GREEN (pre-existing) |
| Inaccessible icon buttons + table-viewport SR label (D-18) | `test/scoria_web/a11y_structural_guard_test.exs` | GREEN (tightened in Plan 41-01 to also assert the D-18 aria-label) |
| Unreadable toasts | `test/scoria_web/toast_opacity_guard_test.exs` | GREEN (pre-existing) |
| Oversized copy buttons | `test/scoria_web/ui_component_test.exs:1632/1645/1657` | GREEN (pre-existing) |
| Inconsistent stats | `test/scoria_web/ui_component_test.exs:357` (`overview_stats` contract) + `:1610` (`signal_strip` removed) | GREEN (pre-existing) |
| Duplicate density controls | `test/scoria_web/ui_component_test.exs:1273-1300` | GREEN (pre-existing) |
| Untested component states | `test/scoria_web/dev_lab_boundary_test.exs` | GREEN (pre-existing) |

### The gap register itself

| Artifact | Status |
|---|---|
| `.planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md` | Complete — Sections A/B/B2 authored this plan (see Task 1 above) |

### Naming the pre-existing red tests honestly (D-21 — no "suite green" claim without this)

**3 confirmed pre-existing red `mix test` (ExUnit) failures, unrelated to v3.3, not fixed in this phase:**

1. **`Scoria.CiPolicyContractTest`** — `test/scoria/ci_policy_contract_test.exs:692` — `assert roadmap =~ "v2.15"` — stale; ROADMAP is now v3.3 and legitimately has zero `v2.15` occurrences. Already tracked as a Phase 40 D-21 deferred item (`40-.../deferred-items.md`); the `v2.15→v3.3` contract update is `/gsd-complete-milestone`'s bookkeeping lane, not Phase 41's — **recorded, not fixed**, per D-21.
2. **`Scoria.WarningInventory.CaptureParityTest`** — `test/scoria/warning_inventory/capture_parity_test.exs:53` — a full-suite-order-sensitive compile-cache flake; passes deterministically in isolation (verified twice, `2 tests, 0 failures`). Not touched by any Phase 41 file.
3. **`Scoria.SupportCopilotGalleryTest`** — `test/scoria/support_copilot_gallery_test.exs:8` — `DBConnection.ConnectionError` sandbox-ownership race in the nested `examples/support_copilot` gallery runner. Entirely within the untouched `examples/support_copilot` subtree.

**6 confirmed pre-existing red `mix scoria.ui.e2e` (Playwright) failures, unrelated to v3.3, not fixed in this phase** (observed during Plan 41-04's Task 3 verification run, logged in this phase's own `deferred-items.md`):

| Spec | Test | Failure |
|---|---|---|
| `command_palette.spec.mjs:76` | keyboard shortcuts overlay opens/closes/traps focus | `#scoria-shortcuts` not visible after pressing `?` |
| `drawer_focus.spec.mjs:214` | CR-01: Escape while the decision modal is stacked over the drawer cancels ONLY the modal | `#approval-detail-drawer` not visible — drawer never opened for this test |
| `modal_focus.spec.mjs:106` | trap: Tab/Shift+Tab wrap correctly | Shift+Tab landed on the wrong focusable id |
| `phase16_parity.spec.mjs:503/526/544` (×3) | MOTION-04 theme toggle flips and page stays ready (Home/Workflows-table/Workflow-detail) | Theme toggle button never became visible/stable within 30s |

None of these 9 pre-existing failures (3 ExUnit + 6 Playwright) touch any file `files_modified` by Phases 41-01 through 41-05. **This phase's own new/extended tests are all green**: the two crash-fix regression tests, the D-18-tightened a11y guard, the D-06 rendered-DOM guard (9/9), the design-system doc contract (3/3), the CI policy lane-contract assertion, and the D-13 drawer live-patch collector (now a throwing assertion, passed).

## Decisions Made

- Placed D-06's guard, PROOF-02's doc+contract, the D-14/D-15 screenshot additions, and the D-04/D-13 collector flip in Section A of the gap register (labeled distinctly as "Phase 41's own PROOF-01/02/03 lock-and-document deliverables") rather than treating them as bare "fixes" — each closes a previously self-declared or explicitly-open item and was fully delivered in-milestone, so Section A (not B or B2) is the honest home.
- Kept the 6 pre-existing e2e failures in the gap register's Section B (deferred future work) distinct from the 3 pre-existing ExUnit failures named in this manifest under D-21 — different test lane, different verified-pre-existing basis, both honestly named rather than either being hidden.
- Re-verified all 5 Section B2 findings' `file:line` citations directly against current source (not trusting the CONTEXT.md citations blindly) before recording them — all 5 confirmed still live.

## Deviations from Plan

None - plan executed exactly as written. Both tasks (the gap register and the evidence manifest) were pure documentation/bookkeeping work with no code changes, no new dependencies, and no touch to any milestone-archival file (`MILESTONES.md`, `v3.3-MILESTONE-AUDIT.md`, `REQUIREMENTS.md` all confirmed untouched).

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 41 is now complete: all 5 requirements-bearing plans (01-05) delivered, all 3 phase requirements (PROOF-01, PROOF-02, PROOF-03) satisfied and evidenced.
- `41-GAP-REGISTER.md` and this SUMMARY's D-19 evidence manifest are the durable proof-of-record `/gsd-audit-milestone` will consume when it writes `v3.3-MILESTONE-AUDIT.md` — this plan deliberately did not touch that file or `MILESTONES.md` (D-20).
- The 3 pre-existing ExUnit failures (stale `v2.15` roadmap assertion, WarningInventory flake, SupportCopilot sandbox race) and the 6 pre-existing e2e failures remain open, named, and not this milestone's regression — candidates for `/gsd-complete-milestone` bookkeeping (the v2.15→v3.3 contract update specifically) and a future e2e-harness flake/regression sweep, respectively.

---
*Phase: 41-proof-docs-and-regression-guardrails*
*Completed: 2026-07-04*
