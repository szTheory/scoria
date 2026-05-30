defmodule Mix.Tasks.Scoria.Test.Connector do
  use Mix.Task

  alias Scoria.TestSupport.Migrations

  @shortdoc "Runs the remote connector adoption verification lane"

  @connector_test_files [
    "test/scoria/connectors/adoption_lane_test.exs",
    "test/scoria/connectors/schema_test.exs",
    "test/scoria/connectors/invocation_test.exs",
    "test/mix/tasks/test.connector_test.exs"
  ]

  def connector_test_files, do: @connector_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.run("app.start")
    Migrations.migrate_core!()
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @connector_test_files)
  end
end

defmodule Mix.Tasks.Test.Connector do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the remote connector adoption verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Connector.run(args)
end
