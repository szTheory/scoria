defmodule Scoria.Runtime.ReleaseGate do
  @moduledoc """
  Middleware that enforces release gating rules before a run is executed.
  Specifically prevents draft prompts from being served in production paths.
  """

  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Ecto.UUID

  @doc """
  Checks if the given `workflow_attrs` or `PromptTemplate` is allowed to execute.
  Returns `:ok` or `{:error, :unapproved_draft}`.
  """
  def check(%PromptTemplate{status: "draft"}), do: {:error, :unapproved_draft}
  def check(%PromptTemplate{}), do: :ok

  def check(%{metadata: metadata}) when is_map(metadata) do
    # Try fetching from prompt_policy with string or atom keys, or top-level runtime map
    prompt_id =
      case metadata do
        %{"runtime" => %{"prompt_policy" => %{prompt_ref: id}}} when is_binary(id) -> id
        %{"runtime" => %{"prompt_policy" => %{"prompt_ref" => id}}} when is_binary(id) -> id
        %{"runtime" => %{"prompt_ref" => id}} when is_binary(id) -> id
        _ -> nil
      end

    if prompt_id do
      case UUID.cast(prompt_id) do
        {:ok, uuid} ->
          case Repo.get(PromptTemplate, uuid) do
            nil -> :ok
            template -> check(template)
          end
        :error ->
          :ok
      end
    else
      :ok
    end
  end

  def check(_), do: :ok
end
