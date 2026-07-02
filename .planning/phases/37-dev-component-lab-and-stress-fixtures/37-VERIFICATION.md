---
phase: 37-dev-component-lab-and-stress-fixtures
verified: 2026-07-02T17:55:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: null
---

# Phase 37: Dev Component Lab And Stress Fixtures Verification Report

**Phase Goal:** Add a dev-only component lab and fixture matrix that make component quality visible across states, themes, and ugly data.
**Verified:** 2026-07-02T17:55:00Z
**Status:** passed
**Re-verification:** No — initial verification.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|------|--------|----------|
| 1 | Dev-only component lab is reachable in local dev and excluded from public dashboard mount / Hex runtime footprint | ✓ VERIFIED | Booted a real `mix phx.server` (SCORIA_DB_PORT=55432 PORT=4799) and `curl http://localhost:4799/scoria/_lab` returned HTTP 200. `git log 95f4fed..HEAD -- lib/scoria_web/router.ex` is empty (no diff). `grep "_lab" lib/scoria_web/router.ex lib/scoria_web/dashboard_nav.ex lib/scoria_web/components/layouts.ex` = zero matches. `mix.exs` `package/0` `files:` list has no `dev`, `priv/dev`, or `priv/shots` entries. `mix test --no-start test/scoria_web/dev_lab_boundary_test.exs test/scoria_web/ds06_drift_guard_test.exs` → 13/13 passing (independently re-run). |
| 2 | Lab renders `ScoriaWeb.UI` primitives and recurring groups across normal/long/empty/dense/disabled/selected/loading/warning/danger/error states | ✓ VERIFIED | `dev/lab/sections/primitives.ex` (18 primitives) and `dev/lab/sections/groups.ex` (5 real `lib/scoria_web/components/*.ex` groups: approval inbox, workflow tree, workflow detail, connector drawer, incident evidence) both route through `DevLab.Sections.States.states_band/1` fed by `DevLab.Fixtures.states_for/2`, which derives all 10 canonical D-11 states (`normal, long_text, empty, dense, disabled, selected, loading, warning, danger, error`) structurally. `state_tone/1` clauses cover all 10 states, mapping `warning→:warn`, `danger/error→:fail`, `selected→:brand`, matching spec exactly. Independently confirmed via `grep` against source. |
| 3 | Lab exercises light, dark, system, reduced-motion, mobile, tablet, desktop, and wide layouts | ✓ VERIFIED | Independently ran the Playwright suite (`priv/dev/e2e/lab.spec.mjs`) against a live server I booted myself: 17/17 tests passed, including explicit light/dark theme persistence, `prefers-color-scheme` "system" mode, `emulateMedia({reducedMotion:'reduce'})` toggling the Foundations "Reduced motion" signal, and a real six-width `setViewportSize` scan (320/375/768/1024/1440/1920) asserting zero page-level horizontal overflow at each width. `dev/lab/sections/viewports.ex` frames all six D-13 proof-target widths with exact maintainer labels (`320px — small mobile` … `Wide desktop`), no device marketing names. |
| 4 | Dev fixture data covers approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, and empty/error cases with realistic and ugly values | ✓ VERIFIED | `dev/lab/fixtures.ex` `scenario/1` has all 15 byte-identical D-19/D-20 scenario clauses (verified via grep), covering all 8 domains with both a normal and empty/error scenario each (`review_queue_empty`, `dataset_empty`, `prompt_registry_empty` present). No `Scoria.Repo`/`Ecto.Query` reference; no nondeterministic call (`DateTime.utc_now`, `Ecto.UUID.generate`, `:rand.*`, etc.) found in the file. `dev/lab/sections/fixtures_view.ex` browses all 15 scenarios grouped by domain with the exact locked D-27 empty/error copy strings verified present verbatim. |
| 5 | Maintainer docs explain how to run and inspect the lab | ✓ VERIFIED | `docs/MAINTAINERS.md` has a "Component Lab (dev-only)" section. Grep-confirmed presence of `/scoria/_lab`, `dev/lab/fixtures.ex`, `mix scoria.ui.e2e`, `dev_lab_boundary_test.exs`, and a "maintainer-only" statement. |

**Score:** 5/5 ROADMAP success criteria verified, 0 present-but-behavior-unverified.

### Plan-Level Must-Haves (all 6 plans)

| Plan | Must-have | Status | Evidence |
|------|-----------|--------|----------|
| 37-01 | Boundary/coverage guard test passes, proves D-21 sole-enforcement | ✓ VERIFIED | Re-ran independently: 13/13 passing |
| 37-01 | 15 scenarios × 10 states, deterministic, HEEx-safe | ✓ VERIFIED | grep confirms all 15 `scenario/1` clauses; no nondeterministic calls found |
| 37-01 | `scenario/1`/`states_for/2` separate functions, no hand-authored matrix | ✓ VERIFIED | Confirmed in source — `states_for/2` is a generic structural transform |
| 37-01 | `state_tone/1` single mapping, never calls `ScoriaWeb.UI.tone/1` | ✓ VERIFIED | `grep "ScoriaWeb.UI.tone("` across all `dev/lab/**` = 0 matches; all 10 state clauses present and correctly mapped |
| 37-01 | No storybook/catalog dependency added | ✓ VERIFIED | `mix.exs` deps list has no `phoenix_storybook`/`phx_live_storybook`/`surface_catalogue`/`surface` |
| 37-01 | No `:tone` key in fixture maps | ✓ VERIFIED | The one `tone:` match in `fixtures.ex` is a key in the unrelated `inventory_id/1` lookup map (mapping the `ScoriaWeb.UI.tone/1` primitive itself to `"PRIM-TONE"`), not a fixture-data field. No scenario clause body contains a `:tone` key. |
| 37-02 | Foundations read-only token/type/spacing/motion inspection, no invented values | ✓ VERIFIED | `dev/lab/sections/foundations.ex` uses only `var(--scoria-*)` references; no raw hex found |
| 37-02 | Primitives renders 18 canonical primitives × 10 states, PRIM-* anchored | ✓ VERIFIED | Confirmed via guard #7 cross-reference test (13/13 passing) and direct source read |
| 37-03 | Groups renders real `lib/` component modules under stress, GROUP-* anchored | ✓ VERIFIED | `dev/lab/sections/groups.ex` imports/renders the actual `ApprovalInboxComponent`, `WorkflowTreeComponent`, `WorkflowDetailPanelComponent`, `ConnectorDetailDrawerComponent`, `IncidentEvidenceComponent` |
| 37-03 | Fixtures browser with locked D-27 copy | ✓ VERIFIED | Exact strings confirmed present verbatim in `fixtures_view.ex` |
| 37-04 | Viewports: exact D-13 labels, no device names | ✓ VERIFIED | grep confirms exact strings |
| 37-04 | Overlays: EXACTLY 7 curated D-10 probes, no 8th | ✓ VERIFIED | 7 numbered HEEx comments (`<%!-- 1. ... --%>` through `7.`) and 7 `<.panel>` elements — exact match |
| 37-05 | `/scoria/_lab` mounted only in `dev/dev_router.ex`, outside public macro | ✓ VERIFIED | Read `dev/dev_router.ex` directly — new scope is textually separate; `lib/scoria_web/router.ex` untouched |
| 37-05 | `handle_params/3` allowlist-only, never `String.to_atom/1` on param | ✓ VERIFIED | `grep "String.to_atom("` on both changed files = 0 matches |
| 37-06 | `lab.spec.mjs` proves route/theme/motion/viewport/overlay/dense/copy in a real browser | ✓ VERIFIED (independently re-run) | 17/17 passing against a server I booted myself, not just trusting the SUMMARY's claim |
| 37-06 | `docs/MAINTAINERS.md` documents the lab | ✓ VERIFIED | grep checks pass; "Component Lab" section present |
| 37-06 | No visual-diff/screenshot-regression CI job added (D-30) | ✓ VERIFIED | `git diff --stat 95f4fed..HEAD -- .github/workflows/ci.yml .github/workflows/ci-verify.yml` is empty |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `dev/lab/fixtures.ex` | 15 scenarios, states_for/2, inventory_id/1 | ✓ VERIFIED | 447 lines, compiles clean, all 15 scenario clauses present |
| `dev/lab/sections/states.ex` | state_tone/1, states_band/1, states_section/1 | ✓ VERIFIED | 96 lines, all functions present and correctly wired |
| `dev/lab/sections/foundations.ex` | Read-only token/type/spacing/motion inspection | ✓ VERIFIED | 200 lines, zero raw hex |
| `dev/lab/sections/primitives.ex` | 18 primitives × 10 states | ✓ VERIFIED | 491 lines |
| `dev/lab/sections/groups.ex` | Real component groups under stress | ✓ VERIFIED | 324 lines, imports real `lib/scoria_web/components/*.ex` modules |
| `dev/lab/sections/fixtures_view.ex` | Fixture catalog browser | ✓ VERIFIED | 187 lines, locked D-27 copy verbatim |
| `dev/lab/sections/viewports.ex` | 6 viewport frames | ✓ VERIFIED | 117 lines |
| `dev/lab/sections/overlays.ex` | 7 curated flow probes | ✓ VERIFIED | 327 lines, exactly 7 numbered probes |
| `dev/lab/lab_live.ex` | D-07 IA shell + section dispatch | ✓ VERIFIED | 121 lines, 7-section dispatch, allowlist param validation |
| `dev/dev_router.ex` | `/scoria/_lab` route mount | ✓ VERIFIED (modified) | New scope textually separate from public macro |
| `test/scoria_web/dev_lab_boundary_test.exs` | Boundary/coverage guard | ✓ VERIFIED | 190 lines, all assertions independently re-run and passing |
| `test/scoria_web/ds06_drift_guard_test.exs` | D-26 dev/ extension | ✓ VERIFIED (modified) | Extended, existing lib/ assertions untouched |
| `priv/dev/e2e/lab.spec.mjs` | Browser proof | ✓ VERIFIED | 313 lines, 17 tests, independently re-run 17/17 green |
| `docs/MAINTAINERS.md` | Component Lab maintainer section | ✓ VERIFIED (modified) | grep checks pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `dev/lab/sections/*.ex` | `DevLab.Fixtures.scenario/1` / `states_for/2` | Direct function calls | ✓ WIRED | Confirmed via compile-clean + guard test #7 |
| `dev/lab/sections/*.ex` | `DevLab.Sections.States.states_band/1` | Direct calls | ✓ WIRED | Confirmed via source read + compile |
| `dev/lab/lab_live.ex` | 7 section modules | `:if` conditional dispatch | ✓ WIRED | All 7 rendered without exception in live browser test |
| `dev/dev_router.ex` | `DevLab.LabLive` | `live/3` routes under `live_session :scoria_lab` | ✓ WIRED | HTTP 200 confirmed live |
| `lib/scoria_web/router.ex` | (must NOT reference `/_lab`) | n/a | ✓ CONFIRMED ABSENT | git diff empty since baseline commit |
| `dev/lab/sections/groups.ex` | `lib/scoria_web/components/*.ex` real modules | Direct component imports | ✓ WIRED | Confirmed via source read — actual production components rendered, not stand-ins |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Boundary/coverage guard (13 tests) | `mix test --no-start test/scoria_web/dev_lab_boundary_test.exs test/scoria_web/ds06_drift_guard_test.exs` | 13 tests, 0 failures | ✓ PASS |
| Dev compile clean | `MIX_ENV=dev mix compile --warnings-as-errors` | No output / clean | ✓ PASS |
| Lab route reachable | `curl http://localhost:4799/scoria/_lab` (live server booted for this verification) | HTTP 200 | ✓ PASS |
| Full browser proof | `npx playwright test --config e2e/playwright.config.mjs e2e/lab.spec.mjs` (against live server booted for this verification) | 17 passed (4.2s) | ✓ PASS |
| Full ExUnit suite | `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` | 3 doctests, 801 tests, 3 failures (15 excluded) | ✓ PASS (all 3 failures pre-existing/unrelated — see below) |

**Full-suite failure cross-check:** The 3 failures (`Scoria.CiPolicyContractTest`, `Scoria.WarningInventory.CaptureParityTest`, `Scoria.SupportCopilotGalleryTest`) match exactly the 3 items logged in `deferred-items.md` as pre-existing/unrelated (Phase 36 ROADMAP-version drift, a DB-connection race in an advisory gallery lane, and a nested-invocation timing issue in warning-inventory tooling's own self-test). None reference `dev/lab/`, `dev_lab_boundary_test.exs`, or `ds06_drift_guard_test.exs`.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| LAB-01 | 37-01, 37-05, 37-06 | Dev-only component lab reachable, no public macro/Hex change | ✓ SATISFIED | Route mounted only in `dev/dev_router.ex`, live HTTP 200 confirmed, `lib/scoria_web/router.ex` untouched, `mix.exs` package.files excludes `dev` |
| LAB-02 | 37-01–37-06 | Inspect states across themes/viewports/data-stress | ✓ SATISFIED | All 10 D-11 states + 6 viewports + theme/motion coverage independently verified via live Playwright run |
| FIXT-01 | 37-01, 37-03, 37-06 | Realistic/ugly fixture data across 8 domains + empty/error | ✓ SATISFIED | 15 scenarios across 8 domains, browsable via Fixtures section, documented in MAINTAINERS.md |

No orphaned requirements — `.planning/REQUIREMENTS.md`'s Phase 37 mapping table (`LAB-01 | 37`, `LAB-02 | 37`, `FIXT-01 | 37`) matches exactly the union of `requirements:` fields across all 6 plans.

### Anti-Patterns Found

None. Scanned all phase-modified files (`dev/lab/**`, `dev/dev_router.ex`, `test/scoria_web/dev_lab_boundary_test.exs`, `test/scoria_web/ds06_drift_guard_test.exs`, `priv/dev/e2e/lab.spec.mjs`, `docs/MAINTAINERS.md`) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER`, "coming soon"/"not yet implemented"-style copy, raw hex colors, and stray `:tone`-key fixture data. Zero matches. No `test.fixme(...)` calls in `lab.spec.mjs` — all 17 declared tests are real assertions, not deferred stubs.

### Human Verification Required

None. Every must-have that a prior plan flagged as `human_judgment: true` (visual/behavioral correctness across all specimens/states in a real browser) was closed by Plan 06's Playwright suite, which this verification independently re-ran against a live server (not just trusted from the SUMMARY) with 17/17 green.

### Gaps Summary

No gaps found. All 5 ROADMAP success criteria, all plan-level must-haves across all 6 plans, all 3 phase requirement IDs (LAB-01, LAB-02, FIXT-01), and all named threat-model mitigations (T-37-01 through T-37-06) were independently verified against the actual codebase — not merely accepted from SUMMARY.md claims. Verification included: re-running the boundary/drift guard test suite, re-compiling under `:dev` with warnings-as-errors, booting a real dev server and curling the route, independently re-running the full 17-test Playwright browser suite, and re-running the full ExUnit suite to confirm the 3 pre-existing failures are unchanged and unrelated.

---

_Verified: 2026-07-02T17:55:00Z_
_Verifier: Claude (gsd-verifier)_
