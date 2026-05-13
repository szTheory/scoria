# Phase 12: Canonical Runtime Identity - Context

**Gathered:** 2026-05-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Define first-class actor, tenant, and session identity for Scoria runs so workflow, approval, telemetry, and audit paths all use one stable app-facing identity model instead of ad hoc attrs and fallbacks.

This phase clarifies runtime nouns and propagation rules. It does not broaden into app authentication, full public runtime APIs, or wider policy/install/docs work that belongs to later Keystone phases.

</domain>

<decisions>
## Implementation Decisions

### Canonical identity shape
- **D-01:** Scoria should introduce one canonical `Scoria.Identity` runtime envelope struct as the stable identity noun for Phase 12.
- **D-02:** The envelope should carry flat first-class canonical fields for `actor_id`, `tenant_id`, and `session_id` rather than treating them as conventions inside a freeform map.
- **D-03:** Top-level `actor:` / `tenant:` / `session:` inputs may exist as convenience sugar, but they must normalize into `Scoria.Identity` immediately before workflow, approval, audit, or telemetry code runs.
- **D-04:** Phoenix-, Plug-, and LiveView-facing helpers should exist only as edge adapters that build the envelope at the front door; `Plug.Conn`, socket assigns, or host-app structs must not become Scoria’s durable runtime identity contract.

### Persistence model
- **D-05:** Canonical `actor_id`, `tenant_id`, and `session_id` should become first-class durable columns on the primary rows that define runtime truth where identity matters, with indexes where operator queries and joins need them.
- **D-06:** Extensible app-specific identity context should live in bounded `metadata` / `attributes` maps beside those columns, not instead of them.
- **D-07:** Durable columns are the source of truth for propagation, filtering, audit joins, and evidence views. Metadata is secondary context and must not silently override canonical fields.
- **D-08:** Scoria should avoid normalized identity-envelope tables in this phase. They add join weight and lifecycle complexity without improving the core embedded Phoenix adoption story.

### Propagation and override rules
- **D-09:** Run-root identity is immutable once a run starts. Workflow steps, approvals, MCP/tool execution, telemetry, and audit paths inherit it by default.
- **D-10:** Per-step or per-execution adjustments belong in a separate transient execution-context concept, not in mutable root identity.
- **D-11:** If Scoria ever permits identity overlays, they must be narrow, explicit, and auditable. Silent ad hoc fallback chains across subsystems are no longer acceptable.
- **D-12:** Telemetry and audit rows must never rewrite canonical root identity. They may project it and attach local execution metadata or explicit override evidence.

### Host-app contract and DX posture
- **D-13:** The public host-app contract should require canonical runtime ids and accept optional non-canonical labels or metadata for UI and evidence ergonomics.
- **D-14:** Scoria must not require host apps to pass app-owned structs, `Plug.Conn`, or socket state into durable runtime internals.
- **D-15:** Phoenix helpers should support common host-app patterns like `conn.assigns`, LiveView session assigns, and on-mount extraction, but those remain adapters around the explicit identity contract.
- **D-16:** Shift low-impact identity and runtime defaults left inside Scoria and future GSD flows. Only materially consequential choices should interrupt the user.

### the agent's Discretion
- Exact struct/module naming between `Scoria.Identity`, `Scoria.Runtime.Identity`, or a similar public noun, provided the product exposes one obvious canonical envelope.
- Exact index layout and which durable rows gain all three identity columns first, provided run truth, approval/audit seams, and operator evidence queries remain coherent.
- Exact naming of the transient execution-context sidecar, provided it is clearly distinct from canonical root identity.
- Exact Phoenix helper API shape for extracting identity from `conn`, session, or LiveView sockets, provided those helpers normalize into the same canonical envelope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 12 goal, plan breakdown, and Keystone sequencing.
- `.planning/PROJECT.md` - current product boundary, embedded Phoenix posture, and Keystone milestone thesis.
- `.planning/REQUIREMENTS.md` - `IDEN-01` and `IDEN-02` plus the milestone’s explicit identity requirements.
- `.planning/STATE.md` - current project posture and accumulated decisions that Keystone must preserve.
- `.planning/MILESTONE-ARC.md` - strategic reasoning for making identity and runtime nouns the next adoption prerequisite.
- `.planning/seeds/SEED-001-agentcore-lessons.md` - explicit lesson that session and actor identity must be durable and visible without drifting into managed-runtime shape.

### Prior phase context and decisions
- `.planning/phases/05-caldera/05-CONTEXT.md` - durable workflow truth, root-owned runs, checkpoint semantics, and stable workflow nouns.
- `.planning/phases/07-seismograph/07-CONTEXT.md` - telemetry, audit, and operator-evidence posture that identity propagation must align with.
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md` - workflow-owned approval truth and attribution expectations.
- `.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-CONTEXT.md` - canonical operational identity direction in telemetry and the rule that durable rows stay local truth.
- `.planning/phases/11-re-verify-seismograph-and-align-milestone-state/11-CONTEXT.md` - shipped-state alignment and evidence expectations entering Keystone.

### Product vision and ecosystem guidance
- `prompts/scoria-gsd-kickoff.md` - batteries-included Phoenix AI ops framing and operator-first design goals.
- `prompts/phoenix-ai-lib-deep-research.md` - surrounding ecosystem analysis and lessons from agent, trace, eval, and MCP systems.
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, Ecto-native, operator-first architecture rules.
- `prompts/scoria-brand-book-deep-research.md` - calm operator-grade, evidence-first product tone that identity surfaces must preserve.

### Current code surface
- `lib/scoria.ex` - current placeholder public module that later runtime APIs will grow from.
- `lib/scoria/workflows/run.ex` - current durable run schema with only `session_id` as first-class identity.
- `lib/scoria/workflows.ex` - run creation, approval transitions, and current identity fallback behavior that Phase 12 should normalize.
- `lib/scoria/workflows/runtime.ex` - workflow execution seam where root identity and transient execution context must separate cleanly.
- `lib/scoria/observe/approval.ex` - approval schema that currently persists session and workflow refs but not full canonical identity.
- `lib/scoria/mcp/executor.ex` - tool/MCP execution seam with ad hoc identity attrs and policy-sensitive audit propagation.
- `lib/scoria/mcp/router.ex` - current Plug-facing boundary where host-app actor context enters Scoria.
- `lib/scoria/sre/telemetry.ex` - public telemetry helper boundary that identity projections feed into.
- `lib/scoria/sre/telemetry_identity.ex` - current canonical telemetry label/ref shape that must align with runtime identity decisions.
- `priv/repo/migrations/20260511000100_create_workflow_tables.exs` - baseline workflow schema design.
- `priv/repo/migrations/20260510160812_create_ai_approvals.exs` - original approval schema with session/run-only identity fields.
- `priv/repo/migrations/20260511000200_link_approvals_to_workflows.exs` - approval/workflow linkage that later identity columns will extend.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows.create_run/1` already centralizes durable run creation, which is the right place to normalize and persist canonical identity once.
- `Scoria.Workflows.approve/3` and `mark_waiting_for_approval/3` already define audited approval seams, making them the right boundary to inherit immutable root identity rather than recalculate it ad hoc.
- `Scoria.SRE.TelemetryIdentity` already gives Scoria a canonical low-cardinality projection shape that can project from durable identity once Phase 12 defines the runtime source of truth.
- `Scoria.MCP.Executor` already concentrates tool execution, budget, breaker, and audit behavior, which is the right place to consume inherited identity plus transient execution context.

### Established Patterns
- Ecto rows are durable truth; telemetry, LiveView, and PubSub are projections or observation seams.
- The product already favors stable nouns, explicit transactions, and operator-readable evidence over hidden runtime magic.
- Scoria has drift today: some seams use `tenant_id` / `actor_id`, some only persist `session_id`, and some fall back to `"system"` or `session_id` as a proxy actor. Phase 12 exists to remove that ambiguity.

### Integration Points
- Run creation must stamp one canonical identity envelope into durable workflow truth.
- Approval, audit, and MCP seams must inherit that identity without each seam inventing new fallback precedence.
- Telemetry identity projection must read from the same canonical runtime contract used by workflow and audit paths.
- Future public runtime APIs in Phase 13 should accept the same identity envelope rather than reintroducing top-level ad hoc attrs.

</code_context>

<specifics>
## Specific Ideas

- The right public posture is one obvious runtime noun, not a bag of attrs.
- Identity should read like normal Phoenix library design: explicit at the boundary, boring in the middle, durable at rest.
- Follow the ecosystem lesson from Ash and similar systems: separate canonical identity from wider context instead of letting request-scoped state leak through the whole stack.
- Great DX here means a small required contract, helper adapters at the Phoenix edge, and fewer user interruptions for low-impact defaults.
- Phase 12 should actively remove current footguns like using `session_id` as a proxy actor or letting missing identity silently collapse to `"system"` without clear intent.

</specifics>

<deferred>
## Deferred Ideas

- Full host-app authentication, actor loading, or tenancy frameworks inside Scoria.
- Protocol-based support for arbitrary host-app identity structs as a default public contract.
- Cross-run normalized identity-governance tables or pseudonymization workflows beyond the immediate runtime identity need.
- Broader public runtime API ergonomics, resume/start/inspect shapes, and install/docs storytelling that belong in Phases 13 through 15.

</deferred>

---

*Phase: 12-canonical-runtime-identity*
*Context gathered: 2026-05-13*
