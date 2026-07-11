---
phase: 49
slug: ai-accessible-docs-and-docs-verification-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-10
---

# Phase 49 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors` |
| Docs diagnostic command | `MIX_ENV=dev mix docs --warnings-as-errors` |
| Phase gate command | `MIX_ENV=dev mix scoria.release_preview` |
| Estimated runtime | ~120 seconds for focused contracts plus docs generation |

---

## Sampling Rate

- **After every task commit:** Run the focused test command for the touched surface.
- **After docs warning cleanup tasks:** Run `MIX_ENV=dev mix docs --warnings-as-errors`.
- **After every plan wave:** Run the quick run command plus `MIX_ENV=dev mix scoria.release_preview`.
- **Before `/gsd:verify-work`:** `MIX_ENV=dev mix scoria.release_preview` must be warning-clean.
- **Max feedback latency:** 180 seconds for focused contracts; docs generation may take longer but must run before hardening the release-preview gate.

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| DOCS-04 | Docs generation is warning-clean and release preview runs docs with warnings-as-errors. | integration/source contract | `MIX_ENV=dev mix docs --warnings-as-errors`; `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs --warnings-as-errors` | Partial: release-preview test exists, warnings-as-errors assertion missing | pending |
| AI-01 | Root `llms.txt` and `AGENTS.md` point to public facade, guide ladder, glossary, capabilities, and verification suites. | docs contract | `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs --warnings-as-errors` | Missing: add or extend AI docs contract | pending |
| AI-02 | AI docs distinguish canonical source docs from generated ExDoc output and avoid stale/internal planning vocabulary. | docs/negative contract | `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors` | Partial: terminology test exists, AI source/generated test missing | pending |

---

## Wave 0 Requirements

- [ ] `test/scoria/ai_doc_contract_test.exs` - covers AI-01 and AI-02 root docs/source-generated boundaries.
- [ ] `lib/scoria/ai_doc_contract.ex` or extension of `lib/scoria/adopter_doc_contract.ex` - centralizes root AI doc required paths and fragments.
- [ ] `test/mix/tasks/scoria.release_preview_test.exs` - asserts docs run with `--warnings-as-errors`.
- [ ] `test/scoria/package_surface_test.exs` - asserts the package decision for `llms.txt`, `AGENTS.md`, and `GEMINI.md`.
- [ ] Current ExDoc warnings are cleaned before release preview is flipped to warnings-as-errors.

---

## Manual-Only Verifications

All phase behaviors should have automated verification through ExUnit contracts and docs/release-preview commands.

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references for DOCS-04, AI-01, and AI-02.
- [ ] No watch-mode flags.
- [ ] Feedback latency is documented for focused tests and docs generation.
- [ ] `nyquist_compliant: true` set in frontmatter after executable plans cover this strategy.

**Approval:** pending
