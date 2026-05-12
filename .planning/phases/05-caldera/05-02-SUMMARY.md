# Phase 05 Plan 02: Runtime, Approval Durability, and Recovery Summary

## Summary
Built the supervised workflow runtime and recovery entrypoints on top of the durable persistence slice. Runtime execution now claims runnable steps, records durable terminal states, persists approval waits before projection, and supports resume and retry through explicit recovery APIs.

## Delivered
- Added `Scoria.Workflows.Runtime`, `Scoria.Workflows.Reconciler`, and `Scoria.Workflows.Resume`.
- Extended `Scoria.Application` with workflow task supervision and a test-safe reconciler startup strategy.
- Added durable approval transitions and recovery dispatch over the same persisted state machine.
- Added runtime coverage for timeout, crash, handoff, approval, resume, and retry flows in `test/scoria/workflows/runtime_test.exs`.

## Verification
- `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs`

## Notes
- Exact resume and retry-failed-step now derive from stored workflow records rather than socket or process memory.
