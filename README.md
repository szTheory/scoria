<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg"><img src="brandbook/logo-primary-light.svg" alt="Scoria" width="360"></picture></p>

# Scoria

AI ops for Phoenix apps.

[![CI](https://github.com/szTheory/scoria/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scoria/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/scoria.svg)](https://hex.pm/packages/scoria)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/scoria)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.19%2B-4B275F.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7%2B-FD4F00.svg)](https://www.phoenixframework.org/)

Scoria is a batteries-included Phoenix library for production AI features. It records every run — prompt renders, model calls, tool calls, retrieval events, approvals, and eval scores — as structured, queryable traces. You get a LiveView operator UI, an eval flywheel, a prompt version registry, and a tool/MCP governance layer, all wired into Phoenix, Ecto, and OTP without a black-box dependency.

Scoria is a Phoenix-native runtime with a narrow public surface — **start with the default runtime**, add lanes only when needed:

- **Default runtime** — durable runs, approvals, operator evidence
- **Bounded handoff** — narrow same-run delegation, projected context, visible lineage
- **Semantic fast path** — opt-in, tenant-partitioned reuse for explicitly safe read-only work
- **Optional knowledge** — pgvector retrieval/grounding when chosen
- **Remote connector** — MCP tool surfaces after default lane is green
- **Upgrade-safe install** — `mix scoria.install` with plan/check/apply paths

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
- [Remote connector adoption](docs/connector_adoption.md)
- [Support copilot gallery](docs/support_copilot_gallery.md) — clone repo for `examples/support_copilot`

## Install

Add Scoria from Hex, then mount the dashboard and run the installer:

```elixir
def deps do
  [
    {:scoria, "~> 0.1", hex: :scoria}
    # Fork or pinned patch only: {:scoria, github: "szTheory/scoria", tag: "v0.1.1"}
  ]
end
```

Tagged GitHub installs are for forks and pinned patches; prefer Hex for normal adoption.

**Next steps:** `mix deps.get` → `mix scoria.install` → `mix ecto.migrate` — then see [Verification](#verification) for `mix test.adoption`.

That installs the default Phoenix lane by:

- mounting the operator dashboard at `/scoria`
- copying Scoria's core Ecto migrations into `priv/repo/migrations`
- injecting baseline runtime defaults into `config/runtime.exs` or `config/config.exs`

The `/scoria` dashboard ships its own precompiled assets (brand-token CSS, a LiveSocket client bundle, and self-hosted fonts), so it renders fully styled and interactive with **no host Tailwind, npm, or asset-pipeline work required**. The installer does not touch your asset config regardless of which pipeline your host app uses.

### Upgrading or re-running install

When upgrading Scoria or re-running install on an existing host app:

1. Run `mix scoria.install --dry-run` to preview planned changes without writes.
2. Run `mix scoria.install --check` to verify current state without writes.
3. Remediate any `manual_review` entries using the printed remediation steps.
4. Run `mix scoria.install` to apply planner-classified changes.

- `--dry-run` and `--check` are no-write modes — they never modify host files.
- `manual_review` entries never receive silent overwrites.
- Apply blocks if managed files drift between check and apply — re-run preview and check before applying.

See [Installer verification modes (upgrade-safe)](docs/operator_verification.md#installer-verification-modes-upgrade-safe) for `SCORIA_CHECK_RESULT`, exit codes, and drift detection details.

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

For the LiveView operator dashboard at `/scoria`, set session keys before mounting routes:

```elixir
conn
|> put_session("tenant_id", identity.tenant_id)
|> put_session("actor_id", identity.actor_id)
```

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

Adoption closeout in CI exercises Scoria via a packaged tarball (`{:scoria, path: unpack_root}` from `mix hex.build --unpack`) — see `Scoria.HexConsumerContract` in the maintainer guide for tarball consumer topology.

Then inspect `/scoria` and `/scoria/workflows/:run_id` for operator evidence from one real run in your app.

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

Optional remote connector lane:

```bash
mix test.connector
```

Use this after `mix test.adoption` when validating MCP connector registration and operator fleet evidence. See [`docs/connector_adoption.md`](docs/connector_adoption.md).

For the bounded semantic lane:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Use that lane only when you are intentionally validating semantic fast-path behavior. The task prepares the retrieval-backed knowledge tables it needs as part of the proof lane, so you do not need to run the full optional knowledge verification first.

### Support copilot gallery (local demo)

Clone the repository to explore Scoria in a realistic support-copilot domain with rich fixtures and a clickable host UI. Shared journey fixtures live in `Scoria.SupportJourney` and `priv/fixtures/support_journey/`. The gallery is **not** in the Hex tarball — it uses a `path: dependency` for local development. This command starts the separate gallery app under `examples/support_copilot`, not the Scoria repo dashboard.

```bash
git clone https://github.com/szTheory/scoria.git
cd scoria/examples/support_copilot
mix setup
mix phx.server
```

Open the gallery host chat at `http://localhost:4010/` and its gallery-local Scoria operator surface at `http://localhost:4010/scoria`.

Run the advisory gallery verification lane from the repo root (not part of closeout order):

```bash
mix scoria.test.support_copilot
```

See [`docs/support_copilot_gallery.md`](docs/support_copilot_gallery.md).

## Phoenix Example

For one end-to-end controller-triggered adoption story, see [`docs/phoenix_runtime_example.md`](docs/phoenix_runtime_example.md). It follows the same public facade and `session_id`/`run_id` rules proven in the runtime integration suite.

For the public delegation lane, see [`docs/bounded_handoffs.md`](docs/bounded_handoffs.md).

## What Scoria Adds

- OpenInference-style trace capture and redaction
- durable workflows, handoffs, and recovery
- pgvector-backed knowledge, citations, and grounding checks
- a trace-first LiveView surface for operators

## Status

Current release: `0.1.1` on [Hex](https://hex.pm/packages/scoria). See [CHANGELOG.md](CHANGELOG.md).

## For maintainers

- [Maintainer guide](docs/MAINTAINERS.md) — parallel CI topology (`policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary`), release operations, warning ratchet
- [Operator verification](docs/operator_verification.md) — adopter verification ladder (also used as docs extra)

For broader repo-health context outside the canonical lane proofs, run `mix test` locally or see the maintainer guide.

`mix ci` is the single-command local merge gate — it reproduces the full CI lane set (deps-lock, format, compile WAE, all gating lanes) and exits non-zero on any failure.
