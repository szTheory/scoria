---
phase: "02-mcp-gateway"
plan: "03"
subsystem: "mcp"
tags:
  - execute
  - tdd
  - isolation
  - telemetry
dependency_graph:
  requires: ["02-01", "02-02"]
  provides: ["end-to-end-mcp-pipeline", "task-isolation"]
  affects: ["lib/scoria/mcp/router.ex", "lib/scoria/application.ex"]
tech_stack:
  added: ["Task.Supervisor", ":telemetry"]
  patterns: ["Task Isolation", "Event Logging"]
key_files:
  created:
    - lib/scoria/mcp/executor.ex
    - test/scoria/mcp/executor_test.exs
  modified:
    - lib/scoria/mcp/router.ex
    - test/scoria/mcp/router_test.exs
    - lib/scoria/application.ex
key_decisions:
  - "Use `Task.Supervisor.async_nolink/2` for tool isolation to ensure crashing tools do not bring down the Plug connection/HTTP request caller."
  - "Default tool execution timeout is 5000ms with `Task.shutdown(task, :brutal_kill)` fallback."
metrics:
  duration: 3
  tasks_completed: 2
  files_modified: 5
---

# Phase 02 Plan 03: End-to-end MCP pipeline with tool execution isolation Summary

End-to-end MCP pipeline wired with telemetry audit logging and OTP-isolated tool execution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Fixed crashing tests due to caller task linking**
- **Found during:** Task 1
- **Issue:** Using `Task.async` links the spawned task to the caller, meaning crashing tools took down the caller (test process and would take down HTTP plug processes).
- **Fix:** Added a `Task.Supervisor` named `Scoria.MCP.TaskSupervisor` to `Scoria.Application` and changed `Executor` to use `Task.Supervisor.async_nolink`.
- **Files modified:** `lib/scoria/application.ex`, `lib/scoria/mcp/executor.ex`
- **Commit:** b768cb7

**2. [Rule 1 - Bug] Fixed Ecto changeset validation type casting mismatch**
- **Found during:** Task 2
- **Issue:** Tool inputs define schemas and validation goes through Ecto changesets. `Ecto.Changeset.apply_changes/1` for schemaless maps returns atom keys, but our DummyTool test expected string keys, causing a mismatch. Also, missing actor context on unregistered tools caused `Map.merge` in `Executor` to throw `BadMapError`.
- **Fix:** Changed DummyTool to match on atom keys. Added `context = context || %{}` to `Executor.execute`.
- **Files modified:** `test/scoria/mcp/router_test.exs`, `lib/scoria/mcp/executor.ex`
- **Commit:** ea99aab

## TDD Gate Compliance
- `test(02-03): add failing test for executor` - RED gate
- `feat(02-03): implement isolated executor with telemetry` - GREEN gate
## Self-Check: PASSED
