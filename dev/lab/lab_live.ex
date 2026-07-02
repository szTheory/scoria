defmodule DevLab.LabLive do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The single param-driven LiveView mounted at `/scoria/_lab` by
  `ScoriaWeb.DevRouter` (Pattern 1/2, `37-RESEARCH.md`) — entirely outside
  the public `scoria_dashboard/2` macro. Renders the lab shell chrome (D-07
  IA nav rail, exact D-27 page copy) and dispatches to the seven section
  function components built in Waves 1-2 (`dev/lab/sections/*.ex`).

  `:section`/`:item` route params are matched against a FIXED compile-time
  allowlist (`@section_slugs`) — never `String.to_atom/1` on unvalidated
  input (V5, T-37-04).
  """

  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :root}

  import ScoriaWeb.UI, only: [page_section: 1]

  import DevLab.Sections.Foundations, only: [foundations: 1]
  import DevLab.Sections.Primitives, only: [primitives: 1]
  import DevLab.Sections.Groups, only: [groups: 1]
  import DevLab.Sections.States, only: [states_section: 1]
  import DevLab.Sections.Viewports, only: [viewports: 1]
  import DevLab.Sections.Overlays, only: [overlays: 1]
  import DevLab.Sections.FixturesView, only: [fixtures_view: 1]

  # D-07 IA — exact order and exact labels. This is the ONLY place the
  # section list is declared; the nav rail and the allowlist below both
  # derive from it so they can never drift apart.
  @sections [
    {"foundations", "Foundations"},
    {"primitives", "Primitives"},
    {"groups", "Groups"},
    {"states", "States"},
    {"viewports", "Viewports"},
    {"overlays", "Overlays"},
    {"fixtures", "Fixtures"}
  ]

  @section_slugs Enum.map(@sections, &elem(&1, 0))

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(socket,
       section: resolve_section(params["section"]),
       item: params["item"],
       page_title: "Component Lab"
     )}
  end

  # Fixed compile-time allowlist match — never String.to_atom/1 on an
  # unvalidated route param (V5). Unknown/nil section falls back to
  # "foundations", the first D-07 IA entry.
  defp resolve_section(section) when section in @section_slugs, do: section
  defp resolve_section(_unknown_or_nil), do: "foundations"

  # Plan 02's Primitives specimens and Plan 04's Overlays probes both keep
  # their representative drawer/modal specimens genuinely open and dismiss
  # them via this shared no-op event name (see 37-02-SUMMARY.md /
  # 37-04-SUMMARY.md "Decisions Made"). The lab never mutates fixture
  # state, so dismissal here is intentionally inert — without this clause,
  # clicking either specimen's dismiss control would crash the LiveView.
  @impl Phoenix.LiveView
  def handle_event("lab-noop-dismiss", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    assigns = assign(assigns, :sections, @sections)

    ~H"""
    <div class="scoria-lab-shell">
      <nav class="scoria-lab-nav" aria-label="Component Lab sections">
        <.link
          :for={{slug, label} <- @sections}
          patch={"/scoria/_lab/" <> slug}
          class={["scoria-lab-nav__item", @section == slug && "scoria-lab-nav__item--active"]}
        >
          {label}
        </.link>
      </nav>

      <div class="scoria-lab-main">
        <.page_section>
          <:eyebrow>Component Lab</:eyebrow>
          <:title>Component Lab</:title>
          <:description>
            Inspect Scoria primitives, groups, fixtures, themes, and stress states before changing shared UI.
          </:description>
          <:actions>
            <.link patch="/scoria/_lab/states" class="scoria-button scoria-button--primary">
              Run lab proof
            </.link>
            <.link patch="/scoria/_lab/fixtures" class="scoria-button scoria-button--ghost">
              Open fixture matrix
            </.link>
          </:actions>
        </.page_section>

        <.foundations :if={@section == "foundations"} />
        <.primitives :if={@section == "primitives"} item={@item} />
        <.groups :if={@section == "groups"} item={@item} />
        <.states_section :if={@section == "states"} />
        <.viewports :if={@section == "viewports"} />
        <.overlays :if={@section == "overlays"} />
        <.fixtures_view :if={@section == "fixtures"} item={@item} />
      </div>
    </div>
    """
  end
end
