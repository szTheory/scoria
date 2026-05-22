# Feature Landscape

**Domain:** Multi-model orchestration and distributed evaluations
**Researched:** 2024-05-24

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Model Fallback Routing | If Anthropic fails/rate-limits, fallback to OpenAI or local models transparently. | Med | Requires a routing layer that understands model feature parity (e.g., context size). |
| Circuit Breakers | Stop hitting an API that is down to prevent cascading timeouts and thread pool exhaustion. | Med | Should be stateful across the cluster (or node-local for simplicity but fast response). |
| Oban-backed Eval Fan-out | Run hundreds of evaluation prompts in parallel without blocking the web process. | Low | Core Oban worker pattern. |
| Configurable Retry Policies | Handle HTTP 429s (Rate Limits) gracefully with exponential backoff. | Low | Built into `Req`, just needs tuning for LLM contexts. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Tenant-aware Rate Shaping | Throttle aggressive tenants while preserving capacity for premium tenants in a multi-tenant environment. | High | Involves token-bucket algorithms mapped per-tenant in ETS. |
| Live Eval Progress Matrix | Real-time LiveView dashboard showing distributed evaluations progressing across models and tenants. | Med | Uses Phoenix.PubSub to stream Oban job completions to the UI. |
| Telemetry-driven Rerouting | Automatically demote a model if its p95 latency spikes, not just on outright failures. | High | Blends standard routing with dynamic telemetry aggregations. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| External Eval Services | Do not ship data out to third-party eval tools (LangSmith, Braintrust). | Build native Phoenix LiveView dashboards querying Ecto results directly. |
| Complex DAGs / LangGraph | Over-engineers the orchestration layer and obscures execution paths. | Use pure Elixir functions, `with` statements, and Oban workflows. |

## Feature Dependencies

```
Model Fallback Routing -> Circuit Breakers (Routing needs health state)
Live Eval Progress Matrix -> Oban-backed Eval Fan-out (Requires jobs to be running)
Tenant-aware Rate Shaping -> Model Fallback Routing (Shape limits can trigger fallbacks)
```

## MVP Recommendation

Prioritize:
1. Model Fallback Routing (static fallback chains)
2. Circuit Breakers (Node-local ETS)
3. Oban-backed Eval Fan-out (Simple parallel queueing)

Defer: Tenant-aware Rate Shaping (complex, wait until production multi-tenant scale demands it).

## Sources
- Standard GenServer/ETS application patterns in Elixir.
- Oban Pro/OSS documentation for distributed workers.