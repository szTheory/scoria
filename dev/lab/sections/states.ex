defmodule DevLab.Sections.States do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  Owns two things, on purpose:

    * `state_tone/1` — the SINGLE lab-state to visual-tone mapping (D-12).
      Every downstream lab section routes state -> tone through this
      function; none of them ever call `ScoriaWeb.UI.tone/1` on a lab state
      name (that function maps *domain status strings*, a different
      vocabulary — see `ScoriaWeb.UI.tone/1`).
    * `states_band/1` — the one reusable per-state renderer every
      `Primitives`/`Groups` section entry uses to show all ten canonical
      D-11 states for a given specimen.

  `states_section/1` is the `States` IA nav section (D-07): a maintainer
  overview of the ten-state vocabulary rendered once on a representative
  specimen.
  """

  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1, panel: 1]

  @doc """
  Maps a canonical D-11 lab-state atom to a `ScoriaWeb.UI` visual tone atom
  (D-12). This is the ONLY place a lab-state name becomes a tone — never
  call `ScoriaWeb.UI.tone/1` on a state atom; that function maps domain
  *status* strings (e.g. `"approval_requested"`), not lab *state* names
  (e.g. `:warning`).
  """
  def state_tone(:warning), do: :warn
  def state_tone(:danger), do: :fail
  def state_tone(:error), do: :fail
  def state_tone(:selected), do: :brand
  def state_tone(:loading), do: :info
  def state_tone(:normal), do: :neutral
  def state_tone(:long_text), do: :neutral
  def state_tone(:empty), do: :neutral
  def state_tone(:dense), do: :neutral
  def state_tone(:disabled), do: :neutral

  attr(:inventory_id, :string, required: true)
  attr(:states, :list, required: true)

  slot :render, required: true do
    attr(:fixture, :any)
  end

  @doc """
  Renders one labeled specimen per D-11 state from a
  `DevLab.Fixtures.states_for/2` keyword list. Every specimen's state label
  is tone-mapped explicitly through `state_tone/1` — never inferred through
  `ScoriaWeb.UI.tone/1`, which would silently map `dense`/`long_text` to
  `:neutral` and coincidentally also "pass" for `warning`/`danger`/`error`,
  hiding a real state/tone drift bug (see `state_tone/1`).
  """
  def states_band(assigns) do
    ~H"""
    <div class="scoria-lab-states" data-inventory-id={@inventory_id}>
      <div :for={{state, fixture} <- @states} class="scoria-lab-state" data-lab-state={state}>
        <.badge tone={state_tone(state)} label={Atom.to_string(state)} />
        <div class="scoria-lab-state__specimen">{render_slot(@render, fixture)}</div>
      </div>
    </div>
    """
  end

  @doc """
  The `States` IA nav section (D-07): a maintainer overview of the ten
  canonical D-11 states, rendered once on a representative badge specimen so
  the vocabulary and its tone mapping are visible before drilling into
  per-primitive/per-group coverage elsewhere in the lab.
  """
  def states_section(assigns) do
    assigns = assign(assigns, :states, DevLab.Fixtures.states_for(:badge, :approval_requested))

    ~H"""
    <.panel>
      <:eyebrow>States</:eyebrow>
      <:title>Canonical Lab States</:title>
      <p class="scoria-page-section__description">
        The ten canonical D-11 states, shown here on one representative
        badge specimen. Every primitive and group elsewhere in the lab
        renders through this same <code>states_band/1</code> renderer.
      </p>
      <.states_band inventory_id={DevLab.Fixtures.inventory_id(:badge)} states={@states}>
        <:render :let={fixture}>
          <.badge tone={:neutral} label={to_string(Map.get(fixture, :status, fixture.scenario))} />
        </:render>
      </.states_band>
    </.panel>
    """
  end
end
