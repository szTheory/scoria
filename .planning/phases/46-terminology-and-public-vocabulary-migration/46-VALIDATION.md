---
phase: 46
slug: terminology-and-public-vocabulary-migration
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/changelog_contract_test.exs test/scoria/terminology_contract_test.exs` |
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
| 46-01-01 | TBD | 0 | TERM-01 | T-46-01 / T-46-04 | Glossary is packaged and exposes final vocabulary without overclaiming trace substrate support | contract/unit | `mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/terminology_contract_test.exs` | `test/scoria/package_surface_test.exs` yes; `test/scoria/terminology_contract_test.exs` Wave 0 | pending |
| 46-01-02 | TBD | 0 | TERM-02 | T-46-02 / T-46-03 | Public aliases normalize through existing validation paths and do not weaken host-owned scope language | contract/unit | `mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs` | `test/scoria/adoption_surface_test.exs` yes; terminology guard Wave 0 | pending |
| 46-01-03 | TBD | 0 | TERM-03 | T-46-01 / T-46-04 | RAG/citation evidence remains evidence; surface-sense evidence becomes trace; no schema rename appears | contract/unit | `mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` | Wave 0 | pending |
| 46-01-04 | TBD | 0 | TERM-04 | T-46-04 | README and CHANGELOG describe unreleased pre-1.0 terminology changes and compatibility status | contract/unit | `mix test --warnings-as-errors test/scoria/changelog_contract_test.exs test/scoria/hex_consumer_contract_test.exs` | Existing tests yes; updates required | pending |

---

## Wave 0 Requirements

- [ ] `test/scoria/terminology_contract_test.exs` - scan current adopter docs, README, selected public moduledocs, and copy surfaces for final vocabulary and blocked legacy strings.
- [ ] No-schema-rename guard in `test/scoria/terminology_contract_test.exs` or `test/scoria/no_schema_rename_contract_test.exs` - prove no `trace_refs` migration or `evidence_refs` rename was introduced.
- [ ] `docs/glossary.md` - committed glossary required by TERM-01.
- [ ] Update `test/scoria/package_surface_test.exs`, `test/scoria/adoption_surface_test.exs`, `test/scoria/changelog_contract_test.exs`, and `test/scoria/hex_consumer_contract_test.exs` to match final vocabulary and upgrade-note expectations.

*If a Wave 0 item is split into a later plan task, that plan must still run its focused contract before any docs/copy task depends on it.*

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
| T-46-01 | Schema rename causing data loss or broken proof references | No migration; add source-scan guard for `trace_refs` and `evidence_refs` preservation. |
| T-46-02 | Copy changes weakening tenant authority language | Keep Phase 44 host-owned scope doctrine and avoid wording that treats URL tenant values as authority. |
| T-46-03 | Alias accepting unsafe scoped context values | Normalize aliases through existing validation behavior and reject unsafe scoped/projected context values through current runtime params paths. |
| T-46-04 | Observability overclaim hiding missing trace substrate | State trace vocabulary alignment only; defer OpenInference-compatible export/substrate claims to SEED-007. |

---

## Validation Sign-Off

- [x] All planned tasks must have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity requires no three consecutive tasks without automated verification.
- [x] Wave 0 covers all missing test references identified by research.
- [x] No watch-mode flags are used.
- [x] Focused feedback latency target is documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
