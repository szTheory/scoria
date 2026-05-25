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
| **Quick run command** | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs test/scoria/semantic_cache/lookup_test.exs test/scoria/semantic_cache/invalidation_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs test/mix/tasks/test.semantic_fast_path_test.exs --trace` |
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
| 46-00-01 | 00 | 0 | PROOF-01 | T-46-00-01 / T-46-00-03 | Semantic proof runs only on the trusted pgvector-backed `55432` lane and exposes one canonical named command. | mix task guard | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/mix/tasks/test.semantic_fast_path_test.exs --trace` | ✅ after implementation | ⬜ pending |
| 46-01-01 | 01 | 1 | EVID-01 | T-46-01-01 / T-46-01-03 | One curated `semantic_evidence` contract preserves fallback, scope, provenance, lifecycle, and refusal truth without UI recomputation. | DTO + runtime | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/runtime/semantic_fast_path_test.exs --trace` | ✅ / ⚠ expand assertions | ⬜ pending |
| 46-02-01 | 02 | 2 | EVID-01 | T-46-02-01 / T-46-02-03 | Runtime surface wiring and drawer rendering prove summary-first semantic evidence plus workflow deep links. | LiveView + component | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/components/runtime_detail_drawer_component_test.exs --trace` | ✅ / ⚠ expand assertions | ⬜ pending |
| 46-03-01 | 03 | 2 | EVID-01 | T-46-03-01 / T-46-03-03 | Workflow notebook proves deep semantic inspection for hit, reject, stale, provenance, lifecycle, and fallback semantics. | component + LiveView | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/components/semantic_evidence_notebook_component_test.exs test/scoria_web/live/workflow_live_test.exs --trace` | ❌ notebook test added by plan | ⬜ pending |
| 46-04-01 | 04 | 3 | PROOF-01, EVID-01 | T-46-04-01 / T-46-04-03 | Final named lane proves cache semantics plus both operator surfaces, and docs/source checks keep the support story aligned. | bounded lane + docs/source | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path --trace && SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.semantic_fast_path_test.exs --trace` | ❌ W0 / partial docs | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/scoria.test.semantic_fast_path.ex` — canonical bounded semantic lane task
- [ ] `lib/mix/tasks/test.semantic_fast_path.ex` — compatibility wrapper
- [ ] `test/mix/tasks/test.semantic_fast_path_test.exs` — file-list and discoverability assertions
- [ ] `test/scoria_web/live/orchestrator_live_test.exs` — runtime drawer wiring assertions for semantic summary projection
- [ ] `test/scoria_web/components/runtime_detail_drawer_component_test.exs` — semantic summary assertions
- [ ] `test/scoria_web/components/semantic_evidence_notebook_component_test.exs` — semantic notebook component assertions
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
