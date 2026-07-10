defmodule Scoria do
  @moduledoc """
  Scoria is the public facade for starting, inspecting, and resuming AI work
  inside a Phoenix app.

  Start here when wiring Scoria into an application. The normal path is:

  1. Normalize request or session context with `identity/1`
  2. Start a durable run with `start_run/2`
  3. Persist the returned `run_id`
  4. Inspect or resume that exact run through the same module

  `session_id` is the host-owned continuity key that groups related turns.
  `run_id` is Scoria's exact durable handle for one run. Reuse a `session_id`
  across turns, but resume only by `run_id`.

  Use this facade from controllers, LiveViews, jobs, or service modules when
  the host app already owns identity, authorization, policy values, prompts,
  and business meaning. Scoria records the durable execution trace and returns
  public `Scoria.Runtime.RunSummary` / `Scoria.Runtime.RunDetail` data.

  For the first-run walkthrough, see `guides/getting-started.md` and
  `guides/golden-path.md`. For the ownership split, see `Scoria.Identity` and
  `guides/ownership-boundary.md`. For lower-level lifecycle APIs behind this
  facade, see `Scoria.Runtime`.

  ## Examples

      iex> identity =
      ...>   Scoria.identity(%{
      ...>     actor_id: "user_123",
      ...>     tenant_id: "tenant_456",
      ...>     session_id: "session_789"
      ...>   })
      iex> {identity.actor_id, identity.tenant_id, identity.session_id}
      {"user_123", "tenant_456", "session_789"}
      iex> identity.metadata
      %{}
  """

  alias Scoria.Runtime

  @doc """
  Normalizes caller-supplied edge identity into the canonical runtime envelope.
  """
  def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)

  @doc """
  Starts a run through the canonical public runtime facade.
  """
  def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)

  @doc """
  Starts a bounded delegated run with one explicit handoff and scoped context.

  Prefer `scoped_context:` for the host-curated context slice passed to the
  delegated role:

      Scoria.start_handoff_run(identity, "critic",
        root_role_id: "planner",
        delegated_kind: "review",
        handoff_input: %{"brief" => "Review the draft answer"},
        scoped_context: %{"task" => "policy review"}
      )

  `projected_context:` remains accepted as a legacy 0.1.x compatibility alias.
  The stored field name is not renamed by the terminology migration.
  """
  def start_handoff_run(identity, delegated_role_id, opts \\ []),
    do: Runtime.start_handoff_run(identity, delegated_role_id, opts)

  @doc """
  Resumes a run by exact durable `run_id`.
  """
  def resume_run(run_id, opts \\ []), do: Runtime.resume_run(run_id, opts)

  @doc """
  Returns the stable public summary for a run.
  """
  def get_run(run_id), do: Runtime.get_run(run_id)

  @doc """
  Returns the stable public summary for a run or raises.
  """
  def get_run!(run_id), do: Runtime.get_run!(run_id)

  @doc """
  Returns the curated detailed public view for a run.
  """
  def get_run_detail(run_id), do: Runtime.get_run_detail(run_id)

  @doc """
  Returns the curated detailed public view for a run or raises.
  """
  def get_run_detail!(run_id), do: Runtime.get_run_detail!(run_id)

  @doc """
  Lists runs that share the same host-owned `session_id`.
  """
  def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
end
