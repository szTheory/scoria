<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Oban configuration in `config/config.exs` and `config/dev.exs` MUST define three explicit queues: `[system: 10, inference: 20, evals: 50]`.
- **D-02:** These limits should be overridable via standard Phoenix `runtime.exs` env vars, but the defaults should be hardcoded in the baseline config.
- **D-03:** The `system` queue is for internal Scoria tasks (compaction, discovery).
- **D-04:** The `inference` queue is for ad-hoc async inference tasks.
- **D-05:** The `evals` queue is strictly for the distributed evaluation workers (Phase 33).
- **D-06:** Introduce a utility module (e.g., `Scoria.Workflows.BatchEnqueue` or `Scoria.JobBatcher`) that wraps `Oban.insert_all/1`.
- **D-07:** Batch insertion must enforce a chunk size limit (e.g., 500) to prevent Postgres parameter limit exhaustion during massive eval fan-outs.
- **D-08:** `insert_all` should be executed inside an `Ecto.Multi` or simple transaction to ensure atomicity of the batch chunk.
- **D-09:** ExUnit tests must rely exclusively on `Oban.Testing` helpers (`assert_enqueued`, `assert_enqueued_with`).
- **D-10:** Do not spin up real queue execution loops in test mode to avoid race conditions.

### the agent's Discretion
None explicitly defined for this phase.

### Deferred Ideas (OUT OF SCOPE)
- Does NOT implement the eval coordinator or circuit breakers (deferred to Phases 31-33).
</user_constraints>

# Phase 30: Oban Infrastructure & Queue Segregation - Research

**Researched:** 2026-05-20
**Domain:** Elixir/Phoenix, Oban Queue Configuration & Batch Insertion
**Confidence:** HIGH

## Summary

This research establishes the implementation path for Phase 30, expanding the Oban footprint in Scoria to handle distributed evaluation fan-outs. We verified how to properly define default queue sizes in `config.exs` and allow dynamic overrides via `runtime.exs` by relying on Elixir's native `Config` keyword deep-merge mechanics. We also established the exact signature required for `Scoria.Workflows.BatchEnqueue` to atomically insert massive job arrays without hitting Postgres parameter limits. This is done using `Oban.insert_all/3` iteratively within an `Ecto.Multi.new()`. Finally, we confirmed that `Oban.Testing` cleanly asserts against jobs created by `insert_all` while Oban remains safely disabled in test mode (`config :scoria, Oban, testing: :manual`).

**Primary recommendation:** Use `config/3`'s native keyword list merging in `runtime.exs` to override the queues dynamically. Implement `Scoria.Workflows.BatchEnqueue` using `Enum.reduce` over chunks of changesets, leveraging `Oban.insert_all(multi, name, chunk)` to compose the batch.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Job Concurrency Limits | Config Layer | Runtime Env | Queue capacities dictate systemic load and must be adjustable per environment using `runtime.exs` bounds. |
| Fan-Out Enqueueing | Workflows | Data Layer | Mass job construction belongs in the workflow layer; chunked multi-insertion guarantees database reliability. |
| Job Insertion Assertions | Tests | — | Tests ensure proper serialization and queue routing without activating asynchronous processing threads. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | ~> 2.17 | Job scheduling & queue processing | The canonical async framework in Phoenix relying purely on standard Ecto/PostgreSQL mechanisms. |
| Ecto.Multi | — | Database transactions | Pairs natively with Oban. Ensures atomic consistency when writing multiple chunks of job data. |

## Architecture Patterns

### Recommended Project Structure
```text
config/
├── config.exs           # Baseline hardcoded queue sizes
├── dev.exs              # Baseline hardcoded queue sizes (if differing)
├── test.exs             # `testing: :manual` override
└── runtime.exs          # Dynamic env var overrides
lib/scoria/
└── workflows/
    └── batch_enqueue.ex # New module per D-06
test/scoria/
└── workflows/
    └── batch_enqueue_test.exs
```

### Pattern 1: Safe Configuration Merging via `Config`
**What:** Leveraging `Config`'s native keyword list deep merging to safely override queue capacities.
**When to use:** When extending configuration (like `Oban` queues) across `config.exs` and `runtime.exs` without erasing prior keys.
**Example:**
```elixir
# config/config.exs
config :scoria, Oban,
  engine: Oban.Engines.Basic,
  queues: [connector_sync: 10, compaction: 10, system: 10, inference: 20, evals: 50],
  repo: Scoria.Repo

# config/runtime.exs
if config_env() == :prod do
  config :scoria, Oban,
    queues: [
      system: String.to_integer(System.get_env("OBAN_SYSTEM_CONCURRENCY") || "10"),
      inference: String.to_integer(System.get_env("OBAN_INFERENCE_CONCURRENCY") || "20"),
      evals: String.to_integer(System.get_env("OBAN_EVALS_CONCURRENCY") || "50")
    ]
end
```
*Note:* Elixir automatically merges keyword lists inside `config` statements across multiple loaded files.

### Pattern 2: Ecto.Multi Chunked Insertion
**What:** Chunking thousands of jobs and appending them iteratively into an `Ecto.Multi`.
**When to use:** Crucial when fan-out parameters exceed the PostgreSQL hard limit of 65,535 parameters.
**Example:**
```elixir
defmodule Scoria.Workflows.BatchEnqueue do
  alias Ecto.Multi
  alias Scoria.Repo

  @default_chunk_size 500

  def enqueue_all(jobs, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)

    jobs
    |> Enum.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {chunk, idx}, multi ->
      # Oban.insert_all(multi, name, changesets) handles Multi appending
      Oban.insert_all(multi, :"batch_#{idx}", chunk)
    end)
    |> Repo.transaction()
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Array Serialization | `Repo.insert_all(Oban.Job, ...)` | `Oban.insert_all/3` | Direct schema insert skips struct metadata generation (worker conversion, queue assignments, defaults). |
| Configuration Syncing | `Application.get_env` lookups in `runtime.exs` | Native `config/3` block merging | The Erlang application configuration isn't populated until config evaluation completes; `Config` handles the AST deep merge for you natively. |

## Common Pitfalls

### Pitfall 1: Manual Application Environment Reads in Config
**What goes wrong:** Attempting to read existing config via `Application.get_env(:scoria, Oban)` in `runtime.exs` returns `nil`.
**Why it happens:** In Phoenix >= 1.6, `runtime.exs` runs before the release configuration boot script applies values to the BEAM.
**How to avoid:** Rely purely on `config :scoria, Oban, queues: [...]` which utilizes `Config.Reader` to natively merge.

### Pitfall 2: Postgres Parameter Limit Exceeded
**What goes wrong:** A massive evaluate run crashes with `Postgrex.Error` (too many parameters).
**Why it happens:** Parameter queries cap at 65,535. Given an Oban job has ~10 fields, bulk inserting >6,000 jobs in one query fails catastrophically.
**How to avoid:** Hardcode an `Enum.chunk_every/2` iteration capped at 500 (D-07).

### Pitfall 3: Flaky Queue Tests
**What goes wrong:** `assert_enqueued` tests fail intermittently.
**Why it happens:** Queues execute jobs inline during tests, racing against the test assertions.
**How to avoid:** Ensure `config :scoria, Oban, testing: :manual` remains explicitly declared in `config/test.exs` (D-10).

## Code Examples

### Testing `Oban.insert_all` safely
```elixir
defmodule Scoria.Workflows.BatchEnqueueTest do
  use ExUnit.Case, async: true
  use Oban.Testing, repo: Scoria.Repo

  alias Scoria.Workflows.BatchEnqueue

  test "chunks and inserts job collections correctly" do
    # Generates struct jobs representing fan-out
    jobs = Enum.map(1..1000, fn i -> Scoria.Compaction.SummarizeWorker.new(%{id: i}) end)
    
    assert {:ok, _results} = BatchEnqueue.enqueue_all(jobs, chunk_size: 500)

    # Oban.Testing parses the db and confirms successful queuing automatically
    assert_enqueued worker: Scoria.Compaction.SummarizeWorker, args: %{id: 1}
    assert_enqueued worker: Scoria.Compaction.SummarizeWorker, args: %{id: 1000}
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `config/test.exs` |
| Quick run command | `mix test test/scoria/workflows/batch_enqueue_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | Queue Segregation Limits Configured | unit | `mix test` | ❌ Wave 0 |
| EVAL-03 | Scalable Evaluator Chunked Insertion | unit | `mix test test/scoria/workflows/batch_enqueue_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/workflows/batch_enqueue_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/workflows/batch_enqueue_test.exs` — Covers EVAL-03 requirement testing.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond existing core tech stack).

## Sources

### Primary (HIGH confidence)
- `Oban Hexdocs` - Verified `Oban.insert_all/5` (`(multi, multi_name, changesets, opts)`) signatures via module AST inspection.
- `Oban.Testing` Documentation - Checked the testing guide for `:manual` behavior in inline job insertion tests.
- `Elixir Config.Reader` Documentation - Demonstrated deep keyword list merging.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows Hex package capabilities.
- Architecture: HIGH - Config logic validated programmatically in scratchpad.
- Pitfalls: HIGH - Documented common constraints tied to specific Ecto / PosgreSQL limitations.

**Research date:** 2026-05-20
**Valid until:** 2026-12-20