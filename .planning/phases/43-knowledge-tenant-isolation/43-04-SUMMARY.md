---
phase: 43-knowledge-tenant-isolation
plan: 04
subsystem: knowledge
tags: [knowledge, tenant-isolation, retrieval, pgvector, scrypath]

requires:
  - phase: 43-03
    provides: Public Knowledge API scope enforcement and retrieval result validation
provides:
  - Knowledge.retrieve/2 passes normalized tenant scope into backend and retriever leaves
  - Pgvector.similar_chunks/2 requires scope and filters tenant visibility before source filters or ranking
  - Scrypath.retrieve/2 and normalize_results/2 require scope and resolve chunks through tenant-qualified lookups
  - Cross-tenant retrieval excludes closer foreign-tenant chunks before ranking
affects: [43-05, knowledge, retrieval, citations, grounding]

tech-stack:
  added: []
  patterns: [Scope normalization at backend leaves, tenant visibility before ranking, durable locator requalification]

key-files:
  created:
    - .planning/phases/43-knowledge-tenant-isolation/43-04-SUMMARY.md
  modified:
    - lib/scoria/knowledge.ex
    - lib/scoria/knowledge/backends/pgvector.ex
    - lib/scoria/knowledge/retrievers/scrypath.ex
    - test/scoria/knowledge/retrieval_test.exs
    - test/scoria/knowledge/pgvector_test.exs
    - test/scoria/knowledge/scrypath_test.exs
    - test/scoria/knowledge/tenant_isolation_test.exs
    - .planning/phases/43-knowledge-tenant-isolation/43-04-PLAN.md

key-decisions:
  - "Retrieval scope is propagated into backend/retriever leaves rather than trusted only at the public facade."
  - "Pgvector applies Scope.visible_to/2 before source_id filters, cosine ordering, and limit."
  - "Scrypath durable locators are requalified by visible source plus visible chunk before normalization."
  - "Verifier-incompatible regex-style key-link patterns were replaced with literal-compatible anchors in plan metadata."

patterns-established:
  - "Backend leaves call Scope.from_opts!/1 independently so direct backend use fails closed."
  - "External retriever payloads remain untrusted until chunk/source visibility is reloaded under caller scope."
  - "Plan verification must run knowledge-tagged tests with --include knowledge because the default suite excludes them."

requirements-completed: [KNOW-03, KNOW-04]

duration: 10min
completed: 2026-07-07
status: complete
---

# Phase 43-04: Retrieval Leaves Scope Enforcement Summary

**Pgvector and Scrypath retrieval leaves now fail closed on missing tenant scope and cannot return foreign-tenant chunks through direct backend or retriever paths.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-07T12:08:00Z
- **Completed:** 2026-07-07T12:17:16Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Passed normalized scope from `Knowledge.retrieve/2` into both backend and retriever calls.
- Required scope inside `Pgvector.similar_chunks/2` and applied tenant/actor visibility before source filters and vector ordering.
- Required scope inside `Scrypath.retrieve/2` and `normalize_results/2`.
- Replaced Scrypath global chunk lookup with visible source plus visible chunk lookup for chunk id and durable locator hits.
- Added regression coverage for missing-tenant raises, actor visibility, source-filter narrowing within tenant, closer foreign-tenant vector exclusion, and foreign Scrypath locator rejection.

## Task Commits

1. **Task 1 RED: Retrieve scope propagation tests** - `cc547dd5`
2. **Task 1 GREEN: Pass scope into knowledge backends** - `d1448ff6`
3. **Task 2 RED: Pgvector tenant filter tests** - `4a5c660f`
4. **Task 2 GREEN: Tenant-filter Pgvector retrieval** - `1d008a7e`
5. **Task 3 RED: Scrypath scope tests** - `5bf32351`
6. **Task 3 GREEN: Tenant-qualify Scrypath normalization** - `55d16f8d`

**Plan metadata:** pending in final docs/tracking commit.

## Files Created/Modified

- `lib/scoria/knowledge.ex` - Passes normalized scope into backend `similar_chunks/2`.
- `lib/scoria/knowledge/backends/pgvector.ex` - Requires scope and scopes the chunk query before filters and ranking.
- `lib/scoria/knowledge/retrievers/scrypath.ex` - Requires scope and resolves result hits through tenant-qualified source/chunk lookups.
- `test/scoria/knowledge/retrieval_test.exs` - Scope propagation tests for backend and retriever doubles.
- `test/scoria/knowledge/pgvector_test.exs` - Direct backend fail-closed, source filter, actor visibility, and ranking isolation tests.
- `test/scoria/knowledge/scrypath_test.exs` - Scoped normalization and foreign locator rejection tests.
- `test/scoria/knowledge/tenant_isolation_test.exs` - End-to-end retrieval proof that closer tenant B chunks are excluded.
- `.planning/phases/43-knowledge-tenant-isolation/43-04-PLAN.md` - Key-link patterns made verifier-compatible.

## Decisions Made

Backend and retriever leaves do not rely on callers having already enforced scope. They normalize their own scope and treat external result payloads as untrusted locators that must be reloaded under the caller's visible source and chunk scope.

## Deviations from Plan

### Auto-fixed Issues

**1. Key-link pattern compatibility**
- **Found during:** Plan verification
- **Issue:** The verifier rejected regex-style escaped patterns such as `similar_chunks\\(.*scope` and searched for escaped `Scope\\.` literally.
- **Fix:** Changed plan metadata patterns to verifier-compatible source anchors.
- **Files modified:** `.planning/phases/43-knowledge-tenant-isolation/43-04-PLAN.md`
- **Verification:** `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-04-PLAN.md` passed 3/3.
- **Committed in:** final docs/tracking commit.

---

**Total deviations:** 1 metadata auto-fix
**Impact on plan:** No product behavior change; verifier now recognizes the implemented retrieval-leaf links.

## Issues Encountered

The project excludes `:knowledge` tests by default, so the exact plan command compiles the files while excluding the tenant assertions. The actual behavior proof was run with `--include knowledge`.

`MIX_ENV=test mix test.knowledge --warnings-as-errors` now reaches the next plan's citation/grounding fixtures and fails three tests that still call `Knowledge.ingest_source/1` without scope:

- `test/scoria/knowledge/grounding_test.exs:6`
- `test/scoria/knowledge/citation_formatter_test.exs:7`
- `test/scoria/knowledge/citation_formatter_test.exs:21`

These failures are expected to be handled by 43-05, which owns citation/grounding scope and full knowledge proof.

## Verification

- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/scrypath_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 22 tests, 0 failures.
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/retrieval_test.exs test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/scrypath_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 32 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/knowledge/retrieval_test.exs test/scoria/knowledge/pgvector_test.exs test/scoria/knowledge/scrypath_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 0 tests, 0 failures, 32 excluded.
- `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-04-PLAN.md` - 3/3 links verified.
- `MIX_ENV=test mix test.knowledge --warnings-as-errors` - 40 tests, 3 failures, 990 excluded; failures deferred to 43-05 citation/grounding scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 43-05 can now scope citation and grounding paths on top of tenant-filtered retrieval leaves. Retrieval no longer leaks foreign-tenant chunks through Pgvector ranking or Scrypath normalization, and remaining knowledge-lane failures are confined to citation/grounding fixtures owned by the next plan.

---
*Phase: 43-knowledge-tenant-isolation*
*Completed: 2026-07-07*
