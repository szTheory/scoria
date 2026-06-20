# Phase 36: Baseline And Inventory - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 36 preserves the recent `/scoria` UI cleanup as committed baseline truth and produces the design-system inventory that gates the rest of v3.3. It is a discovery, classification, and proof-boundary phase. It must inventory UI foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, docs, one-off patterns, and known risks before any later implementation phase changes UI behavior, styling, components, routes, fixtures, or screenshot thresholds.

This phase should make the current system inspectable for maintainers and downstream agents. It should not fix the UI defects it finds unless they block inventory generation or existing tests.

</domain>

<decisions>
## Implementation Decisions

### Inventory Artifact Shape

- **D-01:** Produce a paired inventory artifact family: a human-readable Markdown inventory plus a structured companion index. The Markdown artifact owns rationale, examples, exclusions, research-backed guidance, risk narrative, and maintainer-readable baseline truth. The structured index owns canonical IDs, layer/status fields, file paths, route/component identifiers, state coverage, and machine-checkable relationships.
- **D-02:** Prefer boring repository-local artifacts over adding PhoenixStorybook or a runtime component lab in this phase. Phase 37 may build a dev-only lab from the inventory, but Phase 36 only defines the map and contract.
- **D-03:** Use stable identifiers from the start. Every component, page, hook, fixture, test, doc, and risk should have an ID that future phases can reference without relying on prose matching.
- **D-04:** Avoid duplicate source-of-truth drift. The Markdown inventory may summarize index rows, but canonical IDs and status fields live in the structured index.

### Classification Rules

- **D-05:** Classify every inventory row with both `layer` and `status`.
  - `layer`: `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off`.
  - `status`: `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific`.
- **D-06:** Every inventory row must include `id`, `name`, `layer`, `status`, `owner_path`, `evidence`, `replacement_or_owner`, `next_action`, and `risk_refs`.
- **D-07:** Mark `canonical` only when the item has a clear owner, stable API/token/route contract, representative usage, and appropriate tests or docs for its layer.
- **D-08:** Mark `duplicated` when two or more items solve the same UI job. Cite all relevant call sites and identify the preferred replacement or consolidation target.
- **D-09:** Mark `legacy` when still used but superseded. Include the migration target.
- **D-10:** Mark `missing` when repeated code, repeated copy, repeated tests, or documented needs imply an absent abstraction, state, fixture, proof, or doc.
- **D-11:** Mark `intentionally-page-specific` only when the behavior is tied to a named LiveView/page workflow and extracting it would leak domain context or reduce clarity.
- **D-12:** Phoenix ownership still matters inside the taxonomy. Function components with `attr`/`slot` contracts are the preferred primitive shape; LiveComponents are for stateful component behavior; JS hooks are for browser interop that `Phoenix.LiveView.JS` and server-rendered LiveView cannot cover cleanly; CSS remains token-scoped through the Scoria design system.

### Baseline Proof Boundary

- **D-13:** Use layered lightweight baseline proof. Phase 36 should cite git provenance, existing functional/design-system tests, and advisory screenshot evidence. It should not create a brittle visual gate.
- **D-14:** Git provenance must show the recent UI cleanup is committed separately before v3.3 planning work. Current evidence: UI cleanup commits include `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, and `f490cea`; v3.3 planning commits are `8540e04` and `2f2ad6e`.
- **D-15:** Existing proof should be reused before new proof is invented: ExUnit UI/component tests, DS-06 raw-palette guard, existing Playwright e2e files, `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`.
- **D-16:** Screenshots in Phase 36 are advisory baseline evidence only. Do not promote screenshot diffs into required CI during this phase. Phase 41 may decide whether visual CI is mature enough.
- **D-17:** v3.0 proof gaps are inventory risks, not automatic regressions. They become implementation work only in the relevant later phase.

### Risk Coverage

- **D-18:** Use a hybrid risk model: a central `Known Risk Register` plus per-inventory-item `risk_refs`. Do not duplicate risk prose on every row.
- **D-19:** The risk register must include stable `risk_id`, title, affected JTBD/persona/operator flow, affected inventory refs, owner phase, mitigation/evidence target, status, and closeout proof.
- **D-20:** Required starting risks:
  - `RISK-V30-PROOF` — stale v3.0 proof gaps and partial verification-doc coverage.
  - `RISK-TOAST-LEGIBILITY` — approval warning/error toast readability over dense UI; owner phase 38.
  - `RISK-APPROVAL-HISTORY` — discoverability of approved/denied/expired approvals without implying in-place reversal; owner phase 39.
  - `RISK-RESPONSIVE-SCAN` — responsive tables/lists and mobile scan paths.
  - `RISK-OVERLAY-FOCUS` — drawers, modals, command palette, mobile nav, focus restoration, escape behavior, reduced motion, and theme parity.
- **D-21:** Fold the todo `Make approval toasts legible over dense UI` into `RISK-TOAST-LEGIBILITY` for Phase 38.
- **D-22:** Fold the todo `Add approval decision history` into `RISK-APPROVAL-HISTORY` for Phase 39.
- **D-23:** Every later phase that touches an item with `risk_refs` must either mitigate the risk, prove it unchanged, or explicitly defer it with evidence.

### Design, Product, And DX Lens

- **D-24:** Treat Scoria as an operator-first Phoenix library, not a hosted UI platform. The inventory should preserve boring embedded-library ergonomics: repo-local docs, Mix tasks, Ecto/Phoenix/LiveView-native proof, no runtime dependency expansion, and no hidden service assumptions.
- **D-25:** UI inventory judgments must be JTBD-first. The operator should see job-oriented surfaces and consequences, not backend implementation guts. Expose traces, spans, IDs, policies, and payloads as evidence when useful, not as primary orientation copy.
- **D-26:** Use the newer `brandbook/` as canonical brand truth. The UI direction is field-engineer, grounded, composed, operator-grade, Phoenix-native, evidence-led, dark/light/system safe, and volcanic without flame/phoenix/AI-magic tropes.
- **D-27:** The design pillars to consider for every UI inventory item are: accessibility, responsive behavior, theme parity, motion/reduced motion, performance and render stability, information hierarchy, affordance clarity, density/scannability, microcopy, evidence discoverability, keyboard/focus behavior, and brand fit.
- **D-28:** Prefer decisive defaults. Downstream agents should ask the user again only if a choice changes product shape, security/policy boundary, durable truth model, tenant blast radius, or materially different operator/adopter workflow.

### Reviewed Todos

- **Reviewed, not folded:** `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` — out of scope for v3.3 UI inventory; keep as pending CI correctness follow-up.
- **Reviewed, not folded:** `Docker dev-DX fleet hardening — port-conflict-free multi-lib local DX` — out of scope for v3.3 UI inventory; keep as sibling/fleet DX follow-up.

### Claude's Discretion

Downstream research/planning agents may choose the exact file names and schema format for the structured index, but the recommendation is a Markdown inventory plus a structured data file under `.planning/phases/36-baseline-and-inventory/`. Keep the artifacts source-control friendly, diffable, and easy to review.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase And Milestone Scope

- `.planning/ROADMAP.md` — Phase 36 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `BASE-01`, `INV-01`, `INV-02` and v3.3 out-of-scope boundaries.
- `.planning/PROJECT.md` — current project posture, v3.3 milestone goal, prior shipped UI/design-system context.
- `.planning/STATE.md` — current phase position and pending todos.
- `.planning/METHODOLOGY.md` — decisive defaults and research-first escalation.

### Product, Architecture, And Brand Guidance

- `prompts/sztheory-elixir-dna.md` — operator-first Phoenix library posture, embedded LiveView dashboards, Ecto-native state, zero-configuration onboarding.
- `prompts/phoenix-ai-lib-deep-research.md` — Phoenix-native AI ops positioning, domain nouns, trace/eval/runtime/operator dashboard lessons.
- `prompts/scoria-brand-book-deep-research.md` — older brand research; use only where not superseded by `brandbook/`.
- `brandbook/brand-book.md` — canonical brand, voice, UI, and microcopy guidance.
- `brandbook/README.md` — brand artifact ownership and token consistency rules.
- `brandbook/tokens.json` — canonical brand token data.
- `brandbook/tokens.css` — brandbook token rendering reference.

### Current UI, Components, Hooks, And Proof Surfaces

- `lib/scoria_web/ui.ex` — Scoria component vocabulary and token/status gateway.
- `assets/css/04-components.css` — runtime component CSS and responsive/motion/theme behavior.
- `assets/js/scoria.js` — dashboard hooks: copy, theme, command palette, dismissable overlays, mobile nav, recents.
- `lib/scoria_web/components/layouts/app.html.heex` — dashboard shell, nav, command palette, shortcuts, theme controls.
- `lib/scoria_web/components/layouts/root.html.heex` — root theme/bootstrap behavior.
- `lib/scoria_web/live/` — dashboard LiveView page surfaces to inventory.
- `lib/scoria_web/components/` — dashboard component groups and evidence adapters to inventory.
- `test/scoria_web/ui_component_test.exs` — shared UI component contract tests.
- `test/scoria_web/ds06_drift_guard_test.exs` — raw palette drift guard and `ScoriaWeb.UI` zero-palette assertion.
- `test/scoria_web/live/` — LiveView page tests and current scan/action expectations.
- `test/scoria_web/components/` — evidence/component tests.
- `priv/dev/e2e/` — Playwright proof surfaces, especially command palette, IA orientation, and phase 16 parity specs.
- `priv/dev/shots.mjs` — screenshot harness implementation.
- `lib/mix/tasks/scoria.ui.shots.ex` — Mix entry point for screenshot and critique proof.
- `priv/shots/gap_register.md` — current UI critique gap register.
- `priv/shots/gap_register_final.md` — v3.0 final proof artifact.
- `docs/uat_automation.md` — existing browser/UAT proof notes and known limitations.
- `docs/MAINTAINERS.md` — maintainer proof and design-system harness documentation surface.

### Folded And Reviewed Todos

- `.planning/todos/2026-06-18-make-approval-toasts-legible.md` — folded as `RISK-TOAST-LEGIBILITY`.
- `.planning/todos/2026-06-20-add-approval-decision-history.md` — folded as `RISK-APPROVAL-HISTORY`.
- `.planning/todos/ci-policy-job-cache-key-mislabel.md` — reviewed, not folded.
- `.planning/todos/docker-dx-fleet-hardening.md` — reviewed, not folded.

### Prior UI Milestone Context

- `.planning/milestones/v3.0-MILESTONE-AUDIT.md` — v3.0 proof gap context and known partials.
- `.planning/milestones/v3.0-phases/11-evaluation-engine-seed-depth/11-RESEARCH.md` — screenshot harness, UI critique, seed/proof lessons.
- `.planning/milestones/v3.0-phases/11-evaluation-engine-seed-depth/11-PATTERNS.md` — Mix task, Playwright, gap-register, and fixture analogs.
- `.planning/milestones/v3.0-phases/16-motion-responsive-theme-parity/16-CONTEXT.md` — responsive, motion, focus, and theme parity decisions.
- `.planning/debug/phase16-parity-9-failures.md` — proof-methodology lessons for focus, reduced motion, and overlay tests.

### External Research References

- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` — Phoenix function components, `attr`, `slot`, and compile-time validation.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` — idiomatic LiveView JS command boundary.
- `https://phoenix-live-view.hexdocs.pm/js-interop.html` — JS hook interop boundary.
- `https://hexdocs.pm/phoenix_live_dashboard/` — embedded Phoenix dashboard precedent.
- `https://phoenix-storybook.hexdocs.pm/components.html` — component stories, variations, templates, and source docs precedent.
- `https://github.com/phenixdigital/phoenix_storybook` — PhoenixStorybook prior art and automatic story discovery model.
- `https://storybook.js.org/` — mature component workshop/docs/testing prior art.
- `https://m3.material.io/foundations/design-tokens` — design token system prior art.
- `https://atlassian.design/tokens/design-tokens` — design token naming/usage prior art.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ScoriaWeb.UI` in `lib/scoria_web/ui.ex`: central component vocabulary including badges, buttons, icon buttons, panels, page sections, metrics, overview stats, signal strips, copyable IDs, timestamps, attention cards, selectable cards, object headers, stub pages, keyboard chips, command palette shell, empty states, modal, drawer, form field/section, skeleton, toast, notebook, raw evidence, evidence rows/actions/empty states, table, and flash group.
- `assets/css/04-components.css`: canonical runtime styling surface for shell, nav, mobile drawer, buttons, tokens, tables, responsive summaries, overlays, toasts, command palette, motion, and theme behavior.
- `assets/js/scoria.js`: existing browser interop should be inventoried as named hooks/capabilities, not generalized into new JS abstractions without evidence.
- `priv/dev/e2e/phase16_parity.spec.mjs`: existing proof patterns for responsive overflow, focus visibility, reduced motion, theme parity, and overlay behavior.
- `mix scoria.ui.shots`: existing maintainer proof entry point; Phase 36 should reference it as optional/advisory baseline proof.

### Established Patterns

- Scoria UI uses a token-first, semantic-class design-system gateway. Raw palette leakage is already guarded by DS-06.
- Phoenix function components with `attr` and `slot` declarations are the preferred reusable primitive shape.
- Page-local LiveView markup is acceptable only when tied to a specific operator workflow and marked `intentionally-page-specific`.
- Tables/lists often require both desktop table and mobile summary scan paths; inventory must record both.
- The dashboard shell already includes desktop/mobile navigation, command palette, shortcut overlay, and dark/light/system theme handling; these are high-risk cross-cutting surfaces.
- Existing proof prefers ExUnit and focused Playwright over broad brittle screenshot gating.

### Integration Points

- Phase 37 should consume the structured inventory to decide what the dev component lab renders.
- Phase 38 should consume primitive/component-group rows and `RISK-TOAST-LEGIBILITY`.
- Phase 39 should consume page-flow/component-group rows and `RISK-APPROVAL-HISTORY`.
- Phase 40 should consume accessibility, responsive, motion, theme, overlay, and focus risk refs.
- Phase 41 should consume all inventory/risk/proof refs to add docs and drift guards.

</code_context>

<specifics>
## Specific Ideas

- Make the inventory useful to a maintainer opening the repo cold: they should see what exists, what is canonical, what is duplicated, what is legacy, what is missing, what is intentionally page-specific, and what later phase owns each risk.
- Use JTBD/user-flow language in inventory descriptions where UI is involved: who uses the surface, what job they are doing, what input they need, what action they can take, and what evidence they get back.
- Keep backend nouns available as evidence, not as primary UI orientation. For example, traces, IDs, policy versions, payloads, and audit records belong in evidence rows, drawers, notebooks, or copy affordances when they help the operator.
- Record dark, light, and system theme expectations on cross-cutting UI rows. Theme support is not a nice-to-have in this milestone.
- Record empty, loading, dense, long-text, warning, danger, disabled, selected, mobile, tablet, desktop, and wide states where relevant so Phase 37 can render meaningful lab states.

</specifics>

<deferred>
## Deferred Ideas

- Do not add PhoenixStorybook in Phase 36. The roadmap already defers Storybook evaluation until after the dev-only component lab proves insufficient.
- Do not add screenshot-diff CI in Phase 36. Visual CI remains a future requirement (`VISUAL-CI-01`) unless Phase 41 finds the harness deterministic enough.
- Do not implement approval decision history in Phase 36. It is folded as a Phase 39 risk.
- Do not fix approval toast legibility in Phase 36. It is folded as a Phase 38 risk.
- Do not change core approval semantics to allow approving a denied request in place.
- Do not broaden into CI cache-key cleanup or sibling-repo Docker fleet hardening.

### Reviewed Todos (not folded)

- `CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)` — not part of the v3.3 UI design-system inventory.
- `Docker dev-DX fleet hardening — port-conflict-free multi-lib local DX` — not part of the v3.3 UI design-system inventory.

</deferred>

---

*Phase: 36-Baseline And Inventory*
*Context gathered: 2026-06-20*
