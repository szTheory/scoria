defmodule Mix.Tasks.Scoria.ReleasePreview do
  use Mix.Task

  @shortdoc "Builds docs and verifies the bounded package release surface"
  @required_package_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "CHANGELOG.md",
    "lib/scoria.ex",
    "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
    "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
    "llms.txt",
    "AGENTS.md",
    "guides/getting-started.md",
    "guides/golden-path.md",
    "guides/jtbd-and-user-flows.md",
    "guides/ownership-boundary.md",
    "guides/capabilities/default-runtime.md",
    "guides/capabilities/bounded-handoffs.md",
    "guides/capabilities/semantic-cache.md",
    "guides/capabilities/connectors-and-mcp.md",
    "guides/capabilities/support-copilot-gallery.md",
    "guides/reviewer-verification.md",
    "guides/troubleshooting.md",
    "guides/scoria-vs-external-llm-ops.md",
    "guides/cheatsheet.cheatmd",
    "guides/reference/glossary.md",
    "guides/maintainers.md",
    "docs/glossary.md",
    "docs/adoption_lanes.md",
    "docs/scoria_vs_external_llm_ops.md",
    "docs/phoenix_runtime_example.md",
    "docs/bounded_handoffs.md",
    "docs/semantic_fast_path.md",
    "docs/operator_verification.md",
    "docs/connector_adoption.md",
    "docs/support_copilot_gallery.md",
    "docs/MAINTAINERS.md",
    "brandbook/logo-primary.svg",
    "brandbook/logo-primary-light.svg",
    "brandbook/logo-mark.svg",
    "brandbook/favicon.svg"
  ]
  @release_preview_output_dir Path.join(["tmp", "scoria-release-preview"])
  @generated_docs_output_dir "doc"

  def required_package_paths, do: @required_package_paths
  def release_preview_output_dir, do: @release_preview_output_dir
  def generated_docs_output_dir, do: @generated_docs_output_dir
  def docs_task_args, do: ["--warnings-as-errors"]

  def clean_generated_docs_output!(output_dir \\ generated_docs_output_dir()) do
    File.rm_rf!(output_dir)
    :ok
  end

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("loadpaths")

    output_dir = release_preview_output_dir()
    File.rm_rf!(output_dir)

    Mix.shell().info("==> Building publish-facing docs")
    clean_generated_docs_output!()
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", docs_task_args())

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
