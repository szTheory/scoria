# Roadmap: Scoria

## Milestones

- ✅ **v2.15 Connector Adoption Lane** — named connector verification suite and docs/CI parity (shipped 2026-05-30)
- ✅ **v2.17 Vesicle** — Phases 18–22, canonical brand system (shipped 2026-06-11)
- ✅ **v3.0 Control Room** — Phases 11–17, dashboard design-system / IA / motion / proof (shipped 2026-06-14)
- ✅ **v3.1 CI/CD Velocity** — Phases 23–28, PR CI 77m → 7m38s (shipped 2026-06-17)
- ✅ **v3.2 Drydock** — Phases 29–35, Docker dev-DX hardening + `0.1.2` maintenance release (shipped 2026-06-19)
- ✅ **v3.3 Design System Stress Test** — Phases 36–41.1, `/scoria` UI coherence foundation→proof (shipped 2026-07-04)
- ✅ **v3.4 Pre-1.0 Trust & Security Hardening** — Phases 42–45, SEED-006 P0 trust/security gate (shipped 2026-07-09)
- ✅ **v3.5 Documentation & Release Readiness** — Phases 46–50, SEED-005 stable docs + honest `0.1.3` release (shipped 2026-07-11)
- 🚧 **v3.6 Trace Foundation** — Phases 51–54, SEED-007 OTel-GenAI/OpenInference trace interop (in progress)

## Phases

**Phase Numbering:** Continues from the previous milestone (v3.5 ended at Phase 50). Phase 54.1 inserted (v3.6 milestone-audit integration gap).

- [ ] **Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy** - Trace-upsert FK fix, shared span_kind whitelist, version-pinned semconv module, `gen_ai.*` model-config capture via ReqLLM's attribute builder, correct span_kind + `openinference.span.kind`, legacy-key compat decision.
- [x] **Phase 52: RETRIEVER Span + Host-Declared Attributes** - `RETRIEVER` span dual-written alongside `ai_retrieval_runs`, retrieval config fields with a span↔table consistency guard, reserved host-declared attribute keys, context-pack composition on the `PROMPT` span. (completed 2026-07-12)
- [x] **Phase 53: Structured Child Spans + Write-Time Bound** - `tool`/`prompt`/`retrieval`/`guardrail` as real duration/failure-bearing child spans with parent linkage, the observe pipeline actually wired into the supervision tree, and the SEC-01 write-time PII/cardinality bound behind a closed key registry. (completed 2026-07-18)
- [x] **Phase 53b: `ai_span_events` + `emit_event/1`** - The dead `ai_span_events` table resurrected via a public allow-listed `emit_event/1` through the shared redaction path, with an ordered Buffer flush, and `prompt_rendered`/`guardrail_triggered` emitted from real call sites. (completed 2026-07-18)
- [ ] **Phase 54: Docs Accuracy + Conformance Check** - Honest "OpenInference-compatible" claim with contract-list updates in the same change, plus a falsifiable conformance check.
- [x] **Phase 54.1: Wire ReqLLM/Jido adapters at boot + reconcile CHANGELOG** (INSERTED) - Boot-attach the ReqLLM/Jido telemetry adapters so LLM/Jido-tool spans persist in a real host app without host hand-wiring, and reconcile the CHANGELOG "zero host wiring" claim with reality. Closes the v3.6 milestone-audit integration gap (SPAN-01/SPAN-02/COMPAT-01/EVENT-01, LLM/Jido-tool leg). (completed 2026-07-18)

## Phase Details

### Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy

**Goal**: Every span Scoria emits actually persists to Postgres, carries the current OTel-GenAI model-config attributes, and reports a correct, canonically-sourced `span_kind` — closing the pre-existing silent FK gap that has been swallowing every span insert.
**Depends on**: Nothing (first phase; gates the milestone — nothing downstream persists until this lands)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, SPAN-01, SPAN-02, COMPAT-01
**Success Criteria** (what must be TRUE):

  1. A span emitted through the real adapter path (ReqLLM or Jido) persists as a row in `ai_spans` with a matching `ai_traces` row present (no FK violation, no silently-swallowed `rescue`) — verifiable against a real Postgres, not a test that hand-inserts the trace first.
  2. A persisted LLM span carries `gen_ai.request.model`, `.temperature`, `.top_p`, `.max_tokens`, `.seed`, and `gen_ai.usage.*` together (all four model-config params present on the same span, sourced via `ReqLLM.OpenTelemetry.Attributes`) — never a partial subset.
  3. Every span's `span_kind` column is drawn from one shared whitelist module consumed by both `WorkflowTreeComponent` and `TraceTreeComponent` (no independently-hardcoded lists), and carries a mirrored `openinference.span.kind` attribute, with `mcp` actions translating to `"TOOL"`.
  4. Every `gen_ai.*`/`openinference.*` key string used anywhere in the codebase traces back to one version-pinned mapping module (e.g. `Scoria.Observe.Semconv`), not inline string literals at multiple call sites.
  5. Adopters querying already-persisted legacy keys (`llm.model_name`, `llm.token_count`, `req.url`) against their own Postgres get an explicit, CHANGELOG-documented behavior (dual-emit or clean-replacement) rather than a silent break.

**Plans**: 5 plans
**Wave 1**

- [x] 51-01-PLAN.md — SpanKind taxonomy module + UI-component consumers + CSS status overlay + drift-guard test (FOUND-02, SPAN-02) [Wave 1]
- [x] 51-02-PLAN.md — Version-pinned Semconv delegating module + single-origin test (FOUND-03) [Wave 1]
- [x] 51-03-PLAN.md — Buffer FK trace-upsert fix + loud flush-error surfacing + Telemetry wrapper (FOUND-01) [Wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 51-04-PLAN.md — ReqLLM adapter gen_ai.* + span_kind + legacy-key clean replacement + CHANGELOG 0.1.4 (SPAN-01, SPAN-02, COMPAT-01) [Wave 2]
- [x] 51-05-PLAN.md — Jido adapter span_kind host-declared default + openinference mirror (SPAN-02) [Wave 2]

### Phase 52: RETRIEVER Span + Host-Declared Attributes

**Goal**: Retrieval calls are visible in the trace tree as a linked `RETRIEVER` span without displacing `ai_retrieval_runs` as the system-of-record, and hosts can declare feature/route/archetype/intent plus context-pack composition without Scoria ever inferring them.
**Depends on**: Phase 51 (reuses the fixed span-emission/trace-upsert path)
**Requirements**: RETR-01, RETR-02, ATTR-01, ATTR-02
**Success Criteria** (what must be TRUE):

  1. Calling `Knowledge.retrieve/2` produces both a persisted `ai_retrieval_runs` row (unchanged system-of-record) and a linked `RETRIEVER` span in `ai_spans` sharing the same `trace_id`/`span_id`, reusing the already-computed latency — a join between the two never comes up empty for a successful retrieval call.
  2. `embedding_model`, `index_version`, and `reranker` appear as convention keys on both the `RETRIEVER` span's attributes and `ai_retrieval_runs.metadata`, sourced from one shared value origin, with a consistency guard that would catch the two diverging.
  3. A host-supplied `feature`/`route`/`archetype`/`intent` value passed into a run flows through to persisted span attributes unmodified — Scoria never derives or overwrites these values from its own logic.
  4. A `PROMPT` span's attributes carry which chunk IDs, which memory IDs, and the per-source token split that composed the assembled prompt, alongside `gen_ai.usage.input_tokens` — IDs and counts only, never the raw chunk/memory text.

**Plans**: 6 plans
**Wave 1**

- [x] 52-01-PLAN.md — Semconv projection seam (retrieval-config / host-declared / prompt-context) + drift-guard unit tests
- [x] 52-02-PLAN.md — Embedder optional `model_name/0` callback + Deterministic impl

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 52-03-PLAN.md — `Scoria.Observe` facade: `emit_retriever_span/1` + `emit_prompt_span/1`
- [x] 52-05-PLAN.md — Adapters host-declared pipe (`merge_host_declared/2`) + pass-through tests

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 52-04-PLAN.md — Wire `retrieve/2` + RETR-01 join / RETR-02 equality / ATTR-01 pass-through / D-R2b migration
- [x] 52-06-PLAN.md — ATTR-02 SC#4 acceptance: real `emit_prompt_span/1` + `flush_now` persisted-span assertions

### Phase 53: Structured Child Spans + Write-Time Bound

**Goal**: Tool, prompt, retrieval, and guardrail steps show up as real duration- and failure-bearing child spans in the trace tree — on a pipeline that is actually running in a host app — and no attribute payload can carry raw prompt/completion text.
**Depends on**: Phase 51 (span pipeline + FK-safe trace upsert), Phase 52 (Semconv seam, RETRIEVER/prompt emitters)
**Requirements**: EVENT-01, SEC-01
**Success Criteria** (what must be TRUE):

  1. A `tool`, `prompt`, `retrieval`, or `guardrail` step appears in the trace tree as its own child span with a `parent_id` linking it to the originating span — not folded into the parent's attributes and not modeled as an event. The trace tree renders the nesting (today it does not: `--indent-level` is set and consumed by nothing).
  2. `Scoria.Observe.Buffer` runs under `Scoria.Application` and `Telemetry.attach/1` is called on boot — so a span emitted by a real host app persists to Postgres without the host hand-wiring the pipeline. (Pre-existing gap: today the pipeline is inert outside tests.)
  3. A step that raises produces a persisted child span with `status_code: "ERROR"` and a real duration, and the host's exception is reraised unchanged.
  4. No attribute payload carries raw prompt/completion text; payload sizes are bounded at write time; and a regression test goes RED if a future developer introduces an unbounded free-text attribute (enforced by a closed `Semconv` key registry, not a deny-pattern).

**Plans**: 8 plans (4 waves)
**Wave 1**

- [x] 53-01-PLAN.md — Wire `Observe.Buffer` + `Telemetry.attach/1` into `Scoria.Application` (gates everything) [wave 1]
- [x] 53-02-PLAN.md — `Semconv` closed key registry + guardrail enums + type-only error attributes [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 53-03-PLAN.md — `Observe.span/4` seam: duration + ERROR + reraise; refactor Phase-52 emitters onto it [wave 2]
- [x] 53-04-PLAN.md — `Observe.Bounds` write-time choke point in `Telemetry.handle_event/4` (SEC-01) [wave 2]
- [x] 53-05-PLAN.md — `Observe.Adapters.MCP` — the production `tool` span producer (fingerprint, never args) [wave 2]
- [x] 53-06-PLAN.md — Trace-tree UI: consume `--indent-level`, cycle guard, `tree_order/1`, ERROR overlay, guardrail badge [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 53-07-PLAN.md — `Observe.Guardrail` + G1 release gate (no free-text reason, structurally) [wave 3]

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 53-08-PLAN.md — Step parent span + `trace_id` threading + G2/G3/G4 + `JudgeRunner` PROMPT span [wave 4]

### Phase 53b: `ai_span_events` + `emit_event/1`

**Goal**: The three reserved point-events can be emitted through a redaction-safe, allow-listed event path that cannot lose a batch of good spans, and two of them fire from real call sites during normal operation.
**Depends on**: Phase 53 (the guardrail/prompt spans these events attach to must exist first; `Bounds` must exist to bound event payloads)
**Requirements**: EVENT-02, EVENT-03
**Success Criteria** (what must be TRUE):

  1. Calling the public `emit_event/1` for an allow-listed name (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) produces a persisted `ai_span_events` row whose attributes passed through the identical `Redactor.redact/1` call site spans use — a deny-listed key inside an event's attributes comes back `[REDACTED]`, proven by an integration test.
  2. Calling `emit_event/1` with a name outside the 3-item allow-list is rejected/logged, not silently persisted — including via a raw `:telemetry.execute` on the public bus. The vocabulary cannot silently grow.
  3. `prompt_rendered` and `guardrail_triggered` are actually emitted from real call sites during normal operation (not just reachable via a direct API call in a test) — `user_feedback_received` stays reserved-only, not emitted, in this milestone.
  4. An event whose span has not flushed (or was dropped) can never take down a batch of good spans — proven by a test that flushes 50 valid spans alongside one orphan event and loses nothing.

**Plans**: 5 plans
**Wave 1**

- [x] 53B-01-PLAN.md — Core-lane FK-drop migration + closed Semconv event vocabulary + scoria.prompt.template_ref registry key (Wave 1)
- [x] 53B-02-PLAN.md — Buffer event list + two-phase ordered flush + cast_event/2 (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 53B-03-PLAN.md — emit_event/1 + :event telemetry handler (redact collapse, allow-list re-check, fail-closed time/span_id seam, Bounds:event) (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 53B-04-PLAN.md — Real call-site emission: guardrail_triggered + prompt_rendered (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 53B-05-PLAN.md — SC canaries: SC#1 redact / SC#2 vocabulary / SC#4 orphan / D-05 fail-closed / SEC-01 Bounds:event (Wave 4)

### Phase 54: Docs Accuracy + Conformance Check

**Goal**: The adopter-facing "OpenInference-compatible" claim is both allowed by the codebase's own doc-contract guards and backed by an executable check that would fail if it stopped being true.
**Depends on**: Phase 51 (the underlying convention must actually exist before the claim is made)
**Requirements**: DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):

  1. README (and any other adopter-facing surface) states the version-pinned "OpenInference-compatible" claim, and `adopter_doc_contract.ex`/`ai_doc_contract.ex`'s banned-phrase lists were updated in the same change — `mix test` passes on both contract files with the new claim string present and the old "not a current claim" string intentionally replaced.
  2. A Mix task or ExUnit test exists that asserts every span emitted by the two adapters uses only allow-listed convention key names and a `span_kind` value drawn from the shared whitelist — running it against a real emitted span set fails if an unlisted key or kind appears.

**Plans**: 2 plans

Plans:

- [ ] 54-01-PLAN.md — Flip the claim to version-pinned "OpenInference-compatible", add the new trace guide, and update the doc-contract allowed/banned lists additively (Wave 1)
- [ ] 54-02-PLAN.md — Add the falsifiable ExUnit conformance test driving all three adapters live + negative self-test + adoption-lane registration (Wave 1)

### Phase 54.1: Wire ReqLLM/Jido adapters at boot + reconcile CHANGELOG (INSERTED)

**Goal**: A real `req_llm` chat call or Jido action in a host app produces a persisted LLM/TOOL span with zero host hand-wiring — closing the v3.6 milestone-audit integration gap where `Scoria.Observe.Adapters.ReqLLM.attach/0` and `Adapters.Jido.attach/0` have no `lib/` caller (only tests attach them), so those spans fire into a void in production while the CHANGELOG claims otherwise.
**Depends on**: Phase 51 (defines the ReqLLM/Jido adapters + `gen_ai.*`/`span_kind` wiring), Phase 53 (added the `observe_children/0` boot-attach seam for `Buffer`/`Telemetry`/`MCP` that this extends)
**Requirements**: SPAN-01, SPAN-02, COMPAT-01, EVENT-01 (integration-completion — the adapters were verified correct per-phase but are unreachable at runtime)
**Success Criteria** (what must be TRUE):

  1. `Scoria.Application` boot-attaches the ReqLLM and Jido adapters (mirroring the existing `safe_attach_observe_mcp/0` pattern, config-gated by the same `enabled: false` switch, `{:error, :already_exists}`-tolerant), OR — if host-opt-in is the deliberate design (e.g. `req_llm`/`jido` are optional peer deps) — the adapters stay host-attached and a `guides/` doc instructs hosts to call `attach/0` at boot.
  2. A test proves an upstream `[:req_llm, :request, :stop]` / `[:jido, :action, :stop]` event, with no manual `attach/0` in the test body, results in a persisted span (the boot path did the wiring) — OR, under the opt-in design, the boot path deliberately does not attach and the test asserts that plus the documented host instruction.
  3. The CHANGELOG's "zero host wiring" claim (lines ~183–191) is reconciled to match whichever design is chosen — the code, the CHANGELOG, and `runtime_span_test.exs`'s "NOT boot-attached" moduledoc no longer disagree.

**Plans**: 2 plans

Plans:

- [x] 54.1-01-PLAN.md — Boot-attach ReqLLM/Jido adapters through observe_children/0 + SC#2 boot-path test + runtime_span_test moduledoc reconciliation (Wave 1)
- [x] 54.1-02-PLAN.md — CHANGELOG persist-vs-join amendment + new LLM/tool adapters capability guide + troubleshooting entry + docs-source inventory registration (Wave 1)

## Progress

**Execution Order:**
Phases execute in numeric order: 51 → 52 → 53 → 53b → 54 → 54.1

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 46. Terminology and public vocabulary migration | v3.5 | 8/8 | Complete | 2026-07-09 |
| 47. README first-screen positioning and scope doctrine | v3.5 | 3/3 | Complete | 2026-07-10 |
| 48. ExDoc and guide ladder restructure | v3.5 | 15/15 | Complete | 2026-07-10 |
| 49. AI-accessible docs and docs verification gate | v3.5 | 2/2 | Complete | 2026-07-11 |
| 50. Release readiness and `0.1.3` cut | v3.5 | 11/11 | Complete | 2026-07-11 |
| 51. Foundation Fix + Key Convention + Span-Kind Taxonomy | v3.6 | 5/5 | Complete    | 2026-07-12 |
| 52. RETRIEVER Span + Host-Declared Attributes | v3.6 | 6/6 | Complete    | 2026-07-12 |
| 53. Structured Child Spans + Write-Time Bound | v3.6 | 8/8 | Complete    | 2026-07-18 |
| 53b. `ai_span_events` + `emit_event/1` | v3.6 | 5/5 | Complete    | 2026-07-18 |
| 54. Docs Accuracy + Conformance Check | v3.6 | 0/TBD | Not started | - |
| 54.1. Wire ReqLLM/Jido adapters at boot + reconcile CHANGELOG (INSERTED) | v3.6 | 2/2 | Complete    | 2026-07-18 |

## Archived Milestones

<details>
<summary>✅ v3.5 Documentation & Release Readiness (Phases 46–50) — SHIPPED 2026-07-11</summary>

**Goal:** Make Scoria adoption-ready again after the v3.4 trust/security fixes by replacing jargon-first adopter docs with stable positioning, repairing release-blocking CI/browser drift, and cutting the honest `0.1.3` Hex release.

- [x] Phase 46: Terminology and public vocabulary migration (8/8 plans) — completed 2026-07-09
- [x] Phase 47: README first-screen positioning and scope doctrine (3/3 plans) — completed 2026-07-10
- [x] Phase 48: ExDoc and guide ladder restructure (15/15 plans) — completed 2026-07-10
- [x] Phase 49: AI-accessible docs and docs verification gate (2/2 plans) — completed 2026-07-11
- [x] Phase 50: Release readiness and `0.1.3` cut (11/11 plans) — completed 2026-07-11

Shipped Hex `0.1.3` (tag `v0.1.3`, PR #12 via release-please merge `b904c22a`, post-publish registry attest green). Milestone audit `passed` (18/18 requirements, 5/5 phases verified, 5/5 integration seams) after inline closure of two audit-time gaps: local `main` reconciled onto `origin/main` (it lacked the release commit), and a Phase 46 verification-doc gap closed via gsd-verifier. Full phase detail archived in `.planning/milestones/v3.5-ROADMAP.md`; requirements in `.planning/milestones/v3.5-REQUIREMENTS.md`; audit in `.planning/milestones/v3.5-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v3.4 Pre-1.0 Trust & Security Hardening (Phases 42–45) — SHIPPED 2026-07-09</summary>

**Goal:** Fix the three P0 correctness/security bugs live in shipped `0.1.2` — eval fail-open, knowledge cross-tenant retrieval leak, and dashboard auth bypass — plus the scoped correctness sweep. Fix + prove only; no Hex publish.

- [x] Phase 42: Eval fails closed (7/7 plans) — completed 2026-07-05
- [x] Phase 43: Knowledge tenant isolation (5/5 plans) — completed 2026-07-07
- [x] Phase 44: Dashboard auth seam (7/7 plans) — completed 2026-07-07
- [x] Phase 45: Correctness sweep + fail-closed proof & closeout (5/5 plans) — completed 2026-07-07

Full phase detail archived in `.planning/milestones/v3.4-ROADMAP.md`; requirements in `.planning/milestones/v3.4-REQUIREMENTS.md`; audit in `.planning/milestones/v3.4-MILESTONE-AUDIT.md`; phase artifacts in `.planning/milestones/v3.4-phases/`.

</details>

<details>
<summary>✅ v3.3 Design System Stress Test (Phases 36–41.1) — SHIPPED 2026-07-04</summary>

**Goal:** Make the embedded `/scoria` admin/operator UI internally coherent at the foundation, component, component-group, page-flow, copy, accessibility, motion, fixture, and proof levels without regressing the recent cleanup work.

- [x] Phase 36: Baseline And Inventory (2/2 plans) — completed 2026-06-20
- [x] Phase 37: Dev Component Lab And Stress Fixtures (6/6 plans) — completed 2026-07-02
- [x] Phase 38: Foundations And Primitive Controls (3/3 plans) — completed 2026-07-02
- [x] Phase 39: Component Groups And Operator Flows (8/8 plans) — completed 2026-07-03
- [x] Phase 40: Accessibility, Motion, And Responsive Proof (5/5 plans) — completed 2026-07-03
- [x] Phase 41: Proof, Docs, And Regression Guardrails (5/5 plans) — completed 2026-07-04
- [x] Phase 41.1: Wire orphaned ScoriaWeb.Copy/DatasetCopy into dataset page — COPY-01 SSOT (INSERTED) (1/1 plan) — completed 2026-07-04

Full phase detail archived in `.planning/milestones/v3.3-ROADMAP.md`; requirements in `.planning/milestones/v3.3-REQUIREMENTS.md`; audit in `.planning/milestones/v3.3-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ Earlier milestones</summary>

Archived under `.planning/milestones/`:

- **v3.2 Drydock** — Phases 29–35 (`v3.2-ROADMAP.md`)
- **v3.1 CI/CD Velocity** — Phases 23–28 (`v3.1-ROADMAP.md`)
- **v3.0 Control Room** — Phases 11–17 (`v3.0-ROADMAP.md`)
- **v2.17 Vesicle** — Phases 18–22 (`v2.17-ROADMAP.md`)
- **v2.15 Connector Adoption Lane** — named connector verification suite and docs/CI parity (`MILESTONES.md`)

See `.planning/MILESTONES.md` for full closeout history.

</details>

## Backlog

> Forward roadmap of planned milestones. Each item's full rationale, adjudicated verdicts, peer
> precedent, and file breadcrumbs live in its backing seed under `.planning/seeds/` (see
> `.planning/seeds/README.md` for the index + dependency graph). This section is the durable
> recall surface: `/gsd-complete-milestone` preserves `## Backlog` verbatim across milestone
> rewrites, so it survives context clears. Promote items one at a time via `/gsd-review-backlog`
> or scope them directly in `/gsd-new-milestone`.

### Planned milestone order

**Execution order (do top-to-bottom): SEED-007 → SEED-010 → SEED-008 → SEED-012 → {SEED-009, SEED-011} → SEED-013.**
The `999.x` tags are stable seed IDs (cross-referenced from PROJECT.md/STATE.md), **not** the execution
rank — read the numbered list below for order.

Provenance: the base order was set by a 2026-07-03 AI-eval posture audit (6-agent adjudication vs
LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel). Cadence decision: **P0 fixes →
docs/positioning → feature milestones**, each feature milestone interleaving its own feature docs + a
release as it lands. SEED-006 (P0 trust/security) shipped in v3.4 and SEED-005 (docs/positioning +
honest `0.1.3` release) shipped in v3.5, so the next milestone is a feature seed → SEED-007.

> **Sequencing refinement (2026-07-11) — recorded so it is not re-derived after a context clear.**
> A dependency+dividend re-analysis (all seeds' hard prereqs and what each *emits* for the ones after
> it) kept 007 → 010 → 008 first, then made two deliberate changes vs the original 2026-07-03 list:
> 1. **Pulled SEED-012 forward to right after SEED-008** (was stranded last-but-one). 012 is a pure
>    dividend of 007's attribute convention + 008's confusion-matrix/archetype slot — cheapest to build
>    while that machinery is still warm, not months later behind 009/011.
> 2. **Split SEED-013** into (a) an **early cross-cutting shell** — nav re-group, unified Queue,
>    persistent scope contract, progressive-disclosure/receipts law — which is buildable on **today's**
>    backend (`depends_on: []`), and (b) **late feature-specific screens** (Run Workbench evidence
>    canvas, story-spine, Govern/Privacy/Quality/Cockpit content) that ride their backends. Landing the
>    shell early means 010/008/009/011 build their screens *into* the north-star frame and plug their
>    human-work items into one Queue, instead of building into the old IA and re-slotting later (rework).
>    Whether to actually land the 013 shell early vs keep 013 as one closing capstone is a maintainer
>    call at that point — both are recorded; the dividend case favors early.
>
> **Dividend map (why this order):** 007 emits `span_kind`/`gen_ai.*`/model-config/RETRIEVER-span +
> host-declared `feature`/`route`/`archetype`/`intent` attrs → consumed by 008 (scorers read spans),
> 010 (taint substrate), 012 (archetype attr), and every 013 screen. 008 emits the confusion-matrix +
> typed archetype slot → 012 reuses both wholesale. 009 and 011 depend only on shipped 006 (independent
> tracks; order between them is priority, not dependency). 013 depends on nothing structurally but
> composes every feature seed's UI slice.

1. **SEED-007 (999.3) — Trace Foundation (OTel-GenAI / OpenInference interop)**  (foundational — everything downstream reads spans)
   Semconv as a naming convention over the existing attrs map (not a schema rewrite) + span_kind +
   model config + structured spans/events + RETRIEVER span + host-declared attribute convention +
   README claim fix. **In progress as v3.6 Trace Foundation (Phases 51-54).** → see `SEED-007`.

2. **SEED-010 (999.4) — Lethal-Trifecta Governance**  ⭐ **[FLAGSHIP DIFFERENTIATOR]**
   Content trust tiers + spotlighting + tool-declared trifecta classification + confluence
   escalation policy (Meta Rule-of-Two) + moderation/output hooks + SECURITY-BOUNDARY.md. No peer
   ships this as a runtime seam; Scoria is 2/3 built. Needs 007's taint substrate — build while trace
   work is fresh; highest external/positioning payoff. → see `SEED-010`.

3. **SEED-008 (999.5) — Trustworthy Eval Depth**  (after 007 — scorers are meaningless over attribution-less traces)
   Real scorer library + regression-comparison engine + judge calibration (the unique join Scoria
   already captures but discards) + versioned rubric + typed risk/intent taxonomy slots. Emits the
   confusion-matrix + archetype slot that 012 reuses. → see `SEED-008`.

4. **SEED-012 (999.8) — Architecture-Archetype Awareness (Rule-8 lens)**  (small capstone; PULLED FORWARD — do immediately after 008)
   Host-declared `archetype`/`route` on runs (Scoria records/segments, never infers) + a
   segment-by-attribute dashboard facet (per-archetype/per-route cost/latency/scores) + per-archetype
   Rule-8 eval presets + Router observability (routing accuracy via the SEED-008 confusion-matrix reuse).
   A thin composition over the SEED-007 attribute convention + SEED-008 eval machinery — not new infra;
   cheapest while that machinery is warm. From the 2026-07-03 AI-architecture-patterns ingest (memo:
   `.planning/research/ai-architectural-patterns.md`, which validated ~85% of Scoria as-built). → see `SEED-012`.

5. **SEED-009 (999.6) — Retrieval Eval Depth & Seams**  (independent track — needs only shipped 006; benefits from 007's RETRIEVER span)
   precision@k/NDCG/abstention/staleness (model-free, Scoria-owned) + faithfulness/rerank as
   host-supplied hooks (no model in-lib) + tiny gold set. → see `SEED-009`.

6. **SEED-011 (999.7) — Privacy & Feedback Governance**  (independent track — depends on nothing; order vs 009 is a priority call)
   Trace/memory retention/TTL/purge + right-to-erasure (Scoria owns the tables → owns deletion) +
   PII masking contract + regex pack + human-feedback capture → flywheel + memory forget/expire.
   Unblocks the currently-unserved privacy/legal/compliance persona. → see `SEED-011`.

7. **SEED-013 (999.9) — Operator IA Pivot (Control-Room v2)**  (SPLIT — see refinement note above)
   **(a) Early cross-cutting shell** (buildable on today's backend, `depends_on: []`): tighter nav re-group
   (Home · Queue · Features · Runs · Quality · Govern · [Data & Privacy] · [Audit]), a **unified Queue**
   (one ranked human-work inbox over existing approvals+incidents+reviews), a persistent scope contract
   (Tenant/Feature/Time/Live, cross-tenant loud), and the progressive-disclosure law + receipts +
   "create policy rule from this." Landing this early lets each feature seed build into the frame + plug
   into one Queue. **(b) Late feature-specific screens** that ride their backends: 3-pane **Run Workbench**
   evidence canvas + "story-spine-with-vesicles" trace viz (SEED-007), Govern/blast-radius (SEED-010),
   Data & Privacy (SEED-011), Quality depth (SEED-008/009), **Feature Cockpit** content (SEED-012). From
   the 2026-07-03 operator-UI storyboard ingest (**UI source-of-record:
   `.planning/research/operator-ui-north-star.md`**, ~40% of its ideas already ship). → see `SEED-013`.

### Carried-forward deferred work (pre-audit)

- **SEED-004 — Test-code determinism** (async `IntegrationCase`, remove `Process.sleep`→`eventually/2`,
  raise shard count). Deferred at v3.1 close; keep separate unless a release-blocking test failure requires a narrow fix. *(No seed
  file on disk — tracked only here + STATE.md Deferred Items.)*

- **FLEET-01** — migrate sibling repos onto the shared Traefik + unpublished-DB standard. Deferred v3.2.
- **FLEET-02** — `make nuke-all` fleet-wide teardown (high blast radius). Deferred v3.2.
