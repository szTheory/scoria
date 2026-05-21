defmodule Scoria.Eval.CampaignWorker do
  @moduledoc """
  Durable worker envelope for one eval campaign target shard.
  """

  use Oban.Worker,
    queue: :evals,
    unique: [
      period: 60,
      fields: [:worker, :args],
      keys: [:eval_run_id],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  alias Oban.Job
  alias Scoria.Eval

  @required_keys ~w(campaign_id campaign_target_id eval_run_id tenant_id eval_spec_id provider model)

  @impl Oban.Worker
  def perform(%Job{args: args}) do
    with {:ok, context} <- Eval.load_campaign_execution(args),
         :ok <- maybe_mark_running(context),
         {:ok, result} <- Eval.execute_campaign_target(context),
         {:ok, _campaign} <- Eval.complete_campaign_target(context, result) do
      :ok
    else
      {:error, reason} ->
        with {:ok, context} <- Eval.load_campaign_execution(args) do
          fatal? = Eval.fatal_campaign_failure?(reason)
          {:ok, _campaign} = Eval.fail_campaign_target(context, reason, fatal?: fatal?)
        end

        {:error, reason}
    end
  end

  def new_job(args, opts \\ []) do
    args
    |> normalize_args()
    |> new(Keyword.put(opts, :queue, :evals))
  end

  defp normalize_args(args) do
    args = Map.new(args)

    Enum.reduce(@required_keys, %{}, fn key, acc ->
      Map.put(acc, key, fetch_required!(args, key))
    end)
    |> Map.put("metadata", normalize_metadata(args["metadata"] || args[:metadata]))
  end

  defp fetch_required!(args, key) do
    case args[key] || args[String.to_atom(key)] do
      nil -> raise ArgumentError, "missing campaign worker arg #{key}"
      value -> value
    end
  rescue
    ArgumentError -> args[key]
  end

  defp normalize_metadata(nil), do: %{}

  defp normalize_metadata(%{} = metadata) do
    Enum.into(metadata, %{}, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_metadata(_metadata), do: %{}

  defp maybe_mark_running(context) do
    case Eval.mark_campaign_target_running(context) do
      {:ok, _campaign} -> :ok
      {:error, reason} -> {:error, {:persistence_error, reason}}
    end
  end
end
