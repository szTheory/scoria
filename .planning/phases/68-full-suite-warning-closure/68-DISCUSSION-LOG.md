# Phase 68: Full-Suite Warning Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 68-full-suite-warning-closure
**Areas discussed:** CI gate staging, fix vs re-baseline, adoption WAE in CI, baseline ledger closeout
**Mode:** All areas, advisor-style research synthesis (user requested one-shot recommendations)

---

## CI gate staging

| Option | Description | Selected |
|--------|-------------|----------|
| A — Staged only | `warning_ratchet.test --warnings-as-errors` after handoff; plain `mix test` until green | ✓ (68-01) |
| B — Staged + allow-fail full WAE | Parallel telemetry job | |
| C — Direct flip | Replace `mix test` with WAE immediately | ✓ (68-03 target) |
| D — Two-step PR sequence | A then C when green | ✓ (overall shape) |

**User's choice:** D — staged CI gate (68-01), then full WAE flip (68-03) when local green.
**Notes:** Rejects B (allow-fail). Extends ci_policy_contract_test. Fix WR-01/WR-02 before CI wiring. Closeout order unchanged.

---

## Remaining debt — fix vs re-baseline

| Option | Description | Selected |
|--------|-------------|----------|
| A — Fix everything incl. LiveView | Zero baseline rows | |
| B — Fix p2 only; renew LV baseline | Partial | partial element |
| C — Ratchet only; renew umbrella row | | |
| D — Hybrid fix-first | p2 code-fix; bounded p4; no host-proof baseline | ✓ |

**User's choice:** D — fix p2 host-proof at source; bounded `render_async` sweep for p4; baseline LiveView row only if runtime-only remains (expiry 2026-07-31); delete full-suite umbrella on success.
**Notes:** No `@compile` suppressions on overlay. No renewing full-suite catch-all.

---

## Adoption lane WAE in CI

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full suite WAE only | Implicit adoption coverage | ✓ (68-03 target) |
| B — adoption WAE before handoff | Duplicate run | |
| C — adoption WAE after handoff | Awkward order + duplicate | |
| D — Plain adoption + ratchet WAE | Bridge without duplicate step | ✓ (68-01) |

**User's choice:** D for Phase 68 CI; reject B/C. Document adoption↔ratchet mapping in operator_verification.md.
**Notes:** adoption_test_files ⊆ high_signal_wae_paths. Plain `mix test.adoption` stays behavioral closeout step.

---

## Baseline ledger closeout

| Option | Description | Selected |
|--------|-------------|----------|
| A — Empty Accepted | On full success | ✓ |
| B — Move to Resolved During v2.6 | Audit trail | ✓ |
| C — Renew kept debt only | If partial | ✓ (LiveView only) |
| D — Per-cluster Accepted rows | | |

**User's choice:** B + A on success; C only for proven LiveView remainder; reject D. Same PR as CI flip for 2026-06-07 expiry. inventory `--write` as evidence, not CI gate.

---

## Claude's Discretion

- `mix test.knowledge --warnings-as-errors` timing
- LiveView helper extraction vs per-test `render_async`
- Memoization for `high_signal_path?/1`
- Merge 68-02/68-03 if early full WAE green

## Deferred Ideas

- CI-03 documentation — Phase 69
- Explicit adoption WAE CI step — rejected
- allow-fail parallel WAE — rejected
- Per-cluster markdown baseline rows — rejected
