---
phase: 40-accessibility-motion-and-responsive-proof
plan: 02
subsystem: testing
tags: [exunit, source-scan, motion, a11y, drift-guard]

# Dependency graph
requires: []
provides:
  - "test/scoria_web/motion_drift_guard_test.exs — browserless MOTION-01 tokenization/keyframe source-scan guard (5 assertions)"
  - "test/scoria_web/a11y_structural_guard_test.exs — browserless A11Y-01/A11Y-02 structural-presence source-scan guard (8 assertions)"
affects: [40-03-drawer-modal-focus, 40-04-axe-scan-and-responsive-scan, 40-05-consistency-sweep]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Motion guard allow-list keyed on animation NAME (scoria-skeleton-pulse, scoria-approval-pulse), not the literal duration string, so a future duration edit on either D-20/D-21 exception cannot silently defeat the guard."
    - "@keyframes body extraction via balanced-brace byte scanning (not a naive non-greedy regex), since a keyframes block nests its own `0%, 100% { ... }` rule braces one level deep."
    - "Regex :index offsets are BYTE offsets — window/extraction helpers use binary_part/3, never String.slice/3, to avoid desync when a multi-byte UTF-8 character (en dash, arrow) appears earlier in the source file."
    - "CSS comment-stripping (`/\\*.*?\\*/`) before any count-based regex scan, so header/prose mentions of a banned pattern inside a doc comment cannot self-invalidate a count gate (grep-gate hygiene, T-40-02 mitigation)."

key-files:
  created:
    - test/scoria_web/motion_drift_guard_test.exs
    - test/scoria_web/a11y_structural_guard_test.exs
  modified: []

key-decisions:
  - "The a11y guard's 'real button/a sort/filter controls' assertion is scoped to the `<:filter>` slot only (verified true today via `<.link>`/`<select>`/`<form>` in approval_inbox_component.ex and review_queue_live.ex), not the table's `<th phx-click aria-sort>` column-sort trigger. The sort trigger is not literally a `<button>` element on the current tree — asserting that would make the guard red on landing day, contradicting this plan's explicit must_haves.truths (warning-grade, prove-only-the-already-green-baseline) and its files_modified scope (test files only, no ui.ex change). This is a scoping judgment call, not a defect fix — if Phase 41 or a later plan wants the sort trigger converted to a real `<button>` inside the `<th>` (the WAI-ARIA APG sortable-table pattern), that is in-scope internal wiring (no attr/slot change) for whichever plan owns table/1 changes, not this guard-authoring plan."
  - "Native-semantics dialog check asserts role=\"dialog\" pairs with aria-modal=\"true\" only (not phx-key=\"Escape\" presence), because two of the five current dialog-role elements (the mobile-nav drawer and keyboard-shortcuts overlay in app.html.heex) are JS-hook-driven (scoria.js Dismissable pattern) with no phx-key attribute at all — asserting Escape-key-attribute presence would false-RED on those two already-accessible overlays. Actual Escape-closes-it behavior is Playwright's job (D-12 browserless-vs-browser line), not this source-scan guard's."

requirements-completed: [MOTION-01, A11Y-01, A11Y-02]

coverage:
  - id: D1
    description: "Motion source-scan guard: zero transition:/transition-property: all; animation: declarations tokenized except the two D-20/D-21 exceptions allow-listed by animation name; @keyframes bodies animate only transform/opacity/border-color; no @keyframes outside 05-motion.css"
    requirement: "MOTION-01"
    verification:
      - kind: unit
        ref: "mix test test/scoria_web/motion_drift_guard_test.exs"
        status: pass
      - kind: unit
        ref: "Synthetic-mutation sanity check (elixir -e script): untokenized non-allow-listed animation and a disallowed keyframe property (background-color) are both correctly flagged as offenders — guard is not vacuously green."
        status: pass
    human_judgment: false
  - id: D2
    description: "A11Y structural guard: icon-only button accessible names, no color-only status (primary owner), native-semantics presence (dialog/details/table-viewport/filter-controls), calm-surface structural contract (copy controls, forms)"
    requirement: "A11Y-01, A11Y-02"
    verification:
      - kind: unit
        ref: "mix test test/scoria_web/a11y_structural_guard_test.exs"
        status: pass
      - kind: unit
        ref: "Synthetic-mutation sanity check: icon_button with no aria-label, badge with no label, and role=dialog with no aria-modal are all correctly flagged as offenders."
        status: pass
    human_judgment: false
  - id: D3
    description: "Regression: ds06_drift_guard_test.exs and token_contrast_guard_test.exs stay green (no vocabulary/token change introduced)"
    requirement: "MOTION-01, A11Y-02"
    verification:
      - kind: unit
        ref: "mix test test/scoria_web/motion_drift_guard_test.exs test/scoria_web/a11y_structural_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs (19 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-03
status: complete
---

# Phase 40 Plan 02: Browserless Motion & A11Y Structural Source-Scan Guards Summary

**Two new sub-second, pure-Elixir ExUnit guards — a MOTION-01 tokenization/keyframe scan (5 assertions) and an A11Y-01/A11Y-02 structural-presence scan (8 assertions) — prove the already-green motion and accessibility baseline stays locked, modeled directly on the existing `ui_drift_guard_test.exs` idiom, with zero runtime source changes.**

## Performance

- **Duration:** 25 min (research-file reading + code reading dominated; actual guard authoring + mutation-sanity-checking was fast since both guards passed on the first `mix test` run)
- **Tasks:** 2 completed
- **Files created:** 2 (both new test files; zero `lib/`/`assets/` changes)

## Accomplishments

- Created `test/scoria_web/motion_drift_guard_test.exs`: 5 tests proving (i) zero `transition: all`/`transition-property: all` anywhere in `assets/css/**`; (ii) every `animation:` declaration is tokenized (`var(--scoria-dur-*)` + `var(--scoria-ease-*)`) except the two D-20/D-21 exceptions, allow-listed **by animation name** (`scoria-skeleton-pulse`, `scoria-approval-pulse`) rather than by literal duration string, per the research's resolved Open Question #1; (iii) both allow-listed names are actually present on the current tree (a dedicated false-RED guard per the research addendum — missing either produces a false-RED the moment the guard lands); (iv) every `@keyframes` body animates only `transform`/`opacity`/`border-color`; (v) no `@keyframes` at-rule leaks outside `assets/css/05-motion.css`.
- Created `test/scoria_web/a11y_structural_guard_test.exs`: 8 tests proving icon-only button accessible names, the status-not-color-only invariant (primary owner per D-07), `role="dialog"`/`aria-modal="true"` pairing across all 5 current dialog-role overlays, native `<details>`/`<summary>` pairing, the table scroll viewport's keyboard-reachable `tabindex="0"`, real (never bare-`<div>`) filter controls, copy-control accessible name + live region (`<.id>`, the `raw_evidence` copy button), and the form contract (`<label for>`, sr-only required text, icon+text errors).
- Both guards pass green on the current tree on first run — no code fixes were needed, confirming Phases 36-39 built the baseline accessibly-by-construction as CONTEXT.md claimed.
- Verified both guards are **not vacuously green**: wrote throwaway synthetic-mutation sanity checks (Elixir scripts exercising the exact same regex/extraction logic against deliberately broken input — an untokenized non-allow-listed animation, a disallowed keyframe property, a missing `aria-label`, a missing `label`, a missing `aria-modal`) and confirmed every one is correctly flagged as an offender.
- `ds06_drift_guard_test.exs` and `token_contrast_guard_test.exs` (the pre-existing raw-palette and WCAG-luminance guards) remain green — no vocabulary or token change was introduced.

## Task Commits

Each task was committed atomically:

1. **Task 1: MOTION-01 tokenization + keyframe source-scan guard** - `15ec2e4f` (feat)
2. **Task 2: A11Y structural-presence guard** - `5188d257` (feat)

**Plan metadata:** (this commit, see final_commit step)

## Files Created/Modified

- `test/scoria_web/motion_drift_guard_test.exs` - MOTION-01 browserless source-scan guard (5 tests)
- `test/scoria_web/a11y_structural_guard_test.exs` - A11Y-01/A11Y-02 browserless structural-presence guard (8 tests)

## Decisions Made

- **Allow-list keyed on animation name, not literal duration.** Per the research's resolved Open Question #1 and D-19(ii)'s addendum, `motion_drift_guard_test.exs` allow-lists `scoria-skeleton-pulse` and `scoria-approval-pulse` by their `@keyframes`/`animation-name` identifier, not by matching `1.5s`/`600ms` literal strings — a future duration edit on either documented exception cannot silently defeat the guard, and a dedicated "both names present" test catches the false-RED risk of allow-listing only one.
- **`@keyframes` body extraction uses balanced-brace byte-scanning**, not a naive non-greedy regex — a `@keyframes name { 0%, 100% { ... } 50% { ... } }` block nests its own percentage-selector braces one level deep, so a naive `\{(.*?)\}` regex would stop at the FIRST nested `}` (the close of the first percentage rule) instead of the keyframes block's own close, silently under-scanning every keyframe with more than one selector rule.
- **Regex `:index` offsets are byte offsets, not codepoint offsets** — an early implementation used `String.slice/3` for post-match window extraction and produced a subtle bug (windows starting mid-word) because `ui.ex` contains multi-byte UTF-8 characters (en dashes, arrows) earlier in the file, desyncing byte offsets from grapheme-counted slice positions. Fixed by switching all window/extraction helpers to `binary_part/3`.
- **CSS comment-stripping before any count-based scan** — both guards strip `/* ... */` blocks before running detection regexes, so a doc comment mentioning a banned pattern in prose (e.g. this repo's own header comments describing "no transition-all" or listing `@keyframes` names) cannot accidentally trip or hide a count gate (the plan's stated T-40-02 mitigation).
- **`<:filter>`-scoped real-control check, not table-header-sort scope** — see `key-decisions` in frontmatter for the full rationale: the guard's "real button/a controls" assertion is deliberately scoped to the `<:filter>` slot (verified true today) rather than the table's `<th phx-click aria-sort>` sort trigger (which is not literally a `<button>` element today). Asserting the stricter claim would have made the guard red on landing day, contradicting this plan's explicit "prove only the already-green baseline" scope. Not treated as a Rule 1/2 auto-fix because converting the sort trigger to a nested button is an internal `table/1` implementation change outside this plan's declared `files_modified` (test files only) — flagging it here for whichever future plan owns `table/1` polish, rather than silently absorbing scope creep into a guard-authoring plan.
- **Dialog-role check omits Escape-key-attribute presence** — two of the five current `role="dialog"` overlays (mobile-nav drawer, keyboard-shortcuts overlay, both in `app.html.heex`) are pure JS-hook-driven (`scoria.js` `Dismissable` pattern) with no `phx-key="Escape"` attribute at all; asserting its presence would false-RED on those two already-accessible overlays. The guard checks only the `role="dialog"` + `aria-modal="true"` structural pairing; actual Escape-closes-it behavior is Playwright's job per D-12.

## Deviations from Plan

### Auto-fixed Issues

None — both guards passed green on first run; no code fixes were required.

### Process note (not a plan deviation)

During Task 1's commit, `git add test/scoria_web/motion_drift_guard_test.exs` was run individually as instructed, but the commit unexpectedly also included `.planning/research/ai-architectural-patterns.md` — a file that was already present in the git index (staged) from outside this session before this plan began executing (confirmed via `git status --short` showing `AM` — added-then-modified — prior to any action here). This was not caused by a `git add .`/`git add -A` in this session; it was pre-existing staged state inherited from the working tree. Caught immediately after the Task 1 commit via `git status --short`; Task 2's commit was staged and verified clean (only the intended file) before committing. No further corrective action was taken (no `git reset`/history rewrite) per the no-amend policy — the unrelated file's content is unmodified by this plan and its presence in the Task 1 commit message is a labeling artifact only, not a functional or security issue.

**Total deviations:** 0 auto-fixed code changes; 1 process note (unrelated pre-staged file swept into Task 1's commit, corrected for Task 2, not retroactively rewritten).

## Issues Encountered

None beyond the process note above.

## User Setup Required

None — both new files are pure ExUnit test files with no external dependencies, migrations, or environment configuration.

## Next Phase Readiness

- Both guards are live in the standard `mix test` run (`async: true`, sub-second) and will gate every future PR touching `assets/css/**` or `lib/scoria_web/**`.
- No blockers for Plan 03 (drawer/modal focus trap + restore) or Plan 04 (axe scan + responsive scan) — this plan touched no runtime files, so their file scopes are unaffected.
- The scoping judgment call on table sort-trigger semantics (see Decisions Made) is left as a note for whichever later plan/phase next touches `table/1`'s sort affordance — not filed in `40-GAP-REGISTER.md` since it is not a phase-40 in-scope defect discovery per this plan's own guard-authoring boundary, but worth surfacing for Phase 41's hardening pass to consider.

---
*Phase: 40-accessibility-motion-and-responsive-proof*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created files verified present on disk (`test/scoria_web/motion_drift_guard_test.exs`,
`test/scoria_web/a11y_structural_guard_test.exs`, `40-02-SUMMARY.md`). Both task commit
hashes (`15ec2e4f`, `5188d257`) verified present in `git log`.
