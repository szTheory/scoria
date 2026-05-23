# Scoria Roadmap

**Active milestone:** `v1.9 Crucible`
**Started:** 2026-05-22
**Theme:** Replayable debugging and online quality feedback
**Why now:** Close the operator loop around the surfaces Scoria already owns: trace truth, replayable remediation, score overlays, and reviewable dataset promotion.
**Archive note:** `v1.8 Vanguard` shipped on 2026-05-22. Historical roadmap: `.planning/milestones/v1.8-ROADMAP.md`

## Phases

- [ ] **Phase 37: Replay Lineage & Branch Model** - Create replay branches as durable new runs rooted in existing checkpoint truth.
- [ ] **Phase 38: Replay-Safe Execution & Tool Modes** - Enforce safe replay defaults and historical-stub boundaries for external effects.
- [ ] **Phase 39: Replay Operator UX & Draft Dataset Promotion** - Add replay provenance, diff context, and draft dataset promotion to the operator surface.
- [ ] **Phase 40: Online Scoring & Review Queue** - Sample production traces asynchronously, attach additive score evidence, and route reviewable promotion candidates into operator workflows.

## Phase Details

### Phase 37: Replay Lineage & Branch Model
**Goal**: Operators can branch a new replay run from a chosen source checkpoint without mutating original run history.
**Depends on**: Phase 36
**Requirements**: RPLY-01
**Success Criteria**:
1. Replay branch creation persists `source_run_id`, `source_checkpoint_id`, override metadata, and execution mode as durable truth.
2. Replay runs reuse the existing workflow runtime instead of introducing a second execution engine.
3. Replay lineage is queryable from the public run detail surface and trace explorer.

### Phase 38: Replay-Safe Execution & Tool Modes
**Goal**: Replay execution preserves operator trust by defaulting unsafe effects to explicit safe modes.
**Depends on**: Phase 37
**Requirements**: RPLY-02
**Plans**: 3 plans
Plans:
- [ ] `38-01-PLAN.md` — Add replay-safe persistence contracts, schema fields, and resolver types.
- [ ] `38-02-PLAN.md` — Enforce replay-safe behavior in workflow, connector, and MCP execution seams.
- [ ] `38-03-PLAN.md` — Project replay-safe seam evidence through public runtime DTOs and tests.
**Success Criteria**:
1. External-write and approval-sensitive seams are blocked or historically stubbed by default during replay.
2. Replay-safe adapters make execution mode explicit per tool/result class.
3. Verification proves no replay path silently escapes into live side effects.

### Phase 39: Replay Operator UX & Draft Dataset Promotion
**Goal**: Operators can inspect replay provenance, compare outcomes, and promote reviewed traces into draft dataset items.
**Depends on**: Phase 38
**Requirements**: RPLY-03, DATA-01, DATA-02
**Success Criteria**:
1. LiveView shows source checkpoint, overrides, execution mode, and original-vs-replay context clearly.
2. Operators can promote either original or replayed traces into draft dataset items backed by frozen evidence snapshots.
3. Sealed datasets remain immutable, and promotion into release-driving baselines requires explicit approval flow.
**UI hint**: yes

### Phase 40: Online Scoring & Review Queue
**Goal**: Scoria can asynchronously score sampled production traces and route reviewable candidates into operator-visible queues.
**Depends on**: Phase 39
**Requirements**: SCOR-01, SCOR-02, SCOR-03, SCOR-04
**Success Criteria**:
1. Production trace sampling and score execution run asynchronously through Oban, with zero request-path scoring latency.
2. Deterministic-first rules and optional judge scoring attach additive evidence with scorer version, model, and sampling provenance.
3. Operators can triage low-quality traces, inspect score rationale, and approve or dismiss draft promotion candidates without mutating sealed datasets.
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Notes |
|-------|----------------|--------|-------|
| 37. Replay Lineage & Branch Model | 0/0 | Planned | Start with `$gsd-plan-phase 37` |
| 38. Replay-Safe Execution & Tool Modes | 2/3 | In Progress|  |
| 39. Replay Operator UX & Draft Dataset Promotion | 0/0 | Planned | Depends on replay truth and safety modes |
| 40. Online Scoring & Review Queue | 0/0 | Planned | Depends on replay-driven evidence and draft promotion lanes |
