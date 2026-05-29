defmodule Scoria.Workflows.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(running waiting_for_approval paused retrying failed completed cancelled)
  @execution_modes ~w(live replay)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_runs" do
    field :actor_id, :string
    field :tenant_id, :string
    field :session_id, :string
    field :root_role_id, :string
    field :source_run_id, :binary_id
    field :source_checkpoint_id, :binary_id
    field :status, :string, default: "running"
    field :execution_mode, :string, default: "live"
    field :replay_overrides, :map, default: %{}
    field :current_step_id, :binary_id
    field :latest_checkpoint_id, :binary_id
    field :lock_version, :integer, default: 1
    field :metadata, :map, default: %{}
    field :error_envelope, :map, default: %{}
    field :started_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :last_heartbeat_at, :utc_datetime_usec

    has_many :steps, Scoria.Workflows.Step
    has_many :checkpoints, Scoria.Workflows.Checkpoint
    has_many :events, Scoria.Workflows.Event
    has_many :handoffs, Scoria.Workflows.Handoff
    has_many :approvals, Scoria.Observe.Approval, foreign_key: :workflow_run_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :session_id,
      :actor_id,
      :tenant_id,
      :root_role_id,
      :source_run_id,
      :source_checkpoint_id,
      :status,
      :execution_mode,
      :replay_overrides,
      :current_step_id,
      :latest_checkpoint_id,
      :lock_version,
      :metadata,
      :error_envelope,
      :started_at,
      :completed_at,
      :last_heartbeat_at
    ])
    |> validate_replay_allowlist_immutability()
    |> validate_required([:root_role_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:execution_mode, @execution_modes)
    |> optimistic_lock(:lock_version)
  end

  defp validate_replay_allowlist_immutability(changeset) do
    run = changeset.data
    next_overrides = get_field(changeset, :replay_overrides) || %{}
    previous_overrides = run.replay_overrides || %{}

    if replay_started?(run) and widening_allowlist?(previous_overrides, next_overrides) do
      add_error(changeset, :replay_overrides, "live_tool_allowlist cannot expand after replay start")
    else
      changeset
    end
  end

  defp replay_started?(%__MODULE__{execution_mode: "replay"} = run), do: not is_nil(run.started_at)
  defp replay_started?(_run), do: false

  defp widening_allowlist?(previous_overrides, next_overrides) do
    previous = MapSet.new(live_tool_allowlist(previous_overrides))
    next = MapSet.new(live_tool_allowlist(next_overrides))
    not MapSet.subset?(next, previous)
  end

  defp live_tool_allowlist(overrides) do
    overrides
    |> Map.get("live_tool_allowlist", Map.get(overrides, :live_tool_allowlist, []))
    |> List.wrap()
  end
end
