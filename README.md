# Scoria

[![CI](https://github.com/szTheory/scoria/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scoria/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.19%2B-4B275F.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7%2B-FD4F00.svg)](https://www.phoenixframework.org/)

Scoria is the Phoenix-native runtime and operator surface for identity-aware AI runs. It gives a host app one public place to normalize actor, tenant, and session identity, start durable runs, resume an exact paused run by `run_id`, and inspect operator evidence at `/scoria` without turning the dashboard into the app's source of business truth.

## Install

Add it as a GitHub dependency for now:

```elixir
def deps do
  [
    {:scoria, github: "szTheory/scoria"}
  ]
end
```

Then mount the dashboard in your Phoenix router and run the install task:

```bash
mix scoria.install
```

That installs the default Phoenix lane. The operator dashboard mounts at `/scoria`.

## Quickstart

The host app entrypoint is `Scoria`.

```elixir
identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :chat_session_id)
  })

{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
  )

store_run_id_somewhere(started.run_id)
```

`session_id` is the host-owned continuity key for a conversation or workflow thread. `run_id` is the exact durable Scoria execution handle for one run. Reuse the same `session_id` when the user comes back for another turn, but resume a paused run only by its exact `run_id`.

When a run pauses or completes, inspect it through the same public facade:

```elixir
{:ok, summary} = Scoria.get_run(started.run_id)
same_session_runs = Scoria.list_runs_for_session(identity.session_id)
```

If the run is waiting on approval, resume that exact run after the decision is recorded:

```elixir
{:ok, resumed} =
  Scoria.resume_run(started.run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

The operator evidence page for that same run lives at `/scoria/workflows/:run_id`. Use it to inspect what happened in Scoria; keep your host app as the owner of user-facing business truth.

Starting a new turn in the same conversation means reusing `session_id` and creating a fresh run:

```elixir
{:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

next_run.session_id == started.session_id
next_run.run_id != started.run_id
```

## Verification

Default Phoenix lane:

```bash
mix ecto.migrate
mix test
```

Then prove the core lane with one real run from your app, read it back through `Scoria.get_run/1` or `Scoria.list_runs_for_session/1`, and inspect `/scoria/workflows/:run_id` for operator evidence. The dedicated operator verification guide lives in [`docs/operator_verification.md`](docs/operator_verification.md).

Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix scoria.test.knowledge
```

The knowledge lane does not require `pgvector`, knowledge tables, retrieval, grounding, or `mix scoria.test.knowledge` to prove the core runtime, identity, approval, and operator-evidence path.

## Phoenix Example

For one end-to-end controller-triggered adoption story, see [`docs/phoenix_runtime_example.md`](docs/phoenix_runtime_example.md). It follows the same public facade and `session_id`/`run_id` rules proven in the runtime integration suite.

## What Scoria Adds

- OpenInference-style trace capture and redaction
- durable workflows, handoffs, and recovery
- pgvector-backed knowledge, citations, and grounding checks
- a trace-first LiveView surface for operators

## Status

Scoria is actively evolving. Keystone work has already landed in the runtime, identity, and install surfaces; this phase aligns the public docs with that shipped API.
