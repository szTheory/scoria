---
phase: 11
slug: evaluation-engine-seed-depth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (standard Elixir) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scoria/mix_tasks/ test/scoria/ui_critique_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds (full suite, excludes browser automation) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command for the touched area
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

> Task IDs are provisional until plans are written; this map seeds the contract by requirement.
> Browser/LLM behaviors are manual-only by design (D-01, D-04) — they are intentionally excluded
> from merge-blocking CI.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-XX-XX | TBD | TBD | EVAL-02 | — | N/A | unit | `mix test test/scoria/ui_critique_test.exs` | ❌ W0 | ⬜ pending |
| 11-XX-XX | TBD | TBD | EVAL-01 | — | N/A | manual | requires dev server + Playwright (excluded from CI per D-01) | N/A | ⬜ pending |
| 11-XX-XX | TBD | TBD | EVAL-03 | — | N/A | source/git | `git ls-files priv/dev/shots.mjs priv/shots/gap_register.md` | N/A | ⬜ pending |
| 11-XX-XX | TBD | TBD | EVAL-04 | — | N/A | manual | `mix run priv/repo/dev_seed.exs` (idempotent) then click-through | N/A | ⬜ pending |
| 11-XX-XX | TBD | TBD | EVAL-05 | — | N/A | manual | gap register non-empty + contains `flash_tone_class` known issue | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/ui_critique_test.exs` — covers EVAL-02 (mock ReqLLM response → verify 9-key findings-JSON shape, each `{score: 1–5, findings: string[]}`)
- [ ] Seed idempotency check — running `dev_seed.exs` twice must not double record counts (local integration test; not CI-gated)
- [ ] No framework install needed — ExUnit is standard Elixir

---

## Manual-Only Verifications

> Per D-01/D-04 and the requirements spec, browser automation + LLM critique are excluded from
> merge-blocking CI. These require a running Phoenix dev server, Playwright/chromium, a database
> with seed data, and (for critique) `ANTHROPIC_API_KEY`.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix scoria.ui.shots` captures every screen across its state matrix, gated on `data-scoria-ready` | EVAL-01 | Needs running dev server + Playwright (browser automation, excluded from CI per D-01) | Start `mix phx.server`; run `mix scoria.ui.shots`; verify PNGs under `priv/shots/{date}/{screen}/{state}.png` |
| Critique pass scores screens against the 9-dimension rubric → findings JSON + `gap_register.md` | EVAL-02, EVAL-05 | Needs captured screenshots + `ANTHROPIC_API_KEY` (non-deterministic LLM, gated per D-04) | Run `mix scoria.ui.shots --critique`; verify findings JSON (9 keys/screen) + non-empty `gap_register.md` ranking the `flash_tone_class` known issue |
| Harness is committed dev-only tooling, not shipped to the Hex package | EVAL-03 | Package-manifest + git-state inspection | `git ls-files priv/dev/shots.mjs priv/shots/gap_register.md`; confirm `priv/dev/` + transient `priv/shots/` excluded from `mix.exs` `package.files` |
| Reviews, Incidents, Eval Workbench, Prompt Registry render populated, useful content | EVAL-04 | Needs seeded DB + visual click-through | `mix run priv/repo/dev_seed.exs` (run twice to confirm idempotency) then `mix phx.server` and click each screen |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (manual-only items justified above)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (where automatable)
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
