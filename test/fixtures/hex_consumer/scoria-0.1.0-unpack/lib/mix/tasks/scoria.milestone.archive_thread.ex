defmodule Mix.Tasks.Scoria.Milestone.ArchiveThread do
  use Mix.Task

  @shortdoc "Archives a planning thread with v2.6 closeout resolution metadata"

  @threads_dir ".planning/threads"

  @archives %{
    "warning-ratchet-followup" => %{
      file: "2026-05-27-warning-ratchet-followup.md",
      status: "archived (superseded — shipped v2.6)",
      resolution: """
      ## Resolution

      Shipped v2.6 Warning Ratchet milestone (phases 66–69).

      - **Phases:** 66 Baseline Expiry And Inventory, 67 High-Signal Ratchet, 68 Full-Suite Warning Closure, 69 CI Trust And Milestone Closeout
      - **Requirements:** WARN-03, WARN-04, WARN-05, WARN-06, WARN-07, CI-03
      - **Evidence:** `mix scoria.test.ci_trust`, `.planning/milestones/v2.6-MILESTONE-AUDIT.md`

      **v2.7 follow-up (deferred):** Hex publish, README docs-truth, optional knowledge WAE in CI — see Phase 69 CONTEXT deferred section.
      """
    }
  }

  @impl Mix.Task
  def run([slug]) when is_binary(slug) do
    case Map.get(@archives, slug) do
      nil ->
        Mix.raise("unknown thread slug #{inspect(slug)}; known: #{Map.keys(@archives) |> Enum.join(", ")}")

      %{file: file, status: status, resolution: resolution} ->
        path = Path.join([@threads_dir, file])

        unless File.exists?(path) do
          Mix.raise("thread file not found: #{path}")
        end

        content = File.read!(path)

        updated =
          content
          |> replace_status(status)
          |> append_resolution_if_missing(resolution)

        File.write!(path, updated)
        Mix.shell().info("Archived thread #{slug} → #{path}")
    end
  end

  def run(_args) do
    Mix.raise("usage: mix scoria.milestone.archive_thread <slug>")
  end

  defp replace_status(content, status) do
    Regex.replace(~r/\*\*Status:\*\* .+/, content, "**Status:** #{status}", global: false)
  end

  defp append_resolution_if_missing(content, resolution) do
    if content =~ "## Resolution" do
      content
    else
      String.trim_trailing(content) <> "\n\n" <> resolution
    end
  end
end
