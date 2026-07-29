---
phase: 57-confluence-escalation-gate
plan: 02
subsystem: agent-security
tags: [elixir, confluence-gate, lethal-trifecta, grading, configuration]

# Dependency graph
requires:
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "classify/1's exfiltration_path clause, %Confluence.Evidence{}, and the wave-1 checkpoint decisions (D-25, D-50) this plan does not re-decide"
  - phase: 57-confluence-escalation-gate
    plan: 03
    provides: "%Scoria.Trust.Verdict{}.scanner_tier — the evidence field the untrusted-content leg's grading tests exercise (synthetic witnesses in this plan; the real wiring into confluence_input/2 is a later plan's job)"
provides:
  - "Scoria.Confluence.classify/1 total over all eight D-05 leg-vector combinations, with the terminal :unevaluable clause now genuinely unreachable by construction"
  - "combinations/0 + normalize_combination/1 and the domain-owned reason_codes/0 + normalize_reason_code/1 enum (D-09), without widening Semconv.guardrail_reason_codes/0"
  - "grades/0 + grade/1 — the D-29 weakest-evidence-wins grading ladder, promoted to public functions and fail-closed for unrecognized witness sources (D-30)"
  - "decide/2 — grade + resolved config -> allow/escalate/block, reusing guardrail_decisions/0's vocabulary verbatim without a Semconv edge (D-03)"
  - "resolve_config/1 — the live D-32/D-33 configuration surface (tighten-only per-call, may-loosen app-env, shipped defaults) and validate_app_env/0 (D-34), wired into Scoria.Runtime.Params.start/2 as a loud, early, never-raising refusal"
affects: [57-05, 57-06, 57-07, 57-08, 57-09, 57-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Weakest-evidence-wins grading ladder as a pure function over a leg-witness map, ranked by a fixed grade_rank lookup, fail-closed to the weakest grade for any unrecognized witness source (mirrors Trust.normalize_tier/1's junk-value fallback idiom but inverted: unknown -> weakest, not unknown -> strongest)"
    - "Tighten-only-over-may-loosen-over-shipped-default three-rung config resolution, structurally distinct from Runtime.Rails's last-writer-wins two-rung ladder because the top rung here is request-adjacent (context), not host source code"
    - "ETS log-once guard (local to Scoria.Confluence, not shared with Runtime.Rails) for both invalid-value and unknown-key warnings, never raising and never called from Application.start/2"

key-files:
  created: []
  modified:
    - lib/scoria/confluence.ex
    - lib/scoria/runtime/params.ex
    - test/scoria/confluence_test.exs

key-decisions:
  - "classify/1's evidence.decision field is left nil for all combinations in this plan (including exfiltration_path, where plan 01's tracer had hardcoded \"escalate\") -- decide/2 is the correct, grade-aware way to compute a disposition, and hardcoding \"escalate\" regardless of grade would be actively wrong once non-declared-grade exfiltration_path inputs become reachable in a later plan's executor wiring. The current executor (MCP.Executor.confluence_gate/3) pattern-matches on evidence.grade, not evidence.decision, so this is a non-breaking simplification, not a regression."
  - "evidence.reason_code is now derived from whichever lit leg's :source matches the overall computed grade (leg_reason_code/4), rather than only ever being set by classify/1's own opts. This is what makes the D-30 cascade-four test (malformed scanner tier -> grade scanner_infra, reason_code :scanner_malformed) meaningful: the reason code rides the evidence only when it belongs to the leg that actually determined the grade."
  - "resolve_config/1 and validate_app_env/0 build a local ETS log-once table (:scoria_confluence_warned_keys) rather than reusing Runtime.Rails's, since Scoria.Confluence's D-03 hygiene rule and 57-01's own hygiene test only forbid aliasing Observe/Workflows/Trust/MCP/Repo -- but coupling to Runtime.Rails's internal implementation would still be an undocumented, un-guarded cross-module dependency this leaf module should not carry."

requirements-completed: [GATE-01, GATE-04]

coverage:
  - id: D1
    description: "classify/1 is total over all eight leg-vector combinations, each resolving to its named D-05 combination string; the terminal :unevaluable clause is unreachable by construction and reason_codes/0's domain-owned enum does not widen Semconv's guardrail_reason_codes/0"
    requirement: "GATE-01"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#classify/1 -- totality over all eight leg vectors (D-05, GATE-01)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#combinations/0 and normalize_combination/1 (D-05)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#reason_codes/0 and normalize_reason_code/1 (D-09)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#Semconv guardrail enums are untouched (D-09)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A grade is assigned by the weakest evidence backing the lit legs, in the fixed weakest-first order, exactly one grade per evaluation, and an unrecognized witness source fails closed to the weakest grade rather than the strongest"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#grades/0 and grade/1 -- weakest-evidence grading ladder (D-29) --only grading"
        status: pass
    human_judgment: false
  - id: D3
    description: "decide/2 maps grade + resolved config to allow/escalate/block: the declared grade escalates under shipped defaults, the three weak grades allow, strict:true extends escalation to the weak grades, and enforcement: :observe forces allow regardless"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#decide/2 -- grade + resolved config -> disposition (GATE-04)"
        status: pass
    human_judgment: false
  - id: D4
    description: "resolve_config/1 resolves the config surface live with tighten-only per-call precedence over a may-loosen app-env rung over shipped defaults, and validate_app_env/0 never raises, returning {:unknown_grade, key} for a typo'd key; Scoria.Runtime.Params.start/2 calls it as a loud early refusal, never from Application.start/2"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/confluence_test.exs#resolve_config/1 and validate_app_env/0 -- configuration surface (D-31..D-34)"
        status: pass
      - kind: unit
        ref: "test/scoria/confluence_test.exs#Scoria.Runtime.Params.start/2 wiring (D-34)"
        status: pass
    human_judgment: false

duration: 32min
completed: 2026-07-28
status: complete
---

# Phase 57 Plan 02: Total Combination Ladder, Weakest-Evidence Grading, and Config Surface Summary

**Completed `Scoria.Confluence` as a pure, dependency-free leaf: `classify/1` is now total over all eight D-05 leg-vector combinations, `grade/1`/`decide/2` implement the D-29 weakest-evidence-wins ladder with a D-30 fail-closed fix for unrecognized witness sources, and `resolve_config/1`/`validate_app_env/0` give the gate a live, tighten-only-over-may-loosen configuration surface wired into `Scoria.Runtime.Params.start/2`.**

## Performance

- **Duration:** 32 min (git-timestamp span from base commit `569370d3` to final Task 3 commit `e9388a1b`; includes worktree setup, `mix deps.get`, and full-suite verification)
- **Started:** 2026-07-28T22:15:20-04:00 (base commit)
- **Completed:** 2026-07-28T22:46:53-04:00
- **Tasks:** 3 (all `auto`/`tdd="true"` except Task 3, which is `auto`)
- **Files modified:** 3 (0 created, 3 modified)

## Accomplishments

- `Scoria.Confluence.classify/1` resolves every one of the eight possible three-bit leg-vector inputs to a named clause of the closed `combinations/0` string enum (`none`, `private_data`, `untrusted_content`, `exfil_capable`, `private_data_and_untrusted_content`, `private_data_to_egress`, `untrusted_content_to_egress`, `exfiltration_path`) -- the terminal `{:unevaluable, ...}` clause plan 01 wrote is now genuinely unreachable by construction, proven by a test that iterates all eight leg vectors and asserts none falls to it.
- `reason_codes/0` + `normalize_reason_code/1` add a domain-owned, closed 8-atom enum (`:unclassified_default`, `:approval_pending`, `:approval_granted`, `:approval_denied`, `:confluence_rejected`, `:scanner_malformed`, `:unknown`, `:confluence_resolver_fallthrough`), mirroring `Trust.Verdict.reason_codes/0`'s shape without ever widening `Semconv.guardrail_reason_codes/0` -- pinned by a byte-identical assertion against the pre-phase Semconv enum values.
- `grades/0` + `grade/1` promote plan 01's private `weakest_grade/3` to public functions implementing the D-29 weakest-evidence-wins ladder in the fixed order `unclassified -> scanner_infra -> default_tier -> declared`, and `decide/2` maps a grade plus a resolved config map to `allow`/`escalate`/`block` -- reusing `guardrail_decisions/0`'s vocabulary verbatim as hand-written strings, honoring the `enforcement: :observe` incident kill switch and the `strict: true` opt-in that extends escalation to the three weak grades.
- `resolve_config/1` resolves the D-32 configuration surface (`enforcement`, `declared`, `unclassified`, `scanner_infra`, `default_tier`, `strict`, `unattributed`) live from a three-rung ladder: per-call `context[:confluence]` is tighten-only, application environment may loosen or tighten relative to the shipped default, and the shipped default enforces only for the `declared` grade. `validate_app_env/0` mirrors `Runtime.Rails`'s never-raise / never-boot-check doctrine with its own local ETS log-once guard, and `Scoria.Runtime.Params.start/2` now calls it as a loud, early refusal at run creation -- never from `Application.start/2`.
- A malformed VALUE for a known config key (e.g. `declared: :bogus`) falls back silently to that grade's shipped default at the hot path inside `resolve_config/1` and logs once, so a configuration typo can never refuse a live tool call -- only an unrecognized KEY refuses run creation via `validate_app_env/0`.

## Task Commits

1. **Task 1: Total eight-value combination ladder and the domain-owned reason-code enum** - `fb2e2f03` (feat)
2. **Task 2: Weakest-evidence grading and the four absence-of-evidence cascades** - `acf6f2c2` (feat)
3. **Task 3: Configuration surface, tighten-only precedence, and never-raising validation** - `e9388a1b` (feat)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/confluence.ex` - Total 8-clause `classify/1`; `combinations/0`/`normalize_combination/1`; `reason_codes/0`/`normalize_reason_code/1`; `grades/0`/`grade/1`; `decide/2`; `resolve_config/1`/`validate_app_env/0`; local ETS log-once table
- `lib/scoria/runtime/params.ex` - `start/2`'s `with` chain gains `:ok <- validate_confluence_config()` as its final gate before run-attrs assembly; new private `validate_confluence_config/0` translating `{:unknown_grade, key}` into an `{:error, ...}` the `with` chain already propagates
- `test/scoria/confluence_test.exs` - Rewritten as a table-driven suite: 8 explicit per-leg-vector `classify/1` tests, enum-fallback tests, a 9-test `:grading`-tagged describe block, `decide/2` disposition tests, `resolve_config/1`/`validate_app_env/0` tests (module flipped to `async: false` for the global `Application.env` mutation), and source-scan tests for the `params.ex` wiring

## Decisions Made

- **`evidence.decision` left `nil` for every `classify/1` combination in this plan, including `exfiltration_path`** (plan 01 had hardcoded `decision: "escalate"` there). See `key-decisions` in the frontmatter for the full rationale: `decide/2` is the correct, grade-aware disposition function, and a hardcoded `"escalate"` would be wrong for a non-declared-grade `exfiltration_path` input once such inputs become reachable through a later plan's executor wiring. `MCP.Executor.confluence_gate/3` (unmodified this plan) pattern-matches on `evidence.grade`, never `evidence.decision`, so this is a non-breaking cleanup, not a regression -- verified by the full `executor_confluence_test.exs` suite staying green.
- **`evidence.reason_code` is now derived from the culprit leg** -- whichever lit leg's `:source` matches the overall computed grade contributes its own `:reason_code` (if any) onto the evidence, via `leg_reason_code/4`. This is what gives D-30's cascade-four test (a malformed scanner tier grading `scanner_infra` with reason code `:scanner_malformed`, never `declared`) a real, non-coincidental signal.
- **Local ETS log-once table, not a shared one with `Runtime.Rails`** -- `Scoria.Confluence` stays a dependency-free leaf per D-03; the hygiene test only forbids aliasing `Observe`/`Workflows`/`Trust`/`MCP`/`Repo`, but reusing `Runtime.Rails`'s internal ETS table would still be an undocumented cross-module coupling this leaf module should not carry.
- **`start_handoff/3` was NOT wired to `validate_confluence_config/0`** -- the plan's acceptance criteria names `start/2` specifically ("no call to it exists in any application-start callback"), and `start_handoff/3` is out of this plan's literal scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the inherited weakest-grade fallback that graded an unrecognized/foreign leg witness source as `"declared"` (the strongest, escalating grade)**
- **Found during:** Task 2, while promoting plan 01's private `weakest_grade/3` to the public `grade/1`
- **Issue:** Plan 01's `weakest_grade/3` used `cond do :unclassified in sources -> ... :scanner_infra in sources -> ... :default_tier in sources -> ... sources != [] -> "declared" ... end` -- any lit leg whose `:source` value did NOT match one of the three recognized weak categories silently fell through to `"declared"`, the strongest, escalation-triggering grade. This directly contradicts D-30's stated threat model ("absence of trustworthy evidence must never be presented to the enforcement ladder as presence of it") -- a garbage, malformed, or foreign witness source would have been treated as the STRONGEST possible evidence rather than the weakest.
- **Fix:** `grade_for_source/1` now has an explicit fallback clause `defp grade_for_source(_other), do: "unclassified"` -- any witness source outside the four recognized categories (`:unclassified`, `:scanner_infra`, `:default_tier`, `:declared`) fails closed to `"unclassified"`, the weakest grade.
- **Files modified:** `lib/scoria/confluence.ex` (`grade_for_source/1`)
- **Verification:** New test `"an unrecognized leg witness source fails closed to the weakest grade rather than \"declared\" (D-30)"` in `test/scoria/confluence_test.exs`, tagged `:grading`.
- **Committed in:** `acf6f2c2` (part of the Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for correctness against D-30's own stated threat mitigation. No scope creep -- the fix is scoped entirely to the grading function this task was already promoting to a public API, and is covered by a new, dedicated test.

## Issues Encountered

None beyond the Rule 1 fix above. The fresh worktree needed `mix deps.get` per the documented recipe; the pgvector test database on `localhost:55432` was already running and reachable (`nc -z localhost 55432`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **`Scoria.Confluence` is complete as a pure, dependency-free leaf.** `classify/1`, `grade/1`, and `decide/2` are all ready for plan 57-05 (wave 4) to compose inside `MCP.Executor.confluence_gate/3`, per that plan's own `read_first` citation of this plan's three functions.
- **`resolve_config/1` and `validate_app_env/0` are ready for host configuration.** `Scoria.Runtime.Params.start/2` already refuses run creation loudly on a typo'd `config :scoria, Scoria.Confluence` key; a later plan wiring `resolve_config/1` into the executor's live evaluation path does not need to touch this validation.
- **The full test suite is green modulo one documented pre-existing flake.** `mix test` (1641 tests, 3 doctests) reports exactly one failure: `Scoria.WarningInventory.CaptureParityTest`'s injected-warning assertion, which fails only at full-suite scope (confirmed still passing in isolation, 2/2) -- this is the pre-existing SEED-004-class flake documented in the phase's own test-environment briefing, not a regression from this plan.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` is empty.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-28*
