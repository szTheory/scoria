---
phase: 41-proof-docs-and-regression-guardrails
reviewed: 2026-07-04T18:03:04Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - lib/scoria_web/live/review_queue_live.ex
  - lib/scoria_web/live/prompt_live/release_workbench_live.ex
  - lib/scoria_web/ui.ex
  - test/scoria_web/live/review_queue_live_test.exs
  - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
  - test/scoria_web/a11y_structural_guard_test.exs
  - test/scoria_web/single_header_rendered_guard_test.exs
  - docs/design_system.md
  - docs/MAINTAINERS.md
  - test/scoria_web/design_system_doc_contract_test.exs
  - .github/workflows/ci-verify.yml
  - test/scoria/ci_policy_contract_test.exs
  - priv/dev/shots.mjs
  - priv/dev/contact_sheet.mjs
  - priv/shots/contact_sheet_index.md
  - priv/dev/e2e/drawer_focus.spec.mjs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 41: Code Review Report

**Reviewed:** 2026-07-04T18:03:04Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 41 delivers two crash-class LiveView fixes, an a11y `aria-label` addition, several
browserless regression guards, a maintainer design-system doc plus its anti-drift contract,
a CI policy-lane wiring change, and Node/Playwright screenshot-harness updates.

The three production Elixir changes are **correct and each covered by a genuine regression
test**:

- `review_queue_live.ex` — the added `with/else` clause on `dismiss_candidate` correctly
  catches both a nil `selected_candidate` and a failed `Eval.dismiss_review_candidate/1`,
  and the new "no selected candidate does not crash" test proves it. `%{} = candidate`
  matches any struct/map and falls through to `else` on `nil`. No defect.
- `release_workbench_live.ex` — the `assign(:origin_context, nil)` default in `mount/3`
  removes the render-before-`handle_params` KeyError; `origin_context/2` +
  `origin_path/3` are total over the `@origin_nouns` allow-list (no `FunctionClauseError`
  reachable), and the WR-04 test forces iodata to actually exercise the fix. No defect.
- `ui.ex` — the viewport `aria-label` addition matches the new a11y-guard regex. No defect.

I verified the two new contract preconditions actually hold today: every guard path
`design_system.md` names (that the contract regex captures) exists on disk, all three
cited tokens exist in `02-tokens.css`, and the CI lane order in `ci-verify.yml`
(`ci_policy → docker_dx → design_system → verification_lanes`) satisfies every ordering
assertion in `ci_policy_contract_test.exs`. The `:binary.match` `index_of/2` has no
substring-collision risk across the distinct full paths.

**No BLOCKER/Critical issues.** The findings below concentrate in one changed dev-only
e2e spec (a warning-collector flipped to a hard, timing-sensitive CI gate) and doc drift.

## Warnings

### WR-01: Flipped D-13 focus assertion uses a bare single-shot read + fixed wait instead of the file's own de-flake poll helper — hard-gates CI on a race

**File:** `priv/dev/e2e/drawer_focus.spec.mjs:321-332`
**Issue:** This phase flipped the D-13 "focus survives an unrelated live PubSub patch"
check from a non-throwing `console.warn` collector to two throwing `expect()`s. The
assertions read focus state with a **bare single-shot** `activeElementId(page)` (line 321)
gated only by a fixed `await page.waitForTimeout(500)` (line 314). The same file already
defines `expectActiveElementId` (lines 79-83) using `expect.poll(..., {timeout: 2000})`
**specifically** because "under heavy parallel CI/CD load ... a bare post-keypress read can
win a race against that redirect" (lines 73-78). The flipped assertion does not use that
helper, reintroducing exactly the focus-redirect race the helper exists to prevent — now
as a hard gate. `mix scoria.ui.e2e` runs as a non-`continue-on-error` step in
`.github/workflows/ci.yml:116`, and `docs/MAINTAINERS.md` mandates a strict zero-retry
flake policy, so a race-induced flake here **hard-blocks merges with no retry**.
Separately, `expect(afterId).toBe(beforeId)` over-specifies the a11y contract: the trap
requirement is "focus still inside the drawer," which `stillInside` already asserts;
exact-element-id equality is stricter and more brittle (focus may legitimately move to a
different in-drawer control after a re-render and still satisfy the trap). The flip is
justified in-comment by a single observed green run, which is thin evidence for a
timing-dependent focus-identity assertion.
**Fix:** Assert via polling and drop the over-specified id-equality check, e.g.:
```js
await expect
  .poll(() => focusIsInside(page, DRAWER_ID), {
    message: `focus should still be inside the approval drawer after an unrelated live PubSub patch (before="${beforeId}")`,
    timeout: 2000,
  })
  .toBe(true);
```

### WR-02: Conditional setup, unconditional hard assertion — the D-13 gate can pass without exercising the live patch it names

**File:** `priv/dev/e2e/drawer_focus.spec.mjs:299-316` (setup) vs `324-332` (assert)
**Issue:** The code that actually drives the "unrelated PubSub broadcast" (open a second
approval, click Deny, confirm in the decision modal) is nested under `if (openerCount > 1)`
**and** `if ((await denyButton.count()) > 0)`. If either is false, no live patch is ever
driven, yet the hard focus-survival assertions at 324-332 still run and pass vacuously —
the guard goes green without exercising the scenario in its own name. The seed floor of 10
pending approvals (comment lines 20-21) makes the outer `openerCount > 1` branch reliable,
but the inner `denyButton` branch is not guaranteed by that floor. As a warning collector
this was harmless; as a throwing gate it is a silently-vacuous pass path.
**Fix:** Make the setup precondition explicit so the gate fails loudly when it cannot
exercise the scenario, e.g. `expect(openerCount, 'D-13 needs >=2 seeded approvals').toBeGreaterThan(1);`
and assert the deny path ran (e.g. the decision modal became visible) before the
focus-survival assertions, rather than silently skipping.

### WR-03: Maintainer CI "Policy job" lane command is stale — omits the design-system contract this phase added to the lane

**File:** `docs/MAINTAINERS.md:14` (also recovery command at `:89`)
**Issue:** Step 4 documents the policy lane as
`mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`.
The executable SSOT `ci-verify.yml` (edited in this phase) actually runs a 5-file lane that
now also includes `test/scoria/docker_dx_doc_contract_test.exs` (pre-existing omission) and
`test/scoria_web/design_system_doc_contract_test.exs` (added this phase). A maintainer
reproducing the policy lane from this doc runs an incomplete command and can miss a
design-system contract failure. Notably, `design_system.md` got a dedicated anti-drift
contract this phase, but no contract pins this MAINTAINERS.md command list to
`ci-verify.yml`.
**Fix:** Update the line 14 (and line 89 recovery) command to list all lane files in the
`ci-verify.yml` order: `ci_policy_contract_test.exs docker_dx_doc_contract_test.exs design_system_doc_contract_test.exs verification_lanes_test.exs adoption_surface_test.exs`.

## Info

### IN-01: New doc contract does not validate the roster's bare filenames or its own path

**File:** `test/scoria_web/design_system_doc_contract_test.exs:89-94`
**Issue:** `guard_paths/1` requires a `test/` prefix (`~r/(test\/[^\s`]+_test\.exs)/`), so
the 10 bare-filename entries in `design_system.md`'s "drift-guard roster" (lines ~190-195)
are not checked by test #1 — including `design_system_doc_contract_test.exs` itself, which
appears in the doc **only** in that roster with no `test/`-prefixed path anywhere, so this
contract never validates its own filename. Renaming a guard and updating only the roster
line, or renaming this contract file, would not be caught. The moduledoc scopes to "three
minimal checks, no heavier," so this is partly by design.
**Fix (optional):** Also scan bare `\b[a-z0-9_]+_test\.exs` roster filenames and assert
existence under `test/scoria_web/`.

### IN-02: `freshMountPerCapture` toast sanity-count runs before the per-iteration viewport is set, making the warning message slightly misleading

**File:** `priv/dev/shots.mjs:264-271`
**Issue:** In `freshMountPerCapture` mode the `.scoria-toast` presence count (line 268)
executes after `goto`/`setTheme` but **before** `setViewportSize` for the current iteration
(line 273), yet the warning it logs interpolates `${vp.name}` — implying the check ran at
that viewport. Harmless (element presence is viewport-independent), but the log can mislead
during authoring.
**Fix (optional):** Move the `.scoria-toast` count after `setViewportSize`, or drop
`${vp.name}` from the message.

---

_Reviewed: 2026-07-04T18:03:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
