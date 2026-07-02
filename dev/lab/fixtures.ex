defmodule DevLab.Fixtures do
  @moduledoc """
  Dev-only (`:dev` env only — see `elixirc_paths/1` in `mix.exs`), deterministic,
  reset-free fixture catalog for the Component Lab.

  This module must NEVER be referenced from any module under `lib/` — that
  boundary is enforced structurally (a `lib/ -> DevLab.Fixtures` reference is a
  compile error under `:test`/an adopter build, since `elixirc_paths(:test)` and
  the shipped Hex package never include `dev/`) and proven by
  `test/scoria_web/dev_lab_boundary_test.exs` (D-21).

  Deterministic and reset-free: no `Scoria.Repo`/`Ecto.Query` read, no PubSub,
  and no nondeterministic call (`DateTime.utc_now/0`, `NaiveDateTime.utc_now/0`,
  `Ecto.UUID.generate/0`, `System.unique_integer/0`, `:rand.*`,
  `Enum.random/1`) anywhere in this file — every scenario is a pure literal-data
  read so the lab renders identically on every boot (D-17).

  Two separate responsibilities, on purpose (D-06 spine mechanism — never a
  hand-authored 15x10 fixture matrix):

    * `scenario/1` — one realistic HEEx-safe record per D-20/D-19 domain-noun
      scenario name (15 total: every domain gets a normal AND an empty/error
      scenario).
    * `states_for/2` — a GENERIC transform that derives all ten canonical
      D-11 states (`normal`, `long_text`, `empty`, `dense`, `disabled`,
      `selected`, `loading`, `warning`, `danger`, `error`) from a single
      `scenario/1` record by walking its map/list/string structure. Adding a
      new `scenario/1` clause never requires hand-writing its ten state
      variants — they fall out of the same structural transform.

  Fixture maps carry domain-truth fields ONLY — never a `:tone` key (D-12).
  Visual tone is always derived at render time: `DevLab.Sections.States.state_tone/1`
  for lab-state chrome, or `ScoriaWeb.UI.tone/1` (on real domain-status
  strings, never on a lab-state atom) for domain-status badges. This module
  never calls `ScoriaWeb.UI.tone/1`.

  Any future bulky JSON fixture payload belongs under `priv/dev/lab_fixtures`
  (declared via `@external_resource`) — never under the Hex-shipped
  `priv/fixtures` directory (see `mix.exs` `package/0`). Full rationale in
  `priv/dev/lab_fixtures/README.md`. This module currently needs no such
  file; every scenario below is a plain literal map.
  """

  @states ~w(normal long_text empty dense disabled selected loading warning danger error)a

  @doc "The ten canonical D-11 lab states, in fixed display order."
  def states, do: @states

  # ---------------------------------------------------------------------
  # D-08 inventory coverage anchors: canonical PRIM-*/GROUP-* row IDs from
  # 36-inventory.json, mapped to the primitive/group atom the corresponding
  # lab section renders. This map is the single source of truth the
  # `Primitives`/`Groups` sections (later plans in this phase) read
  # `inventory_id/1` from for their `states_band/1` `inventory_id` attr, and
  # it is also the literal-string anchor
  # `test/scoria_web/dev_lab_boundary_test.exs` guard #7 scans for (a
  # coverage FLOOR — string presence, not proof every primitive/group
  # actually renders every state; see 37-VALIDATION.md for the
  # complementary manual walkthrough).
  # ---------------------------------------------------------------------
  @inventory_ids %{
    attention_card: "PRIM-ATTENTION-CARD",
    badge: "PRIM-BADGE",
    button: "PRIM-BUTTON",
    command_palette: "PRIM-COMMAND-PALETTE",
    drawer: "PRIM-DRAWER",
    empty_state: "PRIM-EMPTY-STATE",
    evidence_action_row: "PRIM-EVIDENCE-ACTION-ROW",
    evidence_empty: "PRIM-EVIDENCE-EMPTY",
    evidence_rows: "PRIM-EVIDENCE-ROWS",
    evidence_section: "PRIM-EVIDENCE-SECTION",
    eyebrow: "PRIM-EYEBROW",
    field: "PRIM-FIELD",
    flash_group: "PRIM-FLASH-GROUP",
    form_section: "PRIM-FORM-SECTION",
    icon_button: "PRIM-ICON-BUTTON",
    id: "PRIM-ID",
    kbd: "PRIM-KBD",
    modal: "PRIM-MODAL",
    notebook: "PRIM-NOTEBOOK",
    object_header: "PRIM-OBJECT-HEADER",
    overview_stats: "PRIM-OVERVIEW-STATS",
    page_section: "PRIM-PAGE-SECTION",
    panel: "PRIM-PANEL",
    raw_evidence: "PRIM-RAW-EVIDENCE",
    selectable_card: "PRIM-SELECTABLE-CARD",
    skeleton: "PRIM-SKELETON",
    status_label: "PRIM-STATUS-LABEL",
    stub_page: "PRIM-STUB-PAGE",
    table: "PRIM-TABLE",
    time: "PRIM-TIME",
    toast: "PRIM-TOAST",
    tone: "PRIM-TONE",
    approval_inbox: "GROUP-APPROVAL-INBOX-COMPONENT",
    citation_evidence: "GROUP-CITATION-EVIDENCE-COMPONENT",
    connector_detail_drawer: "GROUP-CONNECTOR-DETAIL-DRAWER-COMPONENT",
    delegated_evidence: "GROUP-DELEGATED-EVIDENCE-COMPONENT",
    incident_evidence: "GROUP-INCIDENT-EVIDENCE-COMPONENT",
    layouts: "GROUP-LAYOUTS",
    memory_notebook: "GROUP-MEMORY-NOTEBOOK-COMPONENT",
    remote_invocation_evidence: "GROUP-REMOTE-INVOCATION-EVIDENCE-COMPONENT",
    replay_evidence_notebook: "GROUP-REPLAY-EVIDENCE-NOTEBOOK-COMPONENT",
    runtime_detail_drawer: "GROUP-RUNTIME-DETAIL-DRAWER-COMPONENT",
    semantic_evidence_notebook: "GROUP-SEMANTIC-EVIDENCE-NOTEBOOK-COMPONENT",
    trace_tree: "GROUP-TRACE-TREE-COMPONENT",
    workflow_detail_panel: "GROUP-WORKFLOW-DETAIL-PANEL-COMPONENT",
    workflow_tree: "GROUP-WORKFLOW-TREE-COMPONENT"
  }

  @doc "Canonical `PRIM-*`/`GROUP-*` inventory ID for a primitive/group atom (D-08)."
  def inventory_id(key), do: Map.fetch!(@inventory_ids, key)

  @doc "Every primitive/group atom with a canonical inventory ID (D-08 coverage anchors)."
  def inventory_keys, do: Map.keys(@inventory_ids)

  @fixture_source "DevLab.Fixtures"
  @tenant_id "acme-corp"

  # ---------------------------------------------------------------------
  # scenario/1 — one realistic record per D-20/D-19 domain-noun scenario
  # (15 clauses: every domain gets a normal AND an empty/error scenario).
  # ---------------------------------------------------------------------

  def scenario(:approval_requested) do
    %{
      scenario: :approval_requested,
      domain: :approvals,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "support-agent-1",
      session_id: "support-session-42",
      approval_id: "appr-2f9c1a7e4d6b4180ae0f5c9d3b7a1e08c4f6d2a1b3c5e7f901234567890abcd",
      status: "approval_requested",
      tool_name: "issue_refund",
      policy_name: "billing.refund.duplicate-charge-review.tenant-acme-corp.v2026-07-02-r14",
      reason: "Refund requires operator approval (duplicate-charge review)",
      trace_id: "trace-approval-req-001",
      inventory_refs: [inventory_id(:approval_inbox), inventory_id(:badge)]
    }
  end

  def scenario(:approval_denied) do
    %{
      scenario: :approval_denied,
      domain: :approvals,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      session_id: "support-session-42",
      approval_id: "appr-9b1d4e2a",
      status: "denied",
      tool_name: "issue_refund",
      policy_name: "billing.refund.v2",
      reason: "Refund amount exceeds tenant policy ceiling",
      trace_id: "trace-approval-req-002",
      inventory_refs: [inventory_id(:approval_inbox), inventory_id(:badge)]
    }
  end

  def scenario(:incident_opened) do
    %{
      scenario: :incident_opened,
      domain: :incidents,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      incident_id: "inc-4471",
      status: "opened",
      severity: "warning",
      summary: "Tool call latency exceeded SLA on billing_connector",
      trace_id: "trace-incident-4471",
      inventory_refs: [inventory_id(:incident_evidence), inventory_id(:badge)]
    }
  end

  def scenario(:incident_escalated) do
    %{
      scenario: :incident_escalated,
      domain: :incidents,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      incident_id: "inc-4471",
      status: "escalated",
      severity: "danger",
      summary: "Repeated timeout on connector_lookup for Billing MCP",
      trace_id: "trace-incident-4471",
      inventory_refs: [inventory_id(:incident_evidence), inventory_id(:badge)]
    }
  end

  def scenario(:review_candidate_flagged) do
    %{
      scenario: :review_candidate_flagged,
      domain: :reviews,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      review_id: "rev-8821",
      status: "flagged",
      run_id: "run-3390",
      reason: "Online score below promotion threshold",
      trace_id: "trace-review-8821",
      inventory_refs: [inventory_id(:table), inventory_id(:badge)]
    }
  end

  def scenario(:review_queue_empty) do
    %{
      scenario: :review_queue_empty,
      domain: :reviews,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      status: "empty",
      rows: [],
      empty_copy:
        "No fixture rows for this state. Add deterministic dev fixture data before using this state for proof.",
      inventory_refs: [inventory_id(:empty_state), inventory_id(:table)]
    }
  end

  def scenario(:dataset_promoted) do
    %{
      scenario: :dataset_promoted,
      domain: :datasets,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      dataset_id: "ds-refund-eligibility-v3",
      status: "promoted",
      version_name: "refund-eligibility-baseline-v3.2026-07-02",
      row_count: 128,
      rows: [
        %{id: "row-001", input: "duplicate charge on card ending 4471", label: "eligible"},
        %{id: "row-002", input: "downgrade refund request", label: "ineligible"},
        %{id: "row-003", input: "chargeback dispute", label: "needs_review"}
      ],
      trace_id: "trace-dataset-promote-001",
      inventory_refs: [inventory_id(:table), inventory_id(:badge)]
    }
  end

  def scenario(:dataset_empty) do
    %{
      scenario: :dataset_empty,
      domain: :datasets,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      status: "empty",
      rows: [],
      empty_copy:
        "No fixture rows for this state. Add deterministic dev fixture data before using this state for proof.",
      inventory_refs: [inventory_id(:empty_state), inventory_id(:table)]
    }
  end

  def scenario(:workflow_waiting_for_approval) do
    %{
      scenario: :workflow_waiting_for_approval,
      domain: :workflow,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "support-agent-1",
      run_id: "run-3390",
      status: "waiting_for_approval",
      step_name: "wait_for_approval",
      trace_id: "trace-run-3390",
      inventory_refs: [inventory_id(:workflow_tree), inventory_id(:workflow_detail_panel)]
    }
  end

  def scenario(:workflow_failed_step) do
    %{
      scenario: :workflow_failed_step,
      domain: :workflow,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "support-agent-1",
      run_id: "run-3391",
      status: "failed",
      step_name: "connector_lookup",
      reason: "Connector timeout after 3 retries",
      trace_id: "trace-run-3391",
      inventory_refs: [inventory_id(:workflow_tree), inventory_id(:workflow_detail_panel)]
    }
  end

  def scenario(:connector_degraded) do
    %{
      scenario: :connector_degraded,
      domain: :connectors,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      connector_key: "billing",
      connector_label: "Billing MCP",
      status: "degraded",
      reason: "Elevated latency over the last 15 minutes",
      trace_id: "trace-connector-billing-001",
      inventory_refs: [inventory_id(:connector_detail_drawer), inventory_id(:badge)]
    }
  end

  def scenario(:connector_scope_blocked) do
    %{
      scenario: :connector_scope_blocked,
      domain: :connectors,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      connector_key: "billing",
      connector_label: "Billing MCP",
      status: "scope_blocked",
      reason: "Requested scope exceeds granted tool policy",
      trace_id: "trace-connector-billing-002",
      inventory_refs: [inventory_id(:connector_detail_drawer), inventory_id(:badge)]
    }
  end

  def scenario(:prompt_release_blocked) do
    %{
      scenario: :prompt_release_blocked,
      domain: :prompts,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      prompt_id: "prompt-refund-explainer",
      version_name: "refund-explainer.v2026-07-02-rc1",
      status: "release_blocked",
      reason: "Awaiting eval regression sign-off",
      trace_id: "trace-prompt-release-001",
      inventory_refs: [inventory_id(:table), inventory_id(:badge)]
    }
  end

  def scenario(:prompt_registry_empty) do
    %{
      scenario: :prompt_registry_empty,
      domain: :prompts,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      status: "empty",
      rows: [],
      empty_copy:
        "No fixture rows for this state. Add deterministic dev fixture data before using this state for proof.",
      inventory_refs: [inventory_id(:empty_state), inventory_id(:table)]
    }
  end

  def scenario(:eval_regression_detected) do
    %{
      scenario: :eval_regression_detected,
      domain: :evals,
      fixture_source: @fixture_source,
      tenant_id: @tenant_id,
      actor_id: "ops-lead-7",
      eval_spec_id: "eval-refund-explainer-accuracy",
      run_id: "run-eval-4471",
      status: "regression_detected",
      reason: "Accuracy dropped 8pts vs baseline",
      trace_id: "trace-eval-4471",
      inventory_refs: [inventory_id(:table), inventory_id(:badge)]
    }
  end

  @scenario_names ~w(
    approval_requested approval_denied
    incident_opened incident_escalated
    review_candidate_flagged review_queue_empty
    dataset_promoted dataset_empty
    workflow_waiting_for_approval workflow_failed_step
    connector_degraded connector_scope_blocked
    prompt_release_blocked prompt_registry_empty
    eval_regression_detected
  )a

  @doc "All 15 D-20/D-19 scenario names, in the order they were introduced."
  def scenario_names, do: @scenario_names

  @doc "Fixture scenario names for a given D-19 domain (e.g. `:approvals`)."
  def scenarios_for_domain(domain) do
    for name <- @scenario_names, scenario(name).domain == domain, do: name
  end

  @doc "Facade: every scenario as `{name, fixture}` pairs."
  def scenarios, do: for(name <- @scenario_names, do: {name, scenario(name)})

  @doc "Facade: every D-19 domain covered by the fixture catalog."
  def domains, do: @scenario_names |> Enum.map(&scenario(&1).domain) |> Enum.uniq()

  # ---------------------------------------------------------------------
  # states_for/2 — generic 10-state derivation (D-06 spine mechanism).
  # Never a hand-authored 15x10 matrix: adding a `scenario/1` clause above
  # is enough — every state variant below is derived structurally from
  # that one record, so the transform stays O(1) per new ugly scenario.
  # ---------------------------------------------------------------------

  @doc """
  Derives all ten canonical D-11 states for `primitive` from the base
  `scenario_name` record, returning a keyword list
  `[{state_atom, fixture_map}, ...]` in the fixed `states/0` order.

  `primitive` does not change *which* fields get stressed — the derivation
  is fully structural (it walks every map/list/string leaf of the base
  fixture) — it is carried through so callers (state-band renderers) can
  pair the derived fixture with `inventory_id(primitive)`.
  """
  def states_for(primitive, scenario_name) when is_atom(primitive) and is_atom(scenario_name) do
    base = scenario(scenario_name)

    for state <- @states do
      {state, derive_state(state, base)}
    end
  end

  defp derive_state(:normal, base), do: base
  defp derive_state(:long_text, base), do: deep_map(base, &lengthen/1)
  defp derive_state(:empty, base), do: deep_empty(base)
  defp derive_state(:dense, base), do: deep_densify(base, 12)
  defp derive_state(:disabled, base), do: Map.put(base, :disabled, true)
  defp derive_state(:selected, base), do: Map.put(base, :selected, true)
  defp derive_state(:loading, base), do: Map.put(base, :loading, true)
  defp derive_state(:warning, base), do: Map.put(base, :severity, :warning)
  defp derive_state(:danger, base), do: Map.put(base, :severity, :danger)
  defp derive_state(:error, base), do: Map.put(base, :severity, :error)

  # Deterministic string stretcher for the `long_text` state (D-15 ugly
  # data) — no randomness, same input always yields the same output (D-17).
  defp lengthen(""), do: ""
  defp lengthen(s) when is_binary(s), do: s <> " — " <> s <> " — " <> s

  defp deep_map(v, fun) when is_binary(v), do: fun.(v)
  defp deep_map(v, fun) when is_list(v), do: Enum.map(v, &deep_map(&1, fun))
  defp deep_map(v, fun) when is_map(v), do: Map.new(v, fn {k, val} -> {k, deep_map(val, fun)} end)
  defp deep_map(v, _fun), do: v

  defp deep_empty(v) when is_binary(v), do: ""
  defp deep_empty(v) when is_list(v), do: []
  defp deep_empty(v) when is_map(v), do: Map.new(v, fn {k, val} -> {k, deep_empty(val)} end)
  defp deep_empty(v), do: v

  defp deep_densify(v, n) when is_list(v) and v != [] do
    v |> Stream.cycle() |> Enum.take(n) |> Enum.map(&deep_densify(&1, n))
  end

  defp deep_densify(v, _n) when is_list(v), do: v
  defp deep_densify(v, n) when is_map(v), do: Map.new(v, fn {k, val} -> {k, deep_densify(val, n)} end)
  defp deep_densify(v, _n), do: v
end
