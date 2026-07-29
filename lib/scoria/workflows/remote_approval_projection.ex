defmodule Scoria.Workflows.RemoteApprovalProjection do
  @moduledoc """
  Curated operator-facing projection for remote approval inbox and lineage reads.
  """

  import Ecto.Query, warn: false

  alias Scoria.Observe.Approval
  alias Scoria.Observe.Redactor
  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent

  @filter_fields ~w(actor_id session_id status tenant_id tool_name workflow_run_id replay_scope)a
  @preview_max_keys 10
  @preview_max_chars 512
  @decided_statuses ~w(approved rejected expired)
  @decided_default_limit 50

  # Plan 57-11 (D-39/D-40): this string MUST equal
  # `Scoria.MCP.Executor`'s own `@confluence_audit_event_type` module
  # attribute -- the two modules are coupled by this literal because the
  # audit row a confluence approval's `blocker_audit_outbox_event_id`
  # back-link resolves to is only ever written under this event type, and
  # constraining the batch lookup to it (rather than any row sharing the
  # id) keeps a forged or coincidental back-link from ever resolving to
  # unrelated audit evidence.
  @confluence_audit_event_type "tool.confluence.escalated"

  # Closed conversion from the STRING leg-source values
  # `Scoria.Confluence.audit_metadata_value/1` persists into the JSON the
  # copy layer's `ScoriaWeb.ApprovalCopy.witness_source_label/1` matches as
  # ATOMS. Never call `String.to_atom/1` or `String.to_existing_atom/1` on
  # a value read out of persisted JSON -- this hardcoded map is the only
  # conversion, and anything outside it resolves to `:unknown`.
  @confluence_leg_source_map %{
    "declared" => :declared,
    "scanner_infra" => :scanner_infra,
    "default_tier" => :default_tier,
    "unclassified" => :unclassified
  }

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

    approvals =
      Approval
      |> where([approval], approval.status == "pending")
      |> apply_filters(filters)
      |> order_by([approval], desc: approval.inserted_at, desc: approval.id)
      |> limit(^limit)
      |> Repo.all()

    events_by_id = confluence_audit_events_by_id(approvals)

    Enum.map(approvals, &project_approval(&1, events_by_id))
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

    approvals =
      Approval
      |> where([approval], approval.status in @decided_statuses)
      |> apply_filters(filters)
      |> order_by([approval], desc: approval.updated_at, desc: approval.id)
      |> limit(^limit)
      |> Repo.all()

    events_by_id = confluence_audit_events_by_id(approvals)

    Enum.map(approvals, &project_approval(&1, events_by_id))
  end

  def get_approval_lineage!(approval_id) do
    approval = Repo.get!(Approval, approval_id)
    events_by_id = confluence_audit_events_by_id([approval])
    project_approval(approval, events_by_id)
  end

  defp apply_filters(query, filters) do
    Enum.reduce(@filter_fields, query, fn field, query ->
      case Map.get(filters, field) do
        nil -> query
        value -> where(query, [approval], field(approval, ^field) == ^value)
      end
    end)
  end

  # Plan 57-11: batch-loads the confluence audit rows for a PAGE of
  # approvals in exactly one query, mirroring
  # `ScoriaWeb.ApprovalsLive.Index.decision_events_by_approval_id/1`'s
  # batch-by-visible-id-set pattern rather than a per-row lookup. Collects
  # `blocker_audit_outbox_event_id` from ONLY the approvals whose
  # `blocker_kind` is `"confluence"` and whose back-link is non-nil, and
  # returns an empty map immediately (no query at all) when that id list is
  # empty -- a page with zero confluence approvals costs nothing extra
  # (D-51).
  defp confluence_audit_events_by_id(approvals) do
    ids =
      approvals
      |> Enum.filter(fn approval ->
        approval.blocker_kind == "confluence" and
          not is_nil(approval.blocker_audit_outbox_event_id)
      end)
      |> Enum.map(& &1.blocker_audit_outbox_event_id)

    case ids do
      [] ->
        %{}

      ids ->
        AuditOutboxEvent
        |> where([event], event.id in ^ids)
        |> where([event], event.event_type == ^@confluence_audit_event_type)
        |> Repo.all()
        |> Map.new(&{&1.id, &1})
    end
  end

  # Resolves the escalation-time confluence evidence for ONE approval out
  # of the batch-loaded events map. All five keys stay nil unless: the
  # approval is a confluence approval, its back-link is non-nil, the map
  # holds an event for that id, AND that event's `workflow_run_id` equals
  # the approval's own `workflow_run_id` (D-40) -- the back-link column
  # carries no foreign key and is reachable through pass-through decision
  # attrs, so a pointer at another run's evidence must be ignored rather
  # than rendered. Never defaulted, inferred, or synthesized -- an
  # unreadable back-link produces absent values, never a manufactured
  # grade or leg source.
  defp confluence_evidence_fields(
         %Approval{
           blocker_kind: "confluence",
           blocker_audit_outbox_event_id: event_id,
           workflow_run_id: workflow_run_id
         },
         events_by_id
       )
       when not is_nil(event_id) do
    case Map.get(events_by_id, event_id) do
      %AuditOutboxEvent{workflow_run_id: ^workflow_run_id} = event ->
        metadata = event.metadata || %{}

        %{
          combination: Map.get(metadata, "combination"),
          grade: Map.get(metadata, "grade"),
          private_data_source: confluence_leg_source(Map.get(metadata, "private_data_source")),
          untrusted_content_source:
            confluence_leg_source(Map.get(metadata, "untrusted_content_source")),
          exfil_source: confluence_leg_source(Map.get(metadata, "exfil_source"))
        }

      _other ->
        confluence_evidence_nil()
    end
  end

  defp confluence_evidence_fields(_approval, _events_by_id), do: confluence_evidence_nil()

  defp confluence_evidence_nil do
    %{
      combination: nil,
      grade: nil,
      private_data_source: nil,
      untrusted_content_source: nil,
      exfil_source: nil
    }
  end

  defp confluence_leg_source(nil), do: nil
  defp confluence_leg_source(value), do: Map.get(@confluence_leg_source_map, value, :unknown)

  defp project_approval(%Approval{} = approval, events_by_id) do
    baseline_target = baseline_target(approval)
    confluence_evidence = confluence_evidence_fields(approval, events_by_id)

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
      updated_at: approval.updated_at,
      combination: confluence_evidence.combination,
      grade: confluence_evidence.grade,
      private_data_source: confluence_evidence.private_data_source,
      untrusted_content_source: confluence_evidence.untrusted_content_source,
      exfil_source: confluence_evidence.exfil_source
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
