# Getting Started

Scoria is an Elixir/Phoenix library you add to an existing Phoenix app to run AI/LLM work durably and inspectably. Every run - one execution such as a prompt render, model call, tool call, retrieval, approval, or eval score - is recorded as a queryable Postgres/Ecto trace. A mounted LiveView dashboard at `/scoria` lets a human reviewer inspect, debug, approve, and resume that work. Scoria runs inside your app's BEAM and database boundary; it is not a hosted SaaS agent platform.

Use this guide when you want the shortest path from a Phoenix app to one visible Scoria run. The deeper first-run walkthrough is [Golden Path](guides/golden-path.md), ownership details live in [Ownership Boundary](guides/ownership-boundary.md), and terminology lives in the [Glossary](guides/reference/glossary.md).

## What You Install

Start with the default runtime capability. It proves identity-aware durable runs, approvals, and reviewer traces with `mix test.adoption`.

Optional capabilities come later:

- [bounded handoffs](capabilities/bounded-handoffs.md) for narrow same-run delegation
- [semantic cache](capabilities/semantic-cache.md) for safe read-only reuse
- [optional knowledge base](capabilities/default-runtime.md#optional-knowledge-base) for retrieval and grounding
- [connectors and MCP](capabilities/connectors-and-mcp.md) when remote tools are part of your product

The default runtime does not require knowledge setup, semantic cache setup, connector setup, pgvector bootstrap, or a hosted onboarding service.

## Install The Hex Package

Add Scoria to your Phoenix app:

```elixir
def deps do
  [
    {:scoria, "~> 0.1", hex: :scoria}
  ]
end
```

Then fetch dependencies:

```bash
mix deps.get
```

## Run The Installer

Run the installer from the host Phoenix app:

```bash
mix scoria.install
```

That installer wires the default Phoenix capability by:

- mounting the reviewer dashboard at `/scoria`
- copying Scoria's core Ecto migrations into `priv/repo/migrations`
- injecting baseline runtime defaults into `config/runtime.exs` or `config/config.exs`

For existing apps, preview and check before applying:

```bash
mix scoria.install --dry-run
mix scoria.install --check
```

The no-write modes are part of the upgrade-safe install capability. The maintainer details live in [Reviewer Verification](reviewer-verification.md).

## Run Migrations

Run your normal host migration command after the installer copies Scoria migrations:

```bash
mix ecto.migrate
```

Scoria stores durable run records, trace events, approval state, eval evidence, and dashboard evidence inside your app's database boundary. Your Phoenix app still owns its own customer, ticket, order, account, and domain records.

## Mount The Dashboard Behind Host Scope

The dashboard must sit behind host-authenticated scope in real apps. Scoria supplies the dashboard seam; your Phoenix app owns authentication, authorization, tenant membership, role values, and policy values.

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

Your resolver should return trusted tenant and actor values only after your app has authenticated the reviewer and checked membership. Query params do not choose tenants for the Scoria dashboard.

## Create The First Identity

Normalize Phoenix edge state before starting a run:

```elixir
identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })
```

`session_id` is the host-owned continuity key for a conversation or workflow thread. `run_id` is the exact durable Scoria execution handle for one run. Reuse the same `session_id` for another turn in the same conversation; resume a paused execution only by its exact `run_id`.

## Start The First Run

Start one durable run through the public facade:

```elixir
{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
  )
```

Persist `started.run_id` anywhere your host app tracks ongoing work: session, database row, job record, or conversation table.

## Inspect And Resume

Read back the exact run:

```elixir
{:ok, summary} = Scoria.get_run(started.run_id)
same_session_runs = Scoria.list_runs_for_session(identity.session_id)
```

Open the reviewer trace page for the same run:

```text
/scoria/workflows/:run_id
```

If the run pauses for approval, resume that exact run:

```elixir
{:ok, resumed} =
  Scoria.resume_run(started.run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

## Verify The Default Capability

The default runtime verification suite is:

```bash
mix test.adoption
```

For release packaging and docs inventory, maintainers use:

```bash
mix scoria.release_preview
```

The full first-run sequence is [Golden Path](guides/golden-path.md). If a boundary is unclear, check [Ownership Boundary](guides/ownership-boundary.md) before adding optional capabilities.
