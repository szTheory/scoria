# Semantic Fast Path

This guide documents the `v2.1` semantic fast path for Scoria.

Use it only after the default runtime lane already works in your Phoenix app. The semantic fast path is an optimization layer for explicitly safe read-only work, not a replacement runtime.

## What this lane is for

Choose the semantic fast path when you want:

- tenant-partitioned answer reuse
- conservative compatibility checks before reuse
- explicit fallback to the normal runtime path
- operator-visible evidence for `bypass`, `miss`, `reject`, and `hit`

Do not treat this as provider prompt caching or invisible middleware. Scoria owns the semantic cache truth inside its embedded Phoenix boundary.

## Safety rule: only explicitly safe read-only lanes

The semantic fast path is opt-in and lane-based.

Define one lane for work that is safe to reuse:

```elixir
defmodule MyApp.AI.AccountFaqLane do
  use Scoria.SemanticLane,
    lane_key: "account_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end
```

Two common scope shapes:

- `default_scope: :tenant_shared` for tenant-rooted FAQ or policy-style answers
- `default_scope: :actor_scoped` when compatibility needs stricter actor-level reuse

Scoria refuses semantic reuse for write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe.

## Starting a run with the semantic lane

Once the lane exists, attach it to a normal `Scoria.start_run/2` call:

```elixir
{:ok, summary} =
  Scoria.start_run(identity,
    semantic_cache: [lane: MyApp.AI.AccountFaqLane],
    input: "what is scoria?"
  )
```

You are still using the same public runtime facade. The semantic fast path is a bounded addition to the normal runtime lane, not a second runtime surface.

## What Scoria checks before reuse

Scoria only reuses a durable entry when all of these still hold:

- tenant partitioning
- lane compatibility
- prompt compatibility
- policy compatibility
- source compatibility
- freshness and lifecycle state

The lookup stays exact-first and compatibility-aware. It does not widen into aggressive ANN-first behavior by default.

## Runtime outcomes

The semantic fast path reports four operator-facing lookup outcomes:

- `hit`: Scoria reused a durable semantic entry
- `bypass`: Scoria intentionally skipped the fast path and ran the normal runtime path
- `miss`: no reusable entry existed, so the normal runtime path executed
- `reject`: a candidate entry existed, but compatibility or freshness no longer held

Rejected, stale, and bypassed cases still preserve the normal durable runtime truth instead of returning ad hoc out-of-band behavior.

## Durable lifecycle truth

Semantic entries keep explicit lifecycle state:

- `active`
- `stale`
- `invalidated`
- `writeback_rejected`

That state is durable and operator-visible. It is not collapsed into a generic cache miss.

## Operator evidence

The same semantic run remains inspectable at:

```text
/scoria/workflows/:run_id
```

Scoria projects semantic provenance, compatibility, lifecycle state, and fallback reasoning into the existing runtime and workflow surfaces so operators can understand why a lookup hit, missed, bypassed, or was rejected.

## Verification

Use the bounded semantic proof lane when validating this feature:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

This is the canonical `v2.1` troubleshooting lane. Use `mix test.adoption` for the broader public runtime adoption story, and use `mix scoria.test.knowledge` only when you are intentionally validating the optional knowledge lane.

## What this lane intentionally does not include

The shipped `v2.1` scope does not include:

- external semantic cache backends
- advanced ANN tuning or analytics controls
- cross-tenant semantic reuse
- automatic caching for write-side or approval-sensitive flows

Keep this lane narrow, conservative, and operator-visible by default.
