defmodule Scoria.Runtime.RunSummary do
  @moduledoc """
  `Scoria.Runtime.RunSummary` is the compact public DTO returned by run
  lifecycle and polling APIs.

  Use this struct when a host app needs to store or display the current state of
  one durable Scoria run without loading every step, event, approval, or handoff
  record. It is returned by `Scoria.start_run/2`, `Scoria.resume_run/2`,
  `Scoria.get_run/1`, and `Scoria.list_runs_for_session/1`.

  `run_id` identifies one exact Scoria execution. `session_id` remains the
  host-owned continuity key that can group multiple runs in the same
  conversation or workflow thread.

  For the first-run lifecycle, see `guides/golden-path.md`. For the host-owned
  boundary around identity, policy, and business records, see
  `guides/ownership-boundary.md`.
  """

  alias Scoria.Workflows.Run

  @enforce_keys [
    :run_id,
    :session_id,
    :status,
    :actor_id,
    :tenant_id,
    :source_run_id,
    :source_checkpoint_id,
    :execution_mode,
    :replay_posture,
    :live_tool_allowlist,
    :any_seam_executed_live,
    :current_step_id,
    :latest_checkpoint_id,
    :awaiting_approval,
    :started_at,
    :completed_at,
    :inserted_at,
    :updated_at
  ]
  defstruct [
    :run_id,
    :session_id,
    :status,
    :actor_id,
    :tenant_id,
    :source_run_id,
    :source_checkpoint_id,
    :execution_mode,
    :replay_posture,
    :live_tool_allowlist,
    :any_seam_executed_live,
    :current_step_id,
    :latest_checkpoint_id,
    :awaiting_approval,
    :started_at,
    :completed_at,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          run_id: String.t(),
          session_id: String.t() | nil,
          status: String.t(),
          actor_id: String.t() | nil,
          tenant_id: String.t() | nil,
          source_run_id: Ecto.UUID.t() | nil,
          source_checkpoint_id: Ecto.UUID.t() | nil,
          execution_mode: String.t(),
          replay_posture: String.t(),
          live_tool_allowlist: [String.t()],
          any_seam_executed_live: boolean(),
          current_step_id: Ecto.UUID.t() | nil,
          latest_checkpoint_id: Ecto.UUID.t() | nil,
          awaiting_approval: boolean(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  def from_run(%Run{} = run) do
    live_tool_allowlist = live_tool_allowlist(run.replay_overrides)

    %__MODULE__{
      run_id: run.id,
      session_id: run.session_id,
      status: run.status,
      actor_id: run.actor_id,
      tenant_id: run.tenant_id,
      source_run_id: run.source_run_id,
      source_checkpoint_id: run.source_checkpoint_id,
      execution_mode: run.execution_mode,
      replay_posture: replay_posture(run.execution_mode, live_tool_allowlist),
      live_tool_allowlist: live_tool_allowlist,
      any_seam_executed_live: any_seam_executed_live?(run),
      current_step_id: run.current_step_id,
      latest_checkpoint_id: run.latest_checkpoint_id,
      awaiting_approval: run.status == "waiting_for_approval",
      started_at: run.started_at,
      completed_at: run.completed_at,
      inserted_at: run.inserted_at,
      updated_at: run.updated_at
    }
  end

  defp replay_posture("replay", []), do: "safe_replay"
  defp replay_posture("replay", _allowlist), do: "allowlist_live"
  defp replay_posture(_mode, _allowlist), do: "live"

  defp live_tool_allowlist(overrides) when is_map(overrides) do
    overrides
    |> Map.get("live_tool_allowlist", Map.get(overrides, :live_tool_allowlist, []))
    |> List.wrap()
  end

  defp live_tool_allowlist(_), do: []

  defp any_seam_executed_live?(%Run{} = run) do
    Enum.any?(loaded_assoc(run, :approvals), &(&1.executed_live == true)) or
      Enum.any?(loaded_assoc(run, :events), &event_executed_live?/1)
  end

  defp event_executed_live?(event) do
    event
    |> Map.get(:payload, %{})
    |> Map.get("executed_live", false)
  end

  defp loaded_assoc(run, key) do
    case Map.get(run, key) do
      %Ecto.Association.NotLoaded{} -> []
      value -> List.wrap(value)
    end
  end
end
