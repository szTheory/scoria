---
phase: 43-knowledge-tenant-isolation
plan: 02
subsystem: knowledge
tags: [knowledge, tenant-isolation, migration, schema, audit-evidence]

# Dependency graph
requires:
  - phase: 43-knowledge-tenant-isolation
    provides: Scoria.Knowledge.Scope normalization and tenant isolation test spine
provides:
  - Additive knowledge tenant-scope migration under priv/repo/knowledge_migrations
  - Tenant/actor/scope fields on knowledge source, chunk, and citation schemas
  - Tenant/actor audit fields on retrieval run and result schemas
affects: [phase-43, knowledge-migrations, knowledge-schemas, retrieval-audit, citation-audit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Nullable migration columns for legacy upgrade compatibility with fail-closed changesets for new writes
    - Tenant-scoped partial source uniqueness for non-null tenant rows
    - Shared @scope_fields schema attribute for source/chunk/citation tenant evidence

key-files:
  created:
    - priv/repo/knowledge_migrations/20260705010000_add_knowledge_tenant_scope.exs
  modified:
    - lib/scoria/knowledge/source.ex
    - lib/scoria/knowledge/chunk.ex
    - lib/scoria/knowledge/retrieval_run.ex
    - lib/scoria/knowledge/retrieval_result.ex
    - lib/scoria/knowledge/citation.ex
    - test/scoria/knowledge/tenant_isolation_test.exs

key-decisions:
  - "Knowledge tenant columns remain nullable in the migration for adopter upgrade compatibility, while schema changesets reject new unscoped writes."
  - "The historical global source entity/version unique index is replaced with a tenant-scoped partial unique index where tenant_id is not null."
  - "Retrieval runs/results persist tenant_id and optional actor_id as first-class audit evidence instead of metadata-only scope proof."

patterns-established:
  - "Knowledge schema scope fields: source/chunk/citation use @scope_fields [:tenant_id, :actor_id, :scope_kind] plus scope_kind inclusion validation."
  - "Audit row scope fields: retrieval run/result require tenant_id and carry actor_id."

requirements-completed: [KNOW-01, KNOW-02, KNOW-03]

# Metrics
duration: 4 min
completed: 2026-07-07
status: complete
---

# Phase 43 Plan 02: Additive Knowledge Tenant Scope Migration Summary

**Tenant-scope storage columns, indexes, and schema validation for knowledge storage and retrieval audit rows**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-07T11:52:07Z
- **Completed:** 2026-07-07T11:55:21Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `20260705010000_add_knowledge_tenant_scope.exs` under the separate knowledge migration path.
- Added nullable `tenant_id`, `actor_id`, and `scope_kind` columns to sources, chunks, and citations, plus nullable `tenant_id`/`actor_id` audit columns to retrieval runs/results.
- Added tenant indexes for storage, retrieval audit, and citation lookup paths.
- Replaced global source entity/version uniqueness with a tenant-scoped partial unique index for non-null tenants.
- Updated five knowledge schemas so new writes require tenant evidence at changeset level while migration columns stay nullable for legacy rows.
- Extended `tenant_isolation_test.exs` with migration, index, schema-field, and changeset validation proof.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing knowledge tenant migration proof** - `f7cfe89f` (test)
2. **Task 1 GREEN: Add knowledge tenant scope migration** - `cee298a3` (feat)
3. **Task 2 RED: Add failing knowledge schema scope tests** - `9d1bdc7b` (test)
4. **Task 2 GREEN: Add knowledge tenant scope schema fields** - `671315aa` (feat)
5. **Task 2 refactor: Make shared scope fields explicit for key-link proof** - `969630be` (refactor)

_Note: Both tasks were TDD and produced RED then GREEN commits._

## Files Created/Modified

- `priv/repo/knowledge_migrations/20260705010000_add_knowledge_tenant_scope.exs` - Additive tenant-scope migration and rollback.
- `lib/scoria/knowledge/source.ex` - Source tenant/actor/scope fields and new-write validation.
- `lib/scoria/knowledge/chunk.ex` - Chunk tenant/actor/scope fields and new-write validation.
- `lib/scoria/knowledge/retrieval_run.ex` - Retrieval run tenant/actor audit fields and tenant validation.
- `lib/scoria/knowledge/retrieval_result.ex` - Retrieval result tenant/actor audit fields and tenant validation.
- `lib/scoria/knowledge/citation.ex` - Citation tenant/actor/scope fields and new-write validation.
- `test/scoria/knowledge/tenant_isolation_test.exs` - Migration/index/schema/changeset tenant-scope proof.

## Decisions Made

- Kept upgrade columns nullable, matching D-02, because existing adopter rows cannot be assigned a synthetic tenant safely.
- Dropped the old global `[:entity_id, :version]` uniqueness in favor of `[:tenant_id, :entity_id, :version] where tenant_id IS NOT NULL`, allowing the same logical source version in different tenants.
- Left actor-required-for-actor-scoped enforcement in `Scoria.Knowledge.Scope.for_write!/1`; schemas require only tenant and scope kind where appropriate.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The key-link verifier expected the literal `tenant_id.*scope_kind` pattern in source/chunk schema files. A small `@scope_fields [:tenant_id, :actor_id, :scope_kind]` refactor made the shared field contract explicit and verifiable.

## Known Stubs

None.

## Verification

- `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` — PASS (compiled cleanly; 10 knowledge tests excluded by default project filter)
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` — PASS (10 tests, 0 failures)
- `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-02-PLAN.md` — PASS (2/2 links)

## TDD Gate Compliance

- RED gate present: `f7cfe89f` before `cee298a3` for the migration/index proof.
- GREEN gate present: `cee298a3` after the failing migration/index tests.
- RED gate present: `9d1bdc7b` before `671315aa` for schema field/changeset validation.
- GREEN gate present: `671315aa` after the failing schema tests.
- Refactor gate present: `969630be` kept tests green and made key-link proof explicit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `43-03-PLAN.md` to populate the new tenant/actor/scope fields through public Knowledge API write/list/run/result boundaries.

## Self-Check: PASSED

- Verified created file exists: `priv/repo/knowledge_migrations/20260705010000_add_knowledge_tenant_scope.exs`.
- Verified task commits exist: `f7cfe89f`, `cee298a3`, `9d1bdc7b`, `671315aa`, and `969630be`.
- Verified migration columns remain nullable while changesets reject new unscoped writes.
- Verified key links pass for the knowledge migration path and source/chunk shared scope fields.

---
*Phase: 43-knowledge-tenant-isolation*
*Completed: 2026-07-07*
