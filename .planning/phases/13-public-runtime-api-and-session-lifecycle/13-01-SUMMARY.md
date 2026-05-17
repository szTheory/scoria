# Plan 13-01 Summary

## Outcome

- Promoted `Scoria` from a placeholder module into the canonical public runtime facade.
- Added `Scoria.start_run/2`, `resume_run/2`, `get_run/1`, `get_run_detail/1`, and `list_runs_for_session/1` as thin delegates over the new public runtime layer.
- Added Wave 0 facade coverage in `test/scoria_test.exs` and `test/scoria/runtime_test.exs`.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_test.exs test/scoria/runtime_test.exs`

## Notes

- Executed inline on the current dirty tree to preserve in-flight workspace changes.
