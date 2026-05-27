---
phase: 60
slug: drift-classification-and-safe-apply
status: human_needed
verified_at: 2026-05-27
requirements_verified:
  - INST-06
  - INST-07
---

# Phase 60 Verification

## Score

- Implementation completeness: **10/10**
- Requirement traceability: **10/10**
- Verification execution: **8/10** (phase suites green; full suite still blocked by unrelated compile failure)
- Overall phase confidence: **9.3/10**

## Verified Evidence

### Plan 60-01 must-haves (ownership/drift/remediation contract)

- `lib/scoria/install/manifest.ex` defines manifest APIs required by plan (`path/1`, `load/1`, `write!/2`, `entry_for/2`) and freshness validation via `validate_freshness/2`.
- `lib/scoria/install/surface/router.ex`, `lib/scoria/install/surface/runtime_config.ex`, `lib/scoria/install/surface/tailwind.ex`, and `lib/scoria/install/surface/migrations.ex` encode explicit ownership modes (`:marker_region` / `:structural_set`), reason codes, and remediation payloads with `verify_command: "mix scoria.install --check"`.
- `lib/scoria/install/planner.ex` normalizes canonical planner fields (`operation`, `ownership_mode`, `manifest_key`, `fingerprint`, `drift`, `remediation`) and applies deterministic entry ordering via `Enum.sort_by(&{&1.order, &1.id})`.
- `lib/scoria/install/report.ex` renders remediation payload in both human and JSON output paths and preserves the exact trailer contract `SCORIA_CHECK_RESULT status=<status> exit_code=<exit_code>`.
- `test/scoria/install/planner_test.exs` includes explicit fallback coverage for missing marker ownership -> `manual_review` with remediation reason code + verify command.

### Plan 60-02 must-haves (planner-led safe apply)

- `lib/mix/tasks/scoria.install.ex` apply path builds planner artifact via `Planner.build(..., mode: :apply)`, delegates writes to `Scoria.Install.ApplyExecutor.run/2`, prints canonical report/trailer, and halts with explicit `exit_code`.
- `lib/scoria/install/apply_executor.ex` enforces strict preflight gates (`validate_no_blockers!/1`, `validate_freshness!/2`) before mutation dispatch; operations are planner-typed and ordered by `{order, id}`.
- `lib/scoria/install/apply_executor.ex` persists updated ownership baseline through `Manifest.write!/2` only after successful preflight + dispatch.
- `test/mix/tasks/scoria.install_test.exs` verifies: blocked apply zero-write behavior for `manual_review`, stale-fingerprint blocking before writes, and apply mutates only planner-classified actionable surfaces.
- `test/mix/tasks/scoria.install_check_test.exs` verifies check-mode tri-state exit semantics (`0/1/2`), stable trailer strings, and remediation parity in both human/JSON outputs.

### Requirement traceability

| Requirement | Verification evidence | Result |
|-------------|------------------------|--------|
| INST-06 | Planner-led apply routing in `lib/mix/tasks/scoria.install.ex`; preflight-gated operation dispatch in `lib/scoria/install/apply_executor.ex`; equivalence/zero-write/stale-plan tests in `test/mix/tasks/scoria.install_test.exs` | ✅ Verified |
| INST-07 | Manifest-aware drift/freshness and ownership baseline in `lib/scoria/install/manifest.ex`; explicit drift reason/remediation fields in surface analyzers + planner normalization; remediation/trailer parity tests in `test/scoria/install/planner_test.exs` and `test/mix/tasks/scoria.install_check_test.exs` | ✅ Verified |

## Verification Commands and Outcomes

- `MIX_ENV=test mix test test/scoria/install/planner_test.exs` -> pass (`4 tests, 0 failures`)
- `MIX_ENV=test mix test test/scoria/install/planner_test.exs test/mix/tasks/scoria.install_check_test.exs` -> pass (`6 tests, 0 failures`)
- `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` -> pass (`9 tests, 0 failures`)
- `MIX_ENV=test mix test test/scoria/install/planner_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/mix/tasks/scoria.install_check_test.exs` -> pass (`15 tests, 0 failures`)
- `MIX_ENV=test mix test` -> fail (still hits host-proof overlay compile failure: `ScoriaHostProofWeb.ConnCase` not loaded in `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs`)

## Gaps / Human Verification

- No implementation or requirement-traceability gaps found for Phase 60 scope (`INST-06`, `INST-07`).
- Human follow-up is still required to clear unrelated full-suite compile blocker in host-proof overlay tests before milestone-level "all green" can be claimed.
- Optional manual check from `60-VALIDATION.md` (operator quality of remediation prose) remains a human UX/readability judgment rather than an automated gate.
