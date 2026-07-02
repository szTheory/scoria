defmodule DevLab.Sections.Primitives do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Primitives` IA section (D-07): every canonical `ScoriaWeb.UI`
  primitive, rendered across all ten D-11 states via
  `DevLab.Sections.States.states_band/1`, each band anchored to its
  Phase-36 `PRIM-*` inventory ID (D-08). This is the maintainer's "specimen
  under stress" bench (D-25) before Phase 38 changes any shared control.

  Consumes only Plan 01 output: `DevLab.Fixtures.states_for/2`,
  `DevLab.Fixtures.inventory_id/1`, and
  `DevLab.Sections.States.states_band/1`/`state_tone/1` — no new fixture
  catalog, no new state-band renderer, no new primitive is introduced here.

  Tone is NEVER a literal D-11 state atom written directly into a `tone`
  attr. Every specimen embeds the current lab state into its own fixture
  map (`with_lab_state/1`) and resolves color exclusively through
  `DevLab.Sections.States.state_tone/1` (never `ScoriaWeb.UI.tone/1` on a
  lab-state atom — that function maps domain *status* strings, a different
  vocabulary, see D-12).

  `Drawer`/`Modal` specimens render genuinely open only for the `:normal`
  row — stacking ten simultaneously-open full-viewport overlays inside one
  specimen grid would be unusable. Full open/close/focus/dismissal stress
  belongs to the dedicated `Overlays` IA section (D-10); the other nine
  rows here say so explicitly rather than fake an open overlay.
  """

  use Phoenix.Component
  import ScoriaWeb.UI
  import DevLab.Sections.States, only: [states_band: 1]

  attr(:item, :string, default: nil)
  attr(:class, :string, default: nil)

  @doc """
  Renders the `Primitives` IA section. When `item` is set (deep link via
  `/scoria/_lab/primitives/:item`), only that primitive's panel renders;
  otherwise every canonical primitive renders.
  """
  def primitives(assigns) do
    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Primitives</:eyebrow>
      <:title>Primitives</:title>
      <:description>
        Every canonical ScoriaWeb.UI primitive, rendered across all ten D-11
        states and anchored to its Phase-36 PRIM-* inventory ID.
      </:description>

      <.panel :if={show?(@item, "button")}>
        <:eyebrow>Buttons</:eyebrow>
        <:title>ScoriaWeb.UI.button/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:button)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:button)}
          states={with_lab_state(DevLab.Fixtures.states_for(:button, :approval_requested))}
        >
          <:render :let={fixture}>
            <.button variant={button_variant(fixture)} disabled={fixture[:disabled] || false}>
              Approve {fixture[:tool_name]}
            </.button>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "icon_button")}>
        <:eyebrow>Icon Buttons</:eyebrow>
        <:title>ScoriaWeb.UI.icon_button/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:icon_button)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:icon_button)}
          states={with_lab_state(DevLab.Fixtures.states_for(:icon_button, :approval_requested))}
        >
          <:render :let={fixture}>
            <.icon_button
              variant={button_variant(fixture)}
              disabled={fixture[:disabled] || false}
              aria-label={"Approve " <> (fixture[:tool_name] || "")}
            >
              <.lab_check_icon />
            </.icon_button>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "badge")}>
        <:eyebrow>Badges</:eyebrow>
        <:title>ScoriaWeb.UI.badge/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:badge)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:badge)}
          states={with_lab_state(DevLab.Fixtures.states_for(:badge, :incident_opened))}
        >
          <:render :let={fixture}>
            <.badge
              tone={DevLab.Sections.States.state_tone(fixture.lab_state)}
              label={ScoriaWeb.UI.status_label(fixture.status)}
            />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "panel")}>
        <:eyebrow>Panels</:eyebrow>
        <:title>ScoriaWeb.UI.panel/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:panel)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:panel)}
          states={with_lab_state(DevLab.Fixtures.states_for(:panel, :connector_degraded))}
        >
          <:render :let={fixture}>
            <.panel>
              <:eyebrow>{fixture.connector_label}</:eyebrow>
              <:title>Connector Detail</:title>
              <p>{fixture.reason}</p>
            </.panel>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "page_section")}>
        <:eyebrow>Page Sections</:eyebrow>
        <:title>ScoriaWeb.UI.page_section/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:page_section)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:page_section)}
          states={with_lab_state(DevLab.Fixtures.states_for(:page_section, :dataset_promoted))}
        >
          <:render :let={fixture}>
            <.page_section>
              <:eyebrow>Datasets</:eyebrow>
              <:title>{fixture.dataset_id}</:title>
              <:description>{fixture.version_name}</:description>
              <p>{fixture.row_count} rows</p>
            </.page_section>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "overview_stats")}>
        <:eyebrow>Overview Stats</:eyebrow>
        <:title>ScoriaWeb.UI.overview_stats/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:overview_stats)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:overview_stats)}
          states={with_lab_state(DevLab.Fixtures.states_for(:overview_stats, :dataset_promoted))}
        >
          <:render :let={fixture}>
            <.overview_stats label="Dataset summary">
              <:stat
                label="Rows"
                value={to_string(fixture.row_count)}
                tone={DevLab.Sections.States.state_tone(fixture.lab_state)}
              >
                {fixture.version_name}
              </:stat>
            </.overview_stats>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "table")}>
        <:eyebrow>Tables / Lists</:eyebrow>
        <:title>ScoriaWeb.UI.table/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:table)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:table)}
          states={with_lab_state(DevLab.Fixtures.states_for(:table, :dataset_promoted))}
        >
          <:render :let={fixture}>
            <.table id={specimen_id("table", fixture)} rows={fixture.rows}>
              <:col :let={row} label="ID">{row.id}</:col>
              <:col :let={row} label="Input">{row.input}</:col>
              <:col :let={row} label="Label">{row.label}</:col>
            </.table>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "drawer")}>
        <:eyebrow>Drawers</:eyebrow>
        <:title>ScoriaWeb.UI.drawer/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:drawer)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:drawer)}
          states={with_lab_state(DevLab.Fixtures.states_for(:drawer, :connector_degraded))}
        >
          <:render :let={fixture}>
            <div>
              <.drawer
                id={specimen_id("drawer", fixture)}
                show={fixture.lab_state == :normal}
                on_dismiss="lab-noop-dismiss"
                title={fixture.connector_label}
              >
                <p>{fixture.reason}</p>
              </.drawer>
              <p :if={fixture.lab_state != :normal} class="scoria-lab-token-usage">
                Drawer shown open only for the "normal" row above — open/close/focus
                stress lives in the Overlays section (D-10).
              </p>
            </div>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "modal")}>
        <:eyebrow>Modals</:eyebrow>
        <:title>ScoriaWeb.UI.modal/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:modal)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:modal)}
          states={with_lab_state(DevLab.Fixtures.states_for(:modal, :workflow_failed_step))}
        >
          <:render :let={fixture}>
            <div>
              <.modal
                id={specimen_id("modal", fixture)}
                show={fixture.lab_state == :normal}
                on_dismiss="lab-noop-dismiss"
                title="Workflow step failed"
              >
                <p>{fixture.reason}</p>
                <:footer>
                  <.button variant={:ghost} phx-click="lab-noop-dismiss">Close</.button>
                </:footer>
              </.modal>
              <p :if={fixture.lab_state != :normal} class="scoria-lab-token-usage">
                Modal shown open only for the "normal" row above — open/close/focus
                stress lives in the Overlays section (D-10).
              </p>
            </div>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "toast")}>
        <:eyebrow>Toasts</:eyebrow>
        <:title>ScoriaWeb.UI.toast/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:toast)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:toast)}
          states={with_lab_state(DevLab.Fixtures.states_for(:toast, :incident_escalated))}
        >
          <:render :let={fixture}>
            <.toast id={specimen_id("toast", fixture)} tone={toast_tone(fixture)} message={toast_message(fixture)} />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "field")}>
        <:eyebrow>Fields</:eyebrow>
        <:title>ScoriaWeb.UI.field/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:field)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:field)}
          states={with_lab_state(DevLab.Fixtures.states_for(:field, :prompt_release_blocked))}
        >
          <:render :let={fixture}>
            <.field
              id={specimen_id("field", fixture)}
              label="Policy version name"
              required
              error={if fixture.lab_state == :error, do: fixture.reason}
            >
              <input
                id={specimen_id("field-input", fixture)}
                type="text"
                value={fixture.version_name}
                readonly
                disabled={fixture[:disabled] || false}
              />
            </.field>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "form_section")}>
        <:eyebrow>Form Sections</:eyebrow>
        <:title>ScoriaWeb.UI.form_section/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:form_section)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:form_section)}
          states={with_lab_state(DevLab.Fixtures.states_for(:form_section, :eval_regression_detected))}
        >
          <:render :let={fixture}>
            <.form_section title="Eval spec" description={fixture.reason}>
              <.field id={specimen_id("form-section-field", fixture)} label="Eval spec ID">
                <input
                  id={specimen_id("form-section-input", fixture)}
                  type="text"
                  value={fixture.eval_spec_id}
                  readonly
                />
              </.field>
            </.form_section>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "notebook")}>
        <:eyebrow>Notebooks</:eyebrow>
        <:title>ScoriaWeb.UI.notebook/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:notebook)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:notebook)}
          states={with_lab_state(DevLab.Fixtures.states_for(:notebook, :approval_requested))}
        >
          <:render :let={fixture}>
            <.notebook
              id={specimen_id("notebook", fixture)}
              title="Fixture Evidence"
              eyebrow={to_string(Map.get(fixture, :domain, "lab"))}
              empty={fixture.lab_state == :empty}
            >
              <:tab key="evidence" label="Technical evidence">
                <.evidence_section
                  title="Fixture Payload"
                  tone={DevLab.Sections.States.state_tone(fixture.lab_state)}
                >
                  <.evidence_rows rows={notebook_rows(fixture)} />
                </.evidence_section>
              </:tab>
              <:empty_slot>
                <.evidence_empty title="No fixture rows for this state">
                  No fixture rows for this state. Add deterministic dev fixture data
                  before using this state for proof.
                </.evidence_empty>
              </:empty_slot>
            </.notebook>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "raw_evidence")}>
        <:eyebrow>Raw Evidence / Code</:eyebrow>
        <:title>ScoriaWeb.UI.raw_evidence/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:raw_evidence)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:raw_evidence)}
          states={with_lab_state(DevLab.Fixtures.states_for(:raw_evidence, :eval_regression_detected))}
        >
          <:render :let={fixture}>
            <.raw_evidence label="Raw fixture payload" value={inspect(fixture, pretty: true)} open={false} copyable />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "empty_state")}>
        <:eyebrow>Empty States</:eyebrow>
        <:title>ScoriaWeb.UI.empty_state/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:empty_state)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:empty_state)}
          states={with_lab_state(DevLab.Fixtures.states_for(:empty_state, :review_queue_empty))}
        >
          <:render :let={fixture}>
            <.empty_state title={empty_state_title(fixture)}>{empty_state_body(fixture)}</.empty_state>
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "skeleton")}>
        <:eyebrow>Skeletons</:eyebrow>
        <:title>ScoriaWeb.UI.skeleton/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:skeleton)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:skeleton)}
          states={with_lab_state(DevLab.Fixtures.states_for(:skeleton, :workflow_waiting_for_approval))}
        >
          <:render :let={fixture}>
            <.skeleton rows={skeleton_rows(fixture)} />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "id")}>
        <:eyebrow>IDs</:eyebrow>
        <:title>ScoriaWeb.UI.id/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:id)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:id)}
          states={with_lab_state(DevLab.Fixtures.states_for(:id, :approval_requested))}
        >
          <:render :let={fixture}>
            <.id id={specimen_id("id-chip", fixture)} value={fixture.approval_id} copy={fixture.approval_id} />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "time")}>
        <:eyebrow>Timestamps</:eyebrow>
        <:title>ScoriaWeb.UI.time/1</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:time)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:time)}
          states={with_lab_state(DevLab.Fixtures.states_for(:time, :incident_opened))}
        >
          <:render :let={fixture}>
            <.time at={time_specimen_at(fixture)} mode={time_specimen_mode(fixture)} fallback="Not recorded" />
          </:render>
        </.states_band>
      </.panel>
    </.page_section>
    """
  end

  # ---------------------------------------------------------------------
  # Deep-link filter (D-07 IA — /scoria/_lab/primitives/:item wiring lands
  # in Plan 05; this predicate is the seam that route uses).
  # ---------------------------------------------------------------------
  defp show?(nil, _key), do: true
  defp show?(item, key), do: item == key

  # ---------------------------------------------------------------------
  # D-12: every specimen below resolves color EXCLUSIVELY through
  # DevLab.Sections.States.state_tone/1, fed by the lab-state atom this
  # helper embeds into each derived fixture. Never a literal D-11 state
  # atom written directly into a `tone` attr.
  # ---------------------------------------------------------------------
  defp with_lab_state(states) do
    for {state, fixture} <- states, do: {state, Map.put(fixture, :lab_state, state)}
  end

  defp specimen_id(prefix, fixture), do: "lab-#{prefix}-#{fixture.lab_state}"

  defp button_variant(%{lab_state: state}) when state in [:danger, :error], do: :danger
  defp button_variant(_fixture), do: :primary

  # <.toast> only accepts :pass/:fail/:warn/:info/:neutral (no :brand/:trace) —
  # clamp the :selected state's :brand tone down to :info rather than pass an
  # out-of-range value. Still routed exclusively through state_tone/1.
  defp toast_tone(fixture) do
    case DevLab.Sections.States.state_tone(fixture.lab_state) do
      :brand -> :info
      other -> other
    end
  end

  defp toast_message(%{lab_state: :empty}), do: "No fixture rows for this state."

  defp toast_message(fixture),
    do: "#{ScoriaWeb.UI.status_label(fixture.status)}: #{fixture.summary}"

  defp notebook_rows(fixture) do
    fixture
    |> Map.take([:approval_id, :trace_id, :actor_id, :policy_name, :reason, :status])
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)
  end

  defp empty_state_title(%{lab_state: :loading}), do: "Loading records…"
  defp empty_state_title(%{lab_state: :error}), do: "Records failed to load"
  defp empty_state_title(_fixture), do: "No records found"

  defp empty_state_body(fixture) do
    case Map.get(fixture, :empty_copy) do
      copy when copy in [nil, ""] -> "No fixture rows for this state."
      copy -> copy
    end
  end

  defp skeleton_rows(%{lab_state: :dense}), do: 8
  defp skeleton_rows(_fixture), do: 3

  @demo_time ~U[2026-07-02 12:00:00Z]

  defp time_specimen_at(%{lab_state: :empty}), do: nil
  defp time_specimen_at(_fixture), do: @demo_time

  defp time_specimen_mode(%{lab_state: :loading}), do: :elapsed
  defp time_specimen_mode(_fixture), do: :absolute

  # Bare checkmark — the only icon this module authors. Same currentColor,
  # no-hex, no-phoenix-bird/flame shape already used by ScoriaWeb.UI's own
  # copy-confirmation icon (D-26).
  defp lab_check_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path
        fill-rule="evenodd"
        d="M13.78 4.22a.75.75 0 0 1 0 1.06l-6.25 6.25a.75.75 0 0 1-1.06 0L3.22 8.28a.75.75 0 1 1 1.06-1.06L7 9.94l5.72-5.72a.75.75 0 0 1 1.06 0Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end
end
