defmodule Scoria.TestSupport.HostAppProof.Runner do
  @moduledoc false

  alias Scoria.HexConsumerContract

  @route_overlay_test "host_route_smoke_test.exs"

  def deps_get!(host), do: run_mix!(host, :deps_get, ["deps.get"])
  def scoria_install!(host), do: run_mix!(host, :scoria_install, ["scoria.install"])
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

  defp run_mix!(host, step, args) do
    IO.puts("HOST STEP #{step}: mix #{Enum.join(args, " ")}")

    {output, status} =
      System.cmd("mix", args,
        cd: host.root,
        env: host_env(),
        stderr_to_stdout: true
      )

    if status != 0 do
      raise triage_message(host, step, args, output)
    end

    %{step: step, output: output}
  end

  defp triage_message(host, step, args, output) do
    unpack_root = Map.get(host, :unpack_root)
    hex_unpack_env = System.get_env("SCORIA_HEX_UNPACK_ROOT") || "(unset)"

    tarball_dep =
      if host.dep_mode == :hex_tarball and is_binary(unpack_root) do
        HexConsumerContract.tarball_dep_snippet(unpack_root)
      else
        "path dep mode (repo root)"
      end

    replay =
      if step == :overlay_smoke do
        overlay_paths = Enum.map(host.overlay_tests, &("test/" <> &1))

        "cd #{host.root} && MIX_ENV=test mix test #{Enum.join(overlay_paths, " ")} --trace"
      else
        "cd #{host.root} && MIX_ENV=test mix #{Enum.join(args, " ")}"
      end

    nested_failure =
      if step == :overlay_smoke do
        case extract_nested_failure_line(output) do
          nil -> ""
          line -> "#{line}\n\n"
        end
      else
        ""
      end

    """
    host proof step failed

    step: #{step}
    command: mix #{Enum.join(args, " ")}
    host.root: #{host.root}
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
