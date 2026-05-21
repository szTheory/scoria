# Scoria v1.8 Vanguard Roadmap

## Phases

- [x] **Phase 30: Oban Infrastructure & Queue Segregation** - Establish isolated background processing queues and batch insertion.
- [x] **Phase 31: Model Routing & Resiliency Foundation** - Implement ETS-backed circuit breakers and bounded retries.
- [x] **Phase 32: Multi-Model Fallback Orchestration** - Enable automatic model routing based on health and fallback chains.
- [ ] **Phase 33: Distributed Evaluation Fan-out** - Build the eval coordinator and workers for massive campaign execution.
- [ ] **Phase 34: Real-time Operator Dashboards** - Expose orchestration state and eval progress via LiveView.
- [ ] **Phase 35: Vanguard Verification Backfill** - Restore the canonical verification chain for Phases 30 through 34 and close the orphaned v1.8 requirements.
- [ ] **Phase 36: Vanguard Milestone-State Reconciliation** - Align live milestone-state artifacts to the restored v1.8 verification truth.

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
- [x] 30-01-PLAN.md — Queue configuration supporting explicit limits and environment overrides
- [x] 30-02-PLAN.md — Batch queuing utility wrapping Ecto.Multi inserts

### Phase 31: Model Routing & Resiliency Foundation
**Goal**: System correctly identifies and handles model failures via ETS-backed circuit breakers and bounded retries.
**Depends on**: Phase 30
**Requirements**: ORCH-02, ORCH-03
**Success Criteria**:
  1. Node-local ETS table tracks model health state (open/closed circuit).
  2. Outbound `Req` calls use explicit retries with exponential backoff for 429s.
  3. Repeated failures trip the circuit breaker, immediately returning errors without waiting for timeouts.
**Plans**: 3 plans
- [x] 31-01-PLAN.md — ETS Circuit Breaker Foundation
- [x] 31-02-PLAN.md — Req Resiliency Middleware Steps
- [x] 31-03-PLAN.md — Pipeline and Worker Integration

### Phase 32: Multi-Model Fallback Orchestration
**Goal**: Failed model requests automatically route to secondary models transparently based on fallback chains.
**Depends on**: Phase 31
**Requirements**: ORCH-01
**Success Criteria**:
  1. Orchestrator detects a tripped circuit for the primary model.
  2. Request is automatically routed to an appropriate fallback model matching context capabilities.
  3. Telemetry events are emitted for both failures and successful fallbacks.
**Plans**: 2 plans
- [x] 32-01-PLAN.md — Orchestrator Domain Logic
- [x] 32-02-PLAN.md — Integration in Callers

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
**Plans**: 3 plans
- [ ] 34-01-PLAN.md — Durable dashboard projections, fallback provenance, and refresh broadcasts
- [ ] 34-02-PLAN.md — `OrchestratorLive` summary strip, model health matrix, and campaign board
- [ ] 34-03-PLAN.md — Inline campaign drill-in and eval-run detail route
**UI hint**: yes

### Phase 35: Vanguard Verification Backfill
**Goal**: Restore the missing canonical verification chain for Vanguard so implemented requirements are no longer orphaned from milestone closure.
**Depends on**: Phases 30, 31, 32, 33, 34
**Requirements**: EVAL-01, EVAL-02, EVAL-03, ORCH-01, ORCH-02, ORCH-03, OBS-01, OBS-02
**Gap Closure**: Backfills `30-VERIFICATION.md` through `34-VERIFICATION.md`, adds `33-VALIDATION.md`, and closes the verification gaps identified in `.planning/v1.8-MILESTONE-AUDIT.md`.
**Success Criteria**:
  1. Phases 30 through 34 each have canonical `*-VERIFICATION.md` artifacts.
  2. Phase 33 has a `33-VALIDATION.md` artifact aligned to the verification chain.
  3. Every v1.8 requirement has canonical verification evidence instead of orphaned summary-only closure.
**Plans**: TBD

### Phase 36: Vanguard Milestone-State Reconciliation
**Goal**: Reconcile the live v1.8 planning surfaces so roadmap, requirements, and milestone state agree with the restored verification chain.
**Depends on**: Phase 35
**Requirements**: Milestone state reconciliation for v1.8 closure readiness
**Gap Closure**: Reconciles the live milestone-state drift identified in `.planning/v1.8-MILESTONE-AUDIT.md` across roadmap, requirements, state, project, milestone ledger, and milestone arc surfaces.
**Success Criteria**:
  1. `.planning/ROADMAP.md`, `.planning/milestones/v1.8-ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/milestones/v1.8-REQUIREMENTS.md` agree on active v1.8 truth.
  2. `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/MILESTONE-ARC.md` no longer describe stale milestone status.
  3. Validation notes and verification references reflect the repo's current supported proof lane configuration.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 30. Oban Infrastructure & Queue Segregation | 2/2 | Complete | 2026-05-20 |
| 31. Model Routing & Resiliency Foundation | 3/3 | Complete | 2026-05-20 |
| 32. Multi-Model Fallback Orchestration | 2/2 | Complete | 2026-05-20 |
| 33. Distributed Evaluation Fan-out | 0/3 | Not started | - |
| 34. Real-time Operator Dashboards | 0/3 | Not started | - |
| 35. Vanguard Verification Backfill | 0/0 | Not started | - |
| 36. Vanguard Milestone-State Reconciliation | 0/0 | Not started | - |
