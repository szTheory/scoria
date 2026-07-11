---
phase: 50-release-readiness-and-0-1-3-cut
plan: 01
subsystem: testing
tags: [ci, docs-contract, hex-release, maintainers-guide, release-please, elixir]

# Dependency graph
requires:
  - phase: 48-docs-and-guide-ladder
    provides: "guides/maintainers.md as the canonical maintainer guide; docs/*.md reduced to compatibility stubs"
provides:
  - "CiPolicyContractTest docs-contract constants repointed to canonical guides/maintainers.md"
  - "Restored maintainer content in guides/maintainers.md (Hex release & recovery secrets, CI gate map topology, Version namespaces, PR vs release proof depth)"
  - "Green verify/policy CI lane for REL-01 (unblocks PR #12 toward ci-gate)"
affects: [50-02, 50-03, 50-04, release-readiness, ci-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Docs-contract literal-string assertions read canonical guides/ source, never docs/*.md compatibility stubs (D-16)"

key-files:
  created: []
  modified:
    - test/scoria/ci_policy_contract_test.exs
    - guides/maintainers.md

key-decisions:
  - "Both @maintainer_docs and @operator_docs point at guides/maintainers.md (not split to guides/reviewer-verification.md): WARN-06 ratchet commands and the Hex-release section are maintainer-only content Phase 48 consolidated there (D-16, RESEARCH A2)."
  - "Restored the dropped maintainer content in the guide's current numbered-list/table voice rather than pasting pre-Phase-48 docs/MAINTAINERS.md verbatim (D-17/D-19/D-20)."
  - "Used an ExDoc IAL heading anchor ({: #hex-release--recovery-maintainers}) so the '## Hex release & recovery' heading carries a real linkable anchor matching the workflow-comment reference."

patterns-established:
  - "Pattern 1: repoint-path + restore-content — fix drifted docs-contract tests by pointing constants at canonical source and restoring genuinely-dropped content, never by weakening assertions."

requirements-completed: [REL-01]

coverage:
  - id: D1
    description: "CiPolicyContractTest docs-contract constants read canonical guides/maintainers.md; no docs/*.md canonical references remain; v2.15 Connector Adoption Lane breadcrumb test still passes."
    requirement: "REL-01"
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Restored maintainer content in guides/maintainers.md (Hex release & recovery secrets + anchor, CI gate map topology/parity/diagnosis, Version namespaces, PR vs release proof depth) satisfies every repointed assertion without regressing the wider adopter/adoption lanes."
    requirement: "REL-01"
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 01: Repair REL-01 docs-contract drift Summary

**Repointed CiPolicyContractTest docs constants to canonical `guides/maintainers.md` and restored the genuinely-dropped maintainer content (Hex release secrets, CI gate map topology, Version namespaces, PR-vs-release proof depth), turning the 7 red policy-lane tests green without weakening a single assertion.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-07-11T02:33Z
- **Completed:** 2026-07-11T02:41Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Repointed `@maintainer_docs` and `@operator_docs` to `guides/maintainers.md` and fixed the two stale README-link assertions (`docs/MAINTAINERS.md` → `guides/maintainers.md`) — 0 `docs/*.md` canonical references remain in the test.
- Restored the content Phase 48 dropped from the maintainer guide: `## Hex release & recovery` heading + `hex-release--recovery-maintainers` anchor, `RELEASE_PLEASE_TOKEN`/`HEX_API_KEY` secrets, "Normal patch release (fully automated)"/"no manual merge" copy, CI gate map topology (`needs: policy`, Parallel verify jobs, Local parity, Ratchet-is-maintainer-only, failure diagnosis), the **Version namespaces** subsection, and the **PR vs release proof depth** subsection.
- Focused policy lane green (58 tests, 0 failures — all 7 previously-failing tests pass); wider lane green (94 tests, 0 failures — no regression to adopter/adoption assertions or the v2.15 breadcrumb test).

## Task Commits

Each task was committed atomically:

1. **Task 1: Repoint docs-contract constants and fix stale README link assertions** - `51461be5` (test)
2. **Task 2: Restore genuinely-dropped canonical maintainer content into guides/maintainers.md** - `25ad5233` (docs)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified
- `test/scoria/ci_policy_contract_test.exs` - Repointed `@maintainer_docs`/`@operator_docs` to `guides/maintainers.md`; fixed two README-link assertions. No assertion weakened; v2.15 breadcrumb test untouched.
- `guides/maintainers.md` - Restored dropped maintainer content in the guide's current voice: Hex release & recovery secrets + anchor, CI gate map topology/parity/diagnosis, Version namespaces, PR vs release proof depth. No `docs/*.md` stub or generated `doc/` edits.

## Decisions Made
- Both docs constants point at `guides/maintainers.md` (not a split to `guides/reviewer-verification.md`): the ratchet/release commands are maintainer-only content, and the guide's own intro explicitly forbids moving maintainer-only commands into adopter/reviewer docs (D-16, RESEARCH Assumption A2).
- Restored content adapted to the guide's current numbered-list/table style rather than pasted verbatim from the pre-Phase-48 `docs/MAINTAINERS.md` (D-17/D-19/D-20).
- The `## Hex release & recovery` heading uses an ExDoc IAL anchor (`{: #hex-release--recovery-maintainers}`) so it carries a genuine, linkable anchor that matches the workflow-comment reference — real maintainer content, not padding.

## Deviations from Plan

None - plan executed exactly as written. Both tasks landed with no auto-fixes, blocking issues, or architectural changes required.

## Issues Encountered
None. The `section_after/2` test helper truncates a section at the first `### ` heading; the restoration deliberately used `**bold**` subsection markers (not `### ` headings) so the CI-gate-map section and its PR-vs-release subsection remain within the helper's slice — matching the guide's existing heading structure (no `### ` headings anywhere in the file).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- REL-01 policy-lane failure is repaired; the `verify / policy` CI lane is green locally.
- Plan 50-02 (REL-02 e2e: dev_seed arity fix + theme-toggle locator) is independent and can proceed; together 50-01 + 50-02 unblock PR #12 toward `ci-gate` (REL-04).
- No blockers or concerns.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED
- FOUND: test/scoria/ci_policy_contract_test.exs
- FOUND: guides/maintainers.md
- FOUND: .planning/phases/50-release-readiness-and-0-1-3-cut/50-01-SUMMARY.md
- FOUND commit: 51461be5 (Task 1)
- FOUND commit: 25ad5233 (Task 2)
