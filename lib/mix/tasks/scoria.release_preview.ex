defmodule Mix.Tasks.Scoria.ReleasePreview do
  use Mix.Task

  @shortdoc "Builds docs and verifies the bounded package release surface"
  @required_package_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "lib/scoria.ex",
    "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
    "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
    "docs/glossary.md",
    "docs/adoption_lanes.md",
    "docs/scoria_vs_external_llm_ops.md",
    "docs/phoenix_runtime_example.md",
    "docs/bounded_handoffs.md",
    "docs/semantic_fast_path.md",
    "docs/operator_verification.md",
    "docs/connector_adoption.md",
    "docs/support_copilot_gallery.md",
    "docs/MAINTAINERS.md"
  ]
  @release_preview_output_dir Path.join(["tmp", "scoria-release-preview"])

  def required_package_paths, do: @required_package_paths
  def release_preview_output_dir, do: @release_preview_output_dir

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("loadpaths")

    output_dir = release_preview_output_dir()
    File.rm_rf!(output_dir)

    Mix.shell().info("==> Building publish-facing docs")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs")

    Mix.shell().info("==> Building unpacked Hex preview")

    {output, status} =
      System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("hex preview failed:\n#{output}")
    end

    unpack_root = unpack_root!(output_dir)

    case missing_required_paths(unpack_root) do
      [] ->
        Mix.shell().info("==> Release preview passed")

      missing ->
        Mix.raise("""
        release preview is missing required package paths:
        #{Enum.map_join(missing, "\n", &"* #{&1}")}
        """)
    end
  end

  defp unpack_root!(output_dir) do
    if File.regular?(Path.join(output_dir, "mix.exs")) do
      output_dir
    else
      output_dir
      |> File.ls!()
      |> Enum.map(&Path.join(output_dir, &1))
      |> Enum.find(&(File.dir?(&1) and File.regular?(Path.join(&1, "mix.exs")))) ||
        Mix.raise("could not find unpacked package root in #{output_dir}")
    end
  end

  defp missing_required_paths(unpack_root) do
    Enum.reject(@required_package_paths, fn relative_path ->
      File.exists?(Path.join(unpack_root, relative_path))
    end)
  end
end
