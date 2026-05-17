---
phase: 14-policy-defaults-and-install-ergonomics
status: passed
verified_on: 2026-05-16
verified_by_phase: 17-re-verify-keystone-defaults-and-adoption-surface
---

# Phase 14 Verification Report

## Goal Achievement
Phase 14 now has its canonical verification artifact in the original phase directory, backfilled on 2026-05-16 by Phase 17. The primary proof remains requirement-mapped targeted defaults/install seams for `POLY-01` through `POLY-03`, while the fresh full-suite rerun is recorded only as secondary regression hygiene.

## Requirements Coverage
| Requirement | Status | Public seam | Primary proof command |
|-------------|--------|-------------|-----------------------|
| `POLY-01` | Passed | `Scoria.PromptPolicy` normalization and `Scoria.Runtime.Defaults` expose one application-facing defaults surface | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs` |
| `POLY-02` | Passed | Runtime defaults compose with tenant/actor identity and survive the public runtime path into durable metadata | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime/defaults_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs` |
| `POLY-03` | Passed | The default install lane keeps `/scoria` working without forcing the optional knowledge lane, while the explicit knowledge and migration seams stay separate | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs` |
| `POLY-03` | Passed | The core-vs-knowledge migration boundary and explicit knowledge verification command remain repeatable and opt-in | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs test/mix/tasks/scoria.test_knowledge_test.exs` |

The targeted commands above are the canonical requirement proof. The stitched targeted rerun and the fresh `SCORIA_DB_PORT=55432 MIX_ENV=test mix test` pass are secondary confidence evidence only.

## Test Evidence
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs`
- Result: `5 tests, 0 failures`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/runtime/defaults_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs`
- Result: `12 tests, 0 failures`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs`
- Result: `3 tests, 0 failures`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs test/mix/tasks/scoria.test_knowledge_test.exs`
- Result: `3 tests, 0 failures`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs test/scoria/runtime_test.exs test/scoria/runtime_integration_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/scoria/bootstrap/migration_lane_compatibility_test.exs test/mix/tasks/scoria.test_knowledge_test.exs`
- Result: `20 tests, 0 failures`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test`
- Result: `167 tests, 0 failures (13 excluded)`

## Evidence Chain Notes
- Phase 17 writes this file into `.planning/phases/14-policy-defaults-and-install-ergonomics/` so Phase 14 regains a normal validation -> verification closeout chain in its own directory.
- `14-VALIDATION.md` remains the execution ledger; this report is the canonical verification record tying `POLY-01` through `POLY-03` to exact proof commands after the 2026-05-16 reruns.
- The original Phase 14 plan summaries remain historical execution breadcrumbs. This file is the chronology-aware backfill that restores present-tense canonical proof without rewriting that history.
- The full-suite pass is documented only as secondary regression hygiene, so requirement closure still points to the targeted defaults/install seams instead of a monolithic green suite.

## Automated Install-to-Run Closure
- `test/mix/tasks/scoria.install_test.exs` proves the installer writes the default runtime config and dashboard mount.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` proves the installed router resolves `/scoria` and `/scoria/workflows/:run_id`.
- `test/scoria/runtime_integration_test.exs` proves one real run can be started, read back by exact `run_id`, resumed in place, and observed on the operator route with matching status.
- Together these tests supersede the former manual walkthrough and give `POLY-03` a repeatable CI-safe adopter-visible proof lane.

## Residual Risks
- Verification assumes the repo's supported Postgres service on `55432`; reruns against a different port or mismatched compiled artifacts will need matching env before the same commands stay truthful.
