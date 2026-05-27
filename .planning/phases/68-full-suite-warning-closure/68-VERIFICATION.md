# Phase 68 — WARN-07 Closeout Verification

**Verified:** 2026-05-27T23:24:00Z  
**Git SHA:** d875a5e (baseline ledger) + pending CI flip commit  
**Requirement:** WARN-07

## Summary

Full-suite warnings-as-errors gate is green locally with CI parity (`SCORIA_DB_PORT=55432`). CI test job runs `mix test --warnings-as-errors` after closeout lanes; staged ratchet step removed. Baseline ledger rows moved to **Resolved During v2.6**; inventory JSON `"clusters": {}`.

## Command Evidence

### `mix scoria.warning_baseline.check`

```
==> Warning baseline check passed
```

### `MIX_ENV=test mix compile --warnings-as-errors`

Exit code: 0 (no compiler warnings)

### `MIX_ENV=test mix test --warnings-as-errors`

```
Finished in 43.7 seconds (0.9s async, 42.8s sync)
3 doctests, 457 tests, 0 failures (13 excluded)
```

Exit code: 0

Environment: `SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432`

### `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs`

```
Finished in 0.02 seconds (0.02s async, 0.00s sync)
6 tests, 0 failures
```

Exit code: 0

### `MIX_ENV=test mix scoria.warning_inventory --write --scope full`

```
==> Capturing compile + test warning output
==> Wrote .planning/warning-inventory.baseline.json
Warning inventory (full, 0 clusters)
```

Exit code: 0

### Policy job parity (canonical lanes)

```
MIX_ENV=test mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

Both exit 0 — WARN-05 regression preserved.

## CI Contract

`.github/workflows/ci.yml` test job:

- Contains: `run: mix test --warnings-as-errors`
- Does not contain: `mix scoria.warning_ratchet.test --warnings-as-errors`
- Order: `runtime_to_handoff` → full WAE → `mix test.knowledge`

## Path Taken

**Path A (full success):** Both Accepted baseline rows resolved; no renewed full-suite umbrella catch-all (D-11).

## Deviations from Plan

- **Installer subprocess build isolation:** `MIX_BUILD_PATH` for install fixture subprocesses changed from `_build/test` to `_build/install_subprocess` — root cause of host_app_consumer_proof `:nofile` mid-suite (not LiveView warnings).
- **Nested inventory capture:** `WarningInventory.capture_output/0` returns empty output when called inside ExUnit (parent suite is the WAE gate).
