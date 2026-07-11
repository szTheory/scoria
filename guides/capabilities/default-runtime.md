# Default Runtime

The default runtime is the first Scoria capability to wire into a Phoenix app. It proves the boring path first: `identity -> start -> inspect -> resume`, with host-owned identity, durable Scoria runs, approval pauses, reviewer traces, and one verification suite.

Use this guide with [Getting Started](guides/getting-started.md), [Golden Path](guides/golden-path.md), [Ownership Boundary](guides/ownership-boundary.md), and the [glossary](guides/reference/glossary.md).

The default runtime does not require an optional knowledge base, semantic cache setup, connector setup, pgvector bootstrap, retrieval setup, or a hosted onboarding service. Add those capabilities only after the default runtime already works in your host app.

## What this capability is for

Choose the default runtime when you need:

- canonical actor, tenant, and session identity
- durable runs with exact `run_id` resume
- approval pauses and reviewer traces
- one public facade for `identity -> start -> inspect -> resume`
- a reviewer trace page at `/scoria/workflows/:run_id`

Core APIs:

- `Scoria.identity/1`
- `Scoria.start_run/2`
- `Scoria.get_run/1`
- `Scoria.get_run_detail/1`
- `Scoria.resume_run/2`
- `Scoria.list_runs_for_session/1`

When you later add bounded handoffs, the same public readback path exposes delegated lineage:

```elixir
{:ok, detail} = Scoria.get_run_detail(run_id)
delegated = detail.delegated_handoffs
```

## Host-authenticated dashboard scope

The host app authenticates the reviewer and asserts dashboard tenant scope. Scoria records and reads that scope; query params do not choose tenants.

Mount the dashboard behind your own Phoenix authentication and membership checks:

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

`scope_resolver:` may be a module implementing `ScoriaWeb.DashboardScope.Resolver` or an MFA tuple. Return `{:ok, %{tenant_id: current_account.id, actor_id: current_user.id}}` after the host has already authenticated the reviewer and checked tenant membership. Authorization remains delegated to the host; Scoria does not introduce a role model.

The bare `scoria_dashboard "/scoria"` form still compiles for compatibility. It uses the session-backed default resolver, so host apps can provide the same tenant and actor keys in the session:

```elixir
conn
|> put_session("tenant_id", conn.assigns.current_account.id)
|> put_session("actor_id", conn.assigns.current_user.id)
```

`$ mix scoria.install` does not inject auth hooks, authorization policy, role values, or session keys. Those are host-owned nouns. Scoria owns the dashboard scope seam and trusted scope record.

## Start a run

Start from a normal Phoenix controller action. Normalize the Phoenix edge state first, then call the top-level `Scoria` facade.

```elixir
defmodule MyAppWeb.AssistantController do
  use MyAppWeb, :controller

  def create(conn, %{"prompt" => prompt}) do
    identity =
      Scoria.identity(%{
        actor_id: conn.assigns.current_user.id,
        tenant_id: conn.assigns.current_account.id,
        session_id: get_session(conn, :assistant_session_id),
        metadata: %{"channel" => "web"}
      })

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "executor",
        initial_step: %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        },
        runtime: [
          metadata: %{"payload" => %{"prompt" => prompt}}
        ],
        handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
      )

    conn
    |> put_session(:last_scoria_run_id, started.run_id)
    |> redirect(to: ~p"/assistant/runs/#{started.run_id}")
  end
end
```

If identity already lives in assigns or session maps, `Scoria.Identity.from_conn_assigns/1` and `Scoria.Identity.from_session/1` can make the edge boundary clearer. The important contract is that the host hands Scoria one normalized identity before the run starts.

## `session_id` is not `run_id`

Use `session_id` to group related turns in your host app. Use `run_id` to inspect or resume one exact Scoria execution.

- same conversation, new turn: reuse `session_id`, create a fresh run
- paused run: resume only by its exact `run_id`

Persist `started.run_id` anywhere your host app already tracks ongoing work: session, database row, job record, or conversation table. That `run_id` is the exact handle for:

- `Scoria.get_run/1`
- `Scoria.get_run_detail/1`
- `Scoria.resume_run/2`
- `/scoria/workflows/:run_id`

Do not try to resume from `session_id` alone.

## Inspect and resume

Your app can inspect one run directly or list all runs that share the same `session_id`:

```elixir
{:ok, summary} = Scoria.get_run(run_id)
{:ok, detail} = Scoria.get_run_detail(run_id)
same_session_runs = Scoria.list_runs_for_session(session_id)
```

`detail.delegated_handoffs` is available when a bounded handoff branch exists for the same run. The default runtime does not require handoffs, but it gives the host the durable handle that later handoffs reuse.

When an approval pauses the run, resume with the exact `run_id`:

```elixir
{:ok, resumed} =
  Scoria.resume_run(run_id,
    decision: "approved",
    actor_id: current_user.id
  )
```

Link reviewers to the trace for the same durable run:

```elixir
redirect(conn, to: ~p"/scoria/workflows/#{run_id}")
```

Treat that page as a reviewer trace, not as your product's business-truth surface.

## Optional expansions

Keep the default runtime boring before adding optional capabilities:

- [Bounded Handoffs](guides/capabilities/bounded-handoffs.md) when one role truly needs same-run delegation.
- [Semantic Cache](guides/capabilities/semantic-cache.md) when safe read-only reuse is worth the compatibility and lifecycle checks.
- Optional knowledge base setup when retrieval, citations, and grounding are part of your product.
- [Connectors and MCP](guides/capabilities/connectors-and-mcp.md) when remote tool surfaces are part of your product.

These are capability additions, not first-run prerequisites. The optional knowledge base is separate from the semantic cache: the knowledge base owns retrieval, citations, and grounding; semantic cache owns conservative reuse of explicitly safe read-only answers.

## Verification

Run the canonical default runtime verification suite:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

`$ mix test.adoption` does not require semantic cache setup, optional knowledge base setup, connector setup, pgvector bootstrap, retrieval setup, or a hosted control plane.

After the default runtime is proven, use capability-specific verification suites only for the capability you intentionally add:

- `$ mix test.runtime_to_handoff` for bounded runtime-to-handoff escalation
- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path` for semantic cache behavior
- `$ mix test.knowledge` for optional knowledge base behavior
- `$ mix test.connector` for remote connector behavior

Start narrow. Expand only when the current capability already feels boring.
