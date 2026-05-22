# Plan 01 Summary: Ecto-backed Runtime Identity

## Work Completed
- **Schema and Migration:** Created the `Scoria.Runtime.Instance` schema and corresponding Ecto migration for `runtime_instances`. This establishes durable truth for runtime identity with fields for `tenant_id`, `host_session_id`, `current_run_id`, `first_seen_at`, `last_seen_at`, `terminal_offline_reason`, and `transport_kind`.
- **Context API:** Implemented `Scoria.Runtime.register_instance/1` for upserting runtime instance records (updating `last_seen_at` and clearing offline reasons) and `Scoria.Runtime.mark_offline/2` to durably record when and why a runtime disconnected.
- **Testing:** Added and verified tests for the schema changeset (`instance_test.exs`) and the context functions (`runtime_test.exs`).

## Next Steps
- State must be advanced via `gsd-sdk query state.advance-plan`.
- Proceed to execute `29-02-PLAN.md` to integrate ephemeral Phoenix Presence with this durable truth.
