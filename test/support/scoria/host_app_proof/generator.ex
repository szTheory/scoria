defmodule Scoria.TestSupport.HostAppProof.Generator do
  @moduledoc false

  @host_module "ScoriaHostProof"
  @route_smoke_test "test/host_route_smoke_test.exs"
  @runtime_smoke_test "test/host_runtime_smoke_test.exs"

  def create_host!(opts \\ []) do
    suffix = System.unique_integer([:positive]) |> Integer.to_string()
    app_name = "scoria_host_proof_#{suffix}"
    working_root = Path.join(System.tmp_dir!(), "scoria-host-proof-#{suffix}")
    host_root = Path.join(working_root, app_name)
    repo_root = repo_root()

    run!(
      File.cwd!(),
      [
        "phx.new",
        host_root,
        "--app",
        app_name,
        "--module",
        @host_module,
        "--database",
        "postgres",
        "--no-assets",
        "--no-dashboard",
        "--no-mailer",
        "--no-gettext",
        "--no-install",
        "--no-agents-md"
      ]
    )

    register_cleanup(opts, working_root)
    patch_mix_exs!(host_root, repo_root)
    patch_test_config!(host_root, app_name)
    copy_overlay!(host_root)

    %{
      app_name: app_name,
      db_name: "#{app_name}_test",
      root: host_root,
      repo_root: repo_root,
      route_smoke_test: @route_smoke_test,
      runtime_smoke_test: @runtime_smoke_test
    }
  end

  def copy_overlay!(host_root) do
    source_root = Path.join([repo_root(), "test", "support", "scoria", "host_app_proof", "overlay", "test"])
    destination_root = Path.join(host_root, "test")
    File.mkdir_p!(destination_root)

    for source <- Path.wildcard(Path.join(source_root, "*.exs")) do
      File.cp!(source, Path.join(destination_root, Path.basename(source)))
    end
  end

  defp patch_mix_exs!(host_root, repo_root) do
    mix_exs = Path.join(host_root, "mix.exs")
    content = File.read!(mix_exs)

    patched =
      Regex.replace(~r/(defp deps do\s*\n\s*\[)/, content, "\\1\n      {:scoria, path: #{inspect(repo_root)}},")

    File.write!(mix_exs, patched)
  end

  defp patch_test_config!(host_root, app_name) do
    test_config = Path.join([host_root, "config", "test.exs"])

    File.write!(
      test_config,
      File.read!(test_config) <>
        """

        config :#{app_name}, ScoriaHostProof.Repo,
          username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
          password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
          hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
          port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
          database: "#{app_name}_test#{System.get_env("MIX_TEST_PARTITION")}",
          pool: Ecto.Adapters.SQL.Sandbox,
          pool_size: 2

        config :scoria,
          ecto_repos: [Scoria.Repo]

        config :scoria, Scoria.Repo,
          username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
          password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
          hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
          port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
          database: "#{app_name}_test#{System.get_env("MIX_TEST_PARTITION")}",
          pool: Ecto.Adapters.SQL.Sandbox,
          pool_size: 2,
          show_sensitive_data_on_connection_error: true,
          types: Scoria.PostgrexTypes

        config :scoria, Oban,
          engine: Oban.Engines.Basic,
          repo: Scoria.Repo,
          queues: false,
          plugins: false,
          testing: :manual

        config :scoria, Scoria.Vault,
          json_library: Jason,
          ciphers: [
            default: {
              Cloak.Ciphers.AES.GCM,
              tag: "AES.GCM.V1",
              key: Base.decode64!("PwIcoX8/Jhn4gsgZeJueZnyaisQDuCtEvLneO+pDkSk=")
            }
          ]
        """
    )
  end

  defp register_cleanup(opts, path) do
    case Keyword.get(opts, :cleanup) do
      nil -> :ok
      register when is_function(register, 1) -> register.(fn -> File.rm_rf!(path) end)
    end
  end

  defp repo_root do
    File.cwd!()
  end

  defp run!(cwd, args) do
    {output, status} =
      System.cmd("mix", args,
        cd: cwd,
        stderr_to_stdout: true
      )

    if status != 0 do
      raise """
      host generation command failed: mix #{Enum.join(args, " ")}

      #{output}
      """
    end
  end
end
