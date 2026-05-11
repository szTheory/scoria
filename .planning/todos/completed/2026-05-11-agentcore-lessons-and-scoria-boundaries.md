---
created: 2026-05-11T14:56:20Z
title: Record AgentCore lessons for Scoria boundaries
area: planning
files:
  - .planning/research/agentcore-lessons.md
  - .planning/seeds/SEED-001-agentcore-lessons.md
  - .planning/STATE.md
---

## Problem

AWS AgentCore surfaced a concrete set of architecture lessons that are relevant to Scoria’s future planning: explicit session identity, separate memory/auth/tool boundaries, observability as a product primitive, and the need to avoid drifting into a managed-runtime shape.

Without recording those lessons, future phase planning is likely to re-derive them piecemeal or accidentally adopt AWS-shaped assumptions that conflict with Scoria’s embedded Phoenix direction.

## Solution

Keep the new research note and seed as reference material, and carry the main takeaways into future planning defaults:

- keep Phoenix as the control plane
- keep agent execution portable and adapter-driven
- keep session state durable and explicit
- keep tool access policy-backed and audited
- keep deterministic work out of the agent loop

