---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 07
subsystem: documentation-package-surface
tags: [exdoc, hexdocs, package-surface, release-preview, guide-ladder]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-01 RED package/release-preview contracts and 48-03 through 48-15 guide/moduledoc/compatibility surfaces
  - phase: 47-readme-first-screen-positioning-and-scope-doctrine
    provides: README positioning and public ownership-boundary doctrine
provides:
  - Version-aware ExDoc source metadata through Scoria.MixProject.docs_source_ref/0
  - Canonical guide extras, extra groups, module groups, redirects, brand metadata, and public module filtering
  - Hex package and release-preview inventory for guides, compatibility stubs, and docs brand assets
affects: [phase-48, exdoc, hexdocs, package, release-preview]

tech-stack:
  added: []
  patterns:
    - ExDoc config uses helper-backed canonical guide, redirect, module-group, and allowlist functions.
    - docs_source_ref/0 prefers maintainer env override, exact release tag, then main fallback.
    - mix.exs package files and release-preview required paths carry the same guide/stub/brand inventory.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-07-SUMMARY.md
  modified:
    - mix.exs
    - lib/mix/tasks/scoria.release_preview.ex

key-decisions:
  - "ExDoc source links now default to main unless SCORIA_DOCS_SOURCE_REF is set or HEAD is exactly tagged as v0.1.2."
  - "Public ExDoc modules are filtered through a positive allowlist matching the Phase 48 public reference surface and compatibility aliases."
  - "Old docs/*.md paths remain packaged compatibility stubs but are excluded from ExDoc extras."

patterns-established:
  - "Use docs_extras/0, docs_extra_groups/0, docs_module_groups/0, docs_redirects/0, and docs_public_modules/0 as the mix.exs source of truth for the public docs surface."
  - "Keep dev-only docs out of package files and ExDoc extras unless a future plan explicitly changes that boundary."

requirements-completed: [DOCS-01, DOCS-02, DOCS-03]

duration: 9m 15s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 07: ExDoc and Release-Preview Surface Summary

**ExDoc now opens on the canonical guide ladder with grouped public modules, dynamic source refs, redirects, brand assets, and release-preview package coverage.**

## Performance

- **Duration:** 9m 15s
- **Started:** 2026-07-10T22:29:33Z
- **Completed:** 2026-07-10T22:38:48Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added `Scoria.MixProject.docs_source_ref/0`, `@source_url`, `@hexdocs_url`, and `@release_docs_url`; source refs now prefer `SCORIA_DOCS_SOURCE_REF`, then exact `v0.1.2` tag, then `"main"`.
- Replaced flat ExDoc config with canonical `guides/` extras, reader-job extra groups, consumer-journey module groups, old page-ID redirects, logo/favicon, HTML+Markdown formatters, and a public module allowlist.
- Aligned `mix.exs` package files and `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0` with canonical guides, old compatibility stubs, base runtime/migration files, and four docs brand assets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add docs metadata helpers and dynamic source ref** - `0c8d3b59` (`feat`)
2. **Task 2: Configure ExDoc extras, groups, redirects, module allowlist, and brand metadata** - `2255e615` (`feat`)
3. **Task 3: Align package files and release-preview required paths** - `e4f7911b` (`feat`)

## Files Created/Modified

- `mix.exs` - Adds docs metadata helpers, ExDoc guide/module grouping, redirect map, public module filter, package guide/stub/brand inventory, and package metadata links.
- `lib/mix/tasks/scoria.release_preview.ex` - Extends required package paths to include canonical guides, compatibility stubs, and docs brand assets.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-07-SUMMARY.md` - Records plan completion.

## Verification

- `rg -n '@source_url|@hexdocs_url|@release_docs_url|def docs_source_ref|SCORIA_DOCS_SOURCE_REF|tag.*points-at.*HEAD|homepage_url: @hexdocs_url|source_url: @source_url' mix.exs` - PASS.
- `MIX_ENV=test mix run -e 'IO.puts(Scoria.MixProject.docs_source_ref())'` - PASS, printed `main`.
- `SCORIA_DOCS_SOURCE_REF=test-ref MIX_ENV=test mix run -e 'IO.puts(Scoria.MixProject.docs_source_ref())'` - PASS, printed `test-ref`.
- `MIX_ENV=test mix test test/scoria/package_surface_test.exs` - PASS, 8 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` - PASS, 9 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - PASS, 48 tests, 0 failures.
- `MIX_ENV=dev mix scoria.release_preview` - PASS; docs/package preview completed and printed `==> Release preview passed`. It emitted non-failing ExDoc warnings for command literals and intentionally filtered helper/internal modules; broad docs warning-as-error cleanup remains deferred per Phase 48 D-22.

## Decisions Made

- Kept the ExDoc public API reference as a positive allowlist instead of namespace filtering so implementation-detail modules do not become public contracts.
- Kept compatibility wrappers visible in the `Compatibility Aliases` module group without adding runtime deprecation attributes.
- Kept `docs/*.md` compatibility pages packaged for copied source links, but excluded them from ExDoc extras so the sidebar only shows canonical `guides/` pages.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Moved package file alignment into Task 2 commit**
- **Found during:** Task 2 verification.
- **Issue:** `test/scoria/package_surface_test.exs` is the required Task 2 verifier and it asserts both ExDoc config and `mix.exs` package-file inventory. Leaving package files for Task 3 would keep Task 2 red even though ExDoc config was correct.
- **Fix:** Updated `mix.exs` package files in the Task 2 commit; Task 3 then updated the release-preview task to match the same inventory.
- **Files modified:** `mix.exs`
- **Verification:** `MIX_ENV=test mix test test/scoria/package_surface_test.exs` passed, 8 tests, 0 failures.
- **Committed in:** `2255e615`

**Total deviations:** 1 auto-fixed (Rule 3 blocking).
**Impact on plan:** The same planned package inventory still landed; only the task boundary shifted within `mix.exs` so the required verifier could pass.

## Issues Encountered

- `MIX_ENV=dev mix scoria.release_preview` passes but emits existing/non-failing ExDoc warnings from code-autolinking command literals and filtered helper modules. This matches Phase 48 D-22's deferred broad docs warning-clean gate and did not block the release-preview inventory proof.

## Known Stubs

None found in files modified by this plan. The stub-pattern scan only matched `ref != ""` in `docs_source_ref/0`, which is source-ref validation logic.

## Threat Flags

None. The new source-ref environment boundary, ExDoc redirects, and package allowlist are the mitigated surfaces already registered in the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 48-10 can run the remaining final generated-docs gate against grouped ExDoc output. The Phase 48 RED package/release-preview contracts from 48-01 are now green.

## Self-Check: PASSED

- Found modified files: `mix.exs`, `lib/mix/tasks/scoria.release_preview.ex`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-07-SUMMARY.md`.
- Found task commits: `0c8d3b59`, `2255e615`, and `e4f7911b`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
