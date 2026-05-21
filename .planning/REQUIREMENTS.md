# Requirements: v1.8 Vanguard

## Overview

The `v1.8 Vanguard` milestone introduces highly resilient multi-model orchestration and robust distributed evaluation execution. It establishes the primitives required for scale: circuit breaking, dynamic model fallback, and massive fan-out of evaluations via Oban, all while strictly adhering to the "operator-visible" and Phoenix-first mandates.

## Scope

- **In Scope:**
  - Node-local ETS circuit breakers and explicit Req retry steps.
  - Oban queue segregation and scalable batch job insertion.
  - Multi-model fallback orchestration across provider chains.
  - Distributed evaluation fan-out coordinated through Oban workers.
  - LiveView dashboards for model health and evaluation progress.
- **Out of Scope:**
  - Tenant-aware rate shaping.
  - External evaluation services such as LangSmith.
  - Complex DAG orchestration or LangGraph-style flow builders.
  - Cluster-aware circuit breakers beyond the node-local ETS boundary.
  - Telemetry-driven p95 latency rerouting.

## Core Requirements

### ORCH-01: Model Fallback Routing
Scoria must support static fallback chains across LLM providers so failed primary requests can route automatically to a compatible secondary model.

### ORCH-02: Circuit Breakers
Scoria must track rolling failure rates and latencies of models using ETS and trip when a model becomes unhealthy.

### ORCH-03: Configurable Retry Policies
Scoria must handle HTTP 429s gracefully with jittered exponential backoff implemented through `Req` steps.

### EVAL-01: Oban Queue Segregation
Scoria must separate background processing into `inference`, `evals`, and `system` queues.

### EVAL-02: Distributed Eval Coordinator
Scoria must schedule large-scale evaluation campaigns across multiple models and tenants.

### EVAL-03: Scalable Evaluation Insertion
Scoria must use `Oban.insert_all` to batch queue evaluation jobs and prevent database contention.

### OBS-01: Live Eval Progress Matrix
Scoria must provide a real-time LiveView dashboard that streams Oban job completions and campaign progress.

### OBS-02: Circuit Breaker State Visibility
Scoria must provide LiveView visibility into the ETS-backed model health state.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ORCH-01 | Phase 35 | Pending |
| ORCH-02 | Phase 35 | Pending |
| ORCH-03 | Phase 35 | Pending |
| EVAL-01 | Phase 35 | Pending |
| EVAL-02 | Phase 35 | Pending |
| EVAL-03 | Phase 35 | Pending |
| OBS-01 | Phase 35 | Pending |
| OBS-02 | Phase 35 | Pending |
