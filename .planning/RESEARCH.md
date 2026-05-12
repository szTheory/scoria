# Phase 3: LiveView Operator UX - Research

**Researched:** 2024-05-18
**Domain:** Elixir/Phoenix LiveView UI, Real-time Streaming
**Confidence:** HIGH

<user_constraints>
## Project Constraints (from GEMINI.md)
- **Ash Framework:** Do not attempt to integrate with or use the Ash framework. We are strictly all-in on standard Phoenix and Ecto architectures.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Build a Root orchestrator LiveView mounted via the host Phoenix application's router (including `mix scoria.install` generator). | Research verifies `defmacro scoria_dashboard` approach mapped to `live_session`. |
| UI-02 | Develop a Visual Trace Explorer with lazy-loading for deep trace trees and CSS grid-based nested visualization. | Research recommends CSS Grid for deep nesting to avoid DOM bloat, and `stream` for lazy loading. |
| UI-03 | Implement asynchronous token stream rendering with coalescing (buffering) to prevent DOM bloat and CPU spikes. | Research confirms `Process.send_after` buffering pattern (50-100ms interval) to coalesce token updates. |
| UI-04 | Build Human-in-the-Loop (HITL) tool approval modals triggered via PubSub for high-risk tools. | Research outlines PubSub subscription + OTP Task `receive` with long/infinite timeout. |
| UI-05 | Connect real-time PubSub subscriptions (`scoria:runs:tenant_id`) for passive UI updates. | Research confirms `Phoenix.PubSub.subscribe/2` in LiveView `mount/3`. |
</phase_requirements>

## Summary

This phase implements an embedded, operator-first LiveView control plane for the Scoria observability suite. The dashboard must integrate seamlessly into host Phoenix applications via a router macro (similar to `phoenix_live_dashboard`). The UI handles complex AI-specific requirements: rendering deep trace trees efficiently without DOM bloat, managing high-frequency token streams without spiking CPU, and enabling Human-in-the-Loop (HITL) execution pauses.

**Primary recommendation:** Use an embedded LiveView macro (`scoria_dashboard`) in the router, CSS Grid for trace tree layout, and server-side coalescing (`Process.send_after` with ~75ms interval) for token streams.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Router Integration | API / Backend | — | Host app router integration allows embedding LiveView at a specific scope via macro. |
| Trace Explorer | Frontend Server (SSR) | Browser / Client | LiveView handles tree structure, streams handle lazy loading, CSS grid manages deep layout. |
| Token Coalescing | Frontend Server (SSR) | — | LiveView buffers incoming tokens and flushes every ~75ms to minimize WebSocket and DOM diff overhead. |
| HITL Tool Approval | Frontend Server (SSR) | API / Backend | LiveView subscribes to PubSub. Renders modal. Publishes approval back to executing OTP Task. |
| Real-time Updates | Frontend Server (SSR) | — | Phoenix PubSub integrated directly into LiveView `mount` for pushing state updates. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | v1.0+ | Interactive dashboard UI | Project standard; built-in real-time capabilities. |
| Phoenix PubSub | Standard | Internal event broadcasting | Core Phoenix technology for real-time node communication. |
| Elixir `Task` / `Process` | Standard | Async execution & timers | Built-in OTP patterns for HITL pausing and token coalescing. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CSS Grid | Native | Layout / Indentation | Use for rendering deep trace trees to avoid HTML nesting limitations and DOM bloat. |

## Architecture Patterns

### System Architecture Diagram

```
[Host App Router] --> (scoria_dashboard macro) --> [Scoria LiveSession]
                                                         |
                                                         v
[OTP Tasks/Actors] <--(Phoenix PubSub: hitl/tokens)--> [Scoria LiveView Components]
  |                                                      |
  v                                                      v
(Executes tool or           (Receives Token chunks, buffers 75ms) -> [Browser DOM]
 waits on receive)          (Receives HITL event, displays Modal) -> [Browser DOM]
```

### Recommended Project Structure
```
lib/
├── scoria_web/
│   ├── components/            # UI Components (Trace Explorer, HITL Modal)
│   ├── live/                  # LiveView Pages (Orchestrator)
│   └── router.ex              # Scoria Router Macro Definitions
├── scoria/
│   └── observe/               # Backend logic for trace queries & approvals
└── mix/
    └── tasks/
        └── scoria.install.ex  # Mix task for installing dashboard
```

### Pattern 1: Embeddable Router Macro
**What:** Creating a router macro that allows the host app to embed Scoria.
**When to use:** To mount the `ScoriaWeb.OrchestratorLive` directly in the host's `router.ex`.
**Example:**
```elixir
# Source: Phoenix LiveDashboard standard pattern
defmodule ScoriaWeb.Router do
  defmacro scoria_dashboard(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.Router, only: [get: 4, post: 4, put: 4]
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]
        
        live_session :scoria_dashboard, [
          session: {ScoriaWeb.Router, :__session__, [opts]}
        ] do
          live "/", ScoriaWeb.OrchestratorLive, :index
        end
      end
    end
  end
end
```

### Pattern 2: Token Coalescing (Buffering)
**What:** Delaying high-frequency LLM token updates to avoid LiveView DOM and CPU bloat.
**When to use:** Whenever receiving real-time token streams via PubSub or direct messages.
**Example:**
```elixir
# Source: Elixir ecosystem standard for LiveView token streams
def handle_info({:token, token}, socket) do
  new_buffer = [token | socket.assigns.token_buffer]
  
  socket = 
    if socket.assigns.timer_ref == nil do
      ref = Process.send_after(self(), :flush_tokens, 75)
      assign(socket, timer_ref: ref)
    else
      socket
    end

  {:noreply, assign(socket, token_buffer: new_buffer)}
end

def handle_info(:flush_tokens, socket) do
  new_chunk = socket.assigns.token_buffer |> Enum.reverse() |> Enum.join("")
  {:noreply, 
   socket 
   |> assign(full_text: socket.assigns.full_text <> new_chunk)
   |> assign(token_buffer: [], timer_ref: nil)}
end
```

### Anti-Patterns to Avoid
- **Deep HTML div nesting for trees:** Do not use `div` inside `div` for every level of the AI trace tree. Browsers struggle with very deep DOMs. Use a flat list with CSS variables (`--indent-level`) or CSS Grid.
- **Immediate Socket Assignment on Tokens:** Do not call `assign/2` and let LiveView diff the DOM for every single token received. It will crash the browser/process for fast models.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Client-side token throttling | JS hooks for `phx-debounce` | `Process.send_after` | Server-side debouncing prevents CPU waste in the Elixir process and reduces WebSocket traffic. |

**Key insight:** LLMs can stream tokens far faster than browsers can efficiently diff the DOM. Buffering on the server using OTP timer events is the standard Elixir solution.

## Common Pitfalls

### Pitfall 1: CSS Isolation
**What goes wrong:** The embedded LiveView inherits host application CSS which breaks Scoria UI, or Scoria CSS overrides the host.
**Why it happens:** Shared class names (e.g., Tailwind defaults) across boundaries.
**How to avoid:** Namespace Scoria's CSS or rely completely on semantic Tailwind classes scoped tightly to a `.scoria-dashboard` wrapper.

### Pitfall 2: Task Timeout during HITL
**What goes wrong:** A human is prompted to approve a tool execution, but before they click "Approve", the tool execution crashes.
**Why it happens:** The `Task.await` or `receive` block waiting for the PubSub approval has a standard 5000ms timeout.
**How to avoid:** Ensure the `receive` block waiting for human approval uses an `:infinity` timeout or a very generous duration (e.g., 5 minutes).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Deep DOM tree nesting | CSS Grid / Flat DOM | LiveView era | Massive performance boost for rendering deep recursion |
| Client JS throttling | Server-side coalescing | Ongoing | Less bandwidth, lower Elixir CPU usage |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] CSS Grid is sufficient for flat DOM trees. | Patterns | Might still need JS virtual scrolling if trees get > 1000 nodes. |
| A2 | [ASSUMED] Host app uses standard Phoenix Router. | Patterns | `scoria_dashboard` macro will fail if the host uses a non-standard router. |

## Open Questions

1. **CSS Distribution**
   - What we know: Scoria UI is embedded in host apps.
   - What's unclear: Does Scoria bundle a pre-compiled CSS file like LiveDashboard, or assume the host has Tailwind configured to scan Scoria's `deps` directory?
   - Recommendation: Use inline Tailwind classes and instruct the host in the `mix scoria.install` output to add `deps/scoria/lib/**/*.*ex` to their `tailwind.config.js`.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified outside of the Elixir/Phoenix ecosystem).

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
| UI-01 | Router macro definition | unit | `mix test test/scoria_web/router_test.exs` | ❌ Wave 0 |
| UI-02 | Trace Explorer component | unit | `mix test test/scoria_web/components/trace_tree_component_test.exs` | ❌ Wave 0 |
| UI-03 | Token stream coalescing | unit | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ❌ Wave 0 |
| UI-04 | HITL PubSub triggers | unit | `mix test test/scoria_web/live/orchestrator_live_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria_web/router_test.exs` — covers UI-01
- [ ] `test/scoria_web/live/orchestrator_live_test.exs` — covers UI-03, UI-04
- [ ] `test/scoria_web/components/trace_tree_component_test.exs` — covers UI-02

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host app router `pipe_through :browser, :admin_auth` wrapper |
| V3 Session Management | yes | Host app session handling |
| V4 Access Control | yes | Sigra (via project requirements) for UI RBAC |
| V5 Input Validation | yes | Ecto Changesets for UI inputs |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir / LiveView

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-Site Scripting (XSS) in Trace content | Spoofing | Rely on LiveView's default HTML escaping (avoid `raw/1` on trace outputs). |
| Unauthorized HITL Approval | Elevation of Privilege | Validate actor session context before broadcasting approval event. |

## Sources

### Primary (HIGH confidence)
- Phoenix LiveView Docs - [How LiveView Router macros work]
- Phoenix LiveDashboard Source - [How to implement embedded dashboard macros]

### Secondary (MEDIUM confidence)
- ElixirForum / Community - [Server-side token buffering with Process.send_after]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Phoenix concepts (LiveView, PubSub).
- Architecture: HIGH - Adheres strictly to Phoenix idiomatic patterns.
- Pitfalls: HIGH - Known limits of WebSocket DOM diffing with high-frequency streams.

**Research date:** 2024-05-18
**Valid until:** 2025-05-18

## External Reference

- AWS Bedrock AgentCore lessons captured in `.planning/research/agentcore-lessons.md`.
