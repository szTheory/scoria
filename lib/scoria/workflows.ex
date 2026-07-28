defmodule Scoria.Workflows do
  @moduledoc """
  Durable workflow persistence and lifecycle transitions.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Connectors.Connector
  alias Scoria.Connectors.LocalTool
  alias Scoria.Identity
  alias Scoria.Observe
  alias Scoria.Observe.Approval
  alias Scoria.Observe.ReviewerBroadcast
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows.DatasetPromotion
  alias Scoria.Workflows.EventCompactor
  alias Scoria.Workflows.RemoteApprovalProjection
  alias Scoria.Workflows.{Checkpoint, Event, Handoff, ReplayDisposition, Run, Step}

  @topic_prefix "scoria:workflow_runs:"

  def subscribe_run(run_id) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, @topic_prefix <> run_id)
  end

  def get_run!(id), do: Repo.get!(Run, id)

  def get_step!(id), do: Repo.get!(Step, id)

  def get_approval!(id), do: Repo.get!(Approval, id)

  def list_pending_remote_approvals(filters \\ %{}),
    do: RemoteApprovalProjection.list_pending_approvals(filters)

  def get_remote_approval_lineage!(approval_id),
    do: RemoteApprovalProjection.get_approval_lineage!(approval_id)

  def request_baseline_promotion(attrs) when is_map(attrs) do
    DatasetPromotion.request_baseline_promotion(attrs)
  end

  def list_pending_approvals(filters \\ %{}),
    do: RemoteApprovalProjection.list_pending_approvals(filters)

  def list_decided_approvals(filters \\ %{}),
    do: RemoteApprovalProjection.list_decided_approvals(filters)

  def get_approval_lineage!(approval_id),
    do: RemoteApprovalProjection.get_approval_lineage!(approval_id)

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
    attrs = Map.new(attrs)
    initial_step = Map.get(attrs, :initial_step) || Map.get(attrs, "initial_step")
    run_attrs = Map.drop(attrs, [:initial_step, "initial_step"])
    identity = Identity.normalize(run_attrs)
    run_attrs = run_attrs_with_identity(run_attrs, identity)
    identity_snapshot = Identity.to_map(identity)

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
             snapshot: %{
               root_role_id: changes.run.root_role_id,
               metadata: changes.run.metadata,
               identity: identity_snapshot
             },
             metadata: %{"identity" => stringify_map(identity_snapshot)}
           }
         )}
      end)
      |> Multi.run(:event, fn repo, changes ->
        {:ok,
         insert_event(repo, changes.run.id, changes[:initial_step] && changes.initial_step.id, %{
           event_type: "run_started",
           payload: %{status: changes.run.status, identity: identity_snapshot}
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

  def record_connector_auth_failure(run_id, step_id, payload) do
    append_event(run_id, step_id, %{event_type: "connector.auth_failed", payload: payload})
  end

  def record_connector_scope_escalation(run_id, step_id, payload) do
    append_event(run_id, step_id, %{event_type: "connector.scope_escalation", payload: payload})
  end

  def claim_step(%Step{id: id}), do: claim_step(id)

  def claim_step(step_id) do
    case Repo.get(Step, step_id) do
      %Step{} = step when step.status in ["queued", "retrying"] ->
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

        Repo.transaction(fn ->
          # G1 (RAIL-01 D-02, the keystone guard): the run row is locked
          # FOR UPDATE first -- BEFORE the step is re-read/updated -- so the
          # global lock order stays run-then-steps, matching `halt_run/3`'s
          # own order and keeping the two paths deadlock-free (D-04). This
          # is the sole in-`lib/` caller of `claim_step/1`
          # (`runtime.ex:195`), so it closes the dispatched-Task race,
          # direct `Runtime.execute_step/2` calls, and adopter calls in one
          # place.
          run = Repo.one!(from(r in Run, where: r.id == ^step.run_id, lock: "FOR UPDATE"))

          if Run.halted?(run) do
            Repo.rollback(:run_halted)
          end

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

      # Captured BEFORE this transaction's own write (RAIL-01 D-17): true
      # only when `run` arrived already terminal (the G4 clamp path -- a
      # sibling whose transaction started reading `run` AFTER the halt
      # already committed). Threaded through so the post-commit
      # `maybe_emit_rail_observed/1` call below never double-emits for a
      # run that already emitted its one `:observed` event at its real
      # terminal transition.
      already_terminal? = Run.halted?(run)

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

      # G4 (RAIL-01 D-02): clamp the computed next status back to `run.status`
      # when `run` (read above) is already halted. See `clamp_run_status/2`
      # for the documented interleaving this does NOT cover.
      run_status =
        clamp_run_status(
          run,
          Keyword.get(opts, :run_status, if(pending_count == 0, do: "completed", else: "running"))
        )

      checkpoint =
        insert_checkpoint(
          repo,
          run.id,
          completed_step.id,
          replay_transition_checkpoint_attrs(
            run,
            "step_completed",
            run_status,
            result_envelope,
            :result
          )
        )

      insert_event(
        repo,
        run.id,
        completed_step.id,
        replay_transition_event_attrs(run, "step_completed", result_envelope, :result)
      )

      # When `run` is halted, suppress `completed_at`/`current_step_id`/
      # `error_envelope` from the changeset entirely (rather than writing
      # `run`'s own pre-halt values) so the halt's own values survive --
      # `Repo.update` SETs only `changeset.changes`, so an absent key is
      # never written.
      run_update_attrs =
        %{
          status: run_status,
          current_step_id: if(run_status == "completed", do: nil, else: completed_step.id),
          latest_checkpoint_id: checkpoint.id,
          completed_at: if(run_status == "completed", do: now, else: run.completed_at),
          error_envelope: %{}
        }
        |> suppress_when_halted(run, [:completed_at, :current_step_id, :error_envelope])

      updated_run =
        run
        |> Run.changeset(run_update_attrs)
        |> repo.update!()

      {updated_run, completed_step, checkpoint, already_terminal?}
    end)
    |> case do
      {:ok, {run, step, _checkpoint, already_terminal?}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        unless already_terminal?, do: maybe_emit_rail_observed(run)
        {:ok, step}

      {:error, value} ->
        {:error, value}
    end
  end

  def mark_waiting_for_approval(%Run{id: run_id}, %Step{id: step_id}, attrs),
    do: mark_waiting_for_approval(run_id, step_id, attrs)

  def mark_waiting_for_approval(run_id, step_id, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    attrs = Map.new(attrs)

    Repo.transaction(fn repo ->
      run = repo.get!(Run, run_id)
      step = repo.get!(Step, step_id)

      if step.run_id != run.id do
        repo.rollback(
          validation_changeset(%{workflow_run_id: run_id, workflow_step_id: step_id},
            workflow_step_id: "does not belong to workflow_run_id"
          )
        )
      end

      approval_identity = immutable_identity(run, attrs)

      # G6 (RAIL-01 D-02): without this clamp a sibling escalating after the
      # halt commits would rewrite "halted" to "waiting_for_approval", which
      # `resume_run/1` resumes.
      updated_run =
        repo.update!(
          Run.changeset(run, %{
            status: clamp_run_status(run, "waiting_for_approval"),
            current_step_id: step.id
          })
        )

      repo.update!(
        Step.changeset(step, %{status: "waiting_for_approval", started_at: step.started_at || now})
      )

      checkpoint =
        insert_checkpoint(
          repo,
          run.id,
          step.id,
          with_replay_evidence(run, attrs, %{
            transition: "waiting_for_approval",
            status: "waiting_for_approval",
            snapshot: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")},
            metadata: %{}
          })
        )

      insert_event(
        repo,
        run.id,
        step.id,
        with_replay_evidence(run, attrs, %{
          event_type: "waiting_for_approval",
          payload: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")}
        })
      )

      approval_attrs =
        attrs
        |> Map.new()
        |> enrich_remote_approval_attrs()
        |> Map.merge(%{
          actor_id: approval_identity.actor_id,
          tenant_id: approval_identity.tenant_id,
          session_id: approval_identity.session_id,
          workflow_run_id: run.id,
          step_id: step.id,
          checkpoint_id: checkpoint.id,
          status: "pending",
          run_id: run.id
        })
        |> merge_replay_approval_attrs(run)

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
        SRE.insert_audit_outbox_event(
          repo,
          %{
            tenant_id: approval_identity.tenant_id || "system",
            event_type: "approval.requested",
            policy_class: "approval",
            dedupe_key: Map.get(attrs, :dedupe_key) || Map.get(attrs, "dedupe_key"),
            actor_ref: approval_identity.actor_id,
            workflow_run_id: run.id,
            step_id: step.id,
            trace_id: Map.get(attrs, :trace_id) || Map.get(attrs, "trace_id"),
            approval_id: approval.id,
            tool_name: approval.tool_name,
            arguments: approval.arguments,
            reason: Map.get(attrs, :reason) || Map.get(attrs, "reason"),
            session_id: approval_identity.session_id,
            metadata: %{
              "checkpoint_id" => checkpoint.id,
              "root_identity" => stringify_map(Identity.to_map(approval_identity)),
              "run_status" => updated_run.status
            }
          }
          |> merge_replay_audit_attrs(run, approval)
        )

      approval =
        approval
        |> Approval.changeset(%{audit_outbox_event_id: audit_outbox_event.id})
        |> repo.update!()

      {updated_run, approval, audit_outbox_event}
    end)
    |> case do
      {:ok, {run, approval, audit_outbox_event}} ->
        SRE.emit_audit_outbox_telemetry(audit_outbox_event)
        broadcast(run.id, {:approval_requested, run.id, approval.id})

        projection = RemoteApprovalProjection.get_approval_lineage!(approval.id)
        ReviewerBroadcast.hitl_request(approval.tenant_id, projection)

        {:ok, approval}

      {:error, value} ->
        {:error, value}
    end
  end

  defp validation_changeset(attrs, errors) do
    changeset =
      {%{}, %{workflow_run_id: :binary_id, workflow_step_id: :binary_id}}
      |> cast(attrs, [:workflow_run_id, :workflow_step_id])

    Enum.reduce(errors, changeset, fn {field, message}, acc ->
      add_error(acc, field, message)
    end)
  end

  def request_remote_approval(%Run{id: run_id}, %Step{id: step_id}, attrs),
    do: request_remote_approval(run_id, step_id, attrs)

  def request_remote_approval(run_id, step_id, attrs) do
    attrs = Map.new(attrs)

    mark_waiting_for_approval(run_id, step_id, attrs)
  end

  def fail_step(step_or_id, error_envelope, opts \\ [])

  def fail_step(%Step{id: step_id}, error_envelope, opts),
    do: fail_step(step_id, error_envelope, opts)

  def fail_step(step_id, error_envelope, opts) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      step = repo.get!(Step, step_id)
      run = repo.get!(Run, step.run_id)

      # Captured BEFORE this transaction's own write (RAIL-01 D-17) --
      # see the identical comment in `complete_step/3`.
      already_terminal? = Run.halted?(run)

      # G5 (RAIL-01 D-02): the sneakiest of the three clamps -- without it a
      # sibling failing after the halt commits rewrites "halted" to
      # "failed", re-opening `resume_run/1`'s retry branch.
      run_status = clamp_run_status(run, Keyword.get(opts, :run_status, "failed"))

      failed_step =
        step
        |> Step.changeset(%{status: "failed", completed_at: now, error_envelope: error_envelope})
        |> repo.update!()

      checkpoint =
        insert_checkpoint(
          repo,
          run.id,
          failed_step.id,
          replay_transition_checkpoint_attrs(
            run,
            "step_failed",
            run_status,
            error_envelope,
            :error
          )
        )

      insert_event(
        repo,
        run.id,
        failed_step.id,
        replay_transition_event_attrs(run, "step_failed", error_envelope, :error)
      )

      updated_run =
        run
        |> Run.changeset(%{
          status: run_status,
          current_step_id: failed_step.id,
          latest_checkpoint_id: checkpoint.id,
          error_envelope: error_envelope
        })
        |> repo.update!()

      {updated_run, failed_step, already_terminal?}
    end)
    |> case do
      {:ok, {run, step, already_terminal?}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        unless already_terminal?, do: maybe_emit_rail_observed(run)
        {:ok, step}

      {:error, value} ->
        {:error, value}
    end
  end

  @doc """
  Terminally halts a run for exceeding a per-run rail (RAIL-01). Unlike
  `fail_step/3`, this is a new lifecycle transition -- it writes the new
  `"halted"` status (never `"failed"`), a dedicated `"run_halted"`
  checkpoint/event transition, and a `run.rail.tripped` audit-outbox row,
  all inside one transaction.

  `run_id` is locked `FOR UPDATE` FIRST, establishing a single global lock
  order (run before steps) shared with `claim_step/1`'s G1 guard -- this is
  what makes the two paths deadlock-free (56.1-CONTEXT.md D-04). A second
  `halt_run/3` call on an already-halted run rolls back with
  `{:error, :already_halted}`; a genuine race that instead surfaces as
  `Ecto.StaleEntryError` or a unique-constraint violation on the audit
  outbox's `dedupe_key` is normalized to the same value below.
  """
  @spec halt_run(binary() | Run.t(), binary() | nil, map()) ::
          {:ok, Run.t()} | {:error, :already_halted} | {:error, Ecto.Changeset.t()}
  def halt_run(%Run{id: run_id}, step_id, envelope), do: halt_run(run_id, step_id, envelope)

  def halt_run(run_id, step_id, envelope) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.transaction(fn repo ->
      run = repo.one!(from(r in Run, where: r.id == ^run_id, lock: "FOR UPDATE"))

      if Run.halted?(run) do
        repo.rollback(:already_halted)
      end

      if step_id do
        step = repo.get!(Step, step_id)

        step
        |> Step.changeset(%{status: "failed", completed_at: now, error_envelope: envelope})
        |> repo.update!()
      end

      {cancelled_sibling_count, _} =
        repo.update_all(
          from(s in Step, where: s.run_id == ^run.id and s.status in ["queued", "retrying"]),
          set: [status: "cancelled"]
        )

      checkpoint =
        insert_checkpoint(
          repo,
          run.id,
          step_id,
          replay_transition_checkpoint_attrs(run, "run_halted", "halted", envelope, :error)
        )

      insert_event(
        repo,
        run.id,
        step_id,
        replay_transition_event_attrs(run, "run_halted", envelope, :error)
      )

      audit_outbox_event =
        SRE.insert_audit_outbox_event(
          repo,
          halt_audit_envelope(run, step_id, envelope, cancelled_sibling_count)
        )

      updated_run =
        run
        |> Run.changeset(%{
          status: "halted",
          current_step_id: step_id,
          latest_checkpoint_id: checkpoint.id,
          error_envelope: envelope,
          completed_at: now
        })
        |> repo.update!()

      {updated_run, audit_outbox_event}
    end)
    |> case do
      {:ok, {run, audit_outbox_event}} ->
        broadcast(run.id, {:workflow_updated, run.id})
        emit_rail_tripped(run, audit_outbox_event, envelope)
        maybe_emit_rail_observed(run)
        {:ok, run}

      {:error, :already_halted} ->
        {:error, :already_halted}

      {:error, value} ->
        normalize_halt_error(value)
    end
  rescue
    _e in Ecto.StaleEntryError -> {:error, :already_halted}
  end

  defp normalize_halt_error(%Ecto.Changeset{} = changeset) do
    if unique_dedupe_error?(changeset) do
      {:error, :already_halted}
    else
      {:error, changeset}
    end
  end

  defp normalize_halt_error(value), do: {:error, value}

  defp unique_dedupe_error?(%Ecto.Changeset{} = changeset) do
    Enum.any?(changeset.errors, fn
      {:dedupe_key, {_message, metadata}} -> Keyword.get(metadata, :constraint) == :unique
      _ -> false
    end)
  end

  @rail_observed_terminal_statuses ~w(completed failed halted)

  # `[:scoria, :run, :rail, :observed]` fires exactly ONCE per run, at its
  # terminal transition ("completed", "failed", "halted") -- NEVER per
  # check (56.1-CONTEXT.md D-17). Called post-commit from the three --
  # and only three -- functions that write a terminal run status:
  # `complete_step/3`, `fail_step/3`, `halt_run/3`. That set is the choke
  # point; emitting from anywhere else would double-count. Each of those
  # three callers skips this call entirely when its own freshly-read
  # `%Run{}` arrived ALREADY terminal (the G4/G5 clamp path -- a sibling
  # whose transaction started reading `run` after a halt already
  # committed), so a run that transitions to "halted" and then has a
  # sibling step complete/fail against the already-halted row still emits
  # exactly one `:observed` event, not two.
  #
  # Frequency is once per run at the terminal transition, NOT per check:
  # sizing needs the distribution of final per-run totals, and a stream
  # of running counters would force every adopter to build a stateful
  # aggregator keyed by `run_id` with an eviction policy (nobody does
  # that) -- and threshold-crossing has no denominator because rails are
  # `nil` for essentially every adopter. A terminal event is
  # histogram-ready.
  #
  # Measurements separate `steps`, `tool_calls`, `active_ms`, `paused_ms`
  # and `wall_ms` as five distinct numbers, deliberately: a consumer must
  # be able to show what the rail measures (`active_ms`), the human wait
  # cost (`paused_ms`), and the derived wall-clock total (`wall_ms`)
  # separately, and must NEVER render `wall_ms` against the rail limit --
  # that re-teaches the wrong mental model (56.1-CONTEXT.md D-17, D-23).
  #
  # Cardinality contract: `run_id`, `step_id`, `trace_id` and
  # `audit_outbox_event_id` are unbounded and are included (where a given
  # `[:scoria, :run, :rail, *]` event carries them) deliberately as
  # correlation keys for log and trace joins, NEVER as metric tags -- the
  # safe-to-tag dimensions across the whole `[:scoria, :run, :rail, *]`
  # family are `rail`, `reason_code`, `unit`, `terminal_status`,
  # `tripped`, `reason` and `site`. `Observe.Bounds` does not apply here
  # -- its own docstring pins it to the span tree -- so cardinality
  # discipline is entirely ours; an adopter attaching a run id to a
  # counter and killing their Prometheus registry is the one foreseeable
  # way this contract hurts someone.
  #
  # Known, documented gap: a run wedged in "running" or parked in
  # `waiting_for_approval` never reaches a terminal transition and never
  # emits, so the sizing histogram this event feeds is a distribution
  # over terminated runs only.
  #
  # Wrapped in `try/rescue -> :ok` -- a broken adopter handler must not
  # break a run's terminal transition.
  defp maybe_emit_rail_observed(%Run{status: status} = run)
       when status in @rail_observed_terminal_statuses do
    try do
      now = DateTime.utc_now()
      anchor = run.started_at || run.inserted_at
      wall_ms = if anchor, do: DateTime.diff(now, anchor, :millisecond), else: 0
      paused_ms = run.rail_paused_ms || 0
      active_ms = wall_ms - paused_ms

      measurements = %{
        steps: run.rail_steps || 0,
        tool_calls: run.rail_tool_calls || 0,
        active_ms: active_ms,
        paused_ms: paused_ms,
        wall_ms: wall_ms
      }

      metadata = %{
        run_id: run.id,
        tenant_id: run.tenant_id,
        terminal_status: String.to_atom(status),
        tripped: status == "halted",
        max_steps: run.rail_max_steps,
        max_tool_calls: run.rail_max_tool_calls,
        max_active_ms: run.rail_max_active_ms,
        site: :workflow_lifecycle
      }

      :telemetry.execute([:scoria, :run, :rail, :observed], measurements, metadata)
    rescue
      _ -> :ok
    end
  end

  defp maybe_emit_rail_observed(_run), do: :ok

  # `[:scoria, :run, :rail, :tripped]` fires ONCE, post-commit, only on
  # `{:ok, run}` -- never on `{:error, :already_halted}`, because a host
  # looping against a halted run's id would otherwise produce a telemetry
  # storm (56.1-CONTEXT.md D-17). Wrapped in try/rescue so a broken adopter
  # handler cannot halt a halt.
  defp emit_rail_tripped(run, audit_outbox_event, envelope) do
    try do
      rail = attr_value(envelope, :rail)

      measurements = %{
        limit: attr_value(envelope, :limit),
        observed: attr_value(envelope, :observed),
        attempted: attr_value(envelope, :attempted)
      }

      metadata = %{
        rail: rail && String.to_atom(rail),
        reason_code: attr_value(envelope, :reason_code),
        unit: rail_unit(rail),
        run_id: run.id,
        step_id: audit_outbox_event.step_id,
        trace_id: audit_outbox_event.trace_id,
        tenant_id: audit_outbox_event.tenant_id,
        audit_outbox_event_id: audit_outbox_event.id,
        site: attr_value(envelope, :site) |> maybe_atomize()
      }

      :telemetry.execute([:scoria, :run, :rail, :tripped], measurements, metadata)
    rescue
      _ -> :ok
    end
  end

  defp maybe_atomize(nil), do: nil
  defp maybe_atomize(value) when is_binary(value), do: String.to_atom(value)
  defp maybe_atomize(value), do: value

  defp halt_audit_envelope(run, step_id, envelope, cancelled_sibling_count) do
    rail = attr_value(envelope, :rail)

    %{
      tenant_id: run.tenant_id || "system",
      workflow_run_id: run.id,
      step_id: step_id,
      trace_id: Observe.trace_id_for_run(run),
      actor_ref: "system:scoria.rails",
      event_type: "run.rail.tripped",
      policy_class: "run_rail",
      reason_code: attr_value(envelope, :reason_code),
      dedupe_key: "run.rail.tripped:" <> run.id,
      metadata: %{
        "rail" => rail,
        "limit" => attr_value(envelope, :limit),
        "observed" => attr_value(envelope, :observed),
        "attempted" => attr_value(envelope, :attempted),
        "unit" => rail_unit(rail),
        "check_order" => rail_check_order(rail),
        "rails_snapshot" => rails_snapshot(run),
        "halting_step_id" => step_id,
        "cancelled_sibling_count" => cancelled_sibling_count,
        "run_actor_id" => run.actor_id,
        "run_started_at" => run.started_at && DateTime.to_iso8601(run.started_at),
        "run_paused_ms" => run.rail_paused_ms,
        "run_status_after" => "halted"
      }
    }
  end

  # Computed eagerly from the already-locked run row (Claude's Discretion 3)
  # -- all three legs, INCLUDING the untripped ones, at zero extra queries.
  defp rails_snapshot(run) do
    %{
      "max_steps" => %{"limit" => run.rail_max_steps, "observed" => run.rail_steps},
      "max_tool_calls" => %{"limit" => run.rail_max_tool_calls, "observed" => run.rail_tool_calls},
      "max_active_ms" => %{"limit" => run.rail_max_active_ms, "observed" => observed_active_ms(run)}
    }
  end

  defp observed_active_ms(%Run{started_at: nil, inserted_at: nil}), do: 0

  defp observed_active_ms(run) do
    anchor = run.started_at || run.inserted_at
    DateTime.diff(DateTime.utc_now(), anchor, :millisecond) - (run.rail_paused_ms || 0)
  end

  defp rail_unit("max_active_ms"), do: "ms"
  defp rail_unit(_rail), do: "count"

  defp rail_check_order("max_active_ms"), do: 1
  defp rail_check_order("max_steps"), do: 2
  defp rail_check_order("max_tool_calls"), do: 3
  defp rail_check_order(_rail), do: nil

  # G4/G5/G6 (RAIL-01 D-02): the completion-side clamp. Takes the
  # freshly-read `%Run{}` and the computed next status, returning
  # `run.status` unchanged when the run is already halted, otherwise the
  # computed status.
  #
  # ACCEPTED, DOCUMENTED GAP -- do not try to fix this by catching and
  # retrying: `optimistic_lock(:lock_version)` force-changes `lock_version`
  # on every `Run.changeset/2` write. A sibling ALREADY inside
  # `complete_step/3` (or `fail_step/3`/`mark_waiting_for_approval/3`) --
  # i.e. one that read `run` BEFORE this transaction's halt committed --
  # never reaches this clamp at all: its own final `repo.update!` raises
  # `Ecto.StaleEntryError`, unwinding that WHOLE transaction, including the
  # step's own "completed"/"failed" write. The step strands in whatever
  # status it was in and its result/error envelope is lost. Correctness
  # survives either way (no resurrection), but evidence does not. This
  # clamp covers only siblings whose transaction STARTS reading `run` after
  # the halt has already committed. Writing catch-and-retry code for the
  # stale-copy path would silently resurrect the exact race the run-first
  # lock order (D-04) exists to prevent.
  defp clamp_run_status(%Run{} = run, computed_status) do
    if Run.halted?(run), do: run.status, else: computed_status
  end

  # Drops `keys` from `attrs` when `run` is halted, so `Repo.update` (which
  # SETs only `changeset.changes`) never touches them -- the halt's own
  # values for those fields survive untouched.
  defp suppress_when_halted(attrs, %Run{} = run, keys) do
    if Run.halted?(run), do: Map.drop(attrs, keys), else: attrs
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

      # G2 (RAIL-01 D-02): this is the path ROADMAP SC#2 names through
      # `Resume.retry_failed_step/2`, which performs no status check of its
      # own -- refusing here is the only place that guards it.
      if Run.halted?(run) do
        repo.rollback(:run_not_retryable)
      end

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

    case {run.status, List.last(run.checkpoints), current_approved_approval(run)} do
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
    attrs = Map.new(attrs)

    Repo.transaction(fn repo ->
      approval = repo.get!(Approval, approval_id)

      if approval.status != "pending" do
        repo.rollback(:not_pending)
      end

      audit_context = approval_decision_context(repo, approval, attrs)

      update_attrs =
        attrs
        |> Map.drop([:actor_id, "actor_id", :tenant_id, "tenant_id", :session_id, "session_id"])
        |> Map.put(:status, status)

      updated_approval =
        approval
        |> Approval.changeset(update_attrs)
        |> repo.update!()

      audit_outbox_event =
        SRE.insert_audit_outbox_event(
          repo,
          %{
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
            request_actor_ref:
              audit_context.request_event && audit_context.request_event.actor_ref,
            session_id: audit_context.session_id,
            metadata: %{
              "decision_actor_id" => attr_value(attrs, :actor_id),
              "root_identity" =>
                stringify_map(%{
                  actor_id: audit_context.actor_id,
                  tenant_id: audit_context.tenant_id,
                  session_id: audit_context.session_id
                })
            }
          }
          |> merge_replay_audit_attrs(audit_context.run, updated_approval)
        )

      {updated_approval, audit_outbox_event}
    end)
    |> case do
      {:ok, {updated_approval, audit_outbox_event}} ->
        SRE.emit_audit_outbox_telemetry(audit_outbox_event)

        ReviewerBroadcast.approval_decided(
          updated_approval.tenant_id,
          updated_approval.id,
          status
        )

        {:ok, updated_approval}

      {:error, :not_pending} ->
        {:error, :not_pending}

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

    event =
      %Event{}
      |> Event.changeset(
        attrs
        |> Map.put(:run_id, run_id)
        |> Map.put(:step_id, step_id)
        |> Map.put(:sequence, sequence)
      )
      |> repo.insert!()

    _ = EventCompactor.maybe_enqueue_compaction(repo, run_id)
    event
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

  defp current_approved_approval(%Run{} = run) do
    latest_checkpoint = List.last(run.checkpoints)

    run.approvals
    |> Enum.reverse()
    |> Enum.find(fn approval ->
      (approval.status == "approved" and
         approval.step_id == run.current_step_id and
         latest_checkpoint) && approval.checkpoint_id == latest_checkpoint.id
    end)
  end

  defp approval_decision_context(repo, approval, attrs) do
    request_event = approval_request_event(repo, approval)
    run = approval.workflow_run_id && repo.get(Run, approval.workflow_run_id)
    identity = immutable_identity(run || %Run{}, approval)

    %{
      tenant_id: identity.tenant_id || (request_event && request_event.tenant_id) || "system",
      actor_id: identity.actor_id || (request_event && request_event.actor_ref),
      session_id:
        identity.session_id ||
          (request_event && get_in(request_event.metadata || %{}, ["root_identity", "session_id"])),
      trace_id: attr_value(attrs, :trace_id) || (request_event && request_event.trace_id),
      request_event: request_event,
      run: run
    }
  end

  defp merge_replay_approval_attrs(attrs, %Run{} = run) do
    if run.execution_mode == "replay" do
      replay_evidence = replay_approval_evidence(run, attrs)

      attrs
      |> Map.put_new(:replay_disposition, "blocked")
      |> Map.put_new(:replay_scope, "replay_live")
      |> Map.put_new(:replay_reason_code, Map.fetch!(replay_evidence, :replay_reason_code))
      |> Map.put_new(:source_run_id, replay_evidence.source_run_id)
      |> Map.put_new(:source_checkpoint_id, replay_evidence.source_checkpoint_id)
      |> Map.put_new(:source_step_id, replay_evidence.source_step_id)
      |> Map.put_new(:source_approval_id, replay_evidence.source_approval_id)
      |> Map.put_new(:source_audit_outbox_event_id, replay_evidence.source_audit_outbox_event_id)
      |> Map.put_new(:args_fingerprint, replay_evidence.args_fingerprint)
      |> Map.put_new(:subject_ref, replay_evidence.subject_ref)
      |> Map.put_new(:required_scopes, replay_evidence.required_scopes)
      |> Map.put_new(:policy_key, replay_evidence.policy_key)
      |> Map.put_new(:executed_live, false)
    else
      attrs
    end
  end

  defp with_replay_evidence(%Run{} = run, attrs, payload) do
    if run.execution_mode == "replay" do
      evidence = replay_approval_evidence(run, attrs)
      replay_scope = attr_value(attrs, :replay_scope) || "replay_live"

      replay_fields =
        replay_metadata_fields(evidence, replay_scope, attr_value(attrs, :executed_live) || false)

      payload
      |> Map.put(:replay_disposition, Atom.to_string(evidence.replay_disposition))
      |> Map.put(:replay_reason_code, evidence.replay_reason_code)
      |> Map.update(:metadata, replay_fields, &Map.merge(&1 || %{}, replay_fields))
      |> maybe_merge_replay_payload(replay_fields)
    else
      payload
    end
  end

  defp merge_replay_audit_attrs(envelope, %Run{} = run, approval) do
    if run.execution_mode == "replay" do
      evidence = replay_approval_evidence(run, approval)

      envelope
      |> Map.put(:replay_disposition, Atom.to_string(evidence.replay_disposition))
      |> Map.put(:replay_reason_code, evidence.replay_reason_code)
      |> Map.put(:source_run_id, evidence.source_run_id)
      |> Map.put(:source_checkpoint_id, evidence.source_checkpoint_id)
      |> Map.put(:source_step_id, evidence.source_step_id)
      |> Map.put(:source_approval_id, evidence.source_approval_id)
      |> Map.put(:source_audit_outbox_event_id, evidence.source_audit_outbox_event_id)
      |> Map.put(:args_fingerprint, evidence.args_fingerprint)
      |> Map.put(:policy_key, evidence.policy_key)
      |> Map.put(:executed_live, false)
      |> Map.put_new(:replay_idempotency_key, Map.get(approval, :replay_idempotency_key))
    else
      envelope
    end
  end

  defp merge_replay_audit_attrs(envelope, _run, _approval), do: envelope

  defp replay_transition_checkpoint_attrs(
         %Run{} = run,
         transition,
         status,
         envelope,
         envelope_key
       ) do
    replay_fields =
      if run.execution_mode == "replay" do
        replay_transition_fields(envelope)
      else
        %{}
      end

    %{
      transition: transition,
      status: status,
      snapshot: %{:"#{envelope_key}_envelope" => envelope},
      metadata: replay_fields
    }
    |> maybe_put_replay_transition_columns(replay_fields)
  end

  defp replay_transition_event_attrs(%Run{} = run, event_type, envelope, envelope_key) do
    replay_fields =
      if run.execution_mode == "replay" do
        replay_transition_fields(envelope)
      else
        %{}
      end

    %{
      event_type: event_type,
      payload: Map.merge(%{:"#{envelope_key}_envelope" => envelope}, replay_fields)
    }
    |> maybe_put_replay_transition_columns(replay_fields)
  end

  defp maybe_put_replay_transition_columns(attrs, %{
         "replay_disposition" => disposition,
         "replay_reason_code" => reason
       })
       when not is_nil(disposition) and not is_nil(reason) do
    attrs
    |> Map.put(:replay_disposition, disposition)
    |> Map.put(:replay_reason_code, reason)
  end

  defp maybe_put_replay_transition_columns(attrs, _replay_fields), do: attrs

  defp replay_transition_fields(envelope) when is_map(envelope) do
    [
      "replay_disposition",
      "replay_reason_code",
      "source_run_id",
      "source_checkpoint_id",
      "source_step_id",
      "source_approval_id",
      "source_audit_outbox_event_id",
      "args_fingerprint",
      "subject_ref",
      "required_scopes",
      "policy_key",
      "replay_scope",
      "executed_live",
      "replay_idempotency_key"
    ]
    |> Enum.reduce(%{}, fn key, acc ->
      case attr_value(envelope, String.to_atom(key)) do
        nil -> acc
        value -> Map.put(acc, key, value)
      end
    end)
  end

  defp replay_transition_fields(_envelope), do: %{}

  defp replay_metadata_fields(evidence, replay_scope, executed_live) do
    replay_transition_fields(evidence)
    |> Map.put("replay_scope", replay_scope)
    |> Map.put("executed_live", executed_live)
  end

  defp maybe_merge_replay_payload(payload, replay_fields) do
    if Map.has_key?(payload, :payload) do
      Map.update!(payload, :payload, &Map.merge(&1 || %{}, replay_fields))
    else
      payload
    end
  end

  defp replay_evidence(%Run{} = run, attrs) do
    seam = %{
      local_classification: :write,
      tool_id: attr_value(attrs, :local_tool_name) || attr_value(attrs, :tool_name),
      action_class: "write",
      risk_level: "high",
      approval_sensitive: true,
      args_fingerprint: attr_value(attrs, :args_fingerprint),
      subject_ref: attr_value(attrs, :subject_ref) || attr_value(attrs, :grant_subject_ref),
      required_scopes:
        attr_value(attrs, :required_scopes) || attr_value(attrs, :requested_scopes) || [],
      grant_state: attr_value(attrs, :grant_status),
      policy_key: attr_value(attrs, :policy_key)
    }

    source_evidence = %{
      source_run_id: run.source_run_id,
      source_checkpoint_id: run.source_checkpoint_id,
      source_step_id: attr_value(attrs, :source_step_id),
      source_approval_id: attr_value(attrs, :source_approval_id),
      source_audit_outbox_event_id: attr_value(attrs, :source_audit_outbox_event_id),
      args_fingerprint: attr_value(attrs, :args_fingerprint),
      subject_ref: attr_value(attrs, :subject_ref) || attr_value(attrs, :grant_subject_ref),
      required_scopes:
        attr_value(attrs, :required_scopes) || attr_value(attrs, :requested_scopes) || [],
      grant_state: attr_value(attrs, :grant_status),
      policy_key: attr_value(attrs, :policy_key),
      tool_id: attr_value(attrs, :local_tool_name) || attr_value(attrs, :tool_name)
    }

    {_disposition, evidence} = ReplayDisposition.resolve(run, seam, source_evidence, %{}, %{})

    Map.put(evidence, :replay_reason_code, "fresh_replay_approval_required")
  end

  defp replay_approval_evidence(%Run{} = run, attrs) do
    run
    |> replay_evidence(attrs)
    |> Map.put(:replay_disposition, :blocked)
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

  defp enrich_remote_approval_attrs(attrs) do
    connector_id = attr_value(attrs, :connector_id)
    local_tool_id = attr_value(attrs, :local_tool_id)

    connector =
      case connector_id do
        nil -> nil
        id -> Repo.get(Connector, id)
      end

    local_tool =
      case local_tool_id do
        nil -> nil
        id -> Repo.get(LocalTool, id)
      end

    attrs
    |> Map.put_new(:connector_label, connector && connector.label)
    |> Map.put_new(:connector_key, connector && connector.key)
    |> Map.put_new(:local_tool_name, local_tool && local_tool.display_name)
    |> Map.update(:missing_scopes, [], fn scopes ->
      Enum.map(List.wrap(scopes), fn scope -> to_string(scope) end)
    end)
    |> Map.update(:requested_scopes, [], fn scopes ->
      Enum.map(List.wrap(scopes), fn scope -> to_string(scope) end)
    end)
  end

  defp run_attrs_with_identity(run_attrs, identity) do
    run_attrs
    |> Map.put(:actor_id, identity.actor_id)
    |> Map.put(:tenant_id, identity.tenant_id)
    |> Map.put(:session_id, identity.session_id)
    |> Map.put(:metadata, Identity.metadata(run_attrs))
  end

  defp stringify_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp immutable_identity(%Run{} = run, fallback_attrs) do
    root_identity =
      Identity.normalize(%{
        actor_id: run.actor_id,
        tenant_id: run.tenant_id,
        session_id: run.session_id,
        metadata: run.metadata
      })

    fallback_identity = Identity.normalize(fallback_attrs)

    %Identity{
      root_identity
      | actor_id: root_identity.actor_id || fallback_identity.actor_id,
        tenant_id: root_identity.tenant_id || fallback_identity.tenant_id,
        session_id: root_identity.session_id || fallback_identity.session_id
    }
  end
end
