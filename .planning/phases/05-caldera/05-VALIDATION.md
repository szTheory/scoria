# Phase 5 Validation: Durable Agent Workflows & Handoffs

## Phase Goal
Add a durable, operator-readable workflow layer to Scoria that persists stable run state, survives pauses and failures, supports bounded handoffs, and exposes a trace-first LiveView visualizer without turning Scoria into a generic workflow engine.

---

## Requirement Mapping & Verification

### WF-01. Durable workflow truth persists runs, steps, checkpoints, events, approvals, and handoffs in Ecto.
* **Covered By Plans:** 05-01, 05-02
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/workflows_test.exs` - asserts run creation, atomic transition writes, checkpoint persistence, approval linkage, and optimistic locking behavior.
  * **Automated:** `mix test test/scoria/workflows/runtime_test.exs` - asserts side-effect boundaries persist durable state before and after execution.

### WF-02. Workflow execution supports exact resume and retry-failed-step from persisted state.
* **Covered By Plans:** 05-02, 05-04
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/workflows/runtime_test.exs` - asserts runtime transitions to `failed`, `retrying`, and `completed` derive from stored checkpoints and step state.
  * **Automated:** `mix test test/scoria/workflows/integration_test.exs` - asserts restart-safe resume and retry flows across persisted checkpoints.

### WF-03. Handoffs are bounded delegated steps under a root-owned run with stable `role_id` and typed envelopes.
* **Covered By Plans:** 05-02, 05-04
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/workflows/handoff_test.exs` - asserts delegated-step creation, stable `role_id`, typed `handoff_input`, `step_result`, and projected-context-only payloads.
  * **Automated:** `mix test test/scoria/workflows/integration_test.exs` - asserts delegated steps remain owned by the root run across resume and completion paths.

### WF-04. Operator approvals are durable pauses backed by persisted state rather than PubSub or socket memory.
* **Covered By Plans:** 05-02, 05-03
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/workflows/approval_test.exs` - asserts approval waits are written before broadcasts, linked to workflow state, and guarded by optimistic locking.
  * **Automated:** `mix test test/scoria_web/live/workflow_live_test.exs` - asserts the UI renders waiting states and reflects approval decisions from persisted records.

### WF-05. Operators can inspect a trace-first workflow visualizer with lifecycle badges, checkpoint details, and timeline drilldown.
* **Covered By Plans:** 05-03
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria_web/live/workflow_live_test.exs` - asserts run page mounts, streams run updates, and loads detail metadata asynchronously.
  * **Automated:** `mix test test/scoria_web/components/workflow_tree_component_test.exs` - asserts nested step rendering, badge display, handoff markers, and selection behavior.

### WF-06. Jido remains optional and adapter-scoped rather than central to the public API.
* **Covered By Plans:** 05-04
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/workflows/jido_adapter_test.exs` - asserts Jido directives map into Scoria workflow nouns and durable events through the adapter boundary.
  * **Automated:** `mix test test/scoria/workflows/integration_test.exs` - asserts adapter-driven workflow execution still resolves through Scoria-owned lifecycle APIs.

### WF-07. Scoria preserves a minimal install and router integration story.
* **Covered By Plans:** 05-03
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/mix/tasks/scoria.install_test.exs` - asserts install task updates router and asset scanning for the workflow surface.
  * **Automated:** `mix test test/scoria_web/router_test.exs` - asserts the router macro mounts the workflow dashboard surface cleanly.

---

## Nyquist Compliance Checklist
- [ ] **WF-01:** Stable workflow transitions are persisted atomically with checkpoints, events, approvals, and handoffs.
- [ ] **WF-02:** Resume and retry derive next action from persisted state, not LiveView or GenServer memory.
- [ ] **WF-03:** Delegated steps preserve root ownership and typed handoff envelopes.
- [ ] **WF-04:** Approval waits survive disconnects and are visible to operators.
- [ ] **WF-05:** Workflow visualization is trace-first and lazily loads detail metadata.
- [ ] **WF-06:** Jido remains an optional adapter, not the public workflow contract.
- [ ] **WF-07:** Install and router integration remains minimal and test-covered.
