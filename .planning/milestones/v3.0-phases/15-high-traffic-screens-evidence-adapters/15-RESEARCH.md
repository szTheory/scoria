# Phase 15: High-traffic screens + evidence adapters - Research

**Researched:** 2026-06-12
**Status:** Ready for planning
**Phase requirement IDs:** SCREEN-03, SCREEN-04

## Research Question

What does the planner need to know to convert the high-traffic Control Room screens and remaining evidence components without adding backend scope, duplicating layout logic, or weakening the design-system ratchet?

## Executive Summary

Phase 15 is mostly an adoption and consolidation phase, not a new capability phase. The repository already has the core shared shells in `ScoriaWeb.UI`: `<.table>`, `<.drawer>`, `<.modal>`, `<.object_header>`, `<.panel>`, `<.badge>`, `<.empty_state>`, `<.notebook>`, `<.raw_evidence>`, `<.skeleton>`, `<.toast>`, and `<.id>`. The gap is that high-traffic screens and evidence adapters still bypass those shells with raw Tailwind palette classes, local card chrome, custom modal/drawer markup, and one-off raw evidence disclosures.

Recommended planning shape:

1. Add small shared evidence primitives to `lib/scoria_web/ui.ex` and `assets/css/04-components.css` before large adapter rewrites.
2. Convert Home / Live Ops into a compact live status surface with deep links only, moving evidence loading/replay/promotion out of the page.
3. Convert Runs index and Workflow Show into the canonical trace explorer: shared table entry point, object header, next-step verbs, two-pane trace inspector, then notebook adapters.
4. Convert Approvals and Connectors to shared tables plus shared drawer/modal shells while preserving existing event semantics.
5. Convert citation, delegated, memory, replay, semantic, workflow detail, runtime/connector detail, and related evidence components into thin notebook adapters over the new shared primitives.
6. Tighten `test/support/ds06_baseline.txt` for every touched file whose raw-palette count reaches zero.

No new package is needed.

## External Ecosystem Findings

### Embedded Phoenix Dashboards

- Phoenix LiveDashboard keeps observability embedded in Phoenix and derives focused pages from Telemetry metrics. Its docs emphasize adding telemetry dependencies, defining a telemetry module, and configuring `live_dashboard` with metrics; the dashboard maps metrics to real-time charts without requiring app-specific UI inventions. Source: https://phoenix-live-dashboard.hexdocs.pm/metrics.html
- Oban Web is also an embedded LiveView dashboard. Its relevant product pattern is realtime monitoring, filtering, detailed inspection, controlled actions, access control, and action logging within the host app. Source: https://oban-web.hexdocs.pm/overview.html

Planning implication: Scoria should stay embedded, route-stable, and operationally focused. Use existing LiveView routes and actions; do not create nested app shells or new route families for detail objects in this phase.

### Trace Explorer Patterns

- Sentry's tracing docs define traces as connected operations composed of spans, and its Trace View uses a detailed waterfall to show where time and errors originate. Source: https://docs.sentry.io/concepts/key-terms/tracing/
- Datadog distinguishes live trace streams from retained/indexed trace search. It notes that high-throughput span streams are not human-readable, so the UI shows some spans for clarity and provides search plus pause/play. Source: https://docs.datadoghq.com/tracing/trace_explorer/
- Datadog's Trace View exposes trace header facts and lets users inspect the same trace as Flame Graph, Span List, Waterfall, or Map. Source: https://docs.datadoghq.com/tracing/trace_explorer/trace_view/
- New Relic's trace details page separates timeline, latency, and waterfall views; operators select spans from dense trace views to inspect detail. Source: https://docs.newrelic.com/docs/distributed-tracing/ui-data/trace-details/

Planning implication: Home should remain a narrow live stream and should not attempt full inspection. Workflow Show should own inspection with a durable trace tree/waterfall-like list, selected-step detail, and evidence notebook sections. Avoid TraceQL, flame graph, service map, and analytics scope unless existing data trivially supports it.

### AI Observability and Eval Loops

- Langfuse groups observability, prompts, evaluations, datasets, and experiments as a continuous AI engineering workflow; traces include LLM calls, retrieval, embeddings, API calls, sessions, and agent graphs. Source: https://langfuse.com/docs
- Arize Phoenix positions traces as the way to inspect a single AI run step by step, then evaluates outputs, iterates prompts, and turns traces into datasets/experiments. Source: https://arize.com/docs/phoenix
- LangSmith evaluation docs describe the loop: create datasets from curated cases or production traces, define evaluators, run experiments, compare results, and feed failing production traces back into datasets. Source: https://docs.langchain.com/langsmith/evaluation

Planning implication: Phase 15 should keep Scoria's quality loop legible: run -> trace -> replay -> promote to Dataset Builder -> eval -> gate prompt release. Links and verbs should reinforce this flow without adding unbacked eval or experiment features.

## Local Code Findings

### Shared Component Inventory

`lib/scoria_web/ui.ex` currently provides:

- `tone/1` and `status_label/1` as the shared tone/status label mapping.
- `<.badge>` with text label and optional dot.
- `<.button>` variants `:primary`, `:ghost`, `:danger`.
- `<.panel>` with optional eyebrow/title/actions.
- `<.metric>`, `<.attention_card>`, `<.object_header>`, `<.empty_state>`.
- `<.modal>` and `<.drawer>` slot shells with dismiss events owned by parent LiveViews.
- `<.field>` and `<.form_section>`.
- `<.skeleton>`, `<.toast>`, `<.notebook>`, `<.raw_evidence>`, and `<.table>`.

Gaps for SCREEN-04:

- No shared key-value / evidence-row primitive.
- No shared evidence section primitive inside a notebook.
- No shared compact action-row/link-row primitive for evidence notebooks.
- No shared adapter empty state inside notebooks beyond caller slot content.
- Several adapters use inline styles, local cards, or raw Tailwind classes because the current shared notebook only supplies outer shell and tabs.

Recommended additions:

- `evidence_section/1`: title, description, optional badge/actions, `inner_block`.
- `evidence_kv/1` or `evidence_rows/1`: stable key-value rows for maps/DTOs.
- `evidence_action_row/1`: compact link/action strip using existing button/link styling.
- `evidence_empty/1`: notebook-scoped empty state with exact title/body.
- Optional `evidence_code/1` only if `<.raw_evidence>` is too narrow; prefer extending `<.raw_evidence>` first.

Do not build a descriptor renderer, plugin registry, or typed schema language. The adapters should still own projection/copy/event wiring.

### Raw-Palette Debt in Phase 15 Scope

The DS-06 baseline currently lists in-scope rows:

- `lib/scoria_web/live/orchestrator_live.ex:26`
- `lib/scoria_web/live/workflow_live/index.ex:4`
- `lib/scoria_web/live/workflow_live/show.ex:50`
- `lib/scoria_web/live/approvals_live/index.ex:9`
- `lib/scoria_web/live/connectors_live/index.ex:20`
- `lib/scoria_web/components/approval_inbox_component.ex:12`
- `lib/scoria_web/components/citation_evidence_component.ex:18`
- `lib/scoria_web/components/connector_detail_drawer_component.ex:9`
- `lib/scoria_web/components/delegated_evidence_component.ex:46`
- `lib/scoria_web/components/memory_notebook_component.ex:19`
- `lib/scoria_web/components/replay_evidence_notebook_component.ex:24`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex:38`
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex:27`
- `lib/scoria_web/components/trace_tree_component.ex:7`
- `lib/scoria_web/components/workflow_detail_panel_component.ex:12`
- `lib/scoria_web/components/workflow_tree_component.ex:1`

Implementation rule: every plan touching one of these files must remove raw classes from that file or explicitly lower the baseline count if zero is not reached. No new raw palette classes should appear under `lib/scoria_web/`.

### High-Traffic Screens

#### Home / Live Ops: `lib/scoria_web/live/orchestrator_live.ex`

Current facts:

- Imports only `attention_card`, `badge`, and `flash_group`.
- Still owns events and UI for `load_metadata`, `load_retrieval_evidence`, `load_budget_state`, `load_incident_evidence`, `replay_retrieval`, and `promote_retrieval`.
- Renders six inline stream buttons including `Load Deep Metadata`, `Load Retrieval Evidence`, `Load Budget State`, `Load Incident Evidence`, `Replay Retrieval`, and `Promote Retrieval`.
- Renders `CitationEvidenceComponent` and `IncidentEvidenceComponent` inline when async assigns are loaded.
- Uses raw palette classes for the trace card, review candidate context, metadata, budget state, replay notices, and promote notices.

Planning implication:

- Remove or strand the provenance-heavy events from Home rendering. The event handlers can be deleted if tests do not need them, or left unused only if removal would cascade beyond UI scope.
- Replace each stream card with a compact read-only summary and design-system deep links. Use mount-prefix-safe paths from `assigns[:scoria_base] || ""`.
- Preserve day-0 empty copy, PubSub stream behavior, token preview behavior, trace badges, and attention cards.
- Route inspection to `/workflows/:run_id` where possible. If no run ID exists, provide a trace destination only if existing routes support it; otherwise keep a non-mutating summary.
- Route approvals to `/approvals?from=run:<id>` or equivalent supported query.

#### Runs index: `lib/scoria_web/live/workflow_live/index.ex`

Current facts:

- Already imports all `ScoriaWeb.UI`.
- Uses `<.panel>`, `<.empty_state>`, `<.id>`, and `<.badge>`.
- Still renders a raw `<table class="scoria-table">` instead of `<.table>`.
- Uses raw `text-stone-600` on subtitle and cells.

Planning implication:

- This is a small conversion: switch to `<.table id="runs" rows={@runs} density={:compact}>`.
- Preserve `list_runs/0`, 50-row ordering, `short_id/1`, `format_ts/1`, and `Open trace`.
- Add or adjust tests to assert shared table markup and exact operator copy.

#### Workflow Show: `lib/scoria_web/live/workflow_live/show.ex`

Current facts:

- Imports only `object_header` and `skeleton`.
- Already has object header, next-step verbs, origin context, Dataset Builder promotion URL, prompt/incident links, and remote invocation evidence.
- Uses a page-local shell (`min-h-screen bg-stone-50 px-6 py-8 text-stone-900`) inside the app layout.
- Uses raw cards for replay provenance, promotion/baseline notices, review candidate evidence, trace tree container, memory failure, timeline, and promote modal.
- Uses custom promote modal markup instead of `<.modal>`.
- Trace area is close to the desired two-pane shape: `WorkflowTreeComponent.workflow_tree` plus `WorkflowDetailPanelComponent.workflow_detail_panel`.

Planning implication:

- Keep data loading and event behavior stable.
- Convert page shell to app-layout-native `scoria-dashboard`.
- Import needed shared components: `badge`, `button`, `modal`, `panel`, `raw_evidence` or new evidence primitives.
- Convert replay provenance strip, notices, trace tree wrapper, timeline, memory failure state, and promote modal to shared components.
- Ensure `View associated runtime presence` is mount-prefix-safe. Current hard-coded `/scoria?runtime=...` should use `assigns[:scoria_base] || ""`.
- Keep Dataset Builder promotion path unchanged except for style/shell.

#### Approvals: `lib/scoria_web/live/approvals_live/index.ex` and `lib/scoria_web/components/approval_inbox_component.ex`

Current facts:

- LiveView imports only `flash_group` and `toast`.
- Approval inbox component is a local card/list with raw classes.
- Detail is modal-first with custom overlay markup.
- Existing semantics are important: `approve` calls `Workflows.approve/3`, then resumes run only on approval; rejection records a durable rejection and keeps workflow paused.
- Phase 14 already fixed toast tone distinction; preserve it.

Planning implication:

- Convert inbox to a shared `<.table id="approvals">` scan surface with inspect action.
- Parent LiveView should own selected state and render shared `<.drawer>` for detail.
- Final approve/reject confirmation should use shared `<.modal>` and preserve existing `approve`, `reject`, and `dismiss_approval` behavior. If the existing event shape is changed to require confirmation state, tests must prove durable behavior still passes.
- Copy must distinguish approval from rejection consequence.

#### Connectors: `lib/scoria_web/live/connectors_live/index.ex`, runtime and connector drawer components

Current facts:

- LiveView imports all `ScoriaWeb.UI`, but populated states are sparse card grids with raw classes.
- Runtime status dot uses color-only indicator alongside text, but the dot still carries raw palette.
- Detail components are inline `<section>`/`<aside>` blocks, not shared drawer shell.
- Existing data comes from `OperatorSurface.load_runtimes/1`, `OperatorSurface.connector_fleet/1`, and `OperatorSurface.connector_drawer/1`.

Planning implication:

- Convert runtime and connector scan surfaces to shared `<.table>` tables.
- Use text badges for runtime status, health state, refresh status, and auth provenance.
- Render selected runtime/connector through shared `<.drawer>` owned by the parent LiveView.
- Convert dense detail blocks to notebook/evidence sections.

### Evidence Components

Adapters already near target:

- `remote_invocation_evidence_component.ex`: uses `<.notebook>` and tokenized inline styles; still needs evidence primitives.
- `incident_evidence_component.ex`: uses `<.notebook>`, `<.badge>`, and tokenized inline styles; preserve as model.

Adapters requiring larger conversion:

- `citation_evidence_component.ex`: raw outer card, local side-by-side sections, local unsupported-claim warning.
- `delegated_evidence_component.ex`: local card grid, raw details blocks, raw capability tags.
- `memory_notebook_component.ex`: local notebook-like section, raw action chips/cards.
- `replay_evidence_notebook_component.ex`: local notebook-like section, custom toggle pills, custom raw evidence details.
- `semantic_evidence_notebook_component.ex`: local notebook-like section, custom cards and raw evidence pre.
- `workflow_detail_panel_component.ex`: raw panel, local replay/semantic evidence nesting, custom button styling.
- `trace_tree_component.ex`: raw gray/emerald token preview and expansion detail.
- `workflow_tree_component.ex`: mostly simple, already imports `badge`, but has raw `text-stone-600`.
- `runtime_detail_drawer_component.ex` and `connector_detail_drawer_component.ex`: local drawer-like sections; should become content rendered inside shared drawer shell.

Planning implication:

- Do shared primitives first, then convert adapter families in batches.
- Avoid making all adapters one plan if it creates a 3,000-line high-risk task. Split by dependency and verification surface.
- Favor source assertions that adapters import `ScoriaWeb.UI` and contain `<.notebook` plus new evidence primitives, and negative assertions for raw classes.

## Existing Test Surfaces

Likely targeted tests:

- `test/scoria_web/live/orchestrator_live_test.exs`
- `test/scoria_web/live/orchestrator_live_integration_test.exs`
- `test/scoria_web/live/orchestrator_live_sre_test.exs`
- `test/scoria_web/live/workflow_live_test.exs`
- `test/scoria_web/live/approvals_live_test.exs`
- `test/scoria_web/live/approvals_live_integration_test.exs`
- `test/scoria_web/live/connectors_live_test.exs`
- `test/scoria_web/components/runtime_detail_drawer_component_test.exs`
- `test/scoria_web/components/semantic_evidence_notebook_component_test.exs`
- `test/scoria_web/components/trace_tree_component_test.exs`
- `test/scoria_web/components/incident_evidence_component_test.exs`
- `test/scoria_web/ui_component_test.exs`
- `test/scoria_web/ds06_drift_guard_test.exs`

Testing posture:

- Use LiveViewTest-first verification.
- Use source assertions for no raw palette in touched files.
- Use focused behavior assertions for preserved events and route links.
- Browser screenshot/critique can be referenced as optional proof support, not merge-blocking.

## Implementation Hazards

1. Home action removal can break existing tests expecting `Load Retrieval Evidence` or `Replay Retrieval`. Update tests to assert the new deep-link contract and that old mutating labels are absent.
2. `<.table>` emits `phx-click="sort"` for keyed columns. If the parent LiveView lacks a `sort` handler, either omit `key` attrs or add minimal stable handlers. Do not render clickable inert controls.
3. `<.table>` renders density controls with `phx-click="set_density"`. Existing screens that use `<.table>` may already tolerate this; if tests click density controls, add parent handlers.
4. `<.notebook>` raises when multiple tabs exist without `on_tab_change`. Single-tab notebooks can omit the handler.
5. Shared `<.drawer>` currently handles Escape on the scrim element. Parent state still must be the source of truth. Tests should assert drawer close events.
6. Approval detail should not become modal-first. Keep irreversible approve/reject as the modal boundary.
7. Hard-coded `/scoria` links are not mount-prefix safe. Phase 15 should fix in touched files.
8. Raw inline `style=` can be acceptable when tokenized, but repeated tokenized styles across adapters indicate missing component primitives. Prefer shared CSS classes.
9. Removing DS-06 baseline rows must happen only after source scan reaches zero for that file.
10. Do not touch `assets/css/02-tokens.css` unless a real accessibility defect is found.

## Recommended Plan Slicing

### Plan 15-01: Evidence primitive layer

Files:

- `lib/scoria_web/ui.ex`
- `assets/css/04-components.css`
- `test/scoria_web/ui_component_test.exs`

Output:

- Shared evidence section, row/list, action-row, and empty-state primitives.
- Tests proving semantic markup, labels, and no raw palette classes.

### Plan 15-02: Home / Live Ops and Runs index

Files:

- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/live/workflow_live/index.ex`
- related Home/Workflow index tests
- `test/support/ds06_baseline.txt`

Output:

- Home stream is compact read-only status with deep links.
- Mutating evidence/replay/promote controls are absent from Home.
- Runs index uses `<.table id="runs">`.
- DS-06 baseline rows reduced or removed for touched files.

### Plan 15-03: Workflow Show trace inspector

Files:

- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/workflow_tree_component.ex`
- `lib/scoria_web/components/trace_tree_component.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `test/scoria_web/live/workflow_live_test.exs`
- `test/scoria_web/components/trace_tree_component_test.exs`
- `test/support/ds06_baseline.txt`

Output:

- Workflow Show uses shared page/panel/modal/evidence primitives.
- Two-pane trace area remains durable.
- Promote modal uses `<.modal>`.
- Runtime, incident, prompt, replay, and Dataset Builder links preserve origin/mount-prefix context.

### Plan 15-04: Approvals and Connectors

Files:

- `lib/scoria_web/live/approvals_live/index.ex`
- `lib/scoria_web/components/approval_inbox_component.ex`
- `lib/scoria_web/live/connectors_live/index.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/scoria_web/components/connector_detail_drawer_component.ex`
- related tests
- `test/support/ds06_baseline.txt`

Output:

- Approvals table -> drawer detail -> final decision modal.
- Connectors runtime and connector fleet tables -> shared drawers.
- Durable approval/rejection/resume semantics preserved.

### Plan 15-05: Evidence adapter conversion

Files:

- `lib/scoria_web/components/citation_evidence_component.ex`
- `lib/scoria_web/components/delegated_evidence_component.ex`
- `lib/scoria_web/components/memory_notebook_component.ex`
- `lib/scoria_web/components/replay_evidence_notebook_component.ex`
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex`
- `lib/scoria_web/components/remote_invocation_evidence_component.ex`
- `lib/scoria_web/components/incident_evidence_component.ex`
- related component tests
- `test/support/ds06_baseline.txt`

Output:

- All remaining evidence components are thin notebook adapters.
- Adapter code owns projection/copy/events only; `ui.ex` owns chrome, rows, empty states, raw evidence, and tone mapping.

## Validation Architecture

### Source Invariants

- No touched `lib/scoria_web/` file introduces raw palette class strings matching DS-06.
- Every touched baseline row in `test/support/ds06_baseline.txt` is removed or lowered only after a source scan proves the new count.
- New shared evidence primitives live in `lib/scoria_web/ui.ex` and classes live in `assets/css/04-components.css`.
- Home does not render `Load Deep Metadata`, `Load Retrieval Evidence`, `Load Budget State`, `Load Incident Evidence`, `Replay Retrieval`, or `Promote Retrieval`.
- Runs index contains `<.table id="runs"`.
- Workflow Show contains `<.object_header`, a trace area with `WorkflowTreeComponent.workflow_tree`, a selected-step detail component, and shared modal markup for promotion.
- Approvals render an approvals table, shared drawer detail, and shared modal confirmation.
- Connectors render runtime and connector tables plus shared drawer detail.
- Evidence adapter files contain `<.notebook` or are explicitly rendered inside a shared notebook section.

### Behavior Invariants

- Home still renders the attention strip and day-0 empty copy for no traces.
- Home stream cards provide mount-prefix-safe navigation to durable object pages.
- Runs index lists real `Scoria.Workflows.Run` records and opens `/workflows/:id`.
- Workflow Show still loads run tree/detail data, selects steps, switches replay comparison source, and promotes through Dataset Builder URLs.
- Approval approval path still records `approved`, resumes the workflow when possible, and shows pass-tone copy.
- Approval rejection path still records `rejected`, does not resume the workflow, and shows warning copy.
- Connectors still refresh on presence diffs and open runtime/connector details from real `OperatorSurface` data.
- Evidence adapters preserve existing evidence values, raw disclosures, and empty cases.

### Commands

Run focused tests per plan, then the shared guard:

```bash
mix test test/scoria_web/ui_component_test.exs
mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs
mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/trace_tree_component_test.exs
mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs
mix test test/scoria_web/live/connectors_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs
mix test test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/components/incident_evidence_component_test.exs
mix test test/scoria_web/ds06_drift_guard_test.exs
```

Optional visual support after all plans:

```bash
mix scoria.ui.shots
```

Use screenshot results as dev-only proof support, not as a merge-blocking gate.

## Package and Dependency Audit

No dependency changes are recommended. The required work is Phoenix LiveView markup, shared component additions, CSS classes under the existing token system, and tests.

## Research Complete

The phase is ready for plan creation.
