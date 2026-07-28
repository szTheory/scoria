---
schema_version: 1
open_count: 3
waived_count: 0
fixed_count: 0
total_count: 3
last_updated: 2026-07-28T21:29:00.341Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 56.1 | deviation | test/scoria/warning_inventory/capture_parity_test.exs | 53 | Pre-existing SEED-004-class full-suite ordering flake (acknowledged at v3.6 close); unrelated to plan-01 files, passes in isolation | open |  | 2026-07-28T20:02:34.337Z |  |
| 2 | 56.1 | deviation | test/scoria/observe/telemetry_test.exs | 245 | Full-suite-ordering flake (concurrent ETS handler-attach race), unrelated to workflows/rails files; passes in isolation (10 tests, 0 failures) | open |  | 2026-07-28T20:02:39.902Z |  |
| 3 | 56.1 | deviation | test/scoria_web/live/orchestrator_live_test.exs | 356 | SEC-01 orchestrator_live full-suite ordering flake (Bounds/buffer hydration), unrelated to plan 56.1-04's rails.ex/runtime.ex/run.ex changes; passes in isolation | open |  | 2026-07-28T21:29:00.341Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "56.1",
    "file": "test/scoria/warning_inventory/capture_parity_test.exs",
    "line": 53,
    "description": "Pre-existing SEED-004-class full-suite ordering flake (acknowledged at v3.6 close); unrelated to plan-01 files, passes in isolation",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:02:34.337Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "56.1",
    "file": "test/scoria/observe/telemetry_test.exs",
    "line": 245,
    "description": "Full-suite-ordering flake (concurrent ETS handler-attach race), unrelated to workflows/rails files; passes in isolation (10 tests, 0 failures)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:02:39.902Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "56.1",
    "file": "test/scoria_web/live/orchestrator_live_test.exs",
    "line": 356,
    "description": "SEC-01 orchestrator_live full-suite ordering flake (Bounds/buffer hydration), unrelated to plan 56.1-04's rails.ex/runtime.ex/run.ex changes; passes in isolation",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T21:29:00.341Z",
    "resolved_at": null
  }
]
````
