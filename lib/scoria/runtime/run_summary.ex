defmodule Scoria.Runtime.RunSummary do
  @moduledoc """
  Stable public summary DTO for lifecycle, polling, and resume flows.
  """

  alias Scoria.Workflows.Run

  @enforce_keys [
    :run_id,
    :session_id,
    :status,
    :actor_id,
    :tenant_id,
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
          current_step_id: Ecto.UUID.t() | nil,
          latest_checkpoint_id: Ecto.UUID.t() | nil,
          awaiting_approval: boolean(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  def from_run(%Run{} = run) do
    %__MODULE__{
      run_id: run.id,
      session_id: run.session_id,
      status: run.status,
      actor_id: run.actor_id,
      tenant_id: run.tenant_id,
      current_step_id: run.current_step_id,
      latest_checkpoint_id: run.latest_checkpoint_id,
      awaiting_approval: run.status == "waiting_for_approval",
      started_at: run.started_at,
      completed_at: run.completed_at,
      inserted_at: run.inserted_at,
      updated_at: run.updated_at
    }
  end
end
