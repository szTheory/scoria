defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  DS-06 ratchet drift guard: enforces that raw Tailwind palette class usage
  (stone-*/rose-*/sky-*/...) never increases beyond the committed baseline.

  The guard scans all .ex and .heex files under lib/scoria_web/ (including
  templates, so a developer cannot evade it by moving raw palette into HEEx).

  Two assertions:

  1. Ratchet comparison: for each non-excluded file, the palette-class count
     must not exceed the baseline count. New files with any palette usage also
     fail. Baseline committed at test/support/ds06_baseline.txt (plan 12-05).

  2. ui.ex-zero assertion: lib/scoria_web/ui.ex must have zero raw palette
     matches. This file is the enforced token gateway — it must never emit
     raw palette classes.
  """

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  # Files that Phase 12 zeroes out — excluded from the baseline ratchet entirely.
  # ui.ex raw palette is replaced in plan 12-02.
  # remote_invocation_evidence_component.ex is zeroed in plan 12-02.
  @excluded ~w(lib/scoria_web/ui.ex
               lib/scoria_web/components/remote_invocation_evidence_component.ex)

  @baseline_path "test/support/ds06_baseline.txt"

  test "raw palette count never regresses (DS-06 ratchet)" do
    baseline = load_baseline()

    violations =
      for path <- Path.wildcard("lib/scoria_web/**/*.{ex,heex}"),
          path not in @excluded do
        count = path |> File.read!() |> then(&length(Regex.scan(@palette_regex, &1)))
        baseline_count = Map.get(baseline, path, 0)

        cond do
          count > baseline_count -> {path, count, baseline_count, :regression}
          baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}
          true -> nil
        end
      end
      |> Enum.reject(&is_nil/1)

    assert violations == [], format_failure(violations)
  end

  test "baseline is not stale — no file sits below its committed baseline (WR-01)" do
    # WR-01: the ratchet only fails on count > baseline, so once a file's palette
    # usage is reduced (the Phase 12 goal) but the baseline is not lowered, the file
    # silently re-acquires headroom: a later change can add palette back up to the
    # stale baseline with the guard staying green, freezing the worst-ever state.
    # This assertion forces the baseline to be re-committed downward on every
    # improvement, so the ratchet always tightens and never leaves slack.
    baseline = load_baseline()

    stale =
      for {path, baseline_count} <- baseline, baseline_count > 0 do
        count =
          if File.exists?(path) do
            path |> File.read!() |> then(&length(Regex.scan(@palette_regex, &1)))
          else
            # A baselined file that no longer exists is also stale: drop its entry.
            0
          end

        if count < baseline_count, do: {path, count, baseline_count}
      end
      |> Enum.reject(&is_nil/1)

    assert stale == [],
           """
           DS-06 drift guard: stale baseline — these files now use FEWER raw palette
           classes than their committed baseline. Lower the baseline so the ratchet
           tightens (otherwise palette can be re-introduced up to the stale value):
           #{Enum.map_join(stale, "\n", fn {path, count, baseline_count} -> "  #{path}: found #{count}, baseline #{baseline_count}" end)}
             Fix: regenerate #{@baseline_path} from the current codebase and re-commit it.
           """
  end

  test "lib/scoria_web/ui.ex has zero raw palette matches" do
    # ui.ex is the enforced token gateway — it must never emit raw palette classes.
    source = File.read!("lib/scoria_web/ui.ex")
    matches = Regex.scan(@palette_regex, source)

    assert matches == [],
           """
           DS-06 drift guard failed: raw palette class found in lib/scoria_web/ui.ex
           #{Enum.map(matches, fn [m] -> "  #{m}" end) |> Enum.join("\n")}
             Fix: replace with semantic scoria-flash--{tone} class (see 12-UI-SPEC.md DS-05)
           """
  end

  defp load_baseline do
    @baseline_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.into(%{}, &parse_baseline_line/1)
  end

  # WR-02: a malformed committed baseline line (no colon, non-integer count,
  # stray whitespace/\r, a colon inside the path) previously crashed with an
  # opaque MatchError/ArgumentError giving no hint which line was bad. Validate
  # each field and emit a descriptive drift-guard failure naming the line.
  # The path is everything before the LAST colon so paths containing a colon
  # still parse; the count is everything after it.
  defp parse_baseline_line(line) do
    case String.split(line, ":") do
      parts when length(parts) >= 2 ->
        {count_str, path_parts} = List.pop_at(parts, -1)
        path = path_parts |> Enum.join(":") |> String.trim()
        count_str = String.trim(count_str)

        case Integer.parse(count_str) do
          {count, ""} when path != "" ->
            {path, count}

          _ ->
            flunk_baseline(line)
        end

      _ ->
        flunk_baseline(line)
    end
  end

  defp flunk_baseline(line) do
    ExUnit.Assertions.flunk("""
    DS-06 drift guard: malformed baseline entry in #{@baseline_path}
      offending line: #{inspect(line)}
      expected format: <path>:<integer-count>
      Fix: correct the line, or regenerate the baseline with the scanner
      (Path.wildcard("lib/scoria_web/**/*.{ex,heex}") minus @excluded, emit "path:count"
      sorted; see 12-05-PLAN.md) and re-commit #{@baseline_path}.
    """)
  end

  defp format_failure(violations) do
    lines =
      Enum.map(violations, fn {path, count, baseline, reason} ->
        "  #{path}: found #{count}, baseline #{baseline} (#{reason})"
      end)

    """
    DS-06 drift guard failed: raw palette class found in lib/scoria_web/
    #{Enum.join(lines, "\n")}
      Fix: replace with semantic token class (see 12-UI-SPEC.md DS-05)
    """
  end
end
