---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 12
subsystem: public-api-docs
tags: [exdoc, moduledocs, dashboard, reviewer, verification-suite]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 through 48-05 canonical guide bodies
  - phase: 44-dashboard-auth-seam
    provides: host on_mount hook pass-through and DashboardScope tenant authority
provides:
  - Polished public moduledocs for dashboard mount and DashboardScope integration
  - Polished reviewer surface, reviewer broadcast, and verification-suite public docs
  - Canonical guide links for dashboard scope, reviewer trace proof, and verification suites
affects: [phase-48, exdoc, public-api-docs, dashboard-docs, reviewer-docs]

tech-stack:
  added: []
  patterns:
    - Dashboard moduledocs show the explicit `scoria_dashboard "/scoria", on_mount: ..., scope_resolver: ...` integration shape.
    - Reviewer and broadcast docs frame trace reads and PubSub events through host-authenticated tenant scope.
    - Verification-suite docs describe public proof commands as adopter-facing contracts.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-12-SUMMARY.md
  modified:
    - lib/scoria_web/router.ex
    - lib/scoria_web/dashboard_scope.ex
    - lib/scoria_web/reviewer_surface.ex
    - lib/scoria/observe/reviewer_broadcast.ex
    - lib/scoria/verification_suites.ex
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md

key-decisions:
  - "Kept 48-12 documentation-only: no router behavior, DashboardScope behavior, PubSub behavior, verification-suite data, package config, or guide body changes."
  - "Used canonical guide paths in public moduledocs and kept old docs/*.md compatibility paths out of the new module docs."
  - "Treated the broad adoption-surface failures in guide fragments and SRE.AlertSink as outside the 48-12 file set and logged them in deferred-items.md."

patterns-established:
  - "Dashboard docs state that query params are hints and tenant authority comes from host-authenticated scope."
  - "Reviewer docs connect trace/read-model surfaces to reviewer-verification guide proof."

requirements-completed: [DOCS-01, DOCS-03]

duration: 3m 05s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 12: Dashboard and Reviewer Moduledocs Summary

**Dashboard, reviewer trace, and verification-suite public moduledocs now teach the host-authenticated scope boundary and link to canonical Phase 48 guides.**

## Performance

- **Duration:** 3m 05s
- **Started:** 2026-07-10T20:15:22Z
- **Completed:** 2026-07-10T20:18:27Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Reworked `ScoriaWeb.Router` and `ScoriaWeb.DashboardScope` moduledocs around the explicit `on_mount:` / `scope_resolver:` mount seam, host-authenticated tenant scope, and params-as-hints boundary.
- Reworked `ScoriaWeb.ReviewerSurface` and `Scoria.Observe.ReviewerBroadcast` moduledocs around reviewer trace reads, tenant-scoped PubSub events, and canonical reviewer verification guide links.
- Reworked `Scoria.VerificationSuites` moduledoc so verification-suite commands are described as public proof contracts, including `mix scoria.release_preview`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Polish dashboard mount and scope docs** - `dc065f8c` (`docs`)
2. **Task 2: Polish reviewer broadcast and verification suite docs** - `0da23ef9` (`docs`)

## Files Created/Modified

- `lib/scoria_web/router.ex` - Documents `scoria_dashboard "/scoria"` with `on_mount:` and `scope_resolver:` and links to Getting Started / Ownership Boundary.
- `lib/scoria_web/dashboard_scope.ex` - Documents host-authenticated tenant scope, params-as-hints semantics, resolver example, and canonical guide links.
- `lib/scoria_web/reviewer_surface.ex` - Documents reviewer-ready read maps, trace evidence, tenant scope, and reviewer verification guide link.
- `lib/scoria/observe/reviewer_broadcast.ex` - Documents tenant-scoped reviewer trace PubSub fan-out and fail-closed missing-tenant behavior.
- `lib/scoria/verification_suites.ex` - Documents verification suites as adopter-facing proof contracts and names release preview proof.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` - Logs broad adoption-surface failures outside the 48-12 file set.

## Verification

- `rg -n "scoria_dashboard|on_mount|scope_resolver|guides/getting-started.md|host-authenticated|params|query|guides/ownership-boundary.md" lib/scoria_web/router.ex lib/scoria_web/dashboard_scope.ex` - PASS.
- `rg -n "reviewer|trace|guides/reviewer-verification.md|verification suite|mix scoria.release_preview" lib/scoria_web/reviewer_surface.ex lib/scoria/observe/reviewer_broadcast.ex lib/scoria/verification_suites.ex` - PASS.
- `MIX_ENV=test mix run -e '<48-12 compiled moduledoc fragment checks>'` - PASS, printed `48-12 compiled moduledoc fragments ok`.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` - PARTIAL / expected still-RED outside 48-12: 29 tests ran, 8 failures remain in `guides/golden-path.md`, `guides/jtbd-and-user-flows.md`, `guides/capabilities/bounded-handoffs.md`, and `Scoria.SRE.AlertSink` moduledoc coverage. Logged in `deferred-items.md`.

## Decisions Made

- Kept examples in moduledocs as prose/code blocks only; no runtime/dashboard/DB/LiveView doctests were added.
- Preserved Phase 44 behavior exactly: host hooks run before DashboardScope, and query params are not tenant authority.
- Did not fix guide-fragment or SRE moduledoc failures from the broad adoption-surface suite because they are outside the 48-12 file set and already belong to later Phase 48 cleanup.

## Deviations from Plan

None to the implementation scope - the planned dashboard, reviewer, broadcast, and verification-suite public moduledocs were updated as requested.

## Issues Encountered

- The broad `test/scoria/adoption_surface_test.exs` command remains RED outside this plan's files. The 48-12-owned source assertions and compiled moduledoc checks pass; the remaining failures are tracked in `deferred-items.md`.

## Known Stubs

None. Stub scan matched `This Scoria dashboard is not available for this session.` in `ScoriaWeb.DashboardScope`; this is intentional fail-closed dashboard copy from the Phase 44 auth seam, not placeholder content.

## Threat Flags

None. This plan changed public documentation text only and introduced no new endpoint, auth path, file access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The dashboard/reviewer/verification-suite public docs owned by 48-12 now satisfy their canonical guide-link and boundary-language contracts. Later Phase 48 plans still need to close the already-logged guide-fragment failures and SRE public moduledoc guide-link failure.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-12-SUMMARY.md`.
- Found modified module files: `lib/scoria_web/router.ex`, `lib/scoria_web/dashboard_scope.ex`, `lib/scoria_web/reviewer_surface.ex`, `lib/scoria/observe/reviewer_broadcast.ex`, and `lib/scoria/verification_suites.ex`.
- Found task commits: `dc065f8c` and `0da23ef9`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
