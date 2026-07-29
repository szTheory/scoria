---
phase: 57
slug: confluence-escalation-gate
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-07-29
verified: 2026-07-29
---

# Phase 57 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register origin: `register_authored_at_plan_time: true` — all 12 PLAN files carried a
`<threat_model>` block. The auditor verified that the declared mitigations exist; it did
not scan for new threats.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| tool output → taint accumulator | Untrusted tool results mint a trust tier that lights a confluence leg | Scanner verdicts, trust tiers, leg witness sources |
| `MCP.Executor` → `Runtime.execute_handler/6` | The escalation signal that pauses a step before the exfil action runs | `exit({:shutdown, {:scoria_confluence_escalation, attrs}})` |
| host context → `resolve_config/1` | Per-call enforcement rung supplied by adopter request handling | Confluence config (tighten-only) |
| approval-consume CAS | A decided approval authorizes exactly one tool call | Approval id, run id, step id, args fingerprint |
| audit outbox row → reviewer screen | Persisted escalation evidence crosses into operator-facing HTML | Combination, evidence grade, three leg sources |
| `blocker_audit_outbox_event_id` back-link | A column with no foreign key selects which evidence row is read | Audit event id, workflow run id |
| persisted jsonb → BEAM atom table | Untrusted-at-rest strings map into runtime atoms | Leg-source strings |
| evidence struct → span attributes | Gate telemetry crosses into observability storage | Closed-enum confluence attributes |
| broken-window ledger → ship gate | `/gsd-ship` is blocked by the ledger's open count | Window entry statuses |

---

## Threat Register

68 register rows / **60 distinct threats**. All four `critical` rows and the large
majority of `high` rows received deep (ASVS-L2/L3-equivalent) verification — data flow
traced and the dedicated test located and read, not merely grep-matched. `medium`/`low`
rows received L1 grep-level confirmation, per `asvs_level: 1` with `block_on: high`.

**Result: 67 closed / 1 open (non-blocking).**

Rather than restate all 68 rows, this register records the disposition summary plus every
row that is not a plain closure. The full row-by-row evidence table (each with a
`file:line` citation) is in the audit trail entry below.

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-57-19 | Elevation of Privilege | approval-consume CAS | critical | mitigate | Single-statement `Repo.update_all` CAS keyed on `is_nil(a.consumed_at)` (`executor.ex:419-441`); nil fingerprint fails closed at `:410`. Second-consume test `executor_confluence_test.exs:482`. | closed |
| T-57-26 | Tampering | leg accumulator merge semantics | critical | mitigate | Strictly-greater-wins SQL rank fold (`executor.ex:859-935`), not `\|\|`. Bidirectional ordering-independence test `executor_confluence_test.exs:913-917`. | closed |
| T-57-36 | Elevation of Privilege | replay reaching the gate | critical | mitigate | `replay_disposition.ex` has zero confluence references; the gate is reachable only on `replay_gate`'s `{:continue, _}`. Historical-stub test `confluence_audit_test.exs:416`. | closed |
| T-57-37 | Elevation of Privilege | approval reuse across a replay | critical | mitigate | `consume_call_scope/3`'s `where: a.workflow_run_id == ^run_id` structurally cannot match a new run. Cross-run replay test `confluence_audit_test.exs:517-561`. | closed |
| T-57-06 | Denial of Service | second exclusive row lock per tool call | medium | **accept** | Documented in `confluence.ex`'s moduledoc "Accepted limitations" — genuinely documented, not silently dropped. | closed (accepted) |
| T-57-32 | Denial of Service | second exclusive row lock per tool call | medium | **accept** | Documented at the fold, `executor.ex:833-836`, as an extension of the 56.1 D-09 precedent. | closed (accepted) |
| T-57-44 | Repudiation | pending approval on a halted run | medium | mitigate | **Declared** mitigation: the halt path resolves a pending confluence approval to a terminal status so no undecidable row survives (D-52). **Actual:** correct on the single-writer path, but not under concurrency. See the open-threat detail below. | **open — below `high` threshold (non-blocking)** |
| T-57-SC ×4 | Tampering | npm/pip/cargo installs | high | mitigate (n/a) | Zero new external dependencies: `mix.lock`'s last touch (`966d0e32`) predates all phase 57 work. | closed |
| T-57-01 … T-57-59 (all others) | Tampering / Spoofing / Repudiation / Information Disclosure / DoS / Elevation of Privilege | see audit trail | critical–low | mitigate | Verified with a `file:line` citation each — see the audit trail entry below. | closed |

*Status: open · closed · open — below `high` threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Open threat detail — T-57-44 (medium, non-blocking)

`halt_run/3` calls `resolve_pending_confluence_approvals(run)` (`lib/scoria/workflows.ex:672`)
**after** its own transaction commits, with no wrapper of its own — unlike its sibling
post-commit calls (`emit_rail_tripped/3`, `maybe_emit_rail_observed/1`), which are each
independently exception-safe. The function's only `rescue`
(`rescue _e in Ecto.StaleEntryError -> {:error, :already_halted}`, lines 681-683) wraps the
entire function body and was written for the earlier `FOR UPDATE` read/write race, not this
call. Two concrete consequences:

1. If a reviewer concurrently decides the same approval `approve/3` is expiring,
   `repo.update!/1`'s `optimistic_lock` raises `Ecto.StaleEntryError`, `Enum.each` aborts
   mid-list (remaining pending confluence approvals on that run are never resolved), and
   `halt_run/3` reports `{:error, :already_halted}` even though the halt genuinely committed.
2. A non-`StaleEntryError` exception from `approve/3` is not rescued at all and crashes the
   calling process. None of the three call sites wrap it
   (`connectors/invocation.ex:116`, `workflows/runtime.ex:268,302`, `mcp/executor.ex:229`).

`test/scoria/confluence_concurrency_test.exs:472-505`'s D-52 test exercises only the
single-writer, no-race case. This is the same defect as code-review finding **CR-01**,
independently reproduced by the auditor from the code rather than inherited from the review
document.

**Disposition:** deliberately deferred with user approval, tracked at
`.planning/todos/pending/2026-07-29-halt-run-confluence-cleanup-stale-entry-race.md`.
Medium severity sits below `block_on: high`, so `threats_open: 0` and the phase is not
blocked on security grounds. Recorded as **open**, not closed — the declared mitigation
text ("no undecidable row survives") is not literally true under the race the phase itself
designed against, and marking it closed would be exactly the kind of tracking-outruns-code
laundering this phase's own verification caught once already.

---

## Unregistered Flags

| Flag | Description | Nearest Threat Mapping |
|------|-------------|------------------------|
| WR-01 | `handle_event("approve_run_scoped", ...)` (`lib/scoria_web/live/approvals_live/index.ex:161-163, 780-795`) sets `confluence_scope: "run_tool"` with **no server-side check** that the active approval is confluence-kind — the gate exists only in the template's `:if={confluence_approval?(@active_approval)}`. Currently **inert**: `run_tool_scope_granted?/3` (`executor.ex:474`) independently requires `blocker_kind == "confluence"` at the enforcement side, so no live privilege escalation results. But the invariant is enforced in exactly one place (client markup) with zero server-side backstop, unlike every other confluence invariant this phase ships. | Adjacent to T-57-47, but not covered by it — T-57-47's text addresses only the non-castable-column mechanism, not the handler-level authorization gap. **Recommend registering as a new threat in Phase 58** rather than accepting via inertness. |

No `## Threat Flags` section exists in any of the 12 SUMMARY.md files (grep-confirmed) — no
executor-reported new attack surface to reconcile.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-57-01 | T-57-06, T-57-32 | The confluence gate adds a second exclusive row lock on the run row on top of the rail counter, doubling the serialization window that Phase 56.1's D-09 already documented as an accepted limitation. The single-statement fold holds it to one additional lock rather than two. Accepted and documented in-code (`confluence.ex` moduledoc; `executor.ex:833-836`) rather than papered over. | Phase 57 planning (D-17), auditor-confirmed 2026-07-29 | 2026-07-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Register Bookkeeping Defect

Plans 57-10 and 57-11 independently reused the IDs **T-57-51, T-57-52, T-57-53, T-57-54 and
T-57-55**, so each of those five IDs denotes **two distinct threats** with different
components and, in three cases, different STRIDE categories. Both members of every collision
were verified separately (10 verifications across the 5 IDs) and both are recorded in the
audit trail. A threat-ID lookup by ID alone in this phase's register is ambiguous — future
plans in this milestone should allocate from a phase-wide counter rather than restarting
per plan.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-29 | 68 rows / 60 distinct | 67 | 1 (non-blocking) | `gsd-security-auditor` (sonnet), ASVS L1, `block_on: high` |

**Deep-verified (ASVS-L2/L3-equivalent — data flow traced, dedicated test located and read):**
T-57-01, 02, 03, 04, 07, 08, 09, 12, 13, 16, 19, 20, 23, 26, 27, 28, 29, 30, 33, 34, 35, 36,
37, 38, 40, 41, 42, 43, 46, 47, 48, 51(a), 51(b), 52(b), 53(a), 54(a), 55(a), 56, 57, 58.

**Light-verified (L1 grep-level confirmation):**
T-57-05, 06, 10, 11, 14, 15, 17, 18, 21, 22, 24, 25, 31, 32, 39, 45, 49, 50, 52(a), 53(b),
54(b), 55(b), 59, and the four T-57-SC rows.

**Corroborating context (established independently of this audit):** phase verification
`passed` 5/5; full suite 1748 tests with a single documented pre-existing baseline failure
(`Scoria.WarningInventory.CaptureParityTest`, WINDOWS.md entry 1); phase code review
recorded in `57-REVIEW.md`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed (1 open threat, medium severity, below the `high` block threshold)
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-29
