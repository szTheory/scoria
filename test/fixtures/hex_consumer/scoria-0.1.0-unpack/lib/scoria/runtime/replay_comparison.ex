defmodule Scoria.Runtime.ReplayComparison do
  @moduledoc """
  Builds curated original-versus-replay evidence maps for workflow steps.
  """

  alias Scoria.Runtime.RunSummary
  alias Scoria.Workflows.{Checkpoint, Event, Run, Step}

  def build(%Run{execution_mode: "replay"} = replay_run, %Run{} = source_run) do
    source_steps_by_id = Map.new(source_run.steps, &{&1.id, &1})
    source_steps_by_sequence = Map.new(source_run.steps, &{&1.sequence, &1})

    Enum.into(replay_run.steps, %{}, fn replay_step ->
      source_step = resolve_source_step(replay_step, replay_run, source_steps_by_id, source_steps_by_sequence)

      {replay_step.id,
       %{
         original: variant_groups(source_run, source_step, "original"),
         replay: variant_groups(replay_run, replay_step, "replay")
       }}
    end)
  end

  def build(%Run{}, _source_run), do: %{}

  def provenance_strip(%Run{execution_mode: "replay"} = replay_run) do
    summary = RunSummary.from_run(replay_run)
    latest_checkpoint = replay_run.checkpoints |> Enum.reverse() |> Enum.find(& &1.replay_disposition)

    %{
      source_run_id: summary.source_run_id,
      source_checkpoint_id: summary.source_checkpoint_id,
      execution_mode: summary.execution_mode,
      replay_posture: summary.replay_posture,
      live_tool_allowlist: summary.live_tool_allowlist,
      replay_disposition: latest_checkpoint && latest_checkpoint.replay_disposition,
      replay_reason_code: latest_checkpoint && latest_checkpoint.replay_reason_code
    }
  end

  def provenance_strip(%Run{}), do: %{}

  defp resolve_source_step(replay_step, replay_run, source_steps_by_id, source_steps_by_sequence) do
    explicit_source_step_id =
      replay_run
      |> source_refs_for_step(replay_step.id)
      |> Enum.reverse()
      |> Enum.find_value(& &1.source_step_id)

    cond do
      explicit_source_step_id && Map.has_key?(source_steps_by_id, explicit_source_step_id) ->
        source_steps_by_id[explicit_source_step_id]

      Map.has_key?(source_steps_by_sequence, replay_step.sequence) ->
        source_steps_by_sequence[replay_step.sequence]

      true ->
        nil
    end
  end

  defp source_refs_for_step(run, step_id) do
    checkpoint_refs =
      run
      |> assoc_list(:checkpoints)
      |> Enum.filter(&(&1.step_id == step_id))
      |> Enum.map(fn checkpoint ->
        %{
          source_step_id: map_value(checkpoint.metadata, "source_step_id"),
          source_checkpoint_id: map_value(checkpoint.metadata, "source_checkpoint_id"),
          source_run_id: map_value(checkpoint.metadata, "source_run_id")
        }
      end)

    event_refs =
      run
      |> assoc_list(:events)
      |> Enum.filter(&(&1.step_id == step_id))
      |> Enum.map(fn event ->
        %{
          source_step_id: map_value(event.payload, "source_step_id"),
          source_checkpoint_id: map_value(event.payload, "source_checkpoint_id"),
          source_run_id: map_value(event.payload, "source_run_id")
        }
      end)

    approval_refs =
      run
      |> assoc_list(:approvals)
      |> Enum.filter(&(&1.step_id == step_id))
      |> Enum.map(fn approval ->
        %{
          source_step_id: approval.source_step_id,
          source_checkpoint_id: approval.source_checkpoint_id,
          source_run_id: approval.source_run_id
        }
      end)

    checkpoint_refs ++ event_refs ++ approval_refs
  end

  defp variant_groups(run, step, source_variant) do
    checkpoint = find_checkpoint(run, step)
    event = find_event(run, step)
    approval = find_approval(run, step)
    source_refs = source_refs_for_step(run, step && step.id)

    %{
      provenance: provenance_group(run, step, checkpoint, event, approval, source_variant, source_refs),
      overrides: overrides_group(run),
      checkpoint_output: checkpoint_output_group(step, checkpoint, event),
      safety: safety_group(step, checkpoint, event, approval),
      promotion_snapshot: promotion_snapshot_group(run, step, event, checkpoint, source_variant)
    }
    |> Enum.into(%{}, fn {key, value} -> {key, value || %{}} end)
  end

  defp provenance_group(run, nil, checkpoint, event, approval, source_variant, source_refs) do
    %{
      workflow_run_id: run.id,
      workflow_step_id: nil,
      source_variant: source_variant,
      source_run_id: source_run_id(run, source_refs),
      source_checkpoint_id: source_checkpoint_id(run, checkpoint, source_variant, source_refs),
      execution_mode: run.execution_mode,
      replay_disposition: replay_disposition(checkpoint, event, approval),
      replay_reason_code: replay_reason_code(checkpoint, event, approval)
    }
  end

  defp provenance_group(run, step, checkpoint, event, approval, source_variant, source_refs) do
    %{
      workflow_run_id: run.id,
      workflow_step_id: step.id,
      source_variant: source_variant,
      source_run_id: source_run_id(run, source_refs),
      source_checkpoint_id: source_checkpoint_id(run, checkpoint, source_variant, source_refs),
      execution_mode: run.execution_mode,
      replay_disposition: replay_disposition(checkpoint, event, approval),
      replay_reason_code: replay_reason_code(checkpoint, event, approval),
      step_sequence: step.sequence
    }
  end

  defp overrides_group(%Run{} = run) do
    %{
      replay_overrides: run.replay_overrides || %{},
      live_tool_allowlist: live_tool_allowlist(run.replay_overrides)
    }
  end

  defp checkpoint_output_group(step, checkpoint, event) do
    %{
      checkpoint_id: checkpoint && checkpoint.id,
      event_id: event && event.id,
      transition: checkpoint && checkpoint.transition,
      event_type: event && event.event_type,
      projected_context: step && (step.projected_context || %{}),
      result_envelope: step && (step.result_envelope || %{}),
      error_envelope: step && (step.error_envelope || %{}),
      snapshot: checkpoint && (checkpoint.snapshot || %{}),
      recorded_outcome: recorded_outcome(event, checkpoint, step)
    }
  end

  defp safety_group(step, checkpoint, event, approval) do
    %{
      approval_id: approval && approval.id,
      checkpoint_id: checkpoint && checkpoint.id,
      event_id: event && event.id,
      idempotency_key: step && step.idempotency_key,
      replay_scope:
        value_or(
          approval && approval.replay_scope,
          checkpoint && map_value(checkpoint.metadata, "replay_scope"),
          event && map_value(event.payload, "replay_scope")
        ),
      replay_disposition: replay_disposition(checkpoint, event, approval),
      replay_reason_code: replay_reason_code(checkpoint, event, approval),
      executed_live:
        truthy?(
          value_or(
            approval && approval.executed_live,
            checkpoint && map_value(checkpoint.metadata, "executed_live"),
            event && map_value(event.payload, "executed_live")
          )
        )
    }
  end

  defp promotion_snapshot_group(run, step, event, checkpoint, source_variant) do
    %{
      workflow_run_id: run.id,
      workflow_step_id: step && step.id,
      source_variant: source_variant,
      recorded_outcome: recorded_outcome(event, checkpoint, step),
      replay_reason_code:
        value_or(
          event && event.replay_reason_code,
          checkpoint && checkpoint.replay_reason_code
        )
    }
  end

  defp find_checkpoint(_run, nil), do: nil

  defp find_checkpoint(run, step) do
    run.checkpoints
    |> Enum.reverse()
    |> Enum.find(&(&1.step_id == step.id))
  end

  defp find_event(_run, nil), do: nil

  defp find_event(run, step) do
    run.events
    |> Enum.reverse()
    |> Enum.find(&(&1.step_id == step.id))
  end

  defp find_approval(_run, nil), do: nil

  defp find_approval(run, step) do
    run.approvals
    |> Enum.reverse()
    |> Enum.find(&(&1.step_id == step.id))
  end

  defp recorded_outcome(%Event{} = event, _checkpoint, _step) do
    map_value(event.payload, "recorded_outcome")
  end

  defp recorded_outcome(_event, %Checkpoint{} = checkpoint, _step) do
    map_value(checkpoint.snapshot, "recorded_outcome") || map_value(checkpoint.snapshot, "result")
  end

  defp recorded_outcome(_event, _checkpoint, %Step{} = step) do
    map_value(step.result_envelope, "output") || map_value(step.result_envelope, "status")
  end

  defp recorded_outcome(_event, _checkpoint, _step), do: nil

  defp live_tool_allowlist(overrides) when is_map(overrides) do
    overrides
    |> Map.get("live_tool_allowlist", Map.get(overrides, :live_tool_allowlist, []))
    |> List.wrap()
  end

  defp live_tool_allowlist(_), do: []

  defp assoc_list(struct, field) do
    case Map.get(struct, field) do
      %Ecto.Association.NotLoaded{} -> []
      value when is_list(value) -> value
      _ -> []
    end
  end

  defp source_run_id(%Run{} = run, source_refs) do
    source_refs
    |> Enum.reverse()
    |> Enum.find_value(& &1.source_run_id)
    |> Kernel.||(run.source_run_id)
  end

  defp source_checkpoint_id(%Run{} = run, checkpoint, "replay", source_refs) do
    source_refs
    |> Enum.reverse()
    |> Enum.find_value(& &1.source_checkpoint_id)
    |> Kernel.||(run.source_checkpoint_id)
    |> Kernel.||(checkpoint && checkpoint.id)
  end

  defp source_checkpoint_id(%Run{}, checkpoint, _source_variant, _source_refs), do: checkpoint && checkpoint.id

  defp replay_disposition(checkpoint, event, approval) do
    value_or(
      approval && approval.replay_disposition,
      checkpoint && checkpoint.replay_disposition,
      event && event.replay_disposition
    )
  end

  defp replay_reason_code(checkpoint, event, approval) do
    value_or(
      approval && approval.replay_reason_code,
      checkpoint && checkpoint.replay_reason_code,
      event && event.replay_reason_code
    )
  end

  defp value_or(nil, nil, nil), do: nil
  defp value_or(first, _second, _third) when not is_nil(first), do: first
  defp value_or(nil, second, _third) when not is_nil(second), do: second
  defp value_or(nil, nil, third), do: third

  defp value_or(nil, nil), do: nil
  defp value_or(first, _second) when not is_nil(first), do: first
  defp value_or(nil, second), do: second

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
