defmodule Mix.Tasks.Test.Knowledge do
  use Mix.Task

  @shortdoc "Runs the explicit knowledge/full verification lane"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("app.start")
    System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")

    Mix.Tasks.Scoria.Pgvector.Bootstrap.configure_runtime_env()
    Mix.Task.run("app.start")
    Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()

    Scoria.TestSupport.Migrations.migrate_core!()
    Scoria.TestSupport.Migrations.migrate_knowledge!()

    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end
end
