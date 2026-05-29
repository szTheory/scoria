defmodule Scoria.TestSupport.HostAppProof.Runner do
  @moduledoc false

  alias Scoria.HexConsumerContract

  @route_overlay_test "host_route_smoke_test.exs"
  @snapshot_root "tmp/scoria-host-proof-last-failure"
  @snapshot_exclude_dirs ~w(_build deps node_modules .git)

  def deps_get!(host), do: run_mix!(host, :deps_get, ["deps.get"])
  def scoria_install!(host), do: run_mix!(host, :scoria_install, ["scoria.install"])

  def scoria_install_check!(host, opts \\ []) do
    run_mix!(host, :scoria_install_check, ["scoria.install", "--check"], opts)
  end

  def scoria_install_check_pre_apply!(host) do
    scoria_install_check!(host,
      expect_exit: 1,
      expect_trailer: "SCORIA_CHECK_RESULT status=drift exit_code=1"
    )
  end

  def scoria_install_dry_run!(host) do
    run_mix!(host, :scoria_install_dry_run, ["scoria.install", "--dry-run"], expect_exit: 0)
  end

  def ecto_create!(host), do: run_mix!(host, :ecto_create, ["ecto.create"])
  def ecto_migrate!(host), do: run_mix!(host, :ecto_migrate, ["ecto.migrate"])

  def smoke_pair!(host), do: smoke_pair!(host, host.overlay_tests)

  def smoke_pair!(host, overlay_files) do
    test_args = ["test"] ++ Enum.map(overlay_files, &("test/" <> &1)) ++ ["--trace"]

    result = run_mix!(host, :overlay_smoke, test_args)

    overlay_files
    |> Enum.map(fn file ->
      step = file |> Path.rootname() |> String.to_atom()
      %{step: step, output: result.output}
    end)
  end

  def run_route_proof!(host) do
    run_steps(host, [
      &deps_get!/1,
      &scoria_install!/1,
      &ecto_create!/1,
      &ecto_migrate!/1,
      fn h -> smoke_pair!(h, [@route_overlay_test]) end
    ])
  end

  def run_full_proof!(host) do
    run_steps(host, [
      &deps_get!/1,
      &scoria_install!/1,
      &ecto_create!/1,
      &ecto_migrate!/1,
      &smoke_pair!/1
    ])
  end

  def expected_steps(host) do
    install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]

    overlay =
      host.overlay_tests
      |> Enum.map(fn file -> file |> Path.rootname() |> String.to_atom() end)

    install ++ overlay
  end

  defp run_steps(host, steps) do
    results =
      steps
      |> Enum.flat_map(fn step -> step.(host) |> List.wrap() end)

    %{results: results, steps: Enum.map(results, & &1.step)}
  end

  defp run_mix!(host, step, args, opts \\ []) do
    expect_exit = Keyword.get(opts, :expect_exit, 0)
    expect_trailer = Keyword.get(opts, :expect_trailer)

    IO.puts("HOST STEP #{step}: mix #{Enum.join(args, " ")}")

    {output, status} =
      System.cmd("mix", args,
        cd: host.root,
        env: host_env(),
        stderr_to_stdout: true
      )

    failure_reason =
      cond do
        status != expect_exit ->
          "expected exit #{expect_exit}, got #{status}"

        is_binary(expect_trailer) and not String.contains?(output, expect_trailer) ->
          "expected output to contain #{inspect(expect_trailer)}"

        true ->
          nil
      end

    if failure_reason do
      maybe_snapshot_failure!(host, step, args)
      raise triage_message(host, step, args, output, failure_reason)
    end

    %{step: step, output: output}
  end

  defp triage_message(host, step, args, output, failure_reason) do
    unpack_root = Map.get(host, :unpack_root)
    hex_unpack_env = System.get_env("SCORIA_HEX_UNPACK_ROOT") || "(unset)"

    tarball_dep =
      if host.dep_mode == :hex_tarball and is_binary(unpack_root) do
        HexConsumerContract.tarball_dep_snippet(unpack_root)
      else
        "path dep mode (repo root)"
      end

    replay = replay_command(host, step, args)

    nested_failure =
      if step == :overlay_smoke do
        case extract_nested_failure_line(output) do
          nil -> ""
          line -> "#{line}\n\n"
        end
      else
        ""
      end

    failure_line =
      if failure_reason do
        "failure_reason: #{failure_reason}\n"
      else
        ""
      end

    """
    host proof step failed

    step: #{step}
    command: mix #{Enum.join(args, " ")}
    #{failure_line}host.root: #{host.root}
    host.app_name: #{host.app_name}
    host.db_name: #{host.db_name}
    unpack_root: #{inspect(unpack_root)}
    SCORIA_HEX_UNPACK_ROOT: #{hex_unpack_env}
    tarball_dep: #{tarball_dep}
    overlay_tests: #{inspect(host.overlay_tests)}
    SCORIA_DB_HOST: #{System.get_env("SCORIA_DB_HOST", "localhost")}
    SCORIA_DB_PORT: #{System.get_env("SCORIA_DB_PORT", "5432")}
    SCORIA_DB_USERNAME: #{System.get_env("SCORIA_DB_USERNAME", "postgres")}
    replay: #{replay}
    preserve: SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test --only host_proof --trace

    #{nested_failure}#{output}
    """
  end

  defp extract_nested_failure_line(output) do
    output
    |> String.split("\n", trim: false)
    |> Enum.find(fn line ->
      (Regex.match?(~r/^\s*\d+\) test/, line) and String.contains?(line, "FAIL")) or
        String.contains?(line, "** (")
    end)
  end

  defp replay_command(host, step, args) do
    if step == :overlay_smoke do
      overlay_paths = Enum.map(host.overlay_tests, &("test/" <> &1))

      "cd #{host.root} && MIX_ENV=test mix test #{Enum.join(overlay_paths, " ")} --trace"
    else
      "cd #{host.root} && MIX_ENV=test mix #{Enum.join(args, " ")}"
    end
  end

  defp maybe_snapshot_failure!(host, step, args) do
    destination = System.get_env("SCORIA_HOST_PROOF_ROOT") || @snapshot_root
    File.rm_rf!(destination)
    File.mkdir_p!(destination)

    copy_note =
      if is_binary(host.root) and File.dir?(host.root) do
        host_dest = Path.join(destination, "host")

        try do
          copy_host_root_for_snapshot!(host.root, host_dest)
          nil
        rescue
          error -> "host root copy failed: #{Exception.message(error)}"
        end
      else
        "host.root missing or not a directory — host copy skipped"
      end

    manifest = manifest_content(host, step, args, copy_note)
    File.write!(Path.join(destination, "MANIFEST.txt"), manifest)
  end

  defp copy_host_root_for_snapshot!(source, dest) do
    File.mkdir_p!(dest)

    for entry <- snapshot_entries(source) do
      rel = Path.relative_to(entry, source)

      unless snapshot_excluded?(rel) do
        copy_snapshot_entry!(source, dest, entry)
      end
    end
  end

  defp copy_snapshot_entry!(source_root, dest_root, entry) do
    rel = Path.relative_to(entry, source_root)
    dest = Path.join(dest_root, rel)

    case File.lstat(entry) do
      {:ok, %File.Stat{type: :regular}} ->
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(entry, dest)

      {:ok, %File.Stat{type: :directory}} ->
        File.mkdir_p!(dest)

        for child <- snapshot_entries(entry) do
          child_rel = Path.relative_to(child, source_root)

          unless snapshot_excluded?(child_rel) do
            copy_snapshot_entry!(source_root, dest_root, child)
          end
        end

      _ ->
        :ok
    end
  end

  defp snapshot_entries(dir) do
    Path.wildcard(Path.join(dir, "*")) ++ Path.wildcard(Path.join(dir, ".[^.]*"))
  end

  defp snapshot_excluded?(rel_path) do
    rel_path
    |> Path.split()
    |> Enum.any?(&(&1 in @snapshot_exclude_dirs))
  end

  defp manifest_content(host, step, args, copy_note) do
    unpack_root = Map.get(host, :unpack_root)
    hex_unpack_env = System.get_env("SCORIA_HEX_UNPACK_ROOT") || "(unset)"
    replay_full = replay_command(host, step, args)

    tarball_dep_line =
      if host.dep_mode == :hex_tarball and is_binary(unpack_root) do
        "tarball_dep: #{HexConsumerContract.tarball_dep_snippet(unpack_root)}\n"
      else
        ""
      end

    copy_note_line =
      if copy_note do
        "copy_note: #{copy_note}\n"
      else
        ""
      end

    """
    timestamp: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    failed_step: #{step}
    host_root: #{host.root}
    app_name: #{host.app_name}
    db_name: #{host.db_name}
    unpack_root: #{inspect(unpack_root)}
    scoria_version: #{HexConsumerContract.published_version()}
    package_fingerprint: #{HexConsumerContract.package_fingerprint()}
    SCORIA_HEX_UNPACK_ROOT: #{hex_unpack_env}
    replay_full: #{replay_full}
    replay_preserve: SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test --only host_proof
    #{tarball_dep_line}#{copy_note_line}
    """
  end

  defp host_env do
    [
      {"MIX_ENV", "test"},
      {"SCORIA_DB_HOST", System.get_env("SCORIA_DB_HOST", "localhost")},
      {"SCORIA_DB_PORT", System.get_env("SCORIA_DB_PORT", "5432")},
      {"SCORIA_DB_USERNAME", System.get_env("SCORIA_DB_USERNAME", "postgres")},
      {"SCORIA_DB_PASSWORD", System.get_env("SCORIA_DB_PASSWORD", "postgres")}
    ]
  end
end
