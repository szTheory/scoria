# Phase 25: CI/CD Regression & Evaluation Framework - Research

**Researched:** 2026-05-19 [VERIFIED: current_date]
**Domain:** Elixir/Phoenix offline eval execution, replay fixtures, and durable eval evidence [VERIFIED: 25-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from [25-CONTEXT.md](/Users/jon/projects/scoria/.planning/phases/25-ci-cd-regression-and-evaluation-framework/25-CONTEXT.md). [VERIFIED: 25-CONTEXT.md]

### Locked Decisions

> ### Offline regression developer flow
> - **D-01:** Deterministic offline evals should run as ordinary ExUnit tests inside `mix test`, not as a separate default runner.
> - **D-02:** Scoria should layer optional test selection on top of normal ExUnit semantics:
>   - `@moduletag :eval`
>   - stable dataset-oriented tags for targeted reruns
>   - file/module reruns should keep working with normal `mix test` ergonomics
> - **D-03:** `mix test` must remain fully offline for this lane:
>   - no live network calls
>   - no judge-model calls
>   - no hidden fixture recording
> - **D-04:** The default CI contract should continue to treat eval regressions like ordinary test regressions: red test, failing build, normal ExUnit output.
>
> ### Replay artifact strategy
> - **D-05:** Offline regression artifacts should be committed, replay-only baseline fixtures tied to immutable prompt and sealed dataset versions.
> - **D-06:** Scoria should prefer fixture capture at the provider-response seam rather than raw opaque HTTP dumps whenever possible:
>   - normalize irrelevant transport noise
>   - keep the artifact aligned to Scoria’s actual runtime/eval boundary
>   - preserve deterministic replay without over-coupling to provider headers and IDs
> - **D-07:** CI must never auto-record or auto-refresh replay artifacts. Missing or mismatched artifacts should fail loudly.
> - **D-08:** Refreshing or re-recording replay artifacts is an explicit maintainer workflow only, never an implicit test fallback.
> - **D-09:** Replay artifacts must be keyed by immutable execution identity, not mutable labels. At minimum the keying model should include:
>   - prompt version
>   - sealed dataset version
>   - eval spec version
>   - provider/model identity when relevant
>
> ### Eval spec and run model
> - **D-10:** Scoria should use a split eval model:
>   - `EvalSpec` is the immutable baseline contract
>   - `EvalRun` captures the resolved execution snapshot of one run
> - **D-11:** `EvalSpec` should lock the stable comparison contract:
>   - subject reference
>   - dataset snapshot/version
>   - scorer definitions
>   - threshold policy
>   - eval mode
>   - rubric/judge prompt versions when applicable
> - **D-12:** `EvalRun` should snapshot the resolved execution environment actually used:
>   - provider/model
>   - runtime defaults
>   - replay/offline mode
>   - cassette/fixture provenance
>   - judge model if live
>   - explicit overrides used for this run
> - **D-13:** The planner should avoid a forever-untyped catch-all `rubric` blob. Prefer typed Ecto embeds or similarly explicit structured fields for subject, scorers, thresholds, and execution policy.
> - **D-14:** Mutable aliases like “current dataset” or “default judge model” must not be treated as durable eval truth.
>
> ### Mix task and command shape
> - **D-15:** `mix scoria.eval` should remain the explicit live-evaluation lane, primarily for judge-based or otherwise online scoring workflows.
> - **D-16:** Offline deterministic regression remains under `mix test`; Scoria should not hide the primary regression gate behind `mix scoria.eval`.
> - **D-17:** Maintenance responsibilities should use explicit namespaced tasks instead of overloading `mix scoria.eval`. Recommended direction:
>   - `mix scoria.eval` for live evaluation runs
>   - `mix scoria.eval.refresh` (or equivalent) for replay-artifact refresh/record workflows
>   - future reporting/inspection tasks may be added under the same namespace if needed
> - **D-18:** Networked or mutating commands must be obvious from the command name and help text. Principle of least surprise matters more than minimizing task count.
>
> ### Result durability and release-gate signal
> - **D-19:** `EvalRun` persistence should follow a hybrid model:
>   - immutable run header facts on the run row
>   - per-item evidence on associated rows
>   - derived comparison/projection views for UI and reporting
> - **D-20:** `EvalRun` must persist the facts Phase 26 will need to trust later:
>   - executed prompt version reference
>   - dataset/version reference
>   - eval spec/version reference
>   - runner mode (`offline_replay`, `live_judge`, or equivalent)
>   - replay artifact provenance
>   - aggregate pass/fail counts
>   - aggregate latency/cost metrics as appropriate
>   - threshold verdict
>   - explicit baseline comparison anchor when a release decision depends on it
> - **D-21:** Per-item evidence should persist separately from the run header and include:
>   - dataset item reference
>   - pass/fail or numeric score
>   - concise explanation/reason
>   - scorer kind
>   - scorer/judge model identity when applicable
>   - rubric version
>   - evidence/provenance refs back to fixture, trace, or other durable source
> - **D-22:** Scoria should not persist giant opaque “everything blob” run payloads as the primary truth model. Durable facts belong in explicit fields and associations; rich UI views can be projected from them.
> - **D-23:** Scoria should not persist raw chain-of-thought style reasoning. Store concise explanations and durable evidence references instead.
>
> ### Canonical eval persistence boundary
> - **D-24:** Phase 25 planning must resolve the current split between older eval persistence shapes and the newer Phase 24 `ai_eval_datasets` path. There should be one canonical dataset/eval persistence model going forward.
> - **D-25:** The Phase 24 `ai_eval_datasets` / `ai_eval_dataset_items` path is the stronger starting point for the current milestone because it already reflects the open/sealed dataset model and current code usage.
> - **D-26:** If older eval schemas remain temporarily for compatibility, the planner must treat convergence and truth-boundary cleanup as part of this phase rather than allowing long-term split-brain eval storage.
>
> ### Shift-left defaults and interruption policy
> - **D-27:** Low-impact eval framework choices should be shifted left into Scoria defaults and future GSD assumptions rather than repeatedly asking for them.
> - **D-28:** Shift-left defaults should include:
>   - offline evals live in `mix test`
>   - replay-only CI
>   - explicit refresh tasks
>   - immutable keying by prompt/dataset/spec version
>   - typed spec/run split
>   - low-cardinality aggregate metrics with drill-down evidence rows
> - **D-29:** Human interruption should be reserved for materially consequential choices only:
>   - introducing live-network behavior into default test lanes
>   - changing the canonical truth boundary for eval persistence
>   - loosening replay determinism or baseline immutability
>   - expanding Phase 25 into hosted or cross-environment product scope

### Claude's Discretion

> - Exact fixture storage layout and naming convention, provided immutable identity and replay-only semantics remain intact.
> - Exact Ecto module names or embeds for scorer/threshold/subject config, provided the split spec/run boundary remains explicit.
> - Exact names of maintenance Mix tasks, provided live scoring and fixture refresh remain clearly separated.
> - Exact comparison-query/projection strategy for dashboards, provided run header truth and per-item evidence remain durable and inspectable.

### Deferred Ideas (OUT OF SCOPE)

> - Hosted or multi-environment experiment service behavior.
> - Rich benchmark marketplace/catalog features.
> - Fully generalized provider-agnostic replay infrastructure beyond what Phase 25 needs for deterministic CI and live judge runs.
> - Broad release-approval UI work beyond the run evidence needed to support Phase 26.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVAL-01 | System provides an ExUnit-integrated evaluation runner capable of executing Datasets against draft prompt versions. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | Use ordinary ExUnit modules plus `@moduletag :eval` and dataset-specific tags; keep execution under `mix test`, not a parallel runner. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html] |
| EVAL-02 | The evaluation runner mandates HTTP VCR/cassettes for standard test runs to prevent flaky, non-deterministic, and expensive LLM calls during CI. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | Use Req-based provider seams with ReqCassette `mode: :replay` in CI, explicit re-record by deleting cassette or running a dedicated refresh task, and never auto-record in `mix test`. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| EVAL-03 | System provides an LLM-as-a-judge primitive utilizing structured outputs (e.g., via Instructor.ex) for durable, qualitative trace evaluation. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | Keep live judge evaluation under `mix scoria.eval`; use Tribunal judge mode plus `req_llm` transport, because Tribunal already expects structured JSON verdicts from the judge model. [CITED: https://hexdocs.pm/tribunal/llm-as-judge.html] [CITED: https://hexdocs.pm/tribunal/Mix.Tasks.Tribunal.Eval.html] |
| EVAL-04 | Evaluation results are persisted durably to Ecto as `EvalRun` records linked to a specific runtime identity, dataset, and prompt version. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | Expand `EvalRun`/`Score` to explicit run-header facts plus per-item evidence, and converge all run references onto the Phase 24 `ai_eval_datasets` lineage. [VERIFIED: codebase grep] [VERIFIED: priv/repo/migrations] |
</phase_requirements>

## Summary

Scoria already has the right outer shell for this phase: CI treats `mix test` as the default proof lane, `Scoria.EvalCase` exists as a dedicated test seam, `mix scoria.eval` already exists as an explicit non-default command, and Phase 24 introduced `ai_eval_datasets` / `ai_eval_dataset_items` as the active dataset path. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: test/support/eval_case.ex] [VERIFIED: lib/mix/tasks/scoria.eval.ex] [VERIFIED: priv/repo/migrations/20260518220533_create_ai_eval_datasets.exs]

The main planning constraint is that Phase 25 is not only a runner phase. The repo still contains an older eval lineage (`ai_datasets`, `ai_dataset_items`, `ai_eval_specs`, `ai_eval_runs`, `ai_scores`) while current code also uses the newer `ai_eval_datasets` / `ai_eval_dataset_items` lineage, so the planner must include truth-boundary convergence as first-class work instead of layering new execution code on top of split storage. [VERIFIED: priv/repo/migrations/20260510174619_create_eval_tables.exs] [VERIFIED: priv/repo/migrations/20260518220533_create_ai_eval_datasets.exs] [VERIFIED: codebase grep]

The standard implementation shape is: offline regression stays in ExUnit with committed replay-only fixtures; live qualitative scoring stays behind explicit Mix tasks; run truth is stored in typed Ecto fields and associations, not blobs; and cassette recording/refresh is an explicit maintainer workflow. That shape matches the locked context, current Phoenix/Ecto patterns in this repo, Tribunal's documented split between ExUnit and mix-task modes, and ReqCassette's replay-only CI mode. [VERIFIED: 25-CONTEXT.md] [VERIFIED: lib/scoria/prompt_registry.ex] [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]

**Primary recommendation:** Plan Phase 25 as four coordinated workstreams: persistence convergence, offline ExUnit runner helpers, explicit fixture refresh tooling, and live judge run persistence. [VERIFIED: 25-CONTEXT.md] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Offline regression execution under `mix test` | API / Backend | Database / Storage | ExUnit and Mix own selection, filtering, and failure semantics, while the test DB stores datasets and run evidence. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] [VERIFIED: test/test_helper.exs] |
| Replay fixture lookup and cassette enforcement | API / Backend | Database / Storage | The provider seam is exercised in test/runtime code, but the committed cassette files are the immutable replay source. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| Live judge execution via `mix scoria.eval` | API / Backend | Database / Storage | Mix tasks are the explicit entrypoint for online evaluation, and results must persist in Ecto rows for later comparison. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] [CITED: https://hexdocs.pm/tribunal/Mix.Tasks.Tribunal.Eval.html] |
| Eval truth model (`EvalSpec`, `EvalRun`, per-item evidence) | Database / Storage | API / Backend | Durable facts belong in schemas and associations; task/UI layers should project from them. [VERIFIED: 25-CONTEXT.md] [VERIFIED: lib/scoria/eval/eval_run.ex] |
| Future release-gate comparison inputs for Phase 26 | Database / Storage | API / Backend | Phase 26 depends on trustworthy stored run headers and score rows, not ephemeral console output. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 25-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit / `mix test` | Elixir 1.19.5 / Mix 1.19.5 [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`] | Default offline regression gate, tag filtering, targeted reruns | The locked phase context requires ordinary `mix test`, and Mix already supports tag-based focused runs, file reruns, and `--only` semantics. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| `tribunal` | 1.3.6, released 2026-04-24 [VERIFIED: `mix hex.info tribunal`] | ExUnit assertions plus explicit evaluation-mode tooling | Tribunal documents the exact split Scoria wants: hard-fail ExUnit mode for CI gates and separate mix-task mode for aggregate/live evaluation. [CITED: https://hexdocs.pm/tribunal/exunit-integration.html] [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html] |
| `ecto_sql` | 3.13.5, released 2026-03-03 [VERIFIED: `mix hex.info ecto_sql`] | Durable run/spec/dataset persistence and transactional convergence work | The repo already uses Ecto as durable truth, and the eval phase needs migrations plus explicit row modeling rather than process-local state. [VERIFIED: .planning/PROJECT.md] [VERIFIED: priv/repo/migrations] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `req_llm` | 1.11.0, released 2026-05-01 [VERIFIED: `mix hex.info req_llm`] | Judge-model transport for live evaluation | Add directly when implementing EVAL-03, because Tribunal's LLM-as-judge docs require `req_llm` and the current lockfile does not include it yet. [CITED: https://hexdocs.pm/tribunal/llm-as-judge.html] [VERIFIED: mix.lock] |
| `req` | 0.5.17, released 2026-01-05 [VERIFIED: `mix hex.info req`] | Req-native test seam for provider calls | Use as the normalized provider seam for replay/testing helpers when Scoria's subject execution path reaches external model APIs. [CITED: https://hexdocs.pm/req/Req.Test.html] |
| `req_cassette` | 0.6.0, released 2026-03-17 [VERIFIED: `mix hex.info req_cassette`] | Replay-only cassette handling for offline evals | Use for committed replay fixtures because it is built on `Req.Test`, supports `async: true`, supports replay-only mode, and documents explicit shared sessions for spawned processes. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| `bypass` | 2.1.0, released 2020-11-13 [VERIFIED: `mix hex.info bypass`] | Small contract suite at the raw HTTP boundary | Use only for wire-contract or failure-mode tests around the provider adapter, not as the main regression fixture system. [CITED: https://hexdocs.pm/bypass/Bypass.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `req_cassette` | `exvcr` | `exvcr` is a general record/replay library with older adapter-oriented setup; `req_cassette` is Req-native, explicitly async-safe, and already documents ReqLLM usage plus replay-only CI mode. [CITED: https://hexdocs.pm/exvcr/readme.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| `mix scoria.eval` wrapper over Tribunal patterns | Fully custom live eval engine | A custom engine increases planner scope and duplicates threshold/output/reporting behavior Tribunal already exposes via mix-task mode. [CITED: https://hexdocs.pm/tribunal/Mix.Tasks.Tribunal.Eval.html] |
| Typed embeds for scorer/threshold/subject policy | Single `rubric` map blob | The locked context explicitly rejects a forever-untyped blob, and Phase 26 needs durable, queryable fields for comparisons. [VERIFIED: 25-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

Recommended `mix.exs` dependency delta for this phase: [VERIFIED: mix.exs] [VERIFIED: mix.lock]
```elixir
{:tribunal, "~> 1.3"},
{:req_llm, "~> 1.11"},
{:req, "~> 0.5.17", only: :test},
{:req_cassette, "~> 0.6.0", only: :test},
{:bypass, "~> 2.1", only: :test}
```

**Version verification:** `tribunal` 1.3.6 (2026-04-24), `ecto_sql` 3.13.5 (2026-03-03), `req_llm` 1.11.0 (2026-05-01), `req` 0.5.17 (2026-01-05), `req_cassette` 0.6.0 (2026-03-17), and `bypass` 2.1.0 (2020-11-13) were verified from Hex metadata in this session. [VERIFIED: `mix hex.info tribunal`] [VERIFIED: `mix hex.info ecto_sql`] [VERIFIED: `mix hex.info req_llm`] [VERIFIED: `mix hex.info req`] [VERIFIED: `mix hex.info req_cassette`] [VERIFIED: `mix hex.info bypass`]

## Architecture Patterns

### System Architecture Diagram

```text
Developer / CI
  |
  v
mix test ---------------> ExUnit tag filters (`:eval`, dataset tags)
  |                                   |
  |                                   v
  |                           eval test module / helper
  |                                   |
  |                                   v
  |                       Scoria offline eval runner helper
  |                                   |
  |                                   v
  |                    fixture key = prompt_version + dataset_version
  |                                 + eval_spec_version + model/provider
  |                                   |
  |                                   v
  |                        ReqCassette replay plug (`mode: :replay`)
  |                                   |
  |                        no cassette? -> fail test immediately
  |                                   |
  |                                   v
  |                        subject provider execution (offline replay)
  |                                   |
  |                                   v
  |                        deterministic assertions / score builders
  |                                   |
  |                                   v
  +---------------------------> persist EvalRun + Score rows

Explicit maintainer command
  |
  v
mix scoria.eval / mix scoria.eval.refresh
  |
  v
live judge or re-record flow -> provider / judge model -> persist EvalRun + Score rows
```

The current CI already runs `mix test` as the default gate, and the locked context requires keeping that as the boring proof lane. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: 25-CONTEXT.md]

### Recommended Project Structure

```text
lib/
├── scoria/
│   ├── eval/
│   │   ├── dataset.ex               # canonical dataset schema
│   │   ├── dataset_item.ex          # sealed item rows
│   │   ├── eval_spec.ex             # typed immutable baseline contract
│   │   ├── eval_run.ex              # run header facts
│   │   ├── score.ex                 # per-item evidence
│   │   ├── runner.ex                # offline ExUnit execution helper
│   │   ├── fixture_key.ex           # immutable cassette identity builder
│   │   └── refresh.ex               # explicit refresh / re-record support
│   └── eval.ex                      # public context API
├── mix/
│   └── tasks/
│       ├── scoria.eval.ex           # explicit live lane
│       └── scoria.eval.refresh.ex   # explicit cassette maintenance lane
test/
├── support/
│   └── eval_case.ex                 # ExUnit + Tribunal + Req.Test setup
├── scoria/eval/
│   ├── offline_runner_test.exs
│   ├── eval_run_persistence_test.exs
│   └── replay_contract_test.exs
└── fixtures/eval/
    └── ... committed replay artifacts keyed by immutable execution identity
```

This structure extends the repo's current `lib/scoria/eval/*`, `lib/mix/tasks/*`, and `test/support/eval_case.ex` seams instead of inventing a sidecar subsystem. [VERIFIED: codebase grep]

### Pattern 1: ExUnit Is The Default Offline Gate
**What:** Keep offline evals inside normal test modules using standard tags and file-level reruns. [VERIFIED: 25-CONTEXT.md]  
**When to use:** All deterministic, replay-only regression checks that must fail CI like ordinary tests. [VERIFIED: 25-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/mix/Mix.Tasks.Test.html
defmodule Scoria.PromptEvalTest do
  use Scoria.EvalCase, async: true

  @moduletag :eval
  @moduletag dataset: "support-faq-v3"

  test "draft prompt stays grounded" do
    assert :ok = Scoria.Eval.Runner.assert_dataset(
      prompt_version: 7,
      dataset_version: "3",
      eval_spec_version: 2
    )
  end
end
```

### Pattern 2: Replay At The Provider Seam, Not Raw Transport Dumps
**What:** Replay the normalized request/response boundary Scoria actually consumes, and enforce replay-only mode in offline runs. [VERIFIED: 25-CONTEXT.md]  
**When to use:** Any offline test that would otherwise hit a model provider or judge endpoint. [VERIFIED: 25-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/req_cassette/ReqCassette.html
with_cassette fixture_key,
  [mode: :replay, filter_request: &normalize_dynamic_fields/1],
  fn plug ->
    ReqLLM.generate_text(model, prompt, req_http_options: [plug: plug])
  end
```

### Pattern 3: Split Immutable Spec From Resolved Run Snapshot
**What:** `EvalSpec` defines the stable comparison contract; `EvalRun` stores the concrete execution facts used for one run. [VERIFIED: 25-CONTEXT.md]  
**When to use:** Always; do not let run-time overrides mutate the baseline contract row. [VERIFIED: 25-CONTEXT.md]  
**Example:**
```elixir
# Source: repo pattern adapted from Scoria.PromptRegistry
embedded_schema do
  field :subject_kind, Ecto.Enum, values: [:prompt_version]
  field :eval_mode, Ecto.Enum, values: [:offline_replay, :live_judge]
  embeds_many :scorers, ScorerConfig
  embeds_one :thresholds, ThresholdPolicy
end
```

### Anti-Patterns to Avoid

- **Hidden record mode in `mix test`:** ReqCassette defaults to `:record`, so the planner must force replay-only behavior for offline regression helpers or CI will leak live calls into the default lane. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]
- **Leaving both dataset lineages active:** The repo currently has both `ai_datasets` and `ai_eval_datasets`; Phase 25 must converge them instead of routing new code around the ambiguity. [VERIFIED: priv/repo/migrations]
- **Unstructured `rubric` truth:** `Scoria.Eval.EvalSpec` currently stores a single `rubric` map, but the locked context requires typed subject/scorer/threshold policy. [VERIFIED: lib/scoria/eval/eval_spec.ex] [VERIFIED: 25-CONTEXT.md]
- **Opaque run blobs:** `EvalRun` needs explicit prompt/dataset/spec/runtime facts and score rows, not one large payload field. [VERIFIED: 25-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP record/replay for offline evals | Custom file format plus ad hoc request matching | `Req.Test` + `ReqCassette` | ReqCassette already provides replay-only mode, async safety, redaction, templating, and shared-session support for spawned processes. [CITED: https://hexdocs.pm/req/Req.Test.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| Judge-output parsing and threshold semantics | Hand-written JSON prompt parsing for every metric | Tribunal judge modules plus `req_llm` | Tribunal already models structured judge verdicts, thresholds, and custom judges. [CITED: https://hexdocs.pm/tribunal/llm-as-judge.html] [CITED: https://hexdocs.pm/tribunal/Tribunal.Judge.html] |
| Raw transport failure simulation for provider adapters | Homemade local HTTP servers | `Bypass` | Bypass already gives fast per-test HTTP expectations and server up/down control. [CITED: https://hexdocs.pm/bypass/Bypass.html] |
| Prompt/version snapshot semantics | New versioning scheme invented inside evals | Reuse the existing `PromptRegistry` immutable-version pattern | The repo already shipped immutable prompt versions with `entity_id`, `version`, and `is_current`; eval truth should align to that pattern. [VERIFIED: lib/scoria/prompt_registry.ex] [VERIFIED: lib/scoria/prompt_registry/prompt_template.ex] |

**Key insight:** The hard work in this phase is not assertion syntax. It is keeping the default lane deterministic while preserving durable, queryable run truth for Phase 26. [VERIFIED: 25-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: Offline Lane Accidentally Uses Live Network
**What goes wrong:** `mix test` becomes flaky, slow, and billable because the replay layer silently records or falls through to the network. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]  
**Why it happens:** ReqCassette's documented default mode is `:record`, not `:replay`. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]  
**How to avoid:** Force offline helpers to use replay-only mode and route all refresh behavior into `mix scoria.eval.refresh` or equivalent. [VERIFIED: 25-CONTEXT.md]  
**Warning signs:** CI passes only when API keys are present, or a missing cassette creates a new file instead of failing. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]

### Pitfall 2: Split-Brain Eval Truth
**What goes wrong:** Datasets and runs reference two incompatible table families, so the planner cannot guarantee which rows Phase 26 should trust. [VERIFIED: priv/repo/migrations]  
**Why it happens:** The repo contains legacy `ai_datasets` / `ai_dataset_items` tables and newer Phase 24 `ai_eval_datasets` / `ai_eval_dataset_items` tables at the same time. [VERIFIED: priv/repo/migrations]  
**How to avoid:** Start the phase by choosing the canonical dataset path, migrating or deleting the older lineage, and updating all eval FKs and schemas in one bounded wave. [VERIFIED: 25-CONTEXT.md]  
**Warning signs:** `EvalRun` still points to `ai_datasets` while dataset creation and LiveView curation write to `ai_eval_datasets`. [VERIFIED: lib/scoria/eval/eval_run.ex] [VERIFIED: lib/scoria/eval/dataset.ex]

### Pitfall 3: Spawned Processes Break Cassette Matching
**What goes wrong:** Async provider work replays the wrong interaction or repeatedly matches interaction 0, causing nondeterministic failures. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]  
**Why it happens:** ReqCassette tracks interaction order per process unless a shared session is used. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]  
**How to avoid:** If the runner uses `Task.async`, `Task.async_stream`, GenServers, or any spawned process for provider calls, wrap the test in `with_shared_cassette/3` or an explicit shared session. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]  
**Warning signs:** Sequential cassettes fail only under async execution or when concurrency is increased. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]

### Pitfall 4: Run Rows Are Too Thin To Support Phase 26
**What goes wrong:** Phase 25 "passes" but Phase 26 still cannot compare baseline vs candidate because `EvalRun` stores only status and duration. [VERIFIED: lib/scoria/eval/eval_run.ex] [VERIFIED: .planning/ROADMAP.md]  
**Why it happens:** The current schema only stores `status`, `duration_ms`, `dataset_id`, and `eval_spec_id`, and `Score` only stores `score`, `reasoning`, and `details`. [VERIFIED: lib/scoria/eval/eval_run.ex] [VERIFIED: lib/scoria/eval/score.ex]  
**How to avoid:** Add explicit prompt-version refs, identity refs, runner mode, cassette provenance, aggregate counters, verdict fields, and per-item scorer metadata as typed columns/embeds. [VERIFIED: 25-CONTEXT.md]  
**Warning signs:** Release comparison queries need to parse ad hoc JSON or reconstruct baseline identity from console output. [VERIFIED: 25-CONTEXT.md]

## Code Examples

Verified patterns from official sources:

### Focused ExUnit Eval Lane
```bash
# Source: https://hexdocs.pm/mix/Mix.Tasks.Test.html
mix test --only eval
mix test test/scoria/eval/offline_runner_test.exs:12
```

### Replay-Only Cassette Usage
```elixir
# Source: https://hexdocs.pm/req_cassette/ReqCassette.html
with_cassette "support-faq__prompt-7__dataset-3__spec-2",
  [mode: :replay, shared: true, filter_request_headers: ["authorization"]],
  fn plug ->
    Req.get!("https://provider.example/v1/chat", plug: plug)
  end
```

### Live Evaluation Wrapper Shape
```elixir
# Source: https://hexdocs.pm/tribunal/Mix.Tasks.Tribunal.Eval.html
def run(args) do
  Mix.Task.run("app.start")
  # parse dataset/spec/prompt refs
  # resolve provider function
  # run live judge lane
  # persist EvalRun + Score rows
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate custom eval runner for CI | ExUnit test mode for hard pass/fail CI gates | Tribunal 1.3.x docs describe ExUnit test mode as the CI gate path. [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html] | Aligns Scoria with standard `mix test` ergonomics and locked Phase 25 decisions. [VERIFIED: 25-CONTEXT.md] |
| Raw or library-global VCR tooling | Req-native replay via `Req.Test` and `ReqCassette` | Req 0.5.x and ReqCassette 0.6.0 document Req-native stubs, replay modes, and shared sessions. [CITED: https://hexdocs.pm/req/Req.Test.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] | Lower coupling to transport noise and better async/process behavior in Elixir tests. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| Opaque rubric blobs and thin run rows | Typed spec/run split with explicit run-header facts and per-item evidence | This is the locked Phase 25 design direction. [VERIFIED: 25-CONTEXT.md] | Makes Phase 26 comparison and approval queries straightforward instead of reconstructive. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Using the older `ai_datasets` / `ai_dataset_items` lineage as the long-term canonical path is outdated for this milestone because Phase 24 already introduced `ai_eval_datasets` / `ai_eval_dataset_items` and the locked context names that path as the stronger starting point. [VERIFIED: 25-CONTEXT.md] [VERIFIED: priv/repo/migrations/20260518220533_create_ai_eval_datasets.exs]
- Treating `mix scoria.eval` as the default regression gate is outdated for this phase because the locked context and Tribunal docs both separate ExUnit gate mode from explicit evaluation mode. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/tribunal/evaluation-modes.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Scoria.Eval.Runner`, `Scoria.Eval.Refresh`, and fixture-key helper modules do not exist yet and are recommended new seams rather than existing APIs. [ASSUMED] | Architecture Patterns | Low; planner would adjust naming, not product shape. |
| A2 | `req` and `req_cassette` should be test-only dependencies because the locked offline lane is test-only, while `req_llm` should be a non-test dependency because live judge runs happen through `mix scoria.eval`. [ASSUMED] | Standard Stack | Medium; dependency scope affects compile paths and release footprint. |
| A3 | Default offline persisted runs may need an explicit helper or flag if always-on DB writes prove too slow for `mix test`. [ASSUMED] | Open Questions | Medium; affects runner API and default developer ergonomics. |
| A4 | Local unit-test work can proceed without Docker because the current Postgres test service is already reachable on `localhost:55432`. [ASSUMED] | Environment Availability | Low; only affects local fallback guidance. |
| A5 | `req` should be added in this phase as the provider-facing test seam dependency. [ASSUMED] | Environment Availability | Medium; if an existing adapter avoids Req, planner may choose a different seam. |
| A6 | `req_cassette` should be added in this phase as the replay fixture dependency. [ASSUMED] | Environment Availability | Medium; if the provider seam is not Req-based, fixture tooling changes. |
| A7 | `bypass` can be deferred if the planner omits raw adapter contract tests from Phase 25. [ASSUMED] | Environment Availability | Low; affects test depth, not core feature shape. |
| A8 | `test/scoria/eval/replay_contract_test.exs` is the right target file for EVAL-02. [ASSUMED] | Validation Architecture | Low; file naming can change without changing coverage intent. |
| A9 | `test/scoria/eval/eval_run_persistence_test.exs` is the right target file for EVAL-04. [ASSUMED] | Validation Architecture | Low; file naming can change without changing coverage intent. |
| A10 | `test/scoria/eval/offline_runner_test.exs`, `test/scoria/eval/replay_contract_test.exs`, and `test/scoria/eval/eval_run_persistence_test.exs` are the preferred Wave 0 file layout. [ASSUMED] | Validation Architecture | Low; file names are organizational, not architectural. |
| A11 | This research should be refreshed by 2026-06-18 for repo-structure drift and by 2026-06-02 for package-freshness drift. [ASSUMED] | Metadata | Low; stale package versions affect planning accuracy gradually, not immediately. |

## Open Questions (RESOLVED)

1. **Where is the concrete provider-call seam that offline replay should wrap?**
   - **Resolution:** Phase 25 should introduce an explicit eval-owned execution seam at the provider request boundary, not wrap arbitrary runtime internals later in the call graph. The replay contract should live in the new eval runner/judge runner path so offline tests can intercept normalized provider requests and responses before transport-specific noise leaks into fixtures. [RESOLVED: 2026-05-19]
   - **Planning consequence:** The implementation should create a dedicated eval execution module (`Scoria.Eval.Runner` for offline replay and `Scoria.Eval.JudgeRunner` for explicit live runs) that owns fixture-key lookup, replay enforcement, and persistence handoff. If an existing runtime helper is reused underneath, it should sit behind this eval-owned seam rather than being the fixture contract directly.

2. **Should offline ExUnit runs persist rows by default or only when explicitly enabled?**
   - **Resolution:** Offline eval helper paths should persist `EvalRun` and per-item evidence rows by default. This keeps EVAL-04 true in the ordinary regression lane and ensures Phase 26 can depend on one canonical evidence shape across offline and live runs. The ephemeral CI database does not change that requirement; it only scopes the lifetime of those rows to the test job. [RESOLVED: 2026-05-19]
   - **Planning consequence:** `Scoria.Eval.Runner.assert_dataset/1` and `run_offline/1` should write run headers and score rows through the Phase 25 persistence API as the default behavior. A pure assertion-only fast path can be deferred unless execution data later proves the writes materially degrade `mix test`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | ExUnit runner, Mix tasks | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | - |
| Mix | `mix test`, `mix scoria.eval`, migrations | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | - |
| PostgreSQL test service | Existing CI and local test DB | ✓ [VERIFIED: `pg_isready -h localhost -p 55432 -U postgres -d scoria_test`] | reachable on `localhost:55432` [VERIFIED: `pg_isready -h localhost -p 55432 -U postgres -d scoria_test`] | - |
| Docker | CI parity / local service debugging | ✓ [VERIFIED: `docker --version`] | 29.4.1 [VERIFIED: `docker --version`] | Use existing local Postgres without Docker when only unit tests are needed. [ASSUMED] |
| `tribunal` | Existing eval assertions/task patterns | ✓ direct dep [VERIFIED: mix.exs] | 1.3.6 locked [VERIFIED: mix.lock] | - |
| `req_llm` | Live judge lane | ✗ not in lockfile [VERIFIED: mix.lock] | latest 1.11.0 available [VERIFIED: `mix hex.info req_llm`] | Add dependency in this phase. [VERIFIED: `mix hex.info req_llm`] |
| `req` | Req-native provider test seam | ✗ not in lockfile [VERIFIED: mix.lock] | latest 0.5.17 available [VERIFIED: `mix hex.info req`] | Add as test dep in this phase. [ASSUMED] |
| `req_cassette` | Replay-only fixture system | ✗ not in lockfile [VERIFIED: mix.lock] | latest 0.6.0 available [VERIFIED: `mix hex.info req_cassette`] | Add as test dep in this phase. [ASSUMED] |
| `bypass` | Wire-contract tests for provider adapter | ✗ not in lockfile [VERIFIED: mix.lock] | latest 2.1.0 available [VERIFIED: `mix hex.info bypass`] | Can defer if no adapter contract suite is planned in Phase 25. [ASSUMED] |

**Missing dependencies with no fallback:**

- None for planning or code changes. [VERIFIED: environment audit]

**Missing dependencies with fallback:**

- `req`, `req_cassette`, `req_llm`, and `bypass` are not current project deps, but they can be added through `mix.exs` without blocking planning. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: test/test_helper.exs] [VERIFIED: `elixir --version`] |
| Config file | [test/test_helper.exs](/Users/jon/projects/scoria/test/test_helper.exs:1) [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scoria/eval_test.exs test/mix/tasks/scoria.eval_test.exs` for the current eval surface, evolving to `mix test --only eval` as Phase 25 adds tagged regression modules. [VERIFIED: current test files] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Full suite command | `mix test.adoption && mix test && mix test.knowledge` to mirror current CI lanes. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: lib/mix/tasks/test.adoption.ex] [VERIFIED: lib/mix/tasks/scoria.test.knowledge.ex] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | Offline ExUnit helper executes sealed dataset against a prompt version using normal test semantics. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | unit/integration | `mix test --only eval` [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] | ❌ Wave 0 [VERIFIED: codebase grep] |
| EVAL-02 | Missing cassette or mismatched fixture fails the offline lane without network fallback. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | integration | `mix test test/scoria/eval/replay_contract_test.exs` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |
| EVAL-03 | `mix scoria.eval` performs explicit live judge runs and persists qualitative results. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | integration | `mix test test/mix/tasks/scoria.eval_test.exs` plus a focused persistence test file. [VERIFIED: current task test] | ⚠ partial; current task test only checks arg parsing. [VERIFIED: test/mix/tasks/scoria.eval_test.exs] |
| EVAL-04 | `EvalRun` and `Score` persist prompt/dataset/spec/runtime identity plus aggregate and per-item evidence. [VERIFIED: .planning/milestones/v1.6-REQUIREMENTS.md] | unit | `mix test test/scoria/eval/eval_run_persistence_test.exs` [ASSUMED] | ❌ Wave 0 [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/eval_test.exs test/mix/tasks/scoria.eval_test.exs` until the new `:eval` lane exists, then `mix test --only eval`. [VERIFIED: current test files] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]
- **Per wave merge:** `mix test` plus any new targeted replay-contract suite. [VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** `mix test.adoption && mix test && mix test.knowledge` must stay green because CI already treats those as the active proof lanes. [VERIFIED: .github/workflows/ci.yml]

### Wave 0 Gaps

- [ ] `test/scoria/eval/offline_runner_test.exs` - covers EVAL-01 offline dataset execution. [ASSUMED]
- [ ] `test/scoria/eval/replay_contract_test.exs` - covers EVAL-02 replay-only failure behavior and missing-cassette loud failure. [ASSUMED]
- [ ] `test/scoria/eval/eval_run_persistence_test.exs` - covers EVAL-04 typed run/evidence persistence. [ASSUMED]
- [ ] Expand [test/mix/tasks/scoria.eval_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.eval_test.exs:1) beyond argument parsing to cover live lane persistence and explicit online behavior. [VERIFIED: test/mix/tasks/scoria.eval_test.exs]
- [ ] Update [test/support/eval_case.ex](/Users/jon/projects/scoria/test/support/eval_case.ex:1) to integrate `Tribunal.EvalCase` and `Req.Test` setup if the runner adopts Req-native fixtures. [VERIFIED: test/support/eval_case.ex] [CITED: https://hexdocs.pm/tribunal/exunit-integration.html] [CITED: https://hexdocs.pm/req/Req.Test.html]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Host app auth is not the primary concern of this phase. [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | No new browser/session protocol is introduced by offline ExUnit or Mix task eval lanes. [VERIFIED: 25-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: 25-CONTEXT.md] | Keep live-network and mutating behavior behind explicit task names such as `mix scoria.eval` and `mix scoria.eval.refresh`. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/mix/main/Mix.Task.html] |
| V5 Input Validation | yes [VERIFIED: existing schema pattern] | Use Ecto changesets and typed embeds for `EvalSpec`, `EvalRun`, and score/evidence data instead of untyped blobs. [VERIFIED: lib/scoria/eval/eval_spec.ex] [VERIFIED: 25-CONTEXT.md] |
| V6 Cryptography | no [VERIFIED: phase scope] | This phase should redact secrets in fixtures, but it does not introduce new cryptographic primitives. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Committed cassette leaks API keys or cookies | Information Disclosure | Use ReqCassette header and payload filtering, and prefer normalized provider-seam fixtures over raw transport dumps. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] [VERIFIED: 25-CONTEXT.md] |
| CI silently records new fixtures | Tampering | Force replay-only mode in offline lanes and isolate any recording flow behind explicit refresh tasks. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |
| Mutable aliases corrupt run truth | Repudiation | Persist prompt version, dataset version, eval spec version, runner mode, and baseline anchor explicitly on the run header. [VERIFIED: 25-CONTEXT.md] |
| Spawned-process replay mismatch causes flaky failures | Denial of Service | Use ReqCassette shared sessions for any async or multi-process request execution. [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html] |

## Sources

### Primary (HIGH confidence)

- [25-CONTEXT.md](/Users/jon/projects/scoria/.planning/phases/25-ci-cd-regression-and-evaluation-framework/25-CONTEXT.md) - locked decisions, scope, canonical refs.
- [.github/workflows/ci.yml](/Users/jon/projects/scoria/.github/workflows/ci.yml:1) - current CI proof lanes and test contract.
- [mix.exs](/Users/jon/projects/scoria/mix.exs:1) and `mix.lock` - current dependency state and locked versions.
- [lib/scoria/eval.ex](/Users/jon/projects/scoria/lib/scoria/eval.ex:1), [lib/scoria/eval/dataset.ex](/Users/jon/projects/scoria/lib/scoria/eval/dataset.ex:1), [lib/scoria/eval/eval_spec.ex](/Users/jon/projects/scoria/lib/scoria/eval/eval_spec.ex:1), [lib/scoria/eval/eval_run.ex](/Users/jon/projects/scoria/lib/scoria/eval/eval_run.ex:1), [lib/scoria/eval/score.ex](/Users/jon/projects/scoria/lib/scoria/eval/score.ex:1) - current eval surface and schema gaps.
- [test/test_helper.exs](/Users/jon/projects/scoria/test/test_helper.exs:1) and [test/support/eval_case.ex](/Users/jon/projects/scoria/test/support/eval_case.ex:1) - current test defaults and eval seam.
- https://hexdocs.pm/mix/Mix.Tasks.Test.html - ExUnit filtering and rerun behavior.
- https://hexdocs.pm/mix/main/Mix.Task.html - Mix task namespacing and preferred CLI env guidance.
- https://hexdocs.pm/tribunal/exunit-integration.html - Tribunal ExUnit contract.
- https://hexdocs.pm/tribunal/evaluation-modes.html - Tribunal test mode vs evaluation mode split.
- https://hexdocs.pm/tribunal/Mix.Tasks.Tribunal.Eval.html - live eval task features, outputs, thresholds.
- https://hexdocs.pm/tribunal/llm-as-judge.html - structured judge verdicts and `req_llm` requirement.
- https://hexdocs.pm/tribunal/Tribunal.Judge.html - custom judge behavior.
- https://hexdocs.pm/req/Req.Test.html - concurrent Req-native stubs and allowances.
- https://hexdocs.pm/req_cassette/ReqCassette.html - replay modes, filtering, shared sessions, ReqLLM examples.
- https://hexdocs.pm/bypass/Bypass.html - HTTP boundary contract testing.

### Secondary (MEDIUM confidence)

- https://developers.openai.com/api/docs/guides/evaluation-best-practices - evaluator composition guidance, threshold discipline, and LLM-as-judge recommendations used to shape qualitative-eval advice.
- https://hexdocs.pm/exvcr/readme.html - older alternative used only for comparison against Req-native replay tooling.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - current package versions were verified from Hex metadata and the main API contracts were verified from official docs. [VERIFIED: `mix hex.info tribunal`] [VERIFIED: `mix hex.info req`] [VERIFIED: `mix hex.info req_cassette`] [CITED: https://hexdocs.pm/tribunal/exunit-integration.html] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]
- Architecture: HIGH - the repo already exposes the relevant seams, and the main ambiguity is explicitly surfaced as dataset-truth convergence. [VERIFIED: codebase grep] [VERIFIED: priv/repo/migrations]
- Pitfalls: HIGH - each major pitfall is directly supported by either locked context or official library docs. [VERIFIED: 25-CONTEXT.md] [CITED: https://hexdocs.pm/req_cassette/ReqCassette.html]

**Research date:** 2026-05-19 [VERIFIED: current_date]
**Valid until:** 2026-06-18 for repo-specific structure, 2026-06-02 for Hex package freshness. [ASSUMED]
