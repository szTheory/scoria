defmodule Scoria.Workflows.PromptRelease do
  @moduledoc """
  Event-driven workflow service for prompt release approvals.
  """

  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.PromptRegistry

  @doc """
  Starts a prompt release workflow and immediately requests remote approval.
  """
  def start_release_workflow(template_id, actor_id, attrs) when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)
    tenant_id = attrs |> fetch_attr(:tenant_id) |> required_id!(:tenant_id)
    session_id = attrs |> fetch_attr(:session_id) |> optional_id!(:session_id)

    Repo.transaction(fn ->
      {:ok, run} =
        %{
          tenant_id: tenant_id,
          actor_id: optional_id!(actor_id, :actor_id),
          root_role_id: "operator"
        }
        |> maybe_put(:session_id, session_id)
        |> Workflows.create_run()

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "tool_call",
          status: "running",
          role_id: "operator"
        })

      {:ok, step_or_approval} =
        request_remote_approval(run.id, step.id, %{
          tool_name: "prompt_release",
          arguments: %{"template_id" => template_id}
        })

      step_or_approval
    end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp fetch_attr(attrs, field), do: Map.get(attrs, field) || Map.get(attrs, to_string(field))

  defp required_id!(value, field) do
    case optional_id!(value, field) do
      nil -> raise ArgumentError, "#{field} is required for prompt release workflow"
      id -> id
    end
  end

  defp optional_id!(value, _field) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      id -> id
    end
  end

  defp optional_id!(nil, _field), do: nil

  defp optional_id!(value, field) do
    raise ArgumentError,
          "#{field} must be a string for prompt release workflow, got: #{inspect(value)}"
  end

  @doc """
  Requests remote approval for a prompt release.
  """
  def request_remote_approval(run_id, step_id, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:replay_allowed, true)

    Workflows.request_remote_approval(run_id, step_id, attrs)
  end

  @doc """
  Approves or rejects a prompt release request, promoting the draft if approved.
  """
  def approve(approval_id, status, attrs \\ %{}) when status in ["approved", "rejected"] do
    Repo.transaction(fn ->
      {:ok, updated_approval} = Workflows.approve(approval_id, status, attrs)

      if status == "approved" do
        template_id = updated_approval.arguments["template_id"]
        template = PromptRegistry.get_prompt_template!(template_id)
        PromptRegistry.activate_prompt_template!(template)
      end

      updated_approval
    end)
  end
end
