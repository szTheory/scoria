# Phase 34: Real-time Operator Dashboards - Research

**Researched:** 2026-05-21
**Requirement focus:** `OBS-01`, `OBS-02`

## Planning Answer

What needs to be true to plan this phase well:

- The dashboard should extend the existing `/scoria` LiveView surface in `lib/scoria_web/live/orchestrator_live.ex`; it should not create a separate eval-ops app or a second truth system.
- Phase 33 already provides durable campaign, target, and run truth in Ecto (`EvalCampaign`, `EvalCampaignTarget`, `EvalRun`) plus worker rollup semantics, so Phase 34 should read from those rows and treat PubSub as a projection/update path only.
- Real-time campaign UX is currently missing two seams: a dashboard-facing query/projection layer that shapes campaign and model-health data for LiveView, and PubSub broadcasts when campaign/model-health truth changes.
- The model-health surface must combine node-local breaker/fallback posture from the existing orchestration/SRE layer with the established compact card and drawer patterns already used in `OrchestratorLive`.
- The operator drill-in path should remain inline and evidence-first: campaign summary at the dashboard root, target/run lineage in an inline detail panel, and durable run navigation via `WorkflowLive.Show`.

## Current Implementation Reality

### Durable eval campaign truth already exists

- `lib/scoria/eval/eval_campaign.ex` defines the parent aggregate row with `status`, eager counters, timestamps, `tenant_id`, and `eval_spec_id`.
- `lib/scoria/eval/eval_campaign_target.ex` defines explicit target rows with `tenant_id`, `provider`, `model`, `status`, timestamps, `last_error`, and semantic-override guardrails.
- `lib/scoria/eval/campaign_enqueuer.ex` persists campaigns, targets, child runs, and `:evals` jobs in a batch-safe path.
- `lib/scoria/eval/campaign_worker.ex` and `lib/scoria/eval.ex` already update running/completed/failed rollups and preserve partial-vs-fatal semantics.

### Dashboard shell already exists

- `lib/scoria_web/live/orchestrator_live.ex` already mounts the embedded dashboard, subscribes to runtime/run PubSub topics, and renders compact operator cards with existing stone/white card styling.
- `lib/scoria_web/components/runtime_detail_drawer_component.ex` and `connector_detail_drawer_component.ex` provide the compact scan-surface to detail-drawer pattern that the model-health matrix can reuse.
- `lib/scoria_web/live/workflow_live/show.ex` already serves as the durable run truth page and should remain the destination for per-run drill-in links such as `View Eval Run`.

### Missing Phase 34 seams

- There is no query API that lists campaigns for the dashboard with preloaded spec/target/run context.
- There is no LiveView-side state for selected eval campaign, model health matrix, fallback counts, or inline campaign detail.
- There is no PubSub topic for eval campaign progress updates, and current worker completion paths do not broadcast campaign changes.
- There is no operator-facing query for model breaker/fallback posture across configured provider:model pairs.

## Recommended Architecture

### 1. Add an eval dashboard projection layer

Introduce a small query/projection seam under `Scoria.Eval` or a tightly scoped sibling module that returns:

- summary counters for active campaigns, completed today, fallback targets, and breaker-open models
- a campaign list ordered by `last_progress_at desc`
- a selected campaign detail payload with target rows and run lineage
- model-health rows grouped by provider

This layer should keep Ecto truth central and produce dashboard-friendly maps so `OrchestratorLive` does not absorb heavy query logic.

### 2. Add explicit PubSub projection updates

Use `Phoenix.PubSub` to broadcast tenant-scoped dashboard updates whenever campaign rollups or model-health truth changes.

Recommended topic shape:

- `scoria:eval_campaigns:{tenant_id}` for campaign list/detail refreshes
- `scoria:model_health:{tenant_id}` for breaker/fallback posture refreshes

Worker completion/failure paths in `Scoria.Eval` are the right place to emit campaign progress broadcasts because they already own durable rollup transitions.

### 3. Extend `OrchestratorLive` instead of adding a new root LiveView

Phase 34 should add three adjacent dashboard bands inside `OrchestratorLive`:

- summary strip
- model health matrix
- campaign progress board with inline detail panel

This preserves the embedded operator posture already established in Phase 29 and the approved `34-UI-SPEC.md`.

### 4. Keep detail truth durable and navigable

The campaign detail panel should render:

- campaign header/status/counters/timestamps
- target shard table with provider:model, status, fallback indicator, and latest error
- `View Eval Run` links into durable run detail when `eval_run_id` exists

Avoid modal-first drill-in. The inline detail panel is consistent with the UI contract and current operator evidence posture.

## Existing Code Patterns To Reuse

- `lib/scoria_web/live/orchestrator_live.ex`
  - tenant-scoped PubSub subscription in `mount/3`
  - `load_operator_surface/1` as the dashboard refresh seam
  - compact card composition and drawer events
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
  - compact summary cards plus secondary detail surface
- `lib/scoria_web/components/incident_evidence_component.ex`
  - dense operator evidence layout with summary strip plus detailed notebook content
- `lib/scoria/eval.ex`
  - campaign rollup and lineage APIs that should remain the single source of campaign truth
- `lib/scoria/runtime.ex`
  - simple query-facing context API style for LiveView-backed projections
- `test/scoria_web/live/orchestrator_live_test.exs`
  - current LiveView mount, PubSub refresh, and interactive rendering expectations
- `test/scoria_web/live/orchestrator_live_sre_test.exs`
  - evidence-first operator assertions and lazy-load posture

## Risks And Constraints

### Main risks

- Pulling raw campaign/target/run queries directly into the LiveView will create a large, brittle surface and encourage truth drift.
- Broadcasting on every micro-step without aggregation can cause noisy rerenders and fragile tests.
- Reading breaker state straight from UI-local assigns instead of a context/query seam will make the matrix hard to test and easy to desynchronize.
- Presenting fallback completions as ordinary success will violate the UI contract and hide the operator signal Phase 34 is supposed to surface.

### Product constraints

- Stay inside the existing `/scoria` dashboard.
- Keep Ecto rows as durable truth and PubSub as projection.
- Reflect node-local breaker state honestly; do not imply cluster-wide health consensus.
- Preserve calm operator-first posture from Phase 29 and the approved Phase 34 UI contract.

## Suggested Plan Split

1. Projection and PubSub foundation:
   add dashboard query APIs and tenant-scoped progress/model-health broadcasts, with focused tests proving durable truth drives projection updates.
2. Dashboard surface:
   extend `OrchestratorLive` with summary strip, model-health matrix, campaign board, selection state, and responsive inline detail behavior.
3. Drill-in detail and verification:
   add target shard detail rendering, fallback/terminal-state distinctions, `View Eval Run` links, and focused LiveView coverage for live refresh and empty/degraded states.

## Verification Lanes

- `mix test test/scoria/eval/campaign_worker_test.exs test/scoria/eval/campaign_enqueue_test.exs`
- `mix test test/scoria_web/live/orchestrator_live_test.exs`
- `mix test test/scoria_web/live/orchestrator_live_sre_test.exs`
- a new focused eval-dashboard LiveView test file validating summary counters, campaign selection persistence, and fallback/open-state rendering

## Sources

- `.planning/ROADMAP.md`
- `.planning/milestones/v1.8-ROADMAP.md`
- `.planning/milestones/v1.8-REQUIREMENTS.md`
- `.planning/phases/34-real-time-operator-dashboards/34-UI-SPEC.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-CONTEXT.md`
- `.planning/phases/33-distributed-evaluation-fan-out/33-RESEARCH.md`
- `.planning/phases/29-external-runtime-observability-and-operator-ux/29-CONTEXT.md`
- `lib/scoria/eval.ex`
- `lib/scoria/eval/eval_campaign.ex`
- `lib/scoria/eval/eval_campaign_target.ex`
- `lib/scoria/eval/campaign_enqueuer.ex`
- `lib/scoria/eval/campaign_worker.ex`
- `lib/scoria/runtime.ex`
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/live/workflow_live/show.ex`
- `lib/scoria_web/components/runtime_detail_drawer_component.ex`
- `lib/scoria_web/components/connector_detail_drawer_component.ex`
- `lib/scoria_web/components/incident_evidence_component.ex`
- `test/scoria_web/live/orchestrator_live_test.exs`
- `test/scoria_web/live/orchestrator_live_sre_test.exs`
