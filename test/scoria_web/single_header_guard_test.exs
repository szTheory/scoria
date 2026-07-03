defmodule ScoriaWeb.SingleHeaderGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  D-05 single-header guard (warning-grade, Phase-38 source-scan style — mirrors
  `ui_drift_guard_test.exs` + `ds06_drift_guard_test.exs`).

  Scoped to **page LiveViews only** (`lib/scoria_web/live/**/*.ex`), excluding
  `lib/scoria_web/ui.ex` (the sanctioned headers' own home — every `<h1>` literal
  in the codebase lives there) and dialog-scoped component files (drawer/modal/
  palette/notebook — these form their own `role="dialog"` a11y subtree per D-03
  and are not page-outline competitors).

  Three assertions:

  1. Every page module renders exactly one sanctioned page-outline header
     (`page_header/1`, `object_header/1`, or `stub_page/1`) — never zero, never
     more than one. `coming_soon_live.ex` is a documented exception: it renders
     TWO sanctioned headers (`stub_page/1` / `page_header/1`) inside mutually
     exclusive `<%= if %> ... <% else %>` branches (the D-03 stub vs not-found
     cases) — only one ever reaches the DOM per page load. A source-scan can't
     see branch exclusivity, so it's an explicit allow-list entry, not a red flag.
  2. No page module hand-rolls a raw `<h1>` literal outside a sanctioned header.
  3. D-04 region-title-restates-page: a `page_section`/`panel` `:title` slot must
     not literally restate the page's own title. **Warning-grade over static
     string literals only** — dynamic/interpolated titles are unverifiable by
     source-scan, and the semantic-redundancy case (D-04, e.g. `dataset_live`'s
     `<h1>` "Dataset Builder" vs a region "Datasets") is human-reviewed, not a
     string match. The true rendered-DOM assertion is deferred to Phase-41
     `PROOF-03`.
  """

  @page_glob "lib/scoria_web/live/**/*.ex"
  @excluded ~w(
    lib/scoria_web/ui.ex
    lib/scoria_web/live/dataset_live/promote_component.ex
  )
  # dataset_live/promote_component.ex is rendered exclusively as a
  # <.live_component> inside dataset_live/index.ex's <.drawer
  # id="dataset-promote-drawer">, so its region headings live inside a
  # dialog subtree (D-03 exemption) and it is not a routed page module.
  @dialog_scoped_fragments ~w(drawer modal palette notebook)

  @sanctioned_header_regex ~r/<\.(page_header|object_header|stub_page)\b/
  @raw_h1_regex ~r/<h1\b/

  @known_branched_headers %{"lib/scoria_web/live/coming_soon_live.ex" => 2}

  test "every page LiveView renders exactly one sanctioned page-outline header (or a documented branched exception)" do
    offenders =
      for path <- page_files(), reduce: [] do
        acc ->
          source = File.read!(path)
          header_count = @sanctioned_header_regex |> Regex.scan(source) |> length()
          expected = Map.get(@known_branched_headers, path, 1)

          if header_count == expected do
            acc
          else
            reason = if header_count < expected, do: :missing_header, else: :redundant_header
            [{path, header_count, expected, reason} | acc]
          end
      end

    assert offenders == [],
           """
           D-05 drift guard: page LiveView does not render exactly one sanctioned
           page-outline header (page_header/1, object_header/1, stub_page/1):
           #{Enum.map_join(offenders, "\n", fn {path, found, expected, reason} -> "  #{path}: found #{found}, expected #{expected} (#{reason})" end)}
             Fix: route the page-outline heading through exactly one sanctioned
             ScoriaWeb.UI header component. If the page legitimately renders two
             headers inside mutually exclusive branches (like coming_soon_live.ex),
             add it to @known_branched_headers with a comment explaining why.
           """
  end

  test "no raw <h1> literal in a page LiveView outside a sanctioned header" do
    offenders =
      for path <- page_files(),
          source = File.read!(path),
          count = @raw_h1_regex |> Regex.scan(source) |> length(),
          count > 0 do
        {path, count}
      end

    assert offenders == [],
           """
           D-05 drift guard: raw <h1> literal found in a page LiveView. Page modules
           must never hand-roll <h1> — route through page_header/1, object_header/1,
           or stub_page/1 (all defined in lib/scoria_web/ui.ex).
           #{Enum.map_join(offenders, "\n", fn {path, count} -> "  #{path}: #{count} raw <h1> literal(s)" end)}
           """
  end

  test "D-04: static-literal region titles do not restate the page's own static title (warning-grade)" do
    offenders =
      for path <- page_files(),
          page_title = page_title_literal(path),
          not is_nil(page_title),
          region_title <- region_title_literals(path),
          normalize(region_title) == normalize(page_title) do
        {path, page_title, region_title}
      end

    assert offenders == [],
           """
           D-05/D-04 drift guard: a region header (page_section/panel :title) restates
           the page's own page-outline title verbatim (static-literal check only —
           see PROOF-03 for the semantic-redundancy DOM assertion):
           #{Enum.map_join(offenders, "\n", fn {path, page_title, region_title} -> "  #{path}: page title #{inspect(page_title)} vs region title #{inspect(region_title)}" end)}
             Fix: drop the redundant region :title (render the region flush/untitled)
             or give it a distinct, region-specific name.
           """
  end

  defp page_files do
    @page_glob
    |> Path.wildcard()
    |> Enum.reject(&(&1 in @excluded))
    |> Enum.reject(&dialog_scoped?/1)
  end

  defp dialog_scoped?(path) do
    basename = Path.basename(path)
    Enum.any?(@dialog_scoped_fragments, &String.contains?(basename, &1))
  end

  # Static-literal title="..." on the page's own page_header/1 or stub_page/1 call.
  # Dynamic titles (title={...}) are intentionally not matched (unverifiable by
  # source-scan — see the D-05 module doc).
  defp page_title_literal(path) do
    case Regex.run(~r/<\.(?:page_header|stub_page)\s[^>]*?title="([^"]+)"/s, File.read!(path)) do
      [_, title] -> title
      nil -> nil
    end
  end

  # Static-literal <:title>TEXT</:title> slot bodies (page_section/panel). Bodies
  # containing "{" (HEEx interpolation) or "<" (nested tags / EEx <%= %>) are
  # skipped — dynamic/interpolated titles are not string-matchable.
  defp region_title_literals(path) do
    Regex.scan(~r/<:title>([^{<][^{<]*)<\/:title>/, File.read!(path))
    |> Enum.map(fn [_, title] -> title end)
  end

  defp normalize(text), do: text |> String.trim() |> String.downcase()
end
