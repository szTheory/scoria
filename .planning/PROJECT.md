# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## Requirements

### Validated

- ✓ Canonical actor, tenant, and session identity are explicit public runtime nouns. — `v1.4 Keystone`
- ✓ Developers can start, resume, and inspect app-facing runs through the public `Scoria` runtime surface. — `v1.4 Keystone`
- ✓ Provider/model/prompt-policy defaults are installable through one documented application-facing surface. — `v1.4 Keystone`
- ✓ Adoption docs and verification flows align to executable proof lanes instead of prose-only guidance. — `v1.4 Keystone`

### Active

- [ ] Remote MCP connectors can be registered through a Phoenix-native Scoria boundary with boring defaults for discovery, auth, and capability refresh.
- [ ] Remote connector invocation preserves Scoria identity, tool policy, approval, and audit evidence without turning Scoria into a hosted connector platform.
- [ ] Operators can inspect connector health, granted scopes, approvals, and remote invocation evidence through the embedded dashboard surface.
- [ ] Scoria ships a small curated connector/profile layer that improves DX for common remote-tool adoption paths without widening the core product boundary.

### Out of Scope

- Full hosted connector marketplace or broker behavior — would drift Scoria away from its embedded Phoenix product shape.
- First-party browser/code-exec productization in this milestone — adds a separate privileged-execution risk class before connector policy and evidence are proven boring.
- Prompt/version release operations and eval-release gates — reserved for likely `v1.6 Flightpath`.
- Deep external runtime interoperability — valuable, but not ahead of making remote connector governance unsurprising in ordinary Phoenix apps.

## Current Milestone: v1.5 Switchyard

**Goal:** Productize remote MCP connector adoption as an embedded Phoenix capability with stateless-first defaults, policy-backed tool scopes, workflow-owned approvals, and operator-grade audit visibility.

**Target features:**
- Remote MCP connector registration, discovery, and auth flows that fit a normal Phoenix app boundary.
- Stateless-first remote connector invocation with explicit local identity, policy, approval, and audit evidence.
- LiveView operator surfaces for connector health, granted scopes, approval review, and invocation evidence.
- Curated connector profiles and boring install defaults for common remote-tool adoption paths.

**Why now:** Keystone clarified Scoria's public identity, runtime API, and install defaults. The next highest-leverage move is extending those same boundaries into remote tool connectivity before adding broader release-ops or future-bet runtime surfaces.

## Context

- Scoria is shipped through `v1.4 Keystone` as of 2026-05-17.
- The repo already has durable workflow truth, approval lineage, telemetry, and audit seams that remote connector support should reuse instead of bypass.
- The milestone arc still prioritizes adoption prerequisites before adjacent capability expansion.
- Repo-local research and seed context reinforce the same design direction: remain embedded, keep transport separate from LiveView, treat policy and approvals as durable records, and avoid AWS-shaped platform drift.
- External MCP authorization guidance now treats OAuth-style discovery, protected-resource metadata, and PKCE as standard expectations for HTTP-based remote auth flows.

## Constraints

- **Product shape**: Stay embedded and Phoenix-first — Scoria must remain a library plus dashboard surface, not a hosted connector platform.
- **State truth**: Keep connector auth, grants, approvals, and evidence durable in Ecto — operator trust depends on inspectable records rather than process-local state.
- **Transport boundary**: Keep MCP protocol transport in Plug-facing boundaries and reserve LiveView for operator UX only.
- **Security**: Default to least-privilege scopes, redaction, and approval on remote writes / exec / scope escalation.
- **DX**: Keep installation and verification boring for a normal Phoenix app path; only ask the user for materially impactful security or blast-radius choices.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| `v1.5` focuses on remote connector productization, not release ops | Connector breadth is the next missing adoption boundary after Keystone; release discipline can layer cleanly afterward | — Pending |
| Remote connector support is stateless-first by default | This yields real value without forcing stateful session complexity or multi-node surprises into the default milestone path | — Pending |
| Operator/audit visibility is the primary user-facing outcome | Scoria's differentiator is evidence and governance, not merely "can connect a tool" breadth | — Pending |
| Browser/code-exec stays out of scope for `v1.5` | It introduces a separate privileged-execution risk class before connector policy and evidence are proven boring | — Pending |

## Milestone History

- `v1.0 MVP`: Core observability, MCP governance, operator UX, and evaluation flywheel.
- `v1.1 Caldera`: Durable agent workflows, recovery, and handoffs.
- `v1.2 Corpus`: RAG primitives, citations, grounding, and evidence projection.
- `v1.3 Seismograph`: SRE budgets, breakers, telemetry, audit export, incident delivery, and milestone closeout verification.
- `v1.4 Keystone`: Canonical runtime identity, public runtime API, install defaults, adoption docs, verification backfills, and executable adoption guards.

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
*Last updated: 2026-05-17 after starting v1.5 Switchyard*
