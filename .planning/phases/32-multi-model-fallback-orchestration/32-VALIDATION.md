# Phase 32 Validation: Multi-Model Fallback Orchestration

This document records the executable proof inputs for the canonical Phase 32 backfill completed by Phase 35. Requirement closure lives in `32-VERIFICATION.md`.

## Validation Scenarios

### Scenario 1: Orchestrator fallback on primary failure

**Objective:** Prove that `Scoria.Orchestrator` tries a configured fallback model when the primary model fails.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/orchestrator_test.exs
```

**Expected Outcome:**
The focused orchestrator tests prove fallback ordering, fallback telemetry, and successful return of the fallback result when the primary call fails.

### Scenario 2: Exhaustion of the fallback chain

**Objective:** Prove that the orchestrator returns the final error when every model in the fallback chain fails, without looping indefinitely.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/orchestrator_test.exs
```

**Expected Outcome:**
The orchestrator tests prove each configured model is attempted at most once in sequence and that failure exits remain bounded.

### Scenario 3: Caller integration with the orchestrator

**Objective:** Prove that application workers route through `Scoria.Orchestrator` rather than calling lower-level model clients directly.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/compaction/summarize_worker_test.exs test/scoria/eval/judge_runner_test.exs
```

**Expected Outcome:**
The worker tests prove the compaction and eval seams both use the orchestrator boundary and receive fallback-aware behavior through the supported caller path.

## Canonical Closeout

- `ORCH-01` closes through the orchestrator fallback lane plus caller-integration proof.
- The canonical requirement closure and backfill chronology are recorded in `32-VERIFICATION.md`.
