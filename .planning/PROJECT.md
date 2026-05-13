# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, and operator-visible evidence without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current Milestone: v1.4 Keystone

**Goal:** Turn Scoria's shipped internals into a clean, adoptable Phoenix-app product surface centered on identity, sessions, public runtime APIs, and boring install defaults.

**Target features:**

- first-class actor, tenant, and session identity across app-facing runs
- public runtime APIs for starting, resuming, and inspecting runs
- provider/model/prompt policy defaults that fit normal Phoenix app integration
- install, verification, and docs/example flows that match what Scoria already ships

**Why now:** `v1.3 Seismograph` completed the internal control-plane substrate on 2026-05-12. The highest-leverage next step is making that substrate easy to adopt inside ordinary Phoenix applications before expanding further into connector breadth or release-ops surface area.

## Requirements

### Validated

- ✓ Trace-first observability with redaction and OpenInference-shaped storage — shipped across `v1.0 MVP`
- ✓ MCP gateway and tool-governance seams with operator approval hooks — shipped across `v1.0 MVP`
- ✓ LiveView operator visibility for traces and workflow state — shipped across `v1.0 MVP` and `v1.1 Caldera`
- ✓ Durable workflow runs, checkpoints, handoffs, and recovery semantics — shipped in `v1.1 Caldera`
- ✓ Knowledge retrieval, citations, and grounding behind `Scoria.Knowledge` — shipped in `v1.2 Corpus`
- ✓ SRE budgets, breakers, audit lineage, incident routing, and runtime telemetry — shipped in `v1.3 Seismograph`

### Active

- [ ] First-class actor, tenant, and session identity become explicit runtime nouns instead of implicit attrs.
- [ ] App-facing runs can be started, resumed, and inspected through a public `Scoria` runtime API.
- [ ] Provider/model/prompt policies have documented defaults that fit a normal Phoenix installation path.
- [ ] Install, verification, and example flows reflect the actual shipped product boundary.

### Out of Scope

- Managed remote agent hosting — conflicts with Scoria's embedded Phoenix library shape.
- Broad browser or code-execution productization as the milestone centerpiece — important later, but lower leverage before runtime identity and adoption are clear.
- Reworking Seismograph internals without a direct Keystone adoption payoff — keep this milestone focused on public product surface.

## Context

Scoria shipped `v1.3 Seismograph` on 2026-05-12. The current codebase already contains substantial internal capability: durable workflows, approvals, MCP seams, knowledge grounding, SRE budgets/breakers, audit lineage, incident delivery, and operator evidence. The next milestone is not about inventing another major subsystem first; it is about making the existing system legible and usable from a real Phoenix app request/session flow.

The milestone arc and supporting research both point to `v1.4 Keystone` as the next highest-leverage move. `SEED-001-agentcore-lessons` also applies here: Scoria should make session and actor identity explicit, keep policy-backed tool access auditable, and avoid drifting into a managed runtime platform.

Repo signals that motivate this milestone:

- `README.md` still describes `v1.3` as upcoming instead of shipped.
- `lib/scoria.ex` is still a placeholder public module.
- The codebase already exposes lower-level workflow and SRE capabilities, but the public app-facing runtime story is still too implicit for normal Phoenix adoption.

## Constraints

- **Product shape**: Remain embedded and Phoenix-first — Scoria should not become a hosted agent platform.
- **Compatibility**: Preserve existing workflow, SRE, knowledge, and dashboard boundaries — Keystone should clarify and connect them, not break them.
- **Ergonomics**: Default install and verification flow should stay boring for a normal Phoenix app setup.
- **Traceability**: Identity, policy, and runtime decisions must stay observable and operator-visible by default.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep Scoria embedded-first instead of managed-runtime-first | Matches product north star and Phoenix adoption path | ✓ Good |
| Activate `v1.4 Keystone` after `v1.3 Seismograph` | Identity and public runtime clarity unlock adoption faster than more subsystem breadth | — Pending |
| Scope Keystone around identity plus runtime API, with policy/install/docs following behind that core | Efficient path: define stable nouns first, then make the rest of the public surface coherent | — Pending |

## Milestone History

- `v1.0 MVP`: Core observability, MCP governance, operator UX, and evaluation flywheel.
- `v1.1 Caldera`: Durable agent workflows, recovery, and handoffs.
- `v1.2 Corpus`: RAG primitives, citations, grounding, and evidence projection.
- `v1.3 Seismograph`: SRE budgets, breakers, telemetry, audit export, incident delivery, and milestone closeout verification.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-12 after starting v1.4 Keystone*
