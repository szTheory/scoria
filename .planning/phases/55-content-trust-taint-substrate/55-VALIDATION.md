---
phase: 55
slug: content-trust-taint-substrate
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-27
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + StreamData (property tests) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/scoria/trust/ test/scoria/mcp/envelope_test.exs test/scoria/spotlight_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command scoped to the touched module's test file
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Seeded from RESEARCH.md `## Validation Architecture`. Planner refines Task IDs/commands to the final PLAN.md task breakdown.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-* | 01 | 1 | TAINT-01 | — | Absent/junk trust metadata reads `"untrusted"` (fail-closed); only `"trusted"` reads trusted | unit | `mix test test/scoria/trust_test.exs` | ❌ W0 | ⬜ pending |
| 55-01-* | 01 | 1 | TAINT-01 | — | `most_restrictive/2` monotonic law — a scanner may only ADD taint, never launder untrusted→trusted | property | `mix test test/scoria/trust/scan_test.exs` | ❌ W0 | ⬜ pending |
| 55-01-* | 01 | 1 | TAINT-01 | — | `reembed_source`/`reindex_source` idempotent w.r.t. trust (does not revert to untrusted) | unit | `mix test test/scoria/knowledge_test.exs` | ❌ W0 | ⬜ pending |
| 55-02-* | 02 | 2 | TAINT-02 | — | Envelope wrap fires AFTER `reconcile_budget`/`emit_sre_telemetry`; `{:error,_}` passes through unwrapped | unit | `mix test test/scoria/mcp/executor_test.exs` | ❌ W0 | ⬜ pending |
| 55-02-* | 02 | 2 | TAINT-02 | — | Flag off ⇒ `{:ok, value}` byte-identical to 0.1.3; flag on ⇒ `{:ok, %Envelope{}}`; replay stub matches live shape | unit | `mix test test/scoria/mcp/envelope_test.exs` | ❌ W0 | ⬜ pending |
| 55-03-* | 03 | 2 | TAINT-03 | — | Trusted content passes byte-identical; nonce/marker verified absent from body; structured ⇒ `:delimit`, prose ⇒ `:datamark` | unit | `mix test test/scoria/spotlight_test.exs` | ❌ W0 | ⬜ pending |
| 55-04-* | 04 | 3 | TAINT-04 | — | NoOp default = byte-identical current behavior; scanner raise/timeout ⇒ `%Verdict{tier:"untrusted"}` (fail-closed) | unit | `mix test test/scoria/trust/scan_test.exs` | ❌ W0 | ⬜ pending |
| 55-04-* | 04 | 3 | TAINT-04 | — | 8 `scoria.trust.*`/`scoria.spotlight.*` keys registered in `attribute_registry/0` + canary sorted-list test updated | unit | `mix test test/scoria/observe/semconv_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/trust_test.exs` — fail-closed reader (absent/junk/valid), `normalize_tier/1`, `put_tier/2`
- [ ] `test/scoria/trust/scan_test.exs` — monotonic law (property), error isolation, timeout fail-closed
- [ ] `test/scoria/mcp/envelope_test.exs` — accessors total over `t() | term()`, idempotent `wrap/2`, flag on/off shapes
- [ ] `test/scoria/spotlight_test.exs` — technique selection, nonce absence, byte-identical trusted passthrough
- [ ] Existing `test/scoria/observe/semconv_test.exs` — extend pinned registry canary with 8 new keys

*ExUnit + StreamData already present; no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real BYO scanner (Rebuff/LlamaGuard) integration | TAINT-04 | No detector ships in-lib (scope doctrine); only the seam is testable in-repo | A host implements `Scoria.Trust.Scanner`, registers via `config :scoria, :content_scanner`, and confirms verdicts tag traces — out-of-lib |

*All in-lib phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
