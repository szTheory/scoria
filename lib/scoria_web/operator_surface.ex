defmodule ScoriaWeb.OperatorSurface do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `ScoriaWeb.ReviewerSurface`.

  0.1.x compatibility migration note: new dashboard-facing code should use
  `ScoriaWeb.ReviewerSurface`, which names the human dashboard user as the
  reviewer and keeps tenant authority with the host-authenticated dashboard
  scope. This module delegates the old operator surface API so copied 0.1.x
  integrations keep working while they rename.

  The wrapper does not add runtime deprecation warnings. See
  `guides/reference/glossary.md` for the operator-to-reviewer compatibility
  mapping and `guides/reviewer-verification.md` for the verification flow.
  """

  alias ScoriaWeb.ReviewerSurface

  defdelegate load_runtimes(tenant_id), to: ReviewerSurface
  defdelegate runtime_drawer_semantic(run_id), to: ReviewerSurface
  defdelegate connector_fleet(tenant_id), to: ReviewerSurface
  defdelegate connector_drawer(tenant_id, connector_id), to: ReviewerSurface
  defdelegate pending_approval_count(tenant_id), to: ReviewerSurface
  defdelegate status_home_summary(tenant_id), to: ReviewerSurface
  defdelegate empty_status_home_summary, to: ReviewerSurface
  defdelegate fleet_summary(tenant_id), to: ReviewerSurface
  defdelegate incidents_summary(tenant_id), to: ReviewerSurface
  defdelegate list_tenant_runs(tenant_id), to: ReviewerSurface
  defdelegate fetch_tenant_run_detail(tenant_id, run_id), to: ReviewerSurface
  defdelegate fetch_tenant_review_candidate(tenant_id, run, candidate_id), to: ReviewerSurface
  defdelegate list_tenant_incidents(tenant_id), to: ReviewerSurface
  defdelegate fetch_tenant_incident(tenant_id, incident_id), to: ReviewerSurface
  defdelegate find_tenant_incident_for_run(tenant_id, run_id), to: ReviewerSurface
  defdelegate load_budget_projection(trace_id, run_id), to: ReviewerSurface
  defdelegate load_incident_projection(trace_id, run_id), to: ReviewerSurface
  defdelegate empty_incident_projection(trace_id, run_id), to: ReviewerSurface
  defdelegate compact_trace_badges(trace_id, run_id), to: ReviewerSurface
  defdelegate list_incidents(trace_id, run_id), to: ReviewerSurface
  defdelegate list_alert_events(incidents), to: ReviewerSurface
  defdelegate list_incident_events(incidents), to: ReviewerSurface
  defdelegate list_deliveries(trace_id, run_id), to: ReviewerSurface
  defdelegate list_audit_rows(trace_id, run_id), to: ReviewerSurface
  defdelegate latest_budget(trace_id, run_id), to: ReviewerSurface
  defdelegate latest_breaker(trace_id, run_id), to: ReviewerSurface
  defdelegate build_incident_rows(incidents, alert_events, incident_events), to: ReviewerSurface
  defdelegate build_audit_rows(audit_rows), to: ReviewerSurface
  defdelegate build_delivery_rows(deliveries), to: ReviewerSurface
  defdelegate delivery_outcome(delivery), to: ReviewerSurface
  defdelegate budget_status(budget), to: ReviewerSurface
  defdelegate budget_signal(budget), to: ReviewerSurface
  defdelegate budget_status_label(budget), to: ReviewerSurface
  defdelegate budget_actuals(budget), to: ReviewerSurface
  defdelegate breaker_signal(breaker), to: ReviewerSurface
  defdelegate breaker_detail(breaker), to: ReviewerSurface
  defdelegate relay_signal(audit_rows, deliveries), to: ReviewerSurface
  defdelegate relay_detail(audit_rows, deliveries), to: ReviewerSurface
  defdelegate routing_label(value), to: ReviewerSurface
  defdelegate severity_label(value), to: ReviewerSurface
  defdelegate first_present(values), to: ReviewerSurface
  defdelegate decimal_to_string(value), to: ReviewerSurface
end
