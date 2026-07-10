---
phase: 48
slug: exdoc-and-guide-ladder-restructure
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-10
completed: 2026-07-10
---

# Phase 48 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` |
| **Focused suite command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs test/scoria/scope_doctrine_contract_test.exs` |
| **Phase gate command** | `mix scoria.release_preview && test -f doc/index.html && test -f doc/getting-started.html && rg -n "Getting Started\|Guides\|Semantic Cache" doc/index.html doc/getting-started.html && ! rg -n "docs/semantic_fast_path.md\|docs/design_system.md\|docs/docker_dev_dx.md\|docs/uat_automation.md" doc` |
| **Observed runtime** | Focused suite: < 1 second. Release preview plus generated-doc assertions: < 2 seconds, with non-failing ExDoc warnings deferred to DOCS-04 / Phase 49. |

---

## Sampling Rate

- **After every task commit:** Run the focused contract for the touched surface, starting with `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs`.
- **After every plan wave:** Run package/release-preview contracts plus stable docs terminology/adoption contracts.
- **Before verification:** Run the focused Phase 48 suite, `MIX_ENV=test mix compile --warnings-as-errors`, and the release preview generated-doc assertion.
- **Max feedback latency:** Focused contracts stayed under the 90 second target; docs generation produced many existing non-failing ExDoc warnings but did not dominate the gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-T1 | 48-01 | 1 | DOCS-01, DOCS-02 | T-48-01-I/T/R | ExDoc config contract covers grouped extras/modules, source refs, docs URL, logo, favicon, and formatters before implementation | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | Yes | green |
| 48-01-T2 | 48-01 | 1 | DOCS-02, DOCS-03 | T-48-01-I/T | Release-preview inventory contract includes canonical guides, compatibility stubs, and brand assets while excluding dev-only docs | contract | `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs` | Yes | green |
| 48-02-T1 | 48-02 | 1 | DOCS-01, DOCS-03 | T-48-02-I/T | Stable adopter docs contracts use canonical `guides/` paths, not old flat docs paths | contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` | Yes | green |
| 48-02-T2 | 48-02 | 1 | DOCS-03 | T-48-02-E/T | Public guide path and moduledoc contracts point readers to the guide ladder and host-owned boundary language | contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` | Yes | green |
| 48-03-T1 | 48-03 | 2 | DOCS-01, DOCS-03 | T-48-03-T/R | Getting Started and Golden Path exist as Start Here guides and keep `session_id` versus `run_id` precise | contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` | Yes | green |
| 48-03-T2 | 48-03 | 2 | DOCS-03 | T-48-03-E/T | User-flow and ownership-boundary guides preserve host-owned auth, tenant scope, and policy language | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-04-T1 | 48-04 | 2 | DOCS-01, DOCS-03 | T-48-04-T/E | Runtime, handoff, semantic-cache, connector, and gallery capability guides use the canonical capability ladder | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs` | Yes | green |
| 48-04-T2 | 48-04 | 2 | DOCS-03 | T-48-04-R/T | Glossary and capability guide language keeps compatibility aliases explicit without leaking dev-only docs | contract | `MIX_ENV=test mix test test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs` | Yes | green |
| 48-05-T1 | 48-05 | 2 | DOCS-01, DOCS-03 | T-48-05-R/I | Reviewer verification guide preserves proof commands, scope doctrine, and release-preview placement | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-05-T2 | 48-05 | 2 | DOCS-03 | T-48-05-S/I | Comparison, troubleshooting, and maintainer guides are canonical guide-ladder pages and keep dev-only material out of adopter paths | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs` | Yes | green |
| 48-06-T1 | 48-06 | 3 | DOCS-03 | T-48-06-S/I | README guide links point to canonical `guides/` paths and do not advertise old docs names as current surface | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` | Yes | green |
| 48-08-T1 | 48-08 | 3 | DOCS-01, DOCS-03 | T-48-08-R/E | Public runtime entry docs link to first-run guides and host-owned identity/scope boundaries | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` | Yes | green |
| 48-09-T1 | 48-09 | 3 | DOCS-01, DOCS-03 | T-48-09-I/E | Capability moduledocs point to public guides and avoid implementation-first or backend-only adoption paths | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs` | Yes | green |
| 48-11-T1 | 48-11 | 3 | DOCS-03 | T-48-11-T/S/I | Old source docs pages are compatibility stubs that name canonical replacement guides and avoid dev-only docs links | contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-14-T1 | 48-14 | 3 | DOCS-03 | T-48-14-T/S/I | Old capability docs pages are compatibility stubs pointing to canonical capability guides | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/scoria/adoption_surface_test.exs` | Yes | green |
| 48-15-T1 | 48-15 | 3 | DOCS-03 | T-48-15-T/S/I | Old operate/maintainer docs paths remain packaged compatibility pages with canonical guide links | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-12-T1 | 48-12 | 3 | DOCS-01, DOCS-03 | T-48-12-E/T | Dashboard scope docs document host-authenticated tenant scope and params-as-hints semantics | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-12-T2 | 48-12 | 3 | DOCS-01, DOCS-03 | T-48-12-R/T | Verification-suite public docs describe proof commands and link to reviewer verification guides | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-13-T1 | 48-13 | 3 | DOCS-01, DOCS-03 | T-48-13-S/E | SRE and compatibility alias docs point to final modules/guides and state host-owned operational policy | contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` | Yes | green |
| 48-07-T1 | 48-07 | 4 | DOCS-01, DOCS-02 | T-48-07-T/R | `docs_source_ref/0` and docs metadata are dynamic, version-aware, and covered by package-surface contracts | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | Yes | green |
| 48-07-T2 | 48-07 | 4 | DOCS-01, DOCS-03 | T-48-07-I/S | ExDoc extras/modules are grouped by reader job and old generated page IDs redirect to canonical guide IDs | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` | Yes | green |
| 48-07-T3 | 48-07 | 4 | DOCS-02, DOCS-03 | T-48-07-I/T | Release preview packages canonical guides, compatibility stubs, and docs brand assets while excluding dev-only docs | integration | `mix scoria.release_preview` | Yes | green |
| 48-10-T1 | 48-10 | 5 | DOCS-01, DOCS-02, DOCS-03 | T-48-10-R/T | Final focused suite proves package, release-preview, terminology, adoption, glossary, and scope-doctrine contracts together | integration | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/glossary_contract_test.exs test/scoria/scope_doctrine_contract_test.exs` | Yes | green |
| 48-10-T2 | 48-10 | 5 | DOCS-01, DOCS-02, DOCS-03 | T-48-10-I/T | Release preview builds docs and unpacked Hex preview, and generated docs do not retain old/dev source paths | integration | `mix scoria.release_preview && test -f doc/index.html && test -f doc/getting-started.html && rg -n "Getting Started\|Guides\|Semantic Cache" doc/index.html doc/getting-started.html && ! rg -n "docs/semantic_fast_path.md\|docs/design_system.md\|docs/docker_dev_dx.md\|docs/uat_automation.md" doc` | Yes | green |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [x] Update or add docs surface contracts for `main`, `extra_section`, `formatters`, `logo`, `favicon`, `groups_for_extras`, `groups_for_modules`, `redirects`, and dynamic `docs_source_ref/0`.
- [x] Update package/release-preview required path contracts for canonical `guides/` files, compatibility `docs/*.md` stubs that must ship, and required brand assets.
- [x] Update stable docs/adoption/terminology contracts from flat `docs/*.md` paths to canonical `guides/` paths while preserving legacy alias compatibility assertions.
- [x] Add redirect coverage for old generated page IDs before moving content.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Automated Evidence | Manual Status |
|----------|-------------|------------|--------------------|---------------|
| HexDocs sidebar readability and guide ladder ordering | DOCS-01, DOCS-03 | ExUnit can assert config and file presence, but not whether the rendered sidebar is a good product surface | `mix scoria.release_preview` generated `doc/index.html`, `doc/getting-started.html`, and clean sidebar/search assets | Not performed in browser |
| Public moduledoc polish for prioritized entry points | DOCS-03 | Content quality needs human review after contract tests prove links exist | Focused adoption/terminology/glossary/scope contracts passed; ExDoc generated successfully | Not performed in browser |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing or stale docs/package contract references.
- [x] No watch-mode flags.
- [x] Feedback latency remained under 90 seconds for focused contract runs.
- [x] `nyquist_compliant: true` set in frontmatter after task IDs were finalized and Wave 0 passed.
- [ ] Manual HexDocs sidebar inspection performed in a browser.
- [ ] Manual rendered moduledoc polish review performed in a browser.

**Approval:** automated validation complete; manual browser-only review remains explicitly unperformed.
