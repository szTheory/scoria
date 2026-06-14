# Phase 11: Evaluation engine + seed depth - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the **proof loop** that every later v3.0 phase (12–17) re-runs: a committed dev-only
`mix scoria.ui.shots` harness that mechanically captures every dashboard screen across its
state matrix, an LLM critique against the 9-dimension rubric, seed depth so every screen
renders at its most useful, and a baseline audit producing a ranked gap register + fix backlog.

**This phase is tooling + data infrastructure.** It adds `lib/mix/tasks/scoria.ui.shots.ex`,
a `priv/dev/` capture script, and `priv/repo/dev_seed.exs`. It does **not** modify any LiveView
template or add new dashboard screens — the existing 9 screens are the *subjects* of the harness,
not changed by it. Fixing the design system itself is Phases 12–17.

</domain>

<decisions>
## Implementation Decisions

### Browser capture engine
- **D-01:** The harness drives the browser via a **shelled-out Playwright Node script**
  (`System.cmd/3` → checked-in `priv/dev/shots.mjs`), **not** an Elixir browser dependency.
  Rationale: zero Hex footprint (no `mix.exs` change), preserving the package's deliberate
  "no browser automation in merge-blocking CI / clean `mix hex.audit`" posture. Playwright
  natively covers every harness need: `waitForSelector('[data-scoria-ready="true"]')`,
  `setViewportSize`, `evaluate` (theme toggle), `click`, `screenshot`.
- **D-02:** Playwright + browser binaries are a **documented maintainer prerequisite**
  (`npx playwright install chromium`), surfaced in `docs/MAINTAINERS.md` (PROOF-03 ties this off).
  Wallaby was explicitly rejected: it adds a Hex dep visible in `mix.lock`/`hex.audit`, needs
  chromedriver on PATH, and blurs the "no browser automation" contract by using a test-posture
  lib outside `:test`.

### Critique production
- **D-03:** The 9-dimension critique is an **in-harness ReqLLM vision call**, dogfooding Scoria's
  own LLM layer. Confirmed: ReqLLM 1.13 supports `ContentPart.image(binary, "image/png")` for
  Anthropic vision models.
- **D-04:** **Screenshot capture and critique are decoupled.** Screenshots always run
  deterministically; the LLM critique is a **separate gated step** (a `--critique` flag or
  sibling task), run at **phase-milestone boundaries** — not on every local invocation. This
  controls API cost and non-determinism.
- **D-05:** The **canonical critique input is one state per screen** (`populated · desktop · dark`)
  → ~9 vision calls per critique run, keeping the rubric-delta signal across phases 12–17 stable
  and cheap.
- **D-06:** The findings JSON **and** `priv/shots/gap_register.md` are **committed** (per EVAL-03)
  so later-phase audits diff against a stable baseline. Output JSON must match the UI-SPEC's
  per-screen contract (9 keys, each `{score: 1–5, findings: string[]}`).

### Seed data source
- **D-07:** `priv/repo/dev_seed.exs` is a **hybrid**: `Scoria.SupportJourney` is the **spine**
  (reuse its `tenant_id`, `connector_key`, `session_id` identities for Runs / Approvals /
  Connectors so the dashboard tells the same "Acme" domain story as the `support_copilot` gallery).
- **D-08:** Domains SupportJourney does **not** model — eval specs with completed runs, incidents,
  review candidates, prompt release gates, degraded connectors — are added **only in
  `dev_seed.exs`**. No coupling to drift guards: `SupportJourneySourceTest` pins only
  doc-surface fragments, not who calls SupportJourney functions.
- **D-09:** Guard identity drift with a single `# SupportJourney spine — do not inline these values`
  comment block; broken calls surface immediately under `mix test`. Seed must be idempotent
  ("safe to run repeatedly").

### State-matrix navigation
- **D-10:** Overlay states (modal-open / drawer-open) are reached via a **per-screen declarative
  manifest** that names the `phx-click` event + any `phx-value-*` payload; the harness **JS-dispatches**
  it post-load and **re-awaits `data-scoria-ready`**. This matches the codebase's reality:
  overlays are **assigns-driven** (`show_approve_modal`, `runtime_drawer`, `connector_drawer`),
  with **no `live_action`/`push_patch`** overlay pattern.
- **D-11:** Empty vs populated capture uses **dual-tenant navigation** — the harness navigates
  twice per screen with a different `?tenant=` query param (already wired on every screen):
  a seeded tenant for `populated`, an empty tenant for `empty`. **No DB reset** between captures.
- **D-12 [informational]:** Refactoring overlays to `live_action` URL params was **rejected** as pre-phase scope
  creep — it touches 5+ LiveViews and belongs (if ever) in the Phase 12 design-system contract,
  not here.

### Claude's Discretion
- Exact manifest file format (Elixir term vs YAML), screenshot output directory layout beyond
  the UI-SPEC's `priv/shots/{date}/{screen}/{state}.png`, `.gitignore` granularity, sentinel
  poll interval/timeout, and the Node↔Elixir error-propagation protocol are planner/executor calls.
- Model selection for the vision critique and `ANTHROPIC_API_KEY` ergonomics (key-absent
  behavior) are implementation details — default to the latest capable Claude vision model.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase design contract (read first)
- `.planning/phases/11-evaluation-engine-seed-depth/11-UI-SPEC.md` — **The locked output
  contract.** Defines the state matrix (16 effective combos/screen), the 9-dimension rubric
  keys + score semantics, the findings-JSON shape, the `gap_register.md` format, the per-screen
  seed-depth minimums, the 9 in-scope screens + LiveView modules + routes, CLI copywriting,
  and the `flash_group` known-issue note (do NOT fix in Phase 11 — document it in the gap register).

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"Evaluation & Seed Depth" — EVAL-01 … EVAL-05 (the 5 requirements
  this phase closes).
- `.planning/ROADMAP.md` §"Phase 11" — goal + 5 success criteria.

### Code to read/reuse (full paths)
- `lib/scoria/support_journey.ex` + `lib/scoria/support_journey/` — fixture SSOT (seed spine).
- `examples/support_copilot/priv/repo/dev_seed.exs` — existing seed that already uses
  SupportJourney as its spine; the closest analog for `priv/repo/dev_seed.exs`.
- `test/scoria/support_journey_source_test.exs` — the drift guard; confirms it pins doc-surface
  fragments only (does not gate SupportJourney callers).
- `assets/css/02-tokens.css`, `assets/css/04-components.css` — token + component SSOT the rubric
  audits against.
- `assets/js/scoria.js` — `data-scoria-ready` sentinel (set on `phx:page-loading-stop`) and the
  `ThemeToggle` hook the harness toggles.
- `lib/scoria_web/ui.ex` — `empty_state/1` (renders empty captures), `tone/1`, and the
  `flash_tone_class/1` raw-palette known issue (~line 195/195) the baseline audit must rank.
- `lib/mix/tasks/scoria.eval.ex` and the existing `lib/mix/tasks/scoria.*.ex` family — Mix-task
  idioms/conventions to mirror for `scoria.ui.shots`.

### Dependency facts (verified during discussion)
- `mix.exs` — `req ~> 0.5`, `req_llm ~> 1.13` present; **no** browser-automation dep exists.
- No `priv/repo/dev_seed.exs` exists yet — it is net-new.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Scoria.SupportJourney`**: seed spine — reuse `tenant_id`/`connector_key`/`session_id` for
  Runs/Approvals/Connectors rather than minting new identities.
- **`examples/support_copilot/priv/repo/dev_seed.exs`**: a working SupportJourney-spined seed —
  the structural template for the new dashboard seed.
- **`ReqLLM` (1.13)**: the product's own LLM layer, with `ContentPart.image/2` vision support —
  the critique vehicle (dogfooding).
- **`data-scoria-ready` sentinel + `ThemeToggle` hook** (`assets/js/scoria.js`): the harness's
  capture gate and theme-switching mechanism, already in place.
- **`ScoriaWeb.UI.empty_state/1`**: renders the `empty` matrix captures with the copy the UI-SPEC
  specifies.

### Established Patterns
- **Overlays are assigns-driven** (`show_approve_modal`, `runtime_drawer`, `connector_drawer`),
  toggled by `handle_event`, **not** URL/`live_action` — the harness must JS-dispatch `phx-click`
  events to open them, and drawers that show a record need a seeded record ID in the payload.
- **`tenant_id` flows via `params["tenant"]`** on every screen — empty/populated is a query-param
  switch, no DB reset.
- **Mix-task family** under `lib/mix/tasks/scoria.*.ex` — follow its naming + structure.
- **Hex-package hygiene**: the repo guards against browser automation / heavy deps leaking into
  the shipped package and CI — keep capture tooling dev-only with zero `mix.exs` impact.

### Integration Points
- `lib/mix/tasks/scoria.ui.shots.ex` (new) → `System.cmd` → `priv/dev/shots.mjs` (new Playwright
  script) → local `mix phx.server`.
- New `priv/repo/dev_seed.exs` → `Scoria.SupportJourney` + Scoria contexts (Reviews, Incidents,
  Eval, Prompts, Connectors, Workflows).
- Critique step → `ReqLLM` → Anthropic vision → findings JSON → `priv/shots/gap_register.md`.

</code_context>

<specifics>
## Specific Ideas

- Canonical critique state = `populated · desktop · dark`, ~9 calls per critique run.
- Maintainer prerequisite line for MAINTAINERS.md: `npm install -g playwright` (or `npx`) +
  `npx playwright install chromium`.
- `priv/shots/` is `.gitignore`d **except** `gap_register.md` and example contact sheets
  (per UI-SPEC implementation notes).

</specifics>

<deferred>
## Deferred Ideas

- **Migrate overlays to `live_action` URL params** — attractive for a fully stateless capture
  matrix, but it touches 5+ LiveViews. If pursued, it belongs in the **Phase 12** design-system
  contract, not Phase 11.
- **Critiquing more than the canonical state per screen** (full 16-combo LLM critique) — possible
  later if per-state findings prove necessary; deferred to keep cost/determinism controlled.
- **Consolidating `--scoria-space-3` (12px), `--scoria-space-9` (96px), `--scoria-fs-badge` (11px)**
  — flagged by the UI-SPEC as DS gap-register *candidates*; they are audit findings here, changed
  (if at all) in later DS phases.

</deferred>

---

*Phase: 11-evaluation-engine-seed-depth*
*Context gathered: 2026-06-04*
