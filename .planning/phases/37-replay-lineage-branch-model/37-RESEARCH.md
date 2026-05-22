# Phase 37: Replay Lineage & Branch Model - Research

**Date:** 2026-05-22
**Status:** Complete

## Objective

Research what is needed to plan Phase 37 well: create replay branches as durable workflow runs rooted in existing checkpoint truth, without mutating the source run, and expose that lineage in the operator-facing workflow and trace surfaces.

## Key Findings

### 1. The workflow persistence layer is already the correct replay source of truth

`Scoria.Workflows` already owns durable run, step, checkpoint, event, approval, and handoff truth:
- `lib/scoria/workflows.ex`
- `lib/scoria/workflows/run.ex`
- `lib/scoria/workflows/checkpoint.ex`
- `priv/repo/migrations/20260511000100_create_workflow_tables.exs`

The current run lifecycle already persists:
- one root run row
- ordered step rows
- ordered checkpoint rows
- ordered event rows
- `latest_checkpoint_id` on the run

That means replay should branch from persisted workflow truth, not from transient trace state or a second replay-only engine.

### 2. The current schema lacks first-class replay lineage fields

The `ai_workflow_runs` schema currently stores identity, lifecycle, and generic `metadata`, but it has no typed replay lineage fields such as:
- `source_run_id`
- `source_checkpoint_id`
- `execution_mode`
- replay-override payload or replay reason

The `ai_workflow_checkpoints` schema likewise stores generic `snapshot` and `metadata`, but no typed branch provenance. For Phase 37 to satisfy `RPLY-01`, replay lineage must become durable, queryable truth rather than ad hoc JSON inferred from checkpoint payloads.

### 3. The best implementation posture is “new run seeded from existing checkpoint snapshot”

The least-surprise branch model is:
1. read the chosen source run and checkpoint
2. create a brand new workflow run row
3. persist typed replay lineage on that new run
4. seed the branch run with an initial replay-oriented checkpoint/event snapshot
5. dispatch through the existing workflow runtime/reconciler path

This reuses the same engine used by ordinary runs:
- `Scoria.Runtime.start_run/2`
- `Scoria.Workflows.create_run/1`
- `Scoria.Workflows.Reconciler.dispatch_run/2`

It also preserves the source run as immutable historical truth.

### 4. Public inspection DTOs will need explicit lineage fields

The public runtime inspection layer currently projects only generic run facts:
- `lib/scoria/runtime/run_summary.ex`
- `lib/scoria/runtime/run_detail.ex`

`RunSummary` does not expose replay mode or source lineage. `RunDetail` exposes steps, checkpoints, events, approvals, and handoffs, but not a replay lineage block. If lineage remains hidden in raw metadata, the workflow page and downstream API consumers will drift toward ad hoc JSON inspection.

Phase 37 should add explicit public DTO fields for:
- whether a run is a replay branch
- source run id
- source checkpoint id
- execution mode
- override metadata / replay parameters

### 5. The workflow LiveView is already the right first operator surface

The workflow run page already consumes durable run-tree truth:
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/workflow_tree_component.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- `test/scoria_web/live/workflow_live_test.exs`

That means the first user-visible replay lineage surface should land here. The page already shows:
- run status
- step tree
- selected checkpoint snapshot
- remote evidence and dataset promotion links

The missing piece is a replay lineage summary on the run header / detail panel, not a new page.

### 6. “Trace explorer” currently means the orchestrator trace stream, not a dedicated replay subsystem

The repo’s trace-facing operator surface is currently centered around:
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/components/trace_tree_component.ex`
- `lib/scoria/repo/trace.ex`

`ai_traces` currently stores `session_id` and generic `attributes`. There is no obvious typed `workflow_run_id` field on `Trace`, but the LiveView already passes around `run_id` alongside trace actions and evidence filters. Phase 37 should therefore plan for a minimal read-model join or trace-attribute projection that makes replay lineage queryable from trace-facing UI without redefining trace storage first.

The likely shape is:
- enrich workflow or trace-facing projection code with replay lineage
- avoid widening `Trace` prematurely unless the current evidence seam cannot carry the needed `run_id`

### 7. Prior replay-safe and lineage precedents already exist in adjacent phases

Useful analogs:
- Phase 21 emphasized explicit replay as a workflow-owned action after durable evidence exists.
- Phase 33 used persisted lineage as authoritative truth even when replayed envelopes carried inspectable-but-non-authoritative fields.
- Eval work already distinguishes runner modes like `:offline_replay`.

The strongest reusable principles are:
- persisted lineage outranks replay request payloads
- replay must be explicit and operator-visible
- job/runtime envelopes may be inspectable, but they are not the source of truth

### 8. This phase should stop before replay-safe side-effect policy

The roadmap intentionally splits:
- Phase 37: branch lineage model
- Phase 38: replay-safe execution and tool modes

So Phase 37 should persist lineage and route through the existing engine, but it should not try to solve all “historical stub vs blocked live effect” semantics yet. It may persist an `execution_mode` field and default value, but the full safety contract belongs to Phase 38.

## Recommended Planning Decomposition

The cleanest decomposition is three plans:

1. Durable replay lineage persistence
- migration(s)
- typed run/checkpoint lineage fields
- workflow API for creating replay branches
- persistence and compatibility tests

2. Replay branch creation on the existing runtime seam
- branch-from-checkpoint API/service
- seed initial replay checkpoint/event state
- dispatch through existing runtime/reconciler path
- integration coverage proving source run immutability and runtime reuse

3. Replay lineage read models and operator visibility
- extend `RunSummary` / `RunDetail`
- expose lineage on workflow LiveView/detail panel
- surface lineage from trace-facing reads without inventing a second truth model
- add focused LiveView / DTO / projection tests

## Likely Files and Modules

### Persistence and workflow truth
- `lib/scoria/workflows.ex`
- `lib/scoria/workflows/run.ex`
- `lib/scoria/workflows/checkpoint.ex`
- `priv/repo/migrations/TIMESTAMP_add_replay_lineage_to_workflow_runs.exs`
- possibly `lib/scoria/workflows/event.ex` if replay-start events need explicit payload shape
- `test/scoria/workflows_test.exs`
- likely a new focused file such as `test/scoria/workflows/replay_branch_test.exs`

### Runtime and public DTOs
- `lib/scoria/runtime.ex`
- `lib/scoria/runtime/run_summary.ex`
- `lib/scoria/runtime/run_detail.ex`
- maybe `lib/scoria/workflows/reconciler.ex` or `lib/scoria/workflows/runtime.ex` if branch dispatch needs an explicit entry point

### Operator surfaces
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/workflow_detail_panel_component.ex`
- possibly `lib/scoria_web/components/workflow_tree_component.ex` if branch badges belong in the list
- `test/scoria_web/live/workflow_live_test.exs`

### Trace-facing read seams
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria/repo/trace.ex`
- `test/scoria_web/live/orchestrator_live_test.exs`
- possibly a workflow/trace projection helper if the current LiveView logic needs a durable query seam

## File-Specific Risks and Footguns

### `lib/scoria/workflows/run.ex`
- Risk: hiding replay lineage only in `metadata` instead of adding typed fields, which weakens queryability and validation.

### `lib/scoria/workflows.ex`
- Risk: cloning mutable source-run internals directly instead of creating a new run with explicit seeded replay state.
- Risk: letting replay request payload override canonical source lineage after the branch row is created.

### `lib/scoria/runtime/run_summary.ex` / `run_detail.ex`
- Risk: adding lineage only to one DTO, causing the workflow page and public API surfaces to diverge.

### `lib/scoria_web/live/workflow_live/show.ex`
- Risk: reading raw nested metadata in templates instead of consuming a stable DTO shape.

### `lib/scoria_web/live/orchestrator_live.ex`
- Risk: trying to solve all replay UX in this phase. Trace explorer only needs queryable lineage pointers now, not the full Phase 39 diff experience.

## Anti-Patterns To Avoid

- Creating a second replay-specific execution engine.
- Mutating the source run or source checkpoint when branching.
- Treating trace rows as the canonical replay source instead of workflow truth.
- Hiding replay lineage only inside generic metadata maps.
- Coupling Phase 37 to Phase 38 side-effect safety policy.
- Shipping workflow-page lineage without adding the same fields to the public DTOs.

## Verification Strategy

This phase needs:
- migration and schema compatibility proof
- persistence tests for typed lineage truth
- workflow integration tests proving source-run immutability and branch-run creation
- runtime/DTO tests for public detail exposure
- LiveView tests proving replay lineage is operator-visible

Recommended proof lanes:
- `mix test test/scoria/workflows_test.exs test/scoria/workflows/replay_branch_test.exs`
- `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs`
- `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs` or the exact focused DTO/runtime files created in this phase
- `mix ecto.migrate`
- `mix ecto.rollback --step 1`
- `mix ecto.migrate`

## Validation Architecture

| Requirement | Behavior | Test Type | Likely Command |
|-------------|----------|-----------|----------------|
| RPLY-01 | branch run persists typed source lineage and overrides | integration | `mix test test/scoria/workflows/replay_branch_test.exs` |
| RPLY-01 | source run history remains unchanged after branching | integration | `mix test test/scoria/workflows/replay_branch_test.exs` |
| RPLY-01 | runtime public detail exposes replay lineage fields | unit/integration | `mix test test/scoria/runtime_test.exs test/scoria/runtime_view_test.exs` |
| RPLY-01 | workflow LiveView renders replay source + mode | LiveView | `mix test test/scoria_web/live/workflow_live_test.exs` |
| RPLY-01 / Success criterion 3 | trace-facing UI can query replay lineage from run-linked evidence | LiveView/integration | `mix test test/scoria_web/live/orchestrator_live_test.exs` |

Wave 0 is not needed; the repo already has Ecto, workflow, runtime, and LiveView test infrastructure.

## Threat Notes

| Threat | Why it matters | Mitigation direction |
|--------|----------------|----------------------|
| Tampering | replay payload could rewrite source lineage | persist source ids once and derive execution from stored lineage, not mutable request payloads |
| Repudiation | operators could not prove which checkpoint a replay came from | add typed lineage fields and replay-start checkpoint/event evidence |
| Information disclosure | replay overrides may contain sensitive context | store only bounded replay metadata needed for operator truth; keep redaction posture consistent with existing evidence seams |
| Denial of service | schema/runtime drift could break normal runs | keep replay additions additive and reuse existing runtime paths rather than forking lifecycle logic |

## Recommendation

Plan Phase 37 as a three-plan package centered on typed workflow lineage truth. Land schema and workflow APIs first, branch through the existing runtime second, and only then expose lineage on workflow/trace read models. That is the smallest shape that satisfies `RPLY-01` without leaking into Phase 38 or Phase 39.

## RESEARCH COMPLETE
