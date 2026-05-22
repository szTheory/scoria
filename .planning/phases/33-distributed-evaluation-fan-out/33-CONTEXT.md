# Phase 33: Distributed Evaluation Fan-out - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the distributed evaluation execution layer for Vanguard so operators can launch one evaluation campaign across many tenant/model targets, execute each target through Scoria's orchestration boundary, and persist durable result truth back into Ecto.

This phase is about campaign coordination, fan-out, worker execution, failure semantics, and durable progress/result truth. It should extend the existing eval lineage from Phase 25 and the queue/orchestrator groundwork from Phases 30-32 without turning Scoria into a hosted eval platform, an experiment-matrix product, or a second runtime truth system.

</domain>

<decisions>
## Implementation Decisions

### Campaign shape
- **D-01:** A campaign should represent one canonical eval contract fanned across many execution targets, not a bag of per-target semantic overrides.
- **D-02:** The default shape is:
  - one `EvalCampaign` parent referencing one immutable `EvalSpec`
  - many target rows describing tenant/model/provider execution targets
  - one `EvalRun` child execution per target
- **D-03:** Target-level overrides must stay narrow and execution-oriented only:
  - tenant identity
  - provider/model selection
  - queue/priority hints
  - other non-semantic runtime knobs
- **D-04:** Target rows must not silently override prompt versions, judge definitions, threshold policies, dataset slices, or other eval-contract semantics. Those require a different `EvalSpec` or a separate campaign.

### Persistence model
- **D-05:** Phase 33 should introduce one durable parent campaign record rather than flattening campaign identity into `EvalRun` alone.
- **D-06:** The canonical truth hierarchy for this phase is:
  - `EvalCampaign` for coordination and aggregate status
  - `EvalRun` for one concrete target execution
  - `Score` for per-item / per-scorer durable evidence
- **D-07:** Phase 33 should not introduce a second per-result truth hierarchy parallel to `EvalRun` and `Score`.
- **D-08:** `EvalRun` may gain campaign-related foreign keys and fan-out metadata, but it remains the child execution truth rather than a disposable projection row.

### Failure policy
- **D-09:** Fan-out execution should default to partial completion for shard-local execution failures after bounded retries.
- **D-10:** Campaign-aborting failure classes must stay narrow and explicit. Fatal classes include:
  - malformed or invalid campaign/eval contract
  - missing or invalid credentials required for the target lane
  - exhausted hard quota / invariant-breaking configuration failures
  - persistence or integrity errors that make durable truth untrustworthy
- **D-11:** Transient provider/model/worker failures should remain shard-local by default and roll up into partial completion rather than cancelling the entire campaign.
- **D-12:** Campaign terminal states should be explicit and operator-legible, with at least:
  - `completed`
  - `completed_partial`
  - `failed_fatal`
  - `cancelled`
- **D-13:** Whole-campaign cancellation should be best-effort and modeled as such. Planning must not assume transactional all-or-nothing cancellation semantics across already-running Oban jobs.

### Tenant execution semantics
- **D-14:** Scoria should use one shared Oban/Ecto execution fabric for fan-out by default, not per-tenant queue tables or prefix-isolated job infrastructure.
- **D-15:** Canonical tenant identity must be explicit on every durable execution artifact:
  - campaign
  - target/shard
  - eval run
  - result evidence where applicable
- **D-16:** Tenant identity must also be present in job payload/meta so queued work remains inspectable, queryable, and replay-safe.
- **D-17:** The planner should prefer foreign-key multitenancy discipline and central propagation helpers over implicit worker-only tenant scoping.
- **D-18:** Physical tenant isolation is deferred unless a later milestone proves the shared-fabric posture is insufficient for Scoria's embedded-library product shape.

### Result rollup and coordinator truth
- **D-19:** The campaign parent must persist eager aggregate counters and status snapshots rather than reconstructing campaign truth entirely from child rows at read time.
- **D-20:** The campaign truth row should at minimum carry durable aggregate state such as:
  - total targets
  - queued/running/completed/failed/cancelled counts
  - started/finished timestamps
  - last progress timestamp
  - terminal status
- **D-21:** Worker rows and `Score` evidence remain the underlying auditable truth; aggregate counters are the durable coordination summary, not a replacement for child evidence.
- **D-22:** Rich materialized dashboard projections beyond the campaign truth row are deferred to Phase 34 unless Phase 33 discovers a proven need that cannot be satisfied by the parent aggregates plus child drill-down.

### Queueing and execution path
- **D-23:** All fan-out work must use the dedicated `evals` queue established in Phase 30.
- **D-24:** Batch enqueueing must use the Phase 30 `Scoria.Workflows.BatchEnqueue` / `Oban.insert_all` seam rather than ad hoc loops or `Task.async_stream`.
- **D-25:** Individual target workers must execute model requests through `Scoria.Orchestrator`, inheriting the fallback and resiliency posture from Phases 31-32 rather than calling provider clients directly.
- **D-26:** Phase 33 should preserve an embedded-Phoenix, Ecto-native architecture:
  - Oban for durable fan-out
  - Ecto rows as truth
  - PubSub only as an ephemeral projection path for future dashboards
  - no hosted-service control plane drift

### DX and shift-left defaults
- **D-27:** Low-impact distributed-eval design choices should be shifted left into Scoria defaults and future GSD planning assumptions wherever possible.
- **D-28:** The following should be shifted left by default for this phase:
  - one campaign maps to one immutable eval contract
  - one `EvalCampaign` parent plus `EvalRun` children
  - narrow target overrides only
  - shard-local retries with partial completion as the normal degraded outcome
  - explicit fatal-class aborts only
  - eager campaign counters/status snapshots
  - explicit tenant identity on every durable execution object and job envelope
  - `evals` queue plus `BatchEnqueue` for fan-out
  - `Scoria.Orchestrator` as the only model execution boundary
- **D-29:** User interruption should be reserved for materially consequential changes only:
  - broadening campaign targets into semantic per-target override containers
  - introducing a second result truth hierarchy
  - changing tenant isolation shape beyond shared-fabric explicit identity
  - changing fatal-class policy in ways that alter operator trust or spend blast radius
  - drifting toward hosted eval-service behavior
- **D-30:** This shift-left posture should inform downstream GSD planning for this phase and later eval/dashboard phases: unless a decision changes product shape, security, durability, or blast radius, prefer the Scoria-recommended default over re-asking.

### the agent's Discretion
- Exact schema/module names for the campaign and target records, provided the parent-child truth boundary above remains intact.
- Exact target row shape and uniqueness strategy, provided target semantics stay execution-oriented rather than contract-mutating.
- Exact retry counts/backoff wiring and error-code classification, provided retries stay bounded and fatal classes remain narrow.
- Exact aggregate-counter update mechanism, provided worker finalization is idempotent and campaign truth remains durable and cheap to read.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 33 product shape is:
  - one immutable eval contract
  - one durable campaign parent
  - many explicit target rows
  - one `EvalRun` per target
  - durable per-item scores as evidence
  - eager campaign counters for cheap operator reads
- The right mental model is closer to Oban batches, Sidekiq batch-style progress, and Phoenix LiveDashboard than to a hosted experiment platform:
  - explicit parent truth
  - durable child work
  - visible counters/status
  - drill-down evidence
- The key UX/DX principle is comparability without surprise:
  - if two targets are in one campaign, they should be running the same eval contract
  - tenant/model differences should be visible metadata, not hidden semantic drift
- The main footguns to avoid are:
  - override bags that quietly become a second spec system
  - campaign truth reconstructed only from expensive ad hoc queries
  - implicit tenant identity on queued work
  - whole-campaign transactional assumptions on top of best-effort job cancellation
  - bypassing `Scoria.Orchestrator` and losing fallback/resiliency consistency

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 33 goal, success criteria, and dependency on Phase 32.
- `.planning/milestones/v1.8-ROADMAP.md` - Vanguard phase sequencing and exact distributed-eval success criteria.
- `.planning/milestones/v1.8-REQUIREMENTS.md` - `EVAL-02`, plus the surrounding Vanguard orchestration/eval constraints.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and operator-visible posture.
- `.planning/STATE.md` - current milestone status and previously locked eval/orchestration decisions.

### Prior locked Scoria decisions
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - least-surprise defaults and shift-left decision posture.
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-CONTEXT.md` - boring default path and explicit user-interruption policy.
- `.planning/phases/25-ci-cd-regression-and-evaluation-framework/25-CONTEXT.md` - immutable eval contract, durable `EvalRun`/`Score` truth, and anti-hosted-eval posture.
- `.planning/phases/30-oban-infrastructure-and-queue-segregation/30-CONTEXT.md` - dedicated `evals` queue and `BatchEnqueue` fan-out seam.
- `.planning/phases/31-model-routing-and-resiliency-foundation/31-CONTEXT.md` - bounded retries, circuit-breaker posture, and fail-fast model-health semantics.
- `.planning/phases/32-multi-model-fallback-orchestration/32-CONTEXT.md` - `Scoria.Orchestrator` as the execution boundary and fallback telemetry posture.

### Product and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - overall batteries-included Phoenix AI ops framing.
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons on eval/control-plane product shape and avoiding hosted-platform drift.
- `prompts/scoria-brand-book-deep-research.md` - calm operator-grade posture and evidence-first UX.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable defaults, Ecto-native truth, embedded dashboard posture.
- `.planning/research/evals-and-observability.md` - trace-to-dataset-to-eval flywheel and durable eval evidence model.
- `.planning/research/elixir-ai-ecosystem.md` - Scoria's composition strategy and what it should own vs adapt.
- `.planning/research/08-vanguard-ARCHITECTURE.md` - router/coordinator/worker split for Vanguard.
- `.planning/research/08-vanguard-SUMMARY.md` - milestone-level architecture and scale rationale.
- `.planning/research/08-vanguard-PITFALLS.md` - retry storms, DB contention, and fan-out anti-patterns.
- `.planning/research/agentcore-lessons.md` - session/governance/observability lessons without AWS-shaped drift.

### Current code surface
- `lib/scoria/eval.ex` - canonical eval context and current run/score persistence APIs.
- `lib/scoria/eval/eval_spec.ex` - immutable typed eval contract shape.
- `lib/scoria/eval/eval_run.ex` - existing child execution truth row that Phase 33 should extend rather than bypass.
- `lib/scoria/eval/score.ex` - per-item durable evidence row.
- `lib/scoria/eval/runner.ex` - offline run path and current eval-run lifecycle expectations.
- `lib/scoria/eval/judge_runner.ex` - live judge execution path and current orchestrated scoring seam.
- `lib/scoria/orchestrator.ex` - required model execution boundary for worker calls.
- `lib/scoria/workflows/batch_enqueue.ex` - batch fan-out utility for `Oban.insert_all`.
- `lib/mix/tasks/scoria.eval.ex` - explicit live eval command shape that campaign execution should remain coherent with.
- `test/scoria/eval/eval_run_persistence_test.exs` - durable truth expectations for `EvalRun` and `Score`.
- `test/scoria/workflows/batch_enqueue_test.exs` - queueing and chunked enqueue expectations.
- `test/scoria/orchestrator_test.exs` - fallback and telemetry expectations on the orchestrator boundary.

### External standards and adjacent-system guidance
- `https://hexdocs.pm/oban/Oban.html#insert_all/2` - batch fan-out guidance.
- `https://hexdocs.pm/oban/error_handling.html` - retry/error semantics.
- `https://hexdocs.pm/oban/Oban.Telemetry.html` - queue/job telemetry hooks.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - atomic campaign creation/finalization boundaries.
- `https://hexdocs.pm/ecto/3.6.1/multi-tenancy-with-foreign-keys.html` - explicit tenant identity with foreign-key multitenancy.
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` - ephemeral projection channel for future progress streaming.
- `https://developers.openai.com/api/reference/resources/evals` - top-level eval/run object pattern.
- `https://docs.langchain.com/langsmith/evaluation-quickstart` - one evaluation definition across many comparable runs.
- `https://github.com/sidekiq/sidekiq/wiki/Batches` - batch progress and operator-facing aggregate truth.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Eval.create_eval_run/1`, `record_eval_scores/2`, and `complete_eval_run/2` already define the durable child execution lifecycle that Phase 33 should keep rather than replace.
- `Scoria.Workflows.BatchEnqueue` already provides the right chunked fan-out seam for large campaign insertion.
- `Scoria.Orchestrator` already centralizes model fallback and telemetry; worker execution should build on it instead of bypassing it.
- Existing `EvalSpec` typing and immutable versioning already provide the stable eval contract campaigns need.

### Established Patterns
- Scoria repeatedly keeps durable truth in Ecto rows and treats telemetry/PubSub/UI as projections over that truth.
- The repo prefers one boring explicit product shape instead of parallel truth systems or hidden override magic.
- Prior phases repeatedly shift low-impact defaults left and reserve interruption for product-shape or blast-radius decisions.
- The codebase already treats queueing, retries, and worker execution as explicit seams rather than magical process-local orchestration.

### Integration Points
- Campaign creation should sit in the `Scoria.Eval` context and compose with the existing run/score APIs rather than inventing a second domain root elsewhere.
- Target workers should create/update `EvalRun` rows, execute via `Scoria.Orchestrator`, and write `Score` evidence through canonical APIs.
- Campaign aggregate counters should update from worker finalization and feed future Phase 34 PubSub/dashboard projections.
- Tenant/campaign identity should flow through enqueue helpers, worker args/meta, persisted rows, and telemetry consistently from one central normalization path.

</code_context>

<deferred>
## Deferred Ideas

- Broad per-target semantic override containers inside a single campaign.
- A second execution/result truth hierarchy parallel to `EvalRun` and `Score`.
- Per-tenant Oban tables or prefix-isolated queue infrastructure as the default path.
- Rich materialized dashboard projections beyond the campaign truth row before Phase 34 proves the need.
- Hosted experiment-service behaviors, external eval marketplace posture, or non-Phoenix control-plane drift.
- Advanced rerun/attempt lineage tables beyond the minimum needed for clear retry semantics in this phase.

</deferred>

---

*Phase: 33-distributed-evaluation-fan-out*
*Context gathered: 2026-05-21*
