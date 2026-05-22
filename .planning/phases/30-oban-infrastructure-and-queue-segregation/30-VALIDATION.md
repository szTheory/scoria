# Phase 30: Oban Infrastructure & Queue Segregation - Validation

This document records the executable proof inputs for the canonical Phase 30 backfill completed by Phase 35. Requirement closure lives in `30-VERIFICATION.md`.

## Success Criteria 1: Oban is configured with isolated queues for `inference`, `evals`, and `system`.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/oban_config_test.exs
```

**Expected Outcome:**
The test proves the application configuration for Oban includes the required queues (`inference`, `evals`, `system`) and that their defaults match `[system: 10, inference: 20, evals: 50]`.

## Success Criteria 2: Batch insertion of simulated jobs uses `Oban.insert_all` without blocking the Ecto connection pool.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/workflows/batch_enqueue_test.exs
```

**Expected Outcome:**
The test proves `Scoria.Workflows.BatchEnqueue.insert_all/1` inserts the job set through the chunked `Ecto.Multi` path and enqueues the expected jobs successfully.

## Success Criteria 3: Jobs are processed independently based on queue assignment.

**Verification Command:**
```bash
MIX_ENV=test mix test test/scoria/workflows/batch_enqueue_test.exs
```

**Expected Outcome:**
The test proves worker jobs are enqueued onto the correct target queues based on worker configuration, including the `:evals` queue used by the batch enqueue path.

## Canonical Closeout

- `EVAL-01` closes through the explicit queue-configuration proof lane above.
- `EVAL-03` closes through the explicit batch-enqueue proof lane above.
- The canonical requirement closure and backfill chronology are recorded in `30-VERIFICATION.md`.
