# Technology Stack

**Project:** Scoria (v1.7 Outrider)
**Researched:** 2024-05-28

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix | ~> 1.7 | Web / SSE / WebSockets | Core embedded layer. Provides native SSE (via Plug) and WebSockets (Channels) for external runtime interop. |
| Oban | ~> 2.17 | Background Jobs | Idiomatic Elixir background processing. Essential for offloading slow memory compaction (LLM summarization) from the web/eval request cycle. |
| Req | ~> 0.4 | HTTP/SSE Client | The standard, robust HTTP client for Elixir. Crucial for connecting to external hosted tool systems and runtimes. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Ecto | ~> 3.11 | Data Mapping | Standard Elixir DB layer. (Strictly avoiding Ash Framework). |
| pgvector | ~> 0.5 (DB) | Semantic Memory | Already in `dev/pgvector-compose.yml`. Used to store and query compacted memory embeddings. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Server-Sent Events (SSE) / JSON-RPC | N/A | Interoperability Protocol | Foundation of the Model Context Protocol (MCP). Lightweight, text-based, highly compatible with Phoenix. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| External Interop | HTTP / SSE / WebSockets | Rustler (NIFs) / Pyrlang | Integrating Python/JS runtimes directly into the BEAM via NIFs introduces severe crash risks, breaking the "Quality Layer" reliability guarantee. |
| Compaction Engine | Oban | GenServer / Task.async | Manual GenServers for long-running LLM compaction tasks lack persistence, retries, and rate-limiting provided out-of-the-box by Oban. |
| Data Layer | Standard Ecto | Ash Framework | Explicit project non-goal. Scoria is strictly all-in on standard Phoenix/Ecto architecture. |

## Architecture Decisions (One-Shot Recommendations)

1. **Multi-Runtime Integration Protocol**: Use **JSON-RPC over HTTP/SSE** (Model Context Protocol standard). Build standard Phoenix Plugs to act as the server (Host) and use `Req` to act as the client. Do not attempt binary protocols or custom RPC unless latency demands it.
2. **Memory Compaction**: Use a dual-table Ecto design (`raw_events` and `compacted_memories`). Use Oban to process rows from `raw_events` older than a threshold, generating summaries and vector embeddings, writing to `compacted_memories`, and hard-deleting or archiving the raw events.

## Installation

\`\`\`bash
# Core Dependencies to verify/add
mix deps.add oban
mix deps.add req
\`\`\`

## Sources
- Official Elixir/Phoenix ecosystem standards.
- Scoria `GEMINI.md` context (Strict Ecto, no Ash).
- Model Context Protocol (MCP) specifications.