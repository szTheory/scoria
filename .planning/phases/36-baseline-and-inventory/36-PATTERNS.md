# Phase 36: Baseline And Inventory - Pattern Map

**Mapped:** 2026-06-20
**Files analyzed:** 2 new artifact files plus read-only inventory inputs
**Analogs found:** 2 / 2

Phase 36 is a repository-local planning-artifact phase. Runtime UI files, tests, docs, and proof harnesses are inventory inputs only; the planner should not schedule source edits unless inventory generation itself is blocked.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` | doc / planning artifact | file-I/O + transform | `.planning/research/v3.3-design-system-stress-test-inventory.md` | exact |
| `.planning/phases/36-baseline-and-inventory/36-inventory.json` | structured data artifact | transform + file-I/O | `.planning/WARNING-INVENTORY.md` plus `test/scoria_web/ds06_drift_guard_test.exs` baseline-row parsing | role-match |

## Read-Only Inventory Inputs

| Inventory Surface | Role | Data Flow | Source / Analog | Planner Constraint |
|-------------------|------|-----------|-----------------|--------------------|
| `lib/scoria_web/ui.ex` | component library | request-response SSR | self, `ScoriaWeb.UI` attrs/slots | scan only |
| `assets/css/*.css` | design-system foundation | transform | CSS layers and semantic token docs | scan only |
| `assets/js/scoria.js` | hook/client interop | event-driven | self, hook registry | scan only |
| `lib/scoria_web/live/` | page surfaces | request-response SSR | LiveView modules | scan only |
| `lib/scoria_web/components/` | component groups | request-response SSR | evidence and drawer components | scan only |
| `test/scoria_web/` | proof surfaces | batch + request-response | component, LiveView, drift guard tests | scan only |
| `priv/dev/e2e/` and `priv/dev/shots.mjs` | browser proof | event-driven + file-I/O | Phase 16 parity spec and shot harness | scan only |
| `docs/`, `brandbook/`, `priv/shots/*.md` | docs / proof artifacts | file-I/O | maintainer docs, brand truth, gap registers | scan only |

## Pattern Assignments

### `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` (doc, file-I/O + transform)

**Analog:** `.planning/research/v3.3-design-system-stress-test-inventory.md`

**Artifact header + purpose pattern** (lines 1-5):
```markdown
# v3.3 Design System Stress Test Inventory

**Created:** 2026-06-20
**Milestone:** v3.3 Design System Stress Test
**Purpose:** Phase 36 baseline inventory for the Scoria admin/operator UI.
```

**Baseline proof section pattern** (lines 7-12):
```markdown
## Baseline

- Baseline commit: `f490cea` (`ui: consolidate scoria control room patterns`).
- Focused baseline verification passed before milestone start: `mix test test/scoria_web/ui_component_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/incidents_live_test.exs` returned 120 tests, 0 failures.
- Current design-system source of truth is `ScoriaWeb.UI`, tokenized CSS in `assets/css/`, and the canonical brand book in `brandbook/`.
```

Apply this structure, but update the provenance list from current git history: cleanup commits `1773267`, `d35906f`, `4337c5e`, `452f035`, `2d324a0`, `f490cea`; v3.3 planning commits begin at `8540e04` and currently include `2f2ad6e`, `d9097e8`, `16b574b`, `dc138e4`, `2eda3a7`, `388d70b`, `59ea4c8`.

**Foundation and guardrail summary pattern** (lines 14-29):
```markdown
## Canonical Foundations

- Runtime token layer: `assets/css/02-tokens.css`.
- Reset and focus baseline: `assets/css/01-reset.css`.
- Base typography and app chrome: `assets/css/03-base.css`.
- Component layer: `assets/css/04-components.css`.
- Motion contracts: `assets/css/05-motion.css`.
- Token-backed compatibility utilities: `assets/css/06-utilities.css`.
```

**Primitive and page inventory pattern** (lines 31-67, 85-99):
```markdown
## Canonical Primitive Components

Current `ScoriaWeb.UI` primitives:

- `badge/1`
- `button/1`
- `icon_button/1`
...
- `flash_group/1`

## Pages And Flow Surfaces

- Status Home.
- Approvals.
- Incidents index and incident detail.
...
- App shell, sidebar, mobile drawer, command palette, theme selector, breadcrumbs, and toasts.
```

Do not leave this as a loose prose list in the final Phase 36 artifact. Use it as the human-readable summary, then point each summarized item to canonical row IDs in `36-inventory.json`.

**Known duplication / legacy candidate pattern** (lines 115-121):
```markdown
## Known Duplication Or Legacy Candidates

- `metric/1`, `overview_stats/1`, and `signal_strip/1` overlap. `overview_stats/1` is the likely canonical page-level summary; `metric/1` may remain a low-level internal building block; `signal_strip/1` should be evaluated for migration or explicit deprecation.
- Some pages still contain direct `scoria-panel` markup or page-local panel composition. These should be audited against `page_section/1` and `panel/1` conventions rather than patched ad hoc.
```

**Risk register section pattern** (lines 123-143):
```markdown
## Accessibility And Motion Risk Register

High-priority checks:

- Drawer and modal focus trap/restoration after LiveView patches.
- Escape and click-outside dismissal consistency across drawer, modal, command palette, and mobile nav.
- Toasts are readable over dense UI and do not obscure primary decision controls.
```

Replace this loose list with the required central `Known Risk Register` fields from CONTEXT D-18/D-20: `risk_id`, title, affected JTBD/persona/operator flow, affected inventory refs, owner phase, mitigation/evidence target, status, closeout proof. Required starting IDs are `RISK-V30-PROOF`, `RISK-TOAST-LEGIBILITY`, `RISK-APPROVAL-HISTORY`, `RISK-RESPONSIVE-SCAN`, and `RISK-OVERLAY-FOCUS`.

**Proof and fixture coverage pattern** (lines 144-162):
```markdown
## Proof And Fixture Coverage

Existing proof surfaces:

- ExUnit component tests in `test/scoria_web/ui_component_test.exs`.
- LiveView tests for approvals, incidents, reviews, datasets, workflows, connectors, eval specs, prompts, and coming-soon pages.
- Dev-only Playwright harness in `priv/dev/e2e/`.
- Dev-only screenshot harness in `priv/dev/shots.mjs`.
```

### `.planning/phases/36-baseline-and-inventory/36-inventory.json` (structured data, transform + file-I/O)

**Analog:** `.planning/WARNING-INVENTORY.md` for generated artifact metadata and `.planning/research/v3.3-design-system-stress-test-inventory.md` for row categories.

**Generated metadata pattern** from `.planning/WARNING-INVENTORY.md` (lines 1-5):
```markdown
# Warning Inventory

Generated: 2026-05-27T23:21:15.126354Z
Git SHA: 9b3d6e81d99cd3365cdacbec87edd4cdf30ce1f5
Scope: full
```

For JSON, copy the same fields structurally:
```json
{
  "generated_at": "2026-06-20T00:00:00Z",
  "git_sha": "<current git sha>",
  "phase": "36",
  "scope": "v3.3 design-system baseline inventory",
  "schema_version": 1,
  "rows": [],
  "risks": []
}
```

**Required canonical row fields** from CONTEXT D-05/D-06:
```json
{
  "id": "PRIM-TABLE",
  "name": "Scoria table",
  "layer": "primitive",
  "status": "canonical",
  "owner_path": "lib/scoria_web/ui.ex",
  "evidence": ["lib/scoria_web/ui.ex:1198", "test/scoria_web/ui_component_test.exs"],
  "replacement_or_owner": "ScoriaWeb.UI.table/1",
  "next_action": "Feed Phase 37 lab states for desktop table, mobile summary, empty, pagination, and sort.",
  "risk_refs": ["RISK-RESPONSIVE-SCAN"]
}
```

**Layer enum:** `foundation`, `primitive`, `component-group`, `page`, `hook`, `fixture`, `test`, `doc`, `one-off`.

**Status enum:** `canonical`, `duplicated`, `legacy`, `missing`, `intentionally-page-specific`.

**Baseline parsing / validation lesson** from `test/scoria_web/ds06_drift_guard_test.exs` (lines 102-107, 115-128):
```elixir
defp load_baseline do
  @baseline_path
  |> File.read!()
  |> String.split("\n", trim: true)
  |> Enum.into(%{}, &parse_baseline_line/1)
end

defp parse_baseline_line(line) do
  case String.split(line, ":") do
    parts when length(parts) >= 2 ->
      {count_str, path_parts} = List.pop_at(parts, -1)
      path = path_parts |> Enum.join(":") |> String.trim()
      count_str = String.trim(count_str)
```

Planner implication: make the JSON strict and easy to parse. Every row must have all required keys; every `risk_refs` entry must point to a risk in the same file; every `owner_path` should be repository-relative.

## Shared Patterns

### Component Catalog And Semantic Gateway

**Source:** `docs/MAINTAINERS.md` lines 255-315 and `lib/scoria_web/ui.ex` lines 1-13.

```markdown
`ScoriaWeb.UI` is the single enforced token gateway for all dashboard UI components.
Every function component emits brand-book semantic classes (`assets/css/04-components.css`)
driven by design tokens; raw Tailwind palette classes (`bg-rose-200`, etc.) are blocked
in `lib/scoria_web/ui.ex` by `test/scoria_web/ds06_drift_guard_test.exs`.
```

```elixir
defmodule ScoriaWeb.UI do
  @moduledoc """
  Scoria's shared dashboard component vocabulary.
  ...
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
```

Apply to `primitive` rows. Use `ScoriaWeb.UI` function names as stable IDs where possible (`PRIM-BADGE`, `PRIM-TABLE`, `PRIM-DRAWER`, etc.).

### Phoenix Function Component Pattern

**Source:** `lib/scoria_web/ui.ex` lines 60-74 and 145-175.

```elixir
attr(:tone, :atom, default: :neutral)
attr(:label, :string, default: nil)
attr(:dot, :boolean, default: true)
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:inner_block)

@doc "Status badge. Always renders a text label alongside color (a11y: never color-alone)."
def badge(assigns) do
  ~H"""
  <span class={["scoria-badge", "scoria-badge--#{@tone}", not @dot && "scoria-badge--bare", @class]} {@rest}>
    {@label}{render_slot(@inner_block)}
  </span>
  """
end
```

```elixir
attr(:variant, :atom, default: :flat, values: [:flat, :raised])
attr(:flush, :boolean, default: false)
attr(:class, :string, default: nil)
attr(:rest, :global)
slot(:eyebrow)
slot(:title)
slot(:actions)
slot(:inner_block, required: true)
```

Inventory implication: a reusable primitive is `canonical` only when it has an owner function, `attr`/`slot` contract, semantic class output, representative usage, and tests/docs appropriate for the layer.

### Table And Responsive Scan Pattern

**Source:** `lib/scoria_web/ui.ex` lines 1198-1228 and 1239-1324.

```elixir
slot :col, doc: "Table column" do
  attr(:label, :string, required: true)
  attr(:key, :atom)
  attr(:class, :string)
end

slot(:empty)
slot(:action)
slot(:filter)

slot :mobile_summary,
  doc: "Opt-in per-row mobile summary rendered in a sibling container hidden at >=768px.
Exposes object label, status badge text, one key scalar/time, and a primary action.
When absent, the table keeps honest overflow at all widths." do
end
```

```heex
<div class={["scoria-table-shell", @mobile_summary != [] && "scoria-table-shell--has-summary"]}>
  <div :if={@filter != []} class="scoria-table__filter">
    {render_slot(@filter)}
  </div>
  <div class="scoria-table__viewport" tabindex="0">
    <table class="scoria-table" id={@id} {@rest}>
```

Apply to page and component-group rows with table/list scan paths. Flag `RISK-RESPONSIVE-SCAN` when a page has a table without a mobile summary or proof evidence.

### Browser Hook Boundary

**Source:** `assets/js/scoria.js` lines 1-20, 86-135, 137-152.

```javascript
/*
 * Scoria dashboard client init. Concatenated AFTER phoenix.min.js (global `Phoenix`),
 * phoenix_live_view.min.js (global `LiveView`), and phoenix_html.js by mix scoria.assets.build.
 * No bundler required — the library ships its own self-contained LiveSocket + hooks.
 */
(function () {
  "use strict";
```

```javascript
Hooks.ThemeToggle = {
  mounted: function () {
    themeApply(themeStoredMode());
    this.el.addEventListener("click", function () { themeCycle(); });
  },
};

// Escape closes the topmost open drawer/modal that opts in via data-scoria-dismiss.
Hooks.Dismissable = {
  mounted: function () {
    var self = this;
```

Inventory implication: classify hooks as `hook` rows only when they are named browser interop capabilities (`CopyId`, `ThemeToggle`, `Dismissable`, `CommandPalette`, `MobileNav`, `RecordRecentObject`, raw evidence copy behavior). Do not invent a new JS abstraction in Phase 36.

### Drift Guard / Token Proof Pattern

**Source:** `test/scoria_web/ds06_drift_guard_test.exs` lines 1-22, 32-54, 89-100.

```elixir
defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  DS-06 ratchet drift guard: enforces that raw Tailwind palette class usage
  (stone-*/rose-*/sky-*/...) never increases beyond the committed baseline.
```

```elixir
test "lib/scoria_web/ui.ex has zero raw palette matches" do
  # ui.ex is the enforced token gateway — it must never emit raw palette classes.
  source = File.read!("lib/scoria_web/ui.ex")
  matches = Regex.scan(@palette_regex, source)

  assert matches == [],
```

Apply to `foundation`, `primitive`, and `test` rows. Existing drift guards are evidence, not new work.

### Advisory Screenshot And Browser Proof Boundary

**Source:** `docs/MAINTAINERS.md` lines 337-419; `lib/mix/tasks/scoria.ui.shots.ex` lines 39-52, 81-113, 119-167.

```markdown
The screenshot and LLM-critique harness provides a mechanical proof loop for the v3.0 Control Room milestone. It captures every dashboard screen across its state matrix, runs an optional 9-dimension AI critique, and writes a ranked gap register. It is **dev-only**: excluded from the shipped Hex package and never run in merge-blocking CI (D-01).
```

```elixir
@impl Mix.Task
def run(args) do
  {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("invalid options: #{inspect(invalid)}")
  end
```

```elixir
case System.cmd("node", args, stderr_to_stdout: true, into: IO.stream()) do
  {_, 0} ->
    :ok

  {_, code} ->
    Mix.raise("shots.mjs exited with code #{code}")
end
```

Apply to baseline proof narrative. Phase 36 may cite `mix scoria.ui.shots`, `priv/shots/gap_register.md`, and `priv/shots/gap_register_final.md`; it must not promote screenshots to required CI.

### Playwright Proof Pattern

**Source:** `priv/dev/e2e/phase16_parity.spec.mjs` lines 1-17, 44-84.

```javascript
// Phase 16 browser-truth proof — targeted parity checks for MOTION-01..04.
// ...
// No screenshot comparisons (D-30/D-32). Snapshot/screenshot assertions are intentionally excluded.
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
```

```javascript
test.describe('Phase 16 — MOTION-03: 375px no page-level horizontal overflow', () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test('shell (Home) has no page-level horizontal overflow at 375px', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);
```

Use these as evidence references in inventory rows; do not add new Playwright tests in Phase 36 unless existing proof cannot be cited.

### Maintainer Component Glance Index

**Source:** `docs/MAINTAINERS.md` lines 280-315.

```markdown
| Component | Purpose |
|-----------|---------|
| `badge/1` | Status badge — tone + label, never color-alone |
| `button/1` | Primary / ghost / danger button (brand book §8.5) |
| `icon_button/1` | Icon-only button; `md` for chrome controls, `sm` for inline utilities |
...
| `table/1` | Sortable, paginated operator scan table with canonical compact density (DS-01) |
| `flash_group/1` | Flash notification group (DS-05) |
```

Apply to Markdown inventory summaries, but keep canonical status and IDs in `36-inventory.json`.

## No Analog Found

None for the two expected Phase 36 artifacts. If the planner adds a schema validator script, component lab, PhoenixStorybook, screenshot CI, or runtime source edits, those are outside the identified Phase 36 pattern scope and should be rejected or deferred.

## Metadata

**Analog search scope:** `.planning/`, `.planning/milestones/v3.0-phases/*/*PATTERNS.md`, `.planning/research/`, `lib/scoria_web/`, `assets/css/`, `assets/js/`, `test/scoria_web/`, `priv/dev/e2e/`, `priv/dev/shots.mjs`, `lib/mix/tasks/scoria.ui.shots.ex`, `docs/`, `brandbook/`.

**Files scanned:** Phase context/research/roadmap/requirements plus ~30 planning/source/proof files via `rg`, `find`, `wc`, and targeted line reads.

**Pattern extraction date:** 2026-06-20

**Project instructions:** No root `AGENTS.md` found. No project-local `.codex/skills/` or `.agents/skills/` directories found.
