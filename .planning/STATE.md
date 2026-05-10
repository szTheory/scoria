# Project State

## Project Reference
**Name:** Scoria
**Core Value:** A Phoenix-native "AI Application Quality Layer" providing deep observability, continuous evaluation, and secure governance tailored for Elixir and Phoenix applications, adhering to the szTheory "SaaS in a Box" DNA.
**Current Focus:** Roadmap definition and project initialization.

## Current Position
**Phase:** 0
**Plan:** 0
**Status:** Not started

**Progress:**
`[--------------------------------------------------] 0%`

## Performance Metrics
- **Completed Phases:** 0
- **Completed Plans:** 0
- **Total Requirements:** 19
- **Coverage:** 100%

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

**Todos:**
- Begin Phase 1 planning.

**Blockers:**
- None
