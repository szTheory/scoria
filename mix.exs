defmodule Scoria.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :scoria,
      version: @version,
      description: description(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/szTheory/scoria",
      homepage_url: "https://hexdocs.pm/scoria",
      test_load_filters: [
        fn path ->
          String.ends_with?(path, "_test.exs") and not excluded_test_path?(path)
        end
      ],
      test_ignore_filters: [&excluded_test_path?/1]
    ]
  end

  def cli do
    [
      preferred_envs: [
        "scoria.test.adoption": :test,
        "test.adoption": :test,
        "scoria.test.runtime_to_handoff": :test,
        "test.runtime_to_handoff": :test,
        "scoria.test.semantic_fast_path": :test,
        "test.semantic_fast_path": :test,
        "scoria.test.knowledge": :test,
        "test.knowledge": :test,
        "scoria.warning_inventory": :test,
        "scoria.warning_inventory.check_baseline": :test,
        "scoria.test.ci_trust": :test,
        "test.ci_trust": :test,
        "scoria.test.install_contract": :test,
        "test.install_contract": :test,
        "scoria.test.support_copilot": :test,
        "test.support_copilot": :test,
        "scoria.test.connector": :test,
        "test.connector": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Host-app overlay templates and hex unpack fixtures must not compile in the root suite.
  defp excluded_test_path?(path) do
    String.starts_with?(path, "test/fixtures/") or
      String.contains?(path, "host_app_proof/overlay/test/")
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Scoria.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tribunal, "~> 1.3"},
      {:cloak, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:ecto_sql, "~> 3.10"},
      {:oban, "~> 2.19"},
      {:postgrex, ">= 0.0.0"},
      {:pgvector, "~> 0.3.0"},
      {:hammer, "~> 7.3"},
      {:fuse, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_ecto, "~> 4.4"},
      {:req, "~> 0.5"},
      {:req_llm, "~> 1.13"},
      {:tiktoken, "~> 0.4.2"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      "assets.build": ["scoria.assets.build"],
      "assets.deploy": ["scoria.assets.build"]
    ]
  end

  defp description do
    "Phoenix-native AI runtime and operator surface for durable runs, approvals, replay, evaluation, and bounded semantic reuse."
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "docs/adoption_lanes.md",
        "docs/phoenix_runtime_example.md",
        "docs/bounded_handoffs.md",
        "docs/semantic_fast_path.md",
        "docs/operator_verification.md",
        "docs/connector_adoption.md",
        "docs/support_copilot_gallery.md",
        "docs/MAINTAINERS.md"
      ]
    ]
  end

  defp package do
    [
      name: "scoria",
      files: [
        "lib",
        "priv",
        "mix.exs",
        ".formatter.exs",
        "CHANGELOG.md",
        "README.md",
        "LICENSE",
        "docs/adoption_lanes.md",
        "docs/phoenix_runtime_example.md",
        "docs/bounded_handoffs.md",
        "docs/semantic_fast_path.md",
        "docs/operator_verification.md",
        "docs/connector_adoption.md",
        "docs/support_copilot_gallery.md",
        "docs/MAINTAINERS.md"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/szTheory/scoria",
        "Documentation" => "https://hexdocs.pm/scoria",
        "Changelog" => "https://hex.pm/packages/scoria/changelog"
      },
      tags: ~w(elixir phoenix ai llm mcp observability liveview workflows approvals)
    ]
  end
end
