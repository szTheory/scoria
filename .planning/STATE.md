# Project State

## Project Reference
**Name:** Scoria
**Core Value:** A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications, adhering to the szTheory "SaaS in a Box" DNA.
**Current Focus:** Implementation of Core Observability complete. Transitioning to Phase 2.

## Current Position
**Phase:** 4
**Plan:** 2
**Status:** 4-02 Completed

**Progress:**
`[###################-------------------------------] 38%`

## Performance Metrics
- **Completed Phases:** 1
- **Completed Plans:** 6
- **Total Requirements:** 19
- **Coverage:** 100%
- **Phase 4-02 Metrics:** 10m, 2 tasks, 4 files

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

**Todos:**
- Begin Phase 2 planning.

**Blockers:**
- None