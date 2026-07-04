---
phase: 38-foundations-and-primitive-controls
plan: 01
subsystem: ui
tags: [css, design-tokens, color-mix, playwright, toast, wcag]

requires: []
provides:
  - "Opaque --scoria-toast-<tone>-bg semantic tokens (neutral/pass/info/warn/fail) in both dark and light theme blocks"
  - "toast_opacity_guard_test.exs regression guard against re-introducing translucent toast backgrounds"
  - "Browser-truth computed-style alpha proof (light + dark) in priv/dev/e2e/lab.spec.mjs"
affects: [39-approval-decision-history, later-toast-flash-consumers]

tech-stack:
  added: []
  patterns:
    - "Opaque-over-solid-surface color-mix() token idiom: color-mix(in srgb, var(--scoria-tone-<tone>-fg) N%, var(--scoria-surface-panel-raised)) for any future status surface that must never let underlying content bleed through, distinct from the existing translucent --scoria-tone-<tone>-bg tint used for in-page badges/banners."
    - "CSS-source regex guard (mirrors ds06_drift_guard_test.exs's File.read! + block-scoping style) as the correct verification mechanism for color-mix()-valued tokens that token_contrast_guard_test.exs's resolve_token/3 cannot resolve (it flunks, not skips, on color-mix())."

key-files:
  created:
    - test/scoria_web/toast_opacity_guard_test.exs
  modified:
    - assets/css/02-tokens.css
    - assets/css/04-components.css
    - priv/static/scoria/app.css
    - priv/dev/e2e/lab.spec.mjs

key-decisions:
  - "Mix percentage: 16% tone-into-panel-raised in dark theme, 12% in light theme (RESEARCH.md A1 starting values, not exact-pinned by the guard)."
  - "Flash banners repointed to the same opaque toast tokens (D-03 fallback: legibility wins) even though no floating .scoria-flash exists in lib/scoria_web/components/layouts — confirmed by grep before making the change."
  - "priv/static/scoria/app.css (the compile-time-inlined dashboard bundle read by ScoriaWeb.Assets via @external_resource) must be regenerated via `mix scoria.assets.build` whenever assets/css/*.css changes — this is not automatic on `mix compile`, only on `mix assets.build`/`assets.deploy` aliases."

patterns-established:
  - "Toast/flash surfaces get their own --scoria-toast-<tone>-bg family, separate from the shared --scoria-tone-<tone>-bg tint family — future overlay-style surfaces (drawers, modals) that need guaranteed opacity over dense content should follow the same opaque-composite pattern rather than reusing the translucent tone tint."

requirements-completed: [DS-01, DS-04]

coverage:
  - id: D1
    description: "New --scoria-toast-<tone>-bg opaque semantic tokens exist in both dark and light theme blocks, never compositing toward transparent"
    requirement: "DS-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/toast_opacity_guard_test.exs#--scoria-toast-<tone>-bg tokens are declared and opaque in BOTH theme blocks"
        status: pass
    human_judgment: false
  - id: D2
    description: ".scoria-toast--<tone> and .scoria-flash--<tone> backgrounds resolve through the new opaque toast tokens; shared --scoria-tone-*-bg tints unchanged for in-page badges/banners"
    requirement: "DS-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs (no new raw palette/hex)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/token_contrast_guard_test.exs (unmodified pairs still pass)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Warning and error toasts render on a fully opaque computed background (alpha === 1) in both light and dark themes over dense approvals UI"
    requirement: "DS-04"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/lab.spec.mjs#warn and fail toasts render with a fully opaque computed background in both themes"
        status: pass
    human_judgment: false
  - id: D4
    description: "Manual confirmatory visual check: /scoria/_lab/overlays dense-approvals + toast stage shows no bleed-through in either theme"
    verification: []
    human_judgment: true
    rationale: "VALIDATION.md designates this a Manual-Only confirmatory check alongside the automated guard/e2e proof; visual legibility over dense UI benefits from a human look even though the alpha=1 assertion is machine-proven."

duration: 32min
completed: 2026-07-02
status: complete
---

# Phase 38 Plan 01: Opaque Toast Tokens Summary

**Fixed transparent unreadable warning/error toasts (D-04) by adding opaque `--scoria-toast-<tone>-bg` tokens composited over the solid elevated surface, repointing toast/flash CSS at them, and locking the fix with a CSS-source guard plus a computed-style browser proof in both themes.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-07-02T22:40:00Z (approx, per STATE.md)
- **Completed:** 2026-07-02T23:12:00Z
- **Tasks:** 3 completed
- **Files modified:** 5 (1 created, 4 modified, including a regenerated compiled asset)

## Accomplishments

- Added `--scoria-toast-<tone>-bg` (neutral/pass/info/warn/fail) semantic tokens in both the dark (`.scoria-root`) and light (`.scoria-root[data-theme="light"]`) blocks of `assets/css/02-tokens.css`, each an opaque `color-mix()` of the tone accent into `--scoria-surface-panel-raised` — never toward `transparent`.
- Repointed `.scoria-toast--<tone>` (and base `.scoria-toast`) and `.scoria-flash--<tone>` (and base `.scoria-flash`) `background:` declarations in `assets/css/04-components.css` at the new tokens, leaving `border-color`/`color` on the existing `--scoria-tone-<tone>-border/-fg` tokens.
- Created `test/scoria_web/toast_opacity_guard_test.exs`, a focused CSS-source regression guard (regex scan of `assets/css/02-tokens.css`) that asserts each `--scoria-toast-<tone>-bg` token is declared in both theme blocks and is opaque (no see-through `color-mix()` composite, no `rgba()`/`hsla()` with alpha < 1). This exists as its own file because `token_contrast_guard_test.exs`'s `resolve_token/3` flunks (not skips) on `color-mix()`-valued tokens.
- Extended the existing Phase 37 dense-approvals + toast-overlay e2e describe block in `priv/dev/e2e/lab.spec.mjs` with a computed-style assertion: `.scoria-toast--warn` and `.scoria-toast--fail` resolve to `backgroundColor` alpha === 1 in both light and dark themes (via the existing localStorage + reload theme mechanism, since the bare `/_lab` root-layout route has no `ThemeToggle` click affordance).
- Discovered and fixed that `priv/static/scoria/app.css` — the compile-time-inlined bundle `ScoriaWeb.Assets` reads via `@external_resource` — must be regenerated via `mix scoria.assets.build` for source CSS changes to actually reach the running dashboard; this is not automatic on `mix compile`.

## Task Commits

1. **Task 1: Add failing CSS-source toast-opacity guard (RED)** - `aacdb71` (test)
2. **Task 2: Add opaque toast tokens and repoint toast/flash CSS (GREEN)** - `3c0f1af` (feat)
3. **Task 3: Extend dense-approvals lab e2e with opaque-alpha assertion (light + dark)** - `f6105e7` (test)

**Companion fix (discovered during Task 3 verification):** `f519394` (fix) — regenerated `priv/static/scoria/app.css` from the Task 2 source edit.

_Note: Commits are in execution order; the companion fix commit sits between Task 2 and Task 3 chronologically because Task 3's browser verification is what surfaced the stale-build issue._

## Files Created/Modified

- `test/scoria_web/toast_opacity_guard_test.exs` - New CSS-source regression guard for opaque toast tokens
- `assets/css/02-tokens.css` - Added `--scoria-toast-<tone>-bg` tokens (dark + light theme blocks)
- `assets/css/04-components.css` - Repointed `.scoria-toast--<tone>` and `.scoria-flash--<tone>` backgrounds
- `priv/static/scoria/app.css` - Regenerated compiled bundle (`mix scoria.assets.build`) so the compile-time-inlined dashboard actually serves the fix
- `priv/dev/e2e/lab.spec.mjs` - Extended dense-approvals + toast-overlay block with a light/dark opaque-alpha assertion

## Decisions Made

- Mix percentages: 16% (dark) / 12% (light) tone-into-`panel-raised`, per RESEARCH.md Assumption A1 starting values — the guard verifies opacity, not an exact percentage, leaving room for future visual tuning.
- Flash banners (`.scoria-flash--<tone>`) were repointed to the same new opaque toast tokens per D-03's stated fallback ("default flashes to the opaque treatment too — legibility wins"), after confirming via `grep -rn "scoria-flash" lib/scoria_web/components/layouts` that no flash in this codebase is positioned as a floating overlay (no matches).
- `priv/static/scoria/app.css` must be treated as a required companion artifact whenever `assets/css/*.css` changes — added as an explicit key-decision here since it is not obvious from the plan's declared `files_modified` list and there is no automatic rebuild hook on `mix compile`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Compiled dashboard CSS bundle was stale relative to source token/component edits**
- **Found during:** Task 3 (browser e2e verification against the running dev server)
- **Issue:** `ScoriaWeb.Assets` inlines `priv/static/scoria/app.css` at compile time via `@external_resource` rather than serving `assets/css/*.css` directly. Task 2's source edits had no runtime effect until this generated bundle was rebuilt. The first e2e run against the (stale) served CSS showed the toast's computed background alpha at exactly the OLD light-theme translucent `--scoria-tone-warn-bg` value (`0.12`), proving the fix had not shipped rather than a defect in the fix itself.
- **Fix:** Ran `mix scoria.assets.build` to regenerate `priv/static/scoria/app.css` from the edited `assets/css/*.css` sources, recompiled, and restarted the dev server. Diffed the regenerated file against the source edit to confirm no unrelated drift.
- **Files modified:** `priv/static/scoria/app.css`
- **Verification:** Computed style re-check showed `color(srgb ...)` with no alpha component (implies alpha 1); full `lab.spec.mjs` suite (18/18) and `mix scoria.ui.e2e` re-run both green for the new toast-opacity test.
- **Committed in:** `f519394`

**2. [Rule 3 - Blocking issue] Chromium's computed-style notation for `color-mix()`-derived backgrounds**
- **Found during:** Task 3 (writing the e2e alpha-parsing logic)
- **Issue:** The plan's `getComputedStyle(el).backgroundColor` assertion assumed a legacy `rgb()`/`rgba()` string. Chromium instead resolves these specific `color-mix()`-derived backgrounds as CSS Color 4 `color(srgb r g b[ / a])` notation, which omits the alpha term entirely when alpha is 1. The original regex (`rgba?\(...\)` only) threw a `TypeError` on `color(...)` strings.
- **Fix:** Extended the in-page `evaluate()` alpha-parsing logic to handle both notations: legacy `rgb()`/`rgba()` (alpha defaults to 1 if absent) and `color(srgb ...)` (alpha defaults to 1 if the `/ a` term is absent).
- **Files modified:** `priv/dev/e2e/lab.spec.mjs`
- **Verification:** `lab.spec.mjs`'s new test passes in both themes after the fix.
- **Committed in:** `f6105e7` (folded into the Task 3 commit since it was written and verified together, not a separate follow-up)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking issues preventing the plan's own verification from actually proving the fix).
**Impact on plan:** Both fixes were necessary for the plan's stated fix to actually reach the running dashboard and be provably correct in a real browser. No scope creep — no files outside the plan's declared `assets/css/02-tokens.css`, `assets/css/04-components.css`, `test/scoria_web/toast_opacity_guard_test.exs`, `priv/dev/e2e/lab.spec.mjs` set were touched, aside from the required compiled-asset companion (`priv/static/scoria/app.css`), which is a direct build output of the first file.

## Issues Encountered

- Local dev DB (native pgvector Postgres) and `mix phx.server` were not running at session start; started both (`make native-db`, `mix dev.setup`, `SCORIA_DB_PORT=55432 PORT=4799 mix phx.server`) to run the plan's required `mix scoria.ui.e2e` verification, then stopped the server afterward. The pre-existing native-db Docker container was left running (it predates this session).
- The full `mix scoria.ui.e2e` run (all `priv/dev/e2e/*.spec.mjs` files, not just `lab.spec.mjs`) surfaced 4 pre-existing failures unrelated to this plan's files (`ia_orientation.spec.mjs`, `phase16_parity.spec.mjs` theme-toggle smoke) plus one flaky `command_palette.spec.mjs` result that did not reproduce on a re-run. None reference `.scoria-toast`, `.scoria-flash`, or either CSS file this plan touches. Logged (not fixed, per the deviation-rule scope boundary) in `.planning/phases/38-foundations-and-primitive-controls/deferred-items.md`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `--scoria-toast-<tone>-bg` tokens and the opaque-composite pattern are now available for any future overlay-style surface (drawers, modals) that needs guaranteed opacity over dense content.
- `toast_opacity_guard_test.exs` will catch any future regression that re-points `.scoria-toast--*`/`.scoria-flash--*` backgrounds back at the translucent `--scoria-tone-*-bg` tint family.
- Remember to run `mix scoria.assets.build` (and recompile) after any future `assets/css/*.css` edit before relying on the dev Component Lab or dashboard to reflect it — this is not automatic.
- Approval decision history (Phase 39, per STATE.md Pending Todos) is unaffected by and independent of this plan's scope.

---
*Phase: 38-foundations-and-primitive-controls*
*Completed: 2026-07-02*

## Self-Check: PASSED

All created files verified present; all task/companion/docs commit hashes (`aacdb71`, `3c0f1af`, `f519394`, `f6105e7`, `0e0e76d`) verified present in `git log`.
