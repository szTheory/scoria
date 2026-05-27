defmodule Scoria.PackageSurfaceTest do
  use ExUnit.Case, async: true

  @docs_extras [
    "README.md",
    "LICENSE",
    "docs/adoption_lanes.md",
    "docs/phoenix_runtime_example.md",
    "docs/bounded_handoffs.md",
    "docs/semantic_fast_path.md",
    "docs/operator_verification.md"
  ]
  @required_package_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "lib/scoria.ex",
    "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
    "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
    "docs/adoption_lanes.md",
    "docs/phoenix_runtime_example.md",
    "docs/bounded_handoffs.md",
    "docs/semantic_fast_path.md",
    "docs/operator_verification.md"
  ]

  test "project metadata describes one publish surface" do
    project = Mix.Project.config()

    assert project[:source_url] == "https://github.com/szTheory/scoria"
    assert project[:homepage_url] == project[:source_url]
    assert project[:docs][:main] == "readme"
    assert project[:docs][:source_ref] == "v#{project[:version]}"
    assert project[:docs][:extras] == @docs_extras
    assert project[:package][:links]["GitHub"] == project[:source_url]
    assert project[:package][:licenses] == ["MIT"]
  end

  test "docs extras stay explicit and ordered" do
    project = Mix.Project.config()

    assert project[:docs][:extras] == @docs_extras
  end

  test "README keeps the pre-publish tagged GitHub install story" do
    readme = File.read!("README.md")

    assert readme =~
             "Scoria now carries Hex-ready package metadata, but until the first Hex publish lands you should install from a tagged GitHub release:"

    assert readme =~ "{:scoria, github: \"szTheory/scoria\", tag: \"v0.1.0\"}"

    for guide <- tl(@docs_extras) do
      assert readme =~ guide
    end

    refute readme =~ "{:scoria, hex:"
  end

  test "hex preview includes the required release surface" do
    output_dir = Path.join(System.tmp_dir!(), "scoria-hex-preview-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(output_dir) end)

    {output, status} =
      System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert status == 0, output

    unpack_root =
      cond do
        File.regular?(Path.join(output_dir, "mix.exs")) -> output_dir
        true -> find_unpack_root!(output_dir)
      end

    for relative_path <- @required_package_paths do
      assert File.exists?(Path.join(unpack_root, relative_path)),
             "expected #{relative_path} to exist in unpacked artifact"
    end
  end

  defp find_unpack_root!(output_dir) do
    output_dir
    |> File.ls!()
    |> Enum.map(&Path.join(output_dir, &1))
    |> Enum.find(&(File.dir?(&1) and File.regular?(Path.join(&1, "mix.exs")))) ||
      raise "could not find unpacked package root inside #{output_dir}"
  end
end
