# Phase 30: Oban Infrastructure & Queue Segregation - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `config/config.exs` | config | config | `config/config.exs` | exact |
| `config/dev.exs` | config | config | `config/config.exs` | exact |
| `lib/scoria/workflows/batch_enqueue.ex` | utility | batch | `lib/scoria/observe/buffer.ex` | role-match |
| `test/scoria/workflows/batch_enqueue_test.exs` | test | batch | `test/scoria/workflows/event_compactor_test.exs` | exact |

## Pattern Assignments

### `config/config.exs` & `config/dev.exs` (config, config)

**Analog:** `config/config.exs`

**Oban config pattern** (lines 10-13):
```elixir
config :scoria, Oban,
  engine: Oban.Engines.Basic,
  queues: [connector_sync: 10, compaction: 10],
  repo: Scoria.Repo
```
*(Planner: Update `queues` to include `[system: 10, inference: 20, evals: 50]` per decision D-01).*

---

### `lib/scoria/workflows/batch_enqueue.ex` (utility, batch)

**Analog:** `lib/scoria/observe/buffer.ex` and `lib/scoria/eval.ex`

**Chunking & Batch Insertion Pattern** (`lib/scoria/observe/buffer.ex`, lines 68-76):
```elixir
    entries = Enum.map(spans, fn span ->
      span
      |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)
    end)
    
    try do
      Scoria.Repo.insert_all(Scoria.Repo.Span, entries)
```

**`Ecto.Multi` Wrapper Pattern** (`lib/scoria/eval.ex`, lines 38-40):
```elixir
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
    |> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
```

*(Planner: Combine these patterns by chunking job structures using `Enum.chunk_every(jobs, 500)` and performing batch writes using `Oban.insert_all/1` or `Oban.insert_all/2` wrapped within an `Ecto.Multi.run`.)*

---

### `test/scoria/workflows/batch_enqueue_test.exs` (test, batch)

**Analog:** `test/scoria/workflows/event_compactor_test.exs`

**Testing Setup Pattern** (lines 2-3):
```elixir
defmodule Scoria.Workflows.EventCompactorTest do
  use ExUnit.Case, async: false
  use Oban.Testing, repo: Scoria.Repo
```

**Testing Assertion Pattern** (lines 28-31):
```elixir
    assert_enqueued(
      worker: Scoria.Compaction.SummarizeWorker,
      args: %{"run_id" => run.id}
    )
```

## Shared Patterns

### Queue Testing Configuration
**Source:** `config/test.exs` (line 14)
**Apply to:** Standard job manual testing mode for D-10.
```elixir
config :scoria, Oban, testing: :manual
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Core analogs exist for batching and queue management |

## Metadata

**Analog search scope:** `config/`, `lib/scoria/`, `test/scoria/`
**Files scanned:** 100+
**Pattern extraction date:** 2026-05-20