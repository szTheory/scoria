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
- ✅ **v3.6 Trace Foundation** — Phases 51–54.1, SEED-007 OTel-GenAI/OpenInference trace substrate (shipped 2026-07-19)

## Phases

**Phase Numbering:** Integer phases (1, 2, 3): planned milestone work. Decimal phases (2.1, 2.2): urgent insertions. Phase numbering continues from the previous milestone (v3.6 ended at Phase 54.1) — v3.7 starts at Phase 55.

**Current milestone: v3.7 Portcullis (SEED-010 Lethal-Trifecta Governance)**

- [x] **Phase 55: Content Trust & Taint Substrate** - Trust tiers on knowledge chunks/tool outputs + prompt-assembly spotlighting + BYO `scan/2` hook
- [x] **Phase 56: Tool-Declared Trifecta Classification** - Tool-declared trifecta legs resolved at `MCP.Executor`, fail-closed-but-inspectable defaults across all five fail-open seams
- [x] **Phase 56.1: Per-Run Rails (SPLIT from 56)** - Per-run `max_steps`/`max_tool_calls`/`timeout` rails with an audited, non-resumable halt (completed 2026-07-28)
- [ ] **Phase 57: Confluence Escalation Gate** - Escalate to human approval when private-data + untrusted-content + exfil co-occur on one tainted path
- [ ] **Phase 58: Safety Hooks, Security Boundary & Govern Surface** - BYO moderation/output-scanner hooks, `SECURITY-BOUNDARY.md`, minimal read-only Govern surface

## Phase Details

### Phase 55: Content Trust & Taint Substrate

**Goal**: Untrusted content moving through Scoria — retrieved knowledge chunks and tool outputs — carries a trust tier, is visibly separated from instructions at prompt assembly, and is scannable via a BYO hook, supplying the missing untrusted-content leg the confluence gate (Phase 57) will read.
**Depends on**: Nothing (first phase of this milestone; builds on the v3.6 trace substrate — `span_kind`, structured child spans, `ai_span_events`/`emit_event/1`, `Observe.Bounds` IDs-only bounding)
**Requirements**: TAINT-01, TAINT-02, TAINT-03, TAINT-04
**Success Criteria** (what must be TRUE):

  1. A retrieved knowledge chunk carries a trust-tier/taint tag in its `Knowledge.Chunk` metadata, defaulting to untrusted for externally-sourced/retrieved content.
  2. A tool's output arrives wrapped in an envelope carrying a trust tier, so downstream code treats it as potentially-untrusted rather than implicitly-trusted context.
  3. When a prompt is assembled in the orchestrator, untrusted content is spotlighted/datamarked with a model-agnostic delimiter that distinguishes it from instructions.
  4. A host can register a `scan/2` hook (e.g. Rebuff/LlamaGuard-shaped) and see scanned/untrusted content tagged in traces; with none registered, the default no-op leaves current behavior unchanged.

**Plans**: 5 plans (3 waves)
**Wave 1**

- [x] 55-01-PLAN.md — Trust leaf vocab + Tiered protocol + TAINT-01 Knowledge (tracer) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 55-02-PLAN.md — Scoria.MCP.Envelope + executor wrap + soft-launch flag (TAINT-02) [wave 2]
- [x] 55-03-PLAN.md — Scoria.Spotlight datamark/delimit + spotlight trace keys (TAINT-03) [wave 2]
- [x] 55-04-PLAN.md — Scan engine: Scanner/Verdict/Scan, monotonic law, fail-closed (TAINT-04) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 55-05-PLAN.md — Wire scan at retrieve/executor + scoria.trust.* trace tagging (TAINT-04) [wave 3]

### Phase 56: Tool-Declared Trifecta Classification

**Goal**: Every tool call enforced at `MCP.Executor` carries an explicit, tool-declared trifecta classification instead of a silent host-passed default.
**Depends on**: Nothing new (independent of Phase 55's taint substrate — both feed Phase 57's confluence gate)
**Requirements**: CLASS-01, CLASS-02, CLASS-03
**Success Criteria** (what must be TRUE):

  1. A tool declares its `reads_private_data`/`sees_untrusted_content`/`can_exfiltrate` legs plus an `action_class` once, on the tool itself, rather than passed per call.
  2. An unclassified tool no longer silently resolves to `approval_sensitive: false`; it fails closed to an inspectable default and emits telemetry for unclassified/ungated use, closing the fail-open seam (formerly cited as `executor.ex:150-165`; the code moved during Phase 55 — the live-path seam is now `executor.ex:552-554` and the replay seam `executor.ex:181-194`).
  3. At `MCP.Executor` enforcement, every tool call's per-call taint is resolved from the tool's own declaration, never a host-passed default.
  4. Resolution covers ALL five fail-open seams, not just `MCP.Executor`: the replay seam, the live `policy_sensitive_invocation?/1` path, `budget_required?/1`, `Connectors.Invocation.build_seam/2` (which decides replay BEFORE the executor), and `Workflows.Runtime`'s `%{local_classification: :pure}` default.

**Plans**: 3 plans (3 waves)
**Wave 1**

- [x] 56-01-PLAN.md — Classification leaf + Tool declaration surface + executor resolution choke point (tracer) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 56-02-PLAN.md — require_tool_classification refusal + result_envelope persistence + scoria.classification.* registry (CLASS-02) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 56-03-PLAN.md — Fail-open sites 2-5 consume the classification (CLASS-03) [wave 3]

**Context**: `.planning/phases/56-tool-declared-trifecta-classification-per-run-rails/56-CONTEXT.md`

### Phase 56.1: Per-Run Rails (SPLIT from Phase 56)

**Goal**: A single run cannot exceed its own step/call/time budget unnoticed; exceeding a rail halts the run terminally and the halt is audited.
**Depends on**: Nothing new. **Split out of Phase 56 on 2026-07-28** after research showed the two halves share no files or failure modes, that Phase 57 depends on Phase 56 for classification only (not rails), and that rails require a schema migration classification does not. Splitting unblocks Phase 57 earlier.
**Requirements**: RAIL-01
**Success Criteria** (what must be TRUE):

  1. A single run that exceeds its `max_steps`/`max_tool_calls`/`timeout` rails halts, and the halt is recorded in the audit trail.
  2. The halt is genuinely terminal — not resurrectable via `Workflows.retry_step/1` / `Resume.retry_failed_step/2`.
  3. Rails default to unlimited, so an adopter who configures nothing sees unchanged behavior; counting is always on so limits can be sized from real traffic.
  4. Surfaces with no run attribution (inbound JSON-RPC via `MCP.Router`) are an explicit, telemetried no-op rather than a silent gap.

**Plans**: 6 plans (5 waves)
**Wave 1**

- [x] 56.1-01-PLAN.md — Tracer: rail columns, CAS step admission, terminal audited halt + six guards G1-G6 (RAIL-01) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 56.1-02-PLAN.md — Config ladder `Scoria.Runtime.Rails` + threading into both `Params` entry points (RAIL-01) [wave 2]
- [x] 56.1-03-PLAN.md — `max_tool_calls` at both tool entry points, SC#4 no-op, `run_id` forward, CAS determinism battery (RAIL-01) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 56.1-04-PLAN.md — Timeout rail: active-time predicate + changeset-derived pause accounting (RAIL-01) [wave 3]

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 56.1-05-PLAN.md — Halt evidence surfaces: `:observed` telemetry, `scoria.rail.*` trace keys, operator halt message (RAIL-01) [wave 4]

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 56.1-06-PLAN.md — Adopter surface: per-run-rails guide, mirrored footgun notes, migration disclosure (RAIL-01) [wave 5]

**Context**: `.planning/phases/56.1-per-run-rails-split-from-phase-56/56.1-CONTEXT.md` is the canonical locked spec (D-01..D-23); the older D-56.1-A..H notes in `56-CONTEXT.md` are superseded and several of their citations are stale

### Phase 57: Confluence Escalation Gate

**Goal**: When a single tainted execution path touches private data, untrusted content, and an exfil-capable action at once, Scoria pauses for human approval before the exfil action executes — audited, replayable, and fail-closed-but-inspectable by default so no adopter is bricked.
**Depends on**: Phase 55, Phase 56 (consumes the taint substrate and the tool-declared classification the gate evaluates)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04
**Success Criteria** (what must be TRUE):

  1. A confluence evaluator classifies a tainted execution path by which of the three legs (private-data / untrusted-content / exfil) are present, mirroring `ReplayDisposition`'s seam-classification style.
  2. *(amended 2026-07-29, plan 57-10, D-18/D-25)* When all three legs co-occur on one tainted path, the confluence gate decides and refuses at `Scoria.MCP.Executor`, before the tool's execution task is started, and the run's STEP (not the whole run) transitions to `waiting_for_approval` through the existing pause function, so the escalation is resumable. This is a step-scoped pause, not a run-level freeze — a sibling step already in flight may still complete and reopen sibling dispatch while the escalated step alone stays paused (an accepted, documented limitation). Tool calls with no runtime step attribution cannot be paused; that gap is telemetried and documented.
  3. Every confluence escalation decision is written to the audit outbox and can be replayed, consistent with existing approval/replay evidence.
  4. *(amended 2026-07-29, plan 57-10, D-31)* Confluence enforcement is graded by evidence quality: the `declared` grade enforces from the shipped default; the three ungated grades (`unclassified`, `scanner_infra`, `default_tier`) emit telemetry only and never block on their own, so an adopter who has declared nothing is never silently bricked; opting into strict mode extends enforcement to the three ungated grades too.

**Plans**: 10 plans

Plans:
**Wave 1**

- [x] 57-01-PLAN.md — Tracer: one tainted path pauses end-to-end, plus the consolidated migration (GATE-01, GATE-02) [wave 1]
- [x] 57-04-PLAN.md — Semconv confluence attribute group and registry canary (GATE-04) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 57-03-PLAN.md — Phase 55 mint-site repair and the scanner-tier evidence field (GATE-01) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 57-02-PLAN.md — Confluence evaluation model: eight-value ladder, weakest-evidence grading, config surface (GATE-01, GATE-04) [wave 3]

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 57-05-PLAN.md — Gate wiring: approval-consume CAS, attribution and containment, always-on telemetry (GATE-02, GATE-04) [wave 4]
- [x] 57-09-PLAN.md — Reviewer evidence rows, bounded run-scoped approval, capped pending query (GATE-02) [wave 4]

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 57-06-PLAN.md — Per-run leg accumulator: strongest-wins, lit-legs-only, single-statement fold (GATE-01, GATE-02) [wave 5]

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 57-07-PLAN.md — Audit trail on escalate and block, closed metadata projector, replay contract (GATE-03) [wave 6]

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 57-08-PLAN.md — Resume widening, retry guard, concurrency rescue, halt invariants (GATE-02) [wave 7]

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 57-10-PLAN.md — Concurrency suite, shipped-lie repair, requirement and roadmap amendments (GATE-01..04) [wave 8]

**Context**: `.planning/phases/57-confluence-escalation-gate/57-CONTEXT.md` is the canonical locked spec (D-01..D-54); `57-RESEARCH.md` re-verified its citations against the worktree and its file:line coordinates win on conflict

### Phase 58: Safety Hooks, Security Boundary & Govern Surface

**Goal**: Adopters can wire optional moderation/output-scanning through Scoria's existing eval seam, know exactly what Scoria enforces versus what they must own, and see the named dangerous-combination classification for a tainted run through a minimal read-only screen.
**Depends on**: Phase 57 (the Govern surface renders the confluence gate's classification output; hooks and the boundary doc close out the milestone)
**Requirements**: HOOK-01, HOOK-02, BOUND-01, GOVERN-01
**Success Criteria** (what must be TRUE):

  1. A host can register a moderation scorer through the existing `Eval.online_scoring`/`judge_runner` seam; with none registered, moderation stays off by default.
  2. A host can register an output-scanner hook through the same seam and see model output tagged "untrusted" in traces when it fires.
  3. A committed `SECURITY-BOUNDARY.md` states, side by side, what Scoria enforces (taint substrate, tool classification, confluence gate, rails, hook seams) versus what the host must own (detectors, allowlists, sinks, content policy) across improper-output-handling, moderation, system-prompt-leakage, and per-user-allowlist scenarios.
  4. An operator can open a read-only Govern screen and see, for a tainted run, the named dangerous combination ("private data + untrusted content + external egress → exfiltration path") plus per-tool trifecta classification, with no policy-builder or simulate-on-history present.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 51. Foundation Fix + Key Convention + Span-Kind Taxonomy | v3.6 | 5/5 | Complete | 2026-07-12 |
| 52. RETRIEVER Span + Host-Declared Attributes | v3.6 | 6/6 | Complete | 2026-07-12 |
| 53. Structured Child Spans + Write-Time Bound | v3.6 | 8/8 | Complete | 2026-07-18 |
| 53b. `ai_span_events` + `emit_event/1` | v3.6 | 5/5 | Complete | 2026-07-18 |
| 54. Docs Accuracy + Conformance Check | v3.6 | 2/2 | Complete | 2026-07-19 |
| 54.1. Wire ReqLLM/Jido adapters at boot + reconcile CHANGELOG (INSERTED) | v3.6 | 2/2 | Complete | 2026-07-18 |
| 55. Content Trust & Taint Substrate | v3.7 | 5/5 | Complete    | 2026-07-28 |
| 56. Tool-Declared Trifecta Classification | v3.7 | 3/3 | Complete    | 2026-07-28 |
| 56.1. Per-Run Rails (SPLIT from 56) | v3.7 | 6/6 | Complete    | 2026-07-28 |
| 57. Confluence Escalation Gate | v3.7 | 0/TBD | Not started | - |
| 58. Safety Hooks, Security Boundary & Govern Surface | v3.7 | 0/TBD | Not started | - |

## Archived Milestones

<details>
<summary>✅ v3.6 Trace Foundation (Phases 51–54.1) — SHIPPED 2026-07-19</summary>

**Goal:** Finish the trace schema Scoria already half-designed — make spans structured and portable (OTel-GenAI / OpenInference naming convention over the existing `attributes` jsonb map, not typed columns, not a schema rewrite) so eval, regression detection, and every downstream seed can attribute a quality delta to a prompt version, retrieval config, or model change instead of reading a flat blob.

- [x] Phase 51: Foundation Fix + Key Convention + Span-Kind Taxonomy (5/5 plans) — completed 2026-07-12
- [x] Phase 52: RETRIEVER Span + Host-Declared Attributes (6/6 plans) — completed 2026-07-12
- [x] Phase 53: Structured Child Spans + Write-Time Bound (8/8 plans) — completed 2026-07-18
- [x] Phase 53b: `ai_span_events` + `emit_event/1` (5/5 plans) — completed 2026-07-18
- [x] Phase 54: Docs Accuracy + Conformance Check (2/2 plans) — completed 2026-07-19
- [x] Phase 54.1: Wire ReqLLM/Jido adapters at boot + reconcile CHANGELOG — INSERTED (2/2 plans) — completed 2026-07-18

Closed the pre-existing silent FK gap that swallowed every span; established `SpanKind` (8-value) + version-pinned `Semconv` as single key origins; captured model config; emitted structured `tool`/`prompt`/`retrieval`/`guardrail` child spans on a pipeline that boots under `Scoria.Application`; dual-wrote a linked `RETRIEVER` span alongside `ai_retrieval_runs`; resurrected `ai_span_events` via allow-listed `emit_event/1`; bounded all payloads to IDs-and-counts at one write-time choke point; and landed an honest version-pinned "OpenInference-compatible" claim backed by a falsifiable conformance test + boot-attached ReqLLM/Jido adapters. No Hex publish (convention staged under Unreleased `0.1.4`). Milestone audit `passed` (16/16 requirements, 6/6 phases, 12/12 integration seams, 1/1 E2E flow); closed `override_closeout` with one pre-existing SEED-004-class test flake deferred. Inserted Phase 54.1 closed the audit-found adapter boot-attach integration gap. Full phase detail archived in `.planning/milestones/v3.6-ROADMAP.md`; requirements in `.planning/milestones/v3.6-REQUIREMENTS.md`; audit in `.planning/milestones/v3.6-MILESTONE-AUDIT.md`.

</details>

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

**Execution order (do top-to-bottom): SEED-010 → SEED-008 → SEED-012 → {SEED-009, SEED-011} → SEED-013.**
The `999.x` tags are stable seed IDs (cross-referenced from PROJECT.md/STATE.md), **not** the execution
rank — read the numbered list below for order. **SEED-007 (999.3) shipped as v3.6 Trace Foundation (2026-07-19)**;
the substrate it emits (span_kind / gen_ai.* / model-config / RETRIEVER span + host-declared
feature/route/archetype/intent attrs) is now available to every seed below. **SEED-010 (999.4) is now
active as v3.7 Portcullis (Phases 55–58, roadmap created 2026-07-19).**

Provenance: the base order was set by a 2026-07-03 AI-eval posture audit (6-agent adjudication vs
LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel). Cadence decision: **P0 fixes →
docs/positioning → feature milestones**, each feature milestone interleaving its own feature docs + a
release as it lands. SEED-006 (P0 trust/security) shipped in v3.4, SEED-005 (docs/positioning +
honest `0.1.3` release) shipped in v3.5, and SEED-007 (trace foundation) shipped in v3.6, so the next
milestone is the flagship differentiator → SEED-010.

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
> **Dividend map (why this order):** 007 (now shipped) emitted `span_kind`/`gen_ai.*`/model-config/RETRIEVER-span +
> host-declared `feature`/`route`/`archetype`/`intent` attrs → consumed by 008 (scorers read spans),
> 010 (taint substrate), 012 (archetype attr), and every 013 screen. 008 emits the confusion-matrix +
> typed archetype slot → 012 reuses both wholesale. 009 and 011 depend only on shipped 006 (independent
> tracks; order between them is priority, not dependency). 013 depends on nothing structurally but
> composes every feature seed's UI slice.

1. **SEED-010 (999.4) — Lethal-Trifecta Governance**  ⭐ **[FLAGSHIP DIFFERENTIATOR — ACTIVE AS v3.7 PORTCULLIS]**
   Content trust tiers + spotlighting + tool-declared trifecta classification + confluence
   escalation policy (Meta Rule-of-Two) + moderation/output hooks + SECURITY-BOUNDARY.md. No peer
   ships this as a runtime seam; Scoria is 2/3 built. Consumes 007's now-shipped taint substrate —
   build while trace work is fresh; highest external/positioning payoff. Roadmapped as Phases 55–58
   (2026-07-19). → see `SEED-010`.

2. **SEED-008 (999.5) — Trustworthy Eval Depth**  (after 007 — scorers are meaningless over attribution-less traces)
   Real scorer library + regression-comparison engine + judge calibration (the unique join Scoria
   already captures but discards) + versioned rubric + typed risk/intent taxonomy slots. Emits the
   confusion-matrix + archetype slot that 012 reuses. → see `SEED-008`.

3. **SEED-012 (999.8) — Architecture-Archetype Awareness (Rule-8 lens)**  (small capstone; PULLED FORWARD — do immediately after 008)
   Host-declared `archetype`/`route` on runs (Scoria records/segments, never infers) + a
   segment-by-attribute dashboard facet (per-archetype/per-route cost/latency/scores) + per-archetype
   Rule-8 eval presets + Router observability (routing accuracy via the SEED-008 confusion-matrix reuse).
   A thin composition over the SEED-007 attribute convention + SEED-008 eval machinery — not new infra;
   cheapest while that machinery is warm. From the 2026-07-03 AI-architecture-patterns ingest (memo:
   `.planning/research/ai-architectural-patterns.md`, which validated ~85% of Scoria as-built). → see `SEED-012`.

4. **SEED-009 (999.6) — Retrieval Eval Depth & Seams**  (independent track — needs only shipped 006; benefits from 007's RETRIEVER span)
   precision@k/NDCG/abstention/staleness (model-free, Scoria-owned) + faithfulness/rerank as
   host-supplied hooks (no model in-lib) + tiny gold set. → see `SEED-009`.

5. **SEED-011 (999.7) — Privacy & Feedback Governance**  (independent track — depends on nothing; order vs 009 is a priority call)
   Trace/memory retention/TTL/purge + right-to-erasure (Scoria owns the tables → owns deletion) +
   PII masking contract + regex pack + human-feedback capture → flywheel + memory forget/expire.
   Unblocks the currently-unserved privacy/legal/compliance persona. Also owns the deferred
   `user_feedback_received` emission (reserved in v3.6's EVENT-02 vocabulary but not emitted). → see `SEED-011`.

6. **SEED-013 (999.9) — Operator IA Pivot (Control-Room v2)**  (SPLIT — see refinement note above)
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
  raise shard count). Deferred at v3.1 close; keep separate unless a release-blocking test failure requires a narrow fix.
  Now also owns the one v3.6-deferred flake (`capture_parity_test.exs:53`, order-sensitive under full-suite `--seed 0`).
  *(No seed file on disk — tracked only here + STATE.md Deferred Items.)*

- **FLEET-01** — migrate sibling repos onto the shared Traefik + unpublished-DB standard. Deferred v3.2.
- **FLEET-02** — `make nuke-all` fleet-wide teardown (high blast radius). Deferred v3.2.
