---
phase: 50-release-readiness-and-0-1-3-cut
plan: 03
subsystem: infra
tags: [release, hex, hexdocs, exdoc, github-actions, mix, docs-truth]

requires:
  - phase: 50-01
    provides: "restored guides/maintainers.md canonical maintainer content + #hex-release--recovery-maintainers anchor"
  - phase: 48
    provides: "guides/ canonical doc ladder replacing docs/*.md compatibility stubs"
provides:
  - "Four workflow header comments repointed from retired docs/*.md stub paths to guides/maintainers.md"
  - "post_publish_smoke moduledoc example version refreshed 0.1.1 -> 0.1.3 (D-13)"
  - "mix.exs @hexdocs_url switched to per-package HexDocs subdomain form (D-14)"
affects: [50-04, release-readiness, hexdocs, package-metadata]

tech-stack:
  added: []
  patterns:
    - "Package docs metadata uses the 2026 per-package HexDocs subdomain form (https://scoria.hexdocs.pm)"

key-files:
  created:
    - .planning/phases/50-release-readiness-and-0-1-3-cut/deferred-items.md
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - .github/workflows/ci.yml
    - .github/workflows/ci-verify.yml
    - lib/mix/tasks/scoria.post_publish_smoke.ex
    - mix.exs

key-decisions:
  - "Left main @version at 0.1.2 (Release Please owns the 0.1.3 bump per D-12); README/manifest untouched (already correct)"
  - "@release_docs_url kept as the derived #{@hexdocs_url}/#{@version} expression; recomposes correctly against the new subdomain base"
  - "release_preview WAE docs gate is RED due to a plan-01 regression in guides/maintainers.md (out of plan-03 scope) — surfaced as a deferred blocker rather than absorbed"

patterns-established:
  - "Maintainer-doc cross-references in release automation point at guides/maintainers.md (canonical), not docs/*.md compatibility stubs"

requirements-completed: [REL-03]

coverage:
  - id: D1
    description: "Four workflow header comments repointed from retired docs/MAINTAINERS.md / docs/operator_verification.md stub paths to guides/maintainers.md"
    requirement: "REL-03"
    verification:
      - kind: automated_ui
        ref: "grep -rn 'docs/MAINTAINERS.md\\|docs/operator_verification.md' .github/workflows/ (no matches)"
        status: pass
    human_judgment: false
  - id: D2
    description: "post_publish_smoke moduledoc example refreshed SCORIA_REGISTRY_VERSION 0.1.1 -> 0.1.3; 0.1.0 example + required-env error preserved"
    requirement: "REL-03"
    verification:
      - kind: automated_ui
        ref: "grep -n 'SCORIA_REGISTRY_VERSION=0.1.1' lib/mix/tasks/scoria.post_publish_smoke.ex (no matches); 0.1.0 example present"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix.exs @hexdocs_url uses the per-package HexDocs subdomain form (https://scoria.hexdocs.pm); @version stays 0.1.2"
    requirement: "REL-03"
    verification:
      - kind: automated_ui
        ref: "grep -n '@hexdocs_url' mix.exs -> https://scoria.hexdocs.pm; grep -n '@version' -> 0.1.2"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test test/scoria/adoption_surface_test.exs (29 tests, 0 failures — stale-version refute stays green)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Plan verification gate: MIX_ENV=dev mix scoria.release_preview builds clean (docs warnings-as-errors)"
    requirement: "REL-03"
    verification:
      - kind: integration
        ref: "MIX_ENV=dev mix scoria.release_preview (exits 1: 3 'reference to a filtered module' warnings in guides/maintainers.md:43,57,58)"
        status: fail
    human_judgment: true
    rationale: "Pre-existing regression introduced by plan 50-01 (commit 25ad5233) in guides/maintainers.md — OUTSIDE plan 03's files_modified scope. Two bounded in-scope mix.exs fix attempts (skip_code_autolink_to) failed because ExDoc's filtered-module warning is a separate code path. Fix belongs in guides/maintainers.md or ExDoc config as a plan-01 follow-up / plan-04 pre-step. See deferred-items.md D-50-DEF-01. Blocks plan 50-04 must-have #1."

duration: 15min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 03: REL-03 Version/Docs-Truth Polish Summary

**Repointed four release-automation header comments to guides/maintainers.md, refreshed the post-publish-smoke example to 0.1.3, and moved @hexdocs_url to the per-package HexDocs subdomain form — while surfacing a pre-existing plan-01 docs-gate regression that blocks the 0.1.3 release preview.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-11
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 6 (+1 created: deferred-items.md)

## Accomplishments

- Repointed 4 workflow header comments from retired `docs/MAINTAINERS.md` / `docs/operator_verification.md` compatibility-stub paths to `guides/maintainers.md` (release-please.yml + hex-publish.yml at the `#hex-release--recovery-maintainers` anchor; ci.yml + ci-verify.yml at the CI gate map narrative). Comment-only — no CI job/step/needs/matrix/trigger change (D-03).
- Refreshed the `scoria.post_publish_smoke` moduledoc example `SCORIA_REGISTRY_VERSION=0.1.1` -> `0.1.3` (D-13), keeping the adjacent `0.1.0` example and the required-env error message (`0.1.0`) intact.
- Switched `mix.exs` `@hexdocs_url` from the old path form `https://hexdocs.pm/scoria` to the per-package subdomain form `https://scoria.hexdocs.pm` (D-14); `@release_docs_url` recomposes correctly against the new base; `@version` unchanged at `0.1.2` (D-12).
- Discovered and surfaced a release blocker: the `mix scoria.release_preview` docs warnings-as-errors gate is RED due to a plan-01 regression in `guides/maintainers.md` (not plan-03's scope) — logged to `deferred-items.md` for a targeted follow-up.

## Task Commits

Each task was committed atomically:

1. **Task 1: Repoint workflow header comments + refresh smoke example version** - `6692d93e` (docs)
2. **Task 2: Update mix.exs @hexdocs_url to per-package subdomain form** - `e151a502` (docs)

_(Plan metadata commit follows this SUMMARY.)_

## Files Created/Modified

- `.github/workflows/release-please.yml` - Header comment -> guides/maintainers.md#hex-release--recovery-maintainers
- `.github/workflows/hex-publish.yml` - Header comment -> guides/maintainers.md#hex-release--recovery-maintainers
- `.github/workflows/ci.yml` - Maintainer narrative comment -> guides/maintainers.md (CI gate map + flake policy)
- `.github/workflows/ci-verify.yml` - Maintainer narrative comment -> guides/maintainers.md (CI gate map + flake policy)
- `lib/mix/tasks/scoria.post_publish_smoke.ex` - Moduledoc example version 0.1.1 -> 0.1.3
- `mix.exs` - `@hexdocs_url` -> `https://scoria.hexdocs.pm`
- `.planning/phases/50-release-readiness-and-0-1-3-cut/deferred-items.md` - Logged the out-of-scope release_preview WAE regression (D-50-DEF-01)

## Decisions Made

- Kept `main` `@version` at `0.1.2` and left README/`.release-please-manifest.json` untouched (already correct per RESEARCH) — Release Please owns the `0.1.3` bump on the release branch (D-12).
- Kept `@release_docs_url` as the derived `#{@hexdocs_url}/#{@version}` expression rather than hardcoding — it recomposes correctly against the new subdomain base.
- Did NOT absorb the plan-01 `guides/maintainers.md` docs-gate regression into plan 03. It is outside plan 03's `files_modified`, and two bounded in-scope `mix.exs` fix attempts proved ExDoc's filtered-module warning cannot be suppressed via `skip_code_autolink_to`. Surfaced as a deferred blocker instead.

## Deviations from Plan

None - plan executed exactly as written for its two enumerated tasks. Both substantive changes match the plan actions and acceptance criteria. (The release_preview gate failure below is a pre-existing, out-of-scope regression, not an unplanned auto-fix.)

## Issues Encountered

**`mix scoria.release_preview` docs warnings-as-errors gate is RED (release blocker — deferred).**

- **Symptom:** `mix docs` (invoked by `scoria.release_preview`) fails under `--warnings-as-errors` with 3 identical `reference to a filtered module` warnings at `guides/maintainers.md:43,57,58`.
- **Root cause:** Those lines reference maintainer-only Mix tasks in backtick code font (`mix scoria.warning_ratchet.test`, `mix test.adoption`, `mix scoria.post_publish_smoke`). ExDoc 0.40.3 resolves them to their task modules, which are intentionally excluded from the public docs surface via `filter_modules`, and warns.
- **Attribution:** Introduced by plan 50-01 commit `25ad5233` (restoring maintainer content). RESEARCH.md (lines 74, 110) confirms release_preview + `mix docs --warnings-as-errors` built clean at research time, so this is a post-plan-01 regression — NOT caused by any plan-03 change. Proven: the failure is byte-identical with and without the plan-03 `@hexdocs_url` edit.
- **Resolution attempts (bounded, reverted):** Added the resolved module names, then the bare task strings, to `mix.exs` `docs_code_autolink_skips/0`. Neither cleared the warning — ExDoc's filtered-module warning is a separate path from `skip_code_autolink_to`. Both attempts reverted; `mix.exs` carries only the `@hexdocs_url` change.
- **Handling:** Out of plan-03 scope (target file is `guides/maintainers.md`, plan 01's). Logged to `deferred-items.md` as `D-50-DEF-01`. This BLOCKS plan 50-04 must-have truth #1 and must be fixed (in `guides/maintainers.md` or ExDoc config) before the `0.1.3` release preview can pass. Note: docs still GENERATE (`doc/index.html`, `doc/llms.txt`); only the WAE gate trips.

## User Setup Required

None - no external service configuration required for this plan (plan 50-04 owns the maintainer merge/publish setup).

## Next Phase Readiness

- REL-03 version/docs-truth polish is complete: workflow comments, smoke example version, and package docs URL all consistent with the live `0.1.2` baseline and `0.1.3` target; `adoption_surface_test` stays green (29/0); no stale `0.1.1` remains in `lib/mix/tasks/`, `.github/workflows/`, or `mix.exs`.
- **Blocker for plan 50-04:** `mix scoria.release_preview` / `mix docs --warnings-as-errors` are RED on tip of main due to `D-50-DEF-01` (plan-01 `guides/maintainers.md` filtered-module references). Plan 50-04's first read-only gate ("confirm release preview + docs build clean") will fail until this is fixed. Recommend a small plan-01 follow-up (or a plan-04 pre-step) to rewrite the three `mix <maintainer-task>` references so ExDoc does not autolink them.

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED

- All 6 modified files present + deferred-items.md and 50-03-SUMMARY.md created.
- Both task commits present in git log: `6692d93e`, `e151a502`.
