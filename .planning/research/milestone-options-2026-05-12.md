# Milestone Options Research: Scoria

**Date:** 2026-05-12
**Purpose:** Capture milestone options, external product-shape signals, and a recommendation for what Scoria should build next.

## Executive Summary

Scoria has already shipped most of the substrate that modern AI application frameworks advertise: traces, workflow durability, handoffs, tool governance seams, retrieval grounding, and operator-visible evidence. The biggest remaining gap is not raw capability. It is product shape.

If the goal is "people can use this in their Phoenix apps and it meets their expectations," the next milestone should focus on embedded app defaults and public runtime clarity before adding more ambitious connector or runtime breadth.

That leads to this ordering:

1. `v1.4 Keystone` — identity, sessions, public runtime API, install/default ergonomics
2. `v1.5 Switchyard` — tool and MCP connector productization
3. `v1.6 Flightpath` — prompt lifecycle and evaluation operations
4. `v1.7 Outrider` — future-bet ecosystem/runtime integrations

## What the Market Now Expects

### 1. Sessions and resumability are table stakes

OpenAI's current Agents SDK documents session behavior where the runner retrieves prior session history, persists new user and assistant items after runs, and reuses the same session when resuming from interrupted run state. LangGraph's durable execution docs similarly treat pause/resume and human-in-the-loop continuity as default workflow behavior.

Implication for Scoria:

- app-facing sessions and actor identity cannot stay implicit
- "durable workflow" is no longer enough on its own; it must be easy to consume from normal app flows

### 2. Trace-native tool execution is expected

OpenAI's tracing docs describe trace/span coverage for agent runs, LLM generations, tool calls, guardrails, and handoffs. Their tools docs also treat hosted tools, local execution tools, function tools, agents-as-tools, and MCP servers as standard categories.

Implication for Scoria:

- Scoria already aligns well on trace-first philosophy
- the next opportunity is making tool and session identity visible and policy-backed at the product boundary

### 3. MCP is now a real integration surface, not a side quest

The MCP authorization spec requires OAuth 2.1 best practices and says PKCE is required for all clients. It also strongly recommends authorization metadata discovery.

Implication for Scoria:

- remote MCP and tool-connectivity work is strategically important
- but it should land after identity/session/public API cleanup, otherwise the security and UX story will be muddy

### 4. Phoenix teams still expect Telemetry and dashboard-native adoption

OpenTelemetry's Erlang/Elixir getting-started guide explicitly covers Phoenix instrumentation, and Phoenix LiveDashboard remains the standard real-time telemetry/dashboard surface in the ecosystem.

Implication for Scoria:

- least-surprise for Phoenix means installability, Telemetry alignment, and operator surfaces that feel native
- new capability work should strengthen this embedded story, not bypass it

### 5. Evals are shifting from nice-to-have to expected release discipline

OpenAI's Evals API and Anthropic's evaluation guidance both frame evaluations around explicit schemas, test criteria, repeatable runs, and measurable success criteria.

Implication for Scoria:

- Scoria's eval work is directionally correct
- after adoption basics and connector/product surface, prompt/version/eval-release operations become a strong next differentiator

## Repo Reality Check

Scoria's internals are ahead of its public product shape.

Evidence from the repo on 2026-05-12:

- `README.md` still says `v1.3` is next even though `v1.3 Seismograph` shipped on 2026-05-12
- `lib/scoria.ex` is still the default placeholder module
- public planning context is rich, but there was no `.planning/MILESTONE-ARC.md`
- there is a real install task (`mix scoria.install`), evaluation task, and pgvector bootstrap path, which means the substrate exists and can support a better productized surface

This is why the recommendation is not "invent more infrastructure first."

## Milestone Options

## Option A — `v1.4 Keystone`

**Theme:** Embedded app defaults, identity, and public runtime surface

**Includes**

- actor, tenant, and session identity
- public runtime API for start/resume/inspect flows
- default provider/model/prompt policy surface
- install and verification ergonomics
- docs/examples aligned to shipped behavior

**Why it is meaty**

This is not docs polish. It is the milestone that turns Scoria from powerful internals into an adoptable application layer.

**Why it should go first**

- prerequisite for tool expansion without product confusion
- prerequisite for least-surprise app embedding
- highest leverage for adoption

**Primary risks**

- trying to solve every app-framework concern at once
- over-abstracting instead of defining a crisp first public runtime surface

## Option B — `v1.5 Switchyard`

**Theme:** Tool and MCP connector productization

**Includes**

- remote MCP connectors
- OAuth/PKCE-aware auth flows
- tool policy scopes
- stronger approval and audit surfaces
- extension seams for browser/code-execution integrations

**Why it matters**

The market is standardizing on tools and MCP as ordinary building blocks, not exotic integrations.

**Why it should not go first**

Without explicit sessions, actor identity, and runtime boundaries, broader tool support increases ambiguity faster than it increases trust.

## Option C — `v1.6 Flightpath`

**Theme:** Prompt lifecycle and evaluation operations

**Includes**

- prompt/version registry
- trace -> dataset -> eval -> release flow
- baseline comparisons and CI gating
- operator visibility for release-quality decisions

**Why it matters**

This is how Scoria becomes the release discipline for AI changes, not just the runtime instrumentation layer.

**Why it is not first**

It compounds well on top of a clearer runtime and connector story; it is weaker if the runtime entry points still feel fuzzy.

## Option D — `v1.7 Outrider`

**Theme:** Future-bet ecosystem/runtime expansion

**Includes**

- deeper hosted/runtime integrations
- advanced memory policies
- optional interoperability with external agent systems

**Why it is deferred**

This is valuable but easier to justify after the product already feels complete in the default Phoenix adoption path.

## Recommendation

Build `v1.4 Keystone` first.

Reasoning:

1. It best matches the stated goal of making Scoria usable and unsurprising in real Phoenix apps.
2. It strengthens the product boundary without compromising Scoria's embedded-Phoenix DNA.
3. It unlocks the next two milestones in a cleaner order: connectors second, eval-release discipline third.
4. It directly addresses visible repo/product-shape gaps present on 2026-05-12.

## Proposed Success Bar For `v1.4 Keystone`

By the end of the milestone, a developer integrating Scoria into a Phoenix app should be able to:

- install Scoria through a documented path that matches what is actually shipped
- attach a user/session/tenant identity to a run without inventing their own internal convention
- start and resume a normal app-facing AI run through a public Scoria API
- see the run, approvals, and evidence in a native operator surface
- understand from docs and examples where Scoria ends and their app begins

## Source Links

- OpenAI Agents SDK sessions: https://openai.github.io/openai-agents-js/guides/sessions/
- OpenAI Agents SDK tracing: https://openai.github.io/openai-agents-js/guides/tracing/
- OpenAI Agents SDK tools: https://openai.github.io/openai-agents-js/guides/tools/
- OpenAI Evals API: https://developers.openai.com/api/reference/resources/evals
- MCP authorization spec: https://modelcontextprotocol.io/specification/2025-03-26/basic/authorization
- OpenTelemetry Erlang/Elixir Phoenix guide: https://opentelemetry.io/docs/languages/erlang/getting-started/
- LangGraph durable execution: https://docs.langchain.com/oss/python/langgraph/durable-execution
- Anthropic evaluation guidance: https://docs.anthropic.com/en/docs/test-and-evaluate/define-success
