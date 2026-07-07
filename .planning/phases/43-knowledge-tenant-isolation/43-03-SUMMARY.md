---
phase: 43-knowledge-tenant-isolation
plan: 03
subsystem: knowledge
tags: [knowledge, tenant-isolation, retrieval, audit, ecto]

requires:
  - phase: 43-02
    provides: Knowledge tenant/audit schema columns and scope-bearing changesets
provides:
  - Public Knowledge source/chunk APIs require tenant scope before side effects
  - Retrieval runs persist normalized tenant/actor audit evidence
  - Retrieval results validate chunk/source ownership and derive tenant/actor from the run
  - Poisoned mixed result payloads fail atomically without partial inserts
affects: [43-04, 43-05, knowledge, retrieval]

tech-stack:
  added: []
  patterns: [Scope normalization at public API boundaries, tenant-qualified result validation before persistence]

key-files:
  created:
    - .planning/phases/43-knowledge-tenant-isolation/43-03-SUMMARY.md
  modified:
    - lib/scoria/knowledge.ex
    - test/scoria/knowledge_test.exs
    - test/scoria/knowledge/retrieval_test.exs
    - test/scoria/runtime/semantic_fast_path_test.exs
    - test/scoria/semantic_cache/invalidation_test.exs
    - test/scoria/knowledge/tenant_isolation_test.exs
    - .planning/phases/43-knowledge-tenant-isolation/43-03-PLAN.md

key-decisions:
  - "Result payload tenant/actor fields are untrusted; append_retrieval_results/2 derives them from the persisted retrieval run."
  - "Retrieval result validation reloads source and chunk visibility under the run tenant before inserting any rows."
  - "A verifier-incompatible regex-style key-link pattern was replaced with a literal source anchor in the plan metadata."

patterns-established:
  - "Public Knowledge writes call Scope.for_write!/1 before Repo, chunker, embedder, backend, or delete side effects."
  - "Public Knowledge reads and retrieval calls call Scope.from_opts!/1 before database or backend work."
  - "Ecto.Multi wraps retrieval result validation plus inserts so mixed poisoned sets roll back atomically."

requirements-completed: [KNOW-02, KNOW-03, KNOW-04]

duration: 20min
completed: 2026-07-07
status: complete
---

# Phase 43-03: Public Knowledge API Scope Enforcement Summary

**Knowledge source/list/retrieval boundaries now fail closed on missing tenant scope and persist tenant audit evidence without trusting result payloads.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-07T11:47:00Z
- **Completed:** 2026-07-07T12:07:10Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added scoped `create_source/2`, `ingest_source/2`, `reembed_source/2`, `reindex_source/2`, and `list_source_chunks/2` behavior.
- Added retrieval run audit persistence from normalized scope.
- Added tenant-qualified source/chunk validation before retrieval result insertion.
- Added regression coverage for unscoped public APIs, chunk scope inheritance, null/other-tenant exclusion, run/result audit fields, and poisoned result rejection.

## Task Commits

1. **Task 1 RED: Public source/chunk scope tests** - `345ade33`
2. **Task 1 GREEN: Source/chunk API enforcement** - `26904c46`
3. **Task 2 RED: Retrieval scope/audit tests** - `6ad8ed7c`
4. **Task 2 GREEN: Retrieval scope persistence and poisoned result rejection** - `a43d4d4f`

**Plan metadata:** pending in final docs/tracking commit.

## Files Created/Modified

- `lib/scoria/knowledge.ex` - Normalizes scope at public source/chunk/retrieval boundaries and validates retrieval result ownership.
- `test/scoria/knowledge/tenant_isolation_test.exs` - Tenant isolation spine for source/chunk APIs, migration/schema checks, run/result audit, and poisoned results.
- `test/scoria/knowledge/retrieval_test.exs` - Scoped retrieval integration coverage with run/result audit assertions.
- `test/scoria/knowledge_test.exs` - Existing knowledge API tests now pass deterministic tenant scope.
- `test/scoria/runtime/semantic_fast_path_test.exs` - Retrieval fixture rows carry deterministic scope.
- `test/scoria/semantic_cache/invalidation_test.exs` - Retrieval fixture rows carry deterministic scope.
- `.planning/phases/43-knowledge-tenant-isolation/43-03-PLAN.md` - Key-link pattern made verifier-compatible.

## Decisions Made

Retrieval result payloads are treated as untrusted. Even if the caller supplies `tenant_id` or `actor_id`, `append_retrieval_results/2` reloads the run and stamps results with the run tenant/actor after validating the source and chunk are visible under that run scope.

## Deviations from Plan

### Auto-fixed Issues

**1. Key-link pattern compatibility**
- **Found during:** Plan verification
- **Issue:** The GSD key-link verifier received the regex-style `Scope\\.(from_opts!|for_write!)` pattern with the backslash doubled and searched for `Scope\\.`.
- **Fix:** Changed the plan metadata pattern to the literal source anchor `Scope.from_opts!`.
- **Files modified:** `.planning/phases/43-knowledge-tenant-isolation/43-03-PLAN.md`
- **Verification:** `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-03-PLAN.md` passed 2/2.
- **Committed in:** final docs/tracking commit.

---

**Total deviations:** 1 metadata auto-fix
**Impact on plan:** No product behavior change; verifier now recognizes the implemented scope-helper link.

## Issues Encountered

The project excludes `:knowledge` tests by default, so the exact plan command compiles the knowledge files while excluding tenant-lane assertions. The actual behavior proof was run with `--include knowledge`.

## Verification

- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/retrieval_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 17 tests, 0 failures.
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge_test.exs test/scoria/knowledge/retrieval_test.exs test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 35 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/knowledge_test.exs test/scoria/knowledge/retrieval_test.exs test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 13 tests, 0 failures, 22 excluded.
- `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-03-PLAN.md` - 2/2 links verified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 43-04 can now tenant-qualify Pgvector and Scrypath retrieval paths. Public `Knowledge.retrieve/2` requires scope and persists run/result audit evidence, while result persistence rejects backend or custom retriever payloads that point outside the run tenant.

---
*Phase: 43-knowledge-tenant-isolation*
*Completed: 2026-07-07*
