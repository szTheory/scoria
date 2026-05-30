---
status: clean
phase: 79-tarball-consumer-overlay-proof
reviewed: 2026-05-29
depth: standard
files_reviewed: 6
critical: 0
warning: 0
info: 3
total: 3
---

# Phase 79 Code Review

## Scope

- `test/support/scoria/host_app_proof/generator.ex`
- `test/support/scoria/host_app_proof/runner.ex`
- `test/scoria/host_app_consumer_proof_test.exs`
- `.github/workflows/ci-verify.yml`
- `README.md`
- `docs/operator_verification.md`

## Summary

Phase 79 cleanly completes the Phase 78 tarball seam: merge-blocking adoption now exercises full overlay depth via `run_full_proof!/1`, derives the step contract from sorted overlay basenames, and adds operator-first failure diagnostics (structured triage raise, `SCORIA_PRESERVE_HOST`, workspace snapshot, conditional CI artifact). Implementation matches locked decisions (D-30–D-42) and cross-file contracts with `Scoria.HexConsumerContract`.

## Findings

No Critical or Warning issues identified.

### Info

#### IN-01: `replay_command/3` ignores overlay `args` for route-only debug seam

**File:** `test/support/scoria/host_app_proof/runner.ex` (lines 138–146)

For `:overlay_smoke` failures, `replay_command/3` always replays all `host.overlay_tests`, not the `args` passed to `run_mix!/3`. This is accurate for merge-blocking `run_full_proof!/1` (consumer test) but mismatches `run_route_proof!/1`, which runs a single overlay file. Impact is limited to the documented debug seam (D-33).

**Suggestion:** Derive replay paths from `args` test file entries when `step == :overlay_smoke`, e.g. filter `args` for `"test/" <> _` paths.

#### IN-02: Triage and snapshot paths lack automated regression tests

**Files:** `test/support/scoria/host_app_proof/runner.ex`, `test/support/scoria/host_app_proof/generator.ex`

Failure snapshot, `MANIFEST.txt` fields, nested failure extraction, and `SCORIA_PRESERVE_HOST` cleanup were verified manually during 79-02 (induced overlay failure). No ExUnit coverage guards against regressions in diagnostic output shape. Acceptable for phase scope; consider a focused unit test with stubbed `System.cmd/3` if diagnostics evolve further.

#### IN-03: CI artifact upload is statically wired — runtime confirmation pending

**File:** `.github/workflows/ci-verify.yml` (lines 122–129)

The `upload-artifact@v4` step is correctly placed immediately after the adoption closeout lane with `if: failure()`, `if-no-files-found: ignore`, and a scoped path. First live GHA adoption failure should confirm artifact `scoria-host-proof-last-failure` appears when a snapshot exists (noted in 79-VERIFICATION.md).

## Positive Observations

- **Derived step SSOT:** `expected_steps/1` shared between runner and consumer test prevents hardcoded seven-tuple drift when overlay files change.
- **Security hygiene:** Triage and MANIFEST omit `SCORIA_DB_PASSWORD` per T-79-06; only host/port/username surfaced.
- **Fail-safe snapshot:** `maybe_snapshot_failure!/3` wraps host copy in try/rescue so triage raise always fires; symlink copy fallback (`File.cp_r!` → `cp -RL`) matches generated Phoenix asset tree behavior.
- **CI placement:** Artifact upload runs only when adoption fails (prior step failure), not on later lane failures — correct scoping for host-proof diagnostics.
- **Docs alignment:** README and `docs/operator_verification.md` accurately describe tarball dep, `--only host_proof`, preserve flag, snapshot path, and CI artifact name.

## Verdict

Clean at standard depth. Phase 79 implementation is coherent, matches plan intent, and closes HEX-CONSUMER-01 with auditable full-overlay tarball proof plus maintainable failure triage.
