---
phase: 46
slug: terminology-and-public-vocabulary-migration
status: draft
nyquist_compliant: true
wave_0_complete: false
early_guard_plan: 46-01
created: 2026-07-09
---

# Phase 46 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Mix 1.19.5 |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/terminology_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` plus `mix scoria.release_preview` |
| **Estimated runtime** | Focused suite: ~10-30 seconds; full suite depends on DB availability |

---

## Sampling Rate

- **After every task commit:** Run the focused test covering the changed surface, usually docs/package/changelog/terminology contracts.
- **After every plan wave:** Run the quick command above and any focused component tests touched by run-inspection adapter renames.
- **Before `/gsd:verify-work`:** Run `mix scoria.release_preview` and the full focused Phase 46 contract set; run full `mix test --warnings-as-errors` if DB availability is confirmed or shared runtime code was touched.
- **Max feedback latency:** Prefer under 30 seconds for focused checks; do not allow three consecutive task commits without an automated check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 46-01 | 1 | TERM-02 | T-46-01-D | Verification suite public alias preserves command SSOT | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_suites_test.exs test/scoria/verification_lanes_test.exs` | New suite test; existing lanes test | pending |
| 46-01-02 | 46-01 | 1 | TERM-02, TERM-04 | T-46-01-I / T-46-01-R | Reviewer broadcast alias and runtime call sites preserve tenant-scoped PubSub behavior | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/observe/reviewer_broadcast_test.exs test/scoria/observe/operator_broadcast_test.exs` | New reviewer test; existing operator test | pending |
| 46-01-03 | 46-01 | 1 | TERM-03 | T-46-01-T | Storage-surface terminology guard blocks schema/storage renames before docs migration | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` | `test/scoria/terminology_contract_test.exs` created in 46-01 | pending |
| 46-02-01 | 46-02 | 1 | TERM-02, TERM-04 | T-46-02-E | ReviewerSurface alias preserves dashboard tenant authority | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/reviewer_surface_test.exs test/scoria_web/dashboard_scope_source_guard_test.exs test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs test/scoria_web/live/dashboard_auth_workflows_test.exs` | New reviewer test; existing guards | pending |
| 46-03-01 | 46-03 | 1 | TERM-02, TERM-04 | T-46-03-T / T-46-03-I | Semantic cache profile and scoped-context aliases reuse existing validation paths | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/semantic_cache/profile_test.exs test/scoria/semantic_cache/lane_test.exs test/scoria/runtime_test.exs test/scoria/runtime/semantic_fast_path_test.exs` | New profile test; existing runtime tests | pending |
| 46-04-01 | 46-04 | 2 | TERM-02, TERM-03 | T-46-04-02 | Trace-named private adapters preserve storage/proof field names | component/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/components/delegated_trace_component_test.exs test/scoria_web/components/replay_trace_notebook_component_test.exs test/scoria_web/components/semantic_cache_trace_notebook_component_test.exs test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/live/workflow_live_test.exs` | New trace component tests plus legacy semantic wrapper test | pending |
| 46-05-01 | 46-05 | 2 | TERM-02, TERM-03 | T-46-05-01 | Remote/incident copy preserves evidence where it means support proof | component/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/components/incident_evidence_component_test.exs` | Existing incident component test | pending |
| 46-06-01 | 46-06 | 3 | TERM-01, TERM-02 | T-46-06-02 | Glossary defines final vocabulary and evidence/trace boundary | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs` | `test/scoria/glossary_contract_test.exs` created in 46-06 | pending |
| 46-06-02 | 46-06 | 3 | TERM-01 | T-46-06-03 | Glossary is exposed through ExDoc/package/release-preview/Hex consumer surfaces | contract/unit | `MIX_ENV=test mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs` | Existing package and Hex consumer tests updated | pending |
| 46-07-01 | 46-07 | 4 | TERM-01, TERM-02, TERM-03 | T-46-07-02 | README/guides use final vocabulary without path churn or evidence misuse | contract/unit | `bash -lc 'set -euo pipefail; ! rg -n "Keystone|v2\\.0 Relay|The Four Lanes" README.md docs; MIX_ENV=test mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs'` | Existing adoption test; terminology test expanded | pending |
| 46-08-01 | 46-08 | 5 | TERM-04, TERM-03 | T-46-08-02 | README/CHANGELOG explain unreleased terminology migration and final proof passes | contract/unit | `bash -lc 'set -euo pipefail; ! rg -n "trace_refs" lib config priv mix.exs docs README.md CHANGELOG.md; MIX_ENV=dev mix scoria.release_preview; MIX_ENV=test mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/terminology_contract_test.exs'` | Existing changelog/hex tests updated plus release preview | pending |

---

## Early Guard And Exposure Requirements

- [ ] Wave 1 / Plan 46-01 creates `test/scoria/terminology_contract_test.exs` before README/docs/CHANGELOG migration tasks.
- [ ] Wave 1 / Plan 46-01 no-schema guard proves no storage/migration introduction of `trace_refs`, storage `scoped_context`, or storage `cache_key`.
- [ ] Wave 1 / Plan 46-01 no-schema guard asserts preservation of `evidence_refs`, `projected_context`, and `lane_key` in their expected storage/schema/migration sources.
- [ ] Wave 3 / Plan 46-06 creates `docs/glossary.md`, wires it into ExDoc/package/release-preview surfaces, and updates `test/scoria/hex_consumer_contract_test.exs`.
- [ ] Wave 4 / Plan 46-07 expands `test/scoria/terminology_contract_test.exs` for final README/docs vocabulary and retired wording once the docs are migrated.
- [ ] Wave 5 / Plan 46-08 updates `test/scoria/changelog_contract_test.exs` and runs the focused phase contract set, including `test/scoria/hex_consumer_contract_test.exs`.

The glossary itself is intentionally Wave 3, after compatibility aliases and trace/copy boundaries exist per D-05. The storage/no-schema guard is the early guard that README/docs/CHANGELOG migration depends on.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Glossary terminology reads coherently to adopters and does not sound like internal release planning | TERM-01, TERM-02 | Voice and clarity are partly editorial | Review `docs/glossary.md`, README upgrade note, and CHANGELOG note after automated drift tests pass. |
| Trace/evidence boundary is semantically correct in changed prose | TERM-02, TERM-03 | Automated tests can catch blocked strings, but not every meaning distinction | Spot-check every changed paragraph containing `trace` or `evidence`; confirm evidence still means proof/citation/grounding and trace means run inspection. |
| Historical changelog wording remains honest | TERM-04 | Historical sections may legitimately contain old terms | Confirm the new `[Unreleased]` note explains current vocabulary while older release notes remain historically accurate. |

---

## Threat References

| Ref | Threat | Mitigation |
|-----|--------|------------|
| T-46-01 | Schema rename causing data loss or broken proof references | No migration; add source-scan guard for `trace_refs`, storage `scoped_context`, storage `cache_key`, and preservation of `evidence_refs`, `projected_context`, and `lane_key`. |
| T-46-02 | Copy changes weakening tenant authority language | Keep Phase 44 host-owned scope doctrine and avoid wording that treats URL tenant values as authority. |
| T-46-03 | Alias accepting unsafe scoped context values | Normalize aliases through existing validation behavior and reject unsafe scoped/projected context values through current runtime params paths. |
| T-46-04 | Observability overclaim hiding missing trace substrate | State trace vocabulary alignment only; defer OpenInference-compatible export/substrate claims to SEED-007. |

---

## Validation Sign-Off

- [x] All planned tasks must have automated verify commands or explicit early-guard dependencies.
- [x] Sampling continuity requires no three consecutive tasks without automated verification.
- [x] Wave 1 early guard covers storage/no-schema test references before docs migration; Wave 3 covers Hex consumer package exposure.
- [x] No watch-mode flags are used.
- [x] Focused feedback latency target is documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
