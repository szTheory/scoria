# Phase 38: Replay-Safe Execution & Tool Modes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22T22:41:27Z
**Phase:** 38-replay-safe-execution-tool-modes
**Areas discussed:** replay taxonomy, approval-sensitive replay behavior, external-write behavior, replay escape hatches

---

## Replay Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Flat run enum | Keep `live | replay | historical_stubbed` as the main run-level taxonomy | |
| Run intent + seam disposition | Keep run intent as `live | replay` and record per-seam `execute_live | historical_stub | blocked` | ✓ |
| VCR-style record matrix | Use cassette-style modes such as `none | once | new_episodes | all` | |
| Deterministic sandbox engine | Introduce a stricter replay-only execution model around side-effect-free orchestration | |

**User's choice:** Run intent + seam disposition, with low-impact defaults shifted left.
**Notes:** The recommendation set was requested as a one-shot synthesis. `historical_stubbed` should not remain the primary run-level concept because one replay run may mix seam outcomes safely.

---

## Approval-Sensitive Replay

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse historical approval as live authority | Old approval implicitly authorizes live replay | |
| Block again every time | Every replayed approval seam pauses again before any effect | |
| Historical stub by default, fresh replay approval for live rerun | Use historical truth when exact source evidence exists; otherwise require a new replay-scoped approval | ✓ |
| Explicit replay approval at every approval seam | Always require a new replay approval even when stubbing would suffice | |

**User's choice:** Historical stub by default, with fresh replay approval required for any live rerun.
**Notes:** Historical approvals remain evidence only. Replay approval becomes a distinct scope, not an overloaded interpretation of past approval rows.

---

## External-Write Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Hard block all external effects | Never allow replay to cross external-effect boundaries | |
| Historical stub all external effects | Always use prior evidence instead of live effects | |
| Risk-class mixed policy | Pure/internal rerun; external reads stub by default; writes/exec/admin/destructive stub if exact evidence exists, else block | ✓ |

**User's choice:** Risk-class mixed policy with a strict fail-closed boundary.
**Notes:** No silent fallthrough from missing stub evidence to live execution. Local Scoria policy/classification outranks remote hints.

---

## Replay Escape Hatches

| Option | Description | Selected |
|--------|-------------|----------|
| No escape hatch | Replay is always sealed from live effects | |
| Per-run explicit override at replay creation | Create a replay branch with a narrow immutable allowlist for specific tools | ✓ |
| Global/install-time replay-live allowlist | Ambient config allows live replay for classes of tools | |
| Per-step ad hoc unseal | Allow mid-run “go live now” mutation | |

**User's choice:** Per-run explicit override at replay creation only.
**Notes:** No mid-run unsealing and no broad global ambient replay-live switch. Live override still requires current policy checks, fresh replay-scoped approval, and idempotency protection.

---

## the agent's Discretion

- Exact schema placement for `replay_disposition` and replay-specific reason fields
- Exact badge/microcopy wording for blocked, historical stub, and live override consumed
- Exact idempotency-key strategy for replay-live effects

## Deferred Ideas

- Deterministic sandbox engine beyond the current workflow runtime
- Mid-run replay unsealing UX
- Broad global replay-live config as a normal product default
