# Golden Path

The first Scoria adoption path is intentionally boring: `identity -> start -> inspect -> resume`.

Use this guide after [Getting Started](guides/getting-started.md) when you want one copyable Phoenix flow that proves the default runtime capability before optional features. Terminology lives in the [Glossary](guides/reference/glossary.md), and the ownership split lives in [Ownership Boundary](guides/ownership-boundary.md).

Start with the default runtime capability. This is the baseline proof before bounded handoffs, semantic cache, optional knowledge, or remote connectors.

## Capability Ladder

Default runtime capability comes first: `identity -> start -> inspect -> resume` with `mix test.adoption`.
Bounded handoff capability follows only when same-run delegation is needed; use `Scoria.start_handoff_run/3` and prove it with `mix test.runtime_to_handoff`.
Semantic cache capability follows only for safe read-only reuse; define it with `use Scoria.SemanticCache.Profile`, wire it as `semantic_cache: [profile: MyApp.AI.AccountFaqCache]`, and prove it with `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path`.
Optional knowledge base capability is for retrieval, citations, and grounding; prove it with `mix test.knowledge`.
Remote connector capability is for MCP registration and reviewer-visible trace evidence; prove it with `mix test.connector`.

Compatibility note: old links may still mention `connector_adoption.md` while copied docs move toward [Connectors and MCP](guides/capabilities/connectors-and-mcp.md). The embedded-boundary framing stays the same: host apps own business meaning and Scoria owns durable runtime evidence. This capability is explicitly optional.

Start narrow. Expand only when the current capability already feels boring.

## The Path

1. Build one host-owned `Scoria.Identity`.
2. Start one durable run with `Scoria.start_run/2`.
3. Inspect that exact run with `Scoria.get_run/1`, `Scoria.list_runs_for_session/1`, and `/scoria/workflows/:run_id`.
4. Resume the same run with `Scoria.resume_run/2` if it pauses for approval.

That is the whole `identity -> start -> inspect -> resume` loop.

## What This Does Not Require

The default runtime does not require:

- semantic cache setup
- optional knowledge base setup
- connector or MCP setup
- pgvector bootstrap
- hosted onboarding
- LiveView-first orchestration
- direct workflow internals as the normal app entrypoint

Start here even if you plan to add those capabilities later.

For the next capability, add bounded handoffs only after this path is green. The runtime-to-handoff proof is:

```bash
mix test.runtime_to_handoff
```

The default boundary still applies: This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

## Step 1: Build Identity

Start from normal Phoenix request state and pass Scoria one normalized identity:

```elixir
identity =
  Scoria.identity(%{
    actor_id: conn.assigns.current_user.id,
    tenant_id: conn.assigns.current_account.id,
    session_id: get_session(conn, :assistant_session_id),
    metadata: %{"channel" => "web"}
  })
```

`session_id` groups related host turns. `run_id` names one exact Scoria execution.

Use the same `session_id` when a user returns to the same conversation. Use the exact `run_id` when you need to inspect or resume one durable execution.

## Step 2: Start A Run

Call the top-level `Scoria` facade from your Phoenix controller, LiveView, Oban job, or service module:

```elixir
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
      metadata: %{
        "payload" => %{"prompt" => prompt}
      }
    ],
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
  )
```

Store `started.run_id` in your host app. It is the durable handle for this execution.

## Step 3: Inspect The Same Run

Read back one run by exact ID:

```elixir
{:ok, summary} = Scoria.get_run(started.run_id)
```

List related runs by host session:

```elixir
same_session_runs = Scoria.list_runs_for_session(identity.session_id)
```

Open the reviewer trace for the same execution:

```text
/scoria/workflows/:run_id
```

Treat the dashboard as a reviewer trace, not as your product's system of record. Your Phoenix app owns the customer, ticket, account, order, prompt intent, success definition, expected output, and business meaning.

Authorization remains delegated to the host; Scoria does not introduce a role model. If the host-authenticated scope resolver rejects a session, the dashboard fails closed with: This Scoria dashboard is not available for this session.

## Step 4: Resume A Paused Run

If a run pauses for approval, resume that exact `run_id`:

```elixir
{:ok, resumed} =
  Scoria.resume_run(started.run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

The resumed run keeps the same `run_id`. Starting a later turn in the same conversation reuses `session_id` and creates a fresh `run_id`.

```elixir
{:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

next_run.session_id == started.session_id
next_run.run_id != started.run_id
```

## Dashboard Scope Footgun

The host app authenticates the reviewer and asserts dashboard tenant scope. Query params do not choose tenants for the dashboard.

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

The runtime identity you pass to `Scoria.start_run/2` should use the same trusted `tenant_id` that your dashboard scope resolver returns, or live trace and approval updates will not line up in the reviewer UI.

The bare `scoria_dashboard "/scoria"` form still compiles for generated/dev/example mounts through the session-backed default resolver. Authenticated host apps should prefer explicit `on_mount:` and `scope_resolver:` wiring.

For install verification, use Check vs apply guardrails: run `mix scoria.install --dry-run`, then `mix scoria.install --check`, and only apply when `--check` reports the expected host surface state.

## Verification

Run the default runtime verification suite after install and migrations:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Adoption closeout exercises a packaged tarball from `mix hex.build --unpack`; it does not rely only on a monorepo path dependency. The maintainer details live in [Reviewer Verification](reviewer-verification.md).

The reviewer verification guide is packaged at [Reviewer Verification](guides/reviewer-verification.md).

## Where To Go Next

- [JTBD and User Flows](guides/jtbd-and-user-flows.md) maps the capability ladder and reviewer workflow.
- [Ownership Boundary](guides/ownership-boundary.md) explains what Scoria owns versus what your app owns.
- [Default Runtime](guides/capabilities/default-runtime.md) expands this path into the capability guide.
- [Glossary](guides/reference/glossary.md) defines final public vocabulary and 0.1.x compatibility aliases.
