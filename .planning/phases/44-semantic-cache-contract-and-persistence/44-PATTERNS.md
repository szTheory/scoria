# Phase 44 Pattern Map

**Phase:** `44 - Semantic cache contract and persistence`
**Generated:** `2026-05-25`

## Primary Analog Files

### Public runtime normalization

- `lib/scoria/runtime/params.ex`
- `lib/scoria/runtime/defaults.ex`
- `lib/scoria/identity.ex`
- `lib/scoria/prompt_policy.ex`

Why they matter: Phase 44 should extend the existing Scoria runtime start contract instead of inventing a separate entry point.

### Durable context/service modules

- `lib/scoria/knowledge.ex`
- `lib/scoria/eval.ex`

Why they matter: both expose a top-level Scoria context and use explicit Ecto-backed helper flows rather than middleware or generic data bags.

### Durable table/schema patterns

- `lib/scoria/knowledge/retrieval_run.ex`
- `lib/scoria/workflows/run.ex`
- `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`
- `priv/repo/migrations/20260519010100_create_ai_compacted_memories.exs`

Why they matter: these show the current Scoria style for `binary_id`, timestamps, references, and phase-appropriate indexing.

## Concrete Patterns To Reuse

### 1. Runtime option normalization stays in `Params`

Use the `Scoria.Runtime.Params.start/2` pattern: normalize opts, derive explicit public inputs, then return a structured payload for `Scoria.Runtime.start_run/2`.

```elixir
with {:ok, resolved_defaults} <- Defaults.resolve(identity, opts) do
  {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch}}
end
```

Phase 44 should follow this by normalizing `semantic_cache: [lane: ...]` into explicit runtime metadata rather than reading raw opts deep inside workflow execution.

### 2. Prompt-policy facts are projected as explicit metadata

Use the `Scoria.Runtime.Defaults.to_metadata/1` approach:

```elixir
%{
  "provider" => defaults.provider,
  "model" => defaults.model,
  "policy_key" => prompt_policy.policy_key,
  "prompt_ref" => prompt_policy.prompt_ref,
  "prompt_version" => prompt_policy.prompt_version
}
```

Phase 44 entry rows should persist the same compatibility facts instead of inventing alternate field names.

### 3. Ecto contexts own durable writes

`Scoria.Knowledge` and `Scoria.Eval` both keep Repo interactions inside a focused context module. Phase 44 should mirror that style with `Scoria.SemanticCache` rather than letting runtime code assemble raw Repo writes.

### 4. Versioned / append-only truth uses explicit schema pairs

`Scoria.Knowledge` uses separate schemas for runs, results, citations, and scores. Phase 44 should likewise keep `Entry` and `EntryEvent` separate instead of burying lifecycle history inside one mutable row.

### 5. Multi-step durable updates use `Ecto.Multi`

`Scoria.Eval.update_eval_spec/2` is the main analog for "deprecate old, insert new, keep history". If Phase 44 updates entry status and records a paired event in one transaction, it should use `Ecto.Multi` with named steps.

```elixir
Ecto.Multi.new()
|> Ecto.Multi.update(:deprecate_old, old_spec_changeset)
|> Ecto.Multi.insert(:new_spec, EvalSpec.changeset(%EvalSpec{}, base_attrs))
```

### 6. Migrations prefer explicit indexes over implicit assumptions

Knowledge and workflow migrations explicitly add `tenant_id`, foreign-key, and status indexes where query patterns demand them. Phase 44 should plan indexes around:

- `tenant_id`
- `tenant_id + lane_key`
- `tenant_id + scope_kind + actor_id`
- lifecycle/event foreign keys

## File-Level Guidance For Plans

### Likely new files

- `lib/scoria/semantic_cache.ex`
- `lib/scoria/semantic_lane.ex`
- `lib/scoria/semantic_cache/entry.ex`
- `lib/scoria/semantic_cache/entry_event.ex`
- `lib/scoria/semantic_cache/eligibility.ex`
- `priv/repo/migrations/*_create_semantic_cache_tables.exs`
- `test/scoria/semantic_cache_test.exs`
- `test/scoria/semantic_cache/lane_test.exs`
- `test/scoria/semantic_cache/eligibility_test.exs`
- `test/scoria/runtime/semantic_fast_path_test.exs`

### Likely modified files

- `lib/scoria/runtime.ex`
- `lib/scoria/runtime/params.ex`
- `lib/scoria/runtime/defaults.ex`
- `lib/scoria/workflows/runtime.ex`

## Guardrails

- Do not overload `Scoria.Knowledge.RetrievalRun` into semantic cache truth.
- Do not hide semantic-cache activation behind prompt policy alone.
- Do not write semantic-cache miss/bypass rows in Phase 44.
- Do not widen scope from actor-scoped history back to tenant-shared history.
