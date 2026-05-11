defmodule Scoria.SRETest do
  use ExUnit.Case, async: true

  alias Scoria.SRE
  alias Scoria.SRE.{AlertSink, AuditSink}

  defmodule CustomAuditSink do
    @behaviour AuditSink

    @impl true
    def publish(envelope), do: {:ok, Map.put(envelope, :delivered_by, __MODULE__)}
  end

  defmodule CustomAlertSink do
    @behaviour AlertSink

    @impl true
    def publish(envelope), do: {:ok, Map.put(envelope, :delivered_by, __MODULE__)}
  end

  setup do
    original_audit = Application.get_env(:scoria, :sre_audit_sink)
    original_alert = Application.get_env(:scoria, :sre_alert_sink)

    on_exit(fn ->
      restore_env(:sre_audit_sink, original_audit)
      restore_env(:sre_alert_sink, original_alert)
    end)

    :ok
  end

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

  test "uses no-op sinks by default so optional integrations are not required" do
    Application.delete_env(:scoria, :sre_audit_sink)
    Application.delete_env(:scoria, :sre_alert_sink)

    assert {:ok, %{status: :noop, envelope: %{event_type: "approval.requested"}}} =
             SRE.create_audit_outbox_event(%{event_type: "approval.requested"})

    assert {:ok, %{status: :noop, envelope: %{severity: :warning}}} =
             SRE.record_alert_event(%{severity: :warning})
  end

  test "resolves configured sinks through the declared behaviors" do
    Application.put_env(:scoria, :sre_audit_sink, CustomAuditSink)
    Application.put_env(:scoria, :sre_alert_sink, CustomAlertSink)

    assert {:ok, %{delivered_by: CustomAuditSink}} =
             SRE.create_audit_outbox_event(%{event_type: "approval.approved"})

    assert {:ok, %{delivered_by: CustomAlertSink}} =
             SRE.record_alert_event(%{severity: :critical})
  end

  test "rejects sink modules that do not implement the required behavior" do
    Application.put_env(:scoria, :sre_audit_sink, Map)

    assert_raise ArgumentError, ~r/does not implement Scoria.SRE.AuditSink/, fn ->
      SRE.create_audit_outbox_event(%{event_type: "approval.denied"})
    end
  end

  defp restore_env(_key, nil), do: :ok

  defp restore_env(key, value) do
    Application.put_env(:scoria, key, value)
  end
end
