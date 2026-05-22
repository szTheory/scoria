# Phase 29: External Runtime Observability & Operator UX - Validation Strategy

This validation strategy ensures the external runtime observability features built in Phase 29 meet all Nyquist compliance mandates and satisfy the Success Criteria.

## Success Criteria Mapping

### 1. External runtime tracking using Scoria-owned ID
**Verification Strategy**:
- Automated tests verify `Scoria.Runtime.Instance` records are created correctly.
- Assert that Phoenix Presence uses the Scoria-owned `instance.id` as the presence tracking key, enforcing separation from host `session_id`.

### 2. Dashboard displays accurate typed offline reasons
**Verification Strategy**:
- Trigger external runtime disconnection events inside tests.
- Assert that the offline reason (e.g., `transport_closed`) is captured durably on the `Scoria.Runtime.Instance` Ecto record.
- Assert that LiveView `RuntimeDetailDrawerComponent` explicitly renders the correct offline reason badge when a runtime is offline.

### 3. Cross-linking between runtime cards and workflows
**Verification Strategy**:
- ExUnit tests assert the existence of reciprocal HTML links.
- `runtime_detail_drawer_component_test.exs` ensures the runtime card links directly to the active workflow.
- `workflow_live_test.exs` ensures the workflow page links directly back to the active runtime drawer/snapshot.

### 4. Memory compaction auditability without fake diffs
**Verification Strategy**:
- Generate test `CompactedMemory` records matching the schema.
- Assert `MemoryNotebookComponent` lazy-loads raw events properly using LiveView `assign_async`.
- Assert component explicitly renders sequence boundaries and LLM summaries chronologically, using `incident_evidence_component.ex` conventions without relying on unproven structural text diffs.
