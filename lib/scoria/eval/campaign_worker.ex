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

  @required_keys ~w(campaign_id campaign_target_id eval_run_id tenant_id eval_spec_id provider model)

  @impl Oban.Worker
  def perform(%Job{}), do: {:error, :execution_not_implemented}

  def new_job(args, opts \\ []) do
    args
    |> normalize_args()
    |> new(opts)
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
end
