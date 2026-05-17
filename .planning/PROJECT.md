# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Current State

Scoria is shipped through `v1.4 Keystone` as of 2026-05-17. The product now has canonical actor, tenant, and session identity; a public `Scoria` runtime API for start/resume/inspect flows; predictable defaults and install ergonomics; and adoption docs tied to executable proof lanes.

## Next Milestone Goals

- Productize MCP and tool connector breadth under the likely `v1.5 Switchyard` milestone.
- Extend identity, approval, and audit boundaries cleanly into remote connector scenarios.
- Keep install, verification, and operator evidence boring while expanding public tool surface area.

## Milestone History

- `v1.0 MVP`: Core observability, MCP governance, operator UX, and evaluation flywheel.
- `v1.1 Caldera`: Durable agent workflows, recovery, and handoffs.
- `v1.2 Corpus`: RAG primitives, citations, grounding, and evidence projection.
- `v1.3 Seismograph`: SRE budgets, breakers, telemetry, audit export, incident delivery, and milestone closeout verification.
- `v1.4 Keystone`: Canonical runtime identity, public runtime API, install defaults, adoption docs, verification backfills, and executable adoption guards.

<details>
<summary>Archived Keystone Planning Context</summary>

## Previous Active Milestone

`v1.4 Keystone` focused on turning Scoria's shipped internals into a clean, adoptable Phoenix-app product surface centered on identity, sessions, public runtime APIs, and boring install defaults.

### Keystone Outcomes

- First-class actor, tenant, and session identity are explicit runtime nouns.
- App-facing runs can be started, resumed, and inspected through a public `Scoria` runtime API.
- Provider/model/prompt policies have documented defaults that fit a normal Phoenix installation path.
- Install, verification, and example flows reflect the shipped product boundary.

### Constraints That Still Hold

- Remain embedded and Phoenix-first.
- Preserve workflow, SRE, knowledge, and dashboard boundaries while clarifying the public product surface.
- Keep install and verification boring for a normal Phoenix app setup.
- Keep identity, policy, and runtime decisions observable and operator-visible by default.

</details>

---
*Last updated: 2026-05-17 after shipping v1.4 Keystone*
