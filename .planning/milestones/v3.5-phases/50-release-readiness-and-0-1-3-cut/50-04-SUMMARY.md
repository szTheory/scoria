---
phase: 50-release-readiness-and-0-1-3-cut
plan: 04
subsystem: release-engineering
tags: [release, hex, release-please, post-publish-smoke, rel-04, d-04]

requires:
  - phase: 50-11
    provides: "green ci-gate on PR #12 (CLEAN/MERGEABLE, head be87badd) — release-train re-entry gate passed"
provides:
  - "0.1.3 cut: PR #12 merged, v0.1.3 tagged, published to Hex, post-publish registry attest green"
  - "REL-04 satisfied; ROADMAP SC4 + SC5 met; D-04 closeout evidence captured"
affects: [milestone-v3.5-complete]

key-decisions:
  - "Squash-merged PR #12 (repo allows squash/merge/rebase); Release Please treats the squashed release commit as the release trigger and tagged v0.1.3 on the merge commit (D-01 normal path, no emergency hex-publish.yml recovery needed per D-02, no branch-protection/topology change per D-03)."
  - "Post-publish smoke ran as the canonical CI 'Post-publish registry attest / Registry consumer' job inside the Release Please chain (workflow_call SSOT), not a local re-run — the local invocation needs the CI job's DB + phx_new archive env. The CI job is the authoritative fresh-install + live-lineage (0.1.0 -> 0.1.3) proof (D-04)."

requirements-completed: [REL-04]

coverage:
  - id: D1
    description: "PR #12 reaches green ci-gate and merges through Release Please (REL-04, ROADMAP SC4)"
    requirement: "REL-04"
    verification:
      - kind: manual_procedural
        ref: "gh pr view 12 -> CLEAN/MERGEABLE on head be87badd; squash-merged (merge commit b904c22a); Release Please run 29162646314 tagged v0.1.3 + 'Publish to Hex.pm' job success"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hex lists 0.1.3 and post-publish smoke proves fresh install + live-lineage upgrade (REL-04, ROADMAP SC5)"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "curl https://hex.pm/api/packages/scoria/releases/0.1.3 -> HTTP 200 (has_docs, full requirements, inserted 2026-07-11T18:10:45Z)"
        status: pass
      - kind: integration
        ref: "Release Please run 29162646314 'Post-publish registry attest / Registry consumer' job -> completed/success (SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke, fresh install + 0.1.0->0.1.3 lineage)"
        status: pass
    human_judgment: false

duration: ~16min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 04: Release cut — 0.1.3 published (REL-04 closeout) Summary

**Cut the 0.1.3 release: squash-merged the green PR #12, Release Please tagged `v0.1.3` and published to Hex, and the canonical post-publish registry attest passed — REL-04 satisfied, milestone v3.5 complete.**

## Performance

- **Duration:** ~16 min (merge 18:00Z → Hex 200 at 18:10:55Z → attest success ~18:16Z)
- **Completed:** 2026-07-11
- **Tasks:** 3 (Task 1 read-only confirm; Task 2 maintainer merge/publish; Task 3 post-publish smoke + D-04 closeout)

## Accomplishments

- **Task 1 — ci-gate confirm (read-only):** Re-verified PR #12 immediately pre-merge: `state: OPEN`, `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN`, head `be87badd`. Every verify lane green on both the pull_request and push runs (`policy`, `build`, `test`, `ratchet`, `knowledge`, `connector`, `full-suite 1-4`, `e2e`, `verify-summary`); both `ci-gate` entries pass.
- **Task 2 — maintainer merge + publish:** Squash-merged PR #12 (`gh pr merge 12 --squash`) → merge commit `b904c22a`. Release Please (run `29162646314`) ran the full chain green: CI Verify lanes → "Verify CI green on release SHA" → tagged `v0.1.3` + published the GitHub Release (not draft, `publishedAt 2026-07-11T18:00:23Z`) → "Publish to Hex.pm" job **success**. `hex.pm/api/packages/scoria/releases/0.1.3` → **HTTP 200** (`has_docs: true`, full dependency requirements, inserted `18:10:45Z`).
- **Task 3 — post-publish smoke + D-04 closeout:** The "Post-publish registry attest / Registry consumer" job (SSOT `post-publish-smoke.yml` via `workflow_call`, running `SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke`) completed **success** in run `29162646314` — the fresh-install + live-lineage (`0.1.0 → 0.1.3`) consumer proof. Publish + attest run URL/ID recorded in STATE.md closeout evidence (D-04).

## Green-Release Evidence (D-04)

- **Release Please / publish / attest run:** https://github.com/szTheory/scoria/actions/runs/29162646314 (completed/success — includes Publish to Hex.pm + Post-publish registry attest)
- **Merge commit:** `b904c22aea2464a0439ca451da8f628ab94aa026` (squash of PR #12)
- **Tag / Release:** `v0.1.3` (published 2026-07-11T18:00:23Z, not draft)
- **Hex:** `curl https://hex.pm/api/packages/scoria/releases/0.1.3` → HTTP 200 (inserted 18:10:45Z, has_docs)

## Decisions Made

- Used the normal Release Please path (D-01); no manual `hex-publish.yml` emergency recovery (D-02) was needed and none was used. No branch-protection or workflow-topology change (D-03).
- Squash merge (repo allows squash/merge/rebase); Release Please tagged the squashed release commit correctly.
- Took the CI-run post-publish attest as the authoritative Task 3 proof rather than a local re-run: `mix scoria.post_publish_smoke` needs the CI job's DB + `phx_new` archive env; the local invocation aborted on the dev-env `mix test` guard before the consumer overlay. The CI job runs the identical Mix task in the correct env and passed.

## Deviations from Plan

None. Tasks 1–3 executed exactly as the plan's maintainer checkpoint prescribed; no auto-fix rules invoked.

## User Setup Required

None — `RELEASE_PLEASE_TOKEN` / `HEX_API_KEY` were already configured as GitHub Actions secrets and used by the existing publish workflows.

## Next Phase Readiness

- REL-04 satisfied; this is the last phase in milestone v3.5 (`is_last_phase: true`) — milestone is 100% complete.
- Next: `/gsd-complete-milestone v3.5` to archive.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED
- PR #12 merged: FOUND (merge commit b904c22a, gh pr view 12 state MERGED)
- Tag v0.1.3: FOUND (git ls-remote origin refs/tags/v0.1.3 -> b904c22a)
- Hex 0.1.3: FOUND (HTTP 200)
- Post-publish attest: FOUND (run 29162646314 job success)
