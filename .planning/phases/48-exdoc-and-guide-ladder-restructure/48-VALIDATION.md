---
phase: 48
slug: exdoc-and-guide-ladder-restructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-10
---

# Phase 48 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` |
| **Phase gate command** | `mix scoria.release_preview` |
| **Estimated runtime** | ~60 seconds for focused contracts, plus release preview generation |

---

## Sampling Rate

- **After every task commit:** Run the focused contract for the touched surface, starting with `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs`.
- **After every plan wave:** Run package/release-preview contracts plus stable docs terminology/adoption contracts.
- **Before `/gsd:verify-work`:** Run `mix scoria.release_preview` and the full focused contract suite above.
- **Max feedback latency:** 90 seconds for focused contracts unless docs generation dominates the run.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-TBD | TBD | 0/1 | DOCS-01 | T-48-01 | Keep adopter docs navigable without exposing dev-only internals | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | Yes, update required | pending |
| 48-02-TBD | TBD | 0/1 | DOCS-02 | T-48-02 | Avoid missing or misleading dev source refs and package metadata | contract | `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs` | Yes, update required | pending |
| 48-03-TBD | TBD | 0/1 | DOCS-03 | T-48-03 | Preserve old public links while moving canonical guide content | contract | `MIX_ENV=test mix test test/scoria/terminology_contract_test.exs test/scoria/adoption_surface_test.exs` | Yes, update required | pending |
| 48-GATE-TBD | TBD | final | DOCS-01, DOCS-02, DOCS-03 | T-48-01/T-48-02/T-48-03 | Release preview includes the intended guide/package surface | integration | `mix scoria.release_preview` | Yes | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] Update or add docs surface contracts for `main`, `extra_section`, `formatters`, `logo`, `favicon`, `groups_for_extras`, `groups_for_modules`, `redirects`, and dynamic `docs_source_ref/0`.
- [ ] Update package/release-preview required path contracts for canonical `guides/` files, compatibility `docs/*.md` stubs that must ship, and required brand assets.
- [ ] Update stable docs/adoption/terminology contracts from flat `docs/*.md` paths to canonical `guides/` paths while preserving legacy alias compatibility assertions.
- [ ] Add redirect coverage for old generated page IDs before moving content.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HexDocs sidebar readability and guide ladder ordering | DOCS-01, DOCS-03 | ExUnit can assert config and file presence, but not whether the rendered sidebar is a good product surface | Run `mix docs`, open `doc/index.html`, and inspect module groups, extra groups, main guide, and redirect targets |
| Public moduledoc polish for prioritized entry points | DOCS-03 | Content quality needs human review after contract tests prove links exist | Review rendered pages for the prioritized modules listed in `48-CONTEXT.md` D-17 |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing or stale docs/package contract references.
- [ ] No watch-mode flags.
- [ ] Feedback latency remains under 90 seconds for focused contract runs.
- [ ] `nyquist_compliant: true` set in frontmatter after task IDs are finalized and Wave 0 passes.

**Approval:** pending
