# Phase 41: Proof, Docs, And Regression Guardrails - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 41-Proof, Docs, And Regression Guardrails
**Method:** Research + red-team (per user's established discuss-phase method — parallel research
subagents per gray area, then an adversarial red-team pass synthesized into one locked spec; NOT
interactive Q&A). Four gray areas researched against the live repo, then red-teamed by a fifth agent.
**Areas discussed:** Guard hardening / collector-flip / focused ExUnit (GA-1); Maintainer design-system
docs (GA-2); Screenshot proof (GA-3); Final gap register + verification evidence + closeout (GA-4).

---

## GA-1 — Guard hardening, collector→expect() flip, PROOF-03 gaps, focused ExUnit

| Option | Description | Selected |
|--------|-------------|----------|
| Big "flip pass" (warning→blocking) | Treat Phase-40 collectors as warnings needing a flip | |
| Flip is a near no-op | Guards already throw + gate; only D-13 is a real report-only candidate | ✓ |

**Outcome:** Guards are already blocking (`assert offenders == []` in the CI-gated verify lane). Two
axe tiers (full-lab, target-size) stay report-only *by design*. D-13 drawer live-patch focus survival
is the sole genuine flip candidate → VERIFY-THEN-DEFER (flip if never-warns; else register). One
required net-new guard: GAP-A `single_header` rendered-DOM LiveViewTest (self-declared deferral to 41).
Criterion-1 focused ExUnit already satisfied — add no suites.
**Red-team:** CONFIRMED across the board. Corrected: oversized-copy guard is in `ui_component_test.exs`,
not `copy_guard_test.exs`. Locked the "can't run e2e ⇒ default-defer D-13" fallback.

---

## GA-2 — Maintainer design-system docs

| Option | Description | Selected |
|--------|-------------|----------|
| Extend MAINTAINERS.md | Add 11 convention sections to the existing doc | |
| Multiple topic files | One file per convention | |
| One new `docs/design_system.md` | Single topic file, matched-pair guard refs, kept out of ExDoc/package | ✓ |

**Outcome:** One `docs/design_system.md`, out of ExDoc extras + `package.files` (mirrors docker_dev_dx /
uat_automation), cross-linked from MAINTAINERS.md. 11 sections, fixed 4-part shape
(Rule→SSOT→Guard→Example); every section names its enforcing drift guard (matched pair → ties PROOF-02
to PROOF-03). Anti-drift: `design_system_doc_contract_test.exs` modeled 1:1 on
`docker_dx_doc_contract_test.exs`, wired into the policy lane + `ci_policy_contract_test.exs`.
**Red-team:** CONFIRMED — precedent exists exactly as cited (`ci_policy_contract_test.exs:654-663`).

---

## GA-3 — Screenshot proof

| Option | Description | Selected |
|--------|-------------|----------|
| Blocking pixel-diff gate | CI screenshot assertion | ✗ (VISUAL-CI-01 deferred) |
| Evidence contact sheet | Human-reviewable dated baseline; committed manifest, gitignored pixels | ✓ |

**Outcome:** Evidence, never a gate. Committed proof-of-record = markdown manifest; PNGs gitignored;
zero Hex footprint. Two matrix gaps: component-lab states + toast legibility.
**Red-team:** REFUTED GA-3's fix — `states.ex` renders badges, not a toast; the real static toast is
`/_lab/overlays` (RISK-TOAST-LEGIBILITY) and it **auto-dismisses at 4s** (`ui.ex:936-957`). DELTA:
target `/_lab/overlays`; the plan must beat the 4s hide, not assume determinism. Shots-manifest guard
is optional/premature (dev_lab_boundary_test already owns PROOF-03 item-8).

---

## GA-4 — Final gap register + verification evidence + closeout boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Fix surfaced bugs inline | Phase 41 applies a "tiny fix pass" for the live bugs | ✗ (scope-creep leak) |
| Record + owner-gate | Register with live proof; owner decides on a bounded fix lane | ✓ |

**Outcome:** Final register at `41-GAP-REGISTER.md` (phase artifact) with Section A (fixed-in-v3.3),
Section B (deferred future work), Section B2 (surfaced-but-unfixed). Evidence = a manifest of pointers
in `41-SUMMARY.md`. Phase 41 produces; milestone-close (`/gsd-audit-milestone` + `/gsd-complete-
milestone`) consumes/archives — Phase 41 must not touch MILESTONES.md.
**Red-team:** CONFIRMED all four B2 bugs are **still live in current source** (CR-01(39-review) crash,
WR-04 KeyError crash, WR-01 false-error, WR-02 off-by-one). DELTA: **stripped GA-4's "apply inline"**
recommendation (violates no-remediation-budget); made it a **binary OWNER decision** (D-16b). Confirmed
the 3 pre-existing full-suite failures must be cited (D-21). Table-scroll aria-label: register, don't
apply unilaterally (D-18).

---

## Claude's Discretion

Exact file/section names; the Floki assertion shape for GAP-A; whether the optional shots-manifest guard
earns its keep; the 11 doc-section wording (must name a real guard, invent no rule); how to capture the
lab toast before its 4s auto-hide. Constraints hold: no vocabulary change, no runtime dep, no pixel gate,
no unilateral remediation, no milestone archival.

## Owner Decision Pending (D-16b)

**The one item requiring the owner:** whether Phase 41 opens a bounded fix lane for the 2 confirmed live
**crash-class** bugs (`review_queue_live.ex:54-63` missing-`else`; `release_workbench_live.ex`
`@origin_context` KeyError) before v3.3 ships. Asked via AskUserQuestion; user was away (no response in
60s). **Provisional recommendation: (a) fix the 2 crashes** (a proof milestone shouldn't ship with
crashes on the flows it proves), defer WR-01/WR-02 as recorded debt. **Default until confirmed:
record-only (D-16a).** Revisit before/at planning.

## Deferred Ideas

VISUAL-CI-01, STORYBOOK-01, UNDO-01, AXE-PIPELINE-01 (Future Requirements); GAP-40-000
`prefers-contrast`/`forced-colors` non-goal; SEED-004 test-code determinism; WR-01/WR-02 cosmetic;
optional shots-manifest guard; table-scroll SR aria-label. The two ROADMAP "pending todos"
(toast-legibility P38, decision-history P39) were DELIVERED in-milestone → Section A, not deferrals.
