# Phase 53: Structured Child Spans + Write-Time Bound — Discussion Log

**Date:** 2026-07-12
**Method:** 4 parallel cross-aware research subagents + 1 adversarial red-team pass (the user's established preference — research + red-team synthesis, not an interactive Q&A loop).

> Human reference only. Downstream agents read `53-CONTEXT.md`, not this file.

---

## Gray areas presented

Four, all selected:

1. **Child-span seam + parent linkage** — generic wrapper vs. per-kind emitters; explicit `parent_id` vs. implicit process context.
2. **GUARDRAIL call site (what IS a guardrail)** — nothing in `lib/` emits one; `prompt_rendered` has no render site either.
3. **`emit_event/1` API + Buffer event pipeline** — signature, allow-list location, the `ai_span_events` FK hazard.
4. **SEC-01 write-time PII/cardinality bound** — where it lives, what the limits are, and the structural "no raw text" guarantee.

**User's directive (verbatim intent):** research each with subagents; pros/cons/tradeoffs; what's idiomatic for Elixir/Plug/Ecto/Phoenix and this ecosystem; lessons from other libs (even other languages) — what they did right, what they got wrong, footguns; great DX; one-shot a coherent set of recommendations across every relevant lens (SWE/architecture/DevOps/SRE, UI/UX/creative direction/user psychology, JTBD who/what/where/when/why, all design pillars, consumer-not-provider API design, hide the backend guts); mine `prompts/` (brandbook wins over older prompt-era brand refs).

---

## What the research produced, and what the red team did to it

### Killed outright (2)

| Lock | Killed because |
|---|---|
| **Stamp the guardrail decision id onto `ai_approvals.policy_outcome`** (Area B) | The column is **not dead.** It is a live, low-cardinality enum owned by the connector-auth lane — written at `connectors/auth.ex:344`, read and projected to the operator surface at `remote_approval_projection.ex:88`. Writing a span UUID into it would silently poison `RemoteApprovalProjection`. **Verified independently by the orchestrator.** |
| **`Scoria.Observe.Context`** — a process-local trace-context stack + `$callers` hop + `context_resolver` MFA (Area A's *central* mechanism, ~200 LOC) | **Not one of this phase's producers can use it.** G1 runs before any span exists; G2–G4 run in a workflow runtime that never opens a span; both prompt sites are **Oban workers**, whose `$callers` points at the Oban Producer GenServer. The one place `$callers` *would* work (`MCP.Executor`'s Task) emits its telemetry in the parent process anyway. Cut with zero success-criterion risk. |

### Corrected (3 registry bugs that would have shipped)

1. **The dashboard would have gone dark.** `orchestrator_live.ex:237` hydrates traces by querying the **bare** `tenant_id` key inside `attributes`. Area D's closed registry drops unregistered bare keys → every trace disappears. Fix: pre-seed the registry with the bare keys the dashboard queries.
2. **`args_fingerprint` would have been dropped.** Under substring matching, the denied segment `args` kills `args_fingerprint` — the exact field the MCP adapter relies on to avoid persisting raw tool args. Fix: exact **dot-segment** equality, never substring.
3. **The req_llm leak the denylist exists to stop would have sailed through.** `gen_ai.system_instructions` (segment is `system_instructions`, not `instructions`) and `gen_ai.tool.definitions` both **pass** segment denial — and `Semconv.merge_req_llm_attributes/2` is an unfiltered `Map.merge`. A req_llm minor bump would silently persist raw prompts with zero Scoria code change. Fix: an exact-key denylist + a version-pinned canary.

### Adjudicated contradictions (the four areas disagreed)

| Contradiction | Verdict |
|---|---|
| FK on `ai_span_events.span_id` — Area C: drop it; Area B: keep + pre-filter orphans | **Area C.** `insert_all` raises on FK violation (the Buffer's own comment says so), the raise rolls back the whole `Ecto.Multi` including the spans, and `on_conflict` covers only unique conflicts. Area B's pre-filter drops events **forever** (`buffer.ex:88` resets state unconditionally) — and drops them precisely for long-running spans. *(Area C's "~40% of batches" figure was fabricated and was struck.)* |
| `Scoria.Observe.Context` — Area A: build it; Area B: none of my producers can use it | **Area B.** Cut. |
| `trace_id` — Area B: none exists, use `run.id` | **Diagnosis right, proposal incomplete.** Adapters mint random trace ids, and G1 runs *before* the run exists. Closed in CONTEXT (D-03) rather than handed to the planner. |
| `exception.message` — Area A: include (bounded); Area D: forbid | **Area D.** Exception messages embed queries, params, and raw `:reason` terms. `exception.type` only. |
| Registry / denied segments | **Area D's design is right; its list and limits had the three bugs above.** |

---

## Decisions the user made

| # | Question | Answer |
|---|---|---|
| 1 | Scope: the full synthesis is 9–10 plans (51 shipped 5, 52 shipped 6) | **Split 53 / 53b** along the requirement seam. Phase 53 = EVENT-01 + SEC-01 (spans + bound, 6 plans). Phase 53b = EVENT-02 + EVENT-03 (events, 4 plans). No requirement split across phases. ROADMAP.md + REQUIREMENTS.md updated. |
| 2 | `Buffer` is not supervised and `Telemetry.attach/1` is never called from `lib/` — Phase 51's and 52's spans have never persisted in a real host app | **Fix it in Phase 53, Plan 01.** Buffer into the supervision tree, attach on boot, `enabled: false` opt-out, CHANGELOG the adopter-visible change. |
| 3 | `ai_span_events.span_id` is a hard FK; an async flush routinely lands an event before its span; `insert_all` raises and takes up to 1000 good spans with it | **Drop the FK via migration** (Phase 53b). Verified safe for a shipped Hex lib. Also dissolves SEED-011's async-feedback-arrival problem for free. |

---

## Findings the orchestrator verified independently

- `ai_span_events.span_id` **is** `references(:ai_spans, on_delete: :delete_all), null: false`; `ai_spans.parent_id` is a bare `:binary_id`. Confirmed.
- `trace_tree_component.ex:36` sets `--indent-level`; **no CSS consumes it.** The trace tree renders flat. Confirmed.
- `ReviewerBroadcast.span_stopped/1` fail-closes on a missing top-level `tenant_id`; neither Phase-52 emitter sets one. Confirmed.
- **`Scoria.Observe.Buffer` is not in `Scoria.Application`'s children; `Telemetry.attach/1` has zero `lib/` callers.** Confirmed — the pipeline is inert in production.
- `ai_approvals.policy_outcome` is live. Confirmed.
- `Compaction.SummarizeWorker.new_job/2` has **zero callers** — only the eval judge site is a real production prompt-render path. Confirmed.
- `jido` is not a dependency. Confirmed — `Adapters.MCP` is therefore the only production `tool` span producer, and cannot be cut.

---

## Deferred (captured, not acted on)

`PromptRegistry.render/3` (real DX value, no success criterion → backlog) · the approval↔guardrail join (needs a **new** column) · operator UI for events · `PromptPolicy`'s unenforced booleans (a latent lie in the public API) · `with_agent/3` · `Scoria.Observe.Context` (revisit when a host asks for implicit nesting).
