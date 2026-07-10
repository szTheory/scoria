# Choosing Capabilities

Scoria is easiest to adopt when you treat it as a layered Phoenix runtime, not a platform you have to swallow whole.

Start with the narrowest capability that solves your current problem. Expand only when the previous capability already feels boring in your host app. See [Glossary](glossary.md) for the final terminology map.
Start with the default runtime capability. It proves identity-aware durable runs, approvals, and reviewer traces with `mix test.adoption`. Use `mix test.runtime_to_handoff` as the bounded escalation verification suite when the same durable run needs narrow same-run delegation, host-controlled scoped context, and reviewer-visible delegated lineage.

For the ownership boundary behind each capability, see [What Scoria owns vs what your app owns](../README.md#what-scoria-owns-vs-what-your-app-owns) in the README. Scoria is for Phoenix teams where one engineer may need to wear the AI/product, platform, SRE, prompt, eval, and reviewer hats without adopting a separate hosted control plane.

## Capability Set

### 1. Default runtime capability

Start here.

Choose it when you need:

- canonical actor, tenant, and session identity
- durable runs with exact `run_id` resume
- approval pauses and reviewer traces
- one public facade for `identity -> start -> inspect -> resume`

Core APIs:

- `Scoria.identity/1`
- `Scoria.start_run/2`
- `Scoria.get_run/1`
- `Scoria.resume_run/2`
- `Scoria.list_runs_for_session/1`

Reviewer surfaces:

- `/scoria`
- `/scoria/workflows/:run_id`

#### Host-authenticated dashboard scope

The host app authenticates the reviewer and asserts dashboard tenant scope. Scoria records and reads that scope; query params do not choose tenants.

The recommended dashboard mount keeps authentication and membership checks in your Phoenix app, then returns the minimal scope Scoria needs:

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

`scope_resolver:` may be a module implementing `ScoriaWeb.DashboardScope.Resolver` or an MFA tuple. Return `{:ok, %{tenant_id: current_account.id, actor_id: current_user.id}}` after the host has already authenticated the reviewer and checked tenant membership. Authorization remains delegated to the host; Scoria does not introduce a role model.

Scope doctrine mechanism-vs-noun boundary: Scoria owns the dashboard scope seam and trusted scope record; the host owns authentication, authorization, membership policy, and role values.

Query params do not choose tenants for the dashboard. A URL such as `/scoria?tenant=other-account` can be a host-defined hint only if your resolver chooses to inspect it after authentication and membership checks; Scoria's default resolver ignores it.

The bare `scoria_dashboard "/scoria"` form still compiles. It uses the session-backed default resolver for compatibility with existing installer/dev/example mounts, so host apps can still provide the same tenant and actor keys in the session:

```elixir
conn
|> put_session("tenant_id", conn.assigns.current_account.id)
|> put_session("actor_id", conn.assigns.current_user.id)
```

`mix scoria.install` does **not** inject auth hooks, authorization policy, role values, or session keys — that contract is host-owned. If scope is missing or rejected by the resolver, Scoria fails closed with generic browser-facing copy: This Scoria dashboard is not available for this session.

The runtime identity you pass to `Scoria.start_run/2` must use the same `tenant_id` as the host-asserted dashboard scope or live trace and HITL updates will not reach the reviewer UI. When reviewer live broadcast is enabled, ensure Observe `Telemetry` and `Buffer` are started in your host application (see `test/scoria/observe/telemetry_test.exs` for the attach pattern).

Verification suite:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Adoption closeout exercises a packaged tarball from `mix hex.build --unpack` (not a monorepo root `path:` dep). Maintainer CI topology — PR tarball vs release registry attest — lives in [`docs/operator_verification.md`](operator_verification.md).

If you are not sure where to start, start here.

After upgrades, run `mix scoria.install --check` as a no-write verification step. See
[Installer verification modes (upgrade-safe)](operator_verification.md#installer-verification-modes-upgrade-safe)
for the dry-run → check → remediate → apply workflow. See
[Check vs apply drift detection](operator_verification.md#check-vs-apply-drift-detection)
for manifest fingerprint roles at check vs apply time.

This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

### 2. Bounded handoff capability

Add this only when the default runtime capability is already working.

Choose it when:

- one role needs to delegate a narrow slice of work to another role
- the delegated role should stay under the same durable run
- scoped context must stay least-privilege and inspectable

Core API:

- `Scoria.start_handoff_run/3`

Key rule:

- scoped context stays narrow and host-controlled
- broad runtime-state keys such as `transcript`, `messages`, `provider_session`, `session`, and `secrets` are rejected explicitly

Use this for review, critique, classification, or bounded specialist work. Do not use it to build a broad autonomous multi-agent platform by default.

Validate the base runtime capability with `mix test.adoption` before you intentionally expand into `Scoria.start_handoff_run/3`.
Use `mix test.runtime_to_handoff` as the bounded runtime-to-handoff escalation verification suite for the same `Scoria.get_run_detail/1` and `delegated_handoffs` readback path.

### 3. Semantic cache capability

Add this only after the default runtime capability is already boring.

Choose it when:

- you want answer reuse for explicitly safe read-only work
- tenant partitioning and compatibility truth matter more than aggressive hit-rate chasing
- reviewers need to inspect why reuse happened, missed, bypassed, or was rejected

Core API surface:

- `use Scoria.SemanticCache.Profile`
- `Scoria.start_run(..., semantic_cache: [profile: MyApp.AI.AccountFaqCache], ...)`

Key behavior:

- reuse is opt-in
- hits remain inside the normal durable run story
- `bypass`, `miss`, `reject`, and stale outcomes fall through to the normal runtime path
- lifecycle truth stays explicit as `active`, `stale`, `invalidated`, and `writeback_rejected`

Example:

```elixir
defmodule MyApp.AI.AccountFaqCache do
  use Scoria.SemanticCache.Profile,
    cache_key: "account_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end
```

Verification suite:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Use this capability when latency and cost matter, but only if you can keep the work safe, tenant-scoped, and reviewer-visible.

Semantic cache is optional troubleshooting, not a prerequisite for first adoption.

### 4. Optional knowledge base capability

Add this only when you are intentionally validating retrieval, citations, and grounding.

Choose it when:

- you need pgvector-backed retrieval
- you need citation and grounding evidence
- you are ready to own the knowledge setup in your app

Verification suite:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

The host app supplies tenant/actor identity for this capability. Scoria enforces that scope at storage, retrieval, citation, and grounding boundaries; metadata filters can narrow results inside a tenant but are not security proof.

Scope doctrine mechanism-vs-noun boundary: Scoria owns retrieval filtering, citation validation, and persisted evidence; the host owns tenant/actor identity, business truth, and end-user semantics.

This capability is explicitly optional. It is not required to prove the core runtime, handoff, or semantic cache adoption story, and it is not a prerequisite for first adoption.

### 5. Remote connector capability

Add this only when you are intentionally validating remote MCP connector registration and reviewer fleet trace details.

Choose it when:

- you need durable connector records, grants, and health state inside your Phoenix app
- reviewer fleet trace details matter for your integration review
- you have already proven the default runtime capability

Verification suite:

```bash
mix test.connector
```

This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

See [connector_adoption.md](connector_adoption.md) for embedded-boundary framing.

## A Good Default Order

Adopt Scoria in this order:

1. `identity -> start -> inspect -> resume`
2. bounded handoffs if one role truly needs delegation
3. semantic cache if safe read-only reuse is worth it
4. optional knowledge base if retrieval and grounding are part of your product
5. remote connector capability if MCP tool surfaces are part of your product

## What You Do Not Need To Adopt First

You do not need:

- pgvector
- broad multi-agent orchestration
- a hosted control plane
- external semantic cache backends
- advanced ANN tuning

Start narrow. Expand only when the current capability already feels boring.
