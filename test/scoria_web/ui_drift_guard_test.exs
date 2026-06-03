defmodule ScoriaWeb.UIDriftGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Guards against re-introducing the per-component status→color helpers that the
  shared `ScoriaWeb.UI` vocabulary (`tone/1` + `<.badge tone=>` + `<.flash_group>`)
  replaced. New status coloring must go through ScoriaWeb.UI, never a bespoke
  `defp badge_class/status_color/trace_badge_class/flash_kind_class`.

  NOTE: the broader raw-palette-utility gate (failing on `bg-emerald-`/`bg-rose-`
  literals in markup) stays deferred — those compat class names are still
  load-bearing in `assets/css/06-utilities.css` as the semantic-migration runway.
  """

  # The drifted helper names this dedup eliminated. The canonical home is
  # ScoriaWeb.UI (`tone/1`, `badge/1`, `flash_group/1` + private `flash_tone_class`).
  @forbidden ~w(badge_class status_color trace_badge_class flash_kind_class)

  test "no re-introduced per-component status→color helpers in lib/scoria_web" do
    offenders =
      "lib/scoria_web/**/*.ex"
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        source = File.read!(path)

        for name <- @forbidden,
            Regex.match?(~r/\bdefp?\s+#{name}\b/, source),
            do: "#{path}: defp #{name}"
      end)

    assert offenders == [],
           """
           Re-introduced per-component status→color helper(s). Use ScoriaWeb.UI instead:
           map the domain value to a tone atom (via `tone/1` or a local value→tone helper),
           then render `<.badge tone=>`; use `<.flash_group>` for flash banners.

           Offenders:
           #{Enum.join(offenders, "\n")}
           """
  end
end
