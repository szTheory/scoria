# Phase 41: Proof, Docs, And Regression Guardrails - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

> **Research-backed + red-team-hardened, one-shot decisions.** The four gray areas were each resolved
> by a dedicated research pass grounded in the live repo, then **adversarially red-teamed** by a fifth
> agent whose only job was to find where those decisions were wrong against the actual code. The
> red-team produced material deltas — the decisions below are the **hardened** locked spec. Decisions
> changed by the red-team are marked **(revised)**. Read **D-01 The Proof-Lock Stance** first; the
> whole phase hangs off it, and it draws the load-bearing line the milestone's integrity depends on.

<domain>
## Phase Boundary

Phase 41 is the **milestone-closing lock** of v3.3 "Design System Stress Test." It takes what Phases
36–40 built and *proved warning-grade* and makes it **durable and idempotently-improving**: focused
tests + browser proofs a maintainer can re-run (`PROOF-01`), maintainer docs that define the
design-system conventions (`PROOF-02`), and blocking drift guards that prevent regressions
(`PROOF-03`) — plus a **final gap register** separating fixed-in-milestone from explicitly-deferred
work, and the **verification evidence** recorded before milestone close.

**The defining fact (verified):** Phase 40 already did the remediation. The Phase-40 gap register is
essentially empty of real defects; `drawer/1`+`modal/1` focus trap+restore is fixed; axe assert-zero
is green on 7 seeded pages in both themes; browserless MOTION/A11Y source-scan guards + reduced-motion
+ 6-width responsive e2e already exist. **Critically, the browserless ExUnit guards are already
BLOCKING** (they `assert offenders == []` and run in the `verify`/`e2e` CI lane that `ci-gate` hard-
fails on). So "harden the guards" is mostly *already done* — Phase 41 is a **thin lock-and-document
phase**, not a build phase. Its real work is: (1) two small net-new guards, (2) one conventions doc +
its anti-drift contract, (3) closing two screenshot-matrix gaps, (4) the final gap register + evidence
manifest, and (5) an **owner decision** about live bugs Phases 39–40 surfaced but never fixed.

**In scope:** proving (browser + ExUnit), documenting conventions, hardening/adding drift guards, the
screenshot evidence contact sheet, the final gap register, the verification-evidence manifest.

**Out of scope (deferred — do NOT pull in):**
- **New UI or any change to the locked primitive vocabulary** (tone/size/state enums; public
  `attr`/`slot` API of `button/table/drawer/modal/notebook/…`), the public `scoria_dashboard/2` macro,
  `.scoria-root` scoping, or Hex `package.files`. Phase 41 documents and proves; it does not rebuild.
- **New Hex runtime dependency.** Dev-only devDeps in `priv/dev/` are fine (`@axe-core/playwright`
  already added in Phase 40; `priv/dev`+`priv/shots` are excluded from `package.files`, `mix.exs:146-179`).
- **Blocking screenshot-diff pixel gate** (`VISUAL-CI-01`), **PhoenixStorybook** (`STORYBOOK-01`),
  **approval reversal/undo** (`UNDO-01`), **promoting axe to a required CI lane** (`AXE-PIPELINE-01`) —
  all explicit Future Requirements, later milestones. Phase-41 screenshots stay **human evidence, never
  a gate**.
- **Milestone archival** — writing `MILESTONES.md` / `v3.3-MILESTONE-AUDIT.md`, running the
  integration-checker, tagging/archiving: those belong to `/gsd-audit-milestone` + `/gsd-complete-
  milestone`, which *consume* Phase 41's artifacts. Phase 41 PRODUCES the durable proof/gap/evidence;
  it does not archive the milestone (D-19).
- **`prefers-contrast` / `forced-colors`** (Windows High Contrast) — explicit non-goal (GAP-40-000),
  recorded in the register as considered-and-deferred, not a defect.

</domain>

<decisions>
## Implementation Decisions

Requirements **PROOF-01, PROOF-02, PROOF-03** and the five Phase-41 success criteria are the locked
spec. The decisions below resolve *how* to prove, document, and lock — and where the scope line falls.

### D-01 — The Proof-Lock Stance (read first — the whole phase hangs off this)

Phase 41 **PROVES and LOCKS; it does not remediate.** The brief constraint is explicit: *no
remediation budget.* This has one hard consequence that the red-team confirmed is the milestone's
biggest integrity risk (see D-16): defects Phase 41 *surfaces or inherits* are **recorded and
escalated**, not silently fixed inline — with exactly **one owner-gated exception** (D-16b) for
crash-class functional bugs that falsify the milestone's own proof claims. The line is drawn by
**owner decision + scope boundary, never by fix-difficulty.** Everything else below is genuinely
lock-and-document work that reuses the existing harness; add no toolchain, no primitive, no runtime dep.

### Area 1 — Guard hardening, the collector→expect() flip, and focused ExUnit (PROOF-01, PROOF-03, criterion 1)

- **D-02 (revised · the flip is a near no-op — do not manufacture work):** The Phase-40 warning-grade
  language means **detection *style* (source-scan), not non-blocking.** All browserless ExUnit guards
  already end in throwing `assert offenders == []`/`refute` and run in the CI-gated `verify` lane — they
  are **already hard gates.** The Phase-40 e2e specs that matter (curated-page axe `toEqual([])`,
  responsive, modal/drawer focus trap+restore, reduced-motion) also already **throw and are verified
  green.** So there is **no bucket of warning-collectors waiting to be flipped.** Do not invent a
  "flip pass."
- **D-03 (two e2e tiers stay report-only *forever*, by design):** The **axe full-lab scan** stays
  report-only (the lab is a specimen gallery rendering muted/disabled/danger variants that *legitimately*
  fire `color-contrast`); the **curated seeded-real-page axe** assert-zero is the blocking proof.
  **`target-size` (2.5.8)** stays report-only (fights the dense-table design intent). Do not ratchet
  either — that would red-wall the required e2e gate against intentional specimens.
- **D-04 (the one genuine flip candidate · VERIFY-THEN-DEFER):** `drawer_focus.spec.mjs` **D-13**
  (live-PubSub focus-survival, `:280-329`) is the **sole** report-only collector on a real behavior
  (`console.warn`+`testInfo.attach`, no `expect()`). Its pass/warn state is **unrecorded** in
  `40-VERIFICATION.md`. Decision: **run the lane; if it never warns, flip to a throwing `expect()`
  (free lock, zero product code); if it warns/flakes, keep report-only and register a gap-register row**
  (the only fix would be a new restore hook = out of budget). **Fallback (locked):** if the executor
  **cannot run `mix scoria.ui.e2e`** (needs DB+server+browsers), D-13 **defaults to defer/register**,
  never flip-blind.
- **D-05 (PROOF-03 coverage · 7 of 8 already blocking):** Map each named regression to its live guard —
  redundant single-region headers → `single_header_guard_test.exs`; raw palette leakage →
  `ds06_drift_guard_test.exs`; inaccessible icon buttons → `a11y_structural_guard_test.exs`; unreadable
  toasts → `toast_opacity_guard_test.exs`; **oversized copy buttons → `ui_component_test.exs:1632/1645/1657`**
  (red-team correction — *not* `copy_guard_test.exs`, which guards status-via-label-fn); inconsistent
  stats → `ui_component_test.exs:357` (`overview_stats` contract) + `:1610` (`signal_strip` removed);
  duplicate density controls → `ui_component_test.exs:1273-1300`; **untested component states →
  `dev_lab_boundary_test.exs`** (already asserts every D-11 state / D-19-20 scenario / PRIM-*/GROUP-* id
  is referenced). All eight already have a blocking guard **except one**:
- **D-06 (the single required net-new guard · GAP-A):** `single_header_guard_test.exs:28-30` **self-
  declares** that its rendered-DOM semantic-restatement check is *deferred to Phase-41 PROOF-03* — today
  it is a pure `File.read!`+`Regex` static source-scan, no Floki/render. Phase 41 **adds the rendered-DOM
  LiveViewTest assertion** (Floki over a real LiveView render) that proves region titles never restate
  the page title in the *rendered* output. This is legitimate net-new PROOF-03 work and the phase's one
  required new drift guard.
- **D-07 (focused ExUnit criterion-1 is already satisfied — add no suites):** approvals
  (`approvals_live_test`, `approvals_live_integration_test`, `approval_copy_test`), incidents
  (`incidents_live_test`), review queue (`review_queue_live_test`), datasets (`dataset_live/`), and
  shared components (`ui_component_test`) are already richly covered. The **only** net-new ExUnit is the
  D-06 GAP-A assertion. Do **not** author broad new suites — this is a lock phase.

### Area 2 — Maintainer design-system docs (PROOF-02, criterion 3)

- **D-08 (home · one new topic file):** Create **one** new `docs/design_system.md` (short filename).
  **Do NOT** extend `MAINTAINERS.md` (already ~30 KB, CI/release-scoped, and *is* in ExDoc extras +
  `package.files`) and **do NOT** fan out to multiple files. This matches the sibling idiom (one topic
  per `docs/*.md`). **Keep it OUT of ExDoc `extras` and OUT of `package.files`** — exactly like
  `docs/docker_dev_dx.md` / `docs/uat_automation.md` (verified `mix.exs:127-139` extras, `:146-179`
  files) — it documents dev-only `dev/lab/**` + `test/**` guards + `assets/css/**` that never ship.
  Add **one cross-link line** from `MAINTAINERS.md`'s existing catalog section (`:255-336`), mirroring
  the `:3` docker-DX cross-link.
- **D-09 (audience boundary):** Adopter-facing component API = generated **ExDoc on `ScoriaWeb.UI`**
  (already the attr/slot SSOT). Maintainer-facing how/why (BEM/selector discipline, token flow, the
  Component Lab, fixtures, the drift-guard roster) = `docs/design_system.md`. Clean line, no adopter
  value lost.
- **D-10 (coverage · 11 sections, each a matched pair):** One section per named convention — **BEM/
  selectors, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion,
  accessibility, screenshot-proof + drift-guard roster** — each documenting an **existing** SSOT and
  **naming the real drift guard that enforces it** (the full SSOT→guard table is in GA-2 research, e.g.
  tokens → `brandbook/tokens.json`+`02-tokens.css` → `token_contrast_guard`/`toast_opacity_guard`;
  headers → `ui.ex object_header` → `single_header_guard`; motion → `05-motion.css` →
  `motion_drift_guard`+`reduced_motion.spec.mjs`; fixtures → `dev/lab/fixtures.ex`+`dev_seed.exs` →
  `dev_lab_boundary_test`). The **killer feature**: every section names a real guard, making the doc and
  the PROOF-03 guards a **matched pair** — that is what ties PROOF-02 to PROOF-03. The doc **documents
  existing convention only; it invents no new rules** (a convention with no enforcing guard, e.g. pure
  BEM naming, must say "convention, guarded only for palette leakage," not imply a new enforced rule).
- **D-11 (depth · fixed 4-part shape):** Each section is a tight ~6-12-line block:
  **Rule** (one sentence) → **SSOT** (the file[s], `file:line` where useful) → **Guard** (the enforcing
  test + exact `mix test <path>` command) → **Example** (one real snippet/class name, never invented).
- **D-12 (anti-drift for the doc · precedent-matched):** Add
  `test/scoria_web/design_system_doc_contract_test.exs`, modeled **1:1** on the confirmed existing
  `test/scoria/docker_dx_doc_contract_test.exs` (async, no DB, `File.read!`). Three minimal checks:
  (1) every guard path the doc names `File.exists?` (the matched-pair enforcer — rename a guard, the
  doc goes red); (2) a small sample of token names the doc cites still appear in `02-tokens.css`;
  (3) the 11 section headings are pinned present. Failure copy must say *"update the doc + this contract
  together."* **CI wiring (locked):** mirror the docker-DX precedent — add it to the policy job's
  lane-contract step (`.github/workflows/ci-verify.yml`) and assert it in `ci_policy_contract_test.exs`
  alongside `@docker_dx_doc_contract` (`:654-663`). It also runs for free in the default `test` lane.
  Do not go heavier (no token-by-token / DOM diff).

### Area 3 — Screenshot proof (PROOF-01, criterion 2)

- **D-13 (evidence, never a gate):** "Screenshot proof" = a dated, human-reviewable **contact-sheet
  baseline** a maintainer eyeballs — captured via the existing `mix scoria.ui.shots` (`priv/dev/shots.mjs`,
  6 viewports) rendered by `priv/dev/contact_sheet.mjs`. **No pixel diff, no CI screenshot assertion**
  (VISUAL-CI-01 stays deferred; Phase-40 D-14). PNGs/JSON/HTML are **gitignored**; the **committed
  proof-of-record is the markdown manifest** (`priv/shots/contact_sheet_index.md`), not the pixels.
  `priv/shots`+`priv/dev` are both excluded from `package.files` — **Phase 41 commits no images and adds
  zero Hex footprint** (verified `mix.exs:159-165`).
- **D-14 (revised · TWO real matrix gaps · red-team corrected GA-3):** The current `shots.mjs` matrix
  covers theme switching, overlays, collapsed mobile shell, static copy affordances, and the approvals
  flow — but **misses component-lab states and toast legibility.** ⚠ **GA-3's proposed fix was wrong and
  is REJECTED:** `dev/lab/sections/states.ex` renders **badges, not a toast**; the real static toasts
  live at **`dev/lab/sections/overlays.ex:91-94`** (the `RISK-TOAST-LEGIBILITY` fixture, `<.toast
  tone={:warn}/>`+`{:fail}`) and `primitives.ex:250`. **Locked:** add **`/_lab/overlays`** to the
  `shots.mjs` `SCREENS` set for toast legibility (optionally `/_lab/primitives`; `/_lab/states` may be
  added for the broader "component lab states" criterion but does **not** satisfy toasts). Mirror the
  additions into `contact_sheet.mjs`'s duplicate `SCREENS`.
- **D-15 (handle the toast auto-dismiss — do not claim false determinism):** `ScoriaWeb.UI.toast/1`
  (`ui.ex:936-957`) carries `phx-mounted={JS.hide(time: @duration_ms)}`, default **4000ms** — the lab
  toast **auto-hides ~4s after mount.** The plan must **name and verify** this race: capture inside the
  pre-hide window (shots captures shortly after `waitForReady`, which *may* suffice) or capture before JS
  settles / with a disconnected render. Do **not** ship the plan asserting determinism without proving
  the shot lands before the 4s hide.
- **D-16-shots (optional, deferred-in-place):** A browserless **shots-manifest coverage guard** (text-
  assert the `SCREENS` matrix still enumerates every required page/state so coverage can't silently
  shrink) is a **different surface** from PROOF-03 item-8 (`dev_lab_boundary_test` already owns "untested
  component states") — it is **optional/nice-to-have and premature** until the D-14 `SCREENS` set is
  corrected. Frame as optional; do not double-count it as the PROOF-03 guard.

### Area 4 — Final gap register + verification evidence + closeout boundary (criteria 4-5)

- **D-16 (revised · THE OWNER-GATED DECISION — the milestone's integrity hinge):** The red-team
  **CONFIRMED against current source** that four functional bugs surfaced in the Phase 39/40 reviews are
  **still live and were never fixed** (no fix commit exists; only Phase-40 CR-01 + WR-03 landed):
  | Finding | Location | Class |
  |---|---|---|
  | **CR-01(39-review)** crash-on-error — missing `else` → invalid callback return | `review_queue_live.ex:54-63` | **CRASH** |
  | **WR-04** unassigned `@origin_context` → `KeyError` on render | `release_workbench_live.ex:16-48,178` | **CRASH** |
  | **WR-01** false "could not record" toast + stale UI after a *successful* approve | `approvals_live/index.ex:663-689` | UX/cosmetic |
  | **WR-02** `has_more` off-by-one | `approvals_live/index.ex:250` | cosmetic |
  (+ minor IN-* items: float currency `approval_copy.ex:369`, stale receipts `:434`, `.scoria-kbd` 22px
  out of WCAG scope, rounding tolerance in `responsive_scan.spec.mjs:128`.) **These are recorded, with
  live `file:line` proof, in the final register's Section B2 — NOT laundered into a tidy "future work"
  column, and NOT silently fixed inline** (that would violate D-01's no-remediation-budget line, which
  the red-team flagged as the scope-creep leak to strip from GA-4).
  - **D-16a (default · locked):** Phase 41 **records + escalates** all four; the planner does **not**
    fix any inline unilaterally. Disambiguate labels: **"CR-01(39-review)"** (this live crash) vs
    **"CR-01(40, fixed)"** (the already-fixed stacked-Escape) or a reader conflates them.
  - **D-16b (owner exception · PENDING — ⚠ decision-under-owner-review):** Because the milestone's
    *entire charter is proving core operator flows* (criterion 1 / PROOF-01 explicitly list "core
    operator flows"), shipping v3.3 with **two known LiveView crashes** on the review-queue and
    release-workbench flows **falsifies the milestone's own proof claim.** **Recommended (my provisional
    call, owner may override at plan time):** open a **bounded fix lane for the two CRASH-class bugs
    only** — `CR-01(39-review)` + `WR-04` (both one-liner-class, neither crosses a locked boundary) —
    move them to **Section A (fixed-in-milestone)** each locked by a regression test; **defer WR-01/WR-02**
    (UX/cosmetic) to Section B2 as accepted tech debt. The owner picks one of: **(a)** this bounded
    2-crash fix pass [recommended]; **(b)** fix all four; **(c)** defer all four as recorded debt. Until
    the owner confirms, the planner **defaults to D-16a (record-only)**. *(User was away when asked;
    revisit before/at planning.)*
- **D-17 (final gap register · structure + home):** Lives at
  `.planning/phases/41-.../41-GAP-REGISTER.md` (a **phase** artifact — the milestone-level
  `v3.3-MILESTONE-AUDIT.md` is the audit step's job, D-19). Three parts:
  **Section A — fixed-in-v3.3** (CR-01(40) stacked-Escape, WR-03, the `--scoria-text-subtle` token
  repoint, the `.scoria-button--sm` 24px floor, toast legibility [P38], decision-history/FLOW-04 [P39],
  and swept 37/39/40 fixes) — the two ROADMAP "pending todos" (`make-approval-toasts-legible`,
  `add-approval-decision-history`) were **DELIVERED in-milestone** and belong here, **not** as deferrals.
  **Section B — explicitly-deferred future work** (STORYBOOK-01, UNDO-01, AXE-PIPELINE-01, VISUAL-CI-01;
  GAP-40-000 `prefers-contrast`/`forced-colors` non-goal; SEED-004 test-code determinism; the D-04 D-13
  live-patch survival if it defers; e2e-harness flakes).
  **Section B2 — surfaced-but-UNFIXED** (the D-16 findings, with live proof + the escalation note per
  D-16a/b). Model the fixed-vs-known-gaps split on the v3.0 precedent (`MILESTONES.md` "v3.0 Known Gaps"
  + `v3.0-MILESTONE-AUDIT.md:131-138` `gaps_found` acceptance).
- **D-18 (table-scroll SR label · same treatment as D-16):** Real gap — `ui.ex:1320`
  `.scoria-table__viewport tabindex="0"` has **no** `aria-label` (the guard checks only `tabindex`).
  Adding an internal `aria-label` is *not* a public attr/slot change, but it **is remediation** → treat
  identically to D-16: **register the disposition, do not apply unilaterally.** If the owner opens the
  D-16b fix lane, the label rides along and the guard tightens to assert it (genuine hardening);
  otherwise it goes to Section B as an accepted minor SR nit. It must not vanish.
- **D-19 (criterion-5 evidence · a manifest of pointers, not a re-proof):** "Full verification evidence"
  = a **verification-evidence manifest** (recommend a section in `41-SUMMARY.md`) mapping PROOF-01/02/03 →
  the existing green artifacts: the guard + operator-flow ExUnit suites, the `mix scoria.ui.e2e` green
  run, the dated 6-viewport contact sheet + updated `contact_sheet_index.md`, `docs/design_system.md`,
  the drift-guard roster, and `41-GAP-REGISTER.md`. **Record/point — do not re-prove 36–40.** Phase 41
  gets its own `41-VERIFICATION.md` via gsd-verify-phase.
- **D-20 (closeout boundary — do not over-reach):** Phase 41 **PRODUCES** the durable proof/gap/evidence
  *inside* the milestone. `/gsd-audit-milestone` **CONSUMES** them (writes `v3.3-MILESTONE-AUDIT.md`, runs
  the integration-checker); `/gsd-complete-milestone` **ARCHIVES/tags**. Phase 41 must **not** touch
  `MILESTONES.md`, write the audit doc, or archive `REQUIREMENTS.md`.
- **D-21 (criterion-5 honesty · cite the 3 pre-existing failures):** The full `mix test` suite has
  **3 confirmed pre-existing red tests** unrelated to this milestone (verified): a stale
  `ci_policy_contract_test.exs:691` `assert roadmap =~ "v2.15"` (ROADMAP is now v3.3 → 0 matches), a
  WarningInventory compile-cache flake, and a SupportCopilot sandbox race (all logged in
  `40-.../deferred-items.md:79-114`). The evidence manifest **must cite these as pre-existing** or any
  "suite green" claim is false. The `v2.15→v3.3` contract update is milestone-bookkeeping
  (complete-milestone's lane) — **record, do not fix** it in Phase 41.

### Claude's Discretion

Downstream agents choose: exact file/section names; the precise Floki assertion shape for D-06 GAP-A;
whether the D-16-shots manifest guard earns its keep after D-14 corrects `SCREENS`; the exact wording
of the 11 doc sections (as long as each names a real guard and invents no rule); how to capture the
toast before its 4s auto-hide (D-15). **Do not** expand the tone/size/state vocabularies locked in
36–39, add a runtime dep, add a blocking pixel gate, apply D-16/D-18 remediation without the owner
opening the D-16b lane, or archive the milestone. Prefer boring, minimal additions that reuse the
existing harness.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Milestone Scope
- `.planning/ROADMAP.md` — Phase 41 goal + 5 success criteria; the milestone Backlog (999.1 SEED-006
  is the *next* milestone and fixes live bugs — relevant to the D-16 defer-vs-fix decision).
- `.planning/REQUIREMENTS.md` — PROOF-01/02/03 wording + the Future Requirements (STORYBOOK-01,
  UNDO-01, AXE-PIPELINE-01) and (elsewhere) VISUAL-CI-01 — the D-17 Section-B deferral list.
- `.planning/PROJECT.md` — v3.3 intent ("under-adopted, not under-built"; n=1 persona; the milestone
  progress note recording Phase-40 close).
- `.planning/STATE.md` — current position + Deferred Items.

### Phase-40 hand-off (the direct inputs Phase 41 locks)
- `.planning/phases/40-.../40-CONTEXT.md` — The Proof Spine, the D-04 CI two-bucket rule, D-06 axe
  report-only-vs-assert-zero, D-14 screenshots-as-evidence, the explicit "Phase 41 hardens" hand-off.
- `.planning/phases/40-.../40-GAP-REGISTER.md` — the working register (only GAP-40-000 non-goal) that
  Phase 41's `41-GAP-REGISTER.md` finalizes.
- `.planning/phases/40-.../40-VERIFICATION.md`, `40-REVIEW.md`, `40-SUMMARY.md`,
  `.../deferred-items.md` (the 3 pre-existing failures, D-21).
- `.planning/phases/39-.../39-REVIEW.md` — source of the CR-01(39-review)/WR-01/WR-02/WR-04/IN-* findings
  (D-16); Phase-39 flows (FLOW-04 decision history → Section A).

### v3.0 closeout precedent (structure to mirror)
- `.planning/MILESTONES.md` — "v3.0 Known Gaps" (fixed-vs-accepted split for D-17).
- `.planning/milestones/v3.0-MILESTONE-AUDIT.md` §`:131-138` — `gaps_found` acceptance pattern (D-16b).

### Brand & Token SSOT (what the doc documents; where any token lives)
- `brandbook/brand-book.md` — canonical voice/UI conventions the doc points at.
- `brandbook/tokens.json` (canonical) → `assets/css/02-tokens.css` (CSS custom props, both theme blocks).

### Runtime UI, CSS, JS (the SSOTs the D-10 doc sections describe)
- `lib/scoria_web/ui.ex` — `object_header/1` (headers, D-05/D-10), `overview_stats/1`+`metric/1` (stats),
  `modal/1`+`drawer/1` (overlays), `notebook/1`+`raw_evidence/1` (evidence/code), `id/1` (copy), `table/1`
  incl. `.scoria-table__viewport tabindex="0"` at **~1320** (D-18), `toast/1` at **936-957** (the 4000ms
  `phx-mounted` auto-hide, D-15).
- `assets/css/04-components.css` (class vocabulary/BEM), `05-motion.css` (motion SSOT), `02-tokens.css`.
- `dev/lab/fixtures.ex` (`DevLab.Fixtures`) + `priv/repo/dev_seed.exs` (fixtures SSOT, D-10 §8).
- `dev/lab/sections/overlays.ex:91-94` (RISK-TOAST-LEGIBILITY static toasts — the D-14 shots target) +
  `primitives.ex:250`; **not** `states.ex` (badges only).

### Live-bug locations (D-16 — verify current, then record)
- `lib/scoria_web/live/review_queue_live.ex:54-63` (CR-01(39-review) crash) ·
  `lib/scoria_web/live/release_workbench_live.ex:16-48,178` (WR-04 KeyError) ·
  `lib/scoria_web/live/approvals_live/index.ex:250,663-689,434` (WR-02, WR-01, IN-02) ·
  `lib/scoria_web/live/approval_copy.ex:369` (IN-01 float currency).

### Proof harness, guards, docs, CI (reuse — do not rebuild)
- **e2e** `priv/dev/e2e/`: `drawer_focus.spec.mjs:280-329` (D-13 sole report-only collector),
  `a11y_axe.spec.mjs` (tier-1 report-only `:145-148` / tier-2 `toEqual([])` `:205-208`),
  `responsive_scan.spec.mjs`, `modal_focus.spec.mjs`, `reduced_motion.spec.mjs`; libs `ready.mjs`
  (`waitForReady`/`data-scoria-ready`), `axe.mjs`, `boxes_intersect.mjs`.
- **ExUnit guards** `test/scoria_web/`: `single_header_guard_test.exs:28-30` (GAP-A self-declared
  deferral — the D-06 target), `ds06_drift_guard_test.exs`, `a11y_structural_guard_test.exs:116-125`
  (table `tabindex` check, D-18), `toast_opacity_guard_test.exs`, `copy_guard_test.exs`,
  `motion_drift_guard_test.exs`, `scan_convention_guard_test.exs`, `token_contrast_guard_test.exs`,
  `dev_lab_boundary_test.exs` (PROOF-03 item-8 owner), `ui_component_test.exs` (`:357` stats, `:1273-1300`
  density, `:1610` signal_strip, `:1632/1645/1657` oversized-copy).
- **Operator-flow ExUnit**: `approvals_live_test.exs`, `approvals_live_integration_test.exs`,
  `incidents_live_test.exs`, `review_queue_live_test.exs`, `dataset_live/`, `approval_copy_test.exs`.
- **Doc-contract precedent (D-12 model)**: `test/scoria/docker_dx_doc_contract_test.exs`;
  CI wiring assertion `test/scoria/ci_policy_contract_test.exs:20,654-663` (`@docker_dx_doc_contract`).
- **Docs**: `docs/MAINTAINERS.md` (catalog `:255-336`, cross-link precedent `:3`), sibling idiom
  `docs/docker_dev_dx.md`, `docs/uat_automation.md`, `docs/operator_verification.md`.
- **Screenshots**: `priv/dev/shots.mjs` (6 viewports, `SCREENS`), `priv/dev/contact_sheet.mjs`
  (duplicate `SCREENS`), `priv/shots/.gitignore` + `contact_sheet_index.md` (committed manifest).
- **CI / packaging**: `.github/workflows/ci.yml` (`ci-gate needs:[verify,e2e]`, hard-fail),
  `ci-verify.yml` (policy lane-contract step), `mix.exs:127-139` (ExDoc extras), `:146-179`
  (`package.files`; `priv/dev`+`priv/shots` excluded — D-08/D-13).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **The proof harness is complete** — `mix scoria.ui.e2e` (required gate) + `mix scoria.ui.shots` +
  Playwright 1.60 + `waitForReady` + 6 viewport widths. Phase 41 adds at most a spec assertion + shots
  `SCREENS` entries, never a toolchain.
- **The drift guards already exist and already block** — 10+ `test/scoria_web/*guard*`/`ui_component`
  tests, all throwing, all in the CI-gated `verify` lane. PROOF-03 is ~90% already satisfied.
- **The doc-contract pattern is proven** — `docker_dx_doc_contract_test.exs` + its `ci_policy_contract`
  assertion is a 1:1 template for `design_system_doc_contract_test.exs` (D-12).
- **The screenshot pipeline is proven** — `shots.mjs`+`contact_sheet.mjs`+gitignored `priv/shots`+the
  committed `contact_sheet_index.md` manifest = zero-Hex-footprint evidence (D-13).

### Established Patterns
- **Warning-grade = detection style, not non-blocking** (D-02) — the source-scan guards throw today.
- **Matched pair**: every documented convention names its enforcing guard; the doc-contract test keeps
  the pair honest (D-10/D-12).
- **Evidence, never a gate** for screenshots; assertions gate, pixels inform (D-13; VISUAL-CI-01 deferred).
- **Fixed-vs-accepted gap register** with live repro for accepted debt — v3.0 `gaps_found` precedent (D-17).
- **Phase produces, milestone-close consumes** — do not archive from within a phase (D-20).

### Integration Points
- Add the Floki rendered-DOM assertion to (or beside) `single_header_guard_test.exs` (D-06).
- Add `docs/design_system.md` + `MAINTAINERS.md` cross-link + `design_system_doc_contract_test.exs`
  (+ policy-lane wiring in `ci-verify.yml` + `ci_policy_contract_test.exs` assertion) (D-08/D-12).
- Add `/_lab/overlays` (+ optional `/_lab/primitives`,`/_lab/states`) to `shots.mjs` **and**
  `contact_sheet.mjs` `SCREENS`; handle the toast 4s auto-hide (D-14/D-15).
- Write `41-GAP-REGISTER.md` (Sections A/B/B2) + the evidence manifest in `41-SUMMARY.md` (D-17/D-19).
- **Owner gate (D-16b):** IF opened, a bounded 2-crash fix (`review_queue_live.ex`, `release_workbench_live.ex`)
  each with a regression test; else record-only.

</code_context>

<specifics>
## Specific Ideas

- **The one decision that matters most is D-16b** — whether Phase 41 fixes the 2 confirmed live
  crash-class bugs (`review_queue_live` missing-`else`, `release_workbench_live` `@origin_context`
  KeyError) before the milestone ships. My recommendation: **yes, bounded 2-crash fix** — a "proof"
  milestone that ships with crashes on the very operator flows it claims to prove is internally
  contradictory. Owner may override; default until confirmed is record-only (D-16a).
- **The flip is a near no-op** (D-02): the guards already throw. Do not manufacture a "hardening pass."
  The only genuine flip candidate is D-13 drawer live-patch focus survival (VERIFY-THEN-DEFER).
- **GA-3's toast fix was wrong** (D-14): `states.ex` is badges; the real static toast is `/_lab/overlays`
  and it **auto-dismisses at 4s** — the plan must beat the hide, not assume determinism (D-15).
- **The doc's killer feature** (D-10): every convention section names the real drift guard that enforces
  it → PROOF-02 and PROOF-03 become a matched pair, kept honest by a 1:1 clone of the docker-DX contract.
- **Cite the 3 pre-existing red tests** (D-21) in the evidence manifest, or "suite green" is a false claim.
- **Do not archive the milestone** (D-20) — that's `/gsd-audit-milestone` + `/gsd-complete-milestone`.

</specifics>

<deferred>
## Deferred Ideas

- **VISUAL-CI-01** blocking screenshot-diff pixel gate; **STORYBOOK-01** PhoenixStorybook; **UNDO-01**
  approval reversal/undo; **AXE-PIPELINE-01** promote axe to a required CI lane — Future Requirements,
  later milestones. Phase-41 screenshots stay human evidence.
- **GAP-40-000** `prefers-contrast`/`forced-colors` (Windows High Contrast) — explicit non-goal; record
  as considered-and-deferred, not a defect.
- **SEED-004** test-code determinism (async `IntegrationCase`, `Process.sleep`→`eventually/2`) — carried
  deferred; only surfaces here as a Section-B row.
- **WR-01 / WR-02** (false approve-error toast, `has_more` off-by-one) — UX/cosmetic; deferred to
  Section B2 as accepted debt under D-16b(a)/(c) unless the owner picks (b) fix-all.
- **The optional shots-manifest coverage guard** (D-16-shots) — premature until D-14 corrects `SCREENS`;
  `dev_lab_boundary_test` already owns PROOF-03 "untested component states."
- **Table-scroll SR `aria-label`** (D-18) — rides the D-16b lane if opened, else Section B minor nit.

### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel` — CI copy cleanup, unrelated to this UI proof phase (ROADMAP:
  Unmapped). Not folded.
- `docker-dx-fleet-hardening` — fleet convergence, out of milestone scope (ROADMAP: Unmapped). Not folded.
- `make-approval-toasts-legible` (P38) / `add-approval-decision-history` (P39) — **already DELIVERED
  in-milestone**; belong in gap-register Section A (fixed), not as deferrals. Not folded (done).

</deferred>

---

*Phase: 41-Proof, Docs, And Regression Guardrails*
*Context gathered: 2026-07-03 (research-backed + red-team-hardened same day)*
