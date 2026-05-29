defmodule Mix.Tasks.Scoria.WarningRatchet.Check do
  use Mix.Task

  @shortdoc "Fails when high-signal paths contain unclassified compile warnings"

  alias Scoria.WarningInventory
  alias Scoria.WarningRatchet

  @impl Mix.Task
  def run(_args) do
    if Mix.env() != :test do
      Mix.raise("warning ratchet check requires MIX_ENV=test")
    end

    WarningInventory.ensure_clean_tmp!()

    try do
      output = WarningInventory.capture_output()

      offenders =
        output
        |> WarningInventory.parse_output()
        |> WarningInventory.classify()
        |> Enum.filter(fn row ->
          row.cluster_id == :unclassified_compile and WarningRatchet.high_signal_path?(row.file)
        end)

      if offenders == [] do
        Mix.shell().info("==> WARN-06 high-signal unclassified check passed")
        exit({:shutdown, 0})
      end

      lines =
        for row <- Enum.sort_by(offenders, &{&1.file, &1.line}) do
          "- #{row.file}:#{row.line} #{row.message}"
        end

      Mix.raise("""
      WARN-06 high-signal paths contain unclassified compile warnings:

      #{Enum.join(lines, "\n")}

      Remediation:
      - add a Cluster.match/1 rule or fix the code in the same change
      - do not baseline unclassified warnings in high-signal scope
      """)
    after
      WarningInventory.cleanup_transient_tmp!()
    end
  end
end
