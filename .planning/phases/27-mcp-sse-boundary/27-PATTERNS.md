# Phase 27: MCP Server-Sent Events (SSE) Boundary - Pattern Map

**Mapped:** 2024-05-19
**Files analyzed:** 3
**Analogs found:** 2 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/controllers/mcp_controller.ex` | controller | streaming | `lib/scoria_web/controllers/connector_auth_controller.ex` | role-match |
| `lib/scoria_web/router.ex` | router | config | `lib/scoria_web/router.ex` | exact |
| `lib/scoria/mcp/session_registry.ex` | registry | event-driven | No Analog Found | N/A |

## Pattern Assignments

### `lib/scoria_web/controllers/mcp_controller.ex` (controller, streaming)

**Analog:** `lib/scoria_web/controllers/connector_auth_controller.ex`

**Imports pattern** (lines 1-4):
```elixir
defmodule ScoriaWeb.ConnectorAuthController do
  use Phoenix.Controller, formats: [:html]

  import Plug.Conn
```

**Controller Action pattern** (lines 8-20):
```elixir
  def start(conn, %{"connector_id" => connector_id} = params) do
    # ... logic ...

    conn
    |> put_session(AuthState.session_key(connector_id), auth_state)
    |> redirect(external: authorization_url)
  end
```

---

### `lib/scoria_web/router.ex` (router, config)

**Analog:** `lib/scoria_web/router.ex`

**Macro routing pattern** (lines 7-16):
```elixir
  defmacro scoria_dashboard(path, _opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]
        import Phoenix.Router, only: [get: 3]

        get("/connectors/:connector_id/auth/start", ScoriaWeb.ConnectorAuthController, :start)
```

---

## Shared Patterns

### SSE Chunking Pattern
**Source:** `.planning/research/07-outrider-ARCHITECTURE.md`
**Apply to:** `lib/scoria_web/controllers/mcp_controller.ex`
```elixir
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> send_chunked(200)
    # Loop and stream JSON-RPC payload chunks
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/scoria/mcp/session_registry.ex` | registry | event-driven | Scoria does not currently use Elixir's native `Registry` module for ephemeral session tracking. The planner should implement a standard `Registry` and add it to the application supervision tree. |

## Metadata

**Analog search scope:** `lib/scoria/**/*.ex`, `lib/scoria_web/**/*.ex`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-19