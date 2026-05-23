---
phase: 38-replay-safe-execution-tool-modes
verified: 2026-05-23T10:15:19Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: issues_found
  previous_score: 4/7
  issues_closed:
    - "Replay-safe adapters make execution mode explicit per tool/result class."
    - "Replay evidence rows record enough typed context to prove when a seam was blocked because the replay no longer exactly matched the original effect inputs or authority boundary."
    - "Replay evidence needed for later Phase 39 UI work is available through DTOs, not hidden in internal-only structs."
  issues_remaining: []
  regressions: []
---

# Phase 38: Replay-Safe Execution & Tool Modes Verification Report

**Phase Goal:** Replay execution preserves operator trust by defaulting unsafe effects to explicit safe modes.
**Verified:** 2026-05-23T10:15:19Z
**Status:** passed
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | External-write and approval-sensitive seams are blocked or historically stubbed by default during replay. | ✓ VERIFIED | `ReplayDisposition.resolve/5` still fail-closes replay seams in [lib/scoria/workflows/replay_disposition.ex](/Users/jon/projects/scoria/lib/scoria/workflows/replay_disposition.ex:14), and replay seam tests still refute live execution in [test/scoria/connectors/invocation_test.exs](/Users/jon/projects/scoria/test/scoria/connectors/invocation_test.exs:42) and [test/scoria/workflows/integration_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/integration_test.exs:263). |
| 2 | Replay-safe adapters make execution mode explicit per tool/result class. | ✓ VERIFIED | Runtime replay paths now emit typed provenance into persisted transition rows: `Runtime.replay_execution/6` produces replay payloads/envelopes in [lib/scoria/workflows/runtime.ex](/Users/jon/projects/scoria/lib/scoria/workflows/runtime.ex:106), and `complete_step/3` / `fail_step/3` persist them through `replay_transition_checkpoint_attrs/5` and `replay_transition_event_attrs/4` in [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:265) and [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:812). |
| 3 | Verification proves no replay path silently escapes into live side effects. | ✓ VERIFIED | The phase verification bundle passed with `43 tests, 0 failures`, including blocked, historical-stub, and replay-live approval runtime paths in [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:64), [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:306), and [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:388). |
| 4 | Replay-safe execution never reuses a historical approval as live authority. | ✓ VERIFIED | Replay approval rows remain fresh `replay_scope="replay_live"` / `replay_disposition="blocked"` in [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:750), and historical approvals still cannot resume a replay branch until the replay-scoped approval is granted in [test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:244). |
| 5 | Replay-live overrides can execute only for allowlisted tools with current policy checks, fresh replay-scoped approval, and retry-safe idempotency. | ✓ VERIFIED | Allowlist immutability is still enforced in [lib/scoria/workflows/run.ex](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:66), replay-live gating still resolves in [lib/scoria/workflows/replay_disposition.ex](/Users/jon/projects/scoria/lib/scoria/workflows/replay_disposition.ex:29), and replay-live dedupe remains covered in [test/scoria/connectors/invocation_test.exs](/Users/jon/projects/scoria/test/scoria/connectors/invocation_test.exs:172). |
| 6 | Replay evidence rows record enough typed context to prove blocked/stub/live decisions and source lineage without inferring from a legacy boolean or opaque metadata. | ✓ VERIFIED | Replay metadata now includes `source_*`, `replay_scope`, `executed_live`, and `replay_idempotency_key` via `replay_transition_fields/1` and `replay_metadata_fields/3` in [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:853) and [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:880). The SQL test trace shows these fields being inserted into real checkpoint/event rows during runtime replay execution. |
| 7 | Public runtime reads expose replay-safe provenance without pretending the whole replay run had one effect mode. | ✓ VERIFIED | `RunSummary` still separates `execution_mode` from `replay_posture` in [lib/scoria/runtime/run_summary.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_summary.ex:70), and `RunDetail` now reads persisted replay provenance from real runtime-produced rows verified in [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:263) and [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:351). |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs` | Replay-safe schema columns and indexes for seam-level evidence | ✓ VERIFIED | Migration exists and adds replay-safe columns for runs, approvals, checkpoints, events, and audit rows in [priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs](/Users/jon/projects/scoria/priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs:1). |
| `lib/scoria/workflows/replay_disposition.ex` | Shared replay disposition contract and resolver API | ✓ VERIFIED | Resolver still implements canonical replay outcomes and exact-match gating in [lib/scoria/workflows/replay_disposition.ex](/Users/jon/projects/scoria/lib/scoria/workflows/replay_disposition.ex:1). |
| `lib/scoria/observe/approval.ex` | Replay-scoped approval schema separate from `replay_allowed` compatibility | ✓ VERIFIED | Approval schema continues to expose authoritative replay fields while retaining compatibility boolean in [lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:9). |
| `lib/scoria/workflows.ex` | Transactional replay approval and evidence fanout | ✓ VERIFIED | Runtime transitions now persist typed replay evidence through shared helper paths in [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:265) and [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:812). |
| `lib/scoria/connectors/invocation.ex` | Connector replay gating before outbound remote execution | ✓ VERIFIED | Connector seam remains replay-gated before MCP execution in [lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:17). |
| `lib/scoria/mcp/executor.ex` | Policy-sensitive replay idempotency and audit enforcement | ✓ VERIFIED | MCP seam still carries replay idempotency and audit context in [lib/scoria/mcp/executor.ex](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:78). |
| `lib/scoria/runtime/run_summary.ex` | Replay posture summary with run intent and approval wait status | ✓ VERIFIED | Summary projection remains explicit about run intent vs replay posture in [lib/scoria/runtime/run_summary.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_summary.ex:70). |
| `lib/scoria/runtime/run_detail.ex` | Curated seam-level replay evidence projection | ✓ VERIFIED | Detail projection now consumes real persisted replay lineage from checkpoint metadata and event payloads in [lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:47). |
| `lib/scoria/workflows/remote_approval_projection.ex` | Replay-safe approval lineage projection for operator-facing inbox/evidence reads | ✓ VERIFIED | Approval projection still surfaces durable replay fields directly from approval rows in [lib/scoria/workflows/remote_approval_projection.ex](/Users/jon/projects/scoria/lib/scoria/workflows/remote_approval_projection.ex:1). |
| `test/scoria/runtime_view_test.exs` | Projection regression coverage for replay-safe runtime reads | ✓ VERIFIED | Runtime view tests now cover replay-live approval waits plus real historical-stub and blocked runtime persistence paths before asserting DTO output in [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:64). |
| `test/scoria/workflows/remote_approval_projection_test.exs` | Replay approval projection regressions for seam-level evidence exposure | ✓ VERIFIED | Approval projection regressions remain intact in [test/scoria/workflows/remote_approval_projection_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/remote_approval_projection_test.exs:1). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scoria/observe/approval.ex` | `priv/repo/migrations/20260523000100_add_replay_safe_execution_truth.exs` | schema fields match approval replay authority columns | ✓ WIRED | Approval schema fields still align with migration-added replay columns. |
| `lib/scoria/workflows/checkpoint.ex` | `lib/scoria/workflows/event.ex` | both persist typed replay disposition columns | ✓ WIRED | Both schemas still define typed replay columns. |
| `lib/scoria/workflows/runtime.ex` | `lib/scoria/workflows.ex` | waiting_for_approval / complete / fail transitions persist replay evidence | ✓ WIRED | Runtime replay outputs now feed typed transition helpers, and workflow writers persist the typed replay columns plus metadata/payload provenance. |
| `lib/scoria/connectors/invocation.ex` | `lib/scoria/workflows/replay_disposition.ex` | resolve replay decision before `Executor.execute` | ✓ WIRED | Connector seam still resolves replay disposition before live execution. |
| `lib/scoria/mcp/executor.ex` | `lib/scoria/sre/audit_outbox_event.ex` | `replay_idempotency_key` maps into audit dedupe | ✓ WIRED | Replay idempotency still flows into audit dedupe storage. |
| `lib/scoria/runtime/run_detail.ex` | `lib/scoria/workflows/checkpoint.ex` | checkpoint items expose seam-level replay disposition | ✓ WIRED | Projection now reads runtime-produced typed replay columns and metadata successfully. |
| `lib/scoria/runtime/run_detail.ex` | `lib/scoria/observe/approval.ex` | approval items expose replay scope and executed_live facts | ✓ WIRED | Approval rows continue to expose authoritative replay fields. |
| `lib/scoria/workflows/remote_approval_projection.ex` | `lib/scoria/observe/approval.ex` | approval inbox and lineage reads surface replay-safe provenance directly from durable rows | ✓ WIRED | Projection still maps durable approval fields directly. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scoria/workflows.ex` | approval `replay_*` fields | `replay_approval_evidence/2` -> `ReplayDisposition.resolve/5` | Yes | ✓ FLOWING |
| `lib/scoria/workflows.ex` | checkpoint/event replay fields on approval waits | `with_replay_evidence/3` -> `replay_metadata_fields/3` | Yes; metadata/payload now carries lineage and replay scope | ✓ FLOWING |
| `lib/scoria/workflows.ex` | checkpoint/event replay fields on runtime complete/fail | `replay_transition_checkpoint_attrs/5` / `replay_transition_event_attrs/4` | Yes; runtime envelopes are promoted into typed columns and persisted replay metadata | ✓ FLOWING |
| `lib/scoria/runtime/run_detail.ex` | checkpoint lineage fields (`source_*`, `replay_scope`, `executed_live`) | checkpoint metadata written by workflow transitions | Yes; real runtime regression tests assert projected values | ✓ FLOWING |
| `lib/scoria/runtime/run_detail.ex` | event lineage fields (`source_*`, `replay_scope`, `executed_live`) | event payload written by workflow transitions | Yes; real runtime regression tests assert projected values | ✓ FLOWING |
| `lib/scoria/workflows/remote_approval_projection.ex` | approval replay provenance | durable `ai_approvals` rows | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Replay execution seams, workflow persistence, DTO projection reads, approval projection regressions, and MCP replay gating | `mix test test/scoria/connectors/invocation_test.exs test/scoria/workflows_test.exs test/scoria/workflows/integration_test.exs test/scoria/runtime_view_test.exs test/scoria/workflows/remote_approval_projection_test.exs test/scoria/mcp/executor_test.exs` | `43 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `RPLY-02` | `38-01`, `38-02`, `38-03` | Replay execution defaults to safe modes that block or stub external-write and approval-sensitive effects while preserving explicit replay provenance. | ✓ SATISFIED | Replay seams fail closed by default, live overrides remain scoped and approval-gated, and explicit provenance now persists through actual workflow runtime rows and public DTO projections. |

No orphaned Phase 38 requirements found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/scoria/sre.ex` | 147 | `remote_invocation_evidence/1` returns `%{approvals: []}` | ⚠️ Warning | Still a hollow helper, but it is outside the core replay persistence and projection paths verified for Phase 38. |
| `lib/scoria/workflows/event_compactor.ex` | 4 | no-op `maybe_enqueue_compaction/2` | ℹ️ Info | Unrelated infrastructure stub; does not block replay-safe execution or provenance. |
| `lib/scoria_web/views/error_view.ex` | 2 | minimal string-only fallback view | ℹ️ Info | Unrelated blocker repair; not part of Phase 38’s replay-safe contract. |

### Closure Summary

No blocking issues remain. The prior provenance defects are closed: replay runtime outcomes now persist typed replay columns and lineage data on checkpoint/event rows, and the public DTO tests verify those fields from real runtime-produced rows rather than synthetic fixtures.

---

_Verified: 2026-05-23T10:15:19Z_
_Verifier: Codex_
