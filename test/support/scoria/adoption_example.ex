defmodule Scoria.TestSupport.AdoptionExample do
  @moduledoc false

  @shared_session_id "shared-session"
  @waiting_status "waiting_for_approval"
  @completed_status "completed"

  def runtime_identity do
    %{
      actor_id: "public-actor",
      tenant_id: "public-tenant",
      session_id: @shared_session_id
    }
  end

  def shared_session_id, do: @shared_session_id
  def waiting_status, do: @waiting_status
  def completed_status, do: @completed_status

  def operator_route(run_id), do: "/scoria/workflows/#{run_id}"
  def operator_route_pattern, do: "/scoria/workflows/:run_id"

  # `phoenix_doc_surfaces/0` maps each canonical guides/ file to the fragment
  # subset it is responsible for. Phase 48's ExDoc/guide restructure split the
  # content that used to live in one `docs/phoenix_runtime_example.md` file
  # across `guides/golden-path.md`, `guides/capabilities/default-runtime.md`,
  # `guides/capabilities/bounded-handoffs.md`, and `guides/cheatsheet.cheatmd` —
  # no single file can satisfy the full fragment set with one `File.read!/1`.

  def golden_path_doc_fragments do
    [
      "identity -> start -> inspect -> resume",
      "actor_id: conn.assigns.current_user.id",
      "tenant_id: conn.assigns.current_account.id",
      "session_id: get_session(conn, :assistant_session_id)",
      "metadata: %{\"channel\" => \"web\"}",
      "`session_id` groups related host turns. `run_id` names one exact Scoria execution.",
      "next_run.session_id == started.session_id",
      "next_run.run_id != started.run_id",
      "mix test.runtime_to_handoff",
      "mix test.adoption",
      operator_route_pattern(),
      "session_id",
      "run_id",
      "Scoria.start_run/2",
      "Scoria.start_run",
      "Scoria.resume_run",
      "Scoria.get_run"
    ]
  end

  def default_runtime_doc_fragments do
    [
      "Scoria.identity/1",
      "Scoria.get_run_detail/1",
      "{:ok, summary} = Scoria.get_run(run_id)",
      "same_session_runs = Scoria.list_runs_for_session(session_id)",
      "Scoria.resume_run(run_id,",
      "last_scoria_run_id",
      "list_runs_for_session",
      "mix test.adoption"
    ]
  end

  def bounded_handoffs_doc_fragments do
    [
      "Scoria.start_handoff_run/3",
      "delegated = detail.delegated_handoffs",
      "mix test.runtime_to_handoff"
    ]
  end

  def cheatsheet_doc_fragments do
    [
      "Scoria.get_run_detail(handoff_run.run_id)",
      "handoff_run.run_id",
      "delegated = detail.delegated_handoffs"
    ]
  end

  @doc """
  Maps each canonical guides/ path to the fragment subset it must contain.

  Two fragments from the pre-Phase-48 single-file fixture were dropped rather
  than repointed, because the concept they asserted was genuinely removed
  from every guides/ file (not merely relocated or reworded):

  - `"defp needs_bounded_review?(draft_answer) do"` — this decision-point
    helper function does not appear anywhere in guides/; it was dropped when
    the runtime-to-handoff walkthrough was split into separate capability
    guides.
  - `"started.run_id != handoff_run.run_id"` — bounded handoffs now
    explicitly keep the delegated child step "under the same durable run"
    (see guides/capabilities/bounded-handoffs.md), so asserting the root and
    handoff run IDs differ would assert a behavior the current guides
    deliberately no longer describe.
  """
  def phoenix_doc_surfaces do
    %{
      "guides/golden-path.md" => golden_path_doc_fragments(),
      "guides/capabilities/default-runtime.md" => default_runtime_doc_fragments(),
      "guides/capabilities/bounded-handoffs.md" => bounded_handoffs_doc_fragments(),
      "guides/cheatsheet.cheatmd" => cheatsheet_doc_fragments()
    }
  end

  def handoff_doc_fragments do
    [
      "Scoria.start_handoff_run/3",
      "Scoria.get_run_detail/1",
      "Scoria.start_handoff_run(identity, \"critic\"",
      "Scoria.get_run_detail(started.run_id)",
      "delegated = detail.delegated_handoffs",
      "Host and Scoria ownership boundary",
      "The host app owns identity, escalation policy, prompt or draft selection, and scoped-context selection.",
      "Scoria owns durable run creation, scoped-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.",
      "Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.",
      "root_role_id: \"planner\"",
      "delegated_kind: \"review\"",
      "handoff_input: %{\"brief\" => \"Review the draft answer for policy and accuracy\"}",
      "scoped_context: %{",
      "scoped_context: %{}",
      "{:error, :unsafe_projected_context}",
      "before creating a durable delegated run.",
      "same durable run",
      "Delegated Trace",
      "No remaining adopter-facing gap",
      "deferred follow-up",
      "Broad runtime-state keys are rejected explicitly",
      "mix test.runtime_to_handoff",
      "mix test.adoption",
      "`transcript`",
      "`provider_session`",
      "`session`",
      "`secrets`",
      "`socket_state`",
      "handlers: %{\"review\" => {MyApp.RuntimeHandlers, :review}}",
      "/scoria/workflows/:run_id"
    ]
  end
end
