defmodule Mix.Tasks.Scoria.WarningRatchet.Test do
  use Mix.Task

  @shortdoc "Runs WARN-06 high-signal tests with optional --warnings-as-errors"

  @switches [warnings_as_errors: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    if Mix.env() != :test do
      Mix.raise("warning ratchet test requires MIX_ENV=test")
    end

    Scoria.WarningInventory.cleanup_transient_tmp!()

    paths = Scoria.WarningRatchet.high_signal_wae_paths()

    test_args =
      if Keyword.get(opts, :warnings_as_errors, false) do
        ["--warnings-as-errors" | paths]
      else
        paths
      end

    Mix.Task.run("loadpaths")
    Mix.Task.run("compile")

    for module <- [
          Scoria.TestSupport.HostInstallFixtures,
          Scoria.TestSupport.HostAppProof.Generator,
          Scoria.TestSupport.HostAppProof.Runner
        ] do
      Code.ensure_compiled!(module)
    end

    Mix.Task.reenable("test")
    Mix.Task.run("test", test_args)
  end
end
