# Phase 31 Validation: Model Routing and Resiliency Foundation

This document records the executable proof inputs for the canonical Phase 31 backfill completed by Phase 35. Requirement closure lives in `31-VERIFICATION.md`.

## Validation Scenarios

### Scenario 1: Circuit Breaker State Transition

**Objective:** Prove that the ETS-backed circuit breaker opens after crossing the failure threshold and sweeps back toward half-open after the timeout window.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/observe/circuit_breaker_test.exs test/scoria/observe/circuit_breaker_manager_test.exs
```

**Expected Outcome:**
The focused breaker tests prove failure counting, open-state transitions, and manager-driven timeout sweeps on the supported test configuration.

### Scenario 2: Req Pipeline Interception

**Objective:** Prove that outbound `Req` calls integrate with the circuit breaker, short-circuit when the breaker is open, and treat retry-exhausted HTTP failures as breaker failures.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/req/steps/circuit_breaker_test.exs test/scoria/req/steps/resiliency_test.exs test/scoria/req/steps_test.exs
```

**Expected Outcome:**
The Req step tests prove retry behavior, breaker-aware short-circuiting, and resilient request execution through the supported pipeline.

### Scenario 3: Worker Integration

**Objective:** Prove that application workers use the resilient request path rather than bypassing it.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/compaction/summarize_worker_test.exs
```

**Expected Outcome:**
The worker test proves the compaction path routes through the resilient request wiring expected by Phase 31 instead of manually constructing a divergent outbound seam.

## Canonical Closeout

- `ORCH-02` closes through the explicit circuit-breaker transition proof lane.
- `ORCH-03` closes through the Req interception and worker-integration proof lanes.
- The canonical requirement closure and backfill chronology are recorded in `31-VERIFICATION.md`.
