---
phase: 12-design-system-component-layer
fixed_at: 2026-06-04T00:00:00Z
review_path: .planning/phases/12-design-system-component-layer/12-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 12: Code Review Fix Report

**Fixed at:** 2026-06-04T00:00:00Z
**Source review:** .planning/phases/12-design-system-component-layer/12-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (1 critical + 6 warnings; info findings out of scope)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: `<.id>` regenerates a fresh DOM id + hook on every render

**Files modified:** `lib/scoria_web/ui.ex`
**Commit:** b0bc653
**Applied fix:** Added an optional `attr(:id, :string, default: nil)` and replaced the
render-time `id={"id-#{System.unique_integer([:positive])}"}` with an `assign_new(:id, ...)`
that derives a deterministic, render-stable id from `:erlang.phash2(@value)` when the caller
supplies none. A stable DOM id means morphdom patches the existing element in place instead
of tearing down and re-mounting the `phx-hook="CopyId"` instance on every parent update.
Doc note added recommending a caller-supplied id where identical values can co-occur.

### WR-04: `<.notebook>` renders no panel when `selected_tab` matches no tab key

**Files modified:** `lib/scoria_web/ui.ex`
**Commit:** b0bc653
**Applied fix:** Replaced the `selected_tab == nil`-only default with a guard that falls back
to the first tab whenever `selected_tab` matches no current `<:tab>` key
(`not Enum.any?(@tab, &(&1.key == @selected_tab))`). This prevents the silent disappearance
of the `role="tabpanel"` body when a stale or mistyped `selected_tab` is passed.

### WR-05: `<.notebook>` tab buttons emit `phx-click={nil}`, yielding inert tabs

**Files modified:** `lib/scoria_web/ui.ex`
**Commit:** b0bc653
**Applied fix:** Two-part guard. (1) Raise `ArgumentError` at render when
`length(@tab) > 1 and is_nil(@on_tab_change)` — a multi-tab notebook with no handler can never
switch panels and must fail loudly rather than ship visibly-broken controls. (2) For the
single-tab no-handler case, render a non-interactive `<span role="tab">` instead of a
`<button>` so the control does not present as clickable while being inert.
**Note:** CR-01, WR-04, and WR-05 all live in `lib/scoria_web/ui.ex` (the latter two in the
same `notebook/1` function). They were applied together and committed as one atomic commit on
that file.

### WR-06: `approval_value/3` collapses present-but-falsy values into "unknown"

**Files modified:** `lib/scoria_web/components/remote_invocation_evidence_component.ex`
**Commit:** 4258e4e
**Applied fix:** Replaced the `Map.get(...) || Map.get(...) || "unknown"` chain with a `cond`
that uses explicit `Map.has_key?/2` presence checks, so a present-but-falsy value (`nil`,
`false`) renders as itself rather than being silently rewritten to the literal `"unknown"`.

### WR-03: Approval reject path reports a green ":pass" toast

**Files modified:** `lib/scoria_web/live/approvals_live/index.ex`
**Commit:** 5fc69b0
**Applied fix:** Branched the success toast on `status` in `record_approval_decision/2`:
`"approved"` -> `[tone: :pass, message: "Approval granted."]`, any other status (rejection)
-> `[tone: :warn, message: "Approval rejected — workflow remains paused."]`, then passed the
keyword list to the existing local `put_toast/2`. Confirmed `put_toast/2` already takes a
`(socket, opts)` keyword list, so the call contract is unchanged.
**Status: requires human verification** — this is a behavioral/semantic change (toast tone and
copy). The branch logic is straightforward, but a developer should confirm the wording/tone
mapping matches the intended operator UX and that no status other than "approved"/"rejected"
reaches this path.

### WR-01: DS-06 drift guard is an equality-snapshot ratchet that re-permits palette on refactor

**Files modified:** `test/scoria_web/ds06_drift_guard_test.exs`
**Commit:** fa6d9d0
**Applied fix:** Implemented review option (b): added a new test
("baseline is not stale ...") that fails when any baselined file's current palette count is
*below* its committed baseline, prompting a downward re-commit so the ratchet always tightens
on improvement. A baselined file that no longer exists is treated as stale (count 0). Chose
option (b) over option (a) `count != baseline_count` because (a) would break the existing
ratchet test on every unrelated palette change, whereas (b) isolates the staleness check into
its own assertion with a clear regeneration message.
**Validation:** Ran the guard logic standalone (pure Regex/File/String, no app deps) against
the real baseline and codebase — no stale files, no ratchet violations, ui.ex at zero palette.

### WR-02: `load_baseline/1` crashes on any malformed baseline line

**Files modified:** `test/scoria_web/ds06_drift_guard_test.exs`
**Commit:** fa6d9d0
**Applied fix:** Replaced the `[path, count] = String.split(line, ":", parts: 2)` /
`String.to_integer` pair with a `parse_baseline_line/1` helper that splits on all colons,
takes the count as the final field and the path as everything before it (so paths containing
a colon parse correctly), trims both fields, validates the count with `Integer.parse(.. == "")`,
and `flunk/1`s with a descriptive message naming the offending line and the expected format
instead of raising an opaque `MatchError`/`ArgumentError`.
**Note:** WR-01 and WR-02 both modify `test/scoria_web/ds06_drift_guard_test.exs`; applied
together and committed atomically on that file.

## Skipped Issues

None — all in-scope findings were fixed.

## Notes

- Info findings (IN-01 through IN-04) were out of scope (`fix_scope: critical_warning`) and
  were not addressed.
- `mix test` could not be run inside the isolated worktree because `deps/` is not present
  there (it lives in the main checkout). Verification used: Tier 1 re-read of every edit, Tier
  2 `Code.string_to_quoted!` parse checks on all four modified `.ex`/`.exs` files, and for the
  drift-guard test an additional standalone execution of the new/changed logic against the real
  baseline and codebase (no app deps required).

---

_Fixed: 2026-06-04T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
