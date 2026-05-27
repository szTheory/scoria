---
gsd_state_version: 1.0
milestone: v2.3
milestone_name: Runtime-to-handoff adoption example
status: planning
last_updated: "2026-05-27T07:38:17.908Z"
last_activity: 2026-05-27
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 33
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Phase 53 — operator evidence and lane guidance

## Current Position

Phase: 53 (operator-evidence-and-lane-guidance) — READY
Plan: 1 of 3
**Milestone:** v2.3 Runtime-to-handoff adoption example
**Phase:** 53
**Plan:** Not started
**Status:** Ready to plan
**Last activity:** 2026-05-27

**Progress:**
[███░░░░░░░] 33%

## Performance Metrics

- **Latest Shipped Milestone:** `v2.2 OSS adopter onramp` on 2026-05-26
- **Archived Milestone Phases:** 5 complete
- **Archived Milestone Plans:** 16 complete
- **Archived Milestone Task Count:** 35 total
- **Coverage:** 8 shipped milestone requirements satisfied
- **Active Milestone:** `v2.3 Runtime-to-handoff adoption example`
- **Active Milestone Scope:** 3 phases, 9 planned plans, 7 active requirements
- **Phase 52 Plan 01:** Completed in 2m04s across 2 tasks and 2 files
- **Phase 52 Plan 02:** Completed in 3m05s across 3 tasks and 4 files
- **Phase 52 Plan 03:** Completed in 3m33s across 3 tasks and 4 files

## Accumulated Context

### Roadmap Evolution

- Phase `43.1` was inserted after Phase `43` to restore a clean `v2.0 Relay` closeout baseline.
- Phases `44-46` shipped `v2.1 Tenant-scoped semantic fast path` with archived roadmap and requirements ledgers.
- Phases `47-51` shipped `v2.2 OSS adopter onramp` with archived roadmap and requirements ledgers.
- Scoria now has a publishable package/docs lane, a truthful installer contract, a generated-host consumer proof, and a bounded default-lane verifier.
- `v2.3` activates the adoption-example follow-up candidate: one executable runtime-to-handoff path before any broader capability expansion.

**Decisions:**

- `v2.0 Relay` closed the bounded handoff lane with explicit same-run lineage, projected-context safety, and canonical adoption proof.
- `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible middleware.
- Semantic reuse is opt-in through explicit safe read-only lanes, and misses, rejects, and stale entries preserve the normal workflow truth path.
- Operator trust depends on runtime and workflow surfaces projecting semantic evidence from durable runtime metadata and semantic entry/event history.
- The trusted `v2.1` proof lane is `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path`.
- The next milestone should start from OSS adopter readiness, not new runtime capability: package metadata, host-app install truth, and named proof lanes are part of the product surface.
- `mix scoria.install` now needs to be treated as a host-app contract that copies core migrations, wires defaults, and degrades cleanly when optional Tailwind assets are absent.
- Semantic proof lanes must prepare their own optional knowledge or retrieval tables instead of leaking hidden setup assumptions into the support story.
- `v2.2` closed publishability, consumer proof, and support-truth alignment before Scoria reopens broader capability work.
- `v2.3` should clarify lane escalation through one runtime-to-handoff example backed by executable proof, not by broad docs-only guidance.
- No new public runtime API is required for Phase 52.
- The Phase 52 example starts with `Scoria.start_run/2`, escalates through `Scoria.start_handoff_run/3`, and reads delegated detail through `Scoria.get_run_detail/1`.
- The host app owns escalation policy; Scoria owns durable execution, projected-context rejection, and curated readback.
- The Phoenix runtime example now starts a default run before bounded review handoff.
- The host app owns the escalation predicate; Scoria receives only the explicit handoff contract.
- The handoff run is persisted and inspected through `handoff_run.run_id`, not the host `session_id`.
- The bounded handoff guide now states the host/Scoria ownership boundary immediately under the core contract.
- Unsafe projected context is documented as `{:error, :unsafe_projected_context}` before durable delegated run creation.
- The hidden-transcript refutation rejects prescriptive transfer wording without contradicting the required non-copy safety sentence.
- Phase 53 UI design contract is approved in `.planning/phases/53-operator-evidence-and-lane-guidance/53-UI-SPEC.md`; planning should use the delegated evidence anchor, default-lane empty state, curated DTO boundary, and lane wording contract from that file.

**Todos:**

- Plan Phase 53-01.

**Blockers:**

- None. `v2.3` starts from a clean `v2.2` archive with `main` aligned to `origin/main`.

## Deferred Items

Items deferred or intentionally outside active milestone scope:

| Category | Item | Status |
|----------|------|--------|
| tech debt | Project-level full-suite warning audit outside the owned adoption lane still has not been rerun after the post-`v1.9` support-truth shims | still unverified |
| tech debt | LiveView async teardown noise in the workflow/replay test lane | accepted at `v1.9` close |
| future milestone | Advanced bounded-handoff examples beyond the shipped Relay lane | deferred unless real adopter evidence proves the current lane is still confusing |
| active milestone | One runtime-to-handoff adoption example | active in `v2.3` |
| future milestone | External semantic cache backends and advanced tuning | deferred until the embedded default semantic lane and default OSS onramp both prove boring in practice |
| future milestone | Package-family decomposition into multiple Hex libraries | deferred beyond the first OSS adopter closeout |
| future milestone | Hosted demo or managed onboarding surfaces | deferred to preserve the embedded Phoenix product shape |
| tech debt | `mix scoria.release_preview` still warns that `README.md` references `LICENSE` and `Scoria.Knowledge.Source.t()` is undefined/private in generated docs | accepted at `v2.2` close |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work |
