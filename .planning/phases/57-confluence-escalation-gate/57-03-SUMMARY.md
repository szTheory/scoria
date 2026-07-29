---
phase: 57-confluence-escalation-gate
plan: 03
subsystem: agent-security
tags: [elixir, ecto, trust-taint, mcp, scanner, confluence-gate]

# Dependency graph
requires:
  - phase: 55-content-trust-taint-substrate
    provides: "%Scoria.Trust.Verdict{}, Scoria.Trust.Scan.scan/2, the monotonic taint law (D-19), and Scoria.Trust.tier/1's fail-closed reader default"
  - phase: 57-confluence-escalation-gate
    plan: 01
    provides: "the confluence_gate/3 insertion point and %Scoria.Confluence.Evidence{} this plan's untrusted-content leg now feeds real information into"
provides:
  - "%Scoria.Trust.Verdict{scanner_tier} evidence field -- the scanner's pre-clamp opinion, carried alongside the clamped `tier`, never as authority"
  - "The repaired MCP.Executor.scan_tool_output/2 mint site: a real scanner's clean verdict on tool output now resolves the trusted tier instead of being unconditionally clamped to untrusted"
  - "verdict.scanner_tier threaded onto the [:scoria, :tool, :completed] telemetry event (scoria.trust.scanner_tier) and persisted to step.result_envelope['scoria.taint']['scanner_tier'], both as strings, for a later plan's confluence gate to read"
affects: [57-04, 57-05, 57-06, 57-07, 57-08, 57-09, 57-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Conditional incoming_tier seeding at a mint site: 'trusted' only when a real (non-NoOp) scanner is about to evaluate content; left unset (fail-closed default) when no scanner is installed -- preserves both 'a clean scanner verdict is reachable' and 'no scanner still fails closed' simultaneously"
    - "scanner_tier captured BEFORE most_restrictive/2's fold, mirroring how Verdict.reason_code/scanner are already captured pre-clamp -- evidence fields never touch the clamped tier computation"

key-files:
  created: []
  modified:
    - lib/scoria/trust/verdict.ex
    - lib/scoria/trust/scan.ex
    - lib/scoria/mcp/executor.ex
    - test/scoria/trust/verdict_test.exs
    - test/scoria/mcp/executor_test.exs

key-decisions:
  - "incoming_tier is seeded 'trusted' at the mint site ONLY when the resolved content_scanner is not Scanner.NoOp; the plan's <action> text describes this as an unconditional set, but every one of the plan's own <behavior>/<acceptance_criteria> bullets (real-scanner-clean -> trusted, real-scanner-malicious -> untrusted, NoOp -> still Trust.default_tier()) is only jointly satisfiable if the seed is conditional on scanner presence -- implemented literally against those bullets, not the shorthand action-prose"
  - "scanner_tier is threaded onto trust_attrs and the persisted taint map by hand (Map.put with a literal 'scoria.trust.scanner_tier' / 'scanner_tier' string key) rather than widening Semconv.trust_attributes/1's fixed four-key projector, since lib/scoria/observe/semconv.ex is outside this plan's files_modified scope"

requirements-completed: [GATE-01]

coverage:
  - id: D1
    description: "%Scoria.Trust.Verdict{} carries a scanner_tier field holding the scanner's own pre-clamp opinion; the NoOp path leaves it nil, distinguishable from a scanner that returned the default tier"
    requirement: "GATE-01"
    verification:
      - kind: unit
        ref: "test/scoria/trust/verdict_test.exs#scanner_tier evidence field (D-01b, plan 57-03)"
        status: pass
      - kind: unit
        ref: "test/scoria/trust/verdict_test.exs#tier's clamp semantics for a representative set of incoming/scanner pairs are byte-identical to the pre-phase monotonic law"
        status: pass
    human_judgment: false
  - id: D2
    description: "A real scanner returning a clean verdict on tool output now resolves the trusted tier; a malicious verdict still resolves untrusted; the two outcomes differ -- the untrusted-content leg carries information for the first time"
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_test.exs#a real scanner judging tool output clean resolves the trusted tier -- the pre-phase defect pinned this to untrusted"
        status: pass
      - kind: integration
        ref: "test/scoria/mcp/executor_test.exs#a real scanner judging tool output malicious still resolves the untrusted tier, and the two outcomes differ"
        status: pass
    human_judgment: false
  - id: D3
    description: "The shipped NoOp scanner path still yields Trust.default_tier(), and Trust.tier/1's reader default is unaffected -- the mint-site fix does not weaken fail-closed behavior for adopters with no scanner installed"
    requirement: "GATE-01"
    verification:
      - kind: integration
        ref: "test/scoria/mcp/executor_test.exs#the shipped NoOp scanner path still yields Scoria.Trust.default_tier() (D-17 unchanged)"
        status: pass
      - kind: unit
        ref: "test/scoria/mcp/executor_test.exs#the metadata reader path's default is unchanged by the mint-site fix"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-07-28
status: complete
---

# Phase 57 Plan 03: Mint-Site Taint Repair + scanner_tier Evidence Summary

**Repaired the Phase 55 mint-site defect that pinned every tool output to `untrusted` regardless of scanner verdict, and gave `%Trust.Verdict{}` a `scanner_tier` evidence field so the confluence gate can grade on evidence quality without weakening the monotonic taint law.**

## Performance

- **Duration:** 16 min (git-timestamp span from base commit `3d8c9f80` to final Task 2 commit `16dd908c`)
- **Started:** 2026-07-28T21:51:32-04:00 (base commit)
- **Completed:** 2026-07-28T22:07:37-04:00
- **Tasks:** 2 (both `auto`/`tdd="true"`)
- **Files modified:** 5 (0 created, 5 modified)

## Accomplishments

- `%Scoria.Trust.Verdict{}` gains `:scanner_tier` — the scanner's own PRE-CLAMP opinion, captured in `Scoria.Trust.Scan.scan/2` before `most_restrictive/2` folds it against `incoming_tier`. `nil` on the `Scanner.NoOp` short-circuit distinguishes "no scanner ran" from "a scanner ran and returned the default tier" (D-30's `default_tier` vs `scanner_infra` cascade). `most_restrictive/2`'s min-wins ranking and the Phase 55 monotonic law (D-19) are byte-identical, proven by a table-driven regression test across all four incoming/scanner tier combinations.
- `Scoria.MCP.Executor.scan_tool_output/2` now seeds `:incoming_tier` at the trusted identity on the context handed to `Trust.scan/2` whenever a real (non-`NoOp`) scanner is resolved — mirroring `Knowledge.retrieve/2`'s `aggregate_incoming_tier/1` pattern of computing the incoming tier explicitly rather than relying on the callee's default. Before this fix, `:incoming_tier` was never set, so `Trust.Scan.scan/2`'s own fail-closed default (`"untrusted"`) combined with `most_restrictive/2`'s min-wins fold pinned EVERY tool output to `untrusted` regardless of what a real scanner returned — the entire untrusted-content leg carried zero information.
- The shipped `Scanner.NoOp` path is untouched: when no scanner is installed, `:incoming_tier` is deliberately left unset so `Trust.Scan.scan/2` keeps resolving `Trust.default_tier()` — an adopter with no scanner configured sees no behavior change, and the shipped `declared: :escalate` confluence default does not brick them with a 100% pause rate on install.
- `verdict.scanner_tier` now rides alongside the existing `trust_attrs` on the `[:scoria, :tool, :completed]` telemetry event as `"scoria.trust.scanner_tier"` (a string, hand-threaded since `Semconv.trust_attributes/1`'s fixed four-key projector is out of this plan's file scope) and is persisted onto `step.result_envelope["scoria.taint"]["scanner_tier"]`, so a later plan's confluence gate can read the scanner's pre-clamp opinion without any Semconv changes.
- D-31's hard precondition — do not ship the enforcing `declared: :escalate` default without this fix — is now satisfied: a correctly installed scanner returning a clean verdict resolves `trusted`, proven by a regression test that asserts the clean and malicious outcomes differ (the exact "warning sign" RESEARCH.md names: a suite that asserts `untrusted` for both a clean and a malicious fixture proves nothing).

## Task Commits

1. **Task 1: Add the :scanner_tier evidence field to %Trust.Verdict{}** - `8a6b73b4` (feat)
2. **Task 2: Thread an explicit incoming tier at the tool-output mint site** - `16dd908c` (fix)

_Note: this SUMMARY.md is committed separately per the worktree execution protocol (STATE.md/ROADMAP.md are owned by the orchestrator, not this plan)._

## Files Created/Modified

- `lib/scoria/trust/verdict.ex` - `:scanner_tier` added to `defstruct`/`@type t` (nilable string, NOT in `@enforce_keys`); moduledoc documents it as evidence-only, never authority
- `lib/scoria/trust/scan.ex` - Real-scanner branch captures `scanner_tier` before `most_restrictive/2`'s fold; NoOp branch sets `scanner_tier: nil`
- `lib/scoria/mcp/executor.ex` - `scan_tool_output/2` conditionally seeds `:incoming_tier` (trusted, only when a real scanner is resolved); new `put_scanner_tier_attr/2` and `maybe_put_scanner_tier/2` thread `verdict.scanner_tier` (as a string) onto telemetry and the persisted taint map; `persist_taint/3` and `persist_taint_to_step/4` (arity bumped from 3) extended to carry `scanner_tier` through
- `test/scoria/trust/verdict_test.exs` - New `EchoScanner` fixture + `scanner_tier evidence field` describe block: clamp-vs-scanner_tier distinction, NoOp nil, and a table-driven 4-combination monotonic-law pin
- `test/scoria/mcp/executor_test.exs` - New `CleanScanner` fixture + `mint-site incoming_tier fix` describe block: clean-resolves-trusted, malicious-resolves-untrusted-and-differs, NoOp-still-default, reader-default-unchanged, and scanner_tier-flows-to-telemetry-and-taint

## Decisions Made

- **Conditional `incoming_tier` seeding (not literally unconditional):** the plan's `<action>` prose reads as "always set `:incoming_tier` to trusted," but its own `<behavior>`/`<acceptance_criteria>` demand FOUR simultaneously-true outcomes: real-scanner-clean → trusted, real-scanner-malicious → untrusted, the two differ, AND the shipped NoOp path still yields `Trust.default_tier()`. Those are only jointly satisfiable if the trusted seed applies exclusively when a real (non-`NoOp`) scanner is about to evaluate the content — an unconditional seed would make the NoOp path resolve `trusted` instead of the required `untrusted`. Implemented against the literal, testable acceptance criteria rather than the shorthand action-prose; every criterion is now covered by a passing test.
- **`scanner_tier` threaded by hand, not through `Semconv.trust_attributes/1`:** that projector is a closed, `Semconv`-owned fixed-key contract, and `lib/scoria/observe/semconv.ex` is outside this plan's `files_modified` scope. Rather than widening a shared, dependency-free projector as an incidental side effect, `scanner_tier` is added to the `trust_attrs` map and the persisted taint map directly via small local helpers, keeping the change scoped to `executor.ex` as the plan specifies.
- **Persisted taint's `scanner_tier` key stays a plain string, never a bare atom:** the plan explicitly warns against propagating the pre-existing `verdict.reason_code`-as-bare-atom pattern to any confluence-facing value. `scanner_tier` is already a `String.t() | nil` from `Trust.Scan.scan/2` (never an atom), so both the telemetry attribute and the persisted jsonb value satisfy this by construction.

## Deviations from Plan

None — Rule 1/2/3 auto-fixes were not needed; the "conditional seeding" decision above is a literal-acceptance-criteria implementation choice, not a bug fix or scope addition, and is documented under Decisions Made rather than as a deviation.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **D-31's hard precondition is satisfied.** A correctly installed scanner returning a clean verdict on tool output now resolves `trusted`, proven by a regression test asserting the clean and malicious outcomes differ — the confluence gate's `declared: :escalate` default (later plans in this phase) can now safely ship without giving the first scanner-adopting host a 100% pause rate.
- **`scanner_tier` is available for the gate to read.** It rides `[:scoria, :tool, :completed]` telemetry as `"scoria.trust.scanner_tier"` and `step.result_envelope["scoria.taint"]["scanner_tier"]`, both plain strings (or absent when nil) — ready for a later plan's confluence gate to grade on evidence quality without touching the monotonic `tier` clamp.
- **`Semconv.ex` is untouched.** If a later plan wants `scanner_tier` to flow through `Semconv.trust_attributes/1`'s canonical fixed-key projector (rather than the hand-threaded `Map.put` this plan uses), that is an open, unmade decision for whichever plan next touches `lib/scoria/observe/semconv.ex`.
- **No blockers.** `examples/support_copilot/deps/**/_build/**/source.dag` checked clean (no dirty rebar3 artifacts) prior to this SUMMARY being written; `git status --short` is empty.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-28*

## Self-Check: PASSED

All 6 claimed files found on disk; all 3 commits (`8a6b73b4`, `16dd908c`, `d2ae5438`) found in git history. `examples/support_copilot/deps` clean, `git status --short` empty.
