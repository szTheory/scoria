---
phase: 52-runtime-to-handoff-example-contract
verified: 2026-05-27T07:06:42Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 52: Runtime-to-handoff example contract Verification Report

**Phase Goal:** Define and build the narrow adopter-facing path from `Scoria.start_run/2` into `Scoria.start_handoff_run/3`.
**Verified:** 2026-05-27T07:06:42Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

Phase 52 achieved its goal. The adopter-facing example starts with `Scoria.start_run/2`, branches by host-owned policy into `Scoria.start_handoff_run/3`, persists and inspects the handoff run by `handoff_run.run_id`, and documents projected context as an explicit bounded payload with truthful rejection behavior.

The code review warning about creating a default run and then a separate handoff run is not a Phase 52 requirement gap. It is the explicit EXMP-01 shape chosen by the roadmap and plans: the example must start a default run and then escalate into `Scoria.start_handoff_run/3`. Runtime truth matches that shape: `Scoria.start_handoff_run/3` creates its own durable run, and the docs/tests assert `started.run_id != handoff_run.run_id` while preserving `started.session_id == handoff_run.session_id`. The bounded handoff guide's "same durable run" wording applies to the handoff parent/child lineage inside the handoff run, not to reusing the earlier default run as the handoff run.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The example starts from the default runtime lane and uses existing public APIs unless a blocking gap is discovered. | VERIFIED | `docs/phoenix_runtime_example.md:129` calls `Scoria.start_run(identity, root_role_id: "executor")`; `lib/scoria.ex:30-61` exposes the public facade used by the docs. |
| 2 | The example shows how and why the host app escalates to a bounded delegated run. | VERIFIED | `docs/phoenix_runtime_example.md:119-161` contains the host-owned `needs_bounded_review?/1` branch and `Scoria.start_handoff_run/3` call. |
| 3 | Projected context is presented as a bounded, safe-by-default handoff payload rather than hidden runtime state. | VERIFIED | `docs/bounded_handoffs.md:68-96` documents narrow accepted context and broad rejected keys; `docs/phoenix_runtime_example.md:139-142` passes only task and draft answer. |
| 4 | Rejected or excluded projected-context inputs are documented or demonstrated with truthful behavior. | VERIFIED | `docs/bounded_handoffs.md:87-96` documents `{:error, :unsafe_projected_context}`; `lib/scoria/runtime/params.ex:87-91` returns that error; `test/scoria/runtime_test.exs:345-358` proves rejected host session state creates no durable run. |
| 5 | The adopter-facing example starts with `Scoria.start_run/2` before any bounded handoff call. | VERIFIED | `docs/phoenix_runtime_example.md:129-135` and `test/scoria/runtime_test.exs:312-315` show start before handoff. |
| 6 | The example uses `Scoria.start_handoff_run/3` and `Scoria.get_run_detail/1` instead of direct workflow internals. | VERIFIED | `docs/phoenix_runtime_example.md:135` calls `Scoria.start_handoff_run/3`; `docs/phoenix_runtime_example.md:148` calls `Scoria.get_run_detail(handoff_run.run_id)`; no `Scoria.Workflows` appears in the Phoenix guide. |
| 7 | The example treats host `session_id` as continuity and Scoria `run_id` as the durable execution handle. | VERIFIED | `docs/phoenix_runtime_example.md:151-164` and `test/scoria/runtime_test.exs:325-326` assert distinct run IDs under the same session. |
| 8 | Projected context is an explicit bounded payload with rejection behavior. | VERIFIED | `52-EXAMPLE-SHAPE.md` lists accepted/rejected shapes; runtime validation in `lib/scoria/runtime/params.ex:249-294` rejects unsafe key names and aliases. |
| 9 | DB-backed tests prove narrow projected_context is accepted and unsafe projected_context is rejected before durable write. | VERIFIED | `test/scoria/runtime_test.exs:302-358` covers accepted task/draft context and rejected session context with `Scoria.list_runs_for_session("session-example-rejected") == []`. |
| 10 | The host app owns identity, escalation policy, prompt/draft selection, and projected-context selection. | VERIFIED | `docs/bounded_handoffs.md:19` documents the ownership boundary; `test/scoria/adoption_surface_test.exs:87-88` pins it. |
| 11 | Scoria owns durable run creation, unsafe projected-context rejection, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`. | VERIFIED | `docs/bounded_handoffs.md:20`, `lib/scoria/runtime.ex:42-65`, and `lib/scoria/runtime/run_detail.ex:37-49` show durable handoff creation and curated delegated readback. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.planning/phases/52-runtime-to-handoff-example-contract/52-EXAMPLE-SHAPE.md` | Decision record for smallest Phase 52 example shape | VERIFIED | Contains public API surface, exclusions, start-run-before-handoff flow, projected-context accept/reject contract, and baseline verification. |
| `docs/phoenix_runtime_example.md` | Cohesive runtime-to-handoff adopter example | VERIFIED | Contains `defp needs_bounded_review?/1`, public facade calls, distinct `started.run_id`/`handoff_run.run_id`, and no direct workflow internals. |
| `test/scoria/runtime_test.exs` | DB-backed runtime-to-handoff behavior and rejection tests | VERIFIED | Adds public-facade tests for default-to-handoff flow and unsafe projected-context rejection. |
| `test/support/scoria/adoption_example.ex` | Pinned source fragments for docs | VERIFIED | Pins Phoenix and bounded handoff fragments. The rejection sentence is pinned through `{:error, :unsafe_projected_context}` plus `before creating a durable delegated run.` rather than one full sentence; this preserves the same source-test intent. |
| `docs/bounded_handoffs.md` | Projected-context safety and host/Scoria ownership documentation | VERIFIED | Contains ownership boundary, unsafe projected-context rejection example, and curated readback through `Scoria.get_run_detail/1`. |
| `test/scoria/adoption_surface_test.exs` | Public docs safety assertions | VERIFIED | Asserts ownership/rejection wording and refutes raw workflow table readback strings. |
| `test/scoria/handoff_example_source_test.exs` / `test/scoria/phoenix_example_source_test.exs` | Source-alignment fragment checks | VERIFIED | Both iterate `Scoria.TestSupport.AdoptionExample` fragments against docs. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `52-EXAMPLE-SHAPE.md` | `docs/phoenix_runtime_example.md` | Example artifact decision | VERIFIED | Shape decision defines the exact flow implemented in the Phoenix guide. |
| `52-EXAMPLE-SHAPE.md` | `docs/bounded_handoffs.md` | Projected context and host ownership decision | VERIFIED | Bounded handoff guide implements the ownership and rejection contract. |
| `docs/phoenix_runtime_example.md` | `Scoria.start_run/2` | Controller example | VERIFIED | `docs/phoenix_runtime_example.md:129`. |
| `docs/phoenix_runtime_example.md` | `Scoria.start_handoff_run/3` | Host-owned escalation branch | VERIFIED | `docs/phoenix_runtime_example.md:135`. |
| `test/scoria/runtime_test.exs` | `Scoria.get_run_detail/1` | Curated delegated readback assertion | VERIFIED | `test/scoria/runtime_test.exs:328`. |
| `docs/bounded_handoffs.md` | `lib/scoria/runtime/params.ex` | Unsafe projected-context rejection wording | VERIFIED | Docs name `:unsafe_projected_context`; runtime returns it in `Params.validate_projected_context/1`. |
| `docs/bounded_handoffs.md` | `Scoria.get_run_detail/1` | Curated readback boundary | VERIFIED | `docs/bounded_handoffs.md:103-104`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `docs/phoenix_runtime_example.md` | `handoff_run.run_id` | `Scoria.start_handoff_run/3` via public facade | Yes - `Runtime.start_handoff_run/3` creates a run and returns `get_run!(run.id)` | FLOWING |
| `test/scoria/runtime_test.exs` | `detail.delegated_handoffs` | `Scoria.get_run_detail(handoff_run.run_id)` | Yes - `RunDetail.from_run_tree/2` derives delegated handoff rows from persisted steps/handoffs | FLOWING |
| `docs/bounded_handoffs.md` | projected-context rejection | `Params.validate_projected_context/1` | Yes - unsafe keys return `{:error, :unsafe_projected_context}` before `Workflows.create_run/1` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 52 runtime/docs/source validation | `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs` | Orchestrator already ran: 28 tests, 0 failures | PASS |
| Artifact contract checks | `gsd-sdk query verify.artifacts ...` plus manual `rg` follow-up | Required files exist and are substantive; one helper pattern was narrower than the actual source-fragment pinning | PASS |
| Key-link checks | `gsd-sdk query verify.key-links ...` plus manual `rg` follow-up | Manual checks verified public facade calls and readback links where helper regex matching produced false negatives | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| EXMP-01 | `52-01-PLAN.md`, `52-02-PLAN.md`, `52-03-PLAN.md` | Phoenix developer can follow one adopter-facing example that starts a default Scoria run and escalates into `Scoria.start_handoff_run/3` without needing maintainer folklore. | SATISFIED | `docs/phoenix_runtime_example.md:129-151`; `test/scoria/runtime_test.exs:302-338`; `test/support/scoria/adoption_example.ex:38-42`. |
| EXMP-02 | `52-01-PLAN.md`, `52-02-PLAN.md`, `52-03-PLAN.md` | The example shows bounded projected-context shape, including safe inputs and rejected/excluded defaults. | SATISFIED | `docs/bounded_handoffs.md:68-96`; `docs/phoenix_runtime_example.md:139-142`; `test/scoria/runtime_test.exs:345-358`; `lib/scoria/runtime/params.ex:280-294`. |

No orphaned Phase 52 requirements found in `.planning/REQUIREMENTS.md`; EXMP-01 and EXMP-02 are both mapped to Phase 52 and claimed by all three plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `test/scoria/runtime_test.exs` | 6, 11 | `Scoria.Workflows` alias/use | Info | Existing runtime tests use internals for lower-level coverage; adopter-facing docs avoid direct workflow calls. |
| `docs/phoenix_runtime_example.md` | 220 | `pgvector` exclusion | Info | Explicitly states pgvector is not required; not a hidden prerequisite. |
| `test/scoria/adoption_surface_test.exs` | 105-110 | Raw-internal strings in refutations | Info | Strings appear only in tests that refute docs leakage. |

No TODO/FIXME/placeholders, empty implementations, console-only handlers, or hardcoded empty user-facing data were found in the Phase 52 deliverables.

### Human Verification Required

None. This phase is docs, source-alignment, and DB-backed behavior-test work; no visual, external-service, or interactive user-flow validation remains for Phase 52.

### Gaps Summary

No blocking gaps found. The review warning is documented as an intentional Phase 52 contract decision, not a failed requirement. Later phases 53 and 54 will expand operator evidence/lane guidance and proof-command alignment, but those are separate roadmap requirements (`EVID-01`, `DOCS-01`, `DOCS-02`, `PROOF-01`, `PROOF-02`) rather than missing Phase 52 work.

---

_Verified: 2026-05-27T07:06:42Z_
_Verifier: Claude (gsd-verifier)_
