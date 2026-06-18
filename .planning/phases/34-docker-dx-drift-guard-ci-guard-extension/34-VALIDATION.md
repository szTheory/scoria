---
phase: 34
slug: docker-dx-drift-guard-ci-guard-extension
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
---

# Phase 34 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` |
| **Quick run command** | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~30-90 seconds for quick policy command; full suite varies by environment |

---

## Sampling Rate

- **After every task commit:** Run `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- **After every plan wave:** Run the quick policy command plus static `rg` checks for `55432` and stale browser-start `:4000` URLs.
- **Before `/gsd:verify-work`:** Full suite should be green if time permits; the explicit policy command and static checks are mandatory.
- **Max feedback latency:** 90 seconds for required quick checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | DOCS-03 | T-34-01 | File-read-only doc contract preserves Docker/native dev-DX tokens without app, DB, Docker, or network startup. | contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs` | No W0 | pending |
| 34-01-02 | 01 | 1 | DOCS-03 | T-34-02 | Stale browser-start `localhost:4000`/fixed `127.0.0.1:4000` guidance is rejected while qualified Docker-internal `:4000` mechanics remain allowed. | contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs` | No W0 | pending |
| 34-01-03 | 01 | 1 | DOCS-03 | T-34-03 | Phase 31 cache-table reader-facing strings remain pinned in the Docker DX guide. | contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs` | No W0 | pending |
| 34-02-01 | 02 | 1 | DOCS-03 | T-34-04 | FLAKE-01 fixed-host-port policy explicitly includes `.github/workflows/post-publish-smoke.yml` and rejects host ports in the Linux ephemeral range. | contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | Existing | pending |
| 34-02-02 | 02 | 1 | DOCS-03 | T-34-05 | Post-publish smoke workflow uses `5432:5432` and `SCORIA_DB_PORT: 5432`, with zero `55432` hits. | static | `rg -n "55432" .github/workflows/post-publish-smoke.yml` | Existing | pending |
| 34-03-01 | 03 | 2 | DOCS-03 | T-34-07 | Existing policy lane runs the new doc-contract file without adding CI jobs, services, matrices, dependencies, or protected check names. | contract | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` | Existing | pending |

---

## Wave 0 Requirements

- [ ] `test/scoria/docker_dx_doc_contract_test.exs` - create dedicated DOCS-03 file-read-only contract with `defmodule Scoria.DockerDxDocContractTest` and `use ExUnit.Case, async: true`.
- [ ] `test/scoria/ci_policy_contract_test.exs` - extend the existing FLAKE-01 scanner to include `.github/workflows/post-publish-smoke.yml`.
- [ ] `.github/workflows/ci-verify.yml` - append `test/scoria/docker_dx_doc_contract_test.exs` to the existing policy-lane `mix test --no-start --warnings-as-errors` file list.
- [ ] `.github/workflows/post-publish-smoke.yml` - change only `55432:5432` and `SCORIA_DB_PORT: 55432` to `5432`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Phase 35 release scope remains deferred | DOCS-03 / REL-03 context | Publishing and live registry smoke are explicitly out of Phase 34 scope. | Inspect final plan and diff; confirm no task publishes `0.1.2`, merges release PR #3, runs `mix docs` for release, checks Hex, or runs live post-publish smoke as a Phase 34 deliverable. |

---

## Static Verification

```bash
rg -n "55432" .github/workflows/post-publish-smoke.yml
```

Expected after implementation: zero hits.

```bash
rg -n "localhost:4000|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md
```

Expected after implementation: zero stale browser-start hits. Qualified Docker-internal `:4000` mechanics may remain and are judged by the ExUnit doc contract.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 90 seconds for required quick checks.
- [ ] `nyquist_compliant: true` set in frontmatter after plans assign all task checks.

**Approval:** pending
