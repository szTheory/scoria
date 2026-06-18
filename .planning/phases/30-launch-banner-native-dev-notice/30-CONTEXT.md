# Phase 30: Launch banner + native-dev notice - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Starting the dev server (Docker **or** native) immediately shows the operator where to go — eliminating the "where do I poke around?" puzzle. This phase delivers the three DXCLI-05 banner/notice pieces:

1. **`make dev` (native)** prints a single startup line with the populated `http://localhost:4799/scoria` fallback URL (honoring `$PORT`) **before** the server boots, visible without scrolling past Phoenix's boot noise.
2. **Docker `docker/dev-entrypoint.sh` banner** gains the **Traefik admin link** (`http://localhost:8080`) and a **grouped (aligned, copy-pasteable) key-route list** covering the `/scoria` screens — every entry on its own line.
3. **Native-dev notice** in the Docker banner — `Native dev server: make dev → http://localhost:4799/scoria` — so a reader who reaches the banner via Docker is not confused about the native path/port.

**Out of scope (belongs to later phases):** Dockerfile caching audit (Phase 31), secrets/rotation (Phase 32), the `docs/docker_dev_dx.md` rewrite and correcting `localhost:4000` copy across `docs/`/`priv/dev/e2e`/`.planning/` (Phase 33), drift-guard contract tests (Phase 34), the maintenance release (Phase 35). No new routes, no nav/IA changes — banner only reflects what the router already exposes. Sibling-repo migration is out of scope for the whole milestone.
</domain>

<decisions>
## Implementation Decisions

Calibration: user profile is `opinionated` / `minimal_decisive` — decisions below are LOCKED, one coherent set, resolved in a single discussion pass. They cohere deliberately: "derive routes from the router" + "render as a single aligned list" reinforce each other (a derived list is naturally flat), and both express the Phase 29 drift-resistance DNA.

### `make dev` native startup line (success criterion 1)
- **D-01:** `make dev` echoes **exactly one line** before `mix phx.server` starts — the populated `/scoria` URL honoring `$PORT`, e.g.:
  `==> Scoria dev (native) → http://localhost:4799/scoria`
  Rationale: Phoenix's own dev server already prints `Running ScoriaWeb.Endpoint ... http://localhost:4799` but only at the **root** path; the criterion specifically wants the `/scoria` path visible up front. One line satisfies "a startup line ... without scrolling back past server log noise" and avoids duplicating either Phoenix's output or the Docker banner.
- **D-02:** The line MUST interpolate the Makefile `$(PORT)` (default 4799, set in Phase 29) so `make dev PORT=5000` echoes the matching URL. Single source of truth stays `PORT ?= 4799` in the Makefile (carried from Phase 29 D-07/D-08 — do NOT touch `config/dev.exs` port default). The `make dev` recipe is the place to add the `@echo` (currently the recipe is just `SCORIA_DEV_LIVE_RELOAD=1 PORT=$(PORT) mix phx.server`).
- **D-03:** Use `localhost` (not `127.0.0.1`) in the native line for copy-paste friendliness and consistency with the criterion wording. (`make url` separately reports the Docker ephemeral `127.0.0.1` port — different surface, leave it.)
- **D-04:** The `make dev` line does **not** carry the route list — routes live in the Docker banner only. Native users get the URL; the app's own nav orients them from there.

### Docker banner key-route list (success criterion 2)
- **D-05:** **Derive the `/scoria` route list at banner time from the live router** (`mix phx.routes`, filtered to `/scoria` paths), NOT a hand-maintained list. Rationale: the current hand-maintained `Screens:` block in `dev-entrypoint.sh` has **already drifted** — it omits `/datasets` (`live("/datasets", ScoriaWeb.DatasetLive.Index ...)` exists in `router.ex`). A derived list cannot go stale, matching Phase 29's drift-resistance convention (dynamic enumeration over curated lists).
- **D-06:** **Render as a single, column-aligned flat list** — one route per line, copy-pasteable. The user read "grouped" as "visually organized/aligned," not "bucketed by category." Keep it minimal; do not introduce category headers or a nav-group taxonomy.
- **D-07:** **Filter out parameterized/non-pokeable routes** so every printed line is a literal copy-pasteable URL path. Exclude routes containing `:` params (`/workflows/:id`, `/prompts/:id/release`, `/connectors/:connector_id/auth/*`, `/coming/:screen`) and non-GET/non-live entries (MCP `post`/`sse`). Print the static GET/`live` `/scoria` paths only.
- **D-08 (label nuance — Claude's discretion, resolved):** `mix phx.routes` yields **paths + controller/LiveView module names**, not the friendly labels ("Home", "Review Queue") in today's banner. Print the **derived paths column-aligned without reintroducing a hand-maintained label map** — a label map is exactly the drift D-05 kills. If a second human-readable column is desired, derive it mechanically from the route (e.g. last path segment or the route's `:as`/helper name), never a hand-curated lookup. Planner/researcher: confirm the cleanest mechanical rendering; paths-only is acceptable and preferred over a fragile label map.
- **D-09:** The route derivation runs inside the container where `mix` + a compiled app are already available (the entrypoint already runs `mix deps.get` and `mix dev.setup` before the banner). Researcher: verify `mix phx.routes` output format/exit behavior and that the filter is robust to the `as: false`/`alias: false` scoped router (no route helper names). Keep the banner resilient — if derivation fails, the banner must still print (don't `set -e` abort the boot on a routes hiccup).

### Traefik admin link + native notice (success criteria 2 & 3)
- **D-10:** Print the Traefik admin link as the **bare `http://localhost:8080`** (matches the criterion text literally). Confirmed live: `docker/traefik/compose.yml` exposes the dashboard at `127.0.0.1:8080` with `--api.dashboard=true --api.insecure=true`, and Traefik auto-redirects `/` → `/dashboard/`, so the bare link works when clicked or pasted. On its own distinct line.
- **D-11:** Add the native-dev notice line(s) to the Docker banner verbatim-ish: `Native dev server: make dev → http://localhost:4799/scoria`. Hardcoding 4799 here is correct — it states the **native default policy**, mirroring the Makefile `PORT ?= 4799` default (the Docker container itself still listens on `:4000`; do not conflate). Place it as its own distinct, copy-pasteable line so a Docker reader is not confused about the native path/port.
- **D-12:** All three new banner elements (Traefik link, native notice, route list) go on **distinct lines** (criterion 2 requires copy-pasteability). Fit them into the existing `cat <<BANNER ... BANNER` heredoc structure in `dev-entrypoint.sh`; keep the existing Open/Traefik/demo-data/screenshot-harness sections.

### Claude's Discretion
- Exact microcopy/wording of the `make dev` echo and the banner additions, as long as URLs are literal/copy-pasteable and the native-vs-Docker distinction is unambiguous.
- The precise `mix phx.routes` parse/filter pipeline (grep/awk/sed) and column-alignment mechanism — pick the most robust under the container's shell; mirror the Phase 29 awk-alignment idiom if convenient.
- Whether the derived route list replaces the existing static `Screens:` block in place or is built just above the heredoc and interpolated in.
- Banner section ordering/visual separators, as long as the three required elements are present on distinct lines.
- Fallback rendering if `mix phx.routes` derivation fails (must not abort boot).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 30: Launch banner + native-dev notice" — goal + 3 success criteria (the verification bar).
- `.planning/REQUIREMENTS.md` — **DXCLI-05** (the single locked requirement for this phase: copy-pasteable key-route list + populated `/scoria` fallback URL + Traefik admin link).
- `.planning/PROJECT.md` §"Current Milestone: v3.2 Drydock" — milestone goal + "Docker dev-DX hardening (Scoria-only)" target features; locked context (Traefik/`*.localhost` stays; sibling migration out of scope).

### Carried-forward decisions (Phase 29 — MUST honor)
- `.planning/phases/29-makefile-hardening/29-CONTEXT.md` — PORT 4799 lives in the Makefile only (D-07/D-08); `config/dev.exs` port default stays `"4000"`; container listens on `:4000`; drift-resistance + `## name: desc` help convention; awk-alignment idiom.

### Files this phase edits
- `Makefile` (`dev:` target ~L90–91) — add the single `@echo` startup line honoring `$(PORT)`.
- `docker/dev-entrypoint.sh` — add Traefik admin link + native-dev notice + derive the `/scoria` route list (replace the stale hand-maintained `Screens:` block).

### Files this phase reads but does NOT change
- `lib/scoria_web/router.ex` — the **source of truth** for the derived route list (`scoria_dashboard` macro's `live_session :scoria_dashboard` block). Phase 30 reflects it, never edits it.
- `docker/traefik/compose.yml` (~L27–31) — confirms the dashboard is exposed at `127.0.0.1:8080` (`--api.dashboard=true --api.insecure=true`). Reference only.
- `compose.yml`, `config/dev.exs` — Docker-internal `:4000` stays (Phase 29 D-10). Do not touch.

### DX philosophy
- `prompts/sztheory-elixir-dna.md` — Operator-First DX / least-surprise DNA driving the microcopy + drift-resistance choices.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docker/dev-entrypoint.sh` already has a `cat <<BANNER ... BANNER` heredoc with `HOST`/`INSTANCE` interpolation, a `Screens:` block, and a `make url` fallback hint — extend this structure; add the Traefik link, native notice, and derived route list into it.
- `Makefile` `dev:` recipe already threads `PORT=$(PORT)` (Phase 29) — add one `@echo "... http://localhost:$(PORT)/scoria"` before the `mix phx.server` exec; `$(PORT)` is already in scope.
- `mix phx.routes` is available inside the container at banner time (entrypoint runs `mix deps.get` + `mix dev.setup` first, so the app is compiled) — the derivation source needs no new tooling.
- Phase 29's verified awk column-alignment idiom (`29-CONTEXT.md` D-14) is reusable for aligning the derived route list.

### Established Patterns
- **Drift-resistance via dynamic enumeration** (Phase 29 `nuke` warning, `help` parser): banner route list should be *derived*, not curated — the current static list already drifted (missing `/datasets`).
- **Native 4799 is a Makefile-only policy**; the container listens on `:4000`. The banner states the native default (4799) explicitly without changing any container `:4000` wiring.

### Integration Points
- `make dev` echo → consumed by the human operator at the terminal (criterion 1).
- `dev-entrypoint.sh` banner → printed once on `docker compose up` boot (criteria 2 & 3); derives from `router.ex` and references `docker/traefik/compose.yml`'s :8080.

### Drift / verification note (hand-off to Phase 34 guard, do not build here)
- The router→banner derivation is the drift-proofing for *this* phase. A contract test asserting banner ↔ router parity (and the `make dev` URL ↔ `PORT` default) is Phase 34 scope, not Phase 30 — but the planner should keep the derivation testable.
</code_context>

<specifics>
## Specific Ideas

- `make dev` line shape the user endorsed: `==> Scoria dev (native) → http://localhost:4799/scoria` (followed by Phoenix's own boot logs).
- Route list rendering the user endorsed: a single column-aligned flat list (paths one-per-line), not category buckets — "grouped" = visually aligned/organized.
- Traefik link rendering the user endorsed: bare `http://localhost:8080` (relies on Traefik's auto-redirect to `/dashboard/`).
</specifics>

<deferred>
## Deferred Ideas

- **Category-bucketed route grouping** (Operate / Build / Connect) and **nav-taxonomy-mirrored grouping** (reuse `ScoriaWeb.DashboardNav` groups) — both considered and set aside in favor of a minimal aligned list. If a future polish phase wants the banner to mirror the sidebar IA, this is where to start.
- **Friendly human labels** on each route line (beyond the path) — deferred unless a mechanical, drift-free derivation is found; a hand-maintained label map is explicitly rejected.
- **Banner ↔ router parity contract test** and **`make dev` URL ↔ PORT default test** — Phase 34 (Docker DX drift guard) scope.

None of these expand Phase 30 scope.

</deferred>

---

*Phase: 30-launch-banner-native-dev-notice*
*Context gathered: 2026-06-18*
