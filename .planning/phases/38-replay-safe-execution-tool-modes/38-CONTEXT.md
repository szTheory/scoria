# Phase 38: Replay-Safe Execution & Tool Modes - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce replay-safe execution defaults for Scoria replay branches so operator debugging stays trustworthy even when the original run crossed approval-sensitive or externally effectful seams.

This phase decides how replay executes against existing workflow, connector, MCP, and approval seams. It does not broaden into replay diff UX, dataset promotion UX, or a second execution engine. It must preserve the existing durable run model from Phase 37 while making replay handling explicit per effect seam.

</domain>

<decisions>
## Implementation Decisions

### Replay taxonomy and durable truth
- **D-01:** Replay remains a run-level intent, not a run-wide effect outcome. `ai_workflow_runs.execution_mode` should converge on `live | replay` only. The current `historical_stubbed` run enum is the wrong abstraction and should be retired or treated as transitional compatibility state.
- **D-02:** Actual replay handling must be recorded at each risky seam as durable truth with a typed `replay_disposition`, not inferred from generic metadata. The canonical seam outcomes are:
  - `execute_live`
  - `historical_stub`
  - `blocked`
- **D-03:** Replay safety belongs at effect seams, not in LiveView-only logic and not in a second replay engine. The runtime, connector invocation, MCP executor, approvals, events, and audit rows must carry the contract.
- **D-04:** Public DTOs and operator surfaces should continue to show run lineage from the run row, but per-seam replay handling should come from checkpoint, event, approval, and audit evidence rather than pretending the entire replay run had one effect mode.

### Default replay policy by seam class
- **D-05:** Shift the default mapping left inside Scoria:
  - Pure/local/in-memory workflow logic -> `execute_live`
  - External reads -> `historical_stub` by default
  - External writes, `exec`, `admin`, destructive tools, and approval-sensitive seams -> never live by default during replay
- **D-06:** For materially effectful seams, use a mixed safe policy:
  - `historical_stub` if Scoria has durable original evidence and result shape sufficient to continue replay safely
  - `blocked` if evidence is missing, classification is ambiguous, or the replayed call differs materially from source truth
- **D-07:** Ambiguity fails closed. Scoria’s local classification boundary outranks remote connector hints or protocol metadata when deciding replay safety.
- **D-08:** Scoria should not silently fall through from stubbed replay to live execution when historical evidence is missing. Missing evidence is a `blocked` condition.

### Approval-sensitive replay behavior
- **D-09:** Historical approvals are evidence, not authority. Past approval rows must never grant live permission to a new replay branch by themselves.
- **D-10:** Approval-sensitive replay defaults to `historical_stub` only when the exact original effect is durably evidenced and the replay has not materially changed tool identity, arguments, subject, grant state, scopes, or policy boundary.
- **D-11:** If exact source evidence is unavailable, or the replay changes anything material, Scoria must stop again and require a fresh replay-scoped approval before any live side effect can occur.
- **D-12:** Replay approval is a new scope distinct from live-run approval. Persist replay-specific approval semantics explicitly instead of overloading the existing `replay_allowed` boolean as execution authority.
- **D-13:** Recommended replay evidence fields include:
  - `replay_disposition`
  - `source_run_id`
  - `source_checkpoint_id`
  - `source_step_id`
  - `source_approval_id`
  - `source_audit_outbox_event_id`
  - `args_fingerprint`
  - `subject_ref`
  - `required_scopes`
  - `policy_key`
  - `executed_live?`
  - replay approval scope or reason when applicable

### External-write and side-effect boundaries
- **D-14:** For `action_class in ["write", "exec", "admin"]` or `risk_level in ["high", "destructive"]`, Phase 38 should default to:
  - `historical_stub` if durable original effect evidence exists
  - `blocked` otherwise
- **D-15:** Scope escalation, re-auth flows, and other authority-expanding seams remain `blocked` in the default replay lane for this phase.
- **D-16:** Historical stubs require durable evidence strong enough to preserve operator trust:
  - stable tool identity (`local_tool_id` or tool ref)
  - original request summary, redacted
  - original result summary or durable outcome envelope
  - linked approval/policy/audit lineage where relevant
  - explicit marker that the replay used historical truth instead of issuing a live call
- **D-17:** If those evidence requirements are not met, Scoria must block rather than invent a partial stub or permit live execution.

### Escape hatch and replay-live posture
- **D-18:** There should be exactly one escape hatch in Phase 38: a replay-creation-time, run-scoped allowlist for specific previously known tools. No global ambient “live replay” toggle and no mid-run unsealing.
- **D-19:** The escape hatch must be persisted on the replay branch, for example in `replay_overrides["live_tool_allowlist"]`, and immutable once the replay run starts.
- **D-20:** A run-scoped allowlist does not bypass current Scoria policy or approval. A tool may move from `blocked` or `historical_stub` to `execute_live` only after:
  - the run-level allowlist authorizes that tool
  - current local policy checks pass
  - a fresh replay-scoped approval is granted for any approval-sensitive live effect
- **D-21:** Every live override consumption must be durably evidenced and operator-visible. The run should clearly show:
  - safe replay vs replay-live posture
  - which tools were allowlisted
  - whether any allowlisted live path was actually consumed
- **D-22:** Attach a replay idempotency key or equivalent stable dedupe token to any live replay effect so retries do not duplicate writes.

### Shift-left defaults and least-surprise posture
- **D-23:** Low-impact choices should be shifted left inside Scoria and future GSD flows:
  - default seam classification mapping
  - evidence minimum for stubbing
  - ambiguity-fails-closed behavior
  - operator badge taxonomy for `execute_live`, `historical_stub`, and `blocked`
  - no silent fallback from replay to live network/tool traffic
- **D-24:** User interruption should be reserved for materially consequential choices:
  - enabling replay-live overrides at all
  - selecting allowlisted tools for a replay branch
  - approving a replay-live action
  - stricter host-app overrides that convert stub-eligible tools to always-block

### the agent's Discretion
- Exact schema shape for `replay_disposition` and companion reason fields, provided run intent and seam outcome stay separate durable concepts.
- Whether replay seam truth is stored primarily in workflow events, audit outbox rows, invocation result envelopes, or a combination, provided downstream surfaces do not have to infer it from opaque metadata alone.
- Exact idempotency token format for replay-live overrides, provided duplicate live writes are prevented on retry.
- Exact UI copy and badges, provided operator surfaces clearly distinguish historical stubs from live execution and blocked seams.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 38 goal, success criteria, and dependency on Phase 37.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary, replay-safety constraint, and operator-trust posture for v1.9.
- `.planning/REQUIREMENTS.md` - `RPLY-02` and adjacent replay/dataset constraints that bound Phase 38.
- `.planning/STATE.md` - current milestone sequencing and locked strategic decisions.
- `.planning/METHODOLOGY.md` - decisive-defaults lens: shift low-impact choices left and only interrupt for blast-radius decisions.

### Prior locked Scoria decisions
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` - stable local tool identity, dual-plane policy, stateless-first invocation, and fail-closed posture.
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - workflow-owned approval truth, typed remediation posture, and operator evidence design.
- `.planning/phases/37-replay-lineage-branch-model/37-RESEARCH.md` - replay branch truth should be durable, explicit, and routed through the existing runtime seam.
- `.planning/phases/37-replay-lineage-branch-model/37-PATTERNS.md` - persisted lineage outranks envelopes; replay extends existing workflow truth rather than inventing a second engine.

### Current code surface
- `lib/scoria/workflows/run.ex` - current replay-related run fields and execution mode enum.
- `lib/scoria/workflows.ex` - replay branch creation, approval transitions, and workflow-owned durable evidence patterns.
- `lib/scoria/workflows/runtime.ex` - core workflow execution seam where replay-safe handling must attach.
- `lib/scoria/mcp/executor.ex` - policy-sensitive MCP/tool execution seam and audit envelope precedent.
- `lib/scoria/connectors/invocation.ex` - local tool classification, grant checks, approval gating, and typed blocked outcomes.
- `lib/scoria/observe/approval.ex` - durable approval shape; current `replay_allowed` boolean is insufficient as replay-live authority.
- `lib/scoria/runtime.ex` - public replay entrypoint and run inspection APIs.
- `lib/scoria/runtime/run_summary.ex` - public run summary projection that should keep run intent explicit.
- `lib/scoria/runtime/run_detail.ex` - public run detail projection that should expose replay lineage and later seam outcomes.
- `test/scoria/workflows/replay_branch_test.exs` - proves replay branches are new runs and preserve source-run immutability.
- `test/scoria/connectors/invocation_test.exs` - proves current auth/scope/approval blocking posture before outbound execution.
- `test/scoria/workflows/integration_test.exs` - existing invariant that retries must not silently replay persisted side-effect boundaries.

### Product and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - Scoria’s trace-first, operator-grade, Phoenix-native project vision.
- `prompts/phoenix-ai-lib-deep-research.md` - adjacent ecosystem lessons: durable execution, trace->eval loop, tool governance, and safe defaults.
- `prompts/scoria-brand-book-deep-research.md` - calm operator-grade evidence posture; replay should feel inspectable, not magical.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, embedded dashboards, Ecto-native truth, and operator-first DX.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows.create_replay_branch/3` already persists replay lineage and seeds replay-start checkpoint/event truth.
- `Scoria.Workflows.mark_waiting_for_approval/3` and `approve/3` already show the transactional pattern for durable approval and audit evidence updates.
- `Scoria.Connectors.Invocation` already classifies tools by `action_class`, `risk_level`, grant state, and approval need before outbound execution.
- `Scoria.MCP.Executor` already centralizes policy-sensitive tool execution, audit outbox creation, and budget/breaker evidence at the seam where live effects occur.
- `Scoria.Runtime.RunSummary` and `RunDetail` already provide the right public DTO surfaces for replay lineage and later seam-mode projection.

### Established Patterns
- Ecto rows are durable truth; UI, telemetry, and envelopes are projections or evidence of that truth.
- High-risk actions must be explicitly classified and evidenced before external work is treated as complete.
- Original run history is immutable; replay creates a new branch run that carries provenance explicitly.
- Embedded operator UX should show calm, inspectable evidence rather than hidden mutable state or magical fallthrough behavior.

### Integration Points
- Replay-safe resolution should sit in workflow runtime and connector/MCP seams, not in LiveView-only code.
- Per-seam `replay_disposition` truth should project into workflow events, approvals, audit outbox rows, and public DTOs.
- Replay-live overrides should be persisted on the replay run and consumed by connector/MCP policy resolution rather than ad hoc socket state.
- Phase 39 can later read these seam-level replay facts directly for operator diff/provenance UX.

</code_context>

<specifics>
## Specific Ideas

- Replay should feel like Temporal-style branch truth with Phoenix/Ecto ergonomics, not like a cassette-testing framework pretending to be an operator control plane.
- Borrow the safe-default lesson from VCR/ReqCassette and the explicit-approval lesson from GitHub/Slack, but keep Scoria’s vocabulary operator-facing:
  - replay run
  - replay disposition
  - historical stub
  - blocked
  - live override used
- The coherent operator story is:
  - branch from durable checkpoint truth
  - run a safe replay by default
  - inspect exactly which seams reran, stubbed, or blocked
  - opt into a narrowly scoped replay-live branch only when the operator deliberately wants to prove a remediation
- `replay_allowed` as a bare boolean is not expressive enough. Phase 38 should move toward explicit replay disposition and replay approval scope instead.

</specifics>

<deferred>
## Deferred Ideas

- A stricter Temporal-like deterministic sandbox or second replay-specific execution engine - out of scope for Phase 38 and would risk product-shape drift.
- Mid-run “unseal this step” command-bus UX - out of scope; too surprising and too hard to audit cleanly.
- Broad global config that makes replay-live ambient for many tools - out of scope; too easy to forget and too wide a blast radius for the default product posture.

</deferred>

---

*Phase: 38-replay-safe-execution-tool-modes*
*Context gathered: 2026-05-22*
