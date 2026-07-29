defmodule Scoria.Workflows.RemoteApprovalProjection do
  @moduledoc """
  Curated operator-facing projection for remote approval inbox and lineage reads.
  """

  import Ecto.Query, warn: false

  alias Scoria.Observe.Approval
  alias Scoria.Observe.Redactor
  alias Scoria.Repo

  @filter_fields ~w(actor_id session_id status tenant_id tool_name workflow_run_id replay_scope)a
  @preview_max_keys 10
  @preview_max_chars 512
  @decided_statuses ~w(approved rejected expired)
  @decided_default_limit 50

  # D-51: capped with the SAME page-size attribute and the same
  # limit-popping/load-more pattern `list_decided_approvals/1` already uses
  # (`@decided_default_limit`) -- two functions differing only in status
  # scope must not invent two different pagination shapes. The uncapped
  # query was safe only because approvals were rare and human-initiated;
  # the confluence escalation gate is precisely what makes escalation
  # machine-initiated and potentially high volume, and this is the call
  # site an unattended strict-mode adopter's LiveView mounts and PubSub
  # reloads hit on every pending-inbox load.
  def list_pending_approvals(filters \\ %{}) do
    {limit, filters} =
      filters
      |> normalize_filters()
      |> Map.pop(:limit, @decided_default_limit)

    Approval
    |> where([approval], approval.status == "pending")
    |> apply_filters(filters)
    |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&project_approval/1)
  end

  @doc """
  Bounded, filterable decided-approval history (D-20). Mirrors
  `list_pending_approvals/1` exactly, swapping only the `where` scope and adding a
  cap (capped + load-more per D-10).

  The `desc updated_at, desc id` order is a cheap query-level PROXY sort only —
  the *displayed* decided-at/decider comes from the decision `AuditOutboxEvent`
  (Plan 07), not from this timestamp.
  """
  def list_decided_approvals(filters \\ %{}) do
    {limit, filters} =
      filters
      |> normalize_filters()
      |> Map.pop(:limit, @decided_default_limit)

    Approval
    |> where([approval], approval.status in @decided_statuses)
    |> apply_filters(filters)
    |> order_by([approval], desc: approval.updated_at, desc: approval.id)
    |> limit(^limit)
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
    baseline_target = baseline_target(approval)

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
      arguments_preview: preview_arguments(approval.arguments),
      connector_label: approval.connector_label,
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
      baseline_target: baseline_target,
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

  defp baseline_target(%Approval{tool_name: "dataset_baseline_promotion"} = approval) do
    %{
      dataset_id: argument_value(approval.arguments, "dataset_id"),
      dataset_name: argument_value(approval.arguments, "dataset_name"),
      dataset_version: argument_value(approval.arguments, "dataset_version"),
      source_variant: argument_value(approval.arguments, "source_variant")
    }
  end

  defp baseline_target(_approval), do: nil

  defp argument_value(arguments, key) when is_map(arguments) do
    Map.get(arguments, key, Map.get(arguments, String.to_existing_atom(key), nil))
  rescue
    ArgumentError -> Map.get(arguments, key)
  end

  defp argument_value(_arguments, _key), do: nil

  defp preview_arguments(arguments) when is_map(arguments) do
    arguments
    |> Redactor.redact()
    |> Enum.take(@preview_max_keys)
    |> Map.new()
    |> cap_preview_size()
  end

  defp preview_arguments(_arguments), do: %{}

  defp cap_preview_size(preview) do
    if preview_char_count(preview) > @preview_max_chars do
      preview
      |> Enum.take(div(@preview_max_keys, 2))
      |> Map.new()
      |> cap_preview_size()
    else
      preview
    end
  end

  defp preview_char_count(preview), do: preview |> inspect() |> String.length()
end
