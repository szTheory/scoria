# Roadmap: v1.7 Outrider

## Phases

- [x] **Phase 27: MCP Server-Sent Events (SSE) Boundary** - Establish HTTP/SSE interfaces for external runtime interoperability.
- [ ] **Phase 28: Async Session Compaction Engine** - Implement Oban-backed background workers for memory token sliding windows and Ecto summarization.
- [x] **Phase 29: External Runtime Observability & Operator UX** - Expose LiveView presence tracking and memory time-travel diffing.

## Phase Details

### Phase 27: MCP Server-Sent Events (SSE) Boundary
**Goal**: External Python and Node runtimes can connect to Scoria over HTTP/SSE and invoke tools securely.
**Depends on**: Phase 26 (v1.6 Release Gates and Approvals)
**Requirements**: OUTRIDER-01
**Success Criteria** (what must be TRUE):
  1. An external agent can establish an SSE connection to a Scoria Phoenix endpoint.
  2. Scoria can stream MCP standard JSON-RPC payloads to the connected agent.
  3. The agent can respond and invoke a Scoria-registered tool over HTTP/SSE.
**Plans**: TBD

### Phase 28: Async Session Compaction Engine
**Goal**: Scoria transparently compacts old session history without blocking web requests or external agents.
**Depends on**: Phase 27
**Requirements**: OUTRIDER-03, OUTRIDER-04, OUTRIDER-05
**Success Criteria** (what must be TRUE):
  1. An active session that breaches a configured token/time limit automatically enqueues an Oban compaction job.
  2. The Oban worker successfully calls the LLM, summarizes the raw events, and stores the result in a new Ecto schema.
  3. Raw session events are securely archived or soft-deleted from the active context window.
**Plans**: 28-01, 28-02

### Phase 29: External Runtime Observability & Operator UX
**Goal**: Operators can monitor external runtime health and audit the compaction pipeline through the Scoria dashboard.
**Depends on**: Phase 28
**Requirements**: OUTRIDER-02, OUTRIDER-06, OUTRIDER-07
**Success Criteria** (what must be TRUE):
  1. The Scoria LiveView dashboard displays connected external agents in real-time using Phoenix Presence.
  2. A disconnected agent triggers a visible offline state in the dashboard.
  3. An operator can view an active session and see a diff of raw archived events versus the LLM-compacted summaries.
**Plans**: 4 plans
- [x] 29-01-PLAN.md
- [x] 29-02-PLAN.md
- [x] 29-03-PLAN.md
- [x] 29-04-PLAN.md
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 27. MCP Server-Sent Events (SSE) Boundary | 1/1 | Completed | 2026-05-19 |
| 28. Async Session Compaction Engine | 2/2 | Planned | - |
| 29. External Runtime Observability & Operator UX | 4/4 | Completed | 2026-05-20 |
