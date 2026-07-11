---
phase: 49-ai-accessible-docs-and-docs-verification-gate
verified: 2026-07-11T01:02:00Z
status: passed
score: "9/9 automated must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 49: AI-Accessible Docs and Docs Verification Gate Verification Report

**Phase Goal:** Make Scoria's docs accessible to AI-assisted readers and make warning-clean docs generation part of the release-preview gate.
**Verified:** 2026-07-11T01:02:00Z
**Status:** passed
**Re-verification:** No - initial phase verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Root `llms.txt` exists as an AI-readable public source map and points to source docs, not generated docs as source truth. | VERIFIED | `llms.txt` exists; `test/scoria/ai_doc_contract_test.exs` asserts required headings, source paths, source/generated boundary fragments, and forbidden planning-only fragments. |
| 2 | Root `AGENTS.md` exists as the repo-agent operating contract. | VERIFIED | `AGENTS.md` exists; AI docs tests assert required agent sections, source/generated boundary language, and verification commands. |
| 3 | `GEMINI.md` remains a tiny repo-only bridge rather than a second full agent instruction file. | VERIFIED | `GEMINI.md` points to `AGENTS.md`; `Scoria.AiDocContract.repo_only_ai_doc_paths/0` returns `["GEMINI.md"]`; body contract enforces bridge size and wording. |
| 4 | `Scoria.AiDocContract` centralizes AI docs paths, headings, sections, and package/repo-only decisions. | VERIFIED | `lib/scoria/ai_doc_contract.ex` exports the required zero-arity helpers; `test/scoria/ai_doc_contract_test.exs` covers the constants and body contracts. |
| 5 | `llms.txt` and `AGENTS.md` ship in the Hex package while `GEMINI.md` remains excluded. | VERIFIED | `mix.exs` package files include `llms.txt` and `AGENTS.md`; `test/scoria/package_surface_test.exs` asserts packaged AI docs are included and the Gemini bridge is excluded. |
| 6 | Release preview requires the packaged AI docs and excludes `GEMINI.md`. | VERIFIED | `lib/mix/tasks/scoria.release_preview.ex` required paths include `llms.txt` and `AGENTS.md`; `test/mix/tasks/scoria.release_preview_test.exs` asserts the same and excludes `GEMINI.md`. |
| 7 | Public docs generation is warning-clean without adding private contract/helper modules to public ExDoc groups. | VERIFIED | `MIX_ENV=dev mix docs --warnings-as-errors` exited 0; `mix.exs` uses `skip_code_autolink_to`; package surface tests refute private contract/helper modules in `groups_for_modules`. |
| 8 | Release preview runs ExDoc with warnings-as-errors and remains the canonical package/docs gate. | VERIFIED | `Mix.Tasks.Scoria.ReleasePreview.docs_task_args/0` returns `["--warnings-as-errors"]`; task source calls `Mix.Task.run("docs", docs_task_args())`; `MIX_ENV=dev mix scoria.release_preview` passed and printed `==> Release preview passed`. |
| 9 | Maintainer guidance names raw docs WAE as diagnostic only and does not add a separate raw-docs CI policy step. | VERIFIED | `guides/maintainers.md`, `guides/troubleshooting.md`, and `guides/reviewer-verification.md` contain `MIX_ENV=dev mix docs --warnings-as-errors`; `.github/workflows/ci-verify.yml` remained unchanged and still runs `MIX_ENV=dev mix scoria.release_preview`. |

**Score:** 9/9 automated truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `llms.txt` | Root AI-readable source map. | VERIFIED | Includes required headings, public source paths, command references, and source/generated boundary language. |
| `AGENTS.md` | Root repo-agent operating contract. | VERIFIED | Includes source truth, generated output, verification, vocabulary, public API, and avoid-rules sections. |
| `GEMINI.md` | Tiny repo-only bridge to shared agent instructions. | VERIFIED | Preserves the Ash non-goal and points to `AGENTS.md`; excluded from package and release-preview inventory. |
| `lib/scoria/ai_doc_contract.ex` | Internal AI docs contract constants. | VERIFIED | Provides path, heading, section, source-boundary, and forbidden-fragment helpers. |
| `test/scoria/ai_doc_contract_test.exs` | AI docs body and path contracts. | VERIFIED | Included in phase contract test suite; passed. |
| `mix.exs` | Package entries for root AI docs and ExDoc warning cleanup. | VERIFIED | Package files include `llms.txt` and `AGENTS.md`; docs config includes `skip_code_autolink_to`. |
| `lib/mix/tasks/scoria.release_preview.ex` | Release-preview docs warning gate and required package paths. | VERIFIED | Exports `required_package_paths/0`, `docs_task_args/0`, and runs docs with warning-gate args. |
| `test/scoria/package_surface_test.exs` | Package and docs warning cleanup contracts. | VERIFIED | Verifies AI docs package inclusion, `GEMINI.md` exclusion, skip function, and private module curation. |
| `test/mix/tasks/scoria.release_preview_test.exs` | Release-preview inventory, docs args, cleanup, and docs guidance contracts. | VERIFIED | Verifies required paths, generated docs cleanup, docs warning args, source call, and CI/docs guidance. |
| Maintainer docs | Release preview canonical; raw docs WAE diagnostic. | VERIFIED | `guides/maintainers.md`, `guides/troubleshooting.md`, and `guides/reviewer-verification.md` updated and tested. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/scoria/ai_doc_contract.ex` | `llms.txt`, `AGENTS.md`, `GEMINI.md` | Path constants consumed by tests. | VERIFIED | AI docs contract tests assert root/package/repo-only path decisions. |
| `mix.exs` | `llms.txt`, `AGENTS.md` | Package files include packaged AI docs. | VERIFIED | Package surface tests and release preview passed. |
| `lib/mix/tasks/scoria.release_preview.ex` | `llms.txt`, `AGENTS.md` | `required_package_paths/0`. | VERIFIED | Release-preview tests assert required path inclusion. |
| `lib/mix/tasks/scoria.release_preview.ex` | ExDoc warning gate | `Mix.Task.run("docs", docs_task_args())`. | VERIFIED | Source assertion and end-to-end `MIX_ENV=dev mix scoria.release_preview` passed. |
| Maintainer docs | `.github/workflows/ci-verify.yml` | Docs state raw docs WAE diagnostic while CI keeps release preview. | VERIFIED | Release-preview test asserts docs strings and refutes raw `mix docs --warnings-as-errors` in CI workflow. |

### Data-Flow Trace

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| AI docs source map | Root `llms.txt` content | Source repository | Yes - source paths and command strings are read directly by contract tests. | VERIFIED |
| Package inventory | `Mix.Project.config()[:package][:files]` | `mix.exs` | Yes - tests inspect live Mix project config and release preview inspects an unpacked Hex preview. | VERIFIED |
| Release-preview inventory | `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0` | Mix task module attribute | Yes - task checks unpacked package paths. | VERIFIED |
| Docs warning args | `Mix.Tasks.Scoria.ReleasePreview.docs_task_args/0` | Mix task helper | Yes - task passes the helper result to `Mix.Task.run("docs", ...)`. | VERIFIED |
| Generated docs | `doc/index.html`, `doc/llms.txt` | `MIX_ENV=dev mix docs --warnings-as-errors` and release preview | Yes - generated files were produced; `doc/llms.txt` exists and is gitignored. | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 49 AI docs/package/release-preview contracts pass. | `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/hex_consumer_contract_test.exs --warnings-as-errors` | 38 tests, 0 failures. | PASS |
| Public docs generation is warning-clean. | `MIX_ENV=dev mix docs --warnings-as-errors` | Exit 0; generated `doc/index.html` and `doc/llms.txt`. | PASS |
| Canonical release-preview gate passes. | `MIX_ENV=dev mix scoria.release_preview` | Exit 0; printed `==> Release preview passed`. | PASS |
| Test compile remains warning-clean. | `MIX_ENV=test mix compile --warnings-as-errors` | Exit 0. | PASS |
| CI topology unchanged. | `git diff --exit-code -- .github/workflows/ci-verify.yml` | Exit 0. | PASS |
| Prior docs/package regression subset passes. | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/hex_consumer_contract_test.exs --warnings-as-errors` | 81 tests, 0 failures. | PASS |
| Generated markdown is derived output only. | `test -f doc/llms.txt && git check-ignore -q doc/llms.txt` | `doc/llms.txt exists`; `doc/llms.txt ignored`. | PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| AI-01 | 49-01, 49-02 | Root AI-readable docs expose source-oriented Scoria docs and agent guidance. | SATISFIED | `llms.txt`, `AGENTS.md`, `GEMINI.md`, `Scoria.AiDocContract`, AI docs tests, package/release-preview inventory. |
| AI-02 | 49-01, 49-02 | AI docs distinguish source truth from generated ExDoc output and vendor bridge docs. | SATISFIED | AI docs source/generated fragments, forbidden-fragment tests, `GEMINI.md` repo-only exclusion, generated `doc/llms.txt` ignored. |
| DOCS-04 | 49-02 | Public moduledocs and guide links are warning-clean under the milestone docs verification command. | SATISFIED | Raw `MIX_ENV=dev mix docs --warnings-as-errors` passed; release preview runs docs with warning-gate args; maintainer docs name diagnostic WAE command. |

No orphaned Phase 49 requirements were found. `.planning/REQUIREMENTS.md` maps DOCS-04, AI-01, and AI-02 to Phase 49 and all are complete.

### Regression Gate Notes

The prior docs/package regression subset initially exposed one stale contract in `test/scoria/hex_consumer_contract_test.exs`: it still expected the old `docs/glossary.md` compatibility stub to be an ExDoc extra. Phase 48 intentionally moved canonical ExDoc extras to `guides/reference/glossary.md` while keeping `docs/glossary.md` packaged as a compatibility stub. The test was updated in commit `d9156e0d` and the regression subset then passed.

### Hook Dispatch Notes

The installed GSD CLI in this environment does not expose `loop render-hooks`; both execute:post and verify:post hook rendering returned "Unknown command: loop". Code-review and security hook dispatch were therefore unavailable/inactive for this run. Local automated verification and regression gates above passed.

### Human Verification Required

None for Phase 49 completion.

### Gaps Summary

No Phase 49 gaps found. The phase goal is achieved in source docs, package inventory, ExDoc warning behavior, release-preview enforcement, maintainer guidance, and contract tests.

---

_Verified: 2026-07-11T01:02:00Z_
_Verifier: the agent (local phase verification)_
