---
phase: 37-dev-component-lab-and-stress-fixtures
plan: 01
subsystem: ui
tags: [phoenix-liveview, dev-only-tooling, fixtures, design-system, component-lab, elixir]

# Dependency graph
requires: []
provides:
  - DevLab.Fixtures (dev/lab/fixtures.ex) — deterministic fixture catalog: scenario/1 (15 D-20/D-19 domain scenarios), states_for/2 (generic 10-state derivation), inventory_id/1 (D-08 coverage-anchor map of all 46 canonical PRIM-*/GROUP-* inventory IDs)
  - DevLab.Sections.States (dev/lab/sections/states.ex) — state_tone/1 (single lab-state -> tone mapping), states_band/1 (reusable per-state specimen renderer), states_section/1 (States IA overview)
  - test/scoria_web/dev_lab_boundary_test.exs — structural boundary/coverage guard (public-macro exclusion, Hex package exclusion, D-21 zero-lib-reference enforcement, D-04 no component-catalog dep, D-17 fixture-path boundary, D-11/D-20 coverage scans, guard #7 inventory-ID cross-reference)
  - DS-06 drift guard extended to scan dev/lab/**/*.{ex,heex} for raw palette + raw hex (D-26)
affects: [37-02, 37-03, 37-04, 37-05, 37-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generic structural state derivation (deep_map/deep_empty/deep_densify walking any map/list/string) instead of hand-authored per-primitive state variants — adding a scenario stays O(1)"
    - "Single inventory-ID coverage-anchor map (DevLab.Fixtures.inventory_id/1) as the SSOT both the boundary-test guard #7 and later Primitives/Groups sections read from"
    - "Text-scan-only guard tests (File.read!/1 + Regex) proving a dev/-only compile boundary from test/, which cannot compile dev/ modules directly"
    - "Additive, standalone DS-06 extension test scanning a new path tree, rather than folding it into the existing baseline-ratchet file"

key-files:
  created:
    - dev/lab/fixtures.ex
    - dev/lab/sections/states.ex
    - test/scoria_web/dev_lab_boundary_test.exs
    - priv/dev/lab_fixtures/README.md
    - .planning/phases/37-dev-component-lab-and-stress-fixtures/deferred-items.md
  modified:
    - test/scoria_web/ds06_drift_guard_test.exs

key-decisions:
  - "Used the DevLab.* module namespace (not ScoriaWeb.DevLabFixtures) per Claude's Discretion in 37-CONTEXT.md — matches the D-21 guard regex and keeps lab modules visually distinct from the runtime ScoriaWeb.* namespace"
  - "states_for/2 is a fully structural deep-transform (walks any map/list/string leaf) rather than per-primitive typed logic, so adding one new scenario/1 clause never requires hand-writing its ten state variants"
  - "DevLab.Fixtures.inventory_id/1 owns all 46 canonical PRIM-*/GROUP-* IDs from 36-inventory.json as a single coverage-anchor map, satisfying guard #7 and giving later Primitives/Groups sections one place to look up their inventory ID"
  - "DS-06's dev/lab/** extension (D-26) is an additive standalone test, not a change to the existing lib/ ratchet-baseline mechanism — avoids coupling new dev/ coverage to the committed baseline file"

patterns-established:
  - "Pattern: state-band renderer (states_band/1) — every downstream Primitives/Groups section entry renders through this one function component"
  - "Pattern: scenario/1 + states_for/2 split (D-06 spine) — domain data and state-stress derivation are always separate functions, never a hand-authored matrix"

requirements-completed: [LAB-01, FIXT-01]

coverage:
  - id: D1
    description: "Deterministic dev-only fixture catalog: 15 D-20/D-19 domain-noun scenarios (approvals/incidents/reviews/datasets/workflow/connectors/prompts/evals, each with a normal + empty/error scenario) plus a generic states_for/2 deriving all 10 D-11 states from any scenario"
    requirement: "LAB-01"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs#all fifteen D-20/D-19 fixture scenario names are present in dev/lab source (FIXT-01, D-32)"
        status: pass
      - kind: unit
        ref: "test/scoria_web/dev_lab_boundary_test.exs#all ten D-11 canonical states are present in dev/lab source (D-32)"
        status: pass
    human_judgment: false
  - id: D2
    description: "state_tone/1 single lab-state to visual-tone mapping and states_band/1 reusable per-state specimen renderer, built only from existing ScoriaWeb.UI primitives and --scoria-* tokens"
    requirement: "LAB-02"
    verification:
      - kind: unit
        ref: "MIX_ENV=dev mix compile --warnings-as-errors"
        status: pass
      - kind: unit
        ref: "test/scoria_web/ds06_drift_guard_test.exs#dev/lab/** (Component Lab) has zero raw palette classes and zero raw hex colors (D-26)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Structural boundary/coverage guard proving the lab is excluded from the public scoria_dashboard/2 macro, dashboard nav/command palette, and mix.exs package.files; proving the D-21 zero-lib-reference rule as the sole enforcement mechanism; proving no component-catalog dependency (D-04); and the guard #7 inventory-ID cross-reference floor against all 46 canonical 36-inventory.json PRIM-*/GROUP-* rows"
    verification:
      - kind: unit
        ref: "mix test --no-start test/scoria_web/dev_lab_boundary_test.exs test/scoria_web/ds06_drift_guard_test.exs (13 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-07-02
status: complete
---

# Phase 37 Plan 01: Fixture Catalog, State/Tone Vocabulary, Boundary Guard Summary

**Deterministic 15-scenario Component Lab fixture catalog with a generic 10-state structural derivation, an explicit lab-state-to-tone mapping, and a text-scan guard proving the lab stays out of the public macro, the Hex package, and `lib/`.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-02T19:18:04Z
- **Completed:** 2026-07-02T19:39:14Z
- **Tasks:** 3
- **Files modified:** 6 (4 created under `dev/lab/` and `test/`, 1 modified test file, 1 new reserved-directory README, plus 1 phase-level deferred-items log)

## Accomplishments

- `DevLab.Fixtures` (`dev/lab/fixtures.ex`): 15 domain-noun scenarios covering every D-19 domain (approvals, incidents, reviews, datasets, workflow, connectors, prompts, evals) with both a normal and an empty/error scenario each, plus `states_for/2` — a fully structural (map/list/string-walking) transform that derives all 10 canonical D-11 states from any one scenario without hand-authoring a 15x10 matrix.
- `DevLab.Fixtures.inventory_id/1`: a single coverage-anchor map of all 46 canonical `PRIM-*`/`GROUP-*` inventory IDs from `36-inventory.json`, doubling as both the guard #7 literal-string anchor and the future `Primitives`/`Groups` sections' inventory-ID lookup.
- `DevLab.Sections.States` (`dev/lab/sections/states.ex`): `state_tone/1` (the sole D-11-state-to-tone mapping, never calling `ScoriaWeb.UI.tone/1`), `states_band/1` (the reusable per-state specimen renderer every later Primitives/Groups entry will use), and `states_section/1` (the States IA overview).
- `test/scoria_web/dev_lab_boundary_test.exs`: 8 assertions proving public-router/nav/palette exclusion, region-scoped Hex `package.files` exclusion, no component-catalog dependency, the D-21 zero-`lib/`-reference rule (documented as the SOLE enforcement mechanism given `elixirc_paths(:dev)`), the D-17 fixture-path boundary, full 10-state/15-scenario source coverage, and the guard #7 inventory-ID cross-reference floor.
- `test/scoria_web/ds06_drift_guard_test.exs` extended with an additive test scanning `dev/lab/**` for raw palette classes and raw hex colors (D-26), without touching the existing `lib/` ratchet/baseline assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the deterministic dev-only fixture catalog DevLab.Fixtures** - `286fb8f` (feat)
2. **Task 2: Add the lab-state to tone mapping and the reusable state-band renderer** - `1bff1c2` (feat)
3. **Task 3: Author the source-scan boundary and coverage guard test (and extend the DS-06 drift guard to dev/)** - `02c0fc5` (test)

**Plan metadata:** _pending (this commit)_

## Files Created/Modified

- `dev/lab/fixtures.ex` - `DevLab.Fixtures`: `scenario/1`, `states_for/2`, `inventory_id/1`, facade helpers (`scenarios/0`, `domains/0`, `scenario_names/0`, `scenarios_for_domain/1`)
- `dev/lab/sections/states.ex` - `DevLab.Sections.States`: `state_tone/1`, `states_band/1`, `states_section/1`
- `test/scoria_web/dev_lab_boundary_test.exs` - `ScoriaWeb.DevLabBoundaryTest`: 8 structural boundary/coverage tests
- `test/scoria_web/ds06_drift_guard_test.exs` - added a standalone `dev/lab/**` raw-palette/raw-hex test (D-26)
- `priv/dev/lab_fixtures/README.md` - documents the reserved dev-only bulky-JSON fixture-payload directory (never `priv/fixtures/`)
- `.planning/phases/37-dev-component-lab-and-stress-fixtures/deferred-items.md` - logs 3 pre-existing/unrelated full-suite failures found during verification (out of this plan's scope)

## Decisions Made

- Used the `DevLab.*` module namespace (matches the D-21 guard regex; keeps lab modules visually distinct from `ScoriaWeb.*` runtime modules) — per Claude's Discretion in `37-CONTEXT.md`.
- Implemented `states_for/2` as a fully structural deep-transform (recursing through any map/list/string leaf) instead of per-primitive typed state logic, so each new `scenario/1` clause automatically gets all 10 state variants for free (O(1) per new ugly scenario, as required).
- Consolidated all 46 canonical `PRIM-*`/`GROUP-*` inventory IDs into one `DevLab.Fixtures.inventory_id/1` map rather than scattering literal ID strings ad hoc — this single map is both the guard #7 coverage-floor anchor and the lookup later Primitives/Groups sections will use for their `states_band/1` `inventory_id` attr.
- Kept the DS-06 `dev/lab/**` extension (D-26) as a new, standalone, additive test rather than merging it into the existing `lib/` ratchet-baseline mechanism, to avoid coupling brand-new `dev/` coverage to the committed `test/support/ds06_baseline.txt` file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a self-tripping D-17 guard due to the moduledoc's own example text**
- **Found during:** Task 3 (writing `dev_lab_boundary_test.exs`'s D-17 assertion)
- **Issue:** `dev/lab/fixtures.ex`'s moduledoc explained the `priv/dev/lab_fixtures` vs. Hex-shipped `priv/fixtures` boundary using the literal substring `"priv/fixtures/"` in prose — which is exactly the string the new guard test scans `dev/lab/fixtures*` sources for, so the guard failed against its own documentation, not against a real violation.
- **Fix:** Reworded the moduledoc to reference `priv/fixtures` (no trailing slash) and point to `priv/dev/lab_fixtures/README.md` for the full rationale, removing the literal `priv/fixtures/` substring from the source file entirely.
- **Files modified:** `dev/lab/fixtures.ex`
- **Verification:** `mix test --no-start test/scoria_web/dev_lab_boundary_test.exs` — the D-17 assertion now passes (13/13 tests green).
- **Committed in:** `02c0fc5` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Documentation-only fix; no scope creep, no behavior change to the fixture catalog itself.

## Issues Encountered

- The local `SCORIA_DB_PORT=55432` test database (native pgvector helper) was not running at session start; started it via `SCORIA_DB_PORT=55432 make native-db` before running the full-suite verification. No code change required.
- Full-suite verification (`SCORIA_DB_PORT=55432 mix test --warnings-as-errors`) reported **3 doctests, 801 tests, 3 failures (15 excluded)**. All 3 failures are pre-existing/unrelated to this plan's files (`dev/lab/`, `dev_lab_boundary_test.exs`, `ds06_drift_guard_test.exs` are not referenced by any of them): (1) `Scoria.CiPolicyContractTest` expecting `"v2.15"` in `ROADMAP.md`, already documented as a residual Phase 36 failure in `36-VERIFICATION.md`; (2) `Scoria.SupportCopilotGalleryTest`, a `Postgrex` connection-ownership race in the nested advisory gallery lane; (3) `Scoria.WarningInventory.CaptureParityTest`, a nested compile-only self-test timing issue. Logged (not fixed, out of this plan's scope) in `.planning/phases/37-dev-component-lab-and-stress-fixtures/deferred-items.md`.

## User Setup Required

None - no external service configuration required. (Local dev DB was already provisioned via the repo's standard `make native-db` helper; no new setup step introduced by this plan.)

## Next Phase Readiness

- `DevLab.Fixtures` and `DevLab.Sections.States` are ready for Wave 2 (`37-02` Foundations + Primitives, `37-03` Groups + Fixtures catalog, `37-04` Viewports + Overlays) to consume: `scenario/1`, `states_for/2`, `inventory_id/1`, `state_tone/1`, and `states_band/1` are all stable public APIs.
- `test/scoria_web/dev_lab_boundary_test.exs` is the automated verify every later build task in this phase should run (`mix test --no-start test/scoria_web/dev_lab_boundary_test.exs test/scoria_web/ds06_drift_guard_test.exs`) — it will start reporting real coverage gaps as soon as later plans add more `dev/lab/**/*.ex` files (the guard #7 floor already requires all 46 canonical inventory IDs, which this plan's fixture catalog already satisfies).
- No blockers. The 3 pre-existing full-suite failures logged in `deferred-items.md` are unrelated to this phase and should be tracked separately (Phase 36 already owns failure #1; #2 and #3 are new findings from this session, worth a maintainer look before `/gsd-verify-work` on the whole phase).
- **Requirements caveat:** Per this plan's frontmatter `requirements: [LAB-01, FIXT-01]`, `.planning/REQUIREMENTS.md` now checks off both `LAB-01` and `FIXT-01`. `FIXT-01` (realistic/ugly fixture data across all domains) is genuinely satisfied by this plan's fixture catalog. `LAB-01` ("Developer can open a dev-only component lab that renders...") is only structurally satisfied so far — the fixture/render primitives it needs exist, but the lab route itself is not mounted until `37-05` (`DevLab.LabLive` + `dev_router.ex` wiring). Flagging this now so `/gsd-verify-work` on the full phase double-checks `LAB-01` against the actual reachable route once `37-05` lands, rather than trusting the early checkbox alone.

## Self-Check: PASSED

All claimed files found on disk (`dev/lab/fixtures.ex`, `dev/lab/sections/states.ex`,
`test/scoria_web/dev_lab_boundary_test.exs`, `priv/dev/lab_fixtures/README.md`,
`.planning/phases/37-dev-component-lab-and-stress-fixtures/deferred-items.md`,
this SUMMARY.md). All 3 task commit hashes (`286fb8f`, `1bff1c2`, `02c0fc5`)
found in `git log`.

---
*Phase: 37-dev-component-lab-and-stress-fixtures*
*Completed: 2026-07-02*
