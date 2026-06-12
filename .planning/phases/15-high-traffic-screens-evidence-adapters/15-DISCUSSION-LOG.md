# Phase 15: High-traffic screens + evidence adapters - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 15-high-traffic-screens-evidence-adapters
**Areas discussed:** Home trace stream action model, Runs and Workflow Show shape, Approvals and Connectors detail patterns, Evidence adapter consolidation contract
**Mode:** Advisor-mode discussion with explicit subagent-backed research requested by the user

---

## Home Trace Stream Action Model

| Option | Description | Selected |
|--------|-------------|----------|
| Home = triage stream + design-system deep links; Runs/Workflow Show = evidence and mutating actions | Home stays calm and status-first; replay, promotion, and raw evidence move to durable object pages. | yes |
| Home = triage stream with read-only evidence previews; actions deep-link to object pages | Keeps quick diagnostic context but risks duplicating notebook layouts and stream state. | partial |
| Home = full live control room with inline replay/evidence/promote drawers | Fast for experts but recreates the god-page footgun and puts mutating actions on an ephemeral stream. | no |
| Home = status only; move live stream entirely to Runs index | Clean IA but violates the Phase 13 zero-click live feedback decision. | no |

**User's choice:** Approved the recommendation set with reply `1`.

**Notes:** Research recommendation: keep Home as a narrow read-only triage stream with compact summaries and deep links. Mature tools separate scan from investigation; Scoria should keep operator calm and move evidence-heavy or mutating actions to Runs / Workflow Show and Dataset Builder.

---

## Runs and Workflow Show Shape

| Option | Description | Selected |
|--------|-------------|----------|
| APM-style trace inspector | Run index -> object header -> trace tree/waterfall-like list + sticky selected-step detail + evidence notebook stack. | yes |
| IDE-style tri-pane | Run list/sidebar, trace tree center, detail/evidence rail; fast but cramped in embedded dashboard layout. | no |
| Notebook-first run page | Tabs for Overview/Trace/Timeline/Evidence/Raw; accessible but hides the primary trace signal. | no |
| Query/explorer-first APM table | Mature high-volume search model but risks new backend/query scope. | defer |
| Session/conversation-first replay | Strong for chat flows but not the correct primary noun for Phase 15. | defer |

**User's choice:** Approved the recommendation set with reply `1`.

**Notes:** Research recommendation: make Workflow Show Scoria's canonical trace explorer without adding query languages, flame/map modes, or session replay. Use existing run/detail/timeline/evidence data through `ui.ex` components.

---

## Approvals and Connectors Detail Patterns

| Option | Description | Selected |
|--------|-------------|----------|
| Shared tables + contextual right drawer; modal only for final approve/reject | Dense scan surface, contextual inspection, explicit safety boundary for irreversible decisions. | yes |
| Inline master-detail rail beside table | Fast for repeated triage but weaker on mobile and easy to crowd. | possible implementation detail |
| Modal-first detail and decision flow | Strong interruption boundary but poor for routine inspection and current modal has design debt. | no |
| Separate detail pages per approval/connector | Deep-linkable future direction but adds routes and product scope. | defer |
| Current card grids with expandable inline sections | Lowest change but fails density and shared-component goals. | no |

**User's choice:** Approved the recommendation set with reply `1`.

**Notes:** Research recommendation: tables for scan, drawers for detail, modal only for final decision. Parent LiveViews own selected state. Keep behavior LiveViewTest-visible and mount-prefix safe.

---

## Evidence Adapter Consolidation Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Shell-only `<.notebook>` adapters | Smallest change but leaves duplicated layout logic. | no |
| Notebook shell + shared evidence primitives | Adapters own projection/copy/links; `ui.ex` owns chrome/rows/raw evidence/tone/empty/a11y/theme. | yes |
| Typed evidence descriptor renderer | Reduces markup but creates a mini UI schema language too early. | defer |
| Bespoke per-domain components with token cleanup | Fast polish but fails SCREEN-04 architecture goal. | no |
| Full plugin/registry adapter contract | Extension story but out of UI-only Phase 15 scope. | defer |

**User's choice:** Approved the recommendation set with reply `1`.

**Notes:** Research recommendation: add narrowly scoped `ui.ex` evidence primitives only where repeated layout exists. Convert remaining adapters so they are thin domain projections over shared notebook/presentation primitives.

---

## Agent's Discretion

- Exact `ui.ex` primitive API names and slot shapes.
- Exact table columns and filter controls, constrained to current data.
- Exact selected-step layout on Workflow Show across desktop/mobile.
- Exact drawer section ordering for Approvals and Connectors.
- Exact plan slicing and adapter conversion order.

## Deferred Ideas

- Inline Home replay/promote drawers, bulk stream actions, and row keyboard triage.
- Full TraceQL-style search, flame graph/map modes, service maps, session-first replay, and conversation browser.
- Separate approval/connector detail pages and richer connector setup or lifecycle flows.
- Typed evidence descriptor renderer, evidence plugin registry, adapter behaviour, or UI schema language.
- Phase 16 motion/responsive/theme parity and Phase 17 final proof/docs.
