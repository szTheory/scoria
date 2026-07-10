defmodule Scoria.MixProject do
  use Mix.Project

  @version "0.1.2"

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
  # `dev/` holds the dev-only host harness (DevEndpoint/DevRouter) that serves
  # the dashboard via `mix phx.server`. It is excluded from the Hex package
  # (see `package/0` files) so adopters never receive it.
  defp elixirc_paths(:dev), do: ["lib", "dev"]
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
      # Dev-only web server + live reload for the dev harness endpoint (dev/).
      # Scoria is a library — adopters bring their own server — so these are
      # never shipped to Hex (only: :dev). Bandit backs the DevEndpoint.
      {:bandit, "~> 1.5", only: :dev},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      "assets.build": ["scoria.assets.build"],
      "assets.deploy": ["scoria.assets.build"],
      # Dev harness convenience: create+migrate (core+knowledge order)+seed the
      # dev DB in one step. Used by the Docker entrypoint and fresh local setup.
      "dev.setup": ["scoria.dev.db", "run priv/repo/dev_seed.exs"],
      ci: ["scoria.ci"]
    ]
  end

  defp description do
    "Phoenix-native AI ops: LLM traces, evals, prompt versions, replay, tool governance, and MCP workflows. Ecto-backed, LiveView-included."
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
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
    ]
  end

  defp package do
    [
      name: "scoria",
      files: [
        "lib",
        # Explicit priv/ subdirectory inclusions — the bare priv glob was replaced
        # to prevent dev-only harness tooling from shipping to adopters (supply-chain
        # control, T-11-06 / D-01 / D-02).
        "priv/fixtures",
        "priv/host_app_proof",
        # priv/repo: migrations ship to adopters; dev_seed.exs is excluded by
        # listing only the migration subdirs (not the whole dir).
        # Open question #2 resolution: dev_seed.exs is a maintainer dev tool, not
        # a runtime artifact — adopters do not need it in the package.
        "priv/repo/migrations",
        "priv/repo/knowledge_migrations",
        "priv/static",
        # priv/dev intentionally excluded — shots.mjs (screenshots) and e2e/ (the
        # Playwright assertion lane) are dev-only harness tooling, not for adopters
        # (D-01: zero Hex footprint for browser automation tooling). Do NOT add a
        # priv/dev entry here — it would ship Playwright specs + node tooling.
        # priv/shots intentionally excluded — screenshot captures are transient
        # dev-only artifacts; only gap_register.md is committed (per .gitignore rules).
        "mix.exs",
        ".formatter.exs",
        "CHANGELOG.md",
        "README.md",
        "LICENSE",
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
