---
phase: 48-exdoc-and-guide-ladder-restructure
verified: 2026-07-10T23:11:17Z
status: passed
score: "8/8 automated must-haves verified"
behavior_unverified: 2
overrides_applied: 0
---

# Phase 48: ExDoc and Guide Ladder Restructure Verification Report

**Phase Goal:** HexDocs becomes a navigable product surface instead of a flat dump of modules and historical guides.
**Verified:** 2026-07-10T23:11:17Z
**Status:** passed
**Re-verification:** No - initial phase verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | HexDocs opens on a purpose-built Getting Started guide. | VERIFIED | `mix.exs:138-153` sets `main: "getting-started"` and `extra_section: "Guides"`; `test/scoria/package_surface_test.exs:75-92` asserts the metadata. |
| 2 | ExDoc extras are the canonical guide ladder, not old flat `docs/*.md` files. | VERIFIED | `mix.exs:156-176` lists canonical `guides/` extras; `test/scoria/package_surface_test.exs:94-104` asserts compatibility stubs and dev-only docs stay out of ExDoc extras. |
| 3 | ExDoc extras are grouped by reader job. | VERIFIED | `mix.exs:179-211` defines Start Here, Capabilities, Operate & Verify, Compare & Decide, Reference, and Maintainers groups; `test/scoria/package_surface_test.exs:106-144` locks the grouping. |
| 4 | Public modules are grouped by adopter journey and filtered through a curated allowlist. | VERIFIED | `mix.exs:214-261` defines module groups; `mix.exs:278-310` allowlists public modules; `test/scoria/package_surface_test.exs:146-158` checks representative groups. |
| 5 | Docs source links and release metadata are version-aware. | VERIFIED | `mix.exs:126-135` uses `SCORIA_DOCS_SOURCE_REF`, exact tag detection, and `main` fallback; `mix.exs:138-153` sets source URL/ref, homepage URL, HTML/Markdown formatters, logo, favicon, and redirects. |
| 6 | Stable guides exist under the guide ladder and README points readers there. | VERIFIED | `README.md:64-69` lists Start Here, Capabilities, Operate & Verify, Compare & Decide, Reference, and Maintainers guide groups; `guides/getting-started.md:1`, `guides/golden-path.md:1`, `guides/jtbd-and-user-flows.md:1`, `guides/ownership-boundary.md:1`, `guides/reviewer-verification.md:1`, `guides/troubleshooting.md:1`, `guides/scoria-vs-external-llm-ops.md:1`, `guides/reference/glossary.md:1`, and `guides/maintainers.md:1` exist. |
| 7 | Old docs links are preserved as compatibility source stubs and ExDoc redirects, while dev-only docs stay out of the package. | VERIFIED | `mix.exs:264-275` maps old page IDs to canonical guides; `lib/mix/tasks/scoria.release_preview.ex:5-42` requires canonical guides, compatibility stubs, and brand assets; `test/mix/tasks/scoria.release_preview_test.exs:60-95` checks the required path list and dev-only exclusions. |
| 8 | Public moduledocs link to canonical guides and state host-owned identity/scope boundaries. | VERIFIED | `lib/scoria.ex:22-24`, `lib/scoria/identity.ex:20-22`, `lib/scoria/runtime.ex:19-21`, `lib/scoria_web/router.ex:25-26`, `lib/scoria_web/dashboard_scope.ex:3-36`, `lib/scoria_web/reviewer_surface.ex:15-16`, `lib/scoria/verification_suites.ex:17-18`, `lib/scoria/semantic_cache.ex:3-12`, `lib/scoria/connectors.ex:9-16`, and `lib/scoria/sre.ex:10-16`; `test/scoria/adoption_surface_test.exs:621-665` checks D-17 moduledoc links and compatibility alias framing. |

**Score:** 8/8 automated truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | ExDoc main, source metadata, guide extras, extra groups, module groups, redirects, public module filter, package files. | VERIFIED | Lines 126-310 cover docs metadata, extras, groups, redirects, and public module allowlist. |
| `guides/` | Canonical Phase 48 guide ladder. | VERIFIED | All D-03 guide paths exist and are referenced by README and ExDoc extras. |
| `docs/*.md` compatibility stubs | Preserve copied old source links without becoming canonical ExDoc extras. | VERIFIED | Required in release preview/package inventory; excluded from ExDoc extras by package-surface tests. |
| `brandbook/logo-primary.svg`, `brandbook/logo-primary-light.svg`, `brandbook/logo-mark.svg`, `brandbook/favicon.svg` | Docs/package brand assets. | VERIFIED | Required by `lib/mix/tasks/scoria.release_preview.ex:38-41` and tested in `test/mix/tasks/scoria.release_preview_test.exs:33-58`. |
| `lib/mix/tasks/scoria.release_preview.ex` | Build docs, unpack Hex preview, require the Phase 48 package/docs surface, and clean generated docs before rebuild. | VERIFIED | Lines 43-65 clean `doc/` before `mix docs`; lines 69-83 build/unpack and report success. |
| `test/scoria/package_surface_test.exs` | ExDoc/package surface contract. | VERIFIED | Covers metadata, guide extras, grouping, redirects, package files, and dev-only exclusions. |
| `test/mix/tasks/scoria.release_preview_test.exs` | Release-preview inventory and stale generated-doc cleanup contract. | VERIFIED | Lines 60-117 cover task discoverability, required paths, dev-only exclusions, and stale `search_data` cleanup. |
| `48-VALIDATION.md` | Completed Nyquist ledger with concrete task IDs and truthful manual-only caveats. | VERIFIED | Frontmatter is complete with `nyquist_compliant: true` and `wave_0_complete: true`; per-task map has concrete IDs through `48-10-T2`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs` | `doc/getting-started.html` | `main: "getting-started"` and canonical guide extra | VERIFIED | `mix scoria.release_preview` generated `doc/getting-started.html` and the generated-doc assertion found `Getting Started`. |
| `mix.exs` | old generated page IDs | `redirects: docs_redirects()` | VERIFIED | `mix.exs:264-275` maps old IDs such as `semantic_fast_path` to canonical guide IDs. |
| `README.md` | `guides/` ladder | guide group links | VERIFIED | `README.md:64-69` points to canonical guide groups and names. |
| `lib/mix/tasks/scoria.release_preview.ex` | `tmp/scoria-release-preview` | `mix hex.build --unpack` | VERIFIED | `mix scoria.release_preview` exited 0 and printed `Release preview passed`. |
| `test/scoria/adoption_surface_test.exs` | public moduledocs | `Code.fetch_docs/1` D-17 contract | VERIFIED | `test/scoria/adoption_surface_test.exs:621-665` checks prioritized public modules and compatibility aliases. |

### Data-Flow Trace

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `mix.exs` docs config | `Mix.Project.config()[:docs]` | Project config | Yes - package surface tests inspect live project config | VERIFIED |
| Release-preview inventory | `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0` | Mix task module attribute | Yes - release preview checks unpacked Hex package paths | VERIFIED |
| Generated docs | `doc/index.html`, `doc/getting-started.html`, `doc/dist/search_data-*.js` | `mix scoria.release_preview` -> `mix docs` | Yes - generated HTML/search artifacts were checked by CLI assertions | VERIFIED |
| Package preview | `tmp/scoria-release-preview/` | `mix hex.build --unpack` | Yes - unpacked package root was inspected for required paths by the task | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Focused Phase 48 docs/package contracts pass. | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs test/scoria/scope_doctrine_contract_test.exs` | 59 tests, 0 failures. | PASS |
| Release-preview task cleanup regression passes. | `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs` | 2 tests, 0 failures. | PASS |
| Release preview builds docs and unpacked Hex package; generated docs do not retain old/dev source paths. | `mix scoria.release_preview && test -f doc/index.html && test -f doc/getting-started.html && rg -n "Getting Started\|Guides\|Semantic Cache" doc/index.html doc/getting-started.html && ! rg -n "docs/semantic_fast_path\.md\|docs/design_system\.md\|docs/docker_dev_dx\.md\|docs/uat_automation\.md" doc` | Exit 0; printed `Release preview passed`; forbidden path scan clean. | PASS |
| Phase 48 code compiles warning-clean under test compile gate. | `MIX_ENV=test mix compile --warnings-as-errors` | Exit 0. | PASS |
| Validation ledger contains final status and concrete task IDs. | `rg -n "nyquist_compliant: true\|wave_0_complete: true\|status: complete\|48-01-T1\|48-10-T2" .planning/phases/48-exdoc-and-guide-ladder-restructure/48-VALIDATION.md && ! rg -n "TBD" .planning/phases/48-exdoc-and-guide-ladder-restructure/48-VALIDATION.md` | Exit 0 after replacing one false-positive `JTBD` wording in the ledger. | PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| DOCS-01 | 48-01, 48-03 through 48-09, 48-12, 48-13 | A Phoenix adopter can navigate ExDoc through grouped modules and grouped extras instead of one flat sidebar. | SATISFIED | `mix.exs:138-261`, package-surface grouping tests, generated docs assertion, release preview passed. |
| DOCS-02 | 48-01, 48-07, 48-10 | ExDoc source links, release docs links, logo/favicon metadata, and markdown/html formatter settings are version-aware and do not point dev docs at missing tag URLs. | SATISFIED | `mix.exs:126-153`, `test/scoria/package_surface_test.exs:75-92`, `test/mix/tasks/scoria.release_preview_test.exs:60-95`, release preview passed. |
| DOCS-03 | 48-02 through 48-06, 48-08 through 48-15 | Stable adopter guides are organized into a clear guide ladder covering getting started, golden path, user flows, troubleshooting, comparison, and cheatsheet. | SATISFIED | `README.md:64-69`, `guides/` source files, terminology/adoption/glossary/scope contracts, compatibility stubs, and validation ledger. |

No orphaned Phase 48 requirements were found. `.planning/REQUIREMENTS.md` maps DOCS-01, DOCS-02, and DOCS-03 to Phase 48 and leaves DOCS-04 for Phase 49.

### Human Verification Required

| Check | Status | Notes |
|-------|--------|-------|
| Open `doc/index.html` in a browser and visually inspect sidebar readability/order. | NOT PERFORMED | `48-VALIDATION.md` leaves this manual-only check unchecked. Automated generated-doc proof passed. |
| Review rendered public moduledoc pages for polish. | NOT PERFORMED | `48-VALIDATION.md` leaves this manual-only check unchecked. Source and contract proof passed. |

### Gaps Summary

No Phase 48 automated goal gaps found. The phase goal is achieved in source docs, ExDoc/package configuration, generated docs, release-preview package inventory, and contract tests.

Residual work is explicitly outside Phase 48:

- DOCS-04 warning-clean docs verification remains Phase 49 scope. `mix scoria.release_preview` still emits existing non-failing ExDoc filtered-reference warnings.
- Manual rendered-doc sidebar and moduledoc polish review were not performed and are recorded as manual-only caveats, not automated phase blockers.

---

_Verified: 2026-07-10T23:11:17Z_
_Verifier: the agent (local phase verification)_
