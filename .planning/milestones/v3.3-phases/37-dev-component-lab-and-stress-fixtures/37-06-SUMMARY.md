---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 06
subsystem: ui
tags: [phoenix-liveview, playwright, e2e, dev-only-tooling, design-system, component-lab, documentation]

# Dependency graph
requires:
  - phase: 37-05
    provides: "/scoria/_lab" route + DevLab.LabLive shell dispatching to all seven D-07 section modules
provides:
  - "priv/dev/e2e/lab.spec.mjs — 17 deterministic Playwright tests proving the lab in a real browser (route load, D-07 nav, theme persistence, reduced motion, six-width viewport scan, Overlays drawer/modal focus+dismiss, dense-approvals+toast stress fixture, copy control)"
  - "docs/MAINTAINERS.md 'Component Lab' section — how to run/inspect/extend the lab and which probes feed Phases 38-41"
affects: [38, 39, 40, 41]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Theme coverage proved via the shared root.html.heex pre-paint mechanism (localStorage 'scoria-theme' key -> data-theme on <html class=\"scoria-root\">) rather than clicking a #scoria-theme-toggle control, since DevLab.LabLive mounts with layout: {ScoriaWeb.Layouts, :root} directly (no app-shell topbar) — the same persisted key the real ThemeToggle hook writes, so this is real shipped behavior, not a fabricated affordance"
    - "Class-scoped (not id-scoped) Playwright locators around ApprovalInboxComponent instances, since its internal <.table id=\"approvals\"> is hardcoded and repeats whenever the same component renders twice on one lab page (documented duplicate-DOM-id limitation from 37-03)"
    - "<details>/<summary> disclosure controls (raw_evidence open={false}) must be expanded via a summary click before their nested copy button is interactable — native browser collapsed-content behavior, not a bug"
    - "An always-open <.modal> specimen's full-viewport scrim (position: fixed; inset: 0) blocks real pointer clicks on every other control on the SAME page for as long as it stays open — correct modal behavior, but it means click-driven probes (command palette, mobile nav, copy controls) must be proven on a page with no permanently-open overlay if one exists elsewhere in the lab"

key-files:
  created:
    - priv/dev/e2e/lab.spec.mjs
  modified:
    - docs/MAINTAINERS.md
    - dev/lab/sections/foundations.ex

key-decisions:
  - "Theme-toggle coverage tests the persisted localStorage mechanism + reload, not a click on a #scoria-theme-toggle control — no such control is mounted on /scoria/_lab (DevLab.LabLive uses the bare root layout, not the app shell). Explicit light/dark and 'system' (via emulateMedia colorScheme) are both covered."
  - "The Overlays IA page's dismiss-click probe targets the MODAL's own close button, not the drawer's — the always-open modal's full-viewport scrim (real, intended modal behavior) sits visually on top of the drawer and intercepts pointer clicks aimed at the drawer's controls. This is a genuine consequence of stacking two always-open D-10 specimens on one page, not a defect in either component's dismiss contract."
  - "The 'Copy fixture payload' click-outcome probe runs on /scoria/_lab/fixtures, not /scoria/_lab/overlays — Overlays' always-open modal blocks real pointer clicks everywhere else on that page for as long as it stays open; Fixtures renders the identical raw_evidence copyable=\"Copy fixture payload\" control with no competing overlay, so it is the deterministic place to prove a real click."
  - "The copy-outcome assertion accepts either 'Copied' or 'Copy unavailable' (regex) rather than asserting 'Copied' alone — assets/js/scoria.js's click handler produces 'Copy unavailable' whenever the Clipboard API/permission is absent, which is common in headless CI; asserting a bare 'Copied' would be flaky."

requirements-completed: [LAB-01, LAB-02, FIXT-01]

coverage:
  - id: D1
    description: "priv/dev/e2e/lab.spec.mjs proves the lab in a real browser: route load + all seven D-07 nav sections + D-27 header copy/commands, theme persistence (light/dark/system), the Foundations reduced-motion signal, a six-width (D-13) viewport scan of the lab shell with no page-level horizontal overflow, the Overlays drawer/modal focus (autofocus) + inert-dismiss contract, the dense-approvals+toast-over-dense-UI stress fixture, and the Fixtures 'Copy fixture payload' control's real click outcome"
    requirement: "LAB-02"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/lab.spec.mjs — 17/17 passing, verified twice for stability, against a live `mix phx.server` (SCORIA_DB_PORT=55432 PORT=4799) run in this session via `npx playwright test --config e2e/playwright.config.mjs e2e/lab.spec.mjs`"
        status: pass
      - kind: e2e
        ref: "priv/dev/e2e/ full suite (all *.spec.mjs) run against the same live server — lab.spec.mjs's 17 tests all pass; the 12 pre-existing failures are unrelated seed-data-dependent specs (uat.spec.mjs, phase16_parity.spec.mjs, ia_orientation.spec.mjs, command_palette.spec.mjs) that require `mix run priv/repo/dev_seed.exs`, which this plan does not run"
        status: pass
    human_judgment: false
  - id: D2
    description: "The lab route (/scoria/_lab) is genuinely reachable and renders correctly end-to-end in a real browser, closing the caveat 37-05-SUMMARY.md left open (\"LAB-01 is now genuinely reachable ... Plan 06's browser proof is the remaining verification step\")"
    requirement: "LAB-01"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/lab.spec.mjs — route-load test group (2 tests) + all downstream section tests navigating /scoria/_lab/{foundations,overlays,fixtures}"
        status: pass
    human_judgment: false
  - id: D3
    description: "docs/MAINTAINERS.md documents how to run the dev server, open the lab, inspect states/fixture domains, update fixtures, run focused proof, and which lab probes support Phases 38-41; states the lab is maintainer-only and excluded from Hex"
    requirement: "FIXT-01"
    verification:
      - kind: other
        ref: "grep -q '/scoria/_lab' docs/MAINTAINERS.md && grep -q 'dev/lab/fixtures.ex' docs/MAINTAINERS.md && grep -q 'mix scoria.ui.e2e' docs/MAINTAINERS.md — all three pass"
        status: pass
      - kind: other
        ref: "Every command named in the new section (make dev, mix test test/scoria_web/dev_lab_boundary_test.exs, mix scoria.ui.e2e) confirmed to exist in the repo (Makefile target, test file, lib/mix/tasks/scoria.ui.e2e.ex)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No screenshot-diff / visual-regression job was added to the required CI gate this phase (D-30 prohibition)"
    verification:
      - kind: other
        ref: "git diff --stat .github/workflows/ci.yml .github/workflows/ci-verify.yml — empty"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 06: Lab Proof + Maintainer Docs Summary

**Real-browser Playwright proof (`priv/dev/e2e/lab.spec.mjs`, 17 tests) that `/scoria/_lab` renders, persists theme, honors reduced motion, survives a six-width viewport scan, and exercises the Overlays focus/dismiss + dense-toast + copy-control probes — verified green against a live dev server, plus a new `docs/MAINTAINERS.md` "Component Lab" section explaining how to run, inspect, and extend it.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-07-02T17:20:00Z (approx.)
- **Completed:** 2026-07-02T18:15:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 3 (2 created/modified as planned, 1 additional Rule-1 fix)

## Accomplishments

- `priv/dev/e2e/lab.spec.mjs`: 17 deterministic Playwright tests, auto-discovered by the required `e2e` CI gate the moment this file lands (no task/CI change — `testDir`-driven per `playwright.config.mjs`). Covers: route load + all seven D-07 nav sections in exact order + D-27 header title/subtitle/command hrefs; theme persistence for explicit light/dark and "system" (via the shared `root.html.heex` pre-paint mechanism, since no `#scoria-theme-toggle` control exists on this root-layout-only route); the Foundations `prefers-reduced-motion` signal on/off; a six-width (320/375/768/1024/1440/1920) real-browser viewport scan of the lab shell asserting zero page-level horizontal overflow; the Overlays drawer+modal genuinely-open + autofocus + inert-dismiss (`lab-noop-dismiss`) contract; the dense-approvals-table + toast-over-dense-UI stress fixture (`RISK-TOAST-LEGIBILITY` — surfaced, not fixed, per Phase 38 scope); and the "Copy fixture payload" control's real click outcome.
- Verified live: booted the dev server (`SCORIA_DB_PORT=55432 PORT=4799 mix phx.server`, using an existing native pgvector container + `mix scoria.dev.db` for the fresh-DB core/knowledge migration-ordering step), ran `npx playwright test e2e/lab.spec.mjs` — 17/17 green, repeated for stability. Ran the full `priv/dev/e2e/` suite against the same server — `lab.spec.mjs` stayed 17/17 green with zero interference on other specs; the 12 pre-existing failures elsewhere are unrelated seed-data-dependent tests (no `mix run priv/repo/dev_seed.exs` was run this session).
- `docs/MAINTAINERS.md`: new "Component Lab" section — starting the dev server, opening `http://localhost:4799/scoria/_lab`, the D-07 IA table, the D-11 state vocabulary + D-19 fixture domains, updating `dev/lab/fixtures.ex`, running focused proof (`dev_lab_boundary_test.exs` + `mix scoria.ui.e2e`), a Phases 38-41 probe-to-consumer table, and an explicit maintainer-only/unlinked/no-Hex statement (D-05). All three required grep checks pass; every referenced command verified to exist.
- Confirmed D-30: `git diff --stat .github/workflows/ci.yml .github/workflows/ci-verify.yml` is empty — no visual-diff/screenshot-regression job added.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the deterministic lab browser proof spec** - `247ca20` (feat) — includes the Rule 1 `dev/lab/sections/foundations.ex` fix discovered while verifying the spec live
2. **Task 2: Document the Component Lab for maintainers** - `60503a3` (docs)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `priv/dev/e2e/lab.spec.mjs` - 17-test Playwright browser proof for the Component Lab (D-33)
- `docs/MAINTAINERS.md` - new "Component Lab" maintainer section (D-34)
- `dev/lab/sections/foundations.ex` - Rule 1 fix: invalid nested `<p>` around the reduced-motion signal changed to `<div>`

## Decisions Made

- **Theme coverage without a click:** `DevLab.LabLive` mounts with `layout: {ScoriaWeb.Layouts, :root}` directly (37-05) — there is no app-shell topbar or `#scoria-theme-toggle` control on `/scoria/_lab`. Rather than fabricate a toggle affordance that doesn't ship, the theme tests exercise the actual mechanism every lab page depends on: `root.html.heex`'s pre-paint script resolving the persisted `scoria-theme` localStorage key (the same key the real `ThemeToggle` hook writes) into `data-theme` on `<html class="scoria-root">`. Covers explicit light/dark and "system" (via `emulateMedia({colorScheme})`).
- **Dismiss probe targets the modal, not the drawer:** Both the Overlays drawer and modal specimens render simultaneously `show={true}`. The modal's `.scoria-scrim` is `position: fixed; inset: 0` — correct, intended modal behavior — and, being visually on top, intercepts pointer clicks aimed at the drawer's own close button underneath it. The test targets the modal's close button (genuinely clickable, above its own scrim) and documents why the drawer's button is unreachable by a real click while the modal stays open, rather than asserting a false "the drawer closes" outcome.
- **Copy-control probe runs on Fixtures, not Overlays:** the SAME always-open modal on `/scoria/_lab/overlays` blocks real pointer clicks on every other control on that page (including the "Copy fixture payload" button two panels below it) for as long as it stays open — by design (the lab never dismisses its overlay specimens). `dev/lab/sections/fixtures_view.ex` renders an identical `raw_evidence copyable copy_label="Copy fixture payload"` control per scenario with no competing overlay, so the click-outcome probe runs there instead.
- **Copy-outcome assertion accepts "Copied" OR "Copy unavailable":** `assets/js/scoria.js`'s click handler legitimately produces "Copy unavailable" whenever `navigator.clipboard`/permission is absent (common in headless CI). Asserting a bare "Copied" would be flaky wherever clipboard-write permission is denied; both are real, shipped outcomes of the same handler.
- **`<details>` must be expanded before interacting with its copy button:** `<.raw_evidence open={false}>` renders a native `<details>`/`<summary>` — content between `<summary>` and `</details>` (including the copy button) is genuinely hidden by the browser until a maintainer clicks `<summary>`. The test does so explicitly rather than treating this as a bug.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid-HTML `<p>`-in-`<p>` nesting collapsing the Foundations reduced-motion signal**
- **Found during:** Task 1 (live browser verification of the new spec)
- **Issue:** `dev/lab/sections/foundations.ex` wrapped its "Reduced motion" signal in `<p class="scoria-lab-motion-signal" data-lab-motion-signal="true">`, containing `<.eyebrow>` (which itself renders a `<p>`). Nested `<p>` inside `<p>` is invalid HTML5; the browser auto-closes the outer `<p>` the instant it encounters the inner one during parsing, so the actual DOM had an empty, zero-height `<p data-lab-motion-signal="true">` with the eyebrow/off/on content pushed out as unrelated siblings — invisible to any locator scoped to the wrapper, and functionally broken for a sighted maintainer too (the "Reduced motion" indicator never visually appears as a coherent unit). This directly broke the D-14 requirement that reduced-motion behavior be "visible and testable enough to support Phase 40."
- **Fix:** Changed the outer wrapper from `<p>` to `<div>` (valid HTML; `<div>` can legally contain `<p>`/`<span>` children). No other markup, copy, or CSS class changed.
- **Files modified:** `dev/lab/sections/foundations.ex`
- **Verification:** `priv/dev/e2e/lab.spec.mjs`'s two reduced-motion tests failed with "Received: hidden" before the fix and pass after it (verified live against a running dev server, both with and without `emulateMedia({reducedMotion: 'reduce'})`); `MIX_ENV=dev mix compile --warnings-as-errors` and `mix compile --warnings-as-errors` (test env) both clean; `mix test test/scoria_web/dev_lab_boundary_test.exs test/scoria_web/ds06_drift_guard_test.exs` still 13/13 green.
- **Committed in:** `247ca20` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary to make the D-14 reduced-motion truth actually observable in a browser, which is this plan's own stated purpose. No scope creep — single-line tag change, no new files, no architecture change.

## Issues Encountered

- **Real-browser verification uncovered two further test-authoring corrections (not code bugs) before the suite was fully green:** (1) the Overlays dismiss-click probe originally targeted the drawer's close button, which is unreachable by a real pointer click because the always-open modal's full-viewport scrim sits on top of it (correct modal behavior — see Decisions Made); retargeted to the modal's own close button. (2) the copy-control probe originally ran on `/scoria/_lab/overlays` and hit the same modal-scrim interception; retargeted to `/scoria/_lab/fixtures`, which renders an identical control with no competing overlay. Both were fixed in the same commit as Task 1, before it was ever staged, so no broken state was committed.
- **Local `node -e "import(...)"` parse-check (the plan's literal `<automated>` verify command) fails identically for this file AND the pre-existing `phase16_parity.spec.mjs`** with `Error: Playwright Test did not expect test.describe() to be called here.` This is a tooling limitation of invoking `test.describe()` outside Playwright's own test-runner context via a bare `node -e` import — not specific to this file. Used `npx playwright test --config e2e/playwright.config.mjs --list e2e/lab.spec.mjs` instead, which correctly parses and registers all 17 tests. Followed up with a full live run (`npx playwright test e2e/lab.spec.mjs` against a booted dev server) for genuine behavioral proof, exceeding the plan's `<human-check>` bar since no human interaction was actually required to execute it.
- **Native pgvector Postgres on port 55432 was already running (leftover from an earlier session)** but had zero migrations applied. Ran `mix ecto.create` (no-op, already existed) then `mix scoria.dev.db` — the documented fresh-DB core+knowledge migration-ordering task (see project memory `dev-harness-mix-phx-server`) — which completed cleanly. No seed data was loaded (`mix run priv/repo/dev_seed.exs`), which is why the 12 pre-existing, unrelated e2e failures in `uat.spec.mjs`/`phase16_parity.spec.mjs`/`ia_orientation.spec.mjs`/`command_palette.spec.mjs` occurred in the full-suite run — none of the lab's fixtures are DB-backed (D-17), so this had zero effect on `lab.spec.mjs` itself.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 37's two remaining proof/documentation surfaces are complete: the lab has a real, live-verified browser proof in the required `e2e` CI gate, and maintainers have a documented entry point (`docs/MAINTAINERS.md` "Component Lab").
- `LAB-01`'s reachability caveat (open since 37-01-SUMMARY.md, restated in 37-05-SUMMARY.md as "the remaining verification step") is now closed — the route was proven end-to-end in a real, running browser this session, not merely LiveViewTest-rendered.
- `dev/lab/sections/foundations.ex`'s invalid-HTML nesting bug is fixed; the D-14 reduced-motion truth is now genuinely visible and testable, unblocking the exact Phase 40 dependency 37-CONTEXT.md D-14 named ("Reduced-motion behavior must be visible and testable enough to support Phase 40").
- The Overlays IA page's always-open-modal-blocks-sibling-clicks behavior (documented in Decisions Made / Issues Encountered above) is a real, observed consequence of that page's design (two permanently-open D-10 overlay specimens on one page) — not a defect requiring a fix in this plan's scope, but worth a maintainer's attention if Phase 38-41 ever needs to drive a real pointer interaction with the Overlays page's command-palette-open or mobile-nav-open buttons in a future e2e spec; that would need either a different page or a scoped CSS containing-block change, which is out of this plan's declared file scope.
- No blockers. Phase 37 (`dev-component-lab-and-stress-fixtures`) is ready for its final `/gsd-verify-work` pass.

## Self-Check: PASSED

- `priv/dev/e2e/lab.spec.mjs` found on disk.
- `docs/MAINTAINERS.md` contains the new "Component Lab" section (grep-verified).
- `dev/lab/sections/foundations.ex` contains the `<div class="scoria-lab-motion-signal" ...>` fix (grep-verified).
- Both task commit hashes (`247ca20`, `60503a3`) found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
