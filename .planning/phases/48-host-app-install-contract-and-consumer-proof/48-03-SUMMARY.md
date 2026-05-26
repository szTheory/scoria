---
phase: 48-host-app-install-contract-and-consumer-proof
plan: 03
subsystem: runtime
tags: [runtime, host-proof, operator-evidence, adoption]
requires:
  - phase: 48
    provides: generated-host install, migration, and route proof
provides:
  - Host-side runtime smoke for one durable run, readback, and operator evidence
  - Generated-host Scoria test config for Repo, Vault, and Oban startup in the temp Phoenix app
  - Runtime overlay setup aligned with the existing repo-local runtime integration contract
affects: [48-04, adoption]
tech-stack:
  added: []
  patterns: [bounded runtime smoke, shared sandbox wiring, generated-host dependency config]
key-files:
  created:
    - test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs
  modified:
    - test/scoria/host_app_consumer_proof_test.exs
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs
key-decisions:
  - "The generated host gets only the minimal `:scoria` test config needed to boot runtime-owned dependencies inside the proof lane."
  - "Host runtime proof reuses the repo-local runtime integration shape: one approval-paused run, one readback, and one operator route render."
patterns-established:
  - "Generated-host runtime tests check out `Scoria.Repo` explicitly and start the reconciler in test mode."
  - "Default-lane runtime proof stays narrow: one run, one readback, one operator view."
requirements-completed: [PROOF-02]
duration: 45min
completed: 2026-05-26
---

# Phase 48: Host-app install contract and consumer proof Summary

**The generated Phoenix host now proves one real default-lane Scoria run and matching operator evidence**

## Performance

- **Duration:** 45 min
- **Started:** 2026-05-26T04:30:00Z
- **Completed:** 2026-05-26T04:38:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added the host-local runtime smoke to the generated harness and verified it runs after the route smoke in the same fresh Phoenix app.
- Patched the generated host’s `config/test.exs` to supply the minimal `:scoria` Repo, Vault, and Oban config needed for dependency startup inside the adoption proof.
- Aligned the host runtime overlay with `test/scoria/runtime_integration_test.exs` by checking out `Scoria.Repo`, starting `Scoria.Workflows.Reconciler`, and proving one run/readback/operator-view flow on the same `run_id`.

## Task Commits

No new commits were created during this Codex run. The executed changes remain in the local working tree alongside pre-existing user changes.

## Files Created/Modified
- `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` - Host-local runtime smoke for one durable run, readback, and operator evidence render.
- `test/support/scoria/host_app_proof/generator.ex` - Generated-host test config now includes the minimal `:scoria` dependency settings required for runtime startup.
- `test/scoria/host_app_consumer_proof_test.exs` - Host-proof contract remains the single repo-local entrypoint for the generated-host route and runtime smokes.

## Decisions Made
- Use host-side config injection rather than ad hoc CLI flags so the fresh-host proof exercises the same dependency startup path adopters would actually hit.
- Keep the runtime smoke intentionally shallow and let `test/scoria/runtime_integration_test.exs` remain the deeper semantics owner.

## Deviations from Plan

The runtime smoke initially failed before test execution because the generated host lacked `:scoria` dependency config. The fix stayed plan-owned by adding only the minimal test configuration and sandbox wiring required for the bounded runtime proof.

## Issues Encountered

After the route smoke passed, the host runtime test exposed missing `Oban` configuration in the generated app. Adding the minimal `:scoria` test config and explicit reconciler startup resolved the issue without widening the default lane.

## User Setup Required

None - the host runtime proof uses the same local Postgres defaults already required by the generated-host install proof.

## Next Phase Readiness

Phase 48-04 can now wire the generated-host proof into `mix test.adoption` because the host install, route, runtime, and operator-evidence path is fully green.

---
*Phase: 48-host-app-install-contract-and-consumer-proof*  
*Completed: 2026-05-26*
