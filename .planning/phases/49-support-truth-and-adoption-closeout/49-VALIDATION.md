---
phase: 49
slug: support-truth-and-adoption-closeout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir `1.19.5` |
| **Config file** | none - repo uses `test/test_helper.exs` and Mix task wrappers |
| **Quick run command** | `mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs` |
| **Full suite command** | `mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/test.semantic_fast_path_test.exs test/mix/tasks/scoria.release_preview_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs` |
| **Estimated runtime** | ~30 seconds (accepted bounded docs/test closeout exception if local task compilation is cold) |

---

## Sampling Rate

- **After every task commit:** Run the smallest focused verify command for the files just changed.
- **Fast interim smoke:** `mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs`
- **After every plan wave:** Run `mix test test/scoria/adoption_surface_test.exs test/mix/tasks/test.adoption_test.exs test/mix/tasks/test.semantic_fast_path_test.exs test/mix/tasks/scoria.release_preview_test.exs test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 30 seconds target; brief cold-compile overruns are acceptable for this docs/test-only phase

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | DOCS-01 / DOCS-02 | T-49-01 | README and lane docs use one default-lane order and one canonical command per lane | source | `rg -n "mix test\\.adoption|mix test\\.knowledge|mix test\\.semantic_fast_path|mix scoria\\.release_preview|broader repo-health context" README.md docs/adoption_lanes.md` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | DOCS-01 / DOCS-02 | T-49-02 / T-49-03 | Operator, handoff, and semantic guides keep handoffs additive and optional lanes secondary | source | `rg -n "mix scoria\\.release_preview|mix test\\.adoption|mix test\\.knowledge|mix test\\.semantic_fast_path|broader repo-health context|start_handoff_run/3" docs/operator_verification.md docs/bounded_handoffs.md docs/semantic_fast_path.md` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 1 | DOCS-01 / DOCS-02 | T-49-04 / T-49-05 | Installer and knowledge-task copy promote `mix test.knowledge` without implying hidden prerequisites | source | `rg -n "mix test\\.adoption|mix test\\.knowledge|mix scoria\\.test\\.knowledge|Optional later lanes|knowledge verification lane|compatibility" lib/mix/tasks/scoria.install.ex lib/mix/tasks/scoria.test.knowledge.ex` | ✅ | ⬜ pending |
| 49-02-02 | 02 | 1 | DOCS-01 / DOCS-02 | T-49-06 | Installer and knowledge task tests pin canonical public naming while preserving alias support | unit | `mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.test_knowledge_test.exs` | ✅ | ⬜ pending |
| 49-03-01 | 03 | 2 | DOCS-01 / DOCS-02 | T-49-07 | Adoption-surface tests lock the four-tier hierarchy and optional-prerequisite boundaries | unit | `mix test test/scoria/adoption_surface_test.exs` | ✅ | ⬜ pending |
| 49-03-02 | 03 | 2 | DOCS-01 / DOCS-02 | T-49-08 / T-49-09 | Methodology policy encodes research-first escalation defaults from D-19 through D-21 | source | `rg -n "Before asking the user to choose|phase artifacts|\\.planning/research/\\*|prompts/\\*|recommend one cohesive answer|Escalate only when" .planning/METHODOLOGY.md` | ✅ | ⬜ pending |
| 49-03-03 | 03 | 2 | DOCS-01 / DOCS-02 | T-49-08 / T-49-09 | Task tests preserve bounded adoption, semantic, and release-preview proof boundaries | unit | `mix test test/mix/tasks/test.adoption_test.exs test/mix/tasks/test.semantic_fast_path_test.exs test/mix/tasks/scoria.release_preview_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Harness Producer Requirements

- [x] Existing ExUnit task tests already cover installer, adoption, semantic, and release-preview discoverability seams.
- [x] No new runtime harness or external service fixture is required for this phase.
- [x] `test/scoria/adoption_surface_test.exs` remains the primary drift-prevention seam for public wording.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer support answer reads naturally as a bounded closeout chain | DOCS-01 / DOCS-02 | Tone and scanning hierarchy are partly editorial even when strings are correct | Read `README.md` and `docs/operator_verification.md` after execution and confirm the sequence is visually obvious as `mix scoria.release_preview` then `mix test.adoption`, with semantic/knowledge/full-suite guidance clearly secondary |

---

## Validation Sign-Off

- [x] All tasks have directly runnable `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No `MISSING` verify placeholders remain
- [x] No watch-mode flags
- [x] Feedback latency target is <= 30s, with cold-compile exceptions documented for this docs/test closeout phase
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
