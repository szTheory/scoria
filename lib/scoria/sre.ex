defmodule Scoria.SRE do
  @moduledoc """
  Public Phase 7 context boundary for runtime governance, alerts, incidents,
  and audit export.

  Later Seismograph plans can fill in persistence and runtime enforcement behind
  these entrypoints without widening the rest of the codebase's call sites.
  """

  @type attrs :: map()

  def create_budget_policy(attrs), do: not_implemented(:create_budget_policy, attrs)

  def reserve_usage(attrs), do: not_implemented(:reserve_usage, attrs)

  def reconcile_usage(reservation, attrs), do: not_implemented(:reconcile_usage, %{reservation: reservation, attrs: attrs})

  def record_breaker_trip(attrs), do: not_implemented(:record_breaker_trip, attrs)

  def record_alert_event(attrs), do: not_implemented(:record_alert_event, attrs)

  def open_incident(attrs), do: not_implemented(:open_incident, attrs)

  def append_incident_event(incident, attrs),
    do: not_implemented(:append_incident_event, %{incident: incident, attrs: attrs})

  def create_audit_outbox_event(attrs), do: not_implemented(:create_audit_outbox_event, attrs)

  def deliver_notification(target, envelope),
    do: not_implemented(:deliver_notification, %{target: target, envelope: envelope})

  defp not_implemented(action, attrs) do
    {:error, %{action: action, status: :not_implemented, attrs: attrs}}
  end
end
