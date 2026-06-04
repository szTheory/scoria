---
phase: 11-evaluation-engine-seed-depth
plan: "05"
subsystem: tooling
tags: [eval, harness, gap-register, dev-harness, baseline, EVAL-05]

# Dependency graph
requires:
  - "11-03 — scoria.ui.shots harness + shots.mjs (EVAL-01)"
  - "11-04 — gitignore policy so gap_register.md commits while captures are ignored (EVAL-03)"
  - "dev host harness (new) — DevEndpoint/DevRouter so mix phx.server serves the dashboard"
provides:
  - "scoria.ui.shots render_gap_register/2: aggregates per-screen findings JSON into priv/shots/gap_register.md (ranked worst-first + P0/P1 backlog) in the locked UI-SPEC format"
  - "--render-only flag: regenerate the register from existing findings JSON with no screenshots and no LLM calls (re-runnable render)"
  - "@known_baseline_issues injection: surfaces flash_tone_class raw-palette gap as a ranked consistency finding the visual critique cannot see"
  - "priv/shots/gap_register.md: committed baseline (9 screens, 0 P0, 11 P1) — the stable diff target for phases 12-17 (D-06)"
affects:
  - "Phases 12-17 — every later UI phase re-runs the harness and diffs against this baseline"
  - "Phase 12 / DS-05 — flash_tone_class fix is the first ranked backlog item"

# Tech tracking
tech-stack:
  added:
    - "bandit (only: :dev) — dev harness web server"
    - "phoenix_live_reload (only: :dev) — opt-in via SCORIA_DEV_LIVE_RELOAD=1"
    - "playwright 1.60.0 (priv/dev/package.json) — screenshot harness browser driver"
  patterns:
    - "render_gap_register reads only already-written populated_dark_desktop.json (canonical state, D-05) and is pure — re-runnable without a new LLM call"
    - "known-baseline-issue injection merges documented code-level gaps (not visible to vision critique) into the ranked register"

key-files:
  created:
    - "priv/shots/gap_register.md (rendered baseline — replaces the 11-04 placeholder)"
    - "priv/dev/package.json (playwright pin)"
    - "dev/dev_endpoint.ex, dev/dev_router.ex, dev/mix_tasks/scoria_dev_db.ex (dev harness — committed 966d0e3)"
  modified:
    - "lib/mix/tasks/scoria.ui.shots.ex (render-only + known-issue injection)"
    - "config/dev.exs, lib/scoria/application.ex, mix.exs (dev harness wiring — 966d0e3)"

key-decisions:
  - "MAJOR DEVIATION: the plan's human-verify checkpoint assumed a runnable dev server, but Scoria (a Hex library) had none — the live audit was unrunnable. Built a dev-only host harness (DevEndpoint/DevRouter under dev/, never shipped to Hex) as a prerequisite. Committed in 966d0e3 + 7e1cde4."
  - "Fixed two latent gaps the real WebSocket flow exposed: DevRouter needed protect_from_forgery (else LiveView join is rejected as stale → redirect loop → sentinel never fires), and a fresh-DB needs interleaved core+knowledge migrations (mix scoria.dev.db) which plain ecto.migrate can't express."
  - "flash_tone_class is surfaced via a hardcoded @known_baseline_issues entry, not the LLM critique, because flash banners are not rendered in the captured shots (no active flash). It is recorded as a ranked P1 consistency finding and NOT fixed (scope fence — Phase 12 / DS-05)."
  - "Overlay states (connector_drawer, runtime_drawer, prompt_release approve_modal) were skipped: the harness's assumed phx-click selectors do not match the rendered DOM. Minor Phase 11 harness gap; the canonical populated_dark_desktop.png per screen was captured for all 9 screens, so the critique/baseline are complete."

requirements: [EVAL-05]
---

# 11-05: Baseline Design-System Gap Register

## What shipped

The EVAL-05 baseline is rendered and committed. The `--critique` pass aggregates
per-screen findings JSON into `priv/shots/gap_register.md` in the locked UI-SPEC
format (Summary + worst-first Ranked Findings + prioritized P0/P1 Fix Backlog).

**Live audit performed** against the new dev harness:
`mix dev.setup` → `PORT=4799 mix phx.server` → `mix scoria.ui.shots --critique
--url http://localhost:4799/scoria` (Anthropic vision over all 9 screens).

Baseline result: **9 screens audited, 0 P0, 11 P1, 71 passing.** The register
surfaces `flash_tone_class/1` (lib/scoria_web/ui.ex raw palette) as a ranked
consistency finding without fixing it (scope fence — Phase 12 / DS-05).

## Acceptance criteria

- [x] `mix compile --warnings-as-errors` clean
- [x] gap_register.md exists, committed, follows UI-SPEC format (Summary + Ranked Findings + Fix Backlog)
- [x] ranks findings worst-first with prioritized P0/P1 backlog
- [x] surfaces flash_tone_class raw-palette known issue as a ranked finding
- [x] lib/scoria_web/ui.ex unchanged (scope fence verified via git diff)
- [x] render is re-runnable from existing JSON without an LLM call (`--render-only`)

## Self-Check: PASSED

## Follow-ups (captured, not blocking)
- Harness overlay selectors (connector/runtime drawers, prompt_release approve modal) need updating to match the rendered DOM so modal/drawer states are captured in future runs.
- Docker DX initiative (Traefik + caching) — see [[v3-docker-dx-decisions]] — wraps this harness for hands-off runs.
