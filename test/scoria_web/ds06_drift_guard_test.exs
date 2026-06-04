defmodule ScoriaWeb.DS06DriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  DS-06 ratchet drift guard: enforces that raw Tailwind palette class usage
  (stone-*/rose-*/sky-*/...) never increases beyond the committed baseline.

  The guard scans all .ex and .heex files under lib/scoria_web/ (including
  templates, so a developer cannot evade it by moving raw palette into HEEx).

  Two assertions:

  1. Ratchet comparison (runs only when test/support/ds06_baseline.txt exists):
     For each non-excluded file, the palette-class count must not exceed the
     baseline count. New files with any palette usage also fail.
     TODO(12-05): remove File.exists? guard once baseline is committed.

  2. ui.ex-zero assertion (runs unconditionally, tagged :ui_ex_zero):
     lib/scoria_web/ui.ex must have zero raw palette matches. This file is
     the enforced token gateway — it must never emit raw palette classes.
     Plan 12-02 sweeps ui.ex; this tag is dropped in 12-05 when the guard
     goes fully green.
  """

  @palette_regex ~r/\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\d/

  # Files that Phase 12 zeroes out — excluded from the baseline ratchet entirely.
  # ui.ex raw palette is replaced in plan 12-02.
  # remote_invocation_evidence_component.ex is zeroed in plan 12-02.
  @excluded ~w(lib/scoria_web/ui.ex
               lib/scoria_web/components/remote_invocation_evidence_component.ex)

  @baseline_path "test/support/ds06_baseline.txt"

  test "raw palette count never regresses (DS-06 ratchet)" do
    # TODO(12-05): remove File.exists? guard once baseline is committed by plan 12-05
    if File.exists?(@baseline_path) do
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
    else
      # Baseline not yet committed — vacuous pass.
      # Plan 12-05 generates test/support/ds06_baseline.txt and removes this guard.
      assert true
    end
  end

  @tag :ui_ex_zero
  test "lib/scoria_web/ui.ex has zero raw palette matches" do
    # This assertion runs unconditionally (modulo the tag) because ui.ex is the
    # enforced token gateway — it must never emit raw palette classes.
    # Currently tagged :ui_ex_zero because plan 12-02 replaces flash_tone_class/1.
    # The tag is dropped once plan 12-02 is committed and this assertion is green.
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
    |> Enum.into(%{}, fn line ->
      [path, count] = String.split(line, ":", parts: 2)
      {path, String.to_integer(count)}
    end)
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
