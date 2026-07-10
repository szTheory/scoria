---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 04
subsystem: documentation
tags: [guides, capabilities, glossary, exdoc, public-docs]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-01 and 48-02 RED docs contracts
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 Start Here guides and ownership-boundary links
provides:
  - Capability guides for default runtime, bounded handoffs, semantic cache, connectors/MCP, and support-copilot gallery
  - Canonical `guides/reference/glossary.md` preserving final vocabulary, compatibility aliases, and evidence boundary wording
affects: [phase-48, guides, exdoc, adopter-docs]

tech-stack:
  added: []
  patterns:
    - Canonical `guides/capabilities/` docs migrate old flat `docs/` material while keeping optional capability boundaries explicit.
    - Glossary compatibility aliases preserve 0.1.x names without creating new storage/schema terminology.

key-files:
  created:
    - guides/capabilities/default-runtime.md
    - guides/capabilities/bounded-handoffs.md
    - guides/capabilities/semantic-cache.md
    - guides/capabilities/connectors-and-mcp.md
    - guides/capabilities/support-copilot-gallery.md
    - guides/reference/glossary.md
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-04-SUMMARY.md
  modified: []

key-decisions:
  - "Capability guides keep the default runtime first and frame knowledge, semantic cache, and connectors as optional expansions."
  - "The semantic cache guide explicitly says it is not a knowledge base and treats `lane_key` only as stored 0.1.x compatibility vocabulary."
  - "The canonical glossary preserves `evidence_refs` and compatibility aliases without introducing the forbidden `trace_refs` storage token."

patterns-established:
  - "Capability docs link to canonical `guides/...` paths even where sibling Phase 48 plans still own future target bodies."
  - "Repository-local examples are described as examples, not hosted product surfaces or Hex package features."

requirements-completed: [DOCS-01, DOCS-03]

duration: 7m 19s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 04: Capability and Reference Guides Summary

**Canonical capability guide bodies now cover default runtime, handoffs, semantic cache, connectors/MCP, support-copilot gallery, and the final vocabulary glossary.**

## Performance

- **Duration:** 7m 19s
- **Started:** 2026-07-10T19:05:45Z
- **Completed:** 2026-07-10T19:13:04Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created the default runtime, bounded handoff, and semantic cache capability guides under `guides/capabilities/`, preserving the default-first adoption order and D-18 optionality boundaries.
- Created the connectors/MCP and support-copilot gallery capability guides, including reviewer verification links and repository-local gallery framing.
- Added canonical `guides/reference/glossary.md` with core terms, legacy/industry equivalents, compatibility aliases, `evidence_refs`, and no `trace_refs` token.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create default runtime, bounded handoff, and semantic cache capability guides** - `bf0a4fec` (`docs`)
2. **Task 2: Create connectors, support copilot, and glossary guide files** - `7dfbdab3` (`docs`)

## Files Created/Modified

- `guides/capabilities/default-runtime.md` - Default runtime guide with identity, start, inspect, resume, dashboard scope, and optional capability boundaries.
- `guides/capabilities/bounded-handoffs.md` - Bounded handoff guide with host-owned identity/escalation/prompt selection, `scoped_context`, `root_role_id`, and `delegated_kind`.
- `guides/capabilities/semantic-cache.md` - Semantic cache guide with profile vocabulary, `semantic_cache: [profile: ...]`, `lane_key` compatibility framing, lifecycle states, and knowledge-base distinction.
- `guides/capabilities/connectors-and-mcp.md` - Connector/MCP guide with `Scoria.Connectors`, `Scoria.MCP.Tool`, embedded-boundary language, and reviewer verification links.
- `guides/capabilities/support-copilot-gallery.md` - Repository-local gallery guide for `examples/support_copilot`, advisory verification, and support journey fixtures.
- `guides/reference/glossary.md` - Canonical glossary preserving final vocabulary, legacy mappings, compatibility aliases, and evidence boundary wording.

## Verification

- `test -f guides/capabilities/default-runtime.md && test -f guides/capabilities/bounded-handoffs.md && test -f guides/capabilities/semantic-cache.md && rg -n "default runtime|optional knowledge base|scoped_context|delegated_kind|Scoria.SemanticCache.Profile|not a knowledge base" guides/capabilities/default-runtime.md guides/capabilities/bounded-handoffs.md guides/capabilities/semantic-cache.md` - PASS.
- `test -f guides/capabilities/connectors-and-mcp.md && test -f guides/capabilities/support-copilot-gallery.md && test -f guides/reference/glossary.md && rg -n "Scoria.Connectors|Scoria.MCP.Tool|examples/support_copilot|## Core terms|## Compatibility aliases|evidence_refs" guides/capabilities/connectors-and-mcp.md guides/capabilities/support-copilot-gallery.md guides/reference/glossary.md && ! rg -n "trace_refs" guides/reference/glossary.md` - PASS.
- `MIX_ENV=test mix test test/scoria/glossary_contract_test.exs` - PASS, 5 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:423 test/scoria/adoption_surface_test.exs:451 test/scoria/adoption_surface_test.exs:468` - PASS, 3 tests, 0 failures.

The broader Phase 48 stable-doc suites were not run as final acceptance because plan 48-05 and later plans still own `guides/reviewer-verification.md`, `guides/troubleshooting.md`, `guides/maintainers.md`, README rewiring, ExDoc config, and public moduledocs.

## Decisions Made

- Kept old `docs/*.md` sources untouched in this plan; compatibility stubs and ExDoc redirects are owned by later Phase 48 plans.
- Used canonical `guides/...` link literals so RED contracts can see final paths before ExDoc and README rewiring land.
- Kept connector and support-copilot copy embedded-library focused, not hosted-platform focused.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An early targeted ExUnit command accidentally included the later-plan reviewer verification test at `test/scoria/adoption_surface_test.exs:479`, which failed because `guides/reviewer-verification.md` is intentionally owned by 48-05. The correct plan-relevant focused lines were rerun and passed.

## Known Stubs

None found in files created by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 48-05 can now add operate/verify, troubleshooting, comparison, and maintainer guide bodies linked from these capability pages. Later Phase 48 plans can rewire README, ExDoc extras/groups, compatibility stubs, and public moduledocs against these canonical guide files.

## Self-Check: PASSED

- Found created guide files: `guides/capabilities/default-runtime.md`, `guides/capabilities/bounded-handoffs.md`, `guides/capabilities/semantic-cache.md`, `guides/capabilities/connectors-and-mcp.md`, `guides/capabilities/support-copilot-gallery.md`, and `guides/reference/glossary.md`.
- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-04-SUMMARY.md`.
- Found task commits: `bf0a4fec`, `7dfbdab3`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
