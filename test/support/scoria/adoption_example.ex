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

  def doc_fragments do
    [
      "actor_id: conn.assigns.current_user.id",
      "tenant_id: conn.assigns.current_account.id",
      "session_id: get_session(conn, :assistant_session_id)",
      "metadata: %{\"channel\" => \"web\"}",
      "{:ok, summary} = Scoria.get_run(run_id)",
      "same_session_runs = Scoria.list_runs_for_session(session_id)",
      "Scoria.resume_run(run_id,",
      "next_run.session_id == session_id",
      "next_run.run_id != run_id",
      operator_route_pattern(),
      "session_id",
      "run_id",
      "Scoria.start_run",
      "identity -> start -> inspect -> resume",
      "Scoria.resume_run",
      "Scoria.get_run",
      "list_runs_for_session"
    ]
  end

  def handoff_doc_fragments do
    [
      "Scoria.start_handoff_run(identity, \"critic\"",
      "Scoria.get_run_detail(started.run_id)",
      "delegated = detail.delegated_handoffs",
      "root_role_id: \"planner\"",
      "delegated_kind: \"review\"",
      "handoff_input: %{\"brief\" => \"Review the draft answer for policy and accuracy\"}",
      "projected_context: %{",
      "projected_context: %{}",
      "same durable run",
      "Delegated Evidence",
      "No remaining adopter-facing gap",
      "deferred follow-up",
      "Broad runtime-state keys are rejected explicitly",
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
