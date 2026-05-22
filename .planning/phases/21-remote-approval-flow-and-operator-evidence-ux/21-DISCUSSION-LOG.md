# Phase 21 Discussion Log

**Phase:** 21 - Remote Approval Flow and Operator Evidence UX
**Date:** 2026-05-17
**Mode:** recommendation-first discuss-all
**Status:** decisions locked for planning

## Discussion Setup

- User selected all identified gray areas.
- User requested one-shot recommendations rather than iterative questioning.
- User explicitly asked for subagent-backed research covering:
  - pros/cons/tradeoffs
  - idiomatic Elixir/Plug/Ecto/Phoenix posture
  - lessons from adjacent successful systems
  - strong DX and principle-of-least-surprise guidance
  - shifting low-impact preferences left into Scoria/GSD defaults

## Inputs Consulted

### Repo planning and context
- `.planning/ROADMAP.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-CONTEXT.md`
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md`
- `.planning/research/v1.5-switchyard-recommendation.md`
- `.planning/research/mcp-and-tools.md`
- `.planning/research/liveview-operator-ux.md`
- `.planning/research/evals-and-observability.md`

### Prompt and product guidance
- `prompts/scoria-gsd-kickoff.md`
- `prompts/phoenix-ai-lib-deep-research.md`
- `prompts/scoria-brand-book-deep-research.md`
- `prompts/sztheory-elixir-dna.md`

### Code seams reviewed
- `lib/scoria/workflows.ex`
- `lib/scoria/observe/approval.ex`
- `lib/scoria/connectors.ex`
- `lib/scoria/connectors/invocation.ex`
- `lib/scoria/connectors/auth.ex`
- `lib/scoria/connectors/tool_reconciliation.ex`
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/components/incident_evidence_component.ex`
- `test/scoria/connectors/invocation_test.exs`
- `test/scoria_web/live/orchestrator_live_test.exs`

### External guidance checked
- MCP authorization spec and tutorial
- GitHub App permission-change / approval docs
- Slack OAuth and optional-scope docs
- LangGraph interrupt/HITL docs
- Phoenix LiveDashboard and Oban Web operator-surface references
- Stripe Radar review-flow reference

## Area Decisions

### 1. Approval review surface

**Options considered**
- Inline run modal only
- Connector page as approval home
- Global operator inbox only
- Hybrid inbox plus contextual projections
- Host-app/app-facing approval cards

**Locked recommendation**
- Use a hybrid operator surface:
  - a first-class `Approvals Inbox` is the canonical place to review and act on pending remote approvals
  - run and connector views project the same durable approval state contextually

**Why this won**
- Best fit for workflow-owned approval truth
- Strongest least-surprise UX for embedded Phoenix teams
- Supports queueing/triage without losing run-local and connector-local context

### 2. Connector health and grants dashboard

**Options considered**
- Fleet table with detail drawer
- Per-connector drilldown pages with tabs
- Connector event notebook / timeline first
- Attention inbox plus compact fleet summary

**Locked recommendation**
- Use a fleet table with detail drawer as the primary connector operator surface.

**Why this won**
- Best scan-first posture for embedded operator work
- Maps cleanly onto durable connector/grant/capability snapshot rows
- Keeps connector ops visible without drifting into hosted-control-plane ergonomics

### 3. Invocation evidence presentation

**Options considered**
- Run-centric evidence notebook (lineage/timeline-first)
- Payload/policy dossier (payload-first)
- Connector-centric operations console
- Approval-centric queue with evidence drawer

**Locked recommendation**
- Use a run-centric evidence notebook with lineage/timeline-first default.

**Why this won**
- Best match for existing Scoria run/step/audit truth
- Strongest replay and forensic story
- Lets policy/payload and connector context appear as secondary panels instead of replacing the run story

### 4. Approval outcomes and operator actions

**Options considered**
- Binary approval only
- Workflow approval plus typed remediation actions around it
- Rich approval modal with bundled decisions
- Auto-resolve low-impact blockers, human only for high-impact ones

**Locked recommendation**
- Keep approval semantics narrow and workflow-owned.
- Add typed remediation actions around approvals:
  - `approve`
  - `reject`
  - `re-auth`
  - `sync/refresh`
  - `request scope escalation`
  - `adopt pending tool`
  - `replay blocked step`
- Use auto-resolution only as a supporting principle for low-impact situations, not as the only operator model.

**Why this won**
- Preserves clean durable boundaries
- Avoids turning approval rows into a generic command bus
- Keeps low-impact choices shifted left while still supporting operator recovery

## Cross-Area Synthesis

The resulting coherent operator workflow is:

1. Connector dashboard = state surface
2. Approvals inbox = risk surface
3. Run-centric evidence notebook = truth surface

Operator flow:

1. Start from the blocked run or inbox item.
2. Inspect the typed blocker and evidence lineage.
3. Jump to connector details if remediation is needed.
4. Perform the smallest eligible remediation action.
5. Return to evidence.
6. Approve and replay, or reject.

## Shift-Left Defaults Locked

The following should be decided by Scoria/GSD defaults rather than resurfaced to the user during planning unless implementation evidence forces a rethink:

- default badge/status taxonomy
- health rollup formulas
- scope-diff presentation shape
- stale-vs-last-good heuristics
- inbox ordering and grouping defaults
- replay affordance visibility after successful remediation
- non-widening refresh handling
- normal low-impact refresh/rebind choices

## Footguns Explicitly Rejected

- Approval truth owned by a LiveView modal
- Connector page as the only approval home
- Generic “approve and mutate everything” action model
- Auto-resume before durable evidence and workflow state commit
- High-cardinality telemetry built from raw payload/tool/scope detail
- Silent local-tool adoption or scope widening

## Result

The discussion produced a coherent, recommendation-first Phase 21 posture and was written into `21-CONTEXT.md` for downstream planning.
