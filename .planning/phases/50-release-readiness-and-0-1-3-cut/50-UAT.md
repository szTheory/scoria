---
status: complete
phase: 50-release-readiness-and-0-1-3-cut
source: [50-01-SUMMARY.md, 50-02-SUMMARY.md, 50-03-SUMMARY.md, 50-05-SUMMARY.md, 50-06-SUMMARY.md, 50-07-SUMMARY.md, 50-08-SUMMARY.md, 50-09-SUMMARY.md, 50-10-SUMMARY.md, 50-11-SUMMARY.md]
started: 2026-07-11T16:39:51Z
updated: 2026-07-11T18:16:30Z
---

## Current Test

[testing complete]

## Tests

<!-- Automated deliverables: covered by passing CI lanes on PR #12 (ci-gate CLEAN,
     mergeStateStatus CLEAN, live-verified 2026-07-11) + 50-11 local lane runs at the
     current code HEAD. Not presented as manual checkpoints. -->

### 1. REL-01 — Policy lane no longer fails on planning-ledger drift
expected: `verify / policy` lane green; ci_policy_contract_test docs constants point at guides/maintainers.md; v2.15 Connector Adoption Lane breadcrumb preserved.
result: pass
source: automated

### 2. REL-02 — e2e lane browser regressions fixed
expected: `verify / e2e` lane green; dev_seed uses arity-3 tenant-scoped start_release_workflow at both sites; 4 theme-toggle locators use `.filter({ visible: true })`; full e2e 165/0.
result: pass
source: automated

### 3. REL-03 — Version/docs-truth polish
expected: No stale 0.1.1 refs; mix.exs @hexdocs_url = https://scoria.hexdocs.pm, @version 0.1.2; workflow comments point at guides/maintainers.md; adoption_surface_test 29/0; `mix scoria.release_preview` exits 0.
result: pass
source: automated

### 4. Bucket A — docs-source alignment (50-06)
expected: All 7 docs-source cases green (phoenix/handoff/semantic-cache example-source + 4 SupportJourney adopter surfaces) repointed to canonical guides/ SSOT.
result: pass
source: automated

### 5. Bucket B — package/publish surface (50-10)
expected: package_surface_test "one publish surface" asserts https://scoria.hexdocs.pm; single-publish-surface invariant intact.
result: pass
source: automated

### 6. Bucket C — runtime/LiveView rendered contracts (50-07)
expected: seeded-run operator workflow renders the run (tenant-scope aligned); notebook-primitive + incident-evidence contracts repointed; 25/0.
result: pass
source: automated

### 7. Bucket D — UI component / dev-lab contracts (50-08)
expected: ui_component_test maintainer-doc reads repointed to guides/maintainers.md; dev_lab guard #7 reads archived 36-inventory.json; 135/0.
result: pass
source: automated

### 8. Bucket E — SupportCopilot gallery journeys (50-09)
expected: nested gallery knowledge-lane seeds refund policy with tenant scope; approvals proof repointed to current copy; gallery suite 9/0 + parent proof green.
result: pass
source: automated

### 9. Bucket F — warning inventory (50-10)
expected: capture_parity_test green on release head (verify-first, no change needed).
result: pass
source: automated

### 10. Bucket G — DashboardScope mount-halt regression (50-05)
expected: DashboardScope.on_mount/4 fails closed via redirect (not bare-halt) under LiveView 1.1.30; 14 Bucket-G cases green; secret_key_base ≥64 bytes.
result: pass
source: automated

### 11. Release-train re-entry gate — PR #12 ci-gate GREEN (50-11)
expected: Full local suite mirrors CI lane topology 0 failures; PR #12 ci-gate green, mergeStateStatus CLEAN on head be87badd. (Live-reconfirmed this session: ci-gate CLEAN, MERGEABLE.)
result: pass
source: automated

### 12. 0.1.3 release cut & post-publish smoke (REL-04 final leg)
expected: Maintainer merges PR #12 → Release Please tags v0.1.3 + publishes to Hex → `curl .../releases/0.1.3` returns 200 → `mix scoria.post_publish_smoke` proves fresh install + live-lineage upgrade.
result: pass
source: automated
reason: "Cut this session (2026-07-11). PR #12 squash-merged (merge commit b904c22a) → Release Please tagged v0.1.3 + published GitHub Release → 'Publish to Hex.pm' job success → hex.pm lists 0.1.3 (HTTP 200, has_docs, full requirements) → 'Post-publish registry attest' job SUCCESS (Release Please run 29162646314, completed/success). Live-verified: Hex 200 at 18:10:55Z, attest green at 18:16Z."

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
