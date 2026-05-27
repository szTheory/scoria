# Scoria

[![CI](https://github.com/szTheory/scoria/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scoria/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.19%2B-4B275F.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7%2B-FD4F00.svg)](https://www.phoenixframework.org/)

Scoria is the Phoenix-native runtime and operator surface for identity-aware AI runs. It gives a host app one public place to normalize actor, tenant, and session identity, start durable runs, resume an exact paused run by `run_id`, and inspect operator evidence at `/scoria` without turning the dashboard into the app's source of business truth.

Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`. The current public shape is intentionally narrow:

- a default runtime lane for durable Phoenix-hosted runs
- a bounded handoff lane for narrow same-run delegation
- a semantic fast path for explicitly safe read-only work
- an optional knowledge lane for pgvector-backed retrieval and grounding

Start with the default runtime lane. It proves identity-aware durable runs, approvals, and operator evidence with mix test.adoption. Use mix test.runtime_to_handoff as the bounded escalation proof lane when the same durable run needs narrow same-run delegation, host-controlled projected context, and operator-visible delegated lineage.

## Who This Is For

Scoria is for Phoenix teams that want AI runtime governance, durable workflow state, operator-visible evidence, and executable verification without turning their app into a hosted agent platform.

The main job-to-be-done is simple: give a Phoenix app one boring, inspectable way to start, resume, debug, and verify identity-aware AI work.

## Choose Your Lane

Use the narrowest lane that solves your current app problem:

- **Default runtime lane**: start here for identity-aware durable runs, approvals, and operator evidence.
- **Bounded handoff lane**: add this only when one role needs to delegate a narrow slice of work to another role under the same durable run.
- **Semantic fast-path lane**: add this when you want tenant-partitioned answer reuse for explicitly safe read-only work.
- **Optional knowledge lane**: add this only when you are intentionally validating retrieval, citations, and grounding.

Docs:

- [Lane selection guide](docs/adoption_lanes.md)
- [Phoenix runtime example](docs/phoenix_runtime_example.md)
- [Bounded handoffs](docs/bounded_handoffs.md)
- [Semantic fast path](docs/semantic_fast_path.md)
- [Operator verification](docs/operator_verification.md)

## Install

Scoria now carries Hex-ready package metadata, but until the first Hex publish lands you should install from a tagged GitHub release:

```elixir
def deps do
  [
    {:scoria, github: "szTheory/scoria", tag: "v0.1.0"}
  ]
end
```

Then mount the dashboard in your Phoenix router and run the install task:

```bash
mix scoria.install
```

That installs the default Phoenix lane by:

- mounting the operator dashboard at `/scoria`
- copying Scoria's core Ecto migrations into `priv/repo/migrations`
- injecting baseline runtime defaults into `config/runtime.exs` or `config/config.exs`
- updating Tailwind content globs when a Tailwind config is present

Tailwind is optional for the install task. If your host app uses a different asset pipeline, the default lane still installs cleanly.

## Quickstart

The host app entrypoint is `Scoria`.

Keep the canonical order boring: `identity -> start -> inspect -> resume`.

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

## Bounded Handoffs

When the runtime-first lane is already in place and one role needs to delegate a narrow slice of work to another role, branch to the public handoff lane:

```elixir
{:ok, started} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer"},
    projected_context: %{"task" => "policy review", "draft_answer" => draft_answer},
    handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
  )

{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

That records delegated lineage under one durable run and publishes one curated delegated evidence projection through `Scoria.get_run_detail/1`. The same run also exposes a `Delegated Evidence` section at `/scoria/workflows/:run_id`. The full guide lives in [`docs/bounded_handoffs.md`](docs/bounded_handoffs.md).

## Semantic Fast Path

When the default runtime lane is already working and you want conservative answer reuse for explicitly safe read-only work, add a semantic lane instead of widening the core runtime contract:

```elixir
defmodule MyApp.AI.AccountFaqLane do
  use Scoria.SemanticLane,
    lane_key: "account_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end

{:ok, summary} =
  Scoria.start_run(identity,
    semantic_cache: [lane: MyApp.AI.AccountFaqLane],
    input: "what is scoria?"
  )
```

This keeps reuse tenant-partitioned, compatibility-aware, and operator-visible. The semantic fast path stays opt-in, falls back to the normal runtime path on `bypass`, `miss`, `reject`, or stale outcomes, and exposes evidence at `/scoria/workflows/:run_id`. The full guide lives in [`docs/semantic_fast_path.md`](docs/semantic_fast_path.md).

## Verification

Default Phoenix lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Then inspect `/scoria` and `/scoria/workflows/:run_id` for operator evidence from one real run in your app. Read it back through `Scoria.get_run/1` or `Scoria.list_runs_for_session/1`. The dedicated operator verification guide lives in [`docs/operator_verification.md`](docs/operator_verification.md).

`mix test.adoption` is the canonical bounded verifier for the default lane. It carries the generated-host proof under a local proof-only timeout, so you do not need suite-wide timeout changes or a `--trace` variant to use it.

Bounded runtime-to-handoff escalation proof lane:

```bash
mix test.runtime_to_handoff
```

This lane does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

The knowledge lane does not define first adoption. You do not need pgvector, knowledge tables, retrieval, grounding, semantic fast-path setup, or `mix test.knowledge` to prove the core runtime, identity, approval, and operator-evidence path.

For the bounded semantic lane:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Use that lane only when you are intentionally validating `v2.1` semantic fast-path behavior. The task prepares the retrieval-backed knowledge tables it needs as part of the proof lane, so you do not need to run the full optional knowledge verification first.

For broader repo-health context outside the canonical lane proofs, maintainers can still run `mix test`.

## Phoenix Example

For one end-to-end controller-triggered adoption story, see [`docs/phoenix_runtime_example.md`](docs/phoenix_runtime_example.md). It follows the same public facade and `session_id`/`run_id` rules proven in the runtime integration suite.

For the public delegation lane, see [`docs/bounded_handoffs.md`](docs/bounded_handoffs.md).

## What Scoria Adds

- OpenInference-style trace capture and redaction
- durable workflows, handoffs, and recovery
- pgvector-backed knowledge, citations, and grounding checks
- a trace-first LiveView surface for operators

## Status

Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`. The default runtime lane, bounded handoff lane, replay/operator loop, semantic fast path, and optional knowledge lane are all available locally. The remaining work is mostly about keeping the adopter story boring and support-truth honest instead of broad platform expansion.
