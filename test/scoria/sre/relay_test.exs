defmodule Scoria.SRE.RelayTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Decimal, as: D
  alias Scoria.SRE.{AuditOutboxEvent, NotificationDelivery}

  defmodule FailingAuditSink do
    @behaviour Scoria.SRE.AuditSink

    @impl true
    def publish(_envelope), do: {:error, :upstream_unavailable}
  end

  defmodule SuccessfulAuditSink do
    @behaviour Scoria.SRE.AuditSink

    @impl true
    def publish(envelope), do: {:ok, Map.put(envelope, :status, :delivered)}
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    original_audit_sink = Application.get_env(:scoria, :sre_audit_sink)
    original_threadline = Application.get_env(:scoria, :sre_threadline_dispatcher)
    original_chimeway = Application.get_env(:scoria, :sre_chimeway_dispatcher)
    original_mailglass = Application.get_env(:scoria, :sre_mailglass_dispatcher)

    on_exit(fn ->
      restore_env(:sre_audit_sink, original_audit_sink)
      restore_env(:sre_threadline_dispatcher, original_threadline)
      restore_env(:sre_chimeway_dispatcher, original_chimeway)
      restore_env(:sre_mailglass_dispatcher, original_mailglass)
    end)

    ensure_audit_outbox_table!()
    ensure_notification_delivery_table!()
    ensure_incident_tables!()
    :ok
  end

  describe "application supervision" do
    test "starts the relay under the real application supervision tree" do
      assert Enum.any?(Supervisor.which_children(Scoria.Supervisor), fn
               {Scoria.SRE.Relay, pid, :worker, [Scoria.SRE.Relay]} when is_pid(pid) -> true
               _child -> false
             end)
    end
  end

  describe "durable retry handling" do
    test "failed audit deliveries remain retryable with durable attempt state" do
      Application.put_env(:scoria, :sre_audit_sink, FailingAuditSink)

      audit_event =
        Repo.insert!(%AuditOutboxEvent{
          tenant_id: "tenant-relay",
          event_type: "approval.requested",
          policy_class: "approval",
          sink_status: "pending",
          dedupe_key: "relay:retryable",
          payload_hash: "sha256:relay",
          pending_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
          attempt_count: 0,
          actor_ref: "operator-1",
          workflow_run_id: Ecto.UUID.generate(),
          step_id: Ecto.UUID.generate(),
          trace_id: "trace-relay",
          redacted_refs: %{"approval_id" => "approval-1"},
          metadata: %{}
        })

      assert :ok = Scoria.SRE.Relay.drain_once()

      failed_event = Repo.get!(AuditOutboxEvent, audit_event.id)
      assert failed_event.sink_status == "failed"
      assert failed_event.attempt_count == 1
      assert failed_event.metadata["last_error"] =~ "upstream_unavailable"

      Application.put_env(:scoria, :sre_audit_sink, SuccessfulAuditSink)

      assert :ok = Scoria.SRE.Relay.drain_once()

      delivered_event = Repo.get!(AuditOutboxEvent, audit_event.id)
      assert delivered_event.sink_status == "delivered"
      assert delivered_event.attempt_count == 2
      assert delivered_event.sent_at
      refute Map.has_key?(delivered_event.metadata, "last_error")
    end
  end

  describe "optional first-party adapters" do
    test "keep Threadline, Chimeway, and Mailglass as no-op defaults when unconfigured" do
      assert {:ok, %{status: :noop, adapter: :threadline, envelope: audit_envelope}} =
               Scoria.SRE.Adapters.Threadline.publish(%{
                 event_type: "approval.requested",
                 trace_id: "trace-threadline",
                 redacted_refs: %{"approval_id" => "approval-2"}
               })

      refute Map.has_key?(audit_envelope, :__struct__)
      assert audit_envelope.category == "audit"
      assert audit_envelope.event_type == "approval.requested"

      assert {:ok, %{status: :noop, adapter: :chimeway, envelope: chimeway_envelope}} =
               Scoria.SRE.Adapters.Chimeway.publish(%{
                 severity: "warning",
                 routing_class: "review",
                 routing_key: "reviews"
               })

      assert chimeway_envelope.severity == "warning"
      assert chimeway_envelope.routing_class == "review"

      assert {:ok, %{status: :noop, adapter: :mailglass, envelope: mailglass_envelope}} =
               Scoria.SRE.Adapters.Mailglass.publish(%{
                 severity: "critical",
                 routing_class: "page",
                 routing_key: "ops@example.com"
               })

      assert mailglass_envelope.severity == "critical"
      assert mailglass_envelope.routing_class == "page"
    end

    test "routes producer-shaped notification deliveries through sink-specific adapters with severity metadata" do
      Application.put_env(
        :scoria,
        :sre_chimeway_dispatcher,
        {__MODULE__, :capture_delivery, [self(), :chimeway]}
      )

      Application.put_env(
        :scoria,
        :sre_mailglass_dispatcher,
        {__MODULE__, :capture_delivery, [self(), :mailglass]}
      )

      assert {:ok, %{notification_deliveries: [chimeway_delivery]}} =
               Scoria.SRE.record_alert_event(%{
                 tenant_id: "tenant-relay",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:quality",
                 reason_code: "quality_regression",
                 summary: "Review me",
                 measured_value: D.new("0.55"),
                 threshold_value: D.new("0.75"),
                 trace_id: "trace-chimeway",
                 workflow_run_id: Ecto.UUID.generate(),
                 window_bucket: "2026-05-11T20",
                 routing_class: "review"
               })

      assert {:ok, %{notification_deliveries: [mailglass_delivery]}} =
               Scoria.SRE.record_alert_event(%{
                 tenant_id: "tenant-relay",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:latency",
                 reason_code: "breaker_open",
                 summary: "Page me",
                 measured_value: D.new("150.0"),
                 threshold_value: D.new("100.0"),
                 trace_id: "trace-mailglass",
                 workflow_run_id: Ecto.UUID.generate(),
                 window_bucket: "2026-05-11T21"
               })

      assert :ok = Scoria.SRE.Relay.drain_once()

      assert_receive {:captured_delivery, :chimeway, envelope}
      assert envelope.severity == "warning"
      assert envelope.routing_class == "review"
      assert envelope.summary == "Review me"

      assert_receive {:captured_delivery, :mailglass, envelope}
      assert envelope.severity == "critical"
      assert envelope.routing_class == "page"
      assert envelope.summary == "Page me"

      stored_chimeway_delivery = Repo.get!(NotificationDelivery, chimeway_delivery.id)
      stored_mailglass_delivery = Repo.get!(NotificationDelivery, mailglass_delivery.id)

      assert stored_chimeway_delivery.delivery_status == "delivered"
      assert stored_mailglass_delivery.delivery_status == "delivered"
      assert stored_chimeway_delivery.metadata["delivery_outcome"] == "delivered"
      assert stored_mailglass_delivery.metadata["delivery_outcome"] == "delivered"
      assert stored_chimeway_delivery.metadata["delivery_adapter"] == "chimeway"
      assert stored_mailglass_delivery.metadata["delivery_adapter"] == "mailglass"
    end

    test "records unconfigured noop outcomes durably for later operator evidence" do
      assert {:ok, %{notification_deliveries: [delivery]}} =
               Scoria.SRE.record_alert_event(%{
                 tenant_id: "tenant-relay",
                 subject_kind: "workflow",
                 policy_key: "tenant:default:quality",
                 reason_code: "quality_regression",
                 summary: "Review me later",
                 measured_value: D.new("0.61"),
                 threshold_value: D.new("0.75"),
                 trace_id: "trace-unconfigured",
                 workflow_run_id: Ecto.UUID.generate(),
                 window_bucket: "2026-05-12T01",
                 routing_class: "review"
               })

      assert :ok = Scoria.SRE.Relay.drain_once()

      stored_delivery = Repo.get!(NotificationDelivery, delivery.id)

      assert stored_delivery.delivery_status == "delivered"
      assert stored_delivery.metadata["transport_mode"] == "unconfigured"
      assert stored_delivery.metadata["delivery_outcome"] == "unconfigured"
      assert stored_delivery.metadata["delivery_adapter"] == "chimeway"
    end
  end

  defp ensure_audit_outbox_table! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_audit_outbox_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      event_type varchar NOT NULL,
      policy_class varchar NOT NULL,
      sink_status varchar NOT NULL DEFAULT 'pending',
      dedupe_key varchar NOT NULL,
      payload_hash varchar NOT NULL,
      pending_at timestamp(6) without time zone NOT NULL,
      sent_at timestamp(6) without time zone NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      step_id uuid NULL,
      trace_id varchar NULL,
      redacted_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE UNIQUE INDEX IF NOT EXISTS ai_audit_outbox_events_tenant_dedupe_key_idx
    ON ai_audit_outbox_events (tenant_id, dedupe_key)
    """)
  end

  defp ensure_notification_delivery_table! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_notification_deliveries (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      sink_kind varchar NOT NULL,
      routing_key varchar NOT NULL,
      delivery_status varchar NOT NULL DEFAULT 'pending',
      pending_at timestamp(6) without time zone NOT NULL,
      last_attempt_at timestamp(6) without time zone NULL,
      delivered_at timestamp(6) without time zone NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      payload_hash varchar NOT NULL,
      last_error varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      incident_id uuid NULL,
      alert_event_id uuid NULL,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)
  end

  defp ensure_incident_tables! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incidents (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_key varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'open',
      summary text NOT NULL,
      routing_class varchar NOT NULL,
      dedupe_key varchar NOT NULL,
      first_seen_at timestamp(6) without time zone NOT NULL,
      last_seen_at timestamp(6) without time zone NOT NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
      lock_version integer NOT NULL DEFAULT 1,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS ai_incidents_tenant_incident_key_idx ON ai_incidents (tenant_id, incident_key)"
    )

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_alert_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      alert_policy_id uuid NULL,
      incident_id uuid NULL,
      incident_key varchar NOT NULL,
      reason_code varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'new',
      measured_value numeric(18,6) NOT NULL,
      threshold_value numeric(18,6) NOT NULL,
      scorer_version_ref varchar NULL,
      baseline_version_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incident_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_id uuid NOT NULL,
      alert_event_id uuid NULL,
      incident_key varchar NOT NULL,
      event_type varchar NOT NULL,
      reason_code varchar NOT NULL,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)
  end

  def capture_delivery(pid, adapter, envelope) do
    send(pid, {:captured_delivery, adapter, envelope})
    {:ok, %{adapter: adapter, status: :delivered}}
  end

  defp restore_env(key, nil), do: Application.delete_env(:scoria, key)
  defp restore_env(key, value), do: Application.put_env(:scoria, key, value)
end
