# Phase 17: Consistency Sweep + Proof — Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/shots/gap_register_final.md` | report/artifact | transform (JSON → markdown) | `priv/shots/gap_register.md` | exact |
| `priv/dev/contact_sheet.mjs` | utility | file-I/O (read PNGs → write HTML) | `priv/dev/shots.mjs` | role-match |
| `priv/shots/contact_sheet_index.md` | report/artifact | static (hand-authored markdown) | `priv/shots/gap_register.md` | role-match |
| `priv/shots/.gitignore` | config | — | `priv/shots/.gitignore` (self) | exact |
| `lib/scoria_web/ui.ex` | component library | request-response | `lib/scoria_web/ui.ex` (self — backfill only) | exact |
| `docs/MAINTAINERS.md` | documentation | — | `docs/MAINTAINERS.md` (self — extend) | exact |

---

## Pattern Assignments

### `priv/shots/gap_register_final.md` (report, transform)

**Analog:** `priv/shots/gap_register.md`

**Document header pattern** (lines 1–8):
```markdown
# Design-System Gap Register — Baseline 2026-06-04

## Summary
- Screens audited: 9
- P0 issues (score 1): 0
- P1 issues (score 2): 11
- Passing (score ≥ 3): 71
```

**For gap_register_final.md the header becomes:**
```markdown
# Design-System Gap Register — Final {YYYY-MM-DD}

**Run date:** {YYYY-MM-DD}
**Model:** anthropic:claude-sonnet-4-5
**Baseline:** priv/shots/gap_register.md (2026-06-04)
**Final shots:** priv/shots/{final-date}/

## Summary
- Baseline: 0 P0 / 11 P1 / 71 passing
- Final: 0 P0 / {N} P1 / {M} passing
- Net improvement: {11-N} P1 findings resolved
```

**Ranked Findings section pattern** (lines 9–79 of gap_register.md):
```markdown
## Ranked Findings (worst first)

### {screen} — {dimension}: {score}/5
> {finding text, multiline allowed, > prefix on each line}
```

**For gap_register_final.md the delta table replaces the ranked findings:**
```markdown
## Per-Screen Rubric Delta

| Screen | Dimension | Baseline | Final | Change |
|--------|-----------|----------|-------|--------|
| all-screens (flash) | consistency | 2/5 | 5/5 | +3 |
| connectors | density | 2/5 | {score}/5 | {delta} |
| eval_specs | a11y | 2/5 | {score}/5 | {delta} |
| eval_specs | density | 2/5 | {score}/5 | {delta} |
| eval_specs | responsive | 2/5 | {score}/5 | {delta} |
| prompt_release | a11y | 2/5 | {score}/5 | {delta} |
| prompt_release | density | 2/5 | {score}/5 | {delta} |
| prompt_release | responsive | 2/5 | {score}/5 | {delta} |
| prompts | a11y | 2/5 | {score}/5 | {delta} |
| prompts | density | 2/5 | {score}/5 | {delta} |
| prompts | responsive | 2/5 | {score}/5 | {delta} |
```

**Fix Backlog table pattern** (lines 81–95 of gap_register.md):
```markdown
## Fix Backlog (prioritized)
| Priority | Screen | Dimension | Action |
|----------|--------|-----------|--------|
| P1 | all-screens (flash) | consistency | flash_tone_class/1 (lib/scoria_web/ui.ex) renders flash banners with raw palette |
```

**For gap_register_final.md two additional sections are appended after the delta table:**

Section 2 — Deterministic P1 resolution checklist (copy this exact structure per finding):
```markdown
## Deterministic 11-P1 Resolution Checklist

> This checklist requires no API key. Each item is verifiable by code review or `mix test`.

- [x] P1-01 all-screens (flash) / consistency: `flash_tone_class/1` removed; `flash_group/1`
      now emits `scoria-flash--{tone}` BEM classes with no raw palette classes.
      Evidence: `lib/scoria_web/ui.ex` `flash_group/1`; DS-06 guard green.
      Resolving phase: Phase 12.

- [x] P1-02 connectors / density: shared `<.empty_state>` component with responsive padding
      replaces the fixed-height empty layout.
      Evidence: Phase 16 mobile-first shell (16-01-PLAN.md).
      Resolving phase: Phase 16.
```
_(Continue for all 11 P1s using the table in RESEARCH.md §Baseline Artifact Structure.)_

Section 3 — Raw-color-zero assertion (copy verbatim from RESEARCH.md §DS-06 Raw-Color-Zero Citation):
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

**Gitignore impact:** None. The file is a `.md` at `priv/shots/` root. Existing rules (`*/`, `*.png`, `*.json`) do not touch it. It commits cleanly like `gap_register.md`.

---

### `priv/dev/contact_sheet.mjs` (utility, file-I/O)

**Analog:** `priv/dev/shots.mjs`

**File header / JSDoc block pattern** (shots.mjs lines 1–14):
```javascript
/**
 * priv/dev/contact_sheet.mjs — Scoria before/after contact-sheet generator
 *
 * Reads dated PNG capture dirs and emits an HTML grid for visual before/after
 * comparison. Gitignored output; committed generator.
 *
 * Usage:
 *   node priv/dev/contact_sheet.mjs \
 *     --before priv/shots/2026-06-04 \
 *     --after priv/shots/<final-date> \
 *     --out priv/shots/contact_sheet.html
 *
 * No Playwright dependency — plain Node.js fs/path only.
 */
```

**Import block pattern** (shots.mjs lines 16–20):
```javascript
import { chromium } from 'playwright';
import { mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import { join } from 'path';
```

For contact_sheet.mjs, only `fs/promises`, `fs`, and `path` are needed (no Playwright):
```javascript
import { readdir, readFile, writeFile } from 'fs/promises';
import { existsSync } from 'fs';
import { join, relative, dirname } from 'path';
import { fileURLToPath } from 'url';
```

**Arg-parsing pattern** (shots.mjs lines 26–65) — copy the `parseArgs(argv)` function shape exactly:
```javascript
function parseArgs(argv) {
  const args = argv.slice(2);
  const result = {
    before: null,
    after: null,
    out: 'priv/shots/contact_sheet.html',
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--before':
        result.before = args[++i];
        break;
      case '--after':
        result.after = args[++i];
        break;
      case '--out':
        result.out = args[++i];
        break;
      default:
        console.error(`Unknown argument: ${args[i]}`);
        process.exit(1);
    }
  }

  if (!result.before || !result.after) {
    console.error('Error: --before and --after are required');
    process.exit(1);
  }

  return result;
}
```

**Screen manifest pattern** (shots.mjs lines 90–170) — non-tenant-scoped screens have `tenantScoped: false`:
```javascript
const SCREENS = [
  { name: 'live_ops', tenantScoped: true },
  { name: 'approvals', tenantScoped: true },
  { name: 'workflows', tenantScoped: false },
  { name: 'incidents', tenantScoped: true },
  { name: 'connectors', tenantScoped: true },
  { name: 'reviews', tenantScoped: false },
  { name: 'eval_specs', tenantScoped: false },
  { name: 'prompts', tenantScoped: false },
  { name: 'prompt_release', tenantScoped: false },
];
```

The generator uses this to know which screens have empty-state pairs and which only have `populated_*` captures.

**Error-handling pattern** (shots.mjs lines 59–65 and main() guard):
```javascript
if (!result.outDir) {
  console.error('Error: --out-dir is required');
  process.exit(1);
}
```

**Main async entry-point pattern** (shots.mjs — implied by module structure):
```javascript
async function main() {
  const args = parseArgs(process.argv);
  // ... core logic
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
```

**PNG naming scheme to match** (shots.mjs `captureScreen`, verified by research): Files are named `{presence}_{theme}_{viewport}.png` — e.g. `populated_dark_desktop.png`, `empty_light_mobile.png`. The generator pairs by `{screen}/{filename}` path.

---

### `priv/shots/contact_sheet_index.md` (report, static)

**Analog:** `priv/shots/gap_register.md`

**Header + metadata block pattern** (gap_register.md lines 1–8):
```markdown
# Design-System Gap Register — Baseline 2026-06-04

## Summary
- Screens audited: 9
...
```

For contact_sheet_index.md, apply the same style:
```markdown
# Contact Sheet Index — v3.0 Control Room Milestone Close

**Baseline dir:** priv/shots/2026-06-04
**Final dir:** priv/shots/{final-date}
**Generated:** {YYYY-MM-DD}

## Per-Screen Delta Notes

| Screen | State | Baseline File | Final File | Notes |
|--------|-------|---------------|------------|-------|
| live_ops | populated_dark_desktop | 2026-06-04/live_ops/populated_dark_desktop.png | {final-date}/live_ops/populated_dark_desktop.png | Mobile nav, focus indicators |
| approvals | populated_dark_desktop | ... | ... | Modal overlay; responsive shell |
...
```

*(Non-tenant-scoped screens — reviews, eval_specs, prompts, prompt_release — only list `populated_*` rows, not `empty_*`. Note this explicitly in the index.)*

**How-to-regenerate section pattern** — MAINTAINERS.md uses fenced code blocks inside section headings; use the same convention:
```markdown
## How to Regenerate

    node priv/dev/contact_sheet.mjs \
      --before priv/shots/2026-06-04 \
      --after priv/shots/{final-date} \
      --out priv/shots/contact_sheet.html

For future milestone passes, substitute the new baseline and final dirs.
```

**Gitignore impact:** None. The file is a committed `.md` at `priv/shots/` root, same posture as `gap_register.md`.

---

### `priv/shots/.gitignore` (config, modify)

**Analog:** `priv/shots/.gitignore` (self — minimal extension)

**Current file** (lines 1–16, read directly):
```gitignore
# Screenshot harness outputs (PNG captures and JSON critique results are transient
# dev-only artifacts). Only gap_register.md is committed to the repository.
#
# Pattern rationale:
#   */        — ignores all date-stamped capture subdirectories (e.g. 2026-06-04/)
#   *.png     — ignores all screenshot captures at any nesting depth
#   *.json    — ignores all per-screen critique findings JSON files
#
# gap_register.md is tracked because it is the committed baseline audit output
# (EVAL-03 / PROOF-03). It is explicitly negated below to override the *.md rule
# if one were ever added, and it is not matched by any of the rules above.

*/
*.png
*.json
!gap_register.md
```

**Change:** Add one line — `*.html` — to gitignore the generated `contact_sheet.html`. Add it after `*.json` in the same pattern block, with a matching comment. The two new committed `.md` files (`contact_sheet_index.md`, `gap_register_final.md`) are NOT caught by any existing rule and need no negation — they are safe by omission:

```gitignore
*/
*.png
*.json
*.html
!gap_register.md
```

Update the comment block to add:
```
#   *.html    — ignores generated contact-sheet HTML (contact_sheet.html)
```

---

### `lib/scoria_web/ui.ex` (component library, backfill `@doc`)

**Analog:** `lib/scoria_web/ui.ex` (self — the well-documented components are the pattern)

**Single-line @doc pattern to AVOID expanding** (adequate, no change needed):
```elixir
@doc "Status badge. Always renders a text label alongside color (a11y: never color-alone)."
def badge(assigns) do
```

**Multi-line @doc pattern to COPY** — `modal/1` (lines 421–424):
```elixir
@doc "Slot-based modal dialog shell (DS-02).
Renders nothing when show=false. When show=true, renders a scrim + panel with
a consistent triple dismiss contract: close button + scrim click + Escape key.
The caller owns all dismiss events via on_dismiss."
def modal(assigns) do
```

**Multi-line @doc pattern to COPY** — `field/1` (lines 530–535):
```elixir
@doc "Form field wrapper (DS-03).
Renders a label + caller-provided input slot + optional help text + validation error.
Error is surfaced via an exclamation icon + text (never error by color alone).
Required fields include an aria-hidden asterisk and a visually-hidden '(required)' span.
The caller provides the actual input/select/textarea element via the inner_block slot."
def field(assigns) do
```

**Multi-line @doc pattern to COPY** — `toast/1` (lines 596–601):
```elixir
@doc "Transient toast notification (DS-05).
Driven by a server @toasts assign. Auto-dismisses via phx-mounted={JS.hide(...)}.
Manual dismiss X button is also provided. Does NOT use a JS hook (untestable in LiveViewTest).
The phx-mounted auto-dismiss omits 'to:' so it self-targets the toast div (Pitfall 3);
the dismiss button MUST target the toast by id (to: '#id') — a bare JS.hide there would
hide the button, not the toast."
def toast(assigns) do
```

**Multi-line @doc pattern to COPY** — `id/1` (lines 159–164):
```elixir
@doc "Copyable monospace identifier (run/trace/actor IDs). Uses the CopyId JS hook.

The DOM id must be stable across renders so LiveView/morphdom patches the existing
element in place rather than tearing down and re-mounting the CopyId hook. When no
caller-supplied id is given it is derived deterministically from the displayed value;
prefer passing an explicit id where two identical values can appear on one page."
def id(assigns) do
```

**Target components for backfill** (Tier 1 — needs multi-line @doc, currently terse single-line):

`attention_card/1` — current (line 186):
```elixir
@doc "Status Home attention card for nonzero actionable states."
def attention_card(assigns) do
```
Expand to cover: purpose (Status Home strip), attrs (count, label, detail, cta, path, tone), and that it renders an `<a>` tag (callers pass a path, not a click handler).

`evidence_section/1` — current (line 803):
```elixir
@doc "Notebook-scoped evidence section with optional status badge and action slot."
def evidence_section(assigns) do
```
Expand to cover: usage context (inside `<.notebook>` `:tab` slot panels), attrs (title, description, tone, badge), `:actions` slot for action buttons, `:inner_block` for evidence rows/action rows.

`evidence_rows/1` — current (line 830):
```elixir
@doc "Stable key-value evidence rows for adapter-projected values."
def evidence_rows(assigns) do
```
Expand to cover: input format for the `:rows` attr (list of `%{label: ..., value: ...}` maps or `{label, value}` tuples — normalized by `normalize_evidence_rows/1`), and that it renders a `<dl>` with `<dt>/<dd>` pairs.

**Target components for backfill** (Tier 2 — light addition):

`eyebrow/1` — current (line 105):
```elixir
@doc "Small uppercase category/status label (brand book card eyebrow)."
def eyebrow(assigns) do
```
Add: used in panel headers, object headers, and card hierarchy labeling.

`kbd/1` — add: used inline in command palette rows and help text.

`evidence_action_row/1` — current (line 848):
```elixir
@doc "Compact evidence action/link row. Callers own the action/link semantics."
def evidence_action_row(assigns) do
```
Add: used for per-section action links (e.g. "View trace", "Open replay") in evidence panels.

`evidence_empty/1` — current (line 862):
```elixir
@doc "Notebook-scoped evidence empty state."
def evidence_empty(assigns) do
```
Add: used for empty `:tab` slot panels in `<.notebook>` when no evidence data is available; `:title` attr is required.

**@moduledoc** (lines 2–11) — already complete and accurate; no change needed:
```elixir
@moduledoc """
Scoria's shared dashboard component vocabulary.

Function components emit the brand-book semantic classes (see `assets/css/04-components.css`)
driven entirely by design tokens. This is the single home for tone/status → color mapping,
replacing the per-component `badge_class/status_color/trace_badge_class/flash_kind_class`
helpers that previously drifted across the codebase.

Import into a LiveView/component with `import ScoriaWeb.UI`.
"""
```

---

### `docs/MAINTAINERS.md` (documentation, extend)

**Analog:** `docs/MAINTAINERS.md` (self — extend two sections)

**Existing "Screenshot + Critique Harness" section structure** (lines 161–243) — use as the pattern for the new "Design-system component catalog" section. Section anatomy:
```markdown
## {Section Title} (qualifier)

{One-sentence purpose framing.} It {does X}. It is **{qualifier}**: {constraint}.

### Prerequisites

1. **{Tool}** — {requirement note}. {Verify: command}

### {Subsection 1}

{Context sentence.}

```bash
{command}
```

### {Subsection 2 — optional flags}

```bash
{flag usage}
```

### {Qualifier/limitation note}

**{Screen name}**, **{Screen name}**, ... do not support ... — they {behavior}. ...

### {Posture summary}

- `{path}` is **{committed/gitignored}** ({rationale}).
- ...
```

**New section to ADD — "Design-system component catalog"** — model on the harness section above:
```markdown
## Design-system component catalog

`ScoriaWeb.UI` is the single enforced token gateway for all dashboard UI components.
Every function component emits brand-book semantic classes (`assets/css/04-components.css`)
driven by design tokens; raw Tailwind palette classes (`bg-rose-200`, etc.) are blocked
in `lib/scoria_web/ui.ex` by `test/scoria_web/ds06_drift_guard_test.exs`.

### Components at a glance

| Component | Purpose |
|-----------|---------|
| `badge/1` | Status badge — tone + label, never color-alone |
| `button/1` | Primary / ghost / danger button (brand book §8.5) |
| `eyebrow/1` | Small uppercase category/status label |
| `panel/1` | Panel/card surface with optional eyebrow + title + actions header |
| `metric/1` | Metric card: label, big value, explicit delta (brand book §11.3) |
| `id/1` | Copyable monospace identifier — CopyId JS hook |
| `attention_card/1` | Status Home actionable-state card |
| `object_header/1` | Object-detail page header |
| `stub_page/1` | Placeholder page for unimplemented screens |
| `kbd/1` | Keyboard shortcut chip |
| `command_palette/1` | Client-side filtered command palette |
| `empty_state/1` | Empty-state placeholder with optional action |
| `modal/1` | Slot-based modal dialog (DS-02) |
| `drawer/1` | Slot-based drawer panel (DS-02) |
| `field/1` | Form field wrapper (DS-03) |
| `form_section/1` | Form section group (DS-03) |
| `skeleton/1` | Loading skeleton placeholder (DS-05) |
| `toast/1` | Transient toast notification (DS-05) |
| `notebook/1` | Tabbed evidence notebook (DS-04) |
| `raw_evidence/1` | Raw evidence details/pre block (DS-04) |
| `evidence_section/1` | Notebook-scoped evidence section |
| `evidence_rows/1` | Key-value evidence rows |
| `evidence_action_row/1` | Compact evidence action/link row |
| `evidence_empty/1` | Notebook-scoped evidence empty state |
| `table/1` | Sortable, density-aware, paginated data table (DS-01) |
| `flash_group/1` | Flash notification group (DS-05) |
| `tone/1` | Utility: maps status string/atom → semantic tone atom |
| `status_label/1` | Utility: human-readable label for a status string |

### Full attribute/slot reference

```bash
MIX_ENV=dev mix docs
```

The rendered catalog lives in `doc/` (gitignored; standard Elixir ExDoc output).
Open `doc/ScoriaWeb.UI.html` for the full component reference including all `attr`
and `slot` declarations.

### Raw-palette drift protection

```bash
mix test test/scoria_web/ds06_drift_guard_test.exs
```

Three assertions guard `ui.ex` zero-tolerance and enforce the ratchet across all
`lib/scoria_web/` files. `test/support/ds06_baseline.txt` is empty — any raw palette
class introduction fails `mix test` automatically.
```

**Existing harness section extension** — append a "Contact-sheet generation" subsection at line 243 (after the dev-only posture summary). Pattern from the existing optional-flags subsection:
```markdown
### Contact-sheet generation

After capturing two dated shot sets, generate the before/after contact sheet:

```bash
node priv/dev/contact_sheet.mjs \
  --before priv/shots/2026-06-04 \
  --after priv/shots/<final-date> \
  --out priv/shots/contact_sheet.html
```

The generated HTML is gitignored (`*.html` in `priv/shots/.gitignore`).
`priv/shots/contact_sheet_index.md` (committed) records the dir pair and per-screen delta notes.
For future milestone passes, substitute new baseline and final dirs — no code changes needed.
```

**mix.exs `package.files` — no change needed:**
```elixir
# priv/dev intentionally excluded — shots.mjs (screenshots) and e2e/ (the
# Playwright assertion lane) are dev-only harness tooling, not for adopters
# (D-01: zero Hex footprint for browser automation tooling). Do NOT add a
# priv/dev entry here — it would ship Playwright specs + node tooling.
# priv/shots intentionally excluded — screenshot captures are transient
# dev-only artifacts; only gap_register.md is committed (per .gitignore rules).
```
`priv/dev/` and `priv/shots/` are already fully excluded from `package.files` (lines 159–164 of mix.exs). `contact_sheet.mjs` (in `priv/dev/`) and `contact_sheet_index.md` / `gap_register_final.md` (in `priv/shots/`) are automatically excluded. No mix.exs edits required.

---

## Shared Patterns

### Committed dev artifact posture
**Source:** `priv/shots/.gitignore` + `mix.exs` lines 159–164
**Apply to:** All new files in `priv/dev/` and `priv/shots/`

Rule: generated/transient outputs (PNGs, JSON, HTML) are gitignored; committed tooling (`.mjs`) and committed markdown reports (`.md`) are tracked. Package exclusion is inherited — no `mix.exs` edits needed.

### Brand voice for new copy
**Source:** `brandbook/brand-book.md` (referenced in CONTEXT.md canonical refs)
**Apply to:** `gap_register_final.md`, `contact_sheet_index.md`, `docs/MAINTAINERS.md` additions

Convention: calm, exact, useful — no hype, no anthropomorphism, operator-evidence framing. The existing harness section in `docs/MAINTAINERS.md` (lines 161–243) is the reference tone for new documentation prose in this phase.

### Section heading hierarchy in MAINTAINERS.md
**Source:** `docs/MAINTAINERS.md` — `##` for top-level sections, `###` for subsections, bold + inline code for tool names and paths. Code blocks use triple-backtick fences or 4-space indent for shell commands (the existing harness section uses both — prefer triple-backtick fences for commands with flags).

---

## No Analog Found

None. All new/modified files have a close analog in the codebase.

---

## Metadata

**Analog search scope:** `priv/shots/`, `priv/dev/`, `lib/scoria_web/`, `docs/`, `mix.exs`
**Files scanned:** 7 (gap_register.md, .gitignore, shots.mjs, ui.ex, MAINTAINERS.md, mix.exs — plus CONTEXT.md and RESEARCH.md for scope)
**Pattern extraction date:** 2026-06-13
