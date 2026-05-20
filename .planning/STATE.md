# Project State

## Project Reference
**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** v1.7 Outrider milestone planning complete. Ready to begin execution.

## Current Position
**Milestone:** v1.7 Outrider
**Phase:** 29
**Plan:** 04
**Status:** Planned
**Last activity:** [current date] - Completed v1.7 Outrider milestone planning

**Progress:**
`[--------------------------------------------------] Milestone v1.7 Planned`

## Performance Metrics
- **Completed Phases:** 27
- **Completed Plans:** 89
- **Total Validated Requirements:** 81
- **Coverage:** 100% on shipped milestones through `v1.6 Flightpath`
- **Latest Shipped Milestone:** `v1.6 Flightpath` on 2026-05-19

**Phase 23 Metrics:**
- **23-01:** 10m, 2 tasks, 4 files
- **23-02:** 10m, 2 tasks, 3 files
- **23-03:** 5m, 1 tasks, 2 files

**Phase 24 Metrics:**
- **24-01:** 15m, 1 tasks, 4 files
- **24-02:** 10m, 1 tasks, 2 files
- **24-03:** 15m, 3 tasks, 3 files

**Phase 25 Metrics:**
- **25-01:** 25m, 3 tasks, 6 files
- **25-02:** 40m, 3 tasks, 10 files
- **25-03:** 20m, 2 tasks, 4 files

**Phase 26 Metrics:**
- **26-01:** 20m, 2 tasks, 3 files
- **26-02:** 15m, 1 tasks, 2 files
- **26-03:** 15m, 2 tasks, 3 files

**Phase 27 Metrics:**
- **27-01:** 10m, 3 tasks, 4 files

## Accumulated Context
**Decisions:**
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

**Todos:**
- Discuss and define requirements for milestone `v1.7 Outrider` using `/gsd-new-milestone`.

**Blockers:**
- None.

**Reference Updates:**
- `v1.6 Flightpath` shipped-state evidence remains in `.planning/milestones/v1.6-ROADMAP.md`, `.planning/milestones/v1.6-REQUIREMENTS.md`, and Phase 23-26 verification artifacts.

## Deferred Items

Items intentionally outside `v1.5 Switchyard` by default:

| Category | Item | Status |
|----------|------|--------|
| future milestone | Prompt/version release operations | deferred to likely `v1.6 Flightpath` |
| future milestone | Hosted connector marketplace / broker behavior | deferred beyond `v1.5` |
| future milestone | First-party browser/code-exec productization | deferred until connector policy and evidence are proven boring |
| seed | SEED-001-agentcore-lessons | active reference for connector-boundary decisions |
