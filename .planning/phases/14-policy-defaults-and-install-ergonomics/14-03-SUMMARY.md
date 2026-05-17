# Plan 14-03 Summary

## Outcome

Hardened the default Phoenix install lane and explicit knowledge verification lane for `POLY-03`.

- Expanded `mix scoria.install` to inject router, Tailwind, and baseline runtime config scaffolding idempotently.
- Added route-level smoke coverage that proves the installed `/scoria` dashboard mount resolves through Phoenix routing.
- Renamed the explicit knowledge verification task to `Mix.Tasks.Scoria.Test.Knowledge` so `mix scoria.test.knowledge` is the primary contract.
- Kept `Mix.Tasks.Test.Knowledge` as a compatibility wrapper and preserved the existing core-vs-knowledge migration-lane invariants.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs`

## Notes

- The default lane remains Postgres-only and does not pull pgvector or knowledge tables into the happy path.
- Installer output now teaches the core lane first and keeps the knowledge lane explicit and opt-in.
