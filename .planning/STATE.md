---
gsd_state_version: 1.0
milestone: v2.5
milestone_name: Scope
status: executing
last_updated: "2026-05-27T16:57:27.270Z"
last_activity: 2026-05-27
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 14
  completed_plans: 14
  percent: 86
---

# Project State

## Project Reference

**Name:** Scoria
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Current Focus:** Phase 64 — adoption-lane-discoverability-sync

## Current Position

Phase: 65
Plan: Not started
Status: Executing Phase 64
Last activity: 2026-05-27

## Performance Metrics

- **Latest Shipped Milestone:** `v2.4 Adoption Reliability Contract` on 2026-05-27
- **Archived Milestone Artifacts:** roadmap, requirements, audit, and phase directories archived under `.planning/milestones/`
- **Milestone Scope Shipped (v2.4):** 4 phases, 6 plans, 10 requirements
- **Coverage (v2.4):** 10/10 milestone requirements satisfied (per `.planning/milestones/v2.4-MILESTONE-AUDIT.md`)
- **Active Milestone:** `v2.5 Installer Safety & Upgrade Confidence` (6 requirements, 5 phases including 2 gap-closure phases)

## Accumulated Context

### Roadmap Evolution

- Milestone `v2.5 Installer Safety & Upgrade Confidence` is initialized with requirements `INST-03` through `INST-08` mapped to phases 59-61.
- Phase 59 starts the no-write planner/check contract; phase 60 adds manifest-aware drift + safe apply; phase 61 closes proof and guardrail stability.
- `WARN-03` remains intentionally deferred as the immediate next milestone once installer safety closes.
- Phase `43.1` was inserted after Phase `43` to restore a clean `v2.0 Relay` closeout baseline.
- Phases `44-46` shipped `v2.1 Tenant-scoped semantic fast path` with archived roadmap and requirements ledgers.
- Phases `47-51` shipped `v2.2 OSS adopter onramp` with archived roadmap and requirements ledgers.
- Scoria now has a publishable package/docs lane, a truthful installer contract, a generated-host consumer proof, and a bounded default-lane verifier.
- `v2.3` shipped the adoption-example lane: default runtime -> bounded handoff with executable proof and support-truth alignment.
- Milestone-next-step assessment places Scoria in a "strong but meaningful wedges remain" band; remaining leverage is adoption safety/upgrade trust, not net-new capability breadth.

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
- Next milestone should be `Installer Safety & Upgrade Confidence` (`INST-03`, `INST-04`) before `WARN-03`; highest leverage is reducing host-app mutation surprise and upgrade drift risk.
- `WARN-03` remains queued next (immediately after installer safety), not a replacement for installer safety work.
- README/support wording has one notable drift risk ("shipped through v2.1" wording) that should be corrected in the upcoming docs-truth pass.
- Phase 62 Plan 01 reconciled Nyquist ledgers for phases 59 and 61 from existing VERIFICATION evidence — no redundant tests added.
- Phase 62 Plan 02 added `requirements-completed` frontmatter to all phase 60–61 SUMMARY files (INST-06/07 and INST-08) aligned to VERIFICATION evidence.
- Phase 62 Plan 03 closed REQUIREMENTS gap row, set v2.5 audit Nyquist to compliant, and recorded `62-VERIFICATION.md` passed evidence.
- No active `.planning/phases/*` tree currently exists; new lessons are parked in `.planning/threads/` and should graduate into `NN-LEARNINGS.md` once the next phase starts.
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

- Run `/gsd-plan-phase 63` for manifest check fingerprint hardening (optional before v2.5 archive).
- Run `/gsd-complete-milestone` when ready to archive v2.5.
- Keep `WARN-03` queued as the first follow-up milestone after v2.5 gap closure completes.
- Preserve lane-contract, CI-order, and canonical closeout command contracts as non-negotiable constraints during v2.5 work.

**Blockers:**

- Warning baseline expiry for full-suite warning debt is near-term (`2026-06-07`) and should be handled promptly in the warning-ratchet follow-up milestone.
- Installer currently has no shipped planner/check + manifest drift contract; upgrade mutation risk remains until phases 59-61 land.

## Active Threads

- `.planning/threads/2026-05-27-installer-safety-upgrade-confidence.md` — primary open investigation for next milestone requirements and proof shape.
- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — queued-next warning-ratchet scope and baseline-expiry enforcement track.
- `.planning/threads/2026-05-27-milestone-assessment-learnings.md` — lessons + graduation candidates to promote into next phase `NN-LEARNINGS.md`.

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

- Start execution with `/gsd-discuss-phase 59`.
