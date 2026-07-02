# Roadmap: v3.3 Design System Stress Test

**Last updated:** 2026-06-20
**Milestone:** v3.3 Design System Stress Test
**Goal:** Make the embedded `/scoria` admin/operator UI internally coherent at the foundation, component, component-group, page-flow, copy, accessibility, motion, fixture, and proof levels without regressing the recent cleanup work.

## Phase 36: Baseline And Inventory

**Goal:** Preserve the recent UI cleanup as baseline truth and produce a complete design-system inventory before changing more UI.

**Requirements:** BASE-01, INV-01, INV-02

**Success criteria:**

1. Current UI cleanup is committed separately from v3.3 work.
2. Inventory names foundations, primitives, component groups, pages, CSS/JS hooks, fixtures, tests, and docs.
3. Inventory classifies each item as canonical, duplicated, legacy, missing, or page-specific.
4. Known risks include stale v3.0 proof gaps, approval toast legibility, approval decision history, responsive tables/lists, and overlay/focus regressions.
5. No implementation phase starts without the inventory artifact.

## Phase 37: Dev Component Lab And Stress Fixtures

**Goal:** Add a dev-only component lab and fixture matrix that make component quality visible across states, themes, and ugly data.

**Requirements:** LAB-01, LAB-02, FIXT-01

**Plans:** 4/6 plans executed

Plans:
**Wave 1**

- [x] 37-01-PLAN.md — Fixture catalog, state/tone vocabulary, boundary/coverage guard (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 37-02-PLAN.md — Foundations + Primitives specimen sections (Wave 2)
- [x] 37-03-PLAN.md — Groups + Fixtures catalog sections (Wave 2)
- [x] 37-04-PLAN.md — Viewports + Overlays probe sections (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 37-05-PLAN.md — Dev-only lab route mount + DevLab.LabLive shell (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 37-06-PLAN.md — Browser proof (lab.spec.mjs) + maintainer docs (Wave 4)

**Cross-cutting constraints:**

- Lab-authored dev/ chrome in these sections emits zero raw hex and zero raw palette classes; all values resolve through --scoria-* tokens and ScoriaWeb.UI primitives (D-26) — verified by the extended DS-06 drift guard

**Success criteria:**

1. Dev-only component lab is reachable in local dev and excluded from public dashboard mount behavior and Hex runtime footprint.
2. Lab renders `ScoriaWeb.UI` primitives and recurring groups with normal, long, empty, dense, disabled, selected, loading, warning, danger, and error states.
3. Lab exercises light, dark, system, reduced-motion, mobile, tablet, desktop, and wide layouts.
4. Dev fixture data covers approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, and empty/error cases with realistic and ugly values.
5. Maintainer docs explain how to run and inspect the lab.

## Phase 38: Foundations And Primitive Controls

**Goal:** Tighten shared foundations and primitive controls so later page work uses one consistent design-system language.

**Requirements:** DS-01, DS-02, DS-03, DS-04

**Success criteria:**

1. Semantic-token and raw-palette drift guards still pass.
2. Buttons, icon buttons, copy controls, links, badges, IDs, timestamps, metadata rows, raw evidence/code blocks, panels, drawers, modals, toasts, forms, tables, and lists have coherent sizes, spacing, variants, focus states, and accessible names.
3. Overview stats and signal summaries converge on one reusable component pattern.
4. Approval warning/error toasts are readable over dense approvals UI in light and dark themes.
5. Tests prevent regressions to density controls, oversized copy icons, transparent unreadable toasts, and inconsistent stats.

## Phase 39: Component Groups And Operator Flows

**Goal:** Apply the system to real operator workflows so pages serve user intent rather than backend structure.

**Requirements:** FLOW-01, FLOW-02, FLOW-03, FLOW-04, COPY-01

**Success criteria:**

1. Every primary page has clear page orientation, a single obvious primary scan/action path, and no redundant single-region headers.
2. Approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, and eval pages use consistent page-section, table/list, empty/error/loading, toolbar/filter, and detail conventions.
3. Approval drawer is decision-first, with plain-language consequences, actions near the summary, progressive disclosure for raw payload and metadata, and no duplicated "approval required" / "decision required" copy.
4. Decision history makes approved, denied, expired, or decided approvals discoverable without implying in-place reversal.
5. Microcopy uses operator language first and keeps IDs, payloads, traces, and audit terms available as evidence, not primary orientation.

## Phase 40: Accessibility, Motion, And Responsive Proof

**Goal:** Prove the redesigned controls and flows are operable, readable, and stable across accessibility, motion, and viewport constraints.

**Requirements:** A11Y-01, A11Y-02, MOTION-01, RESP-01

**Success criteria:**

1. Keyboard-only navigation works across app shell, command palette, tables/lists, drawers, modals, disclosures, copy controls, and forms.
2. Focus is visible, trapped/restored where appropriate, and not hidden by sticky/floating regions.
3. Dialogs, drawers, disclosures, icon buttons, status, forms, empty states, toasts, and tables/lists meet WCAG 2.2 AA intent.
4. Motion uses tokenized transform/opacity patterns, communicates state, and respects reduced motion.
5. 320, 375, 768, 1024, 1440, and wide desktop widths show no clipped content, trapped scroll, squished essential columns, or floating controls covering navigation.

## Phase 41: Proof, Docs, And Regression Guardrails

**Goal:** Lock the milestone into durable tests, screenshots, docs, and drift guards so future design-system work is idempotently improving.

**Requirements:** PROOF-01, PROOF-02, PROOF-03

**Success criteria:**

1. Focused ExUnit tests cover shared UI components, approval flow, incident/review/dataset scan patterns, and drift guards.
2. Browser proof covers component lab states, theme switching, overlays, mobile shell, copy affordances, toast legibility, and core operator flows.
3. Maintainer docs define conventions for BEM, tokens, page headers, stats, overlays, evidence/code, copy controls, fixtures, motion, accessibility, and screenshot proof.
4. Final gap register separates fixed issues from explicitly deferred future work.
5. Full verification evidence is recorded before milestone close.

## Pending Todo Mapping

| Todo | Phase | Reason |
|------|-------|--------|
| `make-approval-toasts-legible` | 38 | Toast legibility is a primitive/control quality issue. |
| `add-approval-decision-history` | 39 | Decision history belongs to the approvals operator flow. |
| `ci-policy-job-cache-key-mislabel` | Unmapped | CI copy cleanup is unrelated to this UI milestone. |
| `docker-dx-fleet-hardening` | Unmapped | Fleet convergence is out of scope. |

## Previous Milestones

- Shipped **v3.2 Drydock** - Phases 29-35, Docker dev-DX hardening and maintenance release - 2026-06-19.
- Shipped **v3.1 CI/CD Velocity** - Phases 23-28, PR CI 77m to 7m38s measured - 2026-06-17.
- Shipped **v3.0 Control Room** - Phases 11-17, dashboard design-system, IA, motion, and proof - 2026-06-14.
- Shipped **v2.17 Vesicle** - Phases 18-22, canonical brand system - 2026-06-11.

See `.planning/MILESTONES.md` for full closeout history.
