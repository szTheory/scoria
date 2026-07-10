defmodule Scoria.PackageSurfaceTest do
  use ExUnit.Case, async: true

  alias Scoria.HexConsumerContract

  @docs_extras [
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
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
  @required_package_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "CHANGELOG.md",
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

  test "project metadata describes one publish surface" do
    project = Mix.Project.config()

    assert project[:source_url] == "https://github.com/szTheory/scoria"
    assert project[:homepage_url] == "https://hexdocs.pm/scoria"
    assert project[:docs][:main] == "readme"
    assert project[:docs][:source_ref] == "v#{project[:version]}"
    assert project[:docs][:extras] == @docs_extras
    assert project[:package][:links]["GitHub"] == project[:source_url]
    assert project[:package][:licenses] == ["MIT"]
    assert project[:version] == HexConsumerContract.published_version()
  end

  test "docs extras stay explicit and ordered" do
    project = Mix.Project.config()

    assert project[:docs][:extras] == @docs_extras
  end

  test "Hex-primary install with optional GitHub fallback" do
    readme = File.read!("README.md")

    assert readme =~ HexConsumerContract.hex_dep_snippet()

    refute readme =~ "until the first Hex publish lands"

    active_dep_lines =
      readme
      |> String.split("\n")
      |> Enum.filter(fn line ->
        trimmed = String.trim_leading(line)
        String.starts_with?(trimmed, "{:scoria,") and not String.starts_with?(trimmed, "#")
      end)

    assert length(active_dep_lines) == 1
    assert String.trim(hd(active_dep_lines)) == HexConsumerContract.hex_dep_snippet()

    fallback_lines =
      readme
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&String.starts_with?(&1, "# Fork or pinned patch only: {:scoria,"))

    assert length(fallback_lines) == 1
    fallback_line = hd(fallback_lines)

    assert fallback_line =~ "Fork or pinned patch only:"
    assert fallback_line =~ ~r/github:\s+"szTheory\/scoria"/
    assert fallback_line =~ ~r/tag:\s+"v\d+\.\d+\.\d+"/

    for guide <- tl(@docs_extras) do
      assert readme =~ guide
    end
  end

  test "hex preview includes the required release surface" do
    unpack_root = HexConsumerContract.ensure_current_unpack_root!()

    for relative_path <- @required_package_paths do
      assert File.exists?(Path.join(unpack_root, relative_path)),
             "expected #{relative_path} to exist in unpacked artifact"
    end
  end
end
