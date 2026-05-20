# Plan 03 Summary: Runtime Posture Rail and Detail Drawer

## Work Completed
- **Component Creation:** Created `ScoriaWeb.RuntimeDetailDrawerComponent` to render a compact drawer showing runtime detail including host session ID, transport kind, real-time status (online/offline), terminal offline reason, and reciprocal active workflow links. Verified component logic via ExUnit tests.
- **Presence Integration:** Updated `ScoriaWeb.OrchestratorLive` to subscribe to the `mcp:runtimes:#{tenant_id}` PubSub topic.
- **State Augmentation:** Implemented `load_operator_surface/1` in the LiveView to query recent `Scoria.Runtime.Instance` records from the database and merge their durable truth with the ephemeral Phoenix Presence data to accurately derive 'online' vs 'offline' states.
- **Dashboard UI:** Added the external runtime posture rail to the LiveView UI directly above the connector fleet posture, including drawer open/close handlers and real-time UI updates on presence diffs.

## Next Steps
- State must be advanced via `gsd-sdk query state.advance-plan`.
- Proceed to execute `29-04-PLAN.md` to tie external runtimes to active workflows.
