## Plan 09-03 Summary

- Persisted durable notification outcome semantics in `Scoria.SRE.Relay` so successful publishes now record `delivery_outcome` and `delivery_adapter` in delivery metadata while preserving `delivery_status` as the relay state.
- Carried `approval_id` through SRE incident evidence to let the orchestrator notebook render real approval lineage instead of fixture-only IDs.
- Expanded the incident evidence panel to show delivery outcome, transport mode, and transport sink alongside status, routing key, attempts, and errors.
- Replaced the primary SRE orchestrator evidence test with a real-path flow that creates a workflow approval request, records review/page incidents, drains relay deliveries, and verifies the rendered notebook ties approval, audit, incident, and delivery evidence back to the same run and trace.

## Verification

- `MIX_ENV=test mix test test/scoria/sre/relay_test.exs`
- `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs`
- `MIX_ENV=test mix test test/scoria/sre/relay_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria/workflows/integration_test.exs`
