defmodule Mix.Tasks.Scoria.WarningInventory.CheckBaseline do
  use Mix.Task

  @shortdoc "Fails when committed warning-inventory.baseline.json is missing or has open clusters"

  @moduledoc """
  Validates `.planning/warning-inventory.baseline.json` for CI-INV-01.

  The committed baseline must parse as JSON, include required metadata keys, and
  keep `clusters` empty so warning debt cannot regress without an intentional refresh.

  ## Examples

      mix scoria.warning_inventory.check_baseline
  """

  alias Scoria.WarningInventoryBaseline

  @switches [file: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    file = Keyword.get(opts, :file, ".planning/warning-inventory.baseline.json")
    WarningInventoryBaseline.check!(file: file)
    Mix.shell().info("==> Warning inventory baseline check passed")
  end
end
