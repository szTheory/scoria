---
phase: 07
slug: seismograph
status: planned
nyquist_compliant: true
wave_0_required: false
created: 2026-05-11
---

# Phase 7 - Validation Strategy

## Phase Goal

Harden Scoria into a Phoenix-native control plane that can reserve and reconcile spend, stop unsafe external effects with circuit breakers, emit SLO-grade evidence, export durable audit facts, raise reviewable incidents, and project the full evidence trail inside the existing trace-first dashboard.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test test/scoria/sre/budget_engine_test.exs test/scoria/mcp/executor_test.exs test/scoria/workflows/runtime_test.exs` |
| Full suite command | `MIX_ENV=test mix test` |
| Estimated feedback loop | targeted suites under 30 seconds, full suite at plan-wave boundaries |

## Requirement Mapping

| Requirement | Covered By Plans | Primary Verification Commands |
|-------------|------------------|-------------------------------|
| SRE-01 | `07-06`, `07-07`, `07-02` | `MIX_ENV=test mix test test/scoria/sre_test.exs`, `MIX_ENV=test mix test test/scoria/sre/budget_engine_test.exs` |
| SRE-02 | `07-02` | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs` |
| SRE-03 | `07-03` | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs` |
| SRE-04 | `07-03`, `07-04`, `07-05` | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs`, `MIX_ENV=test mix test test/scoria/sre/incident_test.exs`, `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs` |
| SRE-05 | `07-04` | `MIX_ENV=test mix test test/scoria/sre/audit_outbox_test.exs test/scoria/mcp/executor_test.exs` |
| SRE-06 | `07-04`, `07-08` | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs`, `MIX_ENV=test mix test test/scoria/sre/relay_test.exs` |
| SRE-07 | `07-05` | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs` |
| SRE-08 | `07-01`, `07-06`, `07-07`, `07-02`, `07-03`, `07-04`, `07-05`, `07-08` | `MIX_ENV=test mix test test/scoria/sre_test.exs test/scoria/sre/telemetry_test.exs test/scoria/sre/relay_test.exs` |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 07-01-01 | 01 | 1 | SRE-08 | T-07-01-03 | Hammer and Fuse land as explicit first-class dependencies for Phase 7 control-plane behavior | unit | `MIX_ENV=test mix test test/scoria/sre_test.exs` | planned |
| 07-01-02 | 01 | 1 | SRE-08 | T-07-01-01 | Audit and alert sink contracts stay optional-adapter seams instead of hidden runtime globals | unit | `MIX_ENV=test mix test test/scoria/sre_test.exs` | planned |
| 07-06-01 | 06 | 2 | SRE-01,SRE-08 | T-07-06-01 | Budget policies, reservations, and breaker trips are durable and additive in Ecto | unit | `MIX_ENV=test mix test test/scoria/sre_test.exs` | planned |
| 07-06-02 | 06 | 2 | SRE-01,SRE-08 | T-07-06-03 | `Scoria.SRE` owns budget and breaker writes through explicit APIs and `Ecto.Multi` boundaries | unit | `MIX_ENV=test mix test test/scoria/sre_test.exs` | planned |
| 07-02-01 | 02 | 3 | SRE-01,SRE-02 | T-07-02-01 | Reserve-before-effect and reconcile-after-effect semantics are enforced with reason-coded failures | unit | `MIX_ENV=test mix test test/scoria/sre/budget_engine_test.exs` | planned |
| 07-02-02 | 02 | 3 | SRE-02,SRE-08 | T-07-02-02 | Workflow and MCP seams reject over-budget or looping work before side effects begin | unit | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs` | planned |
| 07-07-01 | 07 | 3 | SRE-01,SRE-08 | T-07-07-01 | Alert, incident, delivery, and audit durable nouns store redacted refs, versioned evidence, and stable dedupe keys | unit | `MIX_ENV=test mix test test/scoria/sre_test.exs` | planned |
| 07-03-01 | 03 | 4 | SRE-03 | T-07-03-01 | Fuse breakers guard provider, remote MCP, and other external effects only | unit | `MIX_ENV=test mix test test/scoria/workflows/runtime_test.exs test/scoria/mcp/executor_test.exs` | planned |
| 07-03-02 | 03 | 4 | SRE-04,SRE-08 | T-07-03-02 | Low-cardinality SLI telemetry includes reason codes, version refs, and deep-link evidence metadata | unit | `MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs` | planned |
| 07-04-01 | 04 | 5 | SRE-05 | T-07-04-01 | Sensitive audit facts are written transactionally at workflow and MCP execution seams before relay fanout and exported redacted | integration | `MIX_ENV=test mix test test/scoria/sre/audit_outbox_test.exs test/scoria/mcp/executor_test.exs` | planned |
| 07-04-02 | 04 | 5 | SRE-04,SRE-06 | T-07-04-02 | Stable incident keys dedupe alerts while preserving scorer/baseline evidence and severity routing | unit | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs` | planned |
| 07-05-01 | 05 | 6 | SRE-07 | T-07-05-01 | Operators inspect a compact health rollup plus budget, breaker, incident, and audit evidence inside the existing trace-first LiveView | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs` | planned |
| 07-05-02 | 05 | 6 | SRE-04,SRE-07,SRE-08 | T-07-05-02 | Incident surfaces deep-link to trace evidence, feed the composite health rollup, and load heavy detail asynchronously | liveview | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs` | planned |
| 07-08-01 | 08 | 6 | SRE-06 | T-07-08-01 | Relay workers claim durable rows under supervision and keep failed deliveries retryable | unit | `MIX_ENV=test mix test test/scoria/sre/relay_test.exs` | planned |
| 07-08-02 | 08 | 6 | SRE-06,SRE-08 | T-07-08-02 | Optional adapters stay envelope-oriented, configurable, and harmless when absent | unit | `MIX_ENV=test mix test test/scoria/sre/relay_test.exs` | planned |

## Sampling Rate

- After each task commit: run the task’s targeted command from the table above.
- After each plan: run the plan-level targeted suite named in the plan’s `<verify>`.
- After waves 4, 5, and 6: run `MIX_ENV=test mix test`.
- Before verification/UAT: full suite must be green.

## Multi-Source Coverage Audit

### GOAL Coverage

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Production-grade control plane with budgets, breakers, audit export, incidents, and ecosystem helper seams | `07-01` through `07-05`, `07-08` |
| GOAL | Durable SRE storage substrate beneath runtime and UI slices | `07-06`, `07-07` |

### REQ Coverage

| Source | Item | Covered By |
|--------|------|------------|
| REQ | SRE-01 | `07-06`, `07-07`, `07-02` |
| REQ | SRE-02 | `07-02` |
| REQ | SRE-03 | `07-03` |
| REQ | SRE-04 | `07-03`, `07-04`, `07-05` |
| REQ | SRE-05 | `07-04` |
| REQ | SRE-06 | `07-04`, `07-08` |
| REQ | SRE-07 | `07-05` |
| REQ | SRE-08 | `07-01`, `07-06`, `07-07`, `07-02`, `07-03`, `07-04`, `07-05`, `07-08` |

### RESEARCH Coverage

| Source | Item | Covered By |
|--------|------|------------|
| RESEARCH | `Scoria.SRE` as the public context | `07-01` |
| RESEARCH | Additive migration, durable schemas, and persistence helpers | `07-06`, `07-07`, `07-04` |
| RESEARCH | Runtime guard at `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor` | `07-02`, `07-03` |
| RESEARCH | Fuse around external effects only | `07-03` |
| RESEARCH | Telemetry-driven Parapet helper, no deep dependency | `07-03` |
| RESEARCH | Transactional outbox plus supervised relay | `07-04`, `07-08` |
| RESEARCH | Optional Threadline, Chimeway, Mailglass adapters with no-op defaults | `07-08` |
| RESEARCH | Trace-first LiveView incident evidence and dashboard health rollup | `07-05` |

### CONTEXT Decision Coverage

| Decision | Covered By |
|----------|------------|
| D-01 | `07-01`, `07-06`, `07-02` |
| D-02 | `07-02` |
| D-03 | `07-03` |
| D-04 | `07-02` |
| D-05 | `07-02` |
| D-06 | `07-07`, `07-03`, `07-04` |
| D-07 | `07-03` |
| D-08 | `07-03`, `07-05` |
| D-09 | `07-04` |
| D-10 | `07-05` via composite dashboard health rollup plus trace-first notebook |
| D-11 | `07-03`, `07-04` |
| D-12 | `07-07`, `07-04` |
| D-13 | `07-04` |
| D-14 | `07-08` |
| D-15 | `07-04` |
| D-16 | `07-07`, `07-04` |
| D-17 | `07-01` through `07-08` |
| D-18 | `07-01`, `07-08` |
| D-19 | `07-08` |
| D-20 | `07-03` |
| D-21 | `07-05` |
| D-22 | `07-06`, `07-07`, `07-03`, `07-04` |
| D-23 | `07-04`, `07-05` |
| D-24 | `07-07`, `07-03`, `07-05` |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Calm incident readability under a long evidence notebook | SRE-07 | visual judgment on density and prioritization | Load a run with at least one budget warning, one breaker trip, and one review-only incident; confirm the panel remains trace-first, that paging vs review severity is visually distinct, and that each row deep-links to evidence without expanding raw payloads by default. |

## Validation Sign-Off

- [x] Every requirement maps to at least one plan and targeted automated command.
- [x] Every task has an automated verify command.
- [x] No verification relies on `mix test` alone.
- [x] Deferred scope such as anomaly detection, auto-remediation, and complex alert trees is excluded.
- [x] Locked decisions are traced to plan coverage.
