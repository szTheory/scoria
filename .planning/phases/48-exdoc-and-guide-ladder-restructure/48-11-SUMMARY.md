---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 11
subsystem: documentation
tags: [compatibility, guides, docs, source-links]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 Start Here guide ladder
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-04 capability and glossary guide bodies
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-05 reviewer verification, troubleshooting, comparison, and maintainer guide bodies
provides:
  - Compatibility source pages for old copied `docs/*.md` links
  - Canonical guide pointers for glossary, capability/JTBD, comparison, and runtime docs
affects: [phase-48, docs, guides, hexdocs, package-surface]

tech-stack:
  added: []
  patterns:
    - Old `docs/*.md` source paths remain compatibility pages only; canonical docs live under `guides/`.
    - Compatibility pages name current guide titles first and keep old names only as compatibility context.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-11-SUMMARY.md
  modified:
    - docs/glossary.md
    - docs/adoption_lanes.md
    - docs/scoria_vs_external_llm_ops.md
    - docs/phoenix_runtime_example.md
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md

key-decisions:
  - "Old start, reference, runtime, and comparison source paths are compatibility bridges only; canonical public guide truth stays under guides/."
  - "Compatibility pages use current guide names and paths first, with old names retained only to explain copied 0.1.x source links."

patterns-established:
  - "Old docs source paths should be thin cross-links, not duplicate canonical guide bodies."
  - "Compatibility stubs should explicitly state they are not canonical ExDoc sources."

requirements-completed: [DOCS-03]

duration: 4 min
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 11: Compatibility Source Pages Summary

**Old copied docs source paths now land on thin compatibility pages that point to the canonical Phase 48 guide ladder.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-10T20:05:32Z
- **Completed:** 2026-07-10T20:09:00Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Replaced `docs/glossary.md` with a compatibility page pointing to `guides/reference/glossary.md`.
- Replaced `docs/adoption_lanes.md` with a compatibility page pointing to `guides/jtbd-and-user-flows.md` and `guides/capabilities/default-runtime.md`.
- Replaced `docs/scoria_vs_external_llm_ops.md` with a compatibility page pointing to `guides/scoria-vs-external-llm-ops.md`.
- Replaced `docs/phoenix_runtime_example.md` with a compatibility page pointing to `guides/golden-path.md` and `guides/capabilities/default-runtime.md`.
- Logged the still-RED broad adoption-surface failures outside the 48-11 file set in `deferred-items.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert start, reference, runtime, and comparison docs to compatibility stubs** - `708a9bac` (`docs`)

## Files Created/Modified

- `docs/glossary.md` - Compatibility page for old glossary source links, pointing to the canonical glossary guide.
- `docs/adoption_lanes.md` - Compatibility page for old adoption-lanes source links, pointing to JTBD/user flows and default runtime guides.
- `docs/scoria_vs_external_llm_ops.md` - Compatibility page for old comparison source links, pointing to the canonical comparison guide.
- `docs/phoenix_runtime_example.md` - Compatibility page for old runtime-example source links, pointing to Golden Path and Default Runtime.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` - Records out-of-scope plan-level verification failures that predate or sit outside 48-11.

## Verification

- `rg -n "Compatibility note|guides/reference/glossary.md|guides/jtbd-and-user-flows.md|guides/capabilities/default-runtime.md|guides/golden-path.md|guides/scoria-vs-external-llm-ops.md" docs/glossary.md docs/adoption_lanes.md docs/scoria_vs_external_llm_ops.md docs/phoenix_runtime_example.md` - PASS.
- `git diff --name-only` before task commit listed only the four planned docs files - PASS.
- `git diff -- docs/design_system.md docs/docker_dev_dx.md docs/uat_automation.md` produced no output - PASS.
- `rg -n "docs/(design_system|docker_dev_dx|uat_automation)\\.md" docs/glossary.md docs/adoption_lanes.md docs/scoria_vs_external_llm_ops.md docs/phoenix_runtime_example.md || true` produced no matches - PASS.
- `git diff --check -- docs/glossary.md docs/adoption_lanes.md docs/scoria_vs_external_llm_ops.md docs/phoenix_runtime_example.md` - PASS.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs` - PASS, 10 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - PARTIAL / expected still-RED outside 48-11: 39 tests, 8 failures in `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `guides/capabilities/bounded-handoffs.md`, and D-17 public moduledoc links. These are logged in `deferred-items.md`.

## Decisions Made

- Kept the compatibility pages short instead of duplicating canonical guide bodies.
- Used canonical `guides/...` path literals in every compatibility page so source assertions and copied links remain clear.
- Kept design-system, Docker DX, and UAT automation docs out of these adopter compatibility links.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The broad stable-doc command still fails outside the 48-11 file set. Remaining failures match already-recorded Phase 48 deferred work for guide fragments and public moduledoc canonical links, so they were logged in `deferred-items.md` and not fixed in this plan.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. This plan changed Markdown compatibility pages and one planning deferred-items artifact only; it introduced no runtime endpoint, auth path, file access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The old start, reference, runtime, and comparison source paths now satisfy the compatibility-stub policy. Later Phase 48 plans can continue closing the remaining guide fragment and public moduledoc adoption-surface failures already tracked in `deferred-items.md`.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-11-SUMMARY.md`.
- Found modified docs files: `docs/glossary.md`, `docs/adoption_lanes.md`, `docs/scoria_vs_external_llm_ops.md`, and `docs/phoenix_runtime_example.md`.
- Found deferred-items artifact: `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md`.
- Found task commit: `708a9bac`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
