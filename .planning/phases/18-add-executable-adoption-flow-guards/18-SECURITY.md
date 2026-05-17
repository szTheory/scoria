---
phase: 18
slug: add-executable-adoption-flow-guards
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-17
---

# Phase 18 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| public docs -> host app integrator | README and the Phoenix guide teach adopters how to use the stable public facade and route surfaces. | `session_id`, `run_id`, `Scoria` facade calls, `/scoria/workflows/:run_id` route semantics |
| pure examples -> stateful runtime proof | Doctests may prove public identity and facade shapes, but not end-to-end runtime or operator behavior. | moduledoc examples, doctest execution, facade return-shape expectations |
| runtime integration seam -> docs example | The Phoenix guide must stay derived from checked runtime truth rather than drifting as standalone prose. | controller example fragments, resume semantics, operator route semantics |
| checked example source -> guide prose | One shared source of truth constrains the canonical docs fragments without requiring whole-guide execution. | shared identity/session fragments, route pattern, runtime contract fragments |
| focused lane -> default suite | The fast adoption lane must remain only a subset runner and must not imply the core guards are optional under `mix test`. | named Mix task file list, CI command, maintainer verification commands |
| installer and operator guidance -> operator proof | Installer next steps and operator docs must map to the actual acceptance harness and durable run evidence. | install commands, runtime readback commands, operator route checks, optional knowledge-lane commands |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-18-01-01 | S | `README.md` | mitigate | README keeps `session_id` and `run_id` distinct and requires resume by exact `run_id`, with semantic guards asserting those anchors in [README.md](/Users/jon/projects/scoria/README.md:52) and [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:10). | closed |
| T-18-01-02 | T | `test/scoria/adoption_surface_test.exs` | mitigate | The README guard asserts stable public nouns and snippet sources instead of prose snapshots in [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:10). | closed |
| T-18-01-03 | R | `lib/scoria.ex` | mitigate | Public facade examples are executable moduledoc doctests in [lib/scoria.ex](/Users/jon/projects/scoria/lib/scoria.ex:19), covered by the passing `mix test.adoption` lane. | closed |
| T-18-01-04 | I | `lib/scoria/identity.ex` | mitigate | Identity examples stay at the normalization boundary and avoid internal workflow setup in [lib/scoria/identity.ex](/Users/jon/projects/scoria/lib/scoria/identity.ex:17). | closed |
| T-18-01-05 | D | `README.md` | mitigate | README preserves the default verification lane and the clearly optional knowledge lane in [README.md](/Users/jon/projects/scoria/README.md:81), preventing heavier prerequisites from blocking core adoption. | closed |
| T-18-01-06 | E | doctest coverage | mitigate | Doctests remain narrow while runtime/operator proof stays in integration seams; the split is enforced by docs/tests in [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:10) and [test/scoria/runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:120). | closed |
| T-18-02-01 | S | `docs/phoenix_runtime_example.md` | mitigate | The guide explicitly distinguishes `run_id` from `session_id` and ties resume to exact `run_id` in [docs/phoenix_runtime_example.md](/Users/jon/projects/scoria/docs/phoenix_runtime_example.md:15), with runtime proof in [test/scoria/runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:120). | closed |
| T-18-02-02 | T | guide code fragments | mitigate | Canonical guide fragments are derived from a checked helper source via [test/support/scoria/adoption_example.ex](/Users/jon/projects/scoria/test/support/scoria/adoption_example.ex:23) and enforced by [test/scoria/phoenix_example_source_test.exs](/Users/jon/projects/scoria/test/scoria/phoenix_example_source_test.exs:8). | closed |
| T-18-02-03 | R | `test/support/scoria/adoption_example.ex` | mitigate | The shared helper centralizes the guide contract in one executable owner at [test/support/scoria/adoption_example.ex](/Users/jon/projects/scoria/test/support/scoria/adoption_example.ex:8). | closed |
| T-18-02-04 | I | docs example | mitigate | The Phoenix guide stays on the public `Scoria` and `Scoria.Identity` surfaces rather than internal workflow APIs in [docs/phoenix_runtime_example.md](/Users/jon/projects/scoria/docs/phoenix_runtime_example.md:24). | closed |
| T-18-02-05 | D | fixture-app pressure | mitigate | The guide explicitly rejects a fixture app and whole-guide execution in [docs/phoenix_runtime_example.md](/Users/jon/projects/scoria/docs/phoenix_runtime_example.md:158). | closed |
| T-18-02-06 | E | operator guide boundary | mitigate | Controller/runtime proof stays in the runtime integration seam and leaves operator acceptance to the bounded harness, evidenced by [test/scoria/runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:164) and [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:36). | closed |
| T-18-03-01 | S | `docs/operator_verification.md` | mitigate | Operator verification requires one real `Scoria.start_run/2` run plus `/scoria/workflows/:run_id` evidence in [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:36) and [test/scoria/runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:164). | closed |
| T-18-03-02 | T | `lib/mix/tasks/test.adoption.ex` | mitigate | The task is a thin wrapper over a fixed subset in [lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:1), and its file list is locked by [test/mix/tasks/test.adoption_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.adoption_test.exs:4). | closed |
| T-18-03-03 | R | `.github/workflows/ci.yml` | mitigate | CI now executes the named adoption lane directly in [.github/workflows/ci.yml](/Users/jon/projects/scoria/.github/workflows/ci.yml:68), aligning maintainer and CI proof. | closed |
| T-18-03-04 | I | installer and operator docs | mitigate | Installer next steps and operator docs teach only public facade, route, and evidence surfaces in [lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:101) and [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:58). | closed |
| T-18-03-05 | D | lane strategy | mitigate | The operator guide keeps `mix test` authoritative and `mix test.adoption` as fast feedback only in [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:33). | closed |
| T-18-03-06 | E | operator harness | mitigate | The harness uses existing Phoenix router/LiveView seams instead of browser E2E in [test/scoria/runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:1). | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-17 | 18 | 18 | 0 | Codex via `$gsd-secure-phase 18` |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-17
