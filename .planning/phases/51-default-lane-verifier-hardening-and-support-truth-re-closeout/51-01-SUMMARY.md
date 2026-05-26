---
phase: 51-default-lane-verifier-hardening-and-support-truth-re-closeout
plan: 01
subsystem: verifier
tags: [adoption, verifier, host-proof, timeout]
requires:
  - phase: 48-host-app-install-contract-and-consumer-proof
    provides: fresh-host proof harness and canonical adoption lane
provides:
  - Scoped timeout for the generated-host proof
  - Single-process host smoke proof with preserved step visibility
  - Green bounded adoption verifier without widening suite defaults
affects: [51-02, 51-03, adoption, support]
tech-stack:
  added: []
  patterns: [scoped timeout, batched host smoke proof, canonical bounded verifier]
key-files:
  created: []
  modified: [test/scoria/host_app_consumer_proof_test.exs, test/support/scoria/host_app_proof/runner.ex]
key-decisions:
  - "Published the verifier budget locally with `@moduletag timeout: 180_000` instead of widening ExUnit defaults."
  - "Collapsed route/runtime host smoke into one host-side `mix test ... --trace` process while preserving `:route_smoke` and `:runtime_smoke` in the proof result."
patterns-established:
  - "Slow generated-host proofs declare their own honest timeout at the test boundary."
  - "Runner batching can reduce duplicate Mix boot cost without changing the public proof step contract."
requirements-completed: [DOCS-02]
duration: 15min
completed: 2026-05-26
---

# Phase 51: Default-lane verifier hardening and support truth re closeout Summary

**The canonical adoption verifier is now bounded honestly and runs the expensive host proof with less duplicate harness cost**

## Performance

- **Duration:** 15 min
- **Completed:** 2026-05-26T14:19:28Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added a local `@moduletag timeout: 180_000` to `Scoria.HostAppConsumerProofTest` so the generated-host proof no longer inherits the accidental 60-second suite default.
- Refactored `Scoria.TestSupport.HostAppProof.Runner` so route and runtime smoke execute in one host-side `mix test` process while the returned proof still reports `:route_smoke` and `:runtime_smoke`.
- Kept `mix test.adoption` as the single public default-lane verifier and left `lib/mix/tasks/test.adoption.ex` unchanged.

## Verification

- `rg -n "@(moduletag|tag) timeout: [0-9_]+" test/scoria/host_app_consumer_proof_test.exs`
- `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs --trace`
- `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs test/mix/tasks/test.adoption_test.exs --trace`

## Results

- The single-file host proof passed in about 72.7 seconds.
- The combined host proof plus adoption task-boundary suite passed in about 74.3 seconds with `2 tests, 0 failures`.

## Task Commits

No new commits were created during this Codex run. The executed changes remain in the local working tree alongside pre-existing user changes.

## Next Phase Readiness

Wave 2 can now publish support copy against a truthful default-lane verifier budget and behavior.
