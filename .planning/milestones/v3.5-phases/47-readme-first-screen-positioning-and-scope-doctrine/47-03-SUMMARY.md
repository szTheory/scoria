---
phase: 47-readme-first-screen-positioning-and-scope-doctrine
plan: "03"
subsystem: docs
tags:
  - comparison-guide
  - package-surface
  - release-preview
  - docs-contracts
requires:
  - "47-01 adoption lane doctrine and stable adopter docs contract"
  - "47-02 README first-screen positioning, public scope table, and comparison-guide link"
provides:
  - "POS-04 packaged comparison guide with named peer source links"
  - "Package, ExDoc extras, release-preview, and terminology-contract coverage for docs/scoria_vs_external_llm_ops.md"
  - "Safe current-claim, ceded-strength, and deferred-boundary contract tests"
affects:
  - phase-48-exdoc-guide-ladder
  - phase-50-release-readiness
  - adopter-docs
  - package-surface
tech-stack:
  added: []
  patterns:
    - "Source-linked peer comparison guide with explicit current, ceded, and deferred sections"
    - "Docs-as-public-API contracts for package surface and stable terminology docs"
key-files:
  created:
    - docs/scoria_vs_external_llm_ops.md
    - .planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-03-SUMMARY.md
  modified:
    - lib/scoria/adopter_doc_contract.ex
    - test/scoria/adoption_surface_test.exs
    - test/scoria/package_surface_test.exs
    - test/mix/tasks/scoria.release_preview_test.exs
    - test/scoria/terminology_contract_test.exs
    - mix.exs
    - lib/mix/tasks/scoria.release_preview.ex
key-decisions:
  - "The comparison guide names LangSmith, Langfuse, Braintrust, and Arize Phoenix exactly and source-links deployment posture instead of using hosted-only shorthand."
  - "Current Scoria claims stay limited to embedded Phoenix governance, host Postgres/Ecto records, /scoria review, durable runs, approvals, fail-closed eval posture, tenant-scoped knowledge retrieval, and package verification."
  - "Deferred seeds such as OpenInference export, lethal-trifecta enforcement, deeper eval/retrieval depth, privacy/feedback governance, and AI feature grouping are explicitly not current claims."
requirements-completed:
  - POS-04
duration: "10m 33s"
completed: 2026-07-10
status: complete
---

# Phase 47 Plan 03: External LLM-Ops Comparison Guide Summary

## One-liner

Packaged POS-04 Scoria-vs-external-LLM-ops comparison guide with source-linked peer posture, safe current claims, ceded strengths, and explicit deferred boundaries.

## Scope Completed

- Added docs contracts for the comparison guide path, title, peer names, peer source links, safe current claims, ceded strengths, deferred boundaries, and forbidden current claims.
- Created `docs/scoria_vs_external_llm_ops.md` with named comparisons for LangSmith, Langfuse, Braintrust, and Arize Phoenix.
- Wired the guide into ExDoc extras, Hex package files, release-preview required paths, and stable adopter documentation terminology coverage.
- Verified the guide stays a current-state adoption aid: Scoria is positioned as embedded Phoenix governance with host-owned identity, authorization, role values, business truth, and Postgres/Ecto records.

## Task Commits

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Add RED comparison guide contracts | `def308d7` | `lib/scoria/adopter_doc_contract.ex`, `test/scoria/adoption_surface_test.exs`, `test/scoria/package_surface_test.exs`, `test/mix/tasks/scoria.release_preview_test.exs`, `test/scoria/terminology_contract_test.exs` |
| 2 | Add packaged POS-04 guide and wiring | `0a88cd69` | `docs/scoria_vs_external_llm_ops.md`, `mix.exs`, `lib/mix/tasks/scoria.release_preview.ex` |
| 3 | Run final verification suite | `1273fac9` | Empty verification commit |

## Verification

| Command | Result |
| ------- | ------ |
| `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs` before guide implementation | Expected RED failure: 37 tests, 10 failures, all due to missing guide/package/release-preview wiring after compilation succeeded. |
| `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs` after guide implementation | Passed: 37 tests, 0 failures. |
| `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs` | Passed: 46 tests, 0 failures. |
| `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/hex_consumer_contract_test.exs` | Passed: 18 tests, 0 failures. |
| `mix scoria.release_preview` | Passed. Built ExDoc HTML, markdown `doc/llms.txt`, EPUB, unpacked Hex preview, and reported `==> Release preview passed`. |
| `mix ci` | Failed with unrelated pre-existing issues outside Phase 47-03 scope; details below. |

### `mix ci` Output

Command:

```bash
mix ci
```

Relevant output:

```text
==> mix ci: results

  PASS  deps.unlock --check-unused
  PASS  deps.get --check-locked
  FAIL (exit 1)  format --check-formatted
  PASS  compile --warnings-as-errors
  PASS  release_preview
  FAIL (exit 2)  adoption
  FAIL (exit 2)  runtime_to_handoff
  PASS  semantic_fast_path
  PASS  knowledge
  PASS  connector

==> mix ci: FAILED - one or more steps did not pass
```

Follow-up classification:

- `mix format --check-formatted` returned a long list of pre-existing formatting drift, including fixture and unrelated test files. None of the Phase 47-03 files changed by this plan were listed.
- `mix test.runtime_to_handoff` failed with 48 tests, 1 failure in `test/scoria/runtime_integration_test.exs:159`: the operator-visible workflow page rendered `Workflow run not found` instead of the newly started run id.
- `mix test.adoption` failed with 3 doctests, 63 tests, 1 failure, the same `Scoria.RuntimeIntegrationTest` workflow-page/run-not-found assertion.
- These failures are not caused by the comparison guide, docs extras, package file list, or release-preview required paths added in this plan.

## Deviations from Plan

None - plan executed as written.

## Auth Gates

None.

## Known Stubs

None introduced by this plan. Stub-pattern scan only matched an existing test assertion string, `This Scoria dashboard is not available for this session.`, in `test/scoria/adoption_surface_test.exs`; it is pre-existing fallback copy covered by tests, not a new comparison-guide stub.

## Threat Flags

None. The implementation added documentation, docs/package metadata, release-preview path coverage, and tests only; it introduced no new network endpoint, auth path, file-access trust boundary, or schema change.

## Deferred Issues

- Broader `mix ci` still fails on repository-wide formatting drift and a runtime integration test unrelated to Phase 47-03. The focused Phase 47 documentation, package-surface, release-preview, and Hex consumer checks passed.

## Next Phase Readiness

Phase 47 POS-04 is complete. Phase 48 can treat the comparison guide as a packaged stable adopter doc, while release readiness should continue tracking the unrelated repository-wide `mix ci` failures before publish.

## Self-Check: PASSED

- Found `docs/scoria_vs_external_llm_ops.md`.
- Found `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-03-SUMMARY.md`.
- Found task commits `def308d7`, `0a88cd69`, and `1273fac9`.
