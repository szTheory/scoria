<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. Dataset Versioning: Immutable Snapshots.
2. CI Integration: ExUnit Macros + Dedicated Mix Task.
3. Rubric Storage: Database-Backed with Immutable Versions.

### the agent's Discretion
None explicitly specified.

### Deferred Ideas (OUT OF SCOPE)
None explicitly deferred in prompt, but outside scope of eval flywheel is deferred.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVAL-01 | Implement Ecto schemas for evaluation datasets (`ai_datasets`, `ai_dataset_items`, `ai_eval_specs`, `ai_eval_runs`, `ai_scores`). | Ecto immutable snapshot pattern with `Ecto.Multi`. |
| EVAL-02 | Build LiveView UI integration to "Promote to Dataset" directly from a failed production trace. | LiveView PubSub and DB writes via snapshot insert. |
| EVAL-03 | Provide deterministic unit test evaluation capabilities (integrating Tribunal or native functions). | ExUnit macros using Tribunal test mode. |
| EVAL-04 | Provide LLM-as-judge evaluation capabilities with versioned rubrics and thresholds. | `mix scoria.eval` task calling Tribunal evaluation mode. |
</phase_requirements>

# Phase 4: Evaluation Flywheel - Research

**Researched:** 2024-05
**Domain:** AI Evaluation, Ecto Versioning, ExUnit Integration
**Confidence:** HIGH

## Summary
The Evaluation Flywheel architecture requires implementing a data layer that guarantees immutable snapshots for datasets and rubrics. This ensures CI pipelines run against a predictable state. We integrate Tribunal for the actual execution, splitting execution into ExUnit assertions (for fast, deterministic gates) and a dedicated Mix task (`mix scoria.eval`) for LLM-as-judge benchmarks. The LiveView UI acts as the operator's workbench to promote production traces into these datasets seamlessly.

**Primary recommendation:** Implement the "Ecto Immutable Versioning Snapshot Pattern" using a `version` integer, and utilize `Tribunal` for test and evaluation modes natively integrated with ExUnit.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dataset Storage (`ai_datasets`) | Database | API / Backend | State is truth; immutable version rows managed via `Ecto.Multi` transactions. |
| Fast CI Unit Tests | Backend Testing | — | ExUnit macros provide developer-friendly gates on deterministic assertions. |
| LLM-as-Judge Evals | Mix Task Runner | API / Backend | `mix scoria.eval` cleanly segregates slow, API-bound evaluations from fast unit tests. |
| "Promote to Dataset" UI | Frontend Server (SSR) | — | LiveView directly orchestrates Ecto.Multi context calls to clone trace to dataset. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `tribunal` | `~> 1.3` | Eval framework | First-class Elixir support for AI eval, LLM-as-judge, and ExUnit. |
| `ecto_sql` | `~> 3.10` | Database | Built-in transaction/multi support essential for versioning guarantees. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `req_llm` | `~> 1.2` | LLM HTTP client | Used behind the scenes by Tribunal for LLM-as-judge. |

**Installation:**
Already configured via Phase decisions (Tribunal included).
Verified with:
```bash
mix hex.info tribunal
```

## Architecture Patterns

### Recommended Project Structure
```text
lib/
├── scoria/
│   ├── eval/                  # Domain boundary
│   │   ├── dataset.ex         # Snapshot logic
│   │   ├── dataset_item.ex    
│   │   ├── eval_spec.ex       # Rubric schema
│   │   ├── run.ex             # Eval run records
│   │   └── score.ex           # Run scores
│   └── eval.ex                # Public context API
├── mix/
│   └── tasks/
│       └── scoria.eval.ex     # Mix task runner
test/
└── support/
    └── eval_case.ex           # ExUnit macro injection
```

### Pattern 1: Ecto Immutable Snapshotting
**What:** Treat datasets as versioned, append-only records.
**When to use:** Storing AI evaluation datasets and rubrics where CI stability relies on unchangeable state.
**Example:**
```elixir
defmodule Scoria.Eval.Dataset do
  use Ecto.Schema
  
  schema "ai_datasets" do
    field :entity_id, :binary_id # stable ID
    field :version, :integer
    field :is_current, :boolean, default: true
    # ...
  end
end

def update_dataset(dataset, attrs) do
  new_version = dataset.version + 1
  
  Ecto.Multi.new()
  |> Ecto.Multi.update_all(:deprecate, 
       from(d in Scoria.Eval.Dataset, where: d.entity_id == ^dataset.entity_id and d.is_current == true),
       set: [is_current: false])
  |> Ecto.Multi.insert(:insert, Scoria.Eval.Dataset.changeset(%Scoria.Eval.Dataset{entity_id: dataset.entity_id, version: new_version}, attrs))
  |> Scoria.Repo.transaction()
end
```

### Anti-Patterns to Avoid
- **In-place updates:** Never run `Repo.update` on a dataset once it has been saved. It silently breaks CI runs referencing the dataset.
- **Polluting ExUnit with LLM calls:** Avoid placing slow LLM-as-judge tests inside standard ExUnit tests. Segregate them into `mix scoria.eval`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LLM-as-Judge Assertions | Custom prompts + HTTP calls | `Tribunal` | Handles retries, prompt formatting, grading logic natively in Elixir. |
| Data diffing UI | Complex frontend state | LiveView server-side | Server simply fetches two snapshot rows and presents the diff directly. |

## Runtime State Inventory
| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None (greenfield for `scoria_eval` sub-app) | — |
| Live service config | None | — |
| OS-registered state | None | — |
| Secrets/env vars | None | — |
| Build artifacts | None | — |

## Common Pitfalls

### Pitfall 1: Breaking Dataset Foreign Keys
**What goes wrong:** `ai_dataset_items` are orphaned or modified when a new dataset version is created.
**Why it happens:** Attempting to reuse the same item row ID for a new dataset version.
**How to avoid:** When creating a new `ai_dataset` version, either clone all associated `ai_dataset_items` with a new `dataset_id`, or use an intermediary joining structure. Cloning is safer for immutability.

## Code Examples

### ExUnit Integration Macro
```elixir
defmodule Scoria.EvalCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Scoria.EvalCase
      import Tribunal
      
      # Setup DB Sandbox for tests
      alias Scoria.Repo
    end
  end
end
```

## State of the Art
| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mutable tables | Immutable snapshot row | Modern Ecto | Guaranteed historical correctness. |
| Flaky integration | `mix scoria.eval` task | Current | Developer laptop workflows remain fast. |

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] Tribunal handles deterministic + LLM-based assertions natively. | Standard Stack | May need custom ExUnit helpers. |

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified beyond standard Ecto/Elixir config)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | Immutable Ecto Multi | unit | `mix test test/scoria/eval_test.exs` | ❌ Wave 0 |
| EVAL-03 | Tribunal Macro Loads | unit | `mix test test/support/eval_case_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/scoria/eval_test.exs`
- [ ] `test/support/eval_case.ex` setup

## Security Domain
Step skipped, not explicitly defined. (Assuming no security implications on evaluating datasets internally).

## Sources
### Primary (HIGH confidence)
- Hex.pm - Tribunal docs on ExUnit integration and Mix task modes.
- Ecto Immutable Pattern best practices (QuestDB / ImmuTable hex).

### Secondary (MEDIUM confidence)
- General Web Search verified on standard Ecto immutable append-only structures.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Tribunal is standard for this in Elixir.
- Architecture: HIGH - Immutable dataset rows use standard Ecto `Multi`.
- Pitfalls: HIGH - Foreign keys are the main issue in versioned data.

**Research date:** 2024-05
**Valid until:** 60 days