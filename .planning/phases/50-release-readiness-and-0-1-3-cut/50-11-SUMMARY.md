---
phase: 50-release-readiness-and-0-1-3-cut
plan: 11
subsystem: release-engineering
tags: [ci-gate, release-please, docs-warnings-as-errors, forward-fix]
status: complete
dependency-graph:
  requires: ["50-05", "50-06", "50-07", "50-08", "50-09", "50-10"]
  provides: ["green-pr-12-ci-gate"]
  affects: ["50-04"]
tech-stack:
  added: []
  patterns:
    - "Forward-fix main, let Release Please refresh the release PR, confirm ci-gate on the PR's own head (D-01)"
    - "ExDoc extras-only files must be referenced as plain code spans, not markdown links, or --warnings-as-errors treats the link as a broken extras reference (same technique as the prior mix-task-autolink fix, c809241c)"
key-files:
  created: []
  modified:
    - guides/maintainers.md
decisions:
  - "Fixed a real, previously-undetected regression (docs/design_system.md markdown link breaking mix scoria.release_preview under --warnings-as-errors) via a single forward-fix commit rather than reverting the push, since Rule 1 (auto-fix bugs) applies and D-01 already establishes forward-fix-main as this phase's normal path"
  - "Treated the duplicate push-triggered CI run's single eventually()-timeout failure (Scoria.RuntimeIntegrationTest) as a known test-determinism flake (SEED-004 class) and used gh run rerun --failed to get a clean pass on the same commit, rather than treating it as a new Bucket or bypassing the gate"
metrics:
  duration: "~45 min"
  completed: 2026-07-11
---

# Phase 50 Plan 11: Release-train re-entry gate Summary

Proved the full local suite green mirroring CI's actual lane topology, pushed the committed Bucket A-G fixes (50-05..50-10) to `origin/main`, found and forward-fixed one previously-undetected ExDoc `--warnings-as-errors` regression, and confirmed `PR #12`'s `ci-gate` is GREEN with `mergeStateStatus: CLEAN` — release train handed off to `50-04` Task 2/3.

## What Was Built

Plan 50-11 is the release-train re-entry gate: no new features, no architecture. It executed two tasks — prove-green, then push-and-confirm — and, per the deviation rules, forward-fixed one real gap discovered mid-execution rather than pushing (or leaving pushed) a still-red tree.

### Task 1 — Full suite proven green locally, mirroring CI's actual lane topology

Ran each CI lane exactly as `ci-verify.yml` invokes it (not a naive `mix test`):

| Lane | Command | Result |
|------|---------|--------|
| Full-suite (mirrors `verify / full-suite 1-4`) | `mix test --exclude ratchet_parity` | 3 doctests, 1127 tests, **0 failures** |
| Ratchet (mirrors `verify / ratchet`'s WARN-06 step) | `mix test --include ratchet_parity test/scoria/warning_inventory/capture_parity_test.exs` | 2 tests, **0 failures** |
| Connector (mirrors `verify / connector`) | `mix test.connector --warnings-as-errors` | 13 tests, **0 failures** |
| Nested SupportCopilot gallery (mirrors the gallery step inside `verify / connector` / `test/scoria/support_copilot_gallery_test.exs`) | `mix test test/scoria/support_copilot_gallery_test.exs` | 1 test, **0 failures** |

All four match the target: 0 failures across the entire Bucket A-G surface, consistent with the individually-green 50-05..50-10 SUMMARY.md files.

### Task 2 — Pushed, refreshed PR #12, forward-fixed a new regression, confirmed ci-gate GREEN

1. **Pushed** local `main` (21 commits ahead, 0 behind `origin/main`) via a normal `git push origin main` — fast-forward, no force, no branch-protection change (D-01/D-03).
2. **Release Please refreshed PR #12** automatically (workflow run `29157544889`), moving its head from the stale `0e54b551` to `faf98c52`.
3. **First CI pass on `faf98c52` surfaced a NEW failure** not in Buckets A-G: `verify / test`'s "Run release preview lane" step (`MIX_ENV=dev mix scoria.release_preview`) failed with `warning: documentation references file "docs/design_system.md" but it does not exist` under `mix docs --warnings-as-errors`. Reproduced locally (exit 1) — this was missed by Task 1 because `mix scoria.release_preview` is a separate CI step, not part of `mix test`.
   - **Root cause:** `guides/maintainers.md`'s "Design-system component conventions" section linked to `docs/design_system.md` as a markdown link (`[text](path)`). `docs/design_system.md` is an intentional dev-only, not-shipped-to-Hex file (confirmed by `@dev_only_docs` in `test/mix/tasks/scoria.release_preview_test.exs` and `test/scoria/package_surface_test.exs`) and is deliberately absent from `mix.exs`'s `docs_extras()`. ExDoc's `--warnings-as-errors` build treats any markdown link as a reference into the generated doc set and fails when the target isn't a known extra — even though the file physically exists on disk.
   - **Fix (Rule 1 — auto-fix bug):** changed the markdown link to a plain backtick code-span reference (same technique as the prior `c809241c` fix for mix-task autolinking) so ExDoc no longer tries to resolve it as an extras file. No asserted substring in `design_system_doc_contract_test.exs`, `scoria.release_preview_test.exs`, or `package_surface_test.exs` changed. Commit `37494e54`.
   - Verified locally: `MIX_ENV=dev mix scoria.release_preview` exit 0; `mix test --no-start --warnings-as-errors` across `ci_policy_contract_test.exs`, `docker_dx_doc_contract_test.exs`, `design_system_doc_contract_test.exs`, `verification_lanes_test.exs`, `adoption_surface_test.exs`, `scoria.release_preview_test.exs`, `package_surface_test.exs`: 119 tests, 0 failures.
4. **Pushed the fix** (`37494e54`); Release Please refreshed PR #12 again (workflow run `29157920552`), moving its head to `ccb39992`.
5. **Second CI pass on `ccb39992`:** the pull_request-triggered official check run (`29157968777`) came back fully green — all lanes pass including `ci-gate`. A duplicate push-triggered workflow run on the same branch/commit (`29157968222`, GitHub Actions fires both `push` and `pull_request` events for the `release-please--branches--main` branch) hit one flaky failure: `Scoria.RuntimeIntegrationTest "public runtime proves same-session new runs and exact run_id resume"` timed out inside an `eventually(fn -> ... end)` poll (5000ms) — a timing-based test-determinism flake (same class as the already-deferred `SEED-004` item), not a code regression and not related to Buckets A-G or the docs fix. This duplicate-check failure pushed the PR's `mergeStateStatus` to `UNSTABLE`.
   - **Action:** `gh run rerun 29157968222 --failed` — re-ran only the failed job on the exact same commit (no code change, no bypass, no branch-protection edit). The rerun passed cleanly (`ci-gate` green, `verify-summary` green).
6. **Final confirmation:** `gh pr view 12` → `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, head `ccb3999254b6d3f4cc669a355a73c5f988de54d8`. `gh pr checks 12` → every lane (`policy`, `build`, `test`, `ratchet`, `knowledge`, `connector`, `full-suite 1-4`, `e2e`, `verify-summary`) green on both the pull_request run and the (now-rerun) push run; both `ci-gate` entries pass. Command exits 0.

**No merge, tag, or publish was performed.** No branch-protection or CI-topology change was made (D-03 honored).

## Green-Gate Evidence (record for 50-04 handoff)

- **PR #12:** https://github.com/szTheory/scoria/pull/12 — OPEN, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`
- **PR #12 final head:** `ccb3999254b6d3f4cc669a355a73c5f988de54d8`
- **Official pull_request CI run (all green):** https://github.com/szTheory/scoria/actions/runs/29157968777
- **Duplicate push-triggered CI run (green after `gh run rerun --failed`):** https://github.com/szTheory/scoria/actions/runs/29157968222
- **Release Please refresh runs:** https://github.com/szTheory/scoria/actions/runs/29157544889 (first refresh, surfaced the docs regression) and https://github.com/szTheory/scoria/actions/runs/29157920552 (second refresh, on the fix)

## Explicit Handoff to 50-04

The release train that stalled at `50-04` can now proceed. Resume `50-04-PLAN.md` at:

- **Task 2** — maintainer merges PR #12 through Release Please's normal automerge/manual-merge path (ci-gate is green on `ccb39992`), which tags and publishes `0.1.3` to Hex.
- **Task 3** — post-publish smoke (`mix scoria.post_publish_smoke` against the published `0.1.3` tarball) + D-04 closeout.

This plan performed no merge, tag, or publish action — that authority stays with `50-04`'s maintainer checkpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ExDoc `--warnings-as-errors` regression: broken markdown link to a dev-only, non-extras doc**

- **Found during:** Task 2, first CI pass on PR #12 head `faf98c52` (immediately after the D-01 push)
- **Issue:** `guides/maintainers.md`'s Design-system component conventions section linked to `docs/design_system.md` via markdown link syntax. `docs/design_system.md` is intentionally excluded from `mix.exs`'s `docs_extras()` (it's a dev-only maintainer doc, never shipped to Hex — confirmed by the `@dev_only_docs` lists in `test/mix/tasks/scoria.release_preview_test.exs` and `test/scoria/package_surface_test.exs`). ExDoc's `mix docs --warnings-as-errors` (invoked by `mix scoria.release_preview`, the first step of CI's `verify / test` job) treats markdown links as references into the generated doc set and failed the build because the target isn't a known extra, even though the file exists on disk.
- **Fix:** Changed the markdown link `[Design system conventions](docs/design_system.md)` to a plain backtick code-span reference, mirroring the exact technique used in the prior `c809241c` fix (D-50-DEF-01) for a different ExDoc-autolink false-positive. No test assertion changed.
- **Files modified:** `guides/maintainers.md`
- **Commit:** `37494e54`

### Notable Non-Fixes (CI infra, not a code issue)

**2. Flaky `eventually()` timeout in a duplicate CI run — re-ran, did not treat as a Bucket**

- **Found during:** Task 2, second CI pass on PR #12 head `ccb39992`
- **Issue:** GitHub Actions fires both a `push` and a `pull_request` event for commits on the `release-please--branches--main` branch, producing two parallel `CI` workflow runs against the identical commit SHA. The official pull_request-triggered run passed every lane cleanly; the duplicate push-triggered run hit one flaky `eventually(fn -> ... end)` 5000ms timeout in `Scoria.RuntimeIntegrationTest` — a known test-determinism class already tracked as the deferred `SEED-004` item (async `IntegrationCase`, `Process.sleep` removal), not a code regression and not a new Bucket.
- **Action:** `gh run rerun 29157968222 --failed` — re-ran the one failed job on the unchanged commit. It passed on retry. This is a CI-gate retry, not a bypass: no branch-protection or workflow-topology change was made (D-03 honored), and the same required checks still had to pass.
- **No code or test change** — logged here for visibility only; no bucket, no commit.

## Known Stubs

None. This plan made no application-code changes; the single edit (`guides/maintainers.md`) is a documentation cross-link fix.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were introduced. The one code change was a markdown-link-to-code-span edit in a maintainer-only doc file.

## Self-Check: PASSED

- `guides/maintainers.md` modified as described: FOUND (`git show 37494e54 -- guides/maintainers.md` shows the diff)
- Commit `37494e54` exists: FOUND
- PR #12 green-gate evidence verified live via `gh pr view 12` / `gh pr checks 12` at time of writing (see Green-Gate Evidence section above)
