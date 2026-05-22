# Phase 37: Replay Lineage & Branch Model - Patterns

**Date:** 2026-05-22
**Status:** Complete

## Purpose

Map the files Phase 37 is likely to modify to the closest existing analogs in the repo so planning and execution can extend proven workflow/runtime patterns instead of inventing a replay-only subsystem.

## Primary Pattern Family

### Pattern: persisted lineage outranks replay envelope

**What it is**
- A durable parent/child or source/target relationship is stored in typed fields.
- Runtime envelopes may carry inspectable context, but they do not redefine truth.
- Public surfaces project from persisted lineage, not transient payloads.

**Best analogs**
- `.planning/phases/33-distributed-evaluation-fan-out/33-03-PLAN.md`
- `lib/scoria/workflows.ex`
- `lib/scoria/runtime/run_detail.ex`

**How to reuse it**
- Persist `source_run_id`, `source_checkpoint_id`, `execution_mode`, and bounded replay overrides on the new branch run.
- Treat replay request params as seed input only; after insert, the branch run row is authoritative.
- Surface replay lineage through DTOs and views from persisted fields, not ad hoc assigns.

## Concrete Analog Notes

### 1. `Scoria.Workflows.create_run/1` is the strongest creation analog

Why:
- It already inserts a run plus initial checkpoint/event in one transactional flow.
- It updates `latest_checkpoint_id` as part of the same durable operation.

Reuse:
- branch creation should follow the same multi-step transactional shape
- add a replay-specific initial checkpoint/event instead of creating a second lifecycle path

### 2. `RunSummary` + `RunDetail` are the strongest public projection analogs

Why:
- they define the stable public runtime inspection contract
- UI layers already consume them as curated truth

Reuse:
- add typed replay lineage fields here before reading them in LiveView
- keep templates off raw `metadata`

### 3. `WorkflowLive.Show` is the strongest operator-surface analog

Why:
- it already renders a durable run tree with header, status, selected checkpoint, and evidence side panels
- it subscribes to run updates rather than owning workflow state

Reuse:
- add replay lineage summary in header/detail panel
- keep the page projection-only; do not put branch logic in LiveView

### 4. Orchestrator trace actions show the right “trace surface as projection” posture

Why:
- `orchestrator_live` handles trace actions with run-linked evidence, badges, and lazy projections
- traces are already treated as operator-facing evidence views rather than the canonical workflow store

Reuse:
- expose replay lineage through a trace-facing read seam or enriched projection
- avoid making `ai_traces` the sole canonical lineage store

## File Mapping

| Target file | Role | Closest analog | Reuse pattern |
|-------------|------|----------------|---------------|
| `lib/scoria/workflows/run.ex` | Typed durable run truth | `lib/scoria/eval/eval_run.ex` lineage-style additive fields | Add explicit replay lineage fields and validate bounded execution-mode values |
| `priv/repo/migrations/TIMESTAMP_add_replay_lineage_to_workflow_runs.exs` | Additive schema evolution | `priv/repo/migrations/20260513000100_add_canonical_identity_to_workflow_runs.exs` | Add nullable typed columns plus indexes without breaking old rows |
| `lib/scoria/workflows.ex` | Transactional replay branch creation | `create_run/1`, `append_checkpoint/3`, `complete_step/3` | Create new run + replay-start checkpoint/event atomically and leave source run unchanged |
| `lib/scoria/runtime/run_summary.ex` | Stable summary DTO | existing summary struct | Add small explicit lineage fields for list/polling consumers |
| `lib/scoria/runtime/run_detail.ex` | Detailed public DTO | existing detail struct | Add a replay lineage block derived from persisted fields and checkpoint metadata |
| `lib/scoria_web/live/workflow_live/show.ex` | Workflow run operator page | existing run header + selection flow | Render replay lineage from DTO/run fields only |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | Dense operator detail surface | current checkpoint snapshot and failure sections | Add replay source/mode/override section next to checkpoint detail |
| `lib/scoria_web/live/orchestrator_live.ex` | Trace-facing operator projection | current lazy retrieval/budget/incident evidence loads | Attach replay lineage via run-linked projection, not by inventing new trace mutation flows |
| `test/scoria/workflows/replay_branch_test.exs` | Focused branch truth coverage | `test/scoria/workflows_test.exs` | Build source run + checkpoint fixtures, branch once, assert immutability and lineage |

## Execution Patterns To Preserve

### Pattern: transactionally append durable evidence when lifecycle changes

Use for:
- replay branch creation
- replay-start checkpoint/event emission

Do:
- create the new run, seed initial replay checkpoint, seed initial replay event, and update `latest_checkpoint_id` in one transaction

Do not:
- create the run first and append replay evidence later in a best-effort follow-up

### Pattern: public DTO first, template second

Use for:
- `RunSummary`
- `RunDetail`
- workflow LiveView rendering

Do:
- extend DTOs before updating templates
- read explicit fields in templates

Do not:
- reach into `run.metadata["replay"]` directly from HEEx

### Pattern: additive schema, compatibility-preserving defaults

Use for:
- replay lineage migration

Do:
- add nullable or defaulted columns compatible with pre-Phase-37 rows
- index source-run/source-checkpoint lookup paths needed by operator reads

Do not:
- require synthetic backfill for historical runs unless a safe source exists

## Read-First Recommendations For Execution

Before touching `lib/scoria/workflows.ex`, read:
- `lib/scoria/workflows/run.ex`
- `lib/scoria/workflows/checkpoint.ex`
- `test/scoria/workflows_test.exs`

Before touching `lib/scoria/runtime/run_summary.ex` or `run_detail.ex`, read:
- `lib/scoria/runtime.ex`
- `lib/scoria_web/live/workflow_live/show.ex`

Before touching workflow LiveView/components, read:
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `test/scoria_web/live/workflow_live_test.exs`

Before touching trace-facing projection code, read:
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria/repo/trace.ex`
- `test/scoria_web/live/orchestrator_live_test.exs`

## Footguns

- storing lineage only in `metadata`
- copying source checkpoints into the original run instead of the branch run
- introducing a replay-specific dispatcher instead of using the existing runtime/reconciler seam
- exposing replay lineage in workflow LiveView but not in `RunDetail`
- widening Phase 37 into all replay-safe side-effect rules or replay-vs-original diff UX

## Recommendation

Treat Phase 37 as an extension of the existing workflow truth model:
- additive typed schema
- transactional branch creation
- DTO-first public projection
- trace surfaces as downstream views over workflow lineage

## PATTERN MAPPING COMPLETE
