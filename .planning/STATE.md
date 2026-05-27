---
gsd_state_version: 1.0
milestone: planning-next
milestone_name: pending
status: v2.4 archived and tagged-ready
last_updated: "2026-05-27T09:59:00.000Z"
last_activity: 2026-05-27 — Completed v2.4 archival backfill and finalized milestone closeout records
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 6
  completed_plans: 6
  percent: 100
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Define next milestone requirements via `/gsd-new-milestone`

## Current Position

Phase: Milestone v2.4 complete and archived
Plan: —
Status: Ready for next milestone definition
Last activity: 2026-05-27 — Completed v2.4 archival backfill and finalized milestone closeout records

## Performance Metrics

- **Latest Shipped Milestone:** `v2.4 Adoption Reliability Contract` on 2026-05-27
- **Archived Milestone Artifacts:** roadmap, requirements, audit, and phase directories archived under `.planning/milestones/`
- **Milestone Scope Shipped:** 4 phases, 6 plans, 10 requirements
- **Coverage:** 10/10 milestone requirements satisfied (per `.planning/milestones/v2.4-MILESTONE-AUDIT.md`)
- **Active Milestone:** none (next milestone definition pending)

## Accumulated Context

### Roadmap Evolution

- Phase `43.1` was inserted after Phase `43` to restore a clean `v2.0 Relay` closeout baseline.
- Phases `44-46` shipped `v2.1 Tenant-scoped semantic fast path` with archived roadmap and requirements ledgers.
- Phases `47-51` shipped `v2.2 OSS adopter onramp` with archived roadmap and requirements ledgers.
- Scoria now has a publishable package/docs lane, a truthful installer contract, a generated-host consumer proof, and a bounded default-lane verifier.
- `v2.3` shipped the adoption-example lane: default runtime -> bounded handoff with executable proof and support-truth alignment.

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
- `v2.4` should prioritize one executable reliability contract across lane docs, tests, CI, warnings, and installer behavior before reopening capability expansion.
- Next milestone should preserve v2.4 reliability contracts while scoping one focused expansion axis.
- No new public runtime API is required for Phase 52.
- The Phase 52 example starts with `Scoria.start_run/2`, escalates through `Scoria.start_handoff_run/3`, and reads delegated detail through `Scoria.get_run_detail/1`.
- The host app owns escalation policy; Scoria owns durable execution, projected-context rejection, and curated readback.
- The Phoenix runtime example now starts a default run before bounded review handoff.
- The host app owns the escalation predicate; Scoria receives only the explicit handoff contract.
- The handoff run is persisted and inspected through `handoff_run.run_id`, not the host `session_id`.
- The bounded handoff guide now states the host/Scoria ownership boundary immediately under the core contract.
- Unsafe projected context is documented as `{:error, :unsafe_projected_context}` before durable delegated run creation.
- The hidden-transcript refutation rejects prescriptive transfer wording without contradicting the required non-copy safety sentence.
- Phase 53 UI design contract is archived in `.planning/milestones/v2.3-phases/53-operator-evidence-and-lane-guidance/53-UI-SPEC.md` with delegated evidence anchor and default-lane empty-state guidance.

**Todos:**

- Run `/gsd-new-milestone` to define the next requirement set.

**Blockers:**

- None known for the scoped `v2.4` reliability contract.

## Deferred Items

Items deferred or intentionally outside active milestone scope:

| Category | Item | Status | Owner | Expires |
|----------|------|--------|-------|---------|
| tech debt | Project-level full-suite warning audit outside the owned adoption lanes | baseline tracked in `.planning/WARNING-BASELINE.md` | scoria-maintainers | 2026-06-07 |
| tech debt | LiveView async teardown noise in the workflow/replay test lane | accepted at `v1.9` close; tracked baseline | scoria-web-runtime | 2026-06-30 |
| future milestone | Advanced bounded-handoff examples beyond the shipped Relay lane | deferred unless real adopter evidence proves the current lane is still confusing | product-runtime | 2026-07-31 |
| shipped milestone | One runtime-to-handoff adoption example | shipped in `v2.3` | archived | n/a |
| future milestone | External semantic cache backends and advanced tuning | deferred until the embedded default semantic lane and default OSS onramp both prove boring in practice | runtime-architecture | 2026-08-31 |
| future milestone | Package-family decomposition into multiple Hex libraries | deferred beyond the first OSS adopter closeout | package-architecture | 2026-08-31 |
| future milestone | Hosted demo or managed onboarding surfaces | deferred to preserve the embedded Phoenix product shape | product-ops | 2026-09-30 |
| resolved debt | `mix scoria.release_preview` docs warning debt (`README` license reference + `Scoria.Knowledge.Source.t()` type) | resolved during `v2.4` reliability contract implementation | scoria-maintainers | n/a |
| reference | Archived planning seeds in `.planning/seeds/` | retained as background material, not active milestone work | planning | n/a |

## Operator Next Steps

- Start the next milestone with `/gsd-new-milestone`.
