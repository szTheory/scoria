---
phase: 47
slug: readme-first-screen-positioning-and-scope-doctrine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-10
---

# Phase 47 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` aliases and preferred environments |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | Quick docs contracts under 10 seconds; full suite varies by environment |

---

## Sampling Rate

- **After every task commit:** Run the quick docs-contract command when README or stable docs change.
- **After every plan wave:** Run the quick docs-contract command.
- **Before `/gsd:verify-work`:** Run `mix ci`, plus `mix scoria.release_preview` if packaged docs or release-surface files change.
- **Max feedback latency:** Keep focused docs-contract checks under 10 seconds for normal task commits.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-W0-01 | TBD | 0 | POS-03 | T-47-02 | README scope language keeps host-owned auth, roles, thresholds, and escalation rules outside Scoria ownership. | docs contract | `MIX_ENV=test mix test test/scoria/scope_doctrine_contract_test.exs` | yes | pending |
| 47-POS-01 | TBD | TBD | POS-01 | T-47-03 | README opens with plain-English embedded Phoenix positioning before coined vocabulary. | docs contract | quick docs-contract command | partial | pending |
| 47-POS-02 | TBD | TBD | POS-02 | T-47-02 | README and stable docs state n=1 default lens, CORE/ADJACENT/NOT-OURS boundaries, and reviewer/operator roles. | docs contract | quick docs-contract command | partial | pending |
| 47-POS-03 | TBD | TBD | POS-03 | T-47-02 | Owns-vs-delegates table assigns authz, tenant membership, role values, thresholds, and escalation policy to the host. | docs contract | quick docs-contract command | partial | pending |
| 47-POS-04 | TBD | TBD | POS-04 | T-47-03 | Comparison guide avoids hosted-only framing and states external LLM-ops tradeoffs honestly. | docs contract | quick docs-contract command plus `mix scoria.release_preview` if packaged docs change | no | pending |

---

## Wave 0 Requirements

- [ ] Stabilize the existing focused failure in `test/scoria/scope_doctrine_contract_test.exs` by aligning the contract and README scope language.
- [ ] Add first-screen order assertions for POS-01 in `test/scoria/adoption_surface_test.exs` or a new narrow README positioning test.
- [ ] Add stale `0.1.1` README refutes and current install-fallback assertions through existing contract helpers.
- [ ] Add package/docs list assertions if the phase creates `docs/scoria_vs_external_llm_ops.md`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| External LLM-ops comparison nuance | POS-04 | Peer product language changes quickly and exact claims require human review. | Review `docs/scoria_vs_external_llm_ops.md` against the cited official docs before release. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated docs-contract verification.
- [ ] Wave 0 covers all missing references from research.
- [ ] No watch-mode flags.
- [ ] Feedback latency under 10 seconds for focused docs-contract checks.
- [ ] `nyquist_compliant: true` set in frontmatter after plans assign concrete task IDs and Wave 0 is complete.

**Approval:** pending
