---
phase: 15-adoption-surface-docs-and-example-flow
plan: 01
subsystem: docs
tags: [readme, phoenix, runtime, identity, moduledoc]
requires:
  - phase: 13-public-runtime-api-and-session-lifecycle
    provides: public runtime facade and session/run semantics
  - phase: 14-policy-defaults-and-install-ergonomics
    provides: install lane and runtime defaults wording
provides:
  - runtime-first README quickstart aligned to `Scoria`
  - facade and module docs that explain identity, run, and policy layering
affects: [adoption, docs, phoenix-integration, operator-verification]
tech-stack:
  added: []
  patterns: [public-surface-first teaching, session-id-versus-run-id guidance]
key-files:
  created: []
  modified: [README.md, lib/scoria.ex, lib/scoria/runtime.ex, lib/scoria/identity.ex, lib/scoria/prompt_policy.ex]
key-decisions:
  - "Kept `Scoria` as the only happy-path entrypoint in docs and moduledocs."
  - "Repeated the `session_id` continuity versus exact `run_id` resume rule across all public surfaces."
  - "Linked operator evidence to `/scoria/workflows/:run_id` without making the dashboard the business-system boundary."
patterns-established:
  - "README opens with install, identity normalization, run start, resume, and operator evidence before capability inventory."
  - "Module docs layer `Scoria` first, `Scoria.Identity` second, `Scoria.Runtime` as advanced, and `Scoria.PromptPolicy` as later governance."
requirements-completed: [ADOP-01, ADOP-04]
duration: 25min
completed: 2026-05-15
---

# Phase 15-01 Summary

**Runtime-first adoption docs now teach the shipped `Scoria` facade, exact `run_id` resume, shared `session_id` continuity, and layered public module roles.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-15T21:35:00Z
- **Completed:** 2026-05-15T21:42:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced the stale feature-inventory README opening with a `Scoria`-first quickstart grounded in the existing runtime integration flow.
- Added explicit docs for identity normalization, durable `run_id` persistence, shared `session_id` continuity, exact resume, and operator evidence routing.
- Upgraded public moduledocs so `Scoria`, `Scoria.Identity`, `Scoria.Runtime`, and `Scoria.PromptPolicy` reflect the intended adoption layering instead of placeholder text.

## Task Commits

No commits created in this execution. The repository already had unrelated in-progress changes, so the plan was executed as working-tree edits only.

## Files Created/Modified

- `README.md` - Runtime-first quickstart, verification summary, and example guide links
- `lib/scoria.ex` - Facade-first moduledoc with `session_id` versus `run_id` guidance
- `lib/scoria/runtime.ex` - Advanced lifecycle moduledoc positioned behind `Scoria`
- `lib/scoria/identity.ex` - Phoenix-edge normalization moduledoc
- `lib/scoria/prompt_policy.ex` - Governance/defaults moduledoc

## Decisions Made

- Kept the public docs anchored to functions that already exist in `Scoria` and to semantics proven by `test/scoria/runtime_integration_test.exs`.
- Mentioned the knowledge lane only after the core runtime and operator-evidence path.

## Deviations from Plan

None. The only verification adjustment was interpreting `Code.fetch_docs/1` with its current tuple shape after the plan's sample check proved too strict.

## Issues Encountered

- The planned `Code.fetch_docs/1` assertion assumed a narrower tuple pattern than the Elixir 1.19 docs format returns here. Resolved by verifying the compiled moduledoc payloads directly.

## User Setup Required

None.

## Next Phase Readiness

README and moduledocs now provide the stable vocabulary needed for the dedicated Phoenix example and operator verification guide in Plans `15-02` and `15-03`.
