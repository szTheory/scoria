# Phase 3: LiveView Operator UX - Validation Strategy

This validation strategy ensures the core features built in Phase 3 meet all Nyquist compliance mandates and satisfy the Success Criteria outlined in `ROADMAP.md`.

## Success Criteria Mapping

### 1. User can view deeply nested trace trees without browser lag, utilizing lazy rendering.
**Verification Strategy**:
- ExUnit tests assert the router macro properly handles the LiveView mount.
- A LiveView test mounts the OrchestratorLive and asserts rendering of nested dummy elements.
- Ensure `assign_async` is properly unit tested to verify that deep span metadata fetching occurs without blocking the main render loop.

### 2. Real-time streaming tokens render efficiently without spiking CPU or DOM updates, utilizing coalescing.
**Verification Strategy**:
- LiveView tests simulate sending 100 fast token updates.
- Verify that only a single (or very few) flush events occur and the final token output is successfully rendered on the screen.

### 3. High-risk tool calls trigger an interactive approval modal for an admin, pausing the actual execution process until resolved.
**Verification Strategy**:
- Test the receipt of `hitl_request` messages via LiveView test handlers.
- Assert the modal renders successfully.
- Assert that clicking 'Approve' or 'Reject' correctly executes an Ecto Repo update for the pending approval.

### 4. Day-0 users can install the dashboard via a `mix scoria.install` task with zero manual configuration.
**Verification Strategy**:
- Automated test runs `mix scoria.install` in a dummy environment and validates that the output correctly injects the macro and tailwind content patterns.

## Execution Requirements
All tests executing these strategies must be written using `ExUnit` and executed via `mix test`. No manual tests are acceptable for phase completion. Every acceptance criteria test must be automated to ensure strict Nyquist compliance.