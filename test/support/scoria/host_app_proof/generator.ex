defmodule Scoria.TestSupport.HostAppProof.Generator do
  @moduledoc false

  alias Scoria.HexConsumerContract

  @host_module "ScoriaHostProof"
  @overlay_test_dir "priv/host_app_proof/overlay/test"

  def overlay_test_files do
    Path.wildcard(Path.join([repo_root(), @overlay_test_dir, "*.exs"]))
    |> Enum.map(&Path.basename/1)
    |> Enum.sort()
  end

  def create_host!(opts) do
    dep_mode = Keyword.fetch!(opts, :dep_mode)

    unless dep_mode in [:hex_tarball, :path] do
      raise ArgumentError,
            "dep_mode must be :hex_tarball or :path, got: #{inspect(dep_mode)}"
    end

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

    patch_mix_exs!(
      host_root,
      dep_mode: dep_mode,
      unpack_root: Keyword.get(opts, :unpack_root),
      repo_root: repo_root
    )

    patch_test_config!(host_root, app_name)
    copy_overlay!(host_root)
    patch_host_install_surfaces!(host_root)

    overlay_tests = overlay_test_files()

    %{
      app_name: app_name,
      db_name: "#{app_name}_test",
      root: host_root,
      repo_root: repo_root,
      overlay_tests: overlay_tests,
      working_root: working_root,
      dep_mode: dep_mode,
      unpack_root: Keyword.get(opts, :unpack_root)
    }
  end

  def bump_unpack_dep!(host, new_unpack_root) do
    mix_exs = Path.join(host.root, "mix.exs")
    content = File.read!(mix_exs)
    dep_line = HexConsumerContract.tarball_dep_snippet(new_unpack_root) <> ","

    patched =
      Regex.replace(
        ~r/\{:scoria,\s*path:\s*[^}]+\},/,
        content,
        dep_line
      )

    if patched == content do
      raise "could not find {:scoria, path: ...} dep line in #{mix_exs}"
    end

    File.write!(mix_exs, patched)
    Map.put(host, :unpack_root, new_unpack_root)
  end

  def copy_overlay!(host_root) do
    source_root = Path.join([repo_root(), "priv", "host_app_proof", "overlay", "test"])
    destination_root = Path.join(host_root, "test")
    File.mkdir_p!(destination_root)

    for source <- Path.wildcard(Path.join(source_root, "*.exs")) do
      File.cp!(source, Path.join(destination_root, Path.basename(source)))
    end
  end

  defp patch_mix_exs!(host_root, opts) do
    mix_exs = Path.join(host_root, "mix.exs")
    content = File.read!(mix_exs)

    dep_line =
      case Keyword.fetch!(opts, :dep_mode) do
        :path ->
          repo_root = Keyword.fetch!(opts, :repo_root)
          "{:scoria, path: #{inspect(repo_root)}},"

        :hex_tarball ->
          unpack_root = Keyword.fetch!(opts, :unpack_root)
          {:scoria, path: unpack_root} = Scoria.HexConsumerContract.tarball_dep_tuple(unpack_root)
          "{:scoria, path: #{inspect(unpack_root)}},"
      end

    patched =
      Regex.replace(~r/(defp deps do\s*\n\s*\[)/, content, "\\1\n      #{dep_line}")

    File.write!(mix_exs, patched)
  end

  defp patch_host_install_surfaces!(host_root) do
    host_root
    |> Path.join("lib/*_web/router.ex")
    |> Path.wildcard()
    |> List.first()
    |> case do
      nil -> :ok
      router_path -> patch_router_markers!(router_path)
    end

    runtime_path = Path.join(host_root, "config/runtime.exs")

    if File.exists?(runtime_path) do
      patch_runtime_markers!(runtime_path)
    end
  end

  defp patch_router_markers!(router_path) do
    content = File.read!(router_path)

    if String.contains?(content, "# scoria:router:start") do
      :ok
    else
      patched =
        Regex.replace(
          ~r/(use \w+Web, :router\n)/,
          content,
          "\\1\n  # scoria:router:start\n  # scoria:router:end\n"
        )

      if patched == content do
        raise "Could not seed router ownership markers in #{router_path}"
      end

      File.write!(router_path, patched)
    end
  end

  defp patch_runtime_markers!(runtime_path) do
    content = File.read!(runtime_path)

    if String.contains?(content, "# scoria:runtime:start") do
      :ok
    else
      File.write!(
        runtime_path,
        content <>
          """

          # scoria:runtime:start
          # scoria:runtime:end
          """
      )
    end
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
      nil ->
        :ok

      register when is_function(register, 1) ->
        if preserve_host?() do
          IO.warn("SCORIA_PRESERVE_HOST: preserved host at #{path}")
        else
          register.(fn -> File.rm_rf!(path) end)
        end
    end
  end

  defp preserve_host? do
    System.get_env("SCORIA_PRESERVE_HOST") in ~w(1 true yes)
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
