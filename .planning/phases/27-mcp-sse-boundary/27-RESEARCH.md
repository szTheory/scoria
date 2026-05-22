# Phase 27: MCP Server-Sent Events (SSE) Boundary - Research

**Researched:** 2024-05-19
**Domain:** SSE connection management and process routing in Elixir/Phoenix
**Confidence:** HIGH

## Summary

This phase implements the Model Context Protocol (MCP) Server specification via Server-Sent Events (SSE). It creates an HTTP boundary for external agents (Python, Node) to discover and invoke Scoria tools. The core challenge is bridging the gap between a long-lived `GET` SSE connection process and ephemeral `POST` requests carrying JSON-RPC messages.

**Primary recommendation:** Use Elixir's native `Registry` to route incoming `POST` messages to a recursive receive loop holding the `Plug.Conn` open in the `GET` controller action.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SSE Connection Tracking | API / Backend | — | Elixir Registry provides fast, local PID lookups for session IDs. |
| Message Routing | API / Backend | — | Controller POST action routes JSON-RPC messages to the holding GET process. |
| Event Streaming | API / Backend | — | `Plug.Conn.send_chunked/2` provides HTTP-compliant Server-Sent Events. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Elixir.Registry` | Core | Ephemeral session tracking | Built-in, extremely fast local pubsub and process lookup. |
| `Plug.Conn` | Core | HTTP chunking | `send_chunked/2` and `chunk/2` are the standard for SSE in Phoenix. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Registry` | `Phoenix.PubSub` | PubSub is distributed; we only need local process routing for simple SSE. Registry is simpler. |
| Receive Loop | `GenServer` per session | GenServer adds indirection; a simple recursive loop holding the conn is standard Phoenix SSE pattern. |

## Architecture Patterns

### System Architecture Diagram
```
Client (External Agent)             ScoriaWeb (Elixir API)
       |                                      |
       |----- GET /mcp/sse (session X) ------>| [Process A]
       |                                      |  - Registers with SessionRegistry
       |<---- 200 OK (text/event-stream) -----|  - Calls send_chunked(200)
       |<---- event: endpoint \n data:... ----|  - Enters receive_loop()
       |                                      |
       |----- POST /mcp/messages?session_X -->| [Process B]
       |      { jsonrpc payload }             |  - Looks up PID for session X in Registry
       |                                      |  - send(pid, {:mcp_message, payload})
       |<---- 202 Accepted -------------------|  - Returns immediately
       |                                      |
       |                                      | [Process A] receives message
       |                                      |  - Handles JSON-RPC
       |<---- data: { response payload } -----|  - Calls chunk(conn, response)
```

### Recommended Project Structure
```
lib/scoria/
└── mcp/
    └── session_registry.ex      # Application-level registry configuration (if needed, otherwise just in application.ex)
lib/scoria_web/
└── controllers/
    └── mcp_controller.ex        # GET and POST actions with SSE receive loop
```

### Pattern 1: Registry-based Process Routing
**What:** Using `Registry` to route POST requests to a long-lived GET connection process.
**When to use:** When you need a disconnected request-response pattern like MCP over SSE.
**Example:**
```elixir
# In application.ex
children = [
  {Registry, keys: :unique, name: Scoria.MCP.SessionRegistry}
]

# In controller
def messages(conn, %{"session_id" => session_id}) do
  case Registry.lookup(Scoria.MCP.SessionRegistry, session_id) do
    [{pid, _}] ->
      send(pid, {:mcp_message, conn.body_params})
      send_resp(conn, 202, "")
    [] ->
      send_resp(conn, 404, "Session not found")
  end
end
```

### Pattern 2: SSE Receive Loop
**What:** Holding a connection open and listening for process messages to chunk out.
**When to use:** Streaming server-sent events without WebSockets.
**Example:**
```elixir
def sse(conn, _params) do
  session_id = Ecto.UUID.generate()
  {:ok, _} = Registry.register(Scoria.MCP.SessionRegistry, session_id, nil)

  conn =
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> send_chunked(200)

  endpoint_url = ~s(/mcp/messages?session_id=#{session_id})
  {:ok, conn} = chunk(conn, "event: endpoint\ndata: #{endpoint_url}\n\n")

  listen_loop(conn)
end

defp listen_loop(conn) do
  receive do
    {:mcp_message, payload} ->
      # Process payload
      response = Jason.encode!(%{result: "ok"})
      case chunk(conn, "data: #{response}\n\n") do
        {:ok, conn} -> listen_loop(conn)
        {:error, :closed} -> conn
      end
  after
    30_000 ->
      chunk(conn, ": keepalive\n\n")
      listen_loop(conn)
  end
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Spawning a GenServer to hold the connection state.
  *Why:* The `Plug.Conn` struct is meant to be held by the web process. Spawning a separate GenServer means copying connection state or passing messages back and forth unnecessarily. Keep the loop in the controller process.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Process Lookups | Custom GenServer map | `Registry` | ETS-backed, built-in, highly concurrent |
| Chunked Responses | Manual TCP socket writes | `Plug.Conn.send_chunked/2` | Handles HTTP compliance and web server integration natively |

## Common Pitfalls

### Pitfall 1: Connection Timeouts
**What goes wrong:** The SSE connection drops unexpectedly after 60 seconds.
**Why it happens:** Cowoby/Bandit or standard HTTP middleware enforce idle timeouts.
**How to avoid:** Implement a `receive do ... after 30_000` block in the loop to send a keepalive comment (`: keepalive\n\n`) to prevent the connection from idling out.

### Pitfall 2: Process Leaks
**What goes wrong:** Old sessions remain in memory.
**Why it happens:** The client disconnects ungracefully, or the receive loop crashes.
**How to avoid:** `Registry` automatically cleans up when the registering PID dies. Ensure the `listen_loop` gracefully exits when `chunk/2` returns `{:error, :closed}` so the PID terminates.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/scoria_web/controllers/mcp_controller_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OUTRIDER-01 | GET /mcp/sse registers session and chunks endpoint | integration | `mix test test/scoria_web/controllers/mcp_controller_test.exs` | ❌ Wave 0 |
| OUTRIDER-01 | POST /mcp/messages routes to SSE process | integration | `mix test test/scoria_web/controllers/mcp_controller_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/scoria_web/controllers/mcp_controller_test.exs` — covers OUTRIDER-01

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Unpredictable UUIDv4 for `session_id` |
| V3 Session Management | yes | Ephemeral process binding, no long-lived persistence |
| V4 Access Control | yes | Scoped strictly to allowed MCP operations |
| V5 Input Validation | yes | JSON-RPC schema validation for incoming POST payloads |

### Known Threat Patterns for Elixir/Plug

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Session Hijacking | Spoofing | Rely on TLS (HTTPS) and UUIDv4 unpredictability |
| Denial of Service | Availability | Do not spawn unbounded external processes; limit payload size |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OUTRIDER-01 | MCP SSE Boundary | Addressed via Elixir Registry and `Plug.Conn` chunked streaming patterns. |
</phase_requirements>

## Sources

### Primary (HIGH confidence)
- `.planning/research/phase_27_decisions.md` - Verified architecture decision (Approach A)
- `.planning/phases/27-mcp-sse-boundary/27-PATTERNS.md` - Verified file patterns and chunking implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Registry and Plug are native Elixir/Phoenix primitives.
- Architecture: HIGH - Fully aligned with Phase 27 decisions document.
- Pitfalls: HIGH - Documented standard Phoenix streaming caveats.

**Research date:** 2024-05-19
**Valid until:** Stable codebase lifecycle