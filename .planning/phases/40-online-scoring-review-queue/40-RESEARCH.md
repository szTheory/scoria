# Phase 40: Online Scoring & Review Queue - Research

**Researched:** 2026-05-23 [VERIFIED: current session date]
**Domain:** asynchronous production-trace scoring, operator review queues, and draft promotion governance on Phoenix/Oban/Ecto [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md]
**Confidence:** HIGH [VERIFIED: local code inspection plus official Oban, Phoenix LiveView, Ecto, and Hex package sources]

## User Constraints

- No `40-CONTEXT.md` exists, so this research is constrained by the roadmap, requirements, state file, Phase 39 completion context, the explicit user prompt, and current code seams. [VERIFIED: `gsd-sdk query init.phase-op "40"` output; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/STATE.md; user prompt]
- Phase 40 must address `SCOR-01`, `SCOR-02`, `SCOR-03`, and `SCOR-04`. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
- Phase 39 is complete and already introduced replay provenance plus draft dataset promotion. Phase 40 must build on those seams rather than replace them. [VERIFIED: user prompt; .planning/STATE.md; lib/scoria/runtime/replay_comparison.ex; lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex]
- Online scoring remains additive evidence only, and sealed baseline datasets must never be auto-mutated. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md]
- The repo has no project-root `AGENTS.md` or `CLAUDE.md`. [VERIFIED: `rg --files -g 'AGENTS.md' -g 'CLAUDE.md'`]
- `GEMINI.md` explicitly says not to use the Ash framework, so this phase should stay on the existing Phoenix/Ecto architecture. [VERIFIED: GEMINI.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOR-01 | Scoria can asynchronously sample eligible production traces and attach online scoring evidence without adding latency to the request path. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse Oban plus the existing eval campaign/worker path for all scoring execution, and add a separate sampler/coordinator boundary that persists candidate lineage before enqueuing jobs. [VERIFIED: config/config.exs; lib/scoria/application.ex; lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/eval/campaign_worker.ex; CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| SCOR-02 | Online scoring supports deterministic-first rules and optional judge-based scoring while storing scorer version, judge model, and sampling provenance on every score. [VERIFIED: .planning/REQUIREMENTS.md] | Keep deterministic rule evaluation and judge evaluation as separate scorer kinds in one persisted score contract, and record scorer metadata on each score row or score-adjacent evidence row rather than only at the campaign/run level. [VERIFIED: lib/scoria/eval/eval_spec.ex; lib/scoria/eval/judge_runner.ex; lib/scoria/eval/eval_run.ex; lib/scoria/eval/score.ex] |
| SCOR-03 | Operators can review low-quality or policy-triggered traces in a dedicated queue with deep links back to trace evidence and scoring rationale. [VERIFIED: .planning/REQUIREMENTS.md] | Build a dedicated review-queue projection backed by persisted score/reason metadata and route links to existing operator surfaces: `/scoria/workflows/:id` for workflow evidence and `/scoria` for trace-tree context. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/live/orchestrator_live.ex] |
| SCOR-04 | Draft promotion candidates created from online scoring remain reviewable and separate from sealed baseline datasets until explicitly approved. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse Phase 39 draft promotion for open datasets and Phase 39 baseline approval gating for sealed datasets, but insert a persisted “candidate review” lane in front of both so low-quality traces can be triaged without mutating baseline truth. [VERIFIED: lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex; lib/scoria_web/live/dataset_live/promote_component.ex; test/scoria_web/live/dataset_live/promote_component_test.exs] |
</phase_requirements>

## Summary

Phase 40 should be planned as an additive scoring pipeline layered on top of the eval campaign infrastructure that already exists, not as a second async engine. The repo already has Oban configured and supervised, a dedicated `:evals` queue, campaign parent rows, per-target child rows, per-run judge execution, rollup counters, idempotent worker retries, and manual Oban testing in ExUnit. [VERIFIED: config/config.exs; config/test.exs; lib/scoria/application.ex; lib/scoria/eval/eval_campaign.ex; lib/scoria/eval/eval_campaign_target.ex; lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/eval/campaign_worker.ex; test/scoria/eval/campaign_enqueue_test.exs; test/scoria/eval/campaign_worker_test.exs; CITED: https://hexdocs.pm/oban/Oban.Worker.html; https://hexdocs.pm/oban/testing.html]

The main planning work is not “how do we run jobs?” but “what exact durable objects define sampled trace scoring and operator review?” Today the codebase has durable traces, workflow runs, approvals, replay comparison DTOs, draft dataset promotion, and sealed-baseline approval gating, but it does not yet have an online-scoring candidate table, a review-queue projection, or a clear production-trace sampling boundary. [VERIFIED: lib/scoria/repo/trace.ex; lib/scoria/runtime/replay_comparison.ex; lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex; lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex]

There is one repo-local risk the planner should account for immediately: the current `Scoria.Eval.Score` schema only exposes `score`, `reasoning`, and `details`, while the judge/campaign code and tests expect richer fields such as `status`, `explanation`, `evidence_refs`, and `metadata`. That mismatch must either be resolved in Wave 0 or treated as a prerequisite plan slice before Phase 40 leans on score-level rationale storage. [VERIFIED: lib/scoria/eval/score.ex; lib/scoria/eval.ex; lib/scoria/eval/judge_runner.ex; test/scoria/eval/campaign_worker_test.exs; priv/repo/migrations/20260510174619_create_eval_tables.exs]

**Primary recommendation:** Plan Phase 40 as four plans: sampling contract and persistence, scorer execution/evidence persistence, review-queue projection/UI, and promotion/approval integration that keeps draft candidates reviewable and sealed baselines immutable. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; lib/scoria/eval/campaign_enqueuer.ex; lib/scoria_web/live/workflow_live/show.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Trace eligibility sampling | API / Backend | Database / Storage | Eligibility and random sampling must run off the request path and query persisted traces/spans rather than LiveView state. [VERIFIED: lib/scoria/repo/trace.ex; lib/scoria/repo/span.ex; .planning/REQUIREMENTS.md] |
| Async score execution | API / Backend | Database / Storage | Oban workers and eval contexts already own asynchronous evaluation and persistence. [VERIFIED: lib/scoria/application.ex; lib/scoria/eval/campaign_worker.ex; lib/scoria/eval.ex; CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Score evidence persistence | Database / Storage | API / Backend | Requirement `SCOR-02` demands scorer version, judge model, and sampling provenance on every score, which is durable-state work first. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/eval_run.ex; lib/scoria/eval/score.ex] |
| Review queue projection | API / Backend | Frontend Server (LiveView) | Operators need a curated queue, but the queue contents should come from a projection boundary similar to remote approvals rather than template-side joins. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex] |
| Queue rendering and triage | Frontend Server (LiveView) | API / Backend | The operator UI belongs in LiveView, but it should consume precomputed queue rows and deep links. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex] |
| Draft promotion and baseline gating | API / Backend | Frontend Server (LiveView) | Promotion already belongs to `Scoria.Eval` and workflow approval seams, and sealed baselines are already guarded there. [VERIFIED: lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex; test/scoria_web/live/dataset_live/promote_component_test.exs] |

## Project Constraints (from repo instructions)

- Do not introduce Ash. [VERIFIED: GEMINI.md]
- Stay on standard Phoenix + Ecto + LiveView boundaries already present in the repo. [VERIFIED: GEMINI.md; mix.exs]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | `2.22.1` published `2026-04-30` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/oban] | Async sampling, score execution, retries, priority, and uniqueness. [VERIFIED: config/config.exs; lib/scoria/application.ex; lib/scoria/eval/campaign_worker.ex] | The repo already uses Oban for eval work, and official docs define runtime queue overrides, unique jobs, and priority semantics needed for Phase 40 planning. [VERIFIED: lib/scoria/eval/campaign_worker.ex; lib/scoria/eval/campaign_enqueuer.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Ecto / ecto_sql | `3.13.6` / `3.13.5`, with `ecto_sql 3.13.5` published `2026-03-03` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/ecto_sql] | Transactional persistence for sampled candidates, score evidence, review queues, and promotion decisions. [VERIFIED: lib/scoria/eval.ex; lib/scoria/workflows.ex] | Phase 40 needs multi-row durable truth with rollback-safe writes. [VERIFIED: lib/scoria/eval.ex; lib/scoria/workflows.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Phoenix LiveView | `1.1.30` published `2026-05-05` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/phoenix_live_view] | Operator-visible queue UI and deep-link navigation within existing LiveView routes. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex] | The review queue should live inside current operator surfaces, and LiveView already powers those pages. [VERIFIED: lib/scoria_web/router.ex; mix.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ReqLLM | `1.12.0` published `2026-05-22` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/req_llm] | Existing judge-model transport dependency behind repo-local orchestration. [VERIFIED: mix.exs; mix.lock; lib/scoria/eval/judge_runner.ex] | Use only for optional judge scorers after deterministic rules run first. [VERIFIED: lib/scoria/eval/eval_spec.ex; lib/scoria/eval/judge_runner.ex] |
| `Scoria.Eval.CampaignEnqueuer` / `CampaignWorker` | repo-local [VERIFIED: lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/eval/campaign_worker.ex] | Existing durable async fan-out/fan-in pattern. [VERIFIED: test/scoria/eval/campaign_enqueue_test.exs; test/scoria/eval/campaign_worker_test.exs] | Extend this pattern instead of inventing a second async coordinator. [VERIFIED: lib/scoria/eval.ex] |
| `Scoria.Runtime.ReplayComparison` | repo-local [VERIFIED: lib/scoria/runtime/replay_comparison.ex] | Existing reviewable original/replay evidence groups and promotion context seams. [VERIFIED: lib/scoria/runtime.ex; lib/scoria_web/live/workflow_live/show.ex] | Reuse when queue items need workflow evidence or draft promotion context. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex] |
| `Scoria.Workflows.RemoteApprovalProjection` | repo-local [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] | Existing operator queue/projection pattern for pending approvals. [VERIFIED: lib/scoria/workflows.ex; lib/scoria_web/live/orchestrator_live.ex] | Model review-queue reads after this projection style. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing Oban eval workers [VERIFIED: lib/scoria/eval/campaign_worker.ex] | A separate GenServer polling loop [ASSUMED] | Rejected because the repo already has durable, retryable, testable background-job infrastructure with queue isolation and worker uniqueness. [VERIFIED: config/config.exs; lib/scoria/application.ex; test/scoria/eval/campaign_worker_test.exs] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| A dedicated review-queue projection [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] | Template-side joins directly in LiveView [ASSUMED] | Rejected because Scoria already treats operator queues as curated projections, not page-local data assembly. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex] |
| Reusing Phase 39 promotion seams [VERIFIED: lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex] | Auto-promoting low-score traces into sealed baselines [ASSUMED] | Rejected because milestone state and requirements explicitly forbid automatic mutation of sealed baseline datasets. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md] |

**Installation:**
```bash
# No new dependencies are recommended for Phase 40.
```
[VERIFIED: mix.exs; mix.lock]

**Version verification:** `mix.lock` pins Oban `2.22.1`, Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, `ecto_sql` `3.13.5`, `req` `0.5.18`, and `req_llm` `1.12.0`, and the official Hex package API confirms the publish dates used above. [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/oban; https://hex.pm/api/packages/phoenix; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql; https://hex.pm/api/packages/req_llm]

## Architecture Patterns

### System Architecture Diagram

```text
Production trace + workflow evidence persisted
        |
        v
Trace eligibility sampler
  - selects eligible traces
  - records sampling provenance
  - never runs inline with request path
        |
        v
Scoring campaign coordinator
  - persists candidate/campaign rows
  - enqueues Oban jobs on :evals
        |
        v
Oban workers
  - deterministic rules first
  - optional judge scoring second
  - persist per-score evidence + aggregate status
        |
        +---------------------------+
        |                           |
        v                           v
Review queue projection      Existing workflow evidence
  - low-quality items          - /scoria/workflows/:id
  - policy-triggered items     - replay/provenance notebook
  - draft-promotion candidates
        |
        v
Operator queue UI
  - triage / dismiss / promote
  - deep link to trace/workflow evidence
        |
        v
Draft dataset promotion or sealed-baseline approval
  - open datasets -> Eval draft promotion
  - sealed baselines -> workflow-owned approval request
```
[VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/eval/campaign_worker.ex; lib/scoria/runtime/replay_comparison.ex; lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex]

### Recommended Project Structure
```text
lib/
├── scoria/eval/
│   ├── online_scoring.ex                 # sampling coordinator + enqueue boundary
│   ├── review_queue.ex                   # curated queue projection
│   ├── deterministic_scorer.ex           # deterministic-first rules
│   ├── campaign_enqueuer.ex              # extend, do not replace
│   └── campaign_worker.ex                # extend to persist richer score evidence
├── scoria_web/live/
│   ├── orchestrator_live.ex              # optional queue summary hook-in
│   └── review_queue_live/                # dedicated queue page if needed
├── scoria_web/components/
│   └── review_queue_component.ex         # queue rows, rationale, action buttons
└── scoria/workflows/
    └── dataset_promotion.ex              # keep sealed-baseline gating here
```
[ASSUMED]

### Pattern 1: Sample First, Enqueue Later, Never Score Inline
**What:** Put production-trace selection and queue insertion behind a backend boundary that records sampling metadata and only then enqueues Oban jobs. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/campaign_enqueuer.ex]
**When to use:** Every asynchronous online-scoring trigger, whether periodic, manual, or post-trace ingestion. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED]
**Example:**
```elixir
# Source: lib/scoria/eval/campaign_enqueuer.ex + https://hexdocs.pm/ecto/Ecto.Multi.html
Multi.new()
|> Multi.insert(:candidate, Candidate.changeset(%Candidate{}, attrs))
|> Multi.run(:campaign, fn _repo, %{candidate: candidate} ->
  Eval.create_and_enqueue_campaign(%{
    tenant_id: candidate.tenant_id,
    eval_spec_id: candidate.eval_spec_id,
    targets: build_targets(candidate)
  })
end)
|> Repo.transaction()
```
[VERIFIED: lib/scoria/eval/campaign_enqueuer.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Pattern 2: Deterministic Rules Before Optional Judge Calls
**What:** Run cheap deterministic checks first, then optionally invoke the judge model only for traces that need model-based review. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/eval_spec.ex; lib/scoria/eval/judge_runner.ex]
**When to use:** Every scorer pipeline that mixes policy/rule failures with subjective quality scoring. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: requirement-driven recommendation over existing judge path
with {:ok, rule_scores} <- DeterministicScorer.score(candidate),
     {:ok, judge_scores} <- maybe_run_judge(rule_scores, candidate) do
  persist_scores(candidate, rule_scores ++ judge_scores)
end
```
[VERIFIED: lib/scoria/eval/judge_runner.ex] [ASSUMED]

### Pattern 3: Persist Score Metadata at the Score Boundary
**What:** Store scorer version, scorer kind, judge model, and sampling provenance on each score or score-adjacent evidence row, not only on `EvalRun`. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/eval_run.ex; lib/scoria/eval/score.ex]
**When to use:** Any score row that could later appear in a queue or justify promotion. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: local score/judge mismatch indicates the missing target shape
%{
  eval_run_id: eval_run.id,
  dataset_item_id: dataset_item.id,
  score: 0.42,
  status: "failed",
  explanation: "Missing required policy disclaimer",
  scorer_kind: "deterministic_rule",
  scorer_version: "policy-rules@2026.05.23",
  judge_model: nil,
  evidence_refs: %{"trace_id" => trace_id},
  metadata: %{"sample_rate" => 0.05}
}
```
[VERIFIED: lib/scoria/eval/judge_runner.ex; test/scoria/eval/campaign_worker_test.exs] [ASSUMED]

### Pattern 4: Build Review Queues as Projections, Not Ad Hoc Filters
**What:** Build a curated queue module that returns operator-ready rows with severity, rationale, and deep links. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex]
**When to use:** Any page that shows low-quality traces, policy-triggered traces, or promotion candidates. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: lib/scoria/workflows/remote_approval_projection.ex
def list_review_queue(filters \\ %{}) do
  ReviewItem
  |> apply_filters(filters)
  |> order_by([item], desc: item.inserted_at)
  |> Repo.all()
  |> Enum.map(&project_review_item/1)
end
```
[VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] [ASSUMED]

### Anti-Patterns to Avoid
- **Second async engine:** Do not add a GenServer-only scoring loop when Oban already provides durable queues, retries, uniqueness, and test helpers. [VERIFIED: config/config.exs; lib/scoria/application.ex; test/scoria/eval/campaign_worker_test.exs] [CITED: https://hexdocs.pm/oban/Oban.Worker.html; https://hexdocs.pm/oban/testing.html]
- **Judge-only scoring:** Do not make LLM judges the only scorer path when `SCOR-02` explicitly calls for deterministic-first rules. [VERIFIED: .planning/REQUIREMENTS.md]
- **Queue items without durable evidence links:** Do not render a queue row that cannot resolve back to `trace_id` and `workflow_run_id` or equivalent rationale evidence. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex]
- **Auto-promotion into sealed baselines:** Do not collapse “reviewable candidate” and “baseline mutation” into one action. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md; lib/scoria/workflows/dataset_promotion.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Background retries and queue priority | Custom retry loop | Oban worker semantics | Oban already defines queue, priority, uniqueness, and runtime overrides, and the repo already uses it. [VERIFIED: lib/scoria/eval/campaign_worker.ex; lib/scoria/eval/campaign_enqueuer.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Transactional fan-out persistence | Manual nested `Repo.insert` chains | `Ecto.Multi` | Candidate, campaign, run, and queue writes should commit or roll back together. [VERIFIED: lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/workflows.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Review queue reads | Inline LiveView queries with shaping logic | A projection module modeled after `RemoteApprovalProjection` | Scoria already uses projection boundaries for operator inboxes. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex] |
| Baseline approval gating | UI-only confirmation path | `Scoria.Workflows.request_baseline_promotion/1` | The workflow-owned approval seam already preserves lineage and keeps sealed datasets immutable. [VERIFIED: lib/scoria/workflows/dataset_promotion.ex; test/scoria/workflows/remote_approval_projection_test.exs] |

**Key insight:** Phase 40 mostly needs new durable contracts and projections, not new infrastructure primitives. [VERIFIED: lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/workflows/remote_approval_projection.ex; lib/scoria/eval/dataset_promotion.ex]

## Common Pitfalls

### Pitfall 1: Planning Around the Wrong Persistence Shape
**What goes wrong:** The phase starts building a queue UI before the system has a stable persisted concept of “reviewable scored candidate.” [VERIFIED: local code inspection]
**Why it happens:** The repo has traces, campaigns, runs, scores, approvals, and promotion flows, but no dedicated online-scoring candidate or review-item projection yet. [VERIFIED: lib/scoria/repo/trace.ex; lib/scoria/eval/eval_campaign.ex; lib/scoria/eval/eval_run.ex; lib/scoria/eval/score.ex; lib/scoria/workflows/remote_approval_projection.ex]
**How to avoid:** Make the first plan slice define the durable scoring candidate and review projection contract before any UI work. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED]
**Warning signs:** Planned tasks start in LiveView templates without naming the table/module that owns review status. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex] [ASSUMED]

### Pitfall 2: Relying on the Current `Score` Schema as-Is
**What goes wrong:** Score rationale and provenance requirements cannot be implemented cleanly because the current schema surface is too narrow. [VERIFIED: lib/scoria/eval/score.ex; .planning/REQUIREMENTS.md]
**Why it happens:** `JudgeRunner` and tests build richer score attrs than `Score.changeset/2` or the original `ai_scores` migration currently expose. [VERIFIED: lib/scoria/eval/judge_runner.ex; test/scoria/eval/campaign_worker_test.exs; priv/repo/migrations/20260510174619_create_eval_tables.exs]
**How to avoid:** Treat score-evidence storage shape as a prerequisite design decision in Wave 0. [VERIFIED: local code inspection] [ASSUMED]
**Warning signs:** The plan talks about “storing judge model and scorer version on every score” without touching `Score` or adding an adjacent evidence table. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/score.ex] [ASSUMED]

### Pitfall 3: Confusing Trace Sampling with Workflow Deep Linking
**What goes wrong:** Queue items know a `trace_id` but cannot reliably link operators to the scored workflow evidence, or vice versa. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex]
**Why it happens:** There is no dedicated trace-detail route today, and the workflow evidence page lives at `/scoria/workflows/:id` while the trace-tree surface lives at `/scoria`. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex]
**How to avoid:** Persist both `trace_id` and `workflow_run_id` on reviewable items whenever available, and treat both links as first-class queue metadata. [VERIFIED: lib/scoria/workflows.ex; lib/scoria/observe/approval.ex; test/scoria/runtime_view_test.exs] [ASSUMED]
**Warning signs:** The proposed queue schema only stores one identifier and expects the UI to derive the other later. [VERIFIED: local code inspection] [ASSUMED]

### Pitfall 4: Letting Promotion Bypass Review State
**What goes wrong:** Low-quality or policy-triggered traces jump straight into dataset promotion without an operator queue stop. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Phase 39 already made promotion convenient, so it is tempting to call it directly from scoring completion. [VERIFIED: lib/scoria/eval/dataset_promotion.ex; lib/scoria_web/live/dataset_live/promote_component.ex]
**How to avoid:** Insert an explicit review-item state machine between score completion and any promotion action. [VERIFIED: SCOR-03; SCOR-04 requirements] [ASSUMED]
**Warning signs:** A background worker ends by calling `promote_workflow_source/1` or `request_baseline_promotion/1` automatically. [VERIFIED: lib/scoria/eval.ex; lib/scoria/workflows.ex] [ASSUMED]

## Code Examples

Verified patterns from official sources and local code:

### Oban Worker with Runtime Overrides
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html
defmodule MyApp.ScoreWorker do
  use Oban.Worker, queue: :evals, unique: [period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    :ok
  end
end

MyApp.ScoreWorker.new(%{"candidate_id" => id}, priority: 1)
```
[CITED: https://hexdocs.pm/oban/Oban.Worker.html]

### Manual Oban Testing Mode
```elixir
# Source: https://hexdocs.pm/oban/testing.html
config :my_app, Oban, testing: :manual

defmodule MyApp.WorkerTest do
  use Oban.Testing, repo: MyApp.Repo
end
```
[CITED: https://hexdocs.pm/oban/testing.html]

### Existing Campaign Enqueue Pattern
```elixir
# Source: lib/scoria/eval/campaign_enqueuer.ex
assert {:ok, result} =
         Eval.create_and_enqueue_campaign(%{
           tenant_id: "tenant-root",
           eval_spec_id: eval_spec.id,
           targets: [
             %{tenant_id: "tenant-alpha", provider: "openai", model: "gpt-4o-mini"}
           ]
         })
```
[VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/campaign_enqueuer.ex; test/scoria/eval/campaign_enqueue_test.exs]

### Existing Workflow-Owned Baseline Gating
```elixir
# Source: lib/scoria/workflows/dataset_promotion.ex
Workflows.request_baseline_promotion(%{
  dataset_id: dataset.id,
  workflow_run_id: run.id,
  workflow_step_id: step.id,
  source_variant: "replay",
  provenance: %{...},
  checkpoint_output: %{...},
  safety: %{...},
  promotion_snapshot: %{...}
})
```
[VERIFIED: lib/scoria/workflows/dataset_promotion.ex; test/scoria/workflows/remote_approval_projection_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic eval runs against sealed datasets only. [VERIFIED: lib/scoria/eval/judge_runner.ex; lib/scoria/eval/eval_spec.ex] | Campaign-based async eval fan-out now exists with per-target rows, queue metadata, and worker idempotency. [VERIFIED: lib/scoria/eval/campaign_enqueuer.ex; lib/scoria/eval/campaign_worker.ex; priv/repo/migrations/20260521000000_create_eval_campaigns_and_targets.exs] | Introduced by the campaign migration on `2026-05-21`. [VERIFIED: priv/repo/migrations/20260521000000_create_eval_campaigns_and_targets.exs] | Phase 40 should extend campaigns rather than create a separate scoring-run model. [VERIFIED: lib/scoria/eval/eval_campaign.ex; lib/scoria/eval/eval_campaign_target.ex] |
| Draft promotion was a generic dataset action. [VERIFIED: Phase 24 history; lib/scoria/eval.ex] | Phase 39 added replay-aware draft promotion and workflow-owned sealed-baseline approvals. [VERIFIED: .planning/STATE.md; lib/scoria/eval/dataset_promotion.ex; lib/scoria/workflows/dataset_promotion.ex] | Completed in Phase 39 on `2026-05-23`. [VERIFIED: .planning/STATE.md] | Review-queue actions can reuse these promotion seams instead of inventing new ones. [VERIFIED: test/scoria_web/live/dataset_live/promote_component_test.exs] |
| Operator queue pattern previously centered on approvals. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; lib/scoria_web/live/orchestrator_live.ex] | The next natural queue type is scored review items with rationale and deep links. [VERIFIED: SCOR-03 requirement; existing operator surfaces] [ASSUMED] | Phase 40 target. [VERIFIED: .planning/ROADMAP.md] | The projection pattern is established even though the score-review projection is not built yet. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] |

**Deprecated/outdated:**
- Treating `ai_scores` as a simple numeric-only table is outdated relative to `SCOR-02` if the requirement is taken literally. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/score.ex]
- Using only the approval inbox as the operator queue model is outdated for this milestone because Phase 40 explicitly adds a dedicated review queue. [VERIFIED: .planning/ROADMAP.md; lib/scoria_web/live/orchestrator_live.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new repo-local persistence layer such as `online_scoring` plus `review_queue` is the cleanest Phase 40 shape rather than reusing `EvalCampaign` rows directly as operator queue rows. [ASSUMED] | Recommended Project Structure; Summary | Medium; if campaigns themselves must double as queue items, the planner should collapse one layer. |
| A2 | Deterministic rule scores should skip judge calls when they already produce a terminal review verdict. [ASSUMED] | Pattern 2 | Low to medium; if product wants both always recorded, the worker contract changes but the persistence advice still stands. |
| A3 | Queue items should persist both `trace_id` and `workflow_run_id` whenever available because the current UI has separate trace and workflow surfaces. [ASSUMED] | Pitfall 3 | Medium; if one identifier can always derive the other, the queue schema can be simpler. |
| A4 | The score evidence mismatch should be fixed by extending `Score` or by adding an adjacent score-evidence table before full Phase 40 implementation. [ASSUMED] | Summary; Pitfall 2 | High; if the repo is intentionally split elsewhere, planning around the wrong storage layer will create rework. |

## Open Questions

1. **What durable row is the operator queue actually reading?**
   - What we know: campaigns, runs, and scores exist, but there is no current review-item projection or table. [VERIFIED: lib/scoria/eval/eval_campaign.ex; lib/scoria/eval/eval_run.ex; lib/scoria/eval/score.ex; lib/scoria/workflows/remote_approval_projection.ex]
   - What's unclear: whether queue state should live on a new table, on `EvalCampaignTarget`, or on a score-adjacent projection. [VERIFIED: local code inspection]
   - Recommendation: make this the first planning decision and do not start UI work until it is locked. [ASSUMED]

2. **How should score-level rationale be stored?**
   - What we know: `JudgeRunner` and tests expect score fields that `Score` does not currently expose. [VERIFIED: lib/scoria/eval/judge_runner.ex; lib/scoria/eval/score.ex; test/scoria/eval/campaign_worker_test.exs]
   - What's unclear: whether the intended fix is schema expansion, a new evidence table, or uncommitted local drift. [VERIFIED: local code inspection]
   - Recommendation: add a Wave 0 verification slice or explicit prerequisite plan to reconcile this before Phase 40 execution. [ASSUMED]

3. **What makes a production trace “eligible”?**
   - What we know: traces and spans are persisted, but there is no named sampler or eligibility boundary yet. [VERIFIED: lib/scoria/repo/trace.ex; lib/scoria/repo/span.ex]
   - What's unclear: whether eligibility is based on attributes, workflow outcomes, tenant policy, replayability, or something else. [VERIFIED: local code inspection]
   - Recommendation: define a narrow eligibility contract in the first plan and store the sampling rationale durably. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Compilation and ExUnit | ✓ [VERIFIED: `command -v mix`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| Erlang/OTP | Elixir runtime | ✓ [VERIFIED: `command -v elixir`] | `OTP 28` [VERIFIED: `elixir --version`] | — |
| PostgreSQL | Oban + Ecto persistence | ✓ [VERIFIED: `pg_isready`] | accepting connections on `5432` [VERIFIED: `pg_isready`] | — |
| Oban | Async scoring path | ✓ [VERIFIED: mix.lock; app config] | `2.22.1` [VERIFIED: mix.lock] | No fallback recommended. [VERIFIED: config/config.exs; lib/scoria/application.ex] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit above]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit above]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView test support and `Oban.Testing`. [VERIFIED: test/test_helper.exs; test/scoria_web/live/workflow_live_test.exs; test/scoria/eval/campaign_worker_test.exs] |
| Config file | `test/test_helper.exs` plus `config/test.exs`. [VERIFIED: test/test_helper.exs; config/test.exs] |
| Quick run command | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs`. [VERIFIED: existing test file paths] |
| Full suite command | `mix test`. [VERIFIED: test/test_helper.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOR-01 | Eligible production traces are sampled asynchronously and scoring is executed via Oban without inline request latency. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration | `mix test test/scoria/eval/campaign_enqueue_test.exs test/scoria/eval/campaign_worker_test.exs` | Partial coverage exists for enqueue/worker behavior, but no production-trace sampler tests exist yet. [VERIFIED: test/scoria/eval/campaign_enqueue_test.exs; test/scoria/eval/campaign_worker_test.exs] |
| SCOR-02 | Deterministic-first and optional judge-based scoring both persist scorer metadata and provenance. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scoria/eval/campaign_worker_test.exs` | Judge-path tests exist, but deterministic scorer and per-score provenance tests do not. [VERIFIED: test/scoria/eval/campaign_worker_test.exs] |
| SCOR-03 | Operators can review low-quality/policy-triggered traces in a dedicated queue with rationale and deep links. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView + projection | `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | Queue-like projection tests exist only for approvals, not for scored review items. [VERIFIED: test/scoria/workflows/remote_approval_projection_test.exs; lib/scoria_web/live/orchestrator_live.ex] |
| SCOR-04 | Draft promotion candidates remain reviewable and separate from sealed baselines until explicit approval. [VERIFIED: .planning/REQUIREMENTS.md] | integration + LiveComponent | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/workflows/remote_approval_projection_test.exs` | Phase 39 promotion and baseline-approval tests exist, but no score-driven candidate review tests exist yet. [VERIFIED: test/scoria_web/live/dataset_live/promote_component_test.exs; test/scoria/workflows/remote_approval_projection_test.exs] |

### Sampling Rate
- **Per task commit:** run the narrow slice relevant to worker/persistence or queue/projection changes. [VERIFIED: existing test suite layout]
- **Per wave merge:** `mix test`. [VERIFIED: test/test_helper.exs]
- **Phase gate:** full suite green before `/gsd-verify-work`. [VERIFIED: workflow instructions in prompt]

### Wave 0 Gaps
- [ ] Add a test that defines and verifies trace eligibility and sampling provenance. [VERIFIED: no existing sampler tests found via codebase search]
- [ ] Reconcile or redesign score-level evidence persistence before writing review-queue code. [VERIFIED: lib/scoria/eval/score.ex; lib/scoria/eval/judge_runner.ex; test/scoria/eval/campaign_worker_test.exs]
- [ ] Add review-queue projection tests comparable to `RemoteApprovalProjectionTest`. [VERIFIED: test/scoria/workflows/remote_approval_projection_test.exs]
- [ ] Add LiveView tests for queue triage plus deep links into existing operator surfaces. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: queue actions and approvals are operator actions on LiveView surfaces] | Reuse existing session-backed LiveView identity and do not fall back to anonymous promotion decisions in production paths. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/workflow_live/show.ex] [ASSUMED] |
| V3 Session Management | yes [VERIFIED: operator UI is LiveView-driven] | Keep triage and promotion actions inside existing LiveView sessions and workflow-owned service calls. [VERIFIED: lib/scoria_web/router.ex; lib/scoria/workflows.ex] |
| V4 Access Control | yes [VERIFIED: review decisions and baseline approvals mutate durable truth] | Preserve workflow-owned approval gating for sealed baselines and keep review dismissal/promotion behind backend validation. [VERIFIED: lib/scoria/workflows/dataset_promotion.ex; lib/scoria/eval/dataset_item.ex] |
| V5 Input Validation | yes [VERIFIED: scorer attrs, queue filters, and promotion payloads are persisted from operator/backend input] | Use changesets and explicit projection filters rather than raw map writes. [VERIFIED: lib/scoria/eval/eval_campaign.ex; lib/scoria/eval/eval_campaign_target.ex; lib/scoria/workflows/remote_approval_projection.ex] |
| V6 Cryptography | no [VERIFIED: this phase does not add new crypto primitives] | Keep using existing IDs and audit evidence; do not add homegrown signature schemes for score provenance. [VERIFIED: local code inspection] [ASSUMED] |

### Known Threat Patterns for Phoenix + Oban Review Pipelines

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Queue spoofing through incomplete candidate lineage | Spoofing | Persist candidate lineage (`trace_id`, `workflow_run_id`, tenant identity, sampler version) before enqueue. [VERIFIED: SCOR-01; SCOR-02 requirements] [ASSUMED] |
| Review-state bypass into promotion | Tampering | Require explicit review-item transitions before draft promotion or baseline approval requests. [VERIFIED: SCOR-03; SCOR-04 requirements] [ASSUMED] |
| Score rationale mismatch or loss | Repudiation | Persist scorer version, judge model, rationale, and evidence refs on every score path. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/judge_runner.ex] |
| Overexposing raw trace payloads in queue UIs | Information Disclosure | Show curated rationale summaries and deep-link to detailed evidence instead of dumping full payloads in list rows. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/live/orchestrator_live.ex] [ASSUMED] |
| Judge fan-out overload or starvation | Denial of Service | Keep scoring on the existing `:evals` queue with explicit priority and uniqueness settings, and make deterministic scoring capable of short-circuiting. [VERIFIED: config/config.exs; lib/scoria/eval/campaign_worker.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Silent baseline mutation from automated scoring | Elevation of Privilege | Route sealed-baseline actions only through `request_baseline_promotion/1`. [VERIFIED: lib/scoria/workflows/dataset_promotion.ex; test/scoria/workflows/remote_approval_projection_test.exs] |

## Sources

### Primary (HIGH confidence)
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` - phase scope, requirements, and locked milestone decisions. [VERIFIED: local planning artifacts]
- `mix.exs`, `mix.lock`, `config/config.exs`, `config/test.exs`, `lib/scoria/application.ex` - current stack and Oban runtime/testing configuration. [VERIFIED: local code inspection]
- `lib/scoria/eval.ex`, `lib/scoria/eval/campaign_enqueuer.ex`, `lib/scoria/eval/campaign_worker.ex`, `lib/scoria/eval/eval_campaign.ex`, `lib/scoria/eval/eval_campaign_target.ex`, `lib/scoria/eval/eval_run.ex`, `lib/scoria/eval/eval_spec.ex`, `lib/scoria/eval/judge_runner.ex`, `lib/scoria/eval/score.ex` - current eval/scoring persistence and execution seams. [VERIFIED: local code inspection]
- `lib/scoria/repo/trace.ex` and `lib/scoria/repo/span.ex` - current production trace persistence surface. [VERIFIED: local code inspection]
- `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_detail.ex`, and `lib/scoria/runtime/replay_comparison.ex` - current workflow evidence and promotion context seams. [VERIFIED: local code inspection]
- `lib/scoria/workflows/dataset_promotion.ex` and `lib/scoria/workflows/remote_approval_projection.ex` - current approval-safe promotion and operator queue projection patterns. [VERIFIED: local code inspection]
- `lib/scoria_web/router.ex`, `lib/scoria_web/live/orchestrator_live.ex`, and `lib/scoria_web/live/workflow_live/show.ex` - current operator-visible routes and deep-link surfaces. [VERIFIED: local code inspection]
- `test/scoria/eval/campaign_enqueue_test.exs`, `test/scoria/eval/campaign_worker_test.exs`, `test/scoria/workflows/remote_approval_projection_test.exs`, `test/scoria_web/live/dataset_live/promote_component_test.exs` - verified local behavior and existing extension points. [VERIFIED: local code inspection]
- Oban worker and testing docs. [CITED: https://hexdocs.pm/oban/Oban.Worker.html; https://hexdocs.pm/oban/testing.html]
- Phoenix LiveView docs for router-mounted param handling and patch navigation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Ecto docs for `Ecto.Multi`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Hex package APIs for Oban, Phoenix, Phoenix LiveView, `ecto_sql`, and `req_llm`. [CITED: https://hex.pm/api/packages/oban; https://hex.pm/api/packages/phoenix; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql; https://hex.pm/api/packages/req_llm]

### Secondary (MEDIUM confidence)
- `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-RESEARCH.md` - prior phase decomposition and operator-surface precedent. [VERIFIED: local artifact]

### Tertiary (LOW confidence)
- None. [VERIFIED: all framework/package claims are backed by official docs or official package APIs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current versions and queue/testing behavior were verified from `mix.lock`, app config, and official package/docs sources. [VERIFIED: mix.lock; config/config.exs; config/test.exs] [CITED: https://hex.pm/api/packages/oban; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql]
- Architecture: HIGH - the relevant eval, workflow, trace, and UI seams already exist locally and were inspected directly. [VERIFIED: lib/scoria/eval.ex; lib/scoria/runtime.ex; lib/scoria/workflows.ex; lib/scoria_web/router.ex]
- Pitfalls: HIGH - the major risks are concrete repo-specific gaps, especially score evidence persistence and missing queue contracts. [VERIFIED: lib/scoria/eval/score.ex; lib/scoria/eval/judge_runner.ex; lib/scoria_web/live/orchestrator_live.ex]

**Research date:** 2026-05-23 [VERIFIED: current session date]
**Valid until:** 2026-06-22 for codebase-specific findings, or sooner if the Phase 40 scope or eval persistence contracts change. [ASSUMED]
