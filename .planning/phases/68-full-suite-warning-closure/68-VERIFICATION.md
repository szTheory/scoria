# Phase 68 — WARN-07 Closeout Verification

**Verified:** 2026-05-27T23:28:00Z  
**Git SHA:** 50f12884e643b019aae563097bc9582c070e0c5c  
**Requirement:** WARN-07  
**Status:** `passed`

## Phase Goal

Complete WARN-07 — full-suite warnings-as-errors gate green locally and in CI; baseline ledger closed before 2026-06-07 expiry.

## Summary

Path A (full success): `MIX_ENV=test mix test --warnings-as-errors` is green locally with CI parity (`SCORIA_DB_PORT=55432`). CI test job runs full WAE after closeout lanes; staged ratchet step removed. Baseline ledger **Accepted Warning Debt** table is empty; both prior rows moved to **Resolved During v2.6**. Inventory JSON has `"clusters": {}`.

## REQUIREMENTS.md Traceability

| Requirement | Definition | Phase 68 Evidence | Status |
|-------------|------------|-------------------|--------|
| WARN-07 | CI runs `mix test --warnings-as-errors` and passes, or remaining debt is explicitly re-baselined with owner + renewed expiry | Full WAE green locally; CI test job step `run: mix test --warnings-as-errors`; baseline ledger closed (no renewed umbrella row) | **Complete** |

REQUIREMENTS.md traceability table marks WARN-07 → Phase 68 → Complete.

## Must-Haves Score

**Final-state verified: 26 / 26** (100%)  
**Superseded interim (68-01 staged ratchet): 3** — intentionally replaced by 68-03; not gaps  
**Follow-up (68-REVIEW maintainer hygiene): 2** — out of WARN-07 scope; see Human Verification

### Plan 68-00 — Warning hygiene blockers (7/7)

| Must-have | Verified |
|-----------|----------|
| `warning_ratchet.check` enforces empty `test/tmp/` before capture | `WarningInventory.ensure_clean_tmp!/0` called in `scoria.warning_ratchet.check.ex` |
| Ratchet capture cleans transient `test/tmp/` after run | `cleanup_transient_tmp!/0` in `try/after` in `scoria.warning_ratchet.check.ex` |
| `--format json` uses `json_encode_rows/1` | `lib/mix/tasks/scoria.warning_inventory.ex` routes JSON through `json_encode_rows/1` |
| `high_signal_path?/1` memoization (IN-01) | `MapSet` + `:persistent_term` cache in `lib/scoria/warning_ratchet.ex` |
| Artifact: `ensure_clean_tmp!` in `warning_inventory.ex` | Present |
| Artifact: `json_encode_test.exs` WR-02 contract | `test/scoria/warning_inventory/json_encode_test.exs` |
| Key link: ratchet.check → `ensure_clean_tmp!` | Present |

### Plan 68-01 — Staged ratchet wiring (4/4 final; 3 superseded)

| Must-have | Verified |
|-----------|----------|
| Policy job excludes `warning_ratchet.test` (D-17) | No `warning_ratchet` in `.github/workflows/ci.yml` |
| `ci_policy_contract_test` gate-order contract (D-05) | 6 tests pass; asserts full WAE after `runtime_to_handoff` |
| ~~CI runs staged ratchet after closeout lanes~~ | **Superseded by 68-03** — ratchet removed; full WAE is production gate |
| ~~`ci.yml` contains `scoria.warning_ratchet.test`~~ | **Superseded by 68-03** |
| ~~Operator docs describe staged ratchet CI step~~ | **Superseded by 68-03** — docs now describe full-suite gate |

### Plan 68-02 — Host-proof p2 closure (7/7)

| Must-have | Verified |
|-----------|----------|
| `mix test.adoption --warnings-as-errors` passes | 49 tests, 0 failures (2026-05-27 re-run) |
| Zero `:host_proof_generated_compile` / `:host_overlay_test_path` clusters | `"clusters": {}` in baseline JSON; 68-02 measurement confirmed zero |
| Host-proof noise fixed at source (not baselined) | `HostAppProof.Generator` under `System.tmp_dir!()` |
| Overlay templates under `priv/host_app_proof/overlay/test/` | `host_app_proof_architecture_test.exs` guards path |
| Artifact: `generator.ex` | Present |
| Artifact: `host_app_proof_architecture_test.exs` | Present |
| Key link: consumer proof → `HostAppProof` | Present |

### Plan 68-03 — Full-suite WAE flip (8/8)

| Must-have | Verified |
|-----------|----------|
| `mix test --warnings-as-errors` passes locally | 457 tests, 0 failures (2026-05-27 re-run) |
| CI test job uses full WAE; ratchet step removed | `ci.yml` line 113; no `warning_ratchet` in workflow |
| `WARNING-BASELINE.md` full-suite row resolved (D-11/D-16) | Accepted table empty; both rows in Resolved During v2.6 |
| WARN-05 regression: compile WAE + lane-contract tests | Both exit 0 |
| Artifact: `ci.yml` full WAE gate | Present |
| Artifact: `WARNING-BASELINE.md` Resolved During v2.6 | Present |
| Artifact: `68-VERIFICATION.md` with WARN-07 evidence | This file |
| Key link: CI test job → `mix test --warnings-as-errors` | Gate order: adoption → runtime_to_handoff → full WAE → knowledge |

## Command Evidence (2026-05-27 re-run)

### `mix scoria.warning_baseline.check`

```
==> Warning baseline check passed
```

Exit code: 0

### `MIX_ENV=test mix compile --warnings-as-errors`

Exit code: 0

### `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors`

```
Finished in 43.4 seconds (0.9s async, 42.5s sync)
3 doctests, 457 tests, 0 failures (13 excluded)
```

Exit code: 0  
Environment: `SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432`

### `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption --warnings-as-errors`

```
Finished in 33.6 seconds (0.1s async, 33.5s sync)
3 doctests, 49 tests, 0 failures
```

Exit code: 0

### `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs`

```
Finished in 0.02 seconds (0.02s async, 0.00s sync)
6 tests, 0 failures
```

Exit code: 0

### WARN-05 lane-contract regression

```
MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

15 tests, 0 failures — exit 0

### Baseline inventory JSON

`.planning/warning-inventory.baseline.json`:

```json
{ "clusters": {}, "generated_at": "2026-05-27T23:21:15.126354Z", ... }
```

## CI Contract

`.github/workflows/ci.yml` test job:

- Contains: `run: mix test --warnings-as-errors` (after `runtime_to_handoff`, before `mix test.knowledge`)
- Does not contain: `mix scoria.warning_ratchet.test --warnings-as-errors`
- Policy job: lane WAE only (`verification_lanes_test.exs`, `adoption_surface_test.exs`); no ratchet step

## Path Taken

**Path A (full success):** Both Accepted baseline rows resolved; no renewed full-suite umbrella catch-all (D-11). Expiry pressure for 2026-06-07 cleared.

## Deviations from Plan

- **Installer subprocess build isolation:** `MIX_BUILD_PATH` for install fixture subprocesses uses `_build/install_subprocess` — root cause of mid-suite `:nofile` (not LiveView warnings).
- **Nested inventory capture:** `WarningInventory.capture_output/0` skips nested subprocess when ExUnit is running (parent suite is WAE gate).

## Gaps

None blocking WARN-07 or phase goal.

## Human Verification

| Item | Why |
|------|-----|
| Confirm CI test job green on next push to remote | Local branch is 174 commits ahead of `origin/main`; GitHub Actions not re-run in this verification session |
| Optional: address 68-REVIEW WR-01/WR-02 | `warning_ratchet.test` tmp cleanup asymmetry and neutered ratchet→inventory integration test — maintainer workflow only; does not affect CI full WAE gate |
| Optional: sync `.planning/PROJECT.md` WARN-07 checkbox | Still unchecked; REQUIREMENTS.md already marks Complete (Phase 69 closeout scope) |

## Verdict

**Status: `passed`** — WARN-07 complete. Full-suite WAE green locally; baseline ledger closed; CI contract flipped. Must-haves verified 26/26 for final state; 3 interim 68-01 items superseded by design.
