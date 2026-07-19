# Phase 53: Structured Child Spans + Write-Time Bound - Research

**Researched:** 2026-07-12
**Domain:** Elixir/OTP observability pipeline (telemetry → redaction → bound → persistence) + Phoenix LiveView trace-tree rendering, inside a pre-1.0 Hex library (Scoria) that must not take on new runtime dependencies.
**Confidence:** HIGH — every architectural claim below was verified against the real Scoria codebase (file:line) during this session; the few genuinely external claims (`:telemetry.span/3` semantics, OTel default limits) are `[CITED]` against official docs.

## Summary

This phase has already been researched exhaustively by four parallel discuss-phase subagents plus an adversarial red-team pass — the resulting `53-CONTEXT.md` is not a set of options to weigh, it is a **locked implementation spec** with file:line evidence for nearly every claim (D-00 through D-08). This RESEARCH.md's job is narrower: (1) independently re-verify the load-bearing code citations so the planner can trust them without re-deriving them, (2) supply the Elixir/OTP/Phoenix idiom layer CONTEXT.md assumes but doesn't spell out (supervision-tree wiring shape, `:telemetry.span/3` precedent, `reraise`/`:erlang.raise/3` semantics, WCAG status-overlay pattern, Ecto.Multi idempotency), and (3) fill the planner-facing scaffolding sections (Validation Architecture, Security Domain, Package Legitimacy, Architectural Responsibility Map) that CONTEXT.md does not produce in planner-consumable form.

**Everything in `## User Constraints` below is locked.** Do not propose alternatives to D-00 through D-08; research supporting detail for them instead. The single highest-leverage finding, independently re-verified in this session: `Scoria.Observe.Buffer` is genuinely absent from `Scoria.Application`'s children list (`lib/scoria/application.ex:10-21`, confirmed by direct read) and `Telemetry.attach/1` (`lib/scoria/observe/telemetry.ex:11`) has zero `lib/` callers (confirmed by grep-equivalent read of every adapter — only `req_llm.ex`/`jido.ex` emit spans, neither attaches the handler). Every span Phases 51 and 52 built is therefore inert in a real host app today. Plan 01 (wiring) is a hard, ordering-sensitive prerequisite for every other plan in this phase, exactly as CONTEXT.md D-00a states.

**Primary recommendation:** Build one transparent wrapper `Scoria.Observe.span(kind, name, opts, fun)` (D-01a) that both existing emitters (`emit_retriever_span/1`, `emit_prompt_span/1`) refactor onto with zero signature change, wire `Buffer` into the supervision tree with an `enabled: false` escape hatch (D-00a/Integration Points), insert a single `Bounds.enforce/2` choke point between `Redactor.redact/1` and `ReviewerBroadcast`/`Buffer.cast_span` (D-06a), and consume the already-computed `--indent-level` CSS variable that the trace tree has been silently discarding since Phase 51 shipped (D-00b).

## User Constraints (from CONTEXT.md)

<user_constraints>

### Locked Decisions

**D-00 — The three findings that reshaped this phase (independently re-verified, all confirmed):**
- D-00a: `Scoria.Observe.Buffer` is not in `Scoria.Application`'s children (`lib/scoria/application.ex:10-21`) and `Telemetry.attach/1` has zero `lib/` callers. Every span emitted in a real host app fires into a void. This is Plan 01 and gates everything else.
- D-00b: `trace_tree_component.ex:36` sets `style={"--indent-level: #{depth}"}` and no CSS rule consumes it (only `workflow_tree_component.ex:23` inlines its own `padding-left: calc(...)`). `TraceProjection.with_depths/1` computes depth correctly and it is thrown away. The existing test locks the bug in. SC#1 cannot be met by backend work alone — UI is in scope.
- D-00c: `ReviewerBroadcast.span_stopped/1` fail-closes on a missing top-level `tenant_id`; `orchestrator_live.ex:237` hydrates on `attributes->>'tenant_id'`. `emit_retriever_span/1`/`emit_prompt_span/1` set neither. Every span this phase emits must write `tenant_id` top-level AND into `attributes`.

**D-01 — The span seam: one generic wrapper.**
- D-01a: `Scoria.Observe.span(kind, name, opts, fun)` is the single primitive. Mints fresh `span_id`, uses `System.monotonic_time` for duration, wall-clock `start_time`/`end_time`, runs `fun`, emits on `[:scoria, :observe, :span, :stop]`. Emit itself stays wrapped `try/rescue -> :ok`. Returns `fun`'s value verbatim. Rejected: `start_span`/`stop_span` pair (orphan-span bug); `@decorate` macro (needs a dep + compile magic, can layer later).
- D-01b: thin kind wrappers `with_tool/3`, `with_prompt/3`, `with_guardrail/3`. No `with_agent/3`.
- D-01c: `emit_retriever_span/1` and `emit_prompt_span/1` keep exact public signatures, refactored onto `span/4`. Extract shared attribute pipeline into one private builder.
- D-01d (REVISES Phase-52 D-R6): spans are failure-bearing. `try/rescue` + `catch` → `status_code: "ERROR"` → `reraise e, __STACKTRACE__` (`:erlang.raise/3` for throw/exit). Host's exception observably unchanged. Vocabulary: `"OK"` / `"ERROR"` only.
- D-01e: every span writes `tenant_id` top-level AND into `attributes`.

**D-02 — Parent linkage: EXPLICIT ONLY. `Scoria.Observe.Context` is CUT.**
- D-02a: `parent_id`, `trace_id`, `span_id` are always explicit opts. Host declares; Scoria never infers.
- D-02b: revisit only when a real host integration asks for it.

**D-03 — The `trace_id` convention.**
- D-03a: A run is a trace. `trace_id = run.id`. Exposed via `Scoria.Observe.trace_id_for_run/1`.
- D-03b: `Workflows.Runtime.execute_step/2` puts `trace_id` into handler/telemetry metadata so LLM/tool adapters pick it up instead of minting a random one.
- D-03c: build the step-level parent span — one span per `execute_step` via `span/4` (kind from `step.kind`). G2/G3/G4's guardrail spans take it as `parent_id`.
- D-03d: G1 runs before the run exists. Emit G1's guardrail span after `create_run` succeeds, using `run.id` as `trace_id`, `parent_id: nil`. On a blocked gate there is no run — emit with a freshly-minted `trace_id`, `parent_id: nil`. A blocked run produces a one-span trace.

**D-04 — `Scoria.Observe.Adapters.MCP` — the only production `tool` producer.**
- D-04a: build `Scoria.Observe.Adapters.MCP` consuming `[:scoria, :tool, :started/:completed/:timeout/:failed]` → duration- and failure-bearing TOOL/MCP spans.
- D-04b: project the metadata, never merge it. Emit only `tool_ref`, `tool_name`, `status`, `duration_ms`, `args_fingerprint` (already computed via `:erlang.phash2` — see verification below). Follow the `args_fingerprint`-never-`args` house rule.

**D-05 — Guardrail SPANS (events are Phase 53b).**
- D-05a: a guardrail is a policy decision point (PDP) Scoria evaluates on the runtime path of an AI step, whose outcome can ALLOW, BLOCK, or ESCALATE. Vocabulary is not invented — it describes existing code (`ReleaseGate.check/1`, `Verdict.blocks_release?/1`).
- D-05b: four producers. G1 `runtime.ex:40` and G2 `workflows/runtime.ex:186` are MANDATORY (block + escalate). G3 (`:165`, budget) and G4 (`:290`, breaker) are the same seam, ~3 lines each — ship if there's room.
- D-05c: the span is "it ran" (one GUARDRAIL span per evaluation, duration-bearing, decision as attribute). Phase 53b adds the `guardrail_triggered` event = "it fired."
- D-05d: `not_applicable` ⇒ NO span. `ReleaseGate.check/1` has no-op fall-throughs (`release_gate.ex:57,62,46-59`).
- D-05e: `status_code: "OK"` on a BLOCK. A block is not a span error. `"ERROR"` reserved for the gate itself raising. Decision lives in `scoria.guardrail.decision`, never `status_code`.
- D-05f: Semconv-owned closed enums. Keys: `scoria.guardrail.{name, decision, reason_code, subject_ref, policy_key}`. `@guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)`. `@guardrail_decisions ~w(allow block escalate)` (`modify` RESERVED). `@guardrail_reason_codes ~w(unapproved_draft eval_not_passing eval_required approval_required budget_rejected breaker_open)`. Span name `"guardrail.release_gate"` etc. Unrecognized reason_code → `"unknown"` + `[:scoria, :observe, :guardrail, :fallback]` telemetry.
- D-05g: 🔒 THERE IS NO FREE-TEXT `reason` KEY. `reason_code` is a closed enum. The single most important rule in the phase. `Scoria.Eval.JudgeRunner` produces a free-form `explanation:` at `judge_runner.ex:167`/`:202` (independently verified — confirmed at those exact line numbers) that must never reach a guardrail span.
- D-05h: `modify` reserved as an XACML obligation — future work carries a fail-closed contract.
- D-05i: ❌ DO NOT TOUCH `ai_approvals.policy_outcome` — it is a live column owned by the connector-auth lane (`connectors/auth.ex:344`, `remote_approval_projection.ex:88`).
- D-05j: rejected producers: `PromptPolicy` (normalizer, not a PDP), `Observe.CircuitBreaker` (G4 already covers), `Eval`/online scoring (judges, doesn't gate), `SemanticCache` (routing, not policy).

**D-06 — SEC-01: the write-time bound + the closed key registry.**
- D-06a: new `lib/scoria/observe/bounds.ex` (`Bounds.enforce(metadata, :span | :event) :: {:ok, map()} | :drop`), called in `Telemetry.handle_event/4` immediately after `Redactor.redact/1` and BEFORE `ReviewerBroadcast` + `Buffer.cast_span`. Not inside `Redactor` (adopter-removable via `:mfa` hook — independently verified at `redactor.ex:11-14`). Not in Semconv builders (bypassed by next adapter). Not at DB layer (`Buffer` uses `insert_all`, bypasses changesets — independently verified at `buffer.ex:129`).
- D-06b: THE GUARANTEE is a closed key registry, not a deny-pattern. `Semconv.attribute_registry/0 :: %{key => class}`, `class ∈ :id | :count | :enum | :flag | :timestamp | :structured` — no `:free_text` class. Three admission tiers: (1) registry exact-match, (2) vendor prefixes (`gen_ai.`/`server.`/`openai.`/`req_llm.`/`error.`) unless denied segment, (3) host prefixes via config, default `[]`. `scoria.`/`openinference.`/`jido.`/bare keys are REGISTRY-ONLY, no prefix escape.
- D-06c: THREE REGISTRY BUGS TO AVOID: (1) pre-seed bare keys the dashboard queries (`tenant_id`, `workflow_run_id`, `duration_ms`, `feature`/`route`/`archetype`/`intent`) or the trace UI goes dark; (2) exact dot-segment equality never substring (or `args_fingerprint` gets dropped by a `args` segment-deny); (3) segment denial alone doesn't stop the req_llm leak — `gen_ai.system_instructions`/`gen_ai.tool.definitions` pass exact-segment denial of `messages`/`instructions`, need an exact-key denylist for those four keys plus a version-pinned canary.
- D-06d: numbers — `max_attribute_bytes: 256`, `max_attribute_count: 128`, `max_depth: 5`, `max_list_length: 100`, `max_total_bytes: 16_384`, `max_delta_chunk_bytes: 2_048`, `allowed_key_prefixes: []`, `capture_error_messages: false`. No disable switch. 16 KB not 8 KB because Phase 52's `scoria.prompt.context` alone can be ≤8 KB.
- D-06e: violation behavior — unregistered/denied key → DROP; oversized admitted value → truncate + `…[TRUNCATED]`; over-count → drop beyond limit in sorted-key order. Markers: `scoria.attributes.dropped`, `scoria.attributes.dropped_keys` (≤10 names, ≤64B each), `scoria.attributes.truncated_keys`.
- D-06f: `[:scoria, :observe, :bounds, :exceeded]` telemetry + once-per-distinct-key-per-node `Logger.warning` (reuse ETS dedupe pattern from `reviewer_broadcast.ex`).
- D-06g: `exception.message` NOT persisted in v3.6 — `exception.type`/`error.type` only. Inverts OpenInference's capture-by-default posture.
- D-06h: `Redactor.redact/1` can return a non-map (proven: `test/scoria/observe/redactor_test.exs:52-58`). `Bounds.enforce/2` must fail closed on non-map.
- D-06i: scope — spans: all emitters. ReviewerBroadcast PubSub: yes. Delta chunks: persistence out of scope (verified — no `Buffer.cast_span` on delta path), but egress capped at `max_delta_chunk_bytes`. `Bounds.enforce(_, :event)` built + unit-tested this phase, activated in Phase 53b.
- D-06j: never put `reason_code`/`subject_ref`/`policy_key`/decision id on an SRE metric dimension (OTel Metrics SDK cardinality-2000 overflow silently folds into `otel.metric.overflow=true`).

**D-07 — The trace-tree UI (SC#1's other half).**
- D-07a: consume `--indent-level` via a `padding-left: calc(...)` rule on `.scoria-span`.
- D-07b: apply the ERROR overlay — `.scoria-span--status-error` already exists (`04-components.css:1100-1104`, independently confirmed), component never applies it. Apply when `String.upcase(status_code) == "ERROR"` plus `.sr-only` "Errored" label.
- D-07c: `TraceProjection.tree_order/1` (pre-order DFS). Hydrate orders `asc: s.start_time`; live-append is arrival order (`orchestrator_live.ex:385-389`, independently confirmed). Apply `tree_order/1` on both paths.
- D-07d: 🔴 CYCLE GUARD — `TraceProjection.depth_for/3` (`trace_projection.ex:58-62`, independently confirmed no cycle guard/depth cap) infinite-loops on a self-parent once `parent_id` is populated. Visited-set + hard depth cap, in the same plan that first writes `parent_id`.
- D-07e: guardrail affordance — badge for `span_kind == "guardrail"`. `--scoria-span-guardrail` token already exists both themes (independently confirmed at `02-tokens.css:177,259`). No new tokens needed.
- D-07f: orphan behavior stays — parent not in fetched set ⇒ depth 0 ⇒ renders as root.

**D-08 — What Phase 53 does NOT do:** no `emit_event/1`, no `ai_span_events` writes, no FK migration, no Buffer event list (Phase 53b). No `PromptRegistry.render/3`. No `with_agent/3`, no approval↔guardrail stamp, no `Scoria.Observe.Context`. No event broadcasting to operator UI (flag loudly as roadmapped follow-on).

### Claude's Discretion

- Plan sequencing within the 6-plan budget. Plan 01 (pipeline wiring, D-00a) is a hard prerequisite — everything else is unverifiable without it.
- Whether G3/G4 ship in this phase (~3 lines each) or defer. No SC depends on them.
- Exact internal factoring of `Bounds` (one traversal vs. two; where marker keys are assembled) — keep Semconv-owned and grep-guarded.
- Whether the `:structured`-key total-bytes exemption or the flat 16 KB cap is cleaner — either satisfies the constraint; pick one and test against Phase 52's full 100-chunk pack.

### Deferred Ideas (OUT OF SCOPE)

- `emit_event/1`, `ai_span_events`, FK-drop migration, Buffer event list + ordered flush, 3-name allow-list, `prompt_rendered`/`guardrail_triggered` emission — **Phase 53b**.
- `Scoria.Observe.Context` (process-local trace context + `$callers` hop) — cut; revisit when a real host integration asks for implicit nesting.
- `PromptRegistry.render/3` — DX feature, no success criterion, backlog.
- Approval↔guardrail join — needs a NEW `ai_approvals.guardrail_decision_id` column; never reuse live `policy_outcome`.
- Operator UI for events — a fired `guardrail_triggered` is invisible to the operator in v3.6.
- `PromptPolicy`'s unenforced booleans — a latent lie in the public API surface. Guardrail seam would enforce them, later.
- `with_agent/3`, `EMBEDDING`/`RERANKER` first-class span kinds, auto-inferred `archetype`/`intent` classifiers — out of scope (v3.7+).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVENT-01 | `tool`/`prompt`/`retrieval`/`guardrail` emitted as real child spans (duration/failure-bearing) with `parent_id` linkage, rendered as a tree | D-01 (span/4 wrapper), D-02 (explicit parent linkage), D-03 (trace_id convention), D-04 (MCP adapter), D-05 (guardrail spans), D-07 (UI tree rendering + cycle guard) — see Architecture Patterns, Code Examples |
| SEC-01 | New attribute/event payloads capture IDs/counts never raw text; size bounded at write time behind a closed key registry with a regression test that goes RED on unbounded free text | D-06 (Bounds module design, closed registry, three registry bugs to avoid) — see Architecture Patterns "Bounds choke point", Common Pitfalls, Security Domain |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Span emission (`span/4`, `with_tool/3` etc.) | API / Backend (host app process) | — | Runs inline in whatever process the host calls it from (Oban worker, LiveView, plain request process) — Scoria is a library, not a service boundary |
| Parent/trace ID threading | API / Backend | — | Explicit opts only (D-02a); no cross-tier propagation mechanism exists or is being built |
| Telemetry redaction + bound (`Redactor`, `Bounds`) | API / Backend | — | Synchronous, in-process, before any persistence or broadcast |
| Span persistence (`Buffer` → Postgres) | Database / Storage | API / Backend (GenServer owns the batching) | `Scoria.Repo` via `Ecto.Multi.insert_all`; async batched flush |
| Operator dashboard broadcast (`ReviewerBroadcast`) | API / Backend (Phoenix.PubSub) | Frontend Server (SSR/LiveView) | PubSub fan-out is backend; the LiveView process that receives it is SSR |
| Trace tree rendering (`TraceTreeComponent`, CSS) | Frontend Server (LiveView component) | Browser (CSS custom-property consumption) | Phoenix LiveComponent renders server-side; `--indent-level` is consumed by a CSS rule evaluated client-side |
| Guardrail evaluation (`ReleaseGate`, workflow gates) | API / Backend | — | Runs inline in the workflow runtime process; no new tier |
| MCP tool telemetry → span adapter | API / Backend | — | `:telemetry.attach_many` handler in the host BEAM node, not a network boundary |
| Supervision-tree wiring (`Buffer` under `Scoria.Application`) | API / Backend (OTP) | — | Elixir/OTP application-tier concern, not web-tier |

**Why this matters for this phase specifically:** every capability above resolves to "API/Backend" except the trace-tree render, which is the one place a misassignment would be easy — e.g. trying to fix the flat-tree bug (D-00b) with a JS hook or client-side layout library instead of the existing CSS custom-property + Phoenix LiveComponent mechanism already half-built (`--indent-level` is already computed and threaded; it just needs a consuming CSS rule, per D-07a). Do not introduce a JS dependency for tree indentation — `workflow_tree_component.ex:23` already proves the CSS-only approach works.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | pinned transitively (via `phoenix`/`oban`/`req_llm`), no direct `mix.exs` entry needed | event dispatch backbone for the entire span pipeline | already the spine of Phases 51/52; `:telemetry.execute/3` and `:telemetry.attach_many/4` are the only primitives this phase needs — no new API surface |
| `Ecto.Multi` | already a transitive dep via `ecto`/`ecto_sql` | atomic trace-upsert + span-insert-all in `Buffer.flush_spans/1` | already proven in Phase 51 (`buffer.ex:123-129`); this phase reuses the identical shape, does not need a new one |
| `Phoenix.LiveComponent` / `Phoenix.Component` | already a dep | `TraceTreeComponent` render + CSS custom-property indentation | idiomatic Phoenix pattern already used by `WorkflowTreeComponent` (`workflow_tree_component.ex:23`) — mirror it, do not introduce a JS tree-layout library |

**No new runtime dependency is required for this phase.** [VERIFIED: mix.exs] — confirmed by reading `/Users/jon/projects/scoria/mix.exs`: current deps are `oban ~> 2.19`, `req_llm ~> 1.13`, plus the standard Phoenix/Ecto stack; `jido` is confirmed **not** a dependency (grep of `mix.exs` deps list returned no match), which is the direct evidence behind D-04's "MCP is the only production tool producer" conclusion.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:erlang.raise/3` (BIF, no dep) | OTP-native | re-raising a caught `throw`/`exit` unchanged inside `span/4`'s failure path | when the caught value is a `throw`/`exit` rather than an `%_{}` exception struct — `reraise/2` only covers the `rescue` (exception) case; `catch` needs `:erlang.raise(kind, reason, stacktrace)` |
| `Ecto.Adapters.SQL.Sandbox` (test-only, already a dep) | test-only | real-Postgres acceptance tests for `Bounds`/`span/4`/guardrail spans, mirroring the existing `prompt_span_test.exs` pattern | every new drift-guard/acceptance test in this phase (D-ATTR01-6 discipline: never hand-synthesize a telemetry event as production evidence) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom `span/4` wrapper | `:telemetry.span/3` (built into the `:telemetry` package already in the dep tree) [CITED: hexdocs.pm/telemetry] | `:telemetry.span/3` already implements almost exactly D-01a/D-01d's contract — it runs a function, emits `[prefix, :start]`, and on success emits `[prefix, :stop]` or on exception emits `[prefix, :exception]` **and reraises the caught error** (confirmed via hexdocs: "If an exception does occur, an `EventPrefix ++ [exception]` event will be emitted and the caught error will be re-raised"). It is a legitimate, official-library precedent for the exact try/catch/reraise/emit shape this phase needs. **Not adopted directly** because Scoria's existing consumers (`Telemetry.handle_event/4`, `Buffer`, `ReviewerBroadcast`) are all wired to a single `[:scoria, :observe, :span, :stop]` event carrying a flat span map (`status_code`, `attributes`, etc.) — not telemetry's three-event (`start`/`stop`/`exception`) shape with a `{result, stop_metadata}` return contract. Re-plumbing every consumer to the three-event shape is out of scope and not requested by any success criterion. **Cite it in the `span/4` moduledoc as prior art** — it is independent confirmation that "catch, mark, reraise" is the correct idiomatic shape, not a Scoria invention. |
| Hand-rolled dot-segment matcher for `Bounds`'s vendor-prefix admission | `String.split(key, ".")` + `List.last/1` equality against `@denied_segments` (stdlib only) | no library needed; the entire admission-tier logic in D-06b/D-06c is a few `Enum`/`String` calls over a closed key list — do not reach for a pattern-matching or trie library for ~10 keys |

**Installation:** No new packages. This phase only wires and extends existing modules (`Scoria.Observe`, `Scoria.Observe.Semconv`, `Scoria.Observe.Telemetry`, `Scoria.Observe.Buffer`, `Scoria.Application`) and adds new sibling modules in the same namespace (`Scoria.Observe.Bounds`, `Scoria.Observe.Guardrail`, `Scoria.Observe.Adapters.MCP`).

## Package Legitimacy Audit

**No external packages are installed by this phase.** [VERIFIED: mix.exs] Every module this phase adds (`Bounds`, `Guardrail`, `Adapters.MCP`) is new Scoria-internal code; every capability it depends on (`:telemetry`, `Ecto.Multi`, `Phoenix.LiveComponent`) is already a resolved transitive dependency exercised by Phases 51/52. The Package Legitimacy Gate protocol (registry check, postinstall-script check) does not apply — there is nothing to check.

**Packages removed due to [SLOP] verdict:** none (no packages considered).
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│ HOST APP PROCESS (request / Oban job / LiveView / workflow runtime)     │
│                                                                           │
│  Scoria.Runtime.start_run/2 ──► ReleaseGate.check/1 (G1, pre-run gate)  │
│         │                              │                                │
│         │                     Guardrail.emit/1 (after create_run,      │
│         │                      trace_id = run.id, parent_id: nil)      │
│         ▼                                                               │
│  Workflows.create_run/1  ──► trace_id = run.id (D-03a)                 │
│         │                                                               │
│         ▼                                                               │
│  Workflows.Runtime.execute_step/2                                      │
│         │  ┌── span/4(step.kind, ..., trace_id, parent_id: step-span)  │  step-level parent span (D-03c)
│         │  ├── G2/G3/G4 guardrail checks ──► Guardrail.emit/1          │  child of step span (D-03b/c)
│         │  ├── MCP.Executor.execute/4 ──► [:scoria,:tool,:*] ──┐       │
│         │  └── req_llm / Jido adapters ──► [:req_llm,...]/[:jido,...] │
│         │                                                       │       │
└─────────┼───────────────────────────────────────────────────────┼───────┘
          │                                                       │
          ▼                                                       ▼
  :telemetry.execute([:scoria,:observe,:span,:stop], ...)   Adapters.MCP (NEW, D-04a)
          │                                                       │
          └───────────────────────┬───────────────────────────────┘
                                   ▼
              Scoria.Observe.Telemetry.handle_event/4  (attached on BOOT — D-00a)
                     │
                     ├─► Redactor.redact/1        (key-based deny-list scrub)
                     │
                     ├─► Bounds.enforce/2  (NEW, D-06a — closed registry + size cap)
                     │       │
                     │       ├─ :drop  ──► [:scoria,:observe,:bounds,:exceeded] telemetry + once-per-key log
                     │       └─ {:ok, bounded_metadata}
                     │
                     ├─► ReviewerBroadcast.span_stopped/1 ──► Phoenix.PubSub "scoria:runs:{tenant_id}"
                     │                                              │
                     └─► Buffer.cast_span/2 (GenServer.cast)        ▼
                                │                          OrchestratorLive (LiveView)
                                ▼                                   │
                     Scoria.Observe.Buffer (NEW: supervised          ▼
                     under Scoria.Application, D-00a)      TraceTreeComponent
                                │                            (consumes --indent-level,
                        (5s timer OR flush_now/1)             D-07a; applies status-error
                                ▼                              overlay, D-07b; tree_order/1
                     Ecto.Multi: trace upsert                  not arrival order, D-07c;
                       (on_conflict: :nothing)                 cycle-guarded depth_for/3,
                       + span insert_all                       D-07d)
                                ▼
                          Postgres (ai_traces, ai_spans)
```

A reader tracing the primary use case: a host starts a run → G1 evaluates before the run exists → once the run exists its `id` becomes the trace root → each workflow step opens its own span and threads that as `parent_id` for any guardrail/tool/prompt/retrieval child span it triggers → every span emission funnels through one telemetry event → passes through redaction then the new write-time bound → branches to both a live broadcast (for the open dashboard) and a durable buffered write (for reload/hydrate) → the trace tree component finally renders the resulting `parent_id` graph as actual visual nesting instead of a flat list.

### Recommended Project Structure

```
lib/scoria/observe/
├── observe.ex                  # EXTEND: span/4, with_tool/3, with_prompt/3,
│                                #   with_guardrail/3; emit_retriever_span/1 and
│                                #   emit_prompt_span/1 refactor onto span/4
├── semconv.ex                  # EXTEND: attribute_registry/0, vendor_key_prefixes/0,
│                                #   guardrail_keys/0 + 3 closed enums, error_attributes/1
├── telemetry.ex                # EXTEND: insert Bounds.enforce/2 call between
│                                #   Redactor.redact/1 and Buffer.cast_span/ReviewerBroadcast
├── buffer.ex                   # UNCHANGED shape (D-08 boundary: no event list this phase)
├── bounds.ex                   # NEW (D-06a) — the write-time write-time bound choke point
├── guardrail.ex                # NEW (D-05) — guardrail span builder/emitter
├── span_kind.ex                # UNCHANGED (Phase 51 already ships guardrail/prompt/tool/mcp)
├── trace_projection.ex         # EXTEND: tree_order/1 (D-07c), cycle-guarded depth_for/3 (D-07d)
├── redactor.ex                 # UNCHANGED
├── reviewer_broadcast.ex       # UNCHANGED (already fail-closes correctly on tenant_id)
└── adapters/
    ├── mcp.ex                  # NEW (D-04a) — [:scoria,:tool,*] -> TOOL/MCP spans
    ├── req_llm.ex               # UNCHANGED this phase (trace_id sourcing from metadata
    │                            #   already works via metadata[:trace_id] fallback)
    └── jido.ex                  # UNCHANGED this phase

lib/scoria/application.ex        # EXTEND: add Scoria.Observe.Buffer to children,
                                  #   call Telemetry.attach/1 on boot (D-00a)

lib/scoria/runtime.ex             # EXTEND: G1 guardrail emit after create_run (D-03d)
lib/scoria/workflows/runtime.ex   # EXTEND: step-level parent span (D-03c), trace_id
                                   #   threading (D-03b), G2 (mandatory) + G3/G4 (optional)

lib/scoria_web/components/
├── trace_tree_component.ex      # EXTEND: guardrail badge (D-07e), status-error overlay (D-07b)
└── workflow_tree_component.ex   # reference pattern only (already correct)

assets/css/04-components.css     # EXTEND: consume --indent-level (D-07a)

test/scoria/observe/
├── bounds_test.exs              # NEW — registry canary, byte-cap, dot-segment exactness,
│                                 #   req_llm-leak canary, non-map fail-closed
├── guardrail_test.exs           # NEW — G1/G2 span shape, no free-text, not_applicable-no-span
├── span_test.exs                # NEW — span/4 duration+failure semantics, reraise fidelity
└── adapters/mcp_test.exs        # NEW — 4-event lifecycle -> spans, args_fingerprint-not-args

test/scoria_web/components/
└── trace_tree_component_test.exs # REWRITE — currently locks in the flat-DOM bug (D-00b)
```

### Pattern 1: The transparent `span/4` wrapper (D-01a/D-01d)

**What:** a single function every span-emitting call site funnels through; it owns duration measurement, failure-status marking, and the emit — never the caller.
**When to use:** any new call site that needs a child span (guardrail check, MCP tool call already wrapped via its own adapter, step-level parent span).
**Example (illustrative shape — plan/implement task owns the exact code):**
```elixir
# Source: pattern derived from :telemetry.span/3 (hexdocs.pm/telemetry) + this
# phase's D-01a/D-01d, adapted to Scoria's existing single-stop-event contract
# (Telemetry.handle_event/4 only recognizes [:scoria, :observe, :span, :stop] —
# see lib/scoria/observe/telemetry.ex:60-66, verified this session).
def span(kind, name, opts, fun) do
  span_id = opts[:span_id] || Ecto.UUID.generate()
  start_wall = DateTime.utc_now()
  start_mono = System.monotonic_time()

  {status_code, result} =
    try do
      {"OK", fun.()}
    catch
      kind_c, reason ->
        emit_span(kind, name, opts, span_id, start_wall, start_mono, "ERROR")
        :erlang.raise(kind_c, reason, __STACKTRACE__)
    rescue
      e ->
        emit_span(kind, name, opts, span_id, start_wall, start_mono, "ERROR")
        reraise e, __STACKTRACE__
    else
      value -> {"OK", value}
    end

  emit_span(kind, name, opts, span_id, start_wall, start_mono, status_code)
  result
end
```
**Note the double-emit risk in the sketch above** — a real implementation must emit exactly once per outcome (success OR failure), not twice on the failure path. The planner/implementer must resolve this with a single `try/catch/rescue/else` structure where each branch does its own emit-then-return/reraise, never falling through to a shared post-emit call after the failure branches already emitted. This is exactly the kind of orphan-emission footgun D-01a's rejection of the "start/stop pair" primitive is designed to prevent — keep the emit and the outcome branch atomic in one clause.

### Pattern 2: `:telemetry.span/3`'s catch/reraise contract as precedent [CITED: hexdocs.pm/telemetry]

**What:** the official `:telemetry` package already ships a `span/3` primitive that runs a function, and "if an exception does occur, an `EventPrefix ++ [exception]` event will be emitted and the caught error will be re-raised" — i.e., the exception is never swallowed, it propagates after telemetry observes it.
**When to use:** as design-precedent evidence in the `span/4` moduledoc (per D-01d's explicit instruction: "Say so in the moduledoc") that catch-mark-reraise is the correct, ecosystem-standard shape — not a Scoria invention, and stricter than OpenTelemetry's own `with_span/3` (which is `try...after` only, no catch, no status, per D-01d).
**Source:** https://hexdocs.pm/telemetry/telemetry.html

### Pattern 3: One choke-point write-time bound (D-06a)

**What:** `Bounds.enforce(metadata, :span | :event) :: {:ok, map()} | :drop`, called exactly once, in `Telemetry.handle_event/4`, between `Redactor.redact/1` and the two downstream consumers.
**When to use:** every span (and, structurally but inactive until Phase 53b, every event).
**Verified insertion point:**
```elixir
# Source: lib/scoria/observe/telemetry.ex:60-66 (read this session)
def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  redacted = Redactor.redact(metadata)
  # NEW: Bounds.enforce/2 goes HERE, between redact and the two consumers below.
  ReviewerBroadcast.span_stopped(redacted)
  Buffer.cast_span(buffer_span(redacted), buffer_name)
end
```
A `:drop` result from `Bounds.enforce/2` must short-circuit both `ReviewerBroadcast.span_stopped/1` and `Buffer.cast_span/2` for that span/event — a dropped span must not reach either sink.

### Pattern 4: Supervision-tree wiring with an opt-out (D-00a)

**What:** add `Scoria.Observe.Buffer` to `Scoria.Application`'s children and call `Telemetry.attach/1` in `start/2`, guarded by a config flag so hosts and internal tests retain control.
**Existing precedent in the same file** (verified this session, `lib/scoria/application.ex:29-31`):
```elixir
defp maybe_reconciler do
  if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
end
```
This is the exact shape to mirror for `Buffer` — a `maybe_*` helper folded into the `++` children list, **except** the enablement condition here should be an explicit `config :scoria, Scoria.Observe, enabled: false` opt-out (per CONTEXT's Integration Points), not a `Mix.env()` check — because the whole point of this phase is that persistence must work in a **real host app's `:prod` environment**, not just skip itself there. Test-env implications: existing tests that `start_supervised!({Buffer, name: :some_scoped_name, ...})` and call `Telemetry.detach("scoria-observe-telemetry")`/`attach(buffer_name)` explicitly (the `prompt_span_test.exs` pattern, verified this session) are unaffected — they operate on differently-named scoped buffers, not the default-named one the application boots. `Telemetry.attach/1` must tolerate being called when a handler with that id already exists (`:telemetry.attach_many/4` returns `{:error, :already_exists}` on a duplicate handler id — match and ignore it, don't crash boot).

### Pattern 5: Cycle-guarded tree depth (D-07d)

**What:** `TraceProjection.depth_for/3` currently recurses on `parent_id` with no visited-set and no depth cap — verified this session at `lib/scoria/observe/trace_projection.ex:58-62`:
```elixir
defp depth_for(%{parent_id: nil}, _parent_map, depth), do: depth
defp depth_for(%{parent_id: parent_id}, _parent_map, depth) when is_nil(parent_id), do: depth

defp depth_for(span, parent_map, depth) do
  case Map.get(parent_map, span.parent_id) do
    nil -> depth
    parent -> depth_for(parent, parent_map, depth + 1)
  end
end
```
This is safe today only because no producer sets `parent_id` to anything but `nil` in practice. Once D-02/D-03 wire real `parent_id` values, a self-parent or 2-cycle (possible from a buggy host call, not just Scoria's own code — hosts pass `parent_id` explicitly per D-02a) will infinite-loop the LiveView process computing it. **Required test:** `with_depths([%{id: "a", parent_id: "a"}])` must terminate.

### Pattern 6: `--indent-level` CSS consumption (D-07a)

**What:** `trace_tree_component.ex:36` (verified this session) already sets the custom property; no rule reads it:
```heex
style={"--indent-level: #{Map.get(span, :depth, 0)}"}
```
**The exact fix pattern already exists one file over**, verified this session at `workflow_tree_component.ex:23`:
```heex
style={"--indent-level: #{Map.get(step, :depth, 0)}; padding-left: calc(0.75rem + var(--indent-level) * 1.25rem)"}
```
Either inline the same `padding-left: calc(...)` onto `trace_tree_component.ex`'s row div, or add the equivalent rule to `.scoria-span` in `04-components.css` (D-07a leaves the choice open — either satisfies the constraint). The CSS-variable-driven approach avoids any JS dependency and matches the CSS custom-property pattern already used for span-kind rail coloring (`--scoria-span-guardrail` etc., `02-tokens.css:177,259`, verified this session).

### Anti-Patterns to Avoid

- **Reviving `Scoria.Observe.Context` (process-local trace context):** killed by red-team with decisive evidence (no producer in this phase runs in a process where implicit context would resolve correctly — Oban workers, pre-run gates, and workflow-runtime callers all break it). Do not reintroduce a `Process.put`/`$callers`-based context stack.
- **Computing `trace_id` independently per adapter:** the current `metadata[:trace_id] || Ecto.UUID.generate()` fallback in both `req_llm.ex:50` and `jido.ex:44` (verified this session) mints a fresh orphan trace whenever the caller doesn't supply one. Once D-03b threads `trace_id` through `execute_step`, every span within one workflow step must receive it explicitly — don't leave the random-fallback as the only path for spans this phase's new producers emit.
- **Truncating instead of dropping an unregistered key:** D-06e is explicit — truncation of an unregistered key still leaves prose on the span (a 256-byte prefix of a leaked prompt is still a leaked prompt). Only registry membership decides admission; only admitted values get truncated for size.
- **Storing the guardrail's "reason" as free text:** the single most important rule in the phase (D-05g). `JudgeRunner.explanation` (verified this session at `judge_runner.ex:167` and `:202`, both confirmed) is exactly the kind of LLM-generated free text that must never reach a `scoria.guardrail.*` attribute — only the closed `reason_code` enum may.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Catch-mark-reraise span lifecycle | a bespoke exception-tracking state machine | the `try/catch/rescue/else` + `reraise`/`:erlang.raise/3` pattern, following `:telemetry.span/3`'s own precedent [CITED] | this is a solved, well-trodden BEAM idiom; the only Scoria-specific work is mapping the outcome onto `status_code` and the existing single-stop-event contract |
| Attribute allow-listing | a regex/substring deny-pattern scanner over attribute values | a closed key **registry** (`Semconv.attribute_registry/0`) checked by key, not value | D-06b is explicit: a size bound alone doesn't stop raw text (a 200-byte completion fits any cap); only closing the key space is structural. A deny-pattern is a game of whack-a-mole against every future key a developer might add |
| Trace-tree nesting/indentation | a JS tree-layout library or client-side recursive DOM builder | server-computed `depth` (`TraceProjection.with_depths/1`, already correct) + a CSS custom property + one `calc()` rule (`workflow_tree_component.ex:23`'s pattern) | the depth computation and the rendering primitive already exist and already work in the sibling component; this is a one-line CSS gap, not a rendering-architecture gap |
| Guardrail decision vocabulary | a new ad-hoc severity/outcome enum | XACML's ALLOW/BLOCK/ESCALATE (+ reserved MODIFY-as-obligation) vocabulary, already the closest-fit prior art the CONTEXT.md research surveyed across OpenInference/Langfuse/OTel/OPA | every peer models the *check*, not the *decision*; XACML has had exactly this primitive since 2013 — don't invent a new one when reusing a citable precedent gives the planner and future adopters a name to look up |
| Span-id/parent-id threading across process boundaries | an implicit context-propagation library (e.g., something `$callers`-based, or a custom `Process` dictionary convention) | explicit `opts[:parent_id]`/`opts[:trace_id]`/`opts[:span_id]` on every call (D-02a) | proven this session: none of G1 (pre-run), G2-G4 (workflow runtime, no open span), or the two Oban-job prompt-render sites have an ambient span context an implicit mechanism could reliably read — explicit is not a compromise here, it is strictly correct |

**Key insight:** every "don't hand-roll" item above already has either (a) a working sibling implementation elsewhere in this exact codebase (`workflow_tree_component.ex` for CSS indentation, `SpanKind.normalize/2`'s telemetry-fallback pattern for `Bounds`'s unregistered-key telemetry) or (b) an official upstream library precedent (`:telemetry.span/3`) or (c) a citable external standard (XACML). The discipline this phase enforces is "reuse the nearest already-correct pattern," not "invent a new abstraction."

## Common Pitfalls

### Pitfall 1: Double-emitting a span on the failure path
**What goes wrong:** a naive `span/4` implementation emits once inside a `catch`/`rescue` clause (to mark ERROR before reraising) and then falls through to a second, shared emit call after the `try` block — producing two persisted rows for one logical span invocation.
**Why it happens:** the natural instinct when adding failure handling to a success-only wrapper is to add a branch, not restructure the control flow; `reraise`/`:erlang.raise/3` must happen from *inside* the catch/rescue clause (stacktrace availability requires it — `__STACKTRACE__` is only bound inside the matching clause), which makes it easy to leave the "normal" emit path still reachable.
**How to avoid:** every outcome branch (`catch`, `rescue`, success) does its own single emit-then-return/reraise; there is no code path after the `try` that emits again.
**Warning signs:** a test asserting exactly one `Buffer.flush_now/1`-visible span per `span/4` call around a raising `fun` — if that test needs `assert length(spans) == 1` and it's flaky or shows 2, this is the bug.

### Pitfall 2: Bare-key registry gaps silently blanking the operator dashboard
**What goes wrong:** `Bounds` ships with a registry that doesn't include every bare key the dashboard's SQL actually queries (`tenant_id`, `workflow_run_id`) or that Phase 52 already writes (`feature`, `route`, `archetype`, `intent`, `duration_ms`) — every trace disappears from `OrchestratorLive` because `attributes->>'tenant_id'` (`orchestrator_live.ex:237`, verified this session) now matches nothing.
**Why it happens:** the registry is built by reasoning about what *this phase* writes, not by auditing every bare key every *existing* consumer reads.
**How to avoid:** before enabling `Bounds`, grep every `attributes->>` / `Map.get(attrs, "...")` / `attrs["..."]` bare-key read site across `lib/scoria_web/live/` and `lib/scoria/observe/`, and pre-seed the registry with all of them. Write the acceptance test as "hydrate a trace in `OrchestratorLive` with Bounds on" per D-06c(1), not just a unit test of `Bounds` in isolation.
**Warning signs:** any manual QA of the dashboard after this phase ships shows an empty trace list where traces existed before.

### Pitfall 3: Substring key matching instead of exact dot-segment matching
**What goes wrong:** a denylist check implemented as `String.contains?(key, "args")` (or similar) drops `args_fingerprint` — the exact field D-04b relies on to avoid persisting raw tool args — because `"args_fingerprint"` contains the denied substring `"args"`.
**Why it happens:** substring matching feels simpler to write than segment-splitting, and passes casual manual testing (denying `gen_ai.input.messages` "just works" with `contains?`).
**How to avoid:** split the key on `.`, compare the exact segment(s) against `@denied_segments`, never `String.contains?`/regex substring matching on the whole key. Ship the test from D-06c(2) verbatim: `args_fingerprint`, `gen_ai.usage.input_tokens`, `gen_ai.output.type` all pass while `gen_ai.input.messages` is dropped.
**Warning signs:** any registry/denylist test that only checks the *denied* keys are dropped and never checks that a superficially-similar *admitted* key survives.

### Pitfall 4: Segment-exact denial that still misses the actual leak vector
**What goes wrong:** exact-segment denial of `messages` blocks `gen_ai.input.messages`/`gen_ai.output.messages` but **passes** `gen_ai.system_instructions` (last segment `system_instructions`, not `instructions`) and `gen_ai.tool.definitions` — both of which `deps/req_llm/lib/req_llm/open_telemetry.ex:431-437`'s `content: :attributes` mode can promote, and `Semconv.merge_req_llm_attributes/2` (verified this session, `semconv.ex:32-37`) merges wholesale with no filter of its own.
**Why it happens:** the denylist was built by reasoning about the two obviously-named `messages` keys, not by reading the actual req_llm attribute-builder source that would emit the other two under a mode Scoria doesn't currently enable but could regress into via a version bump.
**How to avoid:** add an exact-key denylist (not just segment) for the specific four keys `gen_ai.input.messages`, `gen_ai.output.messages`, `gen_ai.system_instructions`, `gen_ai.tool.definitions`, plus a version-pinned canary test asserting `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1`'s key set hasn't grown to include a raw-content key under the currently-locked `req_llm ~> 1.13`.
**Warning signs:** a future `req_llm` minor bump changes CI green to a silently-larger attribute payload with no Scoria code change — this is only catchable by the version-pinned canary, not by manual review.

### Pitfall 5: Buffer supervision-tree change breaking existing scoped-buffer tests
**What goes wrong:** wiring `Scoria.Observe.Buffer` into `Scoria.Application`'s children under its default name collides with — or silently duplicates alongside — the many existing tests (`prompt_span_test.exs`, `telemetry_test.exs`, verified this session) that already `start_supervised!` their own uniquely-named scoped `Buffer` and detach/reattach `Telemetry` onto it.
**Why it happens:** the default-named `Buffer` now boots automatically in `:test` env too (unless gated), and a default-named `Telemetry.attach/1` call on boot means the *default* `"scoria-observe-telemetry"` handler id is already attached before any test tries to attach it under a scoped name — but tests use `:telemetry.detach("scoria-observe-telemetry")` first, which will now detach the **application-boot** handler, not a test-local one, changing test isolation semantics.
**How to avoid:** confirm `Telemetry.attach/1` tolerates re-attachment/detachment across the test suite (match-and-ignore `{:error, :already_exists}`), and audit whether `:test` env should boot `Buffer`/`attach` at all vs. deferring to the existing per-test scoped pattern — CONTEXT's Integration Points section explicitly calls for "match+ignore `{:error, :already_exists}` so tests that attach explicitly still work," which is the load-bearing detail to get right here.
**Warning signs:** flaky test failures where spans from one test's scoped buffer appear in another test's assertions, or `:telemetry.attach_many/4` raising because a handler id collision isn't being tolerated.

### Pitfall 6: `Redactor.redact/1`'s non-map escape hatch reaching `Bounds` unguarded
**What goes wrong:** `Redactor.redact/1` can return a bare atom (proven by existing test `test/scoria/observe/redactor_test.exs:52-58`, an `:mfa` config override returning `:custom_mfa_called`); `Telemetry.handle_event/4`'s existing `Map.take/2` call would raise `BadMapError` on that, and since the emit call is wrapped `try/rescue -> :ok` upstream, **the span silently vanishes today** — this is a pre-existing latent bug, independent of this phase, that `Bounds.enforce/2` must not inherit.
**Why it happens:** the `:mfa` redaction hook is an adopter-configurable escape hatch (`redactor.ex:11-14`) with no return-type contract enforced.
**How to avoid:** `Bounds.enforce/2` must pattern-match non-map input and return `:drop` + telemetry + log rather than assuming a map and raising (which would then be swallowed anyway, defeating the entire "regression test goes RED" guarantee SEC-01 promises).
**Warning signs:** a test with a custom `:mfa` redactor returning a non-map value, asserting `Bounds.enforce(non_map_value, :span) == :drop` and that telemetry/log fired — if this test doesn't exist, the fail-closed behavior isn't proven.

## Runtime State Inventory

> Not applicable — this phase is additive (new modules, new supervision-tree children, new CSS rules) rather than a rename/refactor/migration. No existing stored data, live service config, OS-registered state, secrets, or build artifacts carry a name or convention this phase changes. **Nothing found in this category — verified by scope review of D-00–D-08: every decision either adds a new key/module/producer or extends an existing one's behavior; none renames or relocates existing persisted data.**

The one adjacent caution, already captured as D-01c: `emit_retriever_span/1` and `emit_prompt_span/1` **keep their exact public signatures** when refactored onto `span/4` — this is a deliberate non-migration (no caller-visible change), not an omission.

## Code Examples

### Application boot wiring (illustrative — mirrors existing `maybe_reconciler/0` shape)

```elixir
# Source: lib/scoria/application.ex (read this session, current shape below)
defmodule Scoria.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Scoria.Repo,
        Scoria.Vault,
        {Oban, Application.fetch_env!(:scoria, Oban)},
        {Phoenix.PubSub, name: Scoria.PubSub},
        ScoriaWeb.Presence,
        {Registry, keys: :unique, name: Scoria.MCP.SessionRegistry},
        {Task.Supervisor, name: Scoria.MCP.TaskSupervisor},
        {Task.Supervisor, name: Scoria.Workflow.TaskSupervisor},
        Scoria.SRE.Relay
      ] ++ maybe_observe_buffer() ++ maybe_reconciler() ++ dev_children()

    opts = [strategy: :one_for_one, name: Scoria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # NEW (D-00a) — mirrors maybe_reconciler/0's existing shape below.
  defp maybe_observe_buffer do
    if Application.get_env(:scoria, Scoria.Observe, [])[:enabled] != false do
      Scoria.Observe.Telemetry.attach()
      [Scoria.Observe.Buffer]
    else
      []
    end
  end

  defp maybe_reconciler do
    if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
  end
end
```
Calling `Telemetry.attach/1` from inside `start/2` (a supervisor callback, run once per boot) rather than as a supervised child is deliberate — `:telemetry.attach_many/4` is not itself a process, it registers a handler in the `:telemetry` application's ETS-backed registry, so it has no supervision lifecycle of its own.

### Guardrail span emission after `create_run` (D-03d)

```elixir
# Illustrative — the actual shape belongs to the implementer, but the ordering
# constraint is load-bearing: G1's check happens BEFORE create_run
# (lib/scoria/runtime.ex:37-40, verified this session), so its span can only
# be emitted AFTER create_run succeeds, using run.id as trace_id.
def start_run(identity, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start(identity, opts),
       :ok <- check_and_emit_release_gate(workflow_attrs) do
    # ... existing dispatch logic unchanged ...
  end
end

defp check_and_emit_release_gate(workflow_attrs) do
  case Scoria.Runtime.ReleaseGate.check(workflow_attrs) do
    :ok ->
      :ok # span emitted AFTER create_run succeeds, per D-03d — not here

    {:error, reason} = error ->
      # Blocked gate: no run exists. Emit with a freshly-minted trace_id,
      # parent_id: nil (D-03d — "a blocked run produces a one-span trace").
      Scoria.Observe.Guardrail.emit(%{
        name: "release_gate",
        decision: "block",
        reason_code: guardrail_reason_code(reason),
        trace_id: Ecto.UUID.generate(),
        parent_id: nil
      })

      error
  end
end
```

### `Bounds` registry class shape (illustrative, D-06b)

```elixir
# Source: pattern derived from D-06b's admission-tier design.
@attribute_registry %{
  "tenant_id" => :id,
  "workflow_run_id" => :id,
  "session_id" => :id,
  "feature" => :enum,
  "route" => :enum,
  "archetype" => :enum,
  "intent" => :enum,
  "duration_ms" => :count,
  "args_fingerprint" => :id,
  "openinference.span.kind" => :enum,
  "scoria.retrieval.embedding_model" => :enum,
  "scoria.retrieval.index_version" => :enum,
  "scoria.retrieval.reranker" => :enum,
  "scoria.prompt.context" => :structured,
  "scoria.guardrail.name" => :enum,
  "scoria.guardrail.decision" => :enum,
  "scoria.guardrail.reason_code" => :enum,
  "scoria.guardrail.subject_ref" => :id,
  "scoria.guardrail.policy_key" => :id,
  "exception.type" => :enum,
  "error.type" => :enum
  # ... no :free_text class exists anywhere in this map — that is the
  # structural guarantee (D-06b/INV-SEC01).
}

@denied_exact_keys ~w(
  gen_ai.input.messages
  gen_ai.output.messages
  gen_ai.system_instructions
  gen_ai.tool.definitions
)

@vendor_prefixes ~w(gen_ai. server. openai. req_llm. error.)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Phase 52 D-R6: RETRIEVER spans are success-path only (no ERROR status) | Phase 53 D-01d: all spans are failure-bearing (`status_code: "ERROR"` + reraise) | This phase (formal revision of D-R6) | An errored RETRIEVER/LLM/tool/guardrail call now surfaces in the trace tree and feeds `online_scoring.ex`'s `"ERROR"`-status negative-signal sampler (verified this session pattern exists: `online_scoring.ex:453` already matches `String.upcase(status_code) == "ERROR"`), closing a gap where the eval flywheel had nothing to sample |
| Trace tree renders as a flat list (`--indent-level` computed, never consumed) | Real parent-child visual nesting via a consumed CSS custom property | This phase (D-00b/D-07a) | SC#1 becomes visually verifiable, not just data-model-verifiable |
| `opts[:span_id]` semantics undefined/inconsistent across Phase 52 emitters | Own-id semantics locked (D-R2, inherited): `span_id` is always the span's own fresh id; `parent_id` is always the caller's id | Phase 52, continued in Phase 53 | consistent across every new producer this phase adds |
| OpenInference/Langfuse/OTel-GenAI: no first-class guardrail *decision* outcome vocabulary | Scoria's `scoria.guardrail.decision` closed enum (ALLOW/BLOCK/ESCALATE, MODIFY reserved), modeled on XACML | This phase (D-05a/f) | Scoria differentiates on a primitive the whole ecosystem lacks — OTel explicitly rejected a GenAI policy vocabulary and redirected to a namespace with no outcome field (github.com/open-telemetry/semantic-conventions#1034, cited in CONTEXT.md) |

**Deprecated/outdated:** the `Scoria.Observe.Context` design explored during discuss-phase (process-local trace-context stack + `$callers` hop) is dead on arrival for this milestone — not because it's a bad pattern in general, but because none of this phase's five producers (G1/G2/G3/G4, two Oban prompt-render sites) run in a process shape where it would resolve correctly. Do not resurrect it without a new host-integration need driving the requirement (D-02b).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:telemetry.span/3`'s catch/reraise semantics generalize as valid design precedent even though Scoria won't call it directly (it emits 3 events, Scoria needs 1) | Standard Stack / Architecture Pattern 2 | Low — this is cited as moduledoc precedent only, not as code to integrate; if the semantics were subtly different it would only weaken a documentation citation, not break functionality |
| A2 | The exact internal shape of `Bounds`'s admission-tier code (registry map literal, `@denied_exact_keys`, `@vendor_prefixes` shown in Code Examples) is illustrative, not the locked implementation | Code Examples | None if the planner treats these as illustrative (as labeled) — risk only if a plan copies the illustrative registry verbatim without auditing it against every bare key the dashboard actually reads per Pitfall 2 |
| A3 | OTel's `AttributeValueLengthLimit` defaulting to unbounded (∞) as cited in CONTEXT.md D-05g is accurate — not independently re-verified against current OTel spec text in this session (CONTEXT.md's own red-team already asserted it; not re-checked here) | User Constraints D-06/D-05g (inherited from CONTEXT.md, not re-derived) | Low — this is contextual justification for why Scoria's own bound is necessary, not a value Scoria's implementation depends on numerically |

**If a plan needs the exact `Bounds` registry key list finalized**, it must be derived by grepping every bare-key read site across `lib/scoria_web/live/` and every `Semconv`-defined key string across `lib/scoria/observe/semconv.ex` at implementation time — Assumption A2's illustrative list above is a starting point, not a source of truth.

## Open Questions

1. **Exact wording/shape of `Scoria.Observe.Guardrail.emit/1`'s public API**
   - What we know: it must build a GUARDRAIL-kind span (via `span/4` or directly), never emit a free-text `reason` key, honor `not_applicable ⇒ no span` (D-05d), and set `status_code: "OK"` even on a BLOCK decision (D-05e).
   - What's unclear: whether it should be a thin wrapper over `with_guardrail/3` (D-01b) or a standalone function with its own opts shape — CONTEXT.md names both `Scoria.Observe.Guardrail` (Integration Points: `lib/scoria/observe/guardrail.ex`) and the generic `with_guardrail/3` kind wrapper without fully reconciling whether they're the same thing.
   - Recommendation: the planner should decide whether `Guardrail.emit/1` is guardrail-specific (owns the decision/reason_code/subject_ref/policy_key attribute shape) calling `with_guardrail/3` internally, or whether `with_guardrail/3` alone suffices with the guardrail-attribute-building logic living in `Semconv`. Either satisfies the locked decisions; pick the shape that keeps `Semconv` as the sole key-string owner (D-05f).

2. **`:structured`-key total-bytes exemption vs. flat 16 KB cap (explicitly Claude's Discretion in CONTEXT.md D-06d)**
   - What we know: Phase 52's `scoria.prompt.context` alone can reach up to ~8 KB with a full 100-chunk pack (per D-ATTR02-4's own guard); the flat 16 KB total must not clip it.
   - What's unclear: whether exempting `:structured`-class keys from the total-byte budget (bounding them individually instead) is meaningfully simpler to implement/test than just doubling the flat cap to 16 KB.
   - Recommendation: CONTEXT.md already picked the number (16 KB flat) as the primary path with the exemption as an alternative — default to the flat 16 KB cap unless implementation reveals a real edge case (e.g., a span carrying both a full prompt-context AND several other structured keys) that the flat cap can't accommodate.

## Environment Availability

> Skipped — this phase's only external dependency is Postgres, which is already required by every other phase of this project and is already running in the dev/test environment per existing `mix.exs`/`config/` wiring (`Scoria.Repo`, `Ecto.Adapters.SQL.Sandbox` already exercised by dozens of existing tests). No new external tool, service, or runtime is introduced.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir 1.19, already the project's only test framework) |
| Config file | `mix.exs` `test_load_filters`/`test_ignore_filters` (no separate ExUnit config file; standard `test/test_helper.exs`) |
| Quick run command | `mix test test/scoria/observe/ test/scoria_web/components/trace_tree_component_test.exs` |
| Full suite command | `mix test --warnings-as-errors` (project convention, confirmed by existing CI/policy-lane references in STATE.md) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVENT-01 | `span/4` marks ERROR + reraises host exception unchanged | unit | `mix test test/scoria/observe/span_test.exs -x` | ❌ Wave 0 |
| EVENT-01 | tool/prompt/retrieval/guardrail spans persist with `parent_id` linkage via real Buffer.flush_now/1 | integration (real Postgres, mirrors `prompt_span_test.exs` pattern) | `mix test test/scoria/observe/guardrail_test.exs test/scoria/observe/adapters/mcp_test.exs -x` | ❌ Wave 0 |
| EVENT-01 | trace tree renders visual nesting (CSS `--indent-level` consumed) | unit (LiveComponent render assertion) | `mix test test/scoria_web/components/trace_tree_component_test.exs -x` | ✅ exists, but currently asserts the flat-DOM bug — must be **rewritten**, not newly created |
| EVENT-01 | `TraceProjection.depth_for/3` terminates on a parent-cycle | unit | `mix test test/scoria/observe/trace_projection_test.exs -x` | ✅ exists — add cycle-termination case to it |
| EVENT-01 | `Scoria.Observe.Buffer` boots under `Scoria.Application`; `Telemetry.attach/1` fires on boot | integration (application-start assertion) | `mix test test/scoria/application_test.exs -x` | ❌ Wave 0 (no existing `application_test.exs` found — new file) |
| SEC-01 | registry canary (exact key list) + exhaustiveness | unit | `mix test test/scoria/observe/bounds_test.exs -x` | ❌ Wave 0 |
| SEC-01 | exact dot-segment matching (not substring): `args_fingerprint` survives, `gen_ai.input.messages` dropped | unit | `mix test test/scoria/observe/bounds_test.exs -x` | ❌ Wave 0 (same file, additional cases) |
| SEC-01 | req_llm exact-key denylist canary (`gen_ai.system_instructions`, `gen_ai.tool.definitions` dropped) | unit, version-pinned | `mix test test/scoria/observe/bounds_test.exs -x` | ❌ Wave 0 (same file) |
| SEC-01 | dashboard hydration survives Bounds ON (pre-seeded bare keys) | integration (real Postgres + `OrchestratorLive` render) | `mix test test/scoria_web/live/orchestrator_live_test.exs -x` | ✅ exists — add a Bounds-on hydration case |
| SEC-01 | non-map `Redactor.redact/1` output fails closed in `Bounds` | unit | `mix test test/scoria/observe/bounds_test.exs -x` | ❌ Wave 0 (same file) |
| SEC-01 | `Guardrail.emit/1` never persists a free-text `reason` key | unit + real-Postgres regression (must go RED if a future dev adds one) | `mix test test/scoria/observe/guardrail_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/scoria/observe/ --warnings-as-errors` (focused observe-lane run)
- **Per wave merge:** `mix test --warnings-as-errors` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/scoria/observe/span_test.exs` — covers `span/4` duration/failure/reraise semantics (EVENT-01)
- [ ] `test/scoria/observe/guardrail_test.exs` — covers guardrail span shape + never-free-text guarantee (EVENT-01, SEC-01)
- [ ] `test/scoria/observe/adapters/mcp_test.exs` — covers the 4-event MCP tool lifecycle → spans (EVENT-01)
- [ ] `test/scoria/observe/bounds_test.exs` — covers the entire SEC-01 registry/denylist/fail-closed surface (SEC-01)
- [ ] `test/scoria/application_test.exs` — covers Buffer supervision + Telemetry.attach on boot (EVENT-01, D-00a)
- [ ] Existing `test/scoria_web/components/trace_tree_component_test.exs` needs a targeted rewrite (currently asserts the bug being fixed) — not a gap in coverage, a gap in correctness of existing coverage
- [ ] Framework install: none — ExUnit + `Ecto.Adapters.SQL.Sandbox` already fully wired; no new test infra needed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Out of scope — this phase touches only the observability/telemetry pipeline, not auth |
| V3 Session Management | no | Not touched by this phase |
| V4 Access Control | no | Tenant-scoping (`tenant_id` fail-closed broadcast, dashboard `attributes->>'tenant_id'` filtering) already exists and is unmodified by this phase except for ensuring every new span writes `tenant_id` correctly (D-00c/D-01e) |
| V5 Input Validation | yes | The entire SEC-01 surface is input validation at a trust boundary: `Bounds.enforce/2`'s closed key registry + size caps are exactly V5's "positive/allowlist validation over free-form input" pattern, applied to telemetry attribute maps instead of HTTP request bodies |
| V6 Cryptography | no | Not touched — no new secret material, no new encryption surface |
| V7 Error Handling and Logging (informal ASVS mapping — logging discipline) | yes | `exception.message` explicitly NOT persisted (D-06g) — only `exception.type`/`error.type` (low-cardinality, non-sensitive). This is a deliberate inversion of naive "log everything for debuggability" practice, justified because exception messages routinely embed query text, parameter values, and raw error `:reason` terms that can carry prompt-influenced or PII content |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive-content exfiltration via an unbounded attribute value (a raw prompt/completion smuggled into a span attribute, then read by anyone with dashboard/DB access) | Information Disclosure | closed key registry (no `:free_text` class is representable) + write-time size bound + drop-not-truncate on unregistered keys (D-06b/D-06e) — this is SEC-01's entire purpose |
| Upstream dependency (`req_llm`) silently widening its own attribute-capture surface on a routine version bump, bypassing Scoria's own review | Information Disclosure (supply-chain drift) | version-pinned canary test over `ReqLLM.OpenTelemetry.Attributes.start/1`/`.terminal/1`'s key set (D-06c(3)) — the same canary doubles as half of Phase 54's DOCS-02 conformance check |
| Browser-facing DoS via an oversized attribute map pushed to an operator's LiveView over PubSub before persistence | Denial of Service | `Bounds.enforce/2` runs BEFORE `ReviewerBroadcast`, not just before `Buffer` (D-06a: "Bounding before the broadcast is load-bearing: a 2 MB attribute map pushed to an operator LiveView is a real browser DoS") |
| Cross-tenant data leakage via a span missing `tenant_id` landing in the wrong (or no) PubSub topic | Information Disclosure / Spoofing | `ReviewerBroadcast.span_stopped/1` already fail-closes (drops, doesn't misroute) on missing/empty `tenant_id` — this phase's obligation is to ensure every new producer actually sets it (D-00c/D-01e), not to change the fail-closed mechanism itself |
| A raising exception's stacktrace/message reaching a persisted, potentially-multi-tenant-readable span attribute | Information Disclosure | `exception.type` only, never `exception.message`/stacktrace, by default; `capture_error_messages: true` opt-in still routes through `Bounds` truncation + `Redactor.scrub_text/1` (D-06g) |
| Metric-dimension cardinality explosion from a high-cardinality guardrail attribute (`reason_code`, `subject_ref`, `policy_key`, decision id) silently folding SRE dashboards into a lying `otel.metric.overflow=true` bucket | Denial of Service (observability-layer) / Tampering (dashboards report false data) | never place these fields on an SRE metric dimension (D-06j) — keep them on the durable span attribute only, where cardinality doesn't cause silent aggregation collapse |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/scoria/lib/scoria/application.ex` — read in full this session; confirms D-00a (no `Buffer` child) verbatim
- `/Users/jon/projects/scoria/lib/scoria/observe/telemetry.ex` — read in full this session; confirms the single-stop-event contract, `@span_buffer_fields`, and the exact `Bounds.enforce/2` insertion point
- `/Users/jon/projects/scoria/lib/scoria/observe/buffer.ex` — read in full this session; confirms `Ecto.Multi` FK-safe upsert shape, `flush_now/1` test hook, `on_flush_error` posture (all Phase 51 work, reused unmodified)
- `/Users/jon/projects/scoria/lib/scoria/observe.ex`, `.../semconv.ex`, `.../span_kind.ex`, `.../redactor.ex`, `.../reviewer_broadcast.ex`, `.../trace_projection.ex` — all read in full this session; every D-0x citation to these files independently re-verified
- `/Users/jon/projects/scoria/lib/scoria_web/components/trace_tree_component.ex`, `.../workflow_tree_component.ex` — read in full this session; confirms D-00b's flat-tree bug and D-07a's exact fix pattern already present in the sibling component
- `/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex` — read in full this session; confirms the 4-event tool lifecycle and the `args_fingerprint`-via-`:erlang.phash2` precedent (line 228, `tool_hash` field — functionally the same pattern D-04b cites)
- `/Users/jon/projects/scoria/lib/scoria/runtime.ex`, `.../runtime/release_gate.ex`, `.../workflows/runtime.ex` (partial) — read this session; confirms G1's pre-run-existence timing and G2's `waiting_for_approval` call site
- `/Users/jon/projects/scoria/lib/scoria/eval/judge_runner.ex` — read this session; confirms free-text `explanation:` at exact cited lines 167/202
- `/Users/jon/projects/scoria/lib/scoria/repo/span.ex`, `.../repo/trace.ex` — read this session; confirms `ai_spans`/`ai_traces` schema shape (bare `parent_id :binary_id`, no FK — consistent with CONTEXT's claims about `ai_spans.parent_id` being FK-free)
- `/Users/jon/projects/scoria/mix.exs` — read this session; confirms no `jido` dependency, confirms `req_llm ~> 1.13`/`oban ~> 2.19` pins, confirms no new package is needed for this phase
- `.planning/phases/53-structured-child-spans-write-time-bound/53-CONTEXT.md` and `53-DISCUSSION-LOG.md` — the authoritative locked-decision source for this phase (4 parallel research subagents + red-team, per this project's established discuss-phase method)
- `.planning/phases/51-foundation-fix-key-convention-span-kind-taxonomy/51-CONTEXT.md`, `.planning/phases/52-retriever-span-host-declared-attributes/52-CONTEXT.md` — the two prior phases this phase's pipeline directly extends

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/telemetry/telemetry.html — `:telemetry.span/3` catch/reraise/emit semantics [CITED], used as design precedent for `span/4`, not integrated directly
- https://hexdocs.pm/elixir/try-catch-and-rescue.html — `__STACKTRACE__`/`reraise`/`:erlang.raise/3` semantics [CITED]

### Tertiary (LOW confidence)
- None — all external claims in this document were either verified against real code this session or cited to official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; every reused module/pattern independently re-read this session
- Architecture: HIGH — every integration point (application.ex wiring, telemetry.ex insertion point, trace_tree_component.ex CSS gap, trace_projection.ex cycle risk, mcp/executor.ex event lifecycle, runtime.ex/workflows/runtime.ex gate call sites) independently re-verified by direct file read, not just trusted from CONTEXT.md
- Pitfalls: HIGH — six pitfalls documented, four derived directly from CONTEXT.md's red-team findings (already proven against real code), two newly identified this session (double-emit risk in `span/4`, Buffer supervision-tree test-isolation risk) by reasoning about the concrete wiring change

**Research date:** 2026-07-12
**Valid until:** 30 days (stable, internal-codebase-driven research; the only fast-moving external dependency risk — `req_llm` attribute-capture surface drift — is explicitly mitigated by a version-pinned canary test rather than a time-boxed research validity window)
