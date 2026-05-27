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
        WarningInventory.capture_output()
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
    WarningInventory.ensure_clean_tmp!()

    unless pgvector_available?() do
      Mix.shell().info(
        "Note: pgvector may be unavailable locally; knowledge cluster counts can be incomplete."
      )
    end
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
      Jason.encode!(Map.put(metadata, "rows", json_encode_rows(rows)), pretty: true)
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

    phase_67_queue = """
    ## Phase 67 — Fixed vs Deferred

    | Cluster | Action | Owner | Expiry / Notes |
    |---------|--------|-------|----------------|
    | :test_unused_binding | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
    | :test_dead_default_args | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
    | :knowledge_migration_redefine | fix | @scoria-core | migrate-once + scoped ignore_module_conflict (D-11) |
    | :unclassified_compile | fix | @scoria-core | zero in high-signal scope; classify or fix code |
    | :host_proof_generated_compile | defer | @scoria-core | p2 guard only; overlay stays in priv/ |
    | :host_overlay_test_path | defer | @scoria-core | p2 guard only; no CI adoption WAE in Phase 67 |
    | :liveview_async_teardown | defer | @scoria-web-runtime | p4 baselined until 2026-06-30 |
    """

    """
    # Warning Inventory

    Generated: #{metadata["generated_at"]}
    Git SHA: #{metadata["git_sha"]}
    Scope: #{metadata["scope"]}

    ## Phase 67 Ratchet Queue

    | Cluster | Count | Ratchet Tier |
    |---------|------:|--------------|
    #{queue}

    #{phase_67_queue}
    """
  end

  defp json_encode_rows(rows) do
    Enum.map(rows, fn row ->
      Map.new(row, fn {key, value} ->
        {Atom.to_string(key), json_encode_value(value)}
      end)
    end)
  end

  defp json_encode_value(value) when is_atom(value), do: Atom.to_string(value)

  defp json_encode_value(value) when is_list(value) do
    Enum.map(value, &json_encode_value/1)
  end

  defp json_encode_value({a, b, c}) when is_atom(a), do: [Atom.to_string(a), b, c]
  defp json_encode_value(value), do: value

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
