defmodule Mix.Tasks.Scoria.Test.Knowledge do
  use Mix.Task

  @shortdoc "Runs the canonical optional knowledge verification lane"

  def knowledge_test_files do
    (Path.wildcard("test/scoria/knowledge_test.exs") ++
       Path.wildcard("test/scoria/knowledge/**/*_test.exs"))
    |> Enum.sort()
  end

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("scoria.pgvector.bootstrap")
    Mix.Task.reenable("app.start")
    System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")

    Mix.Task.run("scoria.pgvector.bootstrap")

    Scoria.TestSupport.Migrations.migrate_core!()
    Scoria.TestSupport.Migrations.migrate_knowledge!()

    Mix.Task.reenable("test")
    Mix.Task.run("test", ["--only", "knowledge" | args])
  end
end

defmodule Mix.Tasks.Test.Knowledge do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the canonical optional knowledge verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Knowledge.run(args)
end
