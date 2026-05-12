defmodule Scoria.Workflows do
  @moduledoc """
  Durable workflow persistence and lifecycle transitions.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

  @topic_prefix "scoria:workflow_runs:"

  def subscribe_run(run_id) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, @topic_prefix <> run_id)
  end

  def get_run!(id), do: Repo.get!(Run, id)

  def get_step!(id), do: Repo.get!(Step, id)

  def get_approval!(id), do: Repo.get!(Approval, id)

  def list_run_steps(run_id) do
    Step
    |> where([step], step.run_id == ^run_id)
    |> order_by([step], asc: step.sequence)
    |> Repo.all()
  end

  def list_run_checkpoints(run_id) do
    Checkpoint
    |> where([checkpoint], checkpoint.run_id == ^run_id)
    |> order_by([checkpoint], asc: checkpoint.sequence)
    |> Repo.all()
  end

  def list_run_events(run_id) do
    Event
    |> where([event], event.run_id == ^run_id)
    |> order_by([event], asc: event.sequence)
    |> Repo.all()
  end

  def next_step_sequence(run_id) do
    Step
    |> where([step], step.run_id == ^run_id)
    |> select([step], max(step.sequence))
    |> Repo.one()
    |> case do
      nil -> 1
      sequence -> sequence + 1
    end
  end

  def get_run_tree!(id) do
    Run
    |> Repo.get!(id)
    |> Repo.preload(
      approvals: from(a in Approval, order_by: [asc: a.inserted_at]),
      checkpoints: from(c in Checkpoint, order_by: [asc: c.sequence]),
      events: from(e in Event, order_by: [asc: e.sequence]),
      handoffs: from(h in Handoff, order_by: [asc: h.inserted_at]),
      steps: from(s in Step, order_by: [asc: s.sequence])
    )
  end

  def list_runnable_steps do
    Step
    |> join(:inner, [s], r in assoc(s, :run))
    |> where([s, r], s.status in ["queued", "retrying"] and r.status in ["running", "retrying"])
    |> order_by([s, _r], asc: s.run_id, asc: s.sequence)
    |> Repo.all()
  end

  def create_run(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    {initial_step, run_attrs} = Map.pop(attrs, :initial_step)

    multi =
      Multi.new()
      |> Multi.insert(
        :run,
        Run.changeset(%Run{}, Map.merge(%{status: "running", started_at: now}, run_attrs))
      )
      |> maybe_insert_initial_step(initial_step, now)
      |> Multi.run(:checkpoint, fn repo, changes ->
        {:ok,
         insert_checkpoint(
           repo,
           changes.run.id,
           changes[:initial_step] && changes.initial_step.id,
           %{
             transition: "run_started",
             status: changes.run.status,
             snapshot: %{root_role_id: changes.run.root_role_id, metadata: changes.run.metadata},
             metadata: %{}
           }
         )}
      end)
      |> Multi.run(:event, fn repo, changes ->
        {:ok,
         insert_event(repo, changes.run.id, changes[:initial_step] && changes.initial_step.id, %{
           event_type: "run_started",
           payload: %{status: changes.run.status}
         })}
      end)
      |> Multi.update(:run_with_checkpoint, fn changes ->
        Run.changeset(changes.run, %{
          current_step_id: changes[:initial_step] && changes.initial_step.id,
          latest_checkpoint_id: changes.checkpoint.id
        })
      end)

    multi
    |> Repo.transaction()
    |> case do
      {:ok, %{run_with_checkpoint: run}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        {:ok, run}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def create_step(%Run{id: run_id}, attrs), do: create_step(run_id, attrs)

  def create_step(run_id, attrs) do
    attrs = Map.put(attrs, :run_id, run_id)

    %Step{}
    |> Step.changeset(attrs)
    |> Repo.insert()
    |> maybe_broadcast_step(run_id)
  end

  def append_checkpoint(%Run{id: run_id}, step_id, attrs),
    do: append_checkpoint(run_id, step_id, attrs)

  def append_checkpoint(run_id, step_id, attrs) do
    multi =
      Multi.new()
      |> Multi.run(:checkpoint, fn repo, _changes ->
        {:ok, insert_checkpoint(repo, run_id, step_id, attrs)}
      end)
      |> Multi.update(:run, fn %{checkpoint: checkpoint} ->
        run = Repo.get!(Run, run_id)
        Run.changeset(run, %{latest_checkpoint_id: checkpoint.id})
      end)

    multi
    |> Repo.transaction()
    |> case do
      {:ok, %{checkpoint: checkpoint}} ->
        broadcast(run_id, {:workflow_updated, run_id})
        {:ok, checkpoint}

      {:error, _op, value, _changes} ->
        {:error, value}
    end
  end

  def append_event(%Run{id: run_id}, step_id, attrs), do: append_event(run_id, step_id, attrs)

  def append_event(run_id, step_id, attrs) do
    case Repo.transaction(fn repo -> insert_event(repo, run_id, step_id, attrs) end) do
      {:ok, event} ->
        broadcast(run_id, {:workflow_updated, run_id})
        {:ok, event}

      {:error, value} ->
        {:error, value}
    end
  end

  def claim_step(%Step{id: id}), do: claim_step(id)

  def claim_step(step_id) do
    case Repo.get(Step, step_id) do
      %Step{} = step when step.status in ["queued", "retrying"] ->
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

        Repo.transaction(fn ->
          step = Repo.get!(Step, step_id)

          case step.status do
            status when status in ["queued", "retrying"] ->
              Repo.update!(Step.changeset(step, %{status: "running", started_at: now}))

            _ ->
              Repo.rollback(:already_claimed)
          end
        end)

      _ ->
        {:error, :not_runnable}
    end
  end

  def complete_step(step_or_id, result_envelope, opts \\ [])

  def complete_step(%Step{id: step_id}, result_envelope, opts),
    do: complete_step(step_id, result_envelope, opts)

  def complete_step(step_id, result_envelope, opts) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      step = repo.get!(Step, step_id)
      run = repo.get!(Run, step.run_id)

      completed_step =
        step
        |> Step.changeset(%{
          status: "completed",
          completed_at: now,
          result_envelope: result_envelope,
          error_envelope: %{}
        })
        |> repo.update!()

      pending_count =
        Step
        |> where(
          [s],
          s.run_id == ^run.id and s.id != ^step.id and s.status not in ["completed", "cancelled"]
        )
        |> repo.aggregate(:count)

      run_status =
        Keyword.get(opts, :run_status, if(pending_count == 0, do: "completed", else: "running"))

      checkpoint =
        insert_checkpoint(repo, run.id, completed_step.id, %{
          transition: "step_completed",
          status: run_status,
          snapshot: %{result_envelope: result_envelope},
          metadata: %{}
        })

      insert_event(repo, run.id, completed_step.id, %{
        event_type: "step_completed",
        payload: %{result_envelope: result_envelope}
      })

      updated_run =
        run
        |> Run.changeset(%{
          status: run_status,
          current_step_id: if(run_status == "completed", do: nil, else: completed_step.id),
          latest_checkpoint_id: checkpoint.id,
          completed_at: if(run_status == "completed", do: now, else: run.completed_at),
          error_envelope: %{}
        })
        |> repo.update!()

      {updated_run, completed_step, checkpoint}
    end)
    |> case do
      {:ok, {run, step, _checkpoint}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        {:ok, step}

      {:error, value} ->
        {:error, value}
    end
  end

  def mark_waiting_for_approval(%Run{id: run_id}, %Step{id: step_id}, attrs),
    do: mark_waiting_for_approval(run_id, step_id, attrs)

  def mark_waiting_for_approval(run_id, step_id, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      run = repo.get!(Run, run_id)
      step = repo.get!(Step, step_id)

      updated_run =
        repo.update!(
          Run.changeset(run, %{status: "waiting_for_approval", current_step_id: step.id})
        )

      repo.update!(
        Step.changeset(step, %{status: "waiting_for_approval", started_at: step.started_at || now})
      )

      checkpoint =
        insert_checkpoint(repo, run.id, step.id, %{
          transition: "waiting_for_approval",
          status: "waiting_for_approval",
          snapshot: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")},
          metadata: %{}
        })

      insert_event(repo, run.id, step.id, %{
        event_type: "waiting_for_approval",
        payload: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")}
      })

      approval_attrs =
        attrs
        |> Map.new()
        |> Map.merge(%{
          workflow_run_id: run.id,
          step_id: step.id,
          checkpoint_id: checkpoint.id,
          status: "pending",
          run_id: run.id
        })

      approval =
        %Approval{}
        |> Approval.changeset(approval_attrs)
        |> repo.insert!()

      updated_run =
        repo.update!(
          Run.changeset(updated_run, %{
            latest_checkpoint_id: checkpoint.id,
            last_heartbeat_at: now
          })
        )

      audit_outbox_event =
        SRE.insert_audit_outbox_event(repo, %{
          tenant_id: Map.get(attrs, :tenant_id) || Map.get(attrs, "tenant_id") || "system",
          event_type: "approval.requested",
          policy_class: "approval",
          dedupe_key: Map.get(attrs, :dedupe_key) || Map.get(attrs, "dedupe_key"),
          actor_ref: Map.get(attrs, :actor_id) || Map.get(attrs, "actor_id"),
          workflow_run_id: run.id,
          step_id: step.id,
          trace_id: Map.get(attrs, :trace_id) || Map.get(attrs, "trace_id"),
          approval_id: approval.id,
          tool_name: approval.tool_name,
          arguments: approval.arguments,
          reason: Map.get(attrs, :reason) || Map.get(attrs, "reason"),
          metadata: %{
            "checkpoint_id" => checkpoint.id,
            "run_status" => updated_run.status
          }
        })

      {updated_run, approval, audit_outbox_event}
    end)
    |> case do
      {:ok, {run, approval, audit_outbox_event}} ->
        SRE.emit_audit_outbox_telemetry(audit_outbox_event)
        broadcast(run.id, {:approval_requested, run.id, approval.id})
        {:ok, approval}

      {:error, value} ->
        {:error, value}
    end
  end

  def fail_step(step_or_id, error_envelope, opts \\ [])

  def fail_step(%Step{id: step_id}, error_envelope, opts),
    do: fail_step(step_id, error_envelope, opts)

  def fail_step(step_id, error_envelope, opts) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      step = repo.get!(Step, step_id)
      run = repo.get!(Run, step.run_id)
      run_status = Keyword.get(opts, :run_status, "failed")

      failed_step =
        step
        |> Step.changeset(%{status: "failed", completed_at: now, error_envelope: error_envelope})
        |> repo.update!()

      checkpoint =
        insert_checkpoint(repo, run.id, failed_step.id, %{
          transition: "step_failed",
          status: run_status,
          snapshot: %{error_envelope: error_envelope},
          metadata: %{}
        })

      insert_event(repo, run.id, failed_step.id, %{
        event_type: "step_failed",
        payload: %{error_envelope: error_envelope}
      })

      updated_run =
        run
        |> Run.changeset(%{
          status: run_status,
          current_step_id: failed_step.id,
          latest_checkpoint_id: checkpoint.id,
          error_envelope: error_envelope
        })
        |> repo.update!()

      {updated_run, failed_step}
    end)
    |> case do
      {:ok, {run, step}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        {:ok, step}

      {:error, value} ->
        {:error, value}
    end
  end

  def create_handoff(%Step{} = step, attrs) do
    attrs =
      attrs
      |> Map.put(:run_id, step.run_id)
      |> Map.put(:step_id, step.id)

    %Handoff{}
    |> Handoff.changeset(attrs)
    |> Repo.insert()
    |> maybe_broadcast_step(step.run_id)
  end

  def retry_step(%Step{id: step_id}), do: retry_step(step_id)

  def retry_step(step_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      step = repo.get!(Step, step_id)
      run = repo.get!(Run, step.run_id)

      retried_step =
        step
        |> Step.changeset(%{
          status: "retrying",
          retry_count: step.retry_count + 1,
          attempt: step.attempt + 1,
          completed_at: nil,
          error_envelope: %{},
          result_envelope: %{}
        })
        |> repo.update!()

      checkpoint =
        insert_checkpoint(repo, run.id, retried_step.id, %{
          transition: "retry_requested",
          status: "retrying",
          snapshot: %{attempt: retried_step.attempt},
          metadata: %{}
        })

      insert_event(repo, run.id, retried_step.id, %{
        event_type: "retry_requested",
        payload: %{attempt: retried_step.attempt}
      })

      updated_run =
        run
        |> Run.changeset(%{
          status: "retrying",
          current_step_id: retried_step.id,
          latest_checkpoint_id: checkpoint.id,
          error_envelope: %{},
          last_heartbeat_at: now
        })
        |> repo.update!()

      {updated_run, retried_step}
    end)
    |> case do
      {:ok, {run, step}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        {:ok, step}

      {:error, value} ->
        {:error, value}
    end
  end

  def resume_run(run_id) do
    run = get_run_tree!(run_id)

    case {run.status, List.last(run.checkpoints), latest_pending_approval(run.approvals)} do
      {"waiting_for_approval", _checkpoint, %Approval{status: "approved"} = approval} ->
        Repo.transaction(fn repo ->
          step = repo.get!(Step, approval.step_id)
          run = repo.get!(Run, run_id)

          resumed_step = repo.update!(Step.changeset(step, %{status: "queued"}))

          checkpoint =
            insert_checkpoint(repo, run.id, resumed_step.id, %{
              transition: "resume_requested",
              status: "running",
              snapshot: %{checkpoint_id: approval.checkpoint_id},
              metadata: %{}
            })

          insert_event(repo, run.id, resumed_step.id, %{
            event_type: "resume_requested",
            payload: %{approval_id: approval.id}
          })

          updated_run =
            run
            |> Run.changeset(%{
              status: "running",
              latest_checkpoint_id: checkpoint.id,
              current_step_id: resumed_step.id
            })
            |> repo.update!()

          {updated_run, resumed_step}
        end)
        |> case do
          {:ok, {resumed_run, resumed_step}} ->
            broadcast(resumed_run.id, {:workflow_updated, resumed_run.id})
            {:ok, resumed_step}

          {:error, value} ->
            {:error, value}
        end

      {"failed", checkpoint, _approval} when not is_nil(checkpoint) ->
        current_step = Enum.find(run.steps, &(&1.id == run.current_step_id))

        if current_step do
          retry_step(current_step.id)
        else
          {:error, :no_failed_step}
        end

      _ ->
        {:error, :not_resumable}
    end
  end

  def approve(approval_or_id, status, attrs \\ %{})
  def approve(%Approval{} = approval, status, attrs), do: approve(approval.id, status, attrs)

  def approve(approval_id, status, attrs) when status in ["approved", "rejected", "expired"] do
    Repo.transaction(fn repo ->
      approval = repo.get!(Approval, approval_id)
      audit_context = approval_decision_context(repo, approval, attrs)

      updated_approval =
        approval
        |> Approval.changeset(Map.merge(Map.new(attrs), %{status: status}))
        |> repo.update!()

      audit_outbox_event =
        SRE.insert_audit_outbox_event(repo, %{
          tenant_id: audit_context.tenant_id,
          event_type: "approval.#{status}",
          policy_class: "approval",
          dedupe_key: Map.get(attrs, :dedupe_key) || Map.get(attrs, "dedupe_key"),
          actor_ref: audit_context.actor_id,
          workflow_run_id: updated_approval.workflow_run_id,
          step_id: updated_approval.step_id,
          trace_id: audit_context.trace_id,
          approval_id: updated_approval.id,
          decision: status,
          arguments: updated_approval.arguments,
          tool_name: updated_approval.tool_name,
          request_audit_event_id: audit_context.request_event && audit_context.request_event.id,
          request_trace_id: audit_context.request_event && audit_context.request_event.trace_id,
          request_actor_ref: audit_context.request_event && audit_context.request_event.actor_ref
        })

      {updated_approval, audit_outbox_event}
    end)
    |> case do
      {:ok, {updated_approval, audit_outbox_event}} ->
        SRE.emit_audit_outbox_telemetry(audit_outbox_event)
        {:ok, updated_approval}

      {:error, _operation, value, _changes} ->
        {:error, value}
    end
  end

  defp maybe_insert_initial_step(multi, nil, _now), do: multi

  defp maybe_insert_initial_step(multi, initial_step, now) do
    Multi.insert(multi, :initial_step, fn %{run: run} ->
      attrs =
        initial_step
        |> Map.put(:run_id, run.id)
        |> Map.put_new(:sequence, 1)
        |> Map.put_new(:status, "queued")
        |> Map.put_new(:started_at, now)

      Step.changeset(%Step{}, attrs)
    end)
  end

  defp maybe_broadcast_step({:ok, step}, run_id) do
    broadcast(run_id, {:workflow_updated, run_id})
    {:ok, step}
  end

  defp maybe_broadcast_step(error, _run_id), do: error

  defp insert_checkpoint(repo, run_id, step_id, attrs) do
    sequence = next_sequence(repo, Checkpoint, run_id)

    %Checkpoint{}
    |> Checkpoint.changeset(
      attrs
      |> Map.put(:run_id, run_id)
      |> Map.put(:step_id, step_id)
      |> Map.put(:sequence, sequence)
    )
    |> repo.insert!()
  end

  defp insert_event(repo, run_id, step_id, attrs) do
    sequence = next_sequence(repo, Event, run_id)

    %Event{}
    |> Event.changeset(
      attrs
      |> Map.put(:run_id, run_id)
      |> Map.put(:step_id, step_id)
      |> Map.put(:sequence, sequence)
    )
    |> repo.insert!()
  end

  defp next_sequence(repo, schema, run_id) do
    schema
    |> where([row], row.run_id == ^run_id)
    |> select([row], max(row.sequence))
    |> repo.one()
    |> case do
      nil -> 1
      sequence -> sequence + 1
    end
  end

  defp broadcast(run_id, message) do
    Phoenix.PubSub.broadcast(Scoria.PubSub, @topic_prefix <> run_id, message)
  end

  defp latest_pending_approval(approvals) do
    approvals
    |> Enum.reverse()
    |> Enum.find(&(&1.status in ["pending", "approved"]))
  end

  defp approval_decision_context(repo, approval, attrs) do
    request_event = approval_request_event(repo, approval)

    %{
      tenant_id:
        attr_value(attrs, :tenant_id) || (request_event && request_event.tenant_id) || "system",
      actor_id:
        attr_value(attrs, :actor_id) || (request_event && request_event.actor_ref) ||
          approval.session_id,
      trace_id: attr_value(attrs, :trace_id) || (request_event && request_event.trace_id),
      request_event: request_event
    }
  end

  defp approval_request_event(_repo, %Approval{workflow_run_id: nil}), do: nil

  defp approval_request_event(repo, %Approval{} = approval) do
    AuditOutboxEvent
    |> where(
      [event],
      event.workflow_run_id == ^approval.workflow_run_id and
        event.event_type == "approval.requested"
    )
    |> where([event], fragment("?->>? = ?", event.redacted_refs, "approval_id", ^approval.id))
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> repo.one()
  end

  defp attr_value(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
