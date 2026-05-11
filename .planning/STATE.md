# Project State

## Project Reference
**Name:** Scoria
**Core Value:** A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications, adhering to the szTheory "SaaS in a Box" DNA.
**Current Focus:** v1.1 Caldera shipped. Planning v1.2 Corpus.

## Current Position
**Milestone:** v1.1
**Status:** Shipped

**Progress:**
`[##################################################] 100%`

## Performance Metrics
- **Completed Phases:** 5
- **Completed Plans:** 18
- **Total Requirements:** 26
- **Coverage:** 100%
- **Phase 5 Verification:** `MIX_ENV=test mix test` passed on 2026-05-11
- **Phase 5 Surface:** Durable workflow runtime, recovery, and operator UI shipped

## Accumulated Context
**Decisions:**
- Decoupled `scoria_observe` (traces) from `scoria_eval` to avoid a "God Package" architecture.
- Follow OpenInference specifications for trace/span structures.
- Use Ecto as the primary state engine (no external databases required).
- UI will heavily rely on LiveView and PubSub, specifically coalescing token streams to avoid DOM bloat.
- MCP transport strictly separated from UI websockets.
- Phase 1 (OBS-03): Use Native OTP Buffer (GenServer + ETS) for async span batching to avoid external dependencies.
- Phase 1 (OBS-04): Use Hybrid Configurable Deny-list + MFA Escape Hatch for telemetry redaction.
- Phase 1 (OBS-01): Use Core Columns + JSONB Attributes for the Ecto OpenInference schemas to balance query speed and schema flexibility.
- Phase 2 (MCP-03): Validating input arguments via Ecto.Changeset.cast/3 and a dynamic schema map matching the required interface.
- Phase 4-02: Created an ExUnit case template macro Scoria.EvalCase to segregate fast unit tests from slow evaluation runs.
- Phase 4-02: Set up a Mix task scoria.eval that starts the Ecto repository and parses the --dataset argument.
- Phase 5: Introduced `Scoria.Workflows` as the durable workflow source of truth with Ecto-backed runs, steps, checkpoints, events, approvals, and handoffs.
- Phase 5: Added exact resume, retry-failed-step, and a trace-first workflow LiveView at `/scoria/workflows/:id`.
- Phase 5: Kept Jido interoperability behind `Scoria.Workflows.JidoAdapter`.
- Phase 7 (07-07): Kept alert and incident root rows optimistic-lock ready with explicit stable keys rather than opaque map storage.
- Phase 7 (07-07): Stored audit payload hashes and redacted refs instead of raw sensitive arguments in durable outbox rows.
- Phase 7 (07-04): Audit outbox rows are created transactionally at workflow approvals and MCP execution seams, with telemetry emitted only after commit.
- Phase 7 (07-04): Incident dedupe keys use tenant, subject kind, policy key, reason code, and window bucket to keep operator incidents low-cardinality while preserving append-only evidence.

**Todos:**
- Plan Phase 6: Advanced RAG, Citations & Knowledge Grounding.

**Blockers:**
- None

**Reference Updates:**
- AWS Bedrock AgentCore research captured in `.planning/research/agentcore-lessons.md`.
- Future planning seed captured in `.planning/seeds/SEED-001-agentcore-lessons.md`.
- Phase 7 incident, delivery, and audit storage summary captured in `.planning/phases/07-seismograph/07-07-SUMMARY.md`.
- Phase 7 transactional audit and incident routing summary captured in `.planning/phases/07-seismograph/07-04-SUMMARY.md`.
