# Phase 14: Least-iterated screens polish - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** Advisor-mode discussion - user selected all 4 gray areas, requested subagent-backed research, and approved the synthesized recommendations as a coherent set

<domain>
## Phase Boundary

Phase 14 polishes the least-iterated, highest-gain Control Room screens: Review Queue, Incidents, Eval Workbench, Prompt Registry / Release Workbench, and a real Dataset Builder index. The phase closes SCREEN-01 and SCREEN-02 by converting these screens to the shared `ui.ex` component layer, removing in-scope raw-palette leakage, and making Dataset Builder the canonical promote-to-dataset destination.

This is a UI/IA/DX phase only. Do not add net-new backend capability families, fake data, new eval engines, new prompt experiment controls, new annotation workflows, or broad evidence-adapter conversion. Existing Ecto contexts and LiveView event flows are reused. Phase 15 still owns the high-traffic screens and broad evidence-adapter sweep; Phase 16 still owns cross-dashboard motion/responsive/theme parity; Phase 17 still owns final proof/docs.

</domain>

<decisions>
## Implementation Decisions

### Dataset Builder as Canonical Promotion Destination
- **D-01:** Build a real `ScoriaWeb.DatasetLive.Index` mounted at `/datasets`. Add **Dataset Builder** to the Improve nav after Review Queue and before Eval Workbench. Add it to `DashboardNav.@views`, `strip_known_prefixes/1`, command palette navigation, and the `g d` shortcut. Dataset Builder is not a stub and must not use fake rows.
- **D-02:** Dataset Builder owns dataset curation and promotion UX. The index lists open and sealed datasets using shared components (`<.table>`, `<.badge>`, `<.metric>`, `<.panel>`, `<.empty_state>`). Promotion opens inside Dataset Builder using a shared `<.drawer>` or `<.modal>` driven by URL context.
- **D-03:** Promotion URLs carry stable IDs and intent, not raw snapshots. Supported shapes should be equivalent to `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=...` and `/datasets?promote=review&review_candidate_id=...`. The LiveView reconstructs promotion context from existing records; raw promotion snapshots and expected-output JSON are never embedded in query params.
- **D-04:** Within Dataset Builder, use LiveView patch semantics for drawer state and target dataset selection where the current LiveView stays mounted. Use navigate only when crossing from source screens into Dataset Builder. Validate stale or missing IDs and show calm, exact empty/error states.
- **D-05:** Reuse/refactor the current `DatasetLive.PromoteComponent` behavior and the existing `Eval` / `DatasetPromotion` functions. Do not add a new backend promotion model, a new "Promotion Workbench" noun, or altered sealed-baseline mutation rules.
- **D-06:** Source screens converge on Dataset Builder. Review Queue and Workflow Show may be touched only to replace existing promote affordances with "Promote in Dataset Builder" / "Request baseline approval in Dataset Builder" links or navigations. Broader Workflow Show polish remains Phase 15.

### Review Queue Conversion Model
- **D-07:** Keep Review Queue as a single LiveView and preserve the fast master-detail triage flow. Convert it to shared components rather than adding `/reviews/:id`, a lane board, or a separate review workbench.
- **D-08:** Recommended screen shape: index title only (no object breadcrumb), subtitle `Review flagged traces before they become datasets, baselines, or dismissed noise.`, compact metric strip from current `@summary`, filter panel with `<.field>` selects, `<.table id="review-queue">`, and a selected-candidate detail rail on desktop.
- **D-09:** Table columns should prioritize operator scanability: Candidate (rationale plus short trace/run IDs), Severity, Score, Sample, Promotion, and an action cell. Selected row state must not be color-only; use `aria-current` and/or explicit selected text/badge.
- **D-10:** The detail rail keeps triage pivots (`Open run`, `View runtime context`) and dismiss action. Dataset selection, expected-output editing, direct promotion, and sealed-baseline target picking move to Dataset Builder. This makes Review Queue an ingress surface, not a second dataset-management surface.
- **D-11:** Mobile detail may use the same content in `<.drawer>` if needed for usability, but avoid inventing mobile-only behavior. Keep form-level `phx-change` for filters; do not introduce LiveView streams unless research/planning finds a real scaling need.
- **D-12:** Do not add reviewer assignment, rubric editing, corrected-output authoring, bulk actions, annotation scoring, or lane/kanban workflow semantics in Phase 14. Those are future product capabilities, not polish.

### Eval Workbench and Prompt Registry / Release Workbench
- **D-13:** Keep Eval Workbench and Prompt Registry as separate Improve surfaces connected by quality-loop verbs. Do not merge them into a giant "Improve Workbench" tab shell.
- **D-14:** Eval Workbench should answer: what was evaluated, against which dataset/spec, what regressed, and where the operator goes next. Use shared tables/panels/forms and preserve existing links to prompt releases and regressed source runs.
- **D-15:** Prompt Registry should answer: which prompt versions exist, what state they are in, and which candidate can be released. Keep prompt editing on the existing backed behavior; do not add fake prompt experiment controls.
- **D-16:** Release Workbench stays a focused object page. It uses `object_header`, a compact next-step verb row (`View eval results`, `View baseline runs`), two shared comparison panels for Draft Candidate and Active Baseline, text-labeled status badges, shared approve/reject modals, and semantic notice/toast/flash treatment.
- **D-17:** Avoid steppers, wizard language, hidden client-side experiment state, model/prompt playground controls, and any UI that implies experiments can be run unless that capability is already backed by existing code.

### Incidents Evidence Boundary
- **D-18:** Convert `lib/scoria_web/live/incidents_live/index.ex` to shared components/tokens as normal SCREEN-01 work.
- **D-19:** Phase 14 has exactly one evidence-adapter exception: convert only `lib/scoria_web/components/incident_evidence_component.ex` into a thin local notebook/panel adapter because it is first-order Incidents screen content and blocks honest SCREEN-01 completion.
- **D-20:** Preserve the existing incident evidence data contract and section content: health rollup, budget, incident notebook, breaker/relay, and delivery outcomes. Change UI/IA/DX only.
- **D-21:** Do not convert `delegated_evidence_component`, `semantic_evidence_notebook_component`, `replay_evidence_notebook_component`, `trace_tree_component`, workflow detail panels, or other evidence adapters. Phase 15 still owns the broad evidence-adapter sweep, minus this one already-converted component if Phase 14 completes it.

### Cross-Screen Polish Rules
- **D-22:** For every in-scope screen/component touched by Phase 14, remove raw palette classes and shrink/remove the corresponding `test/support/ds06_baseline.txt` row. In-scope targets include Review Queue, Incidents page, IncidentEvidenceComponent, Eval Workbench, Prompt Registry, Release Workbench, Dataset Builder, and the minimum route/nav/source affordance files needed for Dataset Builder.
- **D-23:** Use Scoria brand voice everywhere: calm + exact + useful. Prefer evidence verbs: traced, scored, compared, replayed, promoted, gated, approved, denied. Do not anthropomorphize the model, expose hidden chain-of-thought, use hype copy, or label status by color alone.
- **D-24:** Bind to the existing runtime token system. Do not touch `assets/css/02-tokens.css` for cosmetic preference. Token propagation is reserved for WCAG/accessibility defects or genuine coherence breaks.
- **D-25:** UI polish should use conventional operator-dashboard components: tables, filters, panels, drawers/modals, badges, empty states, object headers, and notebook shells. Avoid decorative cards, marketing composition, graph visualizations, fake timelines, and "vanity dashboard" metrics.

### Agent's Discretion
- Exact component slot shapes, CSS class names, plan slicing, test file organization, route-param names, and whether Dataset Builder's promotion surface is a drawer or modal are planner/executor discretion, constrained by the decisions above.
- Small additions to `ui.ex` are acceptable only if they generalize a repeated Phase 14 need and preserve the token gateway. Prefer existing components first.
- The planner may choose whether Review Queue's detail surface is a sticky desktop rail, a panel column, or a responsive drawer implementation, as long as the workflow remains fast and accessible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Prior Decisions
- `.planning/PROJECT.md` - v3.0 Control Room goal, product boundary, personas, and UI-only milestone constraints.
- `.planning/REQUIREMENTS.md` - SCREEN-01 and SCREEN-02 are Phase 14; SCREEN-03/04, MOTION-01..04, and PROOF-01..03 remain later phases.
- `.planning/ROADMAP.md` - Phase 14 goal/success criteria and adjacent Phase 15/16/17 boundaries.
- `.planning/STATE.md` - current milestone state, prior v3.0 decisions, deferred items, and raw-color/DS-06 context.
- `.planning/phases/13-orientation-spine-ia/13-CONTEXT.md` - binding IA decisions: Improve group, Dataset Builder is real, next-step verbs, object headers, origin context, and one-noun-one-nav-group rule.
- `.planning/phases/13-orientation-spine-ia/13-DISCUSSION-LOG.md` - named-tool IA lessons and approved wording patterns for quality-loop threading.
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` - token gateway, DS-06 ratchet, screen-conversion ownership, and evidence-adapter boundary.
- `.planning/phases/12-design-system-component-layer/12-UI-SPEC.md` - component contracts, slots, attrs, CSS/tokens, DS-06 regex, modal/drawer/table/notebook/form details.
- `.planning/phases/11-evaluation-engine-seed-depth/11-CONTEXT.md` - screenshot/critique proof loop and seed-depth constraints.
- `priv/shots/gap_register.md` - baseline critique findings for eval/prompt/prompt_release density/responsive/a11y and all-screen design gaps.

### Brand, Research, and Product Strategy
- `brandbook/brand-book.md` - binding brand voice, color/token rules, accessibility guidance, microcopy, and "field engineer" design posture.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops strategy, dashboard/admin UI lessons, AI UX patterns, and eval flywheel pitfalls.
- `prompts/scoria-brand-book-deep-research.md` - original brand research and Scoria positioning.
- `prompts/scoria-gsd-kickoff.md` - project vision and LiveView operator UI goals.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable Elixir library architecture and operator-first DX.
- `.planning/research/liveview-operator-ux.md` - prior LiveView operator-UX research referenced by Phase 13.

### Shared Design System and CSS
- `lib/scoria_web/ui.ex` - shared components: panel, metric, object_header, empty_state, modal, drawer, field, form_section, skeleton, toast, notebook, raw_evidence, table.
- `assets/css/02-tokens.css` - runtime semantic token SSOT; do not change for cosmetic preference.
- `assets/css/04-components.css` - component CSS for shared UI classes; add scoped component classes here when needed.
- `assets/css/05-motion.css` - existing motion primitives; Phase 14 should not broaden motion scope.
- `test/support/ds06_baseline.txt` - raw-palette ratchet baseline; Phase 14 shrinks/removes in-scope rows.

### Phase 14 Code Surfaces
- `lib/scoria_web/dashboard_nav.ex` - add Dataset Builder nav entry, active view mapping, shortcut, command palette row, and `/datasets` base stripping.
- `lib/scoria_web/router.ex` - add Dataset Builder dashboard route.
- `lib/scoria_web/live/review_queue_live.ex` - convert to shared components and route promotion to Dataset Builder.
- `lib/scoria_web/live/incidents_live/index.ex` - convert shell to shared components.
- `lib/scoria_web/components/incident_evidence_component.ex` - single Phase 14 evidence-adapter exception; convert to local notebook/panel adapter.
- `lib/scoria_web/live/eval_spec_live/index.ex` - convert Eval Workbench to shared components and preserve next-step links.
- `lib/scoria_web/live/prompt_live/index.ex` - convert Prompt Registry to shared components and preserve edit/version behavior.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - convert Release Workbench comparison/approval UI to shared components.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - existing promotion behavior to reuse/refactor for Dataset Builder.
- `lib/scoria_web/live/workflow_live/show.ex` - minimum allowed touch: route existing promote affordance to Dataset Builder; no broader Workflow Show polish.
- `lib/scoria/eval.ex`, `lib/scoria/eval/dataset_promotion.ex`, `lib/scoria/eval/review_queue.ex` - existing backend behavior to reuse; do not add new capability family.

### Test Surfaces
- `test/scoria_web/live/review_queue_live_test.exs` - existing Review Queue behavior tests to preserve/update.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - existing dataset promotion behavior tests to preserve/reuse.
- `test/scoria_web/live/eval_spec_live/index_test.exs` - existing Eval Workbench tests to preserve/update.
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` - existing Release Workbench tests to preserve/update.
- `test/scoria_web/dashboard_nav_test.exs` - update for Dataset Builder not being a stub and nav/shortcut behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScoriaWeb.UI` components already cover most Phase 14 needs. Use them before adding new APIs.
- `DatasetLive.PromoteComponent` already implements draft promotion, sealed-baseline approval request, expected output JSON validation, source-run links, and promotion notices. Refactor/reuse this behavior under Dataset Builder instead of duplicating it.
- `ReviewQueueLive` already has clean LiveView events and data assigns for filters, selection, summary, datasets, dismiss, direct promote, and baseline request. Keep the event boundaries that remain relevant, but route dataset actions out.
- `ReleaseWorkbenchLive` already uses `object_header` and `origin_context`; preserve that pattern while replacing bespoke comparison cards/notices/modals.
- `IncidentsLive.Index` already threads to run/trace with `from=incident:<id>`; preserve those links.

### Established Patterns
- Embedded Phoenix library posture: routes live under the dashboard mount prefix and must work under arbitrary `scoria_dashboard("/path")` mounts.
- `DashboardNav.groups/0` is the IA SSOT for sidebar, command palette, and shortcuts.
- Query-param origin context from Phase 13 is the accepted way to preserve loop context across pages.
- DS-06 is a ratchet: touched in-scope files should move toward zero raw palette, not preserve baseline debt.
- LiveViewTest is the primary verification posture; browser screenshots/critique are dev-only proof tooling, not merge-blocking CI.

### Integration Points
- Add `/datasets` inside `scoria_dashboard/2` live session.
- Add Dataset Builder as Improve nav item; stub screens remain stubs, but Dataset Builder must be a real route.
- Review Queue and Workflow Show source links navigate into Dataset Builder with promotion context.
- Dataset Builder reconstructs promotion context from `Eval`/workflow/review records and calls existing promotion APIs.
- Eval Workbench links continue to Prompt Release and regressed runs using `from=eval:<id>`.
- Release Workbench links continue back to Eval Workbench and baseline runs using `from=prompt:<id>`.

</code_context>

<specifics>
## Specific Ideas

- Review Queue subtitle: `Review flagged traces before they become datasets, baselines, or dismissed noise.`
- Review Queue empty state: `Scoria has no flagged traces for this filter set. Production traces that fail scoring, trigger policy, or look promotion-ready will appear here.`
- Dataset Builder promotion route examples:
  - `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=original`
  - `/datasets?promote=workflow&run_id=...&step_id=...&source_variant=replay`
  - `/datasets?promote=review&review_candidate_id=...`
- Release Workbench next-step verbs stay flat: `View eval results`, `View baseline runs`. No stepper.
- Incident evidence exception wording for planners: "Phase 14 may touch `IncidentEvidenceComponent` only because Incidents renders it as first-order screen content and it blocks SCREEN-01/DS-06 for Incidents. Treat this as a one-component exception, not the Phase 15 evidence-adapter sweep."
- External tools considered during discussion: Braintrust, Langfuse, Arize Phoenix, LangSmith, Sentry, Oban Web, Phoenix LiveDashboard, Datadog/New Relic incident views, Aludel, Tribunal. Local prompt files and brandbook remain the canonical repo-local references.

</specifics>

<deferred>
## Deferred Ideas

- Broad evidence-adapter conversion across all 13 evidence components remains Phase 15.
- Live Ops / Workflows / Approvals / Connectors polish remains Phase 15.
- Full motion/responsive/theme parity sweep remains Phase 16.
- Final screenshot-contact-sheet proof and MAINTAINERS component catalog remain Phase 17.
- Full prompt/model experiment playground, generated prompt variants, side-by-side run controls, and model-parameter tuning are future backend-backed capabilities.
- Review Queue reviewer assignment, corrected-output authoring, human annotation scoring, bulk actions, lane/kanban workflow, and row-keyboard shortcuts are future capabilities.
- Dataset imports/CSV upload, schema builders, archive/delete management, synthetic dataset generation, and batch add observations are future Dataset Builder expansions unless already trivially backed.
- No todo matches were found for Phase 14, so no todos were folded or reviewed.

</deferred>

---

*Phase: 14-least-iterated-screens-polish*
*Context gathered: 2026-06-12*
