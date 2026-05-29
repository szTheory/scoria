defmodule SupportCopilot.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :support_copilot,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {SupportCopilot.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:scoria, path: "../.."},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:plug_cowboy, "~> 2.7"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.4"},
      {:floki, ">= 0.30.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "scoria.install", "ecto.setup"],
      "ecto.setup": [
        "ecto.create -r Scoria.Repo",
        "ecto.migrate -r Scoria.Repo --to 20260511000300",
        "eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'",
        "ecto.migrate -r Scoria.Repo --to 20260517000200",
        "scoria.pgvector.bootstrap",
        "ecto.migrate -r Scoria.Repo",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop -r Scoria.Repo", "ecto.setup"],
      test: [
        "ecto.create -r Scoria.Repo --quiet",
        "ecto.migrate -r Scoria.Repo --to 20260511000300 --quiet",
        "eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'",
        "ecto.migrate -r Scoria.Repo --to 20260517000200 --quiet",
        "scoria.pgvector.bootstrap",
        "ecto.migrate -r Scoria.Repo --quiet",
        "test --no-start"
      ]
    ]
  end
end
