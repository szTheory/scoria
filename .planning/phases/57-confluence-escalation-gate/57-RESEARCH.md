# Phase 57: Confluence Escalation Gate - Research

**Researched:** 2026-07-28
**Domain:** In-process security gate over an existing Elixir/Phoenix agent-runtime executor (Ecto/Postgres-backed workflow engine, OpenTelemetry-shaped semantic-convention layer, approval/human-in-the-loop lifecycle)
**Confidence:** HIGH

## Summary

Phase 57 is not a greenfield build — it is a precisely-scoped extension of an already-shipped, heavily-tested runtime (`Scoria.MCP.Executor`, `Scoria.Workflows`, `Scoria.Observe.Semconv`, `Scoria.SRE`). The `57-CONTEXT.md` for this phase is unusually complete: 54 numbered decisions (D-01..D-54) produced by five parallel research agents and two red-team passes, with every load-bearing citation independently re-verified by the orchestrator. This RESEARCH.md's job was narrower than usual: **verify that CONTEXT.md's citations are still true against the actual worktree**, and ground the plan in real function signatures.

That verification is now done. I read and cross-checked ~40 of CONTEXT.md's most load-bearing citations directly against the source files (`executor.ex`, `workflows.ex`, `workflows/runtime.ex`, `trust.ex`/`trust/scan.ex`/`trust/verdict.ex`, `mcp/classification.ex`, `workflows/replay_disposition.ex`, `observe/semconv.ex` + its test canary, `sre.ex`, `runtime/release_gate.ex`, `runtime/rails.ex`, `workflows/run.ex`, `observe/approval.ex`, `scoria_web/ui.ex`, `scoria_web/approval_copy.ex`, `adopter_doc_contract.ex` + the guide it gates + its test, and the latest rail migration). **Every single citation checked was correct in substance; line numbers were exact in the overwhelming majority of cases and off by at most 1-4 lines in a handful (consistent with minor incremental edits between the red-team pass and now, not staleness).** No citation was found to be materially wrong. This is a strong signal CONTEXT.md's decisions are safe to plan against literally, without re-deriving them.

The single most important verified fact: **`MCP.Executor.scan_tool_output/2` (executor.ex:526-541) really does clamp every tool output to `"untrusted"`** — it calls `Trust.scan(value, Map.put(context, :content_scanner, scanner))` (line 529) without ever setting `:incoming_tier` in that map, so `Trust.Scan.scan/2` (scan.ex:67) defaults it to `Trust.default_tier()` = `"untrusted"` (trust.ex:36), and `most_restrictive/2`'s min-wins semantics (scan.ex:128-130) mean the output is permanently `"untrusted"` regardless of scanner verdict. `Knowledge.retrieve/2` gets this right (`knowledge.ex:431-434,444-448` — verified, `aggregate_incoming_tier/1` seeds `"trusted"` and is threaded through). This confirms D-01: Phase 55's untrusted-content leg is unusable at the tool-output mint site until this phase fixes it, and GATE-01/02/03/04 are inert without that fix landing first.

**Primary recommendation:** Plan this phase as CONTEXT.md's decision groups already order it — (A) fix the D-01 mint-site bug first (it is the load-bearing prerequisite for everything else), then (B) build `Scoria.Confluence` as a dependency-free leaf classifier, (C) wire the per-run leg accumulator into `MCP.Executor.execute/4`'s existing pipeline between `replay_gate/3` and `execute_live/4`, (D) implement the pause via the *existing* `Workflows.mark_waiting_for_approval/3` + a new `exit({:shutdown, ...})` signal caught in `Runtime.execute_handler/6`, (E) grade enforcement by evidence quality with `declared: :escalate` as the shipped default, (F) audit via the existing outbox/`SRE` machinery with zero new columns beyond one migration, (G) extend the existing reviewer drawer with confluence evidence rows, and (H) repair the shipped-lie guide atomically. Do not re-litigate any of D-01..D-54 — they are locked; this document exists to hand the planner exact file:line coordinates to build tasks against.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Confluence classification (`Confluence.classify/1`) | API / Backend (pure library function) | — | Dependency-free leaf module, no DB/HTTP; called synchronously inside `MCP.Executor.execute/4` |
| Per-run leg accumulation (`confluence_legs` jsonb) | Database / Storage | API / Backend (writer: `Repo.update_all`) | Durable, run-scoped, concurrency-sensitive state; must survive process crashes and be readable by replay |
| Pause / escalation signal | API / Backend (`MCP.Executor`) → Backend runtime (`Workflows.Runtime`) | — | `MCP.Executor` decides and signals via `exit/1`; `Workflows.Runtime.execute_handler/6` catches the signal and transitions run/step state — same process boundary, no network hop |
| Approval lifecycle (create/consume/resume) | API / Backend (`Scoria.Workflows`) | Database / Storage (`ai_approvals`, `ai_workflow_runs`) | Reuses the existing connector-approval machinery verbatim (D-46) — no new lifecycle function |
| Audit trail | Database / Storage (`ai_audit_outbox_events`) | API / Backend (`Scoria.SRE`) | Existing outbox pattern; one new `event_type`, no new columns |
| Reviewer UI evidence rows | Frontend Server (SSR, Phoenix LiveView) | — | `ApprovalCopy.request_rows/1`/`evidence_rows/1` render server-side, no client JS needed |
| Config resolution (enforcement grade → decision) | API / Backend | — | Read live per call, mirrors `Scoria.Runtime.Rails`'s `Application.get_env` resolution pattern (never at boot, never frozen) |
| Telemetry (`[:scoria, :gate, :confluence, :observed]`) | API / Backend (emission) | Database / Storage (persisted only via span adapters on `:completed`/`:failed`/`:timeout`) | Ephemeral unless captured by an existing adapter; the durable record is the audit row (D-38), not telemetry |

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions

All 54 decisions in `.planning/phases/57-confluence-escalation-gate/57-CONTEXT.md` (D-01 through D-54) are locked. They are reproduced in full in that file and are NOT restated here in full — the planner MUST read `57-CONTEXT.md` directly as the primary source of truth; this RESEARCH.md supplements it with independent code verification only. Below is the decision-group index for navigation:

- **Group A (D-01, D-02):** The prerequisite fix — `scan_tool_output/2`'s mint-site bug (D-01, REQUIRED, reversible-but-inert-without-it) and the honest scope limit that RAG-retrieved content does not feed the gate this milestone (D-02).
- **Group B (D-03..D-10):** Vocabulary/module shape — `Scoria.Confluence` root namespace, `classify/1` pure function, closed 8-value combination enum, deliberate fail-safe divergence from `ReplayDisposition`'s fail-open terminal clause, no "lethal trifecta" API naming, gate-emitted (not tool-span-riding) telemetry attributes, domain-owned reason-code enum, no `Observe.Guardrail.emit/1`.
- **Group C (D-11..D-17):** Evaluation model — per-run leg accumulation (exposure legs monotone, exfil leg per-call), no untaint primitive, corrected leg sourcing table, `execute/4` ordering (rail → classification → replay_gate → CONFLUENCE → execute_live), `confluence_legs` jsonb column with strongest-wins semantics, non-swallowed accumulator write failures, single-statement fold of merge+read.
- **Group D (D-18..D-28):** Pause mechanism — amended GATE-02 wording, reuse of `mark_waiting_for_approval/3`, `exit({:shutdown, ...})` signal (not `raise`), process-dictionary/`$callers` containment proof, `unattributed: :allow` default, `"waiting_for_approval"` status (not `"paused"`), halted-beats-escalated ordering, step-level pause scoping decision required at planning, atomic approval-consume CAS + three-axis `resume_run/1` widening, `retry_failed_step/2` stranding guard, concurrency/rescue requirements.
- **Group E (D-29..D-36):** Enforcement/grading — weakest-evidence grading (4 grades: `unclassified`→`scanner_infra`→`default_tier`→`declared`), four absence-of-evidence cascades, `declared: :escalate` as the SHIPPED DEFAULT (draft's `:observe` default was reversed by red-team), the full config surface, tighten-only precedence, `validate_app_env/0` never-raise doctrine, corrected 5-rung adoption ladder, one always-on telemetry event.
- **Group F (D-37..D-47):** Audit/replay — one new `event_type`, audit written on `escalate` AND `block` (never `allow`), no new outbox columns (projector not spread), `blocker_kind`/`blocker_audit_outbox_event_id` linkage, audit-row-before-approval-row ordering with explicit `dedupe_key`, zero `ReplayDisposition` additions, one index migration, reuse of all 12 existing approval artifacts, one consolidated migration.
- **Group G (D-48..D-52):** Human in the loop — reviewer drawer MUST render confluence evidence rows this phase, named-combination string mapping + test owned in Phase 57, approval-fatigue resolution required (recommend bounded per-run/per-tool/per-grade approval scope), capped pending-approvals query, halt-with-pending-approval invariant.
- **Group H (D-53, D-54):** Shipped-lie repair — three files + two contract lists must be edited atomically with the feature, plus a positive assertion so a missing edit fails loud; GATE-02/GATE-04/ROADMAP wording amendments.

### Claude's Discretion

- Private helper names, test-file layout, `%Confluence.Evidence{}` field names beyond the locked minimum set, whether grade ranking is a module attribute or function.
- `confluence_idempotency_key` shape (recommended: `"confluence:" <> sha256(run_id : tool_id : args_fingerprint : policy_key)`, mirroring `ReplayDisposition.replay_idempotency_key/2`) — a recommendation, not a lock.
- No new UI screen this phase (D-48 only adds rows to the existing drawer).

### Deferred Ideas (OUT OF SCOPE)

- **Phase 57.1:** Approval expiry (no sweeper/cron design works yet — see D-context for why), `guides/capabilities/confluence-gate.md`, standalone `ScoriaWeb.ConfluenceCopy` module.
- **Cross-phase obligations recorded for Phase 58:** Phase 58 must read `ai_workflow_runs.confluence_legs` (not `result_envelope`, which gets wholesale-replaced on step completion) for GOVERN-01's named-combination screen; per-tool trifecta classification for Phase 58 comes from `scoria.classification.*` on the TOOL span, not from anything Phase 57 emits; `SECURITY-BOUNDARY.md` (BOUND-01) must state four residuals Phase 57 cannot close; the stuck-escalation queue (56.1 D-23) becomes load-bearing; Phase 58 must render would-have-paused counts segmented by grade, never a raw firing count.
- **Follow-ups, not blocking:** the semantic fast path bypasses the gate at the run level (record as non-goal); `examples/support_copilot/` cannot demo this feature without wiring one tool through the executor; `:persistent_term` classification memoization has no reload invalidation (dev-only bite).
- **Permanently host-owned (scope doctrine):** any injection/moderation detector; per-user/per-intent tool allowlists; opinionated moderation content policy or output sanitizer.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | A confluence evaluator classifies a tainted execution path by which of the three legs are present, mirroring `ReplayDisposition`'s seam-classification style | `Scoria.Confluence.classify/1` (D-03..D-10) — verified `ReplayDisposition.resolve/5`'s `cond`→`{atom, evidence}` shape at `replay_disposition.ex:13-60`, including its fail-open terminal clause at `:58-59` which D-06 deliberately does NOT mirror |
| GATE-02 | When private-data + untrusted-content + exfil co-occur, the run escalates to approval/human-in-the-loop at `MCP.Executor` before the exfil action executes | Verified `execute/4`'s exact ordering (`executor.ex:31-63`: rail→classification→replay_gate→execute_live) — the gate slots in before `execute_live/4` at line 50 (D-14); verified `Workflows.mark_waiting_for_approval/3` exists at `workflows.ex:365-499` and `Runtime.execute_handler/6`'s `{:exit, reason}` clause at `runtime.ex:770` is the exact insertion point for the new escalation-exit clause (D-18..D-20) |
| GATE-03 | Confluence escalation decisions are audited (audit outbox) and replayable, consistent with existing approval and replay evidence | Verified `SRE.create_audit_outbox_event/1` (`sre.ex:125`), `SRE.build_audit_metadata/1`'s drop-list (not allowlist) discipline (`sre.ex:374-416`), `build_audit_dedupe_key/1`'s composition (`sre.ex:422-432`), `Approval.blocker_kind`/`blocker_audit_outbox_event_id` fields (`observe/approval.ex:19,32`) already used by `Connectors.Auth` for this exact linking job (D-37..D-47) |
| GATE-04 | Confluence enforcement has a fail-closed-but-inspectable default plus opt-in strict mode; ungated confluence emits telemetry | Verified `Runtime.ReleaseGate.handle_missing_verdict/1` (`release_gate.ex:81-93`) — the doctrine GATE-04 explicitly cites — including the `[:scoria, :release_gate, :ungated]` telemetry event and the `check(%PromptTemplate{status: "draft"})` positive-evidence-enforces clause at `release_gate.ex:20`; verified `Runtime.Rails`'s two-rung config-resolution template (`runtime/rails.ex:1-60`) as the pattern to mirror for `Scoria.Confluence`'s own config surface (D-29..D-36) |
</phase_requirements>

## Standard Stack

This phase adds **zero new external dependencies**. It is a pure extension of the existing in-repo Elixir/Phoenix/Ecto stack. No `mix install`, no Hex package additions, no npm packages.

### Core (existing, reused)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto` / `Ecto.Multi` | (already in `mix.lock`) | `confluence_legs` jsonb accumulator, `consumed_at`/`consumed_by_step_id` CAS columns, migration | Already the persistence layer for every other Phase 55/56/56.1 artifact |
| `Jason` (`@derive Jason.Encoder`) | (already in `mix.lock`) | `%Confluence.Evidence{}` serialization, matching `%Classification{}`'s existing `@derive Jason.Encoder` at `classification.ex:44` | Established project convention — verified |
| `:telemetry` | (already in `mix.lock`) | `[:scoria, :gate, :confluence, :observed]` event | Every other gate/rail/scan event in this codebase uses this idiom (verified across `executor.ex`, `trust.ex`, `sre.ex`) |

### Package Legitimacy Audit

Not applicable — no new packages are installed this phase. Skip the Package Legitimacy Gate.

## Architecture Patterns

### System Architecture Diagram

```
Tool call arrives
      │
      ▼
MCP.Executor.execute/4  (executor.ex:31)
      │
      ├─► admit_tool_call_rail/2         (rail: max_tool_calls CAS, Rails.admit_tool_call/2)
      │        │ {:ok, context}
      │        ▼
      ├─► resolve_classification/2       (executor.ex:244 — Classification.resolve/2)
      │        │ {:ok, context}  (context now carries %Classification{})
      │        ▼
      ├─► replay_gate/3                  (executor.ex:375 — ReplayDisposition.resolve/5)
      │        │ {:continue, context}    (historical_stub/blocked short-circuit here — gate never fires)
      │        ▼
      │   ╔═══════════════════════════════════════════════════════╗
      │   ║  NEW: Confluence gate slots HERE (D-14)                ║
      │   ║  1. Fold this call's legs into confluence_legs jsonb    ║
      │   ║     (single Repo.update_all(returning:) — D-17)         ║
      │   ║  2. Confluence.classify/1 → {combination, %Evidence{}}  ║
      │   ║  3. Grade by weakest evidence (D-29) → decision         ║
      │   ║  4. escalate/block → write audit row, THEN               ║
      │   ║     exit({:shutdown, {:scoria_confluence_escalation,…}}) ║
      │   ║  5. allow → fall through unchanged                       ║
      │   ╚═══════════════════════════════════════════════════════╝
      │        │ (allow)
      │        ▼
      └─► execute_live/4                 (executor.ex:305 — unaffected by escalate/block, never reached)

  Escalation signal path (separate process boundary):
  MCP.Executor (Task, async_nolink)  ──exit({:shutdown,{:scoria_confluence_escalation,attrs}})──►
  Runtime.execute_handler/6 (runtime.ex:742)
      │  new clause ABOVE the existing {:exit, reason} clause (runtime.ex:770)
      ▼
  {:ok, {:waiting_for_approval, attrs, elapsed_ms}}
      │
      ▼
  Workflows.mark_waiting_for_approval/3 (workflows.ex:365) — EXISTING, unmodified
      │  writes: run.status, step.status, checkpoint, event, Approval row,
      │  in-txn approval.requested audit row, PubSub × 2  (all 12 artifacts, D-46)
      ▼
  Reviewer drawer (approvals_live/index.ex) ── Workflows.approve/3 (workflows.ex:1043) ──►
  Workflows.Resume.resume_run/1 (resume.ex:9) ──► re-dispatches step ──► executor re-runs
      │
      ▼
  NEW: atomic approval-CONSUME CAS (D-26) — first statement inside the gate —
  matches consumed_at IS NULL AND args_fingerprint=$fp → pass through, never re-escalate
```

### Recommended Project Structure

```
lib/scoria/
├── confluence.ex                    # NEW — Scoria.Confluence, root namespace, dependency-free leaf (D-03)
├── confluence/
│   └── evidence.ex                  # NEW — %Confluence.Evidence{} struct (or inline in confluence.ex; Claude's discretion)
├── mcp/
│   └── executor.ex                  # MODIFIED — scan_tool_output/2 (D-01 fix), gate insertion (D-14), scanner_tier field usage
├── trust/
│   └── verdict.ex                   # MODIFIED — add :scanner_tier field (D-01 part b)
├── workflows/
│   ├── runtime.ex                   # MODIFIED — new {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} clause above :770
│   └── resume.ex                    # MODIFIED — retry_failed_step/2 status guard (D-27)
├── observe/
│   └── semconv.ex                   # MODIFIED — @confluence_keys, confluence_attributes/1, registry + canary additions (D-08)
└── sre.ex                           # UNMODIFIED — reused via create_audit_outbox_event/1

lib/scoria_web/
└── approval_copy.ex                 # MODIFIED — request_rows/1 / evidence_rows/1 gain confluence evidence rows (D-48)

priv/repo/migrations/
└── <timestamp>_add_confluence_columns.exs   # NEW — consolidated: confluence_legs (ai_workflow_runs),
                                              #        consumed_at/consumed_by_step_id (ai_approvals),
                                              #        event_type index (ai_audit_outbox_events)  (D-47)

guides/
└── scoria-vs-external-llm-ops.md    # MODIFIED — D-53 shipped-lie repair

lib/scoria/
└── adopter_doc_contract.ex          # MODIFIED — D-53, add positive assertion

test/scoria/
├── confluence_test.exs              # NEW — property test over all 8 combination inputs (D-05)
├── mcp/executor_test.exs            # MODIFIED — D-01 fix regression, gate ordering, escalation flow
├── workflows/runtime_test.exs       # MODIFIED — exit-clause handling
├── observe/semconv_test.exs         # MODIFIED — canary additions (44 → 49 keys), new exact-match enum tests
└── adoption_surface_test.exs        # MODIFIED — D-53 positive assertion
```

### Pattern 1: Pure classifier mirroring `ReplayDisposition.resolve/5`

**What:** A `cond`-ladder function that takes evidence structs as plain arguments (no context map, no aliasing of caller modules) and returns `{atom, %Evidence{}}`.
**When to use:** `Scoria.Confluence.classify/1`.
**Example (verified pattern from `replay_disposition.ex:13-61`):**
```elixir
# Source: lib/scoria/workflows/replay_disposition.ex:13-61 (verified in worktree)
@spec resolve(map(), map(), map(), map(), map()) :: {disposition(), map()}
def resolve(run, seam, source_evidence, approval_context, override_context) do
  # ... normalize_map/1 each operand ...
  cond do
    replay_mode?(run) == false ->
      {:execute_live, evidence(:execute_live, "run_not_in_replay_mode", seam, source_evidence, true)}
    authority_expanding?(seam) ->
      {:blocked, evidence(:blocked, "authority_expanding_change", seam, source_evidence, false)}
    # ... more clauses ...
    true ->
      {:execute_live, evidence(:execute_live, "local_safe_to_rerun", seam, source_evidence, true)}
      # ⚠️ D-06: Confluence.classify/1's terminal clause must NOT mirror this
      # fail-open fall-through — it must be {:unevaluable, "confluence_resolver_fallthrough"}.
  end
end
```

### Pattern 2: No-passthrough fixed-key semantic-convention projector

**What:** A function that reduces over a hand-written keyword list of `{field, "scoria.dotted.key"}` pairs, emitting ONLY those keys, never spreading the input map.
**When to use:** `Semconv.confluence_attributes/1` (D-08).
**Example (verified pattern from `semconv.ex:601-608` and `:624-631`):**
```elixir
# Source: lib/scoria/observe/semconv.ex:601-608 (trust_attributes/1) — verified in worktree
def trust_attributes(input) when is_map(input) do
  Enum.reduce(@trust_keys, %{}, fn {field, key}, acc ->
    case Map.get(input, field) do
      nil -> acc
      value -> Map.put(acc, key, value)
    end
  end)
end
# classification_attributes/1 at :624-631 is byte-identical in shape.
# confluence_attributes/1 must follow this exact reduce-over-@confluence_keys
# shape — never Map.merge(%{...}, input).
```

### Pattern 3: Atomic single-statement CAS admit/consume

**What:** A `Repo.update_all(query, inc: [...])` or `returning:` update wrapped in a `where` clause that only matches when the guard condition holds, returning `{1, [...]}` on success and `{0, _}` on the guard failing.
**When to use:** The `confluence_legs` merge+read (D-17) and the approval-consume CAS (D-26).
**Example (verified pattern from `rails.ex:110-124`):**
```elixir
# Source: lib/scoria/workflows/rails.ex:110-124 (admit_tool_call/2) — verified in worktree
def admit_tool_call(run_id, now \\ DateTime.utc_now()) do
  query =
    from(r in Run,
      where: r.id == ^run_id,
      where: is_nil(r.rail_max_tool_calls) or r.rail_tool_calls < r.rail_max_tool_calls,
      select: r.rail_tool_calls
    )

  case Repo.update_all(query, inc: [rail_tool_calls: 1]) do
    {1, [count]} -> {:ok, count}
    {0, _} -> :denied
  end
end
# D-17's confluence_legs fold and D-26's approval consume both need this exact
# shape: single statement, no read-then-write round trip, {N, result} pattern match.
```

### Pattern 4: Migration house style — `add_if_not_exists`, explicit null/default

**What:** Idempotent column additions safe for `ApplyExecutor.copy_missing_migrations!/2` to copy into host repos, with `null: false, default:` set explicitly (never a nullable jsonb column with no default — Postgres `'{"a":1}'::jsonb || NULL` is `NULL`).
**When to use:** The D-47 consolidated migration.
**Example (verified verbatim from the most recent migration in this repo, `20260728120000_add_rail_columns_to_ai_workflow_runs.exs`):**
```elixir
# Source: priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs — verified in worktree
def up do
  alter table(:ai_workflow_runs) do
    add_if_not_exists :rail_max_steps, :integer
    add_if_not_exists :rail_steps, :bigint, null: false, default: 0
    # ...
  end
end
# D-47's confluence_legs column: add_if_not_exists :confluence_legs, :map, null: false, default: %{}
# (Ecto :map type maps to Postgres jsonb via the project's existing type config.)
```

### Anti-Patterns to Avoid

- **Mirroring `ReplayDisposition`'s fail-open terminal `true -> {:execute_live, ...}` clause (`replay_disposition.ex:58-59`) in `Confluence.classify/1`.** D-06 requires the opposite polarity: an unreachable `{:unevaluable, "confluence_resolver_fallthrough"}` terminal clause that never escalates and never allows silently.
- **Using `jsonb ||` merge for the `confluence_legs` accumulator.** It preserves the FIRST witness per key, not the strongest, silently defeating the grading model for the rest of the run (D-15.1).
- **Writing all three legs (including `false`) on every accumulator update.** Freezes the first call's `false` values permanently (D-15.2). Write only lit legs.
- **`raise` instead of `exit({:shutdown, ...})` for the escalation signal.** Measured and rejected by the red team: a `raise` is defeated by the single most common defensive pattern in adopter code (`try/rescue _ ->`); an `exit({:shutdown, term})` from an `async_nolink` task is defeated only by the rare `catch :exit` (D-20).
- **Adding a 5th value to `Semconv.guardrail_names/0` or routing through `Observe.Guardrail.emit/1`.** Both are pinned by exact-match tests (`semconv_test.exs:373-375`) and would additionally route every confluence reason code through `normalize_reason_code/1` to `"unknown"` (D-10). Verified: `guardrail_names/0` is exactly 4 values at `semconv.ex:338,342`.
- **Defaulting `enforcement: :observe` (draft's original choice).** Explicitly reversed by red-team consensus (D-31) — the shipped default for the `declared` grade is `:escalate`. `:observe` is the documented incident kill switch, not the launch state.
- **Defaulting `unattributed: :deny`.** Scoria's own reference test fixture (`runtime_span_test.exs:82-91`, verified — passes `workflow_run_id:` not `:run_id`, and no `step_id` at all) is itself unattributed by the gate's own reading. Deny-by-default would brick the canonical copy-paste example (D-22).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pause a running workflow step for human approval | A new run-lifecycle transition function or a bespoke `Approval` insert | `Scoria.Workflows.mark_waiting_for_approval/3` (`workflows.ex:365-499`) | Yields all 12 GATE-03 artifacts (run status, step status, checkpoint, event, approval row, in-txn audit row, back-link, 2× PubSub, decision audit row, decision PubSub, 56.1 pause accounting) for free — a bespoke insert loses all 12 (D-46, verified function exists at exact cited line) |
| Resolve a resumed approval back into workflow execution | A new resume path | `Scoria.Workflows.resume_run/1` (`workflows.ex:985-1041`) — widened per D-26's three axes | Already handles checkpoint/step/PubSub reconciliation; widening its finder predicates is far cheaper and safer than reimplementing resumption |
| Domain-owned closed reason-code enum without widening Semconv's frozen one | A PR to `Semconv.guardrail_reason_codes/0` | `Confluence.reason_codes/0` mirroring `Trust.Verdict.reason_codes/0`'s exact shape (`verdict.ex:35-59`, verified) | `guardrail_reason_codes/0` is pinned by an exact-equality test (`semconv_test.exs:382-387`, verified — the "not invented" invariant) |
| Config resolution with an app-env default and a per-call override | A new `GenServer`/`Application.get_env` ad hoc read | Mirror `Scoria.Runtime.Rails`'s two-rung ladder (`runtime/rails.ex:1-60`, verified) | Already solves last-writer-wins vs. tighten-only, `validate_app_env/0`'s never-raise/never-boot-check doctrine, and the ETS log-once ergonomics for typo warnings |
| Atomic per-run counter/accumulator write under concurrency | Read-then-write with an application-level lock | `Repo.update_all(query, [inc: ...] or [set: ..., returning: [...]])` mirroring `Rails.admit_tool_call/2` (`rails.ex:110-124`, verified) | Single-statement CAS avoids the TOCTOU window a read-then-write introduces between two concurrent tool calls in one run |
| A fixed-key attribute projector that must never leak free-text | A `Map.merge(%{}, input)` spread | Hand-written `@confluence_keys` reduce, mirroring `trust_attributes/1`/`classification_attributes/1` (`semconv.ex:601-631`, verified) | `attribute_registry/0`'s exact-match canary test (44 keys today, verified count) makes an accidental spread a hard test failure by design — this is the SEC-01 mechanism working as intended |

**Key insight:** Every mechanism this phase needs — pause, resume, audit, config-resolution, atomic CAS, fixed-key projection — already exists in this codebase, built by the three prior phases of this exact milestone (55, 56, 56.1) plus the earlier v3.4 `ReleaseGate`/v3.6 rail work. The engineering risk in Phase 57 is almost entirely in **correct composition and ordering** (where in `execute/4` the gate slots in, which existing function each new piece calls), not in inventing new mechanism. Treat every "build X" instinct as a signal to first grep for an existing X.

## Common Pitfalls

### Pitfall 1: The mint-site clamp bug silently makes the whole phase inert
**What goes wrong:** Ship GATE-01..04 without fixing D-01, and every declared-scanner verdict on tool output still resolves to `"untrusted"` regardless of actual content — but so does everything else, so the gate appears to "work" in tests that only assert `"untrusted"` shows up, while never actually distinguishing a clean scan from a bad one.
**Why it happens:** `Trust.Scan.scan/2`'s `:incoming_tier` default (`"untrusted"`, via `Trust.default_tier()`) is silently applied whenever the caller forgets to pass it — no error, no warning, because it's a legitimate default for a *reader*, just wrong for a *mint*.
**How to avoid:** Fix must land as a task in the SAME plan wave as the gate — not a "nice to have" cleanup. Verified: `executor.ex:526-541`'s `scan_tool_output/2` is the exact and only mint-site bug location; the fix is `incoming_tier: "trusted"` at that call plus a new `scanner_tier` field on `%Verdict{}` (`verdict.ex:26`, currently `[:tier, :score, :reason_code, :scanner]`).
**Warning signs:** A test asserting `verdict.tier == "untrusted"` for BOTH a clean-scan fixture and a malicious-content fixture without ever asserting a `"trusted"` outcome anywhere in the suite.

### Pitfall 2: `jsonb || NULL` silently disables the accumulator forever
**What goes wrong:** A nullable `confluence_legs` column with no default: every pre-migration row (and any row where the merge fragment ever touches a NULL) has `confluence_legs` permanently `NULL`, and Postgres `'{"a":1}'::jsonb || NULL` evaluates to `NULL`, not the left operand.
**Why it happens:** Postgres's `||` jsonb concatenation operator is NULL-propagating, unlike a typical "merge into existing" mental model.
**How to avoid:** `null: false, default: %{}` (Ecto `:map` type → Postgres jsonb) on the migration, exactly mirroring the verified `rail_steps`/`rail_tool_calls` columns in `20260728120000_add_rail_columns_to_ai_workflow_runs.exs` (`null: false, default: 0`).
**Warning signs:** A test that only inserts fresh rows via the app (which always sets the Ecto schema default) and never exercises a raw-SQL or pre-migration row.

### Pitfall 3: Escalation loops forever on resume
**What goes wrong:** `resume_run/1` re-queues the step and the handler re-executes, reaching the identical tool call. Without a consumed marker, the gate re-evaluates and re-escalates on every resume — a documented LangGraph `interrupt()` footgun.
**Why it happens:** The gate has no memory of "this exact call was already approved" unless one is built explicitly; `Approval.status: "approved"` alone doesn't consume itself.
**How to avoid:** The atomic consume CAS (D-26) — new `consumed_at`/`consumed_by_step_id` columns on `ai_approvals`, a single `UPDATE ... WHERE ... AND consumed_at IS NULL ... RETURNING id` as the gate's FIRST action on every call. A `nil` `args_fingerprint` must fail closed (treat as no match), since `build_replay_seam/2` (`executor.ex:454-470`, verified) reads it with no default.
**Warning signs:** An approval that reads `"approved"` in the DB but the same tool call keeps producing new `waiting_for_approval` transitions on every retry.

### Pitfall 4: `resume_run/1`'s finder breaks first, before the CAS even matters
**What goes wrong:** Widening only `current_approved_approval/1` (`workflows.ex:1191-1201`, verified) looks sufficient in a single-step test, but a sibling step's `complete_step/3` rewrites `run.status` back to `"running"` in real multi-step runs, and `resume_run/1`'s outer `case` head only matches `{"waiting_for_approval", _, ...}` (`workflows.ex:988-989`) — so it falls to `{:error, :not_resumable}` regardless of any finder fix.
**Why it happens:** Three independent predicates gate resumability (run status, `current_step_id` match, `latest_checkpoint_id` match), and only widening one of the three passes single-step tests while stranding multi-step production runs.
**How to avoid:** Widen all three axes for `blocker_kind: "confluence"` approvals specifically, per D-26's corrected finder-widening spec.
**Warning signs:** A regression test suite that is 100% single-step-per-run fixtures — this class of bug is invisible until a real multi-step run with a sibling step completing mid-escalation is exercised.

### Pitfall 5: A rescued `StaleEntryError` gap strands escalated steps
**What goes wrong:** `mark_waiting_for_approval/3` is NOT `StaleEntryError`-rescued (unlike `halt_run/3`), and `Runtime.execute_step/2` only rescues `StepFailureSignal` (`runtime.ex:310-312`). A sibling step completing mid-escalation crashes the unlinked dispatch Task, leaving the step stuck in `"running"` forever.
**Why it happens:** This is a new concurrency interaction Phase 57 introduces (two concurrent writers to the same run row) that the prior phases' rescue coverage didn't anticipate.
**How to avoid:** The call-site rescue at the escalation call site is mandatory per D-28, not optional — normalize to fail-closed on a stale entry rather than crashing the Task.
**Warning signs:** Flaky test failures specifically under concurrent-step fixtures that don't reproduce in isolation.

## Code Examples

### Existing correct incoming_tier threading (the pattern D-01's fix must replicate)
```elixir
# Source: lib/scoria/knowledge.ex:427-448 — verified in worktree
defp resolve_trust_attributes(result_rows, opts) do
  scanner = Keyword.get(opts, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))
  incoming_tier = aggregate_incoming_tier(result_rows)

  {:ok, verdict} =
    Trust.scan(%{chunks: result_rows}, %{content_scanner: scanner, incoming_tier: incoming_tier})
  # ...
end

defp aggregate_incoming_tier(result_rows) do
  Enum.reduce(result_rows, "trusted", fn row, acc ->
    if Trust.tier(row.metadata) == "untrusted", do: "untrusted", else: acc
  end)
end
```

### The bug to fix, verified
```elixir
# Source: lib/scoria/mcp/executor.ex:526-541 — verified in worktree
defp scan_tool_output({:ok, value}, context) do
  scanner = Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scanner.NoOp))
  {:ok, verdict} = Trust.scan(value, Map.put(context, :content_scanner, scanner))
  # ⚠️ No :incoming_tier key set here. Trust.Scan.scan/2 (scan.ex:67) defaults it
  # to Trust.default_tier() = "untrusted" (trust.ex:36), and most_restrictive/2
  # (scan.ex:128-130) is min-wins, so the result is ALWAYS "untrusted".
  # Fix: Map.put(context, :incoming_tier, "trusted") before calling Trust.scan/2
  # (a freshly minted tool output has no prior taint).
  ...
end
```

### Reference handler's own attribution gap (verified, motivates D-22's `unattributed: :allow` default)
```elixir
# Source: test/scoria/workflows/runtime_span_test.exs:82-91 — verified in worktree
{:ok, _result} =
  Scoria.MCP.Executor.execute(
    Scoria.Workflows.RuntimeSpanTest.DummyTool,
    %{"action" => "success"},
    %{
      trace_id: trace_id,
      parent_id: parent_id,
      tenant_id: run.tenant_id,
      workflow_run_id: run.id   # NOTE: not :run_id, and no :step_id at all —
                                 # Scoria's OWN reference fixture is unattributed
                                 # by the gate's reading of context.
    }
  )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `enforcement: :observe` default (draft design) | `enforcement: :enforce` with `declared: :escalate` (shipped default) | Red-team pass 2, this phase's CONTEXT.md D-31 | The "ungated" telemetry-only behavior applies to the three WEAK grades only; positive declared evidence enforces from day one, mirroring `ReleaseGate`'s doctrine exactly |
| `raise` for the escalation signal (draft design) | `exit({:shutdown, {:scoria_confluence_escalation, attrs}})` | Red-team pass 1, D-20 (measured, not assumed) | A raise is defeated by ubiquitous `try/rescue _ ->` adopter code; the exit form survives it |
| Deny-by-default for unattributed calls (draft design) | `unattributed: :allow` | Red-team pass 2, D-22 | Scoria's own shipped reference handler is itself unattributed — deny-by-default would brick the canonical copy-paste example |

**Deprecated/outdated (within CONTEXT.md's own history, worth flagging so the planner doesn't resurrect them):**
- "Observed taint is never sufficient alone" (draft D-13) — deleted; it made Phase 55's entire scanner deliverable dead code and left `default_tier`/`scanner_infra` grades unreachable.
- A boolean or flat-mode enforcement mode enum — cannot express "block the deliberate declaration, not the missing one," which is the entire never-brick argument (D-29).
- `escalate_run/3` as a `halt_run/3` mirror (draft) — rejected; `halt_run`'s un-overwritable clamps are only valid because a halt is terminal, and an escalation must be releasable (D-19).

## Assumptions Log

> CONTEXT.md's decisions are already tagged with a provenance and revision history in the document itself (each D-NN states whether it was revised by red-team and why). This RESEARCH.md's own contribution is code verification, not new claims. The table below lists the small number of places where I could not independently verify a CONTEXT.md citation to the exact line, or where I extrapolated a recommendation beyond what was directly checked.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Ecto`'s `:map` column type maps to Postgres `jsonb` in this project's Repo config (used in the Pattern 4 migration example) | Architecture Patterns, Pattern 4 | Low — this is a standard Ecto/Postgres convention already used by the verified `metadata :map` fields throughout `run.ex`/`step.ex`; if wrong, the migration task simply needs `:jsonb` spelled explicitly instead of `:map` |
| A2 | A handful of CONTEXT.md line-number citations (e.g. `approval.ex:19,31` vs. verified `19,32`; `approval.ex:100` vs. verified `104`; `release_gate.ex:84` vs. verified `86`) drift by 1-4 lines from what I found in the current worktree | Throughout | Negligible — every semantic claim attached to these citations was independently confirmed correct; the drift is consistent with minor unrelated edits between the red-team verification pass and now, not with the underlying fact being wrong |

**If this table were larger, it would signal CONTEXT.md needs re-verification before planning. It is not — the citation accuracy rate across ~40 independently checked references was effectively 100% on substance.**

## Open Questions

CONTEXT.md itself flags two decisions that require an explicit planning-time choice rather than research (both are Claude's-discretion-adjacent but load-bearing enough that the planner must decide and document, not defer):

1. **Step-level vs. run-level pause scoping (D-25).**
   - What we know: `list_runnable_steps/0` (`workflows.ex:99-105`, verified) requires `status in ["running", "retrying"]`, so an escalation does freeze sibling dispatch — until an already-in-flight sibling completes and flips the run back to `"running"` via `complete_step/3`'s unconditional status write (`workflows.ex:263-363`, `complete_step/3`'s only clamp is `Run.halted?`, verified).
   - What's unclear: whether GATE-02's wording should be scoped explicitly to "the escalating step" (accept the gap) or whether `complete_step/3` should gain a `waiting_for_approval` clamp (a real behavior change to shared, heavily-tested code).
   - Recommendation: Plan this as an explicit task-level decision point with both options scoped as alternative tasks; do not let the plan silently pick one without a code comment documenting the choice, per CONTEXT.md's own instruction ("Decide explicitly at planning; do not ship the ambiguity").

2. **Approval-fatigue resolution mechanism (D-50).**
   - What we know: an honest `send_reply`-style tool trips all three legs on every call under strict mode; D-44 forecloses a reusable grant, D-12 forbids untainting, and the per-`args_fingerprint` CAS doesn't help since every reply has different args.
   - What's unclear: whether to build the bounded per-run/per-tool/per-grade approval scope (CONTEXT.md's stated recommendation, option (a)) within this phase's budget, or document the guide-level workaround (option (b)) and defer the scope mechanism.
   - Recommendation: CONTEXT.md explicitly recommends (a) — "it is the difference between a demo and a product, and it keeps the bound inside Phase 57's own vocabulary." Plan for (a) as the primary path; if plan complexity/time forces a cut, (b) is the documented fallback, but shipping neither is explicitly disallowed by CONTEXT.md.

## Environment Availability

Not applicable — this phase has no external service/tool dependencies beyond the existing Postgres database and Elixir/Erlang runtime already required by every other phase in this milestone. No new CLI tools, no new services to probe.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in test framework) |
| Config file | `mix.exs` (test aliases at lines ~25-52, verified: `mix.exs` defines dozens of scoped `test.*` aliases like `test.knowledge`, `test.connector`) |
| Quick run command | `mix test test/scoria/confluence_test.exs` (new pure-classifier property test, fast — no DB) |
| Full suite command | `mix test --warnings-as-errors` (project convention observed across CI policy lane references in STATE.md) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | `Confluence.classify/1` is total over all 8 leg-combination inputs and returns the correct closed enum value | unit (property-style, pure function, no DB) | `mix test test/scoria/confluence_test.exs -x` | ❌ Wave 0 — new file |
| GATE-01 | `scan_tool_output/2` no longer clamps a clean scanner verdict to `"untrusted"` | unit/integration | `mix test test/scoria/mcp/executor_test.exs -x` | ✅ file exists (`test/scoria/mcp/executor_test.exs` — verify via `ls`), needs new cases |
| GATE-02 | Escalation pauses BEFORE `execute_live/4`, no budget reserved, no `mcp.access.granted` row written | integration (DB-backed, `Scoria.IntegrationCase`) | `mix test test/scoria/mcp/executor_test.exs --only confluence -x` | ❌ new `describe` block needed |
| GATE-02 | `Runtime.execute_handler/6`'s new exit clause correctly maps to `{:ok, {:waiting_for_approval, attrs, elapsed_ms}}` | integration | `mix test test/scoria/workflows/runtime_test.exs -x` | ✅ file exists, needs new cases |
| GATE-02 | Resume after approval re-reaches the identical tool call and does NOT re-escalate (consume CAS) | integration | `mix test test/scoria/workflows_test.exs --only confluence -x` | ✅ file exists (verify path), needs new cases |
| GATE-03 | Audit row written on `escalate` AND `block`, never on `allow`; `blocker_audit_outbox_event_id` links correctly | integration | `mix test test/scoria/sre_test.exs -x` or a new `confluence_audit_test.exs` | ❌ Wave 0 likely needed |
| GATE-04 | `declared: :escalate` enforces by default; the three weak grades emit telemetry only, never block | unit | `mix test test/scoria/confluence_test.exs --only grading -x` | ❌ Wave 0 — same new file as GATE-01 |
| GATE-04 | `Semconv.confluence_attributes/1` is a no-passthrough fixed-key projector; registry canary includes the 5 new keys | unit | `mix test test/scoria/observe/semconv_test.exs -x` | ✅ file exists (verified, canary at lines ~274-321), needs canary list update |
| D-53 | Guide no longer denies the confluence claim; positive assertion fails if the edit is missing | unit (doc-content) | `mix test test/scoria/adoption_surface_test.exs -x` | ✅ file exists (verified at lines 253-280), needs positive-assertion addition |

### Sampling Rate
- **Per task commit:** the narrowly-scoped test file for the module just touched (e.g. `mix test test/scoria/confluence_test.exs`)
- **Per wave merge:** `mix test --warnings-as-errors` (full suite) — this project's CI policy lane convention, verified via `STATE.md`'s repeated closeout references to "focused lane green during closeout" plus full-suite gates
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus the specific regression risk this phase introduces: a concurrent-step / multi-sibling-step integration test exercising D-25/D-26/D-28's interactions (this is the single highest-risk untested interaction class per Pitfall 4 and Pitfall 5 above)

### Wave 0 Gaps
- [ ] `test/scoria/confluence_test.exs` — covers GATE-01, GATE-04 (pure classifier, property-style over all 8 combinations, no DB required)
- [ ] A confluence-specific audit test (either a new file or a `describe` block appended to an existing `sre_test.exs`/`workflows_test.exs`) — covers GATE-03
- [ ] Framework install: none — ExUnit is already fully configured; no new test dependency needed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Out of scope — this phase gates tool *actions*, not user auth |
| V3 Session Management | No | Not applicable |
| V4 Access Control | Yes | The confluence gate itself IS an access-control mechanism (human-in-the-loop authorization before an exfil-capable action). Standard control: fail-closed-but-inspectable default (mirrors `ReleaseGate` doctrine, verified `release_gate.ex:20,81-93`), graded by evidence quality (D-29), never a boolean toggle |
| V5 Input Validation | Yes | `Confluence.normalize_combination/1` and the new `Confluence.reason_codes/0` enum both fail closed to a safe default (`"none"` / `:unknown`) on any unrecognized input, mirroring `Trust.normalize_tier/1` (`trust.ex:96-98`, verified) and `Verdict.normalize_reason_code/1` (`verdict.ex:57-59`, verified) |
| V6 Cryptography | Marginal | `confluence_idempotency_key` uses `sha256`, mirroring the existing `ReplayDisposition.replay_idempotency_key/2` pattern (`replay_disposition.ex:147-160`, verified — `Base.encode16(:crypto.hash(:sha256, raw), case: :lower)`) — never hand-roll a hash function, reuse this exact call shape |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Approve-once-exfil-forever (a stale approval reused as a standing grant) | Elevation of Privilege | Atomic consume CAS keyed on `args_fingerprint`, single-use per exact call (D-26, D-44) — "replayable" means reconstructable from evidence, never a reusable execution grant |
| Escalation-signal swallowing (a host `try/rescue` or `catch :exit` silently absorbing the pause and letting the exfil action run) | Tampering / Repudiation | `exit({:shutdown, ...})` is deliberately the LEAST swallowable Elixir control-flow signal available short of a linked-process crash (D-20, measured); document the residual `catch :exit` gap explicitly in `SECURITY-BOUNDARY.md` (Phase 58 obligation, per CONTEXT.md's `<deferred>` section) rather than pretending it's fully closed |
| Config typo silently disabling enforcement fleet-wide | Denial of Service (of the security control itself, i.e. a false sense of safety) | `Confluence.validate_app_env/0` mirroring `Runtime.Rails.validate_app_env/0` (`runtime/rails.ex:100`, verified) — never raises, never called from `Application.start/2`, falls back to that grade's shipped default with a log-once warning rather than refusing every tool call |
| Ordering-luck / attacker-chosen tool sequencing silencing the gate for the rest of a run | Tampering | Strongest-wins (not first-wins) leg accumulation (D-15.1) — a weak `default_tier` observation lit first must never permanently pin a leg's grade for the run's remaining calls |

## Sources

### Primary (HIGH confidence — direct code verification in this session)
- `lib/scoria/mcp/executor.ex` (full file read) — `execute/4` ordering, `scan_tool_output/2` bug, `resolve_classification/2`, `canonical_context/1`, `persist_taint_to_step/3`, `persist_classification_to_step/3`
- `lib/scoria/trust.ex`, `lib/scoria/trust/scan.ex`, `lib/scoria/trust/verdict.ex` (full files read) — the D-01 bug chain, `most_restrictive/2`, `%Verdict{}` struct shape
- `lib/scoria/knowledge.ex` (targeted grep+read) — `aggregate_incoming_tier/1`, `resolve_trust_attributes/2` — the correct mint pattern
- `lib/scoria/knowledge/retrieval_run.ex` (full file read) — confirmed no `workflow_run_id`/`step_id` fields (D-02)
- `lib/scoria/mcp/classification.ex` (full file read) — `unclassified_default/0`, `declared/1`, `declared_sensitive?/1`, `resolve/2`
- `lib/scoria/workflows/replay_disposition.ex` (full file read) — the `cond`→`{atom, evidence}` shape and its fail-open terminal clause
- `lib/scoria/workflows.ex` (targeted grep of every function referenced in CONTEXT.md) — `mark_waiting_for_approval/3`, `resume_run/1`, `approve/3`, `complete_step/3`, `retry_step/1`, `claim_step/1`, `list_runnable_steps/0`, `halt_run/3`, `current_approved_approval/1`
- `lib/scoria/workflows/runtime.ex` (targeted grep+read) — `execute_handler/6`, its `{:exit, reason}` clause, `decorate_run_with_trace_context/4`
- `lib/scoria/observe/semconv.ex` (targeted grep+read) — `@trust_keys`, `@guardrail_names`, `@guardrail_decisions`, `trust_attributes/1`, `classification_attributes/1`, `rail_attributes/1`
- `test/scoria/observe/semconv_test.exs` (targeted read) — the 44-key registry canary (counted, confirmed exact), guardrail exact-match enum tests
- `lib/scoria/sre.ex` (targeted read) — `build_audit_metadata/1`'s drop-list, `build_audit_dedupe_key/1`
- `lib/scoria/runtime/release_gate.ex` (full file read) — `handle_missing_verdict/1`, the `[:scoria, :release_gate, :ungated]` event, the positive-evidence-enforces clause
- `lib/scoria/runtime/rails.ex` (targeted read) — the two-rung config-resolution template, `validate_app_env/0`
- `lib/scoria/workflows/run.ex` (targeted read) — schema, `changeset/2`'s cast list, the counter/changeset writer disjointness comment
- `lib/scoria/observe/approval.ex` (full file read) — schema, `blocker_kind`/`blocker_audit_outbox_event_id` fields, `changeset/2`
- `lib/scoria/workflows/rails.ex` (targeted read) — `admit_tool_call/2`'s atomic CAS shape
- `lib/scoria_web/ui.ex` (targeted read) — `tone/1`, confirmed `"waiting_for_approval"` maps to `:warn`
- `lib/scoria_web/approval_copy.ex` (targeted read) — `request_rows/1`, `evidence_rows/1`
- `lib/scoria/adopter_doc_contract.ex`, `guides/scoria-vs-external-llm-ops.md`, `test/scoria/adoption_surface_test.exs` — the D-53 shipped-lie repair surface, all three files verified
- `priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs` (full file read) — the migration house style to mirror
- `test/scoria/workflows/runtime_span_test.exs` (targeted read) — confirmed the reference handler's `workflow_run_id:`/no-`step_id` attribution gap

### Secondary (MEDIUM confidence)
- `.planning/phases/57-confluence-escalation-gate/57-CONTEXT.md` — the primary decision document itself; treated as MEDIUM here only in the sense that its claims were re-derived from code by this research pass rather than accepted on authority alone — every checked claim was confirmed HIGH via direct verification above
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — project-level framing, milestone goal, prior-phase completion status

### Tertiary (LOW confidence)
- None — no WebSearch or external-library claims were needed for this phase; it is entirely internal codebase composition

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; this phase is pure composition of existing, verified in-repo modules
- Architecture: HIGH — every seam (executor ordering, workflow pause/resume, audit outbox, semconv projector) was independently read and confirmed in the current worktree, not taken on CONTEXT.md's authority alone
- Pitfalls: HIGH — all five documented pitfalls trace to specific, verified code locations (the D-01 bug, the jsonb NULL-propagation semantics, the resume finder's three-predicate gate, the missing StaleEntryError rescue)

**Research date:** 2026-07-28
**Valid until:** This research is tied to a specific commit in a worktree branch under active development (`worktree-phase-55-content-trust-taint`, 46 commits ahead of its remote tracking branch). Re-verify line-number citations if planning is deferred more than a few days or if any of Phases 55/56/56.1's files are touched by an intervening commit. The underlying decisions (D-01..D-54) do not expire — only the file:line coordinates could drift.
