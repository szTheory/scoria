# Phase 27: MCP Server-Sent Events (SSE) Boundary - Validation

This document maps the phase success criteria to observable test commands.

## Success Criteria 1: An external agent can establish an SSE connection to a Scoria Phoenix endpoint.

**Validation Command:**
```bash
mix test test/scoria_web/controllers/mcp_controller_test.exs
```

**Expected Outcome:**
The test verifies that a `GET` request to the `/sse` route returns a 200 OK with `content-type: text/event-stream` and issues an initial `endpoint` event containing the session ID.

## Success Criteria 2: Scoria can stream MCP standard JSON-RPC payloads to the connected agent.

**Validation Command:**
```bash
mix test test/scoria_web/controllers/mcp_controller_test.exs
```

**Expected Outcome:**
The test verifies that when the server streams data through the SSE chunked connection, the payload conforms to the JSON-RPC 2.0 specification and is successfully received by the client process.

## Success Criteria 3: The agent can respond and invoke a Scoria-registered tool over HTTP/SSE.

**Validation Command:**
```bash
mix test test/scoria_web/controllers/mcp_controller_test.exs
```

**Expected Outcome:**
The test verifies that:
1. A valid JSON-RPC request posted to the `/messages` route with the correct `session_id` returns a 202 Accepted.
2. The payload is successfully routed to the running SSE connection process.
3. The server parses the payload, executes the appropriate tool via `Scoria.MCP.Executor.execute`, and streams a properly formatted JSON-RPC 2.0 response back to the client over the SSE connection.

## Complete Phase Validation

To verify the complete functionality for this phase, run the entire test suite to ensure no regressions were introduced.

```bash
mix test
```