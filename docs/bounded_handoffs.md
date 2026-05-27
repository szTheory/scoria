# Bounded Handoffs

This guide documents the narrow public delegation lane for Scoria. Use it when your Phoenix app needs one role to hand a bounded slice of work to another role without turning Scoria into a general-purpose agent platform.

Start with the default runtime lane. It proves identity-aware durable runs, approvals, and operator evidence with mix test.adoption. Add bounded handoff only when the same durable run needs a narrow same-run delegation, host-controlled projected context, and operator-visible delegated lineage.
Keep the normal runtime order `identity -> start -> inspect -> resume` and branch to handoff only when that explicit delegation contract is needed.
Bounded handoffs are added only after `mix test.adoption` proves the normal runtime lane.
They extend the same runtime-first story through one canonical verifier lane: `mix test.runtime_to_handoff`.

## What this lane does

- starts one durable run through the public `Scoria` facade
- records one explicit delegated handoff with inspectable lineage
- keeps the projected context narrow and host-controlled
- creates a queued child step for the delegated role
- leaves the same run visible at `/scoria/workflows/:run_id`

## Core contract

## Host and Scoria ownership boundary

The host app owns identity, escalation policy, prompt or draft selection, and projected-context selection.
Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.
Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.

Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`: the root role that is delegating
- the delegated role argument: the role that should own the child step
- `delegated_kind`: the child step kind that host handlers should execute
- `handoff_input`: the exact host-supplied work brief Scoria should persist
- `projected_context`: the exact projected context slice that is safe to pass down

The host app passes these fields explicitly. Scoria does not fill in hidden handoff defaults for you.

```elixir
identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })

{:ok, started} =
  Scoria.start_handoff_run(identity, "critic",
    root_role_id: "planner",
    delegated_kind: "review",
    handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
    projected_context: %{
      "task" => "policy-and-accuracy review",
      "draft_answer" => draft_answer
    },
    handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
  )
```

If the delegated role should receive no extra context, `projected_context: %{}` is a valid explicit choice.

## What gets persisted

Scoria records:

- the root run with canonical actor, tenant, and session identity
- a root `handoff` step
- a durable handoff row showing the delegated role, delegated kind, and handoff input
- a queued child step with the delegated role and delegated kind

The child step stays under the same durable run. Root ownership does not transfer.

## Safety rule: projected context must stay narrow

Projected context is for the bounded slice only. Do not pass broad runtime state through the public handoff lane.

Broad runtime-state keys are rejected explicitly, including:

- `transcript`
- `messages`
- `history`
- `provider_session`
- `session`
- `headers`
- `secrets`
- `socket_state`

Narrow host-controlled slices such as `%{"task" => "review"}` and `projected_context: %{}` remain valid.

Rejected projected context returns a runtime error before Scoria creates the delegated run:

```elixir
assert {:error, :unsafe_projected_context} =
         Scoria.start_handoff_run(identity, "critic",
           root_role_id: "planner",
           delegated_kind: "review",
           handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
           projected_context: %{"request_headers" => %{"authorization" => "secret"}}
         )
```

Scoria rejects the call with `{:error, :unsafe_projected_context}` before creating a durable delegated run.

## Inspecting delegated lineage

After `Scoria.start_handoff_run/3`:

```elixir
{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

`detail.delegated_handoffs` exposes the delegated role, delegated kind, handoff input, bounded projected context, and the parent/child same-run lineage needed to inspect the bounded lane without reading raw workflow tables.

Open:

```text
/scoria/workflows/:run_id
```

The workflow page keeps the topology-first tree and selected-step rail, and now adds a run-level `Delegated Evidence` section for the curated handoff story under the same durable run.

## Runtime-to-handoff verifier

After the default lane is proven with `mix test.adoption`, use this bounded escalation verifier:

```bash
mix test.runtime_to_handoff
```

The verifier exercises the same delegated readback path in this guide: inspect `Scoria.get_run_detail/1`, confirm `delegated_handoffs`, and cross-check `/scoria/workflows/:run_id`.

## When to use this

Use bounded handoffs when:

- one role needs a second role to review, classify, summarize, or critique
- the delegated role only needs a small projected context slice
- you want the operator surface to show that delegated lineage clearly

Do not use this lane to build a broad autonomous multi-agent platform. Keep the contract narrow and explicit.

## Remaining adoption gap

No remaining adopter-facing gap is required for the runtime-first bounded handoff lane in `v2.0 Relay` closeout. Richer notebook-style delegated forensics remain deferred follow-up work only if real operator confusion appears after the current `Scoria.get_run_detail/1` and `/scoria/workflows/:run_id` surfaces prove insufficient.
