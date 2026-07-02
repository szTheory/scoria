defmodule DevLab.Sections.Groups do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`). Never
  referenced from `lib/` (D-21 — enforced by
  `test/scoria_web/dev_lab_boundary_test.exs`).

  The `Groups` IA section (D-07): recurring `lib/scoria_web/components/*.ex`
  dashboard component groups, each rendered across all ten D-11 states via
  `DevLab.Sections.States.states_band/1`, anchored to its Phase-36 `GROUP-*`
  inventory ID (D-08). This is the maintainer's "specimen under stress" bench
  (D-25) for whole recurring groups (not single primitives — see
  `DevLab.Sections.Primitives`) before Phase 38 changes any shared control.

  Covers, at minimum (D-09): the approval inbox, workflow tree, workflow
  detail, connector drawer, and incident evidence groups. The evidence
  notebook groups (`GROUP-REPLAY-EVIDENCE-NOTEBOOK-COMPONENT` /
  `GROUP-SEMANTIC-EVIDENCE-NOTEBOOK-COMPONENT`) are covered here too — they
  render organically nested inside the real `WorkflowDetailPanelComponent`,
  matching production composition rather than re-mounting them in isolation.

  Per D-10 (curated-scope boundary): this module renders the real
  `lib/scoria_web/components/*.ex` group modules against derived fixture
  data, not a second dashboard page. Full page-flow probes (dense approvals
  with toast overlay, table/list mobile summaries, drawer/modal focus,
  command palette, mobile nav) belong to the `Overlays` IA section (Plan 04),
  not here.

  Every group below is fed by `DevLab.Fixtures.states_for/2` on ONE base
  domain-noun scenario (the same "reusable stress-scenario band" convention
  `DevLab.Sections.Primitives` established) — never a hand-authored 15x10
  matrix. Browsing every scenario (both the "normal" and "empty/error"
  variant per domain) is the `Fixtures` IA section's job
  (`DevLab.Sections.FixturesView`, this same plan), not this module's.

  Tone is never a literal D-11 state atom passed into a `tone` attr here:
  every group below delegates entirely to the REAL `lib/scoria_web/
  components/*.ex` module, which already resolves its own domain-status tone
  via `ScoriaWeb.UI.tone/1` on real domain status strings (not a lab-state
  atom) — this module never calls `state_tone/1` or `tone/1` itself.

  Known, documented (not fixed) limitation: `ScoriaWeb.ApprovalInboxComponent`
  hardcodes its own `<.table id="approvals">` DOM id internally (no caller
  override). Stacking the real component across all ten state rows means
  that id repeats ten times on the page — invalid HTML, but functionally
  inert here (no JS hook/selector keys off that id). Fixing it would mean
  editing `lib/`, out of this dev-only phase's `files_modified` boundary;
  logged here rather than silently accepted.
  """

  use Phoenix.Component
  import ScoriaWeb.UI
  import DevLab.Sections.States, only: [states_band: 1]

  alias ScoriaWeb.ApprovalInboxComponent
  alias ScoriaWeb.ConnectorDetailDrawerComponent
  alias ScoriaWeb.IncidentEvidenceComponent
  alias ScoriaWeb.WorkflowDetailPanelComponent
  alias ScoriaWeb.WorkflowTreeComponent

  attr(:item, :string, default: nil)
  attr(:class, :string, default: nil)

  @doc """
  Renders the `Groups` IA section. When `item` is set (deep link via
  `/scoria/_lab/groups/:item`), only that group's panel renders; otherwise
  every canonical group renders.
  """
  def groups(assigns) do
    ~H"""
    <.page_section class={@class}>
      <:eyebrow>Groups</:eyebrow>
      <:title>Component Groups</:title>
      <:description>
        Recurring dashboard component groups, rendered across all ten D-11
        states and anchored to their Phase-36 GROUP-* inventory ID. Curated
        scope only (D-10) — full page-flow probes live in the Overlays
        section.
      </:description>

      <.panel :if={show?(@item, "approval_inbox")}>
        <:eyebrow>Approval Inbox</:eyebrow>
        <:title>ScoriaWeb.ApprovalInboxComponent</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:approval_inbox)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:approval_inbox)}
          states={with_lab_state(DevLab.Fixtures.states_for(:approval_inbox, :approval_requested))}
        >
          <:render :let={fixture}>
            <ApprovalInboxComponent.render approvals={[approval_inbox_fixture(fixture)]} />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "workflow_tree")}>
        <:eyebrow>Workflow Tree</:eyebrow>
        <:title>ScoriaWeb.WorkflowTreeComponent</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:workflow_tree)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:workflow_tree)}
          states={with_lab_state(DevLab.Fixtures.states_for(:workflow_tree, :workflow_waiting_for_approval))}
        >
          <:render :let={fixture}>
            <WorkflowTreeComponent.workflow_tree
              steps={workflow_tree_steps(fixture)}
              selected_step_id={workflow_tree_selected_id(fixture)}
            />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "workflow_detail_panel")}>
        <:eyebrow>Workflow Detail</:eyebrow>
        <:title>ScoriaWeb.WorkflowDetailPanelComponent</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:workflow_detail_panel)} /></:actions>
        <p class="scoria-page-section__description">
          Also exercises the evidence notebook groups it composes:
          <.id value={DevLab.Fixtures.inventory_id(:replay_evidence_notebook)} />
          and
          <.id value={DevLab.Fixtures.inventory_id(:semantic_evidence_notebook)} />
          — rendered nested here rather than mounted a second time in isolation.
        </p>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:workflow_detail_panel)}
          states={with_lab_state(DevLab.Fixtures.states_for(:workflow_detail_panel, :workflow_failed_step))}
        >
          <:render :let={fixture}>
            <WorkflowDetailPanelComponent.workflow_detail_panel
              step={workflow_detail_step(fixture)}
              comparison={%{}}
              semantic_evidence={%{}}
              selected_source_variant="original"
            />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "connector_detail_drawer")}>
        <:eyebrow>Connector Drawer</:eyebrow>
        <:title>ScoriaWeb.ConnectorDetailDrawerComponent</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:connector_detail_drawer)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:connector_detail_drawer)}
          states={with_lab_state(DevLab.Fixtures.states_for(:connector_detail_drawer, :connector_degraded))}
        >
          <:render :let={fixture}>
            <ConnectorDetailDrawerComponent.render drawer={connector_drawer_fixture(fixture)} />
          </:render>
        </.states_band>
      </.panel>

      <.panel :if={show?(@item, "incident_evidence")}>
        <:eyebrow>Incident Evidence</:eyebrow>
        <:title>ScoriaWeb.IncidentEvidenceComponent</:title>
        <:actions><.id value={DevLab.Fixtures.inventory_id(:incident_evidence)} /></:actions>
        <.states_band
          inventory_id={DevLab.Fixtures.inventory_id(:incident_evidence)}
          states={with_lab_state(DevLab.Fixtures.states_for(:incident_evidence, :incident_opened))}
        >
          <:render :let={fixture}>
            <IncidentEvidenceComponent.render evidence={incident_evidence_fixture(fixture)} />
          </:render>
        </.states_band>
      </.panel>
    </.page_section>
    """
  end

  # ---------------------------------------------------------------------
  # Deep-link filter (D-07 IA — /scoria/_lab/groups/:item wiring lands in
  # Plan 05; this predicate is the seam that route uses). Keys match the
  # exact DevLab.Fixtures.inventory_id/1 atom names for consistency.
  # ---------------------------------------------------------------------
  defp show?(nil, _key), do: true
  defp show?(item, key), do: item == key

  # ---------------------------------------------------------------------
  # D-12: never a literal D-11 state atom written directly into a `tone`
  # attr. This module never resolves tone itself (every group below
  # delegates entirely to the real lib/ component's own domain-status tone
  # logic) — with_lab_state/1 exists only so per-specimen adapter helpers
  # below can branch on the current row's state (e.g. to select which
  # workflow-tree row is "selected", never to derive a color).
  # ---------------------------------------------------------------------
  defp with_lab_state(states) do
    for {state, fixture} <- states, do: {state, Map.put(fixture, :lab_state, state)}
  end

  @demo_time ~U[2026-07-02 12:00:00Z]

  # -- Approval inbox -----------------------------------------------------
  # ApprovalInboxComponent reads via ScoriaWeb.ApprovalCopy.field/2 (graceful
  # Map.get, nil-safe) — only :id/:inserted_at/:workflow_run_id are added
  # here because the base scenario has no schema-shaped equivalents, and
  # leaving :id unset would make ApprovalCopy.field(approval, :id) == nil
  # coincidentally equal the default nil highlight_approval_id.
  defp approval_inbox_fixture(fixture) do
    fixture
    |> Map.put(:id, Map.get(fixture, :approval_id))
    |> Map.put(:inserted_at, @demo_time)
    |> Map.put(:workflow_run_id, "run-3390")
    |> Map.put_new(:arguments_preview, %{
      "ticket_id" => "tick-4471",
      "amount_cents" => 5200,
      "customer" => "acme-support"
    })
  end

  # -- Workflow tree --------------------------------------------------------
  # WorkflowTreeComponent needs a `steps` list (not a single scenario
  # record) — build a short deterministic lineage that culminates in the
  # derived fixture's own step_name/status, so long_text/empty/dense stress
  # on the base scenario is visible on the tree's final row.
  defp workflow_tree_steps(fixture) do
    step_name = Map.get(fixture, :step_name, "step")
    status = Map.get(fixture, :status, "waiting_for_approval")

    [
      %{id: "step-plan", kind: "prompt", status: "completed", role_id: "assistant", depth: 0},
      %{id: "step-tool", kind: "tool", status: "completed", role_id: "issue_refund", depth: 1},
      %{id: "step-current", kind: workflow_step_kind(step_name), status: status, role_id: step_name, depth: 1}
    ]
  end

  defp workflow_step_kind("wait_for_approval"), do: "approval"
  defp workflow_step_kind(_step_name), do: "tool"

  defp workflow_tree_selected_id(%{lab_state: :selected}), do: "step-current"
  defp workflow_tree_selected_id(_fixture), do: nil

  # -- Workflow detail panel ------------------------------------------------
  # WorkflowDetailPanelComponent's other attrs (checkpoint/comparison/
  # semantic_evidence/promotion_context) already default to nil/%{} and
  # render their own "no evidence" empty states — no adapter needed there.
  defp workflow_detail_step(fixture) do
    %{
      id: Map.get(fixture, :run_id, "run-unknown"),
      role_id: Map.get(fixture, :step_name, "step"),
      kind: "tool"
    }
  end

  # -- Connector drawer -----------------------------------------------------
  defp connector_drawer_fixture(fixture) do
    connector_key = Map.get(fixture, :connector_key, "connector")

    %{
      endpoint_url: "https://connectors.acme-corp.internal/#{connector_key}",
      status: Map.get(fixture, :status, "degraded"),
      health_state: connector_health_state(fixture),
      last_refresh_status: connector_refresh_status(fixture),
      transport_kind: "mcp/http",
      auth_mode: "oauth2_client_credentials"
    }
  end

  defp connector_health_state(%{lab_state: state}) when state in [:danger, :error], do: "unhealthy"
  defp connector_health_state(_fixture), do: "degraded"

  defp connector_refresh_status(%{lab_state: :loading}), do: "refreshing"
  defp connector_refresh_status(_fixture), do: "ok"

  # -- Incident evidence ------------------------------------------------------
  # IncidentEvidenceComponent expects a fully-hydrated nested evidence map
  # (health_rollup/budget/breaker/incidents/audit_rows/deliveries) with no
  # graceful nil-default path — every key below is deterministic, literal,
  # domain-realistic filler for the sub-fields the base incident scenario
  # does not itself carry (D-17: no randomness, same input -> same output).
  defp incident_evidence_fixture(fixture) do
    incident_id = Map.get(fixture, :incident_id, "inc-unknown")
    trace_id = Map.get(fixture, :trace_id, "trace-unknown")
    status = fixture |> Map.get(:status, "opened") |> to_string()
    severity = fixture |> Map.get(:severity, "warning") |> to_string()
    summary = Map.get(fixture, :summary, "Incident summary not recorded")
    escalated? = status == "escalated"

    %{
      trace_id: trace_id,
      run_id: "run-" <> incident_id,
      health_rollup: %{
        review_count: if(escalated?, do: 0, else: 1),
        page_count: if(escalated?, do: 1, else: 0),
        budget_signal: "Budget nominal",
        budget_detail: "Reservation stays within the connector's tenant budget ceiling.",
        breaker_signal: if(escalated?, do: "Breaker open", else: "Breaker closed"),
        breaker_detail: "See breaker evidence below for reason code and integration kind.",
        relay_signal: "Relay healthy",
        relay_detail: "Audit and delivery evidence is listed below."
      },
      budget: %{
        status: "pass",
        status_label: "Within budget",
        actuals: "$0.42 spent of $5.00 reserved",
        policy_key: "connector.billing.budget-ceiling.v1",
        reason_code: "n/a",
        provider_ref: "billing_connector",
        tool_ref: "connector_lookup"
      },
      breaker: %{
        state: if(escalated?, do: "open", else: "closed"),
        state_label: if(escalated?, do: "Open", else: "Closed"),
        reason_code: "connector_timeout",
        integration_kind: "mcp",
        breaker_key: "billing_connector.breaker"
      },
      incidents: [
        %{
          summary: summary,
          reason_code: "latency_sla_exceeded",
          routing_label: if(escalated?, do: "Paged", else: "Review queue"),
          routing_class: if(escalated?, do: "page", else: "review"),
          severity_label: String.capitalize(severity),
          scorer_version: "n/a",
          baseline_version: "n/a",
          incident_key: incident_id,
          trace_id: trace_id,
          run_id: "run-" <> incident_id,
          approval_id: nil
        }
      ],
      audit_rows: [],
      deliveries: []
    }
  end
end
