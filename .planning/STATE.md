---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: tenant-scoped semantic fast path
status: shipped
last_updated: "2026-05-25T16:08:00.000Z"
last_activity: 2026-05-25
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 12
  completed_plans: 12
  percent: 100
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** milestone closed; ready to define the next milestone

## Current Position

Phase: milestone complete
Plan: archived
**Milestone:** `v2.1 Tenant-scoped semantic fast path`
**Phase:** Archived
**Plan:** Archived
**Status:** Shipped on 2026-05-25
**Last activity:** 2026-05-25

**Progress:**
[██████████] 100%

## Performance Metrics

- **Milestone Phases:** 3
- **Milestone Plans:** 12
- **Milestone Task Count:** 28 planned tasks across Phases 44-46
- **Coverage:** 100% on shipped milestones through `v2.1 Tenant-scoped semantic fast path`
- **Latest Shipped Milestone:** `v2.1 Tenant-scoped semantic fast path` on 2026-05-25
- **Active Milestone:** none

## Accumulated Context

### Roadmap Evolution

- Phase `43.1` was inserted after Phase `43` to restore a clean `v2.0 Relay` closeout baseline.
- Phases `44-46` shipped `v2.1 Tenant-scoped semantic fast path` with archived roadmap and requirements ledgers.

**Decisions:**

- `v2.0 Relay` closed the bounded handoff lane with explicit same-run lineage, projected-context safety, and canonical adoption proof.
- `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible middleware.
- Semantic reuse is opt-in through explicit safe read-only lanes, and misses, rejects, and stale entries preserve the normal workflow truth path.
- Operator trust depends on runtime and workflow surfaces projecting semantic evidence from durable runtime metadata and semantic entry/event history.
- The trusted `v2.1` proof lane is `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path`.

**Todos:**

- Start the next milestone with `$gsd-new-milestone` when the next scope decision is ready.

**Blockers:**

- None. Phase `44` proof (`18 tests, 0 failures`), Phase `45` proof (`18 tests, 0 failures`), the named semantic lane (`44 tests, 0 failures`), and the docs/source lane (`7 tests, 0 failures`) all passed on 2026-05-25 before ship.

## Deferred Items

Items deferred or intentionally outside shipped milestone scope:

| Category | Item | Status |
|----------|------|--------|
| tech debt | Project-level full-suite warning audit outside the owned adoption lane still has not been rerun after the post-`v1.9` support-truth shims | still unverified |
| tech debt | LiveView async teardown noise in the workflow/replay test lane | accepted at `v1.9` close |
| future milestone | Hosted connector marketplace / broker behavior | deferred beyond `v1.5` |
| future milestone | First-party browser/code-exec productization | deferred until connector policy and evidence are proven boring |
| future milestone | Advanced bounded-handoff examples beyond the shipped Relay lane | deferred unless post-Relay adoption evidence proves they are needed |
| future milestone | External semantic cache backends and advanced tuning | deferred until the embedded default semantic lane proves boring in practice |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work |
