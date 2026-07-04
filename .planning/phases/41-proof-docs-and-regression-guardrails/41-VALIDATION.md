---
phase: 41
slug: proof-docs-and-regression-guardrails
status: populated
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-04
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Floki + Phoenix.LiveViewTest; Node/Playwright screenshot harness (`mix scoria.ui.shots`) |
| **Config file** | `test/test_helper.exs`; e2e/shots via `mix scoria.ui.*` |
| **Quick run command** | `mix test test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/single_header_rendered_guard_test.exs test/scoria_web/design_system_doc_contract_test.exs` |
| **Full suite command** | `mix test` (+ `mix scoria.ui.shots` for the contact-sheet evidence) |
| **Estimated runtime** | ~60-90 seconds (ExUnit); screenshot harness separate (needs dev server) |

---

## Sampling Rate

- **After every task commit:** Run the touched test file(s) (each task's `<automated>` command)
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full `mix test` green (modulo the 3 cited pre-existing red tests, D-21) + a fresh `mix scoria.ui.shots` capture (or documented MANUAL-CAPTURE-PENDING)
- **Max feedback latency:** ~90 seconds (ExUnit quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | PROOF-01 | T-41-01 | dismiss_candidate with no selection returns valid `{:noreply, socket}` + graceful notice (no LiveView crash) | unit (LiveViewTest, red→green) | `mix test test/scoria_web/live/review_queue_live_test.exs` | ✅ extend existing | ⬜ pending |
| 41-01-02 | 01 | 1 | PROOF-01 | T-41-02 | mount/2 assigns a safe `:origin_context`; render/1 never KeyErrors on callback-order change | unit (direct callback, red→green; A1 source-scan fallback) | `mix test test/scoria_web/live/prompt_live/release_workbench_live_test.exs` | ✅ extend existing | ⬜ pending |
| 41-01-03 | 01 | 1 | PROOF-03 | T-41-03 | `.scoria-table__viewport` carries an aria-label (guard tightened to assert it) | unit (source-scan, red→green) | `mix test test/scoria_web/a11y_structural_guard_test.exs` | ✅ extend existing | ⬜ pending |
| 41-02-01 | 02 | 1 | PROOF-03 | T-41-04 | rendered region titles never restate the rendered page title on routed pages | integration (LiveViewTest + Floki) | `mix test test/scoria_web/single_header_rendered_guard_test.exs` | ❌ W0 — net-new (D-06 GAP-A) | ⬜ pending |
| 41-03-01 | 03 | 1 | PROOF-02 | T-41-05 | doc/guard matched pair: design_system.md names only real, existing guards | manual authoring + grep gate | `test -f docs/design_system.md && grep -c '^## ' docs/design_system.md` (expect 11) | ❌ W0 — net-new doc | ⬜ pending |
| 41-03-02 | 03 | 1 | PROOF-02 | T-41-05 | contract fails if a named guard path, cited token, or section heading drifts | unit (`File.read!` contract) | `mix test test/scoria_web/design_system_doc_contract_test.exs` | ❌ W0 — net-new (D-12) | ⬜ pending |
| 41-03-03 | 03 | 1 | PROOF-02 | T-41-06 | doc-contract test runs in the CI-gated policy lane-contract step | unit (CI-policy contract) | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria_web/design_system_doc_contract_test.exs` | ✅ extend existing | ⬜ pending |
| 41-04-01 | 04 | 1 | PROOF-01 | T-41-07 | toast captured inside the fresh 4000ms window across theme×viewport matrix (no empty-toast shots) | dev-tool (Node syntax + SCREENS grep) | `node --check priv/dev/shots.mjs && node --check priv/dev/contact_sheet.mjs && grep -c "lab_overlays" priv/dev/shots.mjs priv/dev/contact_sheet.mjs` | ✅ extend existing | ⬜ pending |
| 41-04-02 | 04 | 1 | PROOF-01 | T-41-08 | committed manifest enumerates lab_overlays (or MANUAL-CAPTURE-PENDING recorded); no images committed | dev-tool (manifest grep) + advisory human-check | `grep -c "lab_overlays\|/_lab/overlays" priv/shots/contact_sheet_index.md \|\| echo "MANUAL-CAPTURE-PENDING recorded in SUMMARY"` | ✅ extend existing | ⬜ pending |
| 41-04-03 | 04 | 1 | PROOF-01 | T-41-07 | D-04 D-13 collector locked (flipped to throwing expect()) or deferred/registered — never flipped blind | dev-tool (Node syntax) + e2e-gated decision | `node --check priv/dev/e2e/drawer_focus.spec.mjs` | ✅ extend existing | ⬜ pending |
| 41-05-01 | 05 | 2 | PROOF-01,02,03 | T-41-09 | gap register keeps surfaced-but-unfixed (B2) distinct from deferred (B), with live proof | doc gate (grep) | `test -f .planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md && grep -Eic "section a\|section b2\|CR-01\|WR-04\|WR-01\|WR-02" .planning/phases/41-proof-docs-and-regression-guardrails/41-GAP-REGISTER.md` | ❌ W0 — net-new (D-17) | ⬜ pending |
| 41-05-02 | 05 | 2 | PROOF-01,02,03 | T-41-10 | evidence manifest maps PROOF-01/02/03 to green artifacts + names the 3 pre-existing red tests | doc gate (grep) | `grep -Eic "verification evidence manifest\|PROOF-01\|pre-existing" .planning/phases/41-proof-docs-and-regression-guardrails/41-05-SUMMARY.md` | ❌ W0 — net-new (D-19) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Red→green regression rows (D-16b crash lane):** 41-01-01 (CR-01) and 41-01-02 (WR-04) each carry a regression test whose assertion fails on today's source and passes only after the fix. 41-01-03 (D-18) similarly fails on the un-labeled `.scoria-table__viewport` and passes after the aria-label is added.

---

## Wave 0 Requirements

Framework already present (ExUnit + Floki + Phoenix.LiveViewTest + pinned Playwright); no install needed (D-01: no new runtime deps). Wave 0 gaps are net-new **files**, not new infrastructure:

- [x] Confirm existing ExUnit + `mix scoria.ui.shots` infrastructure covers phase requirements (no new framework install — scope fence D-01).
- [ ] `test/scoria_web/single_header_rendered_guard_test.exs` — net-new (D-06 GAP-A); authored in Plan 02.
- [ ] `test/scoria_web/design_system_doc_contract_test.exs` + `docs/design_system.md` — net-new (D-12/D-08); the doc must be authored in the same plan (Plan 03) as the contract test, which fails on a missing file.
- [ ] `41-GAP-REGISTER.md` — net-new (D-17); authored in Plan 05.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Contact-sheet toast legibility eyeball (advisory) | PROOF-01 | Screenshots are human-reviewable evidence, never a gate (D-13) | Open the regenerated contact sheet; confirm /_lab/overlays warn+fail toasts are legible in light+dark across 6 widths. Advisory only — recorded in the Plan 04 SUMMARY, not a blocking gate. |

*Every gating behavior has an automated verify. The one manual item above is advisory evidence (D-13), not a pass/fail gate.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (3 net-new files, framework already present)
- [x] No watch-mode flags
- [x] Feedback latency < 90s (ExUnit quick run)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** populated by planner 2026-07-04
