---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 09
subsystem: public-api-docs
tags: [exdoc, moduledocs, semantic-cache, knowledge, connectors, mcp, req, eval, prompt-registry]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 through 48-05 canonical guide bodies and glossary
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-08 public runtime entry moduledoc pattern
provides:
  - Polished public moduledocs for semantic cache, optional knowledge base, connectors, MCP, Req steps, eval, and prompt registry modules
  - Canonical guide links from capability and integration modules to semantic cache, connectors/MCP, default runtime, reviewer verification, and ownership-boundary guides
  - Explicit optional-capability and ownership-boundary language for semantic cache, knowledge, connectors, eval, and prompt surfaces
affects: [phase-48, exdoc, public-api-docs, capability-docs]

tech-stack:
  added: []
  patterns:
    - Public capability moduledocs open with adopter-facing purpose before implementation details.
    - Optional capabilities link to canonical guides and keep host-owned identity, policy, corpus, tool, and prompt decisions explicit.
    - Semantic cache docs distinguish safe read-only answer reuse from the optional knowledge base.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-09-SUMMARY.md
  modified:
    - lib/scoria/semantic_cache/profile.ex
    - lib/scoria/semantic_cache.ex
    - lib/scoria/knowledge.ex
    - lib/scoria/connectors.ex
    - lib/scoria/connectors/auth.ex
    - lib/scoria/mcp/tool.ex
    - lib/scoria/req/steps.ex
    - lib/scoria/eval.ex
    - lib/scoria/prompt_registry.ex

key-decisions:
  - "Kept this plan documentation-only: no runtime behavior, schema, package, guide-body, or ExDoc config changes were made."
  - "Accepted the broad adoption-surface verification command as partial because its remaining failures are known later-plan guide/DashboardScope items outside the 48-09 file set."
  - "Used canonical guide paths directly in moduledocs rather than old docs/*.md compatibility paths."

patterns-established:
  - "Capability module docs state when to add the optional surface and what the host app still owns."
  - "Integration module docs link to verification-suite guidance without adding new doctest surfaces."

requirements-completed: [DOCS-01, DOCS-03]

duration: 5 min
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 09: Capability and Integration Moduledocs Summary

**Capability and integration public moduledocs now point to canonical guides and frame optional semantic cache, knowledge, connector, eval, and prompt surfaces through Scoria's ownership boundary.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-10T19:52:22Z
- **Completed:** 2026-07-10T19:56:57Z
- **Tasks:** 1
- **Files modified:** 9

## Accomplishments

- Reworked semantic cache moduledocs to link `guides/capabilities/semantic-cache.md`, mention profiles, and explicitly say semantic cache is not a knowledge base.
- Reworked knowledge, connector, MCP, Req, eval, and prompt registry moduledocs to use final public vocabulary, canonical guide links, and host-owned responsibility language.
- Kept examples/documentation pure and did not add DB, Repo, router, PubSub, worker, or LiveView doctest surfaces.

## Task Commits

Each task was committed atomically:

1. **Task 1: Polish capability and integration public docs** - `935965f2` (`docs`)

## Files Created/Modified

- `lib/scoria/semantic_cache/profile.ex` - Frames cache profiles as opt-in safe read-only reuse contracts and links the semantic cache guide.
- `lib/scoria/semantic_cache.ex` - Documents semantic cache lookup/admission/invalidation as reviewer-visible answer reuse, not a knowledge base.
- `lib/scoria/knowledge.ex` - Frames knowledge as optional retrieval/citation/grounding capability after default runtime proof.
- `lib/scoria/connectors.ex` - Documents remote connector records, fleet details, and host-owned tool availability decisions.
- `lib/scoria/connectors/auth.ex` - Documents host-owned connector authorization handoff, grant recording, and reviewer evidence.
- `lib/scoria/mcp/tool.ex` - Documents the MCP tool behavior as host-defined tool metadata and invocation shape.
- `lib/scoria/req/steps.ex` - Documents Req integration steps in the default runtime trace and verification-suite context.
- `lib/scoria/eval.ex` - Documents eval datasets, specs, score evidence, campaigns, and reviewer candidates as release proof.
- `lib/scoria/prompt_registry.ex` - Documents prompt template version lineage and its ownership split with eval/reviewer evidence.

## Verification

- `rg -n "guides/capabilities/semantic-cache.md|not a knowledge base|profile|guides/capabilities/connectors-and-mcp.md|verification suite|reviewer" lib/scoria/semantic_cache/profile.ex lib/scoria/semantic_cache.ex lib/scoria/knowledge.ex lib/scoria/connectors.ex lib/scoria/connectors/auth.ex lib/scoria/mcp/tool.ex lib/scoria/req/steps.ex lib/scoria/eval.ex lib/scoria/prompt_registry.ex` - PASS.
- `MIX_ENV=test mix run -e '<48-09 compiled moduledoc fragment checks>'` - PASS, printed `48-09 compiled moduledoc fragments ok`.
- `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs` - PASS, 10 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` - PARTIAL / known out-of-scope failures: 39 tests ran, 8 failures remain in guide fragments and `ScoriaWeb.DashboardScope` moduledoc coverage owned by later Phase 48 plans and already tracked in `deferred-items.md`.

## Decisions Made

- Kept implementation strictly to the nine plan-owned moduledoc blocks.
- Used `guides/capabilities/semantic-cache.md`, `guides/capabilities/connectors-and-mcp.md`, `guides/capabilities/default-runtime.md`, `guides/reviewer-verification.md`, and `guides/ownership-boundary.md` as the public links.
- Did not edit `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `guides/capabilities/bounded-handoffs.md`, or `lib/scoria_web/dashboard_scope.ex` even though broad verification still reports failures there.

## Deviations from Plan

None to the implementation scope - the planned capability and integration public moduledocs were updated as requested.

## Issues Encountered

- The broad plan-level adoption-surface command still fails outside this plan's files. Remaining failures are known Phase 48 deferred items for guide-fragment cleanup and dashboard-scope public docs, so they were not fixed in 48-09.

## Known Stubs

None found in files modified by this plan.

## Threat Flags

None. This plan changed documentation only and introduced no new endpoint, auth path, file-access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The capability and integration modules owned by 48-09 now satisfy their public guide-link and vocabulary contracts. Later Phase 48 public-moduledoc and guide-fragment plans still need to close the already-known `adoption_surface_test` failures outside this file set.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-09-SUMMARY.md`.
- Found modified module files: `lib/scoria/semantic_cache/profile.ex`, `lib/scoria/semantic_cache.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/connectors.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/mcp/tool.ex`, `lib/scoria/req/steps.ex`, `lib/scoria/eval.ex`, and `lib/scoria/prompt_registry.ex`.
- Found task commit: `935965f2`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
