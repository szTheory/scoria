defmodule DevLab.Sections.Viewports do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Viewports` IA section (D-07): the six D-13 proof-target widths — 320,
  375, 768, 1024, 1440, and wide desktop — made directly inspectable as
  side-by-side simulator frames, all constraining the SAME dense table/list
  specimen so responsive collapse and overflow behavior are comparable at a
  glance (RISK-RESPONSIVE-SCAN). This is the manual/visual complement to the
  Playwright `page.setViewportSize` proof Plan 06 adds after the lab route
  mounts (Plan 05) — it does not replace that behavioral proof.

  Frames are proof aids only: built from `ScoriaWeb.UI.panel/1`/`kbd/1`
  chrome plus the shared `table/1` primitive, constrained via an inline
  `width`/`max-width` style on a wrapper `div` — never a new breakpoint,
  spacing, or type token (D-13/D-26). The responsive collapse behavior being
  simulated (overflow-x scroll inside `table/1`'s own
  `scoria-table__viewport`, and the `mobile_summary` table→card swap)
  already lives in `assets/css/04-components.css`; this module reuses that
  CSS as-is and forks nothing.

  Viewport labels use the EXACT D-13 maintainer strings verbatim — proof
  targets, never device marketing names (e.g. never "iPhone SE").
  """

  use Phoenix.Component
  import ScoriaWeb.UI, only: [page_section: 1, panel: 1, kbd: 1, table: 1]

  # D-13 verbatim labels, in fixed proof-target order. `nil` width means "no
  # artificial cap" — the unconstrained wide-desktop proof target.
  @widths [
    {320, "320px — small mobile"},
    {375, "375px — mobile"},
    {768, "768px — tablet"},
    {1024, "1024px — small desktop"},
    {1440, "1440px — desktop"},
    {nil, "Wide desktop"}
  ]

  attr(:class, :string, default: nil)

  @doc """
  Renders the `Viewports` IA section: one simulator frame per D-13
  proof-target width, each constraining the same dense table specimen
  (`DevLab.Fixtures.states_for(:table, :dataset_promoted)`'s `:dense` row —
  the same densified fixture `DevLab.Sections.Primitives` already renders
  for the `table` primitive band, reused rather than re-derived).
  """
  def viewports(assigns) do
    assigns =
      assigns
      |> assign(:widths, @widths)
      |> assign(:specimen, viewport_specimen())

    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Viewports</:eyebrow>
      <:title>Viewport Simulator</:title>
      <:description>
        The six D-13 proof-target widths, each framing the same dense
        table/list specimen so responsive collapse and overflow behavior
        (RISK-RESPONSIVE-SCAN) are directly comparable. Real browser-resize
        proof lives in Plan 06's Playwright suite once the lab route mounts
        (Plan 05) — these frames are the manual/visual complement, not a
        replacement.
      </:description>

      <div :for={{width, label} <- @widths} class="scoria-lab-viewport" data-lab-viewport-width={viewport_key(width)}>
        <.panel>
          <:eyebrow>Proof target</:eyebrow>
          <:title>{label}</:title>
          <:actions><.kbd>{viewport_chip(width)}</.kbd></:actions>
          <div class="scoria-lab-viewport__frame" style={viewport_frame_style(width)}>
            <.table id={"lab-viewport-table-" <> viewport_key(width)} rows={@specimen.rows}>
              <:col :let={row} label="ID">{row.id}</:col>
              <:col :let={row} label="Input">{row.input}</:col>
              <:col :let={row} label="Label">{row.label}</:col>
              <:mobile_summary :let={row}>
                <div class="scoria-mobile-summary">
                  <div class="scoria-mobile-summary__label">{row.input}</div>
                  <div class="scoria-mobile-summary__meta">{row.label}</div>
                </div>
              </:mobile_summary>
            </.table>
          </div>
        </.panel>
      </div>
    </.page_section>
    """
  end

  # ---------------------------------------------------------------------
  # D-13: width applied only via inline style — never a new breakpoint
  # token. `nil` (wide desktop) gets no max-width cap at all.
  # ---------------------------------------------------------------------
  defp viewport_frame_style(nil), do: "width: 100%;"

  defp viewport_frame_style(width),
    do: "width: 100%; max-width: #{width}px; margin-inline: auto;"

  defp viewport_chip(nil), do: "Wide"
  defp viewport_chip(width), do: "#{width}px"

  defp viewport_key(nil), do: "wide"
  defp viewport_key(width), do: Integer.to_string(width)

  # The `:dense` row of the SAME table specimen DevLab.Sections.Primitives
  # renders for the `table` primitive band (D-06 spine: one shared
  # derivation, never a re-authored second dense fixture).
  defp viewport_specimen do
    :table
    |> DevLab.Fixtures.states_for(:dataset_promoted)
    |> Keyword.fetch!(:dense)
  end
end
