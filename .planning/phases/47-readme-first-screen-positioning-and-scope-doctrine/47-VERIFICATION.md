---
phase: 47-readme-first-screen-positioning-and-scope-doctrine
verified: 2026-07-10T14:18:31Z
status: passed
score: "10/10 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 47: README First-Screen Positioning and Scope Doctrine Verification Report

**Phase Goal:** A Phoenix adopter immediately understands what Scoria is, who it is for, where its boundary is, and why embedded governance differs from hosted LLM-ops.
**Verified:** 2026-07-10T14:18:31Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | README opens with a plain-English embedded Phoenix paragraph before coined capability or verification-suite vocabulary. | VERIFIED | `README.md:14` starts with "Scoria is an Elixir/Phoenix library..." before `Choose Your Capability` at `README.md:47`; `test/scoria/adoption_surface_test.exs:103` enforces this ordering. |
| 2 | README and stable docs state the n=1 roles-not-headcount lens, Core/Adjacent/Not Scoria boundaries, and reviewer/operator role clearly. | VERIFIED | `README.md:16-22`, `docs/adoption_lanes.md:8`, and `docs/operator_verification.md:7`; locked by `test/scoria/adoption_surface_test.exs:114`. |
| 3 | An adopter-facing owns-vs-delegates table makes the P1-P6 scope doctrine concrete. | VERIFIED | `README.md:30-45` has the required table, headers, rows, and host-owned responsibilities; `test/scoria/scope_doctrine_contract_test.exs:103` verifies headers, rows, host-owned terms, and no public P1-P6 row labels. |
| 4 | A stable comparison page explains Scoria vs hosted/external LLM-ops with honest strengths and ceded tradeoffs. | VERIFIED | `docs/scoria_vs_external_llm_ops.md:1-84` includes current Scoria claims, host-owned boundaries, ceded strengths, peer posture/source links, and deferred/not-current claims; official peer docs were checked during verification. |
| 5 | README version references and install fallback examples no longer point at stale `0.1.1` guidance. | VERIFIED | `README.md:84-90` uses Hex primary plus `v0.1.2` fork/pinned-patch fallback; `README.md:320` states current release `0.1.2`; `rg` found no README `0.1.1`/`v0.1.1` matches. |
| 6 | Regression contracts guard README positioning, persona, stale-version cleanup, scope table, and comparison guide claims. | VERIFIED | `lib/scoria/adopter_doc_contract.ex:24-100` defines contract constants; tests at `test/scoria/adoption_surface_test.exs:103-203` and `test/scoria/scope_doctrine_contract_test.exs:103-125` exercise them. |
| 7 | Stable docs cross-link the public scope table and retain host-owned auth/policy language. | VERIFIED | `docs/adoption_lanes.md:8,36-67` and `docs/operator_verification.md:7,24-71` link or name the table and preserve host-owned authentication, authorization, role, policy, threshold, and business-truth wording. |
| 8 | The comparison guide names LangSmith, Langfuse, Braintrust, and Arize Phoenix exactly and source-links peer posture. | VERIFIED | `docs/scoria_vs_external_llm_ops.md:64-71`; `test/scoria/adoption_surface_test.exs:146-154` checks required peer names and source links. |
| 9 | The comparison guide separates safe current claims from deferred seeds and avoids hosted-only peer framing. | VERIFIED | Current claims are scoped to `docs/scoria_vs_external_llm_ops.md:20-32`; deferred claims are in `docs/scoria_vs_external_llm_ops.md:73-82`; `test/scoria/adoption_surface_test.exs:156-193` refutes forbidden current claims and hosted-only wording. |
| 10 | The comparison guide ships through docs, package, release-preview, and stable-doc terminology surfaces. | VERIFIED | `mix.exs:127-140` docs extras, `mix.exs:148-182` package files, `lib/mix/tasks/scoria.release_preview.ex:5-23`, `test/scoria/package_surface_test.exs:6-39`, `test/mix/tasks/scoria.release_preview_test.exs:7-52`, and `test/scoria/terminology_contract_test.exs:10-20`. |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `README.md` | First-screen positioning, persona boundaries, ownership table, comparison link, version cleanup. | VERIFIED | Substantive Markdown; wired from package docs extras and docs contracts. |
| `docs/adoption_lanes.md` | Capability guide cross-link to ownership table and n=1 persona language. | VERIFIED | Lines 5-8 and 36-67 preserve capability order and host-owned scope boundary. |
| `docs/operator_verification.md` | Reviewer verification guide cross-link and host-owned auth/policy language. | VERIFIED | Lines 3-9 and 24-71 preserve reviewer/operator compatibility and dashboard-scope proof. |
| `docs/scoria_vs_external_llm_ops.md` | Stable POS-04 comparison guide. | VERIFIED | Exists with required title, peer names, current claims, ceded strengths, deferred claims, and source links. |
| `mix.exs` | Docs extras and package files include comparison guide. | VERIFIED | `docs/scoria_vs_external_llm_ops.md` appears in both lists exactly once. |
| `lib/mix/tasks/scoria.release_preview.ex` | Release-preview required paths include comparison guide. | VERIFIED | Required path list includes `docs/scoria_vs_external_llm_ops.md`; `mix scoria.release_preview` passed. |
| `lib/scoria/adopter_doc_contract.ex` | README/comparison contract helpers. | VERIFIED | Exports the expected zero-arity helpers; GSD artifact helper produced a false negative because Elixir `def name, do:` syntax does not include literal `/0` text. |
| `test/scoria/adoption_surface_test.exs` | README first-screen, persona, stale-version, and comparison guide assertions. | VERIFIED | Tests read README/comparison docs and assert ordering, exact persona copy, source links, current/deferred sections, and refutes. |
| `test/scoria/scope_doctrine_contract_test.exs` | Public owns-vs-delegates table contract. | VERIFIED | Verifies table title, headers, rows, host-owned responsibilities, and no P1-P6 public row labels. |
| `test/scoria/package_surface_test.exs` | Package surface includes comparison guide. | VERIFIED | Docs extras and package files list comparison guide. |
| `test/mix/tasks/scoria.release_preview_test.exs` | Release-preview inventory includes comparison guide. | VERIFIED | Required paths contract includes comparison guide. |
| `test/scoria/terminology_contract_test.exs` | Stable docs list includes comparison guide. | VERIFIED | Stable adopter docs include `docs/scoria_vs_external_llm_ops.md`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `test/scoria/adoption_surface_test.exs` | `README.md` | `File.read!(@readme)` order/persona/stale-version assertions | VERIFIED | Manual grep found README reads at lines 40, 82, 104, 115, 127, 197, 224, and 256. GSD key-link helper missed this due escaped pattern mismatch. |
| `test/scoria/scope_doctrine_contract_test.exs` | `README.md` | `public_scope_table_source!/0` and `File.read!(@readme)` | VERIFIED | Reads README and extracts the scope table section. |
| `README.md` | `docs/adoption_lanes.md` | Capability guide link | VERIFIED | `README.md:63`. |
| `README.md` | `docs/scoria_vs_external_llm_ops.md` | Comparison guide link | VERIFIED | `README.md:22`. |
| `docs/adoption_lanes.md` | `README.md` | Ownership table cross-link | VERIFIED | `docs/adoption_lanes.md:8`. |
| `docs/operator_verification.md` | `README.md` | Ownership table cross-link | VERIFIED | `docs/operator_verification.md:7`. |
| `mix.exs` | `docs/scoria_vs_external_llm_ops.md` | Docs extras and package files | VERIFIED | `mix.exs:133` and `mix.exs:175`. |
| `lib/mix/tasks/scoria.release_preview.ex` | `docs/scoria_vs_external_llm_ops.md` | `required_package_paths/0` | VERIFIED | `lib/mix/tasks/scoria.release_preview.ex:15`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `README.md` and `docs/*.md` | Static Markdown content | Repository Markdown files | N/A - static docs, directly read by tests and packaged by Mix | VERIFIED |
| `mix.exs` docs/package lists | `project[:docs][:extras]`, `project[:package][:files]` | `Mix.Project.config()` | Yes - package tests inspect the actual Mix project config | VERIFIED |
| `lib/mix/tasks/scoria.release_preview.ex` | `@required_package_paths` | Mix task module attribute | Yes - release-preview command uses the list to verify unpacked Hex preview paths | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| POS-01/POS-02/POS-03 docs contracts pass. | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs test/scoria/changelog_contract_test.exs test/scoria/glossary_contract_test.exs` | 46 tests, 0 failures. | PASS |
| Package/release/Hex contract surface passes. | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/hex_consumer_contract_test.exs` | 18 tests, 0 failures. | PASS |
| Review-focused Phase 47 package/docs contracts pass. | `MIX_ENV=test mix test test/mix/tasks/scoria.release_preview_test.exs test/scoria/adoption_surface_test.exs test/scoria/package_surface_test.exs test/scoria/scope_doctrine_contract_test.exs test/scoria/terminology_contract_test.exs` | 42 tests, 0 failures. | PASS |
| Packaged docs/release preview includes the comparison guide. | `mix scoria.release_preview` | Built docs, unpacked Hex preview, and reported `Release preview passed`. | PASS |
| Full repository merge gate remains broader than Phase 47. | `mix ci` | Failed: `format --check-formatted`, `adoption`, and `runtime_to_handoff`; release preview, semantic fast path, knowledge, and connector passed. | RESIDUAL DEBT - not a Phase 47 gap |
| Known runtime failure location. | `MIX_ENV=test mix test test/scoria/runtime_integration_test.exs:159` | 1 test, 1 failure: timeout in `operator-visible workflow page stays aligned with the public runtime contract`. | RESIDUAL DEBT - runtime/dashboard behavior outside Phase 47 docs/package scope |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| No Phase 47 probes declared or found. | `find scripts -path '*/tests/probe-*.sh' -type f` and phase grep | No probe paths. | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| POS-01 | 47-01, 47-02 | README first screen explains Scoria as an embedded Phoenix library before coined vocabulary. | SATISFIED | `README.md:14`, `test/scoria/adoption_surface_test.exs:103`, focused docs tests passed. |
| POS-02 | 47-01, 47-02 | Adopter can identify who Scoria is for/not for and n=1 reviewer/operator persona. | SATISFIED | `README.md:16-22`, `docs/adoption_lanes.md:8`, `docs/operator_verification.md:7`, focused docs tests passed. |
| POS-03 | 47-01, 47-02 | Adopter can see what Scoria owns vs what host app owns through concrete table. | SATISFIED | `README.md:30-45`, `test/scoria/scope_doctrine_contract_test.exs:103`, focused docs tests passed. |
| POS-04 | 47-03 | Adopter can compare Scoria to hosted/external LLM-ops tools with honest tradeoffs. | SATISFIED | `docs/scoria_vs_external_llm_ops.md:1-84`, package/release-preview wiring, source links checked against official peer docs on 2026-07-10. |

No orphaned Phase 47 requirements were found. `.planning/REQUIREMENTS.md` maps POS-01, POS-02, POS-03, and POS-04 to Phase 47; all are claimed by phase plans and verified above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `docs/adoption_lanes.md` | 66 | `not available` | INFO | Intended fail-closed dashboard copy, not placeholder content. |
| `docs/operator_verification.md` | 69 | `not available` | INFO | Intended fail-closed dashboard copy, not placeholder content. |
| `test/scoria/adoption_surface_test.exs` | 385 | `TBD` | INFO | Appears inside a refute assertion guarding docs; not unresolved debt. |
| `test/scoria/adoption_surface_test.exs` | 507 | `not available` | INFO | Test assertion for intended fail-closed dashboard copy. |

No blocker debt markers (`TBD`, `FIXME`, `XXX`) were found in Phase 47 modified production/docs files as unresolved debt.

### External Source Check

POS-04 source-linked peer posture was checked against official docs during verification:

| Peer | Source | Verification Note |
|------|--------|-------------------|
| LangSmith | `https://docs.langchain.com/langsmith/self-hosted` | Official docs describe self-hosted LangSmith and cloud-provider setup, so the guide correctly avoids "all peers are hosted SaaS." |
| Langfuse | `https://langfuse.com/self-hosting` | Official docs describe Langfuse Cloud plus self-hosting via Docker, local/VM, Kubernetes/Helm, and cloud Terraform options. |
| Braintrust | `https://www.braintrust.dev/docs/admin/self-hosting` | Official docs describe a self-hosted/data-plane deployment model and shared operational responsibility. |
| Arize Phoenix | `https://arize.com/docs/phoenix/self-hosting` | Official docs expose Phoenix self-hosting; the guide uses the exact name "Arize Phoenix." |

### Human Verification Required

None for Phase 47 completion. The only validation-strategy human note concerned peer comparison nuance; this verification checked the guide against the linked official peer docs on 2026-07-10 and the guide itself stays source-linked for future release review.

### Gaps Summary

No Phase 47 gaps found. The goal is achieved in the codebase/docs.

Residual unrelated repo debt remains:

- `mix ci` fails `format --check-formatted` on repository-wide formatting drift outside the Phase 47 docs/package files. A grep against the format output did not identify the actual Phase 47 files as format offenders; visible matches were fixture/context references.
- `mix ci` fails `adoption` and `runtime_to_handoff` because `test/scoria/runtime_integration_test.exs:159` times out in the operator-visible workflow page test. A focused rerun reproduced that failure. This is runtime/dashboard behavior, not README/docs/package positioning.

---

_Verified: 2026-07-10T14:18:31Z_
_Verifier: the agent (gsd-verifier)_
