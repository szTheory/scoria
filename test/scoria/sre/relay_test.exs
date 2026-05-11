defmodule Scoria.SRE.RelayTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent

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

    on_exit(fn ->
      restore_env(:sre_audit_sink, original_audit_sink)
    end)

    ensure_audit_outbox_table!()
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

  defp restore_env(_key, nil), do: :ok
  defp restore_env(key, value), do: Application.put_env(:scoria, key, value)
end
