# Phase 27: MCP Server-Sent Events (SSE) Boundary - Deep Architectural Analysis & Decision

## 1. Context and Goals
**Goal**: External Python and Node runtimes can connect to Scoria over HTTP/SSE and invoke tools securely.
**Requirement**: OUTRIDER-01 (MCP SSE Boundary)
**Context**: Scoria is an Elixir/Phoenix-native AI operations library. We need to implement the Model Context Protocol (MCP) Server specification via Server-Sent Events (SSE), allowing external agents (like a local Python script or a Node.js runtime) to connect, discover available tools, and invoke them over an HTTP transport.

## 2. Lessons Learned from the Ecosystem & Elixir Context

### The MCP SSE Specification
The MCP specification defines SSE as a transport layer:
1. **Connection**: The client makes a `GET` request to the SSE endpoint.
2. **Initialization**: The server establishes the SSE connection and emits an `endpoint` event containing a URI (e.g., `/mcp/messages?session_id=...`).
3. **Communication**: The client sends JSON-RPC messages via `POST` to the provided URI.
4. **Responses**: The server processes the `POST` requests and sends the JSON-RPC responses back through the open SSE connection.

### Elixir/Phoenix Advantages & Footguns
- **Pros**: Phoenix and the BEAM are uniquely suited for long-lived connections (like SSE). A `Plug.Conn` can easily be held open, or we can use `Bandit`'s native chunking or long-poll techniques.
- **Footguns**: 
  - **State Management**: The `POST` request and the `GET` (SSE) request are handled by two different Elixir processes. We must reliably route messages from the POST process to the SSE process.
  - **Connection Drops**: If the client disconnects, we need to clean up any associated session state to avoid memory leaks.
  - **Timeouts**: Default HTTP timeouts might kill the SSE connection prematurely. We need to configure the server to allow long-lived connections for these specific routes.

## 3. Analysis of Proposed Architectural Approaches

### Approach A: PubSub / Registry for Process Routing
- **Concept**: Use `Registry` (or `Phoenix.PubSub`) to track active SSE connection processes. 
  1. The `GET /mcp/sse` controller action generates a `session_id`, registers itself in `Registry.Scoria.MCPSessions`, sends the `endpoint` event to the client, and enters a recursive receive loop using `Plug.Conn.chunk/2`.
  2. The `POST /mcp/messages` action receives the `session_id`, looks up the PID in the Registry, and sends an Elixir message (`send(pid, {:mcp_message, json_rpc_request})`) to the SSE process.
  3. The SSE process handles the JSON-RPC request (via `Scoria.MCP.Executor`) and chunks the response back.
- **Pros**: 
  - Idiomatic Elixir. The `Registry` is fast and built-in.
  - Keeps the SSE connection process as the single source of truth for the session state.
- **Cons**: 
  - Holding a `Plug.Conn` open with a recursive receive loop is slightly manual but standard practice for SSE in Phoenix without WebSockets.

### Approach B: GenServer per Session
- **Concept**: The `GET /mcp/sse` endpoint spawns a dedicated `GenServer` for the session and hands off the socket/connection state.
- **Pros**: Clean state management via GenServer callbacks.
- **Cons**: Overkill for a simple SSE loop. A recursive function in the controller holding the `Plug.Conn` is usually sufficient for SSE, and reduces process indirection.

## 4. One-Shot Recommendations for Phase 27

**Decision:** We will adopt **Approach A (Registry-based Process Routing with Controller Receive Loop)**. It leverages Elixir's strengths (lightweight processes and fast local pubsub/registry) to implement the disconnected POST/SSE pattern required by the MCP specification.

### 4.1 Registry Setup
Define `Scoria.MCP.SessionRegistry` using Elixir's `Registry` (keys: unique, name: `Scoria.MCP.SessionRegistry`). This registry will be started in the Scoria application tree.

### 4.2 SSE Controller (`ScoriaWeb.MCPController`)
Implement the SSE initialization and message routing:

1.  **`GET /mcp/sse`**:
    *   Generates a unique `session_id` (e.g., UUID).
    *   Registers the current process in `Scoria.MCP.SessionRegistry` under `session_id`.
    *   Calls `Plug.Conn.send_chunked(conn, 200)` and sets the appropriate headers (`content-type: text/event-stream`, `cache-control: no-cache`).
    *   Sends the initial `endpoint` event: `event: endpoint\ndata: /mcp/messages?session_id=<session_id>\n\n`.
    *   Enters a recursive `listen_loop(conn)` that waits for Elixir messages.
2.  **`listen_loop(conn)`**:
    *   Uses `receive do` to wait for messages from the POST endpoint or internal execution results.
    *   On receiving a JSON-RPC response, formats it as an SSE data payload (`data: <json>\n\n`) and uses `Plug.Conn.chunk(conn, payload)`.
    *   Handles connection closure gracefully.

### 4.3 Message Ingestion
1.  **`POST /mcp/messages`**:
    *   Requires `session_id` query param.
    *   Looks up the PID for `session_id` in `Scoria.MCP.SessionRegistry`.
    *   If found, asynchronously sends the parsed JSON-RPC payload to the PID and immediately responds to the POST request with `202 Accepted` (as per MCP spec, though HTTP 200 is also common; SSE responses arrive on the other channel).
    *   If not found, responds with `404 Not Found` or `400 Bad Request`.

### 4.4 Router Configuration
Expose the endpoints in `ScoriaWeb.Router` or instruct operators on how to mount them in their host application router. Since Scoria is an engine/library, we will likely provide a router macro or standard controller that operators can forward to, similar to `Phoenix.LiveDashboard`.

```elixir
scope "/mcp", ScoriaWeb do
  pipe_through :api
  get "/sse", MCPController, :sse
  post "/messages", MCPController, :messages
end
```

### 4.5 Security & Authentication (Future-Proofing)
While this phase focuses on the boundary, we must ensure it's extensible for auth. The `POST` endpoint must verify that the incoming message belongs to the session. Since the POST payload is sent via a separate HTTP request, it might lack the initial headers from the GET request. Relying on the `session_id` as an unguessable bearer token (UUIDv4) is standard for this specific flow in the MCP spec, provided the channel is HTTPS.

## Summary
By using `Plug.Conn.send_chunked/2` and Elixir's `Registry` to bridge the gap between the `GET` (SSE) process and the `POST` (message) process, we can build a robust, idiomatic, and highly concurrent MCP SSE boundary that perfectly satisfies OUTRIDER-01.