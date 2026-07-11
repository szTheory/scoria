---
phase: 49-ai-accessible-docs-and-docs-verification-gate
plan: 02
subsystem: documentation
tags: [ai-docs, package-surface, release-preview, exdoc, warnings-as-errors]

requires:
  - phase: 49-ai-accessible-docs-and-docs-verification-gate
    plan: 01
    provides: root `llms.txt`, `AGENTS.md`, repo-only `GEMINI.md`, and `Scoria.AiDocContract`
provides:
  - Packaged `llms.txt` and `AGENTS.md` inventory across Hex package and release preview
  - Explicit repo-only `GEMINI.md` exclusion contracts
  - ExDoc warning-clean source docs without adding private contract/helper modules to public docs
  - Release preview docs generation with `--warnings-as-errors`
affects: [phase-49, docs, package-surface, release-preview, ai-docs]

tech-stack:
  added: []
  patterns:
    - Release preview exports small constants for inventory and docs warning-gate args.
    - ExDoc warning cleanup uses `skip_code_autolink_to` plus narrow source-doc markup fixes for command literals that ExDoc special-cases.

key-files:
  created:
    - .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-02-SUMMARY.md
  modified:
    - mix.exs
    - lib/mix/tasks/scoria.release_preview.ex
    - test/scoria/package_surface_test.exs
    - test/mix/tasks/scoria.release_preview_test.exs
    - guides/maintainers.md
    - guides/troubleshooting.md
    - guides/reviewer-verification.md
    - README.md
    - CHANGELOG.md
    - guides/capabilities/bounded-handoffs.md
    - guides/capabilities/connectors-and-mcp.md
    - guides/capabilities/default-runtime.md
    - guides/capabilities/semantic-cache.md
    - guides/capabilities/support-copilot-gallery.md
    - guides/cheatsheet.cheatmd
    - guides/getting-started.md
    - guides/golden-path.md
    - guides/jtbd-and-user-flows.md
    - guides/ownership-boundary.md
    - guides/reference/glossary.md
    - lib/scoria/verification_suites.ex

key-decisions:
  - "`llms.txt` and `AGENTS.md` ship in the Hex package and release-preview required paths; `GEMINI.md` remains repo-only."
  - "`mix scoria.release_preview` is the canonical docs/package gate and now runs ExDoc with `--warnings-as-errors`."
  - "`MIX_ENV=dev mix docs --warnings-as-errors` is documented only as a maintainer diagnostic shortcut."
  - "Private contract/helper modules remain out of `docs_public_modules/0`; warning cleanup uses skip rules and narrow source-doc markup changes instead."

patterns-established:
  - "Package inventory is triple-locked through `mix.exs`, `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0`, and focused tests."
  - "Release preview exposes `docs_task_args/0` so the warning-gate behavior is testable without running the whole task."
  - "Inline command references that ExDoc treats as Mix task autolinks use shell-prompt code spans to avoid filtered-module warnings."

requirements-completed: [DOCS-04, AI-01, AI-02]

duration: 9 min
completed: 2026-07-11
status: complete
---

# Phase 49 Plan 02: Package and Release Preview Docs Warning Gate Summary

**Root AI docs now ship deliberately, ExDoc source docs are warning-clean, and release preview is the canonical warning-failing docs/package gate.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-11T00:40:20Z
- **Completed:** 2026-07-11T00:49:26Z
- **Tasks:** 3
- **Files modified:** 22

## Accomplishments

- Added `llms.txt` and `AGENTS.md` to `mix.exs` package files and `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0`.
- Added package/release-preview tests that consume `Scoria.AiDocContract` and assert `GEMINI.md` stays repo-only.
- Added ExDoc `skip_code_autolink_to` configuration for command-like env-prefixed spans and known intentional private helper references.
- Cleaned current ExDoc filtered-module warnings without adding private contract/helper modules to public docs.
- Added `Mix.Tasks.Scoria.ReleasePreview.docs_task_args/0` and made release preview run `Mix.Task.run("docs", docs_task_args())`.
- Updated maintainer, troubleshooting, and reviewer verification docs so release preview is canonical and raw docs WAE is diagnostic only.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add package inventory tests** - `98172739` (`test`)
2. **Task 1 GREEN: Package shared root AI docs** - `1935020a` (`feat`)
3. **Task 2 RED: Add docs warning cleanup contract** - `6d87fe6d` (`test`)
4. **Task 2 GREEN: Make docs warning gate clean** - `9fe09536` (`feat`)
5. **Task 3 RED: Add release-preview warning gate contract** - `528d10a0` (`test`)
6. **Task 3 GREEN: Enforce docs warnings in release preview** - `a1306cb2` (`feat`)

**Plan metadata:** recorded in this closeout commit

## Files Created/Modified

- `mix.exs` - Package inventory for root AI docs and ExDoc autolink warning cleanup.
- `lib/mix/tasks/scoria.release_preview.ex` - Release-preview required paths and docs `--warnings-as-errors` args.
- `test/scoria/package_surface_test.exs` - Package inventory and docs warning-cleanup contracts.
- `test/mix/tasks/scoria.release_preview_test.exs` - Release-preview inventory, cleanup, docs args, and maintainer-doc contracts.
- `guides/maintainers.md` - Canonical release preview and diagnostic raw docs WAE wording.
- `guides/troubleshooting.md` - Diagnostic raw docs WAE command for docs-generation failures.
- `guides/reviewer-verification.md` - Release-preview docs warning gate wording and no separate raw-docs CI policy step.
- README, changelog, capability guides, glossary, cheatsheet, and `lib/scoria/verification_suites.ex` - Narrow command-markup fixes for ExDoc warning cleanup.

## Verification

- `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/ai_doc_contract_test.exs --warnings-as-errors` - PASS, 25 tests, 0 failures.
- `MIX_ENV=dev mix docs --warnings-as-errors` - PASS; generated `doc/index.html` and `doc/llms.txt`.
- `MIX_ENV=dev mix scoria.release_preview` - PASS; printed `==> Release preview passed`.
- `git diff --exit-code -- .github/workflows/ci-verify.yml` - PASS; CI topology unchanged.
- `git diff --check` - PASS.

## Decisions Made

- Kept `GEMINI.md` out of package files and release-preview required paths because it is a repo-only vendor bridge.
- Kept `Scoria.AiDocContract`, `Scoria.AdopterDocContract`, `Scoria.HexConsumerContract`, and `Scoria.SupportJourney` out of public ExDoc module groups.
- Used source-doc shell-prompt command spans for inline `mix ...` references because ExDoc handles those before `skip_code_autolink_to`.
- Kept direct raw docs WAE as a diagnostic command instead of adding a separate CI policy step.

## Deviations from Plan

Used the plan's allowed narrow prose/source-doc fallback for inline `mix ...` command warnings. ExDoc special-cases those spans before the generic skip predicate, so configuration alone could not silence that warning class.

**Total deviations:** 0 scope changes.
**Impact on plan:** No scope change; warning cleanup remained documentation-only and did not widen public module curation.

## Issues Encountered

- ExDoc `skip_code_autolink_to` does not intercept the dedicated `mix ...` autolink clauses. The fix was to keep commands visible while making inline command spans begin with a shell prompt.

## User Setup Required

None.

## Next Phase Readiness

Phase 49 can close with root AI docs packaged deliberately, generated ExDoc output warning-clean, and release preview enforcing docs warnings as errors.

## Self-Check: PASSED

- Found packaged AI docs in `mix.exs` and release-preview required paths.
- Found `docs_task_args/0` returning `["--warnings-as-errors"]`.
- Confirmed `GEMINI.md` remains repo-only.
- Confirmed `.github/workflows/ci-verify.yml` was unchanged.
- Confirmed generated `doc/llms.txt` exists only as ignored derived output.

---
*Phase: 49-ai-accessible-docs-and-docs-verification-gate*
*Completed: 2026-07-11*
