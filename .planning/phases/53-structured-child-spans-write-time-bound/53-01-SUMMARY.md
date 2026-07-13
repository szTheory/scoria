---
phase: 53-structured-child-spans-write-time-bound
plan: 01
subsystem: observability
tags: [elixir, otp, supervision, telemetry, ecto, postgres]

# Dependency graph
requires:
  - phase: 51-foundation-fix-key-convention-span-kind-taxonomy
    provides: Scoria.Observe.Buffer, Scoria.Observe.Telemetry.attach/1, the trace/span persistence pipeline
  - phase: 52-retriever-span-host-declared-attributes
    provides: emit_retriever_span/1, emit_prompt_span/1 span emitters that now have somewhere to persist
provides:
  - Scoria.Observe.Buffer as a supervised child of Scoria.Supervisor (boots in :prod)
  - Scoria.Observe.Telemetry.attach/1 called during Scoria.Application.start/2
  - Scoria.Application.observe_children/0 public boot seam (@doc false)
  - config :scoria, Scoria.Observe, enabled: false opt-out
affects: [53-02, 53-03, 53-04, 53-05, 53-06, 53-07, 53-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "maybe_*/0 private helper folded into Scoria.Application's ++ children chain, config-gated (not Mix.env()) when the child must boot in :prod"
    - "Public @doc false seam function exposing a private children-builder's output for test assertions instead of reaching into private functions"
    - "Match-and-ignore {:error, :already_exists} from :telemetry.attach_many/4 at boot so a duplicate handler id never crashes start/2"

key-files:
  created:
    - test/scoria/application_test.exs
  modified:
    - lib/scoria/application.ex
    - CHANGELOG.md

key-decisions:
  - "maybe_observe_buffer/0 gates on Application.get_env(:scoria, Scoria.Observe, [])[:enabled] != false (absent key = enabled-by-default), deliberately NOT Mix.env() -- Buffer must boot in :prod per D-00a, unlike maybe_reconciler/0's test-only exclusion."
  - "observe_children/0 is public (@doc false) so Task 1's enabled: false test has a real seam instead of reaching into a private function; maybe_observe_buffer/0 delegates to it."
  - "safe_attach_observe_telemetry/0 match-and-ignores both :ok and {:error, :already_exists} from Telemetry.attach/0 -- a boot crash from a duplicate handler id would take the entire host app down (T-53-08)."

patterns-established:
  - "Config-gated (not Mix.env()-gated) children builders in Scoria.Application for behavior that must run in every environment including :prod."

requirements-completed: [EVENT-01]

coverage:
  - id: D1
    description: "Scoria.Observe.Buffer runs as a supervised child of Scoria.Supervisor after Scoria.Application boots"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/application_test.exs#Scoria.Observe.Buffer runs as a supervised child of Scoria.Supervisor"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoria.Observe.Telemetry.attach/1 is called during Scoria.Application.start/2 and is idempotent (duplicate handler id does not crash boot)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/application_test.exs#Telemetry.attach/1 is idempotent at boot: a duplicate handler id does not raise"
        status: pass
    human_judgment: false
  - id: D3
    description: "A span emitted through the default pipeline (no scoped buffer, no manual attach) persists to Postgres after Buffer.flush_now/1 -- the SC#2 proof"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/application_test.exs#a span emitted through the default pipeline persists to Postgres after Buffer.flush_now/1"
        status: pass
    human_judgment: false
  - id: D4
    description: "config :scoria, Scoria.Observe, enabled: false removes Buffer from the boot children list and skips the boot attach"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/application_test.exs#config :scoria, Scoria.Observe, enabled: false removes Buffer from the boot children list and skips the boot attach"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-13
status: complete
---

# Phase 53 Plan 01: Wire Buffer + Boot Attach into Scoria.Application Summary

**`Scoria.Observe.Buffer` now boots as a supervised child of `Scoria.Application` and `Scoria.Observe.Telemetry.attach/1` fires on boot, so spans emitted by Phases 51/52 persist to Postgres in a real host app instead of firing into a void.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-13T17:20:00Z (approx)
- **Completed:** 2026-07-13T17:33:23Z
- **Tasks:** 2
- **Files modified:** 3 (`lib/scoria/application.ex`, `test/scoria/application_test.exs`, `CHANGELOG.md`)

## Accomplishments

- `Scoria.Observe.Buffer` is now a supervised child of `Scoria.Supervisor`, gated on `config :scoria, Scoria.Observe, enabled: false` (absent key = enabled-by-default), and boots in every environment including `:prod` (unlike `maybe_reconciler/0`'s test-only exclusion).
- `Scoria.Observe.Telemetry.attach/1` (default arg `Buffer`) is called during `Scoria.Application.start/2`, tolerating `{:error, :already_exists}` so a duplicate handler id can never crash boot.
- New public `Scoria.Application.observe_children/0` (`@doc false`) exposes the children-builder output as a real test seam.
- `test/scoria/application_test.exs` proves the literal SC#2 claim end-to-end: a span emitted via `:telemetry.execute/3` with no scoped buffer and no manual attach, flushed via `Scoria.Observe.Buffer.flush_now/0` (default name), reads back from Postgres via `Scoria.Repo.get_by!/2`.
- CHANGELOG documents the behavior change for adopters: spans that were previously inert outside tests now persist automatically, with an `enabled: false` opt-out.

## Task Commits

1. **Task 1: Wave-0 test — Buffer supervision + boot attach + default-pipeline persistence** - `1fd6d83c` (test, RED)
2. **Task 2: Wire Buffer + boot attach into Scoria.Application** - `266b6cad` (feat, GREEN)

**Plan metadata:** pending (this SUMMARY commit)

## Files Created/Modified

- `test/scoria/application_test.exs` - 4 tests proving Buffer supervision, idempotent boot attach, default-pipeline persistence, and the `enabled: false` opt-out
- `lib/scoria/application.ex` - `maybe_observe_buffer/0`, public `observe_children/0` (`@doc false`), `safe_attach_observe_telemetry/0`
- `CHANGELOG.md` - new `### Added` entry under `## [Unreleased]` documenting the automatic-boot behavior change

## Decisions Made

- `maybe_observe_buffer/0` gates on `Application.get_env(:scoria, Scoria.Observe, [])[:enabled] != false` (absent key = ON), deliberately not `Mix.env()` — per D-00a the Buffer must boot in `:prod` too.
- `observe_children/0` is public (`@doc false`) so tests use a real seam instead of reaching into a private function; `maybe_observe_buffer/0` delegates to it.
- `safe_attach_observe_telemetry/0` match-and-ignores both `:ok` and `{:error, :already_exists}` — a boot crash from a duplicate handler id would take the entire host app down (T-53-08, threat register mitigation).
- **Deliberately did NOT mark `EVENT-01` complete in `.planning/REQUIREMENTS.md`.** `EVENT-01` ("tool/prompt/retrieval/guardrail are emitted as real child spans") appears in this plan's `requirements` frontmatter alongside 6 of the other 7 plans in this phase (53-02, 53-03, 53-05, 53-06, 53-07, 53-08). This plan only wires the boot-time persistence prerequisite (SC#2) -- it does not itself emit any child spans -- so running `gsd-tools query requirements.mark-complete EVENT-01` would have prematurely flipped the checkbox to done while 6+ plans still need to land. Reverted via `git checkout -- .planning/REQUIREMENTS.md` before this commit; left for whichever plan actually delivers the last piece of EVENT-01 (or the phase-close reconciliation) to mark complete.

## Deviations from Plan

None - plan executed exactly as written. One out-of-scope, pre-existing test-isolation flake was discovered during full-suite verification and logged (not fixed) per the executor's scope boundary rule — see below.

## Issues Encountered

- **Worktree had no `deps/`/`_build/` for this Elixir project.** Symlinked `deps/` from the sibling main-repo checkout (identical `mix.lock`, verified via `diff`) to avoid a redundant network fetch, ran `mix deps.get`/`mix compile` to build a worktree-local `_build/test`, and removed the symlink after verification completed. No `deps/`/`_build/` artifacts were staged or committed (both are gitignored).
- **`test/scoria/warning_inventory/capture_parity_test.exs` full-suite-only flake.** `mix test --warnings-as-errors` (full suite) reported `1206 tests, 1 failure` — a subprocess-spawning warning-capture test raced under full parallel load. Re-ran in isolation immediately after: `2 tests, 0 failures`. Confirmed pre-existing and unrelated to this plan's files (matches the documented SEED-004 test-code-determinism debt). Logged in `.planning/phases/53-structured-child-spans-write-time-bound/deferred-items.md`, not fixed (out of scope for this plan's `files_modified`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 53 SC#2 is satisfied: every downstream plan in this phase (53-02..53-08) can now be verified against a real, boot-wired span pipeline instead of a hand-synthesized scoped-buffer test rig. `Scoria.Application.observe_children/0` is available as the canonical seam for any future test that needs to assert on the default-pipeline boot behavior. No blockers.

## Self-Check: PASSED

- FOUND: lib/scoria/application.ex
- FOUND: test/scoria/application_test.exs
- FOUND: CHANGELOG.md
- FOUND: .planning/phases/53-structured-child-spans-write-time-bound/53-01-SUMMARY.md
- FOUND commit: 1fd6d83c (test, RED)
- FOUND commit: 266b6cad (feat, GREEN)
- FOUND commit: 46bb90c5 (docs, SUMMARY + deferred-items)

---
*Phase: 53-structured-child-spans-write-time-bound*
*Completed: 2026-07-13*
