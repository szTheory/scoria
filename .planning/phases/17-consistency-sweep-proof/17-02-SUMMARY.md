---
phase: 17-consistency-sweep-proof
plan: "02"
subsystem: proof-artifacts
tags: [proof, contact-sheet, dev-tooling, documentation]
dependency_graph:
  requires: [17-01]
  provides: [priv/dev/contact_sheet.mjs, priv/shots/contact_sheet_index.md, MAINTAINERS-contact-sheet-subsection]
  affects: [PROOF-02]
tech_stack:
  added: []
  patterns: [committed-generator-over-gitignored-html, paired-png-readdir, before-after-arg-cli]
key_files:
  created:
    - priv/dev/contact_sheet.mjs
    - priv/shots/contact_sheet_index.md
  modified:
    - docs/MAINTAINERS.md
decisions:
  - "*.html gitignore rule already present from Plan 17-01 — no duplicate addition needed"
  - "Generator uses plain Node.js fs/path only (no Playwright) — relative img src paths via path.relative so HTML renders on any machine"
  - "7 screens baseline-only (pre-existing Phase 13 modal overlay timeout) — rendered as explicit placeholder in HTML, accurately documented in index as 'not re-captured'"
  - "Non-tenant-scoped screens (reviews, eval_specs, prompts, prompt_release, workflows) have empty_* skip logic in generator matching shots.mjs tenantScoped manifest"
  - "contact_sheet_index.md covers all 9 screens — 2 paired (live_ops, approvals), 7 baseline-only with per-phase improvement notes"
metrics:
  duration: "~3 minutes"
  completed: "2026-06-13T16:20:17Z"
  tasks: 2
  files: 3
---

# Phase 17 Plan 02: Contact-Sheet Generator + Index (PROOF-02) Summary

Committed `priv/dev/contact_sheet.mjs` (before/after HTML grid generator, `--before/--after/--out` CLI, plain Node.js, no Playwright) and `priv/shots/contact_sheet_index.md` (baseline 2026-06-04 vs final 2026-06-13, 9-screen delta notes table, regenerate command); appended "Contact-sheet generation" subsection to the existing MAINTAINERS harness section.

## Tasks Completed

| # | Task | Commit | Key Deliverable |
|---|------|--------|-----------------|
| 1 | Write priv/dev/contact_sheet.mjs generator | c5cc4af | 338-line generator; `--before/--after/--out`; graceful missing-screen handling; no Playwright |
| 2 | Generate contact sheet, author index, document in MAINTAINERS | 361e0f4 | `contact_sheet_index.md` (9 screens, 2 paired, 7 baseline-only); MAINTAINERS harness subsection |

## What Was Built

### `priv/dev/contact_sheet.mjs`

Plain Node.js (`fs/promises`, `fs`, `path`) before/after contact-sheet generator modeled on `priv/dev/shots.mjs`:

- `parseArgs(argv)` shape mirrors shots.mjs — `{ before, after, out }` with default `out = priv/shots/contact_sheet.html`; exits 1 with error if `--before` or `--after` is missing
- `SCREENS` manifest (9 entries with `tenantScoped` flags) mirrors shots.mjs — non-tenant-scoped screens skip `empty_*` pairs matching harness behavior
- Core: `readdir` both dirs, build `{screen}/{filename}` sets, pair by filename; screens missing from `--after` dir render an explicit "not re-captured" placeholder (no crash)
- `<img src>` paths are relative via `path.relative(dirname(out), targetFile)` — HTML renders on any machine (Assumption A2)
- `main().catch(...)` entry-point guard
- No Playwright import; `mix.exs` untouched

### `priv/shots/contact_sheet_index.md`

Committed index recording:
- Baseline dir: `priv/shots/2026-06-04`, Final dir: `priv/shots/2026-06-13`, Generated: 2026-06-13
- Per-screen delta notes table (9 screens): 2 paired (`live_ops`, `approvals` — 8 PNGs each), 7 baseline-only (Phase 13 modal overlay timeout pre-existing deferred item)
- Phase improvement notes per screen (Phases 12–16 cited)
- "How to Regenerate" fenced block with exact command and future-milestone substitution note
- No API keys, secrets, or tenant PII

### `docs/MAINTAINERS.md` — "Contact-sheet generation" subsection

Appended after "Dev-only posture summary" in the existing "Screenshot + Critique Harness" section (D-11). Documents:
- `node priv/dev/contact_sheet.mjs --before … --after … --out …` command
- HTML is gitignored (`*.html`); `contact_sheet_index.md` (committed) records the dir pair
- Future milestone note (no code change needed)

### Gitignore posture

`*.html` rule was already present in `priv/shots/.gitignore` (added by Plan 17-01). `git check-ignore priv/shots/contact_sheet.html` exits 0. No change to `.gitignore` was needed.

## Deviations from Plan

### Auto-noted (no fix needed)

**1. `*.html` .gitignore sub-task already satisfied by Plan 17-01**
- **Found during:** Pre-execution file read of `priv/shots/.gitignore`
- **Issue:** Plan 17-01 already added `*.html` rule with comment; the Task 1 sub-task was a no-op
- **Action:** Verified rule present, treated as done — did not duplicate the line
- **Files modified:** None (`.gitignore` unchanged in this plan)

### No architectural changes. No new dependencies.

## Verification Results

| Check | Result |
|-------|--------|
| `node --check priv/dev/contact_sheet.mjs` | PASS (syntax valid) |
| `node priv/dev/contact_sheet.mjs` (no args) exits 1, mentions `--before` | PASS |
| No Playwright import in contact_sheet.mjs | PASS |
| `git check-ignore priv/shots/contact_sheet.html` | PASS (exits 0) |
| `priv/shots/contact_sheet_index.md` exists, contains `contact_sheet.mjs` | PASS |
| Index records `2026-06-04` baseline dir | PASS |
| Index records `2026-06-13` final dir | PASS |
| Index covers all 9 screens | PASS (2 paired, 7 baseline-only) |
| `grep "Contact-sheet generation" docs/MAINTAINERS.md` | PASS |
| No API key / secret / PII in index or MAINTAINERS subsection | PASS |
| `git diff --quiet mix.exs` | PASS (unchanged) |

## Known Stubs

None. The `contact_sheet_index.md` accurately states which screens are paired vs baseline-only. The "not re-captured" entries are accurate descriptions of the partial final dir — not stubs.

## Threat Flags

None. T-17-03 (HTML gitignored) verified. T-17-04 (no PII in index/docs) verified. T-17-05 (mix.exs unchanged) verified.

## Outputs for Downstream Plans

- `priv/dev/contact_sheet.mjs` committed — re-runnable for future milestone passes with new `--before/--after` dirs
- `priv/shots/contact_sheet_index.md` committed — baseline/final dir pair + per-screen delta notes on record
- `docs/MAINTAINERS.md` updated — harness section now includes contact-sheet generation command

## Self-Check: PASSED

Files verified:
- `priv/dev/contact_sheet.mjs` — FOUND (c5cc4af)
- `priv/shots/contact_sheet_index.md` — FOUND (361e0f4)
- `docs/MAINTAINERS.md` contains "Contact-sheet generation" — FOUND (361e0f4)

Commits verified:
- `c5cc4af` — feat(17-02): add priv/dev/contact_sheet.mjs — FOUND
- `361e0f4` — feat(17-02): add contact_sheet_index.md + document generator in MAINTAINERS harness section — FOUND
