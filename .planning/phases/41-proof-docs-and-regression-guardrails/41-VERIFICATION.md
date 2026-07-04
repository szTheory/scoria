---
phase: 41-proof-docs-and-regression-guardrails
verified: "2026-07-04T18:11:31Z"
status: passed
score: 11/13 must-haves verified
behavior_unverified: "1 # D-13 drawer-focus e2e invariant is present + wired but not independently re-executed by this verifier (requires booting a dev server + Playwright browser, out of spot-check scope)"
overrides_applied: 0
re_verification: null
human_verification:

  - [object Object]
  - [object Object]

---

# Phase 41: Proof, Docs, And Regression Guardrails Verification Report

**Phase Goal:** Lock the milestone into durable tests, screenshots, docs, and drift guards so future design-system work is idempotently improving.
**Verified:** 2026-07-04T18:11:31Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Focused ExUnit tests cover shared UI components, approval flow, incident/review/dataset scan patterns, and drift guards (Roadmap SC1) | ✓ VERIFIED | Ran the 6 phase-touched test files directly: `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/single_header_rendered_guard_test.exs test/scoria_web/single_header_guard_test.exs test/scoria_web/design_system_doc_contract_test.exs` → 36 tests, 0 failures. Pre-existing suites (`approvals_live_test.exs`, `incidents_live_test.exs`, dataset tests, drift guards) confirmed unchanged and part of the full-suite green baseline (see truth 13). |
| 2 | `dismiss_candidate` with no candidate selected leaves the LiveView alive with a graceful notice (CR-01(39-review)) | ✓ VERIFIED | `lib/scoria_web/live/review_queue_live.ex:54-68` — exhaustive `else` clause confirmed present, returns `{:noreply, socket}` + notice. Locking test in `review_queue_live_test.exs` passed. |
| 3 | `ReleaseWorkbenchLive.mount/2` assigns a default `:origin_context` so `render/1` never depends on callback order (WR-04) | ✓ VERIFIED | `lib/scoria_web/live/prompt_live/release_workbench_live.ex:49` — `assign(:origin_context, nil)` in `mount/2`, confirmed present; `handle_params/3:59-60` still overrides. Locking test passed. |
| 4 | `.scoria-table__viewport` carries an `aria-label` (D-18) and the a11y guard asserts it | ✓ VERIFIED | `lib/scoria_web/ui.ex:1320` — `aria-label="Scrollable table content"` present. `a11y_structural_guard_test.exs:130-134` asserts it via regex; test passed. |
| 5 | A rendered-DOM guard proves region titles never restate the page title across routed pages (D-06/GAP-A, PROOF-03's 8th regression) | ✓ VERIFIED | `test/scoria_web/single_header_rendered_guard_test.exs` exists, is substantive (9 parameterized route tests, real `Floki`-based Router/Endpoint harness, honesty-caveat skip list for 4 param routes), namespaced `ErrorView` fix for the cross-plan compile collision is present (`ScoriaWeb.SingleHeaderRenderedGuardTest.ErrorView`). Ran and passed. |
| 6 | One `docs/design_system.md` defines every named design-system convention with a real enforcing guard (PROOF-02) | ✓ VERIFIED | File exists, 11 `## ` sections confirmed (`grep -c` = 11: BEM & CSS selectors, Tokens, Page headers, Stats, Overlays, Evidence & code, Copy controls, Fixtures, Motion, Accessibility, Screenshot-proof + drift-guard roster). Spot-read confirms substantive Rule→SSOT→Guard→Example content citing real file paths, not placeholders. |
| 7 | The doc cannot silently drift — a contract test fails if a named guard disappears, a cited token vanishes, or a section heading is dropped; wired into the CI policy lane as merge-blocking | ✓ VERIFIED | `test/scoria_web/design_system_doc_contract_test.exs` exists (3 checks); ran and passed. `.github/workflows/ci-verify.yml:56` includes the test path in the policy job's `mix test --no-start --warnings-as-errors` step. `test/scoria/ci_policy_contract_test.exs:21,662,667,669` asserts the lane-contract step names and orders it. |
| 8 | Screenshot matrix captures component-lab states and toast legibility via `/_lab/overlays` (D-14) | ⚠️ PRESENT (visual judgment — see Human Verification) | `SCREENS` entries confirmed in both `priv/dev/shots.mjs:177` and `priv/dev/contact_sheet.mjs:72`; `priv/shots/contact_sheet_index.md:91-105` documents the new screen and a 2026-07-04 dated run (12/12 captures, 0 toast-sanity warnings). Actual legibility of the rendered PNGs is a visual judgment call this verifier cannot make from source alone — routed to human verification. |
| 9 | The toast is actually present in every capture — harness re-navigates before each theme×viewport shot to beat the 4000ms auto-hide (D-15) | ✓ VERIFIED | `priv/dev/shots.mjs:250-269` — confirmed the `freshMountPerCapture` branch re-navigates (`page.goto`), re-awaits ready, and re-sets theme before every capture (not once per screen), with a non-throwing sanity-check warning if the toast count is 0. Logic is sound and genuinely wired, not decorative. |
| 10 | The committed `contact_sheet_index.md` manifest enumerates the new `lab_overlays` screen | ✓ VERIFIED | `grep -c lab_overlays priv/shots/contact_sheet_index.md` confirms 3 occurrences documenting the screen, run, and honest 0-paired-diff note. |
| 11 | The D-04/D-13 drawer live-patch focus-survival collector is flipped from report-only to a hard blocking assertion | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `priv/dev/e2e/drawer_focus.spec.mjs:284-330` confirms the `console.warn`/`testInfo.attach` pattern is gone and the D-13 test now uses throwing `expect()` calls. This is a runtime focus-preservation invariant across an async PubSub re-render — code presence/wiring is confirmed, but this verifier did not boot a dev server + Playwright browser to independently re-execute the test (out of spot-check scope, no server/service startup). SUMMARY documents one dated passing run. Routed to human verification. |
| 12 | `41-GAP-REGISTER.md` separates fixed-in-v3.3 (Section A) from explicitly-deferred (Section B) from surfaced-but-unfixed (Section B2, with live file:line proof) (D-17, Roadmap SC4) | ✓ VERIFIED | File exists with exactly this three-part structure. Independently re-verified all 5 Section B2 findings still live against current source: WR-01 (`approvals_live/index.ex:684-689`, no reload/patch in the `{:error, reason}` branch — confirmed), WR-02 (`:250`, `has_more` off-by-one — confirmed), IN-01 (`approval_copy.ex:369-370`, float-division `money_amount/1` — confirmed), IN-02 (`approvals_live/index.ex:434-440`, pending-scope `reload_inbox/1` doesn't reset `:decision_receipts` — confirmed), `.scoria-kbd` (`assets/css/04-components.css:432-441`, `min-height: 22px` — confirmed still 2px short of the 24px floor). None were laundered or silently fixed. |
| 13 | A verification-evidence manifest maps PROOF-01/02/03 to green artifacts and names the pre-existing red tests so no "suite green" claim is false (D-19, Roadmap SC5) | ✓ VERIFIED | `41-05-SUMMARY.md`'s "Verification Evidence Manifest" section present, maps all 3 requirements to real artifacts. Independently ran the full suite (`mix test`): **3 doctests, 937 tests, 3 failures** — exact match to the claimed baseline. Confirmed 2 of the 3 named failures by direct re-run (`ci_policy_contract_test.exs:692` stale `v2.15` assertion; `support_copilot_gallery_test.exs:8` Ecto-sandbox race in the nested example project) and confirmed the third (`capture_parity_test.exs:53`) passes deterministically in isolation (`mix test test/scoria/warning_inventory/capture_parity_test.exs` → 2 tests, 0 failures), matching the documented "full-suite-order flake" characterization. No new regressions found. |

**Score:** 11/13 truths verified (1 present-but-visual-judgment routed to human, 1 present-and-wired-but-behaviorally-unexercised-by-this-verifier)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/scoria_web/live/review_queue_live.ex` | Exhaustive `else` on `dismiss_candidate` | ✓ VERIFIED | Confirmed lines 54-68 |
| `lib/scoria_web/live/prompt_live/release_workbench_live.ex` | `mount/2` defensive `:origin_context` | ✓ VERIFIED | Confirmed line 49 |
| `lib/scoria_web/ui.ex` | `.scoria-table__viewport` aria-label | ✓ VERIFIED | Confirmed line 1320 |
| `test/scoria_web/live/review_queue_live_test.exs` | CR-01 regression test | ✓ VERIFIED | Present, passes |
| `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` | WR-04 regression test | ✓ VERIFIED | Present, passes |
| `test/scoria_web/a11y_structural_guard_test.exs` | Tightened to assert aria-label | ✓ VERIFIED | Present, passes |
| `test/scoria_web/single_header_rendered_guard_test.exs` | Net-new rendered-DOM guard | ✓ VERIFIED | Present, substantive (9 tests), passes |
| `docs/design_system.md` | 11 sections, Rule→SSOT→Guard→Example | ✓ VERIFIED | Present, 11 sections confirmed, substantive content |
| `docs/MAINTAINERS.md` | Cross-link to design_system.md | ✓ VERIFIED | Line 257 confirmed |
| `test/scoria_web/design_system_doc_contract_test.exs` | 3-check anti-drift contract | ✓ VERIFIED | Present, passes |
| `.github/workflows/ci-verify.yml` | Doc contract added to policy lane step | ✓ VERIFIED | Line 56 confirmed |
| `test/scoria/ci_policy_contract_test.exs` | `@design_system_doc_contract` + lane assertion | ✓ VERIFIED | Lines 21, 662, 667, 669 confirmed |
| `priv/dev/shots.mjs` | `lab_overlays` SCREENS entry + timing-safe capture | ✓ VERIFIED | Confirmed, logic sound |
| `priv/dev/contact_sheet.mjs` | Mirrored SCREENS entry | ✓ VERIFIED | Confirmed |
| `priv/shots/contact_sheet_index.md` | Regenerated manifest listing `lab_overlays` | ✓ VERIFIED | Confirmed |
| `priv/dev/e2e/drawer_focus.spec.mjs` | D-13 collector flipped to throwing assertion | ✓ VERIFIED (code); ⚠️ behavior not independently re-executed | Confirmed code shape; runtime pass not re-verified by this agent |
| `.planning/phases/.../41-GAP-REGISTER.md` | Sections A/B/B2 | ✓ VERIFIED | Confirmed structure and content, re-verified B2 findings live |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Each of the 3 fix/guard commits (CR-01, WR-04, D-18) | Its locking regression test | Red-before/green-after test cited in SUMMARY, test exists and currently passes | ✓ WIRED | Confirmed by running the tests |
| `single_header_rendered_guard_test.exs` | `lib/scoria_web/ui.ex` real CSS selectors | Floki assertions against `.scoria-pagehead__title h1` / `.scoria-panel__header h2` / `.scoria-page-section__header h2` | ✓ WIRED | Selectors confirmed to exist in `ui.ex`; test passes against real render |
| `docs/design_system.md` | Real guard test paths | Contract test's `File.exists?` check over every cited `test/..._test.exs` path | ✓ WIRED | Contract test passes |
| `ci-verify.yml` policy job | `design_system_doc_contract_test.exs` | Added to the `mix test --no-start --warnings-as-errors` file list | ✓ WIRED | Confirmed present |
| `ci_policy_contract_test.exs` | `ci-verify.yml`'s lane-contract step | `@design_system_doc_contract` module attr + ordering assertion | ✓ WIRED | Confirmed, test passes |
| `shots.mjs`/`contact_sheet.mjs` SCREENS | `dev/lab/sections/overlays.ex` toast fixture | `/_lab/overlays` route, `freshMountPerCapture` re-navigate loop | ✓ WIRED | Confirmed route path and capture logic |
| `41-GAP-REGISTER.md` Section A | Actual commits/tests | Cites specific commit hashes and test names for each fixed item | ✓ WIRED | Cross-checked against real source and passing tests |

### Data-Flow Trace (Level 4)

Not applicable — this phase's artifacts are tests, documentation, CI wiring, and dev-only screenshot/e2e scripts, not components rendering dynamic application data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase-touched ExUnit regression tests all pass | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/single_header_rendered_guard_test.exs test/scoria_web/single_header_guard_test.exs test/scoria_web/design_system_doc_contract_test.exs` | 36 tests, 0 failures | ✓ PASS |
| Full suite matches the documented pre-existing-failure baseline (no new regressions) | `mix test` (full run, once) | 3 doctests, 937 tests, 3 failures (15 excluded) | ✓ PASS (matches SUMMARY claim exactly) |
| Named pre-existing failure #1 confirmed | `mix test --failed` | `ci_policy_contract_test.exs:692` stale `v2.15` assertion, exactly as documented | ✓ PASS (confirms pre-existing, not a regression) |
| Named pre-existing failure #2 confirmed | `mix test --failed` | `support_copilot_gallery_test.exs:8` Ecto-sandbox race in nested example project, exactly as documented | ✓ PASS (confirms pre-existing, not a regression) |
| Named pre-existing failure #3 confirmed as isolation-passing flake | `mix test test/scoria/warning_inventory/capture_parity_test.exs` | 2 tests, 0 failures | ✓ PASS (confirms documented flake characterization) |
| e2e drawer-focus D-13 invariant (browser-based) | Not run — requires dev server + Playwright | N/A | ? SKIP (routed to human verification, out of no-server spot-check scope) |
| Screenshot legibility of `/_lab/overlays` captures | Not run — visual judgment | N/A | ? SKIP (routed to human verification) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` conventions found in this project, and no PLAN/SUMMARY declares a probe script for this phase.

Step 7c: SKIPPED (no declared or conventional probes for this phase).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PROOF-01 | 41-01, 41-04, 41-05 | Focused tests + browser proofs (component-lab states, theme switching, overlays, mobile shell, copy affordances, toast legibility, core operator flows) | ✓ SATISFIED (with 1 human-judgment item outstanding — toast legibility) | Crash-fix tests pass; screenshot matrix code confirmed wired; visual legibility needs human sign-off |
| PROOF-02 | 41-03, 41-05 | Maintainer docs define conventions (BEM, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, drift guards) | ✓ SATISFIED | `docs/design_system.md` (11 sections) + doc-contract test + CI wiring all confirmed real and green |
| PROOF-03 | 41-01, 41-02, 41-05 | Drift guards prevent regressions to duplicate density controls, inconsistent stats, redundant single-region headers, raw palette leakage, inaccessible icon buttons, unreadable toasts, oversized copy buttons, untested component states | ✓ SATISFIED | All 8 named regressions have a live blocking guard; the 8th (rendered-DOM single-header) is net-new this phase and confirmed passing |

No orphaned requirements found — `.planning/REQUIREMENTS.md` maps only PROOF-01/02/03 to Phase 41, and all three are claimed (and satisfied) across the plan set.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in any of the 17 phase-touched files | — | None |

No debt markers, stub returns, or placeholder content found in any file this phase modified or created.

### Human Verification Required

### 1. Toast-legibility screenshot review

**Test:** Open the `/_lab/overlays` captures from a `mix scoria.ui.shots` run (PNGs are gitignored — regenerate locally if not already present) and eyeball at minimum the dark/light 1440px and 320px shots.
**Expected:** Toast icon + message text + dismiss control are clearly legible in both themes and both widths, without visual collision with the stacked drawer/modal overlay probe underneath.
**Why human:** Legibility and contrast are a visual judgment call — this phase's own design intentionally keeps screenshots as human evidence, never a CI gate (D-13/VISUAL-CI-01 deferred).

### 2. D-13 drawer-focus invariant, independent re-execution

**Test:** With a local dev server running, execute the single named Playwright test `D-13: focus survives an unrelated live PubSub patch while the drawer stays open` in `priv/dev/e2e/drawer_focus.spec.mjs` (now a throwing assertion, not a report-only collector).
**Expected:** The test passes — focus remains inside the still-open drawer's DOM subtree after an unrelated PubSub-driven live patch.
**Why human:** This is a runtime state-preservation invariant across an async re-render. This verifier confirmed the code is present and correctly shaped (throwing `expect()`, not `console.warn`) but did not start a dev server/browser to independently re-execute it, per the no-server spot-check constraint. The plan's SUMMARY documents one passing dated run from execution time; an independent re-run would close this out fully.

### Gaps Summary

No gaps found. All must-haves from the ROADMAP success criteria and all 5 plans' frontmatter are either fully verified against the actual codebase (11 of 13 truths) or present-and-wired with only a runtime/visual confirmation step remaining that this verifier could not perform without starting a server (2 of 13 truths, both routed to human verification, neither indicating a defect). Independent re-execution of the two crash-fix regression tests, the D-06 rendered-DOM guard, the doc-contract test, and a full-suite run all confirm the phase's own claims hold up against the real codebase — including the honest claim that 3 specific ExUnit failures are pre-existing and unrelated (verified by direct re-run) and that 5 specific Section B2 findings (WR-01, WR-02, IN-01, IN-02, `.scoria-kbd`) remain genuinely unfixed and were not laundered into the "future work" section.

---

_Verified: 2026-07-04T18:11:31Z_
_Verifier: Claude (gsd-verifier)_
