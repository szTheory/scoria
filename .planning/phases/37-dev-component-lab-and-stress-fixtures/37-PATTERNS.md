# Phase 37: Dev Component Lab And Stress Fixtures - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 9 new/modified
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `dev/dev_router.ex` (MODIFIED — add `live_session :scoria_lab`) | route | request-response | `dev/dev_router.ex` (existing `scope "/"` + `scoria_dashboard/2` body) | exact (self-modify) |
| `dev/lab/lab_live.ex` | controller (LiveView) | request-response | `lib/scoria_web/router.ex` `scoria_dashboard/2` macro's `live_session`/`live` wiring + `lib/scoria_web/components/layouts/root.html.heex` | role-match |
| `dev/lab/fixtures.ex` (`DevLab.Fixtures` / `ScoriaWeb.DevLabFixtures`) | model (static fixture catalog) | CRUD (read-only, in-memory) | `lib/scoria/support_journey.ex` + `lib/scoria/support_journey/handlers.ex` | role-match |
| `dev/lab/sections/states.ex` (`states_band/1`) | component | transform (render-per-state) | `lib/scoria_web/ui.ex` (`badge/1`, `panel/1` attr/slot shape) | role-match |
| `dev/lab/sections/{primitives,groups,foundations,viewports,overlays,fixtures_view}.ex` | component | transform | `lib/scoria_web/ui.ex` (`page_section/1`, `panel/1`) + `lib/scoria_web/components/*.ex` group components | role-match |
| `test/scoria_web/dev_lab_boundary_test.exs` | test (guard) | batch (text-scan) | `test/scoria_web/ds06_drift_guard_test.exs` | exact |
| `priv/dev/e2e/lab.spec.mjs` | test (e2e) | request-response (browser) | `priv/dev/e2e/phase16_parity.spec.mjs` | exact |
| `docs/MAINTAINERS.md` (MODIFIED — add Component Lab section) | config/docs | — | existing `docs/MAINTAINERS.md` CI-lane/dev-command sections | exact (self-modify) |
| (no `test/support/` file needed) | — | — | — | n/a — guard test is pure text-scan, no fixture-module dependency (Pitfall 1) |

## Pattern Assignments

### `dev/dev_router.ex` (route, request-response)

**Analog:** itself (`dev/dev_router.ex`, full file already read — 55 lines)

**Current full shape** (lines 1-55):
```elixir
defmodule ScoriaWeb.DevRouter do
  use Phoenix.Router
  import Phoenix.Controller
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_demo_tenant)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end

  defp put_demo_tenant(conn, _opts) do
    if Plug.Conn.get_session(conn, "tenant_id") do
      conn
    else
      Plug.Conn.put_session(conn, "tenant_id", Scoria.SupportJourney.tenant_id())
    end
  end
end
```

**Required addition** (per RESEARCH.md Pattern 1, verified against this exact file — `live`/`live_session` are NOT currently imported at module scope, only inside `scoria_dashboard/2`'s own `quote` block per Pitfall 3):
```elixir
import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 3]

scope "/scoria/_lab" do
  pipe_through(:browser)

  live_session :scoria_lab, root_layout: {ScoriaWeb.Layouts, :root} do
    live("/", DevLab.LabLive, :index)
    live("/:section", DevLab.LabLive, :index)
    live("/:section/:item", DevLab.LabLive, :index)
  end
end
```

**Rule:** Keep this block textually separate from `scope "/" do ... scoria_dashboard("/scoria") end` — the boundary guard test (`dev_lab_boundary_test.exs`) proves `lib/scoria_web/router.ex` never references `_lab`; this file (`dev/`) is where the lab scope belongs, never `lib/`.

---

### `dev/lab/lab_live.ex` (controller/LiveView, request-response)

**Analogs:**
1. `lib/scoria_web/router.ex` — `scoria_dashboard/2` macro body (for `live_session`/route-param wiring conventions; do not copy the macro shape itself, just the session/pipeline idiom)
2. `lib/scoria_web/components/layouts/root.html.heex` (full file, 32 lines, read verbatim above) — reuse this layout **as-is**, unmodified, via `use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}`

**Root layout excerpt to reuse (lines 1-32)** — already self-contained (compile-time CSS/JS inlining, pre-paint theme script, `data-scoria-ready` wiring via `assets/js/scoria.js`):
```heex
<html lang="en" class="scoria-root" data-theme="dark" data-theme-mode="system" data-scoria-socket={assigns[:scoria_socket_path] || "/live"}>
  <head>
    ...
    <style nonce={assigns[:scoria_nonce]}><%= Phoenix.HTML.raw(ScoriaWeb.Assets.css()) %></style>
    <script nonce={assigns[:scoria_nonce]}>/* pre-paint theme resolution */</script>
  </head>
  <body>
    {@inner_content}
    <script nonce={assigns[:scoria_nonce]}><%= Phoenix.HTML.raw(ScoriaWeb.Assets.js()) %></script>
  </body>
</html>
```

**Core pattern — `handle_params`-driven section routing** (no analog file has this exact shape in-repo; this is RESEARCH.md's synthesized pattern, safe to use as the copy source since it is grounded in verified `Phoenix.LiveView` conventions and the root-layout excerpt above):
```elixir
defmodule DevLab.LabLive do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}
  import ScoriaWeb.UI

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(socket,
       section: params["section"] || "foundations",
       item: params["item"],
       page_title: "Component Lab"
     )}
  end
end
```

**V5 input-validation rule (from RESEARCH.md Security Domain):** match `:section`/`:item` params against a fixed compile-time allowlist (`case`/pattern match); never `String.to_atom/1` on unvalidated params.

---

### `dev/lab/fixtures.ex` (model/fixture catalog, CRUD read-only)

**Analog:** `lib/scoria/support_journey.ex` + `lib/scoria/support_journey/handlers.ex` — realistic domain-fixture spine already in the repo (approvals, incidents, tool/handler outputs).

Read these two files for the domain-noun naming convention (`approval_requested`, `incident_opened`, etc. already exist as real Scoria domain events there) before inventing new scenario names — D-20's required names should match/extend that existing vocabulary rather than diverge from it.

**Shape to copy (D-16/D-17):** deterministic, reset-free, HEEx-safe maps keyed by scenario atom/string name, e.g.:
```elixir
defmodule DevLab.Fixtures do
  @moduledoc """
  Dev-only (:dev env, never shipped to Hex — see mix.exs elixirc_paths/1).
  Deterministic, reset-free fixture catalog for the Component Lab. NEVER
  reference from lib/ — see D-21 / dev_lab_boundary_test.exs.
  """

  def states_for(:badge) do
    [
      normal: %{tone: :neutral, label: "Normal"},
      warning: %{tone: :warn, label: "Warning"},
      danger: %{tone: :fail, label: "Danger"},
      # ... all 10 canonical D-11 states
    ]
  end

  def scenario(:approval_requested), do: %{...}
  def scenario(:incident_opened), do: %{...}
  # D-20 domain-noun scenario names, covering approvals/incidents/reviews/
  # datasets/workflow detail/connectors/prompts/evals/empty/error paths (D-19)
end
```

**Critical constraint (D-12/D-21, enforced structurally):** never call `ScoriaWeb.UI.tone/1` (domain-status → tone mapper) on a lab *state* name. Write an explicit `state_tone/1` mapping instead (see `states.ex` below). Never reference this module from any file under `lib/`.

---

### `dev/lab/sections/states.ex` (component, transform)

**Analog:** `lib/scoria_web/ui.ex` `badge/1` (lines 60-74, read verbatim) — canonical `attr`/`slot` contract shape to mirror for all lab-authored function components.

**Imports/attr pattern to copy** (from `ui.ex` lines 60-74):
```elixir
attr(:tone, :atom, default: :neutral)
attr(:label, :string, default: nil)
attr(:dot, :boolean, default: true)
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:inner_block)

def badge(assigns) do
  ~H"""
  <span class={["scoria-badge", "scoria-badge--#{@tone}", not @dot && "scoria-badge--bare", @class]} {@rest}>
    {@label}{render_slot(@inner_block)}
  </span>
  """
end
```

**Core "state band" pattern to build** (per RESEARCH.md Pattern 3 — plain `attr`/`slot` component, no DSL/macro per D-04/Claude's Discretion):
```elixir
defmodule DevLab.Sections.States do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1, panel: 1]

  attr :inventory_id, :string, required: true
  attr :states, :list, required: true
  slot :render, required: true do
    attr :fixture, :any
  end

  def states_band(assigns) do
    ~H"""
    <div class="scoria-lab-states" data-inventory-id={@inventory_id}>
      <div :for={{state, fixture} <- @states} class="scoria-lab-state" data-lab-state={state}>
        <.badge tone={state_tone(state)} label={to_string(state)} />
        <div class="scoria-lab-state__specimen">{render_slot(@render, fixture)}</div>
      </div>
    </div>
    """
  end

  # D-12: explicit lab-state -> visual-tone table. NEVER derive from ScoriaWeb.UI.tone/1
  # (that maps domain status strings, a different vocabulary — Pitfall 4).
  defp state_tone(:warning), do: :warn
  defp state_tone(:danger), do: :fail
  defp state_tone(:error), do: :fail
  defp state_tone(:selected), do: :brand
  defp state_tone(_), do: :neutral
end
```

---

### `dev/lab/sections/{primitives,groups,foundations,viewports,overlays,fixtures_view}.ex` (components, transform)

**Analog:** `lib/scoria_web/ui.ex` `page_section/1` (lines 193+) and `panel/1` (lines 155-192, `attr(:variant, :atom, default: :flat, values: [:flat, :raised])`, `slot(:eyebrow)`, `slot(:title)`, `slot(:actions)`, `slot(:inner_block, required: true)`) for section-container chrome; `lib/scoria_web/components/*.ex` for the actual recurring dashboard component groups being cataloged (approval inbox, workflow tree/detail, connector drawer, incident evidence, evidence notebook — enumerate via `Glob("lib/scoria_web/components/*.ex")` when authoring each section).

**Rule (UI-SPEC "Component Inventory For Lab Chrome"):** lab chrome itself must be built ONLY from existing `ScoriaWeb.UI` primitives: `badge/1`, `eyebrow/1` (lines 139-143), `kbd/1`, `id/1` (line 307+), `panel/1`, `page_section/1`, `empty_state/1` (line 653+), `skeleton/1` (line 843+), `drawer/1`, `modal/1`, `toast/1`, `raw_evidence/1`, `notebook/1`, `metric/1`, `overview_stats/1`, `signal_strip/1`. Do not invent new primitives; if new lab-only chrome is unavoidable (e.g. viewport-simulator frame), keep it internal to `dev/` and consume only `--scoria-*` semantic tokens.

---

### `test/scoria_web/dev_lab_boundary_test.exs` (test/guard, batch text-scan)

**Analog:** `test/scoria_web/ds06_drift_guard_test.exs` (lines 1-80, read verbatim)

**Imports/structure pattern to copy** (lines 1-22):
```elixir
defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  ...
  """

  @palette_regex ~r/.../
  @excluded ~w(...)
  @baseline_path "test/support/ds06_baseline.txt"
```

**Core text-scan assertion pattern to copy** (lines 32-54 shape — `Path.wildcard` + `File.read!` + `Regex.scan` + violations list + single `assert violations == []`):
```elixir
test "raw palette count never regresses (DS-06 ratchet)" do
  violations =
    for path <- Path.wildcard("lib/scoria_web/**/*.{ex,heex}"),
        path not in @excluded do
      count = path |> File.read!() |> then(&length(Regex.scan(@palette_regex, &1)))
      # ... compare against baseline
    end
    |> Enum.reject(&is_nil/1)

  assert violations == [], format_failure(violations)
end
```

**Concrete assertions to author for `dev_lab_boundary_test.exs`** (per RESEARCH.md's verified sketch and D-31/D-21/D-32):
```elixir
test "public dashboard macro never mounts the lab" do
  source = File.read!("lib/scoria_web/router.ex")
  refute source =~ "_lab"
end

test "package.files never ships dev/ or priv/dev/" do
  source = File.read!("mix.exs")
  refute source =~ ~r/"dev"(?!_)/
end

test "dashboard nav and command palette never link the lab" do
  refute File.read!("lib/scoria_web/dashboard_nav.ex") =~ "_lab"
  refute File.read!("lib/scoria_web/components/layouts.ex") =~ "_lab"
end

test "lib/ never references dev-only lab/fixture modules (D-21)" do
  violations =
    for path <- Path.wildcard("lib/**/*.{ex,heex}"),
        File.read!(path) =~ ~r/DevLab\./ do
      path
    end

  assert violations == []
end

test "all D-11 canonical states are present in lab source" do
  states = ~w(normal long_text empty dense disabled selected loading warning danger error)
  source = "dev/lab" |> Path.wildcard("**/*.ex") |> Enum.map_join(&File.read!/1)
  for s <- states, do: assert(source =~ s, "missing state: #{s}")
end

test "all D-20 fixture scenario names are present in lab source" do
  scenarios = ~w(approval_requested approval_denied incident_opened incident_escalated
                 review_candidate_flagged dataset_promoted dataset_empty
                 workflow_waiting_for_approval workflow_failed_step
                 connector_degraded connector_scope_blocked
                 prompt_release_blocked eval_regression_detected)
  source = Path.wildcard("dev/lab/**/*.ex") |> Enum.map_join(&File.read!/1)
  for s <- scenarios, do: assert(source =~ s, "missing fixture scenario: #{s}")
end
```

**Critical:** never `alias`/`import` a `dev/`-scoped module directly (Pitfall 1) — `test/`'s `elixirc_paths` excludes `dev/`; this test file must be pure `File.read!/1` + regex, exactly like the DS06 guard.

---

### `priv/dev/e2e/lab.spec.mjs` (test/e2e, request-response browser)

**Analog:** `priv/dev/e2e/phase16_parity.spec.mjs` (header + first 40 lines read verbatim)

**Imports pattern to copy** (lines 1-16):
```javascript
import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
```

**Reduced-motion + viewport proof pattern to copy** (verified in RESEARCH.md, drawn from this same file):
```javascript
test.use({ viewport: { width: 375, height: 812 } });
await page.emulateMedia({ reducedMotion: 'reduce' });
await page.setViewportSize({ width: 1280, height: 900 });
```

**Readiness pattern** (`priv/dev/e2e/lib/ready.mjs`, reused as-is, no changes needed):
```javascript
export async function waitForReady(page, timeoutMs = 15000) {
  await page.waitForFunction(
    () => document.documentElement.getAttribute('data-scoria-ready') === 'true',
    { timeout: timeoutMs }
  );
}
```

**Required lab.spec.mjs coverage (D-33):** route load at `/scoria/_lab`, theme toggle, `emulateMedia({reducedMotion: 'reduce'})`, `setViewportSize` scan across 320/375/768/1024/1440/wide, overlay/focus probe, dense table/list case, toast-region-over-dense-UI fixture, copy-control check.

**Critical (Pitfall 2):** this file is picked up automatically by the required `e2e` CI job (`testDir`-driven, no task/CI changes needed). Every assertion must be true of what actually ships in this phase — use the established `test.fixme('<reason> — <unlock>')` convention (`docs/uat_automation.md`) for anything intentionally deferred; never leave a bare failing/flaky assertion.

---

### `docs/MAINTAINERS.md` (docs, config)

**Analog:** itself — existing CI-lane map / dev-command sections (`make dev`, `MIX_ENV=dev mix scoria.release_preview` precedent per RESEARCH.md Sources).

**Content to add (D-34):** how to start the dev server, open `/scoria/_lab`, inspect states/domains, update `dev/lab/fixtures.ex`, run `mix test test/scoria_web/dev_lab_boundary_test.exs` and `mix scoria.ui.e2e`, and how lab probes relate to Phases 38-41.

---

## Shared Patterns

### Dev-only compile/package boundary
**Source:** `dev/dev_router.ex` module doc (lines 1-13) + `mix.exs` `elixirc_paths/1` and `package/0` `files:` allowlist
**Apply to:** every new file under `dev/lab/`
```elixir
# dev/ compiles ONLY under MIX_ENV=dev; excluded from Hex package.files.
# test/ elixirc_paths does NOT include dev/ — see Pitfall 1.
```

### `attr`/`slot` function-component contract
**Source:** `lib/scoria_web/ui.ex` (`badge/1` lines 60-74, `panel/1` lines 155-192)
**Apply to:** all `dev/lab/sections/*.ex` and `dev/lab/fixtures.ex`-consuming components
```elixir
attr(:tone, :atom, default: :neutral)
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:inner_block)
```

### Root layout reuse (self-contained CSS/JS/theme/readiness)
**Source:** `lib/scoria_web/components/layouts/root.html.heex` (full file, 32 lines)
**Apply to:** `dev/lab/lab_live.ex` — `use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}`

### Text-scan guard-test structure
**Source:** `test/scoria_web/ds06_drift_guard_test.exs` (lines 1-54)
**Apply to:** `test/scoria_web/dev_lab_boundary_test.exs`
```elixir
for path <- Path.wildcard("..."), do: File.read!(path) =~ pattern
assert violations == []
```

### Playwright readiness + motion/viewport proof
**Source:** `priv/dev/e2e/phase16_parity.spec.mjs` + `priv/dev/e2e/lib/ready.mjs`
**Apply to:** `priv/dev/e2e/lab.spec.mjs`
```javascript
await waitForReady(page);
await page.emulateMedia({ reducedMotion: 'reduce' });
await page.setViewportSize({ width, height });
```

## No Analog Found

None — every file in scope has at least a role-match analog already in the repo (see RESEARCH.md "Runtime State Inventory": this is a greenfield tree, but every mechanism it composes — layout, sentinel, motion, e2e wiring, guard-test shape, fixture-domain vocabulary — already exists and was read verbatim in this session or the research session).

## Metadata

**Analog search scope:** `dev/`, `lib/scoria_web/ui.ex`, `lib/scoria_web/components/layouts/root.html.heex`, `lib/scoria/support_journey.ex`, `test/scoria_web/ds06_drift_guard_test.exs`, `priv/dev/e2e/`
**Files scanned:** 9 (dev_router.ex, ds06_drift_guard_test.exs, root.html.heex, ui.ex excerpt lines 55-155, phase16_parity.spec.mjs header, plus 37-CONTEXT.md/37-RESEARCH.md/37-UI-SPEC.md already-verified excerpts)
**Pattern extraction date:** 2026-07-02
