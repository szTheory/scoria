---
phase: 43-knowledge-tenant-isolation
plan: 05
subsystem: knowledge
tags: [knowledge, tenant-isolation, citations, grounding, docs]

requires:
  - phase: 43-04
    provides: Tenant-qualified retrieval leaves
provides:
  - Knowledge.create_citation/2 validates anchors under normalized tenant scope before insert
  - CitationFormatter.validate_anchor/2 reloads source and chunk visibility under tenant-qualified constraints
  - Grounding citation validity passes scope into citation anchor validation and fails closed without tenant scope
  - Optional knowledge docs describe host-supplied tenant/actor identity, citation isolation, and the full proof lane
affects: [knowledge, citations, grounding, docs]

tech-stack:
  added: []
  patterns: [Scoped citation validation, fail-closed grounding validity, tenant evidence on persisted citations]

key-files:
  created:
    - .planning/phases/43-knowledge-tenant-isolation/43-05-SUMMARY.md
  modified:
    - lib/scoria/knowledge.ex
    - lib/scoria/knowledge/citation_formatter.ex
    - lib/scoria/knowledge/grounding.ex
    - test/scoria/knowledge/citation_formatter_test.exs
    - test/scoria/knowledge/grounding_test.exs
    - test/scoria/knowledge/tenant_isolation_test.exs
    - README.md
    - docs/adoption_lanes.md
    - docs/operator_verification.md
    - .planning/phases/43-knowledge-tenant-isolation/43-05-PLAN.md

key-decisions:
  - "Citation anchors are treated as untrusted evidence until source and chunk rows are reloaded through Scope.visible_to/2."
  - "Citation creation derives persisted tenant_id, actor_id, and scope_kind from normalized scope rather than caller-supplied citation attributes."
  - "Grounding citation validity preserves the existing failed-score shape for missing scope while preventing unscoped anchor reads."
  - "Docs describe metadata filters as narrowing inside an already tenant-scoped lane, not as the security boundary."

patterns-established:
  - "Quote evidence follows the same tenant boundary as retrieval chunks and retrieval results."
  - "Knowledge-lane verification requires --include knowledge or mix test.knowledge because default test selection excludes :knowledge tests."
  - "Plan key-link metadata should use literal-compatible anchors instead of escaped regex strings."

requirements-completed: [KNOW-01, KNOW-02, KNOW-03, KNOW-04]

duration: 12min
completed: 2026-07-07
status: complete
---

# Phase 43-05: Citation, Grounding, and Proof Summary

**Citation quote paths and grounding citation validity now require tenant scope, persist citation audit evidence, and are covered by the full optional knowledge proof lane.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-07T12:17:16Z
- **Completed:** 2026-07-07T12:28:06Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added scoped `Knowledge.create_citation/2` behavior that validates anchors before insert and stamps citation rows with `tenant_id`, `actor_id`, and `scope_kind`.
- Updated `CitationFormatter.validate_anchor/2` to require scope and requalify both source and chunk visibility before trusting quote evidence.
- Rejected wrong-tenant, legacy null-tenant, wrong-source, wrong-digest, and invalid-offset anchors without exposing them as valid citations.
- Routed `Knowledge.score_grounding/2` and `Grounding.score_citation_validity/2` through scoped citation validation.
- Documented the optional knowledge tenant contract, including host-supplied tenant/actor identity, fail-closed missing tenant behavior, metadata filter limits, and the dedicated knowledge migration path.
- Re-ran the full knowledge lane successfully after 43-05 closed the citation and grounding failures deferred from 43-04.

## Task Commits

1. **Task 1 RED: Citation scope tests** - `5aa8b095`
2. **Task 1 GREEN: Scope citation validation and audit** - `d9be2953`
3. **Task 2 RED: Grounding scope tests** - `60a14f60`
4. **Task 2 GREEN: Route grounding through scoped citations** - `dcc14b93`
5. **Task 3 GREEN: Document knowledge tenant proof** - `84738a4f`

**Plan metadata:** included in final docs/tracking commit.

## Files Created/Modified

- `lib/scoria/knowledge.ex` - Adds scoped citation creation and passes grounding opts into citation validity scoring.
- `lib/scoria/knowledge/citation_formatter.ex` - Requires scope for anchor validation and reloads source/chunk under tenant-qualified visibility.
- `lib/scoria/knowledge/grounding.ex` - Accepts scope for citation validity and fails closed when scope is absent.
- `test/scoria/knowledge/citation_formatter_test.exs` - Covers scoped citation formatter behavior.
- `test/scoria/knowledge/grounding_test.exs` - Covers scoped grounding citation validity.
- `test/scoria/knowledge/tenant_isolation_test.exs` - Adds end-to-end citation isolation and audit evidence checks.
- `README.md` - Notes tenant-scoped retrieval/citations and missing-tenant fail-closed behavior.
- `docs/adoption_lanes.md` - Documents host identity ownership and metadata filter limits.
- `docs/operator_verification.md` - Documents the knowledge-lane proof and migration path.
- `.planning/phases/43-knowledge-tenant-isolation/43-05-PLAN.md` - Key-link patterns made verifier-compatible.
- `.planning/phases/43-knowledge-tenant-isolation/43-05-SUMMARY.md` - Plan closeout summary.

## Decisions Made

Citation creation validates anchors first and then applies scope-derived audit fields to the inserted row. This prevents callers from spoofing tenant evidence on citation records and keeps citation quotes protected by the same boundary as raw chunks, retrieval results, and retrieval leaves.

Grounding citation validity returns the existing failed score shape when scope is absent, instead of raising through the scorer path. That preserves public scoring conventions while ensuring no unscoped citation validation runs.

## Deviations from Plan

### Auto-fixed Issues

**1. Key-link pattern compatibility**
- **Found during:** Plan verification
- **Issue:** The verifier rejected regex-style escaped patterns such as `validate_anchor\\(.*scope` and searched for escaped `mix test\\.knowledge` literally.
- **Fix:** Changed plan metadata patterns to verifier-compatible source anchors.
- **Files modified:** `.planning/phases/43-knowledge-tenant-isolation/43-05-PLAN.md`
- **Verification:** `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-05-PLAN.md` passed 3/3.
- **Committed in:** final docs/tracking commit.

---

**Total deviations:** 1 metadata auto-fix
**Impact on plan:** No product behavior change; verifier now recognizes the implemented citation, grounding, and docs links.

## Issues Encountered

The project excludes `:knowledge` tests by default, so the exact plan commands compile the target files while excluding the tenant assertions. Behavior proof must use `--include knowledge` for focused files or `mix test.knowledge --warnings-as-errors` for the full optional lane.

## Verification

- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/citation_formatter_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 23 tests, 0 failures.
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/grounding_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 22 tests, 0 failures.
- `MIX_ENV=test mix test.knowledge --warnings-as-errors` - 46 tests, 0 failures, 990 excluded.
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/citation_formatter_test.exs test/scoria/knowledge/grounding_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 26 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/knowledge/citation_formatter_test.exs test/scoria/knowledge/grounding_test.exs test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` - 0 tests, 0 failures, 26 excluded.
- `rg -n "tenant-scoped|missing tenant|metadata filters|KnowledgeMigrationRepo|schema_migrations_knowledge|priv/repo/knowledge_migrations|mix test\\.knowledge --warnings-as-errors|actor-scoped|cross-tenant" README.md docs/adoption_lanes.md docs/operator_verification.md` - required docs proof strings found.
- `gsd-tools query verify.key-links .planning/phases/43-knowledge-tenant-isolation/43-05-PLAN.md` - 3/3 links verified.

## User Setup Required

None - no external service configuration required.

## Phase Readiness

Phase 43 is ready for final build verification. Storage, public APIs, retrieval leaves, citations, grounding citation validity, and operator docs now share the same tenant-scope contract, and the full optional knowledge lane passes under `mix test.knowledge --warnings-as-errors`.

---
*Phase: 43-knowledge-tenant-isolation*
*Completed: 2026-07-07*
