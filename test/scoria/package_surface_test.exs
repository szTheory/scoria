defmodule Scoria.PackageSurfaceTest do
  use ExUnit.Case, async: true

  alias Scoria.AiDocContract
  alias Scoria.HexConsumerContract

  @packaged_ai_docs AiDocContract.packaged_ai_doc_paths()
  @repo_only_ai_docs AiDocContract.repo_only_ai_doc_paths()
  @canonical_guides [
    "guides/getting-started.md",
    "guides/golden-path.md",
    "guides/jtbd-and-user-flows.md",
    "guides/ownership-boundary.md",
    "guides/capabilities/default-runtime.md",
    "guides/capabilities/bounded-handoffs.md",
    "guides/capabilities/semantic-cache.md",
    "guides/capabilities/connectors-and-mcp.md",
    "guides/capabilities/support-copilot-gallery.md",
    "guides/capabilities/llm-and-tool-adapters.md",
    "guides/reviewer-verification.md",
    "guides/troubleshooting.md",
    "guides/scoria-vs-external-llm-ops.md",
    "guides/cheatsheet.cheatmd",
    "guides/reference/glossary.md",
    "guides/maintainers.md"
  ]
  @compatibility_stub_paths [
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
  @docs_brand_assets [
    "brandbook/logo-primary.svg",
    "brandbook/logo-primary-light.svg",
    "brandbook/logo-mark.svg",
    "brandbook/favicon.svg"
  ]
  @dev_only_docs [
    "docs/design_system.md",
    "docs/docker_dev_dx.md",
    "docs/uat_automation.md"
  ]
  @docs_support_extras ["README.md", "CHANGELOG.md", "LICENSE"]
  @docs_extras @docs_support_extras ++ @canonical_guides
  @base_required_package_paths [
    "README.md",
    "LICENSE",
    "mix.exs",
    "CHANGELOG.md",
    "lib/scoria.ex",
    "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
    "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs"
  ]
  @required_package_paths Enum.concat([
                            @base_required_package_paths,
                            @packaged_ai_docs,
                            @canonical_guides,
                            @compatibility_stub_paths,
                            @docs_brand_assets
                          ])
  @redirects %{
    "adoption_lanes" => "jtbd-and-user-flows",
    "phoenix_runtime_example" => "golden-path",
    "bounded_handoffs" => "bounded-handoffs",
    "semantic_fast_path" => "semantic-cache",
    "operator_verification" => "reviewer-verification",
    "connector_adoption" => "connectors-and-mcp",
    "support_copilot_gallery" => "support-copilot-gallery",
    "scoria_vs_external_llm_ops" => "scoria-vs-external-llm-ops",
    "MAINTAINERS" => "maintainers"
  }

  test "project metadata describes one publish surface" do
    project = Mix.Project.config()
    docs = project[:docs]

    assert project[:source_url] == "https://github.com/szTheory/scoria"
    assert project[:homepage_url] == "https://scoria.hexdocs.pm"
    assert docs[:main] == "getting-started"
    assert docs[:source_url] == "https://github.com/szTheory/scoria"
    assert docs[:source_ref] == "main"
    assert docs[:extra_section] == "Guides"
    assert docs[:formatters] == ["html", "markdown"]
    assert docs[:logo] == "brandbook/logo-mark.svg"
    assert docs[:favicon] == "brandbook/favicon.svg"
    assert project[:package][:links]["Documentation"] == project[:homepage_url]
    assert project[:package][:links]["GitHub"] == project[:source_url]
    assert project[:package][:licenses] == ["MIT"]
    assert project[:version] == HexConsumerContract.published_version()
  end

  test "docs extras expose canonical guide ladder without legacy stubs" do
    docs = Mix.Project.config()[:docs]

    for path <- @docs_extras do
      assert path in docs[:extras], "expected #{path} in ExDoc extras"
    end

    for path <- @compatibility_stub_paths ++ @dev_only_docs do
      refute path in docs[:extras], "expected #{path} to stay out of ExDoc extras"
    end
  end

  test "docs extras are grouped by adopter job" do
    groups = Mix.Project.config()[:docs][:groups_for_extras]

    assert_group_contains(groups, "Start Here", [
      "README.md",
      "guides/getting-started.md",
      "guides/golden-path.md",
      "guides/jtbd-and-user-flows.md",
      "guides/ownership-boundary.md",
      "guides/cheatsheet.cheatmd"
    ])

    assert_group_contains(groups, "Capabilities", [
      "guides/capabilities/default-runtime.md",
      "guides/capabilities/bounded-handoffs.md",
      "guides/capabilities/semantic-cache.md",
      "guides/capabilities/connectors-and-mcp.md",
      "guides/capabilities/support-copilot-gallery.md",
      "guides/capabilities/llm-and-tool-adapters.md"
    ])

    assert_group_contains(groups, "Operate & Verify", [
      "guides/reviewer-verification.md",
      "guides/troubleshooting.md"
    ])

    assert_group_contains(groups, "Compare & Decide", [
      "guides/scoria-vs-external-llm-ops.md"
    ])

    assert_group_contains(groups, "Reference", [
      "guides/reference/glossary.md"
    ])

    assert_group_contains(groups, "Maintainers", [
      "guides/maintainers.md",
      "CHANGELOG.md",
      "LICENSE"
    ])
  end

  test "public modules are grouped around the adopter journey" do
    groups = Mix.Project.config()[:docs][:groups_for_modules]

    assert_module_group_contains(groups, "Start Here", Scoria)
    assert_module_group_contains(groups, "Start Here", Scoria.Identity)
    assert_module_group_contains(groups, "Install & Verify", ScoriaWeb.Router)
    assert_module_group_contains(groups, "Install & Verify", Scoria.VerificationSuites)
    assert_module_group_contains(groups, "Runtime & Workflows", Scoria.Runtime.RunSummary)
    assert_module_group_contains(groups, "Runtime & Workflows", Scoria.Runtime.RunDetail)
    assert_module_group_contains(groups, "Reviewer Dashboard", ScoriaWeb.DashboardScope)
    assert_module_group_contains(groups, "Knowledge & Semantic Cache", Scoria.SemanticCache)
    assert_module_group_contains(groups, "Connectors & MCP", Scoria.Connectors)
  end

  test "docs warning cleanup skips command literals without adding private contract modules" do
    docs = Mix.Project.config()[:docs]
    skip_code_autolink_to = docs[:skip_code_autolink_to]

    assert is_function(skip_code_autolink_to, 1)
    assert skip_code_autolink_to.("mix test.adoption")
    assert skip_code_autolink_to.("mix scoria.release_preview")
    assert skip_code_autolink_to.("MIX_ENV=dev mix docs --warnings-as-errors")
    assert skip_code_autolink_to.("Scoria.AdopterDocContract.comparison_guide_path/0")
    assert skip_code_autolink_to.("Scoria.SupportJourney")
    refute skip_code_autolink_to.("Scoria")

    public_modules =
      docs[:groups_for_modules]
      |> Keyword.values()
      |> List.flatten()

    refute Scoria.AiDocContract in public_modules
    refute Scoria.AdopterDocContract in public_modules
    refute Scoria.HexConsumerContract in public_modules
    refute Scoria.SupportJourney in public_modules
  end

  test "docs redirects preserve old generated HexDocs page ids" do
    redirects = Mix.Project.config()[:docs][:redirects]

    assert is_map(redirects), "expected ExDoc redirects to be configured"
    assert redirects == @redirects
  end

  test "package files include guides, compatibility stubs, and docs brand assets" do
    package_files = Mix.Project.config()[:package][:files]

    for path <- @packaged_ai_docs ++ @canonical_guides ++ @compatibility_stub_paths ++ @docs_brand_assets do
      assert path in package_files, "expected #{path} in package files"
    end

    for path <- @repo_only_ai_docs ++ @dev_only_docs do
      refute path in package_files, "expected repo/dev-only doc #{path} to stay out of package files"
    end
  end

  test "package files intentionally ship shared AI docs but exclude the Gemini bridge" do
    package_files = Mix.Project.config()[:package][:files]

    assert AiDocContract.root_llms_path() in package_files
    assert AiDocContract.root_agents_path() in package_files
    refute AiDocContract.gemini_bridge_path() in package_files
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
  end

  test "hex preview includes the required release surface" do
    unpack_root = HexConsumerContract.ensure_current_unpack_root!()

    for relative_path <- @required_package_paths do
      assert File.exists?(Path.join(unpack_root, relative_path)),
             "expected #{relative_path} to exist in unpacked artifact"
    end
  end

  defp assert_group_contains(groups, label, expected_paths) do
    assert is_list(groups), "expected #{label} group in groups_for_extras"

    paths = paths_for_label(groups, label)
    assert is_list(paths), "expected #{label} group in groups_for_extras"

    for path <- expected_paths do
      assert path in paths, "expected #{label} group to include #{path}"
    end
  end

  defp assert_module_group_contains(groups, label, module) do
    assert is_list(groups), "expected #{label} group in groups_for_modules"

    modules = paths_for_label(groups, label)
    assert is_list(modules), "expected #{label} group in groups_for_modules"
    assert module in modules, "expected #{label} group to include #{inspect(module)}"
  end

  defp paths_for_label(groups, label) do
    groups
    |> Enum.find_value(fn
      {group_label, paths} when is_list(paths) ->
        if to_string(group_label) == label, do: paths

      _other ->
        nil
    end)
  end
end
