defmodule Scoria.TestSupport.HostAppProof.Runner do
  @moduledoc false

  def deps_get!(host), do: run_mix!(host, :deps_get, ["deps.get"])
  def scoria_install!(host), do: run_mix!(host, :scoria_install, ["scoria.install"])
  def ecto_create!(host), do: run_mix!(host, :ecto_create, ["ecto.create"])
  def ecto_migrate!(host), do: run_mix!(host, :ecto_migrate, ["ecto.migrate"])

  def smoke_pair!(host) do
    result =
      run_mix!(host, :route_runtime_smoke, [
        "test",
        host.route_smoke_test,
        host.runtime_smoke_test,
        "--trace"
      ])

    [
      %{step: :route_smoke, output: result.output},
      %{step: :runtime_smoke, output: result.output}
    ]
  end

  def run_route_proof!(host) do
    run_steps(host, [
      &deps_get!/1,
      &scoria_install!/1,
      &ecto_create!/1,
      &ecto_migrate!/1,
      &smoke_pair!/1
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
      raise """
      host proof step failed: #{step}
      command: mix #{Enum.join(args, " ")}
      host: #{host.root}

      #{output}
      """
    end

    %{step: step, output: output}
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
