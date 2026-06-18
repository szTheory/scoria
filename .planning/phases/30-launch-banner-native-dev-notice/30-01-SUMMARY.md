---
phase: 30-launch-banner-native-dev-notice
plan: "01"
subsystem: dx-tooling
tags: [banner, makefile, docker, entrypoint, dx, routes]
dependency_graph:
  requires: []
  provides: [native-startup-url-line, docker-banner-route-list, traefik-link, native-dev-notice]
  affects: [Makefile, docker/dev-entrypoint.sh]
tech_stack:
  added: []
  patterns: [compute-then-interpolate, boot-safe-shell-variable, mix-phx-routes-derivation]
key_files:
  created: []
  modified:
    - Makefile
    - docker/dev-entrypoint.sh
decisions:
  - "D-01..D-12 from CONTEXT.md all honored: one @echo before phx.server, $(PORT) interpolation, mix phx.routes ScoriaWeb.DevRouter with || true + empty-check fallback, unquoted heredoc, paths-only route list, stale Screens: block removed"
  - "Route list is paths-only (no mechanical label column) per D-08/RESEARCH recommendation — simplest drift-proof output"
  - "Traefik admin link line includes descriptive microcopy per D-12 (distinct, copy-pasteable line)"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-18"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
status: complete
---

# Phase 30 Plan 01: Launch Banner + Native Dev Notice Summary

Delivered the three DXCLI-05 launch-banner pieces so starting the dev server (native or Docker) immediately shows the operator the `/scoria` URL — no guessing required.

## What Was Built

**One-liner:** Added `@echo` native URL to `make dev` and rewired the Docker banner to derive its `/scoria` route list live from `ScoriaWeb.DevRouter` (replacing the stale hand-maintained `Screens:` block that had drifted to omit `/scoria/datasets`), plus a bare Traefik admin link and a native-dev server notice.

## Task Results

### Task 1: Makefile `dev:` recipe — native startup URL line

- Added exactly one `@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"` line to the `dev:` recipe, placed immediately before the existing `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server` exec line.
- Commit: `0f058b9`
- Verification: `make -n dev` → `echo "==> Scoria dev (native) → http://localhost:4799/scoria"` (default PORT); `make -n dev PORT=5000` → `http://localhost:5000/scoria` (PORT override honored). Echo appears on line 1, server exec on line 2.

### Task 2: Docker banner — route list + Traefik link + native notice

- Added pre-heredoc `ROUTES` shell variable computing the 9 literal GET `/scoria` paths from `mix phx.routes ScoriaWeb.DevRouter` via `awk '$2 == "GET" && $3 ~ /^\/scoria/ && $3 !~ /:/ { print $3 }' | sort -u | sed 's/^/    /'`, suffixed with `|| true` + empty-check fallback.
- Removed the stale `Screens:` block (which omitted `/scoria/datasets`) and replaced it with `Key routes (derived live from the router):` heading + `${ROUTES}` interpolation.
- Added `Traefik admin (which app is routed where):  http://localhost:8080` on its own line.
- Added `Native dev server: make dev → http://localhost:4799/scoria` on its own line.
- Commit: `050709f`
- Verification: shellcheck clean, bash -n passes, all grep checks pass, `set -euo pipefail` intact, `|| true` present, `Screens:` block gone, protected files unchanged.

## Phase Verification Results

| Check | Result |
|-------|--------|
| `make -n dev` shows URL with default PORT 4799 | PASS |
| `make -n dev PORT=5000` shows URL with :5000 | PASS |
| Route filter pipeline returns exactly 9 literal GET `/scoria` paths incl. `/scoria/datasets` | PASS |
| `grep -F 'http://localhost:8080' docker/dev-entrypoint.sh` | PASS |
| `grep -F 'Native dev server' docker/dev-entrypoint.sh` | PASS |
| `shellcheck docker/dev-entrypoint.sh` clean | PASS |
| `|| true` + empty-check fallback present | PASS |
| `set -euo pipefail` intact at top of script | PASS |
| Stale `Screens:` block removed | PASS |
| `lib/scoria_web/router.ex`, `config/dev.exs`, `compose.yml`, `docker/traefik/compose.yml` unchanged | PASS |
| `mix test` | 738 tests, 1 pre-existing failure (unrelated ratchet_parity test) |

The single `mix test` failure (`Scoria.WarningInventory.CaptureParityTest`) is a pre-existing infrastructure issue: it shells out `mix do compile --force + test` as a subprocess and fails when the parent parallel test suite saturates the PostgreSQL connection pool (documented in the test file as `:ratchet_parity` tagged and "incompatible with the parallel/sharded full-suite run"). This failure is completely unrelated to the banner or Makefile changes.

## Verified Route Set (9 paths)

```
/scoria
/scoria/approvals
/scoria/connectors
/scoria/datasets       ← was missing from the stale Screens: block
/scoria/eval_specs
/scoria/incidents
/scoria/prompts
/scoria/reviews
/scoria/workflows
```

## Deviations from Plan

None — plan executed exactly as written. All D-01..D-12 decisions honored. All five RESEARCH pitfalls (P1–P5) avoided. The only adjustment from CONTEXT to RESEARCH was already documented in RESEARCH (Pitfall P1: `as: false` does NOT blank col-1 in `mix phx.routes` output — handled by anchoring awk filter on `$2`/`$3`, not `$1`).

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | `0f058b9` | feat(30-01): add native startup URL line to Makefile dev: recipe |
| 2 | `050709f` | feat(30-01): update Docker dev banner with live route list, Traefik link, native notice |

## Known Stubs

None. Both artifacts are fully wired: the Makefile echo interpolates the live `$(PORT)` value; the route list is derived live from `ScoriaWeb.DevRouter` at container boot.

## Threat Flags

No new threat surface. T-30-02 (boot-safety DoS) mitigated via `|| true` + empty-check as planned.

## Self-Check: PASSED

- `/Users/jon/projects/scoria/Makefile` — exists and contains `@echo "==> Scoria dev (native) → http://localhost:$(PORT)/scoria"`
- `/Users/jon/projects/scoria/docker/dev-entrypoint.sh` — exists and contains `mix phx.routes ScoriaWeb.DevRouter`, `http://localhost:8080`, `Native dev server`
- Commits `0f058b9` and `050709f` confirmed in git log
