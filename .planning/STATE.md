---
gsd_state_version: 1.0
milestone: v2.2
milestone_name: oss adopter onramp
status: ready_to_closeout
last_updated: 2026-05-26T14:46:26Z
last_activity: 2026-05-26
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 16
  completed_plans: 16
  percent: 100
stopped_at: Phase 51 verified — milestone v2.2 ready for closeout
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Milestone `v2.2 OSS adopter onramp` — ready for closeout

## Current Position

Phase: 51 (default-lane-verifier-hardening-and-support-truth-re-closeout) — VERIFIED
Plan: 3 of 3
**Milestone:** `v2.2 OSS adopter onramp`
**Phase:** 51
**Plan:** Complete
**Status:** Ready for closeout
**Last activity:** 2026-05-26

**Progress:**
[██████████] 100%

## Performance Metrics

- **Milestone Phases:** 5 planned
- **Milestone Plans:** 16 completed
- **Milestone Task Count:** 7 completed in Phase 47
- **Coverage:** 8 active milestone requirements mapped
- **Latest Shipped Milestone:** `v2.1 Tenant-scoped semantic fast path` on 2026-05-25
- **Active Milestone:** `v2.2 OSS adopter onramp`

## Accumulated Context

### Roadmap Evolution

- Phase `43.1` was inserted after Phase `43` to restore a clean `v2.0 Relay` closeout baseline.
- Phases `44-46` shipped `v2.1 Tenant-scoped semantic fast path` with archived roadmap and requirements ledgers.
- Post-`v2.1` repo-local hardening improved package/install truth and restored the named semantic proof lane before the next milestone opened.
- `v2.2` now turns that reconciled repo truth into an active OSS adopter onramp milestone.

**Decisions:**

- `v2.0 Relay` closed the bounded handoff lane with explicit same-run lineage, projected-context safety, and canonical adoption proof.
- `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible middleware.
- Semantic reuse is opt-in through explicit safe read-only lanes, and misses, rejects, and stale entries preserve the normal workflow truth path.
- Operator trust depends on runtime and workflow surfaces projecting semantic evidence from durable runtime metadata and semantic entry/event history.
- The trusted `v2.1` proof lane is `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path`.
- The next milestone should start from OSS adopter readiness, not new runtime capability: package metadata, host-app install truth, and named proof lanes are part of the product surface.
- `mix scoria.install` now needs to be treated as a host-app contract that copies core migrations, wires defaults, and degrades cleanly when optional Tailwind assets are absent.
- Semantic proof lanes must prepare their own optional knowledge or retrieval tables instead of leaking hidden setup assumptions into the support story.
- `v2.2` should close publishability, consumer proof, and support-truth alignment before Scoria reopens broader capability work.

**Todos:**

- None. Phase 51 verification and the milestone audit are now complete; the next workflow step is milestone closeout/archive.

**Blockers:**

- None. `v2.2` now has canonical verification for Phases 47 through 51, `MIX_ENV=dev mix scoria.release_preview` is green, and `MIX_ENV=test mix test.adoption` passed with `3 doctests, 42 tests, 0 failures` on 2026-05-26.

## Deferred Items

Items deferred or intentionally outside active milestone scope:

| Category | Item | Status |
|----------|------|--------|
| tech debt | Project-level full-suite warning audit outside the owned adoption lane still has not been rerun after the post-`v1.9` support-truth shims | still unverified |
| tech debt | LiveView async teardown noise in the workflow/replay test lane | accepted at `v1.9` close |
| future milestone | Advanced bounded-handoff examples beyond the shipped Relay lane | deferred unless real adopter evidence proves the current lane is still confusing |
| future milestone | External semantic cache backends and advanced tuning | deferred until the embedded default semantic lane and default OSS onramp both prove boring in practice |
| future milestone | Package-family decomposition into multiple Hex libraries | deferred beyond the first OSS adopter closeout |
| future milestone | Hosted demo or managed onboarding surfaces | deferred to preserve the embedded Phoenix product shape |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work |
