# Phase 15 Pattern Map: High-Traffic Screens + Evidence Adapters

**Mapped:** 2026-06-12
**Source:** Inline pattern mapping from Phase 15 CONTEXT.md, RESEARCH.md, UI-SPEC.md, VALIDATION.md, and current code.

## Purpose

Phase 15 should be implemented by adopting existing Scoria design-system patterns, not by inventing new product capabilities. The closest local analogs are the Phase 12 `ScoriaWeb.UI` components and the Phase 14 screen conversions that preserved existing LiveView event names while replacing local chrome.

## Shared Component Patterns

### Component Gateway

Source file: `lib/scoria_web/ui.ex`

Existing primitives available to all Phase 15 screens:

- `badge/1` with `tone/1` and `status_label/1`
- `button/1`
- `panel/1`
- `object_header/1`
- `empty_state/1`
- `modal/1`
- `drawer/1`
- `field/1`
- `form_section/1`
- `skeleton/1`
- `toast/1`
- `notebook/1`
- `raw_evidence/1`
- `table/1`

Important constraints:

- `notebook/1` raises if more than one tab is rendered without `on_tab_change`.
- `table/1` renders density buttons with `phx-click="set_density"` and sortable headers for columns with `key`. Parent LiveViews must either own the handler or avoid making unhandled controls visible.
- `button/1` currently includes a finite `rest` allowlist. If Phase 15 converts event buttons that need `phx-value-step-id`, `phx-value-source`, or `phx-value-density`, update the allowlist deliberately or keep semantic `<button class="scoria-button ...">` markup for that event.

### CSS Gateway

Source file: `assets/css/04-components.css`

Existing class families cover panels, badges, tables, drawers, modals, empty states, span rows, page headers, forms, notebooks, raw evidence, flash, skeletons, toasts, object headers, command palette, and IA primitives. Phase 15 evidence primitives should extend this file with token-bound classes only, using names under:

- `.scoria-evidence-section*`
- `.scoria-evidence-rows*`
- `.scoria-evidence-action-row*`
- `.scoria-evidence-empty*`

Do not edit `assets/css/02-tokens.css` unless a real accessibility defect is found.

## Existing Plan Analog

Phase 14 plans demonstrate the expected executor contract:

- frontmatter with `phase`, `plan`, `type`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`
- `must_haves.truths`, `must_haves.artifacts`, and `must_haves.key_links`
- XML task blocks with `read_first`, concrete `action`, `acceptance_criteria`, and `verify`
- STRIDE threat model
- focused LiveViewTest/component verification plus DS-06 checks

Use Phase 14's pattern of preserving backed LiveView event names while replacing presentation shells.

## High-Traffic Screen Patterns

### Home / Live Ops

Source file: `lib/scoria_web/live/orchestrator_live.ex`

Current shape:

- imports only `attention_card`, `badge`, and `flash_group`
- preserves Status Home attention strip and live trace stream
- renders trace rows through `TraceTreeComponent`
- still exposes mutating/provenance-heavy stream controls:
  - `Load Deep Metadata`
  - `Load Retrieval Evidence`
  - `Load Budget State`
  - `Load Incident Evidence`
  - `Replay Retrieval`
  - `Promote Retrieval`
- renders evidence panels inline after lazy events

Target pattern:

- keep `/` as a status-first triage surface
- keep PubSub trace stream, token preview, attention cards, and day-0 empty state
- replace stream buttons with mount-prefix-safe links: `Open run`, `Open trace`, `Review approval`, `Open incident`
- remove Home rendering paths for lazy evidence/replay/promote controls when tests have been updated
- use existing `assigns[:scoria_base] || ""` base path pattern

Tests to update:

- `test/scoria_web/live/orchestrator_live_test.exs`
- `test/scoria_web/live/orchestrator_live_integration_test.exs`
- `test/scoria_web/live/orchestrator_live_sre_test.exs`

Known existing assertions still expect `load_retrieval_evidence`, `load_budget_state`, `load_incident_evidence`, `Replay Retrieval`, and `Promote Retrieval`; these should be rewritten to assert the new read-only link contract.

### Runs Index

Source file: `lib/scoria_web/live/workflow_live/index.ex`

Current shape:

- imports all `ScoriaWeb.UI`
- already uses `panel/1`, `empty_state/1`, `id/1`, and `badge/1`
- still renders a raw `<table class="scoria-table">`
- subtitle and cells use raw `text-stone-*` classes

Target pattern:

- `page_title` stays `Runs`
- subtitle becomes `Inspect recorded workflow runs and open the trace that explains them.`
- use `<.table id="runs" rows={@runs} density={:compact}>`
- columns: Run, Status, Runtime, Started or Updated, Action
- row action remains `Open trace`
- preserve `list_runs/0`, 50-row ordering, `short_id/1`, and `format_ts/1`

## Workflow Show Patterns

Source file: `lib/scoria_web/live/workflow_live/show.ex`

Current shape:

- imports only `object_header` and `skeleton`
- already has object header, next-step verbs, origin context, Dataset Builder promotion URL, prompt/incident links, and remote invocation evidence
- uses a local page shell with `bg-stone-*`
- trace inspector is close to target: `WorkflowTreeComponent.workflow_tree` plus `WorkflowDetailPanelComponent.workflow_detail_panel`
- custom promote modal markup exists instead of shared `<.modal>`
- runtime link is hard-coded as `/scoria?runtime=...`

Target pattern:

- import the needed `ScoriaWeb.UI` components instead of hand-authoring local chrome
- keep run loading, selected step, comparison source, promotion URL, and event behavior stable
- render app-layout-native `scoria-dashboard` shell
- keep next-step verbs: `Replay run`, `Promote in Dataset Builder`, `Open incident`, `Open prompt`, `View associated runtime presence`
- make runtime presence link mount-prefix-safe via `(assigns[:scoria_base] || "") <> "?runtime=..."`
- convert promotion confirmation to shared `<.modal>`
- route replay provenance, promotion notices, review candidate evidence, timeline, and selected-step evidence through panels/notebooks/evidence primitives

Tests to update:

- `test/scoria_web/live/workflow_live_test.exs`
- `test/scoria_web/components/trace_tree_component_test.exs`

## Approval and Connector Patterns

### Approvals

Sources:

- `lib/scoria_web/live/approvals_live/index.ex`
- `lib/scoria_web/components/approval_inbox_component.ex`

Current shape:

- LiveView imports only `flash_group` and `toast`
- inbox component uses local card/list markup
- active approval is modal-first custom overlay
- approval event semantics are already correct:
  - approval calls `Workflows.approve/3`
  - approval resumes via `Resume.resume_run/1` when possible
  - rejection records durable rejection and keeps workflow paused
  - toast tone distinction is already fixed

Target pattern:

- primary inbox is shared `<.table id="approvals">`
- row action is `Inspect approval`
- parent LiveView owns selected drawer state and confirmation modal state
- detail opens in shared `<.drawer>`
- final approve/reject confirmation uses shared `<.modal>`
- copy must use `Approve workflow`, `Reject approval`, and `Keep reviewing`
- keep event names or provide compatibility wrappers so existing tests and PubSub behavior remain stable

Tests to update:

- `test/scoria_web/live/approvals_live_test.exs`
- `test/scoria_web/live/approvals_live_integration_test.exs`

### Connectors

Sources:

- `lib/scoria_web/live/connectors_live/index.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/scoria_web/components/connector_detail_drawer_component.ex`

Current shape:

- LiveView imports all `ScoriaWeb.UI`
- populated states are sparse local card grids
- runtime status dot still uses raw color classes
- detail components render local section/aside blocks, not the shared drawer shell

Target pattern:

- runtime presence and connector fleet are shared tables
- row actions: `Inspect runtime`, `Inspect connector`
- parent LiveView renders shared `<.drawer>` shells and passes selected detail content into them
- detail content uses notebook/evidence primitives when dense
- preserve `OperatorSurface.load_runtimes/1`, `OperatorSurface.connector_fleet/1`, `OperatorSurface.connector_drawer/1`, presence diff refresh, and close events

Tests to update:

- `test/scoria_web/live/connectors_live_test.exs`
- `test/scoria_web/components/runtime_detail_drawer_component_test.exs`

## Evidence Adapter Patterns

Already near target:

- `lib/scoria_web/components/remote_invocation_evidence_component.ex`
- `lib/scoria_web/components/incident_evidence_component.ex`

These prove that notebook wrappers work, but both still use local tokenized panels/styles that Phase 15 primitives can simplify.

Adapters needing larger conversion:

- `lib/scoria_web/components/citation_evidence_component.ex`
- `lib/scoria_web/components/delegated_evidence_component.ex`
- `lib/scoria_web/components/memory_notebook_component.ex`
- `lib/scoria_web/components/replay_evidence_notebook_component.ex`
- `lib/scoria_web/components/semantic_evidence_notebook_component.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `lib/scoria_web/components/trace_tree_component.ex`
- `lib/scoria_web/components/workflow_tree_component.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/scoria_web/components/connector_detail_drawer_component.ex`
- `lib/scoria_web/components/approval_inbox_component.ex`

Target adapter contract:

- adapter imports `ScoriaWeb.UI`
- adapter renders one notebook or content intended for a parent shared drawer/notebook
- adapter owns data projection, copy, links, and event wiring only
- `ui.ex` owns section chrome, row/key-value chrome, action rows, raw disclosure, empty state, tone mapping, and accessibility semantics

## DS-06 Baseline Rows in Scope

Current in-scope baseline rows:

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
- `lib/scoria_web/live/approvals_live/index.ex:9`
- `lib/scoria_web/live/connectors_live/index.ex:20`
- `lib/scoria_web/live/orchestrator_live.ex:26`
- `lib/scoria_web/live/workflow_live/index.ex:4`
- `lib/scoria_web/live/workflow_live/show.ex:50`

Implementation rule:

- Every plan touching one of these files must reduce raw-palette leakage.
- Remove the baseline row only after the source scan reaches zero for that file.
- Do not add new raw palette classes under `lib/scoria_web/`.

## Verification Patterns

Primary verification is ExUnit + LiveViewTest:

- `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_integration_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/trace_tree_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- `mix test test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs test/scoria_web/live/connectors_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`
- `mix test test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/components/incident_evidence_component_test.exs test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs`

Optional visual proof after implementation:

- `mix scoria.ui.shots`

