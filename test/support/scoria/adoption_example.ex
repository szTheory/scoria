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
      "Scoria.identity/1",
      "Scoria.start_run/2",
      "Scoria.start_handoff_run/3",
      "Scoria.get_run_detail/1",
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
      "defp needs_bounded_review?(draft_answer) do",
      "Scoria.get_run_detail(handoff_run.run_id)",
      "handoff_run.run_id",
      "delegated = detail.delegated_handoffs",
      "last_scoria_handoff_run_id",
      "started.run_id != handoff_run.run_id",
      "session_id groups related host turns; run_id names one exact Scoria execution.",
      "identity -> start -> inspect -> resume",
      "Scoria.resume_run",
      "Scoria.get_run",
      "list_runs_for_session"
    ]
  end

  def handoff_doc_fragments do
    [
      "Scoria.start_handoff_run/3",
      "Scoria.get_run_detail/1",
      "Scoria.start_handoff_run(identity, \"critic\"",
      "Scoria.get_run_detail(started.run_id)",
      "delegated = detail.delegated_handoffs",
      "Host and Scoria ownership boundary",
      "The host app owns identity, escalation policy, prompt or draft selection, and projected-context selection.",
      "Scoria owns durable run creation, projected-context validation, queued delegated child creation, and curated readback through `Scoria.get_run_detail/1`.",
      "Scoria does not copy hidden transcript, provider session, socket assigns, cookies, headers, or secrets into the handoff.",
      "root_role_id: \"planner\"",
      "delegated_kind: \"review\"",
      "handoff_input: %{\"brief\" => \"Review the draft answer for policy and accuracy\"}",
      "projected_context: %{",
      "projected_context: %{}",
      "{:error, :unsafe_projected_context}",
      "before creating a durable delegated run.",
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
