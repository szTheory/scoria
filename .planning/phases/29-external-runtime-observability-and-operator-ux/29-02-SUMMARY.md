# Plan 02 Summary: Phoenix Presence for External Runtimes

## Work Completed
- **Presence Setup:** Created `ScoriaWeb.Presence` and added it to the supervision tree to manage real-time presence data for external runtime connections. Tests pass.
- **Connection Tracking:** Updated `ScoriaWeb.MCPController.sse/2` to leverage the durable Ecto-backed truth established in Plan 01.
  - When an SSE connection is made, `Scoria.Runtime.register_instance/1` is called to establish a durable connection ID.
  - Phoenix Presence tracks the live connection keyed by this exact `instance.id` (avoiding the ephemeral `session_id`).
  - Terminal reasons (`transport_closed`) are caught in a `try/after` block and durably stored in Ecto when the stream ends.
- **Testing:** Adapted the controller test `mcp_controller_test.exs` to support Ecto Sandbox checkout since `sse/2` now reaches out to the database via `Scoria.Runtime`. Tests verified to pass.

## Next Steps
- State must be advanced via `gsd-sdk query state.advance-plan`.
- Proceed to execute `29-03-PLAN.md` for integrating LiveView operator dashboards.
