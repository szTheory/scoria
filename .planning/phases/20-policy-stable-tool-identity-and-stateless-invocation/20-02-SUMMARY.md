# Phase 20 Plan 02: Catalog Reconciliation Summary

## Summary
Implemented deterministic reconciliation from refreshed connector catalog evidence into durable local-tool truth. Refresh now preserves stable local ids for safe drift, creates pending candidates for risky drift, and marks removed tools without deleting historical rows.

## Delivered
- Added `Scoria.Connectors.ToolReconciliation` for stable rebinding and drift classification.
- Wired reconciliation into `Scoria.Connectors.Discovery` after snapshot refresh.
- Recorded reconciliation outcome metadata for matched, pending, and removed local-tool ids.
- Preserved existing local-tool rows across widened or ambiguous remote changes and marked removed remote tools as `removed`.
- Added coverage in `test/scoria/connectors/tool_reconciliation_test.exs` and expanded `test/scoria/connectors_test.exs`.

## Verification
- `SCORIA_DB_PORT=55432 mix test test/scoria/connectors/tool_reconciliation_test.exs test/scoria/connectors_test.exs`

## Notes
- Refresh treats capability snapshots as evidence input, not runtime identity truth.
- No commit was created during this execution.
