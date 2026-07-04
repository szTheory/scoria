# Phase 41 Final Gap Register (v3.3 Design System Stress Test)

**Status:** FINAL — this is the polished, three-part register D-17 requires. It supersedes and
finalizes the Phase 40 working draft (`.planning/phases/40-accessibility-motion-and-responsive-proof/40-GAP-REGISTER.md`,
which opened empty of real defects except the GAP-40-000 non-goal).

**Precedent mirrored:** `.planning/MILESTONES.md` "v3.0 Known Gaps" + `.planning/milestones/v3.0-MILESTONE-AUDIT.md:131-138`'s
`gaps_found` fixed-vs-accepted split.

**Scope note (D-20):** This document is produced by Phase 41. It does **not** archive the
milestone — `MILESTONES.md`, `v3.3-MILESTONE-AUDIT.md`, and `REQUIREMENTS.md` are untouched here;
`/gsd-audit-milestone` and `/gsd-complete-milestone` consume this register.

---

## Section A — Fixed-in-v3.3

### A.1 The two D-16b crash-class fixes (owner-approved bounded fix lane, ✅ RESOLVED 2026-07-04)

| Finding | Location | Class | Fix | Locking regression test | Commits (Plan 41-01) |
|---|---|---|---|---|---|
| **CR-01(39-review)** | `lib/scoria_web/live/review_queue_live.ex:53-64` | CRASH — non-exhaustive `with` in `handle_event("dismiss_candidate", ...)` returned a bare `nil`/`{:error, changeset}` directly from `handle_event/3` | Added an exhaustive `else` clause returning `{:noreply, socket}` with notice `"Could not dismiss this candidate. Refresh and try again."` (copied verbatim from `39-REVIEW.md`'s own suggested fix) | `test/scoria_web/live/review_queue_live_test.exs` — `"dismiss_candidate with no selected candidate does not crash the LiveView"` | `c54d1e81` (test, RED) → `d90dc972` (fix, GREEN) |
| **WR-04** | `lib/scoria_web/live/prompt_live/release_workbench_live.ex:16-48,178` | CRASH — `mount/2` never assigned `:origin_context`; `render/1` read `@origin_context` unconditionally, `KeyError` if a render happened before `handle_params/3` ran | `mount/2` now defensively `assign(:origin_context, nil)`; `handle_params/3` (unchanged) still overrides it | `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` — `"WR-04: mount/2 assigns a safe :origin_context default render/1 does not depend on handle_params/3 having run first"` (direct-callback technique — `mount/2` + `render/1` + `Phoenix.HTML.Safe.to_iodata/1` forced evaluation; a bare `%Phoenix.LiveView.Rendered{}` struct match alone false-passed, see A1 pitfall below) | `0375ec1a` (test, RED) → `f35b1362` (fix, GREEN) |

**A1 pitfall discovered and worked around (Plan 41-01):** a bare `%Phoenix.LiveView.Rendered{}`
struct match does not force evaluation of the lazily-evaluated `dynamic` closure, so the plan's
originally-sketched WR-04 test silently false-passed on unfixed source. Fixed by adding
`Phoenix.HTML.Safe.to_iodata/1` to force real evaluation (mirrors what
`Phoenix.LiveViewTest.render/1` does under the hood) — see `41-01-SUMMARY.md` Deviations.

### A.2 D-18 — table-scroll screen-reader label (rides the D-16b lane)

| Finding | Location | Fix | Locking guard | Commit |
|---|---|---|---|---|
| **D-18** | `lib/scoria_web/ui.ex:1320` `.scoria-table__viewport tabindex="0"` had no `aria-label` | Added `aria-label="Scrollable table content"` | `test/scoria_web/a11y_structural_guard_test.exs` — `"the table scroll viewport stays keyboard-reachable (tabindex=\"0\", D-11 calmer-surface contract)"`, tightened to also assert the aria-label | `38a891ed` (fix + guard tightening, single commit — task not `tdd="true"`) |

### A.3 Already-fixed swept items (delivered before or during Phase 41, not re-touched by it)

| Item | Phase | Disposition |
|---|---|---|
| **CR-01(40, fixed)** — stacked modal-over-drawer window-Escape collision (Escape closed both the modal and the drawer instead of only the modal) | 40 (post-execution code review) | Fixed with a verified regression test during Phase 40. **Disambiguation:** this is a *different* finding from `CR-01(39-review)` above — do not conflate the two "CR-01" labels. |
| **WR-03** — a rejection toast was reporting the same green "decision recorded" tone as an approval, blurring a safety-relevant distinction | 39/40 (`approvals_live/index.ex` `record_approval_decision/2`, code comment cites "WR-03") | Fixed — rejection now shows a distinct `:warn` toast ("Approval denied - run is still waiting for approval.") |
| **`--scoria-text-subtle` token repoint** — AA contrast failure on the semantic alias | 40-04 | Fixed via token SSOT repoint (dark → muted-warm, light → graphite-700); pumice-500 primitive untouched. Axe curated assert-zero is green on all 7 seeded pages, both themes, as a result. |
| **`.scoria-button--sm` 24px floor** — WCAG 2.5.8 target-size violation found live during Phase 40-05 authoring | 40-05 | Fixed inline (found via a real dev-server run, not a plan sketch); locked by a throwing `expect()` in `responsive_scan.spec.mjs` (this is fix-and-assert-atomic per D-04, not a warning-grade collector). |
| **Toast legibility over dense approvals UI [P38]** — ROADMAP pending todo `make-approval-toasts-legible` | 38 | **DELIVERED in-milestone.** Belongs here, not as a deferral. |
| **Approval decision history for approved/denied/expired requests [P39, FLOW-04]** — ROADMAP pending todo `add-approval-decision-history` | 39 | **DELIVERED in-milestone.** Belongs here, not as a deferral. |
| **Swept 37/39/40 fixes** — smaller in-lane fixes found and fixed during their own phase's authoring rather than deferred: invalid p-in-p HEEx nesting bug in `dev/lab/sections/foundations.ex` that collapsed the reduced-motion signal (37-06); incidents copy routed through `IncidentCopy.severity_label/1` instead of a raw atom, required for the D-26 copy guard to be green (39-08); connectors `health_state`/`last_refresh_status` widened to the same status-badge fix as `runtime.status` (39-05); focus-restore hooks added at `workflow_detail_panel_component.ex`'s promote-modal opener so restore doesn't land on `<body>` (40-03). | 37/39/40 | Fixed in their originating phase's own lane; listed here per D-17's explicit instruction to carry them into the final register. |

### A.4 Phase 41's own PROOF-01/02/03 lock-and-document deliverables (new guards/docs closing previously self-declared or open items)

These are not "bug fixes" in the CRASH sense above — they are the phase's actual proof/document/guard
output, several of which close a previously self-declared coverage gap or an explicitly open
decision from Phase 40's hand-off. Listed here (not Section B/B2) because each is complete, green,
and delivered in-milestone:

| Deliverable | Closes | Evidence |
|---|---|---|
| `test/scoria_web/single_header_rendered_guard_test.exs` (D-06, GAP-A) | `single_header_guard_test.exs:28-30`'s self-declared "deferred to Phase-41 PROOF-03" rendered-DOM coverage gap — the 8th and final PROOF-03 named regression now has a live blocking guard | 9 parameterized route tests, all pass (`bda1d0e2`); documented honesty-caveat skip list (4 param routes with no comparable `:title` slot) |
| `docs/design_system.md` (11 sections) + `docs/MAINTAINERS.md` cross-link + `test/scoria_web/design_system_doc_contract_test.exs` (D-08–D-12) | PROOF-02 in full — every documented convention now names a real, verified enforcing guard, kept honest by a CI-gated anti-drift contract | `3a46a30e`, `82746042`, `ee5f296b`; 3 doc-contract tests + extended `ci_policy_contract_test.exs` lane-contract assertion pass |
| `priv/dev/shots.mjs` / `priv/dev/contact_sheet.mjs` `/_lab/overlays` toast-legibility capture + `freshMountPerCapture` strategy (D-14/D-15) | The two real screenshot-matrix gaps (component-lab states, toast legibility) Phase-40's `contact_sheet_index.md` never covered | `2d914ecc`, `8c66c23a`; real `mix scoria.ui.shots` run, `lab_overlays` 12/12 captures, 0 toast-sanity warnings, 3/12 PNGs manually eyeballed legible in both themes |
| `drawer_focus.spec.mjs` D-13 live-PubSub focus-survival collector flipped from `console.warn`+`testInfo.attach` to a throwing `expect()` (D-04 VERIFY-THEN-DEFER) | Phase 40's one open "genuine flip candidate" decision — **resolved as FLIPPED, not deferred**, since `mix scoria.ui.e2e` observed zero warnings on a real run | `0c7412ed` |

---

## Section B — Explicitly-deferred future work

These are intentional, previously-scoped-out items. None is a surfaced defect; all were already
named as out-of-scope before or during Phase 41 and remain so.

| Item | Source | Disposition |
|---|---|---|
| **STORYBOOK-01** — PhoenixStorybook | REQUIREMENTS.md Future Requirements | Deferred, later milestone |
| **UNDO-01** — approval reversal/undo | REQUIREMENTS.md Future Requirements | Deferred, later milestone |
| **AXE-PIPELINE-01** — promote axe to a required (blocking) CI lane | REQUIREMENTS.md Future Requirements | Deferred, later milestone. Axe full-lab scan stays report-only by design (specimen gallery legitimately fires `color-contrast`); curated seeded-page assert-zero remains the blocking proof. |
| **VISUAL-CI-01** — blocking screenshot pixel-diff CI gate | REQUIREMENTS.md Future Requirements | Deferred, later milestone. Screenshots stay human evidence (`priv/shots/contact_sheet_index.md`), never a gate, per D-13. |
| **GAP-40-000** — `prefers-contrast`/`forced-colors` (Windows High Contrast Mode) | `40-GAP-REGISTER.md` | Considered-and-deferred non-goal, not a defect — would require a new high-contrast token layer (locked-vocabulary boundary crossing). |
| **SEED-004** — test-code determinism (async `IntegrationCase`, remove `Process.sleep`, raise shard count) | STATE.md Deferred Items (v3.1 close) | Carried deferred; leading candidate for a future milestone. Not a Phase 41 surface. |
| **e2e-harness flakes** (6 pre-existing failures observed during Plan 41-04's Task 3 verification run: `command_palette.spec.mjs:76`, `drawer_focus.spec.mjs:214` [a *different* CR-01 test than Section A's], `modal_focus.spec.mjs:106`, `phase16_parity.spec.mjs:503/526/544`) | `deferred-items.md` (this phase) | None caused by any Phase 41 file change (all outside `files_modified` scope for Plan 04); 159 other e2e tests passed the same run. Candidate for a future e2e-harness flake/regression sweep. |
| **`target-size` (WCAG 2.5.8) report-only e2e tier** | CONTEXT.md D-03 | Stays report-only forever, by design — ratcheting it would red-wall the required e2e gate against the dense-table design intent. |
| **The optional shots-manifest coverage guard** (D-16-shots) | CONTEXT.md D-16-shots | Not built — premature until D-14's `SCREENS` set was corrected (now done); `dev_lab_boundary_test.exs` already owns PROOF-03's "untested component states" item, so this remains genuinely optional/nice-to-have, not a required PROOF-03 guard. |
| **Plan 04 screenshot capture** | N/A | No `MANUAL-CAPTURE-PENDING` fallback was needed — the dev server + Playwright environment was available and the real harness ran successfully (see Section A.4). |

**Reviewed but explicitly not folded into this milestone (out of scope entirely, not merely deferred-within-v3.3):**
`ci-policy-job-cache-key-mislabel` (CI copy cleanup, carried from v3.1 close) and
`docker-dx-fleet-hardening`/FLEET-01/FLEET-02 (sibling-repo fleet convergence) — both already
recorded as "Unmapped" in ROADMAP.md and reviewed-and-not-folded in `41-CONTEXT.md`'s Deferred
Ideas section; listed here only for completeness, not as v3.3 debt.

---

## Section B2 — Surfaced-but-UNFIXED (live proof + escalation note, D-16a)

Per the owner's D-16b decision, only the two CRASH-class bugs (Section A.1) and D-18 were opened
for a bounded in-lane fix. The following were **surfaced by the Phase 39/40 code reviews, confirmed
still live against current source during this plan, and are recorded here — not laundered into
Section B's "future work" column, and not fixed inline.**

| Finding | Location (verified live 2026-07-04) | Issue | Class | Escalation note |
|---|---|---|---|---|
| **WR-01** | `lib/scoria_web/live/approvals_live/index.ex:663-689` (`record_approval_decision/2`) | A successful approval decision followed by a failed `Resume.resume_run/1` reports a factually-wrong `"Could not record ... approval decision"` `:fail` toast — the decision *was* recorded; only the resume failed. The `else` branch also returns the socket with no `reload_inbox`/`push_patch`, so the just-decided approval keeps rendering as pending until an unrelated PubSub reload arrives. | UX/cosmetic (misleading message + stale UI, not a crash) | Deferred per owner's D-16b(a) pick (bounded 2-crash lane only). Candidate for a future UI-defect sweep or the next milestone's approval-flow hardening; the suggested fix (distinguish the decision-write success boundary from the resume-failure boundary, still reload/clear selection) is already documented in `39-REVIEW.md`. Not gating v3.3. |
| **WR-02** | `lib/scoria_web/live/approvals_live/index.ex:250` | `has_more={@scope == "decided" and length(@approval_inbox) >= @decided_limit}` — when the decided history contains exactly `@decided_limit` rows and no more, "Load more" renders anyway; clicking it re-fetches the same rows and only then hides the button. | Cosmetic (dead-click affordance, not a crash) | Deferred per D-16b(a). Standard fix (`fetch limit+1`, derive `has_more` from the extra row) already documented in `39-REVIEW.md`; not gating v3.3. |
| **IN-01** | `lib/scoria_web/approval_copy.ex:369-370` | `money_amount/1` formats money via `:erlang.float_to_binary(cents / 100, decimals: 2)` — float division on money is a fragile pattern if this helper is ever reused beyond a display label (currently masked correctly for display by `decimals: 2`). | Minor / info-level | Deferred per D-16b(a). Not a currently-observable display bug; recorded as accepted debt for the next time this helper is touched. |
| **IN-02** | `lib/scoria_web/live/approvals_live/index.ex:434` (`reload_inbox/1`'s pending-scope clause) | The pending-scope `reload_inbox/1` clause does not reset `:decision_receipts`, so stale decided-scope receipts linger in assigns after switching Decided → Pending. Currently harmless — `ApprovalInboxComponent` only reads `@decision_receipts` when `scope == "decided"` — but is dead state that will bite if the pending view ever starts consuming that map. | Minor / info-level | Deferred per D-16b(a). Suggested fix (`assign(:decision_receipts, %{})` in the pending clause) already documented in `39-REVIEW.md`; not gating v3.3. |
| **`.scoria-kbd` 22px min-height** | `assets/css/04-components.css:432-441` (`.scoria-kbd { min-width: 24px; min-height: 22px; ... }`) | Falls 2px short of the WCAG 2.5.8 (2.2) 24×24px minimum target-size floor that `.scoria-button--sm` was fixed to meet in Phase 40-05. | Minor / accessibility (out of WCAG target-size scope for this element per existing e2e tolerance) | Deferred — `.scoria-kbd` is a small inline keyboard-shortcut glyph, not a primary interactive control; the `target-size` e2e tier is report-only by design (D-03) and does not gate on it. Candidate for a future a11y-polish pass; not gating v3.3. |
| **`responsive_scan.spec.mjs:128` 1px rounding tolerance** | `priv/dev/e2e/responsive_scan.spec.mjs:113-124` (`undersizedTargets/1`, `Math.min(r.w, r.h) < 23` — a documented 1px tolerance below the 24px floor, matching WCAG 2.5.8's own allowance) | Not a defect — an intentional, documented tolerance for sub-pixel rendering rounding, matching the WCAG 2.5.8 spec's own allowance language (confirmed via the code comment directly above the check). | Non-issue (documented intentional tolerance) | Recorded here only because `41-CONTEXT.md` named it among the "minor IN-* items" to verify-and-record; confirmed still live and confirmed intentional (not a bug) — no escalation needed beyond this note. |

**Disambiguation (per D-16a):** `"CR-01(39-review)"` in Section A.1 is the live `dismiss_candidate`
crash fixed by this phase. `"CR-01(40, fixed)"` in Section A.3 is the already-fixed stacked-Escape
collision from Phase 40. These are two different findings that happen to share the "CR-01" label
from two different phases' code reviews — do not conflate them.

---

*Phase: 41-proof-docs-and-regression-guardrails*
*Register finalized: 2026-07-04*
*Produced by: Plan 41-05 (this phase does not archive the milestone — see D-20)*
