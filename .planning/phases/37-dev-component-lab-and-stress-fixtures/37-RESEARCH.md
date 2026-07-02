# Phase 37: Dev Component Lab And Stress Fixtures - Research

**Researched:** 2026-07-02
**Domain:** Phoenix LiveView dev-only tooling (repo-local component preview/lab), fixture design, dev-only compile boundaries, focused browser proof
**Confidence:** HIGH

## Summary

Phase 37 is 100% buildable from patterns already proven in this repo — no new libraries, no new npm packages, no new CI topology. The dev-only compile/package boundary (`dev/` compiled only under `MIX_ENV=dev`, excluded from `mix.exs` `package.files`) is already established by `ScoriaWeb.DevRouter`/`ScoriaWeb.DevEndpoint`, and the root layout (`ScoriaWeb.Layouts`, `:root`) + `ScoriaWeb.Assets` compile-time CSS/JS inlining is completely mount-path-independent, so the lab gets a fully-styled, fully-interactive (LiveSocket, theme toggle, readiness sentinel) page for free by reusing that layout — it does not need any new asset pipeline work.

The single most important constraint the planner must design around is the **compile-path split**: `lib/` (including `lib/mix/tasks/`) compiles under *every* Mix env and ships to Hex; `dev/` compiles *only* under `:dev` and never ships; `test/` compiles under `:test`, which does **not** include `dev/` in its `elixirc_paths`. This means an ExUnit test under `test/` can never `alias`/call a lab module directly — it will fail to compile in `mix test`. The two safe patterns already proven in-repo are (1) pure text/regex guard tests reading source files as strings (exactly what `ds06_drift_guard_test.exs` and `token_contrast_guard_test.exs` do), and (2) a dev-only Elixir check invoked as a `mix` task under `dev/mix_tasks/` (exactly what `Mix.Tasks.Scoria.Dev.Db` does, run under the default `:dev` env). Phase 37's required guard/coverage tests should use pattern (1); an optional richer coverage check can use pattern (2), run manually/locally (not wired into `mix test`).

The second key finding: `priv/dev/e2e/*.spec.mjs` is **testDir-driven and already a required CI gate** (`e2e` job → `ci-gate`, per `.github/workflows/ci.yml`). Adding `priv/dev/e2e/lab.spec.mjs` requires zero CI/task changes (the existing `mix scoria.ui.e2e` task and CI job pick it up automatically) but it also means every assertion in that file is immediately gating — so per the established `test.fixme('<reason> — <unlock>')` convention (`docs/uat_automation.md`), anything not fully proven yet must be registered as `fixme`, never a flaky/failing assertion.

**Primary recommendation:** Mount a new `live_session :scoria_lab` directly inside `dev/dev_router.ex` (new `import Phoenix.LiveView.Router` at module scope, reusing the existing `:browser` pipeline), rooted at `{ScoriaWeb.Layouts, :root}` with a lab-authored shell (not `app.html.heex` — different IA per D-07). Build the lab as one primary LiveView with `handle_params`-driven section routing (`?section=primitives&item=table`) plus small function-component "state band" renderers per D-06/D-11, backed by a single dev-only fixture module (`dev/dev_lab_fixtures.ex`) returning HEEx-safe maps keyed by D-20 domain-noun scenario names. Guard/coverage proof: text-scan ExUnit tests under `test/` (no dev/ compile dependency) plus one new deterministic Playwright spec under `priv/dev/e2e/lab.spec.mjs`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lab route mounting (`/scoria/_lab`) | Frontend Server (SSR/LiveView, dev-only) | — | LiveView mount is server-side; `dev/dev_router.ex` already owns this tier for the dashboard, lab reuses it |
| Component/group/state rendering | Frontend Server (SSR/LiveView) | Browser/Client | Server-renders `ScoriaWeb.UI` primitives with fixture data; client only needed for hooks (theme, dismiss, copy) already shipped |
| Fixture catalog (data) | Dev-only Elixir module (`dev/`) | Static JSON (`priv/dev/`, optional) | D-16/D-17: deterministic, reset-free, no DB — belongs beside the LiveView, not in `priv/repo/` |
| Theme / reduced-motion / viewport mechanics | Browser/Client (existing JS + CSS) | Frontend Server (labels/state only) | `assets/js/scoria.js` + `05-motion.css` already own theme/motion; lab only *displays* current state, does not reimplement mechanics |
| Coverage/exclusion guards | Test tier (`test/`, text-based) | Dev-only Mix task (`dev/mix_tasks/`) | Compile-path split forces text-based proof in `test/`; richer runtime coverage checks must live in `:dev` env |
| Browser proof (route load, focus, viewport) | CI/E2E tier (`priv/dev/e2e/`, Playwright) | — | Existing Tier-2 e2e lane (`mix scoria.ui.e2e`) is the established home for client-observable truths |

## Package Legitimacy Audit

**Not applicable.** Phase 37 introduces zero new Hex/npm dependencies. `@playwright/test`/`playwright` (`priv/dev/package.json`, pinned `1.60.0`) are already installed and used by the existing e2e lane; the lab's e2e spec reuses them as-is. Per D-03/D-04 and `REQUIREMENTS.md`, no runtime UI dependency and no PhoenixStorybook may be added.

## Architecture Patterns

### System Architecture Diagram

```
Maintainer browser
      │  GET/LiveView connect  /scoria/_lab?section=primitives&item=table
      ▼
ScoriaWeb.DevEndpoint  (dev/dev_endpoint.ex — Bandit, :dev-only, socket "/live")
      │  plug ScoriaWeb.DevRouter
      ▼
ScoriaWeb.DevRouter  (dev/dev_router.ex — :dev-only)
      │  pipe_through :browser   (fetch_session, protect_from_forgery, put_secure_browser_headers)
      │
      ├─ scope "/"  → scoria_dashboard("/scoria")   [UNCHANGED — public macro, lib/scoria_web/router.ex]
      │
      └─ scope "/scoria/_lab"  [NEW — lives only in dev_router.ex, never touches the macro]
             live_session :scoria_lab,
               root_layout: {ScoriaWeb.Layouts, :root},   (reused — self-contained CSS/JS/root shell)
               on_mount: [lab-local hook or none]
             live "/", DevLab.LabLive, :index
             live "/:section", DevLab.LabLive, :index
             live "/:section/:item", DevLab.LabLive, :index
                    │
                    ▼
            DevLab.LabLive (dev/lab/lab_live.ex)
                    │ handle_params → assign current section/item from path,
                    │                 NOT from a DB read
                    ▼
      ┌─────────────────────────────────────────────────────────┐
      │ Section renderers (function components, dev/lab/sections/*.ex)│
      │  Foundations · Primitives · Groups · States · Viewports ·│
      │  Overlays · Fixtures                                    │
      └─────────────────────────────────────────────────────────┘
                    │  each primitive/group rendered N times,
                    │  once per D-11 state band, using:
                    ▼
      DevLab.Fixtures (dev/lab/fixtures.ex — "ScoriaWeb.DevLabFixtures")
        deterministic HEEx-safe maps per D-20 scenario name
        (approval_requested, incident_opened, dataset_empty, ...)
                    │
                    ▼
      ScoriaWeb.UI primitives (lib/scoria_web/ui.ex — UNCHANGED, runtime module)
      + existing component groups (lib/scoria_web/components/*.ex)
                    │  rendered HTML uses existing tokens only
                    ▼
      assets/css/{02-tokens,04-components,05-motion}.css  (inlined via ScoriaWeb.Assets)
      assets/js/scoria.js hooks (ThemeToggle, Dismissable, CommandPalette, MobileNav, CopyId)
                    │
                    ▼
Browser proof:  priv/dev/e2e/lab.spec.mjs (Playwright)
  — route load, theme toggle, emulateMedia(reducedMotion), setViewportSize scan,
    overlay/focus, dense table, copy controls — via mix scoria.ui.e2e (existing CI e2e job)

Guard proof (compile-independent, runs in mix test):
  test/scoria_web/dev_lab_boundary_test.exs
    — text-scans lib/scoria_web/router.ex, mix.exs, dashboard_nav.ex, layouts.ex/*.heex
```

### Recommended Project Structure

```
dev/
├── dev_router.ex             # MODIFIED — add `import Phoenix.LiveView.Router`
│                              #   + new scope "/scoria/_lab" live_session block
├── dev_endpoint.ex            # UNCHANGED — same endpoint, same socket path
├── lab/
│   ├── lab_live.ex            # single param-driven LiveView (handle_params routes sections)
│   ├── fixtures.ex            # ScoriaWeb.DevLabFixtures — D-16/D-20 scenario catalog
│   └── sections/
│       ├── foundations.ex     # function components: token/type/spacing/motion inspection
│       ├── primitives.ex      # renders every ScoriaWeb.UI primitive x state band
│       ├── groups.ex          # renders lib/scoria_web/components/*.ex groups x state band
│       ├── states.ex          # the reusable "state band" renderer shared by primitives/groups
│       ├── viewports.ex       # viewport-simulator frame (320/375/768/1024/1440/wide)
│       ├── overlays.ex        # curated drawer/modal/toast/command-palette/mobile-nav probes
│       └── fixtures_view.ex   # "Fixtures" IA section: browse/inspect the fixture catalog itself
priv/dev/
├── e2e/
│   └── lab.spec.mjs           # NEW — route load, theme, reduced-motion, viewport, overlay proof
│   └── lib/ready.mjs          # REUSED — waitForReady(page), no change needed
test/
└── scoria_web/
    └── dev_lab_boundary_test.exs   # NEW — text-based exclusion + coverage guard (see below)
docs/
└── MAINTAINERS.md             # MODIFIED — add "Component Lab" maintainer section (D-34)
```

### Pattern 1: Dev-only route mounted outside the public macro

**What:** Add a second `live_session` directly in `dev/dev_router.ex`, entirely separate from the `scoria_dashboard/2` macro invocation, so the public macro (`lib/scoria_web/router.ex`, shipped to Hex) is never touched.
**When to use:** Any dev-only LiveView surface that must never be reachable by a host app that calls `scoria_dashboard "/scoria"`.
**Example:**
```elixir
# dev/dev_router.ex
use Phoenix.Router
import Phoenix.Controller
import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 3]  # NEW import
import ScoriaWeb.Router

pipeline :browser do
  # ...existing pipeline, unchanged...
end

scope "/" do
  pipe_through(:browser)
  scoria_dashboard("/scoria")   # UNCHANGED — public macro
end

# NEW — lab lives entirely in dev/, never referenced by lib/scoria_web/router.ex
scope "/scoria/_lab" do
  pipe_through(:browser)

  live_session :scoria_lab, root_layout: {ScoriaWeb.Layouts, :root} do
    live("/", DevLab.LabLive, :index)
    live("/:section", DevLab.LabLive, :index)
    live("/:section/:item", DevLab.LabLive, :index)
  end
end
```
Source: pattern mirrors the existing `scoria_dashboard/2` macro body in `lib/scoria_web/router.ex` and the precedent of `Phoenix.LiveDashboard.Router.live_dashboard/2` (dashboard mounted as a sibling scope, not by extending the host's own routes). `[CITED: hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html]`

### Pattern 2: Reuse the self-contained root layout, author a lab-specific shell (not the dashboard shell)

**What:** `{ScoriaWeb.Layouts, :root}` (`lib/scoria_web/components/layouts/root.html.heex`) inlines `ScoriaWeb.Assets.css()`/`.js()` at compile time and sets up the pre-paint theme script + `data-scoria-ready` sentinel wiring — all mount-path-independent. Reuse it verbatim for the lab's `root_layout`. Do **not** reuse `app.html.heex` (the dashboard's GOV.UK-style operator nav shell) — author a lab-specific shell inside `DevLab.LabLive`'s own render/1, with the D-07 IA (`Foundations/Primitives/Groups/States/Viewports/Overlays/Fixtures`) as its own nav rail, built only from existing `ScoriaWeb.UI` primitives (per the UI-SPEC "Component Inventory For Lab Chrome" table — `panel/1`, `page_section/1`, `badge/1`, `eyebrow/1`, `kbd/1`, `id/1`).
**When to use:** Always, for this phase — this is the only way to get LiveSocket + hooks + CSS/JS + FOUC-free theme + readiness sentinel with zero new asset-pipeline work.
**Example:**
```elixir
# dev/lab/lab_live.ex
defmodule DevLab.LabLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}
  import ScoriaWeb.UI  # panel, page_section, badge, eyebrow, kbd, id, empty_state, skeleton, ...

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(socket,
       section: params["section"] || "foundations",
       item: params["item"],
       page_title: "Component Lab"
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-lab-shell">
      <nav class="scoria-lab-nav" aria-label="Component Lab sections">
        <.link :for={s <- ~w(foundations primitives groups states viewports overlays fixtures)}
          patch={~p"/scoria/_lab/#{s}"} class={["scoria-lab-nav__item", @section == s && "scoria-lab-nav__item--active"]}>
          {String.capitalize(s)}
        </.link>
      </nav>
      <main class="scoria-lab-main">
        <.page_section>
          <:eyebrow>Component Lab</:eyebrow>
          <:title>Component Lab</:title>
          <:description>Inspect Scoria primitives, groups, fixtures, themes, and stress states before changing shared UI.</:description>
          <DevLab.Sections.render section={@section} item={@item} />
        </.page_section>
      </main>
    </div>
    """
  end
end
```
Source: derived directly from `lib/scoria_web/components/layouts/root.html.heex` and `lib/scoria_web/assets.ex` (both read verbatim in this session). `[VERIFIED: read lib/scoria_web/components/layouts/root.html.heex, lib/scoria_web/assets.ex]`

### Pattern 3: One reusable "state band" renderer, no DSL

**What:** A single function component `states_band/1` (analogous in spirit to PhoenixStorybook's `Variation`/Lookbook's preview scenarios, but implemented as a plain Phoenix function component with `attr`/`slot`, per Claude's Discretion in CONTEXT.md) that takes a component-rendering slot and a list of `{state_name, fixture}` pairs, and renders one labeled instance per D-11 state.
**When to use:** Every entry under `Primitives` and `Groups` sections.
**Example:**
```elixir
# dev/lab/sections/states.ex
defmodule DevLab.Sections.States do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1, panel: 1]

  attr :inventory_id, :string, required: true   # e.g. "PRIM-TABLE" (D-08 coverage anchor)
  attr :states, :list, required: true           # [{:normal, fixture}, {:empty, fixture}, ...]
  slot :render, required: true do
    attr :fixture, :any
  end

  def states_band(assigns) do
    ~H"""
    <div class="scoria-lab-states" data-inventory-id={@inventory_id}>
      <div :for={{state, fixture} <- @states} class="scoria-lab-state" data-lab-state={state}>
        <.badge tone={state_tone(state)} label={to_string(state)} />
        <div class="scoria-lab-state__specimen">
          {render_slot(@render, fixture)}
        </div>
      </div>
    </div>
    """
  end

  # D-12: lab STATE name -> visual TONE mapping is a separate, explicit table —
  # never derive tone from the state atom via ScoriaWeb.UI.tone/1 (that maps
  # domain status strings, a different vocabulary).
  defp state_tone(:warning), do: :warn
  defp state_tone(:danger), do: :fail
  defp state_tone(:error), do: :fail
  defp state_tone(:selected), do: :brand
  defp state_tone(_), do: :neutral
end
```
Caller usage (one primitive, all 10 states):
```heex
<DevLab.Sections.States.states_band inventory_id="PRIM-BADGE" states={DevLab.Fixtures.states_for(:badge)}>
  <:render :let={fixture}>
    <.badge tone={fixture.tone} label={fixture.label} />
  </:render>
</DevLab.Sections.States.states_band>
```
This is the **transferable lesson from PhoenixStorybook/Lookbook** (parameterized variation rendering) applied as a plain `attr`/`slot` component — no macro, no DSL, no new dependency. `[CITED: hexdocs.pm/phoenix_storybook/components.html — variation-group concept, reimplemented natively]` `[CITED: lookbook.build/guide/components/view_component — preview-per-state concept, reimplemented natively]`

### Anti-Patterns to Avoid

- **A generic macro-based "story" DSL:** D-04/Claude's Discretion explicitly reject PhoenixStorybook-style macros. Plain function components with `attr`/`slot` are sufficient and keep the lab a first-class, readable Elixir module tree.
- **Re-deriving `ScoriaWeb.UI.tone/1` from lab state names:** `tone/1` maps *domain status strings* (`"approval_requested"` → `:warn`). Lab *state* names (`warning`, `danger`, `error`, `selected`, ...) are a separate vocabulary (D-12) — write an explicit `state_tone/1` mapping in the lab, never call `ScoriaWeb.UI.tone(state_name)`.
- **Recompiling the whole dashboard as a second app:** D-10 — only add curated flow probes where isolated components are insufficient (dense approvals+toast, table/list mobile summary, drawer/modal focus, command palette, mobile nav, raw-evidence copy, long evidence). Do not build a parallel `/scoria/_lab/approvals` full page clone.
- **Calling `ScoriaWeb.DevLabFixtures` from `lib/`:** Any `lib/` module (including `lib/mix/tasks/*`) compiles under every env, including when the Hex-packaged adopter's app compiles this library as a dependency. Referencing a `dev/`-only module from `lib/` is a **compile error outside `:dev`** — this is the D-21 boundary enforced structurally, not just by convention.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Self-contained CSS/JS bundle for a new dev route | A second `Plug.Static` mount or a separate asset build target | `{ScoriaWeb.Layouts, :root}` + `ScoriaWeb.Assets.css/0`/`.js/0` (already compile-time inlined) | Already mount-path-independent; a second bundle would drift from the single token/component CSS SSOT |
| "Is the page ready" signal for Playwright | A new `data-lab-ready` attribute/hook | Existing `data-scoria-ready="true"` sentinel (set on `phx:page-loading-stop` in `assets/js/scoria.js:759`) + `priv/dev/e2e/lib/ready.mjs`'s `waitForReady(page)` | Sentinel fires on any LiveView using the shared JS bundle, including the lab, for free |
| Reduced-motion emulation mechanism | A JS-toggled "force reduced motion" class/data-attribute | `page.emulateMedia({ reducedMotion: 'reduce' })` (Playwright) for automated proof; for manual/visual inspection, a read-only indicator that reads `matchMedia('(prefers-reduced-motion: reduce)').matches` | `assets/css/05-motion.css` already keys off the *real* `@media (prefers-reduced-motion: reduce)` query with `!important` (unlayered) — Playwright's `emulateMedia` sets the actual OS-level signal the CSS already listens to; inventing a second (fake) toggle mechanism would violate D-14 ("must not invent new motion language") |
| Viewport-width proof | New CSS breakpoint tokens | `page.setViewportSize({width, height})` (Playwright, already used in `priv/dev/e2e/phase16_parity.spec.mjs`) for automated proof; a CSS-only `iframe`/`resize` simulator frame (built from existing `panel/1` + inline style width, not a new token) for the manual `Viewports` IA section | D-13 explicitly forbids inventing new breakpoint tokens; the six widths are proof targets, not design tokens |
| Coverage bookkeeping for "does every state/domain exist" | A hand-rolled test-runner script that imports the fixture module from `test/` | Text-regex scan of `dev/**/*.ex` source (same technique as `ds06_drift_guard_test.exs`) run from `test/`, OR a `dev/mix_tasks/` Elixir-level check run under the default `:dev` env | `test/` cannot compile `dev/` (elixirc_paths split) — importing the fixture module from an ExUnit test is a guaranteed compile failure |

**Key insight:** Every mechanism the lab needs (self-contained styling, readiness sentinel, reduced-motion signal, viewport proof, e2e wiring) already exists in this repo for the dashboard. Phase 37's job is composition and coverage, not invention.

## Runtime State Inventory

Not applicable — Phase 37 is a greenfield addition (new `dev/lab/` tree, new test file, new e2e spec, doc updates). It renames/moves nothing and there is no prior lab state to migrate. Confirmed: `find dev -type d` shows only `dev/` and `dev/mix_tasks/` exist today; no `dev/lab/` or lab-named modules exist anywhere in the repo (`grep -r "DevLab\|_lab\b" lib/ dev/ test/` returns no hits outside `.planning/`).

## Common Pitfalls

### Pitfall 1: `test/` cannot see `dev/` — direct module references silently break `mix test`

**What goes wrong:** A guard/coverage test under `test/` does `alias ScoriaWeb.DevLabFixtures` (or `DevLab.Fixtures`) and calls it directly. `mix test` compiles under `elixirc_paths(:test) = ["lib", "test/support"]` — `dev/` is absent — so the test file fails to compile with `UndefinedFunctionError`/`module not available`, and (per `docs/MAINTAINERS.md`) the policy lane runs `mix compile --warnings-as-errors`, which will hard-fail CI.
**Why it happens:** The mental model "the module exists in the repo" doesn't match Mix's per-env compile scoping; this is easy to miss because `dev/dev_router.ex`/`dev_endpoint.ex` have never been referenced from `test/` before (confirmed: zero `grep` hits for `DevRouter`/`DevEndpoint` under `test/`), so there is no prior failure to learn from.
**How to avoid:** Guard/coverage tests under `test/` must use `File.read!/1` + `Regex.scan` against `dev/**/*.ex` source text (proven pattern: `test/scoria_web/ds06_drift_guard_test.exs`), never `alias`/`import` a `dev/`-scoped module. If truly dynamic (runtime) fixture-catalog introspection is wanted, write it as a `dev/mix_tasks/*.ex` task (compiles `:dev`-only, run manually or as a documented local command — never added to `mix test`).
**Warning signs:** Any `alias`/`import`/module-dot-call referencing a name defined under `dev/` inside a file under `test/`.

### Pitfall 2: A new `priv/dev/e2e/*.spec.mjs` file is immediately a required CI gate

**What goes wrong:** `.github/workflows/ci.yml`'s `e2e` job runs `mix scoria.ui.e2e`, which is `testDir`-driven (`priv/dev/e2e/playwright.config.mjs`: `testDir: '.', testMatch: '**/*.spec.mjs'`) — any new spec file is picked up automatically, and `ci-gate` requires `needs: [verify, e2e]` to succeed. A lab spec with an unproven/flaky assertion (e.g. asserting something about a not-yet-built section) will break `CI / ci-gate` for every unrelated PR, not just lab work.
**Why it happens:** The convenience of "no new mix task, no CI change" cuts both ways — there is no staging/advisory lane for e2e specs.
**How to avoid:** Author every assertion in `lab.spec.mjs` against what actually ships in this phase; for anything intentionally deferred, use the established `test.fixme('<reason/ID> — <named unlock>')` convention (`docs/uat_automation.md`), never a bare assertion expected to fail.
**Warning signs:** A new `.spec.mjs` file added in the same PR as partial/WIP lab sections; any assertion referencing a section not yet implemented.

### Pitfall 3: `DevRouter` doesn't import `Phoenix.LiveView.Router` at module scope today

**What goes wrong:** `live`/`live_session` are currently only available *inside* the `scoria_dashboard/2` macro's `quote` block (that macro does its own `import Phoenix.LiveView.Router, only: [...]` locally). `dev/dev_router.ex` itself only imports `Phoenix.Controller` and `ScoriaWeb.Router` — calling `live(...)` directly in a new scope without adding the import will fail to compile with `undefined function live/3`.
**Why it happens:** Easy to assume the dashboard's live/live_session macros are already globally available in `DevRouter` because the dashboard route "just works" — but that availability is macro-local, not module-global.
**How to avoid:** Add `import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]` at the top of `dev/dev_router.ex` before adding the new `scope "/scoria/_lab"` block.
**Warning signs:** `warning: Phoenix.LiveView.Router.live/3 is undefined` or similar at `mix compile` (dev env).

### Pitfall 4: State-name vs. tone-name drift (D-11/D-12)

**What goes wrong:** A section author writes `<.badge tone={:warning} .../>` (using the *lab state* name `warning` as if it were a *visual tone*) instead of `<.badge tone={:warn} .../>` (the actual `ScoriaWeb.UI` tone atom). `ScoriaWeb.UI.badge/1`'s `tone` attr has no `values:` constraint list, so this silently falls through to whatever CSS class `scoria-badge--warning` resolves to (likely unstyled/default), rather than raising.
**Why it happens:** `warning`/`danger`/`error` (lab states) are lexically close to `:warn`/`:fail` (tones) but not identical strings — a natural typo, not a logic error.
**How to avoid:** Route every state→visual-affordance decision through one explicit `state_tone/1` function (Pattern 3 above) rather than inlining tone atoms per call site; never pass a D-11 state atom directly as a `tone` attr.
**Warning signs:** Any HEEx literal `tone={:warning}`, `tone={:danger}` (should be `:warn`, `:fail`), or `tone={:error}` in `dev/lab/`.

### Pitfall 5: Fixture data quietly becoming a hidden business rule (D-21)

**What goes wrong:** A page under `lib/scoria_web/live/` starts importing/aliasing `DevLab.Fixtures` "just to get a quick example row for an empty branch," and over time real behavior (e.g. a default policy name, a magic tenant id) leaks from the lab fixture catalog into runtime logic.
**Why it happens:** Fixture data is realistic and convenient; the dev-only compile boundary makes the leak a compile error only if the reference is unconditional — a lazy `Code.ensure_loaded?(DevLab.Fixtures)` guard could mask it.
**How to avoid:** Treat `dev/lab/fixtures.ex` (and everything under `dev/lab/`) as *evidence for maintainers*, never import it from `lib/`. The Pitfall-1 text-scan guard test doubles as enforcement here: assert zero matches for `DevLab\.` (or the chosen module prefix) inside `lib/**/*.{ex,heex}`.
**Warning signs:** Any `DevLab` (or `ScoriaWeb.DevLabFixtures`/`ScoriaWeb.DevFixtures`) reference under `lib/`.

## Code Examples

### Verified: `data-scoria-ready` sentinel wiring (reused as-is, no lab-side change needed)

```javascript
// Source: assets/js/scoria.js:759 (read verbatim in this session)
document.documentElement.setAttribute("data-scoria-ready", "true");
```
```javascript
// Source: priv/dev/e2e/lib/ready.mjs (read verbatim in this session)
export async function waitForReady(page, timeoutMs = 15000) {
  await page.waitForFunction(
    () => document.documentElement.getAttribute('data-scoria-ready') === 'true',
    { timeout: timeoutMs }
  );
}
```

### Verified: reduced-motion + viewport proof pattern already used for the dashboard (reuse directly for the lab spec)

```javascript
// Source: priv/dev/e2e/phase16_parity.spec.mjs (pattern read verbatim in this session)
test.use({ viewport: { width: 375, height: 812 } });
// ...
await page.emulateMedia({ reducedMotion: 'reduce' });
// ...
await page.setViewportSize({ width: 1280, height: 900 });
```

### Verified: text-based guard test pattern to adapt for the lab exclusion proof

```elixir
# Source: test/scoria_web/ds06_drift_guard_test.exs (pattern read verbatim in this session)
test "public dashboard macro never mounts the lab" do
  source = File.read!("lib/scoria_web/router.ex")
  refute source =~ "_lab",
         "lib/scoria_web/router.ex must not reference the dev-only component lab (D-01/D-03)"
end

test "package.files never ships dev/ or priv/dev/" do
  {files, _} = Code.eval_file("mix.exs") |> then(fn _ -> {nil, nil} end)
  source = File.read!("mix.exs")
  # Read package/0's files: list textually rather than compiling the project again.
  refute source =~ ~r/"dev"(?!_)/, "package files must not include the dev/ directory"
end

test "dashboard nav and command palette never link the lab" do
  nav_source = File.read!("lib/scoria_web/dashboard_nav.ex")
  layouts_source = File.read!("lib/scoria_web/components/layouts.ex")
  refute nav_source =~ "_lab"
  refute layouts_source =~ "_lab"
end
```
Note: `mix.exs` itself is a `.ex` file compiled by Mix on every invocation — reading it with `File.read!/1` for a regex assertion (rather than re-evaluating `Mix.Project.config()[:package][:files]`, which would require the already-loaded project config) is the safe, side-effect-free approach used here, consistent with how the DS06 guard treats source files as plain text.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| No dev-only component preview surface | Repo-local `/scoria/_lab` LiveView lab, `dev/`-scoped | Phase 37 (this phase) | Maintainers get systematic state/theme/viewport/motion coverage before Phase 38-41 touch shared controls |
| Screenshot-only visual QA (`mix scoria.ui.shots` on real dashboard pages) | Lab-driven state-matrix inspection + existing screenshot harness stays page-focused | Phase 37 | The two are complementary, not a replacement — shots.mjs still covers the 9 real dashboard screens; the lab covers isolated component/state coverage the pages can't (e.g. an `error` state that never occurs on the seeded dashboard) |

**Deprecated/outdated:** None — this phase adds capability, it does not replace or deprecate any existing proof surface. `STORYBOOK-01` and `VISUAL-CI-01` remain explicitly deferred future-evaluation paths (REQUIREMENTS.md), not something this research recommends adopting now.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Module naming `DevLab.LabLive` / `DevLab.Fixtures` (vs. the CONTEXT.md-suggested `ScoriaWeb.DevLabFixtures`/`ScoriaWeb.DevFixtures`) is Claude's Discretion territory, not a locked name | Recommended Project Structure, Pattern 2/3 | Low — CONTEXT.md explicitly delegates exact module names to downstream agents; either naming works structurally. Planner should pick one and use it consistently; this research's examples are illustrative, not prescriptive |
| A2 | `mix phx.server` in the CI `e2e` job compiles under the default `:dev` Mix env (not `:test` or `:prod`) | Pitfall 2, System Architecture Diagram | Low-Medium — if CI actually pins `MIX_ENV` elsewhere for that job, the lab route would not exist at `/scoria/_lab` during the e2e job and `lab.spec.mjs` would fail outright at route-load. Verify by checking `MIX_ENV` env var scoping in `.github/workflows/ci.yml`'s `e2e` job before relying on it (no explicit `env: MIX_ENV` was found in the job in this session's read, which supports the default-`:dev` assumption, but was not exhaustively grepped across the whole file) |

## Open Questions

1. **Should the lab's own `handle_params`/section routing use a single `DevLab.LabLive` or one LiveView per top-level IA section?**
   - What we know: A single param-driven LiveView (Pattern 2) keeps route wiring in `dev_router.ex` minimal (3 `live` clauses) and matches D-06's "Claude's Discretion... prefer... small modules over a clever DSL."
   - What's unclear: Whether `Fixtures` (browsing raw fixture catalog data, D-27 "Open fixture matrix" command) is better as a `live_component` inside the same LiveView or a fully separate route.
   - Recommendation: Default to one LiveView with `handle_params`-driven sections (simplest, fewest route declarations); let the planner split into `live_component`s per section only if a single `render/1` becomes unwieldy (>~300 lines).

2. **Exact shape of the "coverage check" mentioned in D-32 — text-regex only, or also a `dev/mix_tasks/` runtime check?**
   - What we know: The text-regex approach (Pitfall 1 / Code Examples) is sufficient to prove state-name and D-20 scenario-name string presence in `dev/lab/**/*.ex` source, mirroring the proven DS06 pattern, and needs no new CI wiring.
   - What's unclear: Whether the planner wants a stronger *semantic* coverage check (e.g., "every `PRIM-*`/`GROUP-*` `canonical` row in `36-inventory.json` has a corresponding lab entry") which would require parsing the actual lab section list, not just grepping for substrings.
   - Recommendation: Start with text-regex (D-32 says "if practical" — text-regex against inventory IDs referenced as literal strings in lab source, per D-08/D-29, is directly practical). Defer a JSON-cross-reference coverage script to a later polish task if the planner judges it worth the added complexity.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Phoenix/Phoenix LiveView | Lab LiveView | ✓ | Elixir `~> 1.19`, Phoenix `~> 1.7`, LiveView `~> 1.0` (mix.exs) | — |
| Bandit + phoenix_live_reload (`:dev`-only deps) | `ScoriaWeb.DevEndpoint` (reused, unchanged) | ✓ | `bandit ~> 1.5`, `phoenix_live_reload ~> 1.5` | — |
| Node.js ≥ 18 | `mix scoria.ui.e2e` (lab.spec.mjs) | ✓ (assumed present in CI `e2e` job — `actions/setup-node@v*` with `node-version: "20"` seen in `.github/workflows/ci.yml`) | 20 (CI) | — |
| `@playwright/test` / `playwright` 1.60.0 | `lab.spec.mjs` | ✓ (already installed, `priv/dev/package.json`) | 1.60.0 pinned | — |
| PostgreSQL | Only if lab needs a live DB read (it should not — D-17) | N/A | — | Lab fixtures are static Elixir data; no DB dependency planned |

**Missing dependencies with no fallback:** None identified.
**Missing dependencies with fallback:** None — all required tooling is already present in the repo.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`) + `@playwright/test` (Playwright, via `mix scoria.ui.e2e`) |
| Config file | `mix.exs` (`elixirc_paths/1`, `test_load_filters`); `priv/dev/e2e/playwright.config.mjs` |
| Quick run command | `mix test --warnings-as-errors test/scoria_web/dev_lab_boundary_test.exs` |
| Full suite command | `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` (ExUnit); `make dev` then `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` (Playwright, local) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAB-01 | Lab route renders `ScoriaWeb.UI` primitives/groups; public macro and Hex footprint untouched | unit + guard | `mix test test/scoria_web/dev_lab_boundary_test.exs` | ❌ Wave 0 |
| LAB-01 | Lab route actually loads in a real browser at `/scoria/_lab` | e2e | `mix scoria.ui.e2e` (picks up `priv/dev/e2e/lab.spec.mjs`) | ❌ Wave 0 |
| LAB-02 | Theme (light/dark/system), reduced motion, and all 6 viewports are inspectable/provable | e2e | `mix scoria.ui.e2e` (`lab.spec.mjs`: theme toggle, `emulateMedia`, `setViewportSize` per width) | ❌ Wave 0 |
| LAB-02 | All 10 canonical states (`normal`...`error`) render for covered primitives | unit (text coverage) + visual (manual) | `mix test test/scoria_web/dev_lab_boundary_test.exs` (state-name presence scan) | ❌ Wave 0 |
| FIXT-01 | Fixture catalog covers approvals/incidents/reviews/datasets/workflow/connectors/prompts/evals/empty/error domains with D-20 scenario names | unit (text coverage) | `mix test test/scoria_web/dev_lab_boundary_test.exs` (D-20 scenario-name presence scan) | ❌ Wave 0 |
| D-21 | Runtime `lib/` never references dev-only lab/fixture modules | guard | `mix test test/scoria_web/dev_lab_boundary_test.exs` (zero-reference scan of `lib/**/*.{ex,heex}`) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix compile --warnings-as-errors` (dev env, to catch Pitfall 3-class compile errors early) + `mix test test/scoria_web/dev_lab_boundary_test.exs`
- **Per wave merge:** `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` (full ExUnit) + local `mix scoria.ui.e2e` run before pushing (CI `e2e` job will also run it, but it is a required gate — see Pitfall 2)
- **Phase gate:** Full ExUnit suite green + CI `e2e` job green (already required by `ci-gate`) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria_web/dev_lab_boundary_test.exs` — covers LAB-01 (exclusion), LAB-02/FIXT-01 (state/domain coverage text-scan), D-21 (zero `lib/` reference guard)
- [ ] `priv/dev/e2e/lab.spec.mjs` — covers LAB-01 (route load), LAB-02 (theme/motion/viewport), D-33 curated probes (dense table, overlay focus, toast-over-dense-UI stress fixture, copy controls)
- [ ] No new fixture/shared-test-helper file needed — `dev/lab/fixtures.ex` is itself the fixture source; no `test/support/` addition required since guard tests are pure text-scans

*(No pre-existing test infrastructure covers dev-only lab surfaces — this is the first phase to add either the module tree or its proof.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Lab is dev-only, localhost-bound in normal use; no auth surface added or changed |
| V3 Session Management | no (reused, unchanged) | Reuses the existing `:browser` pipeline's `fetch_session`/`protect_from_forgery`/`Plug.Session` config (`ScoriaWeb.DevEndpoint`) verbatim — no new session logic |
| V4 Access Control | **yes — this is the core threat for this phase** | Structural exclusion: `dev/`-only `elixirc_paths`, `mix.exs` `package.files` allowlist (not denylist-of-dev), no reference from `lib/scoria_web/router.ex`'s public macro, no link from `dashboard_nav.ex`/command palette (D-01, D-03, D-05, D-31) |
| V5 Input Validation | minor | Lab route params (`:section`, `:item`) are used only to select among a fixed, compile-time-known set of section/component atoms — validate with an explicit allowlist match (`case`/pattern match), not raw string interpolation into anything executed |
| V6 Cryptography | no | No crypto surface added |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental adopter-facing exposure of dev tooling (lab shipped to Hex, or reachable via public macro) | Information Disclosure / Elevation of Privilege (exposes internal fixture/evidence data + maintainer-only affordances to a production host app) | Structural: `elixirc_paths(:dev)` compile boundary + `mix.exs` `package.files` allowlist + text-scan guard tests proving both boundaries (this phase's `dev_lab_boundary_test.exs`) — this is the *primary* mitigation this phase must prove, not a generic "add auth" control |
| Fixture data silently becoming a hidden runtime dependency | Tampering (business logic drifts from documented behavior) | D-21 zero-reference guard (`lib/` never imports `dev/`-scoped fixture modules) — enforced by the same guard test |
| Lab route params used unsafely to select a component/section | Tampering / minor Information Disclosure (arbitrary atom creation from user input, or reflected content) | Match `:section`/`:item` params against a fixed, compile-time list (`String.to_existing_atom/1` guarded by a `case`, or a literal `Map`/allowlist lookup) — never `String.to_atom/1` on unvalidated params |

## Sources

### Primary (HIGH confidence)
- `lib/scoria_web/router.ex` — `scoria_dashboard/2` macro body, confirms it is untouched by this phase's design
- `dev/dev_router.ex`, `dev/dev_endpoint.ex` — dev-only compile boundary, `:browser` pipeline, `put_demo_tenant` precedent
- `dev/mix_tasks/scoria_dev_db.ex` — precedent for dev-only Mix tasks run under default `:dev` env
- `mix.exs` — `elixirc_paths/1` per-env split, `package/0` `files:` allowlist, deps (no new deps needed)
- `lib/scoria_web/ui.ex` (1477 lines, read in full via `grep`/section reads) — full primitive/attr/slot surface enumerated
- `lib/scoria_web/components/layouts.ex`, `layouts/root.html.heex` — root layout reuse, `ScoriaWeb.Assets` inlining mechanism
- `lib/scoria_web/dashboard_nav.ex` — confirms `on_mount`/`@views` map does not (and should not) include lab views
- `lib/scoria_web/assets.ex` — compile-time CSS/JS inlining, mount-path independence
- `assets/js/scoria.js` — `data-scoria-ready` sentinel (line 759), `ThemeToggle`, `Dismissable`, `CommandPalette`, `MobileNav` hooks read in full
- `assets/css/05-motion.css` — reduced-motion mechanism (unlayered `@media (prefers-reduced-motion: reduce)`, `!important`), confirms no per-component toggle exists today
- `test/scoria_web/ds06_drift_guard_test.exs`, `token_contrast_guard_test.exs` — proven text-scan guard-test pattern
- `test/scoria_web/ui_component_test.exs` — existing component proof/`render_component` conventions
- `priv/dev/e2e/playwright.config.mjs`, `phase16_parity.spec.mjs`, `uat.spec.mjs`, `lib/ready.mjs` — e2e patterns (`emulateMedia`, `setViewportSize`, `waitForReady`)
- `lib/mix/tasks/scoria.ui.shots.ex`, `scoria.ui.e2e.ex` — confirms `testDir`-driven spec pickup, "no new mix task" precedent, and that `lib/mix/tasks/*` ships to Hex but only shells out at runtime (never compile-time-references `dev/`)
- `.github/workflows/ci.yml` — confirms `e2e` job is a required `ci-gate` dependency, `mix phx.server` boot step, port 4000
- `docs/uat_automation.md` — `test.fixme` convention, Tier 1/Tier 2 test classification
- `docs/MAINTAINERS.md` — CI lane map, confirms `MIX_ENV=dev mix scoria.release_preview` precedent for dev-only CI steps
- `.planning/phases/36-baseline-and-inventory/36-inventory.json` — full 86-row inventory (all `PRIM-*`/`GROUP-*`/`HOOK-*`/`PAGE-*` IDs), risk register (`RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`, `RISK-TOAST-LEGIBILITY`, `RISK-V30-PROOF`), and the `MISSING-COMPONENT-LAB-STATES` row this phase directly closes
- `.planning/REQUIREMENTS.md` — LAB-01, LAB-02, FIXT-01 exact wording; `STORYBOOK-01`/`VISUAL-CI-01` deferred status
- `.planning/phases/37-dev-component-lab-and-stress-fixtures/37-CONTEXT.md`, `37-UI-SPEC.md` — locked D-01..D-34 decisions and the approved UI design contract, read in full

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` — sibling-scope router-mount precedent for a dev tool (pattern analogy only, not copied verbatim)
- `https://hexdocs.pm/phoenix_storybook/components.html`, `https://lookbook.build/guide/components/view_component`, `https://viewcomponent.org/guide/previews.html` — conceptual precedent for "render a component across states," reimplemented natively per D-04 (not adopted as dependencies)

### Tertiary (LOW confidence)
- None — all findings in this research are grounded in files read directly in this session; no unverified WebSearch-only claims were needed given the phase is entirely internal-pattern-driven.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; every mechanism (layout reuse, sentinel, motion, e2e wiring) verified by reading the actual source in this session.
- Architecture: HIGH — route-mounting pattern, compile-path boundary, and layout reuse are all directly derived from existing, working code in this exact repo (not analogous external precedent).
- Pitfalls: HIGH — Pitfalls 1-3 are structural facts about this repo's `mix.exs`/CI config (verified by reading `elixirc_paths/1`, `ci.yml`, and confirming via `grep` that no prior test references `DevRouter`/`DevEndpoint`); Pitfalls 4-5 are direct readings of the locked D-11/D-12/D-21 decisions.

**Research date:** 2026-07-02
**Valid until:** 30 days (stable, repo-internal patterns; re-verify if `mix.exs` `elixirc_paths`, `ScoriaWeb.Layouts`, or the `e2e` CI job topology change before planning executes)
