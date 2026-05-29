defmodule Mix.Tasks.Scoria.Eval do
  @shortdoc "Runs LLM-as-judge evaluations for a dataset"
  @moduledoc """
  Runs LLM-as-judge evaluations over dataset items.

  ## Options
    * `--dataset` - The UUID of the dataset to evaluate

  ## Example
      mix scoria.eval --dataset 00000000-0000-0000-0000-000000000000
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Start the application so we can use Repo
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, switches: [dataset: :string])

    dataset_id = Keyword.get(opts, :dataset)

    if is_nil(dataset_id) do
      Mix.raise("Missing --dataset option")
    end

    IO.puts("Starting evaluation for dataset #{dataset_id}")
    # TODO: Fetch dataset using Scoria.Eval and iterate over items using Tribunal
  end
end
