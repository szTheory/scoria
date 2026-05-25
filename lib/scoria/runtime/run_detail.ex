defmodule Scoria.Runtime.RunDetail do
  @moduledoc """
  Curated public detail DTO for advanced run inspection.
  """

  alias Scoria.Observe.Approval
  alias Scoria.Runtime.RunSummary
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  @enforce_keys [
    :summary,
    :steps,
    :checkpoints,
    :events,
    :approvals,
    :handoffs,
    :delegated_handoffs,
    :comparison_by_step,
    :replay_provenance_strip
  ]
  defstruct [
    :summary,
    :steps,
    :checkpoints,
    :events,
    :approvals,
    :handoffs,
    :delegated_handoffs,
    :comparison_by_step,
    :replay_provenance_strip
  ]

  @type item :: map()
  @type t :: %__MODULE__{
          summary: RunSummary.t(),
          steps: [item()],
          checkpoints: [item()],
          events: [item()],
          approvals: [item()],
          handoffs: [item()],
          delegated_handoffs: [item()],
          comparison_by_step: %{optional(Ecto.UUID.t()) => map()},
          replay_provenance_strip: map()
        }

  def from_run_tree(%Run{} = run, opts \\ []) do
    steps = Enum.map(run.steps, &step_item/1)
    handoffs = Enum.map(run.handoffs, &handoff_item/1)

    %__MODULE__{
      summary: RunSummary.from_run(run),
      steps: steps,
      checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
      events: Enum.map(run.events, &event_item/1),
      approvals: Enum.map(run.approvals, &approval_item/1),
      handoffs: handoffs,
      delegated_handoffs: delegated_handoff_items(steps, handoffs),
      comparison_by_step: Keyword.get(opts, :comparison_by_step, %{}),
      replay_provenance_strip: Keyword.get(opts, :replay_provenance_strip, %{})
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
      idempotency_key: step.idempotency_key,
      projected_context: step.projected_context || %{},
      result_envelope: step.result_envelope || %{},
      error_envelope: step.error_envelope || %{},
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
      snapshot: checkpoint.snapshot || %{},
      replay_disposition: checkpoint.replay_disposition,
      replay_reason_code: checkpoint.replay_reason_code,
      source_run_id: map_value(checkpoint.metadata, "source_run_id"),
      source_checkpoint_id: map_value(checkpoint.metadata, "source_checkpoint_id"),
      source_step_id: map_value(checkpoint.metadata, "source_step_id"),
      source_approval_id: map_value(checkpoint.metadata, "source_approval_id"),
      source_audit_outbox_event_id:
        map_value(checkpoint.metadata, "source_audit_outbox_event_id"),
      replay_scope: map_value(checkpoint.metadata, "replay_scope"),
      executed_live: truthy?(map_value(checkpoint.metadata, "executed_live")),
      inserted_at: checkpoint.inserted_at
    }
  end

  defp event_item(%Event{} = event) do
    %{
      id: event.id,
      step_id: event.step_id,
      sequence: event.sequence,
      event_type: event.event_type,
      replay_disposition: event.replay_disposition,
      replay_reason_code: event.replay_reason_code,
      source_run_id: map_value(event.payload, "source_run_id"),
      source_checkpoint_id: map_value(event.payload, "source_checkpoint_id"),
      source_step_id: map_value(event.payload, "source_step_id"),
      source_approval_id: map_value(event.payload, "source_approval_id"),
      source_audit_outbox_event_id: map_value(event.payload, "source_audit_outbox_event_id"),
      replay_scope: map_value(event.payload, "replay_scope"),
      executed_live: truthy?(map_value(event.payload, "executed_live")),
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
      replay_disposition: approval.replay_disposition,
      replay_reason_code: approval.replay_reason_code,
      replay_scope: approval.replay_scope,
      source_run_id: approval.source_run_id,
      source_checkpoint_id: approval.source_checkpoint_id,
      source_step_id: approval.source_step_id,
      source_approval_id: approval.source_approval_id,
      source_audit_outbox_event_id: approval.source_audit_outbox_event_id,
      executed_live: approval.executed_live,
      inserted_at: approval.inserted_at
    }
  end

  defp handoff_item(%Handoff{} = handoff) do
    %{
      id: handoff.id,
      step_id: handoff.step_id,
      delegated_role_id: handoff.delegated_role_id,
      delegated_kind: handoff.delegated_kind,
      capability_tags: handoff.capability_tags || [],
      handoff_input: handoff.handoff_input || %{},
      status: handoff.status,
      inserted_at: handoff.inserted_at
    }
  end

  defp delegated_handoff_items(steps, handoffs) do
    steps_by_parent =
      Enum.group_by(steps, & &1.parent_step_id)

    steps_by_id = Map.new(steps, &{&1.id, &1})

    handoffs
    |> Enum.map(fn handoff ->
      parent_step = Map.get(steps_by_id, handoff.step_id)

      child_step =
        steps_by_parent
        |> Map.get(handoff.step_id, [])
        |> Enum.filter(&delegated_child_step?(&1, handoff))
        |> Enum.sort_by(&{&1.sequence || 0, Map.get(&1, :inserted_at) || ~U[1970-01-01 00:00:00Z]})
        |> List.first()

      %{
        id: handoff.id,
        handoff_id: handoff.id,
        parent_step_id: handoff.step_id,
        parent_step_sequence: parent_step && parent_step.sequence,
        parent_step_kind: parent_step && parent_step.kind,
        parent_role_id: parent_step && parent_step.role_id,
        delegated_role_id: handoff.delegated_role_id,
        delegated_kind: handoff.delegated_kind,
        handoff_input: handoff.handoff_input,
        capability_tags: handoff.capability_tags,
        child_step_id: child_step && child_step.id,
        child_step_sequence: child_step && child_step.sequence,
        child_step_kind: child_step && child_step.kind,
        child_role_id: child_step && child_step.role_id,
        child_status: child_step_status(child_step),
        status: child_step_status(child_step),
        projected_context: child_projected_context(child_step),
        sequence: delegated_sequence(parent_step, child_step),
        inserted_at: handoff.inserted_at
      }
    end)
    |> Enum.sort_by(&{&1.sequence || 0, Map.get(&1, :inserted_at) || ~U[1970-01-01 00:00:00Z]})
  end

  defp delegated_child_step?(step, handoff) do
    step.role_id == handoff.delegated_role_id and step.kind == handoff.delegated_kind
  end

  defp child_step_status(nil), do: "child_step_pending"
  defp child_step_status(child_step), do: child_step.status

  defp child_projected_context(nil), do: %{}
  defp child_projected_context(child_step), do: child_step.projected_context || %{}

  defp delegated_sequence(parent_step, child_step) do
    cond do
      is_integer(parent_step && parent_step.sequence) -> parent_step.sequence
      is_integer(child_step && child_step.sequence) -> child_step.sequence
      true -> nil
    end
  end

  defp map_value(map, key) when is_map(map) do
    atom_key =
      try do
        String.to_existing_atom(key)
      rescue
        ArgumentError -> nil
      end

    Map.get(map, key, atom_key && Map.get(map, atom_key))
  end

  defp map_value(_map, _key), do: nil

  defp truthy?(value), do: value in [true, "true", 1, "1"]
end
