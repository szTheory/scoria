# Phase 41: Bounded Handoff Contract & Safety - Research

**Researched:** 2026-05-24 [VERIFIED: current session date]
**Domain:** public bounded handoff contract truth, same-run delegated lineage, and projected-context safety inside the existing Scoria runtime lane [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: roadmap/context/state review plus local code and test inspection]

## User Constraints

- `v2.0 Relay` intentionally formalizes repo-local bounded handoff truth rather than reopening handoff research or widening product scope. [VERIFIED: .planning/PROJECT.md; .planning/STATE.md; .planning/memory/bounded-handoff-productization-lessons.md]
- Phase 41 must close `HAND-01`, `HAND-02`, `SAFE-01`, and `SAFE-02` without absorbing the richer operator-surface and adoption-story work already reserved for Phase 42. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]
- The repo already has a public wedge: `Scoria.start_handoff_run/3`, bounded handoff docs, runtime detail DTOs, and adoption-lane checks. Planning should tighten that wedge instead of replacing it. [VERIFIED: lib/scoria.ex; lib/scoria/runtime.ex; docs/bounded_handoffs.md; test/scoria/adoption_surface_test.exs]
- The worktree is already dirty in the implementation files this milestone will eventually touch, so Phase 41 plans should isolate contract, safety, and proof work into small slices with narrow file lists and strong regression lanes. [VERIFIED: `git status --short`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HAND-01 | Developer can start a bounded delegated run through `Scoria.start_handoff_run/3` with explicit root role, delegated role, delegated kind, and host-supplied handoff input. [VERIFIED: .planning/REQUIREMENTS.md] | Tighten `Scoria.Runtime.Params.start_handoff/3` so the public boundary stops relying on implicit defaults or payload projection magic and instead persists explicit contract fields from caller input. [VERIFIED: lib/scoria/runtime/params.ex; lib/scoria/runtime.ex] |
| HAND-02 | Delegated work remains rooted under the same durable run, with a persisted handoff step, durable handoff record, and queued child step instead of transferring root ownership. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `Scoria.Runtime.start_handoff_run/3` and `Scoria.Workflows.Runtime.handle_handoff/3` as the same-run substrate, but make the durable handoff/readback truth explicit enough that callers can inspect root role, delegated role, delegated kind, and child lineage without reading internals. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/workflows/runtime.ex; lib/scoria/runtime/run_detail.ex] |
| SAFE-01 | Public bounded handoffs reject unsafe projected-context keys such as transcript/session/secrets state instead of silently accepting broad delegated context. [VERIFIED: .planning/REQUIREMENTS.md] | Move projected-context validation to the public normalization path and deepen it beyond the current top-level denylist in `Scoria.Workflows.Runtime`. [VERIFIED: lib/scoria/runtime/params.ex; lib/scoria/workflows/runtime.ex; test/scoria/runtime_test.exs] |
| SAFE-02 | The public handoff lane stays intentionally narrow and host-controlled, avoiding broad autonomous multi-agent platform behavior in the default Scoria surface. [VERIFIED: .planning/REQUIREMENTS.md] | Keep docs, DTOs, params, and tests centered on one explicit host-controlled handoff slice, with adjunct metadata clearly secondary and no broad runtime-state delegation path. [VERIFIED: docs/bounded_handoffs.md; .planning/PROJECT.md; .planning/memory/bounded-handoff-productization-lessons.md] |
</phase_requirements>

## Summary

Phase 41 should be executed as three narrow plans that match the roadmap exactly: first tighten the public input contract and same-run durable lineage, then harden projected-context validation and failure semantics, then lock the bounded lane with docs and regression proof. The current implementation already has the right public entrypoint and same-run ownership model, so the planning burden is not “invent handoffs” but “remove hidden semantics and make the shipped truth inspectable.” [VERIFIED: .planning/ROADMAP.md; lib/scoria/runtime.ex; lib/scoria/workflows/runtime.ex]

The biggest contract drift today lives in `Scoria.Runtime.Params.start_handoff/3`. It still falls back to `root_role_id: "executor"`, defaults `delegated_kind` to `"delegated_task"`, and silently injects `payload`/`input` into `projected_context`. Those shortcuts conflict directly with the Phase 41 context decisions that require explicit root role, explicit delegated kind, explicit handoff input semantics, and no implicit payload projection. [VERIFIED: lib/scoria/runtime/params.ex; .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]

The main safety weakness is timing and depth, not just the denylist contents. `Scoria.Workflows.Runtime.handle_handoff/3` currently rejects only a shallow top-level set of keys after the run and root handoff step already exist. That produces a failed run, but it still treats bounded-context enforcement as an execution-time seam instead of a public contract check, and it leaves nested aliases or renamed broad state insufficiently guarded. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/workflows/runtime.ex; test/scoria/runtime_test.exs]

Public readback also needs tightening. `RunDetail` already exposes steps and handoff rows, but the durable handoff row currently omits delegated kind, root role, and explicit contract-oriented lineage fields, while the docs promise a narrow inspectable lane. Phase 41 should establish the minimum truthful DTO baseline Phase 42 can later polish without redefining the contract. [VERIFIED: lib/scoria/runtime/run_detail.ex; lib/scoria/workflows/handoff.ex; docs/bounded_handoffs.md]

**Primary recommendation:** plan Phase 41 as three plans aligned to the roadmap: `41-01` for explicit public contract and same-run lineage truth, `41-02` for deep projected-context validation plus explicit failure/readback behavior, and `41-03` for docs/source/test proof that the lane stays narrow by default. [VERIFIED: .planning/ROADMAP.md]

## Architecture Patterns

### Pattern 1: Normalize at the public boundary, not after durable writes
**What:** Reject invalid handoff contract state in `Scoria.Runtime.Params` before `Workflows.create_run/1` and `create_step/2` persist runtime truth. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/runtime/params.ex]
**Why:** Phase 41 is formalizing a public contract, not merely adding an execution-time guard. [VERIFIED: .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]

### Pattern 2: Keep same-run lineage in the existing workflow substrate
**What:** Reuse the current root handoff step plus queued child step model instead of creating a second run or ownership transfer path. [VERIFIED: lib/scoria/runtime.ex; lib/scoria/workflows/runtime.ex]
**Why:** `HAND-02` is already structurally present; the gap is explicitness and readback truth. [VERIFIED: .planning/REQUIREMENTS.md; test/scoria/runtime_test.exs]

### Pattern 3: Curated runtime DTOs are the public inspectability seam
**What:** Expose minimum truthful handoff facts through `Scoria.Runtime.RunDetail` and related public runtime reads, not through raw workflow schemas or ad hoc LiveView logic. [VERIFIED: lib/scoria/runtime/run_detail.ex; .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]
**Why:** Phase 13 already locked public runtime DTOs as the host-app-facing contract. [VERIFIED: .planning/phases/13-public-runtime-api-and-session-lifecycle/13-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Leaving semantic defaults in place while only updating docs
`delegated_kind`, `root_role_id`, and implicit payload projection would continue to undermine support truth even if the guide text becomes more explicit. [VERIFIED: lib/scoria/runtime/params.ex; docs/bounded_handoffs.md]

### Pitfall 2: Treating shallow denylist checks as sufficient safety
A top-level key check misses nested broad state and keeps the rejection too late in the flow. [VERIFIED: lib/scoria/workflows/runtime.ex]

### Pitfall 3: Expanding Phase 41 into a full operator UX or docs milestone
That would steal work from Phase 42 and blur the milestone boundary the roadmap explicitly sets. [VERIFIED: .planning/ROADMAP.md; .planning/phases/41-bounded-handoff-contract-safety/41-CONTEXT.md]

## Recommended Plan Breakdown

1. `41-01`: make `Scoria.start_handoff_run/3` explicit about root role, delegated kind, handoff input, and same-run lineage truth; persist only what the host app actually said.
2. `41-02`: add deep projected-context validation and explicit unsafe-context contract errors before durable persistence, then preserve an honest readback/failure story.
3. `41-03`: update guide/source fragments and regression lanes so docs, tests, and runtime behavior all teach the same narrow lane.

