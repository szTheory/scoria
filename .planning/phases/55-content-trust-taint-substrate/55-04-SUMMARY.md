---
phase: 55-content-trust-taint-substrate
plan: 04
subsystem: trust
tags: [trust, taint, elixir, behaviour, task-supervisor, fail-closed, security]

requires:
  - phase: 55-01
    provides: "Scoria.Trust leaf vocabulary (tiers/0, default_tier/0, tier_key/0, normalize_tier/1, tier/1, trusted?/1, put_tier/2)"
provides:
  - "Scoria.Trust.Scanner behaviour (@callback scan/2) + Scoria.Trust.Scanner.NoOp default"
  - "Scoria.Trust.Verdict struct (@enforce_keys [:tier]) with score/reason_code/scanner + closed reason_code enum normalizer"
  - "Scoria.Trust.Scan orchestration module: monotonic taint law (D-19) + fail-closed error/timeout isolation (D-20)"
  - "Scoria.Trust.scan/2 public per-leg delegator"
  - "Scoria.Trust.TaskSupervisor dedicated boot child"
affects: [55-05, 56, 57]

tech-stack:
  added: []
  patterns:
    - "Config-swap scanner registration mirroring Orchestrator's req_llm_module precedent (per-call context override + Application.get_env fallback)"
    - "Bounded Task.Supervisor.async_nolink/2 + Task.yield/2 + Task.shutdown/2 isolation, mirroring MCP.Executor's timeout discipline, on a DEDICATED Task.Supervisor to avoid a Knowledge->MCP coupling"
    - "Monotonic taint resolution via an order-map (most_restrictive/2) -- the mathematically-enforced no-laundering guarantee"
    - "try/catch kind,reason around the host scanner call (catches raise/throw/exit uniformly) as defense-in-depth alongside Task.yield's own {:exit,_} handling"

key-files:
  created:
    - lib/scoria/trust/scanner.ex
    - lib/scoria/trust/verdict.ex
    - lib/scoria/trust/scan.ex
    - test/scoria/trust/scanner_test.exs
    - test/scoria/trust/verdict_test.exs
    - test/scoria/trust/scan_test.exs
  modified:
    - lib/scoria/trust.ex
    - lib/scoria/application.ex

key-decisions:
  - "A scanner returning {:ok, :not_scanned} is treated internally as a maximally-trusted verdict (tier: \"trusted\") so the monotonic law's most_restrictive/2 naturally passes incoming_tier through unchanged -- avoids a separate no-op code path duplicating the monotonic resolution logic."
  - "Scoria.Trust.Scan normalizes BOTH the incoming_tier and the scanner-returned verdict tier through Trust.normalize_tier/1 before comparing -- a scanner returning a junk/non-enum tier value (e.g. a typo) fails closed to \"untrusted\" rather than being compared literally, closing a would-be bypass where a junk tier string could accidentally sort as more-trusted in the order map."
  - "Scan.scan/2 emits NO telemetry of its own -- per D-21, trace tagging is a fixed-projector attribute group attached to the EXISTING span at each minting site (Knowledge.retrieve/2, MCP.Executor in Plan 05), not a new event owned by Scan. This keeps the NoOp path a true zero-overhead, zero-emission no-op and avoids a duplicate/competing telemetry surface with Plan 05's projector."

requirements-completed: [TAINT-04]

coverage:
  - id: D1
    description: "Scoria.Trust.Scanner behaviour (@callback scan/2) + Scoria.Trust.Scanner.NoOp default returning {:ok, :not_scanned}; registration mirrors req_llm_module (Application.get_env + per-call context override)"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/scanner_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoria.Trust.Verdict struct (@enforce_keys [:tier], fields tier/score/reason_code/scanner) + closed reason_code enum normalizer (fallback :unknown)"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/verdict_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dedicated Scoria.Trust.TaskSupervisor boot child, separate from Scoria.MCP.TaskSupervisor, live after application boot"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/scanner_test.exs#boot: Scoria.Trust.TaskSupervisor"
        status: pass
    human_judgment: false
  - id: D4
    description: "Monotonic taint law (D-19): resolved = most_restrictive(incoming_tier, verdict_tier), exhaustively proven over all 4 tier combinations, including an adversarial scanner attempting to launder untrusted->trusted"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/scan_test.exs#monotonic taint law (D-19) -- exhaustive 4-combination enumeration"
        status: pass
    human_judgment: false
  - id: D5
    description: "Fail-closed error/timeout isolation (D-20): raise/throw/exit/{:error,_}/malformed-return/timeout all resolve to untrusted + a distinguishing reason_code, caller never crashes"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/scan_test.exs#fail-closed error isolation (D-20) and #fail-closed timeout isolation (D-20)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Scoria.Trust.scan/2 public per-leg delegator returns the same resolved result as Scoria.Trust.Scan.scan/2; grep confirms scan.ex has zero Scoria.MCP coupling"
    requirement: "TAINT-04"
    verification:
      - kind: unit
        ref: "test/scoria/trust/scan_test.exs#Scoria.Trust.scan/2 delegator (D-18)"
        status: pass
      - kind: other
        ref: "grep -n \"Scoria.MCP\" lib/scoria/trust/scan.ex (returns nothing)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-27
status: complete
---

# Phase 55 Plan 04: Scan Engine (Scanner Behaviour + Verdict + Monotonic/Fail-Closed Scan Orchestration) Summary

**BYO `Scoria.Trust.Scanner` behaviour + `NoOp` default, `Scoria.Trust.Verdict` struct, and `Scoria.Trust.Scan` orchestration enforcing the monotonic taint law (a scanner can only add taint) and fail-closed error/timeout isolation (a scanner failure never crashes the caller and never gains trust) — no detector ships in-lib.**

## Performance

- **Duration:** ~10 min
- **Tasks:** 2 (both auto, tdd="true")
- **Files modified:** 8 (6 created, 2 modified)

## Accomplishments

- `Scoria.Trust.Scanner` — the BYO behaviour (`@callback scan(content, context) :: {:ok, Verdict.t()} | {:ok, :not_scanned} | {:error, term()}`) and its shipped `NoOp` default, which always returns `{:ok, :not_scanned}` — byte-identical current behavior, zero overhead, nothing emitted (D-16, D-17).
- `Scoria.Trust.Verdict` — `@enforce_keys [:tier]` struct with `tier`, `score` (host-only, never persisted), `reason_code` (atom), `scanner` (module) fields, plus `reason_codes/0` and `normalize_reason_code/1` implementing the closed enum `~w(prompt_injection moderation_flag untrusted_source scanner_error scanner_timeout unknown)` with `:unknown` fallback (D-21).
- `Scoria.Trust.Scan` — the orchestration engine. Resolves the registered scanner (context override → `Application.get_env(:scoria, :content_scanner, NoOp)`), short-circuits with zero overhead when the scanner is `NoOp`, and otherwise runs the host scanner inside a bounded `Task.Supervisor.async_nolink/2` + `Task.yield/2` + `Task.shutdown/2` on its OWN dedicated `Scoria.Trust.TaskSupervisor` (not `Scoria.MCP.TaskSupervisor` — no `Knowledge → MCP` coupling, D-18/D-23).
- **Monotonic taint law (D-19)**, the single most security-critical invariant in the phase: `resolved = most_restrictive(incoming_tier, verdict_tier)` via an order-map (`untrusted` = 0, `trusted` = 1, lower wins). Both `incoming_tier` and the scanner's returned tier are normalized through `Trust.normalize_tier/1` before comparison, so even a junk/typo'd tier value from a scanner fails closed rather than being compared literally. Proven exhaustively over all 4 tier combinations plus a dedicated adversarial test where a scanner unconditionally claims `"trusted"` and the law refuses the upgrade.
- **Fail-closed error/timeout isolation (D-20)**: any scanner `raise`, `throw`, `exit`, `{:error, _}`, or a malformed/unrecognized return value resolves to `%Verdict{tier: "untrusted", reason_code: :scanner_error}`; a scanner that sleeps past the bounded timeout resolves to `%Verdict{tier: "untrusted", reason_code: :scanner_timeout}`. The calling process never crashes in any of these paths — proven by five dedicated fail-mode tests plus a live `Process.alive?(self())` assertion.
- `Scoria.Trust.scan/2` — a thin public per-leg delegator to `Scoria.Trust.Scan.scan/2` (D-18), documented as an ordinary runtime "invoke" edge rather than a compile-time structural dependency, so `Scoria.Trust` stays free of `alias Scoria.Knowledge` / `Scoria.MCP` / `Scoria.Observe` (D-02/D-23) while still exposing the scan seam on the leaf module.
- `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}` added to `Scoria.Application`'s boot children, alongside the existing MCP and Workflow supervisors.

## Task Commits

1. **Task 1: Scanner behaviour + NoOp + Verdict struct + Scoria.Trust.TaskSupervisor** — `1307381f` (feat, tdd)
2. **Task 2: Scoria.Trust.Scan orchestration — monotonic law + fail-closed error/timeout isolation** — `95104816` (feat, tdd)

_Both tasks landed test + implementation together in a single commit each (tests were written alongside the implementation and both were green before committing — see TDD Gate Compliance note below)._

## Files Created/Modified

- `lib/scoria/trust/scanner.ex` — `Scoria.Trust.Scanner` behaviour + `Scoria.Trust.Scanner.NoOp`.
- `lib/scoria/trust/verdict.ex` — `Scoria.Trust.Verdict` struct + `reason_codes/0`/`normalize_reason_code/1`.
- `lib/scoria/trust/scan.ex` — `Scoria.Trust.Scan` orchestration: scanner resolution, bounded Task isolation, monotonic law, fail-closed conversion.
- `lib/scoria/trust.ex` — added the `scan/2` thin public delegator.
- `lib/scoria/application.ex` — added `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}` to the boot children.
- `test/scoria/trust/scanner_test.exs` — NoOp behavior, `content_scanner` registration default/override, `Scoria.Trust.TaskSupervisor` boot liveness.
- `test/scoria/trust/verdict_test.exs` — `@enforce_keys` enforcement, `reason_code` closed-enum normalization.
- `test/scoria/trust/scan_test.exs` — exhaustive monotonic law enumeration, adversarial laundering attempt, five fail-closed error/timeout modes, `{:ok, :not_scanned}` pass-through, `Scoria.Trust.scan/2` delegation parity, score-never-leaks assertion, NoOp zero-telemetry assertion.

## Decisions Made

- `{:ok, :not_scanned}` is internally represented as a maximally-trusted verdict (`tier: "trusted"`) so it flows through the SAME `most_restrictive/2` monotonic resolution as every other verdict, rather than a separate short-circuit branch — one code path, not two, for "scanner contributed no additional taint."
- Both `incoming_tier` and the scanner's returned `verdict.tier` are normalized via `Trust.normalize_tier/1` before the monotonic comparison — a scanner returning a non-enum tier value (typo, bug, or hostile) fails closed to `"untrusted"` rather than being compared as a literal string against the order-map (which would `Map.fetch!` and raise, or worse, silently misorder).
- `Scoria.Trust.Scan` emits zero telemetry of its own. Per D-21, `scoria.trust.*` trace tagging is a fixed-projector attribute group attached to the EXISTING span at each minting site (`Knowledge.retrieve/2`, `MCP.Executor` — both Plan 05's job), not a new telemetry event owned by `Scan`. This keeps the `NoOp` path a genuinely zero-overhead, zero-emission no-op and avoids a competing/duplicate telemetry surface ahead of Plan 05's projector wiring.
- The internal `try/catch kind, reason` wrapper around the host scanner call is a belt-and-suspenders layer alongside `Task.yield`'s own `{:exit, _}` handling — both paths converge on the same `fail_closed(:scanner_error, scanner)` outcome, so a raising/throwing/exiting scanner is covered twice rather than relying on a single mechanism.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed a literal `Scoria.MCP` substring from `scan.ex`'s moduledoc that tripped the plan's own acceptance-criteria grep gate**
- **Found during:** Task 2, immediately after the first green test run and warnings-as-errors compile
- **Issue:** The moduledoc's prose explaining "why a dedicated `Scoria.Trust.TaskSupervisor` instead of reusing the MCP one" named `Scoria.MCP.TaskSupervisor` literally, which made `grep -n "Scoria.MCP" lib/scoria/trust/scan.ex` (the plan's own acceptance criterion, verifying zero `Knowledge → MCP` coupling) return a match — a false positive on a documentation string, not an actual code dependency, but it violated the letter of the plan's verification command.
- **Fix:** Reworded the moduledoc to describe the same rationale ("deliberately NOT the tool-execution supervisor used elsewhere in the codebase") without the literal `Scoria.MCP` substring. No functional code change — `scan.ex` never `alias`es or references `Scoria.MCP` anywhere; this was purely a docstring wording fix.
- **Files modified:** `lib/scoria/trust/scan.ex`
- **Commit:** Landed within `95104816` (Task 2 commit; the sequence was write → test green → compile clean → discover grep-gate false-positive → fix wording → re-verify tests/compile/grep all green → commit).

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug/verification-gate fix, no functional change)
**Impact on plan:** Doc-wording only; no scope creep, no behavior change. All `must_haves.truths` and `must_haves.prohibitions` from the plan frontmatter are satisfied.

## TDD Gate Compliance

Each task's test file and implementation were authored together and verified green before the single atomic commit for that task, rather than as separate RED-then-GREEN commits. This satisfies the plan's per-task `tdd="true"` requirement (tests exist, prove the described behavior, and are green) but does not produce a separate `test(...)` commit preceding each `feat(...)` commit in git history. This plan's frontmatter is `type: execute` (not `type: tdd`), so the stricter plan-level RED/GREEN/REFACTOR gate sequence does not apply — task-level `tdd="true"` was satisfied by test-and-implementation co-authorship + passing verification, not by commit-order gating (consistent with Plan 55-01's precedent).

## Issues Encountered

None beyond the grep-gate wording fix documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Scoria.Trust.Scan` and `Scoria.Trust.scan/2` are ready for Plan 05 to wire into the two taint-minting chokepoints: `Knowledge.retrieve/2` (batch-scan the result set) and `MCP.Executor` (scan tool output at envelope creation). The `Scan.scan/2` API (`content`, `context` map with `:content_scanner`/`:incoming_tier`/`:timeout` keys) was deliberately kept simple enough that batch scanning at retrieval is a straightforward `Enum.map` over per-chunk calls — no redesign needed.
- `Verdict.reason_code` (normalized, closed enum) and `Verdict.tier` (resolved) are exactly the two fields Plan 05's `Semconv.trust_attributes/1` projector needs to tag the RETRIEVER/tool spans — `Verdict.score` is deliberately never populated by `Scan`, so Plan 05 cannot accidentally thread it into a trace even if it tried.
- Cross-phase note (D-22, recorded for Phase 57): a scan failure/timeout marks content `untrusted` with `reason_code` `:scanner_error`/`:scanner_timeout` — Phase 57's confluence gate must branch on `reason_code` to distinguish content-untrusted from infra-failure-untrusted; not enforced this phase.
- No blockers. Scoped verification (`mix test test/scoria/trust/scanner_test.exs test/scoria/trust/verdict_test.exs test/scoria/trust/scan_test.exs`) is green (32/32), `mix compile --warnings-as-errors` is clean, and the app boots correctly with the new `Scoria.Trust.TaskSupervisor` child (confirmed live via `Process.whereis/1` in the scanner test suite).

---
*Phase: 55-content-trust-taint-substrate*
*Completed: 2026-07-27*

## Self-Check: PASSED

All 8 created/modified files confirmed present on disk (`lib/scoria/trust/scanner.ex`, `lib/scoria/trust/verdict.ex`, `lib/scoria/trust/scan.ex`, `lib/scoria/trust.ex`, `lib/scoria/application.ex`, `test/scoria/trust/scanner_test.exs`, `test/scoria/trust/verdict_test.exs`, `test/scoria/trust/scan_test.exs`). Both task commits confirmed in `git log` (`1307381f`, `95104816`). Scoped test suite green (32/32, `mix test test/scoria/trust/scanner_test.exs test/scoria/trust/verdict_test.exs test/scoria/trust/scan_test.exs`), `mix compile --warnings-as-errors` clean, `grep -n "Scoria.MCP" lib/scoria/trust/scan.ex` returns nothing, and the app boots correctly with `Scoria.Trust.TaskSupervisor` live.
