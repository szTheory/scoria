# Feature Landscape

**Domain:** Embedded Phoenix-native AI Application Quality Layer
**Researched:** 2024-05-28

## Table Stakes

Features users expect for multi-runtime integration and advanced memory management.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| MCP (Model Context Protocol) SSE Support | Standard for agent interop | Medium | Implementing JSON-RPC over SSE in standard Phoenix Plug/Req. |
| Token-Aware Memory Windowing | Prevents context limits | Low | Basic sliding window strategy in Ecto before heavy summarization. |
| Async Compaction Jobs | Non-blocking summarization | Medium | Using Oban to summarize old context without blocking evaluations. |
| Webhook Receivers | Allow external agents to report state | Low | Standard Phoenix endpoints for Python/JS runtimes to push telemetry. |

## Differentiators

Features that set Scoria apart as a premium embedded quality layer.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Memory "Time-Travel" LiveView | Operators can see what the agent "remembered" vs what actually happened. | High | Diffing raw archived Ecto records vs compacted vector summaries in real-time. |
| Phoenix Presence for External Agents | Real-time health monitoring of connected external runtimes (Python/Node). | Medium | Treat external runtimes as users in a Presence channel to detect silent failures. |
| Semantic Memory Injection | Automatically injects relevant historical compaction chunks into current context via pgvector. | High | Requires wiring `pgvector` searches into the runtime prompt resolution phase. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| In-Process Python/JS Runtimes (NIFs) | Risk of segfaults taking down the Elixir host. | Provide robust HTTP/SSE/WebSocket integration endpoints (MCP). |
| Ash Framework Integration | Project constraint / Architecture non-goal. | Use pure Ecto schemas, Contexts, and Oban workers. |
| Synchronous LLM Compaction | Blocks the web request / scheduler, terrible UX. | Queue compaction tasks to Oban and return immediately. |

## Feature Dependencies

\`\`\`text
Webhook Receivers → MCP SSE Support (Requires base protocol handling)
Async Compaction Jobs → Semantic Memory Injection (Injection relies on compacted data)
\`\`\`

## MVP Recommendation

Prioritize:
1. MCP-compatible HTTP/SSE endpoints for external tool hosting.
2. Basic Oban-backed async memory compaction (Raw -> Summary).
3. LiveView dashboard for inspecting compacted memory state.

Defer: 
- Advanced Semantic Memory Injection (Vector DB RAG): Wait until the basic summarization pipeline is verified and stable, then introduce `pgvector` similarity search.

## Sources
- Elixir/Phoenix Idiomatic Patterns (Oban for background, Presence for distributed state).
- Scoria `GEMINI.md` architectural constraints.