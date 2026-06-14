---
phase: 15
slug: high-traffic-screens-evidence-adapters
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-12
---

# Phase 15 - UI Design Contract: High-Traffic Screens + Evidence Adapters

> Visual and interaction contract for the Phase 15 screen-polish and evidence-adapter slice. This phase adopts the existing Scoria component layer; it does not redesign tokens, add backend capability, add routes, or introduce a third-party UI registry.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none - custom token-first scoped CSS, not shadcn |
| Preset | not applicable |
| Component library | `ScoriaWeb.UI` Phoenix LiveView function components |
| Component source | `lib/scoria_web/ui.ex`, `assets/css/04-components.css` |
| Icon library | Existing inline SVG/Heroicon-style 16px and 18px icons |
| Font - sans | IBM Plex Sans via `--scoria-font-sans` |
| Font - mono | JetBrains Mono via `--scoria-font-mono` |

shadcn gate: not applicable. This is a Phoenix LiveView project with an established repo-local component layer and no `components.json`.

Registry safety gate: no external registries, no shadcn blocks, no third-party UI packages.

Sources: `.planning/phases/15-high-traffic-screens-evidence-adapters/15-CONTEXT.md`, `.planning/phases/15-high-traffic-screens-evidence-adapters/15-RESEARCH.md`, approved Phase 12 and Phase 14 UI specs, `assets/css/02-tokens.css`, `brandbook/brand-book.md`.

---

## Spacing Scale

Declared values for Phase 15 screen templates:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, badge dots, tight inline pairs, compact trace metadata gaps |
| sm | 8px | Compact control spacing, button groups, table affordances, notebook row gaps |
| md | 16px | Default element gaps, panel body padding, drawer sections, evidence row padding |
| lg | 24px | Page header to content gap, trace area gutters, drawer body rhythm |
| xl | 32px | Major screen regions, two-pane trace layout gaps, dense dashboard grids |
| 2xl | 48px | Empty-state vertical rhythm and large section breaks |
| 3xl | 64px | Page-level spacing only when a layout genuinely needs breathing room |

Exceptions:
- Existing shared component CSS may internally resolve to `--scoria-space-3` = 12px for default table cells, form input inline padding, and nav item padding. Phase 15 implementers should use component classes and not hand-author new 12px layout utilities.
- Interactive controls in tables, drawers, modals, trace tree rows, and selected-step actions must preserve a 44px minimum hit target where practical.
- Workflow Show may use a sticky selected-step detail rail on desktop; sticky offsets must use existing app-shell spacing and must not create a nested app shell.
- No raw Tailwind spacing or palette cleanup should change `assets/css/02-tokens.css` for cosmetic preference.

---

## Typography

Contract: 4 type tiers, 2 weights. Use IBM Plex Sans for UI text and JetBrains Mono for trace IDs, run IDs, span labels, timestamps, token counts, code, and raw evidence.

| Role | Token | Size | Weight | Line Height | Usage |
|------|-------|------|--------|-------------|-------|
| Display / metric | `--scoria-fs-display` / `--scoria-fs-metric` | 30px | 600 | `--scoria-lh-tight` = 1.2 | Metric values and high-emphasis counts only |
| Page / panel heading | `--scoria-fs-panel` | 18px | 600 | `--scoria-lh-tight` = 1.2 | Screen sections, drawer titles, modal titles, notebook section headings |
| Body / table | `--scoria-fs-body` | 14px | 400 | `--scoria-lh-body` = 1.5 | Tables, descriptions, evidence rows, form help, empty state bodies |
| Label / meta | `--scoria-fs-label` | 12px | 400 or 600 | 1.45 | Column headers, field labels, badges, trace IDs, timestamps, key-value labels |

Locked implementation detail: `.scoria-badge` may use `--scoria-fs-badge` = 11px through existing CSS. Do not introduce 11px directly in new HEEx templates.

---

## Color

All Phase 15 surfaces bind to semantic Scoria tokens. Do not introduce raw palette classes under `lib/scoria_web/`.

| Role | Semantic Token | Light Value | Dark Value | Usage |
|------|----------------|-------------|------------|-------|
| Dominant (60%) | `--scoria-surface-app` | `#faf5ef` | `#11100f` | Dashboard app background |
| Secondary (30%) | `--scoria-surface-panel` | `#fff9f3` | `#181513` | Panels, table shells, nav/sidebar surfaces, notebook shells |
| Raised | `--scoria-surface-panel-raised` | `#ffffff` | `#211c19` | Drawers, modals, selected-step detail, dense evidence sections |
| Sunken | `--scoria-surface-sunken` | `#f1e8de` | `#0c0b0a` | Inputs, code blocks, raw evidence, compact trace payload previews |
| Accent (10%) | `--scoria-action` | `#b94f31` | `#e65a32` | Reserved list below |
| Destructive | `--scoria-danger-action` | `#9e2f20` | `#ff6b4a` | Reject/deny/destructive confirmation controls only |

Accent reserved for:
- Primary navigation/action CTAs: `Open trace`, `Promote in Dataset Builder`, `Replay run`, and the final positive confirmation in an approval modal.
- Active Operate nav item, active command-palette row, active table sort indicator, and selected density toggle.
- Notebook active tab underline.
- Focus rings via `--scoria-focus-ring`.
- Selected trace/span row border or badge, paired with `aria-current`, `aria-selected`, or visible `Selected` text.

Semantic tone usage:
- `:pass` for approved, healthy, active, completed, resumed.
- `:info` for running, queued, reference, in progress, runtime presence.
- `:warn` for pending, needs review, approval requested, degraded, paused.
- `:fail` for failed, rejected, denied, unhealthy, offline.
- `:trace` for replay, trace, candidate, promoted, comparison, workflow evidence.
- `:neutral` for unknown, default, archived, unselected.

Status is never color-only. Every badge, dot, chip, and span must carry visible text.

---

## Screen Visual Contracts

### Home / Live Ops

Focal point: a calm status-first triage surface with the existing attention strip and compact live trace stream. Home is not a workbench.

Required shape:
- Preserve `/` as Status Home with zero-click live feedback.
- Stream cards are compact read-only summaries: trace/run ID, current status, key badges, short span signal, timestamp, and next destination.
- Allowed actions are navigation/read actions only: `Open run`, `Open trace`, `Open incident`, `Review approval`.
- Replace inline god-page buttons with design-system deep links and compact status actions.
- Do not render full notebook panels, raw JSON, replay controls, promote controls, or evidence loading controls on Home.
- Empty state must make day-0 behavior clear: first chat response, agent run, eval sample, or MCP request appears as a trace.

### Runs Index

Focal point: the runs table is the scan surface.

Required shape:
- Page title: `Runs`.
- Subtitle: `Inspect recorded workflow runs and open the trace that explains them.`
- Use `<.table id="runs">` with compact density by default.
- Columns: Run, Status, Runtime, Started, Duration or Updated, Action.
- Row action: `Open trace`.
- Preserve real `Scoria.Workflows.Run` records, 50-row ordering, `short_id/1`, and `format_ts/1`.
- Do not add TraceQL, flame graph, service map, or analytics controls.

### Workflow Show / Trace Explorer

Focal point: a canonical APM-style trace inspector. Durable run/span tree first, selected-step detail second, evidence notebooks third.

Required shape:
- Use `<.object_header>` with breadcrumbs, run ID, status badge, and origin context.
- Next-step verbs are flat design-system buttons/links: `Replay run`, `Promote in Dataset Builder`, `Open incident`, `Open prompt`, `View associated runtime presence`.
- Main trace area is two-pane on desktop: tree or waterfall-like list on the left, selected-step detail on the right.
- On narrow viewports, selected-step detail collapses into a drawer or stacked section; do not create a custom nested app shell.
- Below the trace area, render timeline, replay provenance, semantic evidence, delegated evidence, memory evidence, remote invocation evidence, and raw details through notebook adapters.
- Promotion confirmation uses shared `<.modal>`, not custom overlay markup.
- All links must be mount-prefix-safe via existing base-path patterns.

### Approvals

Focal point: table scan first, drawer detail second, final decision modal only at the irreversible boundary.

Required shape:
- Use `<.table id="approvals">` as the primary scan surface.
- Columns: Approval, Workflow, Requested by or Actor, Consequence, Requested, Status, Action.
- Row action: `Inspect approval`.
- Detail opens in shared `<.drawer>` owned by parent LiveView selected state.
- Final approve/reject decision uses shared `<.modal>`.
- Approval copy states that approval resumes the workflow when possible.
- Rejection copy states that rejection records a durable rejection and keeps the workflow paused.
- Approval and rejection must not share the same pass/green treatment.

### Connectors

Focal point: dense operational scan tables, not sparse card grids.

Required shape:
- Render runtime presence and connector fleet posture as shared tables or table-like shared panels.
- Runtime table columns: Runtime, Status, Active runs, Queue or Presence, Last seen, Action.
- Connector table columns: Connector, Health, Auth or Provenance, Refresh state, Last checked, Action.
- Detail opens in shared `<.drawer>` owned by parent LiveView selected state.
- Drawer content uses notebook/evidence sections when dense.
- Status dots are decorative only; text labels are mandatory.
- Do not add connector setup wizards, connector detail routes, MCP Gateway behavior, Tool Registry behavior, or lifecycle controls.

---

## Evidence Adapter Contract

Thin adapter definition: adapter owns domain data projection, exact copy, links, and LiveView events. `ScoriaWeb.UI` owns chrome, section framing, key-value rows, raw evidence disclosure, empty states, tone mapping, accessibility semantics, and light/dark styling.

Required shared primitives for Phase 15:
- `evidence_section/1` for notebook-internal titled sections with optional description, badge, and actions.
- `evidence_rows/1` or equivalent key-value rows for stable maps/DTOs.
- `evidence_action_row/1` for compact notebook actions and links.
- `evidence_empty/1` for notebook-scoped empty states.
- Prefer extending `<.raw_evidence>` before adding a separate code/raw block primitive.

Adapter prohibitions:
- No bespoke raised card chrome.
- No ad-hoc grid/list shell styling.
- No raw palette classes.
- No one-off raw JSON `<details>` blocks outside shared raw evidence.
- No custom badge styling.
- No duplicated empty-state wrappers.
- No typed evidence descriptor renderer, plugin registry, adapter behaviour, or UI schema language.

In-scope adapter surfaces:
- `citation_evidence_component.ex`
- `delegated_evidence_component.ex`
- `memory_notebook_component.ex`
- `replay_evidence_notebook_component.ex`
- `semantic_evidence_notebook_component.ex`
- `remote_invocation_evidence_component.ex`
- `incident_evidence_component.ex`
- `workflow_detail_panel_component.ex`
- `trace_tree_component.ex`
- `workflow_tree_component.ex`
- `runtime_detail_drawer_component.ex`
- `connector_detail_drawer_component.ex`
- `approval_inbox_component.ex`

---

## Interaction Contracts

Home action grammar:
- Use `Open run`, `Open trace`, `Review approval`, `Open incident`.
- Do not use `Load Deep Metadata`, `Load Retrieval Evidence`, `Load Budget State`, `Load Incident Evidence`, `Replay Retrieval`, or `Promote Retrieval` on Home.

Workflow Show next-step grammar:
- Use `Replay run`, `Promote in Dataset Builder`, `Open incident`, `Open prompt`, `View associated runtime presence`.
- Preserve origin context where useful with existing `from=` patterns.
- Dataset promotion remains owned by Dataset Builder URLs established in Phase 14.

Approvals decision grammar:
- Drawer action labels: `Approve workflow`, `Reject approval`, `Close drawer`.
- Modal confirm labels: `Approve workflow`, `Reject approval`.
- Alternate modal action: `Keep reviewing`.
- Approve path records approval and resumes when possible.
- Reject path records rejection and does not resume the workflow.

Connectors interaction grammar:
- Use `Inspect runtime`, `Inspect connector`, `Close drawer`.
- `Refresh` may appear only where existing data/event flow already supports it.
- Drawer close must restore list context.

Overlay behavior:
- Drawers and modals keep existing close button, scrim click, and Escape dismissal behavior.
- Parent LiveViews own selected/open state.
- Modal is reserved for final approve/reject confirmation or similarly safety-relevant decisions.

---

## Copywriting Contract

Voice: calm, exact, useful. Prefer evidence verbs: traced, replayed, promoted, compared, gated, approved, rejected, paused, resumed, refreshed, inspected. Avoid hype, magic, hidden chain-of-thought language, and color-only status.

| Element | Copy |
|---------|------|
| Primary CTA | `Open trace` |
| Home empty heading | `No traces yet` |
| Home empty body | `The first chat response, agent run, eval sample, or MCP request will appear here as a trace.` |
| Home trace actions | `Open run`; `Open trace`; `Review approval`; `Open incident` |
| Runs subtitle | `Inspect recorded workflow runs and open the trace that explains them.` |
| Runs empty heading | `No runs recorded yet` |
| Runs empty body | `Workflow runs appear here after Scoria records the first trace.` |
| Workflow Show error | `Run could not be loaded. Check the run ID or return to Runs and open the trace again.` |
| Workflow Show empty trace | `No spans recorded for this run` |
| Workflow Show empty trace body | `The run exists, but no trace spans were recorded for inspection.` |
| Approvals empty heading | `No approvals waiting` |
| Approvals empty body | `Tool calls and workflow steps that require operator approval will appear here.` |
| Approval drawer primary | `Approve workflow` |
| Approval drawer secondary | `Reject approval` |
| Connector empty heading | `No connector activity yet` |
| Connector empty body | `Connector runtimes and fleet health appear after the host app reports presence.` |
| Generic loading label | `Loading...` |
| Generic recoverable error | `The requested record could not be loaded. Check the ID or return to the previous screen and try again.` |

Destructive / safety confirmations:
- `Reject approval`: heading `Reject this approval?`; body `The workflow stays paused and the rejection is recorded for the run.`; confirm button `Reject approval`; alternate action `Keep reviewing`.
- `Approve workflow`: heading `Approve this workflow step?`; body `Scoria records the approval and resumes the workflow when the run can continue.`; confirm button `Approve workflow`; alternate action `Keep reviewing`.

Prohibited copy:
- Generic CTAs such as `Submit`, `OK`, `Cancel`, `Click here`.
- Vague errors such as `Something went wrong`, `No data found`, `Nothing here`.
- Hype language, model anthropomorphism, hidden chain-of-thought language, and fake confidence.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable - shadcn is not initialized |
| third-party registries | none | not applicable - no external registry declared |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
