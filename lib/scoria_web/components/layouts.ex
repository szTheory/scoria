defmodule ScoriaWeb.Layouts do
  @moduledoc """
  Root layout for the embedded Scoria dashboard.

  Scoria owns this layout (wired via the `scoria_dashboard` macro's `live_session`), so the
  dashboard renders a complete, self-contained HTML document — its own `<head>`, its own
  inlined stylesheet + client bundle, its own LiveSocket — independent of the host app's
  layout and asset pipeline.
  """
  use Phoenix.Component

  alias ScoriaWeb.DashboardNav

  embed_templates("layouts/*")

  @doc "Porous-cinder brand mark (negative-space vesicles evoke a trace tree)."
  attr(:class, :string, default: nil)

  def brand_mark(assigns) do
    ~H"""
    <svg class={["scoria-brand__mark", @class]} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M5.2 4.6C8 2.4 16 2 19.2 5.2c3 3 2.6 11-0.6 14.2-3 3-11.2 2.8-14.2-0.4C1.2 15.8 2 6.9 5.2 4.6Z"
        fill="var(--scoria-ember-500)"
        opacity="0.16"
        stroke="var(--scoria-ember-500)"
        stroke-width="1.1"
      />
      <circle cx="10" cy="9" r="2.1" fill="var(--scoria-ember-500)" />
      <circle cx="15.4" cy="12.6" r="1.3" fill="var(--scoria-molten-400)" />
      <circle cx="9.2" cy="15" r="1" fill="var(--scoria-molten-400)" opacity="0.8" />
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
end
