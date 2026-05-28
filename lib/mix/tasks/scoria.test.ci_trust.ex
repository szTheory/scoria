defmodule Mix.Tasks.Scoria.Test.CiTrust do
  use Mix.Task

  @shortdoc "Runs Phase 69 CI trust contract bundle (policy + optional ratchet hygiene)"

  @switches [fast: :boolean]

  @fast_files [
    "test/scoria/ci_policy_contract_test.exs",
    "test/scoria/verification_lanes_test.exs"
  ]

  @full_files @fast_files ++ ["test/scoria/warning_inventory/tmp_preflight_test.exs"]

  def ci_trust_test_files(mode \\ :full) do
    case mode do
      :fast -> @fast_files
      :full -> @full_files
    end
  end

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    files =
      if Keyword.get(opts, :fast, false) do
        @fast_files
      else
        @full_files
      end

    Mix.Task.run("loadpaths")

    for file <- files do
      Mix.Task.reenable("test")
      Mix.Task.run("test", [file])
    end
  end
end

defmodule Mix.Tasks.Test.CiTrust do
  use Mix.Task

  @shortdoc "Compatibility wrapper for CI trust contract verification"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.CiTrust.run(args)
end
