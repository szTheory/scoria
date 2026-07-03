# Phase 40 — Deferred Items (out-of-scope discoveries)

Issues discovered during execution that are NOT directly caused by the current
plan/task's changes, and are therefore logged here (not fixed) per the
executor's scope-boundary rule.

## 40-03: `phase16_parity.spec.mjs` MOTION-04 theme-toggle flake (pre-existing, unrelated to drawer/modal focus)

**Found during:** 40-03 Task 2/3 live e2e run (`mix scoria.ui.e2e`) against a real dev server, used to
verify the drawer/modal focus fix and the new specs did not regress anything.

**Symptom:** 3 tests in `priv/dev/e2e/phase16_parity.spec.mjs` (`MOTION-04: theme-toggle smoke` — Home/shell,
Workflows table, Workflow detail) time out clicking `page.locator('#scoria-theme-toggle,
#scoria-theme-toggle-mobile').first()`. Playwright's error log shows the locator resolves to the
`-mobile` toggle, which is `display: none` at the default desktop viewport (`element is not visible`).

**Root cause (not fixed):** `.first()` selects by DOM order, not visibility — if `#scoria-theme-toggle-mobile`
happens to appear before `#scoria-theme-toggle` in the DOM, `.first()` resolves to the hidden one instead of
the visible desktop toggle. The comment above the selector ("prefer desktop at 1280px default viewport")
assumes DOM order matches visibility preference, which does not hold. The correct fix (out of scope for this
plan) is `.filter({ visible: true }).first()`, matching the idiom already used elsewhere in this harness
(`command_palette.spec.mjs`'s `openPaletteWithButton`, and this same plan's own new drawer/modal-opener
selectors).

**Not fixed here because:** `phase16_parity.spec.mjs` is untouched by 40-03's `files_modified` and the bug
is unrelated to focus-trap/restore — it is a pre-existing selector-visibility bug in a Phase-16 spec, not a
regression introduced by the Task 1 `ui.ex`/opener changes. Per the executor scope-boundary rule, this is
logged rather than fixed.

**Suggested fix for whoever picks this up:** change the 3 occurrences of
`page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first()` in `phase16_parity.spec.mjs` to
`.filter({ visible: true }).first()`.

## 40-03: cross-spec-file parallel-worker race over the shared pending-approval pool (pre-existing, worsened marginally by drawer_focus.spec.mjs)

**Found during:** 40-03 Task 2 full-suite verification (`mix scoria.ui.e2e`, which runs with Playwright's
default worker parallelism — observed as 6 workers for 73 tests).

**Symptom:** `uat.spec.mjs`'s "manual dismiss (×) button hides the toast" test intermittently times out
clicking the drawer's "Deny request" button (`element is not stable` → `element was detached from the DOM,
retrying`), and the screenshot at failure time shows the approval drawer already closed back to the base
table. Reproduced 3 times in a row under the full parallel suite; passed cleanly every time when run in
isolation with `--workers=1` (confirmed twice), and the fixture pool was never actually exhausted (7-plus
pending approvals remained each time) — ruling out simple fixture starvation.

**Root cause (not a Task 1 regression):** multiple spec files (`uat.spec.mjs`, `ia_orientation.spec.mjs`, and
now this plan's `drawer_focus.spec.mjs`) each independently select
`getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first()` with no cross-file
coordination. When two of these run concurrently in separate Playwright workers against the SAME dev server/
tenant, both can resolve to the identical "first pending" row at the same instant; whichever worker decides
it first triggers `Workflows.approve/3`'s `OperatorBroadcast.approval_decided/3`, which reaches every other
open socket on that tenant via `handle_info({:approval_decided, ...})` and — via the existing, correct
`maybe_clear_active_approval/2` — closes any OTHER worker's drawer that happened to have the SAME approval
open. This is pre-existing test-suite architecture (both `uat.spec.mjs` and `ia_orientation.spec.mjs` already
raced this way before this plan), not a defect in the Task 1 `ui.ex` focus-trap/restore fix — confirmed by
the clean, deterministic pass under `--workers=1` and by the scoped per-task verify command
(`npx playwright test drawer_focus.spec.mjs`) passing 5/5 repeatedly.

**Partial mitigation applied in this plan:** bumped `@pending_approval_floor` in
`lib/mix/tasks/scoria.ui.e2e.ex` from 5 to 10 (Rule 3 — this plan's new `drawer_focus.spec.mjs` D-13 collector
adds one more destructive decision to the same shared pool, so the floor needed headroom regardless). This
does not eliminate the race (a larger pool doesn't stop two workers resolving `.first()` to the identical
current-first row at the same instant), but it does reduce outright fixture-exhaustion risk as more
approval-consuming specs accumulate.

**Not fully fixed here because:** the real fix (per-worker-unique fixture assignment, or serializing all
approval-decision specs into one `test.describe.configure({ mode: 'serial' })` group across files, or sharding
workers by spec file) is a broader e2e-harness architecture change outside this plan's `files_modified` scope
and this task's declared fix (drawer/modal focus trap + restore). Per the executor scope-boundary rule this is
logged, not redesigned, here. The plan's own verification tiering treats the scoped per-task Playwright run as
this task's primary gate and reserves the full parallel `mix scoria.ui.e2e` run for "the per-wave sampling
tier" — both scoped runs (`drawer_focus.spec.mjs`, `modal_focus.spec.mjs`) pass deterministically.

**Suggested fix for whoever picks this up:** either (a) have every approval-consuming spec file select a
row by a criterion that can't collide across files (e.g. tag/consume specific seeded approval IDs per spec),
or (b) force `mix scoria.ui.e2e`'s Playwright invocation to a single worker when destructive approval-decision
specs are present, or (c) shard destructive specs into their own serial project in `playwright.config.mjs`.
