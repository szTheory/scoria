defmodule Scoria.HexConsumerContract do
  @moduledoc """
  Single source of truth for Hex consumer dependency shapes and tarball wiring.

  Exports adopter-facing Hex dep snippets, version policy, GitHub fallback tuples,
  and CI tarball path tuples. Non-runtime SSOT — tests and Mix tasks import these
  helpers; the running application does not depend on them.
  """

  @compile {:no_warn_undefined, [{:file, :lock, 2}, {:file, :unlock, 1}]}

  @app :scoria
  @hex_requirement "~> 0.1"
  @baseline_upgrade_version "0.1.0"
  @github_repo "szTheory/scoria"
  @cache_parent "tmp/scoria-hex-consumer"
  @stamp_file ".scoria-hex-consumer.stamp"
  @lock_file ".build.lock"

  @doc """
  Application atom for Scoria Hex package identity.
  """
  def app, do: @app

  @doc """
  Explicit Hex semver requirement policy (not auto-derived from patch).
  """
  def hex_requirement, do: @hex_requirement

  @doc """
  Published version from Application spec — mirrors mix.exs @version.
  """
  def published_version do
    Application.spec(:scoria, :vsn) |> to_string()
  end

  @doc """
  Baseline upgrade version hook for Phase 80 committed fixture (0.1.0).
  """
  def baseline_upgrade_version, do: @baseline_upgrade_version

  @doc """
  Adopter-facing Hex dep tuple for generated host mix.exs or README guards.
  """
  def hex_dep_tuple, do: {@app, @hex_requirement, hex: @app}

  @doc """
  Adopter-facing Hex dep snippet — byte-match README active dep line.
  """
  def hex_dep_snippet, do: "{:scoria, \"~> 0.1\", hex: :scoria}"

  @doc """
  GitHub fallback dep tuple for forks or pinned patches.
  """
  def github_fallback_tuple(version), do: {@app, github: @github_repo, tag: "v#{version}"}

  @doc """
  GitHub fallback dep snippet for README commented fallback line.
  """
  def github_fallback_snippet(version) do
    "{:scoria, github: \"#{@github_repo}\", tag: \"v#{version}\"}"
  end

  @doc """
  CI tarball dep tuple — path to hex.build --unpack directory (no :hex key).
  """
  def tarball_dep_tuple(unpack_root), do: {@app, path: unpack_root}

  @doc """
  CI tarball dep snippet for generated host mix.exs assertions.
  """
  def tarball_dep_snippet(unpack_root), do: "{:scoria, path: #{inspect(unpack_root)}}"

  @doc """
  Content hash of packaged file inventory plus published version (12-char hex suffix).
  """
  def package_fingerprint do
    version = published_version()
    package_files = Mix.Project.config()[:package][:files]

    hash_lines =
      package_files
      |> Enum.flat_map(&package_path_hash_lines/1)
      |> Enum.sort()

    payload = Enum.join([version | hash_lines], "\n")

    :crypto.hash(:sha256, payload)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 12)
  end

  @doc """
  Resolve or build the current unpack root for tarball consumer proof.

  Resolution order: `SCORIA_HEX_UNPACK_ROOT` env override, fingerprint cache hit,
  or exclusive-lock guarded `mix hex.build --unpack`.
  """
  def ensure_current_unpack_root! do
    case System.get_env("SCORIA_HEX_UNPACK_ROOT") do
      nil -> build_or_reuse_cache!()
      env_path -> env_override_root!(env_path)
    end
  end

  @doc """
  Discover the directory containing packaged `mix.exs` inside a hex.build --unpack output.
  """
  def unpack_root!(output_dir) do
    if File.regular?(Path.join(output_dir, "mix.exs")) do
      output_dir
    else
      output_dir
      |> File.ls!()
      |> Enum.map(&Path.join(output_dir, &1))
      |> Enum.find(&(File.dir?(&1) and File.regular?(Path.join(&1, "mix.exs")))) ||
        Mix.raise("could not find unpacked package root in #{output_dir}")
    end
  end

  defp env_override_root!(env_path) do
    expanded = Path.expand(env_path)
    unpack_root = unpack_root!(expanded)
    mix_exs = Path.join(unpack_root, "mix.exs")

    unless File.regular?(mix_exs) do
      Mix.raise("SCORIA_HEX_UNPACK_ROOT missing mix.exs at #{unpack_root}")
    end

    Path.expand(unpack_root)
  end

  defp build_or_reuse_cache! do
    version = published_version()
    fp = package_fingerprint()
    cache_dir = Path.join([@cache_parent, "#{version}-#{fp}"])

    if cache_hit?(cache_dir, fp) do
      Path.expand(unpack_root!(cache_dir))
    else
      build_with_lock!(cache_dir, fp)
    end
  end

  defp cache_hit?(cache_dir, fp) do
    stamp_path = Path.join(cache_dir, @stamp_file)

    File.dir?(cache_dir) and
      File.regular?(stamp_path) and
      File.read!(stamp_path) == fp and
      valid_unpack_root?(cache_dir)
  end

  defp valid_unpack_root?(dir) do
    case safe_unpack_root(dir) do
      {:ok, _} -> true
      :error -> false
    end
  end

  defp safe_unpack_root(dir) do
    {:ok, unpack_root!(dir)}
  rescue
    _ -> :error
  end

  defp build_with_lock!(cache_dir, fp) do
    File.mkdir_p!(@cache_parent)
    lock_path = Path.join(@cache_parent, @lock_file)

    {:ok, fd} = open_exclusive_lock!(lock_path)

    try do
      if function_exported?(:file, :lock, 2) do
        :ok = :file.lock(fd, :exclusive)
      end

      try do
        if cache_hit?(cache_dir, fp) do
          Path.expand(unpack_root!(cache_dir))
        else
          do_build!(cache_dir, fp)
        end
      after
        if function_exported?(:file, :unlock, 1), do: :file.unlock(fd)
      end
    after
      :file.close(fd)
      File.rm(lock_path)
    end
  end

  defp open_exclusive_lock!(lock_path, retries \\ 100) do
    case :file.open(String.to_charlist(lock_path), [:write, :exclusive, :raw]) do
      {:ok, fd} ->
        {:ok, fd}

      {:error, :eexist} when retries > 0 ->
        Process.sleep(200)
        open_exclusive_lock!(lock_path, retries - 1)

      other ->
        Mix.raise("could not acquire hex consumer build lock: #{inspect(other)}")
    end
  end

  defp do_build!(cache_dir, fp) do
    {output, status} =
      System.cmd("mix", ["hex.build", "--unpack", "--output", cache_dir],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("hex.build --unpack failed:\n#{output}")
    end

    File.write!(Path.join(cache_dir, @stamp_file), fp)
    Path.expand(unpack_root!(cache_dir))
  end

  defp package_path_hash_lines(relative_path) do
    unless File.exists?(relative_path) do
      Mix.raise("missing package file: #{relative_path}")
    end

    if File.regular?(relative_path) do
      [hash_line(relative_path, relative_path)]
    else
      relative_path
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&hash_line(&1, &1))
    end
  end

  defp hash_line(relative_path, absolute_path) do
    hash =
      absolute_path
      |> File.read!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    "#{relative_path}:#{hash}"
  end
end
