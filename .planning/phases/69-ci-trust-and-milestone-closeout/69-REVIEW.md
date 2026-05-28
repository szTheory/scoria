---
status: issues
phase: 69-ci-trust-and-milestone-closeout
reviewed: 2026-05-28
depth: standard
files_reviewed: 6
critical: 0
warning: 1
info: 2
total: 3
---

# Phase 69 Code Review

## Scope

Reviewed source files from phase 69 SUMMARY artifacts (plans 69-00 through 69-02). Planning artifacts excluded per workflow D-03 unless cross-cutting issues found.

**Focus areas:** CI-03 maintainer trust (operator doc, ci.yml comments, contract anchors), 68-REVIEW WR-01/WR-02 ratchet tmp hygiene remediations, subprocess ratchet→inventory integration test.

**Files reviewed (6):**

| Area | Files |
|------|-------|
| Operator / CI docs | `docs/operator_verification.md`, `.github/workflows/ci.yml`, `README.md` |
| Contract tests | `test/scoria/ci_policy_contract_test.exs` |
| Ratchet hygiene | `lib/mix/tasks/scoria.warning_ratchet.test.ex`, `test/scoria/warning_inventory/tmp_preflight_test.exs` |

**Verification run:** `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/warning_inventory/tmp_preflight_test.exs` — 11 tests, 0 failures (~272s; subprocess ratchet check dominates).

## Findings

### WR-03 [WARNING] Policy failure diagnosis uses `MIX_ENV=test` but CI policy job does not

**Files:** `docs/operator_verification.md` (CI gate map failure diagnosis), `.github/workflows/ci.yml`

**Issue:** Phase 69-00 added failure-diagnosis bullets under `### CI gate map (maintainers)`. For policy compile and lane-contract failures, the doc tells maintainers to run `MIX_ENV=test mix compile --warnings-as-errors` and `MIX_ENV=test mix test --warnings-as-errors ...`. The **policy** job in `ci.yml` runs those commands **without** `MIX_ENV=test` (default `dev`). The gate map’s numbered policy steps correctly omit `MIX_ENV=test` (matching `ci.yml` and `Scoria.CiPolicyContractTest`’s `@compile_wae`).

**Why it matters:** A maintainer debugging a policy-job CI failure may reproduce in `test` while CI failed in `dev`, seeing different warnings or a false pass/fail — undermining the CI-03 “run the matching maintainer command next” goal.

**Remediation:**

- Align failure-diagnosis bullets with CI: `mix compile --warnings-as-errors` and `mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` (no `MIX_ENV=test`), **or**
- Set `MIX_ENV: test` on the policy job in `ci.yml` if test-env compile is the intended WARN-05 surface (would require contract-test and lane-doc sync).

---

### IN-01 [INFO] WARN-06 section still documents manual tmp cleanup for `warning_ratchet.test`

**File:** `docs/operator_verification.md`

**Issue:** Line 233 credits automatic tmp cleanup for `mix scoria.warning_ratchet.check` only. Phase 69-01 added symmetric `ensure_clean_tmp!/0` + `cleanup_transient_tmp!/0` to `Mix.Tasks.Scoria.WarningRatchet.Test`, but WARN-06 prose still implies manual `rm -rf test/tmp/*` before the ratchet chain and does not mention test-task cleanup.

**Why it matters:** Low impact — extra manual step is harmless. Maintainers may still believe `warning_ratchet.test` leaves `test/tmp/` pollution (the 68-REVIEW WR-01 scenario now fixed in code).

**Remediation:** Extend WARN-06 bullet to include `warning_ratchet.test` in the automatic cleanup note, or drop redundant `rm -rf` from the documented chain when preceded by either ratchet command.

---

### IN-02 [INFO] Integration test covers `warning_ratchet.check` only, not `warning_ratchet.test`

**File:** `test/scoria/warning_inventory/tmp_preflight_test.exs`

**Issue:** Subprocess integration test exercises `mix scoria.warning_ratchet.check` → inventory (WR-02 fix). No parallel test for `mix scoria.warning_ratchet.test`, which is the heavier maintainer command in WARN-06 and the WR-01 remediation target.

**Why it matters:** Regression in test-task tmp symmetry would not be caught by the subprocess contract. WR-01 fix is structurally verified by mirroring `check` in source, not by an executable test.

**Remediation:** Optional subprocess test for `scoria.warning_ratchet.test` with a minimal path set, or a focused unit test that simulates fixture dirs and asserts `cleanup_transient_tmp!/0` after the test task’s `after` block.

## Positive observations

- **68-REVIEW WR-01 remediated:** `warning_ratchet.test` mirrors `check` with `ensure_clean_tmp!/0` before work and `cleanup_transient_tmp!/0` in `after`.
- **68-REVIEW WR-02 remediated:** Ratchet→inventory chain uses `System.cmd("mix", ["scoria.warning_ratchet.check"], ...)` so capture is not nested under ExUnit (~272s real capture in verification run).
- **CI-03 doc bundle:** Gate map topology matches `ci.yml` step order; `ci.yml` changes are comments-only; README link is ≤2 lines with stable anchor.
- **Contract anchor:** `CI-03 documents CI gate map for maintainers` follows thin-anchor pattern (D-06) consistent with WARN-06 doc tests.
- **No CI topology drift:** Ratchet commands remain maintainer-only; full-suite WAE ordering unchanged.

## Verdict

**status: issues** — no critical or security blockers; 68-REVIEW maintainer-hygiene warnings are remediated in code. One new documentation warning (policy failure diagnosis `MIX_ENV` mismatch) should be fixed for faithful CI-03 maintainer parity.
