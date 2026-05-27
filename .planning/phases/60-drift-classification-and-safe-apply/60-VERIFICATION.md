---
phase: 60
slug: drift-classification-and-safe-apply
status: passed
verified_at: 2026-05-27
requirements_verified:
  - INST-06
  - INST-07
---

# Phase 60 Verification

## Score

- Implementation completeness: **10/10**
- Requirement traceability: **10/10**
- Verification execution: **10/10** (automated adoption lane + installer contract tests; overlay template pollution removed)
- Overall phase confidence: **10/10**

## Verified Evidence

### Plan 60-01 must-haves (ownership/drift/remediation contract)

- `lib/scoria/install/manifest.ex` defines manifest APIs required by plan (`path/1`, `load/1`, `write!/2`, `entry_for/2`) and freshness validation via `validate_freshness/2`.
- Surface analyzers encode ownership modes, reason codes, and remediation payloads with `verify_command: "mix scoria.install --check"`.
- `lib/scoria/install/planner.ex` normalizes canonical planner fields and deterministic `{order, id}` ordering.
- `lib/scoria/install/report.ex` renders remediation in human/JSON paths and preserves `SCORIA_CHECK_RESULT` trailer contract.

### Plan 60-02 must-haves (planner-led safe apply)

- Apply path is planner-led with preflight gates and typed operation dispatch.
- Blocked apply performs zero writes for `manual_review` and stale fingerprints.
- Check/apply exit semantics and trailer contract covered by subprocess tests.

### Requirement traceability

| Requirement | Verification evidence | Result |
|-------------|------------------------|--------|
| INST-06 | Planner-led apply + apply_executor tests + adoption lane | Verified |
| INST-07 | Manifest/drift/remediation + install_check contract tests + adoption lane | Verified |

## Verification Commands and Outcomes

- `MIX_ENV=test mix test test/scoria/install/planner_test.exs` -> pass
- `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs` -> pass
- `MIX_ENV=test mix test test/scoria/install/planner_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_route_smoke_test.exs test/mix/tasks/scoria.install_check_test.exs` -> pass (15 tests)
- `MIX_ENV=test mix test.adoption` -> pass (58 tests, includes installer check + planner)
- `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` -> pass (e2e host proof with ownership marker seeding)
- `MIX_ENV=test mix test` -> no host-proof overlay compile pollution (templates moved to `priv/host_app_proof/overlay/test/`)

## Automated replacements for prior human gates

1. **Full-suite overlay compile blocker** — resolved by relocating host-proof overlay templates out of `test/` discovery paths.
2. **Remediation prose quality** — codified in `test/mix/tasks/scoria.install_check_test.exs` (summary, actionable steps, human/JSON parity, no panic artifacts).

## Gaps

None for Phase 60 scope.
