---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: tenant-scoped semantic fast path
status: executing
last_updated: "2026-05-25T07:28:51.437Z"
last_activity: 2026-05-25
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 7
  completed_plans: 7
  percent: 67
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Phase 45 — compatibility-and-invalidation-engine

## Current Position

Phase: 45 (compatibility-and-invalidation-engine) — EXECUTING
Plan: 1 of 4
**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Phase:** 45
**Plan:** Not started
**Status:** Executing Phase 45
**Last activity:** 2026-05-25

**Progress:**
[██████████] 100%

## Performance Metrics

- **Completed Phases:** 41
- **Completed Plans:** 123
- **Total Validated Requirements:** 116
- **Coverage:** 100% on shipped milestones through `v1.9 Crucible`
- **Latest Shipped Milestone:** `v2.0 Relay` on 2026-05-25
- **Active Milestone:** `v2.1 Tenant-scoped semantic fast path`

**Phase 31 Metrics:**

- **31-01:** 15m, 2 tasks, 4 files
- **31-02:** 20m, 3 tasks, 6 files
- **31-03:** 10m, 2 tasks, 3 files

**Phase 32 Metrics:**

- **32-01:** 15m, 2 tasks, 4 files
- **32-02:** 20m, 3 tasks, 5 files

**Phase 39 Metrics:**

- **39-01:** 7m, 2 tasks, 5 files
- **39-02:** 6min, 2 tasks, 5 files
- **39-03:** 12m, 2 tasks, 12 files
- **39-04:** 6min, 2 tasks, 9 files

**Phase 40 Metrics:**

- **40-01:** 66m, 1 task, 8 files
- **40-02:** resumed in working tree, targeted lane green
- **40-03:** resumed in working tree, targeted lane green
- **40-04:** resumed in working tree, targeted lane green
- **40-05:** resumed in working tree, targeted lane green
- **40-06:** resumed in working tree, targeted lane green, checkpoint approved 2026-05-24
- **40-07:** resumed in working tree, targeted lane green

## Accumulated Context

### Roadmap Evolution

- Phase 43.1 inserted after Phase 43: Fix full-suite failures blocking clean Relay closeout (URGENT)

**Decisions:**

- Milestone activation decision for `v1.9`: prioritize replayable debugging and online scoring with reviewable dataset promotion over semantic caching and broad handoff productization.
- Milestone activation decision for `v1.9`: online scoring remains additive evidence only; sealed baseline datasets are never auto-mutated.
- Post-`v1.9`: public handoff productization stays narrow behind `Scoria.start_handoff_run/3` and compounds the durable workflow substrate instead of expanding into broad orchestration surface area.
- Post-`v1.9`: projected context is the actual handoff product boundary; unsafe delegated context keys should be rejected explicitly, not left to convention.
- Post-`v1.9`: support truth is part of productization, so docs/source checks, `mix test.adoption` env defaults, and default-path compile stability belong in the same wedge as the API work.
- Used `Ecto.Changeset.apply_changes/1` to compute merged text payloads in-memory before running the tokenizer, avoiding partial map logic.
- Adopted strict `Ecto.Multi` version deprecation mimicking `Scoria.Eval`.
- Added an explicit `update_draft_template/2` for draft-only in-place changes.
- Used exact table pattern analog of `ai_eval_specs` for `ai_prompt_templates` via unique version constraints.
- Test helper `errors_on` recreated locally since standard `Scoria.DataCase` wasn't immediately available, avoiding structural modification of test support.
- Decoupled `scoria_observe` (traces) from `scoria_eval` to avoid a "God Package" architecture.
- Follow OpenInference specifications for trace/span structures.
- Use Ecto as the primary state engine (no external databases required).
- UI will heavily rely on LiveView and PubSub, specifically coalescing token streams to avoid DOM bloat.
- MCP transport strictly separated from UI websockets.
- Phase 1 (OBS-03): Use Native OTP Buffer (GenServer + ETS) for async span batching to avoid external dependencies.
- Phase 1 (OBS-04): Use Hybrid Configurable Deny-list + MFA Escape Hatch for telemetry redaction.
- Phase 1 (OBS-01): Use Core Columns + JSONB Attributes for the Ecto OpenInference schemas to balance query speed and schema flexibility.
- Phase 2 (MCP-03): Validating input arguments via `Ecto.Changeset.cast/3` and a dynamic schema map matching the required interface.
- Phase 4-02: Created an ExUnit case template macro `Scoria.EvalCase` to segregate fast unit tests from slow evaluation runs.
- Phase 4-02: Set up a Mix task `scoria.eval` that starts the Ecto repository and parses the `--dataset` argument.
- Phase 5: Introduced `Scoria.Workflows` as the durable workflow source of truth with Ecto-backed runs, steps, checkpoints, events, approvals, and handoffs.
- Phase 5: Added exact resume, retry-failed-step, and a trace-first workflow LiveView at `/scoria/workflows/:id`.
- Phase 5: Kept Jido interoperability behind `Scoria.Workflows.JidoAdapter`.
- Phase 6: Kept `Scoria.Knowledge` as the sole public context for corpus, retrieval, citation, and grounding work.
- Phase 6: Used pgvector as the default retrieval backend behind a narrow adapter boundary.
- Phase 6: Made citation anchors machine-readable and offset-valid before any optional judge review.
- Phase 7 (07-07): Kept alert and incident root rows optimistic-lock ready with explicit stable keys rather than opaque map storage.
- Phase 7 (07-07): Stored audit payload hashes and redacted refs instead of raw sensitive arguments in durable outbox rows.
- Phase 7 (07-04): Audit outbox rows are created transactionally at workflow approvals and MCP execution seams, with telemetry emitted only after commit.
- Phase 7 (07-04): Incident dedupe keys use tenant, subject kind, policy key, reason code, and window bucket to keep operator incidents low-cardinality while preserving append-only evidence.
- Phase 7 (07-03): External-effect breaker state is enforced at runtime and MCP seams with deterministic open-state tracking plus reason-coded telemetry.
- Phase 7 (07-08): Relay polling stays supervised in normal boots, but timer-driven polling is disabled in `MIX_ENV=test` to avoid sandbox ownership conflicts.
- Phase 8: Breaker-open exits now reconcile durable reservations to zero actual usage before failing workflow or MCP execution.
- Phase 9: Operator approvals mutate truth only through `Scoria.Workflows`, and real incident routing now produces durable delivery rows and operator evidence lineage.
- Phase 10: Runtime and incident lifecycle telemetry now emit from live seams, while `mix test` and `mix test.knowledge` run as separate explicit verification lanes.
- Phase 11: Re-verified Seismograph and aligned project state, roadmap, and requirement artifacts to the shipped baseline.
- Phase 12 planning decision: activate `v1.4 Keystone` next, focused on identity, public runtime API, and adoptable Phoenix integration defaults.
- Phase 18: Keep the adoption proof as checked docs/source/test seams and a bounded `mix test.adoption` lane instead of a browser-E2E-first harness.
- Milestone activation decision for `v1.5`: remote connector support stays stateless-first by default, with operator/audit visibility prioritized over breadth.
- Milestone activation decision for `v1.6`: `v1.5 Switchyard` successfully shipped. Focus shifts to prompt lifecycle and eval-release operations.
- Phase 23 (23-01): Used the tiktoken hex package with the native Rust bindings to handle accurate prompt token estimation for gpt-4o.
- Phase 23 (23-01): Handled potential string or atom keys in prompt template maps uniformly.
- Phase 23 (23-01): Implemented robust nil-handling and concatenation strategies for upper-bound token estimation without risking crashes.
- Phase 32: Adjusted `ai_compacted_memories` to use `:binary` for embeddings to ensure environment compatibility.
- Phase 32: Increased database connection `pool_size` to 20 in `test.exs` to stabilize concurrent tests.
- Phase 39 (39-01): Keep replay source-run lookup inside `Scoria.Runtime.get_run_detail!/1` so UI layers consume `comparison_by_step` and `replay_provenance_strip` from curated runtime DTOs.
- Phase 39 (39-01): Prefer explicit `source_step_id` lineage from checkpoints, events, and approvals before falling back to step-sequence matching in replay comparisons.
- Phase 39 (39-02): Load `Workflows.get_run_tree!/1` and `Runtime.get_run_detail!/1` together so the workflow tree stays topology-driven while the right rail stays DTO-driven.
- Phase 39 (39-02): Keep `WorkflowDetailPanelComponent` as the shell and CTA host while delegating grouped comparison rendering to `ReplayEvidenceNotebookComponent`.
- Phase 39 (39-03): Open dataset promotions call `Scoria.Eval.promote_workflow_source/1`, while sealed baselines route through `Scoria.Workflows.request_baseline_promotion/1`.
- Phase 39 (39-03): Baseline promotion approvals use the exact `dataset_baseline_promotion` tool identity so workflow projections expose durable lineage and replay provenance.
- Phase 39 (39-04): Sealed baseline targets stay visible in the promotion modal, but the baseline lane requires an explicit confirmation step before `Scoria.Workflows.request_baseline_promotion/1`.
- Phase 39 closeout: user accepted automation-substituted UAT after targeted LiveView interaction tests revalidated replay UX and promotion flows, and the repo proved non-browserable in isolation without a host endpoint/server dependency.
- Phase 40 (40-01): Kept `ai_scores.reasoning/details` as compatibility aliases while promoting `explanation`, `metadata`, and scorer provenance to the canonical online-scoring contract.
- Phase 40 (40-01): Repaired the Phase 25 convergence migration so fresh databases materialize the typed `EvalSpec` and `EvalRun` contract required by current eval workers.
- Phase 40 (40-03): Online scoring runs through the existing `CampaignWorker` lane, with deterministic evidence persisted before any optional judge call.
- Phase 40 (40-03): Judge-backed online scoring appends onto deterministic score rows by feeding base score attrs through `JudgeRunner`, preserving retry idempotence.
- Phase 40 (40-04): Review queue reads live behind `Scoria.Eval.ReviewQueue`, which owns severity ordering, deep links, and promotion context DTOs.
- Phase 40 (40-05): Queue-selected rationale/provenance is preserved on both `/scoria/workflows/:id` and `/scoria?runtime=...` via `review_candidate_id`.
- Phase 40 (40-06): Queue promotion reuses the shared workflow-source promotion payload builder instead of duplicating snapshot shaping in the UI.
- Phase 40 (40-07): Sealed-baseline requests stay behind the exact `dataset_baseline_promotion` workflow approval identity, and queue detail DTOs retain approval lineage.

**Todos:**

- Start Phase 44 planning for semantic cache contract and persistence.
- Preserve semantic fast-path scope as tenant-partitioned, evidence-first, and safe-read-only.
- Keep operator diagnostics and verification in-scope rather than treating them as post-feature cleanup.

**Blockers:**

- None. `mix test test/scoria/eval/offline_runner_test.exs test/scoria/eval/eval_run_persistence_test.exs test/scoria_web/live/orchestrator_live_test.exs --trace` passed `15 tests, 0 failures`, and a fresh isolated `mix test` passed `3 doctests, 344 tests, 0 failures (13 excluded)` on 2026-05-25.

## Deferred Items

Items deferred or intentionally outside shipped milestone scope:

| Category | Item | Status |
|----------|------|--------|
| tech debt | Project-level full-suite `mix test` failures outside the owned v1.9 verification lanes | cleared by Phase `43.1` on 2026-05-25 |
| tech debt | Project-level full-suite warning audit outside the owned adoption lane still has not been rerun after the post-`v1.9` support-truth shims | still unverified |
| tech debt | LiveView async teardown noise in the workflow/replay test lane | accepted at `v1.9` close |
| future milestone | Hosted connector marketplace / broker behavior | deferred beyond `v1.5` |
| future milestone | First-party browser/code-exec productization | deferred until connector policy and evidence are proven boring |
| future milestone | Advanced bounded-handoff examples beyond the shipped Relay lane | deferred unless post-Relay adoption evidence proves they are needed |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work |
| Phase 41 P01 | 11 min | 2 tasks | 8 files |
| Phase 41 P02 | 3 min | 2 tasks | 3 files |
| Phase 41 P03 | 4 min | 2 tasks | 6 files |
