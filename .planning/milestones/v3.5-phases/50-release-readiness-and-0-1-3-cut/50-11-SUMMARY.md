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
  - "Treated two separate CI flakes (a duplicate-run eventually()-timeout in Scoria.RuntimeIntegrationTest, and a transient Hex-registry deps.get timeout fetching lazy_html in the nested SupportCopilot gallery lane) as CI infra flakiness rather than new Buckets, and used gh run rerun --failed on each rather than bypassing the gate"
metrics:
  duration: "~55 min"
  completed: 2026-07-11
---

# Phase 50 Plan 11: Release-train re-entry gate Summary

Proved the full local suite green mirroring CI's actual lane topology, pushed the committed Bucket A-G fixes (50-05..50-10) to `origin/main`, found and forward-fixed one previously-undetected ExDoc `--warnings-as-errors` regression, and confirmed `PR #12`'s `ci-gate` is GREEN with `mergeStateStatus: CLEAN` on its final head `be87badd96ec6123748b6edaf37330541cf4586e` — release train handed off to `50-04` Task 2/3.

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
   - **Action:** `gh run rerun 29157968222 --failed` — re-ran only the failed job on the exact same commit (no code change, no bypass, no branch-protection edit). The rerun passed cleanly (`ci-gate` green, `verify-summary` green, `mergeStateStatus: CLEAN`).
6. **Final metadata commit** (`d326b3ca`, this SUMMARY.md + STATE.md + ROADMAP.md) was also pushed to `origin/main` to keep the repo's phase-tracking docs in sync with the code that PR #12 now reflects. This triggered a **third** Release Please refresh (workflow run `29159343360`), moving PR #12's head to `be87badd96ec6123748b6edaf37330541cf4586e`.
7. **Third CI pass on `be87badd`:** the pull_request-triggered run (`29159392071`) hit one more flake — `Scoria.SupportCopilotGalleryTest "advisory adoption journey"` failed because the nested `examples/support_copilot` project's `mix deps.get` timed out fetching `lazy_html` from the Hex registry (`Failed to fetch record for lazy_html from registry`, `:timeout`) — a transient network flake in the nested-project dependency-resolution step, not a code regression, not related to Buckets A-G or the docs fix (the sibling push-triggered run `29159391155` on the identical commit passed cleanly).
   - **Action:** `gh run rerun 29159392071 --failed` — re-ran only the failed shard on the unchanged commit. The rerun passed cleanly.
8. **Final confirmation:** `gh pr view 12` → `state: OPEN`, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, head `be87badd96ec6123748b6edaf37330541cf4586e`. `gh pr checks 12` → every lane (`policy`, `build`, `test`, `ratchet`, `knowledge`, `connector`, `full-suite 1-4`, `e2e`, `verify-summary`) green on both the pull_request run and the push run; both `ci-gate` entries pass. Command exits 0. No merge, tag, or publish happened at any point (`gh pr view 12 --json state,closed,mergedAt` confirms `OPEN`/`false`/`null` throughout, including after the "Release PR Auto-Merge" workflow ran a no-op success on an earlier, not-yet-green head).

**No merge, tag, or publish was performed.** No branch-protection or CI-topology change was made (D-03 honored).

## Green-Gate Evidence (record for 50-04 handoff)

- **PR #12:** https://github.com/szTheory/scoria/pull/12 — OPEN, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`
- **PR #12 final head:** `be87badd96ec6123748b6edaf37330541cf4586e`
- **Official pull_request CI run (all green after one rerun):** https://github.com/szTheory/scoria/actions/runs/29159392071
- **Sibling push-triggered CI run (green on first pass):** https://github.com/szTheory/scoria/actions/runs/29159391155
- **Release Please refresh runs:** https://github.com/szTheory/scoria/actions/runs/29157544889 (1st refresh, surfaced the docs regression), https://github.com/szTheory/scoria/actions/runs/29157920552 (2nd refresh, on the docs fix — this head was also fully green, see runs `29157968777`/`29157968222`), https://github.com/szTheory/scoria/actions/runs/29159343360 (3rd refresh, on the trailing metadata commit — final green head)

## Explicit Handoff to 50-04

The release train that stalled at `50-04` can now proceed. Resume `50-04-PLAN.md` at:

- **Task 2** — maintainer merges PR #12 through Release Please's normal automerge/manual-merge path (ci-gate is green on `be87badd`), which tags and publishes `0.1.3` to Hex. Note PR #12's head may drift again if any further commit lands on `main` before the maintainer merges (Release Please refreshes on every push) — re-check `gh pr checks 12` immediately before merging.
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

**3. Transient Hex-registry `deps.get` timeout in the nested SupportCopilot gallery lane — re-ran, did not treat as a Bucket**

- **Found during:** Task 2, third CI pass on PR #12 head `be87badd` (after the trailing metadata-commit push triggered a third Release Please refresh)
- **Issue:** `Scoria.SupportCopilotGalleryTest "advisory adoption journey"` runs `mix deps.get` inside the nested `examples/support_copilot` demo project as part of its proof. That `deps.get` failed with `Failed to fetch record for lazy_html from registry (using cache instead)` / `:timeout`, then `** (Mix) Unknown package lazy_html in lockfile` — a transient Hex.pm registry network timeout, not a code or lockfile regression. The sibling push-triggered CI run on the identical commit passed this same lane cleanly on its first attempt, confirming non-determinism rather than a real break.
- **Action:** `gh run rerun 29159392071 --failed` — re-ran only the failed shard on the unchanged commit. It passed on retry.
- **No code or test change** — logged here for visibility only; no bucket, no commit.

## Known Stubs

None. This plan made no application-code changes; the single edit (`guides/maintainers.md`) is a documentation cross-link fix.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were introduced. The one code change was a markdown-link-to-code-span edit in a maintainer-only doc file.

## Self-Check: PASSED

- `guides/maintainers.md` modified as described: FOUND (`git show 37494e54 -- guides/maintainers.md` shows the diff)
- Commit `37494e54` exists: FOUND
- PR #12 green-gate evidence verified live via `gh pr view 12` / `gh pr checks 12` at time of writing, on final head `be87badd96ec6123748b6edaf37330541cf4586e` (see Green-Gate Evidence section above)
- PR #12 confirmed not merged/closed at any point (`state: OPEN`, `closed: false`, `mergedAt: null`)
