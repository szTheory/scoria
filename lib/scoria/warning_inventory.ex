defmodule Scoria.WarningInventory do
  @moduledoc """
  Parses and classifies compiler warning output for maintainer inventory runs.

  Inventory runs in capture mode (no WAE) so warnings can be measured even when
  the suite fails. Unclassified compile warnings should prompt registry updates.
  """

  alias Scoria.VerificationLanes
  alias Scoria.WarningBaseline
  alias Scoria.WarningInventory.Cluster

  @excluded_patterns [
    ~r/\[warning\]/,
    ~r/severity:\s*"warning"/,
    ~r/retry(ing)?\s+request/i
  ]

  @location_pattern ~r/(?<file>[^\s:]+\.ex(?:s)?):(?<line>\d+)(?::\d+)?/

  @doc """
  Parses captured mix output into warning maps.
  """
  @spec parse_output(String.t()) :: [map()]
  def parse_output(output) when is_binary(output) do
    output
    |> String.split("\n")
    |> parse_lines([])
    |> Enum.reverse()
    |> Enum.uniq()
  end

  @doc """
  Classifies parsed warning maps with cluster, lane, and ratchet metadata.
  """
  @spec classify([map()]) :: [map()]
  def classify(warnings) do
    Enum.map(warnings, fn warning ->
      cluster_id = Cluster.match(warning)

      warning
      |> Map.put(:cluster_id, cluster_id)
      |> Map.put(:path_area, path_area(warning.file))
      |> Map.put(:ratchet_tier, ratchet_tier(cluster_id))
      |> Map.put(:lane_ids, lane_ids_for_file(warning.file))
      |> Map.put(:in_adoption_lane, in_adoption_lane?(warning.file))
      |> Map.put(:in_closeout, in_closeout?(warning.file))
      |> Map.put(:dedupe_key, dedupe_key(warning, cluster_id))
    end)
  end

  @doc """
  Maps cluster ids to Phase 67 ratchet ordering tiers.
  """
  @spec ratchet_tier(atom()) :: atom()
  def ratchet_tier(cluster_id) do
    case cluster_id do
      :canonical_surface_clean -> :p0_compile_lib
      :knowledge_migration_redefine -> :p4_baselined_deferred
      :test_unused_binding -> :p3_high_signal_tests
      :test_dead_default_args -> :p3_high_signal_tests
      :host_proof_generated_compile -> :p2_adoption_lane_files
      :host_overlay_test_path -> :p2_adoption_lane_files
      :liveview_async_teardown -> :p4_baselined_deferred
      :unclassified_compile -> :p5_out_of_scope
      _ -> :p5_out_of_scope
    end
  end

  @doc """
  Joins baseline owner/expiry metadata onto classified rows by surface name.
  """
  @spec join_baseline([map()], keyword()) :: [map()]
  def join_baseline(rows, opts \\ []) do
    baseline = WarningBaseline.load(Keyword.take(opts, [:file, :date]))
    surfaces = Map.new(WarningBaseline.accepted_rows(baseline), &{&1.surface, &1})

    Enum.map(rows, fn row ->
      case Map.get(surfaces, row[:baseline_surface]) do
        nil ->
          row

        baseline_row ->
          row
          |> Map.put(:owner, baseline_row.owner)
          |> Map.put(:expires, baseline_row.expires)
      end
    end)
  end

  @doc """
  Returns lane ids associated with a file path.
  """
  @spec lane_ids_for_file(String.t()) :: [atom()]
  def lane_ids_for_file(file) do
    ids = []

    ids =
      if in_adoption_lane?(file) do
        [:adoption | ids]
      else
        ids
      end

    ids =
      if String.contains?(file, "verification_lanes_test") or
           String.contains?(file, "adoption_surface_test") do
        [:release_preview | ids]
      else
        ids
      end

    Enum.uniq(ids)
  end

  @doc """
  Builds a stable dedupe key for inventory rows.
  """
  @spec dedupe_key(map(), atom()) :: {atom(), String.t(), String.t()}
  def dedupe_key(%{file: file, message: message}, cluster_id) do
    fingerprint =
      message
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
      |> String.slice(0, 80)

    {cluster_id, file, fingerprint}
  end

  @doc """
  Summarizes classified rows by cluster id count.
  """
  @spec cluster_counts([map()]) :: %{atom() => non_neg_integer()}
  def cluster_counts(rows) do
    Enum.frequencies_by(rows, & &1.cluster_id)
  end

  @doc """
  Captures compile + test warning output for inventory and ratchet checks.

  Runs in capture mode (no WAE) so warnings can be measured even when the suite fails.
  """
  @spec capture_output() :: String.t()
  def capture_output do
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

  defp parse_lines([], acc), do: acc

  defp parse_lines([line | rest], acc) do
    cond do
      excluded_line?(line) ->
        parse_lines(rest, acc)

      String.contains?(line, "warning:") ->
        parse_lines(rest, maybe_add_warning(line, rest, acc))

      true ->
        parse_lines(rest, acc)
    end
  end

  defp maybe_add_warning(line, rest, acc) do
    message = extract_message(line)
    location_line = Enum.find(rest, &Regex.match?(@location_pattern, &1))

    case location_line do
      nil ->
        acc

      loc ->
        %{"file" => file, "line" => line_no} = Regex.named_captures(@location_pattern, loc)

        warning = %{
          file: file,
          line: String.to_integer(line_no),
          message: message,
          signal_kind: :compile_warning,
          compiler_kind: :elixir
        }

        [warning | acc]
    end
  end

  defp extract_message(line) do
    line
    |> String.replace(~r/^\s*warning:\s*/u, "")
    |> String.trim()
  end

  defp excluded_line?(line) do
    Enum.any?(@excluded_patterns, &Regex.match?(&1, line))
  end

  defp path_area(file) do
    cond do
      String.starts_with?(file, "lib/scoria/") -> :canonical_lib
      String.starts_with?(file, "test/") -> :test
      String.starts_with?(file, "lib/") -> :lib
      true -> :other
    end
  end

  defp in_adoption_lane?(file) do
    file in Mix.Tasks.Scoria.Test.Adoption.adoption_test_files()
  end

  defp in_closeout?(file) do
    in_adoption_lane?(file) or
      Enum.any?(VerificationLanes.closeout_order(), fn lane_id ->
        file_matches_lane?(file, lane_id)
      end)
  end

  defp file_matches_lane?(file, :release_preview), do: String.contains?(file, "release_preview")
  defp file_matches_lane?(file, :adoption), do: in_adoption_lane?(file)

  defp file_matches_lane?(file, :runtime_to_handoff),
    do: String.contains?(file, "runtime_to_handoff")

  defp file_matches_lane?(_file, _lane_id), do: false
end
