# Phoenix Runtime Example

This is the canonical Phoenix-hosted Scoria flow for the Keystone public runtime surface. It is derived from the existing runtime integration behavior in `test/scoria/runtime_integration_test.exs`, not from a separate sample app or a speculative architecture.

Keep the canonical adoption order boring: `identity -> start -> inspect -> resume`.

## What this guide shows

- normalize request and session context with `Scoria.identity/1`
- start a run through `Scoria.start_run/2`
- persist `run_id` as the exact durable handle for one run
- reuse `session_id` for continuity across turns
- inspect progress with `Scoria.get_run/1` and `Scoria.list_runs_for_session/1`
- link `/scoria/workflows/:run_id` as operator evidence for that same run
- resume a paused approval flow through `Scoria.resume_run/2`

## Core rule: `session_id` is not `run_id`

Use `session_id` to group related turns in your host app. Use `run_id` to inspect or resume one exact Scoria execution.

- same conversation, new turn: reuse `session_id`, create a fresh run
- paused run: resume only by its exact `run_id`

That distinction is the main contract to preserve in your Phoenix app.

## Controller-triggered start

Start from a normal controller action. Normalize the Phoenix edge state first, then call the top-level `Scoria` facade.

```elixir
defmodule MyAppWeb.AssistantController do
  use MyAppWeb, :controller

  def create(conn, %{"prompt" => prompt}) do
    identity =
      Scoria.identity(%{
        actor_id: conn.assigns.current_user.id,
        tenant_id: conn.assigns.current_account.id,
        session_id: get_session(conn, :assistant_session_id),
        metadata: %{"channel" => "web"}
      })

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "executor",
        initial_step: %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        },
        runtime: [
          metadata: %{
            "payload" => %{"prompt" => prompt}
          }
        ],
        handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
      )

    conn
    |> put_session(:last_scoria_run_id, started.run_id)
    |> redirect(to: ~p"/assistant/runs/#{started.run_id}")
  end
end
```

If your identity already lives in assigns or session maps, the same module exposes narrower helpers:

```elixir
identity_from_assigns = Scoria.Identity.from_conn_assigns(conn.assigns)
identity_from_session = Scoria.Identity.from_session(get_session(conn))
```

Use those helpers only when they make the edge boundary clearer. The important part is that the controller hands Scoria one normalized identity before the run starts.

## Persist the exact `run_id`

Persist `started.run_id` anywhere your host app already tracks ongoing work: session, database row, job record, or a conversation table. That `run_id` is the exact handle for:

- `Scoria.get_run/1`
- `Scoria.resume_run/2`
- `/scoria/workflows/:run_id`

Do not try to resume from `session_id` alone.

## Inspect progress from the host app

Your app can inspect one run directly or list all runs that share the same `session_id`.

```elixir
{:ok, summary} = Scoria.get_run(run_id)
same_session_runs = Scoria.list_runs_for_session(session_id)
```

Use `Scoria.get_run/1` when the host app needs the current state of one exact execution. Use `Scoria.list_runs_for_session/1` when you want to show a session timeline across multiple turns.

## Operator evidence page

The operator page for one run is:

```text
/scoria/workflows/:run_id
```

Link to it from your host app when an operator needs traceable evidence for the same durable run:

```elixir
redirect(conn, to: ~p"/scoria/workflows/#{run_id}")
```

Treat that page as operator evidence, not as the source of your product's business truth.

## Bounded handoffs branch from the same runtime lane

If the core runtime path is already working and a draft needs a bounded review, branch from the same identity and `run_id` model instead of starting a second onboarding path.
The host app owns identity, escalation policy, prompt or draft selection, and projected-context selection.
Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback through Scoria.get_run_detail/1.
Use Scoria.start_handoff_run/3 only for that explicit bounded delegation branch.

```elixir
def create(conn, %{"draft_answer" => draft_answer}) do
  identity =
    Scoria.identity(%{
      actor_id: conn.assigns.current_user.id,
      tenant_id: conn.assigns.current_account.id,
      session_id: get_session(conn, :assistant_session_id),
      metadata: %{"channel" => "web"}
    })

  {:ok, started} = Scoria.start_run(identity, root_role_id: "executor")

  conn = put_session(conn, :last_scoria_run_id, started.run_id)

  if needs_bounded_review?(draft_answer) do
    {:ok, handoff_run} =
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

    conn = put_session(conn, :last_scoria_handoff_run_id, handoff_run.run_id)

    {:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)
    delegated = detail.delegated_handoffs

    started.run_id != handoff_run.run_id

    redirect(conn, to: ~p"/assistant/runs/#{handoff_run.run_id}")
  else
    redirect(conn, to: ~p"/assistant/runs/#{started.run_id}")
  end
end

defp needs_bounded_review?(draft_answer) do
  String.contains?(draft_answer, "policy")
end
```

Use `Scoria.get_run_detail/1` when the host app or support path needs the curated delegated evidence surface, and use `/scoria/workflows/:run_id` when an operator needs the same run's `Delegated Evidence` section.

session_id groups related host turns; run_id names one exact Scoria execution.

## Resume after approval

When a run pauses for approval, resume that exact run by the stored `run_id`.

```elixir
{:ok, resumed} =
  Scoria.resume_run(run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

The resumed run keeps the same `run_id`. Resuming does not create a new run.

## Same session, fresh run

When the user comes back for another turn in the same conversation, reuse the same `session_id` and start a new run:

```elixir
identity =
  Scoria.identity(%{
    actor_id: conn.assigns.current_user.id,
    tenant_id: conn.assigns.current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })

{:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

next_run.session_id == session_id
next_run.run_id != run_id
```

This is the intended continuity model:

- `session_id` groups the conversation
- `run_id` names one exact execution

## Verification checklist

After wiring the flow:

1. Start a run through your controller with `Scoria.start_run/2`.
2. Store the returned `run_id`.
3. Read it back with `Scoria.get_run/1`.
4. Open `/scoria/workflows/:run_id` and confirm the same run is visible there.
5. If the run pauses for approval, call `Scoria.resume_run/2` with the stored `run_id`.
6. Start another turn with the same `session_id` and confirm it produces a different `run_id`.

## What this guide does not require

- LiveView-first orchestration
- background-job-first orchestration
- direct workflow internals as the normal app entrypoint
- pgvector or the knowledge lane just to prove the runtime path

Use the public `Scoria` facade first. Expand into advanced runtime or knowledge features only after this core lane is working.
