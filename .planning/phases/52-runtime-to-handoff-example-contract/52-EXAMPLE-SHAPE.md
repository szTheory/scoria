# Phase 52 Example Shape

## Decision

No new public runtime API is required for Phase 52.

Phase 52 uses the existing public `Scoria` facade to show one adopter-facing path from the default runtime lane into a bounded handoff. The example starts with a normal run before any bounded handoff call, then lets the host app decide whether review or classification needs a delegated run.

## In Scope

- One adopter-facing runtime-to-handoff example shape.
- A default run started through `Scoria.start_run/2`.
- A bounded delegated run started through `Scoria.start_handoff_run/3`.
- Curated delegated readback through `Scoria.get_run_detail/1`.
- Host-owned continuity through `session_id` and durable Scoria execution handles through `run_id`.
- Explicit projected-context accept and reject examples.

## Explicit Exclusions

- No sample Phoenix app
- No semantic fast-path prerequisite
- No knowledge or retrieval prerequisite
- No pgvector prerequisite
- No direct Scoria.Workflows calls
- No raw workflow table readback

## API Surface

- `Scoria.identity/1`
- `Scoria.start_run/2`
- `Scoria.start_handoff_run/3`
- `Scoria.get_run_detail/1`

## Example Flow

The host starts a default run with `Scoria.start_run/2`, persists `started.run_id`, decides in host code whether a bounded review/classification handoff is needed, calls `Scoria.start_handoff_run/3`, persists `handoff_run.run_id`, and uses `Scoria.get_run_detail(handoff_run.run_id)` for curated delegated readback.

The host app owns escalation policy; Scoria does not infer or transfer policy from the default run.

session_id groups related host turns; run_id names one exact Scoria execution.

## Projected Context Contract

Accepted examples:

- `projected_context: %{}`
- `%{"task" => "policy-and-accuracy review", "draft_answer" => draft_answer}`

Rejected examples include:

- `transcript`
- `messages`
- `history`
- `provider_session`
- `runtime_state`
- `session`
- `headers`
- `cookies`
- `secrets`

The host chooses the bounded payload before calling Scoria. Scoria rejects broad runtime-state keys through `Scoria.start_handoff_run/3` instead of silently projecting transcript, provider, session, request, cookie, or secret state into delegated work.

## Verification Contract

Plan 52 implementation must preserve this shape:

- The example starts with `Scoria.start_run/2` before any bounded handoff call.
- The example uses `Scoria.start_handoff_run/3` for delegation.
- The example uses `Scoria.get_run_detail(handoff_run.run_id)` for delegated readback.
- The example treats host `session_id` as continuity and Scoria `run_id` as the durable execution handle.
- The example keeps optional semantic fast path, knowledge, retrieval, pgvector, direct workflow calls, and raw workflow table reads out of scope.

## Source Audit

- `docs/phoenix_runtime_example.md` already establishes the default runtime lane, `started.run_id` persistence, and `session_id` versus `run_id` boundary.
- `docs/bounded_handoffs.md` already establishes bounded handoff input, projected-context safety, and curated delegated readback.
- `lib/scoria.ex` already exposes the public facade needed for the example.
- `lib/scoria/runtime/params.ex` already rejects unsafe projected-context keys before durable handoff creation.
- `lib/scoria/runtime/run_detail.ex` already exposes curated delegated handoff readback through the public detail DTO.

## Baseline Quick Verification

Command: `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs`

Baseline docs/source quick verification passed before Phase 52 implementation.
