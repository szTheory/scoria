---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: milestone
status: ready_to_plan
last_updated: 2026-05-23T10:16:22.178Z
last_activity: 2026-05-23
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 6
  completed_plans: 110
  percent: 25
stopped_at: Phase 38 complete (3/3) — ready to discuss Phase 39
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Phase 39 — replay operator ux & draft dataset promotion

## Current Position

Phase: 38 (replay-safe-execution-tool-modes) — EXECUTING
Plan: 1 of 3
**Milestone:** `v1.9 Crucible`
**Phase:** 39
**Plan:** Not started
**Status:** Ready to plan
**Last activity:** 2026-05-23

**Progress:**
`[..................................................] 0% - v1.9 Crucible Started`

## Performance Metrics

- **Completed Phases:** 36
- **Completed Plans:** 103
- **Total Validated Requirements:** 106
- **Coverage:** 100% on shipped milestones through `v1.8 Vanguard`
- **Latest Shipped Milestone:** `v1.8 Vanguard` on 2026-05-22

**Phase 31 Metrics:**

- **31-01:** 15m, 2 tasks, 4 files
- **31-02:** 20m, 3 tasks, 6 files
- **31-03:** 10m, 2 tasks, 3 files

**Phase 32 Metrics:**

- **32-01:** 15m, 2 tasks, 4 files
- **32-02:** 20m, 3 tasks, 5 files

## Accumulated Context

**Decisions:**

- Milestone activation decision for `v1.9`: prioritize replayable debugging and online scoring with reviewable dataset promotion over semantic caching and broad handoff productization.
- Milestone activation decision for `v1.9`: online scoring remains additive evidence only; sealed baseline datasets are never auto-mutated.
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

**Todos:**

- Run `$gsd-plan-phase 37` to start `v1.9 Crucible`.

**Blockers:**

- None.

## Deferred Items

Items intentionally outside `v1.8 Vanguard` by default:

| Category | Item | Status |
|----------|------|--------|
| tech debt | Normalize Nyquist frontmatter for Phases 30-32 if they re-enter audit scope | accepted at `v1.8` close |
| future milestone | Hosted connector marketplace / broker behavior | deferred beyond `v1.5` |
| future milestone | First-party browser/code-exec productization | deferred until connector policy and evidence are proven boring |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work |
