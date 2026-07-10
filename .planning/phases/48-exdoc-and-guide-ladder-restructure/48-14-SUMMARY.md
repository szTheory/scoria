---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 14
subsystem: documentation
tags: [guides, compatibility, exdoc, capability-docs]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: canonical capability guides under guides/capabilities from 48-04
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: README and public moduledoc links to canonical guide paths from 48-06, 48-09, 48-13
provides:
  - Thin compatibility source pages for old capability docs paths
  - Source-link preservation for bounded handoffs, semantic cache, connectors/MCP, and support-copilot gallery docs
  - Explicit current guide names and canonical guides/capabilities targets in each compatibility page
affects: [phase-48, guides, exdoc, adopter-docs, compatibility-links]

tech-stack:
  added: []
  patterns:
    - Old docs/*.md capability paths remain source-link compatibility pages only.
    - Canonical guide truth stays under guides/capabilities/.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-14-SUMMARY.md
  modified:
    - docs/bounded_handoffs.md
    - docs/semantic_fast_path.md
    - docs/connector_adoption.md
    - docs/support_copilot_gallery.md

key-decisions:
  - "Old capability docs paths are compatibility pages only; canonical guide bodies stay under guides/capabilities/."
  - "Each compatibility page names the current guide first and mentions old names only as 0.1.x compatibility context."
  - "The plan did not touch dev-only docs or ExDoc/package configuration."

patterns-established:
  - "Compatibility pages use a short `Compatibility note` plus a direct canonical guide link instead of duplicating guide bodies."

requirements-completed: [DOCS-03]

duration: 2m 7s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 14: Capability Compatibility Source Pages Summary

**Old capability docs source paths now resolve to thin compatibility pages that point at the canonical `guides/capabilities/` guide ladder.**

## Performance

- **Duration:** 2m 7s
- **Started:** 2026-07-10T22:12:26Z
- **Completed:** 2026-07-10T22:14:33Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Replaced the old full guide bodies in `docs/bounded_handoffs.md`, `docs/semantic_fast_path.md`, `docs/connector_adoption.md`, and `docs/support_copilot_gallery.md` with compatibility source pages.
- Pointed each old source path at its canonical guide: Bounded Handoffs, Semantic Cache, Connectors and MCP, and Support Copilot Gallery under `guides/capabilities/`.
- Preserved 0.1.x source-link compatibility while making clear these pages are excluded from the canonical ExDoc guide surface.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert capability docs to compatibility stubs** - `70c668b7` (`docs`)

## Files Created/Modified

- `docs/bounded_handoffs.md` - Compatibility page pointing to `guides/capabilities/bounded-handoffs.md`.
- `docs/semantic_fast_path.md` - Compatibility page pointing to `guides/capabilities/semantic-cache.md` and current Semantic Cache naming.
- `docs/connector_adoption.md` - Compatibility page pointing to `guides/capabilities/connectors-and-mcp.md`.
- `docs/support_copilot_gallery.md` - Compatibility page pointing to `guides/capabilities/support-copilot-gallery.md`.

## Verification

- `rg -n "Compatibility note|guides/capabilities/bounded-handoffs.md|guides/capabilities/semantic-cache.md|guides/capabilities/connectors-and-mcp.md|guides/capabilities/support-copilot-gallery.md" docs/bounded_handoffs.md docs/semantic_fast_path.md docs/connector_adoption.md docs/support_copilot_gallery.md` - PASS.
- `rg -n "# Semantic Cache|Semantic Cache|semantic fast-path|guides/capabilities/semantic-cache.md" docs/semantic_fast_path.md` - PASS.
- `git diff --name-only -- docs/design_system.md docs/docker_dev_dx.md docs/uat_automation.md` - PASS, no output; dev-only docs untouched.
- `git diff --check -- docs/bounded_handoffs.md docs/semantic_fast_path.md docs/connector_adoption.md docs/support_copilot_gallery.md` - PASS.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs` - PASS, 10 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` - PARTIAL / expected out-of-scope failures: 39 tests ran, 7 failures remain in `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, and `guides/capabilities/bounded-handoffs.md`. These are the same guide-fragment failures already logged in `deferred-items.md` by 48-13 and are outside this plan's `files_modified` set.

## Decisions Made

- Kept the compatibility pages intentionally short instead of copying canonical guide content into both old and new paths.
- Used current public names first: Bounded Handoffs, Semantic Cache, Connectors and MCP, and Support Copilot Gallery.
- Left `docs/design_system.md`, `docs/docker_dev_dx.md`, `docs/uat_automation.md`, ExDoc extras, package inventory, and release-preview configuration untouched.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The broad stable-doc command remains red on pre-existing guide-fragment contract failures outside this plan's files. The failure set matches the existing Phase 48 deferred-items ledger, so no out-of-scope guide edits were made.

## Known Stubs

None that prevent this plan's goal. The four modified files are intentional compatibility pages, not incomplete placeholders.

## Threat Flags

None. This plan changed documentation text only and introduced no new endpoint, auth path, file-access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Old copied capability source links now land on explicit compatibility pages. Remaining guide-fragment adoption-surface failures are still tracked in `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` for a later guide cleanup plan.

## Self-Check: PASSED

- Found modified compatibility pages: `docs/bounded_handoffs.md`, `docs/semantic_fast_path.md`, `docs/connector_adoption.md`, and `docs/support_copilot_gallery.md`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-14-SUMMARY.md`.
- Found task commit: `70c668b7`.
- Confirmed dev-only docs remain untouched: `docs/design_system.md`, `docs/docker_dev_dx.md`, and `docs/uat_automation.md`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
