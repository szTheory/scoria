# Phase 15: High-traffic screens + evidence adapters - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** Advisor-mode discussion - user selected all 4 gray areas, explicitly requested subagent-backed research, and approved the synthesized recommendation set

<domain>
## Phase Boundary

Phase 15 polishes Scoria's high-traffic Control Room surfaces and completes the remaining evidence-adapter consolidation. The phase closes SCREEN-03 and SCREEN-04 by converting Home / Live Ops, Runs / Workflow Show, Approvals, Connectors, and the remaining evidence components onto the shared `ui.ex` component layer.

This phase is UI/IA/DX only. It must not add net-new backend capability, query languages, session replay surfaces, connector setup workflows, fake data, new routes for approval/connector detail objects, or broad proof/docs work. Existing Ecto contexts, PubSub streams, LiveView event flows, origin context, Dataset Builder promotion flow, and Phase 12/13/14 component patterns are reused. Phase 16 still owns cross-dashboard motion/responsive/theme parity; Phase 17 still owns final proof, contact sheets, and docs.

</domain>

<decisions>
## Implementation Decisions

### Home / Live Ops Action Model
- **D-01:** Keep Home mounted at `/` as a calm status-first triage surface with the Phase 13 attention strip and the live trace stream. Home keeps zero-click live feedback for operators, but it is not a workbench.
- **D-02:** Replace Home's inline god-page buttons with design-system deep links and compact status actions. Allowed Home actions are read/navigation oriented: `Open run`, `Open trace`, `Open incident`, `Review approval`, and equivalent mount-prefix-safe links with `from=` origin context where useful.
- **D-03:** Move raw evidence loading, replay, promotion, and other provenance-heavy or mutating actions out of Home. Replay and trace inspection belong on Runs / Workflow Show; promotion belongs in Dataset Builder through the Phase 14 promotion URLs.
- **D-04:** Home trace cards should be compact, read-only summaries: trace/run ID, current status, key badges, short span signal, and next destination. Do not embed full notebook panels, raw JSON, replay controls, or promote controls in the stream.
- **D-05:** Preserve Home's day-0 feedback: the empty state still makes it obvious that the first chat response, agent run, eval sample, or MCP request will appear as a trace.

### Runs / Workflow Show as Canonical Trace Explorer
- **D-06:** Runs index becomes a shared-component scan surface: page title, short operator subtitle, optional lightweight filters only if backed by current assigns/data, `<.table id="runs">`, status badges, mono IDs, timestamps, and one primary action: `Open trace`.
- **D-07:** Workflow Show is the canonical APM-style trace inspector: `object_header` + next-step verbs, followed by a two-pane trace area and then a unified evidence notebook stack.
- **D-08:** The primary trace area should keep the durable run/span tree as the first-class object. Use a tree or waterfall-like list on the left and selected-step detail on the right. The selected-step detail may be sticky on desktop and collapse into a drawer/stack on narrow viewports, but do not create a custom nested app shell.
- **D-09:** Keep next-step verbs flat and evidence-based: `Replay run`, `Promote in Dataset Builder`, `Open incident`, `Open prompt`, `View associated runtime presence`. They should be design-system buttons/links and preserve origin context where applicable.
- **D-10:** Timeline, replay provenance, semantic evidence, delegated evidence, memory evidence, remote invocation evidence, and raw details should render through the notebook/adapters described below. Do not leave bespoke raised cards, raw Tailwind palette classes, or duplicated raw-evidence disclosures in Workflow Show.
- **D-11:** Do not add TraceQL-style search, flame graph/map modes, session-first replay, conversation browser, or new aggregated trace analytics in Phase 15. These are future capabilities unless already trivially backed by current data and expressed as simple table filters.

### Approvals and Connectors Detail Patterns
- **D-12:** Approvals and Connectors use shared tables as their primary scan surfaces. Tables should prioritize operator scanability, explicit text status, stable IDs, relevant timestamps/counts, and one clear inspect action.
- **D-13:** Primary detail inspection opens in the shared `<.drawer>` shell, owned by the parent LiveView's selected state. Drawers should preserve list context, restore focus, label themselves accessibly, and use notebook-like sections when detail content becomes dense.
- **D-14:** The shared `<.modal>` shell is reserved for final approve/reject confirmation or similarly safety-relevant decisions. Approval detail is not modal-first; the modal is the irreversible-decision boundary.
- **D-15:** Approval copy must state the consequence plainly. Approval resumes the workflow when possible; rejection records a durable rejection and keeps the workflow paused. Do not use the same green/pass treatment for approval and rejection.
- **D-16:** Connectors should show runtime presence and connector fleet posture as dense shared tables or table-like panels, not sparse card grids. Status dots are decorative only; text labels are mandatory.
- **D-17:** Do not add separate approval detail routes, connector detail routes, setup wizards, tool registry behavior, MCP Gateway behavior, or richer connector lifecycle controls in Phase 15. These belong to later backend-backed phases.

### Evidence Adapter Consolidation Contract
- **D-18:** Use "notebook shell + shared evidence primitives" as the Phase 15 adapter contract. A thin adapter imports `ScoriaWeb.UI`, renders one `<.notebook>` with domain tabs/sections, maps existing assigned evidence into rows/sections/actions, and contains only domain data projection, copy, and event/link wiring.
- **D-19:** `ui.ex` owns shared evidence presentation: outer section chrome, notebook header/tab behavior, section/card framing, key-value rows, raw evidence disclosure, empty-state framing, badge/tone mapping, focus/accessibility semantics, and dark/light styling.
- **D-20:** Adapters must not own bespoke raised cards, ad-hoc grid/list chrome, raw palette classes, one-off raw JSON `<details>` blocks, custom badge styling, or duplicated empty-state wrappers.
- **D-21:** Add small `ui.ex` primitives only when they remove repeated evidence layout. Acceptable candidates: evidence section, evidence row/key-value list, evidence action row, compact code/raw block wrapper, and notebook empty state. Avoid a typed descriptor renderer, plugin registry, or UI schema language.
- **D-22:** Convert all in-scope evidence/detail components toward this contract, including citation evidence, delegated evidence, memory notebook, replay evidence notebook, semantic evidence notebook, runtime detail drawer, connector detail drawer, approval inbox, workflow detail panel, trace tree/workflow tree polish, and any remaining Workflow Show evidence blocks. `IncidentEvidenceComponent` and `RemoteInvocationEvidenceComponent` already moved closer to the contract in earlier phases; preserve/reuse their lessons rather than reintroducing bespoke chrome.
- **D-23:** Existing data contracts are preserved. The phase changes how evidence is presented, not what evidence exists or how it is persisted.

### Cross-Screen Polish Rules
- **D-24:** For every in-scope file touched by Phase 15, remove raw palette classes and shrink or remove the corresponding `test/support/ds06_baseline.txt` row. Do not add new raw palette classes anywhere under `lib/scoria_web/`.
- **D-25:** Use Scoria brand voice everywhere: calm, exact, useful. Prefer evidence verbs such as traced, replayed, promoted, compared, gated, approved, rejected, paused, resumed, refreshed, and inspected. Avoid hype, magic, hidden chain-of-thought language, or color-only status.
- **D-26:** Bind to the existing runtime token system. Do not touch `assets/css/02-tokens.css` for cosmetic preference. Token changes are reserved for WCAG/accessibility defects or genuine coherence breaks.
- **D-27:** Use conventional operator-dashboard components: shared tables, filters, panels, drawers, modals, badges, empty states, object headers, next-step verb rows, and notebook shells. Avoid decorative cards, vanity metrics, graph modes without data support, fake timelines, and marketing composition.
- **D-28:** Preserve LiveViewTest-first verification. Browser screenshot/critique tooling remains dev-only proof support, not merge-blocking CI.

### Agent's Discretion
- Exact component APIs for any new evidence primitives, CSS class names, plan slicing, table columns, drawer section order, selected-step responsive behavior, and whether the Workflow Show selected-step detail is sticky or stacked are planner/executor discretion, constrained by the decisions above.
- The planner may decide whether Approvals uses a desktop inline rail before the drawer/modal boundary, but the default recommendation is table -> drawer -> final decision modal.
- The planner may choose the exact order of adapter conversion, but should prefer shared primitive work before large adapter rewrites so the DS-06 ratchet is durable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Prior Decisions
- `.planning/PROJECT.md` - v3.0 Control Room goal, product boundary, personas, and UI-only milestone constraints.
- `.planning/REQUIREMENTS.md` - SCREEN-03 and SCREEN-04 are Phase 15; MOTION-01..04 and PROOF-01..03 remain later phases.
- `.planning/ROADMAP.md` - Phase 15 goal/success criteria and adjacent Phase 14/16/17 boundaries.
- `.planning/STATE.md` - current milestone state, completed Phase 14 status, deferred items, and DS-06/raw-color context.
- `.planning/phases/14-least-iterated-screens-polish/14-CONTEXT.md` - Dataset Builder promotion ownership, Review Queue/Incidents/Eval/Prompt polish rules, cross-screen voice, and Phase 15 evidence boundary.
- `.planning/phases/13-orientation-spine-ia/13-CONTEXT.md` - Home status-first contract, nav groups, object headers, next-step verbs, origin context, and honest stub boundaries.
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` - token gateway, DS-06 ratchet, notebook shell contract, and screen/adaptor conversion ownership.
- `.planning/phases/12-design-system-component-layer/12-UI-SPEC.md` - locked component contracts, slots, attrs, CSS/tokens, modal/drawer/table/notebook/form details, and DS-06 regex.
- `.planning/phases/11-evaluation-engine-seed-depth/11-CONTEXT.md` - screenshot/critique harness, state matrix, and seed-depth constraints.
- `.planning/phases/11-evaluation-engine-seed-depth/11-UI-SPEC.md` - screen list, screenshot matrix, populated-state minimums, and Control Room rubric.
- `priv/shots/gap_register.md` - baseline critique findings, especially connectors density and all-screen consistency gaps.

### Brand, Product Strategy, and Prompt Corpus
- `brandbook/brand-book.md` - binding brand voice, color/token rules, accessibility guidance, UI guidance, and microcopy rules.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops strategy, trace/eval flywheel, LiveView operator UI lessons, AI UX patterns, and footguns.
- `prompts/scoria-brand-book-deep-research.md` - original brand research and Scoria positioning.
- `prompts/brand-book-pressure-test-prompt.md` - pressure-test lenses for brand, UI/UX, accessibility, implementation readiness, and microcopy.
- `prompts/scoria-gsd-kickoff.md` - project vision, trace store, eval workbench, governance layer, and LiveView operator dashboard goals.
- `prompts/sztheory-elixir-dna.md` - embedded LiveView dashboards, durable state, operator-first DX, and Elixir ecosystem posture.

### External Ecosystem References Consulted
- `https://phoenix-live-dashboard.hexdocs.pm/metrics.html` - LiveDashboard pattern: embedded Phoenix observability configured through telemetry and separate focused pages.
- `https://oban-web.hexdocs.pm/overview.html` - Oban Web pattern: embedded LiveView dashboard, realtime updates, filtering, detailed inspection, and controlled actions.
- `https://docs.sentry.io/concepts/key-terms/tracing/` - tracing concepts and trace/span terminology for operator debugging.
- `https://docs.datadoghq.com/tracing/trace_explorer/trace_view/` - trace detail page patterns: trace header, visualizations, span details, and inspection controls.
- `https://docs.datadoghq.com/tracing/trace_explorer/` - live trace search, high-throughput stream pause/select behavior, and filter/query cautions.
- `https://docs.newrelic.com/docs/distributed-tracing/ui-data/trace-details/` - trace details page pattern: timeline/latency/waterfall views and selected span details.
- `https://langfuse.com/docs` - LLM observability/evaluation platform pattern: traces, prompts, evals, and open/self-hostable AI engineering workflow.
- `https://arize.com/docs/phoenix` - AI observability workflow: traces -> evaluations -> prompts -> datasets/experiments.
- `https://docs.langchain.com/langsmith/evaluation` - evaluation feedback loop: production traces -> datasets -> offline experiments -> redeploy.

### Shared Design System and CSS
- `lib/scoria_web/ui.ex` - shared components: attention_card, panel, metric, object_header, empty_state, modal, drawer, field, form_section, skeleton, toast, notebook, raw_evidence, table.
- `assets/css/02-tokens.css` - runtime semantic token SSOT; do not change for cosmetic preference.
- `assets/css/04-components.css` - component CSS for shared UI classes; add scoped component classes here when needed.
- `assets/css/05-motion.css` - existing motion primitives; Phase 15 should not broaden motion scope.
- `test/support/ds06_baseline.txt` - raw-palette ratchet baseline; Phase 15 shrinks/removes in-scope rows.

### Phase 15 Code Surfaces
- `lib/scoria_web/live/orchestrator_live.ex` - Home / Live Ops stream; replace inline evidence/replay/promote buttons with compact summaries and deep links.
- `lib/scoria_web/live/workflow_live/index.ex` - Runs index; convert to shared table/filter/empty-state pattern.
- `lib/scoria_web/live/workflow_live/show.ex` - canonical trace inspector; object header, next-step verbs, trace area, evidence notebook stack, Dataset Builder links.
- `lib/scoria_web/live/approvals_live/index.ex` - Approvals surface; table -> drawer detail -> final decision modal; preserve durable decision behavior.
- `lib/scoria_web/live/connectors_live/index.ex` - Connectors surface; runtime/connector scan tables and shared drawers.
- `lib/scoria_web/components/approval_inbox_component.ex` - approval queue/list presentation to convert to shared table/drawer-friendly shape.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` - runtime detail drawer to convert to shared drawer/notebook primitives.
- `lib/scoria_web/components/connector_detail_drawer_component.ex` - connector detail drawer to convert to shared drawer/notebook primitives.
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - selected-step detail and nested replay/semantic evidence to convert to shared primitives.
- `lib/scoria_web/components/workflow_tree_component.ex` - workflow tree display in canonical trace area.
- `lib/scoria_web/components/trace_tree_component.ex` - Home trace summary/tree component to polish without making Home a workbench.
- `lib/scoria_web/components/citation_evidence_component.ex` - retrieval/citation evidence adapter.
- `lib/scoria_web/components/delegated_evidence_component.ex` - delegated handoff evidence adapter.
- `lib/scoria_web/components/memory_notebook_component.ex` - memory evidence adapter.
- `lib/scoria_web/components/replay_evidence_notebook_component.ex` - replay comparison evidence adapter.
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex` - semantic fast-path evidence adapter.
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` - existing Phase 12 proof adapter; preserve as model where useful.
- `lib/scoria_web/components/incident_evidence_component.ex` - Phase 14 converted adapter; preserve as model where useful.
- `lib/scoria_web/dashboard_nav.ex` - preserve Home/Runs/Approvals/Connectors IA and mount-prefix-safe nav behavior.
- `priv/dev/shots.mjs` and `lib/mix/tasks/scoria.ui.shots.ex` - dev-only screenshot harness if planner chooses to validate visual state during or after implementation.

### Test Surfaces
- `test/scoria_web/live/orchestrator_live_test.exs` - Home/stream behavior tests.
- `test/scoria_web/live/orchestrator_live_integration_test.exs` - Home integration behavior.
- `test/scoria_web/live/orchestrator_live_sre_test.exs` - SRE badges and incident evidence behavior.
- `test/scoria_web/live/workflow_live_test.exs` - Workflow Show trace/evidence behavior.
- `test/scoria_web/live/approvals_live_test.exs` - Approvals surface behavior.
- `test/scoria_web/live/approvals_live_integration_test.exs` - approval decision integration.
- `test/scoria_web/live/connectors_live_test.exs` - Connectors surface behavior.
- `test/scoria_web/components/runtime_detail_drawer_component_test.exs` - runtime drawer behavior.
- `test/scoria_web/components/semantic_evidence_notebook_component_test.exs` - semantic evidence behavior.
- `test/scoria_web/components/trace_tree_component_test.exs` - trace tree behavior.
- `test/scoria_web/components/incident_evidence_component_test.exs` - existing notebook adapter behavior to preserve.
- `test/scoria_web/ui_component_test.exs` - shared component and remote invocation adapter tests.
- `test/scoria_web/ds06_drift_guard_test.exs` - raw-palette ratchet enforcement.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScoriaWeb.UI` already exposes the core Phase 15 primitives: table, drawer, modal, object_header, panel, badge, empty_state, skeleton, toast, notebook, raw_evidence.
- `object_header/1` and Phase 13 origin context are already wired into Workflow Show; continue using that pattern for run detail and deep links.
- `DashboardNav.groups/0` and `@views` are the IA SSOT; Phase 15 should not create new nav nouns or duplicate routes.
- `DatasetLive.PromoteComponent` and Dataset Builder routes already own promotion; Workflow Show and Home should route there instead of reintroducing local promotion UI.
- `RemoteInvocationEvidenceComponent` and `IncidentEvidenceComponent` are useful proof points for notebook-based adapters, but Phase 15 should generalize shared primitives further so adapter chrome does not drift.
- `assign_async`, PubSub subscriptions, and LiveViewTest-visible server assigns are existing patterns; prefer them over new client-side JS for Phase 15 polish.

### Established Patterns
- Embedded Phoenix library posture: routes must work under arbitrary `scoria_dashboard("/path")` mounts. All generated links must use `assigns[:scoria_base] || ""` or existing helpers.
- Parent LiveViews own state; shared components are slot/attr shells and emit regular LiveView events.
- DS-06 is a ratchet. Touched in-scope files should move toward zero raw palette, and no new file may introduce raw palette classes.
- Status is never conveyed by color alone. Badges/dots must include explicit text labels.
- LiveViewTest is the primary verification posture; browser screenshots/critique are dev-only proof tooling.

### Integration Points
- Home deep links connect to `/workflows/:id`, `/incidents`, `/approvals`, and Dataset Builder / prompt surfaces through existing routes and `from=` origin context.
- Workflow Show selected step controls drive the trace inspector, evidence adapters, and Dataset Builder promotion context.
- Approvals use existing `Workflows.list_pending_remote_approvals/1`, `Workflows.approve/3`, and `Resume.resume_run/1`; the phase changes the shell, not decision semantics.
- Connectors use existing `OperatorSurface.load_runtimes/1`, `OperatorSurface.connector_fleet/1`, and drawer projection functions; the phase changes presentation only.
- Evidence adapters consume existing maps/DTOs from runtime, SRE, semantic, replay, delegated, remote invocation, incident, and memory contexts.

</code_context>

<specifics>
## Specific Ideas

- Home action grammar: `Open run`, `Open trace`, `Review approval`, `Open incident`. Avoid `Load Deep Metadata`, `Load Retrieval Evidence`, `Load Budget State`, `Replay Retrieval`, and `Promote Retrieval` on Home.
- Workflow Show shape: run index -> object header -> next-step verbs -> trace tree/waterfall-like list + selected step detail -> evidence notebook stack -> timeline/raw evidence.
- Approvals shape: table scan, drawer detail, final modal. Modal copy must distinguish approval from rejection and state workflow consequence.
- Connectors shape: runtime presence and connector posture as dense scan tables with drawer detail; no sparse card grid as the primary populated state.
- Thin adapter definition for planners: "adapter owns projection, copy, links/events; `ui.ex` owns chrome, rows, raw evidence, tone, empty state, accessibility, and dark/light styling."
- Research-backed ecosystem lesson: mature tools keep live status surfaces narrow and move inspection/actions to durable object pages. Scoria should learn the pattern without copying enterprise APM complexity.
- External tools considered during discussion: Phoenix LiveDashboard, Oban Web, Sentry, Datadog, New Relic, Grafana/Tempo, Langfuse, LangSmith, Arize Phoenix, GitHub Actions approvals, Vercel/Netlify deploy panels, Stripe integrations.

</specifics>

<deferred>
## Deferred Ideas

- Inline Home replay/promote drawers, bulk stream actions, and row keyboard triage.
- Full TraceQL-style search, flame graph/map visualizations, service maps, session-first replay, and conversation browser.
- Separate approval detail routes, connector detail routes, connector setup wizards, Tool Registry behavior, MCP Gateway behavior, and richer connector lifecycle controls.
- Typed evidence descriptor renderer, evidence plugin registry, adapter behaviour, or UI schema language for external/custom evidence kinds.
- Broad cross-dashboard motion/responsive/theme parity remains Phase 16.
- Final screenshot-contact-sheet proof and MAINTAINERS component catalog remain Phase 17.
- No todo matches were found for Phase 15, so no todos were folded or reviewed.

</deferred>

---

*Phase: 15-high-traffic-screens-evidence-adapters*
*Context gathered: 2026-06-12*
