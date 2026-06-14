---
phase: 17-consistency-sweep-proof
plan: "03"
subsystem: design-system-docs
tags: [documentation, exdoc, design-system, maintainers]
dependency_graph:
  requires: []
  provides: [PROOF-03]
  affects: [lib/scoria_web/ui.ex, docs/MAINTAINERS.md]
tech_stack:
  added: []
  patterns: [ExDoc @doc backfill, MAINTAINERS.md section extension]
key_files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - docs/MAINTAINERS.md
decisions:
  - "@doc multi-line strings use a compact prose style (not triple-quote heredoc) matching the existing ui.ex rich @doc pattern (modal/1, field/1, toast/1, id/1)"
  - "Design-system catalog section placed immediately before the Screenshot + Critique Harness section in MAINTAINERS.md"
  - "Components at a glance table noted as glance index, not SSOT — SSOT lives in code via mix docs"
metrics:
  duration: "2 minutes"
  completed: "2026-06-13T15:56:02Z"
  tasks: 2
  files: 2
---

# Phase 17 Plan 03: Design-system @doc backfill + MAINTAINERS catalog Summary

## One-liner

Backfilled 7 sparse `@doc` strings in `ScoriaWeb.UI` with multi-line ExDoc entries and added a `## Design-system component catalog` section to `docs/MAINTAINERS.md` pointing to `mix docs` as the SSOT.

## What Was Built

### Task 1: Backfill 7 sparse @doc strings in lib/scoria_web/ui.ex

Expanded the following single-liner `@doc` attributes to multi-line catalog entries mirroring the `modal/1`, `field/1`, `toast/1`, and `id/1` rich-@doc pattern:

**Tier 1 (full multi-line with attrs/slots):**
- `attention_card/1` — purpose (Status Home attention strip), attrs (count, label, detail, cta, path, tone), renders `<a>` tag (path, not click handler)
- `evidence_section/1` — notebook `:tab` slot context, attrs (title, description, tone, badge), `:actions` slot, `:inner_block` for rows/action rows
- `evidence_rows/1` — `%{label:, value:}` map / `{label, value}` tuple input, normalized by `normalize_evidence_rows/1`, renders `<dl>/<dt>/<dd>`

**Tier 2 (light context addition):**
- `eyebrow/1` — panel headers, object headers, card hierarchy labeling
- `kbd/1` — command palette rows and help text inline key bindings
- `evidence_action_row/1` — per-section action links in evidence panels
- `evidence_empty/1` — empty `:tab` panels in `<.notebook>`, `:title` required

`@moduledoc` and the ~23 already-adequate `@doc`s are untouched.

### Task 2: Add Design-system component catalog section to docs/MAINTAINERS.md

Added `## Design-system component catalog` immediately before the existing `## Screenshot + Critique Harness (dev-only)` section, containing:
- Framing paragraph: `ScoriaWeb.UI` as single enforced token gateway, DS-06 guard reference
- "Components at a glance" table covering all 28 public `ui.ex` components with one-line purposes
- Note that the table is a glance index, not the SSOT
- "Full attribute/slot reference" subsection: `MIX_ENV=dev mix docs` command, `doc/ScoriaWeb.UI.html` pointer
- "Raw-palette drift protection" subsection: `mix test test/scoria_web/ds06_drift_guard_test.exs`, three-assertion description, empty baseline note

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 304615e | docs(17-03): backfill 7 sparse @doc strings in ScoriaWeb.UI |
| Task 2 | fa33a68 | docs(17-03): add Design-system component catalog section to MAINTAINERS.md |

## Verification Results

- `mix docs` exits 0; `doc/ScoriaWeb.UI.html` generated
- `mix test test/scoria_web/ds06_drift_guard_test.exs` — 3 tests, 0 failures
- `docs/MAINTAINERS.md` contains `## Design-system component catalog`, `mix docs`, `ds06_drift_guard_test`
- `docs/design_system.md` does NOT exist
- `git diff` on `ui.ex` touches only the 7 named functions' @docs (7 `+@doc` lines, 7 `-@doc` lines; moduledoc + other @docs untouched)
- `## Screenshot + Critique Harness (dev-only)` section intact and unmodified

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. This plan is documentation-only. No data sources, UI rendering, or runtime behavior changed.

## Threat Flags

None. Documentation-only plan: no new routes, no runtime code, no auth surface, no new dependencies. T-17-06 mitigated (DS-06 guard green). T-17-07 accepted (component names + `mix docs` usage; no secrets).

## Self-Check: PASSED

- `lib/scoria_web/ui.ex` modified: confirmed (7 @doc expansions)
- `docs/MAINTAINERS.md` modified: confirmed (catalog section added)
- `docs/design_system.md` absent: confirmed
- Commit 304615e exists: confirmed
- Commit fa33a68 exists: confirmed
- `mix docs` exits 0: confirmed
- DS-06 guard 3/3 green: confirmed
