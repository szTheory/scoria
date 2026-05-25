defmodule Mix.Tasks.Test.SemanticFastPath do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria semantic fast-path verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.SemanticFastPath.run(args)
end
