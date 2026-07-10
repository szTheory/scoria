---
phase: 48-exdoc-and-guide-ladder-restructure
plan: 10
subsystem: documentation-validation
tags: [validation, exdoc, guide-ladder, package-surface, release-preview]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: 48-01 through 48-15 guide, package, ExDoc, compatibility, and moduledoc work
provides:
  - Focused Phase 48 contract validation passed after the scope-doctrine compatibility repair
  - Blocked generated-doc validation result for old docs path exposure in ExDoc search data
affects: [phase-48, validation, guide-ladder, generated-docs]

tech-stack:
  added: []
  patterns:
    - Validation closeout stops on generated-doc assertion failures and does not claim Nyquist completion.

key-files:
  created: []
  modified:
    - .planning/phases/48-exdoc-and-guide-ladder-restructure/48-10-SUMMARY.md

key-decisions:
  - "Plan 48-10 resumed after fix 5c5ba9ff and Task 1 passed with 58 tests, 0 failures."
  - "Plan 48-10 stopped during Task 2 because the stricter generated-doc source assertion still found old docs paths in ExDoc search data."
  - "48-VALIDATION.md remains incomplete; no green validation ledger status was claimed after the Task 2 failure."

patterns-established:
  - "Generated doc sidebar proof must be distinguished from full-text ExDoc search-index exposure when closing Phase 48."

requirements-completed: []

duration: 5 min
completed: 2026-07-10
status: blocked
---

# Phase 48 Plan 10: Validation Closeout Summary

**Focused contracts now pass, but final generated-doc validation remains blocked by old docs path exposure in ExDoc search data.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-10T22:52:35Z
- **Stopped:** 2026-07-10T22:57:07Z
- **Tasks completed:** 1 of 3
- **Files modified:** this summary only; `48-VALIDATION.md` was left unchanged.

## Result

Plan 48-10 did not complete. Task 1 passed after the compatibility-stub repair in `5c5ba9ff`, but Task 2's generated-doc assertion failed before validation-ledger closeout.

## Task 1 Verification

```bash
MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs test/scoria/scope_doctrine_contract_test.exs
```

Observed result:

- **Exit code:** 0
- **Tests:** 58 tests, 0 failures
- **Notes:** `test/scoria/scope_doctrine_contract_test.exs` is green after `docs/adoption_lanes.md` and `docs/operator_verification.md` regained the required scope-doctrine compatibility fragments.

Source-level Task 1 checks:

- `@stable_adopter_docs` in `test/scoria/terminology_contract_test.exs` lists canonical `guides/` paths only.
- `@docs_extras` in `test/scoria/package_surface_test.exs` is `@docs_support_extras ++ @canonical_guides`.
- Old `docs/*.md` package paths remain in `@compatibility_stub_paths`, not canonical ExDoc extras.
- Package and release-preview contracts include canonical guides, compatibility stubs, and brand assets.

## Task 2 Verification

```bash
mix scoria.release_preview
```

Observed result:

- **Exit code:** 0
- **Output:** printed `==> Release preview passed`
- **Generated artifacts:** `doc/index.html`, `doc/getting-started.html`, and `tmp/scoria-release-preview` were generated.
- **Non-failing warnings:** ExDoc emitted existing warnings about command literals and filtered modules, matching the deferred broad docs warning-clean gate noted in earlier Phase 48 summaries.

Passing generated-doc checks:

```bash
test -f doc/index.html && test -f doc/getting-started.html && rg -n "Getting Started|Guides|Semantic Cache" doc/index.html doc/getting-started.html
```

Observed result:

- **Exit code:** 0
- **Evidence:** `doc/getting-started.html` contains `Getting Started`; its sidebar nav is marked `data-extras="Guides"`.

```bash
rg -n "docs/semantic_fast_path\\.md|docs/design_system\\.md|docs/docker_dev_dx\\.md|docs/uat_automation\\.md|semantic_fast_path|design_system|docker_dev_dx|uat_automation" doc/dist/sidebar_items-*.js
```

Observed result:

- **Exit code:** 1
- **Evidence:** no forbidden old docs path or dev-only docs path appears in the generated sidebar bundle.

```bash
rg -n "Start Here|Capabilities|Operate & Verify|Compare & Decide|Reference|Maintainers|Semantic Cache|Getting Started" doc/dist/sidebar_items-*.js
```

Observed result:

- **Exit code:** 0
- **Evidence:** the generated sidebar bundle includes the expected guide groups and canonical guide entries.

## Blocking Failure

The plan's stricter generated-doc command still fails:

```bash
! rg -n "docs/semantic_fast_path.md|docs/design_system.md|docs/docker_dev_dx.md|docs/uat_automation.md" doc
```

Observed result:

- **Exit code:** 1
- **Failure file:** `doc/dist/search_data-CA6DA77B.js`
- **Matches:**
  - `docs/semantic_fast_path.md`
  - `docs/docker_dev_dx.md`

The sidebar-specific check is clean, but ExDoc's generated search index still contains old/dev docs path strings. Because the plan and continuation instructions require stopping on any failed validation command, Task 2 is not marked complete.

## Validation Ledger

`.planning/phases/48-exdoc-and-guide-ladder-restructure/48-VALIDATION.md` was intentionally left unchanged:

- `nyquist_compliant: false`
- `wave_0_complete: false`
- `status: draft`
- `TBD` task IDs remain unresolved

This is truthful because Task 2 did not pass all required generated-doc assertions and Task 3 was not run.

## Generated Artifact Handling

`mix scoria.release_preview` generated ignored verification artifacts:

- `doc/index.html`
- `doc/getting-started.html`
- `doc/semantic_fast_path.html` redirect output
- `tmp/scoria-release-preview`

`git ls-files doc tmp/scoria-release-preview` returned no tracked files before generation, and `git status --short` did not list generated `doc/` or `tmp/scoria-release-preview` files after generation. They were left uncommitted.

The pre-existing untracked `.planning/research/.cache/` directory was left untouched.

## Task Commits

No task commits were created for Task 1 or Task 2 because both were validation-only and produced no tracked task-file changes. This blocked summary supersedes the earlier Task 1 blocker summary.

## Deviations from Plan

None. The plan's Task 2 action explicitly requires stopping on generated-doc assertion failure, recording the failure in this summary, leaving `48-VALIDATION.md` incomplete, and routing the fix back to the owning prior plan/file.

## Known Stubs

None introduced by this plan. The generated `doc/semantic_fast_path.html` file is an ExDoc redirect artifact, not a source stub.

## Threat Flags

None. This plan run changed planning documentation only and introduced no runtime endpoint, auth path, file-access trust boundary, schema change, package dependency, or committed generated public docs surface.

## Next Phase Readiness

Blocked. The owning docs/config plan should remove or intentionally justify old/dev docs path strings from generated ExDoc search data, or revise the Phase 48 generated-doc assertion to target sidebar links only. After that, rerun Plan 48-10 from Task 2.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-10-SUMMARY.md`.
- Confirmed `48-VALIDATION.md` remains incomplete with `nyquist_compliant: false`, `wave_0_complete: false`, `status: draft`, and unresolved `TBD` task IDs.
- Confirmed blocker evidence remains reproducible in `doc/dist/search_data-CA6DA77B.js`: `docs/semantic_fast_path.md` and `docs/docker_dev_dx.md`.
- Confirmed no tracked generated `doc/` or `tmp/scoria-release-preview` files were added to git status.
