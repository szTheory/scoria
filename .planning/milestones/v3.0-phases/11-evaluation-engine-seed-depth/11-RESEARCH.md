# Phase 11: Evaluation Engine + Seed Depth — Research

**Researched:** 2026-06-04
**Domain:** Mix task authoring, Playwright Node scripting, ReqLLM vision API, Ecto seed patterns, Hex package hygiene
**Confidence:** HIGH (all findings verified directly from codebase or installed deps)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Harness drives browser via shelled-out Playwright Node script (`System.cmd/3` → checked-in `priv/dev/shots.mjs`), not an Elixir browser dep. Zero Hex footprint, zero `mix.exs` change.
- **D-02:** Playwright + browser binaries are a documented maintainer prerequisite (`npx playwright install chromium`), surfaced in `docs/MAINTAINERS.md`. Wallaby explicitly rejected.
- **D-03:** 9-dimension critique is an in-harness ReqLLM vision call, dogfooding Scoria's own LLM layer. ReqLLM 1.13 `ContentPart.image(binary, "image/png")` confirmed in codebase.
- **D-04:** Screenshot capture and critique are decoupled — screenshots always run deterministically; critique is a separate `--critique` flag, run at phase-milestone boundaries only.
- **D-05:** Canonical critique input = one state per screen (`populated · desktop · dark`), ~9 vision calls per critique run.
- **D-06:** Findings JSON and `priv/shots/gap_register.md` are committed (per EVAL-03). JSON must match UI-SPEC per-screen contract (9 keys, each `{score: 1–5, findings: string[]}`).
- **D-07:** `priv/repo/dev_seed.exs` is hybrid: `Scoria.SupportJourney` is the spine (reuse `tenant_id="acme-corp"`, `connector_key="billing"`, `session_id="support-session-42"`).
- **D-08:** Domains SupportJourney doesn't model (eval specs, incidents, review candidates, prompt release gates, degraded connectors) are added only in `dev_seed.exs`. No coupling to drift guards.
- **D-09:** Guard identity drift with `# SupportJourney spine — do not inline these values` comment block. Seed must be idempotent.
- **D-10:** Overlay states reached via per-screen declarative manifest naming `phx-click` event + `phx-value-*` payload; harness JS-dispatches it post-load and re-awaits `data-scoria-ready`.
- **D-11:** Empty vs populated capture uses dual-tenant navigation (`?tenant=` query param, already wired on every screen). No DB reset between captures.
- **D-12:** Refactoring overlays to `live_action` URL params rejected as pre-phase scope creep.

### Claude's Discretion

- Exact manifest file format (Elixir term vs YAML), screenshot output directory layout beyond `priv/shots/{date}/{screen}/{state}.png`, `.gitignore` granularity, sentinel poll interval/timeout, Node↔Elixir error-propagation protocol.
- Model selection for vision critique and `ANTHROPIC_API_KEY` ergonomics (key-absent behavior) — default to latest capable Claude vision model.

### Deferred Ideas (OUT OF SCOPE)

- Migrate overlays to `live_action` URL params.
- Critiquing more than the canonical state per screen (full 16-combo LLM critique).
- Consolidating `--scoria-space-3` (12px), `--scoria-space-9` (96px), `--scoria-fs-badge` (11px) — audit findings, not Phase 11 changes.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EVAL-01 | Mix task `mix scoria.ui.shots` captures every dashboard screen across state matrix (empty/populated/modal-open/drawer-open × light/dark × mobile/desktop), gated on `data-scoria-ready` | Sentinel confirmed in `assets/js/scoria.js:84`. Overlay events mapped per-screen. Dual-tenant wiring confirmed on all mounts. |
| EVAL-02 | Captured screenshots can be critiqued against 9-dimension rubric to produce structured per-screen findings | `ContentPart.image/2` API verified in `deps/req_llm/lib/req_llm/message/content_part.ex:66`. `ReqLLM.Generation.generate_text/3` call signature confirmed. |
| EVAL-03 | Harness ships as committed dev-only tooling (not merge-blocking CI) with documented usage | `package.files` in `mix.exs` excludes `priv/dev/`; no `priv/shots/` entry; `.gitignore` currently lacks `priv/shots/` — must add. |
| EVAL-04 | `dev_seed.exs` populates every dashboard screen so each renders at its most useful | Seed depth contract mapped screen-by-screen using real schema introspection (see Seed Depth section). |
| EVAL-05 | Baseline audit produces ranked design-system gap register and prioritized fix backlog | Gap register format locked in UI-SPEC. Known issue: `flash_tone_class/1` at `lib/scoria_web/ui.ex:195` uses raw palette — must surface as ranked finding. |
</phase_requirements>

---

## Summary

Phase 11 builds the proof loop that all later v3.0 phases (12–17) re-run. It is pure **tooling + data infrastructure** — no LiveView template changes, no new screens. The deliverables are: (1) `lib/mix/tasks/scoria.ui.shots.ex` — a dev-only Mix task that shells out to a Playwright Node script; (2) `priv/dev/shots.mjs` — the checked-in Playwright capture script; (3) `priv/repo/dev_seed.exs` — an idempotent seed that makes every screen render its richest populated state; and (4) a committed baseline audit (`priv/shots/gap_register.md`) driven by ReqLLM vision critiques.

All major technical decisions are locked in CONTEXT.md (D-01 through D-12). Research confirms every locked decision is consistent with the codebase. Key findings: the `data-scoria-ready` sentinel is set unconditionally on `phx:page-loading-stop` in `assets/js/scoria.js:84`; `tenant_id` flows via `params["tenant"]` on every LiveView mount; overlays are assigns-driven (`show_approve_modal`, `runtime_drawer`, `connector_drawer`) and reached via `handle_event`, not URL params; ReqLLM `ContentPart.image(binary, "image/png")` is the verified vision API; and the `flash_tone_class/1` raw-palette known issue lives at `lib/scoria_web/ui.ex:195`.

**Primary recommendation:** Implement in wave order: seed first (so captures are meaningful), then harness (capture script + Mix task), then baseline critique run and gap register commit.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Screenshot capture | Dev tooling (Node/Playwright) | Mix task (Elixir shell-out) | Browser automation belongs in the Node layer; Mix task is the Elixir entry point only |
| LLM vision critique | Mix task (Elixir/ReqLLM) | — | Critique is pure Elixir using the existing ReqLLM dep, no Node involved |
| Seed data | Ecto / Scoria contexts | SupportJourney SSOT | Data lives in Postgres; seed calls real context functions |
| Gap register output | Mix task (Elixir file write) | — | Markdown file written by the Elixir critique step |
| State matrix navigation | Node/Playwright script | Per-screen manifest | Playwright owns viewport, theme-toggle JS eval, and overlay event dispatch |
| Tenant isolation | LiveView (params["tenant"]) | — | All screens already wire tenant_id from the query param |

---

## Standard Stack

### Core (all already in mix.exs — zero new Hex deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `req_llm` | `~> 1.13` (locked) | Vision critique via `ContentPart.image/2` | Already in `deps`; confirmed `1.13` in `mix.exs:91` |
| `jason` | `~> 1.4` (locked) | Findings JSON encode/decode | Already in `deps`; used throughout codebase |
| `mix` (stdlib) | Elixir stdlib | Mix task scaffold (`use Mix.Task`) | Matches existing `lib/mix/tasks/scoria.*.ex` family |

[VERIFIED: codebase `mix.exs`]

### External Tooling (documented prerequisites, NOT mix.exs deps)

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| Node.js | v22.14.0 (on this machine) | Runtime for `shots.mjs` | System prerequisite |
| Playwright | 1.60.0 (on this machine via npx) | Browser automation, screenshot capture | `npm install -g playwright` or `npx playwright` |
| Chromium | bundled with Playwright | Headless browser for captures | `npx playwright install chromium` |

[VERIFIED: `command -v node`, `npx playwright --version` → 1.60.0 on this machine]

### Package Legitimacy Audit

> This phase installs **zero new Hex packages**. Playwright is a documented maintainer prerequisite (not a `mix.exs` dep). No slopcheck audit needed for Hex. Node is a system runtime, not a package install.

| Package | Registry | Disposition |
|---------|----------|-------------|
| `req_llm ~> 1.13` | Hex (already installed) | Approved — already in lockfile |
| `jason ~> 1.4` | Hex (already installed) | Approved — already in lockfile |
| Playwright | npm (system prereq, not installed by mix) | Approved — documented prerequisite per D-02 |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
mix scoria.ui.shots [--critique] [--tenant-empty X] [--tenant-seeded Y]
       |
       v
  Mix.Tasks.Scoria.UiShots  (lib/mix/tasks/scoria.ui.shots.ex)
       |
       +--[screenshot pass]-----> System.cmd("node", ["priv/dev/shots.mjs", ...args])
       |                                   |
       |                          priv/dev/shots.mjs (Playwright)
       |                                   |
       |                          Local dev server (mix phx.server)
       |                                   |
       |                    [per screen × state matrix]
       |                         await data-scoria-ready
       |                         set viewport (1280 or 375)
       |                         set theme (dark or light)
       |                         dispatch overlay event (if overlay state)
       |                         await data-scoria-ready again
       |                         page.screenshot() -> priv/shots/{date}/{screen}/{state}.png
       |
       +--[critique pass, --critique only]
                  |
                  +-> Read PNG binaries from priv/shots/{date}/
                  +-> ReqLLM.Generation.generate_text("anthropic:claude-...", messages)
                      messages: [system(rubric_prompt), user([ContentPart.image(png_binary, "image/png")])]
                  +-> Parse JSON response -> per-screen findings map
                  +-> Write priv/shots/{date}/{screen}/{state}.json
                  +-> Render priv/shots/gap_register.md (committed)
```

### Recommended Project Structure (new files only)

```
lib/mix/tasks/
└── scoria.ui.shots.ex       # Mix task entry point

priv/dev/
└── shots.mjs                # Playwright capture script (checked in)

priv/repo/
└── dev_seed.exs             # Dashboard seed (net-new, idempotent)

priv/shots/
├── .gitignore               # tracks gap_register.md + example sheets; ignores *.png + *.json
├── gap_register.md          # COMMITTED — baseline audit output
└── 2026-06-04/              # GITIGNORED — date-stamped capture directories
    ├── live_ops/
    │   ├── empty_dark_desktop.png
    │   ├── empty_dark_mobile.png
    │   ├── empty_light_desktop.png
    │   ├── empty_light_mobile.png
    │   ├── populated_dark_desktop.png
    │   ├── populated_dark_desktop.json   # critique output (canonical state)
    │   ├── populated_dark_mobile.png
    │   ├── populated_light_desktop.png
    │   ├── populated_light_mobile.png
    │   ├── modal_dark_desktop.png
    │   ├── modal_dark_mobile.png
    │   └── ...
    └── approvals/
        └── ...
```

### Pattern 1: Mix Task Structure (mirrors existing family)

**What:** `use Mix.Task` with `OptionParser`, `Mix.shell().info/1` for output, `Mix.raise/1` for errors.
**When to use:** All new Mix tasks in this project.

```elixir
# Source: lib/mix/tasks/scoria.warning_inventory.ex + scoria.eval.ex
defmodule Mix.Tasks.Scoria.Ui.Shots do
  @shortdoc "Captures dashboard screenshots across the state matrix"
  @moduledoc """
  ...
  """
  use Mix.Task

  @switches [
    critique: :boolean,
    tenant_empty: :string,
    tenant_seeded: :string,
    url: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    # NOTE: do NOT call Mix.Task.run("app.start") — this task
    # does not need the Elixir app running; it shells out to Node.
    # Critique step does need app (for ReqLLM), so start lazily there.
    ...
  end
end
```

[VERIFIED: codebase `lib/mix/tasks/scoria.eval.ex`, `lib/mix/tasks/scoria.warning_inventory.ex`]

### Pattern 2: System.cmd Shell-Out to Node

**What:** `System.cmd/3` with `stderr_to_stdout: true`, checking exit code.
**When to use:** The screenshot pass — shells out to `priv/dev/shots.mjs`.

**Recommended arg-passing protocol:** Pass configuration as CLI flags (not stdin JSON or temp files). Flags are simple, inspectable, and avoid race conditions with stdin buffering. The manifest itself (screen list + overlay events) is hardcoded into `shots.mjs` — it doesn't change per invocation, only the tenant IDs and base URL vary.

```elixir
# Source: lib/mix/tasks/scoria.warning_inventory.ex (uses System.cmd for git)
defp run_playwright(opts) do
  node_script = Path.join([File.cwd!(), "priv", "dev", "shots.mjs"])
  base_url = Keyword.get(opts, :url, "http://localhost:4000/scoria")
  tenant_empty = Keyword.get(opts, :tenant_empty, "empty-tenant")
  tenant_seeded = Keyword.get(opts, :tenant_seeded, "acme-corp")
  out_dir = Path.join([File.cwd!(), "priv", "shots", Date.to_iso8601(Date.utc_today())])

  args = [
    node_script,
    "--base-url", base_url,
    "--tenant-empty", tenant_empty,
    "--tenant-seeded", tenant_seeded,
    "--out-dir", out_dir
  ]

  case System.cmd("node", args, stderr_to_stdout: true, into: IO.stream()) do
    {_, 0} -> :ok
    {_, code} -> Mix.raise("shots.mjs exited with code #{code}")
  end
end
```

**Missing Playwright/chromium detection:** `shots.mjs` should check `playwright.chromium.launch()` and emit the maintainer-facing error on failure:

```javascript
// In priv/dev/shots.mjs — startup check
import { chromium } from 'playwright';
let browser;
try {
  browser = await chromium.launch();
} catch (e) {
  console.error(
    'Error: Playwright/Chromium not installed.\n' +
    'Run: npm install -g playwright && npx playwright install chromium'
  );
  process.exit(1);
}
```

[ASSUMED: System.cmd error-propagation approach is Claude's discretion per CONTEXT.md]

### Pattern 3: Playwright State Matrix Navigation

**What:** Per-screen declarative manifest hardcoded in `shots.mjs` — no external file needed.
**When to use:** Each screen has a manifest entry listing its overlay events (if any).

```javascript
// Source: confirmed from reading ApprovalsLive, ConnectorsLive, PromptLive.ReleaseWorkbenchLive
const SCREENS = [
  {
    name: "live_ops",
    path: "/",
    overlays: []  // no overlay in OrchestratorLive (approval modal is driven by select_approval event needing a real approval ID)
  },
  {
    name: "approvals",
    path: "/approvals",
    overlays: [
      // approval modal opens via select_approval event with a real approval ID
      // seeded tenant must have pending approval; ID pulled from DOM data attribute
      { state: "modal", event: "select_approval", valueAttr: "data-approval-id" }
    ]
  },
  {
    name: "connectors",
    path: "/connectors",
    overlays: [
      { state: "connector_drawer", event: "open_connector_drawer", valueAttr: "data-connector-id" },
      { state: "runtime_drawer", event: "open_runtime_drawer", valueAttr: "data-runtime-id" }
    ]
  },
  {
    name: "prompt_release",
    path: "/prompts",  // navigate to list first, then follow link to /prompts/:id/release
    overlays: [
      { state: "approve_modal", event: "open_approve", value: null }
    ]
  }
  // ... etc
];
```

**Sentinel polling:**

```javascript
// Source: assets/js/scoria.js:84 — confirmed sentinel is set on phx:page-loading-stop
async function waitForReady(page, timeoutMs = 5000) {
  try {
    await page.waitForFunction(
      () => document.documentElement.getAttribute('data-scoria-ready') === 'true',
      { timeout: timeoutMs }
    );
  } catch {
    throw new Error(
      `Error: data-scoria-ready not set on <html> after ${timeoutMs}ms. Is the dev server running?`
    );
  }
}
```

**Theme toggle:**

```javascript
// Source: assets/js/scoria.js:48 — ThemeToggle hook sets data-theme on documentElement
// Harness sets it directly (no need to click the button)
await page.evaluate((theme) => {
  document.documentElement.setAttribute('data-theme', theme);
}, 'light');
await waitForReady(page); // re-gate in case theme change triggers a reload
```

[VERIFIED: `assets/js/scoria.js` lines 84 (sentinel) and 48 (ThemeToggle)]

### Pattern 4: ReqLLM Vision Call

**What:** Pass PNG binary as `ContentPart.image(binary, "image/png")` in a user message alongside the rubric prompt.
**When to use:** Critique pass only (`--critique` flag), `populated · desktop · dark` state per screen.

```elixir
# Source: deps/req_llm/lib/req_llm/message/content_part.ex:66
# Source: deps/req_llm/lib/req_llm/context.ex (user/2 with content parts list)
alias ReqLLM.Message.ContentPart
alias ReqLLM.Context

def critique_screen(png_path, screen_name, rubric_prompt) do
  binary = File.read!(png_path)
  image_part = ContentPart.image(binary, "image/png")
  text_part = ContentPart.text(rubric_prompt)

  messages = [
    Context.system(system_instruction()),
    Context.user([text_part, image_part])
  ]

  # Key-absent behavior: ReqLLM reads ANTHROPIC_API_KEY from env via dotenvy.
  # If absent, generate_text returns {:error, ...}. Wrap with graceful message.
  case ReqLLM.Generation.generate_text(
    "anthropic:claude-opus-4-5",   # or claude-sonnet-4-5 — Claude's discretion
    messages,
    max_tokens: 2048
  ) do
    {:ok, response} ->
      text = ReqLLM.Response.text(response)
      parse_findings_json(text, screen_name)

    {:error, reason} ->
      if is_nil(System.get_env("ANTHROPIC_API_KEY")) do
        Mix.raise("ANTHROPIC_API_KEY is not set. Set it to run the critique pass.")
      else
        Mix.raise("Critique failed for #{screen_name}: #{inspect(reason)}")
      end
  end
end
```

**Findings JSON shape (from UI-SPEC):**

```elixir
# Each screen produces a map with exactly these 9 keys:
%{
  "brand_fit"   => %{"score" => 3, "findings" => ["..."]},
  "consistency" => %{"score" => 2, "findings" => ["flash_tone_class uses raw palette"]},
  "hierarchy"   => %{"score" => 4, "findings" => []},
  "affordance"  => %{"score" => 3, "findings" => ["..."]},
  "a11y"        => %{"score" => 3, "findings" => ["..."]},
  "responsive"  => %{"score" => 4, "findings" => []},
  "motion"      => %{"score" => 3, "findings" => ["..."]},
  "microcopy"   => %{"score" => 3, "findings" => ["..."]},
  "density"     => %{"score" => 3, "findings" => ["..."]}
}
```

**System instruction (rubric prompt anchor):**

```
You are a design-system auditor for the Scoria operator dashboard.
Score the provided screenshot on these 9 dimensions.
Return ONLY a JSON object with keys:
brand_fit, consistency, hierarchy, affordance, a11y, responsive, motion, microcopy, density.
Each key maps to {"score": 1-5, "findings": ["...string array of specific observations"]}.
Score 1=critical violation, 2=significant gap, 3=acceptable, 4=good, 5=excellent.
```

[VERIFIED: ContentPart.image/2 in `deps/req_llm/lib/req_llm/message/content_part.ex:66`]
[VERIFIED: Context.user/2 with content parts list in `deps/req_llm/lib/req_llm/context.ex:239`]
[VERIFIED: ReqLLM.Generation.generate_text/3 in `deps/req_llm/lib/req_llm/generation.ex:73`]
[VERIFIED: ANTHROPIC_API_KEY loaded via dotenvy per `deps/req_llm/lib/req_llm.ex:55`]

### Pattern 5: Idempotent Seed

**What:** `dev_seed.exs` uses `Repo.get_by/2` + `if is_nil(...)` guards or `Repo.insert/2` with `on_conflict: :nothing` to be safe to re-run.
**When to use:** Every record insertion in the seed.

```elixir
# Source: examples/support_copilot/priv/repo/dev_seed.exs — existing pattern
# SupportJourney spine — do not inline these values
alias Scoria.SupportJourney
tenant_id = SupportJourney.tenant_id()      # "acme-corp"
session_id = SupportJourney.session_id()    # "support-session-42"
connector_key = SupportJourney.connector_key()  # "billing"

# Idempotency pattern for entities without natural unique keys:
# Use dedupe_key or check count before inserting
existing = Repo.get_by(Scoria.SRE.Incident, dedupe_key: "seed-incident-1")
incident =
  if is_nil(existing) do
    {:ok, i} = Scoria.SRE.IncidentManager.open_incident(%{
      tenant_id: tenant_id,
      incident_key: "quality-regression-001",
      dedupe_key: "seed-incident-1",
      severity: "warning",
      summary: "Quality regression on support-agent refund lane",
      routing_class: "review",
      ...
    })
    i
  else
    existing
  end
```

[VERIFIED: `examples/support_copilot/priv/repo/dev_seed.exs` structure + `Scoria.SRE.Incident` schema]

### Anti-Patterns to Avoid

- **App startup in screenshot task:** Do NOT call `Mix.Task.run("app.start")` in `scoria.ui.shots` for the screenshot pass — Node/Playwright does not need the Elixir app running. Only start the app for the critique pass (to use ReqLLM).
- **Hardcoding tenant IDs in seed:** Use `SupportJourney.tenant_id()` — never `"acme-corp"` as a literal. The comment guard `# SupportJourney spine — do not inline these values` makes this policy visible.
- **`page.click()` for overlay open:** Use `page.dispatchEvent('phx-click')` or `page.evaluate()` to trigger LiveView events, not DOM clicks on elements that may not be visible in the initial viewport.
- **DB reset between captures:** D-11 locks dual-tenant navigation. No DB reset. Empty tenant (`"empty-tenant"`) has no data; seeded tenant (`"acme-corp"`) has seed data.
- **Blocking on sentinel before page.goto completes:** Call `waitForReady` after `page.goto` returns, not during navigation. The sentinel is cleared on each navigation and reset on `phx:page-loading-stop`.
- **Writing `priv/shots/` to `package.files`:** The `shots.mjs` lives in `priv/dev/` which is NOT in `mix.exs:package.files` — confirm it stays excluded. Screenshots must also be excluded.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Screenshot capture | Custom HTTP client + HTML-to-image | Playwright `page.screenshot()` | Playwright handles LiveView hydration, JS hook execution, CSS rendering |
| Sentinel waiting | Manual `setTimeout` polling loop | `page.waitForFunction(...)` | Playwright's waitForFunction has proper timeout, retry, and error semantics |
| Vision API integration | Raw HTTP to Anthropic API | `ReqLLM.Generation.generate_text/3` with `ContentPart.image/2` | Already in deps; handles auth, retries, telemetry |
| JSON schema validation of critique output | Custom validator | Elixir pattern-match + `Jason.decode!/1` | 9-key shape is simple enough for pattern matching; don't add a validation dep |
| Seed idempotency | Truncating/resetting DB | `Repo.get_by` + conditional insert | DB reset breaks the dual-tenant capture; conditional insert is safe |

**Key insight:** Playwright natively covers every harness need. Any attempt to replicate its wait mechanics in Elixir would require a browser dep that contradicts D-01.

---

## Overlay Capture: Per-Screen Event Inventory

This answers research question #3 (D-10 implementation detail).

| Screen | Overlay State | LiveView Event | phx-value-* | Needs Seeded Record ID? |
|--------|--------------|----------------|-------------|------------------------|
| Approvals (`/approvals`) | `modal` (approval detail) | `select_approval` | `id: <approval.id>` | YES — read first `approval_inbox` row ID from DOM |
| Connectors (`/connectors`) | `connector_drawer` | `open_connector_drawer` | `id: <connector_id>` | YES — read first connector row's `data-connector-id` from DOM |
| Connectors (`/connectors`) | `runtime_drawer` | `open_runtime_drawer` | `id: <runtime_id>` | YES — read first runtime row's `data-runtime-id` from DOM |
| Prompt Release Workbench (`/prompts/:id/release`) | `approve_modal` | `open_approve` | none | NO — modal has no payload |
| Prompt Release Workbench | `reject_modal` | `open_reject` | none | NO |
| Live Ops (`/`) | none | — | — | — |
| Incidents (`/incidents`) | none (inline selection, not overlay) | — | — | — |
| Review Queue (`/reviews`) | none (inline selection, not overlay) | — | — | — |
| Eval Workbench (`/eval_specs`) | none (inline edit form, not overlay) | — | — | — |
| Runs/Workflows (`/workflows`) | none (navigation to show view) | — | — | — |

[VERIFIED: `ApprovalsLive.Index` — modal driven by `show_approve_modal` assign, opened via `select_approval` event with `%{"id" => approval_id}`]
[VERIFIED: `ConnectorsLive.Index` — drawers driven by `runtime_drawer`/`connector_drawer` assigns, events `open_runtime_drawer`/`open_connector_drawer` with `%{"id" => id}`]
[VERIFIED: `PromptLive.ReleaseWorkbenchLive` — `show_approve_modal` assign, `open_approve` event with no payload]

**DOM ID extraction approach for Playwright:** For overlays that need a real record ID, the harness should read the first data attribute from the rendered list before dispatching the event:

```javascript
// Example: Approvals modal
const firstApproval = await page.$('[data-approval-id]');
const approvalId = await firstApproval?.getAttribute('data-approval-id');
if (approvalId) {
  await page.evaluate(
    (id) => window.scoriaLiveSocket.execJS(
      document.querySelector('[phx-click="select_approval"]'),
      `[["push",{"event":"select_approval","value":{"id":"${id}"}}]]`
    ),
    approvalId
  );
  await waitForReady(page);
}
```

[ASSUMED: Exact Playwright LiveView event dispatch approach is Claude's discretion. The simpler `page.click()` on a rendered list row is the most idiomatic Playwright approach when the element is visible.]

**Simpler alternative:** Instead of synthesizing LiveView events, click the first visible row button for overlays that open on row click. For Approvals, click the first `button[phx-click="select_approval"]`. This is idiomatic Playwright and avoids DOM introspection complexity.

---

## Dual-Tenant Navigation: Confirmed Wiring

This answers research question #4 (D-11 implementation detail).

| Screen | Mount reads tenant from | Empty tenant value | Seeded tenant value |
|--------|------------------------|-------------------|-------------------|
| Live Ops (`OrchestratorLive`) | `params["tenant"] \|\| session["tenant_id"] \|\| "default"` | `"empty-tenant"` | `"acme-corp"` |
| Approvals (`ApprovalsLive.Index`) | `params["tenant"] \|\| session["tenant_id"] \|\| "default"` | `"empty-tenant"` | `"acme-corp"` |
| Connectors (`ConnectorsLive.Index`) | `params["tenant"] \|\| session["tenant_id"] \|\| "default"` | `"empty-tenant"` | `"acme-corp"` |
| Incidents (`IncidentsLive.Index`) | `params["tenant"] \|\| session["tenant_id"] \|\| "default"` (cast: `is_map(params) && params["tenant"]`) | `"empty-tenant"` | `"acme-corp"` |
| Review Queue (`ReviewQueueLive`) | Does NOT read `params["tenant"]` — uses global query filters | N/A | N/A |
| Eval Workbench (`EvalSpecLive.Index`) | Does NOT read `params["tenant"]` — lists all eval specs | N/A | N/A |
| Prompt Registry (`PromptLive.Index`) | Does NOT read `params["tenant"]` — lists all templates | N/A | N/A |
| Workflow Index (`WorkflowLive.Index`) | Does NOT read `params["tenant"]` — lists all runs (global) | N/A | N/A |

[VERIFIED: Reading `mount/3` of each LiveView module]

**Important finding:** Review Queue, Eval Workbench, Prompt Registry, and Workflow Index do not support `?tenant=` switching. For these screens, "empty" state is achieved by running the harness against a freshly migrated DB (before seeding), OR by making the seed idempotent and the harness capturing them pre-seed. The simpler approach: capture the empty state **before** running the seed for those four screens, or use a separate empty DB. 

**Recommended resolution (Claude's discretion):** Since the seed is idempotent and the harness runs against a running dev server, capture empty states for these four screens with `?tenant=` not helping — instead, the harness should detect empty DB state at script start and warn. OR: seed creates data under a specific `tenant_id` that these global-list screens show everything regardless, making "empty" vs "populated" a before/after seed distinction rather than a tenant distinction for these screens.

**Practical approach:** Have `dev_seed.exs` create data that shows on the non-tenant-scoped screens (they list globally). Before seeding, those screens are naturally empty. After seeding, they show data. The harness can capture both states by: (1) running with a fresh DB for empty captures, OR (2) accepting that "empty" for these four global-list screens means "empty DB" — which is a one-time capture at baseline setup, not per-run.

---

## Seed Depth: Screen-by-Screen Data Map

This answers research question #5 (D-08 detail). All schema fields verified from source.

### Seed spine identities (from `Scoria.SupportJourney`)
```elixir
# SupportJourney spine — do not inline these values
tenant_id    = "acme-corp"          # SupportJourney.tenant_id()
session_id   = "support-session-42" # SupportJourney.session_id()
connector_key = "billing"           # SupportJourney.connector_key()
```

### Screen → Required Seed Data

**Live Ops (`ScoriaWeb.OrchestratorLive`, `/`)**
- Needs: runs in `scoria:runs:acme-corp` PubSub namespace, trace stream hydration
- Seed via: `Scoria.start_run/2` with `tenant_id: "acme-corp"` (already in example seed — reuse)
- Minimum: ≥4 runs in various statuses (completed, running, failed, pending_approval)

**Approvals (`ScoriaWeb.ApprovalsLive.Index`, `/approvals`)**
- Needs: `Workflows.list_pending_remote_approvals(%{tenant_id: "acme-corp"})` returns ≥1 row
- Seed via: `Scoria.start_run/2` with an approval step, then do NOT approve it (leave pending)
- Already in example seed: run #2 creates a pending approval approval
- **Overlay requirement:** The `active_approval` assign is set by clicking a row via `select_approval`. The seeded pending approval must have a real UUID for `phx-value-id`.

**Runs / Workflows (`ScoriaWeb.WorkflowLive.Index`, `/workflows`)**
- Needs: `Repo.all(from r in Run, ...)` returns ≥4 rows
- Seed via: `Scoria.start_run/2` × 4 with different statuses. Example seed already creates 3+ runs.
- Add one `in_progress` run (start run, don't complete it).

**Incidents (`ScoriaWeb.IncidentsLive.Index`, `/incidents`)**
- Needs: `OperatorSurface.list_tenant_incidents("acme-corp")` returns ≥2 incidents
- Seed via: `Scoria.SRE.IncidentManager.open_incident/1` with `tenant_id: "acme-corp"`
- Schema required fields: `tenant_id`, `incident_key`, `severity`, `status`, `summary`, `routing_class`, `dedupe_key`, `first_seen_at`, `last_seen_at`
- Minimum: 2 incidents — one `"warning"` severity + `"open"`, one `"critical"` + `"resolved"`
- Link one to a seeded workflow run via `workflow_run_id`

**Connectors (`ScoriaWeb.ConnectorsLive.Index`, `/connectors`)**
- Needs: `OperatorSurface.connector_fleet("acme-corp")` returns ≥2 connectors with mix of health states
- Seed via: Create `Scoria.Connectors.Connector` records (or use `ensure_billing_connector!` from example seed)
- Connector with `health_state: "degraded"` required per D-08
- **Drawer requirement:** `open_connector_drawer` needs a real `connector_id` from the seeded fleet

**Review Queue (`ScoriaWeb.ReviewQueueLive`, `/reviews`)**
- Needs: `Eval.list_review_queue/1` returns ≥3 `OnlineScoreCandidate` rows
- Schema: `tenant_id`, `dedupe_key`, `status` (from `@statuses`), `review_status` (from `@review_statuses`), `score`, `scorer_kind`, etc.
- Seed via: Direct `Repo.insert/2` on `%OnlineScoreCandidate{}` — no high-level API for synthetic seed data
- Mix of statuses: `"needs_review"`, `"promotion_candidate"`, one with `"approval_requested"`
- Mix of `review_status`: `"pending"`, `"in_review"`, `"approved"`
- At least one with `trace_id` and `workflow_run_id` pointing to a seeded run

**Eval Workbench (`ScoriaWeb.EvalSpecLive.Index`, `/eval_specs`)**
- Needs: `Eval.list_eval_specs()` returns ≥2 EvalSpec rows (must be `is_current: true`)
- Seed via: `Eval.create_eval_spec/1`
- Required attrs: `name`, `description`, `dataset_id`, `dataset_version`, `eval_mode` (`:live_judge` or `:offline_replay`), `subject`, `scorers`, `threshold_policy`
- `dataset_id` must reference a real `Dataset` record — create dataset first
- Need ≥1 with a completed eval run (create via `Eval.create_eval_run/1` + `Eval.complete_eval_run/2`)

**Prompt Registry (`ScoriaWeb.PromptLive.Index`, `/prompts`)**
- Needs: `PromptRegistry.list_prompt_templates()` returns ≥2 rows
- Seed via: `PromptRegistry.create_draft_template/1`
- Required attrs: `entity_id` (UUID), `version`, `is_current`, `status`, `system_message`, `user_template`
- Need ≥1 with status `"active"` (promote a draft), ≥1 still `"draft"`

**Prompt Release Workbench (`ScoriaWeb.PromptLive.ReleaseWorkbenchLive`, `/prompts/:id/release`)**
- Needs: A navigable seeded draft template with a pending approval
- Seed via: After creating a draft prompt template, call `PromptRelease.start_release_workflow(draft_id, actor_id)`
- The harness navigates to `/prompts/<seeded_draft_id>/release`
- **Modal requirement:** `show_approve_modal` is toggled by `open_approve` event with no payload

---

## Hex-Package Hygiene Analysis

This answers research question #6.

### `package.files` in `mix.exs` (current state)

```elixir
# lib/mix/tasks/ — INCLUDED (lib/ is in package.files)
# priv/ — INCLUDED as a glob — this is the concern

files: [
  "lib",
  "priv",          # <- entire priv/ is shipped
  "mix.exs",
  ...
]
```

**Finding:** `priv/` is included as a bare directory glob, which means `priv/dev/shots.mjs` and `priv/shots/` would be included in the shipped Hex package if created. This must be addressed.

**Required fix:** Add `"priv/dev"` exclusion to `package.files`. Since Elixir's `package.files` is an inclusion list (not exclusion), the fix is to replace `"priv"` with explicit subdirectory inclusions:

```elixir
files: [
  "lib",
  "priv/fixtures",
  "priv/host_app_proof",
  "priv/repo",         # includes dev_seed.exs — acceptable (it's a maintainer artifact)
  "priv/static",
  # "priv/dev" intentionally excluded (shots.mjs is not for adopters)
  # "priv/shots" intentionally excluded (screenshots are not for adopters)
  "mix.exs",
  ...
]
```

[VERIFIED: `mix.exs:133` — `"priv"` is in `package.files` as a bare directory]
[VERIFIED: `priv/` structure via `ls priv/`]

**Note:** `priv/repo/dev_seed.exs` being in `package.files` is acceptable — it is a developer tool that adopters may find useful. The key exclusions are `priv/dev/` (shots.mjs) and `priv/shots/` (screenshot output).

### `.gitignore` additions needed

```gitignore
# Screenshot harness outputs (PNG + JSON captures — committed: gap_register.md only)
priv/shots/*/
priv/shots/**/*.png
priv/shots/**/*.json
```

The `priv/shots/gap_register.md` is committed and should NOT be gitignored. The date-stamped directories are gitignored. The recommended approach is a `priv/shots/.gitignore` file that says:

```gitignore
# Ignore all screenshot captures; only gap_register.md is committed
*/
*.png
*.json
```

[VERIFIED: Current `.gitignore` has no `priv/shots/` entry — must be added]

### merge-blocking CI exclusion

The `scoria.ui.shots` task is not registered in `cli.preferred_envs` in `mix.exs`, so it does not run in any CI environment by default. No additional CI guard needed — the task is purely a developer/maintainer tool per D-01/D-02. Document in `docs/MAINTAINERS.md` per PROOF-03.

---

## Common Pitfalls

### Pitfall 1: `data-scoria-ready` Not Re-set After Theme Toggle

**What goes wrong:** The harness sets `data-theme="light"` via JS eval, then immediately screenshots — but the sentinel is still `"true"` from the previous page load, so the harness doesn't know if the theme change triggered a re-render.
**Why it happens:** Theme toggle in `ThemeToggle` hook is a CSS-only change (no LiveView round-trip), so `phx:page-loading-stop` doesn't fire again.
**How to avoid:** Theme toggle is CSS-only and instant. After `page.evaluate(() => document.documentElement.setAttribute('data-theme', 'light'))`, wait for a brief CSS repaint with `page.waitForTimeout(100)` or check the attribute directly, then screenshot immediately. Do not re-wait for `data-scoria-ready` — it won't be reset.
**Warning signs:** Screenshots that appear identical in dark and light mode (CSS not applied).

### Pitfall 2: Approval Modal Not Visible Without Seeded Record

**What goes wrong:** `select_approval` event with a valid approval ID only opens the modal if that ID is in the current `approval_inbox` list. If the seed didn't create a pending approval for `"acme-corp"`, the inbox is empty and the event is a no-op.
**Why it happens:** `ApprovalsLive` guards the modal in `handle_event("select_approval", ...)` with `Enum.find(socket.assigns.approval_inbox, &(to_string(&1.id) == approval_id))`.
**How to avoid:** Seed must create ≥1 pending approval for `tenant_id: "acme-corp"`. Verify in seed output log: `"  ✓ refund-review run (pending approval)"`.
**Warning signs:** Overlay screenshots look identical to baseline (no modal visible).

### Pitfall 3: `Eval.create_eval_spec/1` Requires a Real Dataset

**What goes wrong:** `create_eval_spec` calls `put_dataset_snapshot!` which loads `dataset_id` from the DB. If no dataset exists when creating the eval spec, it raises.
**Why it happens:** EvalSpec has `dataset_id` as a required field and the context validates it on insert.
**How to avoid:** Create a `Dataset` (via `Eval.create_dataset/1`) and then seal it (via `Eval.seal_dataset/1`) before calling `Eval.create_eval_spec/1`. Seal it because live judge eval runs require sealed datasets.
**Warning signs:** `** (ArgumentError) missing live eval option dataset_id` or Repo constraint violation during seeding.

### Pitfall 4: `flash_tone_class/1` Will Score Low on `consistency` Dimension

**What goes wrong:** The baseline critique will flag `flash_group` on every screen that shows a flash message, scoring `consistency` low because the rendered HTML uses raw palette classes (`border-rose-200 bg-rose-50 text-rose-900`) not semantic tokens.
**Why it happens:** `lib/scoria_web/ui.ex:195` — known issue, documented in UI-SPEC as DS-05 gap.
**How to avoid:** Do NOT fix it in Phase 11. Document it in the gap register. The harness captures existing reality; fixing `flash_tone_class/1` is Phase 12 scope.
**Warning signs:** `consistency` scores of 2 across multiple screens.

### Pitfall 5: Review Queue / Eval Workbench / Prompt Registry Don't Filter by Tenant

**What goes wrong:** Trying to capture "empty" state via `?tenant=empty-tenant` on these four screens fails because they don't read `params["tenant"]` — they list all records globally.
**Why it happens:** `EvalSpecLive`, `PromptLive.Index`, `ReviewQueueLive`, and `WorkflowLive.Index` do not call `params["tenant"]` in `mount/3`.
**How to avoid:** Capture empty states for these screens before running the seed (on a freshly migrated DB) or accept that "empty" screenshots for these screens are a baseline-only artifact. Document this limitation in `docs/MAINTAINERS.md`.
**Warning signs:** "Empty" screenshots for these screens still show seeded data.

### Pitfall 6: `shots.mjs` Not in PATH / Node version mismatch

**What goes wrong:** `System.cmd("node", [...])` fails with `{:error, :enoent}` or version error.
**Why it happens:** Node is installed via asdf on this machine (`/Users/jon/.asdf/shims/node`). `System.cmd` uses the PATH at process start time, which may not include asdf shims in some invocation contexts.
**How to avoid:** In the Mix task, detect node with `System.find_executable("node")` and emit a helpful error if nil. Document Node as a prerequisite.
**Warning signs:** `Mix.raise("Cannot find node executable. Install Node.js >= 18.")`.

---

## Code Examples

### Creating an Incident in the Seed

```elixir
# Source: lib/scoria/sre/incident_manager.ex:66
# Source: lib/scoria/sre/incident.ex (schema)
alias Scoria.SRE.IncidentManager

{:ok, incident} = IncidentManager.open_incident(%{
  tenant_id: tenant_id,
  incident_key: "quality-regression-seed-001",
  severity: "warning",
  status: "open",
  summary: "Quality regression on refund approval lane",
  routing_class: "review",
  dedupe_key: "seed-incident-warning-001",
  first_seen_at: DateTime.utc_now(),
  last_seen_at: DateTime.utc_now()
})
IO.puts("  ✓ incident (warning/open)")
```

### Creating a Review Candidate in the Seed

```elixir
# Source: lib/scoria/eval/online_score_candidate.ex (schema)
alias Scoria.Eval.OnlineScoreCandidate
alias Scoria.Repo

existing = Repo.get_by(OnlineScoreCandidate, dedupe_key: "seed-candidate-001")
if is_nil(existing) do
  %OnlineScoreCandidate{}
  |> OnlineScoreCandidate.changeset(%{
    tenant_id: tenant_id,
    dedupe_key: "seed-candidate-001",
    status: "needs_review",
    review_status: "pending",
    score: 0.42,
    score_status: "low_quality",
    severity: "low_quality",
    scorer_kind: "llm_judge",
    scorer_version: "v1",
    judge_model: "claude-sonnet",
    rubric_version: "eval-spec-v1",
    sampled_at: DateTime.utc_now()
  })
  |> Repo.insert!()
  IO.puts("  ✓ review candidate (needs_review)")
end
```

### Creating an EvalSpec in the Seed

```elixir
# Source: lib/scoria/eval.ex:154 + lib/scoria/eval/eval_spec.ex
alias Scoria.Eval

# Step 1: Create and seal a dataset
{:ok, dataset} = Eval.create_dataset(%{
  name: "Refund policy eval dataset v1",
  version: "1",
  items: [
    %{input: %{"query" => "refund policy"}, expected_output: %{"answer" => "30-day refund policy"}}
  ]
})
{:ok, sealed_dataset} = Eval.seal_dataset(dataset)

# Step 2: Create eval spec referencing the sealed dataset
{:ok, spec} = Eval.create_eval_spec(%{
  name: "Refund Response Quality",
  description: "Scores refund policy answers against golden examples",
  dataset_id: sealed_dataset.id,
  dataset_version: sealed_dataset.version,
  eval_mode: :live_judge,
  subject: %{"prompt_template_id" => nil},
  scorers: [%{"scorer_kind" => "llm_judge", "weight" => 1.0}],
  threshold_policy: %{"pass_rate_gte" => 0.8, "mean_score_gte" => 0.7, "max_latency_ms" => 5000}
})
IO.puts("  ✓ eval spec (#{spec.name})")
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Browser automation via Wallaby (Elixir) | Node/Playwright shell-out (D-02) | Phase 11 design | Zero Hex footprint; no chromedriver PATH dep |
| Ad-hoc screen review | Mechanized 16-state-per-screen matrix | Phase 11 | Reproducible; re-runnable across phases 12–17 |
| LLM critique as separate external process | In-harness ReqLLM vision call (dogfooding) | Phase 11 | Uses existing dep; no new infrastructure |
| Scattered `tenant_id` sources | Canonical `SupportJourney.tenant_id()` | Prior phases | Drift-guarded; broken calls surface under `mix test` |

**Deprecated/outdated:**
- `flash_tone_class/1` raw palette classes (`border-rose-200` etc.) at `ui.ex:195`: will be flagged by the baseline audit as a DS-05 gap. Fix is Phase 12 scope, not Phase 11.

---

## Validation Architecture

> `workflow.nyquist_validation` is not set to `false` in `.planning/config.json` (key absent). Section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (standard Elixir) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/scoria/mix_tasks/` (after Wave 0 creates files) |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVAL-01 | `mix scoria.ui.shots` exits 0 when dev server is up, captures files to `priv/shots/` | manual-only (requires running dev server + Playwright) | N/A — browser automation excluded from merge-blocking CI per D-01 | N/A |
| EVAL-02 | Critique pass produces valid 9-key JSON per screen | unit (JSON shape validation) | `mix test test/scoria/ui_critique_test.exs` | ❌ Wave 0 |
| EVAL-03 | `priv/dev/shots.mjs` is checked in; `priv/shots/gap_register.md` is committed | manual verify | `git status priv/dev/shots.mjs priv/shots/gap_register.md` | N/A |
| EVAL-04 | After running `dev_seed.exs`, each screen shows ≥N records (per UI-SPEC minimums) | manual verify | `mix run priv/repo/dev_seed.exs && mix phx.server` then click-through | N/A |
| EVAL-05 | Gap register is non-empty and contains the `flash_tone_class` known issue | manual verify after critique run | N/A | N/A |

**Manual-only justification for EVAL-01, EVAL-03, EVAL-04, EVAL-05:** These require a running Phoenix dev server + Playwright (browser automation) + database with real data. They are intentionally excluded from merge-blocking CI per the requirements spec ("Browser tests in merge-blocking CI" is explicitly out of scope).

**Unit-testable subset:**
- JSON findings shape validation (parse a mock critique response and verify 9-key structure) — EVAL-02 partial
- Seed idempotency: run `dev_seed.exs` twice and verify record counts don't double — possible as a local integration test but not CI-gated

### Wave 0 Gaps

- [ ] `test/scoria/ui_critique_test.exs` — covers EVAL-02 (mock ReqLLM response → verify 9-key JSON shape)
- [ ] No framework install needed — ExUnit is standard Elixir

---

## Security Domain

> `security_enforcement` not set to `false` — section included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Dev-only tooling; no auth surface |
| V3 Session Management | no | Mix task, no session |
| V4 Access Control | no | Dev-only tooling; no access control surface |
| V5 Input Validation | yes (low risk) | `OptionParser` validates CLI flags; no user-supplied data reaches the DB |
| V6 Cryptography | no | ANTHROPIC_API_KEY read from env; no custom crypto |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell injection via `--base-url` flag | Tampering | `System.cmd/3` passes args as list (no shell interpolation); validate URL format in OptionParser |
| ANTHROPIC_API_KEY leaking in logs | Information Disclosure | ReqLLM handles auth headers; don't log the key in Mix task output |
| Screenshots containing sensitive DB data | Information Disclosure | `priv/shots/` gitignored except `gap_register.md`; screenshots are dev-only artifacts |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `shots.mjs` runtime | ✓ | v22.14.0 | None (blocking) |
| Playwright | Screenshot capture | ✓ | 1.60.0 (via npx) | None (blocking for EVAL-01) |
| Chromium | Playwright headless browser | unverified locally | — | `npx playwright install chromium` |
| `mix phx.server` | Screenshot capture target | dev-time only | — | None (blocking for EVAL-01) |
| ANTHROPIC_API_KEY | Vision critique | unverified | — | Graceful error: "Set ANTHROPIC_API_KEY to run --critique" |
| PostgreSQL | Dev seed + critique | dev-time only | — | None (blocking for seed) |

**Missing dependencies with no fallback:**
- Chromium browser binaries — must run `npx playwright install chromium` (documented in MAINTAINERS.md per D-02)

**Missing dependencies with fallback:**
- ANTHROPIC_API_KEY — absent key yields a clear error message; screenshot pass runs without it

---

## Open Questions (RESOLVED)

1. **Empty-state capture for global-list screens**
   - What we know: Review Queue, Eval Workbench, Prompt Registry, and Workflow Index do not support `?tenant=` switching — they list all records globally.
   - What's unclear: How to mechanically capture "empty" state for these four screens without a DB reset.
   - Recommendation: The planner should decide between (a) skipping the empty matrix state for these four screens and documenting the limitation, or (b) structuring the harness to capture empty state only on freshly-migrated DBs. Option (a) is simpler and aligned with D-11 (no DB reset).
   - **RESOLVED** — see Plan 03 <interfaces> (chosen: RESEARCH option (a) — skip the empty matrix state for the 4 non-tenant-scoped screens, capture populated-only; manifest `tenantScoped` flag gates empty captures; limitation documented in docs/MAINTAINERS.md per Plan 04).

2. **Overlay dispatch for record-ID-dependent overlays**
   - What we know: Approvals modal and Connector drawers require a real record ID from the seeded data; the Playwright script must discover this ID at runtime.
   - What's unclear: Best DOM attribute strategy — do the rendered list rows emit `phx-value-id` attributes that Playwright can read, or does it need a custom `data-*` attribute?
   - Recommendation: Read the existing LiveView templates carefully during implementation. Approvals rows already render `phx-click="select_approval"` and `phx-value-id={approval.id}` — Playwright can use `page.getAttribute('[phx-click="select_approval"]', 'phx-value-id')` or click the first row directly.
   - **RESOLVED** — see Plan 03 <interfaces> (chosen: Playwright page.click on the first-row phx-click button supplies the real seeded record id, then re-await data-scoria-ready; per-screen overlay/selector manifest hardcoded in shots.mjs).

3. **`priv/repo/dev_seed.exs` inclusion in shipped Hex package**
   - What we know: Current `package.files` includes `"priv"` as a bare directory.
   - What's unclear: Whether the project intentionally ships `priv/repo/` to adopters (migrations are shipped; the dev_seed.exs would be new there).
   - Recommendation: The planner should decide whether `dev_seed.exs` belongs in `package.files`. It is a developer tool that adopters may find useful as a reference, but it is not a runtime artifact. The safer default is to exclude it and document it only in MAINTAINERS.md.
   - **RESOLVED** — see Plan 04 <interfaces> (chosen: EXCLUDE priv/repo/dev_seed.exs from the shipped package — omit "priv/repo" from package.files; documented in MAINTAINERS.md only).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sentinel re-wait not needed after theme toggle (CSS-only change) | Pitfall 1, Pattern 3 | Low — theme toggle is provably CSS-only per ThemeToggle hook source |
| A2 | `page.click()` on first rendered list row is sufficient for overlay dispatch (simpler than custom event dispatch) | Overlay Event Inventory | Medium — if rows are conditionally rendered or not visible at 375px viewport, click may fail |
| A3 | `SupportJourney.tenant_id()` ("acme-corp") is the correct seeded tenant ID to use for all tenant-scoped screens | Seed Depth section | Low — confirmed from SupportJourney source and example seed |
| A4 | Playwright node module is available globally via `npx playwright` without a local `package.json` | Environment Availability | Medium — confirmed `npx playwright --version` = 1.60.0 on this machine, but might need explicit install |
| A5 | `mix.exs:package.files` must be refactored from `"priv"` to explicit subdirs to exclude `priv/dev/` and `priv/shots/` | Hex-Package Hygiene | High if wrong — `shots.mjs` would be shipped to adopters |
| A6 | `Eval.create_eval_spec/1` requires `dataset_id` referencing a sealed dataset (not just any dataset) | Seed Depth, Eval Workbench | High — if wrong, seed will fail at runtime |

---

## Sources

### Primary (HIGH confidence — verified from codebase)

- `assets/js/scoria.js:84` — `data-scoria-ready` sentinel confirmed set on `phx:page-loading-stop`
- `assets/js/scoria.js:48` — `ThemeToggle` hook confirmed CSS-only via `documentElement.setAttribute`
- `deps/req_llm/lib/req_llm/message/content_part.ex:66` — `ContentPart.image(binary, media_type)` API
- `deps/req_llm/lib/req_llm/context.ex:229–246` — `Context.user/2` with content parts list
- `deps/req_llm/lib/req_llm/generation.ex:73` — `generate_text/3` signature
- `deps/req_llm/lib/req_llm.ex:55` — ANTHROPIC_API_KEY loaded via dotenvy
- `lib/scoria/support_journey.ex` — tenant_id="acme-corp", session_id="support-session-42", connector_key="billing"
- `examples/support_copilot/priv/repo/dev_seed.exs` — idempotency pattern (try/rescue per step)
- `lib/scoria_web/live/approvals_live/index.ex` — confirms `select_approval` event + `show_approve_modal` assign
- `lib/scoria_web/live/connectors_live/index.ex` — confirms `runtime_drawer`/`connector_drawer` assigns + events
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` — confirms `show_approve_modal` + `open_approve` event
- `lib/scoria_web/ui.ex:195` — raw palette in `flash_tone_class/1` confirmed
- `lib/scoria/sre/incident.ex` — incident schema + required fields
- `lib/scoria/eval/online_score_candidate.ex` — review candidate schema + status enums
- `lib/scoria/eval/eval_spec.ex` — eval spec schema
- `mix.exs:133` — `"priv"` in package.files; `req_llm ~> 1.13` confirmed at line 91
- `lib/mix/tasks/scoria.eval.ex` — Mix task skeleton (shortdoc, use Mix.Task, OptionParser)
- `lib/mix/tasks/scoria.warning_inventory.ex` — `System.cmd("git", ...)` usage pattern

### Secondary (MEDIUM confidence — verified from code + structural analysis)

- Playwright 1.60.0 — confirmed via `npx playwright --version` on this machine
- Node.js v22.14.0 — confirmed via `node --version` on this machine
- `ReviewQueueLive`, `EvalSpecLive`, `PromptLive.Index`, `WorkflowLive.Index` do not read `params["tenant"]` — confirmed by reading all four `mount/3` implementations

### Tertiary (LOW confidence)

- None — all claims verified directly from codebase or installed deps.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all confirmed from `mix.exs` and installed `deps/`
- Architecture patterns: HIGH — verified against real LiveView source and ReqLLM dep
- Seed depth: HIGH — schema introspection from source; MEDIUM for idempotency patterns (example seed used as template)
- Pitfalls: HIGH (sentinel/theme, overlay seeding) / MEDIUM (empty state for non-tenant-scoped screens)
- Hex hygiene: HIGH — `mix.exs:package.files` read directly

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (30 days — stack is stable; ReqLLM 1.13 is locked in lockfile)
