# Bounded Handoffs

This guide documents the narrow public delegation lane for Scoria. Use it when your Phoenix app needs one role to hand a bounded slice of work to another role without turning Scoria into a general-purpose agent platform.

Start with the normal runtime lane first: `identity -> start -> inspect -> resume`. Validate that base lane with `mix test.adoption`, then add bounded handoffs only when you intentionally need same-run delegation. Bounded handoffs extend that same runtime-first story instead of creating a second quickstart or a separate verifier lane.

## What this lane does

- starts one durable run through the public `Scoria` facade
- records one explicit delegated handoff with inspectable lineage
- keeps the projected context narrow and host-controlled
- creates a queued child step for the delegated role
- leaves the same run visible at `/scoria/workflows/:run_id`

## Core contract

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

## When to use this

Use bounded handoffs when:

- one role needs a second role to review, classify, summarize, or critique
- the delegated role only needs a small projected context slice
- you want the operator surface to show that delegated lineage clearly

Do not use this lane to build a broad autonomous multi-agent platform. Keep the contract narrow and explicit.

## Remaining adoption gap

No remaining adopter-facing gap is required for the runtime-first bounded handoff lane in `v2.0 Relay` closeout. Richer notebook-style delegated forensics remain deferred follow-up work only if real operator confusion appears after the current `Scoria.get_run_detail/1` and `/scoria/workflows/:run_id` surfaces prove insufficient.
