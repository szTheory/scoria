defmodule Scoria.Observe.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected expired)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_approvals" do
    field(:tool_name, :string)
    field(:arguments, :map, default: %{})
    field(:status, :string, default: "pending")
    field(:actor_id, :string)
    field(:tenant_id, :string)
    field(:session_id, :string)
    field(:run_id, :string)
    field(:reason, :string)
    field(:trace_id, :string)
    field(:blocker_kind, :string)
    field(:connector_id, :binary_id)
    field(:local_tool_id, :binary_id)
    field(:connector_label, :string)
    field(:connector_key, :string)
    field(:local_tool_name, :string)
    field(:grant_status, :string)
    field(:grant_subject_ref, :string)
    field(:policy_outcome, :string)
    field(:missing_scopes, {:array, :string}, default: [])
    field(:requested_scopes, {:array, :string}, default: [])
    field(:replay_allowed, :boolean, default: false)
    field(:blocker_workflow_event_id, :binary_id)
    field(:blocker_audit_outbox_event_id, :binary_id)
    field(:audit_outbox_event_id, :binary_id)
    field(:replay_disposition, :string)
    field(:replay_scope, :string)
    field(:replay_reason_code, :string)
    field(:source_run_id, :binary_id)
    field(:source_checkpoint_id, :binary_id)
    field(:source_step_id, :binary_id)
    field(:source_approval_id, :binary_id)
    field(:source_audit_outbox_event_id, :binary_id)
    field(:args_fingerprint, :string)
    field(:subject_ref, :string)
    field(:required_scopes, {:array, :string}, default: [])
    field(:policy_key, :string)
    field(:executed_live, :boolean, default: false)
    field(:replay_idempotency_key, :string)
    field(:workflow_run_id, :binary_id)
    field(:step_id, :binary_id)
    field(:checkpoint_id, :binary_id)
    field(:lock_version, :integer, default: 1)

    # D-26: the approval-consume CAS pair -- a single `Repo.update_all`
    # statement is the only writer (`WHERE ... AND consumed_at IS NULL
    # ... RETURNING id`), preventing `resume_run/1` from re-escalating the
    # identical tool call forever. Deliberately absent from `cast/3` below
    # -- see the comment there for why (opposite polarity from the D-15
    # rail/confluence_legs rule in `Run.changeset/2`).
    field(:consumed_at, :utc_datetime_usec)
    field(:consumed_by_step_id, :binary_id)

    # D-50 (checkpoint-resolved `d50-scope`): the bounded
    # per-run/per-tool/per-grade approval scope. `"call"` (the default,
    # NULL means `"call"`) or `"run_tool"`.
    field(:confluence_scope, :string)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [
      :tool_name,
      :arguments,
      :status,
      :actor_id,
      :tenant_id,
      :session_id,
      :run_id,
      :reason,
      :trace_id,
      :blocker_kind,
      :connector_id,
      :local_tool_id,
      :connector_label,
      :connector_key,
      :local_tool_name,
      :grant_status,
      :grant_subject_ref,
      :policy_outcome,
      :missing_scopes,
      :requested_scopes,
      :replay_allowed,
      :blocker_workflow_event_id,
      :blocker_audit_outbox_event_id,
      :audit_outbox_event_id,
      :replay_disposition,
      :replay_scope,
      :replay_reason_code,
      :source_run_id,
      :source_checkpoint_id,
      :source_step_id,
      :source_approval_id,
      :source_audit_outbox_event_id,
      :args_fingerprint,
      :subject_ref,
      :required_scopes,
      :policy_key,
      :executed_live,
      :replay_idempotency_key,
      :workflow_run_id,
      :step_id,
      :checkpoint_id,
      :lock_version
      # LOAD-BEARING (D-26, opposite polarity from `Run.changeset/2`'s D-15
      # rule): `:consumed_at`, `:consumed_by_step_id`, and `:confluence_scope`
      # are DELIBERATELY absent from this list. `Workflows.approve/3`
      # passes caller-supplied attrs straight through to this changeset
      # (`workflows.ex`), so a castable `:consumed_at` would let a caller
      # pass `consumed_at: nil` and un-consume an already-consumed
      # approval, re-opening a spent exfiltration grant. The only sanctioned
      # writer is the D-26 consume CAS's single `Repo.update_all(...)`
      # statement, which never goes through this changeset at all.
    ])
    |> validate_required([:tool_name, :status])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
  end
end
