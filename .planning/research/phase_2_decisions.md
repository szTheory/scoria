# Phase 2 Architectural Decisions: MCP Gateway & Tool Governance

This document establishes the architectural strategy for two critical gray areas in Phase 2 of the Scoria project. It draws upon the "szTheory Elixir DNA," standard Phoenix idioms, and lessons learned from the broader AI and Elixir ecosystems.

## 1. MCP Transport: Bespoke Plug Endpoint vs. External Dependency

**The Gray Area:** Should Scoria add an external MCP library like `emcp` or `anubis` as a dependency to handle the protocol, or build a bespoke JSON-RPC Plug endpoint from scratch?

### Ecosystem Lessons & Tradeoffs
*   **External Dependencies (`emcp`, `anubis`):** These libraries successfully abstract away the boilerplate of JSON-RPC 2.0 and the Model Context Protocol specs (framing, SSE vs. STDIO transport). However, external libraries typically enforce their own OTP execution models (e.g., synchronously calling a function when a tool is invoked).
*   **The Scoria Differentiator:** Scoria's primary value proposition is not just speaking MCP, but **governing** it. This requires strict OTP isolation (e.g., `Task.yield` for timeouts), rigorous Ecto changeset validation *before* execution, and crucially, **Human-In-The-Loop (HITL) approval suspension**. Pausing a tool invocation to wait for a human via a LiveView modal requires deep control over the process lifecycle and the HTTP/SSE connection. Fighting an external library's execution loop to implement this suspension is a massive footgun.

### Architectural Recommendation: Bespoke JSON-RPC Plug (`Scoria.MCP.Router`)
**Decision:** We will build a bespoke JSON-RPC Plug endpoint from scratch. Scoria will **not** take a hard dependency on `emcp` or `anubis`.

**Rationale & Ergonomics:**
1.  **Protocol Simplicity:** The MCP HTTP transport is simply JSON-RPC 2.0 over standard POST requests and Server-Sent Events (SSE). Parsing JSON-RPC is trivial in Elixir using `Plug.Conn` and standard JSON decoding.
2.  **Ultimate Control:** By owning the Plug pipeline, we can trivially intercept the request, perform our policy checks, spawn an isolated `Task`, and hold the SSE connection open indefinitely while waiting for an asynchronous PubSub event (the HITL approval) before returning the tool result.
3.  **The "Conn" Pattern:** A bespoke Plug allows us to leverage the standard `%Plug.Conn{}` lifecycle, seamlessly passing HTTP headers, connection assigns, and actor contexts directly into the tool execution boundaries.

*Verdict: The maintenance burden of parsing JSON-RPC is vastly lower than the friction of retrofitting async HITL approvals and custom OTP sandboxing into an opinionated third-party MCP SDK.*

## 2. External Ecosystem Boundaries: Sigra & Threadline

**The Gray Area:** The requirements mandate injecting actor context via "Sigra" and audit logging via "Threadline." Are these internal modules we need to stub out, or external systems we integrate with? How do we architect this boundary?

### Ecosystem Lessons & Tradeoffs
*   **The "Unix Philosophy" DNA:** The szTheory ecosystem demands that libraries do one thing exceptionally well and compose cleanly ("SaaS in a Box"). Hardcoding dependencies on `Sigra` (auth) or `Threadline` (audit) inside Scoria would couple them tightly, violating this philosophy and making Scoria unusable for the broader OSS Elixir community.
*   **Idiomatic Phoenix:** The best Phoenix libraries (like Oban Web or LiveDashboard) do not dictate *how* you authenticate; they dictate the *contract* they expect.

### Architectural Recommendation: Decoupled Integration via Idiomatic Contracts
**Decision:** `Sigra` and `Threadline` are **external systems**. Scoria will not build them, stub them, or take them as hex dependencies. Instead, Scoria will rely on standard Elixir/Phoenix integration patterns (Plug Assigns and Telemetry) to establish a frictionless boundary.

**Rationale & Ergonomics:**
1.  **Actor Context (The Sigra Boundary):** 
    Scoria will rely on the standard Plug `conn.assigns` pattern. We assume that the host Phoenix application has a router pipeline that handles authentication (via Sigra or any other tool). 
    ```elixir
    # Host App Router
    pipeline :mcp_auth do
      plug Sigra.Plug.Authenticate
      plug :put_actor_assign
    end

    scope "/mcp" do
      pipe_through [:api, :mcp_auth]
      # Scoria expects `conn.assigns.current_actor` to be populated here.
      forward "/", Scoria.MCP.Router 
    end
    ```
    This completely decouples Scoria from Sigra while fulfilling the requirement perfectly. Scoria's policy engine simply checks `conn.assigns.current_actor` and passes it into the execution context.

2.  **Audit Logging (The Threadline Boundary):**
    Scoria will not write audit logs directly. Instead, Scoria will emit rich, structured `:telemetry` events for every significant action.
    ```elixir
    :telemetry.execute(
      [:scoria, :tool, :approved],
      %{duration: 120},
      %{tool: "create_refund", actor_id: "usr_123", trace_id: "..."}
    )
    ```
    In the host application, a `Threadline` telemetry handler can attach to these events and route them to the audit log. This provides comprehensive intent tracing without Scoria needing to know Threadline exists.

*Verdict: Rely on the host app's Plug pipeline to inject the actor, and rely on `:telemetry` to export the audit trail. This perfectly satisfies the "SaaS in a Box" integration requirements while keeping Scoria pure, composable, and OSS-ready.*