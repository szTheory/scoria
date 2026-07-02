defmodule DevLab.Sections.FixturesView do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Fixtures` IA section (D-07): a browser/inspector for the fixture
  catalog itself (D-27 "Open fixture matrix" secondary command). A
  contributor can find the canonical fixture example for a domain without
  reverse-engineering older pages (D-23), and inspect each scenario's raw
  payload as evidence (D-29) before reusing it in a new lab specimen.

  Lists all 15 D-20/D-19 `DevLab.Fixtures.scenario/1` scenarios, grouped by
  domain (approvals, incidents, reviews, datasets, workflow, connectors,
  prompts, evals). Reuses the existing evidence-notebook group —
  `raw_evidence/1` / `notebook/1` / `evidence_section/1`, default
  `open: false` — for progressive-disclosure raw payload inspection; no new
  disclosure widget is introduced here (D-28: hide backend guts from
  primary orientation, expose them only as evidence).

  Two locked D-27 copy contracts live in this module as source-verbatim
  module attributes (`@fixture_empty_copy`, `@fixture_error_copy`) so the
  exact strings are grep-able here even when a scenario's :rows already
  carries its own matching `empty_copy` (the three `_empty` scenarios in
  `DevLab.Fixtures`) or when the defensive render-failure path prepends a
  component/fixture detail ahead of the locked error wrapper.
  """

  use Phoenix.Component
  import ScoriaWeb.UI

  @fixture_empty_copy "No fixture rows for this state. Add deterministic dev fixture data before using this state for proof."
  @fixture_error_copy "Lab fixture failed to render. Check the fixture builder and component attrs before changing runtime UI."

  @domain_labels %{
    approvals: "Approvals",
    incidents: "Incidents",
    reviews: "Reviews",
    datasets: "Datasets",
    workflow: "Workflow detail",
    connectors: "Connectors",
    prompts: "Prompts",
    evals: "Evals"
  }

  attr(:item, :string, default: nil)
  attr(:class, :string, default: nil)

  @doc """
  Renders the `Fixtures` IA section. When `item` is set (deep link via
  `/scoria/_lab/fixtures/:item`), only the matching scenario renders;
  otherwise every domain and every scenario in it renders.
  """
  def fixtures_view(assigns) do
    assigns = assign(assigns, :domains, DevLab.Fixtures.domains())

    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Fixtures</:eyebrow>
      <:title>Fixture Matrix</:title>
      <:description>
        Every Component Lab fixture scenario, grouped by domain — reachable
        via the "Open fixture matrix" secondary command. Inspect each
        scenario's raw payload as evidence before reusing it in a new
        specimen.
      </:description>

      <.panel :for={domain <- @domains} :if={visible_domain?(@item, domain)}>
        <:eyebrow>{domain_label(domain)}</:eyebrow>
        <:title>{domain_label(domain)} fixtures</:title>
        <.scenario_specimen
          :for={scenario_name <- DevLab.Fixtures.scenarios_for_domain(domain)}
          :if={show_scenario?(@item, scenario_name)}
          name={scenario_name}
        />
      </.panel>
    </.page_section>
    """
  end

  attr(:name, :atom, required: true)

  defp scenario_specimen(assigns) do
    assigns = assign(assigns, :result, scenario_result(assigns.name))

    ~H"""
    <div class="scoria-lab-fixture-specimen" data-fixture-scenario={@name}>
      <%= case @result do %>
        <% {:ok, fixture} -> %>
          <.notebook
            id={"lab-fixture-" <> Atom.to_string(@name)}
            title={fixture_title(@name)}
            eyebrow={to_string(Map.get(fixture, :domain, "fixture"))}
            empty={fixture_empty?(fixture)}
          >
            <:tab key="evidence" label="Technical evidence">
              <.evidence_section
                title="Fixture payload"
                description={"fixture_source: " <> to_string(Map.get(fixture, :fixture_source, "DevLab.Fixtures"))}
              >
                <div class="scoria-lab-fixture-refs">
                  <.id
                    :for={ref <- Map.get(fixture, :inventory_refs, [])}
                    value={ref}
                    title="Inventory / risk reference"
                  />
                </div>
                <.raw_evidence
                  label="Raw fixture payload"
                  value={inspect(fixture, pretty: true, limit: :infinity, printable_limit: :infinity)}
                  open={false}
                  copyable
                  copy_label="Copy fixture payload"
                />
              </.evidence_section>
            </:tab>
            <:empty_slot>
              <.empty_state title="No fixture rows for this state">
                {fixture_empty_copy(fixture)}
              </.empty_state>
            </:empty_slot>
          </.notebook>

        <% {:error, message} -> %>
          <.evidence_section title={fixture_title(@name)} tone={:fail} badge="Fixture error">
            <.empty_state title="Fixture error">{message}</.empty_state>
          </.evidence_section>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------
  # Deep-link filter (D-07 IA — /scoria/_lab/fixtures/:item wiring lands in
  # Plan 05; these predicates are the seam that route uses). `item` matches
  # a scenario name (e.g. "approval_requested"), not a domain.
  # ---------------------------------------------------------------------
  defp show_scenario?(nil, _name), do: true
  defp show_scenario?(item, name), do: item == Atom.to_string(name)

  defp visible_domain?(nil, _domain), do: true

  defp visible_domain?(item, domain) do
    Enum.any?(DevLab.Fixtures.scenarios_for_domain(domain), &(Atom.to_string(&1) == item))
  end

  defp domain_label(domain), do: Map.get(@domain_labels, domain, to_string(domain))

  defp fixture_title(name), do: name |> Atom.to_string() |> String.replace("_", " ")

  # `_empty` scenarios (review_queue_empty/dataset_empty/prompt_registry_empty)
  # carry rows: [] plus their own :empty_copy already equal to the locked
  # D-27 body — this predicate is the structural signal, never a lab-state
  # atom.
  defp fixture_empty?(fixture), do: Map.get(fixture, :rows) == []

  defp fixture_empty_copy(fixture) do
    case Map.get(fixture, :empty_copy) do
      copy when copy in [nil, ""] -> @fixture_empty_copy
      copy -> copy
    end
  end

  # ---------------------------------------------------------------------
  # Defensive render-failure path (D-27 error copy). DevLab.Fixtures.scenario/1
  # is deterministic and every atom below comes from DevLab.Fixtures.scenario_names/0,
  # so this practically never raises — the guard still exists so a future
  # broken scenario clause fails gracefully inside this one specimen instead
  # of crashing the whole /scoria/_lab page (D-32/Rule 2).
  # ---------------------------------------------------------------------
  defp scenario_result(scenario_name) do
    {:ok, DevLab.Fixtures.scenario(scenario_name)}
  rescue
    exception -> {:error, fixture_error_message(scenario_name, exception)}
  end

  defp fixture_error_message(scenario_name, exception) do
    module_name = exception.__struct__ |> Module.split() |> List.last()
    detail = "DevLab.Fixtures.scenario(:#{scenario_name}) / #{module_name}"

    String.replace(
      @fixture_error_copy,
      "Lab fixture failed to render.",
      "Lab fixture failed to render: #{detail}."
    )
  end
end
