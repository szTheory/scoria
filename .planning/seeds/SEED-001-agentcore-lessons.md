---
status: archived
archived_on: 2026-05-22
title: AgentCore Lessons for Scoria boundaries
---

# Seed: AgentCore Lessons for Scoria

**Captured:** 2026-05-11
**Source:** AWS Bedrock AgentCore research

## Trigger Conditions

Surface this seed when planning or revisiting:

- Agent runtime boundaries
- Session-scoped identity and memory
- Tool governance / MCP gateways
- Browser or code-execution integrations
- Observability contracts for agent systems
- Whether Scoria should absorb more agent-hosting responsibilities

## Why This Matters

AgentCore is a useful external reference because it shows how a managed agent platform decomposes into runtime, memory, identity, tools, observability, and policy. The core lesson for Scoria is to preserve the embedded Phoenix product shape while keeping execution, auth, and tool access boundary-driven.

## Design Takeaways

- Keep Scoria code-defined and embedded first; avoid turning it into a managed agent runtime.
- Make session and actor identity explicit and durable.
- Keep tool access policy-backed and auditable.
- Treat observability as a product primitive, not an add-on.
- Use deterministic Elixir code for deterministic tasks; do not default everything into the agent loop.

## Anti-Patterns

- AWS-shaped platform drift
- Hidden runtime state treated as product truth
- Sandbox or IAM assumptions without explicit least-privilege review
- Overly broad built-in tool surfaces

## Resolution

Archived as a reference seed on 2026-05-22.

The design lessons were already absorbed into shipped and verified planning surfaces, especially the identity, policy, and anti-platform-drift work across Keystone and the remote connector phases. This seed remains useful background material, but it is no longer an open implementation candidate for milestone-close audit purposes.
