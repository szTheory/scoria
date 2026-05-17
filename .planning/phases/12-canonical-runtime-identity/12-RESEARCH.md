# Phase 12: Canonical Runtime Identity - Research

**Generated:** 2026-05-13
**Phase:** 12
**Requirements:** `IDEN-01`, `IDEN-02`

## User Constraints (from CONTEXT.md) [VERIFIED: .planning/phases/12-canonical-runtime-identity/12-CONTEXT.md]

### Locked Decisions
- Introduce one canonical runtime envelope, preferably `Scoria.Identity`, as the public noun for actor, tenant, and session identity.
- Persist `actor_id`, `tenant_id`, and `session_id` as first-class durable columns on the rows that define runtime truth.
- Treat metadata as extensible secondary context; metadata must not override canonical identity columns.
- Keep run-root identity immutable after run creation; execution-time adjustments belong in a separate transient execution-context concept.
- Keep Phoenix, Plug, and LiveView helpers at the edge as adapters into the canonical envelope instead of making request-scoped framework state the durable contract.

### Agent Discretion
- Exact module naming and helper API shape for edge adapters.
- Exact rollout order for which durable rows receive all identity columns first, provided run truth plus approval and evidence seams stay coherent.
- Exact shape of any transient execution-context sidecar, provided it stays clearly distinct from root identity.

## Phase Requirements [VERIFIED: .planning/REQUIREMENTS.md]

- `IDEN-01`: A Scoria run can carry explicit actor, tenant, and session identifiers through its canonical runtime entrypoint.
- `IDEN-02`: Workflow, approval, telemetry, and audit paths preserve the same actor, tenant, and session identity without requiring app-specific internal conventions.

## Summary

Phase 12 is mostly a boundary-correction phase, not a greenfield feature. The repo already has the durable workflow substrate, approval lifecycle, MCP execution seam, and telemetry identity projection, but identity currently drifts across them:

- workflow runs only persist `session_id` and `root_role_id`
- approvals persist `session_id` plus an overloaded string `run_id`
- runtime and MCP seams rely on ad hoc context maps for `tenant_id` and `actor_id`
- telemetry identity defaults missing values to `"system"` and does not project actor or session identity
- Plug and LiveView edges derive actor identity from framework-specific assigns and fallback chains

The planning implication is that Phase 12 should not try to solve public API ergonomics end-to-end. It should establish a single canonical identity envelope, make workflow runs the durable source of truth for it, propagate it into approval and execution seams, and align telemetry and audit producers with that same source. A clean Phase 12 split is:

1. define the identity noun and persistence contract
2. wire propagation through workflow and approval seams
3. align telemetry and audit projection plus verification coverage

## Current Code Findings

### `lib/scoria/workflows/run.ex`
- `Scoria.Workflows.Run` persists `session_id` and `root_role_id` but has no first-class `actor_id` or `tenant_id` fields.
- `metadata` is available and could hide identity today, which conflicts with the context decision that metadata must remain secondary.
- `create_run/1` therefore needs to become the normalization and stamping seam for canonical identity.

### `lib/scoria/workflows.ex`
- `create_run/1` writes the run row, initial checkpoint, and initial event in one transaction, making it the right root-identity insertion point.
- `mark_waiting_for_approval/3` builds approval attrs and audit evidence from ad hoc attrs maps with defaults like `tenant_id || \"system\"`.
- `approve/3` reconstructs attribution from the approval row plus the latest request audit event; `approval_decision_context/3` falls back to `approval.session_id` as actor identity, which is exactly the footgun Phase 12 should remove.
- The workflow module is already the durable truth boundary, so identity propagation should happen here instead of in LiveView or MCP callers.

### `lib/scoria/workflows/runtime.ex`
- The runtime seam consumes `budget_context` and `breaker_context` maps, pulling `tenant_id` and `actor_id` from those transient maps rather than from durable run truth.
- This is the right place to separate immutable root identity from execution-context overlays: the runtime can derive inherited identity from `run`, while keeping cost/tool/trace attrs in transient context.

### `lib/scoria/observe/approval.ex`
- Approvals store `session_id`, `run_id`, `workflow_run_id`, `step_id`, and `checkpoint_id`.
- `run_id` is a string field while `workflow_run_id` is the binary-id durable run ref, which is confusing and should be clarified in planning.
- No first-class `actor_id` or `tenant_id` exists today, so approval attribution depends on request-time attrs and audit-row lookups.

### `lib/scoria/mcp/executor.ex`
- MCP execution accepts an arbitrary `context` map and threads `tenant_id`, `actor_id`, `run_id`, and `step_id` through budget, audit, breaker, and telemetry paths.
- This seam should continue to accept context, but Phase 12 needs a clear contract for which fields come from canonical run identity versus transient execution-only metadata.

### `lib/scoria/mcp/router.ex`
- The Plug boundary assigns `conn.assigns[:current_actor]` directly into `Executor.execute/4`.
- That is acceptable only as an edge adapter; the router should not remain the de facto identity contract.
- Phase 12 planning should reserve helper/adaptor work here, but not turn Plug structs or assign shapes into durable internals.

### `lib/scoria/sre/telemetry_identity.ex`
- The telemetry identity builder is already the canonical low-cardinality projector for operational telemetry, but it defaults missing identity to `"system"` and only groups on tenant-oriented operational dimensions.
- It intentionally omits actor identity to stay low-cardinality, which is compatible with Phase 12 as long as actor and session become correlation refs or durable evidence fields rather than grouping labels.
- Planning should explicitly preserve the low-cardinality telemetry posture while changing the source of `tenant_id` and run refs to the canonical identity envelope.

### Current UI / host-app seams
- `lib/scoria_web/live/orchestrator_live.ex` derives `actor_id` from `session["actor_id"] || session["user_id"] || session["session_id"] || "operator"` and `tenant_id` from `session["tenant_id"] || "default"`.
- Those fallbacks are useful examples for future helpers, but they are not acceptable as durable truth rules.

## Architectural Responsibility Map

| Concern | Best Owner | Why |
|---|---|---|
| Normalize host-app identity into one canonical struct | `Scoria.Identity` plus helper constructors | Keeps edge adapters thin and gives all downstream seams one noun |
| Persist immutable root identity | `Scoria.Workflows.create_run/1` and `Scoria.Workflows.Run` | Run creation already owns durable root truth |
| Inherit identity into approval lifecycle | `Scoria.Workflows` and `Scoria.Observe.Approval` | Approval rows and audit evidence are created here transactionally |
| Distinguish root identity from transient execution attrs | `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor` | They already own execution-time budget, breaker, and audit contexts |
| Project canonical identity into low-cardinality telemetry | `Scoria.SRE.TelemetryIdentity` | This module already centralizes telemetry projection rules |
| Adapt Plug / LiveView assigns into the canonical identity contract | `Scoria` or `Scoria.Identity` helper APIs | Keeps framework-specific extraction at the edge |

## Recommended Implementation Shape

### 1. Introduce one canonical identity envelope
- Add a dedicated public struct such as `Scoria.Identity` with first-class fields for `actor_id`, `tenant_id`, `session_id`, and optional `metadata`.
- Provide normalization helpers that accept a struct, plain map, and convenience sugar such as top-level `actor`, `tenant`, or `session` fields and convert them into the canonical envelope before workflow code runs.
- Keep the struct boring and explicit; do not introduce protocols or host-app struct coupling in this phase.

### 2. Make workflow runs the durable source of truth
- Add `actor_id` and `tenant_id` columns to `ai_workflow_runs`, keeping existing `session_id`.
- Update `Scoria.Workflows.Run` and `Scoria.Workflows.create_run/1` so every run stores the canonical envelope once and initial checkpoints/events snapshot that same root identity.
- Keep `metadata` for non-canonical labels and host-app context, but treat it as additive only.

### 3. Persist enough identity on approval rows to remove fallback reconstruction
- Add first-class `actor_id` and `tenant_id` columns to `ai_approvals`, preserving `session_id`.
- Stop using `approval.session_id` as an actor fallback in `approval_decision_context/3`.
- Preserve `workflow_run_id` as the join back to run truth; Phase 12 can also evaluate whether the older string `run_id` field should be retained only for compatibility, renamed later, or formally documented as a host reference.

### 4. Separate root identity from execution context
- Runtime and MCP code should inherit canonical identity from the run or normalized execution input, then merge transient attrs like `trace_id`, `provider_ref`, `policy_key`, cost estimates, or tool metadata separately.
- Do not mutate canonical identity mid-run. If a step needs local variation, store it in an execution-context map with explicit naming.

### 5. Align telemetry and audit producers with canonical identity without increasing cardinality
- `TelemetryIdentity` should keep low-cardinality grouping labels focused on tenant and operational dimensions.
- Actor and session should flow as durable run or approval fields and, where necessary, audit refs or event metadata rather than grouping labels.
- Audit, approval, budget, and MCP producers should stop inventing their own fallback precedence and instead consume normalized canonical identity.

### 6. Add edge adapters, not edge-owned truth
- Phase 12 should likely include a small public helper surface for building identity from Plug or LiveView session data.
- The adapter outputs must be the canonical struct; they should not leak `Plug.Conn`, socket assigns, or raw session shapes into durable internals.

## Alternatives Considered

### Store identity only in metadata maps
Rejected because it preserves the exact ambiguity this phase exists to remove, makes filtering and indexing weaker, and encourages each seam to reinterpret keys independently.

### Create a normalized identity table and reference it from runs and approvals
Rejected for this phase because it adds join weight and lifecycle complexity without improving the embedded Phoenix adoption story. The context explicitly rules this out.

### Keep telemetry identity completely separate from runtime identity
Rejected because it would preserve drift between runtime truth, audit evidence, and operator-visible telemetry. The better boundary is shared source identity with different projections for low-cardinality telemetry versus durable evidence.

## Anti-Patterns to Avoid

- Using `session_id` as a proxy actor id in approval or workflow decision paths.
- Continuing to default missing tenant or actor silently to `"system"` deep inside workflow and MCP internals instead of normalizing earlier.
- Treating `Plug.Conn`, LiveView sockets, or host-app structs as durable runtime identity carriers.
- Letting telemetry grouping labels absorb actor or session ids and blow up cardinality.
- Mutating run-root identity after the run has started.

## Test Strategy

### Identity normalization and schema tests
- Add focused unit tests for the new identity struct and normalization helpers.
- Extend `test/scoria/workflows_test.exs` or a new identity-focused workflow test to prove run creation persists `actor_id`, `tenant_id`, and `session_id`.

### Workflow and approval propagation tests
- Extend `test/scoria/workflows/runtime_test.exs` and `test/scoria/workflows/integration_test.exs` to prove approvals, checkpoints, and resume paths inherit the same root identity.
- Extend `test/scoria/sre/audit_outbox_test.exs` so approval-request and approval-decision evidence carries canonical actor, tenant, and session lineage from run truth.

### MCP and telemetry projection tests
- Extend `test/scoria/mcp/executor_test.exs` and `test/scoria/mcp/executor_telemetry_test.exs` to prove executor contexts use normalized canonical identity plus transient execution metadata.
- Extend `test/scoria/workflows/runtime_telemetry_test.exs` or `test/scoria/sre/telemetry_test.exs` to prove telemetry projection remains low-cardinality while sourcing tenant and run refs from canonical identity.

### Migration and query verification
- Add migration tests or focused assertions proving new run and approval indexes exist for operator filtering on `tenant_id`, `actor_id`, and `session_id`.

## Validation Architecture

### Test Framework
- Framework: ExUnit
- Quick run command: `MIX_ENV=test mix test test/scoria/workflows_test.exs test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs`
- Full suite command: `MIX_ENV=test mix test`
- Estimated quick runtime: under 30 seconds on the current codebase

### Phase Requirements -> Test Map
- `IDEN-01`
  - canonical identity struct normalization tests
  - run creation persistence tests
  - host-adapter helper tests for Plug/LiveView/session input
- `IDEN-02`
  - workflow approval propagation tests
  - audit outbox lineage tests
  - runtime and MCP telemetry projection tests

### Wave 0 Gaps
- No existing dedicated runtime identity module or tests exist yet.
- Existing approval and runtime suites assume partial identity and will need updated fixtures once canonical fields are introduced.

## Risks and Pitfalls

- Migration fallout: adding columns to `ai_workflow_runs` and `ai_approvals` will touch factories, fixtures, and old tests quickly.
- Backward compatibility: existing callers may still pass top-level `tenant_id` and `actor_id`; plan slices should preserve compatibility by normalizing them instead of breaking them abruptly.
- Telemetry overreach: if actor or session become labels, SRE cardinality will regress.
- Approval drift: if approval rows do not gain canonical fields, decision attribution will keep reconstructing identity indirectly from request audit rows.

## Recommended Plan Breakdown

### Plan 12-01: Identity Envelope and Public Runtime Nouns
- Create the canonical identity module and normalization helpers.
- Add run-schema/migration changes to persist canonical identity at the root workflow seam.
- Add focused unit and workflow tests for run creation and normalization compatibility.

### Plan 12-02: Workflow and Approval Identity Propagation
- Add approval-schema/migration changes for canonical identity fields.
- Update workflow, runtime, and approval seams to inherit root identity without fallback chains.
- Expand workflow, integration, and audit tests to prove propagation and immutability.

### Plan 12-03: Telemetry and Audit Identity Alignment
- Align telemetry and audit producers with canonical identity as their source while preserving low-cardinality projection rules.
- Update runtime and MCP telemetry tests plus audit evidence assertions.
- Add verification notes proving operator-visible evidence, telemetry refs, and approval lineage all agree on run identity.

## RESEARCH COMPLETE
