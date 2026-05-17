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
      "Scoria.resume_run",
      "Scoria.get_run",
      "list_runs_for_session"
    ]
  end
end
