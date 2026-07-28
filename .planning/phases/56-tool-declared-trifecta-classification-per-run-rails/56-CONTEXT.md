# Phase 56 Context — Tool-Declared Trifecta Classification

**Requirements:** CLASS-01, CLASS-02, CLASS-03
**Deferred to Phase 56.1:** RAIL-01 (see `<scope>`)
**Method:** 3 parallel research agents + 1 adversarial red-team pass, synthesized. No interactive Q&A.

---

## `<scope>`

**RAIL-01 is split out into Phase 56.1.** The red-team pass recommended this and the evidence is decisive:

- `ROADMAP.md:72` — Phase 57 depends on Phase 56 for *"the taint substrate and the tool-declared classification."* It does **not** consume rails. Splitting unblocks Phase 57 strictly earlier.
- The halves share no files and no failure modes. Classification touches `MCP.Tool`, `MCP.Executor`, `Connectors.Invocation`, `ReplayDisposition`. Rails touch the `Workflows` lifecycle, `Runtime`, `Params`, `Defaults`, `Reconciler`, `Semconv`.
- Rails require a **schema migration** for a durable per-run tool-call counter (see D-56.1-B). Classification requires none.

Phase 56 = CLASS-01/02/03 only. Rails decisions are recorded in `<deferred>` so 56.1 starts from a researched base rather than a blank page.

---

## `<decisions>`

### D-01 — Declaration surface (CLASS-01)

Extend `Scoria.MCP.Tool` with `@callback classification() :: %Scoria.MCP.Classification{}`, marked **`@optional_callbacks [classification: 0]`**, plus a `use Scoria.MCP.Tool, reads_private_data: true, ...` macro that generates it. Mirrors `Scoria.SemanticCache.Profile` (`lib/scoria/semantic_cache/profile.ex:22-54`) — the only existing behaviour-plus-`__using__` precedent in `lib/`.

**`@optional_callbacks` is load-bearing, not stylistic.** A *required* callback added to a published behaviour emits `warning: function classification/0 required by behaviour ... is not implemented`, which is a hard build failure for any adopter compiling with `--warnings-as-errors` — Scoria's own documented workflow (`AGENTS.md`). This is the same never-brick-an-adopter constraint that produced phase 55's D-08.

Detection: `Code.ensure_loaded?/1` + `function_exported?/3` (the idiom already at `executor.ex:678`). `Code.ensure_loaded?` is required — without it a lazily-loaded module under `:interactive` is misread as undeclared.

**Memoize the resolution in `:persistent_term` keyed by module.** `Profile.describe/1` resolves once at config time; `Executor.execute/4` is a per-call hot path.

### D-02 — `action_class` closed enum (CLASS-01)

Reuse the existing in-lib enum **verbatim**: `~w(read write exec admin)` from `lib/scoria/workflows/replay_disposition.ex:11`. Closed, not open.

- `Scoria.MCP.Classification` becomes the owner, exposing `action_classes/0`, `default_action_class/0`, `normalize_action_class/1` (fail-closing to `"admin"`). `ReplayDisposition`'s private `@effectful_classes` derives from it rather than duplicating.
- **List order is load-bearing** — `Enum.drop(@effectful_classes, 1)` at `replay_disposition.ex:92` pins `"read"` at index 0 as the sole non-effectful member. Assert the order in a test.
- Closed because the value is written to trace attributes as an `:enum`; an open enum is an unbounded-cardinality leak, and `ReplayDisposition` *branches* on membership, so an unknown value silently takes the fail-**open** fall-through at `:58-59`.
- **No `"pure"`/`"none"`.** Purity is the separate, already-existing `local_classification` axis (`replay_disposition.ex:65-67`). Conflating them would create two competing purity signals.

### D-03 — Unclassified fallback (CLASS-02)

An undeclared tool resolves to:

```elixir
%Scoria.MCP.Classification{
  reads_private_data: true, sees_untrusted_content: true, can_exfiltrate: true,
  action_class: "admin", source: :unclassified_default
}
```

It **still runs**, and emits `[:scoria, :class, :unclassified]`. `source` is `@enforce_keys` — it must never be silently absent, because Phase 57 branches on it (see D-06).

A default-off `config :scoria, :require_tool_classification` flag makes resolution **refuse** instead, returning `{:error, %{status: :unclassified_tool, ...}}` in the same envelope shape as the existing `:access_denied` path (`executor.ex:519-527`). Do not defer this flag — without it CLASS-02 ships pure telemetry with no enforcement path.

**HARD PROHIBITION — the resolved values may be written ONLY to new namespaced context keys.** Writing any of the following would brick currently-succeeding calls. Each was verified in code by the red-team pass:

| Key | Why it must not be written |
|---|---|
| `:policy_sensitive`, `:sensitive_tool` | Gate a synchronous audit-outbox insert (`executor.ex:539-547`) and `BudgetEngine.reserve_step` (`executor.ex:398-422`); both are `{:error,_}`-capable and abort the call at `executor.ex:97-100` |
| `:approval_sensitive` | Gates `live_override_ready?/2` (`replay_disposition.ex:122-127`). Setting it `true` makes approved live overrides require a `replay_approved?` hosts do not pass today → `:execute_live` becomes `:blocked` |
| `:local_classification` | Gates `pure_local?/1` (`replay_disposition.ex:65-67`). Clobbering a host's `:pure` with `:admin` turns `:execute_live` into `:blocked` |
| `:action_class`, `:risk_level` | Must not be overwritten on any call where a host supplied them — see D-04 |

**The "replay-inert" justification is RETRACTED.** An earlier draft argued the maximal default was safe because `effectful_or_remote?/1` is already true for current defaults. That reasoning examined only one `cond` clause and is wrong — two clauses above it read `approval_sensitive`. Inertness is achieved by the write-prohibition above, **not** by any property of `effectful_or_remote?/1`.

**Persist for replay.** Write `%{"scoria.classification" => ...}` into `step.result_envelope` using the same jsonb `fragment("? || ?")` choke point phase 55 established for `"scoria.taint"` (`executor.ex:300-340`). Phase 57 SC#3 requires escalation decisions be replayable; in-memory context alone cannot satisfy that.

### D-04 — Precedence: tighten-only, fallback is not an operand (CLASS-03)

Resolution is `tool_declaration ⊔ host_declaration`, tighten-only. Legs join with `or`; `action_class` joins with `max` over `read ⊏ write ⊏ exec ⊏ admin`.

**`:unclassified_default` applies ONLY when neither a tool nor a host declaration exists.** It is never a join operand. A maximal default combined with a max-join would dominate every declaration — clamping a host's `"read"` up to `"admin"` and flipping working replay calls to `:blocked`. `source: :unclassified_default` is mutually exclusive with `:tool_declared` / `:host_tightened`.

**Operator polarity is INVERTED relative to phase 55's D-19 — do not copy `most_restrictive/2`.** `Trust.Scan.@tier_order` is `%{"untrusted" => 0, "trusted" => 1}` and `most_restrictive/2` takes the **min** (`scan.ex:40,128-130`). `action_class` tightens **upward**, so the join is **max**. The *law* is the same (a source of sensitivity may only add, never remove); the *operator* is opposite. A copy-paste would silently de-escalate every join, and no shape-based test would catch it. Ship directional tests in **both** argument orders: `join("read","admin") == "admin"` and `join("admin","read") == "admin"`.

Normalize **both** operands through `normalize_action_class/1` before any ordinal lookup — `Map.fetch!` raises on junk.

Disagreement handling mirrors phase 55's D-03 two-branch rule:

| Case | Behavior |
|---|---|
| Host key absent | Declaration wins, **silently** (this is every adopter today; warning here would be noise) |
| Host tighter | Applied, `source: :host_tightened`, no warning |
| Host looser | Clamped to declaration + `Logger.warning` + `[:scoria, :class, :precedence_conflict]` |
| Host junk | Normalized to most-restrictive, same warning + event |

A host needing a genuinely looser classification edits the tool's `classification/0` — static, reviewable, greppable — rather than a per-call map. On the controller path that map is literally `Map.new(conn.assigns)` (`mcp_controller.ex:117`), i.e. request-derived. Loosening is not removed; it is relocated beyond reach of an attacker-influenced request.

### D-05 — Every fail-open site is fixed, and there are FIVE (CLASS-03)

Resolution happens **once**, in `MCP.Executor.execute/4`, before `replay_gate/3`.

| # | Site | Nature |
|---|---|---|
| 1 | `executor.ex:181-194` `build_replay_seam/2` | Replay-only. **The requirement's `executor.ex:150-165` citation is stale** — the code moved during phase 55. Fix the citation in REQUIREMENTS.md and ROADMAP.md when locking. |
| 2 | `executor.ex:552-554` `policy_sensitive_invocation?/1` | **Live path.** Nil-falsy, no explicit default; decides whether a `tool.invocation` audit row is written at all |
| 3 | `executor.ex:442-447` `budget_required?/1` | Gates budget reservation (second, read-only call site at `:682`) |
| 4 | `invocation.ex:60-75` `build_seam/2` | Defaults `action_class: "read"`, `approval_sensitive: false` — and computes a replay disposition at `:26`, **before** the executor is reached |
| 5 | `workflows/runtime.ex:474` `Keyword.get(opts, :replay_seam, %{local_classification: :pure})` | **The worst.** A total replay bypass, defaulted open, at step granularity |

Sites 4 and 5 were missed by the requirement text entirely. Note the codebase is already internally inconsistent — three seam builders default `:pure` / `:read` / `:write`, and `workflows.ex:993-1001` hardcodes a maximal seam. If site 5 is scoped out, **say so in writing**; do not claim "all fail-open sites fixed" while it stands.

### D-06 — Phase 57 cascade mitigation (cross-phase obligation)

If every legacy call resolves all-three-legs-true, Phase 57's confluence gate fires on 100% of legacy traffic. This does **not** brick — `ROADMAP.md:81` says Phase 57 defaults to telemetry, not blocking — but it ships a 100%-false-positive signal adopters will permanently filter out.

Phase 56's obligation is to make the mitigation *possible*: `source` is `@enforce_keys` (D-03), and it is persisted to `step.result_envelope` (D-03), so Phase 57 can give `:unclassified_default` a separate, operator-selectable disposition from `:tool_declared`. This is the phase-56 analogue of phase 55's D-22 bricking-cascade guard.

---

## `<canonical_refs>`

- `.planning/ROADMAP.md` — Phase 56 goal + SC; **Phase 57 section is a constraint**, not background
- `.planning/REQUIREMENTS.md` — CLASS-01/02/03, RAIL-01
- `.planning/phases/55-content-trust-taint-substrate/55-CONTEXT.md` — D-03 (fail-closed + telemetry), D-07 (billing ordering), D-08 (soft-launch), D-19 (monotonic law), D-21 (no second span), D-22 (bricking cascade)
- `lib/scoria/semantic_cache/profile.ex:22-54` — the declaration-surface template
- `lib/scoria/workflows/replay_disposition.ex` — the enum owner today; **`cond` clause ORDER is the hazard surface**
- `lib/scoria/trust/scan.ex:40,128-130` — D-19's operator, whose polarity must be inverted here
- `CLAUDE.md`, `AGENTS.md`

---

## `<deferred>`

### Phase 56.1 — Per-Run Rails (RAIL-01), researched and ready

- **D-56.1-A — Lifecycle reality.** There is **no orchestrator loop and Oban is uninvolved**. Runs progress via `Workflows.Reconciler`, a GenServer dispatching one `Runtime.execute_step/2` per runnable step. `run.status` is the master switch: `list_runnable_steps/0` (`workflows.ex:98-104`) joins on it, so any status outside `["running","retrying"]` structurally stops dispatch. There is no periodic tick; `Run.last_heartbeat_at` is written and **read by nothing**.
- **D-56.1-B — Counting.** `max_steps` must be `count(*) + coalesce(sum(retry_count),0)` — `retry_step/1` reuses the row (`workflows.ex:556-566`), so plain `count(*)` never sees a retry loop, the classic runaway. `max_tool_calls` needs a **new durable counter + schema migration**, incremented via atomic `Repo.update_all`/`jsonb_set` — **never** `Run.changeset/2`, which raises `Ecto.StaleEntryError` under concurrent sibling steps via `optimistic_lock(:lock_version)` (`run.ex:63`).
- **D-56.1-C — Halt is NOT terminal without a new guard.** `resume_run/1` correctly refuses `"cancelled"`, but `retry_step/1` never inspects run status, and public `Resume.retry_failed_step/2` (`resume.ex:16-23`) targets `run.current_step_id` — exactly the step `fail_step` just set. Add a `run.status == "cancelled"` guard rolling back with `:run_not_retryable`, or the rail is a speed bump.
- **D-56.1-D — Config path.** `run.metadata["runtime"]` is **not** a free extension point: `Params.start_metadata/5` clobbers host input (`params.ex:129`) and `Defaults.to_metadata/1` is a fixed 6-key projector. Thread a new `:rails` key through `Params.start/2`. Never reuse `:timeout` — it already means the 5s per-step handler bound (`runtime/params.ex:9`).
- **D-56.1-E — Defaults nil = unlimited**, always-count + `[:scoria, :run, :rail, :observed]` so adopters size limits from real traffic (D-08 shape). Reject a shipped default cap — Scoria ships mechanism, not policy.
- **D-56.1-F — Silently-inert surface.** `MCP.Router` passes no `run_id` (`router.ex:36`), so `max_tool_calls` gives **zero** coverage on inbound JSON-RPC MCP traffic. Must be an explicit telemetried no-op (`[:scoria, :run, :rail, :skipped]`, `reason: :no_run_id`) and documented, not a silent gap.
- **D-56.1-G — Guardrail span deferred.** `Observe.Guardrail.emit/1` would require inventing 3 reason codes in an enum whose stated invariant is *"not invented"* (`semconv.ex:34-37`) and breaks two exact-match contract tests. Ship telemetry + audit outbox only; revisit with Phase 58's Govern surface.
- **D-56.1-H — Accepted limitation.** Preflight-only rails cannot halt a run wedged inside one long tool call; only the per-call `Task.yield/Task.shutdown` bound applies (`executor.ex:390-393`). A true wall-clock guarantee needs a supervised sweeper over `ai_workflow_runs`.

### Separate follow-up — Phase 55 span-projection gap

`Adapters.MCP.emit_tool_span/4` (`lib/scoria/observe/adapters/mcp.ex:84-107`) builds attributes from a fixed 8-key literal plus `merge_host_declared` (only `~w(feature route archetype intent)a`, `semconv.ex:108`). It never spreads metadata, so phase 55's `scoria.trust.*` attributes merged at `executor.ex:69-73` reach **live telemetry handlers only and are dropped from the persisted span**.

The RETRIEVER chokepoint is unaffected — `observe.ex:250` does `Map.merge(trust_attributes)`. So phase 55 delivered D-18's trace tagging on **one of its two chokepoints** in persisted form.

This is a phase-55 defect, not phase-56 scope, but Phase 57 cannot read the tool-output untrusted leg off spans until it is fixed. Track it as a small phase-55 follow-up.

---

## `<open_questions>`

Genuinely undecidable from code; flag at planning if they become blocking:

1. **`default_action_class/0` = `"admin"` or `"exec"`?** No in-lib reader distinguishes them today (`replay_disposition.ex:93` treats write/exec/admin identically). Locked to `"admin"` as maximally-gated, mirroring `Trust.default_tier() == "untrusted"`; revisit if Phase 57/58 branches meaningfully.
2. **Proxy/remote MCP tools.** `Router` maps `%{tool_name => tool_module}` (`router.ex:21`), so one module fronting N remote tools can declare only one classification. Does the behaviour need `classification/1` taking the tool name? No proxy tool exists in-repo, so this is not decidable from code — deferred until one does.
3. **Should `%Classification{}` also absorb `risk_level` and `local_classification`?** `build_replay_seam/2` defaults *four* fields from host context; CLASS-01 names only three legs + `action_class`. Absorbing them closes the same footgun class but exceeds the requirement's literal text. **Recommendation: no** — D-03's write-prohibition already neutralizes them, and absorbing `local_classification` directly contradicts D-02.
4. **`classification/0` isolation.** `try/catch` (raise/throw/exit) vs phase 55's D-20 bounded-Task treatment. `classification/0` should be a pure constant like `name/0`, so `try/catch` plus a documented purity contract is proposed — but a host doing I/O there would hang the caller before the tool's own Task timeout applies.
5. **Is `:policy_sensitive` eventually *derived* from the classification?** Long-term they are the same concept, but unifying turns a per-call audit insert on for everyone. Likely a staged deprecation across a later milestone; worth naming rather than leaving two parallel sensitivity vocabularies undocumented.
