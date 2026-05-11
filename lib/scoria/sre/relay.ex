defmodule Scoria.SRE.Relay do
  @moduledoc """
  Supervised durable fanout worker for audit outbox rows and notification
  deliveries.

  Delivery state stays local first: rows are claimed in the database, attempt
  counters are incremented before fanout, and failures remain durable for later
  retries.
  """

  use GenServer

  import Ecto.Query, warn: false

  require Logger

  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.{AuditOutboxEvent, NotificationDelivery}

  @default_poll_interval 5_000
  @default_batch_size 25

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def drain_once(opts \\ []) do
    opts
    |> state_from_opts()
    |> drain()
  end

  @impl true
  def init(opts) do
    state = state_from_opts(opts)
    if state.auto_drain?, do: schedule_drain(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:drain, state) do
    _ = drain(state)
    schedule_drain(state.poll_interval)
    {:noreply, state}
  end

  defp state_from_opts(opts) do
    %{
      auto_drain?: Keyword.get(opts, :auto_drain?, Mix.env() != :test),
      poll_interval: Keyword.get(opts, :poll_interval, @default_poll_interval),
      batch_size: Keyword.get(opts, :batch_size, @default_batch_size)
    }
  end

  defp schedule_drain(delay_ms) do
    Process.send_after(self(), :drain, delay_ms)
  end

  defp drain(state) do
    with :ok <- drain_audit_outbox(state.batch_size),
         :ok <- drain_notifications(state.batch_size) do
      :ok
    end
  rescue
    error in [Postgrex.Error, DBConnection.ConnectionError] ->
      log_relay_error("relay drain skipped", error)
      :ok

    error in Ecto.QueryError ->
      log_relay_error("relay drain query skipped", error)
      :ok
  end

  defp drain_audit_outbox(batch_size) do
    batch_size
    |> claim_pending_audit_events()
    |> Enum.each(&deliver_audit_event/1)

    :ok
  end

  defp drain_notifications(batch_size) do
    batch_size
    |> claim_pending_notifications()
    |> Enum.each(&deliver_notification/1)

    :ok
  end

  defp claim_pending_audit_events(batch_size) do
    now = now()

    Repo.transaction(fn ->
      query =
        from(event in AuditOutboxEvent,
          where: event.sink_status in ["pending", "failed"],
          order_by: [asc: event.pending_at, asc: event.inserted_at],
          limit: ^batch_size,
          lock: "FOR UPDATE SKIP LOCKED"
        )

      events = Repo.all(query)
      ids = Enum.map(events, & &1.id)

      if ids != [] do
        from(event in AuditOutboxEvent, where: event.id in ^ids)
        |> Repo.update_all(
          set: [sink_status: "processing", updated_at: now],
          inc: [attempt_count: 1]
        )
      end

      Repo.all(from(event in AuditOutboxEvent, where: event.id in ^ids))
    end)
    |> case do
      {:ok, events} -> events
      {:error, reason} -> raise reason
    end
  end

  defp claim_pending_notifications(batch_size) do
    now = now()

    Repo.transaction(fn ->
      query =
        from(delivery in NotificationDelivery,
          where: delivery.delivery_status in ["pending", "failed"],
          order_by: [asc: delivery.pending_at, asc: delivery.inserted_at],
          limit: ^batch_size,
          lock: "FOR UPDATE SKIP LOCKED"
        )

      deliveries =
        query
        |> Repo.all()
        |> Repo.preload([:incident, :alert_event])

      ids = Enum.map(deliveries, & &1.id)

      if ids != [] do
        from(delivery in NotificationDelivery, where: delivery.id in ^ids)
        |> Repo.update_all(
          set: [delivery_status: "delivering", last_attempt_at: now, updated_at: now],
          inc: [attempt_count: 1]
        )
      end

      NotificationDelivery
      |> where([delivery], delivery.id in ^ids)
      |> Repo.all()
      |> Repo.preload([:incident, :alert_event])
    end)
    |> case do
      {:ok, deliveries} -> deliveries
      {:error, reason} -> raise reason
    end
  end

  defp deliver_audit_event(event) do
    sink = SRE.audit_sink()
    envelope = audit_envelope(event)

    case publish_with_rescue(sink, envelope) do
      {:ok, _result} -> mark_audit_delivered(event)
      {:error, reason} -> mark_audit_failed(event, reason)
    end
  end

  defp deliver_notification(delivery) do
    sink = notification_sink(delivery)
    envelope = notification_envelope(delivery)

    case publish_with_rescue(sink, envelope) do
      {:ok, _result} -> mark_notification_delivered(delivery)
      {:error, reason} -> mark_notification_failed(delivery, reason)
    end
  end

  defp notification_sink(%NotificationDelivery{sink_kind: "chimeway"}),
    do: Scoria.SRE.Adapters.Chimeway

  defp notification_sink(%NotificationDelivery{sink_kind: "mailglass"}),
    do: Scoria.SRE.Adapters.Mailglass

  defp notification_sink(_delivery), do: SRE.alert_sink()

  defp publish_with_rescue(sink, envelope) do
    sink.publish(envelope)
  rescue
    error -> {:error, error}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp mark_audit_delivered(event) do
    event
    |> AuditOutboxEvent.changeset(%{
      sink_status: "delivered",
      sent_at: now(),
      metadata: drop_last_error(event.metadata)
    })
    |> Repo.update()
  end

  defp mark_audit_failed(event, reason) do
    event
    |> AuditOutboxEvent.changeset(%{
      sink_status: "failed",
      metadata: put_last_error(event.metadata, reason)
    })
    |> Repo.update()
  end

  defp mark_notification_delivered(delivery) do
    delivery
    |> NotificationDelivery.changeset(%{
      delivery_status: "delivered",
      delivered_at: now(),
      last_error: nil,
      metadata: drop_last_error(delivery.metadata)
    })
    |> Repo.update()
  end

  defp mark_notification_failed(delivery, reason) do
    error = format_error(reason)

    delivery
    |> NotificationDelivery.changeset(%{
      delivery_status: "failed",
      last_error: error,
      metadata: put_last_error(delivery.metadata, error)
    })
    |> Repo.update()
  end

  defp audit_envelope(event) do
    %{
      tenant_id: event.tenant_id,
      event_id: event.id,
      event_type: event.event_type,
      policy_class: event.policy_class,
      dedupe_key: event.dedupe_key,
      payload_hash: event.payload_hash,
      actor_ref: event.actor_ref,
      workflow_run_id: event.workflow_run_id,
      step_id: event.step_id,
      trace_id: event.trace_id,
      redacted_refs: Map.new(event.redacted_refs || %{}),
      metadata: Map.new(event.metadata || %{})
    }
  end

  defp notification_envelope(delivery) do
    incident = delivery.incident
    alert_event = delivery.alert_event

    %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      sink_kind: delivery.sink_kind,
      routing_key: delivery.routing_key,
      workflow_run_id: delivery.workflow_run_id || incident && incident.workflow_run_id,
      trace_id: delivery.trace_id || incident && incident.trace_id || alert_event && alert_event.trace_id,
      severity:
        metadata_value(delivery.metadata, "severity") ||
          incident && incident.severity || alert_event && alert_event.severity || "warning",
      routing_class:
        metadata_value(delivery.metadata, "routing_class") ||
          incident && incident.routing_class || "review",
      incident_key: incident && incident.incident_key,
      reason_code: alert_event && alert_event.reason_code,
      payload_hash: delivery.payload_hash,
      summary: metadata_value(delivery.metadata, "summary"),
      metadata: Map.new(delivery.metadata || %{})
    }
  end

  defp put_last_error(metadata, reason) do
    metadata
    |> Map.new()
    |> Map.put("last_error", format_error(reason))
  end

  defp drop_last_error(metadata) do
    metadata
    |> Map.new()
    |> Map.delete("last_error")
  end

  defp format_error(%_{} = error), do: Exception.message(error)
  defp format_error(reason), do: inspect(reason)

  defp metadata_value(metadata, key) do
    metadata
    |> Map.new()
    |> Map.get(key)
  end

  defp log_relay_error(message, error) do
    Logger.debug(fn -> "#{message}: #{Exception.message(error)}" end)
  rescue
    Protocol.UndefinedError -> Logger.debug("#{message}: #{inspect(error)}")
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
