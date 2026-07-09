---
id: SEED-013
status: deferred
planted: 2026-07-03
deferred_on: 2026-07-09
planted_during: v3.3 Design System Stress Test (phase 40 in-flight)
trigger_when: next milestone scoped as dashboard IA / operator UX / content-hierarchy pivot / control-room redesign — sequence AFTER SEED-006 (P0) and ideally alongside/after SEED-005 (positioning vocab)
scope: large
priority: high
depends_on: []
composes_with: [SEED-005, SEED-007, SEED-008, SEED-010, SEED-011, SEED-012]
enriched: 2026-07-03 (from the operator-UI storyboard deep-research ingest + a red-team synthesis pass)
---

# SEED-013: Operator IA Pivot (Control-Room v2)

## Why This Matters

A first-principles operator-UI storyboard (`.planning/research/operator-ui-north-star.md`, distilled from
`prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md`) reframes the dashboard from
"LLM observability grouped by Scoria module" to **an AI control room for one engineer, organized around
operator moments** (Orient → Act → Investigate → Recover → Improve → Govern → Audit). The v3.0 Control
Room IA spine (three-group nav, Status Home, ⌘K, breadcrumbs) was sound and ~40% of the storyboard's best
ideas already ship — so this is a **coherence pivot, not a rebuild.** The residue worth its own milestone
is the **structural** layer that is buildable on **today's** backend and makes the whole surface cohere:

- **Nav re-group** (Home · Queue · Features · Runs · Quality · Govern · [Data & Privacy] · [Audit]) —
  lifting the two new organizing objects (a unified **Queue** and the **AI Feature**) out of the current
  Operate/Improve/Configure grouping and elevating **Govern** so the differentiator isn't buried.
- **Unified Queue** — one ranked human-work inbox so the n=1 operator stops polling separate Approvals,
  Incidents, and Review Queue pages.
- **Persistent scope contract** (Tenant / Feature / Time / Live) that follows the operator and renders
  cross-tenant / non-prod **loudly** — a UI-layer hardening of the [[SEED-006]] cross-tenant class.
- **3-pane Run Workbench** (story-spine / evidence-canvas / inspector) as the forensic center of gravity.
- **Progressive-disclosure law** (`Summary | Details | Raw JSON`) + **receipts** on every consequential
  action + **"create policy rule from this."**
- **Feature Cockpit shell** — a per-feature homepage keyed on a **host-declared** feature attribute.
- **"Story spine with vesicles"** trace visualization — the volcanic brand fused to the trace data-viz.

This is the **structural shell**. The feature-specific *screens* it frames (Govern/blast-radius,
Data & Privacy, Feature Cockpit tab content, Quality depth, Retrieval Explorer) ride their own backend
seeds and only get built when that backend exists — see the slice map in the North-Star doc.

## When to Surface

**Trigger:** a dashboard-IA / operator-UX / content-hierarchy pivot milestone. **Sequence after
[[SEED-006]]** (P0 security gates the next release) and **ideally alongside/after [[SEED-005]]** (the
"AI Feature" vocabulary + operator-moments framing + plain-language copy standards should land in docs and
UI together). The **shell is independent of the feature seeds** (`depends_on: []`) and buildable on the
current backend; but it *composes with* 007/008/010/011/012 as those land, so it also reads well as the
umbrella a few feature milestones each contribute a slice to.

## Scope Estimate

**Large.** It is a re-grouping + several cross-cutting patterns across the whole dashboard, but almost
entirely a **surface/IA** change over existing data and existing `ScoriaWeb.UI` primitives — not new
subsystems. The genuinely-new surfaces are: the unified **Queue** list, the **Feature Cockpit** shell,
the **Run Workbench** right-inspector pane, and the **story-spine** node styling. Everything else is
re-slotting current pages under a new nav and applying the progressive-disclosure/receipt/scope patterns.

## What to build

1. **Tighter nav re-group (BUILD — `dashboard_nav.ex`).** Re-slot the current three groups into the
   target IA: Approvals + Incidents + Review Queue become **Queue** categories; **Features** lifts out as
   a top-level object; **Configure → Govern** (elevated); reserve **Data & Privacy** + **Audit** as honest
   stubs until [[SEED-011]] / the receipts ledger land. Preserve ⌘K, g-chords, breadcrumbs, active-state.
2. **Unified Queue (BUILD — the only genuinely-new list surface today).** One ranked inbox composing the
   *existing* human-work records (approvals + open incidents + flagged reviews); ranked by blocking impact
   → security/privacy risk → severity → age → blast radius → release risk → cost. **Bulk actions only for
   low-risk review cases — never bulk-approve high-risk tool actions.** Categories for release gates /
   privacy tasks slot in when [[SEED-008]]/[[SEED-011]] land.
3. **Persistent scope contract (BUILD — shell chrome).** A top scope bar (Tenant / Feature / Time / Live)
   that follows the operator; cross-tenant and any non-prod scope render visually loud. No "Env" object —
   host-declared attribute only, if at all.
4. **3-pane Run Workbench (BUILD — enhance `workflow_live/show.ex`).** Add a persistent right **inspector**
   (Diagnosis / Risk / Actions / **Related**: same actor/prompt/tool/error) and a **per-span-kind evidence
   canvas**. **Guardrail:** Diagnosis/Related are **mechanical correlations / linked-record counts**, never
   an in-lib LLM verdict. Pattern-adaptive (per-archetype) view is the [[SEED-012]] slice.
5. **Progressive-disclosure law + receipts + policy-from-decision (BUILD — `ui.ex` + flows).** Formalize
   `Summary | Details | Raw JSON` on every evidence surface (summary default, raw never first); a copyable
   **receipt** component on every consequential action; a "create policy rule from this" affordance on
   approval decisions.
6. **Feature Cockpit shell (BUILD — new surface, host-declared attr).** A per-feature homepage with the
   tab set framed but tabs populated incrementally by composing seeds. **Scoria segments by a host-declared
   feature attribute; it never models Feature as an owned entity and never infers it.**
7. **Story-spine-with-vesicles viz (BUILD — CSS/token + trace component).** Porous span-nodes whose shape
   encodes state (filled = evidence, hollow = redacted, ring = human decision, split ring = branch/replay,
   glowing rim = live, broken rim = error). Extends the existing `--scoria-span-*` palette + trace-tree
   components; motion stays operational (no shimmer).

## Explicitly NOT (anti-scope-creep)

- The full **10-section nav** from the storyboard — it is *more* orientation cost for n=1. Tighter nav only.
- **"Env" (prod/staging/dev) as a Scoria-modeled concept** — embedded = one deploy (host-declared attr max).
- **In-lib LLM diagnosis / "most likely failure" / "behaviorally dangerous" prompt-diff opinions** — P2
  violation; mechanical signals or host-supplied only.
- **Building feature-screens that need unbuilt backends** — Govern/blast-radius rides [[SEED-010]], Data &
  Privacy rides [[SEED-011]], Quality depth rides [[SEED-008]]/[[SEED-009]], Feature Cockpit content rides
  [[SEED-012]]. Ship honest stubs (v3.0 precedent), never fake data.
- **Modeling Feature/Env/tenant as owned business nouns** — host declares; Scoria records and segments.
- A **big-bang rewrite** — the v3.0 spine + v3.3 design-system are the substrate; this evolves them.

## Scope doctrine reference

P3 (operator/reviewer surface at `/scoria`, never end-user) is the load-bearing principle. P1 (durable
reconstructable record → receipts) + P4 (identity/tenant/feature by host-declared reference, not modeled)
+ P5 (zero egress — receipts/traces in the host's own Postgres). The whole seed is a **surface** over
already-recorded facts; it introduces no new owned entity and no in-lib opinion.

## Breadcrumbs

- `lib/scoria_web/dashboard_nav.ex` (the `@groups` nav model — the re-group happens here + the `@views`
  map + ⌘K `command_sections/1`).
- `lib/scoria_web/ui.ex` (`ScoriaWeb.UI`) — progressive-disclosure/receipt primitives; `page_header/1`,
  `object_header/1`, `notebook/1`, `drawer/1`, `command_palette/1` are the reuse surface.
- `lib/scoria_web/live/orchestrator_live.ex` (Home / attention strip / live stream — append-and-mark).
- `lib/scoria_web/live/approvals_live/`, `.../incidents_live/`, `.../review_queue_live.ex` — the three
  human-work surfaces the unified **Queue** composes.
- `lib/scoria_web/live/workflow_live/show.ex` (the Run Workbench to grow to 3 panes).
- `assets/css/02-tokens.css` (`--scoria-span-*` palette for the vesicle viz), `05-motion.css`.
- `.planning/phases/36-baseline-and-inventory/36-inventory.json` (the design-system quality map — start map
  for the pivot), `/scoria/_lab` (`dev/lab/`) — prototype the new surfaces without touching runtime `lib/`.
- Source memo: `.planning/research/operator-ui-north-star.md` (the doctrine-filtered synthesis + slice map)
  → `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` (raw storyboard).
- Related: [[SEED-012]] (Feature Cockpit *content* + pattern-adaptive traces), [[SEED-010]] (Govern +
  blast-radius), [[SEED-011]] (Data & Privacy), [[SEED-008]]/[[SEED-009]] (Quality/retrieval depth),
  [[SEED-007]] (attribute substrate the scope bar reads), [[SEED-005]] (vocabulary + copy standards).

## Notes

Planted 2026-07-03 from the operator-UI storyboard deep-research ingest (3 Explore agents mapped the raw
storyboard, the as-built dashboard, and GSD state; a red-team pass filtered every idea through the scope
doctrine + the n=1 persona test). The storyboard was generated blank-slate/maximalist, so the correct
residue is a **North-Star doc** (the UI source-of-record) + this **one structural seed** + cross-ref
annotations folded into the feature seeds — not a wholesale adoption of its 10-section maximal IA. The
maintainer chose "full ingest" + "structural seed owns the pivot; feature-screens ride their backend
seeds" (2026-07-03). This seed is the umbrella that makes the surface cohere; the feature seeds each ship
a slice of the North Star as their backend lands.
