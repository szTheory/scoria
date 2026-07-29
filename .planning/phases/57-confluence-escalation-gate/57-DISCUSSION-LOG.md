# Phase 57: Confluence Escalation Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `57-CONTEXT.md` — this log preserves the alternatives considered and who killed what.

**Date:** 2026-07-28
**Phase:** 57-confluence-escalation-gate
**Areas discussed:** Confluence scope & evaluation model; Pause mechanism; Enforcement default & never-brick cascade; Audit, replay & approval lifecycle; Vocabulary, Semconv contract & Phase 58 hand-off

**Method (no interactive Q&A — the user's standing preference for phase gray areas):**
1. Loaded PROJECT/REQUIREMENTS/STATE plus the three prior CONTEXT files (55, 56, 56.1), extracting the three cross-phase obligations written *for* Phase 57 (55 D-22, 56 D-06, 56.1 D-22's six points).
2. Five parallel `gsd-advisor-researcher` agents, one per gray area, each aware of the other four and required to name the cross-area dependencies it created.
3. Orchestrator reconciled **five direct conflicts** between them into `57-SYNTHESIS-DRAFT.md`, marking every reconciliation as unverified and naming them as the primary attack surface.
4. Two adversarial red-team agents on the **reconciled synthesis** (code-truth lens; adopter-brick/cascade/coherence lens).
5. Orchestrator verified the single highest-stakes finding (F-01) directly in the code before accepting it.
6. Final locked spec; red-team changes marked `(revised)`.

**Outcome shape:** 54 locked decisions, **11 of them reversed or materially rewritten by the red team**, one phase split (57 / 57.1), two requirement wording amendments, and one previously-unknown Phase 55 defect promoted to a blocking prerequisite.

---

## Confluence scope & evaluation model (GATE-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-call only | All three legs true on one resolved `%Classification{}` | |
| Per-run accumulation of all three legs | Full session-scoped trifecta | |
| **Per-run for the two exposure legs; per-call for exfil** | Exposure accumulates, capability does not | ✓ |
| Session-scoped (`session_id`) rather than run-scoped | Wider blast radius | |

**Locked:** D-11. Per-call cannot see the actual attack (private data at step 2, untrusted content at step 3, exfil at step 7). Accumulating all three would pause a later harmless read once any exfil-capable tool had run. The split is what makes GATE-02's "pause before the exfil action" pause the *right* call; per-call survives as a strict subset, not a second mode.

**Accumulator storage — rejected:** derive-on-read from sibling `step.result_envelope` (destroyed at step completion — see below); `run.error_envelope` (wiped by `complete_step/3`); `run.metadata` (viable, rejected on ownership hygiene); `:persistent_term`/ETS (not replayable, not multi-node); six typed scalar columns.

**Red-team reversals here were severe.** The draft's accumulator would have silently disabled the gate three different ways: first-witness `||` ordering combined with weakest-evidence grading pins a leg to its weakest grade for the whole run (ordering luck, or an attacker choosing which tool runs first, silences the gate permanently); writing the full three-leg map freezes the first call's `false` values under any merge order; and a nullable jsonb column with no default makes `'{...}'::jsonb || NULL` = NULL, killing the accumulator for every pre-migration row silently. All three fixed in D-15.

---

## Pause mechanism (GATE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Executor creates approval + returns `{:error, …}`; adopter re-runs | Simplest | |
| New `Workflows.escalate_run/3` mirroring `halt_run/3` | Symmetric with 56.1 | |
| Synchronous in-executor block/await | Most direct reading of GATE-02 | |
| **Signal from executor → Runtime's existing `{:waiting_for_approval, …}` outcome** | Reuses the only resumable pause | ✓ |

**Locked:** D-19/D-20. `escalate_run/3` is killed by an asymmetry that is structural, not cosmetic: `halt_run/3` works only because six clamps make `"halted"` un-overwritable, permissible solely because a halt is terminal — an escalation must be *released*, so the equivalent clamps need a release point that does not exist. Option (a) is killed by an inherited 56.1 invariant: `fail_step/3` writes `"failed"`, which is not in the pause set, so human thinking time accrues as *active* time and the run halts on the timeout rail at the first dispatch after approval. Option (d) is killed three times over (two nested 5 s `Task.yield` bounds and the `:inline` Reconciler executing inside its own `handle_call`).

**Notes — the draft's mechanism was inverted by measurement.** It chose `raise` over an exit signal on the stated rationale that an exit "emits a SASL crash report on a deliberate control-flow path." The red team measured both: `exit({:shutdown, term})` from `async_nolink` yields cleanly with **no** log line, and `try/rescue _ ->` **does not catch an exit**. So the draft had picked the *more* swallowable of the two — a raise is defeated by the single most common defensive pattern in adopter code. Reversed to an exit (D-20).

The draft's stated reason for rewording GATE-02 was also wrong: the executor *can* drive a run-lifecycle transition (it already calls `halt_run/3`). What it cannot do is stop the handler continuing after the decision. The rewording stands; its justification was corrected (D-18).

The draft's process-dictionary marker survived, but only after its proposed alternative was tested and refuted — there is genuinely no channel from `Runtime` into the executor's `context` (the host must hand-forward). It was strengthened to resolve through `$callers`, which covers `Task.async`/`async_stream`; raw `spawn` is the honest telemetried residual (D-21).

---

## Enforcement default & never-brick cascade (GATE-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Single boolean `enforce` | Simplest | |
| Flat mode enum `:off \| :observe \| :strict` | Conventional | |
| **Four-grade evidence model × three dispositions** | Grades by weakest evidence backing the lit legs | ✓ |
| Per-tenant policy rows (`BudgetEngine` shape) | Richest | |

**Locked:** D-29. A boolean or flat enum cannot express "block the deliberate declaration, not the missing one" — and that distinction is the entire never-brick argument. Two prior phases wrote the fields (`source` as `@enforce_keys`, `reason_code` as a closed enum) specifically so this branch would be constructable.

**Cascade count went from two to four.** The two inherited ones (56 D-06's `unclassified_default`, 55 D-22's scanner infra failure) were joined by `default_tier` — found *independently by two blind researchers*, the strongest signal in the synthesis — and by `Trust.normalize_tier/1`'s junk fallback, which would grade a *buggy* scanner as positive evidence (found by red team; produced the new `scanner_malformed` code).

**The default itself was reversed, and the two red teams split on it.** The code-truth lens defended the orchestrator's `enforcement: :observe`; the brick lens overturned it on four grounds and won: "ungated" is a defined term of art in the very `ReleaseGate` doctrine GATE-04 cites (it fires only on *evidence absent*), so the draft's reading makes SC#4's own qualifier vacuous; hard-forcing every grade to `allow` is fail-**open**, contradicting GATE-04's literal "fail-closed" adjective; v3.7 is unreleased so the `declared` population is empty and the enforcing default is a *provable* no-op at upgrade — never-brick satisfied structurally rather than by a switch; and the rollout evidence is one-sided (CSP `Report-Only` is terminal, Istio `PERMISSIVE` meshes rarely reach `STRICT`, and Kubernetes explicitly reversed admission `failurePolicy` from `Ignore` to `Fail` at v1 GA). Locked as D-31, with a hard precondition that D-01 lands first, and an explicit flag that ROADMAP SC#4 / GATE-04 need a wording amendment (D-54).

**Rung 2 of the adoption ladder was inverted.** The draft claimed `require_tool_classification: true` "structurally eliminates" the unclassified cascade. It is bypassable on two shipped call sites, and even where it works, "eliminate your false positives by making 100% of your undeclared tool calls error" is an outage with a security rationale (D-35).

---

## Audit, replay & approval lifecycle (GATE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Audit row per evaluation | Maximum inspectability | |
| **Audit row on escalate + block only** | Proportional to decisions, not tool calls | ✓ |
| New `event_type` per decision (`confluence.approved`, …) | Explicit | |
| New columns on `ai_audit_outbox_events` / `ai_approvals` | Typed | |

**Locked:** D-37/D-38/D-39/D-40. Per-evaluation is killed by arithmetic — the trifecta fires on 100% of legacy traffic, so it is a row per tool call forever. A parallel decision vocabulary is the opposite of GATE-03's "consistent with existing approval evidence" and splits the auditor's query in two. New columns buy nothing over the existing `blocker_kind` + `blocker_audit_outbox_event_id` pair, which `Connectors.Auth` already uses for exactly this job.

**Notes:** the draft wrote the row only on escalation; the red team showed that leaves every `block` with **no durable record anywhere**, which fails GATE-03's own word "decision" (D-38). Replay needed nothing new — all three existing dispositions are already correct downstream of `replay_gate/3`, which structurally *defuses* 56 D-02's fail-open fall-through rather than mitigating it (D-43). Re-asking a human on replay was rejected on Temporal's determinism law; auto-approving on replay was rejected because it builds a bypass primitive a bug could reach on a live run.

**Approval expiry was moved out of the phase.** 56.1 D-22.2 assigned it here, and the draft accepted. The red team found the design does not work: with no sweeper, expiry materializes only when a decider acts — while the expired approval is *simultaneously suppressed* from the pending list, so no decider ever reaches it. Net state is strictly worse than never expiring. Deferred to 57.1, where Phase 58's stuck-escalation queue can supply the human trigger.

---

## Vocabulary, Semconv contract & Phase 58 hand-off

| Option | Description | Selected |
|--------|-------------|----------|
| `Scoria.MCP.Confluence` | Tool-namespaced | |
| `Scoria.Gate.Confluence` | Gate-namespaced | |
| **`Scoria.Confluence`** | Root leaf, matching `Scoria.Trust` | ✓ |
| `Scoria.Trifecta` / `Scoria.MCP.LethalTrifecta` | Uses the community coinage | |

**Locked:** D-03. Three researchers proposed three different names. Root wins: the legs are cross-cutting (the untrusted leg is also minted at `Knowledge.retrieve/2`) and Phase 58's screen is run-scoped. The coinage is banned from every API name — Scoria's own machine-checked doc contracts forbid the literal strings, and the brandbook bans alarm-coded language ("make safety & governance normal, not an alarm").

**`Observe.Guardrail` — the anticipated caller declines.** Its moduledoc names Phase 57 as its future caller, so this was a genuine fork. Declined on cost: a 5th `guardrail_names/0` value breaks an exact-match test, every confluence reason code would normalize to `"unknown"` plus a warning plus fallback telemetry *on every evaluation*, and the fixed 5-key projector structurally cannot carry `combination` — the one thing Phase 58 must render. Not a coverage gap, because the pause routes through a path that already emits a GUARDRAIL span (D-10).

**The reason-code invariant held.** `Semconv.guardrail_reason_codes/0` is documented as "not invented" and 56.1 already deferred a whole span rather than widen it. Phase 57 takes Phase 55's sanctioned escape hatch — a domain-owned closed enum with its own normalizer (D-09).

**Notes:** the draft's attribute emission site was found unemittable. It pinned `scoria.confluence.*` to `[:scoria, :tool, :completed]`, which fires only inside the success branch of `execute_live` — while the gate runs *before* `execute_live`. So on escalate and block no attribute would ever have reached a span, and the registry key `scoria.confluence.approval_ref` ("escalate only") was **provably dead**. This is the same "decorative hook" defect class the Phase 55 red team caught. Fixed in D-08.

---

## Findings that changed the phase's shape

**The blocking prerequisite (D-01), verified by the orchestrator directly.** `MCP.Executor.scan_tool_output/2` calls `Trust.scan/2` without `:incoming_tier`; `Scan.scan/2` defaults it to `"untrusted"` and `most_restrictive/2` is min-wins — so **every tool output clamps to `"untrusted"` regardless of what the scanner returns**, and `%Verdict{}` has no field preserving the scanner's own tier. `Knowledge.retrieve/2` does it correctly. Consequence: a zero-config adopter's untrusted leg is permanently `default_tier` (gate inert), while an adopter who follows the ladder and installs a real scanner gets `declared` grade on 100% of calls (gate pauses everything). There is no configuration in between. Promoted from "Phase 55 defect" to a Phase 57 prerequisite.

**The step-envelope durability claim is false (recorded as Phase 58 obligation #1).** `complete_step/3` wholesale-replaces `step.result_envelope` from the handler's return and `retry_step/1` zeroes it, so Phase 55's `"scoria.taint"` and Phase 56's `"scoria.classification"` merges survive only for failed, timed-out, and currently-paused steps — destroyed on every successful one. Both prior phases' test suites assert on this column by calling the executor directly, never through `Runtime → complete_step`, which is why it shipped. The executor moduledoc's "ALWAYS persisted" claim needs correcting.

**Scoria's own reference handler does not forward the keys the gate depends on**, which turned the draft's `unattributed: :deny` default into this phase's brick (D-22).

**Scope split.** Streams with no shared files and no shared failure modes — approval expiry, the adopter guide, the standalone copy module — moved to 57.1, mirroring the 56 → 56.1 precedent.

---

## Deferred / redirected

- Approval expiry, `guides/capabilities/confluence-gate.md`, standalone `ScoriaWeb.ConfluenceCopy` → **Phase 57.1**.
- Six cross-phase obligations recorded for **Phase 58** (read path, per-tool source, the four `SECURITY-BOUNDARY.md` residuals, the now-load-bearing stuck-escalation queue, the no-policy-builder constraint, and the grade-segmented denominator).
- Semantic fast path bypassing the gate at run level; the example app being unable to demo the feature; `:persistent_term` staleness on hot reload; multi-node Reconciler registration → **follow-ups, non-blocking**.
- Injection/moderation detectors, per-user tool allowlists, opinionated content policy → **permanently host-owned** per scope doctrine.
