# JTBD and User Flows

Scoria is for Phoenix teams that want one embedded way to start, resume, inspect, and verify AI/LLM work without adopting a hosted agent platform. Start from [Getting Started](guides/getting-started.md), follow the [Golden Path](guides/golden-path.md), and use the [Glossary](guides/reference/glossary.md) when a term needs a precise definition.

## Jobs To Be Done

Core: a Phoenix engineer can add durable AI runtime governance to an existing app, start one identity-aware run, inspect the reviewer trace, pause for approval, resume the exact run, and prove the default runtime capability with a verification suite.

Adjacent: security, privacy/legal, Trust and Safety, domain experts, PMs, and support teams consume exported proof, review outputs, policy hooks, or documented boundaries, but they are not the first dedicated Scoria surface.

Not Scoria's surface: end users of host AI flows, host product designers, finance or executive dashboards, general data warehouses, host auth administration, host policy administration, and business-domain work queues.

The reviewer is a role one engineer may wear, not a required department. Scoria should stay usable by the smallest viable team while still leaving room for larger review workflows.

## Capability Ladder

Adopt capabilities in this order:

1. Default runtime capability: `identity -> start -> inspect -> resume`.
2. Bounded handoff capability: same durable run, narrow delegated work, host-selected scoped context.
3. Semantic cache capability: safe read-only answer reuse with tenant partitioning and reviewer trace detail.
4. Optional knowledge base capability: retrieval, citations, grounding, and tenant-scoped knowledge proof.
5. Remote connector capability: MCP connector registration, grants, health, approval pauses, and trace evidence.

Start narrow. Expand only when the current capability already feels boring in your host app.

## Default Runtime Flow

The default runtime flow is the first user flow:

```text
identity -> start -> inspect -> resume
```

The host app builds identity from authenticated Phoenix state. Scoria starts a durable run, stores trace records, surfaces the reviewer dashboard, and resumes paused work by exact `run_id`.

Use this when you need:

- canonical actor, tenant, and `session_id` identity
- durable `run_id` readback
- approval pauses
- reviewer trace pages at `/scoria/workflows/:run_id`
- `$ mix test.adoption` as the default runtime verification suite

This flow does not require semantic cache, optional knowledge base, connector setup, or pgvector bootstrap.

## Reviewer Flow

A reviewer enters through a host-authenticated dashboard scope:

1. The host app authenticates the reviewer.
2. The host app checks tenant membership and authorization.
3. The dashboard scope resolver returns trusted `tenant_id` and `actor_id`.
4. Scoria shows runs, approvals, incidents, eval evidence, prompt release evidence, and traces for that asserted tenant scope.
5. Query params remain hints; they do not choose the dashboard tenant.

For the exact ownership split, see [Ownership Boundary](guides/ownership-boundary.md).

## Escalation Flow

Use bounded handoffs only when a role needs to delegate a narrow slice of work to another role under the same durable run.

That bounded handoff capability starts after the default runtime capability is already green; it is not the first adoption surface. The semantic cache capability is the later safe-read-only reuse step, and the optional knowledge base capability is a retrieval/citation layer, not a prerequisite for the default runtime.

The host app owns:

- which facts may enter `scoped_context`
- which role receives the delegated work
- escalation policy
- prompt or draft selection
- business meaning

Scoria owns:

- durable run creation
- scoped-context validation
- queued delegated child creation
- `Scoria.get_run_detail/1` readback
- reviewer trace projection

## Verification Flow

Use one verification suite per capability:

| Capability | Verification suite | Use when |
|------------|--------------------|----------|
| Default runtime capability | `$ mix test.adoption` | First adoption and core runtime proof. |
| Bounded handoff capability | `$ mix test.runtime_to_handoff` | Narrow same-run delegation is wired. |
| Semantic cache capability | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path` | Safe read-only reuse is intentionally enabled. |
| Optional knowledge base capability | `$ mix test.knowledge` | Retrieval, citations, and grounding are part of your product. |
| Remote connector capability | `$ mix test.connector` | MCP connector registration and trace proof are part of your product. |

Maintainer packaging proof is `$ mix scoria.release_preview`; see [Reviewer Verification](guides/reviewer-verification.md).

## What To Read Next

- [Golden Path](guides/golden-path.md) for the first copyable flow.
- [Ownership Boundary](guides/ownership-boundary.md) for what Scoria owns versus what your app owns.
- [Default Runtime](guides/capabilities/default-runtime.md) for the expanded default runtime capability.
- [Glossary](guides/reference/glossary.md) for final public terms and 0.1.x compatibility aliases.
