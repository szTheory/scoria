# Phase 3 Decisions: LiveView Operator UX

This document captures the architectural decisions for Phase 3, generated via deep research to optimize for the "szTheory" Unix philosophy, developer ergonomics, and lessons from the broader ecosystem.

## 1. Human-in-the-Loop (HITL) Execution Blocking

**Decision:** Ecto State Machine with Durable Checkpoints
**Status:** Approved

**Rationale:**
While In-Memory OTP Blocking (GenServer `receive` or `Task.await`) leverages native Elixir primitives for minimal latency, it directly contradicts Scoria's "szTheory" DNA, which mandates Ecto-native state and an operator-first developer experience. Real-world lessons from ecosystem tools like LangGraph demonstrate that Human-in-the-Loop workflows require durable checkpointing to survive server deployments and application restarts. 

By serializing the run state into an Ecto State Machine:
1. **Resilience:** The execution process exits while waiting for human input. If the server restarts or deploys during a 30-minute wait, the state is not lost.
2. **LiveView Synergy:** The embedded LiveView dashboard can easily query, visualize, and approve `PendingApprovals` natively from Ecto on mount, without relying on brittle PubSub coordination or interrogating running GenServers across a cluster.
3. **Auditability:** Every state transition (e.g., `running` -> `waiting_approval` -> `approved`) becomes a durable Ecto transaction, making Threadline audit logging trivial.

*Tradeoff:* Introduces slightly higher Day-0 complexity with database migrations, but guarantees Day-2 operational simplicity and true reliability for long-running workflows.

## 2. Trace Tree Visualization State

**Decision:** Lazy Rendering via `assign_async` and `LiveComponent`
**Status:** Approved (Shifted Left)

**Rationale:**
A complex AI agent loop might generate hundreds of spans. Visualizing this synchronously bloats the LiveView DOM and spikes server memory. Following the "Operator-First DX" requirement:
- Only the root run, immediate children, and any failed spans are fetched on the initial dashboard mount.
- Child nodes are kept collapsed by default. 
- When an operator expands a node, the UI uses LiveView 0.20+ `assign_async` to fetch the deep span metadata in an isolated process. This keeps the Day-0 UI "snappy" while preserving Day-2 debugging depth.

## 3. Real-Time Streaming (Token Coalescing)

**Decision:** LiveView Buffered Ticker (Coalescing) over 1:1 PubSub Renders
**Status:** Approved (Shifted Left)

**Rationale:**
If a fast model (like Groq or a local vLLM) generates tokens rapidly, sending a `handle_info` message to LiveView for *every single token* will thrash the DOM and lock up the browser.
- The underlying execution engine streams tokens via PubSub.
- The LiveView dashboard subscribes but *buffers* the tokens into an internal queue in the socket assigns.
- A `:timer.send_interval(50)` flush event pushes the coalesced buffer to the DOM at a controlled 20fps/50ms rate using `phx-update="stream"`.
- This ensures the UI remains completely responsive and feels "alive" (adhering to the Scoria Brand Book), while structurally protecting the server from CPU spikes.
