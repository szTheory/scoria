# Scoria v1.8 Vanguard Roadmap

## Phases

- [ ] **Phase 30: Oban Infrastructure & Queue Segregation** - Establish isolated background processing queues and batch insertion.
- [ ] **Phase 31: Model Routing & Resiliency Foundation** - Implement ETS-backed circuit breakers and bounded retries.
- [ ] **Phase 32: Multi-Model Fallback Orchestration** - Enable automatic model routing based on health and fallback chains.
- [ ] **Phase 33: Distributed Evaluation Fan-out** - Build the eval coordinator and workers for massive campaign execution.
- [ ] **Phase 34: Real-time Operator Dashboards** - Expose orchestration state and eval progress via LiveView.

## Phase Details

### Phase 30: Oban Infrastructure & Queue Segregation
**Goal**: Distributed jobs can be enqueued and executed in isolated queues without starving web requests.
**Depends on**: Phase 29
**Requirements**: EVAL-01, EVAL-03
**Success Criteria**:
  1. Oban is configured with isolated queues for `inference`, `evals`, and `system`.
  2. Batch insertion of 100+ simulated jobs uses `Oban.insert_all` without blocking the Ecto connection pool.
  3. Jobs are processed independently based on queue assignment.
**Plans**: 2 plans
- [ ] 30-01-PLAN.md — Queue configuration supporting explicit limits and environment overrides
- [ ] 30-02-PLAN.md — Batch queuing utility wrapping Ecto.Multi inserts

### Phase 31: Model Routing & Resiliency Foundation
**Goal**: System correctly identifies and handles model failures via ETS-backed circuit breakers and bounded retries.
**Depends on**: Phase 30
**Requirements**: ORCH-02, ORCH-03
**Success Criteria**:
  1. Node-local ETS table tracks model health state (open/closed circuit).
  2. Outbound `Req` calls use explicit retries with exponential backoff for 429s.
  3. Repeated failures trip the circuit breaker, immediately returning errors without waiting for timeouts.
**Plans**: 3 plans
- [ ] 31-01-PLAN.md — ETS Circuit Breaker Foundation
- [ ] 31-02-PLAN.md — Req Resiliency Middleware Steps
- [ ] 31-03-PLAN.md — Pipeline and Worker Integration

### Phase 32: Multi-Model Fallback Orchestration
**Goal**: Failed model requests automatically route to secondary models transparently based on fallback chains.
**Depends on**: Phase 31
**Requirements**: ORCH-01
**Success Criteria**:
  1. Orchestrator detects a tripped circuit for the primary model.
  2. Request is automatically routed to an appropriate fallback model matching context capabilities.
  3. Telemetry events are emitted for both failures and successful fallbacks.
**Plans**: TBD

### Phase 33: Distributed Evaluation Fan-out
**Goal**: Operators can run large evaluation campaigns across multiple models and tenants simultaneously.
**Depends on**: Phase 32
**Requirements**: EVAL-02
**Success Criteria**:
  1. Eval Coordinator accepts a campaign and fans out individual evaluation jobs via Oban.
  2. Individual eval workers execute requests through the `Scoria.Orchestrator.Router`.
  3. Worker results are written back to the database.
**Plans**: TBD

### Phase 34: Real-time Operator Dashboards
**Goal**: Operators can visualize multi-model health and distributed evaluation progress in real-time.
**Depends on**: Phase 33
**Requirements**: OBS-01, OBS-02
**Success Criteria**:
  1. LiveView dashboard displays real-time health (ETS state) of all configured models.
  2. Eval campaign progress is streamed to a LiveView interface via `Phoenix.PubSub`.
  3. Operator can visually distinguish between primary model success and fallback usage.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 30. Oban Infrastructure & Queue Segregation | 2/2 | Complete | 2026-05-20 |
| 31. Model Routing & Resiliency Foundation | 0/3 | Not started | - |
| 32. Multi-Model Fallback Orchestration | 0/3 | Not started | - |
| 33. Distributed Evaluation Fan-out | 0/3 | Not started | - |
| 34. Real-time Operator Dashboards | 0/3 | Not started | - |