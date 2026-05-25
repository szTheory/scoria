---
phase: 46
slug: operator-evidence-and-verification
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir `1.19.5` |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/mix/tasks/test.adoption_test.exs --trace` |
| **Full suite command** | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected semantic/UI subset on the aligned DB port.
- **After every plan wave:** Run the bounded semantic fast-path lane once the new Mix task exists.
- **Before `$gsd-verify-work`:** Semantic lane must be green, then the broader `mix test` umbrella.
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 0 | EVID-01, PROOF-01 | T-46-01 / T-46-02 | Semantic proof only runs on the trusted pgvector-backed test path; operators do not trust lane output until the port strategy is explicit. | lane guard | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/lookup_test.exs --trace` | ✅ | ⬜ pending |
| 46-01-02 | 01 | 1 | EVID-01 | T-46-02 / T-46-03 | Runtime and workflow surfaces render one shared semantic-evidence contract with reason-coded fallback and scope truth. | component + LiveView | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/workflow_live_test.exs --trace` | ✅ / ⚠ expand assertions | ⬜ pending |
| 46-01-03 | 01 | 1 | EVID-01 | T-46-01 / T-46-03 | Workflow evidence shows persisted provenance, lifecycle status, and candidate refusal truth without widening tenant or actor visibility. | DTO + LiveView | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria_web/live/workflow_live_test.exs --trace` | ✅ / ⚠ expand assertions | ⬜ pending |
| 46-02-01 | 02 | 2 | PROOF-01 | T-46-01 / T-46-04 | Named semantic verification lane is pinned to `:test`, bounded to the canonical file list, and remains discoverable through task tests. | mix task | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs --trace` | ❌ W0 | ⬜ pending |
| 46-02-02 | 02 | 2 | PROOF-01 | T-46-04 | Partitioning, bypass, fallback, reject/stale, and invalidation semantics stay green under the named semantic lane. | integration | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path --trace` | ❌ W0 | ⬜ pending |
| 46-03-01 | 03 | 3 | PROOF-01 | T-46-04 | Docs and support-truth references point to `mix test.semantic_fast_path` and the same runtime/workflow vocabulary used in the UI. | docs/source test | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.semantic_fast_path_test.exs --trace` | ⚠ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/scoria.test.semantic_fast_path.ex` — canonical bounded semantic lane task
- [ ] `lib/mix/tasks/test.semantic_fast_path.ex` — compatibility wrapper
- [ ] `test/mix/tasks/test.semantic_fast_path_test.exs` — file-list and discoverability assertions
- [ ] `test/scoria_web/components/runtime_detail_drawer_component_test.exs` — semantic summary assertions
- [ ] `test/scoria_web/live/workflow_live_test.exs` — semantic notebook assertions for hit/miss/reject/stale provenance
- [ ] Keep the semantic verification port strategy explicit; current trusted path is `SCORIA_DB_PORT=55432`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator notebook readability and progressive disclosure still feel summary-first before raw metadata | EVID-01 | Visual density and copy hierarchy are product-shape checks, not pure mechanics | Open a semantic hit and a semantic reject workflow run, confirm the summary strip leads with verdict, fallback, scope, reason, and provenance links before raw payloads |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s on the bounded lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
