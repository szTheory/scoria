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

**Plans:** 6/6 plans complete

Plans:
**Wave 1**

- [x] 37-01-PLAN.md — Fixture catalog, state/tone vocabulary, boundary/coverage guard (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 37-02-PLAN.md — Foundations + Primitives specimen sections (Wave 2)
- [x] 37-03-PLAN.md — Groups + Fixtures catalog sections (Wave 2)
- [x] 37-04-PLAN.md — Viewports + Overlays probe sections (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 37-05-PLAN.md — Dev-only lab route mount + DevLab.LabLive shell (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 37-06-PLAN.md — Browser proof (lab.spec.mjs) + maintainer docs (Wave 4)

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

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 38-01-PLAN.md — Opaque toast/flash tokens + CSS-source opacity guard + dense-approvals e2e alpha assertion (Wave 1)

**Wave 2** *(blocked on Wave 1 completion — shares assets/css/04-components.css)*

- [x] 38-02-PLAN.md — Delete signal_strip duplicate, close copy-control a11y gaps, guard stat/copy-icon/size-scale/focus invariants (Wave 2)

**Wave 3** *(blocked on Wave 2 completion — shares test/scoria_web/ui_component_test.exs)*

- [x] 38-03-PLAN.md — Audit-and-lock coherence guards for the rest of Criterion 2 (links, badges, timestamps, metadata rows, panels, drawers, modals, forms, tables, lists) (Wave 3)

**Success criteria:**

1. Semantic-token and raw-palette drift guards still pass.
2. Buttons, icon buttons, copy controls, links, badges, IDs, timestamps, metadata rows, raw evidence/code blocks, panels, drawers, modals, toasts, forms, tables, and lists have coherent sizes, spacing, variants, focus states, and accessible names.
3. Overview stats and signal summaries converge on one reusable component pattern.
4. Approval warning/error toasts are readable over dense approvals UI in light and dark themes.
5. Tests prevent regressions to density controls, oversized copy icons, transparent unreadable toasts, and inconsistent stats.

## Phase 39: Component Groups And Operator Flows

**Goal:** Apply the system to real operator workflows so pages serve user intent rather than backend structure.

**Requirements:** FLOW-01, FLOW-02, FLOW-03, FLOW-04, COPY-01

**Plans:** 8/8 plans complete

Plans:
**Wave 1** *(foundation — parallel, no file overlap)*

- [x] 39-01-PLAN.md — page_header/1 + additive status_label/1 in ScoriaWeb.UI (Wave 1)
- [x] 39-02-PLAN.md — strings-only ScoriaWeb.Copy + per-domain copy modules (Wave 1)
- [x] 39-03-PLAN.md — ApprovalCopy SSOT + list_decided_approvals/1 + real-path fixtures + write-invariant guard (Wave 1)

**Wave 2** *(page adoption — blocked on Wave 1)*

- [x] 39-04-PLAN.md — Index-page header migration + microcopy (orchestrator, workflow, eval-spec, prompt, coming-soon) (Wave 2)
- [x] 39-05-PLAN.md — Scan conventions + microcopy (dataset, connectors, review_queue, incidents) (Wave 2)
- [x] 39-06-PLAN.md — Approval drawer decision-first redesign + alarm-chrome removal (Wave 2)

**Wave 3** *(blocked on Wave 2 — shares approvals_live/index.ex with 39-06)*

- [x] 39-07-PLAN.md — Decision-history surface (Pending|Decided scope, read-only receipt, audit-sourced attribution) (Wave 3)

**Wave 4** *(guards + proof — blocked on Waves 2-3)*

- [x] 39-08-PLAN.md — Warning-grade guards (single-header, scan-convention, copy) + automated flow proof (Wave 4)

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

**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 40-01-PLAN.md — Shared e2e infra: @axe-core/playwright pin + overrides, boxesIntersect + axe-run helpers, gap register scaffold
- [x] 40-02-PLAN.md — Browserless source-scan guards: motion tokenization/keyframe guard + a11y structural-presence guard

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 40-03-PLAN.md — D-10 drawer/modal focus trap+restore fix + atomic drawer/modal keyboard specs (SC 2.4.11, live-patch collector)
- [x] 40-04-PLAN.md — axe WCAG 2.2 AA scan: report-only baseline (both themes) → curated assert-zero on real pages
- [x] 40-05-PLAN.md — Responsive proof (D-16 catalog, 6 widths) + reduced-motion e2e + 6-width screenshot evidence

## Phase 41: Proof, Docs, And Regression Guardrails

**Goal:** Lock the milestone into durable tests, screenshots, docs, and drift guards so future design-system work is idempotently improving.

**Requirements:** PROOF-01, PROOF-02, PROOF-03

**Plans:** 5 plans

Plans:
**Wave 1** *(no file overlap — parallel)*

- [ ] 41-01-PLAN.md — D-16b bounded crash-fix lane: CR-01(39-review) + WR-04 fixes + D-18 aria-label, each locked by a regression test (Wave 1)
- [ ] 41-02-PLAN.md — D-06 GAP-A rendered-DOM single-header drift guard (closes the 8th PROOF-03 regression) (Wave 1)
- [ ] 41-03-PLAN.md — docs/design_system.md (11 sections) + doc-contract test + CI policy-lane wiring (Wave 1)
- [ ] 41-04-PLAN.md — Screenshot proof: /_lab/overlays SCREENS + toast-timing-safe capture + contact-sheet manifest (Wave 1)

**Wave 2** *(blocked on Waves 1 — consumes all lane outputs)*

- [ ] 41-05-PLAN.md — 41-GAP-REGISTER.md (Sections A/B/B2) + D-19 verification-evidence manifest (Wave 2)

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

## Backlog

> Forward roadmap of planned milestones. Each item's full rationale, adjudicated verdicts, peer
> precedent, and file breadcrumbs live in its backing seed under `.planning/seeds/` (see
> `.planning/seeds/README.md` for the index + dependency graph). This section is the durable
> recall surface: `/gsd-complete-milestone` preserves `## Backlog` verbatim across milestone
> rewrites, so it survives context clears. Promote items one at a time via `/gsd-review-backlog`
> or scope them directly in `/gsd-new-milestone`.

### Planned milestone order

Sequenced (dependency + priority). Order was set by a 2026-07-03 AI-eval posture audit
(6-agent adjudication vs LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel). Cadence
decision: **P0 fixes → docs/positioning → feature milestones**, each feature milestone
interleaving its own feature docs + a release as it lands.

1. **999.1 → SEED-006 — Pre-1.0 Trust & Security Hardening**  🔴 **[P0 · GATES THE NEXT HEX RELEASE]**
   Fix 3 live bugs in shipped 0.1.2: eval fail-open (fake-green scorers + judge grades
   expected-vs-expected + decorative release gate), knowledge cross-tenant retrieval leak,
   dashboard auth bypass; + correctness bugs (fake-cosine score_chunk, citation_presence
   abstention penalty, chunker overlap no-op, latency-vs-0). The pending 0.1.3 release PR (#12)
   is held until this lands. → see `SEED-006`.

2. **999.2 → SEED-005 — Documentation & Positioning overhaul**  (adoption bottleneck; the *front door*)
   STABLE docs only (terminology sense-aware rename, scope-doctrine + owns-vs-delegates table,
   ExDoc grouping, glossary, README first-screen) + the honest release cut (gated on 999.1).
   Feature-specific guides are interleaved into the build milestones below, NOT pre-written here.
   → see `SEED-005`.

3. **999.3 → SEED-007 — Trace Foundation (OTel-GenAI / OpenInference interop)**  (foundational for eval attribution)
   Semconv as a naming convention over the existing attrs map (not a schema rewrite) + span_kind +
   model config + structured spans/events + RETRIEVER span + README claim fix. → see `SEED-007`.

4. **999.4 → SEED-010 — Lethal-Trifecta Governance**  ⭐ **[FLAGSHIP DIFFERENTIATOR]**
   Content trust tiers + spotlighting + tool-declared trifecta classification + confluence
   escalation policy (Meta Rule-of-Two) + moderation/output hooks + SECURITY-BOUNDARY.md. No peer
   ships this as a runtime seam; Scoria is 2/3 built. Sequence early (after 006 + 007). → see `SEED-010`.

5. **999.5 → SEED-008 — Trustworthy Eval Depth**  (after 006 + 007)
   Real scorer library + regression-comparison engine + judge calibration (the unique join Scoria
   already captures but discards) + versioned rubric + typed risk/intent taxonomy slots. → see `SEED-008`.

6. **999.6 → SEED-009 — Retrieval Eval Depth & Seams**  (after 006)
   precision@k/NDCG/abstention/staleness (model-free, Scoria-owned) + faithfulness/rerank as
   host-supplied hooks (no model in-lib) + tiny gold set. → see `SEED-009`.

7. **999.7 → SEED-011 — Privacy & Feedback Governance**
   Trace/memory retention/TTL/purge + right-to-erasure (Scoria owns the tables → owns deletion) +
   PII masking contract + regex pack + human-feedback capture → flywheel + memory forget/expire.
   Unblocks the currently-unserved privacy/legal/compliance persona. → see `SEED-011`.

8. **999.8 → SEED-012 — Architecture-Archetype Awareness (Rule-8 lens)**  (small capstone; after 007 + 008)
   Host-declared `archetype`/`route` on runs (Scoria records/segments, never infers) + a
   segment-by-attribute dashboard facet (per-archetype/per-route cost/latency/scores) + per-archetype
   Rule-8 eval presets + Router observability (routing accuracy via the SEED-008 confusion-matrix reuse).
   A thin composition over the SEED-007 attribute convention + SEED-008 eval machinery — not new infra.
   From the 2026-07-03 AI-architecture-patterns ingest (memo: `.planning/research/ai-architectural-patterns.md`,
   which validated ~85% of Scoria as-built). → see `SEED-012`.

9. **999.9 → SEED-013 — Operator IA Pivot (Control-Room v2)**  (dashboard coherence; sequence after 006, alongside/after 005)
   The **structural** operator-UI pivot buildable on today's backend: a tighter nav re-group
   (Home · Queue · Features · Runs · Quality · Govern · [Data & Privacy] · [Audit]), a **unified Queue**
   (one ranked human-work inbox over existing approvals+incidents+reviews), a persistent scope contract
   (Tenant/Feature/Time/Live, cross-tenant loud), a 3-pane **Run Workbench**, the progressive-disclosure
   law + receipts + "create policy rule from this," a **Feature Cockpit shell** (host-declared feature
   attribute), and the "story-spine-with-vesicles" trace viz. It is the umbrella the feature-specific
   screens fold into: Govern/blast-radius rides `SEED-010`, Data & Privacy rides `SEED-011`, Quality depth
   rides `SEED-008`/`SEED-009`, Feature Cockpit content rides `SEED-012`. From the 2026-07-03 operator-UI
   storyboard ingest (**UI source-of-record: `.planning/research/operator-ui-north-star.md`**, which
   doctrine-filtered a blank-slate/maximalist storyboard down to this one structural seed + annotations —
   ~40% of its ideas already ship). → see `SEED-013`.

### Carried-forward deferred work (pre-audit)

- **SEED-004 — Test-code determinism** (async `IntegrationCase`, remove `Process.sleep`→`eventually/2`,
  raise shard count). Deferred at v3.1 close; leading pre-audit next-milestone candidate. *(No seed
  file on disk — tracked only here + STATE.md Deferred Items.)*

- **FLEET-01** — migrate sibling repos onto the shared Traefik + unpublished-DB standard. Deferred v3.2.
- **FLEET-02** — `make nuke-all` fleet-wide teardown (high blast radius). Deferred v3.2.

### Post-v3.3 housekeeping follow-ups (do when the v3.3 window is idle — collision-avoidance)

- Record the 6-principle **scope doctrine** (Scoria owns the verb; host owns the noun — P1–P6,
  detailed in `SEED-005` / `SEED-006`) into `PROJECT.md` `## Key Decisions` + `## Constraints`.

- Clean up `STATE.md` `## Deferred Items` (currently corrupted with stray per-plan metric rows) and
  add rows for SEED-005…011 so STATE.md's deferred view matches this Backlog.
