---
phase: 48-host-app-install-contract-and-consumer-proof
plan: 02
subsystem: adoption
tags: [phoenix, installer, host-proof, adoption]
requires:
  - phase: 48
    provides: hardened installer contract and truthful default-lane inventory
provides:
  - Generated Phoenix host harness rooted in a temp app with a local `path:` Scoria dependency
  - Bounded host-proof runner for `deps.get`, install, migrate, and route smoke steps
  - Default-lane migration copy boundary that excludes optional semantic-cache migrations from fresh-host install proof
affects: [48-03, 48-04, adoption]
tech-stack:
  added: []
  patterns: [generated-host harness, bounded overlay, default-lane migration filtering]
key-files:
  created:
    - test/scoria/host_app_consumer_proof_test.exs
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex
    - test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs
  modified:
    - lib/mix/tasks/scoria.install.ex
    - test/mix/tasks/scoria.install_test.exs
key-decisions:
  - "The generated host stays deterministic by using a local `path:` dependency back to the repo root instead of a checked-in sample app or network-only package fetch."
  - "Default-lane host installs copy only the migrations needed for the default adoption proof; optional semantic-cache migrations no longer leak into the fresh-host path."
patterns-established:
  - "Host-proof steps execute in one explicit order and raise with captured output on the first failure."
  - "Fresh-host support code lives under test support and overlay files instead of a second maintained Phoenix application."
requirements-completed: [PROOF-01]
duration: 1h
completed: 2026-05-26
---

# Phase 48: Host-app install contract and consumer proof Summary

**Fresh Phoenix host adoption proof now runs through a bounded generated harness instead of repo-local fixtures**

## Performance

- **Duration:** 1h
- **Started:** 2026-05-26T04:24:00Z
- **Completed:** 2026-05-26T04:38:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Confirmed the generated-host harness and helper seams were present, then closed the default-lane regression exposed by the first fresh-host migration run.
- Filtered optional semantic-cache migrations out of the host install copy path so `mix ecto.migrate` stays valid for the default lane without retrieval or knowledge setup.
- Verified the generated host can fetch deps, run `mix scoria.install`, create and migrate its database, and prove `/scoria` and `/scoria/workflows/:run_id` routes exist through a copied route smoke.

## Task Commits

No new commits were created during this Codex run. The executed changes remain in the local working tree alongside pre-existing user changes.

## Files Created/Modified
- `test/scoria/host_app_consumer_proof_test.exs` - Repo-local contract for the bounded generated-host adoption path.
- `test/support/scoria/host_app_proof/generator.ex` - Temp-host creation, dependency patching, overlay copy, and generated-host test config helpers.
- `test/support/scoria/host_app_proof/runner.ex` - Explicit host-proof step runner for deps, install, migrate, route smoke, and runtime smoke.
- `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs` - Host-local route visibility assertions for `/scoria` and `/scoria/workflows/:run_id`.
- `lib/mix/tasks/scoria.install.ex` - Default-lane migration copy now excludes optional semantic-cache migrations.
- `test/mix/tasks/scoria.install_test.exs` - Installer contract assertions now lock the host migration boundary.

## Decisions Made
- Treat semantic fast path as optional at the host migration boundary, not just in docs and task names.
- Keep the generated-host proof tiny and disposable: temp directory, patched `mix.exs`, copied `test/` overlay, and no long-lived sample app.

## Deviations from Plan

One plan-owned bug surfaced during execution: the generated host failed `mix ecto.migrate` because optional semantic-cache migrations referenced retrieval tables outside the default lane. The fix stayed inside Phase 48 scope by narrowing the copied migration set rather than widening host setup.

## Issues Encountered

The first generated-host route proof exposed that the default install path still pulled optional semantic-cache migrations into the fresh Phoenix app. After filtering those migrations out of the installer copy path, the fresh-host proof passed.

## User Setup Required

None - the proof uses the local Postgres defaults already normalized in the phase validation commands.

## Next Phase Readiness

Phase 48-03 can build directly on the same generated-host harness because the install, migrate, and route visibility path is now green and bounded.

---
*Phase: 48-host-app-install-contract-and-consumer-proof*  
*Completed: 2026-05-26*
