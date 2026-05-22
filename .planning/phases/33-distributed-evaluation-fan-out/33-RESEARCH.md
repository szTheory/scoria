# Phase 33: Distributed Evaluation Fan-out - Research

**Researched:** 2026-05-21
**Requirement focus:** `EVAL-02`

## Planning Answer

What needs to be true to plan this phase well:

- The new durable parent truth should be an `EvalCampaign` row with eager aggregate counters and terminal status, not a derived read model reconstructed from `EvalRun` rows.
- `EvalRun` remains the canonical child execution truth and should be extended with campaign lineage and tenant identity instead of replaced.
- Fan-out must use the existing `Scoria.Workflows.BatchEnqueue` + `Oban.insert_all` seam on the `:evals` queue, not ad hoc insert loops or `Task.async_stream`.
- Worker execution should stay inside the existing eval boundary and call the orchestration layer already established in Phase 32, preserving fallback, retry, and telemetry behavior.
- Tenant identity must be explicit on campaigns, targets, eval runs, and queued job args so large campaigns stay inspectable and replay-safe.
- Campaign completion semantics should default to partial completion for shard-local failures, with fatal terminal failure reserved for invalid contracts, credential/config invariants, or persistence-integrity failures.

## Recommended Architecture

### Coordinator truth

- Add `Scoria.Eval.EvalCampaign` as a parent aggregate row with:
  - `tenant_id`
  - `eval_spec_id`
  - status enum/string including `queued`, `running`, `completed`, `completed_partial`, `failed_fatal`, `cancelled`
  - eager counters for `total_targets`, `queued_targets`, `running_targets`, `completed_targets`, `failed_targets`, `cancelled_targets`
  - timestamps for `started_at`, `finished_at`, `last_progress_at`
  - summary metadata for fatal error code / last error context if needed
- Add `Scoria.Eval.EvalCampaignTarget` as an explicit child row carrying execution-only metadata:
  - `tenant_id`
  - `campaign_id`
  - provider/model target selection
  - queue/priority hints
  - per-target status and timestamps
  - optional linkage to spawned `eval_run_id`

### Child execution truth

- Extend `Scoria.Eval.EvalRun` with:
  - `campaign_id`
  - `campaign_target_id`
  - `tenant_id`
- Keep `Score` as the per-item durable evidence row.
- Keep campaign aggregate truth cheap to read while preserving `EvalRun` + `Score` as the auditable evidence lineage.

### Enqueue path

- Campaign creation should live in `Scoria.Eval`, using `Ecto.Multi` to:
  - validate the immutable `EvalSpec`
  - create the campaign parent
  - create target rows
  - build all worker jobs
  - insert jobs through `Scoria.Workflows.BatchEnqueue`
  - move campaign status to `queued`
- Jobs must land on the dedicated `:evals` queue from Phase 30.

### Worker path

- Add a dedicated Oban worker for one target shard.
- Normalize job args through a `new_job/2` helper, following existing worker patterns.
- Each worker should:
  - mark target/campaign progress as running
  - create or attach the target `EvalRun`
  - execute through the eval/orchestrator path already in the repo
  - persist scores and final run facts
  - finalize target status and aggregate campaign counters in one transaction
- Worker-local failures should become target-local failures by default; campaign fatal failure should be reserved for explicitly fatal classes.

## Existing Code Patterns To Reuse

- `lib/scoria/eval.ex`
  - canonical Ecto context for eval persistence
  - `create_eval_run/1`, `record_eval_scores/2`, `complete_eval_run/2`
- `lib/scoria/eval/eval_run.ex`
  - current child execution truth schema and validation posture
- `lib/scoria/workflows/batch_enqueue.ex`
  - chunked `Oban.insert_all` fan-out seam
- `lib/scoria/compaction/summarize_worker.ex`
  - `Oban.Worker` uniqueness, normalized job args, and transactional finalization shape
- `lib/scoria/connectors/discovery_job.ex`
  - small `new_job/2` + args normalization pattern
- `lib/scoria/orchestrator.ex`
  - execution boundary with fallback telemetry
- `lib/scoria/eval/judge_runner.ex`
  - current live eval path that already routes through the orchestrator
- `lib/scoria/sre/telemetry_identity.ex`
  - low-cardinality tenant/provider/model metadata pattern for telemetry

## Risks And Constraints

### Main risks

- Reconstructing campaign status entirely from child rows will create expensive reads and race-prone operator truth.
- Bypassing `BatchEnqueue` or `:evals` queue segregation risks DB contention and queue starvation.
- Letting target rows carry semantic eval overrides will quietly create a second eval-spec system.
- Whole-campaign cancellation semantics are best-effort only; plans should not assume transactional cancellation across already-running jobs.

### Product constraints

- Stay embedded and Phoenix/Ecto-native.
- Do not widen into a hosted eval platform.
- Keep dashboard projection concerns secondary to durable Ecto truth; rich real-time operator UX belongs mainly to Phase 34.

## Suggested Plan Split

1. Persistence foundation:
   add campaign and target schemas, migration, `EvalRun` lineage fields, and canonical `Scoria.Eval` APIs with persistence tests.
2. Coordinator fan-out:
   add campaign creation + target normalization + batch enqueue path on `:evals`, with tests for chunking and target/job lineage.
3. Worker execution and rollup:
   add target worker execution, result persistence, partial/fatal status handling, aggregate counter updates, and telemetry/progress tests.

## Verification Lanes

- `mix test test/scoria/eval/*campaign*.exs`
- `mix test test/scoria/workflows/batch_enqueue_test.exs`
- focused worker tests proving queue assignment, orchestrator execution path, durable result persistence, and aggregate counter rollup

## Sources

- `.planning/phases/33-distributed-evaluation-fan-out/33-CONTEXT.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-PATTERNS.md`
- `.planning/milestones/v1.8-REQUIREMENTS.md`
- `.planning/research/08-vanguard-ARCHITECTURE.md`
- `.planning/research/08-vanguard-PITFALLS.md`
- `lib/scoria/eval.ex`
- `lib/scoria/eval/eval_run.ex`
- `lib/scoria/eval/judge_runner.ex`
- `lib/scoria/orchestrator.ex`
- `lib/scoria/workflows/batch_enqueue.ex`
- `lib/scoria/compaction/summarize_worker.ex`
- `lib/scoria/connectors/discovery_job.ex`
- `lib/scoria/sre/telemetry_identity.ex`
