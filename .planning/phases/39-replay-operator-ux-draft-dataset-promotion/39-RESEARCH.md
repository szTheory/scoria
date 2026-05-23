# Phase 39: Replay Operator UX & Draft Dataset Promotion - Research

**Researched:** 2026-05-23 [VERIFIED: current session date]
**Domain:** Phoenix LiveView operator UX, replay provenance projection, and eval dataset promotion [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**Confidence:** HIGH [VERIFIED: local code inspection plus official Phoenix LiveView, Ecto, and Hex package sources]

## User Constraints

- No `39-CONTEXT.md` exists yet, so this research is constrained by the roadmap, requirements, prior phase artifacts, the approved Phase 39 UI contract, and the explicit user prompt. [VERIFIED: `gsd-sdk query init.phase-op "39"` output; .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; user prompt]
- Treat the approved UI contract as the design source of truth for the operator surface. [VERIFIED: user prompt; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
- Keep this phase inside the existing `/scoria/workflows/:id` surface and do not invent a new top-level replay console or dataset page for the primary flow. [VERIFIED: user prompt; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
- Focus on existing workflow run LiveView/detail-panel surfaces, runtime DTOs, dataset promotion flows, approval/baseline semantics, and the smallest decomposition that satisfies the phase. [VERIFIED: user prompt]
- Phase 39 must address `RPLY-03`, `DATA-01`, and `DATA-02`. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
- Sealed datasets must remain immutable, and release-driving baseline promotion must never become a direct inline mutation path. [VERIFIED: .planning/REQUIREMENTS.md; .planning/STATE.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
- There is no project-root `AGENTS.md` or `CLAUDE.md`, and there are no project-local skill directories under `.agents/skills/` or `.claude/skills/`. [VERIFIED: project root listing; `find .agents/skills -maxdepth 2 -name SKILL.md`; `find .claude/skills -maxdepth 2 -name SKILL.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RPLY-03 | Operator can inspect replay provenance and compare replay output against the original run, including source checkpoint, overrides, and execution-mode evidence. [VERIFIED: .planning/REQUIREMENTS.md] | Use existing replay truth already persisted on runs, approvals, checkpoints, and events, but extend the runtime/detail projection and workflow UI so the right rail renders comparison-ready evidence instead of raw `inspect/1` blobs. [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; lib/scoria_web/components/workflow_detail_panel_component.ex] |
| DATA-01 | Operator can promote an original or replayed trace into a draft dataset item backed by a frozen evidence snapshot. [VERIFIED: .planning/REQUIREMENTS.md] | Replace the current ad hoc dataset modal save path with a promotion service that freezes source variant, replay provenance, step/checkpoint evidence, and optional expected output into dataset item `input`/`metadata` before insert. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex; lib/scoria_web/live/dataset_live/promote_component.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| DATA-02 | Sealed datasets remain immutable, and promotion into release-driving baseline datasets always requires explicit operator approval. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse existing dataset-state enforcement for direct draft promotion, surface sealed datasets as visible but disabled in the modal, and model any baseline lane after the workflow-owned approval pattern already used by prompt release rather than direct mutation. [VERIFIED: lib/scoria/eval/dataset.ex; lib/scoria/eval/dataset_item.ex; lib/scoria/workflows/prompt_release.ex; lib/scoria_web/live/prompt_live/release_workbench_live.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
</phase_requirements>

## Summary

Phase 39 is a projection-and-operator-flow phase, not a new runtime-engine phase. Replay lineage and replay-safe seam truth already exist on `Scoria.Workflows.Run`, `Scoria.Runtime.RunSummary`, `Scoria.Runtime.RunDetail`, approvals, checkpoints, events, and the dedicated approval projection boundary. [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; lib/scoria/workflows/remote_approval_projection.ex; .planning/phases/38-replay-safe-execution-tool-modes/38-03-SUMMARY.md] The current workflow page does not expose that truth in the approved shape because it still renders raw step context and checkpoint snapshots with `inspect/1`, and the existing dataset promotion modal only saves operator-edited JSON into open datasets without freezing replay/source provenance. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/components/workflow_detail_panel_component.ex; lib/scoria_web/live/dataset_live/promote_component.ex]

The smallest phase shape that satisfies the approved contract is three-layered: first extend the read model with comparison-ready fields, then replace the right rail with a replay evidence notebook and source toggle on the existing workflow route, then replace the current ad hoc promotion save path with a frozen-snapshot draft promotion flow that keeps sealed baselines visible but non-mutable. [VERIFIED: .planning/ROADMAP.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; lib/scoria/runtime/run_detail.ex; lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex]

The main planning risks are already visible in the codebase. `RunDetail` currently drops `projected_context`, `result_envelope`, `error_envelope`, and raw checkpoint snapshot payloads that the approved comparison notebook needs, `DatasetLive.PromoteComponent` filters sealed datasets out of the target list even though the UI contract requires them to remain visible but disabled, and the parent workflow LiveView never handles the component's `{:promote_successful}` message. [VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria_web/live/dataset_live/promote_component.ex; lib/scoria_web/live/workflow_live/show.ex] Those gaps should become explicit early plan items instead of being discovered mid-implementation. [VERIFIED: local code inspection]

**Primary recommendation:** Plan Phase 39 as three plans: comparison-ready runtime projections, workflow-page replay notebook UX, and frozen draft-dataset promotion with sealed-baseline visibility and approval-safe gating. [VERIFIED: .planning/ROADMAP.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; lib/scoria/workflows/prompt_release.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Replay provenance strip | Frontend Server (LiveView) | API / Backend | The UI contract places this directly below the workflow page header, but the facts come from durable run summary fields such as `execution_mode`, `source_run_id`, `source_checkpoint_id`, `replay_posture`, and `live_tool_allowlist`. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; lib/scoria/runtime/run_summary.ex; lib/scoria_web/live/workflow_live/show.ex] |
| Original-vs-replay comparison notebook | Frontend Server (LiveView) | API / Backend | The page interaction belongs in LiveView, but the comparison must be backed by curated DTOs rather than template-side struct introspection. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; lib/scoria/runtime/run_detail.ex; lib/scoria_web/components/workflow_detail_panel_component.ex] |
| Replay seam evidence | API / Backend | Database / Storage | Seam evidence is already persisted on approvals, checkpoints, events, and audit rows, so the backend owns normalization and projection. [VERIFIED: priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs; lib/scoria/workflows.ex; lib/scoria/runtime/run_detail.ex] |
| Draft dataset item creation | API / Backend | Database / Storage | Dataset inserts and sealed-state enforcement already live in `Scoria.Eval` and Ecto changesets. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset.ex; lib/scoria/eval/dataset_item.ex] |
| Baseline approval gating | API / Backend | Frontend Server (LiveView) | Existing release-gate behavior shows that approval workflows are backend-owned transactions with UI rails layered on top. [VERIFIED: lib/scoria/workflows/prompt_release.ex; lib/scoria_web/live/prompt_live/release_workbench_live.ex; test/scoria/workflows/prompt_release_test.exs] |
| Frozen promotion snapshot assembly | API / Backend | Database / Storage | The snapshot must be created once, atomically, at insert time so the UI cannot drift from what was actually persisted. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.7` published `2026-05-06` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/phoenix] | Route and LiveView shell for `/scoria/workflows/:id` and existing operator pages. [VERIFIED: lib/scoria_web/router.ex; lib/scoria_web/live/workflow_live/show.ex] | The workflow page already lives here, so Phase 39 should extend that route instead of creating a parallel surface. [VERIFIED: lib/scoria_web/router.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| Phoenix LiveView | `1.1.30` published `2026-05-05` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/phoenix_live_view] | Stateful workflow page updates, async loads, and modal/drawer interactions. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/live/dataset_live/promote_component.ex] | Official docs say LiveComponents are appropriate when state and event handling must be encapsulated, and function components should be preferred otherwise. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html] |
| Ecto / ecto_sql | `3.13.6` / `3.13.5` with `ecto_sql 3.13.5` published `2026-03-03` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/ecto_sql] | Durable workflow truth, dataset inserts, and sealed-state enforcement. [VERIFIED: lib/scoria/workflows.ex; lib/scoria/eval.ex; lib/scoria/eval/dataset.ex; lib/scoria/eval/dataset_item.ex] | Phase 39 needs transactional promotion and immutable-state validation, which the repo already implements at this boundary. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | `2.22.1` published `2026-04-30` [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/oban] | Existing async job infrastructure for later review-queue work. [VERIFIED: mix.exs; mix.lock] | Do not pull Oban into the Phase 39 happy path unless the plan intentionally introduces an asynchronous baseline-approval follow-up. [VERIFIED: .planning/ROADMAP.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| `Scoria.Runtime.RunSummary` / `RunDetail` | repo-local [VERIFIED: lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex] | Curated operator DTO boundary for replay truth. [VERIFIED: lib/scoria/runtime.ex] | Extend these first when the UI needs structured replay fields. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/runtime/run_detail.ex] |
| `Scoria.Workflows.RemoteApprovalProjection` | repo-local [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex] | Operator-facing approval lineage and pending approval reads. [VERIFIED: lib/scoria/workflows.ex] | Reuse this pattern if Phase 39 needs a visible approval-gated baseline lane. [VERIFIED: lib/scoria/workflows/remote_approval_projection.ex; test/scoria/workflows/remote_approval_projection_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending the existing workflow page [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | A new replay console route [ASSUMED] | Rejected because the approved UI contract explicitly keeps the work on the workflow page and the user prompt forbids a new top-level console. [VERIFIED: user prompt; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| Structured field-group comparison [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | Third-party text diff viewer [ASSUMED] | Rejected because the approved UX prefers grouped evidence cards, and no additional UI dependency is necessary on the current stack. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; mix.exs] |
| Draft promotion into existing open datasets [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset.ex] | Creating a brand-new dataset for every promotion [ASSUMED] | Rejected because Phase 24 established open datasets as the mutable curation lane and the current modal already assumes selecting an existing dataset. [VERIFIED: .planning/phases/24-trace-to-dataset-curation-via-liveview/24-RESEARCH.md; lib/scoria_web/live/dataset_live/promote_component.ex] |

**Installation:**
```bash
# No new dependencies are recommended for Phase 39.
```
[VERIFIED: mix.exs; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]

**Version verification:** `mix.lock` pins Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, `ecto_sql` `3.13.5`, and Oban `2.22.1`, and the Hex package API confirms the publish dates listed above. [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/phoenix; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql; https://hex.pm/api/packages/oban]

## Architecture Patterns

### System Architecture Diagram

```text
Operator selects workflow step on /scoria/workflows/:id
        |
        v
WorkflowLive.Show
  - tree/timeline stay driven by run tree
  - right rail reads curated replay detail
        |
        +------------------------------+
        |                              |
        v                              v
Workflows.get_run_tree!/1        Runtime.get_run_detail!/1
  - step order/topology            - replay provenance fields
  - existing page subscription      - approval/checkpoint/event evidence
                                    - comparison-ready selected-source data
        |                              |
        +--------------+---------------+
                       |
                       v
Replay evidence notebook
  - provenance group
  - overrides group
  - checkpoint/output group
  - safety evidence group
  - promotion snapshot summary
                       |
             operator chooses source variant
                       |
                       v
Dataset promotion component
  - open datasets selectable
  - sealed baselines visible but disabled
  - optional approval notice for baseline lane
                       |
                       v
Scoria.Eval promotion service
  - build frozen snapshot
  - insert dataset item transactionally
  - reject sealed datasets at write time
```
[VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria/runtime.ex; lib/scoria/runtime/run_detail.ex; lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]

### Recommended Project Structure
```text
lib/
├── scoria/runtime/
│   ├── run_summary.ex              # keep replay strip facts here
│   ├── run_detail.ex               # add comparison-ready evidence fields here
│   └── replay_comparison.ex        # new grouped source-variant resolver
├── scoria/eval/
│   └── dataset_promotion.ex        # new frozen snapshot builder and target classification
├── scoria_web/live/workflow_live/
│   └── show.ex                     # parent orchestration, success flash/state, source toggle
├── scoria_web/components/
│   └── workflow_detail_panel_component.ex  # replay evidence notebook right rail
└── scoria_web/live/dataset_live/
    └── promote_component.ex        # dataset target list + confirmation flow
```
[ASSUMED]

### Pattern 1: Use Curated DTOs for Replay Evidence, Not Raw Struct Dumps
**What:** Extend `RunDetail` and related helpers so the right rail can render grouped provenance, output, and safety sections from curated maps. [VERIFIED: lib/scoria/runtime/run_detail.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**When to use:** Any workflow-page field that currently depends on `inspect(@step.projected_context)` or `inspect(@checkpoint.snapshot)`. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex]
**Example:**
```elixir
# Source: lib/scoria/runtime/run_detail.ex + Phase 39 recommendation
def selected_source(detail, :replay) do
  %{
    provenance: %{
      source_run_id: detail.summary.source_run_id,
      source_checkpoint_id: detail.summary.source_checkpoint_id,
      execution_mode: detail.summary.execution_mode,
      replay_posture: detail.summary.replay_posture
    },
    safety: Enum.filter(detail.approvals, &(&1.replay_scope == "replay_live")),
    checkpoints: detail.checkpoints,
    events: detail.events
  }
end
```
[VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria/runtime/run_summary.ex] [ASSUMED]

### Pattern 2: Build Promotion Snapshots Once at the Eval Boundary
**What:** Build the dataset item payload from the selected source variant inside `Scoria.Eval`, then insert it transactionally. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex]
**When to use:** Every operator promotion submit, including cases where the UI is showing editable notes or expected output. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**Example:**
```elixir
# Source: Ecto.Multi docs + existing Eval context pattern
Multi.new()
|> Multi.run(:dataset, fn _repo, _changes -> {:ok, Eval.get_dataset!(dataset_id)} end)
|> Multi.run(:item, fn repo, %{dataset: dataset} ->
  attrs = build_frozen_snapshot(selected_source, dataset)

  %DatasetItem{}
  |> DatasetItem.changeset(Map.put(attrs, :dataset_id, dataset.id), dataset.state)
  |> repo.insert()
end)
|> Repo.transaction()
```
[VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Pattern 3: Model Approval-Gated Baseline UX After Prompt Release Rails
**What:** If Phase 39 exposes a baseline lane, make it workflow-owned and confirmation-first instead of writing directly to sealed datasets. [VERIFIED: lib/scoria/workflows/prompt_release.ex; lib/scoria_web/live/prompt_live/release_workbench_live.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**When to use:** Only when the operator explicitly targets a release-driving sealed baseline path. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**Example:**
```elixir
# Source: lib/scoria/workflows/prompt_release.ex
def request_baseline_promotion(attrs) do
  Workflows.request_remote_approval(run_id, step_id, %{
    tool_name: "dataset_baseline_promotion",
    arguments: attrs,
    replay_allowed: false
  })
end
```
[VERIFIED: lib/scoria/workflows/prompt_release.ex] [ASSUMED]

### Anti-Patterns to Avoid
- **UI-side inference of replay facts:** Do not infer `historical_stub` or `replay_blocked` from status strings or booleans when the typed columns already exist. [VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria/workflows/remote_approval_projection.ex]
- **Raw JSON as the first-read UX:** Do not keep `inspect/1` as the primary operator surface once structured evidence groups exist. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
- **Direct writes into sealed datasets:** Do not special-case baseline mutation in the component; the sealed-state rejection already lives in `DatasetItem.changeset/3` and the requirement forbids silent mutation. [VERIFIED: lib/scoria/eval/dataset_item.ex; .planning/REQUIREMENTS.md]
- **Trace-table-first joins for primary truth:** Do not make Phase 39 depend on a new `workflow_run_id` foreign key on `ai_traces`; the trace table only stores `session_id` and generic `attributes` today. [VERIFIED: lib/scoria/repo/trace.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Replay provenance inference | Ad hoc template boolean logic | `RunSummary`, `RunDetail`, and `RemoteApprovalProjection` fields | The replay-safe phase already projected typed fields for `replay_disposition`, `replay_reason_code`, `replay_scope`, and lineage IDs. [VERIFIED: lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; lib/scoria/workflows/remote_approval_projection.ex; .planning/phases/38-replay-safe-execution-tool-modes/38-03-SUMMARY.md] |
| Dataset immutability rules | Component-only guards | `Dataset.changeset/2` and `DatasetItem.changeset/3` | The database boundary already rejects writes to sealed datasets and should remain authoritative. [VERIFIED: lib/scoria/eval/dataset.ex; lib/scoria/eval/dataset_item.ex] |
| Baseline approval workflow | A bespoke modal-only decision path | The existing workflow approval pattern used by `PromptRelease` | Prompt release already proves Scoria’s operator approvals should be workflow-owned and transactionally audited. [VERIFIED: lib/scoria/workflows/prompt_release.ex; test/scoria/workflows/prompt_release_test.exs] |
| Large diff dependency | New client-side diff library | Grouped comparison cards and small curated deltas | The approved UI contract explicitly prefers field-group comparison over patch-style text diffs. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |

**Key insight:** Most Phase 39 risk comes from bypassing boundaries Scoria already has, not from missing new infrastructure. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/eval.ex; lib/scoria/workflows/prompt_release.ex]

## Common Pitfalls

### Pitfall 1: Planning the UI Against the Wrong Read Boundary
**What goes wrong:** The page keeps reading raw workflow structs and accumulates template-level `inspect/1` branching instead of getting a stable comparison model. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex]
**Why it happens:** `WorkflowLive.Show` currently loads the run tree directly, and `RunDetail` still omits several fields the comparison notebook needs. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria/runtime/run_detail.ex]
**How to avoid:** Add the comparison-ready DTO work before the main UI refactor and keep the tree/topology read separate from the notebook projection. [VERIFIED: lib/scoria/runtime.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] [ASSUMED]
**Warning signs:** New template conditionals start reading `run.execution_mode`, `step.result_envelope`, and `checkpoint.snapshot` directly from mixed raw structs. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex; lib/scoria/workflows/step.ex; lib/scoria/workflows/checkpoint.ex]

### Pitfall 2: Treating the Existing Promotion Modal as “Almost Done”
**What goes wrong:** The plan underestimates the work because a modal already exists, but the current component only writes operator-supplied JSON to open datasets and does not persist selected source variant, replay lineage, frozen evidence summary, or success-state wiring. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex; lib/scoria/eval.ex; lib/scoria_web/live/workflow_live/show.ex]
**Why it happens:** The modal came from Phase 24’s generic trace-to-dataset flow, not from the tighter replay-reviewed draft promotion contract. [VERIFIED: .planning/phases/24-trace-to-dataset-curation-via-liveview/24-RESEARCH.md; .planning/phases/24-trace-to-dataset-curation-via-liveview/24-SUMMARY.md]
**How to avoid:** Treat promotion as a service redesign plus UX refactor, not as a copy tweak. [VERIFIED: local code inspection] [ASSUMED]
**Warning signs:** Planned tasks only mention labels, CSS, or adding a toggle without touching `Scoria.Eval`. [VERIFIED: lib/scoria/eval.ex; lib/scoria_web/live/dataset_live/promote_component.ex]

### Pitfall 3: Hiding Sealed Baselines Instead of Showing Them as Gated
**What goes wrong:** Operators cannot tell whether a baseline exists or why it is unavailable. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**Why it happens:** The current component filters datasets to `state == :open`, so sealed datasets disappear entirely from the selector. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex]
**How to avoid:** Split the target list into selectable open datasets and visible disabled sealed datasets with approval helper copy. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**Warning signs:** The modal only renders one `<select>` of open datasets and has no baseline notice card. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex]

### Pitfall 4: Assuming Trace Rows Are the Canonical Source for Workflow Promotions
**What goes wrong:** The plan drifts into new joins or schema changes just to identify original/replay variants. [VERIFIED: lib/scoria/repo/trace.ex]
**Why it happens:** `DATA-01` uses the word “trace”, but the approved UI keeps the primary flow on workflow runs and checkpoints. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
**How to avoid:** Use workflow run, step, checkpoint, event, and approval truth as the canonical promotion snapshot, and only attach a trace ID when one is already present in durable evidence. [VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria/workflows.ex; lib/scoria/observe/approval.ex] [ASSUMED]
**Warning signs:** A plan introduces a new `workflow_run_id` on `ai_traces` as a prerequisite for the first UI slice. [VERIFIED: lib/scoria/repo/trace.ex] [ASSUMED]

## Code Examples

Verified patterns from official sources and local code:

### LiveComponent Boundary for the Promotion Surface
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html
<.live_component
  module={ScoriaWeb.DatasetLive.PromoteComponent}
  id="promote-component"
  step={selected_step}
  selected_source={selected_source}
/>
```
[CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html]

### Async Notebook Data Load on Connected Mount
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
def mount(%{"id" => run_id}, _session, socket) do
  {:ok,
   socket
   |> assign(:selected_source, :replay)
   |> assign_async(:comparison, fn ->
     {:ok, %{comparison: Runtime.get_run_detail!(run_id)}}
   end)}
end
```
[CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Eval-Boundary Snapshot Insert
```elixir
# Source: lib/scoria/eval.ex + https://hexdocs.pm/ecto/Ecto.Multi.html
def promote_replay_snapshot(dataset_id, snapshot_attrs) do
  Multi.new()
  |> Multi.run(:dataset, fn _repo, _changes -> {:ok, get_dataset!(dataset_id)} end)
  |> Multi.run(:item, fn repo, %{dataset: dataset} ->
    attrs = Map.put(snapshot_attrs, :dataset_id, dataset.id)

    %DatasetItem{}
    |> DatasetItem.changeset(attrs, dataset.state)
    |> repo.insert()
  end)
  |> Repo.transaction()
end
```
[VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Workflow detail panel shows raw `inspect/1` dumps of projected context and checkpoint snapshots. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex] | Approved contract requires structured provenance, overrides, outcome, safety, and promotion-summary groups. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | Phase 39 planning target. [VERIFIED: .planning/ROADMAP.md] | The DTO layer must grow before the UI can become stable. [VERIFIED: lib/scoria/runtime/run_detail.ex] [ASSUMED] |
| Generic dataset promotion writes arbitrary JSON into open datasets. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex] | Draft promotion now needs source-variant-aware frozen evidence snapshots. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | Requirement introduced for Phase 39. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md] | `Scoria.Eval` needs a real promotion API, not just `add_dataset_item/2`. [VERIFIED: lib/scoria/eval.ex] [ASSUMED] |
| Sealed datasets are enforced at write time but hidden from the promotion picker. [VERIFIED: lib/scoria/eval/dataset_item.ex; lib/scoria_web/live/dataset_live/promote_component.ex] | Sealed baselines must remain visible and explicitly approval-gated. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | Phase 39 planning target. [VERIFIED: .planning/ROADMAP.md] | The modal needs separate target-group rendering and clearer semantics. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] [ASSUMED] |

**Deprecated/outdated:**
- Raw `inspect/1` blobs as the primary operator evidence view are outdated for this workflow surface. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]
- Hiding sealed datasets from the picker is outdated relative to the approved contract. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A small new repo-local helper such as `Scoria.Runtime.ReplayComparison` is the cleanest way to normalize original-vs-replay notebook data. [ASSUMED] | Recommended Project Structure | Low to medium; the planner may instead extend `RunDetail` directly if that keeps the surface simpler. |
| A2 | Phase 39 can satisfy `DATA-02` by keeping sealed baselines visible and non-mutable, while deferring any actual baseline-mutation execution path until a dedicated approval-backed workflow exists. [ASSUMED] | Summary; Pattern 3; Open Questions | Medium; if stakeholders expect a full baseline approval request flow in Phase 39, the plan needs one more backend/UI slice. |
| A3 | Promotion snapshots should use workflow truth as canonical and only attach a trace ID opportunistically when durable evidence already contains one. [ASSUMED] | Pitfall 4 | Medium; if downstream eval consumers require a mandatory trace FK, the schema or source builder needs expansion. |

## Open Questions

1. **Does Phase 39 need to create baseline-promotion approval requests, or only expose sealed baselines as visible gated targets?**
   - What we know: The requirement says release-driving baselines require explicit approval, while the UI spec phrases the baseline lane as conditional and the user prompt asks for the smallest decomposition. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; user prompt]
   - What's unclear: Whether “approval flow” in this phase means a fully wired request path or a visible non-mutable lane plus approval-required affordance. [VERIFIED: local artifact comparison]
   - Recommendation: Decide this in planning up front, because it changes whether Phase 39 needs a new workflow service modeled after `PromptRelease`. [VERIFIED: lib/scoria/workflows/prompt_release.ex] [ASSUMED]

2. **What exact dataset item shape should represent a frozen replay snapshot?**
   - What we know: `DatasetItem` supports `input`, `expected_output`, `metadata`, and optional `source_trace_id`, and current eval runners consume dataset items through `input`/`expected_output`. [VERIFIED: lib/scoria/eval/dataset_item.ex; lib/scoria/eval/judge_runner.ex; lib/scoria/eval/offline_runner_test.exs]
   - What's unclear: Whether replay provenance belongs in `input`, in `metadata`, or split across both for downstream runner ergonomics. [VERIFIED: local code inspection]
   - Recommendation: Keep replay lineage and operator notes in `metadata`, keep runner-essential invocation context in `input`, and avoid stuffing presentation-only groups into the executable payload. [VERIFIED: .planning/phases/24-trace-to-dataset-curation-via-liveview/24-RESEARCH.md] [ASSUMED]

3. **Where should “original” evidence come from when the operator is on a replay run?**
   - What we know: Replay runs persist `source_run_id` and `source_checkpoint_id`, and replay-safe detail items preserve lineage IDs and replay disposition facts. [VERIFIED: lib/scoria/workflows/run.ex; lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex]
   - What's unclear: Whether the comparison notebook should fetch the original run detail lazily by `source_run_id` or precompute a denormalized comparison projection from the replay run alone. [VERIFIED: local code inspection]
   - Recommendation: Prefer lazy fetch of the original run detail by `source_run_id` so the notebook can compare like-for-like DTOs without duplicating storage. [VERIFIED: lib/scoria/runtime.ex] [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | ExUnit, LiveView tests, compilation | ✓ [VERIFIED: `command -v mix`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| Erlang/OTP | Elixir runtime | ✓ [VERIFIED: `mix --version`] | `OTP 28` [VERIFIED: `mix --version`] | — |
| `node` | Asset-related tasks if UI work touches frontend build steps | ✓ [VERIFIED: `command -v node`] | `v22.14.0` [VERIFIED: `node --version`] | Phase 39 can still implement server-rendered UI without invoking Node-specific tooling. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/components/workflow_detail_panel_component.ex] |
| `npm` | Optional frontend dependency management | ✓ [VERIFIED: `command -v npm`] | `11.1.0` [VERIFIED: `npm --version`] | No new npm packages are recommended. [VERIFIED: mix.exs; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit above]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit above]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView test support. [VERIFIED: test/test_helper.exs; test/scoria_web/live/workflow_live_test.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs`. [VERIFIED: existing test file paths] |
| Full suite command | `mix test`. [VERIFIED: test/test_helper.exs; existing suite structure] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RPLY-03 | Replay run header and right rail show source run/checkpoint, execution mode, overrides, and replay disposition evidence. [VERIFIED: .planning/ROADMAP.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | LiveView + DTO | `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs` | `runtime_view_test.exs` and `workflow_live_test.exs` exist, but they do not yet cover the Phase 39 notebook contract. [VERIFIED: test/scoria/runtime_view_test.exs; test/scoria_web/live/workflow_live_test.exs] |
| DATA-01 | Operator can promote original or replay source into an open draft dataset item with frozen provenance metadata. [VERIFIED: .planning/REQUIREMENTS.md] | LiveComponent + Eval integration | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/eval_test.exs` | Existing files exist, but they currently cover only raw JSON save behavior. [VERIFIED: test/scoria_web/live/dataset_live/promote_component_test.exs; test/scoria/eval_test.exs] |
| DATA-02 | Sealed datasets stay immutable even if the target seals between render and submit, and sealed baselines remain visible but disabled. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] | LiveComponent + context | `mix test test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/eval_test.exs test/scoria/eval/dataset_item_test.exs` | `dataset_item_test.exs` exists for write rejection, but there is no UI race/regression test yet. [VERIFIED: test/scoria/eval/dataset_item_test.exs; test/scoria_web/live/dataset_live/promote_component_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs` for projection/UI slices, and `mix test test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria/eval_test.exs` for promotion slices. [VERIFIED: existing test files]
- **Per wave merge:** `mix test`. [VERIFIED: test/test_helper.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: GSD workflow instructions in prompt]

### Wave 0 Gaps
- [ ] Add a focused LiveView regression for the replay provenance strip and source toggle on the workflow page. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; test/scoria_web/live/workflow_live_test.exs]
- [ ] Add a DTO regression proving `RunDetail` exposes the comparison payloads the notebook needs, not just lineage IDs. [VERIFIED: lib/scoria/runtime/run_detail.ex; test/scoria/runtime_view_test.exs]
- [ ] Extend the promotion component tests to cover sealed datasets visible-but-disabled, submit-race failure recovery, and success notice wiring back to `WorkflowLive.Show`. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex; lib/scoria_web/live/workflow_live/show.ex; test/scoria_web/live/dataset_live/promote_component_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: operator actions are session-driven LiveView events in `WorkflowLive.Show` and `ReleaseWorkbenchLive`] | Use the existing session identity path and avoid fallback-only actor IDs for promotion/approval decisions. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex; lib/scoria_web/live/prompt_live/release_workbench_live.ex] [ASSUMED] |
| V3 Session Management | yes [VERIFIED: LiveView router/session setup in tests and router macros] | Keep promotion and any approval actions inside normal Phoenix session-backed LiveViews. [VERIFIED: lib/scoria_web/router.ex; test/scoria_web/live/workflow_live_test.exs] |
| V4 Access Control | yes [VERIFIED: operator promotions and approvals mutate durable truth] | Route any baseline lane through workflow approvals and keep sealed datasets non-mutable from the component. [VERIFIED: lib/scoria/eval/dataset_item.ex; lib/scoria/workflows/prompt_release.ex; .planning/REQUIREMENTS.md] |
| V5 Input Validation | yes [VERIFIED: promotion modal accepts JSON and dataset selections] | Continue using changesets and JSON parsing at the component/context boundary. [VERIFIED: lib/scoria_web/live/dataset_live/promote_component.ex; lib/scoria/eval/dataset_item.ex] |
| V6 Cryptography | no [VERIFIED: this phase does not introduce new crypto surfaces] | Use existing durable IDs and audit rows; do not add homegrown snapshot hashing unless separately required. [VERIFIED: local code inspection] [ASSUMED] |

### Known Threat Patterns for Phoenix LiveView + Ecto Operator Flows

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Session fallback spoofing on operator actions | Spoofing | Do not rely on `"operator"` or `"operator-fallback"` defaults for promotion/baseline actions in production paths; require validated session identity. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; lib/scoria_web/live/prompt_live/release_workbench_live.ex] [ASSUMED] |
| Sealed-dataset race between render and submit | Tampering | Re-check dataset state at insert time through `DatasetItem.changeset/3`, then refresh the modal target list on failure. [VERIFIED: lib/scoria/eval.ex; lib/scoria/eval/dataset_item.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| Provenance confusion between original and replay | Repudiation | Persist and display typed `source_run_id`, `source_checkpoint_id`, `replay_disposition`, `replay_reason_code`, and source-variant labels. [VERIFIED: lib/scoria/runtime/run_summary.ex; lib/scoria/runtime/run_detail.ex; .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md] |
| Overexposing raw step/checkpoint payloads | Information Disclosure | Make structured evidence the default and collapse raw JSON behind advanced disclosure. [VERIFIED: .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md; lib/scoria_web/components/workflow_detail_panel_component.ex] |
| Direct baseline mutation from the UI | Elevation of Privilege | Reuse workflow-owned approval seams for any release-driving baseline path and keep sealed datasets immutable. [VERIFIED: .planning/REQUIREMENTS.md; lib/scoria/eval/dataset_item.ex; lib/scoria/workflows/prompt_release.ex] |

## Sources

### Primary (HIGH confidence)
- `lib/scoria_web/live/workflow_live/show.ex` - current workflow route, event flow, and modal parent orchestration. [VERIFIED: local code inspection]
- `lib/scoria_web/components/workflow_detail_panel_component.ex` - current raw detail-panel rendering that Phase 39 must replace. [VERIFIED: local code inspection]
- `lib/scoria_web/live/dataset_live/promote_component.ex` - current promotion modal behavior and limitations. [VERIFIED: local code inspection]
- `lib/scoria/runtime/run_summary.ex` and `lib/scoria/runtime/run_detail.ex` - current replay DTO fields and missing comparison fields. [VERIFIED: local code inspection]
- `lib/scoria/eval.ex`, `lib/scoria/eval/dataset.ex`, and `lib/scoria/eval/dataset_item.ex` - dataset insert and sealed-state rules. [VERIFIED: local code inspection]
- `lib/scoria/workflows/prompt_release.ex` and `lib/scoria/workflows/remote_approval_projection.ex` - existing approval-safe operator patterns. [VERIFIED: local code inspection]
- `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-UI-SPEC.md` - approved UX contract and state semantics. [VERIFIED: local artifact]
- `.planning/phases/38-replay-safe-execution-tool-modes/38-03-SUMMARY.md` and `.planning/phases/37-replay-lineage-branch-model/37-RESEARCH.md` - prior replay truth and operator-readiness context. [VERIFIED: local artifacts]
- Phoenix LiveView docs for `Phoenix.LiveComponent` and `Phoenix.LiveView.assign_async/3`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html; https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Ecto docs for `Ecto.Multi`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Hex package API for Phoenix, Phoenix LiveView, `ecto_sql`, and Oban release currency. [CITED: https://hex.pm/api/packages/phoenix; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql; https://hex.pm/api/packages/oban]

### Secondary (MEDIUM confidence)
- `.planning/phases/24-trace-to-dataset-curation-via-liveview/24-RESEARCH.md` and `24-SUMMARY.md` - historical dataset promotion intent and open/sealed curation model. [VERIFIED: local artifacts]
- `.planning/phases/26-release-gates-and-approvals/26-VERIFICATION.md` - shipped release-gate operator pattern and verification precedent. [VERIFIED: local artifact]

### Tertiary (LOW confidence)
- None. [VERIFIED: all non-local framework claims in this document are backed by official docs or official package APIs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The phase stays on the existing Phoenix/LiveView/Ecto stack, and the versions were verified from both `mix.lock` and the official Hex API. [VERIFIED: mix.lock] [CITED: https://hex.pm/api/packages/phoenix; https://hex.pm/api/packages/phoenix_live_view; https://hex.pm/api/packages/ecto_sql; https://hex.pm/api/packages/oban]
- Architecture: HIGH - The route, DTO, workflow, dataset, and approval seams all exist locally and were inspected directly. [VERIFIED: lib/scoria_web/router.ex; lib/scoria/runtime.ex; lib/scoria/eval.ex; lib/scoria/workflows.ex]
- Pitfalls: HIGH - The main pitfalls are concrete current-code gaps, not hypothetical ecosystem issues. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex; lib/scoria_web/live/dataset_live/promote_component.ex; lib/scoria_web/live/workflow_live/show.ex]

**Research date:** 2026-05-23 [VERIFIED: current session date]
**Valid until:** 2026-06-22 for codebase-specific findings, or sooner if Phase 39 scope changes. [ASSUMED]
