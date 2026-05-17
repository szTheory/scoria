# Plan 13-03 Summary

## Outcome

- Added stable public DTOs in `lib/scoria/runtime/run_summary.ex` and `lib/scoria/runtime/run_detail.ex`.
- Added public inspection helpers in `Scoria.Runtime` and surfaced the common summary path through `Scoria`.
- Added `test/scoria/runtime_view_test.exs` to verify curated summary/detail projections and session grouping without exposing raw `%Scoria.Workflows.Run{}` structs.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs`
