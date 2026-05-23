defmodule Scoria.Workflows.RemoteApprovalProjection do
  @moduledoc """
  Curated operator-facing projection for remote approval inbox and lineage reads.
  """

  import Ecto.Query, warn: false

  alias Scoria.Observe.Approval
  alias Scoria.Repo

  @filter_fields ~w(actor_id session_id status tenant_id tool_name workflow_run_id replay_scope)a

  def list_pending_approvals(filters \\ %{}) do
    filters = normalize_filters(filters)

    Approval
    |> where([approval], approval.status == "pending")
    |> apply_filters(filters)
    |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
    |> Repo.all()
    |> Enum.map(&project_approval/1)
  end

  def get_approval_lineage!(approval_id) do
    Approval
    |> Repo.get!(approval_id)
    |> project_approval()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(@filter_fields, query, fn field, query ->
      case Map.get(filters, field) do
        nil -> query
        value -> where(query, [approval], field(approval, ^field) == ^value)
      end
    end)
  end

  defp project_approval(%Approval{} = approval) do
    %{
      id: approval.id,
      workflow_run_id: approval.workflow_run_id,
      step_id: approval.step_id,
      checkpoint_id: approval.checkpoint_id,
      status: approval.status,
      tool_name: approval.tool_name,
      actor_id: approval.actor_id,
      tenant_id: approval.tenant_id,
      session_id: approval.session_id,
      reason: approval.reason,
      trace_id: approval.trace_id,
      blocker_kind: approval.blocker_kind,
      grant_status: approval.grant_status,
      grant_subject_ref: approval.grant_subject_ref,
      policy_outcome: approval.policy_outcome,
      requested_scopes: approval.requested_scopes,
      required_scopes: approval.required_scopes,
      replay_allowed: approval.replay_allowed,
      replay_disposition: approval.replay_disposition,
      replay_reason_code: approval.replay_reason_code,
      replay_scope: approval.replay_scope,
      source_run_id: approval.source_run_id,
      source_checkpoint_id: approval.source_checkpoint_id,
      source_step_id: approval.source_step_id,
      source_approval_id: approval.source_approval_id,
      source_audit_outbox_event_id: approval.source_audit_outbox_event_id,
      args_fingerprint: approval.args_fingerprint,
      subject_ref: approval.subject_ref,
      policy_key: approval.policy_key,
      executed_live: approval.executed_live,
      replay_idempotency_key: approval.replay_idempotency_key,
      audit_outbox_event_id: approval.audit_outbox_event_id,
      blocker_workflow_event_id: approval.blocker_workflow_event_id,
      blocker_audit_outbox_event_id: approval.blocker_audit_outbox_event_id,
      inserted_at: approval.inserted_at,
      updated_at: approval.updated_at
    }
  end

  defp normalize_filters(filters) when is_map(filters) do
    Map.new(filters, fn
      {key, value} when is_binary(key) ->
        normalized_key =
          try do
            String.to_existing_atom(key)
          rescue
            ArgumentError -> key
          end

        {normalized_key, value}

      pair ->
        pair
    end)
  end

  defp normalize_filters(_filters), do: %{}
end
