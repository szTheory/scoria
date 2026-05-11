---
phase: 07-seismograph
plan: 06
subsystem: sre
tags: [sre, budgets, breakers, ecto]
requires: [07-01]
provides: [SRE-01, SRE-08]
affects:
  - priv/repo/migrations/20260511170000_create_sre_budget_and_breaker_tables.exs
  - lib/scoria/sre.ex
  - lib/scoria/sre/budget_policy.ex
  - lib/scoria/sre/budget_reservation.ex
  - lib/scoria/sre/breaker_trip.ex
  - test/scoria/sre_test.exs
tech_stack:
  added: [ecto]
  patterns: [ecto_multi, optimistic_locking, append_only_evidence]
decisions:
  - Keep budget policy, reservation, and breaker trip writes behind `Scoria.SRE`.
  - Use additive binary-id tables with explicit threshold and evidence columns instead of opaque blobs.
metrics:
  completed_at: 2026-05-11T18:29:00Z
  commits: [e39903f, f82b39a]
---

# Phase 7 Plan 06: Durable SRE Budget And Breaker Persistence Summary

Durable Ecto storage and a narrow `Scoria.SRE` context now exist for budget policies, usage reservations, reconciliation, release, and breaker trip history.

## What Landed

- Added `ai_budget_policies`, `ai_budget_reservations`, and `ai_breaker_trips` with binary IDs, explicit scope and evidence fields, optimistic locking for policies, and the query indexes called for by the plan.
- Added `Scoria.SRE.BudgetPolicy`, `Scoria.SRE.BudgetReservation`, and `Scoria.SRE.BreakerTrip` schemas with focused changeset validation.
- Replaced the Phase 7 SRE stubs with public persistence helpers in `Scoria.SRE` for policy CRUD, reservation creation, reservation reconciliation, reservation release, and breaker trip recording. Reservation and state transitions use `Ecto.Multi`.
- Expanded `test/scoria/sre_test.exs` to cover the durable schemas, public helper surface, sink behavior, and the reservation lifecycle.

## Verification

- `MIX_ENV=test mix test test/scoria/sre_test.exs`
  Result: passed, 9 tests, 0 failures.
- Acceptance criteria checks:
  - PASS `rg -n "create table\\(:ai_budget_policies|create table\\(:ai_breaker_trips" priv/repo/migrations/20260511170000_create_sre_budget_and_breaker_tables.exs`
  - PASS `rg -n "field :estimated_units|field\\(:estimated_units" lib/scoria/sre/budget_reservation.ex`
  - PASS `rg -n "field :breaker_key|field\\(:breaker_key" lib/scoria/sre/breaker_trip.ex`
  - PASS `rg -n "Ecto\\.Multi|def create_budget_policy\\(|def reserve_usage\\(|def reconcile_usage\\(|def record_breaker_trip\\(" lib/scoria/sre.ex`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Pending knowledge migration requires pgvector**
- **Found during:** verification
- **Issue:** `MIX_ENV=test mix ecto.migrate` attempted to run the earlier pending `20260511000300_create_knowledge_tables.exs` migration, which failed because the local PostgreSQL instance does not have the `vector` extension control file installed.
- **Fix:** Applied only the owned SRE migration version directly with `Ecto.Migrator.up/4`, then ran the plan's scoped SRE test file.
- **Files modified:** none
- **Verification:** `MIX_ENV=test mix test test/scoria/sre_test.exs`
- **Commit:** not applicable

**2. [Rule 2 - Execution Shape] Combined green implementation across both plan tasks**
- **Found during:** task execution
- **Issue:** the plan uses one shared SRE test file and one shared verification command for both tasks, so the green implementation had to land as one coherent persistence slice for the scoped test file to pass.
- **Fix:** Kept the TDD red commit separate, then landed the durable migration, schemas, and `Scoria.SRE` helper implementation together in one feature commit.
- **Files modified:** `priv/repo/migrations/20260511170000_create_sre_budget_and_breaker_tables.exs`, `lib/scoria/sre.ex`, `lib/scoria/sre/budget_policy.ex`, `lib/scoria/sre/budget_reservation.ex`, `lib/scoria/sre/breaker_trip.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/sre_test.exs`
- **Commit:** `f82b39a`

**Total deviations:** 2 auto-fixed. **Impact:** no functional scope expansion; one verification workaround was required because of an unrelated local database prerequisite.

## Known Stubs

None.

## Self-Check: PASSED

- Found `.planning/phases/07-seismograph/07-06-SUMMARY.md`
- Found commit `e39903f`
- Found commit `f82b39a`
