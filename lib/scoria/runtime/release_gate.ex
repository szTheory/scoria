defmodule Scoria.Runtime.ReleaseGate do
  @moduledoc """
  Middleware that enforces release gating rules before a run is executed.
  Specifically prevents draft prompts from being served in production paths.
  """

  import Ecto.Query

  alias Scoria.Eval.{EvalRun, Verdict}
  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Ecto.UUID

  @online_scoring_source "online_scoring"

  @doc """
  Checks if the given `workflow_attrs` or `PromptTemplate` is allowed to execute.
  Returns `:ok` or a release-gating error tuple.
  """
  def check(%PromptTemplate{status: "draft"}), do: {:error, :unapproved_draft}

  def check(%PromptTemplate{} = template) do
    case latest_completed_eval_run(template.id) do
      nil ->
        handle_missing_verdict(template)

      %{threshold_verdict: verdict} ->
        if Verdict.blocks_release?(verdict) do
          {:error, {:eval_not_passing, verdict}}
        else
          :ok
        end
    end
  end

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

  defp latest_completed_eval_run(nil), do: nil

  defp latest_completed_eval_run(prompt_template_id) do
    EvalRun
    |> join(:left, [run], campaign in assoc(run, :campaign))
    |> where([run], run.prompt_template_id == ^prompt_template_id)
    |> where([run], run.status == "completed")
    |> where(
      [_run, campaign],
      fragment("?->>'source' IS DISTINCT FROM ?", campaign.metadata, ^@online_scoring_source)
    )
    |> order_by([run], desc: run.inserted_at)
    |> limit(1)
    |> select([run], %{threshold_verdict: run.threshold_verdict})
    |> Repo.one()
  end

  defp handle_missing_verdict(%PromptTemplate{} = template) do
    if Application.get_env(:scoria, :require_eval_verdict, false) do
      {:error, :eval_required}
    else
      :telemetry.execute(
        [:scoria, :release_gate, :ungated],
        %{},
        %{prompt_template_id: template.id}
      )

      :ok
    end
  end
end
