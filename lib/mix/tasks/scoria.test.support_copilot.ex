defmodule Mix.Tasks.Scoria.Test.SupportCopilot do
  use Mix.Task

  @shortdoc "Runs the advisory support-copilot gallery verification lane"

  @support_copilot_test_files [
    "test/scoria/support_journey_source_test.exs",
    "test/scoria/support_copilot_gallery_test.exs"
  ]

  def support_copilot_test_files, do: @support_copilot_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @support_copilot_test_files)
  end
end
