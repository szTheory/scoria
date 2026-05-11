defmodule Scoria.SRETest do
  use ExUnit.Case, async: true

  alias Scoria.SRE

  test "exposes a stable public context boundary for phase 7 entrypoints" do
    assert Code.ensure_loaded?(SRE)

    assert function_exported?(SRE, :create_budget_policy, 1)
    assert function_exported?(SRE, :reserve_usage, 1)
    assert function_exported?(SRE, :reconcile_usage, 2)
    assert function_exported?(SRE, :record_breaker_trip, 1)
    assert function_exported?(SRE, :record_alert_event, 1)
    assert function_exported?(SRE, :open_incident, 1)
    assert function_exported?(SRE, :append_incident_event, 2)
    assert function_exported?(SRE, :create_audit_outbox_event, 1)
    assert function_exported?(SRE, :deliver_notification, 2)
  end
end
