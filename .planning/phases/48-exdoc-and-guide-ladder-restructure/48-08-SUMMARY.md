---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 08
subsystem: public-api-docs
tags: [exdoc, moduledocs, runtime, facade, identity, prompt-policy]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-03 through 48-05 canonical guide bodies
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-06 README guide ladder links
provides:
  - Polished public moduledocs for facade, identity, runtime lifecycle, runtime DTOs, and prompt policy
  - Canonical guide links from first public API pages to getting started, golden path, ownership boundary, and default runtime docs
  - Explicit session_id versus run_id and host-owned identity/policy boundary language
affects: [phase-48, exdoc, public-api-docs, runtime-docs]

tech-stack:
  added: []
  patterns:
    - Public entrypoint moduledocs open with adopter-facing purpose before backend details.
    - Runtime docs distinguish host-owned session continuity from exact Scoria run handles.
    - Prompt-policy docs frame policy values as host-owned inputs rather than Scoria-owned authorization.

key-files:
  created:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-08-SUMMARY.md
  modified:
    - lib/scoria.ex
    - lib/scoria/identity.ex
    - lib/scoria/runtime.ex
    - lib/scoria/runtime/run_summary.ex
    - lib/scoria/runtime/run_detail.ex
    - lib/scoria/prompt_policy.ex
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md

key-decisions:
  - "Kept runtime and DTO examples as prose/non-doctest documentation; only the existing pure facade and identity doctests remain executable doctest surfaces."
  - "Logged broad adoption-surface failures outside the 48-08 file set to deferred-items.md instead of widening this plan into later public-moduledoc and guide-fragment work."

patterns-established:
  - "Facade/runtime module docs link directly to canonical guide paths rather than old docs/*.md compatibility paths."
  - "Public runtime DTO docs describe returned API data, not persistence internals."

requirements-completed: [DOCS-01, DOCS-03]

duration: 5m 10s
completed: 2026-07-10
status: complete
---

# Phase 48 Plan 08: Public Runtime Entry Moduledocs Summary

**Public facade, identity, runtime lifecycle, runtime DTO, and prompt-policy moduledocs now read as adopter-facing entry pages with canonical guide links and ID-boundary guidance.**

## Performance

- **Duration:** 5m 10s
- **Started:** 2026-07-10T19:42:38Z
- **Completed:** 2026-07-10T19:47:48Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Reworked `Scoria`, `Scoria.Identity`, `Scoria.Runtime`, `Scoria.Runtime.RunSummary`, `Scoria.Runtime.RunDetail`, and `Scoria.PromptPolicy` moduledocs so they open with public purpose, when-to-use guidance, and canonical `guides/` links.
- Preserved the `session_id` versus `run_id` distinction in facade, identity, runtime, and DTO docs.
- Added host-owned identity, tenant scope, prompt-policy, and business-meaning language without adding runtime, Repo, PubSub, router, DB, or LiveView doctests.
- Logged the remaining broad adoption-surface failures that belong to later Phase 48 guide/public-moduledoc plans.

## Task Commits

Each task was committed atomically:

1. **Task 1: Polish facade, identity, runtime, and prompt policy docs** - `5f3dd74f` (`docs`)

## Files Created/Modified

- `lib/scoria.ex` - Adds first-run and ownership-boundary guide links plus clearer facade purpose.
- `lib/scoria/identity.ex` - Frames identity as host-owned boundary data and links to getting started / ownership docs.
- `lib/scoria/runtime.ex` - Documents the deeper runtime lifecycle API, default-runtime optionality, and guide links.
- `lib/scoria/runtime/run_summary.ex` - Explains the public summary DTO and `run_id` / `session_id` fields.
- `lib/scoria/runtime/run_detail.ex` - Explains the detailed public DTO for reviewer/run inspection.
- `lib/scoria/prompt_policy.ex` - Frames prompt policy as host-owned governance input and links to ownership/default-runtime guides.
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md` - Records out-of-scope broad adoption-surface failures observed during this plan.

## Verification

- `rg -n "guides/getting-started.md|guides/golden-path.md|guides/ownership-boundary.md|session_id|run_id|host-owned" lib/scoria.ex lib/scoria/identity.ex lib/scoria/runtime.ex lib/scoria/prompt_policy.ex` - PASS.
- `MIX_ENV=test mix run -e '<48-08 compiled moduledoc fragment checks>'` - PASS, printed `48-08 compiled moduledoc fragments ok`.
- `MIX_ENV=test mix test test/scoria_test.exs test/scoria/identity_doctest_test.exs` - PASS, 3 doctests, 2 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria_test.exs test/scoria/identity_doctest_test.exs` - PARTIAL / expected still-RED outside 48-08: 31 tests plus 3 doctests ran, 8 adoption-surface failures remain in later-plan module docs and guide-fragment contracts. Logged in `deferred-items.md`.

## Decisions Made

- Kept the implementation to moduledocs in the six named public entry modules; no runtime behavior, package config, ExDoc config, or guide body edits were made.
- Avoided adding new doctest surfaces for runtime, dashboard, DB, Repo, PubSub, router, or LiveView examples.
- Treated broad adoption-surface failures outside the named files as deferred Phase 48 work, per the scope-boundary rule.

## Deviations from Plan

None to the implementation scope - the planned six public entry modules were updated as requested.

## Issues Encountered

- The broader plan-level adoption-surface command still fails outside this plan's files. Remaining failures are documented in `.planning/phases/48-exdoc-and-guide-ladder-restructure/deferred-items.md`.
- `mix format` initially introduced unrelated formatting churn in pre-existing runtime code. Those formatter-only changes were discarded from the touched files and the doc edits were reapplied so the task commit stayed scoped.

## Known Stubs

None found in files modified by this plan.

## Threat Flags

None. This plan changed documentation and planning ledger text only; it introduced no new endpoint, auth path, file-access trust boundary, schema change, or package dependency.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Later Phase 48 public-moduledoc plans can continue from the deferred D-17 failures for dashboard, connector, eval, SRE, and compatibility surfaces. The start/install/facade/identity/runtime entry points owned by 48-08 now have canonical guide links and compiled moduledoc proof.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-08-SUMMARY.md`.
- Found modified module files: `lib/scoria.ex`, `lib/scoria/identity.ex`, `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex`, and `lib/scoria/prompt_policy.ex`.
- Found task commit: `5f3dd74f`.

---
*Phase: 48-exdoc-and-guide-ladder-restructure*
*Completed: 2026-07-10*
