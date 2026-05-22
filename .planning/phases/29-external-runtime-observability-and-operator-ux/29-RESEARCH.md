# Phase 29: External Runtime Observability and Operator UX - Research

**Researched:** 2026-05-19
**Domain:** Elixir/Phoenix LiveView, Phoenix.Presence, Ecto UI Projections
**Confidence:** HIGH

## Summary

This phase exposes the transport seams built in Phase 27 (MCP SSE) and the compaction artifacts from Phase 28 (Async SummarizeWorker) as a coherent operator surface inside the Scoria dashboard. The objective is to use `Phoenix.Presence` to securely identify and list connected external agents, and to construct a notebook-style view of compaction blocks (`CompactedMemory`) against raw workflow `Event` entries within `ScoriaWeb.WorkflowLive.Show`. 

**Primary recommendation:** Use `Phoenix.Presence` strictly for transient attachment tracking within `ScoriaWeb.MCPController`, rely on `Scoria.Runtime.CompactedMemory` combined with `Scoria.Workflows.Event` for the durable notebook UI in `WorkflowLive.Show`, and extend `ScoriaWeb.OrchestratorLive` with a compact "Runtime Posture" card stack identical in IA to the existing Connector Fleet UI.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Transport Attachment (Presence) | API / Backend | Browser / Client | Phoenix Presence lives in the Elixir application layer, tracking processes (like SSE loop in MCPController) and distributing state across nodes via PubSub. LiveView is just a client of this PubSub state. |
| Runtime Identity / Linkage | Database / Storage | API / Backend | Durable truth (tenant, instance_id, last_offline_reason) must be stored in Postgres (via Ecto) to survive process death, rather than remaining in ephemeral PubSub metadata. |
| Dashboard Real-Time View | Frontend Server (SSR) | Browser / Client | Phoenix LiveView maintains UI state over WebSocket, rendering Presence diffs as they arrive. |
| Compaction Notebook Audit | Frontend Server (SSR) | Database / Storage | Ecto provides the `CompactedMemory` records and related `Events`; LiveView renders the notebook structure and manages the collapse/expand interactions for raw evidence without thick client-side JavaScript. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The dashboard should show external runtimes as a compact adjacent operator surface, not as a new full-width primary fleet console and not as something hidden until drill-down.
- **D-02:** The recommended Phase 29 shape is a runtime status rail or compact card stack beside the existing operator surfaces in `OrchestratorLive`, parallel to approvals and connector posture.
- **D-03:** Each runtime row/card should stay compact and scan-first, emphasizing:
  - runtime identity
  - current presence status
  - active session or run linkage when available
  - last heartbeat or last seen indicator when available
  - compaction freshness / latest compacted-memory linkage
- **D-04:** A dedicated wide fleet table is not the default Phase 29 IA. It is a possible later expansion if tenant/runtime scale proves the compact rail insufficient.
- **D-05:** Runtime scanability matters, but Scoria must not drift into a hosted runtime-control-plane posture. The runtime surface is an operator aid inside the embedded dashboard, not the new center of gravity.
- **D-06:** Phase 29 should expose status plus runtime identity plus transport/session linkage as the default contract.
- **D-07:** Presence should mean transport/process attachment first, not general remote-agent health. The UI must not imply stronger liveness guarantees than Scoria can prove.
- **D-08:** Status semantics should be:
  - `connected` -> a Presence entry exists and Scoria can resolve runtime identity plus current linkage
  - `offline` -> Presence left / transport closed / runtime no longer attached
  - `degraded` -> only valid if Scoria has an explicit runtime heartbeat or runtime-activity signal independent of transport keepalives
- **D-09:** Scoria must not derive `degraded` from SSE keepalive comments or mere socket openness. A transport that is still attached is not automatically a healthy runtime.
- **D-10:** Offline state should show a typed reason when available, such as:
  - `transport_closed`
  - `presence_left`
  - `session_not_found`
  - `heartbeat_timeout`
  - `operator_disconnect`
- **D-11:** Presence metadata should stay small and ephemeral. Richer operator-visible identity and linkage truth should come from Ecto-backed projections or `fetch/2` enrichment rather than bloated Presence metadata.
- **D-12:** The stable key for runtime presence should be a Scoria-owned runtime instance id, not only a host-app `session_id`. Session/run linkage remains metadata or projection.
- **D-13:** Operators need durable runtime identity and linkage beyond the life of a live connection. The following should be durable Ecto-backed truth or equivalent projection inputs:
  - runtime instance id
  - actor/tenant identity
  - host session id when applicable
  - current and last linked run id
  - first seen / last seen
  - last terminal offline reason
  - transport kind
  - bounded runtime descriptors that matter to operators
- **D-14:** The following should remain ephemeral connection-state metadata:
  - Presence refs
  - current transport facts
  - current heartbeat timestamp/age
  - reconnecting/stale labels
  - other volatile live-session hints
- **D-15:** The rule is simple: if operators need it after the process dies, it belongs in durable truth; if it only describes the current live connection, it may remain ephemeral.
- **D-16:** The compaction audit view should use a timeline/notebook model with `raw range -> compacted memory` blocks, not a side-by-side textual diff as the primary presentation.
- **D-17:** Each compaction block should make the transformation explicit and auditable:
  - exact raw sequence range
  - compacted timestamp
  - archived event count
  - token-count metadata
  - summary text
  - expandable raw evidence beneath
- **D-18:** Summary-first collapse behavior is acceptable inside each compaction block, but summary-first is not the top-level information architecture for the page.
- **D-19:** Raw events remain the source of truth. Compacted summaries are operator aids and durable derived memory, not replacements for the original evidence.
- **D-20:** Scoria must not render a fake “diff” that implies event-to-summary alignment the system does not actually store. Current compaction output is a bounded freeform summary over a sequence range, not a structurally aligned patch.
- **D-21:** Sequence boundaries should be the lead audit reference in the UI. Timestamps are useful, but `start_sequence` / `end_sequence` are the actual compaction join keys.
- **D-22:** Token-count labels must be precise. If the persisted token count refers to archived raw tokens rather than summary tokens, the UI must say that explicitly.
- **D-23:** Scoria should support both a top-level runtime scan surface and deep workflow/session evidence, but with one clearly primary truth path.
- **D-24:** The dashboard root remains the scan/state surface. Workflow/session detail remains the truth surface.
- **D-25:** The primary drill-in from a runtime row should go to the linked workflow/session when one exists, not to a runtime-only page as the default path.
- **D-26:** The workflow/session page should become the place where runtime presence context, session timeline, and memory time-travel evidence are read together.
- **D-27:** Reciprocal links are mandatory:
  - runtime row -> linked workflow/session
  - workflow/session -> linked runtime card or drawer
  - compaction block -> exact runtime presence snapshot/context when available
  - offline runtime alert -> last active session/run
- **D-28:** If a dedicated runtime detail page exists later, it is a secondary ops surface for triage, not the primary truth surface.
- **D-29:** Low-impact Phase 29 choices should be shifted left into Scoria defaults and treated as locked by downstream GSD planning rather than re-asked:
  - rail/card runtime presentation over wide-table-first IA
  - workflow/session truth path over runtime-detail-first navigation
  - `connected` / `offline` semantics from Presence
  - no `degraded` without a real heartbeat contract
  - notebook-style compaction audit instead of side-by-side diff
  - compact runtime rows with one obvious primary action
  - lazy loading for deep archived raw evidence
  - explicit copy that raw events are truth and summaries are derived memory
- **D-30:** User interruption should be reserved for materially impactful future choices only:
  - introducing a real heartbeat contract that changes health semantics
  - making runtime fleet management a primary product surface
  - broadening into stateful remote runtime/session management
  - changing raw-event retention/archival posture in ways that affect audit truth

### the agent's Discretion
- Exact component/module names for runtime projections, drawers, and notebook rows, provided the split between dashboard scan surface and workflow/session truth surface remains intact.
- Exact card density, badge copy, and visual grouping, provided the UI stays calm, compact, operator-grade, and embedded rather than hosted-control-plane-like.
- Exact query/projection boundaries and async-loading strategy, provided heavy archived evidence stays lazy and LiveView does not become the source of truth.
- Exact route/anchor structure for cross-links, provided the primary drill-in remains workflow/session-first and runtime-only pages stay secondary.

### Deferred Ideas (OUT OF SCOPE)
- A full runtime fleet table with heavier filtering/sorting and runtime-only drilldown as a primary surface.
- Strict runtime heartbeat/degraded semantics unless and until external runtimes expose an explicit heartbeat/activity contract.
- Hosted-control-plane-style runtime administration beyond the embedded dashboard posture.
- State-heavy remote runtime/session management that hides transport/session lifecycle behind Scoria defaults.
- Rich textual diffing or semantic alignment views that require data Scoria does not currently persist.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OUTRIDER-02 | The dashboard displays connected agents | `Phoenix.Presence` implemented in `MCPController` enables this capability via pubsub broadcasts. |
| OUTRIDER-06 | Disconnected agents trigger offline state | `Phoenix.Presence` implicitly handles process death/leave. The UI projection can default to "offline" and map last-known reasons. |
| OUTRIDER-07 | Operator can see compaction vs raw diff | By querying `Scoria.Runtime.CompactedMemory` with `Scoria.Workflows.Event` sequences, we provide a notebook UI in `WorkflowLive.Show`. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_pubsub` | `2.1` | Distributes Presence state across nodes | Built-in to Phoenix [VERIFIED: codebase grep] |
| `Phoenix.Presence` | `1.7` | CRDT-based process tracking for live state | Native robust way to handle online/offline status in Elixir [CITED: hexdocs.pm/phoenix/Phoenix.Presence.html] |
| `Ecto.Query` | `3.10+` | Fetches durable metrics for the notebook | Core to Scoria architecture [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.Presence` | Custom heartbeat loop with Redis | Unnecessary dependency. `Phoenix.Presence` uses PubSub with no external infra and scales well for thousands of nodes. |
| Ecto UI Loading | Storing full context in LiveView assigns | `LiveView` becomes memory-heavy. Lazy async-loading `assign_async` is preferred for heavy evidence. |

## Architecture Patterns

### System Architecture Diagram
```text
  [External Runtime]
         │
         ▼ (SSE Stream / MCP)
  [ScoriaWeb.MCPController]
         │
         ├─> Tracks connection in `ScoriaWeb.Presence` (Ephemeral)
         │       └─> PubSub broadcast "runtime:presence:tenant_id"
         │
         └─> Saves events to `Scoria.Workflows.Event`
                 │
                 ▼ (Oban background job Phase 28)
           [SummarizeWorker] ─> Writes to `Scoria.Runtime.CompactedMemory`
                 │
                 ▼
  [ScoriaWeb.OrchestratorLive] <─ Listens to Presence PubSub 
    (Displays Status Card)

  [ScoriaWeb.WorkflowLive.Show] <─ Queries `CompactedMemory` + `Event`
    (Notebook UI)
```

### Recommended Project Structure
```text
lib/
├── scoria_web/
│   ├── presence.ex                       # New: Phoenix.Presence definition
│   ├── live/
│   │   ├── orchestrator_live.ex          # Update: subscribe to presence
│   │   ├── workflow_live/show.ex         # Update: Compaction audit layout
│   ├── components/
│   │   ├── runtime_posture_component.ex  # New: Presence card
│   │   ├── compaction_notebook_component.ex # New: Memory notebook
```

### Pattern 1: Ephemeral Presence with Durable Identity
**What:** Use Phoenix.Presence to track the active TCP/SSE connections but merge it with the durable state derived from `Scoria.Runtime.Instance` or equivalent Ecto models.
**When to use:** Tracking external systems that repeatedly connect/disconnect.
**Example:**
```elixir
# Source: [ASSUMED] Standard Elixir pattern
# In ScoriaWeb.MCPController
runtime_id = conn.params["runtime_id"] || Ecto.UUID.generate()
ScoriaWeb.Presence.track(self(), "runtimes:presence:\#{tenant_id}", runtime_id, %{
  status: "connected",
  session_id: session_id,
  connected_at: System.system_time(:second)
})
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Presence Tracking | Custom GenServer Pinging | `Phoenix.Presence` | Handles split-brain (netsplits) and node deaths automatically using CRDTs. |
| Async UI Loading | Manual `send(self(), :load)` | LiveView `assign_async/3` | Built-in, handles loading/error states cleanly without explicit message handling [VERIFIED: codebase grep `OrchestratorLive`]. |

## Common Pitfalls

### Pitfall 1: Bloated Presence Payload
**What goes wrong:** Adding too much metadata to the `Phoenix.Presence.track` call (like full session history or large JSON).
**Why it happens:** Attempting to render the full dashboard from Presence data directly.
**How to avoid:** Store ONLY `status`, `connected_at`, and linkage IDs (`session_id`) in Presence. Use `ScoriaWeb.Presence.fetch/2` or `OrchestratorLive` projections to fetch durable metadata from Ecto based on the tracked ID.
**Warning signs:** High PubSub latency or LiveView crashes due to large diff payloads.

### Pitfall 2: Treating Socket Openness as "Healthy"
**What goes wrong:** Relying on the TCP socket to claim an agent is perfectly functional.
**Why it happens:** SSE connections can remain open in a half-dead state.
**How to avoid:** Render it strictly as "Connected" (transport layer), not "Healthy" (application layer), unless explicit heartbeats are sent.
**Warning signs:** Using terminology like "Degraded" without an SLA contract.

## Code Examples

### Tracking Presence
```elixir
# Source: [CITED: hexdocs.pm/phoenix/Phoenix.Presence.html]
defmodule ScoriaWeb.Presence do
  use Phoenix.Presence, otp_app: :scoria,
                        pubsub_server: Scoria.PubSub
end
```

### Compaction Evidence Component Template
```elixir
# Source: [ASSUMED] Adherence to Phase 29 design constraints
defmodule ScoriaWeb.CompactionNotebookComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div class="rounded-xl border border-stone-200 bg-white shadow-sm p-4">
      <div class="flex items-center justify-between mb-2">
        <span class="text-xs font-mono">Sequences: <%= @memory.start_sequence %> - <%= @memory.end_sequence %></span>
        <span class="text-xs text-stone-500"><%= @memory.token_count %> archived tokens</span>
      </div>
      <p class="text-sm font-medium"><%= @memory.summary_text %></p>
      
      <details class="mt-4">
        <summary class="text-xs text-blue-600 cursor-pointer">View Raw Archived Events</summary>
        <div class="mt-2 space-y-2 bg-stone-50 p-2 rounded">
          <div :for={event <- @events} class="text-xs font-mono">
            [<%= event.sequence %>] <%= event.event_type %>
          </div>
        </div>
      </details>
    </div>
    """
  end
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Standard Elixir pattern for Presence merge | Architecture Patterns | Minor UI data fetching refactor required. |
| A2 | Adherence to Phase 29 design constraints for notebook | Code Examples | Design might need tweak if it fails strict CSS tests, but structure is sound. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond existing standard Elixir/Phoenix stack).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OUTRIDER-02 | Dashboard displays connected agents via Presence | unit/integration | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ Wave 0 |
| OUTRIDER-06 | Disconnected agents trigger offline state | unit/integration | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ Wave 0 |
| OUTRIDER-07 | Operator can see compaction vs raw diff in notebook | unit/integration | `mix test test/scoria_web/live/workflow_live_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements through `orchestrator_live_test.exs` and `workflow_live_test.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | MCP / Connector specific Auth |
| V3 Session Management | yes | `Phoenix.Presence` |
| V4 Access Control | yes | LiveView tenant checks |
| V5 Input Validation | yes | Ecto Changeset validations |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-Tenant Data Leakage | Information Disclosure | Filter Ecto queries and Presence PubSub topics securely by `tenant_id`. |
| Unbounded SSE Payload | Denial of Service | Terminate or ignore oversized MCP payloads before passing to JSON-RPC parser. |

## Sources

### Primary (HIGH confidence)
- Codebase Grep - Verified existing Phoenix ecosystem, `OrchestratorLive` setup, `WorkflowLive.Show` structures.
- Elixir/Phoenix Official Docs - Confirmed `Phoenix.Presence` API shapes.

### Secondary (MEDIUM confidence)
- Architectural reasoning on splitting `Phoenix.Presence` ephemeral state from Ecto Durable state.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir concepts align with exact decisions required.
- Architecture: HIGH - Mapped strictly to Scoria's constraints and Phase 28 prior art.
- Pitfalls: HIGH - Documented standard Phoenix live-state gotchas.

**Research date:** 2026-05-19
**Valid until:** 2026-06-19
