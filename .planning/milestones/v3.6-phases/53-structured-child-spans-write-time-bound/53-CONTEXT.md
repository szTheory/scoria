# Phase 53: Structured Child Spans + Write-Time Bound - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `tool` / `prompt` / `retrieval` / `guardrail` steps appear as **real duration- and failure-bearing child spans** with `parent_id` linkage — **on a pipeline that actually runs in a host app** — and make it **structurally impossible** for an attribute payload to carry raw prompt/completion text.

In scope (locked by `.planning/REQUIREMENTS.md`):
- **EVENT-01** — the four kinds as real child spans (duration + failure), `parent_id`-linked, rendered as a tree.
- **SEC-01** — write-time PII/size/cardinality bound behind a **closed key registry**, with a regression test that goes RED if a future dev introduces unbounded free text.

**⚠ SCOPE CHANGE — this phase was SPLIT during discussion.** The original Phase 53 carried EVENT-01, EVENT-02, EVENT-03, and SEC-01. Red-team's honest plan count for the full synthesis was **9–10 plans** (Phase 51 shipped 5, Phase 52 shipped 6). The user approved a split along the requirement seam:
- **Phase 53 (this phase)** — EVENT-01 + SEC-01. Spans and the bound.
- **Phase 53b** — EVENT-02 + EVENT-03. `ai_span_events`, `emit_event/1`, the FK migration, `prompt_rendered` / `guardrail_triggered`.

No requirement is split across the two. ROADMAP.md and REQUIREMENTS.md were updated in the same change.

**Out of scope (Phase 53b):** `emit_event/1`, the `[:scoria, :observe, :event, :emit]` telemetry clause, the `ai_span_events` FK-drop migration, the Buffer event list + ordered flush, the 3-name allow-list, and the emission of `prompt_rendered` / `guardrail_triggered`. **This phase builds the guardrail and prompt SPANS those events will later attach to.**

**Method:** four parallel research subagents (child-span seam / guardrail+prompt call sites / `emit_event`+Buffer / SEC-01 bound — cross-aware for coherence) + one adversarial red-team pass, every claim verified against real code. Red-team findings are marked **(revised)** or **(red-team)**. It killed two locks outright and forced the scope split. This mirrors the Phase 51/52 discuss method.

**Cross-cutting meta-principle (inherited):** *one shared Semconv-owned seam; single source of truth; structural guarantees proven by drift-guard tests; host declares, Scoria never infers.*

</domain>

<decisions>
## Implementation Decisions

### D-00 — The three findings that reshaped this phase (verified against real code)

- **D-00a — THE PIPELINE IS INERT IN PRODUCTION.** `Scoria.Observe.Buffer` is **not** in `Scoria.Application`'s children (`lib/scoria/application.ex:10-21`), and `Scoria.Observe.Telemetry.attach/1` is called **only** from tests and `examples/support_copilot` — **zero `lib/` callers**. So `:telemetry.execute([:scoria, :observe, :span, :stop], …)` in a host app fires into a void: no redaction, no broadcast, no insert. **Phase 51's and Phase 52's spans have never persisted in a real host app.** Every Phase-53 success criterion is unverifiable until this is wired. **This is Plan 01 and it gates everything else.**
- **D-00b — THE TRACE TREE RENDERS FLAT.** `lib/scoria_web/components/trace_tree_component.ex:36` sets `style={"--indent-level: #{depth}"}` and **no CSS rule consumes `--indent-level`** (only `workflow_tree_component.ex:23` inlines its own `padding-left: calc(...)`). `TraceProjection.with_depths/1` computes depth correctly and it is **thrown away**. The existing test *locks the bug in* — `test/scoria_web/components/trace_tree_component_test.exs:7` is named "renders trace span data using a **flat** DOM structure". **SC#1 ("appears in the trace tree as its own child span") cannot be met by backend work alone.** The UI is in scope.
- **D-00c — PHASE-52's SPANS ARE INVISIBLE TO THE OPERATOR.** `ReviewerBroadcast.span_stopped/1` (`reviewer_broadcast.ex:33-51`) returns `:dropped` on a missing **top-level** `tenant_id`; `orchestrator_live.ex:237` hydrates on `attributes->>'tenant_id'`. `Observe.emit_retriever_span/1` and `emit_prompt_span/1` set **neither**. The adapters set both — that is the only reason their spans render. **Every span this phase emits must write `tenant_id` top-level AND into `attributes`.**

### D-01 — The span seam: one generic wrapper

- **D-01a — `Scoria.Observe.span(kind, name, opts, fun)`** is the single primitive. Mints a fresh `span_id`; `System.monotonic_time` for duration; wall-clock `start_time`/`end_time`; runs `fun`; emits on the existing `[:scoria, :observe, :span, :stop]` event (so redaction + `ReviewerBroadcast` + the FK-safe Buffer flush all apply unchanged). The emit itself stays wrapped `try/rescue -> :ok` (Phase 52 D-R6 continuity — a raising handler can never reach the caller). Returns `fun`'s value **verbatim** — `span/4` is transparent.
  - **Rejected — `start_span`/`stop_span` pair:** leaks unclosed spans on early return/raise. This is the #1 orphan-span bug across every ecosystem surveyed.
  - **Rejected — `@decorate` macro:** needs a `decorator` dep + compile-time magic. Can be layered on `span/4` later with zero contract change.
- **D-01b — thin kind wrappers** on top: `with_tool/3`, `with_prompt/3`, `with_guardrail/3`. **No `with_agent/3`** (red-team cut: no success criterion, no producer).
- **D-01c — Phase-52 signatures unchanged.** `emit_retriever_span/1` and `emit_prompt_span/1` keep their exact public signatures and are refactored **onto** `span/4`. Extract the shared attribute pipeline (`observe.ex:138-143`) into one private builder so both paths have a single origin (D-00c doctrine). **This honors 52's D-ATTR02-1 promise ("zero contract change") literally.** Deprecate nothing — `@deprecated` on a helper shipped yesterday is churn.
- **D-01d — failure-bearing (revised; formally REVISES Phase-52 D-R6).** 52's D-R6 said "success-path only for v3.6 — an ERROR-status RETRIEVER span is deferred." EVENT-01 says spans are duration-**and-failure**-bearing. Direct contradiction → **D-R6 is revised.** `span/4` uses `try/rescue` + `catch` → `status_code: "ERROR"` → **`reraise e, __STACKTRACE__`** (`:erlang.raise/3` for throw/exit). The host's exception is observably unchanged.
  - *Failure-bearing IS the JTBD:* the n=1 SWE opens the tree **because something went wrong**. A tree showing only what succeeded is an alibi, not a debugger.
  - The infrastructure is already built and orphaned: `assets/css/04-components.css:1100-1119` ships a WCAG-compliant `.scoria-span--status-error` overlay (Phase 51 D-12) that **no component applies**, and `online_scoring.ex:453` already matches `String.upcase(status_code) == "ERROR"` to drive negative-signal sampling — **the eval flywheel is waiting on ERROR spans that nothing emits.**
  - Vocabulary is settled, invent nothing: `"OK"` (default, `trace_projection.ex:39`) / `"ERROR"`.
  - **Note for planning:** OTel's own `with_span/3` is `try…after` — it does NOT catch, does NOT set ERROR status, and records no exception. Our `try/rescue → ERROR + reraise` is **strictly better than the reference implementation.** Say so in the moduledoc.
- **D-01e — every span writes `tenant_id` top-level AND into `attributes`** (D-00c). Without this the span persists and the operator never sees it.

### D-02 — Parent linkage: EXPLICIT ONLY. `Scoria.Observe.Context` is CUT. (revised — red-team BLOCKER)

Area A's central lock was a process-local context stack (`:scoria_observe_ctx` pdict key + a `:"$callers"` one-hop fallback + depth cap + `context_resolver` MFA hook). **Red-team killed it, and the evidence is decisive: not one of this phase's producers can use it.**

| Producer | Where it runs | Ambient span context? |
|---|---|---|
| G1 `ReleaseGate.check/1` (`lib/scoria/runtime.ex:40`) | inline in the caller's process, **before any span exists** | **No** |
| G2/G3/G4 (`lib/scoria/workflows/runtime.ex` `execute_step/2`) | inline in `execute_step`'s caller — `runtime.ex:72` (request) or the `Workflows.Reconciler` GenServer | **No** — nothing in the workflow runtime ever opens a span |
| Judge prompt (`lib/scoria/eval/judge_runner.ex:154`) | an **Oban job process** | **No** — and `$callers` there points at the **Oban Producer GenServer** (`deps/oban/lib/oban/queue/producer.ex:107,261`), a guaranteed miss plus a `Process.info/2` cost |
| Compaction prompt (`summarize_worker.ex:96`) | an Oban job process | **No** |

The one place `$callers` *would* work is unnecessary: `MCP.Executor` does use `Task.Supervisor.async_nolink` (`executor.ex:194`), but its `[:scoria, :tool, :*]` telemetry fires in the **parent** process (`executor.ex:51,57,63,69`), outside the Task.

- **D-02a — LOCK: `parent_id`, `trace_id`, and `span_id` are always EXPLICIT opts.** Host declares; Scoria never infers. This is Phase 52's D-R3 contract, kept verbatim. ~200 LOC of speculative infrastructure deleted with **zero success-criterion risk**, and the "host declares, Scoria never infers" doctrine fight dissolves entirely.
- **D-02b — revisit only when a real host integration asks for it.** Note in the moduledoc that an implicit-context variant is a known, deliberate deferral — not an oversight.

### D-03 — The `trace_id` convention (red-team: this must be closed HERE, not handed to the planner)

There is **no trace_id convention today.** `@span_buffer_fields` (`telemetry.ex:74`) excludes `workflow_run_id`, so it survives only because the adapters double-write it into `attributes` — **there is no persisted run↔trace join in the database at all.** Both adapters do `trace_id: metadata[:trace_id] || Ecto.UUID.generate()` (`jido.ex:~46`, `req_llm.ex:~50`) — a **fresh random orphan trace** per span.

- **D-03a — A RUN IS A TRACE. `trace_id = run.id`.** Exposed as one function (`Scoria.Observe.trace_id_for_run/1`); documented. FK-safe and collision-free: `ai_spans.trace_id` FKs to `ai_traces`, `Buffer` upserts trace rows idempotently (`buffer.ex:124-127`, `on_conflict: :nothing`), and `ai_traces.id` has no other producer. This creates the run↔trace join the operator surface **already assumes** (`orchestrator_live.ex` renders `trace[:workflow_run_id]`).
- **D-03b — thread it.** `Workflows.Runtime.execute_step/2` puts `trace_id` into the handler/telemetry metadata so the LLM/tool adapters pick it up **instead of minting a random one.** Without this, guardrail spans and LLM spans land in *different traces* and SC#1's linkage is true only within the guardrail subtree.
- **D-03c — build the step-level parent span.** One span per `execute_step` via `span/4` (kind from `step.kind`). G2/G3/G4's guardrail spans take it as `parent_id`. **Without it, EVENT-01's parent-linkage criterion is literally unsatisfiable for the workflow gates** — there is nothing to be a child of. ~20 LOC on top of `span/4`. In scope; name it as a plan task.
- **D-03d — G1 is special: it runs before the run exists.** `ReleaseGate.check/1` (`runtime.ex:40`) precedes `Workflows.create_run/1`, so `run.id` is unavailable at its decision point. **Emit G1's guardrail span after `create_run` succeeds**, using `run.id` as `trace_id` and `parent_id: nil` (trace root). On a **blocked** gate there is no run — emit with a freshly-minted `trace_id`, `parent_id: nil`. **A blocked run produces a one-span trace.** Document it.

### D-04 — `Scoria.Observe.Adapters.MCP` — the only production `tool` producer (NOT optional)

`jido` is **confirmed not a dependency** (`mix.exs` — `oban`, `req_llm`, no jido). `Adapters.Jido` therefore fires only if the host happens to run Jido. Meanwhile `lib/scoria/mcp/executor.ex` **already emits a complete tool lifecycle that nothing listens to**: `[:scoria, :tool, :started]` (`:194`), `:completed` with `%{duration: duration}` (`:51`), `:timeout` (`:57`), `:failed` with `:reason` (`:63`, `:69`).

- **D-04a — build `Scoria.Observe.Adapters.MCP`** consuming those four events → duration- and failure-bearing TOOL/MCP spans. **Without it SC#1's `tool` leg has no production producer at all.**
- **D-04b — PROJECT the metadata, NEVER merge it.** `executor.ex:37` merges **raw tool `args`** into the metadata and `:63`/`:69` put a raw error `:reason` term. Emit only `tool_ref`, `tool_name`, `status`, `duration_ms`, and an **`args_fingerprint`** — `:erlang.phash2` is **already computed** at `executor.ex:228`, and the precedent column already exists (`lib/scoria/sre/audit_outbox_event.ex:32` has `args_fingerprint` and **no** `args` column). **"Fingerprint, never args" is already the house rule** — follow it. `Bounds` (D-06) is the backstop, not the primary defense.

### D-05 — Guardrail SPANS (the events are Phase 53b)

- **D-05a — the definition.** *A guardrail is a **policy decision point (PDP)** that Scoria evaluates on the runtime path of an AI step, whose outcome can **ALLOW**, **BLOCK**, or **ESCALATE** that step to a human.* Nouns: gate, policy, decision, reason code, subject. Verbs: check, allow, block, escalate. This is not invented vocabulary — it describes code that already exists, using verbs already in the source (`ReleaseGate.check/1`, `Verdict.blocks_release?/1`).
  - *Why this matters:* **every peer models the *check*; almost none model the *decision*.** OpenInference has a `GUARDRAIL` span kind with **zero** outcome attributes. Langfuse has a `GUARDRAIL` observation type with no `effect`. OTel's `gen_ai.evaluation.result` has a score but no action. OpenAI moderation has `flagged` but no action. OTel **explicitly rejected** a GenAI policy vocabulary ([semantic-conventions#1034](https://github.com/open-telemetry/semantic-conventions/issues/1034) closed and routed to the generic `security_rule.*` namespace, which still has no outcome field; [#3374](https://github.com/open-telemetry/semantic-conventions/issues/3374) — "should decision outcomes be first-class signals?" — closed with a redirect). **The missing primitive across the whole ecosystem is `effect`. XACML has had it since 2013.** `scoria.guardrail.decision` is that primitive.
  - **⚠ Vocabulary divergence to state in Phase 54:** OpenInference defines `GUARDRAIL` narrowly ("protect against jailbreak user input prompts"). Scoria's definition is **broader** (any runtime policy gate). Defensible, but say so, or an adopter will assume it means content moderation.
- **D-05b — four producers, all on live paths.** **G1** `lib/scoria/runtime.ex:40` (`ReleaseGate.check/1` inside `Scoria.start_run/2`; public entry `lib/scoria.ex:51`) and **G2** `lib/scoria/workflows/runtime.ex:186` (`{:waiting_for_approval, …}`) are **MANDATORY** — together they cover *block* and *escalate*. **G3** `workflows/runtime.ex:165` (budget) and **G4** `workflows/runtime.ex:290` (breaker) are the same seam, ~3 lines each — ship if there's room, defer without guilt.
- **D-05c — the span is "it ran".** One GUARDRAIL span per **evaluation**, duration-bearing, carrying the decision as an attribute. *(Phase 53b adds the `guardrail_triggered` event = "it **fired**", emitted only when `decision != "allow"`.)*
- **D-05d — `not_applicable` ⇒ NO span.** `ReleaseGate.check/1` has no-op fall-throughs (`release_gate.ex:57`, `:62` `def check(_), do: :ok`) and returns `:ok` immediately when no `prompt_ref` is configured (`:46-59`). A host with no prompt policy would otherwise get a meaningless guardrail span **on every single run**. XACML's `NotApplicable` — cite it. *(Corollary: today nothing can distinguish a **passed** gate from a **skipped** one. Pundit/CanCanCan both needed bolt-on `verify_authorized` safety nets for exactly this reason. A decision record makes "was this checked?" observable by construction.)*
- **D-05e — `status_code: "OK"` on a BLOCK.** A block is **not** a span error — the *evaluation* succeeded; the business decision went a particular way. `"ERROR"` is reserved for the gate itself raising. This coheres with Phase 51 D-12 (status is an orthogonal overlay axis). Getting this wrong would (a) light every blocked run red in the trace tree and (b) feed junk into `online_scoring.ex`'s `"ERROR"` sampler. **The decision lives in `scoria.guardrail.decision`, never in `status_code`.**
- **D-05f — Semconv-owned closed enums** (`lib/scoria/observe/semconv.ex`; anti-inline grep-guarded per D-15):
  - Keys: `scoria.guardrail.{name, decision, reason_code, subject_ref, policy_key}`
  - `@guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)`
  - `@guardrail_decisions ~w(allow block escalate)` — **`modify` RESERVED** (see D-05h)
  - `@guardrail_reason_codes ~w(unapproved_draft eval_not_passing eval_required approval_required budget_rejected breaker_open)` — these **already exist in the domain**: `ReleaseGate` returns exactly these atoms; the breaker envelope already carries `reason_code: "breaker_open"` (`breaker_registry.ex:139`). **We are not inventing the enum; we are refusing to widen it.**
  - Span `name`: `"guardrail.release_gate"` etc. — ≤4 distinct values, low-cardinality.
  - Unrecognized reason_code → `"unknown"` + `[:scoria, :observe, :guardrail, :fallback]` telemetry (mirrors the `SpanKind.normalize/2` fallback, `span_kind.ex:56-75`).
  - Free reuse of the ATTR-01 seam: `Semconv.merge_host_declared/2` (`semconv.ex:87`).
- **D-05g — 🔒 THERE IS NO FREE-TEXT `reason` KEY. `reason_code` is a closed enum. This is the single most important rule in the phase.**
  - The unbounded reason string is **the leak nobody guards.** Every masking layer in the ecosystem (Langfuse `mask`, LangSmith `hide_inputs`, Traceloop `TRACE_CONTENT=false`) targets `gen_ai.*` inputs/outputs. **None catches a guardrail's own free-text explanation** — which is generated *by a model that just read the PII* and routinely quotes it verbatim. OTel's `AttributeValueLengthLimit` defaults to **∞**.
  - **Scoria has this exact string one refactor away from the trace store:** `Scoria.Eval.JudgeRunner` produces a free-form LLM `explanation:` at `lib/scoria/eval/judge_runner.ex:167` and `:202`. The OTel-blessed `gen_ai.evaluation.explanation` key actively **invites** putting it on a span. Someone will.
  - The builder projects to a **fixed key set** — no host map is ever spread into attributes (mirrors `Semconv.prompt_context/1`'s no-passthrough discipline). The never-text guarantee is **structural**, not a review convention.
- **D-05h — `modify` reserved as an XACML obligation.** Keep `"modify"` in the reserved decision vocabulary and document in the moduledoc that a future `modify` carries an **obligation the caller MUST discharge or deny** — a fail-closed contract, not a suggestion. This is exactly SEED-010's "permit, but spotlight/redact the untrusted content." Costs one comment; saves SEED-010 a vocabulary migration. *(Also: keep the **decision** (allow/block/escalate) separate from **remediation** (what the caller does about it) — Guardrails AI's `OnFailAction` taxonomy is deliberately separate from its outcome. Don't let a future PR collapse them.)*
- **D-05i — ❌ DO NOT TOUCH `ai_approvals.policy_outcome` (revised — red-team BLOCKER, verified).** Area B proposed stamping a guardrail decision id onto it, calling it "currently dead." **It is not dead.** It is a **live, low-cardinality enum column owned by the connector-auth lane**: written at `lib/scoria/connectors/auth.ex:344` (`"auth_required"` / `"scope_escalation_required"`, enumerated at `:325-328`), and **read + projected to the operator surface** at `lib/scoria/workflows/remote_approval_projection.ex:88`. Writing a span UUID into it would silently poison `RemoteApprovalProjection`. **The approval↔guardrail stamp is CUT from Phase 53** — no success criterion requires it. If it is ever wanted, add a **new** `ai_approvals.guardrail_decision_id :binary_id` column; never reuse `policy_outcome`.
- **D-05j — rejected producers** (each for a reason worth keeping): `PromptPolicy` — a *normalizer*, not a PDP; its `approval_required` / `grounding_required` / `tools_allowed` booleans (`prompt_policy.ex:26-28`) are **written and never read by any enforcement point** (log this as a latent lie in the public API surface; the guardrail seam is what would enforce it — later). `Observe.CircuitBreaker` — G4 already covers this at the actual enforcement point; instrumenting both double-counts. `Eval` / online scoring — an eval **judges**, it does not **gate**; OpenInference, Langfuse, **and Scoria's own whitelist** all separate `EVALUATOR` from `GUARDRAIL` (the failing-eval path *does* gate — via **G1**, which is where we instrument it). `SemanticCache` — a cache miss is a *routing* decision, not a policy decision; calling it a guardrail would drown the real signal in cache-miss noise.

### D-06 — SEC-01: the write-time bound + the closed key registry

- **D-06a — WHERE: a new `lib/scoria/observe/bounds.ex`** (`Bounds.enforce(metadata, :span | :event) :: {:ok, map()} | :drop`), called in `Telemetry.handle_event/4` **immediately after `Redactor.redact/1` and BEFORE `ReviewerBroadcast` + `Buffer.cast_span`.**
  - **NOT inside `Redactor`:** its `:mfa` config hook (`redactor.ex:11-14`) **replaces redaction wholesale**, so a bound living there is **silently removable by adopter config**. Scoria's SEC-01 promise is to the **adopter's end users**, not to the adopter — it must not be adopter-removable.
  - **NOT in the Semconv builders:** both adapters build attribute maps inline and emit directly, so a builder-local bound is trivially bypassed by the next adapter → fails the SC "a regression test would fail" bar.
  - **NOT at the DB layer:** `Buffer` uses `insert_all` (`buffer.ex:129`), which **bypasses changesets entirely**. Non-starter, verified.
  - Bounding **before** the broadcast is load-bearing: a 2 MB attribute map pushed to an operator LiveView is a real browser DoS.
- **D-06b — THE GUARANTEE: a closed key registry, not a deny-pattern.** A size bound alone does not stop raw text (a 200-byte completion fits any cap). `Semconv.attribute_registry/0 :: %{key => class}` where `class ∈ :id | :count | :enum | :flag | :timestamp | :structured` — **there is no `:free_text` class; it is unrepresentable.** Three admission tiers:
  1. **Registry (exact match)** — admitted, bounded per class.
  2. **Vendor prefixes** (`gen_ai.` / `server.` / `openai.` / `req_llm.` / `error.`) — admitted as bounded scalars **unless** a dot-segment hits `@denied_segments`.
  3. **Host prefixes** — `config :scoria, Scoria.Observe.Bounds, allowed_key_prefixes: ["myapp."]`, default `[]`.
  - **`scoria.` / `openinference.` / `jido.` and all bare keys are REGISTRY-ONLY — no prefix escape.** Scoria's own namespaces are **closed**. A Scoria dev therefore **cannot persist a new key without editing the registry**, and that edit trips a D-15-style canary asserting the exact sorted key list. **Two deliberate red-test edits stand between a 2 a.m. `attributes["completion"] = resp.text` and an adopter's Postgres.** That is the SC guarantee.
  - **INV-SEC01 (state it as an invariant):** *the set of attribute keys Scoria itself can persist ≡ `Semconv.attribute_registry/0`'s keys. No registry entry may declare a free-text class. Every `:structured` key's builder output is leaf-asserted (Phase 52's D-ATTR02-4 test, generalized).*
  - **Bonus:** Phase 54's DOCS-02 conformance check ("every span uses only allow-listed convention key names") then **reads the same registry**. This phase hands Phase 54 its allow-list for free.
- **D-06c — 🔴 THREE REGISTRY BUGS THE RED TEAM CAUGHT (all must be fixed at implementation):**
  1. **Pre-seed the bare keys the dashboard QUERIES, or the trace UI goes dark.** `orchestrator_live.ex:237` hydrates on `fragment("?->>? = ?", s.attributes, "tenant_id", …)`. The adapters write bare `"tenant_id"`, `"workflow_run_id"`, `"duration_ms"` into `attributes`; Phase 52 ships bare `feature`/`route`/`archetype`/`intent`. **If `Bounds` drops unregistered bare keys, every trace disappears from the dashboard.** The registry MUST be pre-seeded with all of these **before `Bounds` is enabled**, and the acceptance test must include "hydrate a trace in `OrchestratorLive` with Bounds on."
  2. **Exact dot-segment equality, NEVER substring.** Under substring matching, `args_fingerprint` (which contains `args`) would be **dropped** — killing the very field D-04b relies on. Ship a test asserting `args_fingerprint`, `gen_ai.usage.input_tokens`, and `gen_ai.output.type` all pass while `gen_ai.input.messages` is dropped.
  3. **Segment denial does NOT stop the req_llm leak it exists to stop.** `deps/req_llm/lib/req_llm/open_telemetry.ex:431-437` has a `content: :attributes` mode promoting `gen_ai.input.messages`, `gen_ai.output.messages`, `gen_ai.system_instructions`, `gen_ai.tool.definitions`. Under exact-segment matching the first two are blocked (`messages`), but **`gen_ai.system_instructions` (segment is `system_instructions`, not `instructions`) and `gen_ai.tool.definitions` PASS** — and `Semconv.merge_req_llm_attributes/2` (`semconv.ex:33-37`) is an **unfiltered `Map.merge`**. A req_llm minor bump would then silently persist raw prompts **with zero Scoria code change.** **Fix: add an exact-key denylist for those four keys**, plus a version-pinned canary test over `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1`'s key set. *(That canary is also half of Phase 54's DOCS-02 check.)*
- **D-06d — the numbers** (`config :scoria, Scoria.Observe.Bounds`): `max_attribute_bytes: 256` (a string leaf — >4× the longest legitimate value, too short to be a useful prompt); `max_attribute_count: 128` (**OTel parity** — `OTEL_ATTRIBUTE_COUNT_LIMIT`); `max_depth: 5`; `max_list_length: 100` (Phase 52 D-ATTR02-6 parity); **`max_total_bytes: 16_384` (revised — red-team)**; `max_delta_chunk_bytes: 2_048`; `allowed_key_prefixes: []`; `capture_error_messages: false`. **No disable switch** — limits tune *upward* only, and raising a byte cap never relaxes key admission.
  - **Why 16 KB, not 8 KB:** Phase 52's D-ATTR02-4 already asserts `Jason.encode!` of `scoria.prompt.context` **alone** ≤ 8 KB with 100-chunk + 100-memory caps. An 8 KB budget for the **whole** attribute map would truncate a full pack and **regress Phase 52 SC#4.** Register `scoria.prompt.context` as class `:structured`; confirm `max_depth: 5` / `max_list_length: 100` don't clip it (it needs depth 3 and exactly 100 — **do not lower either**). Alternative: exempt `:structured` keys from the total and bound them individually.
  - **No `Jason.encode!` on the hot path** — approximate byte accounting during the single traversal. `Bounds` runs synchronously in the caller's process on **every** span. The exact `Jason.encode!` assertion lives in the **test**.
- **D-06e — violation behavior.** Unregistered / denied key → **DROP the key** (truncating prose still leaves prose — drop is the only answer consistent with "never raw text"). Oversized *admitted* value → **truncate** + `…[TRUNCATED]` suffix. Over-count → drop beyond the limit in deterministic sorted-key order. Markers (themselves registry keys): `scoria.attributes.dropped` (int), `scoria.attributes.dropped_keys` (≤10 names, ≤64 B each), `scoria.attributes.truncated_keys`. **OTel only records a *count* of dropped attributes — shipping the *names* is strictly better operator UX and costs nothing.** *(Residual, document it: a host that puts PII in a key **name** leaks it here; the 64 B / 10-name cap bounds it.)*
- **D-06f — the guard must be observable.** `[:scoria, :observe, :bounds, :exceeded]` telemetry (counts + reason + key names) so an SRE can alert on *"my instrumentation is trying to log prompts"* — the SEC-01 counterpart of `[:scoria, :observe, :buffer, :flush_error]`. Plus a **once-per-distinct-key-per-node** `Logger.warning` (reuse the ETS dedupe already in `reviewer_broadcast.ex` and the storm-control precedent in `buffer.ex:177`). The dev learns at **dev time**, prod ops learn **once**, not 10k times.
- **D-06g — 🔴 `exception.message` is NOT PERSISTED in v3.6 (revised — Area D wins over Area A).** An exception message is arbitrary-length, attacker/prompt-influenced text: `Ecto.NoResultsError` embeds the query, `Postgrex.Error` embeds parameter values, and `mcp/executor.ex:63` already stuffs a raw `:reason` term into tool telemetry. **`Semconv.error_attributes/1` emits `exception.type` / `error.type` ONLY** (a module name — low-cardinality, enum-like). No message, no stacktrace. `capture_error_messages: true` may exist as an opt-in, defaults `false`, and when on must still route through `Bounds` truncation + `Redactor.scrub_text/1`. **This formally revises Area A's D-53A-1.**
  - This is the deliberate inverse of **OpenInference**, whose `OPENINFERENCE_HIDE_INPUTS` / `HIDE_OUTPUTS` / `HIDE_PROMPTS` flags all default **False** (capture-by-default, opt-in-to-hide — every adopter who never reads the docs ships prompts to a vendor). **Scoria mirrors the vocabulary and inverts the default.** That is a sharper README line than the compatibility claim itself: *"OpenInference-compatible naming; Scoria never captures message content at all — there is no `HIDE_INPUTS` because inputs are never captured."*
- **D-06h — `Redactor.redact/1` can return a NON-MAP.** Proven: `test/scoria/observe/redactor_test.exs:52-58`'s `:mfa` override returns the bare atom `:custom_mfa_called`. `telemetry.ex:71`'s `Map.take/2` would then raise `BadMapError` **inside the synchronous telemetry handler**, and `emit_span/1`'s `try/rescue → :ok` swallows it — **the span vanishes silently.** `Bounds.enforce/2` must **fail closed** (`:drop` + telemetry + log) on a non-map, and must never propagate (`try/rescue → :drop`). This is a latent bug today, independent of SEC-01.
- **D-06i — scope of the bound.** Spans: **all** emitters. `ReviewerBroadcast` PubSub: **yes** (bound applies before the broadcast). `[:scoria, :observe, :span, :delta]` streaming chunks: **persistence is out of scope — verified** (`telemetry.ex:51-58` only broadcasts; there is no `Buffer.cast_span`), but **egress is in scope** — cap at `max_delta_chunk_bytes` and keep `scrub_delta_chunk/1`. **The CHANGELOG must say this out loud:** *"streaming deltas carry completion text to the operator's browser in memory; they are never persisted."* Anything less is a dishonest SEC-01 claim. **`Bounds.enforce(_, :event)`'s `:event` arm is BUILT AND UNIT-TESTED in this phase and ACTIVATED in Phase 53b** — this is the explicit assignment of SEC-01's event clause across the split.
- **D-06j — SRE metrics path (red-team).** `Scoria.SRE.Telemetry` already emits guardrail-adjacent metrics carrying `policy_key` / `trace_id` / `run_id` / `actor_id` in the attrs map (`lib/scoria/workflows/runtime.ex:716-733`). **Never put `reason_code`, `subject_ref`, `policy_key`, or a decision id on a metric dimension** — OTel's Metrics SDK has a default **cardinality limit of 2000** and on overflow **silently folds** into a synthetic `otel.metric.overflow=true` bucket: *your dashboards start lying rather than erroring.* Verify the bound's posture covers this path; at minimum, document the rule.

### D-07 — The trace-tree UI (SC#1's other half — not optional, see D-00b)

- **D-07a — consume `--indent-level`.** Add a `padding-left: calc(...)` rule to `.scoria-span` in `assets/css/04-components.css`, or inline it as `workflow_tree_component.ex:23` already does. **Do not leave the var dangling.**
- **D-07b — apply the ERROR overlay.** `.scoria-span--status-error` **already exists** (`04-components.css:1100-1104`) and the component simply never applies it (zero `status` references in `trace_tree_component.ex`). Apply it when `String.upcase(status_code) == "ERROR"`, plus the `.sr-only` "Errored" label the CSS comment (`:1094-1098`) explicitly demands (**WCAG 1.4.1 — never color-alone**).
- **D-07c — `TraceProjection.tree_order/1` (pre-order DFS).** Hydrate orders `asc: s.start_time` (`orchestrator_live.ex:238`); live-append is **arrival order** (`:385-389`). **Start-time order is not tree order** — two concurrent tool calls under one agent will render indented under the wrong sibling. Nothing caught this because nothing was ever nested. Apply `tree_order/1` on both paths.
- **D-07d — 🔴 CYCLE GUARD (a DoS this phase itself activates).** `TraceProjection.depth_for/3` (`trace_projection.ex:58-62`) has **no cycle guard and no depth cap**. A self-parent or a 2-cycle **infinite-loops the LiveView process**. It is latent today only because `parent_id` is effectively always nil — **Phase 53 populates `parent_id` and arms it.** Visited-set + hard depth cap, **in the same plan that first writes `parent_id`.** Test that `with_depths([%{id: "a", parent_id: "a"}])` **terminates**.
- **D-07e — guardrail affordance.** `trace_tree_component.ex` currently renders only a rail + a name. Add a badge for `span_kind == "guardrail"`. **The rail token `--scoria-span-guardrail` already exists in both themes** (`assets/css/02-tokens.css:177,259`; brandbook `tokens.json` — amber `#ffd166` dark / `#7a5a16` light). **No new tokens needed.** Microcopy names the gate and states the decision in operator words, never the raw reason_code: *"Blocked — prompt version is a draft, not released"*, *"Held for approval — this step needs a human"*, *"Blocked — budget exhausted"*, *"Blocked — provider circuit is open"*. Allowed reads neutral: *"Checked — allowed"* (**not "Passed"** — that reads like an eval score). Mirror the existing `ReviewCopy.severity_label/1` enum→copy pattern (`review_copy.ex:47-58`).
- **D-07f — orphan behavior stays.** A parent not in the fetched set ⇒ depth 0 ⇒ renders as a root. That is the right graceful default under an eventually-consistent Buffer. Keep it.

### D-08 — What Phase 53 does NOT do (guard the boundary)

- **No `emit_event/1`, no `ai_span_events` writes, no FK migration, no Buffer event list** — Phase 53b. This phase builds the **spans** those events will attach to.
- **No `PromptRegistry.render/3` (revised — red-team CUT).** Area B proposed a `{{var}}` substitution engine + fail-loud missing-var handling + token counting as the host DX path. **No success criterion mentions host prompt rendering.** It is a DX feature smuggled into an observability phase → **backlog** (revisit in 53b if `prompt_rendered` needs a host-facing producer).
- **No `with_agent/3`**, no approval↔guardrail stamp (D-05i), no `Scoria.Observe.Context` (D-02).
- **No event broadcasting to the operator UI.** No SC requires it. **Flag loudly as a roadmapped follow-on:** in v3.6 a fired guardrail lands in Postgres and **no operator can see it**. That is a deliberate, known gap — not a silent omission.

### Claude's Discretion (delegated to researcher/planner)

- **Plan sequencing within the 6-plan budget.** Plan 01 (pipeline wiring, D-00a) is a **hard prerequisite** — everything else is unverifiable without it. The rest can be waved.
- **Whether G3/G4 ship in this phase** (~3 lines each on the same seam as G1/G2) or defer. No SC depends on them.
- **The exact internal factoring of `Bounds`** (one traversal vs. two; where the marker keys are assembled) — keep it Semconv-owned and grep-guarded.
- **Whether the `:structured`-key total-bytes exemption or the flat 16 KB cap is cleaner** (D-06d) — either satisfies the constraint; pick one and test it against Phase 52's full 100-chunk pack.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements & roadmap (authoritative)
- `.planning/REQUIREMENTS.md` — v3.6 locked requirements. **Phase 53 owns EVENT-01 + SEC-01 only** (EVENT-02/EVENT-03 moved to Phase 53b during this discussion; the traceability table was updated in the same change). Scope doctrine (convention-not-columns, host-declares-Scoria-never-infers, zero required egress) is held here.
- `.planning/ROADMAP.md` §"Phase 53" — goal + 4 success criteria (the acceptance bar), and §"Phase 53b" — **the boundary this phase must NOT cross.** Both were rewritten during this discussion.

### The foundation this phase reuses (READ FIRST)
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/51-CONTEXT.md` — the span-emission + FK-safe trace-upsert pipeline, `SpanKind` (D-10..D-15), `Semconv` single-origin (D-16), the Buffer flush-error posture (D-05..D-09), the `status`-as-overlay-axis rule (D-12), and the drift-guard-test pattern (D-15) this phase mirrors.
- `.planning/phases/52-retriever-span-host-declared-attributes/52-CONTEXT.md` — the Semconv seam (`merge_host_declared/2`, `retrieval_config_attributes/1`, `prompt_context/1`), the `@span_buffer_fields` "all keys go in `attributes`" rule (D-00), own-id semantics (D-R2), and the D-ATTR02-4 leaf-assertion guard shape that SEC-01 generalizes.
  - **⚠ Phase 53 formally REVISES two Phase-52 decisions:** **D-R6** (success-path-only spans → ERROR spans now required by EVENT-01) and **D-ATTR01-4** (deferred value hygiene → `Bounds` now applies to host-declared keys; **add a regression test that a normal `feature`/`route` value still passes byte-for-byte with Bounds ON** — this is the seam most likely to silently break Phase 52's SC#3). **D-ATTR02-1**'s promised PROMPT-span relocation is fulfilled here with zero contract change.
- `.planning/seeds/SEED-007-trace-foundation-otel-openinference.md` — origin seed.
- `.planning/seeds/SEED-010-*.md` — lethal-trifecta (NEXT milestone). The guardrail vocabulary locked here is its substrate: a confluence evaluator is a fifth gate of the same shape (`escalate` exists; `modify` is reserved for spotlighting/redaction). **Build none of it here.** Also note for SEED-010: *store `content_hash` + character offsets + score + detector_id, **never the content*** (Guardrails AI's `error_spans: [{start, end, reason}]` is the best precedent — it stores offsets, not content). The moderation paradox: flagged content is disproportionately extreme, so a store that persists it becomes the highest-severity data concentration in the stack, and GDPR Art. 17 erasure vs. an immutable audit log is unsolvable *if you store bodies*.
- `.planning/seeds/SEED-011-*.md` — owns `user_feedback_received` **emission**. Not emitted in v3.6.

### Convention sources (reference, NOT dependencies)
- `deps/req_llm/lib/req_llm/open_telemetry/attributes.ex` — `start/1` / `terminal/1`; the closed scalar key set Scoria merges today.
- **`deps/req_llm/lib/req_llm/open_telemetry.ex:431-437`** — the `content: :attributes` mode promoting `gen_ai.input.messages` / `gen_ai.output.messages` / `gen_ai.system_instructions` / `gen_ai.tool.definitions`. **This is the evidence for D-06c(3): the single most likely path by which raw prompt text lands in an adopter's DB, requiring zero Scoria code change.** `req_llm 1.13` locked.
- OpenInference span-kind enum + configuration spec — **`PROMPT` and `GUARDRAIL` are both real span kinds** (the Python enum is `TOOL, CHAIN, LLM, RETRIEVER, EMBEDDING, AGENT, RERANKER, UNKNOWN, GUARDRAIL, EVALUATOR, PROMPT`), so `span_kind.ex`'s mappings are correct and Phase 54's conformance claim is not at risk. Its `HIDE_INPUTS`/`HIDE_OUTPUTS` privacy flags all default to **capture** — Scoria mirrors the vocabulary and **inverts the default** (D-06g). Plain-string reference; **do not add `opentelemetry*` as a dep.**

### Project DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, Ecto-native durable state, consumer-not-provider API (hide the span plumbing), host owns identity/policy, zero-config default.
- `brandbook/` — **canonical** for the trace-tree affordances (D-07e). The `--scoria-span-guardrail` token already exists in both themes; no new tokens needed. Brandbook **supersedes** any older brand references in `prompts/`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scoria/observe.ex` — the Phase-52 host-facing facade (`emit_retriever_span/1`, `emit_prompt_span/1`). `span/4` + the `with_*` wrappers land here; the two existing emitters refactor **onto** it with unchanged signatures.
- `lib/scoria/observe/semconv.ex` — the single key-string owner. Extend with: `attribute_registry/0`, `vendor_key_prefixes/0`, `guardrail_keys/0` + the three closed enums, `error_attributes/1` (type only), `duration_key/0`.
- `lib/scoria/observe/span_kind.ex` — `normalize/2` + `to_openinference/1`; `guardrail`/`prompt`/`tool` already in the whitelist, CSS rails already exist. The `normalize/2` unknown-value fallback + telemetry is the pattern D-05f's `reason_code` fallback mirrors.
- `lib/scoria/observe/buffer.ex` — `flush_now/1` test hook, the FK-safe `Ecto.Multi`, `Map.put_new_lazy(:id, …)`.
- `lib/scoria/observe/reviewer_broadcast.ex` — the ETS once-per-trace dedupe (`@trace_seen_table`) that D-06f's once-per-key log dedupe reuses.
- `lib/scoria/sre/audit_outbox_event.ex:32` — the **`args_fingerprint`-never-`args`** precedent D-04b follows. `mcp/executor.ex:228` already computes the `:erlang.phash2`.

### Established Patterns
- **Span persistence contract:** only `@span_buffer_fields` survive `Telemetry.buffer_span/1` (`telemetry.ex:74`) → **all new keys go in `attributes`** (52 D-00). `tenant_id`/`workflow_run_id` survive only because the adapters double-write them.
- **Drift-guard test discipline (51 D-15):** canary + exhaustiveness + anti-inline grep + real-Postgres assertion after `Buffer.flush_now/1`. **Never hand-synthesize a telemetry event as production evidence** (52 D-ATTR01-6) — reuse the `prompt_span_test.exs:20-52` setup (scoped Buffer + real `Telemetry.attach/1`).
- **Loud-but-non-fatal (51 D-05..D-09):** observability never breaks host business logic. `span/4`'s emit, `Guardrail.emit/1`, and `Bounds` all wrap `try/rescue`. The one exception: `span/4` **reraises the host's own exception** — it must be observably unchanged.

### Integration Points
- **`lib/scoria/application.ex:10-21`** — add `Scoria.Observe.Buffer` to children; call `Telemetry.attach/1` on boot (match+ignore `{:error, :already_exists}` so tests that attach explicitly still work); `config :scoria, Scoria.Observe, enabled: false` to opt out. **CHANGELOG it — adopters get span persistence they didn't have.** *(Plan 01, gates everything.)*
- **New:** `lib/scoria/observe/bounds.ex`, `lib/scoria/observe/adapters/mcp.ex`, `lib/scoria/observe/guardrail.ex`.
- `lib/scoria/observe/telemetry.ex:60-74` — insert `Bounds.enforce/2` between `Redactor.redact/1` and `ReviewerBroadcast`/`Buffer.cast_span`; guard the non-map case (D-06h). *(Note: `telemetry.ex` has **two** `Redactor.redact(` call sites today — `:52` delta, `:68` span. Phase 53b collapses them to one for EVENT-02's "identical call site"; this phase should not fight that.)*
- `lib/scoria/runtime.ex:40` — **G1**; emit after `create_run` (D-03d). `lib/scoria/workflows/runtime.ex:165 / :186 / :290` — **G3 / G2 / G4**; `execute_step/2` gains the step-level parent span (D-03c) and threads `trace_id` (D-03b).
- `lib/scoria/observe/adapters/{req_llm,jido}.ex` — take `trace_id` from metadata instead of minting a random one; mint `:id` at emit time (a flush-time id is unreferenceable as a `parent_id`).
- `lib/scoria_web/components/trace_tree_component.ex`, `lib/scoria_web/live/orchestrator_live.ex:237-238,385-389`, `lib/scoria/observe/trace_projection.ex:47-63`, `assets/css/04-components.css`, `lib/scoria_web/review_copy.ex` — the D-07 UI lane.
- `test/scoria_web/components/trace_tree_component_test.exs:7-33` — **must be rewritten**; it currently asserts the flat-DOM bug.
- `lib/scoria/eval/judge_runner.ex:154` — the live prompt-render site (Oban `:evals`, reached via `CampaignWorker.perform/1` and `online_scoring.ex:323`). **Phase 53 wraps it in a PROMPT span; Phase 53b adds the `prompt_rendered` event.** ⚠ **`Compaction.SummarizeWorker` has NO enqueuer in `lib/`** (verified: `new_job/2` has zero callers) — it runs only if a *host* enqueues it. Instrument it for symmetry, but **it is not the production proof.**

</code_context>

<specifics>
## Specific Ideas

- **Method:** 4 parallel cross-aware research subagents + 1 adversarial red-team pass, every claim verified against real code. The red team **killed two locks outright** — the `ai_approvals.policy_outcome` stamp (BLOCKER: the column is live, not dead) and `Scoria.Observe.Context` (BLOCKER: not one producer in this phase can use it) — **corrected three registry bugs** that would have blanked the operator dashboard, dropped `args_fingerprint`, and left the actual req_llm prompt-leak path open, and **forced the scope split** (9–10 plans → 6 + 4).
- **The phase coheres under one line:** *one `span/4` seam every producer calls with explicit ids, one `Bounds` choke point every payload passes through, one `Semconv` registry that owns every key string — and a trace tree that finally renders the tree.*
- **The differentiator worth stating out loud:** `ai_span_events` is a Postgres table Scoria owns — **durable and unsampled**, unlike an OTel span event, which the SDK is licensed by spec to drop (`OTEL_SPAN_EVENT_COUNT_LIMIT = 128`, plus sampling). *An audit record the telemetry SDK may silently discard is not an audit record.* **Scoria accidentally already has OPA's decision-log architecture: the decision record is durable; the span is the correlation handle.** 🚩 **Flag to Phase 54:** if Scoria ever adds an OTLP exporter, `guardrail_triggered` **must not** be exported as an OTel span event — export it as a log record or a separate signal.

</specifics>

<deferred>
## Deferred Ideas

- **`emit_event/1`, `ai_span_events`, the FK-drop migration, the Buffer event list + ordered flush, the 3-name allow-list, `prompt_rendered` / `guardrail_triggered` emission** — **Phase 53b** (EVENT-02, EVENT-03). The FK-drop is **approved**: `ai_span_events.span_id` is a hard FK while `ai_spans.parent_id` is deliberately FK-free for the identical out-of-order-arrival reason; `insert_all` **raises** on an FK violation and takes the whole `Ecto.Multi` (up to 1000 spans) with it. Migration is safe for a shipped Hex lib (`Install.Surface.Migrations` reports new migrations as structural drift with `mix scoria.install --check` remediation; 3 post-0.1.0 migrations already ship this way, no fixture refresh needed).
- **`Scoria.Observe.Context`** (process-local trace context + `$callers` hop + `context_resolver` MFA) — cut; revisit when a real host integration asks for implicit nesting.
- **`PromptRegistry.render/3`** — a `{{var}}` substitution engine + fail-loud missing-var + token count. Real DX value, no success criterion. Backlog.
- **The approval↔guardrail join** — needs a **new** `ai_approvals.guardrail_decision_id` column; never reuse the live `policy_outcome`.
- **Operator UI for events** — a fired `guardrail_triggered` is invisible to the operator in v3.6. Roadmapped follow-on, deliberately.
- **`PromptPolicy`'s unenforced booleans** (`approval_required` / `grounding_required` / `tools_allowed` — written, never read) — a latent lie in the public API surface. The guardrail seam is what would enforce them. Later.
- **`with_agent/3`**, `EMBEDDING`/`RERANKER` first-class span kinds, auto-inferred `archetype`/`intent` classifiers — out of scope (v3.7+ / explicitly excluded).

### Reviewed Todos (not folded)
None — `todo.match-phase 53` returned zero matches.

</deferred>

---

*Phase: 53-structured-child-spans-write-time-bound*
*Context gathered: 2026-07-12 (4 parallel research subagents + adversarial red-team, verified against real code)*
