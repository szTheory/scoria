---
phase: 09
slug: restore-audited-approval-and-incident-delivery-wiring
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-12
---

# Phase 9 — UI Design Contract

> Visual and interaction contract for the audited approval and incident-delivery seam repair in the existing trace-first LiveView notebook.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | none |
| Icon library | none |
| Font | system sans (`font-sans` host stack) |

### Surface Contract

- Keep the existing Phoenix LiveView + Tailwind surface and improve truthfulness, not breadth.
- The main screen remains the trace list. Approval, audit, incident, and delivery evidence are revealed only after operator intent.
- The approval path stays modal and task-focused; the incident path stays notebook-style and evidence-first.

## Visual Hierarchy

| Screen Area | Role | Visual Priority |
|-------------|------|-----------------|
| Trace card + badge row | Primary focal point | First thing scanned; each trace card is the operator's entry point |
| Incident evidence notebook | Secondary focal point | Loaded on demand; becomes the dominant reading surface once opened |
| Approval modal CTA row | Immediate action focus | Approve and reject buttons are the only saturated controls in the modal |
| Composite health rollup | Compact summary | Fast orientation only; never replaces the evidence notebook |

### Interaction Rules

- Do not auto-load metadata, retrieval, budget, or incident evidence on mount.
- Keep action links as lightweight text actions until an operator explicitly requests deeper evidence.
- Use badges to show state at a glance; use notebook cards to explain why the state exists.
- Any approval, audit, incident, or delivery fact shown in the notebook must deep-link or label back to the same trace, run, or approval lineage.
- Icon-only actions are not allowed in this phase. Every action remains text-labeled.

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline badge separation when text already provides grouping |
| sm | 8px | Button inner gaps, trace action clustering |
| md | 16px | Default card padding and vertical rhythm inside notebook sections |
| lg | 24px | Gaps between notebook subsections and modal body blocks |
| xl | 32px | Separation between major dashboard regions |
| 2xl | 48px | Approval modal breathing room and page section breaks |
| 3xl | 64px | Top-level page spacing on wide layouts only |

Exceptions: none

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14px | 400 | 1.5 |
| Label | 12px | 600 | 1.4 |
| Heading | 18px | 600 | 1.3 |
| Display | 30px | 600 | 1.15 |

### Type Rules

- Use uppercase tracked labels only for category markers, status chips, and notebook micro-headings.
- Use monospace only for trace IDs, run IDs, approval IDs, routing keys, and incident keys.
- Do not introduce a fifth size for this phase.

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F8FAFC` | App background, notebook canvas, modal scrim contrast support |
| Secondary (30%) | `#FFFFFF` | Trace cards, notebook panels, modal surface |
| Accent (10%) | `#2563EB` | Primary trace deep-link actions, active approval CTA, trace/run/approval lineage links |
| Destructive | `#BE123C` | Reject action, failed delivery state, page-critical and breaker-open emphasis |

Accent reserved for: `Approve Decision`, `Load Incident Evidence`, `Load Deep Metadata`, trace/run/approval deep-links, and the currently selected operator action only. Accent must not be used for every button or every status chip.

### Semantic State Colors

- Review / inspect states: `#0369A1` on pale sky background.
- Warning / pending states: `#B45309` on pale amber background.
- Success / delivered / healthy states: `#047857` on pale emerald background.
- Critical / rejected / failed / breaker-open states: destructive palette only.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Approve Decision |
| Empty state heading | No Incident Evidence Loaded |
| Empty state body | Select `Load Incident Evidence` on a trace to inspect approval, audit, incident, and delivery lineage for that run. |
| Error state | Incident evidence could not be loaded. Refresh the trace and retry; if the failure persists, inspect relay and audit rows for the same trace. |
| Destructive confirmation | Reject Decision: Reject this approval and keep the workflow paused until a new operator action is recorded. |

### Copy Rules

- Replace generic `Approve` and `Reject` button labels with `Approve Decision` and `Reject Decision`.
- Modal heading stays `Approval Required`, but the body must name the tool and explain that the decision will be durably audited.
- Evidence-loading actions use verb + noun labels: `Load Incident Evidence`, `Load Budget State`, `Load Retrieval Evidence`, `Load Deep Metadata`.
- Review incidents should be described as operator review work, not pager events.
- Unconfigured or noop delivery outcomes must be explicit in notebook copy; they are evidence states, not silent failures.

## Component and Layout Contract

| Area | Contract |
|------|----------|
| Trace cards | White card on dominant background with shadow-light separation; action row stays text-first and low chrome |
| Badge row | Compact uppercase chips directly below the trace tree; severity and routing colors must stay semantically consistent |
| Approval modal | Single-column white modal, max width `md`, with destructive action visually subordinate to the approval CTA except when the current decision is rejection |
| Incident notebook | Rounded notebook shell with compact five-card health rollup, followed by evidence cards in a two-column desktop layout and one-column mobile stack |
| Delivery outcomes | Each delivery row must show sink kind, delivery status, routing key, and attempts in one compact card without hidden hover-only details |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-12
