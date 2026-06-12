defmodule ScoriaWeb.Layouts do
  @moduledoc """
  Root layout for the embedded Scoria dashboard.

  Scoria owns this layout (wired via the `scoria_dashboard` macro's `live_session`), so the
  dashboard renders a complete, self-contained HTML document — its own `<head>`, its own
  inlined stylesheet + client bundle, its own LiveSocket — independent of the host app's
  layout and asset pipeline.
  """
  use Phoenix.Component

  import ScoriaWeb.UI, only: [command_palette: 1, kbd: 1]

  alias ScoriaWeb.DashboardNav

  embed_templates("layouts/*")

  @doc "TV-1 Span rail brand mark (evenodd vesicle holes; pixel-snapped 3-hole geometry from favicon)."
  attr(:class, :string, default: nil)

  def brand_mark(assigns) do
    ~H"""
    <svg class={["scoria-brand__mark", @class]} viewBox="-53.32 -52.98 99.66 96.07" fill="none" aria-hidden="true">
      <path
        fill="var(--scoria-ember-500)"
        fill-rule="evenodd"
        d="M0,-51.98L35.48,-36.24Q41.88,-33.4,42.43,-26.42L44.79,3.37Q45.34,10.35,40.4,15.31L23.06,32.67Q18.12,37.63,11.17,38.44L-13.32,41.28Q-20.27,42.09,-25.37,37.29L-47.22,16.74Q-52.32,11.94,-50.51,5.18L-42.31,-25.54Q-40.5,-32.3,-34.2,-35.36ZM-10,-24C-10,-30.63,-15.37,-36,-22,-36C-28.63,-36,-34,-30.63,-34,-24C-34,-17.37,-28.63,-12,-22,-12C-15.37,-12,-10,-17.37,-10,-24ZM12,0C12,-5.52,7.52,-10,2,-10C-3.52,-10,-8,-5.52,-8,0C-8,5.52,-3.52,10,2,10C7.52,10,12,5.52,12,0ZM36,26C36,20.48,31.52,16,26,16C20.48,16,16,20.48,16,26C16,31.52,20.48,36,26,36C31.52,36,36,31.52,36,26Z"
      />
    </svg>
    """
  end

  @doc "Inline stroke icons for nav items (brand book §9: stroke, rounded)."
  attr(:name, :atom, required: true)
  attr(:class, :string, default: "scoria-nav__icon")

  def icon(assigns) do
    ~H"""
    <svg class={@class} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <%= case @name do %>
        <% :pulse -> %>
          <path d="M3 12h4l2 6 4-14 2 8h6" />
        <% :tree -> %>
          <circle cx="6" cy="6" r="2" /><circle cx="6" cy="18" r="2" /><circle cx="18" cy="12" r="2" />
          <path d="M8 6h4a2 2 0 0 1 2 2v2m0 4v2a2 2 0 0 1-2 2H8" />
        <% :flag -> %>
          <path d="M4 21V4m0 0 9-1 7 2-7 2-9-1" />
        <% :grid -> %>
          <rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" /><path d="M14 17.5h7M17.5 14v7" />
        <% :doc -> %>
          <path d="M7 3h7l5 5v13H7z" /><path d="M14 3v5h5M10 13h6M10 17h6" />
        <% :inbox -> %>
          <path d="M3 13h4l2 3h6l2-3h4" /><path d="M5 13V5h14v8M3 13v6h18v-6" />
        <% :plug -> %>
          <path d="M9 3v5m6-5v5" /><path d="M6 8h12v3a6 6 0 0 1-12 0z" /><path d="M12 17v4" />
        <% :alert -> %>
          <path d="M12 4 2 20h20z" /><path d="M12 10v4m0 3h.01" />
        <% _ -> %>
          <circle cx="12" cy="12" r="8" />
      <% end %>
    </svg>
    """
  end

  @doc "Nav groups passthrough for the shell template."
  def nav_groups, do: DashboardNav.groups()

  @doc "Command palette sections for the shell template."
  def command_sections(base_path), do: DashboardNav.command_sections(base_path)
end
