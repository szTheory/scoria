---
phase: 11-evaluation-engine-seed-depth
plan: "03"
subsystem: tooling
tags: [playwright, mix-task, screenshot-harness, ui-critique, node, eval]

# Dependency graph
requires:
  - "11-01 — dev_seed.exs populating all 9 screens (seeded pending approval + degraded connector for overlays)"
  - "11-02 — Scoria.UICritique.critique_screen/3 called in --critique branch"
provides:
  - "priv/dev/shots.mjs — standalone Playwright ES module capturing state matrix across 9 screens"
  - "lib/mix/tasks/scoria.ui.shots.ex — Mix task: screenshot pass (System.cmd → Node) + --critique pass (UICritique)"
  - "mix scoria.ui.shots [--critique] runnable harness implementing EVAL-01"
affects:
  - "11-04-PLAN — docs/MAINTAINERS.md documents harness usage + empty-state limitation"
  - "11-05-PLAN — baseline audit runs mix scoria.ui.shots; gap register aggregated here"
  - "Phase 12–17 — every later v3.0 phase re-runs this proof loop"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Playwright ES module: import { chromium } from 'playwright' (no package.json — standalone)"
    - "waitForReady(page, 5000): page.waitForFunction on data-scoria-ready=true (phx:page-loading-stop sentinel)"
    - "CSS-only theme toggle: page.evaluate setAttribute('data-theme', ...) + waitForTimeout(100) — no re-wait"
    - "tenantScoped manifest flag: gates empty-state captures to 5 tenant-scoped screens only"
    - "Overlay dispatch: idiomatic Playwright page.click on first phx-click button row"
    - "System.cmd(\"node\", args_list, ...) shell-out — discrete list, never shell string (T-11-04)"
    - "Lazy app.start: Mix.Task.run(\"app.start\") inside --critique branch only"
    - "System.find_executable(\"node\") node detection with actionable Mix.raise on nil"

key-files:
  created:
    - "priv/dev/shots.mjs"
    - "lib/mix/tasks/scoria.ui.shots.ex"
  modified: []

key-decisions:
  - "Overlay dispatch uses idiomatic Playwright page.click on first phx-click button row (simpler than LiveView event synthesis; resolves open question #2 per plan interfaces)"
  - "Empty-state capture skipped for 4 non-tenant-scoped global-list screens (reviews, eval_specs, prompts, workflows); tenantScoped flag in manifest; documented limitation for Plan 04 MAINTAINERS.md (resolves open question #1)"
  - "Screenshot pass never starts the Elixir app — System.cmd shells to Node/Playwright against the running dev server; app.start only in --critique branch for ReqLLM"
  - "Critique pass writes per-screen populated_dark_desktop.json only (D-05 canonical state); gap_register.md aggregation deferred to Plan 05"

requirements-completed: [EVAL-01]

# Metrics
duration: 35min
completed: 2026-06-04
---

# Phase 11 Plan 03: Screenshot + Critique Harness Summary

**Two-file harness: priv/dev/shots.mjs (Playwright state-matrix capture) + lib/mix/tasks/scoria.ui.shots.ex (Mix task entry point with decoupled --critique pass)**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-04
- **Completed:** 2026-06-04
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Created `priv/dev/shots.mjs` as a standalone Playwright ES module with the 9-screen hardcoded manifest, tenantScoped empty-state gating, sentinel gating, CSS-only theme toggle, two viewports, overlay dispatch via idiomatic `page.click()`, and the UI-SPEC missing-sentinel/missing-Playwright error copy
- Created `lib/mix/tasks/scoria.ui.shots.ex` that: detects `node` with `System.find_executable`, shells to the script with a discrete args list (never a shell string — T-11-04), starts the Elixir app only in the `--critique` branch, and calls `Scoria.UICritique.critique_screen/3` on each screen's canonical state
- `mix compile --warnings-as-errors` passes clean
- `mix help scoria.ui.shots` lists the task with its shortdoc

## Task Commits

1. **Task 1: priv/dev/shots.mjs** — `d61634e` (feat)
2. **Task 2: lib/mix/tasks/scoria.ui.shots.ex** — `94ef95c` (feat)

## Files Created/Modified

- `/Users/jon/projects/scoria/priv/dev/shots.mjs` — Playwright state-matrix capture script. Standalone ES module (`import { chromium } from 'playwright'`). Hardcoded SCREENS manifest covering 9 screens with tenantScoped flags and overlay selectors. waitForReady() gates on data-scoria-ready sentinel. CSS-only theme toggle via page.evaluate. Viewports: desktop 1280×900 and mobile 375×812. Overlay dispatch via Playwright page.click on first phx-click button. Startup Playwright detection with actionable error copy. Browser closed in finally block.
- `/Users/jon/projects/scoria/lib/mix/tasks/scoria.ui.shots.ex` — Mix task entry point. Screenshot pass: node detection via System.find_executable, System.cmd with discrete args list to shots.mjs, no app.start. Critique pass (--critique): Mix.Task.run("app.start") then UICritique.critique_screen/3 per screen writing findings JSON. @switches module attribute, OptionParser strict validation, Mix.raise on invalid opts.

## Decisions Made

- Used `page.click()` on first `button[phx-click="..."]` for overlay dispatch — idiomatic Playwright, avoids LiveView event synthesis complexity, supplies real seeded record ID via the button's phx-value-id attribute
- `tenantScoped: false` screens (reviews, eval_specs, prompts, workflows) capture populated-only; their empty state requires a DB-reset which contradicts D-11. Limitation documented for Plan 04.
- `app.start` placed inside `run_critique_pass/2` private function, called only when `opts[:critique]` is true — screenshot pass never starts the Elixir app

## Deviations from Plan

None — plan executed exactly as written. All interfaces in the plan frontmatter were implemented verbatim:
- 9-screen SCREENS manifest with tenantScoped flags and overlay selectors matches the `<interfaces>` block
- waitForReady() uses 5000ms timeout with the UI-SPEC missing-sentinel error copy
- System.cmd passes args as a discrete list (never shell string, no sh/bash)
- Mix.Task.run("app.start") inside critique branch only

## Known Stubs

None — both files are complete implementations. The critique pass writes real per-screen findings JSON via UICritique; the gap_register.md aggregation is intentionally deferred to Plan 05 (documented in code comment).

## Threat Flags

No new security-relevant surface beyond what the plan's `<threat_model>` covers:

| Flag | File | Description |
|------|------|-------------|
| T-11-04 mitigated | lib/mix/tasks/scoria.ui.shots.ex | System.cmd("node", args, ...) — args is a discrete list variable, never a shell string; no &&/|/; chaining; no sh/bash |
| T-11-05 mitigated | priv/dev/shots.mjs | Browser closed in finally block; 5000ms sentinel timeout with actionable error; Playwright/node detection at startup |
| T-11-02 acknowledged | priv/dev/shots.mjs | priv/shots/ outputs are gitignored (per Plan 04); screenshot pass args are discrete argv entries — no eval of untrusted input |

## Self-Check: PASSED

- `priv/dev/shots.mjs` exists: FOUND
- `lib/mix/tasks/scoria.ui.shots.ex` exists: FOUND
- `node --check priv/dev/shots.mjs` exits 0: VERIFIED
- `mix compile --warnings-as-errors` exits 0: VERIFIED
- `mix help scoria.ui.shots` lists task: VERIFIED
- Commit `d61634e` exists: FOUND (git log)
- Commit `94ef95c` exists: FOUND (git log)

## Next Phase Readiness

- `mix scoria.ui.shots` is runnable against a dev server with Plan 01 seed applied
- The critique pass delegates to Plan 02's `Scoria.UICritique.critique_screen/3` — no changes needed to that module
- Plan 04 (MAINTAINERS.md) can document the empty-state limitation (tenantScoped: false screens)
- Plan 05 (baseline audit) can run `mix scoria.ui.shots` and aggregate the per-screen JSON into gap_register.md

---
*Phase: 11-evaluation-engine-seed-depth*
*Completed: 2026-06-04*
