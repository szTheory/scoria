---
id: SEED-012
status: deferred
planted: 2026-07-03
deferred_on: 2026-07-09
planted_during: v3.3 Design System Stress Test (phase 40 in-flight)
trigger_when: next milestone scoped as pattern lens / archetype / router analytics / Rule-8 evals — sequence AFTER SEED-007 + SEED-008
scope: small-medium
priority: medium
enriched: 2026-07-03 (from the AI-architecture-patterns deep-research ingest + a red-team synthesis pass)
depends_on: [SEED-007, SEED-008]
---

# SEED-012: Architecture-Archetype Awareness (Rule-8 lens)

## Why This Matters

The AI-architecture-patterns memo (`.planning/research/ai-architectural-patterns.md`) makes one meta-idea
load-bearing — **Rule 8: "the eval shape should match the architecture shape."** A router needs
routing-accuracy + confusion-matrix; RAG needs retrieval + faithfulness + citation; a tool-assistant needs
tool-selection + args + permissions; an agent needs trace + goal-completion + stop-behavior. Today Scoria
is **archetype-agnostic**: it records runs/traces/scores regardless of *what kind* of AI feature the host
built, so the operator sees the same generic surface for a single-call classifier and a multi-agent
handoff. This seed adds a thin, **host-declared** lens that lets the dashboard + eval presets adapt to the
archetype — realizing Rule 8 as a small composition over already-built surfaces.

It is deliberately a **capstone / composition seed**: it is mostly a *dividend* of [[SEED-007]] (the
`archetype`/`route` trace-attribute convention) + [[SEED-008]] (the typed `archetype` slot + Rule-8 eval
presets + confusion-matrix reuse). Promoted to its own tracked seed (maintainer decision, 2026-07-03) so
the pattern lens + Router observability + the segment-by-attribute dashboard view are a first-class,
schedulable milestone rather than easily-dropped annotations.

## When to Surface

**Trigger:** a pattern-lens / archetype / router-analytics / Rule-8-eval milestone, **after [[SEED-007]]
and [[SEED-008]]** — this seed reads their attribute convention + eval machinery and adds almost no new
infra of its own. Small; can also ride as a follow-on inside the SEED-007 or SEED-008 milestone if scope
allows.

## Scope Estimate

**Small-Medium.** Mostly a dashboard segment view + preset config; the storage + eval mechanics already
exist after 007/008. The one genuinely-new *surface* is the segment-by-attribute view.

## What to build

1. **Host-declared `archetype` (BUILD slot — thin).** Let the host tag an AI feature/run with its
   archetype from the ladder enum: `single_call`, `structured_extraction`, `prompt_chain`, `rag`,
   `router`, `tool_assistant`, `parallelization`, `evaluator_optimizer`, `orchestrator_workers`,
   `agentic_loop`, `multi_agent`. Rides the [[SEED-007]] attribute convention + the [[SEED-008]] typed
   slot. **Scoria stores + surfaces it; NEVER infers it** — inferring what a host's feature "is" would be
   a P2 "opinion" / P1 "business-truth" violation.
2. **Segment-by-attribute dashboard view (BUILD).** Group runs / spans /
   cost / latency / eval-scores by `archetype` (and by `route`). Land it as a *facet* on an existing
   surface (Runs / Trace Explorer, or the Cost Ledger stub) rather than a brand-new page. This is the
   operator payoff: "show me all my router runs and their per-route cost + routing accuracy." **Where it
   lands (2026-07-03 reconcile):** if [[SEED-013]]'s Feature Cockpit shell has shipped, this segment view
   becomes the **Overview/Quality tab content** of the cockpit rather than a standalone facet — see the
   reconciliation note below.
3. **Rule-8 preset bundles (BUILD config + DOCS — guidance, not enforcement).** Per-archetype recommended
   eval-set + guardrail checklist, surfaced as *suggestions/config on top of [[SEED-008]]'s scorer
   library* — never enforced thresholds (P2 mechanism-not-opinion). "You tagged this `rag` → here's the
   retrieval + faithfulness + citation eval set most `rag` features want."
4. **Router observability as the first concrete archetype (BUILD — reuse).** Per-route cost/latency
   (group-by over the `route` attribute) + routing accuracy (predicted-route vs gold-route through the
   [[SEED-008]] confusion-matrix machinery). No new primitive: it's the `route` attribute + a
   segment view + confusion-matrix reuse.

## Reconciliation with [[SEED-013]] (Operator IA Pivot, 2026-07-03)

The operator-UI storyboard ingest (`.planning/research/operator-ui-north-star.md`) introduced a much
larger **Feature Cockpit** — a per-feature homepage keyed on a host-declared feature attribute. To avoid
overlap: **[[SEED-013]] owns the Cockpit *shell*** (the per-feature page, its tab frame, the
segment-by-attribute view chrome, the pattern-adaptive Run Workbench pane); **this seed (012) owns the
*content* that populates it** — the per-archetype eval presets, the router confusion-matrix / routing
accuracy, and the archetype/route grouping data. They **compose, not duplicate**: 013 is the surface, 012
is the analytics that fill it. If 013 has not yet shipped, 012's segment view lands as a standalone facet
(item 2) as originally scoped; if it has, 012's view is a cockpit tab. Neither seed changes the doctrine
posture — host declares `archetype`/`route`/feature; Scoria records and segments, never infers.

## Explicitly NOT (anti-scope-creep)

- Scoria **inferring/assigning** the archetype (P1/P2 violation) — host declares only.
- Opinionated policy thresholds or enforced per-archetype gates (P2 — mechanism, not opinion).
- Any new heavyweight subsystem — this is composition + one dashboard facet, not net-new infra. If it
  can't be built as a thin layer over 007+008, that's a signal to cut it back, not to grow it.

## Scope doctrine reference

P1 (durable record of a host-declared fact, not Scoria's business truth) + P2 (surfacing/segmenting
*mechanism*; host supplies the archetype value + any thresholds) + P3 (operator/reviewer surface at
`/scoria` only). The whole seed is host-declares / Scoria-records-and-surfaces — the same posture as
[[SEED-010]]'s tool-declared trifecta classification and [[SEED-008]]'s host-set risk_tier/intent slots.

## Breadcrumbs

- `lib/scoria/observe/**` + the `attributes` map convention → the `archetype`/`route` keys ([[SEED-007]]).
- `lib/scoria/eval/dataset_item.ex` (the typed slot set — add `archetype` beside `intent`/`risk_tier`),
  `lib/scoria/eval/**` (confusion-matrix machinery from [[SEED-008]] item 2, reused for routing accuracy).
- `lib/scoria_web/live/workflow_live/` + `operator_surface.ex` (segment-by-attribute facet; or de-stub the
  Cost Ledger / a Runs facet).
- Source memo: `.planning/research/ai-architectural-patterns.md` — §5 router, §7 parallelization, §15
  decision-tree, §17 ladder, Rule 8. Red-team synthesis: `~/.claude/plans/i-did-a-new-recursive-origami.md`.
- Related: [[SEED-007]] (attribute substrate), [[SEED-008]] (eval half), [[SEED-005]] (docs: "which pattern
  → which surface").

## Notes

Planted 2026-07-03 from the AI-architecture-patterns deep-research ingest (3 Explore agents mapped the lib,
GSD state, and dashboard; a red-team Plan agent pressure-tested the synthesis against the scope doctrine).
The red-team's verdict: the memo *validates* ~85% of Scoria as-built, so the correct residue is annotations
+ this **one** small capstone seed — everything else folded into 005/007/008/009/010/011. The clean,
doctrine-safe nugget worth its own seed is the host-declared archetype lens + the segment-by-attribute
dashboard view; even that is best shipped as a thin follow-on to 007/008, never as heavyweight new infra.
Parallelization/voting cohort grouping (§7) and the evaluator-optimizer loop (§8, expressible today as a
Workflow + judge gate) were considered and deliberately **deferred/documented-not-built** — low leverage
for the n=1 persona.
