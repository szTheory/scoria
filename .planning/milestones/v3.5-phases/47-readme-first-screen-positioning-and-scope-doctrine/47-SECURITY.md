---
phase: 47
slug: readme-first-screen-positioning-and-scope-doctrine
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-07-10
---

# Phase 47 - Security

Per-phase security contract: verify every declared threat mitigation from the
Phase 47 plan-time threat registers. Implementation files were treated as
read-only during this audit.

## Audit Context

- Auditor: gsd-security-auditor
- ASVS level: 1 - grep-level presence in cited files
- ASVS reference: `/Users/jon/.claude/gsd-core/references/security-asvs-levels.md`
- Project-local `.codex/skills/` and `.agents/skills/` directories were not present.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| adopter -> README/docs | Adopters rely on public docs to decide whether Scoria owns auth, policy, release truth, hosted control-plane responsibilities, or host-owned app decisions. | Public install, positioning, scope, and comparison guidance. |
| docs -> package surface | Packaged README/docs become Hex/HexDocs public API and can mislead consumers if stale or incomplete. | README, stable docs, ExDoc extras, package files, and release-preview inventory. |
| docs -> peer comparison claims | Public comparison copy can misrepresent peer deployment models or Scoria's unbuilt future capabilities. | Peer names, source links, current Scoria claims, deferred future claims. |

## Threat Register

| Threat Ref | Category | Severity | Component | Disposition | Mitigation | Status | Evidence |
|------------|----------|----------|-----------|-------------|------------|--------|----------|
| 47-01/T-47-01 | Tampering | medium | README.md version/install guidance | mitigate | README-scoped stale-version contract helpers and tests per D-06. | closed | `lib/scoria/adopter_doc_contract.ex:32`, `test/scoria/adoption_surface_test.exs:196` |
| 47-01/T-47-02 | Elevation | high | Scope doctrine docs | mitigate | Contracts keep auth, authorization, tenant membership, role values, thresholds, and escalation policy host-owned per D-03/D-04. | closed | `test/scoria/scope_doctrine_contract_test.exs:23`, `test/scoria/scope_doctrine_contract_test.exs:103`, `README.md:37` |
| 47-01/T-47-03 | Information Disclosure | medium | Public docs comparison and future-claim copy | mitigate | Comparison-guide deferred-claim guards and RED-first pattern per D-07. | closed | `lib/scoria/adopter_doc_contract.ex:78`, `test/scoria/adoption_surface_test.exs:185`, `docs/scoria_vs_external_llm_ops.md:73` |
| 47-01/T-47-SC | Tampering | medium | package installs | accept | No npm, pip, cargo, or Hex dependency install introduced in Phase 47. | closed | Accepted risk AR-47-01-SC; phase commits touched docs/tests/package metadata only; `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, and `Cargo.lock` absent. |
| 47-02/T-47-01 | Tampering | medium | README install/status copy | mitigate | Replace stale README `0.1.1` status/fallback with `0.1.2` baseline and contract-test it per D-06. | closed | `README.md:85`, `README.md:320`, `test/scoria/adoption_surface_test.exs:196`; literal grep for stale `v0.1.1`, stale current release, and `OpenInference` returned no README matches. |
| 47-02/T-47-02 | Elevation | high | Scope doctrine table and guide copy | mitigate | Public table assigns auth, authz, tenant membership, role values, thresholds, escalation rules, business truth, and end-user surfaces to the host per D-03/D-04. | closed | `README.md:34`, `README.md:37`, `README.md:38`, `README.md:40`, `docs/operator_verification.md:7`, `test/scoria/scope_doctrine_contract_test.exs:118` |
| 47-02/T-47-03 | Information Disclosure | medium | README future capability claims | mitigate | Remove README implication of OpenInference export/substrate and keep deferred seed claims out of first-screen copy per D-05. | closed | `docs/scoria_vs_external_llm_ops.md:77`, `test/scoria/adoption_surface_test.exs:168`; `rg 'OpenInference' README.md` returned no matches. |
| 47-02/T-47-SC | Tampering | medium | package installs | accept | No package install or dependency change introduced in Plan 47-02. | closed | Accepted risk AR-47-02-SC; commits `b9f6c661` and `281d7611` touched README/adopter docs only; no lockfile changes. |
| 47-03/T-47-01 | Tampering | medium | Package docs inventory | mitigate | Add comparison guide to mix.exs, release-preview required paths, and package surface tests. | closed | `mix.exs:133`, `mix.exs:175`, `lib/mix/tasks/scoria.release_preview.ex:15`, `test/scoria/package_surface_test.exs:12`, `test/mix/tasks/scoria.release_preview_test.exs:17` |
| 47-03/T-47-02 | Information Disclosure | medium | Comparison guide | mitigate | Source-link peer posture and separate current Scoria claims from deferred future seeds per D-05. | closed | `docs/scoria_vs_external_llm_ops.md:60`, `docs/scoria_vs_external_llm_ops.md:66`, `docs/scoria_vs_external_llm_ops.md:73`, `test/scoria/adoption_surface_test.exs:133` |
| 47-03/T-47-03 | Spoofing | low | Peer name collision | mitigate | Require exact `Arize Phoenix` spelling to avoid confusion with the Phoenix web framework. | closed | `lib/scoria/adopter_doc_contract.ex:40`, `docs/scoria_vs_external_llm_ops.md:69`, `docs/scoria_vs_external_llm_ops.md:71`, `test/scoria/adoption_surface_test.exs:146` |
| 47-03/T-47-SC | Tampering | medium | package installs | accept | No new package installation introduced; Package Legitimacy Audit says none. | closed | Accepted risk AR-47-03-SC; `0a88cd69` only added `docs/scoria_vs_external_llm_ops.md` to docs/package/release-preview inventory; no lockfile changes. |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-47-01-SC | 47-01/T-47-SC | Phase 47-01 introduced docs contract helpers/tests only (`3f5c80ca`, `2916c974`) and did not add npm, pip, cargo, or Hex dependencies. | Plan-time disposition, verified by security audit | 2026-07-10 |
| AR-47-02-SC | 47-02/T-47-SC | Phase 47-02 edited README/adopter Markdown only (`b9f6c661`, `281d7611`) and introduced no package install or dependency change. | Plan-time disposition, verified by security audit | 2026-07-10 |
| AR-47-03-SC | 47-03/T-47-SC | Phase 47-03 added a packaged guide and inventory/test coverage (`def308d7`, `0a88cd69`, `1273fac9`); `mix.exs` changes were docs/package path additions only, not dependency changes. | Plan-time disposition, verified by security audit | 2026-07-10 |

## Summary Threat Flags

| Summary | Threat Flags |
|---------|--------------|
| 47-01-SUMMARY.md | None |
| 47-02-SUMMARY.md | None |
| 47-03-SUMMARY.md | None |

Unregistered flags: none.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-10 | 12 | 12 | 0 | gsd-security-auditor |

### Security Audit 2026-07-10

| Metric | Count |
|--------|-------|
| Threats found | 12 |
| Closed | 12 |
| Open | 0 |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] Summary threat flags incorporated
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-10
