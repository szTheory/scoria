# Domain Pitfalls

**Domain:** Embedded Phoenix-native AI Application Quality Layer (v1.7 Outrider)
**Researched:** 2024-05-28

## Critical Pitfalls

Mistakes that cause rewrites, severe performance degradation, or data loss.

### Pitfall 1: BEAM Scheduler Starvation during Compaction
**What goes wrong:** The application becomes unresponsive, health checks fail, and requests time out.
**Why it happens:** Executing synchronous, long-running LLM API calls (for memory summarization) directly inside a web request process or a naive `Task`, tying up database connections or schedulers.
**Consequences:** Complete system lockup.
**Prevention:** Strictly enforce that all memory compaction and semantic vectorization occurs within `Oban` background jobs. Limit Oban concurrency to prevent exhausting database connections.
**Detection:** High latency on all endpoints, Oban queue backups, Ecto pool timeouts (`DBConnection.ConnectionError`).

### Pitfall 2: Compaction Drift (Lossy Memory)
**What goes wrong:** External agents begin hallucinating or failing tasks because they lack necessary context that was "compacted" away.
**Why it happens:** LLM summarization is inherently lossy. Aggressive compaction drops specific identifiers, exact quotes, or system state needed by tools.
**Consequences:** Reduced agent accuracy and trust.
**Prevention:** 
1. Implement a hybrid memory strategy: retain a short rolling window of *raw* events (e.g., last 10 turns) alongside the compacted summary of older events.
2. Store vector embeddings of original events in `pgvector` to allow the agent to explicitly retrieve dropped facts (RAG).
**Detection:** Agent evaluation scores drop; operators complain that agents "forgot" details during long sessions.

## Moderate Pitfalls

### Pitfall 1: External Runtime Unreliability
**What goes wrong:** Python or Node.js runtimes crash, hang, or silently fail, leaving Scoria waiting for a response.
**Prevention:** Treat all external integrations as unreliable. Use strict timeouts (via `Req` options), circuit breakers, and monitor agent liveliness using Phoenix Presence over WebSockets/SSE. Never block a BEAM process indefinitely waiting for an external agent.

### Pitfall 2: MCP Specification Churn
**What goes wrong:** The Model Context Protocol (MCP) is relatively new and evolving. Hardcoding strict parsing may break as external tools update their SDKs.
**Prevention:** Design the Scoria `MCPPlug` and JSON-RPC parsers to be permissive with unknown fields. Maintain a strict abstraction layer between the MCP protocol parsing and Scoria's internal Ecto representation of tools/memory.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| MCP Integration | Protocol impedance mismatch (SSE vs WebSockets). | Default to SSE for host-to-client streaming, as it aligns best with the current MCP standard, using pure Phoenix Plugs. |
| Memory Compaction | Token limit exhaustion during the summarization itself. | Ensure the chunking algorithm never sends more raw text to the summarizer LLM than its context window allows. Use recursive chunking if necessary. |

## Sources
- Incident reports from LangChain/LlamaIndex production deployments (context loss).
- Elixir BEAM operational guidelines (scheduler starvation).
- MCP standard documentation.