defmodule Scoria.Runtime.RunDetail do
  @moduledoc """
  Curated public detail DTO for advanced run inspection.
  """

  alias Scoria.Observe.Approval
  alias Scoria.Runtime.RunSummary
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  @enforce_keys [:summary, :steps, :checkpoints, :events, :approvals, :handoffs]
  defstruct [:summary, :steps, :checkpoints, :events, :approvals, :handoffs]

  @type item :: map()
  @type t :: %__MODULE__{
          summary: RunSummary.t(),
          steps: [item()],
          checkpoints: [item()],
          events: [item()],
          approvals: [item()],
          handoffs: [item()]
        }

  def from_run_tree(%Run{} = run) do
    %__MODULE__{
      summary: RunSummary.from_run(run),
      steps: Enum.map(run.steps, &step_item/1),
      checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
      events: Enum.map(run.events, &event_item/1),
      approvals: Enum.map(run.approvals, &approval_item/1),
      handoffs: Enum.map(run.handoffs, &handoff_item/1)
    }
  end

  defp step_item(%Step{} = step) do
    %{
      id: step.id,
      sequence: step.sequence,
      kind: step.kind,
      role_id: step.role_id,
      status: step.status,
      parent_step_id: step.parent_step_id,
      started_at: step.started_at,
      completed_at: step.completed_at
    }
  end

  defp checkpoint_item(%Checkpoint{} = checkpoint) do
    %{
      id: checkpoint.id,
      step_id: checkpoint.step_id,
      sequence: checkpoint.sequence,
      transition: checkpoint.transition,
      status: checkpoint.status,
      inserted_at: checkpoint.inserted_at
    }
  end

  defp event_item(%Event{} = event) do
    %{
      id: event.id,
      step_id: event.step_id,
      sequence: event.sequence,
      event_type: event.event_type,
      inserted_at: event.inserted_at
    }
  end

  defp approval_item(%Approval{} = approval) do
    %{
      id: approval.id,
      step_id: approval.step_id,
      checkpoint_id: approval.checkpoint_id,
      status: approval.status,
      tool_name: approval.tool_name,
      actor_id: approval.actor_id,
      tenant_id: approval.tenant_id,
      session_id: approval.session_id,
      inserted_at: approval.inserted_at
    }
  end

  defp handoff_item(%Handoff{} = handoff) do
    %{
      id: handoff.id,
      step_id: handoff.step_id,
      delegated_role_id: handoff.delegated_role_id,
      status: handoff.status,
      inserted_at: handoff.inserted_at
    }
  end
end
