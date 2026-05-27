defmodule Mix.Tasks.Scoria.WarningInventory do
  use Mix.Task

  @shortdoc "Captures and classifies full-suite warning inventory for maintainers"

  alias Scoria.WarningInventory

  @switches [
    format: :string,
    write: :boolean,
    since: :string,
    scope: :string,
    include_runtime: :boolean,
    quiet: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    preflight!()

    format = Keyword.get(opts, :format, "table")
    scope = Keyword.get(opts, :scope, "full")
    quiet? = Keyword.get(opts, :quiet, false)
    since = validate_since!(Keyword.get(opts, :since))
    include_runtime? = Keyword.get(opts, :include_runtime, false)

    output =
      if quiet? do
        ""
      else
        capture_output()
      end

    parsed = WarningInventory.parse_output(output)

    runtime_rows =
      if include_runtime? do
        runtime_log_rows(output)
      else
        []
      end

    rows =
      (parsed ++ runtime_rows)
      |> WarningInventory.classify()
      |> apply_scope(scope)
      |> WarningInventory.join_baseline()

    metadata = %{
      "schema_version" => "1.0",
      "git_sha" => git_sha(),
      "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "since" => since,
      "scope" => scope
    }

    if Keyword.get(opts, :write, false) do
      write_artifacts!(rows, metadata)
    end

    render(rows, format, metadata)
  end

  defp preflight! do
    if Mix.env() != :test do
      Mix.raise("warning inventory requires MIX_ENV=test")
    end

    tmp_dir = Path.join(["test", "tmp"])

    case File.ls(tmp_dir) do
      {:ok, []} ->
        :ok

      {:ok, entries} ->
        Mix.raise(
          "test/tmp contains #{length(entries)} entries; clean installer fixture pollution before running warning inventory"
        )

      {:error, :enoent} ->
        :ok
    end

    unless pgvector_available?() do
      Mix.shell().info(
        "Note: pgvector may be unavailable locally; knowledge cluster counts can be incomplete."
      )
    end
  end

  defp capture_output do
    Mix.shell().info("==> Capturing compile + test warning output")

    {output, _status} =
      System.cmd(
        "mix",
        ["do", "compile", "--force", "+", "test"],
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    output
  end

  defp runtime_log_rows(output) do
    output
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/(async|teardown|sandbox)/iu, &1))
    |> Enum.reject(&String.contains?(&1, "[warning]"))
    |> Enum.map(fn line ->
      %{
        file: "runtime",
        line: 0,
        message: String.trim(line),
        signal_kind: :runtime_log,
        compiler_kind: :runtime
      }
    end)
  end

  defp apply_scope(rows, "high_signal") do
    Enum.filter(rows, fn row ->
      String.starts_with?(row.file, "lib/") or
        row.file in Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() or
        String.contains?(row.file, "test/scoria_web/live/")
    end)
  end

  defp apply_scope(rows, _scope), do: rows

  defp render(rows, "json", metadata) do
    payload = Map.put(metadata, "rows", rows)
    Mix.shell().info(Jason.encode!(payload, pretty: true))
  end

  defp render(rows, "md", metadata) do
    Mix.shell().info(render_markdown(rows, metadata))
  end

  defp render(rows, _format, metadata) do
    Mix.shell().info("Warning inventory (#{metadata["scope"]}, #{map_size(WarningInventory.cluster_counts(rows))} clusters)")

    for row <- Enum.sort_by(rows, &{&1.ratchet_tier, &1.cluster_id, &1.file}) do
      Mix.shell().info(
        "#{row.cluster_id} #{row.file}:#{row.line} #{String.slice(row.message, 0, 80)}"
      )
    end
  end

  defp write_artifacts!(rows, metadata) do
    File.mkdir_p!("tmp/warning-inventory")

    baseline_json = %{
      "schema_version" => metadata["schema_version"],
      "git_sha" => metadata["git_sha"],
      "generated_at" => metadata["generated_at"],
      "clusters" =>
        rows
        |> WarningInventory.cluster_counts()
        |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
    }

    File.write!(
      ".planning/warning-inventory.baseline.json",
      Jason.encode!(baseline_json, pretty: true)
    )

    File.write!(".planning/WARNING-INVENTORY.md", render_markdown(rows, metadata))

    File.write!(
      "tmp/warning-inventory/latest.json",
      Jason.encode!(Map.put(metadata, "rows", rows), pretty: true)
    )

    Mix.shell().info("==> Wrote .planning/warning-inventory.baseline.json")
    Mix.shell().info("==> Wrote .planning/WARNING-INVENTORY.md")
    Mix.shell().info("==> Wrote tmp/warning-inventory/latest.json")
  end

  defp render_markdown(rows, metadata) do
    counts = WarningInventory.cluster_counts(rows)

    queue =
      counts
      |> Enum.sort_by(fn {cluster_id, _count} -> WarningInventory.ratchet_tier(cluster_id) end)
      |> Enum.map(fn {cluster_id, count} ->
        "| #{cluster_id} | #{count} | #{WarningInventory.ratchet_tier(cluster_id)} |"
      end)
      |> Enum.join("\n")

    """
    # Warning Inventory

    Generated: #{metadata["generated_at"]}
    Git SHA: #{metadata["git_sha"]}
    Scope: #{metadata["scope"]}

    ## Phase 67 Ratchet Queue

    | Cluster | Count | Ratchet Tier |
    |---------|------:|--------------|
    #{queue}
    """
  end

  defp git_sha do
    case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> "unknown"
    end
  end

  defp validate_since!(nil), do: nil

  defp validate_since!(ref) when is_binary(ref) do
    if String.contains?(ref, ";") or String.contains?(ref, "`") do
      Mix.raise("invalid --since ref: #{inspect(ref)}")
    end

    ref
  end

  defp pgvector_available? do
    false
  end
end
