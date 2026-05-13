---
phase: 10
plan: 03
subsystem: bootstrap
tags: [sre, pgvector, migrations, test-bootstrap, knowledge]
requires:
  - phase: 07-04
    provides: SRE schema and the prior bootstrap blocker this slice removes
provides:
  - boring default core/SRE test bootstrap without pgvector
  - explicit knowledge/full verification lane behind a pgvector gate
  - migration-history compatibility for knowledge version 20260511000300
affects: [10-04, 11]
tech-stack:
  added: []
  patterns: [split migration lanes, explicit optional infra, compatibility-first bootstrap]
key-files:
  created: [priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs, lib/mix/tasks/scoria.test.knowledge.ex, test/scoria/bootstrap/migration_lane_compatibility_test.exs]
  modified: [mix.exs, test/test_helper.exs, test/support/knowledge_case.exs, lib/mix/tasks/scoria.pgvector.bootstrap.ex, priv/repo/migrations/20260511000300_create_knowledge_tables.exs]
decisions:
  - "Kept migration version 20260511000300 intact by moving the real knowledge migration into a dedicated knowledge lane and leaving a no-op compatibility migration in the core lane."
  - "Made ordinary test bootstrap run only core migrations, while the explicit knowledge lane reuses the pgvector bootstrap gate and runs its own migration source."
  - "Kept knowledge opt-in at both test discovery and runtime bootstrap boundaries so unrelated SRE verification never touches pgvector."
metrics:
  duration: 16min
  completed: 2026-05-12
  tasks: 2
  files_modified: 8
---

# Phase 10 Plan 03: Migration Lane Bootstrap Summary

**Core/SRE tests now bootstrap through a plain Postgres lane, while pgvector-backed knowledge stays explicit and compatible with the historical `20260511000300` migration version.**

## Performance

- **Duration:** 16 min
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- The default test bootstrap now migrates only the core path, so `mix test` and focused SRE suites no longer depend on pgvector being installed.
- Knowledge migration version `20260511000300` remains historically compatible by staying recorded in the core lane while the real vector-backed migration lives in `priv/repo/knowledge_migrations/`.
- The explicit knowledge/full lane remains first-class through `mix test.knowledge`, which enables knowledge-tagged tests, checks pgvector availability, and runs the knowledge migration source separately.
- Regression coverage proves two safety cases: fresh core-only environments reach later SRE schema safely, and already-migrated knowledge environments can rerun the explicit lane idempotently.

## Verification

- `MIX_ENV=test mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs --trace`
- `MIX_ENV=test mix test test/scoria/sre_test.exs --trace`

## Task Commits

1. **Task 1: Split the Core and Knowledge Bootstrap Paths at the Migration Boundary** - `64b4a28` (feat)
2. **Task 2: Make the Default Test Bootstrap Boring and Keep Knowledge Opt-In** - `64b4a28` (feat)

## Decisions Made

- Preserved migration compatibility by treating the core-lane `20260511000300` file as a no-op sentinel instead of renumbering or deleting it.
- Used a separate migration source for knowledge so already-migrated environments can rerun the explicit lane without corrupting `schema_migrations`.
- Kept `KnowledgeCase` as the opt-in pgvector seam and did not leak knowledge bootstrap into the default helper path.

## Deviations from Plan

None in product behavior. The implementation for this slice was already present in commit `64b4a28`, so this execution pass verified the lane split and recorded the plan summary instead of reapplying code changes.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-03-SUMMARY.md`
- Verified commit `64b4a28` exists in git history
