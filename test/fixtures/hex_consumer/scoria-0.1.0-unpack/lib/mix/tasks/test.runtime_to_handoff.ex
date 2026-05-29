defmodule Mix.Tasks.Test.RuntimeToHandoff do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the bounded runtime-to-handoff verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.RuntimeToHandoff.run(args)
end
