# Architecture Patterns

**Domain:** Embedded Phoenix-native AI Application Quality Layer
**Researched:** 2024-05-28

## Recommended Architecture

Scoria's v1.7 architecture expands the core embedded model with asynchronous background processing for memory and boundary interfaces for external runtimes.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Scoria.Runtime.Memory` | Ecto Context managing raw context/sessions. | `Scoria.Runtime`, `Scoria.Compaction` |
| `Scoria.Compaction` | Orchestrates Oban jobs to summarize/vectorize memory. | `Scoria.Runtime.Memory`, LLM Provider |
| `ScoriaWeb.MCPPlug` | Boundary for Model Context Protocol (JSON-RPC via HTTP/SSE). | External Runtimes, `Scoria.Connectors` |
| `ScoriaWeb.AgentPresence` | Tracks health/liveliness of connected external runtimes. | `ScoriaWeb.MCPPlug`, LiveView Dashboard |

### Data Flow (Memory Compaction)

1. **Active Session**: Agent interactions are saved rapidly to `runtime_events` (Raw Ecto).
2. **Trigger**: When session tokens exceed X, or time exceeds Y, an `Oban` job (`Scoria.Compaction.Worker`) is enqueued.
3. **Processing**: Oban worker calls LLM to summarize `runtime_events` N through M.
4. **Storage**: Summary and vector embeddings are stored in `compacted_memories` (pgvector).
5. **Cleanup**: Original `runtime_events` are soft-deleted or moved to cold storage for audit purposes.

### Data Flow (External Runtime Integration)

1. **Connection**: External Python agent connects to Scoria via SSE (`ScoriaWeb.MCPPlug`).
2. **Tracking**: Phoenix Presence registers the agent as "connected".
3. **Execution**: Scoria streams tool definitions or quality evaluations to the agent.
4. **Response**: Agent executes and posts back via HTTP POST or WebSocket.

## Patterns to Follow

### Pattern 1: Oban for LLM-based State Mutations
**What:** Offloading slow LLM summarization tasks to Oban workers.
**When:** Whenever memory needs compaction, vectorization, or semantic processing.
**Example:**
\`\`\`elixir
defmodule Scoria.Compaction.SummarizeWorker do
  use Oban.Worker, queue: :compaction, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    # 1. Fetch uncompacted events
    # 2. Call LLM to summarize
    # 3. Insert into Ecto compacted_memories
    # 4. Mark raw events as compacted
    :ok
  end
end
\`\`\`

### Pattern 2: Server-Sent Events (SSE) for MCP
**What:** Using standard `Plug.Conn` to stream Server-Sent Events for the Model Context Protocol.
**When:** Integrating with external hosted tool systems and agent runtimes.
**Example:**
\`\`\`elixir
defmodule ScoriaWeb.MCP.SSEPlug do
  import Plug.Conn

  def call(conn, _opts) do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> send_chunked(200)
    # Loop and stream JSON-RPC payload chunks
  end
end
\`\`\`

## Anti-Patterns to Avoid

### Anti-Pattern 1: NIFs for External Runtimes
**What:** Using `Rustler` or `Erlport` to run Python/JS LangChain agents inside the BEAM.
**Why bad:** A crash in the external runtime's C-bindings or memory space will segfault and kill the Elixir VM. Scoria is a *quality layer* and must outlive the agents it monitors.
**Instead:** Expose standard HTTP/SSE/WebSocket endpoints. Keep external runtimes in separate OS processes or Docker containers.

### Anti-Pattern 2: Ash Framework for Memory Modeling
**What:** Attempting to use Ash Framework resources to model the complex relationship between raw events and compacted summaries.
**Why bad:** Explicitly violates project non-goals (`GEMINI.md`).
**Instead:** Use pure Ecto schemas, standard Elixir Contexts, and raw SQL/pgvector queries where complex vector math is required.

## Scalability Considerations

| Concern | At 100 Sessions | At 10K Sessions | At 1M Sessions |
|---------|--------------|--------------|-------------|
| Compaction Jobs | Run synchronously or lightly queued. | Strict Oban concurrency limits to avoid API rate limits (HTTP 429). | Partitioned Oban queues, dedicated compaction nodes. |
| External Agents | Single Phoenix node handles SSE. | Standard Phoenix Channels/Presence scales effortlessly. | Redis/PubSub backed Presence across cluster. |

## Sources
- Elixir/Phoenix ecosystem best practices for concurrent streams (SSE) and background jobs (Oban).
- Model Context Protocol (MCP) architecture guides.