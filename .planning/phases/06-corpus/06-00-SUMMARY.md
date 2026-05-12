# Phase 06 Plan 00: pgvector Bootstrap and Knowledge Test Scaffold Summary

## Summary
Added the explicit pgvector prerequisite slice for Phase 6 so vector-backed work no longer depends on a hidden local database assumption. The repo now ships a bootstrap task, a committed pgvector compose asset, and a shared knowledge test case that fails loudly until the prerequisite is satisfied.

## Delivered
- Added `Mix.Tasks.Scoria.Pgvector.Bootstrap` with `--check` verification and Docker-based local provisioning guidance.
- Added `dev/pgvector-compose.yml` and `dev/pgvector-init.sql` to boot a pgvector-capable local Postgres with both `scoria_dev` and `scoria_test`.
- Added `Scoria.KnowledgeCase` as the shared vector-backed test foundation.
- Updated `test/test_helper.exs` to load the knowledge case and apply pgvector runtime env setup before Phase 6 tests run.

## Verification
- `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres SCORIA_DB_NAME=scoria_dev mix scoria.pgvector.bootstrap --check`

## Notes
- The default local database on `localhost:5432` still does not provide the `vector` extension; the intended Phase 6 verification target is the bundled service on `localhost:55432`.
