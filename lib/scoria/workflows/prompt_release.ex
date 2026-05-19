defmodule Scoria.Workflows.PromptRelease do
  @moduledoc """
  Event-driven workflow service for prompt release approvals.
  """

  alias Scoria.Repo
  alias Scoria.Workflows
  alias Scoria.PromptRegistry

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
        {:ok, _} = PromptRegistry.transition_status(template, "active")
      end

      updated_approval
    end)
  end
end
