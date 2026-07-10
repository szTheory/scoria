---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 05
subsystem: documentation
tags: [guides, reviewer-verification, troubleshooting, comparison, maintainers, exdoc]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 Start Here guide ladder and 48-04 capability/glossary guides
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: external LLM-ops comparison guide baseline and safe current/deferred claims
provides:
  - Operate & Verify guides for reviewer verification and troubleshooting
  - Compare & Decide guide under canonical guides/scoria-vs-external-llm-ops.md
  - Packaged maintainer guide under canonical guides/maintainers.md
affects: [phase-48, guides, exdoc, adopter-docs, package-surface]

tech-stack:
  added: []
  patterns:
    - Canonical guides preserve old docs/operator and docs/scoria_vs links as compatibility concepts while new content uses reviewer/capability/verification-suite vocabulary.
    - Maintainer-only commands stay in reviewer/maintainer guides rather than README or first-run adopter docs.

key-files:
  created:
    - guides/reviewer-verification.md
    - guides/troubleshooting.md
    - guides/scoria-vs-external-llm-ops.md
    - guides/maintainers.md
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-05-SUMMARY.md
  modified: []

key-decisions:
  - "Reviewer verification is the canonical public name; operator verification remains compatibility wording only."
  - "The comparison guide preserves Phase 47 safe current claims, named peer source links, ceded strengths, and explicit not-current claims."
  - "Maintainer-only CI, release, warning, installer, and dev-tool commands are intentionally packaged in guides/maintainers.md, not README."

patterns-established:
  - "Operate & Verify docs link to canonical guides/reference/glossary.md and preserve host-owned dashboard scope proof."
  - "Troubleshooting starts from the smallest failing verification suite before broad repo-health commands."
  - "Maintainer docs keep dev-only docs out of adopter HexDocs while documenting release-preview and docs maintenance."

requirements-completed: [DOCS-01, DOCS-03]

duration: 8 min
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 05: Operate, Compare, and Maintainer Guides Summary

**Canonical Operate & Verify, Troubleshooting, external LLM-ops comparison, and Maintainer guide bodies now exist under `guides/` with Phase 46/47 vocabulary preserved.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-10T19:19:33Z
- **Completed:** 2026-07-10T19:27:22Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Created `guides/reviewer-verification.md` with default runtime proof, host-owned dashboard tenant scope, upgrade-safe installer modes, release-preview proof, semantic cache outcome vocabulary, and maintainer closeout chain.
- Created `guides/troubleshooting.md` with common failure paths for `session_id` versus `run_id`, missing dashboard scope, semantic cache/profile confusion, optional knowledge setup, release preview/package drift, and installer check/apply drift.
- Created `guides/scoria-vs-external-llm-ops.md` with the guarded Phase 47 comparison title, named peers, source links, safe current claims, ceded strengths, and not-current claims.
- Created `guides/maintainers.md` with CI topology, release-preview/docs maintenance, installer contract proof, release recovery, warning ratchet, Phase 44 dashboard scope proof, and dev-only inspection surfaces.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create reviewer verification and troubleshooting guides** - `81076159` (`docs`)
2. **Task 2: Create comparison and maintainer guides under canonical paths** - `ec69bd1a` (`docs`)

## Files Created/Modified

- `guides/reviewer-verification.md` - Canonical reviewer verification guide replacing operator-verification naming while preserving compatibility proof requirements.
- `guides/troubleshooting.md` - Troubleshooting guide for runtime IDs, dashboard scope, semantic cache, optional knowledge, installer drift, and release preview.
- `guides/scoria-vs-external-llm-ops.md` - Canonical Compare & Decide guide preserving Phase 47 external LLM-ops contracts.
- `guides/maintainers.md` - Packaged maintainer guide for release-preview, CI topology, docs maintenance, warnings, installer contracts, and dev-only tools.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` - Logs broad stable-doc RED failures outside the 48-05 file set.

## Verification

- `test -f guides/reviewer-verification.md && test -f guides/troubleshooting.md && rg -n "host authenticates|tenant scope|verification suite|session_id|run_id|dashboard scope|semantic cache|guides/reference/glossary.md" guides/reviewer-verification.md guides/troubleshooting.md` - PASS.
- `test -f guides/scoria-vs-external-llm-ops.md && test -f guides/maintainers.md && rg -n "Scoria vs external LLM-ops platforms|LangSmith|Langfuse|Braintrust|Arize Phoenix|Not current Scoria claims|mix scoria.release_preview" guides/scoria-vs-external-llm-ops.md guides/maintainers.md` - PASS.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:312 test/scoria/adoption_surface_test.exs:479 test/scoria/adoption_surface_test.exs:575` - PASS, 3 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:223 test/scoria/adoption_surface_test.exs:575` - PASS, 2 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs` - PASS, 10 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` - PARTIAL / expected still-RED outside 48-05: 39 tests, 11 failures in README links, Golden Path fragments, JTBD/bounded-handoff fragments, and D-17 moduledoc guide links. These are logged in `deferred-items.md` because they are outside the 48-05 file set.

## Decisions Made

- Kept old `operator_verification` and `operator` terminology only as compatibility notes in the canonical reviewer guide.
- Kept the comparison guide current-section free of deferred claims while preserving the same peer posture and source links from Phase 47.
- Kept dev-only docs such as design system, Docker dev DX, UAT automation, component lab, and screenshot harness out of adopter HexDocs while summarizing their maintainer-only proof commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved reviewer-guide compatibility fragments required by existing contracts**
- **Found during:** Task 1 verification
- **Issue:** The first draft of `guides/reviewer-verification.md` passed the plan source assertions but missed compatibility fragments still asserted by `test/scoria/adoption_surface_test.exs`, including `mix scoria.test.install_contract`, upgrade-safe installer wording, default runtime proof details, and semantic cache outcome vocabulary.
- **Fix:** Added the required compatibility proof sections and amended the Task 1 commit so the reviewer/troubleshooting guide task remained atomic.
- **Files modified:** `guides/reviewer-verification.md`
- **Verification:** `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:312 test/scoria/adoption_surface_test.exs:479 test/scoria/adoption_surface_test.exs:575` passed.
- **Committed in:** `81076159`

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** The fix preserved existing docs contract behavior without widening runtime or package scope.

## Issues Encountered

- The broad stable-doc command still fails because Phase 48 has later-plan RED contracts for README rewiring, public moduledoc links, and a few sibling guide fragments. These were logged to `deferred-items.md` and not fixed in 48-05 to keep this plan scoped to its four canonical guide files.

## Known Stubs

None. Stub scan matched `This Scoria dashboard is not available for this session.` in `guides/reviewer-verification.md`; this is intentional fail-closed dashboard copy, not a stub.

## Threat Flags

None. This plan created Markdown guides and one planning deferred-items artifact only; it introduced no new runtime endpoint, auth path, file access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The 48-05 guide bodies are ready for later Phase 48 README rewiring, ExDoc extras/groups, compatibility stubs, release-preview path updates, and public moduledoc link work. The broad adoption-surface RED failures are already documented in `deferred-items.md` for those later plans.

## Self-Check: PASSED

- Found created guide files: `guides/reviewer-verification.md`, `guides/troubleshooting.md`, `guides/scoria-vs-external-llm-ops.md`, and `guides/maintainers.md`.
- Found planning artifacts: `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` and `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-05-SUMMARY.md`.
- Found task commits: `81076159` and `ec69bd1a`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
