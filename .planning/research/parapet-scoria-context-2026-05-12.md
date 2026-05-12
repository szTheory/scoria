```md
# Scoria Development Export for Parapet

_Prepared from the Scoria repo on 2026-05-12._

## 1. Current Milestone & Roadmap

### Current shipped baseline

- `.planning/PROJECT.md` and `.planning/STATE.md` still describe **v1.2 Corpus** as the current completed milestone.
- Shipped baseline includes:
  - v1.0 MVP: core observability, MCP governance, LiveView operator UX, evaluation flywheel
  - v1.1 Caldera: durable workflows, handoffs, exact resume, retry-failed-step
  - v1.2 Corpus: pgvector-backed knowledge layer, citations, grounding, retrieval evidence in the existing dashboard

### Active forward path / roadmap reality

- `.planning/ROADMAP.md` now shows **v1.3 Seismograph** as the active/planned milestone family with gap-closure follow-up phases:
  - Phase 8: **complete** — breaker-open budget reservation reconciliation
  - Phase 9: **planned/in progress in roadmap terms** — restore audited approval and incident delivery wiring
  - Phase 10: **planned** — wire production SRE telemetry and fix default verification bootstrap
  - Phase 11: **planned** — re-verify Seismograph and align milestone state

### Important planning inconsistency

- There is a real planning-state inconsistency:
  - `.planning/PROJECT.md` and `.planning/STATE.md` still frame v1.2 as the current completed milestone and v1.3 as upcoming
  - `.planning/ROADMAP.md`, the v1.3 audit, and recent phase work show v1.3 gap closure is actively underway
- For Parapet integration work, treat **v1.3 Seismograph + phases 8-11** as the relevant current direction.

### Why Parapet cares

v1.3 is the milestone that directly shapes Parapet integration:

- token/cost budget enforcement
- breaker state and external-effect governance
- SRE telemetry and SLI/SLO envelope design
- audit export and evidence lineage
- incident routing and delivery
- regression alerting with scorer/baseline references

## 2. Recent Commits

```text
70d156a docs(09-03): record incident evidence summary
0a765c4 feat(09-03): expose durable incident delivery outcomes
4fad874 docs(09-02): record incident delivery summary
3e6ecf1 feat(09-02): produce durable incident delivery rows
3ec7113 docs(09-01): record approval wiring summary
7583cd7 feat(09-01): lock approval audit attribution
9d1b758 feat(09-01): restore workflow-owned approval ui path
caa7878 docs(roadmap): add v1.3 gap closure phases
a957493 docs: refresh README and add CI
c09aa66 chore: archive v1.2 milestone
79111cc docs(07-05): add plan execution summary
5918e26 feat(07-05): refresh trace badges from lazy SRE evidence
b5813f6 test(07-05): extend lazy incident evidence coverage
7f43d68 feat(07-05): add trace-first incident evidence notebook
7c7e4e1 docs(07-08): complete relay runtime plan
```

## 3. Telemetry & OpenInference

### 3a. Current shipped observability path

Scoria already has a shipped **OpenInference-style observability path**:

- `Scoria.Observe.Telemetry`
  - attaches to `[:scoria, :observe, :span, :stop]`
  - redacts metadata through `Scoria.Observe.Redactor`
  - sends spans into the async buffer for persistence
- `Scoria.Observe.Adapters.ReqLLM`
  - listens to `[:req_llm, :request, :stop]`
  - emits a normalized span to `[:scoria, :observe, :span, :stop]`
  - current shape:
    - `name: "req_llm_request"`
    - `span_kind: "LLM"`
    - attributes include:
      - `"llm.model_name"`
      - `"llm.token_count"`
      - `"req.url"`
- `Scoria.Observe.Adapters.Jido`
  - listens to `[:jido, :action, :stop]`
  - emits a normalized span to `[:scoria, :observe, :span, :stop]`
  - current shape:
    - `name: "jido_action"`
    - `span_kind: "INTERNAL"`
    - attributes include:
      - `"jido.action_name"`
      - `"jido.status"`
      - `"duration_ms"`

### OpenInference / persisted trace model

Planning and state docs explicitly say Scoria follows **OpenInference specifications for trace/span structures**.

Persisted observability model is Ecto-backed:

- traces
- spans
- span events

Important characteristics called out in planning/state:

- core columns + JSONB attributes
- durable trace/span store in Postgres
- redaction at the telemetry boundary
- trace-first LiveView operator UX

### 3b. Current SRE / Parapet-facing telemetry path

Scoria also has a newer **SRE telemetry helper layer** intended specifically for Parapet/SRE-style consumers:

- `Scoria.SRE.Telemetry`
- `Scoria.SRE.Adapters.Parapet`

Currently defined SRE metric/event categories:

- `latency`
- `cost`
- `quality`
- `budget_burn`
- `breaker_state`
- `tool_reliability`

Current `Scoria.SRE.Telemetry` shared metadata allowlist:

- `tenant_id`
- `incident_key`
- `reason_code`
- `severity`
- `trace_id`
- `run_id`
- `policy_key`
- `provider`
- `model`
- `tool_name`
- `integration_kind`
- `scorer_version`
- `baseline_version`
- `breaker_key`
- `state`

Current `Scoria.SRE.Adapters.Parapet.translate/3` split:

- **labels**:
  - `tenant_id`
  - `incident_key`
  - `reason_code`
  - `severity`
  - `policy_key`
  - `provider`
  - `model`
  - `tool_name`
  - `integration_kind`
  - `breaker_key`
  - `state`
- **refs**:
  - `trace_id`
  - `run_id`
  - `scorer_version`
  - `baseline_version`

### Important current gap

This SRE telemetry contract exists, but **live producer wiring is still incomplete**.

The v1.3 milestone audit says:

- `Scoria.SRE.Telemetry` defines emitters
- but production call sites were not found outside tests
- so reason-coded SLI signals are **not yet proven in live runtime/MCP paths**

This is now the explicit job of **Phase 10**.

### Current Parapet-facing telemetry philosophy

Scoria’s own Parapet seed and planning posture already align around:

- low-cardinality labels only
- high-cardinality refs separated from labels
- durable Ecto evidence as the source of truth
- Parapet as the ephemeral metrics/SLO/alerting layer
- deep links from Parapet alerts into Scoria trace/evidence UI

## 4. Evals & MCP Tools

### 4a. Eval state

#### What is concretely implemented

`Scoria.Eval` currently provides durable eval/dataset management:

- immutable datasets
- immutable dataset version updates
- dataset item cloning on dataset updates
- eval spec creation and immutable versioning
- trace promotion into a dataset snapshot (`promote_trace_to_dataset/2`)

Core eval schemas present in the repo:

- `Scoria.Eval.Dataset`
- `Scoria.Eval.DatasetItem`
- `Scoria.Eval.EvalSpec`
- `Scoria.Eval.EvalRun`
- `Scoria.Eval.Score`

#### What “evaluation execution” looks like right now

The dedicated mix task exists:

- `mix scoria.eval --dataset <uuid>`

But the task is still basically a stub:

- it starts the app
- parses `--dataset`
- prints `Starting evaluation for dataset ...`
- TODO comment still says it needs to fetch datasets and iterate items using Tribunal

So:

- **dataset/eval persistence and promotion are real**
- **full LLM-as-judge batch execution through the mix task is not complete yet**

#### The most concrete current scoring path

The most real execution path for scoring today is in `Scoria.Knowledge.score_grounding/2`.

It persists deterministic grounding/citation scores for:

- `citation_presence`
- `citation_validity`
- `chunk_membership`
- `unsupported_claims`
- `retrieval_hits`
- `retrieval_ranking`

And it can optionally append a judge-based score carrying:

- `scorer_kind`
- `rubric_version`
- `model`
- `prompt_version`
- `score`
- `status`
- `reasoning`
- `details`
- `evidence_refs`

So the current “eval story” is:

- durable eval/dataset model exists
- trace promotion exists
- knowledge-layer deterministic scoring exists
- judge result persistence exists as an optional appended score
- full dataset execution loop via `mix scoria.eval` is still unfinished

### 4b. MCP / tool calling state

Tool calling is implemented through `Scoria.MCP.Executor.execute/4`.

What it already does:

- isolated execution via `Task.Supervisor`
- explicit timeout handling
- tool telemetry:
  - `[:scoria, :tool, :started]`
  - `[:scoria, :tool, :completed]`
  - `[:scoria, :tool, :timeout]`
  - `[:scoria, :tool, :failed]`
- budget reservation and reconciliation hooks
- breaker wrapping via `Scoria.SRE.BreakerRegistry`
- sensitive MCP access auditing
- policy-sensitive tool invocation auditing

### Tool failure representations

Current tool/MCP failure states are represented as:

- `{:error, :timeout}`
- `{:error, :execution_failed}`
- `{:error, %{status: :breaker_open} = envelope}`
- `{:error, %{status: :access_denied, ...}}`

There is already a distinction between:

- timeout
- execution failure
- breaker open
- access denied

This distinction matters for Parapet because it gives you separate error families to map into SLOs or alerts.

### Tool audit / governance state

Sensitive access and tool governance are already partially durable:

- sensitive MCP access can create audit outbox rows like `mcp.access.granted` / `mcp.access.denied`
- policy-sensitive invocations create `tool.invocation` audit outbox rows
- audit rows carry tenant, actor, trace, workflow run, step, policy, and redacted metadata

### How tool failures / eval scores show up in SRE-facing state

SRE-side schemas and incident planning already account for:

- `scorer_version_ref`
- `baseline_version_ref`
- `reason_code`
- `policy_key`
- `trace_id`
- `workflow_run_id`

This means Parapet integration can already expect Scoria’s incident/evidence model to carry eval-specific references when regressions become incidents.

## 5. HITL

### Short answer

Scoria **does have HITL**, but not yet as a generic standalone queue subsystem.

### What exists today

HITL is currently represented as **workflow-owned durable approval pauses**:

- `Scoria.Workflows.mark_waiting_for_approval/3`
- `Scoria.Workflows.approve/3`
- `Scoria.Workflows.resume_run/1`

Durable pieces involved:

- `Run.status = "waiting_for_approval"`
- `Step.status = "waiting_for_approval"`
- persisted `Approval` rows
- persisted checkpoint
- persisted workflow event
- persisted audit outbox row for `approval.requested`

Approval outcomes currently supported:

- `approved`
- `rejected`
- `expired`

### Important boundary

This is **not** yet a generalized HITL queue product with routing, SLA management, prioritization, etc.

Right now it is:

- durable approval pauses inside workflows
- operator-mediated continuation
- auditability around approval decisions

### Recent approval/HITL work

Phase 9 specifically restored the correct approval boundary:

- UI actions should no longer mutate approval rows directly
- `Scoria.Workflows.approve/3` is the blessed mutation path
- approval request/decision should write workflow truth + audit evidence transactionally
- resume should happen only through workflow-owned logic after commit

So for Parapet:

- there is real HITL state already
- but it is workflow approval state, not a generic queue abstraction

## 6. Parapet-Relevant Future Work

### Phase 10: immediate integration pressure

Phase 10 is directly relevant to Parapet and is now decisioned in `.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md`.

Planned direction:

- wire real live SRE telemetry producers at:
  - `Scoria.Workflows.Runtime`
  - `Scoria.MCP.Executor`
- emit separate **post-commit incident lifecycle telemetry** from the durable incident seam
- keep relay/delivery outcomes **DB-first truth**, not first-class SLO sources by default
- move toward **canonical operational identity** as the telemetry contract
- introduce a shared `identity_key`
- treat `incident_key` as a derived projection rather than the primary runtime identity
- fix the default verification bootstrap so ordinary core/SRE work runs via ordinary `mix test`

This is probably the single most important short-term Scoria input for Parapet work.

### Phase 11: verification and state alignment

Phase 11 is planned to:

- re-verify Seismograph
- align milestone state artifacts
- close the evidence gap between what planning says and what focused verification proves

For Parapet, that means the Scoria-side SRE contract is still stabilizing and is not yet formally “closed.”

### Current Parapet synergy seeds already captured in Scoria

`.planning/memory/parapet-synergy.md` already calls out these likely integration directions:

1. AI quality and latency SLOs
2. cost/token burn-rate alerts
3. deploy correlation to eval regressions
4. MCP tool reliability as an SRE target
5. strict high-cardinality telemetry safety
6. deep-linking from Parapet alerts into Scoria’s durable evidence UI

### Dormant but relevant future seed

`.planning/seeds/SEED-001-agentcore-lessons.md` is not a Parapet plan directly, but it is relevant because it reinforces future integration pressure around:

- explicit session/actor identity
- policy-backed tool access
- observability as a product primitive
- avoiding managed-runtime drift

If Parapet later integrates more deeply with Scoria runtime identity, policy, or tool boundaries, this seed is relevant.

## 7. Best Current Mental Model for Parapet

If you are building Parapet’s Scoria integration right now, the most accurate mental model is:

- **Shipped today**
  - OpenInference-style span ingestion and persistence
  - trace-first LiveView operator UX
  - durable datasets/eval specs and trace promotion
  - deterministic grounding/citation scoring
  - isolated MCP tool execution with audit telemetry
  - workflow-owned durable approval pauses
  - durable SRE nouns: budgets, breaker trips, alerts, incidents, notification deliveries, audit outbox

- **Defined but not yet fully live-wired**
  - SRE telemetry producers for runtime/MCP
  - canonical Parapet-facing SLI flow from execution seams into incidents
  - boring default bootstrap for SRE verification

- **Strong likely integration contract**
  - low-cardinality SLI labels
  - high-cardinality refs kept separate
  - durable Ecto evidence as source of truth
  - Parapet for SLO math, burn-rate alerting, and operational signal fanout
  - deep links back into Scoria traces, approvals, audits, incidents, and retrieval/eval evidence
```
