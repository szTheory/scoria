# Phase 17: Consistency Sweep + Proof — Research

**Researched:** 2026-06-13
**Domain:** LLM audit harness re-run, before/after contact-sheet generator, ExDoc component catalog, MAINTAINERS.md documentation
**Confidence:** HIGH — all findings verified by direct codebase inspection; no external package lookups required (this phase installs nothing new)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** HYBRID audit: re-run LLM critique (method-match per-screen rubric delta) + commit a deterministic, zero-API-cost 11-P1 resolution checklist.
- **D-02:** LLM critique re-run uses the existing harness path unchanged: `mix scoria.ui.shots --critique` → `Scoria.UICritique.critique_screen/3` (ReqLLM vision, same 9-dimension rubric) over the same 9 screens, canonical `populated · desktop · dark` state. No new methodology.
- **D-03:** Stamp run date and model id/version into commit message / report header. Treat the deterministic P1 checklist — not raw LLM scores — as the falsifiable proof.
- **D-04:** 11 baseline P1s map to resolving phase + concrete evidence (component/CSS/test). This checklist requires no API key to re-verify.
- **D-05:** Ship a committed contact-sheet GENERATOR plus a committed markdown index; rendered images stay gitignored and regenerable. No committed binaries.
- **D-06:** Extend the existing dev harness: new `priv/dev/contact_sheet.mjs` or `--before/--after` (contact-sheet) mode on `priv/dev/shots.mjs`. Must accept `--before priv/shots/2026-06-04 --after priv/shots/<final-date>`.
- **D-07:** Commit the generator + `contact_sheet_index.md` (records baseline dir, final dir, per-screen baseline→final delta notes). Generated HTML/grid output lives gitignored alongside PNGs under `priv/shots/`. Generator stays excluded from the Hex package via `mix.exs package.files`.
- **D-08:** Capture a fresh "final" screenshot set (seed-first → `mix scoria.ui.shots`) into a new dated dir before generating the contact sheet. Baseline "before" set already exists at `priv/shots/2026-06-04/`.
- **D-09:** `lib/scoria_web/ui.ex` `@moduledoc`/per-component `@doc` + existing `attr`/`slot` declarations are the catalog SSOT. Backfill sparse `@doc` strings so `mix docs` renders the full component reference. No standalone `docs/design_system.md`.
- **D-10:** Add "Design-system component catalog" section to `docs/MAINTAINERS.md` listing shared components and pointing to `mix docs` for full attribute/slot reference.
- **D-11:** The harness-usage half of PROOF-03 is ALREADY satisfied by the existing "Screenshot + Critique Harness (dev-only)" section in `docs/MAINTAINERS.md`. Verify accuracy (add contact-sheet command if added); do not rewrite.
- **D-12:** Consolidate audit into ONE committed report file `priv/shots/gap_register_final.md` (mirroring `priv/shots/gap_register.md`). Contains: (1) per-screen baseline→final rubric delta table, (2) deterministic 11-P1 resolution checklist, (3) raw-color-zero section. One file, not split across dirs.
- **D-13:** Assert raw-color-zero by CITING the existing executable. Report states count is 0 and names: `test/scoria_web/ds06_drift_guard_test.exs` (three tests) + empty `test/support/ds06_baseline.txt`. Do not add a new counting script.

### Claude's Discretion

- Exact filenames (`contact_sheet.mjs` vs a `shots.mjs` flag; `gap_register_final.md` vs equivalent name), the precise markdown layout of the delta table and P1 checklist, CSS/HTML of the generated contact-sheet grid, plan slicing, and which dated dir the final shots land in.
- Whether final critique covers all 9 screens or is scoped to screens with baseline P1s plus a representative sample — but the per-screen delta table must cover all 9 screens.
- Whether the MAINTAINERS.md catalog section sits inside or adjacent to the existing harness section, as long as both are reachable from `docs/MAINTAINERS.md`.

### Deferred Ideas (OUT OF SCOPE)

- Standing browser-a11y lane (axe across all screens/themes/viewports).
- CI visual-regression screenshot baselines.
- Adding screenshot/critique or contact-sheet generation to merge-blocking CI.
- Recurring multi-date audit archive.
- Standalone `docs/design_system.md`.
- Release `0.1.1` publish via release-please.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | A final audit shows rubric-score improvement (baseline → final) per screen and a raw-color-class count of zero. | Harness re-run mechanics fully documented (§Harness Re-Run Mechanics); 11 P1 findings enumerated verbatim with resolving evidence (§Baseline Artifact Structure); raw-color-zero cite path confirmed (§DS-06 Raw-Color-Zero Proof). |
| PROOF-02 | Before/after contact sheets document the iteration as a basis for future passes. | Dated-dir layout, PNG naming scheme, gitignore posture, and Hex package exclusion fully documented (§Contact-Sheet Generator). |
| PROOF-03 | `docs/MAINTAINERS.md` documents the design-system component catalog and how to run the screenshot harness. | All 30 public `ui.ex` functions catalogued with @doc status; existing harness section confirmed accurate; ExDoc wiring confirmed (§Component Catalog via ExDoc). |
</phase_requirements>

---

## Summary

Phase 17 is entirely about producing three committed proof artifacts for an already-shipped dashboard. No UI code changes, no new dependencies, no new CI lanes. The work divides cleanly into three non-overlapping tracks that can be planned in parallel waves or as a linear sequence.

**Track A (PROOF-01):** Re-run `mix scoria.ui.shots --critique` to generate a dated final screenshot set and per-screen LLM rubric JSON, then author `priv/shots/gap_register_final.md` containing the per-screen rubric delta table, the deterministic 11-P1 resolution checklist, and the DS-06 raw-color-zero citation.

**Track B (PROOF-02):** Write `priv/dev/contact_sheet.mjs` (or a `--contact-sheet` mode on `shots.mjs`) that accepts `--before priv/shots/2026-06-04 --after priv/shots/<final-date>` and generates a per-screen before/after HTML grid (gitignored). Commit the generator plus `priv/shots/contact_sheet_index.md` (which records the dir pair and per-screen delta notes).

**Track C (PROOF-03):** Backfill `@doc` strings and slot documentation in `lib/scoria_web/ui.ex` for the subset of components where the existing `@doc` is a single-line terse string that `mix docs` renders incompletely (principally: `badge`, `button`, `eyebrow`, `attention_card`, `kbd`, `evidence_action_row`, `evidence_empty`, `evidence_rows`, `evidence_section`). Then add a "Design-system component catalog" section to `docs/MAINTAINERS.md`.

**Primary recommendation:** Sequence as: Wave 0 (screenshot capture + harness re-run) → Wave 1 (gap_register_final.md authoring + contact-sheet generator + MAINTAINERS.md catalog section) → Wave 2 (contact_sheet_index.md + final verification). The harness re-run must come first because it produces the final-date dir that Track B reads.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| LLM rubric re-run | Mix task (dev-only) | Elixir app (ReqLLM) | `mix scoria.ui.shots --critique` drives `Scoria.UICritique.critique_screen/3`; the Mix task starts the Elixir app only for the critique pass |
| Screenshot capture | Node/Playwright (dev-only) | — | `shots.mjs` drives Chromium directly against the running dev server; the Mix task shells out via `System.cmd("node", ...)` |
| Final report authoring | Human / executor | — | `gap_register_final.md` is hand-authored from per-screen JSON + rubric delta; it is not auto-generated by the task |
| Contact-sheet generation | Node.js (dev-only) | — | New `contact_sheet.mjs` reads on-disk dated PNGs and writes an HTML grid; no Elixir involvement |
| Component catalog | ExDoc + `ui.ex` moduledocs | MAINTAINERS.md (entry-point) | `mix docs` renders `ui.ex` `@doc`/`attr`/`slot` declarations; MAINTAINERS.md is the human-navigable entry-point, not the SSOT |
| Raw-color-zero proof | ExUnit (DS-06 guard) | — | `mix test test/scoria_web/ds06_drift_guard_test.exs` — already green; the report cites it, does not re-implement it |

---

## Standard Stack

### Core (no new installations — everything is already in place)

| Tool | Version | Purpose | Status |
|------|---------|---------|--------|
| Node.js | 22.14.0 (verified) | `shots.mjs` and new `contact_sheet.mjs` runtime | Already installed |
| Playwright | 1.60.0 (verified) | Chromium screenshot capture | Already installed (`npx playwright install chromium`) |
| ExDoc | `~> 0.38` (pinned in mix.exs) | `mix docs` renders `ui.ex` `@doc`/`attr`/`slot` catalog | Already a dev dep |
| ReqLLM | `~> 1.13` (pinned in mix.exs) | LLM vision calls in `Scoria.UICritique.critique_screen/3` | Already wired |

### External Service Requirement

| Service | Required For | Env Var | Notes |
|---------|-------------|---------|-------|
| Anthropic API | `--critique` pass only | `ANTHROPIC_API_KEY` | Not needed for screenshots, contact-sheet generation, or ExDoc catalog |

**This phase installs no new packages.** The Package Legitimacy Audit section is therefore omitted — there is nothing to audit.

---

## Harness Re-Run Mechanics (PROOF-01, D-01/D-02/D-08)

[VERIFIED: direct codebase read — `lib/mix/tasks/scoria.ui.shots.ex`, `lib/scoria/ui_critique.ex`]

### Invocation Chain

```
mix run priv/repo/dev_seed.exs    # 1. seed (idempotent)
mix phx.server                    # 2. dev server (terminal A)
mix scoria.ui.shots               # 3. screenshot pass → priv/shots/{today}/{screen}/*.png
mix scoria.ui.shots --critique    # 4. critique pass → per-screen populated_dark_desktop.json
                                  #    + priv/shots/gap_register.md auto-generated
```

The `mix scoria.ui.shots` Mix task in `lib/mix/tasks/scoria.ui.shots.ex` handles both passes:

- **Screenshot pass** (`run_screenshot_pass/2`): shells out to `priv/dev/shots.mjs` via `System.cmd("node", [script_path | args])`. Does NOT start the Elixir app. Output goes to `priv/shots/{Date.utc_today() |> Date.to_iso8601()}/`.
- **Critique pass** (`run_critique_pass/2`, only with `--critique` flag): calls `Mix.Task.run("app.start")` first (to access ReqLLM and application config), then iterates the 9 screens calling `Scoria.UICritique.critique_screen/3` on `{out_dir}/{screen}/populated_dark_desktop.png`. Writes `{out_dir}/{screen}/populated_dark_desktop.json`. Terminates by calling `render_gap_register/2`.

### Model ID/Version

[VERIFIED: `lib/scoria/ui_critique.ex` line 11]

```elixir
@default_model "anthropic:claude-sonnet-4-5"
```

The executor must stamp this model spec in the final report header (D-03). The model can be overridden via `Keyword.get(opts, :model, @default_model)` but should NOT be overridden — D-02 requires method-match with the 2026-06-04 baseline.

### 9 Screens Covered

[VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex` line 56]

```elixir
@screens ~w(live_ops approvals workflows incidents connectors reviews eval_specs prompts prompt_release)
```

The canonical state for critique is `populated · desktop · dark` — PNG path: `{out_dir}/{screen}/populated_dark_desktop.png`.

### Gap Register Write Path

The `render_gap_register/2` function writes to:

```
priv/shots/gap_register.md   # NOT inside out_dir — stable top-level path
```

For the final pass, the executor writes `priv/shots/gap_register_final.md` manually (or by a targeted invocation) rather than overwriting the committed baseline. The task currently only knows about `gap_register.md` — the executor will need to either (a) rename/copy after the run, or (b) write the final report manually using the per-screen JSON files.

**Practical approach (D-12):** Run `mix scoria.ui.shots --critique` normally (produces `gap_register.md` from the final run). Then hand-author `gap_register_final.md` using the per-screen JSON plus the rubric delta table format documented below. The final critique JSON files land at `priv/shots/{final-date}/{screen}/populated_dark_desktop.json`.

### Seed-First Capture Sequence

1. `mix run priv/repo/dev_seed.exs` — idempotent; seeded tenant is `acme-corp`.
2. `mix phx.server` in a separate terminal.
3. `mix scoria.ui.shots` — Node/Playwright captures. Output: `priv/shots/{date}/`.
4. `mix scoria.ui.shots --critique` — OR if PNGs already exist: use `--skip-shots` to run only the critique pass.

**Important:** The `--skip-shots` flag exists but is not documented in MAINTAINERS.md. When re-using the PNGs from the screenshot pass, run:

```bash
mix scoria.ui.shots --skip-shots --critique
```

### Known Empty-State Limitation

[VERIFIED: `priv/dev/shots.mjs` SCREENS manifest; `docs/MAINTAINERS.md` §Empty-state limitation]

Four screens have `tenantScoped: false` in the shots.mjs SCREENS manifest and therefore capture **populated-only**:

- `reviews` — non-tenant-scoped
- `eval_specs` — non-tenant-scoped
- `prompts` — non-tenant-scoped
- `prompt_release` — non-tenant-scoped (navigates from `/prompts`)

Five screens are tenant-scoped and capture both empty + populated:

- `live_ops`, `approvals`, `workflows`, `incidents`, `connectors`

The contact-sheet generator must account for this asymmetry — before/after rows for non-tenant-scoped screens only pair `populated_*` states, not `empty_*`.

---

## Baseline Artifact Structure (PROOF-01, D-04)

[VERIFIED: `priv/shots/gap_register.md` — read directly]

### Baseline Summary (2026-06-04)

- Screens audited: 9
- P0 issues (score 1): 0
- P1 issues (score 2): 11
- Passing (score ≥ 3): 71

### The 11 P1 Findings — Verbatim + Resolving Evidence

| # | Screen | Dimension | Baseline Finding (first sentence) | Resolving Phase | Concrete Evidence |
|---|--------|-----------|-----------------------------------|-----------------|-------------------|
| P1-01 | all-screens (flash) | consistency | `flash_tone_class/1` renders flash banners with raw palette classes (border-rose-200 bg-rose-50 text-rose-900) | Phase 12 | `ui.ex` `flash_group/1` rewrote to emit `scoria-flash--{tone}` BEM classes; DS-06 ratchet zeroed `ui.ex` raw-palette count |
| P1-02 | connectors | density | Empty states consume significant vertical space with minimal information | Phase 16 | Mobile-first shell + responsive padding refactor (16-01-PLAN.md); shared `<.empty_state>` component via Phase 14/15 conversions |
| P1-03 | eval_specs | a11y | Cannot verify focus-visible states from static screenshot | Phase 16 | Focus-visible hardening across all interactive controls (16-05-PLAN.md MOTION-02) |
| P1-04 | eval_specs | density | Large amount of empty space below the 2-row table — viewport underutilized | Phase 14 | Eval Workbench shared-component conversion (14-05-PLAN.md); `<.table>` density toggle wired |
| P1-05 | eval_specs | responsive | Fixed sidebar navigation would likely cause issues at 375px mobile width | Phase 16 | Mobile-first off-canvas nav drawer replacing fixed sidebar (16-01-PLAN.md MOTION-03) |
| P1-06 | prompt_release | a11y | Dark background with light text meets contrast requirements / Edit links lack visible affordance | Phase 16 | Focus-visible hardening + a11y sweep (16-05-PLAN.md MOTION-02); status not conveyed by color alone |
| P1-07 | prompt_release | density | Table has only 2 rows visible with significant empty space below | Phase 14 | Prompt Registry and Release Workbench conversion (14-06-PLAN.md); `<.table>` compact density |
| P1-08 | prompt_release | responsive | Layout appears optimized for desktop viewport (1280px+) | Phase 16 | Mobile summary adoption + off-canvas nav (16-04-PLAN.md + 16-01-PLAN.md MOTION-03) |
| P1-09 | prompts | a11y | No visible focus indicators on interactive elements | Phase 16 | Focus-visible hardening (16-05-PLAN.md MOTION-02) |
| P1-10 | prompts | density | Table rows are very compact / Long Entity IDs (UUIDs) consume excessive horizontal space | Phase 14 | Prompt Registry conversion (14-06-PLAN.md); `<.table>` density controls; `<.id>` middle-truncation component |
| P1-11 | prompts | responsive | Fixed sidebar layout may not adapt well to mobile viewport (375px) | Phase 16 | Mobile-first off-canvas nav drawer (16-01-PLAN.md MOTION-03); table viewport overflow fix (16-02-PLAN.md) |

### Delta Table Format (for gap_register_final.md)

The final report's delta table must method-match the baseline's "Ranked Findings" format. Use:

```markdown
### {screen} — {dimension}: {baseline_score}/5 → {final_score}/5
> {finding text}
```

The baseline format was produced by `render_gap_register/2` which renders `### {screen} — {dimension}: {score}/5`. The delta table adds a `→ {final_score}` suffix to each row. Screens with no P1s in the baseline are shown only if the final audit surfaces new findings.

---

## Contact-Sheet Generator (PROOF-02, D-05/D-06/D-07)

[VERIFIED: `priv/dev/shots.mjs`, `priv/shots/.gitignore`, `mix.exs` package.files]

### Dated-Dir Layout

```
priv/shots/
  2026-06-04/          # baseline "before" dir (exists on disk, gitignored)
    live_ops/
      empty_dark_desktop.png
      empty_dark_mobile.png
      empty_light_desktop.png
      empty_light_mobile.png
      populated_dark_desktop.png
      populated_dark_desktop.json
      populated_dark_mobile.png
      populated_light_desktop.png
      populated_light_mobile.png
    approvals/
      [same structure + overlay: modal_dark_desktop.png etc.]
    ...
  2026-06-13/          # (example) final "after" dir — to be created by harness re-run
    [same structure]
  contact_sheet_index.md    # COMMITTED — records dir pair + per-screen delta notes
  contact_sheet.html        # GITIGNORED — generated HTML grid
  gap_register.md           # COMMITTED — baseline
  gap_register_final.md     # COMMITTED — final delta report
```

### PNG File-Naming Scheme

[VERIFIED: `priv/dev/shots.mjs` `captureScreen` function]

Files are named: `{presence}_{theme}_{viewport}.png` where:
- `presence`: `empty` | `populated` | `{overlay_state}` (e.g. `modal`, `connector_drawer`, `runtime_drawer`, `approve_modal`)
- `theme`: `dark` | `light`
- `viewport`: `desktop` (1280×900) | `mobile` (375×812)

Canonical critique state: `populated_dark_desktop.png`

### Pairing Logic for Before/After

The generator pairs files by matching `{screen}/{filename}` across the two dated dirs. Screens with no `empty_*` captures in the baseline (reviews, eval_specs, prompts, prompt_release) will only have `populated_*` pairs — the generator must skip-and-note missing empty captures rather than erroring.

### Contact Sheet Generator Interface (D-06)

Recommended as a separate `priv/dev/contact_sheet.mjs` (keeps `shots.mjs` focused):

```bash
node priv/dev/contact_sheet.mjs \
  --before priv/shots/2026-06-04 \
  --after priv/shots/2026-06-13 \
  --out priv/shots/contact_sheet.html
```

The generator reads all `*.png` files from both dirs, pairs them by `screen/filename`, and emits an HTML file with a CSS grid showing before/after pairs per screen. The generated HTML is gitignored (same rules as `*.png`).

### Gitignore and Hex Hygiene

[VERIFIED: `priv/shots/.gitignore`, `mix.exs` `package.files`]

`priv/shots/.gitignore` rules:
- `*/` — ignores all dated subdirs (e.g. `2026-06-04/`)
- `*.png` — ignores all PNGs at any depth
- `*.json` — ignores all per-screen critique JSON
- `!gap_register.md` — explicit negation to keep committed

**New artifacts must respect this posture:**
- `contact_sheet.html` — gitignored (matches no committed pattern → add explicit `!contact_sheet_index.md` negation or simply ensure `.md` files aren't caught; current rules only block `*/`, `*.png`, `*.json` — so `.md` and `.html` would NOT be ignored by current rules)

Wait — checking the gitignore rules more carefully: the existing rules are `*/`, `*.png`, `*.json`, and `!gap_register.md`. A `.html` file at the top of `priv/shots/` would NOT be caught by `*/` (which only matches directories) or `*.png`/`*.json`. Therefore the contact-sheet HTML needs to be explicitly gitignored.

**Action for planner:** The `.gitignore` in `priv/shots/` must be extended to also ignore `*.html` (or specifically `contact_sheet.html`). The committed files (`contact_sheet_index.md` and `gap_register_final.md`) will not be caught by any ignore rule — they are safe to commit.

`mix.exs` `package.files` does NOT include `priv/shots/` or `priv/dev/` — both are explicitly excluded. No changes needed to `mix.exs` for new artifacts in those dirs. [VERIFIED: `mix.exs` lines 143–177]

---

## Component Catalog via ExDoc (PROOF-03, D-09/D-10)

[VERIFIED: direct read of `lib/scoria_web/ui.ex` — 1177 lines]

### ExDoc Wiring

[VERIFIED: `mix.exs`]

- `ex_doc "~> 0.38"` is already a dev-only dependency (line 97).
- `docs/0` function is defined; `docs/MAINTAINERS.md` is already in `extras:` (line 137).
- `mix docs` renders cleanly today. No `groups_for_modules` or `nest_modules_by_prefix` is configured — not needed for a single module.

### Complete Public Function Inventory

All 30 public functions in `ScoriaWeb.UI` with their current `@doc` status:

| Function | Current @doc Quality | Notes |
|----------|---------------------|-------|
| `tone/1` | Multi-line @doc (lines 15–18) | Well-documented; covers all tone atoms |
| `status_label/1` | Single-line @doc | Adequate; short function |
| `badge/1` | Single-line @doc | Adequate; attrs declared above |
| `button/1` | Single-line @doc | References brand book §8.5 — adequate |
| `eyebrow/1` | Single-line @doc | Very terse — "Small uppercase category/status label (brand book card eyebrow)." Could benefit from a usage example |
| `panel/1` | Single-line @doc | Adequate |
| `metric/1` | Single-line @doc | References brand book §11.3; "never a magic score" — adequate |
| `id/1` | Multi-line @doc (lines 159–164) | Well-documented (CopyId hook, stable id note) |
| `attention_card/1` | Single-line @doc | Very terse — "Status Home attention card for nonzero actionable states." No slot/usage description |
| `object_header/1` | Single-line @doc | Adequate one-liner |
| `stub_page/1` | Single-line @doc | Adequate |
| `kbd/1` | Single-line @doc | Very terse — "Keyboard shortcut chip." |
| `command_palette/1` | Single-line @doc | Adequate; mentions client-side filtering |
| `empty_state/1` | Single-line @doc | Adequate |
| `modal/1` | Multi-line @doc (lines 421–424) | Well-documented; dismiss contract explained |
| `drawer/1` | Multi-line @doc (lines 474–478) | Well-documented; dismiss contract explained |
| `field/1` | Multi-line @doc (lines 530–535) | Well-documented; a11y notes |
| `form_section/1` | Multi-line @doc (lines 560–562) | Adequate |
| `skeleton/1` | Multi-line @doc (lines 580–582) | Adequate; mentions aria-label and reduced-motion |
| `toast/1` | Multi-line @doc (lines 596–601) | Well-documented; includes JS.hide pitfall note |
| `notebook/1` | Multi-line @doc (lines 695–700) | Well-documented; tab mechanics explained |
| `raw_evidence/1` | Multi-line @doc (lines 777–779) | Adequate |
| `evidence_section/1` | Single-line @doc | Terse — "Notebook-scoped evidence section with optional status badge and action slot." |
| `evidence_rows/1` | Single-line @doc | Terse — "Stable key-value evidence rows for adapter-projected values." |
| `evidence_action_row/1` | Single-line @doc | Terse — "Compact evidence action/link row. Callers own the action/link semantics." |
| `evidence_empty/1` | Single-line @doc | Terse — "Notebook-scoped evidence empty state." |
| `table/1` | Multi-line @doc (lines 904–909) | Well-documented; mobile_summary slot explained |
| `flash_group/1` | Multi-line @doc (lines 1054–1057) | Well-documented; DS-05 noted |

### Backfill Priority

Components where `@doc` is sparse enough that `mix docs` renders an incomplete or un-useful catalog entry:

**Tier 1 — Expand (multi-line @doc recommended):**
- `attention_card/1` — needs: purpose (Status Home strip), attrs (count, label, detail, cta, path, tone), example usage
- `evidence_section/1` — needs: usage context (inside `<.notebook>` tab panels), attrs (title, description, tone, badge, actions slot)
- `evidence_rows/1` — needs: input format (list of `{label, value}` tuples or `%{label:, value:}` maps)

**Tier 2 — Expand (light addition):**
- `eyebrow/1` — add context: used in panel headers, card hierarchy eyebrows
- `kbd/1` — add context: used inline in command palette rows and help text
- `evidence_action_row/1` — add context: used for per-section action links in evidence panels
- `evidence_empty/1` — add context: used for empty tab panels in `<.notebook>`

**Tier 3 — Already adequate (no change needed):**
`tone/1`, `status_label/1`, `badge/1`, `button/1`, `panel/1`, `metric/1`, `id/1`, `object_header/1`, `stub_page/1`, `command_palette/1`, `empty_state/1`, `modal/1`, `drawer/1`, `field/1`, `form_section/1`, `skeleton/1`, `toast/1`, `notebook/1`, `raw_evidence/1`, `table/1`, `flash_group/1`

### ExDoc Groups (not needed)

All 30 public functions live in the single `ScoriaWeb.UI` module. No `groups_for_modules` or `nest_modules_by_prefix` configuration is needed — ExDoc will render all functions in alphabetical order within the module page, which is sufficient for a component catalog. [ASSUMED: ExDoc renders `attr`/`slot` declarations as part of the function signature; confirmed to be standard Phoenix.Component behavior but not verified via ExDoc docs in this session]

---

## MAINTAINERS.md + DS-06 Citation (PROOF-01/PROOF-03, D-11/D-13)

[VERIFIED: `docs/MAINTAINERS.md` §Screenshot + Critique Harness (dev-only) — read directly]

### Existing "Screenshot + Critique Harness (dev-only)" Section

The section at line 162 of `docs/MAINTAINERS.md` is already complete and accurate. It covers:
- Prerequisites (Node.js >= 18, Playwright + Chromium, ANTHROPIC_API_KEY)
- Seed-first workflow (`mix run priv/repo/dev_seed.exs`)
- Screenshot pass (`mix scoria.ui.shots`)
- Critique pass (`mix scoria.ui.shots --critique`)
- Empty-state limitation (4 non-tenant-scoped screens)
- Dev-only posture summary (gitignore + package.files + no CI)
- Optional flags (`--url`, `--tenant-empty`, `--tenant-seeded`, `--release-id`)

**Required addition (D-11):** When the contact-sheet generator is added, append its usage to this section — e.g.:

```markdown
### Contact-sheet generation (--before / --after)

After capturing two dated shot sets, generate the before/after contact sheet:

    node priv/dev/contact_sheet.mjs \
      --before priv/shots/2026-06-04 \
      --after priv/shots/<final-date> \
      --out priv/shots/contact_sheet.html

The generated HTML is gitignored. `contact_sheet_index.md` (committed) records the dir pair and per-screen delta notes.
```

### New "Design-System Component Catalog" Section (D-10)

This section does NOT yet exist in `docs/MAINTAINERS.md`. It must be added. Content should include:

1. A brief statement that `ScoriaWeb.UI` is the single enforced token gateway.
2. A glance table of all shared components (27 public HEEx components: badge, button, eyebrow, panel, metric, id, attention_card, object_header, stub_page, kbd, command_palette, empty_state, modal, drawer, field, form_section, skeleton, toast, notebook, raw_evidence, evidence_section, evidence_rows, evidence_action_row, evidence_empty, table, flash_group — plus `tone/1` and `status_label/1` as utility functions).
3. The `mix docs` invocation: `MIX_ENV=dev mix docs` and a note that the rendered catalog lives in `doc/` (gitignored in standard Elixir projects).
4. A note on the DS-06 guard: raw palette drift protection via `mix test test/scoria_web/ds06_drift_guard_test.exs`.

Placement: the section can sit immediately before or after the existing "Screenshot + Critique Harness" section. Both must be reachable from `docs/MAINTAINERS.md`. The catalog section is logically separate from the harness section.

### DS-06 Raw-Color-Zero Citation (D-13)

[VERIFIED: `test/scoria_web/ds06_drift_guard_test.exs`, `test/support/ds06_baseline.txt`]

The three tests in `ds06_drift_guard_test.exs`:

1. `"raw palette count never regresses (DS-06 ratchet)"` — scans all `.ex`/`.heex` under `lib/scoria_web/` (excluding `ui.ex` and `remote_invocation_evidence_component.ex`); count must not exceed baseline.
2. `"baseline is not stale — no file sits below its committed baseline (WR-01)"` — forces downward ratchet on every improvement.
3. `"lib/scoria_web/ui.ex has zero raw palette matches"` — explicit zero assertion on the token gateway.

`test/support/ds06_baseline.txt` is currently **empty** (1 line file with no entries), meaning the ratchet allows 0 matches across all non-excluded files. This is the proof that raw-color count = 0.

**Exact citation text for the raw-color-zero section of `gap_register_final.md`:**

```markdown
## Raw-Color-Zero Assertion

Raw palette class count: **0**

Enforcement: `test/scoria_web/ds06_drift_guard_test.exs` — three assertions:
1. "raw palette count never regresses (DS-06 ratchet)" — scans lib/scoria_web/**/*.{ex,heex}
2. "baseline is not stale — no file sits below its committed baseline (WR-01)"
3. "lib/scoria_web/ui.ex has zero raw palette matches"

Baseline: `test/support/ds06_baseline.txt` is empty — zero headroom. Any raw palette class
introduction fails `mix test` automatically.

Run: `mix test test/scoria_web/ds06_drift_guard_test.exs` — must be green before PROOF-01 is closed.
```

---

## Architecture Patterns

### Recommended Project Structure (new artifacts only)

```
priv/
  dev/
    contact_sheet.mjs        # NEW — committed, gitignored from Hex via mix.exs package.files
    shots.mjs                # existing — no changes needed
  shots/
    .gitignore               # extend to add: *.html
    2026-06-04/              # existing baseline (gitignored dir)
    {final-date}/            # NEW — created by harness re-run (gitignored dir)
    contact_sheet.html       # NEW — generated, gitignored (add *.html to .gitignore)
    contact_sheet_index.md   # NEW — committed
    gap_register.md          # existing — committed baseline
    gap_register_final.md    # NEW — committed

lib/scoria_web/
  ui.ex                      # MODIFIED — backfill @doc strings for 7 sparse components

docs/
  MAINTAINERS.md             # MODIFIED — add catalog section; extend harness section
```

### Pattern: gap_register_final.md Structure

```markdown
# Design-System Gap Register — Final {date}

**Run date:** {date}
**Model:** anthropic:claude-sonnet-4-5
**Baseline:** priv/shots/gap_register.md (2026-06-04)
**Final shots:** priv/shots/{final-date}/

## Summary

- Baseline: 0 P0 / 11 P1 / 71 passing
- Final: 0 P0 / {N} P1 / {M} passing
- Net improvement: {11-N} P1 findings resolved

## Per-Screen Rubric Delta

| Screen | Dimension | Baseline | Final | Change |
|--------|-----------|----------|-------|--------|
| all-screens (flash) | consistency | 2/5 | 5/5 | +3 |
| connectors | density | 2/5 | {score}/5 | {delta} |
| eval_specs | a11y | 2/5 | {score}/5 | {delta} |
...

## Deterministic 11-P1 Resolution Checklist

> This checklist requires no API key. Each item is verifiable by code review or `mix test`.

- [x] P1-01 all-screens (flash) / consistency: `flash_tone_class` → `flash_group/1` semantic BEM classes
      Evidence: `lib/scoria_web/ui.ex` `flash_group/1` (no raw palette); DS-06 guard (`mix test test/scoria_web/ds06_drift_guard_test.exs`)
...

## Raw-Color-Zero Assertion

[as documented in the citation text above]
```

### Pattern: contact_sheet_index.md Structure

```markdown
# Contact Sheet Index — v3.0 Control Room Milestone Close

**Baseline dir:** priv/shots/2026-06-04
**Final dir:** priv/shots/{final-date}
**Generated:** {date}

## Per-Screen Delta Notes

| Screen | State | Baseline File | Final File | Notes |
|--------|-------|---------------|------------|-------|
| live_ops | populated_dark_desktop | 2026-06-04/live_ops/populated_dark_desktop.png | {final-date}/live_ops/populated_dark_desktop.png | Responsive shell, mobile nav, focus indicators |
...

## How to Regenerate

    node priv/dev/contact_sheet.mjs \
      --before priv/shots/2026-06-04 \
      --after priv/shots/{final-date} \
      --out priv/shots/contact_sheet.html

For future milestone passes, substitute the new baseline and final dirs.
```

### Pattern: contact_sheet.mjs Implementation Notes

The contact-sheet generator reads PNGs from two dated dirs and writes an HTML file. Key concerns:

1. **fs.readdir** both dirs, build a set of `{screen}/{filename}` paths from each.
2. **Cross-reference** to find before/after pairs. Log screens that exist in one dir but not the other.
3. **HTML output** uses inline `<img>` tags with `src` as relative file paths from `priv/shots/` — no base64 encoding (files can be large).
4. **No Playwright dependency** — this is a file-system read + HTML-write; plain Node.js `fs` and `path`.
5. **Graceful handling** of missing empty-state pairs for non-tenant-scoped screens (reviews, eval_specs, prompts, prompt_release).

### Anti-Patterns to Avoid

- **Overwriting gap_register.md:** The critique pass auto-writes to `priv/shots/gap_register.md`. The final report goes to `gap_register_final.md`. Do not overwrite the committed baseline.
- **Committing generated HTML:** `contact_sheet.html` must stay gitignored. The `.gitignore` update is load-bearing.
- **Adding mix.exs package.files entries:** `priv/dev/` and `priv/shots/` are already fully excluded — no changes needed to `mix.exs`.
- **Re-running critique to "fix" score variance:** LLM scores are ±1–2 non-deterministic. The report acknowledges this; the deterministic P1 checklist is the falsifiable proof (D-03).
- **Expanding @doc into novel documentation not derivable from the code:** The catalog backfill adds usage context, not invented specifications. Cross-check against `12-UI-SPEC.md` if slot/attr semantics are unclear.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Raw-color count proof | A new counting script | Cite `ds06_drift_guard_test.exs` (D-13) | The guard already runs on every `mix test`; a second script would diverge |
| Component catalog | Standalone `docs/design_system.md` | `ui.ex` moduledocs + `mix docs` | Hand-written docs drift from `attr`/`slot` declarations on every change |
| Contact-sheet images | Commit PNGs to git | Generate from on-disk dirs | Violates zero-binary-commit posture; images are regenerable |
| New ExDoc grouping config | `groups_for_modules` or `nest_modules_by_prefix` | None needed | All 30 functions are in one module; ExDoc renders them fine without grouping |

---

## Common Pitfalls

### Pitfall 1: `gap_register.md` Overwritten on Critique Re-Run

**What goes wrong:** Running `mix scoria.ui.shots --critique` auto-overwrites `priv/shots/gap_register.md` from the final run's JSON. The committed baseline (2026-06-04) is replaced.
**Why it happens:** `render_gap_register/2` hardcodes the output to `priv/shots/gap_register.md`.
**How to avoid:** Either (a) stash/backup `gap_register.md` before the final critique run, OR (b) commit `gap_register_final.md` as a separate file and don't overwrite `gap_register.md`. Option (b) is correct per D-12 — `gap_register.md` is the stable baseline and should not be overwritten.
**Warning signs:** After `mix scoria.ui.shots --critique`, `git diff priv/shots/gap_register.md` shows changes — this means the baseline was overwritten.

### Pitfall 2: HTML File Not Gitignored

**What goes wrong:** `contact_sheet.html` is not caught by any existing rule in `priv/shots/.gitignore` (`*/`, `*.png`, `*.json` don't match `.html` files at root of `priv/shots/`).
**Why it happens:** The gitignore was designed before the HTML contact sheet existed.
**How to avoid:** Add `*.html` or `contact_sheet.html` to `priv/shots/.gitignore` before generating the contact sheet.
**Warning signs:** `git status` shows `contact_sheet.html` as an untracked file.

### Pitfall 3: LLM Score Variance Misread as Regression

**What goes wrong:** The final critique run produces a score lower than baseline on a screen that was improved. This triggers confusion about whether the screen regressed.
**Why it happens:** LLM vision scores are ±1–2 non-deterministic between runs (D-03).
**How to avoid:** The report acknowledges non-determinism; the deterministic P1 checklist is the proof. A score that drops does not override the checklist evidence.
**Warning signs:** A final score for a screen where there's clear Phase 14/15/16 evidence of improvement comes back at the same or lower level.

### Pitfall 4: Missing `--skip-shots` Pattern

**What goes wrong:** Executor re-runs the full screenshot pass (slow, requires server up) when only the critique pass is needed because PNGs already exist.
**Why it happens:** The `--skip-shots` flag exists but is not in MAINTAINERS.md documentation.
**How to avoid:** When PNGs are already captured from the screenshot pass, use `mix scoria.ui.shots --skip-shots --critique`.
**Warning signs:** Console shows Playwright launching when the intent was critique-only.

### Pitfall 5: @doc Backfill Drifts from 12-UI-SPEC

**What goes wrong:** A backfilled `@doc` string describes slot semantics that differ from the locked design contract in `12-UI-SPEC.md`.
**Why it happens:** `@doc` is written from memory without cross-checking the spec.
**How to avoid:** For any `@doc` expansion that describes slot behavior (especially `notebook`, `evidence_section`, `evidence_rows`), cross-check `.planning/phases/12-design-system-component-layer/12-UI-SPEC.md` before committing.
**Warning signs:** A `@doc` says a slot is optional when the component raises on `required: true`.

---

## Runtime State Inventory

This phase is a documentation/proof sweep — no renames, no refactors, no data migrations.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no DB schema or key changes | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | `ANTHROPIC_API_KEY` — required for critique pass only; no name change | None |
| Build artifacts | None | None |

---

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` — treated as enabled.

This is a proof phase, so the validation strategy IS the implementation. The falsifiable checks split into two categories: deterministic (runnable without API key, re-runnable by any maintainer) and non-deterministic audit trail (LLM scores).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (already configured) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/scoria_web/ds06_drift_guard_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test/Proof Map

| Req ID | Behavior | Proof Type | Command / Artifact | Verifiable Without API Key? |
|--------|----------|------------|--------------------|-----------------------------|
| PROOF-01 | P1 resolution checklist: all 11 P1s have concrete code/test evidence | Deterministic checklist in `gap_register_final.md` | `git log` + code review of Phases 14/15/16 commits | Yes |
| PROOF-01 | Per-screen rubric delta table covers all 9 screens | Artifact existence | `priv/shots/gap_register_final.md` committed and contains 9-screen delta | Yes |
| PROOF-01 | Raw-color count = 0 | Executable test | `mix test test/scoria_web/ds06_drift_guard_test.exs` — 3 tests, all green | Yes |
| PROOF-01 | LLM rubric scores show improvement | Non-deterministic audit trail | `gap_register_final.md` §Per-Screen Rubric Delta — scores stamped with date + model | No (requires API key to reproduce) |
| PROOF-02 | Contact-sheet generator is committed and runnable | Artifact existence | `priv/dev/contact_sheet.mjs` exists; `node priv/dev/contact_sheet.mjs --help` | Yes |
| PROOF-02 | `contact_sheet_index.md` is committed with dir pair + delta notes | Artifact existence | `git show priv/shots/contact_sheet_index.md` | Yes |
| PROOF-02 | Generated HTML contact sheet is gitignored | Gitignore check | `git status priv/shots/contact_sheet.html` → should show "nothing to commit" | Yes |
| PROOF-03 | `mix docs` renders complete component catalog | `mix docs` run | `MIX_ENV=dev mix docs && ls doc/ScoriaWeb.UI.html` | Yes |
| PROOF-03 | `docs/MAINTAINERS.md` has catalog section | File content | `grep -n "Design-system component catalog" docs/MAINTAINERS.md` | Yes |
| PROOF-03 | `docs/MAINTAINERS.md` harness section is accurate (includes contact-sheet usage) | File content | Code review of updated harness section | Yes |

### Sampling Rate

- **Per task commit:** `mix test test/scoria_web/ds06_drift_guard_test.exs` (< 2s, no DB needed)
- **Per wave:** `mix test` (full suite)
- **Phase gate:** Full suite green + `priv/shots/gap_register_final.md` committed + `priv/shots/contact_sheet_index.md` committed + `priv/dev/contact_sheet.mjs` committed + `docs/MAINTAINERS.md` updated before `/gsd:verify-work`

### Wave 0 Gaps

None — this phase has no new test files to create. The DS-06 guard already exists and already passes. The validation is artifact-existence and `mix docs` rendering, not new test code.

---

## Security Domain

This phase touches no authentication, session management, access control, cryptography, or network-facing code. The only external call is the Anthropic API for the LLM critique pass, which uses the existing `ReqLLM` + `ANTHROPIC_API_KEY` path already in production. No new security surface is introduced.

ASVS: not applicable — pure documentation + dev tooling phase.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `contact_sheet.mjs`, screenshot pass | Yes | 22.14.0 (verified) | — |
| Playwright | Screenshot capture | Yes | 1.60.0 (verified) | — |
| `ANTHROPIC_API_KEY` | `--critique` pass only | Unknown (env var) | — | Skip critique pass; use `--render-only` if JSON already exists |
| Elixir / Mix | All Mix tasks, `mix docs` | Yes | 1.19.5 / Mix 1.19.5 (verified) | — |
| ExDoc | `mix docs` | Yes | `~> 0.38` in `mix.exs` (verified) | — |
| Dev server + seeded DB | Screenshot capture | Unknown (runtime) | — | Run `mix run priv/repo/dev_seed.exs` + `mix phx.server` |

**Missing dependencies with no fallback:** None — all required tools are installed.

**Missing dependencies with fallback:**
- `ANTHROPIC_API_KEY`: if unavailable, the critique pass cannot run. The deterministic P1 checklist and the DS-06 guard are both API-key-free. The LLM delta scores are the only API-dependent artifact.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExDoc renders `attr`/`slot` declarations as structured documentation within a component's function page | §Component Catalog via ExDoc | If ExDoc does not auto-render Phoenix.Component `attr`/`slot` declarations, the catalog value of `mix docs` is lower; executor may need to add prose to `@doc` strings that reproduce what `attr` would have documented |
| A2 | The contact-sheet HTML uses relative `src` paths for `<img>` tags pointing at sibling PNG files | §Contact-Sheet Generator | If the executor uses absolute paths, the HTML won't render on other machines; use relative paths from the output file's location |
| A3 | Phase 16 specifically addressed the 5 P1 responsive/a11y/density findings on prompts, prompt_release, and eval_specs screens (P1-03 through P1-11) | §Baseline Artifact Structure | If a Phase 16 plan did not in fact address a specific P1 (e.g. density on prompt_release is structural, not responsive/motion-related), the P1 checklist must note the finding differently |

**If this table is empty:** It is not empty. Three assumptions are flagged above. A1 carries medium risk; the executor should run `MIX_ENV=dev mix docs` early and inspect `doc/ScoriaWeb.UI.html` before writing the MAINTAINERS.md catalog section.

---

## Open Questions

1. **Final dated-dir name**
   - What we know: the dir name is `Date.to_iso8601(Date.utc_today())` — the day `mix scoria.ui.shots` is executed.
   - What's unclear: the executor controls the execution date; the dir name is not known until capture day.
   - Recommendation: Plan tasks should use `{final-date}` as a placeholder. `contact_sheet_index.md` fills in the real value after capture.

2. **Does render_gap_register need a --output-path flag to produce gap_register_final.md directly?**
   - What we know: `render_gap_register/2` hardcodes output to `priv/shots/gap_register.md`. Adding a flag would require code change to the Mix task.
   - What's unclear: Is it simpler to hand-author `gap_register_final.md` from the per-screen JSON, or to add `--output-path`?
   - Recommendation: Hand-author `gap_register_final.md` (keep the Mix task unchanged; it is already correct for the rolling baseline use case). The per-screen JSON files provide all the data needed.

3. **Which 11-P1 findings were concretely addressed vs. only partially addressed?**
   - What we know: The 5 responsive/density P1s on prompts/eval_specs/prompt_release map directly to Phase 16 responsive work (16-01 through 16-04) and the `<.table>` conversion (Phase 14). The connectors density P1 maps to Phase 16. The a11y P1s on prompts/eval_specs/prompt_release map to Phase 16 focus-visible work. Flash consistency maps to Phase 12.
   - What's unclear: Density P1s may partially persist if the screen still has very few seed rows visible; the LLM may still flag density as low even with responsive fixes.
   - Recommendation: The P1 checklist should note the concrete code/phase evidence for each item; it should NOT claim the LLM will necessarily score those dimensions higher in the final run (non-determinism). The checklist proves the work was done; the final LLM score is an independent audit.

---

## Sources

### Primary (HIGH confidence)

All findings in this research were verified by direct codebase reads. No external sources were consulted (no new packages, no external APIs to research beyond what is already wired).

- `lib/mix/tasks/scoria.ui.shots.ex` — harness invocation chain, `@screens` list, output paths, `--skip-shots` flag
- `lib/scoria/ui_critique.ex` — model ID (`anthropic:claude-sonnet-4-5`), rubric dimensions, `critique_screen/3` signature
- `priv/shots/gap_register.md` — baseline artifact (2026-06-04): 0 P0 / 11 P1 / 71 passing; all 11 P1 findings verbatim
- `priv/dev/shots.mjs` — PNG naming scheme (`{presence}_{theme}_{viewport}.png`), dated-dir layout, `tenantScoped` manifest
- `priv/shots/.gitignore` — committed files vs gitignored rules
- `lib/scoria_web/ui.ex` (1177 lines) — complete public function inventory, `@doc` coverage assessment
- `mix.exs` — `package.files` exclusions (`priv/dev/`, `priv/shots/` not included), ExDoc dep `~> 0.38`, `docs:` config, `extras:` list
- `test/scoria_web/ds06_drift_guard_test.exs` — three test names, assertions, `@palette_regex`, `@excluded` list
- `test/support/ds06_baseline.txt` — empty (1 line), confirming zero raw-palette headroom
- `docs/MAINTAINERS.md` — harness section confirmed complete and accurate (lines 161–243)
- `.planning/phases/17-consistency-sweep-proof/17-CONTEXT.md` — 13 locked decisions D-01..D-13
- `priv/shots/2026-06-04/` (directory listing) — 9 screen subdirs confirmed, PNG naming verified against `live_ops/` and `prompts/` subdirs

### Secondary (MEDIUM confidence)

- `.planning/REQUIREMENTS.md` — PROOF-01/02/03 definitions
- `.planning/ROADMAP.md` — Phase 17 goal and success criteria
- `.planning/STATE.md` — current milestone state
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` — DS-06 ratchet design; D-04 "Phase 17 deletes the baseline file entirely" note (now resolved: baseline is empty, not deleted)

---

## Metadata

**Confidence breakdown:**
- Harness re-run mechanics: HIGH — verified by reading source files
- Baseline P1 findings: HIGH — read verbatim from `gap_register.md`
- Contact-sheet generator design: HIGH for interface/gitignore; MEDIUM for HTML output format (planner/executor discretion)
- ExDoc component catalog: HIGH for inventory; ASSUMED for Phoenix.Component `attr`/`slot` auto-rendering in ExDoc (A1)
- DS-06 citation: HIGH — read test file and baseline directly

**Research date:** 2026-06-13
**Valid until:** This research reads committed code; it remains valid until the codebase changes. The LLM model ID (`anthropic:claude-sonnet-4-5`) is the current `@default_model` as of this research date.
