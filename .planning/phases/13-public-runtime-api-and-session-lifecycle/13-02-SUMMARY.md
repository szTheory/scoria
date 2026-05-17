# Plan 13-02 Summary

## Outcome

- Added `Scoria.Runtime.start_run/2` and `resume_run/2` on top of `Scoria.Workflows.create_run/1` and `Scoria.Workflows.Resume.resume_run/2`.
- Added `Scoria.Runtime.Params` to keep public lifecycle inputs explicit: canonical identity, runtime options, initial step payload, and dispatch options are normalized separately.
- Locked same-session continuity semantics with `test/scoria/runtime_integration_test.exs`: new starts reuse `session_id` but produce a fresh `run_id`, while resume stays exact to `run_id`.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs`
