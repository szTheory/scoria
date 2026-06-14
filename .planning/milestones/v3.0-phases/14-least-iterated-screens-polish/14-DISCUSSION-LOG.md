# Phase 14: Least-iterated screens polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 14-least-iterated-screens-polish
**Areas discussed:** Dataset Builder as canonical promotion destination, Review Queue conversion model, Eval Workbench + Prompt Registry / Release Workbench structure, Incidents evidence boundary
**Mode:** Text-mode advisor discussion with 4 parallel subagent research threads. User selected all areas and approved the synthesized recommendation set.

---

## Dataset Builder as Canonical Promotion Destination

| Option | Description | Selected |
|--------|-------------|----------|
| Dataset Builder index owns promotion via route/query context | Add real `/datasets` index and deep-link promotion from source screens using stable IDs. | |
| Keep inline promote modal/component, restyled/reused | Smallest behavior change, but Dataset Builder remains absent or secondary. | |
| Dataset Builder index plus nested promotion drawer/modal | Real canonical page, promotion task opens in Dataset Builder from URL context, existing backend reused. | yes |
| Dedicated object-style promotion route | Clear task route such as `/datasets/promotions/new`, but creates a new product noun. | |

**User's choice:** Approved synthesized recommendation.

**Notes:** Research found that Braintrust, Langfuse, Arize Phoenix, and LangSmith all make datasets first-class and treat trace-to-dataset promotion as durable curation, not incidental modal UI. The selected Scoria shape is a real Dataset Builder index at `/datasets`, added to Improve with command-palette/nav support, plus a drawer/modal promotion surface driven by URL context. Source screens should navigate there instead of duplicating dataset selectors. Promotion context uses stable IDs only; raw snapshots stay server-side and are reconstructed from existing records.

---

## Review Queue Conversion Model

| Option | Description | Selected |
|--------|-------------|----------|
| DS table + selected detail rail/drawer | Convert current master-detail LiveView to shared table/filter/metric/detail components. | yes |
| Compact review feed + detail rail | Narrative cards similar to issue streams, but weaker DS table adoption. | |
| Table index + separate candidate detail route | Strong route semantics, but heavier IA and slower triage. | |
| Lane board by review state/severity | Kanban-style lanes, but invents workflow semantics not backed by current data model. | |

**User's choice:** Approved synthesized recommendation.

**Notes:** The research recommendation kept the single LiveView because existing event boundaries are clean and the operator job is fast triage. The final synthesis resolves a conflict with Dataset Builder: Review Queue keeps scan/filter/select/dismiss and evidence pivots, but dataset selection and promotion move to Dataset Builder. That makes Review Queue an ingress surface and Dataset Builder the canonical curation surface.

---

## Eval Workbench + Prompt Registry / Release Workbench Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Separate registries linked by quality-loop verbs | Eval Workbench, Prompt Registry, and Release Workbench stay separate but visibly connected. | yes |
| Single Improve Workbench shell with tabs | Consolidates surfaces but conflicts with current IA and deep-linkable tasks. | |
| Release-centered gate queue | Makes releases prominent but distorts Eval Workbench around prompt releases only. | |
| Experiment playground clone | Familiar from prompt/eval tools, but implies net-new backed experiment controls. | |

**User's choice:** Approved synthesized recommendation.

**Notes:** The selected shape keeps nouns honest and route-addressable. Eval Workbench answers what was evaluated and what regressed. Prompt Registry answers which versions exist and what can be released. Release Workbench remains an object page with `object_header`, flat next-step verbs, draft-vs-active comparison panels, shared modals, semantic badges, and no steppers/fake experiment controls.

---

## Incidents Evidence Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Shell-only Incidents polish; defer `IncidentEvidenceComponent` | Strictly preserves Phase 15 boundary, but Incidents remains visibly unfinished and raw-palette-heavy. | |
| Narrow exception: convert only `IncidentEvidenceComponent` outer/layout shell now | Makes Incidents coherent end-to-end while preserving broad Phase 15 evidence-adapter scope. | yes |
| Pull full evidence-adapter conversion into Phase 14 | Maximizes consistency but violates Phase 15 scope and expands blast radius. | |

**User's choice:** Approved synthesized recommendation.

**Notes:** The selected boundary is a single named exception. `IncidentEvidenceComponent` is first-order Incidents screen content and carries significant DS-06 debt, so leaving it untouched would make SCREEN-01 dishonest. Convert only that evidence component to a thin notebook/panel adapter. Do not pull forward the other evidence components from Phase 15.

---

## External Lessons Considered

- Braintrust / Langfuse / Arize Phoenix / LangSmith: production traces become datasets; datasets power evals/experiments; eval evidence gates prompt/model changes.
- Sentry: issue/review queues work when filter/status triage leads to rich detail evidence.
- Oban Web / Phoenix LiveDashboard: embedded operator tools should be dense, route-addressable, action-aware, and close to runtime truth.
- Datadog / New Relic incident views: incident evidence is part of the incident trust surface, not optional decoration.
- Aludel / Tribunal: prompt/eval surfaces can be Phoenix-native and ExUnit/eval-mode friendly, but Scoria should present persisted Scoria evidence rather than clone playground controls in this UI-only phase.

## Agent's Discretion

- Exact component APIs, plan slicing, CSS helper class names, and test file organization.
- Whether Dataset Builder promotion renders as a drawer or modal.
- Whether Review Queue mobile detail uses a drawer immediately or a responsive panel first.
- Exact route-param names, as long as query params carry stable IDs and not raw snapshots.

## Deferred Ideas

- Broad evidence-adapter conversion across 13 evidence components - Phase 15.
- High-traffic screen polish - Phase 15.
- Motion/responsive/theme parity - Phase 16.
- Final proof/docs/contact sheets - Phase 17.
- Full experiment playground, prompt/model variant runner, dataset import/schema builder, annotation scoring, reviewer assignment, bulk queue actions, and lane/kanban workflow - future backend-backed capabilities.
