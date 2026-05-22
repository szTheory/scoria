# Phase 38: Replay-Safe Execution & Tool Modes - Research

**Researched:** 2026-05-23
**Domain:** Replay-safe workflow execution across workflow runtime, connector invocation, MCP execution, approvals, and audit seams. [VERIFIED: `.planning/ROADMAP.md`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, codebase inspection]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- A stricter Temporal-like deterministic sandbox or second replay-specific execution engine - out of scope for Phase 38 and would risk product-shape drift.
- Mid-run “unseal this step” command-bus UX - out of scope; too surprising and too hard to audit cleanly.
- Broad global config that makes replay-live ambient for many tools - out of scope; too easy to forget and too wide a blast radius for the default product posture.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RPLY-02 | Replay execution defaults to safe modes that block or stub external-write and approval-sensitive effects while preserving explicit replay provenance. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use the existing workflow runtime and connector/MCP seams, add seam-level `replay_disposition` truth plus replay-scoped approval semantics, and require durable evidence before any historical stub or live override is allowed. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria/observe/approval.ex`] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No repo-root `CLAUDE.md` or `AGENTS.md` file is present, and no `.claude/skills/` or `.agents/skills/` directory is present, so this phase is constrained by the planning artifacts and existing code only. [VERIFIED: repo inspection]

## Summary

Scoria already has the correct architectural seam for this phase: replay runs are durable workflow rows with explicit lineage, connector invocation already classifies tool risk before outbound work, MCP execution already emits policy/audit evidence, and approvals are durable Ecto rows with optimistic locking. [VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/workflows.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex`]

The planning problem is therefore not “how do we build replay,” but “where do we add seam-level replay truth so the existing engine fails closed.” [VERIFIED: `.planning/ROADMAP.md`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/runtime.ex`] The codebase still exposes a transitional run enum `live | replay | historical_stubbed`, still defaults remote approval requests to `replay_allowed: true`, and does not persist a typed seam disposition on checkpoints, events, approvals, or audit rows. [VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/workflows.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/observe/approval.ex`]

The clean Phase 38 plan is to keep `execution_mode` as run intent only, resolve replay safety inside workflow runtime plus connector/MCP seams, and persist the outcome at every effect boundary so Phase 39 can read operator-visible replay facts directly instead of inferring from metadata. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `.planning/phases/37-replay-lineage-branch-model/37-PATTERNS.md`, `lib/scoria/runtime/run_detail.ex`]

**Primary recommendation:** Implement a shared replay-disposition resolver in the runtime/connector/MCP seam, persist its output on workflow event plus audit/approval evidence rows, and treat missing historical evidence as `blocked`, never as implicit permission to go live. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`, `lib/scoria/workflows/runtime.ex`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Replay run intent persistence (`execution_mode`, source lineage, override allowlist) | Database / Storage | API / Backend | Run rows are already Scoria’s durable truth and Phase 37 stored replay lineage there. [VERIFIED: `lib/scoria/workflows/run.ex`, `priv/repo/migrations/20260523000100_add_replay_lineage_to_workflow_runs.exs`] |
| Seam-level replay safety classification (`execute_live`, `historical_stub`, `blocked`) | API / Backend | Database / Storage | The decision must happen before outbound work in runtime, connector, and MCP execution seams, then be persisted as evidence. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`] |
| Historical-stub evidence lookup and validation | Database / Storage | API / Backend | Stub eligibility depends on prior durable checkpoint/event/approval/audit facts, not UI state. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex`] |
| Replay-scoped approval authority | Database / Storage | API / Backend | Approval rows are durable truth today, but Phase 38 must stop overloading `replay_allowed` and add explicit replay scope semantics. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/observe/approval.ex`, `lib/scoria/workflows.ex`] |
| Replay-live idempotency / dedupe | API / Backend | Database / Storage | The execution seam must attach a stable key before live effects, and persistence must enforce dedupe across retries. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/step.ex`, `lib/scoria/sre/audit_outbox_event.ex`; CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07] |
| Operator projection of replay facts | Frontend Server (SSR) | Browser / Client | LiveView should read typed replay facts from DTOs and evidence rows rather than own policy logic. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/runtime/run_detail.ex`, `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/live/orchestrator_live.ex`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `3.13.5` in `mix.lock`; Hex latest `3.14.0` published 2026-05-19. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info ecto_sql`] | Durable schema changes, transactions, and row-level truth for runs, steps, approvals, checkpoints, events, and audit rows. [VERIFIED: `lib/scoria/workflows/*.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex`] | The phase needs transactional multi-row updates plus optimistic locking, which Ecto documents directly. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html, CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| `phoenix` | `1.8.7` published 2026-05-06. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info phoenix`] | Existing PubSub and LiveView host surface for workflow/operator projections. [VERIFIED: `lib/scoria/workflows.ex`, `lib/scoria_web/live/*`] | This phase should project replay facts through existing Phoenix surfaces instead of introducing a second operator surface. [VERIFIED: `.planning/PROJECT.md`, `lib/scoria_web/live/workflow_live/show.ex`] |
| `phoenix_live_view` | `1.1.30` published 2026-05-05; `1.2.0-rc` exists but the repo is locked to `1.1.30`. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info phoenix_live_view`] | Workflow and orchestrator UI projections for replay lineage and later seam facts. [VERIFIED: `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/live/orchestrator_live.ex`] | The phase only needs projection changes on top of durable DTOs, which fits the current LiveView surface. [VERIFIED: `lib/scoria/runtime/run_detail.ex`, `test/scoria_web/live/workflow_live_test.exs`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | `2.22.1` published 2026-04-30. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info oban`] | Not required for the core seam rewrite, but available if the plan chooses any async verification or audit backfill follow-up. [VERIFIED: `mix.lock`, project state] | Use only for follow-on async work; do not turn replay disposition itself into a queued side channel. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `.planning/METHODOLOGY.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing workflow runtime + connector + MCP seams | A second replay-only execution engine | Rejected because Phase 38 is explicitly scoped to preserve the existing durable run model and avoid a second engine. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `.planning/ROADMAP.md`] |
| Typed Ecto fields plus typed event/audit evidence | Metadata-only replay annotations | Metadata-only storage would force downstream inference and contradict the locked requirement for durable seam truth. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/observe/approval.ex`] |
| Replay-scoped approval semantics | Reusing `replay_allowed` as live authority | Current boolean shape is not expressive enough and is explicitly called out as insufficient by the locked decisions. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/observe/approval.ex`, `lib/scoria/workflows.ex`] |

**Installation:**
```bash
mix deps.get
```
No new dependency is required by the research recommendations; the phase should land on the existing Phoenix/Ecto stack. [VERIFIED: `mix.exs`, `mix.lock`]

**Version verification:** `mix.lock` currently pins `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, `ecto_sql 3.13.5`, and `oban 2.22.1`; Hex metadata was checked on 2026-05-23 to confirm current publish dates and identify that only `ecto_sql` has a newer release (`3.14.0`) that is outside this phase’s scope. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql`, `mix hex.info oban`]

## Architecture Patterns

### System Architecture Diagram

The diagram below reflects the current seam ownership and the recommended Phase 38 insertion point for replay safety. [VERIFIED: `lib/scoria/runtime.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`]

```text
Replay branch request
  |
  v
Scoria.Runtime.replay_run/3
  |
  v
Scoria.Workflows.create_replay_branch/3 ---> ai_workflow_runs (run intent: live|replay)
  |
  v
Scoria.Workflows.Runtime.execute_step/2
  |
  +--> Pure/local handler ---------------------------> complete_step (execute_live)
  |
  +--> Connector invocation seam
  |      |
  |      +--> local classification + grant/policy checks
  |      +--> replay disposition resolver
  |             |
  |             +--> historical evidence found ------> historical_stub + durable event/audit/approval evidence
  |             +--> missing/changed/ambiguous ------> blocked + durable event/audit/approval evidence
  |             +--> allowlisted + approved + policy ok --> execute_live + replay idempotency key
  |
  +--> MCP executor seam
         |
         +--> audit/budget/breaker envelope
         +--> same replay disposition resolver contract
```

### Recommended Project Structure

```text
lib/scoria/
├── workflows/                 # durable run, step, checkpoint, event, approval transitions
├── connectors/                # local tool classification, grants, replay-sensitive connector gating
├── mcp/                       # outbound tool execution seam and policy/audit envelope
├── runtime/                   # public DTOs and replay branch entrypoints
└── sre/                       # audit outbox dedupe and durable evidence rows

lib/scoria_web/
├── live/workflow_live/        # workflow operator projection
└── live/orchestrator_live.ex  # trace-facing replay projection

test/scoria/
├── workflows/                 # replay branch and runtime seam tests
├── connectors/                # invocation seam tests
└── workflows/integration_test.exs
```
This layout already exists and should be extended instead of introducing a replay-only subtree. [VERIFIED: repo tree, codebase inspection]

### Pattern 1: Shared Replay Disposition Resolver

**What:** One resolver decides `execute_live | historical_stub | blocked` from run intent, tool classification, historical evidence, approval scope, and allowlist state. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

**When to use:** Call it before any connector or MCP seam that can cross an external or approval-sensitive boundary. [VERIFIED: `.planning/ROADMAP.md`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/mcp/executor.ex`]

**Example:**
```elixir
# Source pattern: lib/scoria/connectors/invocation.ex, lib/scoria/mcp/executor.ex,
# lib/scoria/workflows/runtime.ex
case resolve_replay_disposition(run, local_tool, args, context, historical_evidence) do
  {:execute_live, replay_meta} ->
    execute_live_with_idempotency(tool_module, args, Map.merge(context, replay_meta))

  {:historical_stub, replay_meta, stubbed_result} ->
    persist_replay_evidence(run, step, replay_meta)
    {:ok, stubbed_result}

  {:blocked, replay_meta} ->
    persist_replay_evidence(run, step, replay_meta)
    {:error, %{status: :replay_blocked, replay_disposition: :blocked}}
end
```
The resolver should return durable evidence input, not just a branching decision, because downstream DTOs must not reconstruct replay truth from opaque maps. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/runtime/run_detail.ex`]

### Pattern 2: Approval Truth Separate from Replay Authority

**What:** Keep approval request/decision rows, but add replay-specific scope semantics instead of using `replay_allowed` as a blanket authority flag. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/observe/approval.ex`]

**When to use:** Any time a replayed effect is approval-sensitive or a live override is requested. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/connectors/invocation.ex`, `lib/scoria/connectors/auth.ex`]

**Example:**
```elixir
# Source pattern: lib/scoria/workflows.ex, lib/scoria/observe/approval.ex
%{
  blocker_kind: "remote_write",
  replay_disposition: "blocked",
  replay_scope: "live_override",
  source_approval_id: source_approval.id,
  source_audit_outbox_event_id: source_audit.id,
  args_fingerprint: args_fingerprint,
  required_scopes: local_tool.required_scopes
}
```
The important constraint is semantic separation, not the exact field names. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

### Anti-Patterns to Avoid

- **Run-wide historical stub mode:** The repo still accepts `historical_stubbed` on `Run`, but the locked Phase 38 model requires seam-level disposition instead. [VERIFIED: `lib/scoria/workflows/run.ex`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
- **UI-owned replay safety:** LiveView already renders replay lineage, but the context explicitly says safety belongs in runtime, connector, MCP, approval, event, and audit seams. [VERIFIED: `lib/scoria_web/live/workflow_live/show.ex`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
- **Silent stub-to-live fallback:** Missing historical evidence must become `blocked`, not implicit permission. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
- **Boolean approval authority:** `replay_allowed` exists today, but planning should treat it as transitional compatibility only. [VERIFIED: `lib/scoria/observe/approval.ex`, `lib/scoria/workflows.ex`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Replay execution engine | A second dispatcher or replay-only runtime | `Scoria.Runtime.replay_run/3` plus `Scoria.Workflows.Runtime.execute_step/2` and existing reconciler flow | Phase 37 already established replay as a new run routed through the existing engine. [VERIFIED: `lib/scoria/runtime.ex`, `test/scoria/workflows/replay_branch_test.exs`, `.planning/phases/37-replay-lineage-branch-model/37-RESEARCH.md`] |
| Transactional evidence fanout | Ad hoc chained inserts and updates | `Ecto.Multi` or `Repo.transaction` around run/step/checkpoint/event/approval/audit writes | Ecto documents Multi for grouped repo operations and the repo already uses both transaction styles successfully. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html, VERIFIED: `lib/scoria/workflows.ex`] |
| Concurrency control for evidence rows | Manual “last writer wins” updates | Existing `optimistic_lock(:lock_version)` on run and approval rows | Ecto’s optimistic lock raises on stale writes and the repo already applies it on these durable truths. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html, VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/observe/approval.ex`] |
| Replay-live retry dedupe | In-memory retry guards | Persisted idempotency key / fingerprint plus durable unique enforcement | HTTP idempotency guidance expects a stable key plus request fingerprinting for retry safety, and Scoria already has durable dedupe fields such as `dedupe_key` and `idempotency_key`. [CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07, VERIFIED: `lib/scoria/workflows/step.ex`, `lib/scoria/sre/audit_outbox_event.ex`] |

**Key insight:** Scoria already has durable workflow, approval, and audit primitives; the phase risk is inventing a parallel replay control plane instead of extending those primitives with typed replay facts. [VERIFIED: `lib/scoria/workflows.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex`, `.planning/PROJECT.md`]

## Common Pitfalls

### Pitfall 1: Treating `execution_mode` as seam truth

**What goes wrong:** A replay run that contains both pure/local reruns and blocked or stubbed tool calls gets flattened into one misleading mode. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Why it happens:** `Run` still allows `historical_stubbed` as a run-level enum, and current DTOs project replay lineage from the run row only. [VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/runtime/run_detail.ex`]
**How to avoid:** Keep run intent as `live | replay`, and persist seam disposition on effect evidence rows. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Warning signs:** New code checks only `run.execution_mode` to decide whether a live tool call is safe. [VERIFIED: `lib/scoria/workflows/run.ex`; ASSUMED: future bad implementation pattern]

### Pitfall 2: Reusing historical approval rows as live authority

**What goes wrong:** Replay branches inherit the authority of an old approval even though the new branch may have different arguments, scopes, or policy context. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Why it happens:** Current approval rows expose `replay_allowed`, and current remote approval helpers default it to `true`. [VERIFIED: `lib/scoria/observe/approval.ex`, `lib/scoria/workflows.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/connectors/invocation.ex`]
**How to avoid:** Persist replay-specific approval scope and compare exact source evidence before allowing a historical stub or live override. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Warning signs:** Planner tasks mention “reuse existing approval” without a new replay approval row or evidence diff. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`; ASSUMED: future bad implementation pattern]

### Pitfall 3: Falling through to live when historical evidence is incomplete

**What goes wrong:** Replay executes a real side effect simply because Scoria cannot find the original result envelope or approval lineage. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Why it happens:** Existing step completion and event payloads have no typed replay disposition field yet, so a naive implementation may rely on “best effort” metadata lookups. [VERIFIED: `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/workflows.ex`]
**How to avoid:** Make missing evidence a first-class `blocked` outcome and persist the reason. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
**Warning signs:** A branch in connector or MCP code says “if no stub, just execute.” [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`; ASSUMED: future bad implementation pattern]

## Code Examples

Verified patterns from official sources and current repo seams:

### Transactional seam evidence write

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:approval, approval_changeset)
|> Ecto.Multi.run(:audit, fn repo, %{approval: approval} ->
  {:ok, insert_audit(repo, approval)}
end)
|> Repo.transact()
```
`Ecto.Multi` groups dependent repo operations and aborts later steps when a `run/3` callback returns `{:error, value}`. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Optimistic locking on durable authority rows

```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3
approval
|> Ecto.Changeset.cast(attrs, [:status, :lock_version])
|> Ecto.Changeset.optimistic_lock(:lock_version)
```
This is already the repo pattern on `Run` and `Approval`, and it should remain in any replay approval authority rewrite. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html, VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/observe/approval.ex`]

### Idempotent replay-live effect contract

```elixir
# Source idea: IETF HTTP Idempotency-Key draft + existing Scoria dedupe fields
context
|> Map.put(:replay_idempotency_key, replay_key)
|> Map.put(:args_fingerprint, args_fingerprint)
|> execute_live_effect()
```
The key should identify retries of the same replay-live request, and the fingerprint should detect payload mismatch. [CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Run-wide `historical_stubbed` execution enum | Run intent `live | replay` plus seam-level `replay_disposition` | Locked in Phase 38 context on 2026-05-22. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] | Keeps replay lineage on the run row while making actual effect handling inspectable per seam. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] |
| Bare `replay_allowed` boolean | Replay-scoped approval semantics with exact source evidence | Locked in Phase 38 context on 2026-05-22. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] | Prevents old approvals from silently granting live replay authority. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] |
| Opaque metadata inference | Typed checkpoint/event/approval/audit evidence | Phase 38 requirement and success criteria. [VERIFIED: `.planning/ROADMAP.md`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] | Phase 39 can project replay facts directly without brittle metadata parsing. [VERIFIED: `.planning/phases/37-replay-lineage-branch-model/37-PATTERNS.md`, `lib/scoria/runtime/run_detail.ex`] |

**Deprecated/outdated:**
- `historical_stubbed` as a primary run-level taxonomy is outdated for this milestone and should be retired or treated as transitional compatibility only. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/run.ex`]
- `replay_allowed` as execution authority is outdated for this milestone because it cannot express replay scope, evidence match, or live-override consumption. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/observe/approval.ex`]

## Assumptions Log

All material claims in this research were verified against the repo, Hex registry output, or official docs. [VERIFIED: research session artifacts]

## Open Questions

1. **Where should `replay_disposition` live first: workflow events, audit rows, approval rows, or result envelopes?**
   - What we know: The user left schema placement to agent discretion, but downstream surfaces must not infer from opaque metadata. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
   - What's unclear: Which table becomes the canonical source for seam disposition versus supporting projections. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
   - Recommendation: Plan for one canonical write path that updates workflow event plus whichever durable row already “owns” that seam, then project outward from there. [VERIFIED: `lib/scoria/workflows/event.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex`]

2. **How should Scoria detect a “materially changed” replayed call?**
   - What we know: The context explicitly names tool identity, arguments, subject, scopes, grant state, and policy boundary as material. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
   - What's unclear: Exact fingerprint algorithm and which redacted fields belong in the durable comparison. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
   - Recommendation: Plan a dedicated comparator module and store both a stable fingerprint and a redacted comparison summary for operator evidence. [CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07, VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

3. **How should historical stubs feed step completion without pretending a live call happened?**
   - What we know: Current `complete_step/3` persists `result_envelope` and appends `step_completed` evidence. [VERIFIED: `lib/scoria/workflows.ex`]
   - What's unclear: Whether the stub marker belongs in the result envelope, event payload, checkpoint snapshot, or all three. [VERIFIED: `lib/scoria/workflows.ex`, `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`]
   - Recommendation: Plan for a single replay evidence envelope shape reused by completed, blocked, and stubbed seam outcomes. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`; ASSUMED: exact module name/shape remains to be chosen]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile, migrations, tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Dependency, test, migration commands | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | Repo-backed workflow/approval/audit persistence | ✓ [VERIFIED: `psql --version`, `pg_isready`] | `psql 14.17`; server accepting connections on local `5432`. [VERIFIED: `psql --version`, `pg_isready`] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via `ExUnit.start/1`. [VERIFIED: `test/test_helper.exs`] |
| Config file | `test/test_helper.exs`. [VERIFIED: `test/test_helper.exs`] |
| Quick run command | `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs` [VERIFIED: existing test file paths] |
| Full suite command | `mix test` [VERIFIED: Mix/ExUnit project layout] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RPLY-02 | Replay blocks or stubs remote write/exec/admin seams by default. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`] | integration | `mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs` | Partial: existing files exist, but replay-safe cases need new examples. [VERIFIED: `test/scoria/connectors/invocation_test.exs`, `test/scoria/workflows/integration_test.exs`] |
| RPLY-02 | Replay approval-sensitive seams require replay-scoped authority and never reuse old approval as live authority. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] | integration | `mix test test/scoria/connectors/invocation_test.exs` | Partial: approval tests exist, but replay-scoped approval cases do not yet exist. [VERIFIED: `test/scoria/connectors/invocation_test.exs`] |
| RPLY-02 | No replay path silently escapes to a live side effect when evidence is missing. [VERIFIED: `.planning/ROADMAP.md`] | unit/integration | `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/connectors/invocation_test.exs` | Partial: replay lineage tests exist; missing blocked-on-no-evidence assertions. [VERIFIED: `test/scoria/workflows/replay_branch_test.exs`, `test/scoria/connectors/invocation_test.exs`] |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/connectors/invocation_test.exs`
- **Per wave merge:** `mix test test/scoria/workflows/replay_branch_test.exs test/scoria/connectors/invocation_test.exs test/scoria/workflows/integration_test.exs`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] Add replay-specific invocation tests covering `historical_stub`, `blocked`, and allowlisted `execute_live` outcomes at the connector seam. [VERIFIED: `test/scoria/connectors/invocation_test.exs`, `.planning/ROADMAP.md`]
- [ ] Add runtime/integration tests proving missing historical evidence blocks rather than falls through to live execution. [VERIFIED: `test/scoria/workflows/integration_test.exs`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]
- [ ] Add approval tests proving historical approvals are evidence-only and replay-live requires fresh replay-scoped approval. [VERIFIED: `lib/scoria/observe/approval.ex`, `test/scoria/connectors/invocation_test.exs`, `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse current connector grant subject and auth failure/scope escalation seams; replay must not bypass them. [VERIFIED: `lib/scoria/connectors/auth.ex`, `lib/scoria/connectors/invocation.ex`] |
| V3 Session Management | no | Replay safety is not introducing a new session mechanism in this phase. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/runtime.ex`] |
| V4 Access Control | yes | Local policy checks plus replay-scoped approval are the control boundary before any live replay side effect. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/connectors/invocation.ex`] |
| V5 Input Validation | yes | Continue using Ecto changesets and explicit local classification before persisting replay authority or evidence. [VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/workflows/step.ex`] |
| V6 Cryptography | no | This phase can use opaque ids or stable keys without introducing new cryptographic requirements as a primary control. [VERIFIED: current phase scope and codebase inspection] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Historical approval reused as live authority | Elevation of Privilege | Persist replay-scoped approval semantics and require fresh approval for replay-live effects. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] |
| Missing historical evidence falls through to live tool traffic | Tampering | Fail closed to `blocked` and persist the reason on durable evidence rows. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`] |
| Duplicate live replay writes on retry | Tampering / Repudiation | Attach a stable idempotency key plus payload fingerprint before live execution and persist it alongside audit evidence. [CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07, VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/step.ex`, `lib/scoria/sre/audit_outbox_event.ex`] |
| Concurrent approval or run updates overwrite each other | Tampering | Keep `optimistic_lock(:lock_version)` on authority rows. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html, VERIFIED: `lib/scoria/workflows/run.ex`, `lib/scoria/observe/approval.ex`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md` - locked Phase 38 decisions, discretion, and scope boundaries. [VERIFIED: file read]
- `.planning/ROADMAP.md` - phase goal, success criteria, and requirement mapping. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - `RPLY-02` requirement wording. [VERIFIED: file read]
- `lib/scoria/workflows.ex`, `lib/scoria/workflows/run.ex`, `lib/scoria/workflows/runtime.ex` - current replay branch, step runtime, approval, and checkpoint/event transaction seams. [VERIFIED: codebase inspection]
- `lib/scoria/connectors/invocation.ex`, `lib/scoria/connectors/auth.ex`, `lib/scoria/mcp/executor.ex` - current risk classification, approval gating, auth evidence, and outbound execution seams. [VERIFIED: codebase inspection]
- `lib/scoria/observe/approval.ex`, `lib/scoria/sre/audit_outbox_event.ex` - durable approval and audit truth models. [VERIFIED: codebase inspection]
- `test/scoria/workflows/replay_branch_test.exs`, `test/scoria/connectors/invocation_test.exs`, `test/scoria/workflows/integration_test.exs` - current proof lanes and test gaps. [VERIFIED: codebase inspection]
- Hex package registry via `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql`, `mix hex.info oban` - current package versions and publish dates. [VERIFIED: command output]
- https://hexdocs.pm/ecto/Ecto.Multi.html - grouped repo operations and `run/3` semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- https://hexdocs.pm/ecto/Ecto.Changeset.html - optimistic locking behavior and failure semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
- https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07 - idempotency-key and fingerprint guidance for replay-live dedupe. [CITED: https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07]

### Secondary (MEDIUM confidence)

- https://hexdocs.pm/oban/unique_jobs.html - useful only as background on persisted uniqueness semantics; not required for the core phase design. [CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified against `mix.lock` and Hex package metadata on 2026-05-23. [VERIFIED: `mix.lock`, Hex package registry via `mix hex.info ...`]
- Architecture: HIGH - the phase boundary and seam ownership are explicit in the context and match the current runtime/connector/MCP code. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, codebase inspection]
- Pitfalls: HIGH - each pitfall is either a locked decision or a direct mismatch between that decision and the current code shape. [VERIFIED: `.planning/phases/38-replay-safe-execution-tool-modes/38-CONTEXT.md`, `lib/scoria/workflows/run.ex`, `lib/scoria/observe/approval.ex`]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 for codebase shape; re-check Hex package versions before execution if this phase is planned later. [VERIFIED: codebase inspection, Hex package registry via `mix hex.info ...`]
