# Research Report: MCP Integration and Agent Tool Workflows

**Project:** Scoria (Phoenix-native AI ops layer)
**Focus:** Model Context Protocol (MCP), Agents, Tool Governance, HITL, Secure Execution

## Executive Summary
Integrating the Model Context Protocol (MCP) into a Phoenix application requires establishing a firm security boundary between the LLM model and internal host systems. For Scoria, the "MCP Gateway" acts as a policy-enforced proxy. This research explores current Elixir MCP libraries and outlines an idiomatic Phoenix architecture for secure tool execution, human-in-the-loop (HITL) approvals, and robust governance based on OTP and Plug patterns.

## Current Elixir/Phoenix MCP Ecosystem
The Elixir ecosystem provides several foundational libraries for building MCP servers and clients:
- **Anubis (formerly Hermes):** A comprehensive MCP implementation for Elixir that supports multiple transports (SSE, HTTP, STDIO) and integrates deeply with Phoenix.
- **emcp:** A specialized MCP server library that uses a "Plug-like" approach, allowing the passing of the `conn` (connection) directly into tool callbacks. This is highly beneficial for authentication and session binding.
- **ElixirMcpServer:** A lightweight, standard JSON-RPC 2.0 compliance framework.

*Recommendation for Scoria:* Wrap or adapt the concepts from Anubis or emcp, prioritizing the Plug-based HTTP/SSE transport (`emcp` style) to bind tool calls to authenticated Phoenix sessions and actor context (via Sigra).

## MCP Gateway Architecture in Scoria
Based on the szTheory DNA and the `phoenix-ai-lib-deep-research.md` document, Scoria must clearly separate LiveView UI transport from MCP protocol transport.

1. **Protocol Separation:**
   - **Phoenix LiveView/WebSockets:** Used strictly for the operator dashboard, trace explorer, approval modals, and streaming chat UI.
   - **Plug/Streamable HTTP:** Used for the actual MCP Gateway endpoint (`Scoria.MCP.Router`). This endpoint handles JSON-RPC for external MCP clients/servers over standard POST/GET with SSE responses.
2. **Gateway Responsibilities:**
   - **Origin Validation:** Essential for HTTP transports to prevent DNS rebinding risks.
   - **Authentication:** Token-based (API key or OAuth/OIDC via Lockspire).
   - **Registry:** Maps exposed resources, prompts, and tools.
   - **Audit & Policy Check:** Intercepts every invocation before execution to apply RBAC and logging.

```elixir
# Example Architecture Route
scope "/mcp" do
  pipe_through [:api, :mcp_auth] # Injects actor context
  forward "/", Scoria.MCP.Router
end
```

## Tool Governance and Secure Execution Patterns
Security must prevent the AI from acting as a "confused deputy." Scoria will implement this through three layers:

### 1. The "Conn" Pattern & Actor Context
Tool execution must be intrinsically tied to the authenticated user.
- Pass the `actor_id` and `tenant_id` into the tool execution context `ctx`.
- Tools utilize existing application authorization libraries (e.g., Bodyguard, or Scoria's own `ToolPolicy`) to determine if the actor has permission.

### 2. Strict Schema Validation & Ecto
- Tool arguments must be strictly validated against JSON Schemas before the tool's Elixir function is called.
- For write operations, Ecto changesets are used to prevent injection and enforce domain constraints.

### 3. OTP-based Sandboxing
- **Process Isolation:** Every tool invocation runs in its own isolated Erlang process (via `Task` or `GenServer`). If a tool crashes from bad input, it does not bring down the AI session or the Phoenix node.
- **Timeouts:** Wrap tool execution in `Task.yield/2` to enforce rigid execution limits, avoiding infinite loops or resource starvation caused by LLM hallucinations.

## Human-in-the-Loop (HITL) and Approval Workflows
High-risk tools (e.g., `external_write`, `financial_action`) require explicit human intervention.

1. **Side-Effect Classification:** Tools declare their side-effect level:
   `side_effect: :read_only | :internal_write | :external_write | :financial_action`
2. **Approval Suspension Loop:**
   - When an LLM requests a high-risk tool call, the MCP Gateway intercepts it.
   - The run state transitions to `waiting_for_approval`.
   - A `ToolApproval` record is created in Ecto, emitting a telemetry/PubSub event.
   - The LiveView Operator Dashboard (or the user's chat UI) listens for this event and displays an approval modal.
   - The LLM stream is paused (using Elixir's receive blocks or bounded queues).
   - Upon `Approve` or `Deny`, the decision is fed back into the process, and the trace records the human intervention.

## Observability and Audit Logging
- **Tracing & Telemetry:** Every tool invocation (`start`, `approval_requested`, `stop`, `exception`) emits structured telemetry events, persisting as spans inside the Ecto trace store.
- **Redaction by Default:** To comply with data privacy, raw prompt payloads and sensitive tool arguments are redacted based on tenant policies before being saved to the database or exported via OpenTelemetry.

## Conclusion
Scoria's approach to MCP and tool governance should avoid reinventing protocol plumbing and instead focus on wrapping standard transports (like Anubis/emcp) with an opinionated, Ecto-backed, OTP-isolated policy engine. The primary differentiator will be the seamless pausing of GenServers for LiveView HITL approvals and the exhaustive auditing of tool traces tied to authenticated actors.