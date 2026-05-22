## Plan 21-02 Summary

- Added `Scoria.Connectors.OperatorProjection` plus `Scoria.Connectors.list_connector_fleet/1` and `get_connector_drawer/1` for durable operator read models.
- Added embedded dashboard components for the approvals inbox and connector detail drawer.
- Updated `ScoriaWeb.OrchestratorLive` to load the durable approval inbox, compact connector fleet, and connector drawer while keeping the modal as an interrupt affordance.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs`
