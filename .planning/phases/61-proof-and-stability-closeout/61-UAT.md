---
status: complete
phase: 61-proof-and-stability-closeout
source: 61-01-SUMMARY.md, 61-02-SUMMARY.md, 61-03-SUMMARY.md
started: 2026-05-27T15:46:16Z
updated: 2026-05-27T16:30:00Z
---

## Current Test

none — automated coverage complete

## Tests

### 1. Install task help documentation
expected: Run `mix help scoria.install`. Help describes three modes, no-write guarantee for dry-run/check, exit/trailer table, default verify command, and pointer to operator_verification.md.
result: passed
automation: test/scoria/adoption_surface_test.exs (`mix scoria.install task documents three modes and upgrade-safe verification` via Code.fetch_docs).

### 2. Operator-ordered human summary
expected: On a host with mixed install states, `mix scoria.install --dry-run` prints a summary section with operator-ordered counts in this order: would_change, already_present, skipped, manual_review.
result: passed
automation: test/scoria/install/report_test.exs (`render_human prints operator summary keys in contract order`); test/mix/tasks/scoria.install_check_test.exs (`optional_surface_absent` asserts `skipped:` in human output).

### 3. JSON summary_operator field
expected: `mix scoria.install --dry-run --format json` emits `summary_operator` with operator buckets, `schema_version` is string `"1.0"`, and planner `summary` keys unchanged.
result: passed
automation: test/scoria/install/report_test.exs (`render_json includes summary_operator and schema_version 1.0`).

### 4. Check mode never writes
expected: Run `mix scoria.install --check` on a host app. No host files change compared to immediately before the command.
result: passed
automation: test/mix/tasks/scoria.install_check_test.exs (`non_root_browser_only` snapshot); test/mix/tasks/scoria.install_test.exs (dry-run/check snapshot parity).

### 5. SCORIA_CHECK_RESULT trailer
expected: `mix scoria.install --check` prints final line matching `SCORIA_CHECK_RESULT status=<...> exit_code=<0|1|2>`.
result: passed
automation: test/mix/tasks/scoria.install_check_test.exs (tri-state `assert_check_result` table and B-cycle compliant trailer).

### 6. Dry-run and check plan equivalence
expected: On the same host/fixture, normalized plan output is identical between `--dry-run` and `--check`.
result: passed
automation: test/scoria/install/mode_equivalence_test.exs (in-process planner parity); test/mix/tasks/scoria.install_check_test.exs (`dry-run and --check bodies match for compliant host`).

### 7. Upgrade-safe workflow in operator docs
expected: `docs/operator_verification.md` contains upgrade-safe subsection with workflow steps, no-write check, manual_review policy, and trailer format.
result: passed
automation: test/scoria/adoption_surface_test.exs (`operator verification guide documents upgrade-safe installer modes`).

### 8. Adoption lanes cross-reference
expected: `docs/adoption_lanes.md` cross-references installer verification modes with link to operator_verification.md.
result: passed
automation: test/scoria/adoption_surface_test.exs (same test asserts lane_guide pins).

### 9. B-cycle idempotency convergence
expected: Owned fixture dry-run→check→apply→check→apply converges; second apply is no-op / already_present.
result: passed
automation: test/mix/tasks/scoria.install_test.exs (`mix scoria.install B-cycle: dry-run → check → apply → check → apply is idempotent`).

### 10. Adoption lane merge gate
expected: `mix test.adoption` passes including thin INST-08 contract pins.
result: passed
automation: lib/mix/tasks/test.adoption.ex includes report_test.exs, mode_equivalence_test.exs, install_test.exs, install_check_test.exs; CI step `Run adoption closure lane`.

### 11. Maintainer v2.4 closeout chain
expected: Maintainer closeout commands succeed in CI order.
result: passed
automation: .github/workflows/ci.yml (compile WAE, lane-contract tests, release_preview, ecto, test.adoption, test.runtime_to_handoff, mix test, mix test.knowledge).

### 12. Closeout order unchanged
expected: `VerificationLanes.closeout_order/0` returns `[:release_preview, :adoption, :runtime_to_handoff]` only; no `mix test.install_contract` in CI closeout.
result: passed
automation: test/scoria/verification_lanes_test.exs (`closeout chain stays pinned` and `ci lane ordering follows the canonical closeout chain`).

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None — human UAT replaced by adoption lane + installer contract tests + CI closeout chain.
