defmodule Scoria.Workflows.JidoAdapter do
  @moduledoc """
  Optional adapter that translates Jido-style directives into Scoria workflow primitives.
  """

  alias Scoria.Workflows

  def translate_directive(%{"type" => "handoff"} = directive) do
    with {:ok, delegated_role_id} <- fetch_string(directive, "delegated_role_id") do
      {:ok,
       %{
         kind: :handoff,
         delegated_role_id: delegated_role_id,
         capability_tags: List.wrap(Map.get(directive, "capability_tags", [])),
         handoff_input: Map.get(directive, "handoff_input", %{}),
         projected_context: Map.get(directive, "projected_context", %{})
       }}
    end
  end

  def translate_directive(%{"type" => "step_result"} = directive) do
    {:ok, %{kind: :step_result, result_envelope: Map.get(directive, "result", %{})}}
  end

  def translate_directive(%{"type" => "event"} = directive) do
    with {:ok, event_type} <- fetch_string(directive, "event_type") do
      {:ok, %{kind: :event, event_type: event_type, payload: Map.get(directive, "payload", %{})}}
    end
  end

  def translate_directive(_directive), do: {:error, :unsupported_directive}

  def apply_directive(step_id, directive) do
    step = Workflows.get_step!(step_id)

    case translate_directive(directive) do
      {:ok, %{kind: :handoff} = handoff} ->
        Workflows.create_handoff(step, %{
          delegated_role_id: handoff.delegated_role_id,
          capability_tags: handoff.capability_tags,
          handoff_input: handoff.handoff_input,
          result_summary: %{},
          status: "pending"
        })

      {:ok, %{kind: :step_result, result_envelope: result_envelope}} ->
        Workflows.complete_step(step.id, result_envelope)

      {:ok, %{kind: :event, event_type: event_type, payload: payload}} ->
        Workflows.append_event(step.run_id, step.id, %{event_type: event_type, payload: payload})

      error ->
        error
    end
  end

  defp fetch_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :unsupported_directive}
    end
  end
end
