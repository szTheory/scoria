# Phase 21: Remote Approval Flow and Operator Evidence UX - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend Scoria's workflow-owned approval and evidence model into remote connector scenarios with operator-grade visibility.

This phase turns the durable connector/auth boundary from Phases 19-20 into an operator-facing control surface. It must make remote write, exec, and scope-escalation approval paths workflow-owned; let operators inspect connector health, grants, and refresh state; and present remote invocation evidence with exact identity, policy, approval, and redacted request/response lineage. It does not broaden into curated profile productization, install ergonomics, or broader hosted-style connector fleet behavior; those remain Phase 22 or later work.

</domain>

<decisions>
## Implementation Decisions

### Approval review surface
- **D-01:** Remote approvals should live in a first-class `Approvals Inbox` inside Scoria's embedded dashboard, not only as inline run modals and not primarily inside connector settings.
- **D-02:** The approvals inbox is the canonical operator triage surface for pending remote write, exec, and scope-escalation decisions.
- **D-03:** Run pages and connector detail views should project approval state read-through, but approval truth remains workflow-owned and durable in Ecto rows.
- **D-04:** The current inline modal pattern is acceptable as a local projection or interrupt affordance, but it is not the primary home of remote approval review in the final Phase 21 shape.
- **D-05:** Host-app-facing approval cards are not the core product posture for this phase. They may become an optional extension later, but the embedded operator dashboard is the default Scoria approval surface.

### Connector operator dashboard
- **D-06:** The primary connector UX should be a fleet table with detail drawer or equivalent scan-first surface, not a connector-event notebook as the top-level IA.
- **D-07:** Operators should be able to scan current connector health, auth/grant state, granted scopes, last refresh status, last good refresh, and pending local-tool adoption state in one compact fleet view.
- **D-08:** The detail drawer should provide the deeper evidence strip for one connector: auth metadata provenance, refresh history summary, scope challenges, pending approvals, and links into exact run/evidence records.
- **D-09:** Connector detail should stay operational and inspectable without feeling like a hosted connector platform. The product center of gravity remains embedded governance, not connector fleet productization.
- **D-10:** Capability refresh should be presented as the latest durable snapshot plus refresh history/evidence, not as a magically live remote truth feed.

### Invocation evidence presentation
- **D-11:** Remote invocation evidence should be presented as a run-centric evidence notebook with a lineage/timeline-first default.
- **D-12:** The default reading order for one remote invocation should be:
  - canonical identity and run/step context
  - local policy outcome
  - approval request/decision lineage when applicable
  - connector/grant/scope context
  - redacted request/response summaries
  - replay or follow-on outcome
- **D-13:** Payload/policy summaries should be secondary panels inside the evidence notebook, not the default top-level IA. This keeps Scoria trace-first instead of blob-first.
- **D-14:** Connector posture should appear as contextual side information in the invocation evidence view, not as the primary frame for understanding one blocked or approved run.
- **D-15:** Telemetry must remain low-cardinality. Metrics should use stable outcome categories, risk buckets, connector/profile identifiers, and event types, while exact details are recovered through durable record links rather than high-cardinality labels.

### Approval outcomes and operator actions
- **D-16:** Approval semantics should stay narrow and workflow-owned: an approval answers whether a blocked write, exec, or escalation may proceed.
- **D-17:** Connector maintenance and recovery actions should exist around approvals as typed remediation actions, not as overloaded approval statuses.
- **D-18:** Operators should be able to take the following typed actions when relevant:
  - `approve`
  - `reject`
  - `re-auth`
  - `sync/refresh`
  - `request scope escalation`
  - `adopt pending tool`
  - `replay blocked step`
- **D-19:** Action availability must be eligibility-driven by the durable blocked outcome:
  - `:auth_required` -> `re-auth`
  - `:scope_escalation_required` -> `request scope escalation`
  - quarantined/pending tool state -> `adopt pending tool`
  - stale discovery/refresh evidence -> `sync/refresh`
  - successful remediation + explicit approval path -> `replay blocked step`
- **D-20:** `approve and mutate everything` is explicitly the wrong model. Approval rows must not become a generic command bus for arbitrary connector state changes.
- **D-21:** Auto-resume after remediation is not the default. Recovery should produce a fresh durable event/evidence record, then replay or resume explicitly through workflow-owned seams.

### Shift-left defaults and least-surprise posture
- **D-22:** Low-impact decisions should be shifted left into Scoria defaults instead of surfaced for operator choice:
  - default badge/status taxonomy
  - normal health rollup formulas
  - non-widening refresh handling
  - scope-diff presentation shape
  - stale-vs-last-good connector status heuristics
  - default ordering and grouping in the inbox and fleet table
  - replay affordance visibility rules after successful remediation
- **D-23:** Human interruption should be reserved for materially impactful moments:
  - remote writes/exec
  - scope widening
  - pending tool adoption after catalog drift
  - ambiguous or high-risk connector recovery paths
- **D-24:** The product should copy the best permission-widening lessons from GitHub/Slack-style ecosystems: existing power remains stable, new power requires explicit review, and the UI should explain what changed and why.
- **D-25:** The product should copy the best HITL lessons from durable workflow systems like LangGraph: exact state is persisted before waiting, and resumption depends on durable state rather than transient UI coordination.

### Cohesive operator workflow
- **D-26:** The coherent Phase 21 operator workflow is:
  - the connector dashboard is the state surface
  - the approvals inbox is the risk surface
  - the run-centric evidence notebook is the truth surface
- **D-27:** Operators should start from the blocked run or inbox item, inspect the typed blocker, jump to connector details if needed, perform the smallest eligible remediation, return to evidence, then approve and replay or reject.
- **D-28:** Cross-links between these surfaces are mandatory. Every approval, blocked invocation, grant challenge, and replay should link to the exact connector, run, step, approval, and audit evidence rows involved.

### the agent's Discretion
- Exact LiveView routing, whether the inbox/drawer live inside the existing `OrchestratorLive` or adjacent LiveViews, provided the product still presents one obvious embedded dashboard path.
- Exact query/projection modules and presenter boundaries, provided Ecto rows remain truth and LiveView remains projection.
- Exact badge copy, timeline grouping, and tab/drawer composition, provided the IA remains scan-first for connectors and lineage-first for invocation evidence.
- Exact typed remediation schema/module names, provided approval decisions and connector maintenance actions remain separate durable concepts.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 21 UX should borrow from:
  - Phoenix LiveDashboard / Oban Web style scan-first operator tables with drilldown
  - GitHub/Slack style explicit permission-widening review
  - LangGraph style durable interrupt/resume semantics
  - Stripe Radar style inbox + detail review ergonomics
- The right Scoria reading order is:
  - see the blocked or approved run
  - understand what policy or grant blocked it
  - inspect exact approval and connector lineage
  - remediate the smallest thing necessary
  - replay explicitly through workflow truth
- Approval should feel like part of the workflow, not a scary emergency, and not a hidden connector-admin side alley.
- Connector health should feel boring and inspectable, not magical and not SaaS-control-plane heavy.
- Evidence should emphasize stable nouns already present in Scoria:
  - run
  - step
  - connector
  - local tool
  - grant
  - approval
  - audit event
- The product should stay calm, dense, and operator-grade:
  - compact rollups first
  - deep evidence on demand
  - no giant raw payload walls by default
  - no hidden mutable UI state

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 21 goal, success criteria, and dependency on Phase 20.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and current Switchyard thesis.
- `.planning/REQUIREMENTS.md` - `POLI-03`, `EVID-01`, `EVID-02`, and `EVID-03`.
- `.planning/STATE.md` - milestone posture and active sequencing context.
- `.planning/MILESTONE-ARC.md` - why remote connector governance is the current leverage point.
- `.planning/research/v1.5-switchyard-recommendation.md` - active recommendation synthesis for Switchyard.

### Prior locked Scoria decisions
- `.planning/phases/12-canonical-runtime-identity/12-CONTEXT.md` - durable identity nouns and canonical runtime truth.
- `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md` - explicit runtime API posture and session/run semantics.
- `.planning/phases/14-policy-defaults-and-install-ergonomics/14-CONTEXT.md` - shift-left defaults and least-surprise product posture.
- `.planning/phases/15-adoption-surface-docs-and-example-flow/15-CONTEXT.md` - one obvious adoption path and embedded host-app integration expectations.
- `.planning/phases/18-add-executable-adoption-flow-guards/18-CONTEXT.md` - executable proof lanes and default-lane adoption posture.
- `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-CONTEXT.md` - durable connector/auth nouns, explicit refresh jobs, and auth posture.
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` - stable local tool identity, dual-plane policy, typed blocked outcomes, and stateless-first invocation posture.

### Project and product guidance
- `.planning/research/mcp-and-tools.md` - prior MCP/tool governance research, especially HITL suspension and transport boundaries.
- `.planning/research/liveview-operator-ux.md` - embedded LiveView operator dashboard patterns and async evidence-loading posture.
- `.planning/research/evals-and-observability.md` - trace/evidence design principles, redaction rules, and operator evidence posture.
- `prompts/scoria-gsd-kickoff.md` - Scoria vision, control-plane framing, and ecosystem alignment.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native AI ops product lessons, governance UX, and adjacent-system references.
- `prompts/scoria-brand-book-deep-research.md` - operator-grade voice, dense dashboard guidance, and approval/evidence UX posture.
- `prompts/sztheory-elixir-dna.md` - embedded LiveView dashboard and Ecto-native state principles.

### Current code surface
- `lib/scoria/workflows.ex` - workflow-owned approval transitions, event/checkpoint durability, and resume semantics.
- `lib/scoria/observe/approval.ex` - current durable approval row shape and optimistic locking posture.
- `lib/scoria/connectors.ex` - connector listing/sync boundary for operator surfaces.
- `lib/scoria/connectors/invocation.ex` - typed remote blocked outcomes and connector-aware invocation gate.
- `lib/scoria/connectors/auth.ex` - auth failure and scope escalation durability seam.
- `lib/scoria/connectors/connector.ex` - durable connector truth.
- `lib/scoria/connectors/grant.ex` - durable grant/secrets posture.
- `lib/scoria/connectors/capability_snapshot.ex` - latest durable capability snapshot and refresh metadata posture.
- `lib/scoria/connectors/local_tool.ex` - stable local tool noun that approval/evidence should reference.
- `lib/scoria/connectors/tool_reconciliation.ex` - pending/adoption semantics for catalog drift.
- `lib/scoria_web/live/orchestrator_live.ex` - current operator surface, inline approval modal, and evidence-loading patterns.
- `lib/scoria_web/components/incident_evidence_component.ex` - compact rollup + deep evidence component pattern to extend for remote invocation evidence.
- `test/scoria/connectors/invocation_test.exs` - expected auth/scope blocked outcomes and durable evidence assertions.
- `test/scoria_web/live/orchestrator_live_test.exs` - current approval modal and evidence-view interaction expectations.

### External standards and adjacent-system guidance
- `https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization` - MCP authorization requirements, protected-resource metadata, and scope-challenge posture.
- `https://modelcontextprotocol.io/specification/draft/basic/authorization` - draft MCP auth guidance including explicit runtime scope-challenge handling.
- `https://modelcontextprotocol.io/docs/tutorials/security/authorization` - explanatory MCP auth flow guidance and operator-relevant auth concepts.
- `https://www.rfc-editor.org/rfc/rfc9728.pdf` - OAuth 2.0 Protected Resource Metadata.
- `https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration` - explicit permission change approval semantics and installation-update posture.
- `https://docs.github.com/en/enterprise-server@3.17/apps/using-github-apps/approving-updated-permissions-for-a-github-app` - updated-permissions review flow and stable-old-permissions posture.
- `https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps` - dual-plane permission model and actor+app attribution posture.
- `https://docs.slack.dev/authentication/installing-with-oauth/` - least-privilege OAuth posture, additive scope behavior, and explicit approval flow.
- `https://docs.slack.dev/changelog/2026/03/16/optional-scopes/` - optional-scope posture that reinforces shifting low-impact access choices left.
- `https://docs.langchain.com/oss/python/langgraph/interrupts` - durable interrupt/resume model and persistence-first HITL lessons.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - embedded Phoenix operator-surface pattern.
- `https://hexdocs.pm/oban_web/overview.html` - operator-grade queue/table + drilldown ergonomics in the Elixir ecosystem.
- `https://docs.stripe.com/radar/reviews?locale=en-GB` - review-queue ergonomics and evidence-rich operator decision flow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows` already owns durable approval request, decision, checkpoint, and resume state. Phase 21 should project this rather than invent a second approval state machine.
- `Scoria.Connectors.Invocation` already distinguishes `:auth_required`, `:scope_escalation_required`, and `:tool_unavailable`, which is the right substrate for typed operator remediation.
- `Scoria.Connectors.Auth` already records auth failure and scope-escalation evidence in workflow-compatible shapes.
- `Scoria.Connectors` already exposes fleet-friendly list/get boundaries over durable connector, grant, capability snapshot, and local-tool rows.
- `OrchestratorLive` and `IncidentEvidenceComponent` already establish the desired UI pattern: compact top-level rollup, lazy deep evidence loading, and operator-first interaction.

### Established Patterns
- Ecto rows are durable truth; LiveView is a projection and control surface over that truth.
- Plug-facing transport/auth seams stay outside LiveView.
- High-risk actions flow through durable audit/evidence paths before UI projection.
- The repo repeatedly prefers one obvious operator path with boring defaults over a broad matrix of host-app customization choices.

### Integration Points
- Phase 21 should add approval-inbox and connector-dashboard projections over existing workflow/connectors rows.
- The run-centric evidence notebook should join workflow events, approval rows, audit outbox rows, connector/grant state, and local-tool records without redefining truth in the UI layer.
- Connector dashboard actions should call explicit context APIs for re-auth, sync, scope review, pending-tool adoption, and replay readiness rather than mutating state in socket assigns.
- Evidence views, inbox rows, and connector detail drawers should cross-link through durable IDs for run, step, connector, local tool, grant, approval, and audit event.

</code_context>

<deferred>
## Deferred Ideas

- Host-app-facing approval cards or end-user embedded approval UX outside the Scoria operator dashboard.
- Rich approval editing flows that let operators rewrite payloads or arguments inline before replay.
- Hosted-style connector fleet operations, assignment-heavy ops workflows, or marketplace-like connector admin breadth.
- Broader profile/install ergonomics and curated connector adoption polish - Phase 22.
- Stateful session-heavy remote connector UX beyond the stateless-first milestone center.

</deferred>

---

*Phase: 21-remote-approval-flow-and-operator-evidence-ux*
*Context gathered: 2026-05-17*
