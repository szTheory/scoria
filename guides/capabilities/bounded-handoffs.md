# Bounded Handoffs

Bounded handoffs are the narrow public delegation capability for Scoria. Use them when your Phoenix app needs one role to hand a bounded slice of work to another role without turning Scoria into a general-purpose agent platform.

Use this guide with [Default Runtime](guides/capabilities/default-runtime.md), [Golden Path](guides/golden-path.md), and the [glossary](guides/reference/glossary.md).

Start with the default runtime capability. It proves identity-aware durable runs, approvals, and reviewer traces with `mix test.adoption`. Add bounded handoffs only when the same durable run needs narrow same-run delegation, host-controlled scoped context, and reviewer-visible delegated lineage. The default runtime path is `identity -> start -> inspect -> resume`.

## What this capability does

- starts one durable run through the public `Scoria` facade
- records one explicit delegated handoff with inspectable lineage
- keeps the scoped context narrow and host-controlled
- creates a queued child step for the delegated role
- leaves the same run visible at `/scoria/workflows/:run_id`

## Host and Scoria ownership boundary

The host app owns identity, escalation policy, prompt or draft selection, and scoped-context selection.

Scoria owns durable run creation, scoped-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.

Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.

## Core contract

Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`: the root role that is delegating
- the delegated role argument: the role that should own the child step
- `delegated_kind`: the child step kind that host handlers should execute
- `handoff_input`: the exact host-supplied work brief Scoria should persist
- `scoped_context`: the exact scoped context slice that is safe to pass down

The host app passes these fields explicitly. Scoria does not fill in hidden handoff defaults.

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
    scoped_context: %{
      "task" => "policy-and-accuracy review",
      "draft_answer" => draft_answer
    },
    handlers: %{"review" => {MyApp.RuntimeHandlers, :review}}
  )
```

If the delegated role should receive no extra context, `scoped_context: %{}` is a valid explicit choice.

`projected_context:` remains accepted as a legacy 0.1.x compatibility alias. New public examples should use `scoped_context:`.

## What gets persisted

Scoria records:

- the root run with canonical actor, tenant, and session identity
- a root `handoff` step
- a durable handoff row showing the delegated role, delegated kind, and handoff input
- a queued child step with the delegated role and delegated kind

The child step stays under the same durable run. Root ownership does not transfer.

## Safety rule: scoped context must stay narrow

Scoped context is for the bounded slice only. Do not pass broad runtime state through the public handoff capability.

Broad runtime-state keys are rejected explicitly, including:

- `transcript`
- `messages`
- `history`
- `provider_session`
- `session`
- `headers`
- `secrets`
- `socket_state`

Narrow host-controlled slices such as `%{"task" => "review"}` and `scoped_context: %{}` remain valid.

Rejected scoped context returns the existing runtime error before Scoria creates the delegated run:

```elixir
assert {:error, :unsafe_projected_context} =
         Scoria.start_handoff_run(identity, "critic",
           root_role_id: "planner",
           delegated_kind: "review",
           handoff_input: %{"brief" => "Review the draft answer for policy and accuracy"},
           scoped_context: %{"request_headers" => %{"authorization" => "secret"}}
         )
```

Scoria rejects the call with `{:error, :unsafe_projected_context}` before creating a durable delegated run.

## Inspecting delegated lineage

After `Scoria.start_handoff_run/3`:

```elixir
{:ok, detail} = Scoria.get_run_detail(started.run_id)
delegated = detail.delegated_handoffs
```

`detail.delegated_handoffs` exposes the delegated role, delegated kind, handoff input, bounded scoped context, and the parent/child same-run lineage needed to inspect the bounded capability without reading raw workflow tables.

Open:

```text
/scoria/workflows/:run_id
```

The workflow page keeps the topology-first tree and selected-step rail, and includes a run-level `Delegated Trace` section for the curated handoff story under the same durable run.

## Runtime-to-handoff verifier

After the default runtime capability is proven with `mix test.adoption`, use this bounded escalation verification suite:

```bash
mix test.runtime_to_handoff
```

The verifier exercises the same delegated readback path in this guide: inspect `Scoria.get_run_detail/1`, confirm `delegated_handoffs`, and cross-check `/scoria/workflows/:run_id`.

This is one canonical verification suite for the bounded handoff capability; do not replace it with raw workflow-table assertions.

## When to use this

Use bounded handoffs when:

- one role needs a second role to review, classify, summarize, or critique
- the delegated role only needs a small scoped context slice
- the reviewer trace should show delegated lineage clearly

Do not use this capability to build a broad autonomous multi-agent platform. Keep the contract narrow and explicit.

## Remaining adoption gap

No remaining adopter-facing gap is required for closeout of the runtime-first bounded handoff capability. Richer notebook-style delegated forensics remain deferred follow-up work only if real reviewer confusion appears after the current `Scoria.get_run_detail/1` and `/scoria/workflows/:run_id` surfaces prove insufficient.
