# Phase 30: Launch banner + native-dev notice - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 30-launch-banner-native-dev-notice
**Areas discussed:** make dev startup line, Docker banner route source, route grouping, Traefik admin link

---

## `make dev` startup line

| Option | Description | Selected |
|--------|-------------|----------|
| Single /scoria URL line | One echoed line: populated `http://localhost:4799/scoria` (honors `$PORT`), then server starts. No duplication of Phoenix's own root-URL output. | ✓ |
| Compact native mini-banner | Several echoed lines (URL + native/Docker note + key routes); partially duplicates the Docker banner and Phoenix's boot line. | |

**User's choice:** Single /scoria URL line.
**Notes:** Phoenix already prints its own root URL but never the `/scoria` path — the single line fills exactly that gap and satisfies "visible without scrolling past server log noise."

---

## Docker banner route source (drift)

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from `mix phx.routes` | Generate the `/scoria` route list at banner time from the live router; cannot go stale; matches Phase 29 drift-resistance DNA. | ✓ |
| Curated hand-list (fix drift now) | Keep an explicit hand-maintained list, correct it now (add `/datasets`), comment-tie to router.ex; relies on discipline. | |

**User's choice:** Derive from `mix phx.routes`.
**Notes:** The existing hand-maintained `Screens:` block already drifted — it omits `/datasets`, which exists in `router.ex`. Deriving makes the banner self-correcting.

---

## Route grouping ("grouped" interpretation)

| Option | Description | Selected |
|--------|-------------|----------|
| By operational category | Labeled buckets (Operate / Build / Connect). Most scannable; needs a taxonomy. | |
| Reuse dashboard nav groups | Mirror `ScoriaWeb.DashboardNav` sidebar grouping so banner == UI taxonomy. | |
| Single aligned list (minimal) | One flat, column-aligned list; treat "grouped" as visually organized/aligned. | ✓ |

**User's choice:** Single aligned list (minimal).
**Notes:** Coheres with deriving from `mix phx.routes` — a derived list is naturally flat. Category/nav grouping deferred (see Deferred Ideas).

---

## Traefik admin link

| Option | Description | Selected |
|--------|-------------|----------|
| Bare `http://localhost:8080` | Matches the criterion text literally; Traefik auto-redirects to `/dashboard/`, so the bare link works. | ✓ |
| Explicit `/dashboard/` path | Canonical path, avoids reliance on redirect; deviates from the criterion's literal wording. | |

**User's choice:** Bare `http://localhost:8080`.
**Notes:** Confirmed live — `docker/traefik/compose.yml` exposes the dashboard at `127.0.0.1:8080` with `--api.dashboard=true --api.insecure=true`. Link is real, not aspirational.

---

## Claude's Discretion

- Resolved without re-asking (minimal_decisive profile): how to render derived routes without a hand-maintained label map — print column-aligned paths; any second column must be mechanically derived, never curated (CONTEXT D-08).
- Microcopy/wording of the `make dev` echo and banner additions.
- The exact `mix phx.routes` parse/filter/align pipeline and fallback rendering if derivation fails (must not abort boot).
- Banner section ordering and visual separators.

## Deferred Ideas

- Category-bucketed route grouping (Operate / Build / Connect) and nav-taxonomy-mirrored grouping (reuse `DashboardNav`) — considered, set aside for a future polish phase.
- Friendly human labels per route line — deferred unless a mechanical, drift-free derivation exists; hand-maintained label map rejected.
- Banner ↔ router parity contract test and `make dev` URL ↔ PORT-default test — Phase 34 (Docker DX drift guard) scope.
