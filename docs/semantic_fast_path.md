# Semantic Cache

This guide documents the tenant-scoped semantic cache for Scoria. The file path remains `docs/semantic_fast_path.md` for Phase 46 link stability. See [Glossary](glossary.md) for terminology.

Use it only after the default runtime capability already works in your Phoenix app. The semantic cache is an optimization layer for explicitly safe read-only work, not a replacement runtime.

## What this capability is for

Choose the semantic cache when you want:

- tenant-partitioned answer reuse
- conservative compatibility checks before reuse
- explicit fallback to the normal runtime path
- reviewer-visible trace details for `bypass`, `miss`, `reject`, and `hit`

Do not treat this as provider prompt caching or invisible middleware. Scoria owns the semantic cache truth inside its embedded Phoenix boundary.

## Safety rule: only explicitly safe read-only profiles

The semantic cache is opt-in and profile-based.

Define one profile for work that is safe to reuse:

```elixir
defmodule MyApp.AI.AccountFaqCache do
  use Scoria.SemanticCache.Profile,
    cache_key: "account_faq",
    default_scope: :tenant_shared,
    safe_read_only: true
end
```

`Scoria.SemanticLane`, `lane:`, and `lane_key` remain accepted as legacy 0.1.x compatibility aliases; new public examples should use `Scoria.SemanticCache.Profile`, `profile:`, and `cache_key:`.

Two common scope shapes:

- `default_scope: :tenant_shared` for tenant-rooted FAQ or policy-style answers
- `default_scope: :actor_scoped` when compatibility needs stricter actor-level reuse

Scoria refuses semantic reuse for write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe.

## Starting a run with the semantic cache profile

Once the profile exists, attach it to a normal `Scoria.start_run/2` call:

```elixir
{:ok, summary} =
  Scoria.start_run(identity,
    semantic_cache: [profile: MyApp.AI.AccountFaqCache],
    input: "what is scoria?"
  )
```

You are still using the same public runtime facade. The semantic cache is a bounded addition to the normal runtime capability, not a second runtime surface.

## What Scoria checks before reuse

Scoria only reuses a durable entry when all of these still hold:

- tenant partitioning
- profile compatibility
- prompt compatibility
- policy compatibility
- source compatibility
- freshness and lifecycle state

The lookup stays exact-first and compatibility-aware. It does not widen into aggressive ANN-first behavior by default.

## Runtime outcomes

The semantic cache reports four reviewer-facing lookup outcomes:

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

That state is durable and reviewer-visible. It is not collapsed into a generic cache miss.

## Reviewer trace

The same semantic run remains inspectable at:

```text
/scoria/workflows/:run_id
```

Scoria projects semantic cache provenance, compatibility, lifecycle state, and fallback reasoning into the existing runtime and workflow surfaces so reviewers can understand why a lookup hit, missed, bypassed, or was rejected.

## Verification

Use the bounded semantic cache verification suite when validating this feature:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

This is the canonical semantic cache troubleshooting verification suite. Use `mix test.adoption` for the broader public runtime adoption story, and use `mix test.knowledge` only when you are intentionally validating the optional knowledge base.

## What this capability intentionally does not include

The semantic cache scope does not include:

- external semantic cache backends
- advanced ANN tuning or analytics controls
- cross-tenant semantic reuse
- automatic caching for write-side or approval-sensitive flows

Keep this capability narrow, conservative, and reviewer-visible by default.
