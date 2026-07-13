defmodule Scoria.Runtime do
  @moduledoc """
  `Scoria.Runtime` exposes the durable run lifecycle behind the top-level
  `Scoria` facade.

  Most host apps should call `Scoria` directly. This module exists for the
  deeper lifecycle layer once you already have canonical identity and want the
  underlying start, resume, and inspection primitives spelled out explicitly.

  The same identity contract still applies here: `session_id` groups continuity
  across related turns, while `run_id` identifies one exact durable run for
  inspection or resume.

  Use this module when building framework adapters, tests, or advanced runtime
  integrations that need direct access to start/resume/read APIs. The default
  runtime path does not require semantic cache, optional knowledge base,
  connector, or MCP setup.

  For the copyable first-run sequence, see `guides/golden-path.md`. For the
  default runtime capability and optional expansion points, see
  `guides/capabilities/default-runtime.md`.
  """

  import Ecto.Query, warn: false

  alias Ecto.NoResultsError
  alias Scoria.Repo
  alias Scoria.Runtime.{Instance, Params, ReplayComparison, RunDetail, RunSummary}
  alias Scoria.SemanticCache
  alias Scoria.SemanticCache.Entry
  alias Scoria.Workflows
  alias Scoria.Workflows.{Reconciler, Resume, Run}

  @doc """
  Starts a new run from canonical identity plus explicit runtime options.

  Wires G1 -- the release gate -- into a guardrail span (D-03d, D-05*).
  `ReleaseGate.check/1` runs BEFORE a run exists, so its outcome is carried
  forward and the guardrail span is emitted at the right point for each
  path: AFTER `Workflows.create_run/1` succeeds on the allowed path (the
  new run's id becomes the trace's `trace_id`, D-03a), immediately with a
  freshly-minted `trace_id` on the blocked path (a blocked run produces a
  legitimate ONE-SPAN TRACE, not an orphan), and not at all when the gate
  is not applicable (D-05d -- a host with no prompt policy configured must
  not get a meaningless guardrail span on every run). This function's
  return contract is unchanged: the guardrail span is a side effect, never
  a control-flow change.
  """
  def start_run(identity, opts \\ []) do
    with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
           Params.start(identity, opts) do
      guardrail_applicable? = prompt_ref_configured?(workflow_attrs)
      guardrail_started_wall = DateTime.utc_now()
      guardrail_start_mono = System.monotonic_time()

      case Scoria.Runtime.ReleaseGate.check(workflow_attrs) do
        :ok ->
          start_run_after_gate(
            workflow_attrs,
            dispatch_opts,
            guardrail_applicable?,
            guardrail_started_wall,
            guardrail_start_mono
          )

        {:error, reason} = error ->
          emit_g1_block(reason, guardrail_started_wall, guardrail_start_mono)
          error
      end
    end
  end

  defp start_run_after_gate(
         workflow_attrs,
         dispatch_opts,
         guardrail_applicable?,
         guardrail_started_wall,
         guardrail_start_mono
       ) do
    case Scoria.Workflows.Runtime.prepare_semantic_fast_path(workflow_attrs) do
      {:hit, prepared_attrs, entry} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs) do
          emit_g1_allow(guardrail_applicable?, run, guardrail_started_wall, guardrail_start_mono)

          with {:ok, _completed_run} <-
                 Scoria.Workflows.Runtime.complete_semantic_fast_path_hit(run, entry) do
            {:ok, get_run!(run.id)}
          end
        end

      {:continue, prepared_attrs} ->
        with {:ok, run} <- Workflows.create_run(prepared_attrs) do
          emit_g1_allow(guardrail_applicable?, run, guardrail_started_wall, guardrail_start_mono)

          with {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
            {:ok, get_run!(run.id)}
          end
        end
    end
  end

  # G1's not-applicable predicate (D-05d): mirrors ONLY the prompt_ref
  # key-shape match inside `ReleaseGate.check/1`'s `%{metadata: metadata}`
  # clause (release_gate.ex:36-44) -- whether a prompt_ref is resolvable
  # from the workflow attrs' metadata at all, the same question that
  # decides `check/1`'s no-op fall-through. `release_gate.ex` is untouched
  # by this plan (its return contract is a locked acceptance criterion,
  # `git diff lib/scoria/runtime/release_gate.ex` must stay empty), so this
  # predicate cannot be shared as a function call into that module; it is
  # intentionally narrow to just the key-shape question, not the deeper
  # UUID-cast/`Repo.get` resolution `check/1` performs beyond it.
  defp prompt_ref_configured?(%{metadata: metadata}) when is_map(metadata) do
    case metadata do
      %{"runtime" => %{"prompt_policy" => %{prompt_ref: id}}} when is_binary(id) -> true
      %{"runtime" => %{"prompt_policy" => %{"prompt_ref" => id}}} when is_binary(id) -> true
      %{"runtime" => %{"prompt_ref" => id}} when is_binary(id) -> true
      _ -> false
    end
  end

  defp prompt_ref_configured?(_workflow_attrs), do: false

  # G1's single allow-path emit site (D-03d): both `prepare_semantic_fast_path/1`
  # branches create a run via `Workflows.create_run/1` and both call this
  # helper, so there is one emit call, not two. Emits AFTER the run exists
  # -- `run.id` becomes the trace's `trace_id` (D-03a) -- and stays silent
  # when the gate was not applicable (D-05d).
  defp emit_g1_allow(false, _run, _started_wall, _start_mono), do: :ok

  defp emit_g1_allow(true, run, started_wall, start_mono) do
    Scoria.Observe.Guardrail.emit(%{
      name: "release_gate",
      decision: "allow",
      trace_id: Scoria.Observe.trace_id_for_run(run),
      parent_id: nil,
      tenant_id: run.tenant_id,
      workflow_run_id: run.id,
      session_id: run.session_id,
      started_wall: started_wall,
      start_mono: start_mono
    })
  end

  # G1's blocked-path emit (D-03d): no run exists and none will be created,
  # so a freshly-minted `trace_id` roots a ONE-SPAN TRACE -- the legitimate,
  # intentional shape a blocked run produces, not an orphan-span bug.
  # `ReleaseGate.check/1`'s three error atoms are the exact vocabulary
  # `Semconv`'s guardrail reason_code enum closes over (D-05f); the
  # `{:eval_not_passing, verdict}` verdict struct is dropped here so only
  # the bare atom reaches `Guardrail.emit/1` (T-53-05) -- a verdict struct
  # carries scores and potentially judge output, none of which belongs on
  # a span.
  defp emit_g1_block(reason, started_wall, start_mono) do
    Scoria.Observe.Guardrail.emit(%{
      name: "release_gate",
      decision: "block",
      reason_code: block_reason_code(reason),
      trace_id: Ecto.UUID.generate(),
      parent_id: nil,
      started_wall: started_wall,
      start_mono: start_mono
    })
  end

  defp block_reason_code(:unapproved_draft), do: :unapproved_draft
  defp block_reason_code({:eval_not_passing, _verdict}), do: :eval_not_passing
  defp block_reason_code(:eval_required), do: :eval_required
  defp block_reason_code(other), do: other

  @doc """
  Starts a bounded delegated run with one explicit handoff and queued child step.
  """
  def start_handoff_run(identity, delegated_role_id, opts \\ []) do
    with {:ok, %{workflow_attrs: workflow_attrs, handoff_attrs: handoff_attrs, dispatch_opts: dispatch_opts}} <-
           Params.start_handoff(identity, delegated_role_id, opts),
         {:ok, run} <- Workflows.create_run(workflow_attrs),
         {:ok, step} <-
           Workflows.create_step(run.id, %{
             sequence: 1,
             kind: "handoff",
             role_id: workflow_attrs.root_role_id,
             status: "queued"
           }),
         {:ok, _completed_step} <-
           Scoria.Workflows.Runtime.execute_step(step.id,
             handler: fn _step, _run -> {:handoff, handoff_attrs} end
           ),
         {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
      {:ok, get_run!(run.id)}
    end
  end

  @doc """
  Resumes an existing run by exact durable `run_id`.
  """
  def resume_run(run_id, opts \\ []) do
    with {:ok, dispatch_opts} <- Params.resume(run_id, opts),
         {:ok, run} <- Resume.resume_run(run_id, dispatch_opts) do
      {:ok, RunSummary.from_run(run)}
    end
  end

  @doc """
  Returns the stable public summary for a run.
  """
  def get_run(run_id) do
    {:ok, get_run!(run_id)}
  rescue
    NoResultsError -> {:error, :not_found}
  end

  @doc """
  Returns the stable public summary for a run or raises.
  """
  def get_run!(run_id) do
    run_id
    |> Workflows.get_run!()
    |> RunSummary.from_run()
  end

  @doc """
  Returns the curated detailed public view for a run.
  """
  def get_run_detail(run_id) do
    {:ok, get_run_detail!(run_id)}
  rescue
    NoResultsError -> {:error, :not_found}
  end

  @doc """
  Returns the curated detailed public view for a run or raises.
  """
  def get_run_detail!(run_id) do
    run = Workflows.get_run_tree!(run_id)
    source_run = load_source_run(run)

    RunDetail.from_run_tree(run,
      semantic_evidence: build_semantic_evidence(run),
      comparison_by_step: ReplayComparison.build(run, source_run),
      replay_provenance_strip: ReplayComparison.provenance_strip(run)
    )
  end

  @doc """
  Lists runs that share the same host-owned `session_id`.
  """
  def list_runs_for_session(session_id) do
    Run
    |> where([run], run.session_id == ^session_id)
    |> order_by([run], desc: run.inserted_at, desc: run.id)
    |> Repo.all()
    |> Enum.map(&RunSummary.from_run/1)
  end

  @doc """
  Registers or updates a durable runtime instance presence.
  """
  def register_instance(attrs) when is_map(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    attrs_string = for {k, v} <- attrs, into: %{}, do: {to_string(k), v}
    
    instance = 
      cond do
        id = attrs_string["id"] -> Repo.get(Instance, id) || %Instance{}
        host_session_id = attrs_string["host_session_id"] -> 
          Repo.get_by(Instance, host_session_id: host_session_id) || %Instance{}
        true -> %Instance{}
      end
      
    # Only set first_seen_at if it's a new instance (or hasn't been set)
    attrs_string = 
      if instance.first_seen_at do
        attrs_string
      else
        Map.put_new(attrs_string, "first_seen_at", now)
      end
      |> Map.put("last_seen_at", now)
      |> Map.put("terminal_offline_reason", nil)
      
    instance
    |> Instance.changeset(attrs_string)
    |> Repo.insert_or_update()
  end

  @doc """
  Marks a runtime instance as offline with a reason.
  """
  def mark_offline(instance_id, reason) when is_binary(instance_id) and is_binary(reason) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    case Repo.get(Instance, instance_id) do
      nil -> {:error, :not_found}
      instance ->
        instance
        |> Instance.changeset(%{
          "last_seen_at" => now, 
          "terminal_offline_reason" => reason
        })
        |> Repo.update()
    end
  end

  @doc """
  Lists compacted memories for a given run, ordered by sequence.
  """
  def list_compacted_memories_for_run(run_id) do
    Scoria.Runtime.CompactedMemory
    |> where([m], m.run_id == ^run_id)
    |> order_by([m], asc: m.start_sequence)
    |> Repo.all()
  end

  defp maybe_dispatch(_run_id, dispatch_opts) when dispatch_opts == [] or dispatch_opts == %{},
    do: {:ok, 0}

  defp maybe_dispatch(run_id, dispatch_opts), do: Reconciler.dispatch_run(run_id, dispatch_opts)

  defp build_semantic_evidence(%Run{} = run) do
    runtime_semantic = get_in(run.metadata || %{}, ["runtime", "semantic_cache"])
    step_semantic = step_semantic_cache_result(run)

    if is_map(runtime_semantic) or is_map(step_semantic) do
      entry_id = semantic_entry_id(runtime_semantic, step_semantic)
      candidate_entry_id = map_value(runtime_semantic, "candidate_entry_id")
      entry = load_semantic_entry(entry_id)
      candidate_entry = load_semantic_entry(candidate_entry_id)
      events = semantic_events(entry, candidate_entry)

      %{
        summary: semantic_summary(runtime_semantic, step_semantic, entry, candidate_entry, run),
        candidate: semantic_candidate(runtime_semantic, candidate_entry),
        compatibility: semantic_compatibility(runtime_semantic, entry, candidate_entry, run),
        provenance: semantic_provenance(runtime_semantic, step_semantic, entry, candidate_entry, run),
        lifecycle: semantic_lifecycle(entry, candidate_entry, step_semantic),
        events: events,
        raw_metadata: %{
          runtime_semantic_cache: runtime_semantic || %{},
          step_semantic_cache: step_semantic || %{}
        }
      }
    else
      %{}
    end
  end

  defp step_semantic_cache_result(%Run{} = run) do
    run.steps
    |> Enum.sort_by(&{&1.sequence || 0, &1.inserted_at || ~U[1970-01-01 00:00:00Z]})
    |> Enum.reverse()
    |> Enum.find_value(fn step ->
      semantic_cache = map_value(step.result_envelope, "semantic_cache")

      if is_map(semantic_cache), do: semantic_cache, else: nil
    end)
  end

  defp semantic_entry_id(runtime_semantic, step_semantic) do
    map_value(runtime_semantic, "entry_id") || map_value(step_semantic, "entry_id")
  end

  defp load_semantic_entry(nil), do: nil
  defp load_semantic_entry(entry_id), do: Repo.get(Entry, entry_id)

  defp semantic_events(nil, nil), do: []

  defp semantic_events(entry, candidate_entry) do
    [entry, candidate_entry]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(& &1.id)
    |> Enum.flat_map(fn semantic_entry ->
      label =
        if candidate_entry != nil and semantic_entry.id == candidate_entry.id and
             (entry == nil or entry.id != candidate_entry.id) do
          "candidate"
        else
          "selected"
        end

      semantic_entry.id
      |> SemanticCache.list_events()
      |> Enum.map(fn event ->
        %{
          entry_id: semantic_entry.id,
          entry_role: label,
          event_id: event.id,
          event_kind: event.event_kind,
          reason_code: event.reason_code,
          workflow_run_id: event.workflow_run_id,
          span_id: event.span_id,
          metadata: event.metadata || %{},
          inserted_at: event.inserted_at
        }
      end)
    end)
    |> Enum.sort_by(&{&1.inserted_at || ~U[1970-01-01 00:00:00Z], &1.event_id})
  end

  defp semantic_summary(runtime_semantic, step_semantic, entry, candidate_entry, run) do
    lookup_status = map_value(runtime_semantic, "lookup_status")
    entry_source = entry || candidate_entry

    %{
      verdict: lookup_status || map_value(step_semantic, "status") || "not_evaluated",
      lookup_status: lookup_status,
      eligibility_status: map_value(runtime_semantic, "eligibility_status"),
      eligibility_reason_code: map_value(runtime_semantic, "eligibility_reason_code"),
      lookup_reason_code: map_value(runtime_semantic, "lookup_reason_code"),
      candidate_status: map_value(runtime_semantic, "candidate_status") || (candidate_entry && candidate_entry.status),
      fallback_executed: lookup_status in ["bypass", "miss", "reject"],
      fallback_outcome: fallback_outcome(lookup_status, step_semantic),
      reason_code:
        map_value(runtime_semantic, "lookup_reason_code") ||
          map_value(runtime_semantic, "eligibility_reason_code") ||
          (entry_source && entry_source.state_reason_code),
      lane_key: semantic_lane_key(runtime_semantic, entry_source),
      scope_kind: map_value(runtime_semantic, "scope_kind") || (entry_source && entry_source.scope_kind),
      scope_reason: map_value(runtime_semantic, "scope_reason") || (entry_source && entry_source.scope_reason),
      workflow_run_id: run.id
    }
  end

  defp semantic_candidate(runtime_semantic, candidate_entry) do
    %{
      candidate_entry_id: map_value(runtime_semantic, "candidate_entry_id"),
      candidate_status: map_value(runtime_semantic, "candidate_status") || (candidate_entry && candidate_entry.status),
      state_reason_code: candidate_entry && candidate_entry.state_reason_code,
      actor_id: candidate_entry && candidate_entry.actor_id,
      tenant_id: candidate_entry && candidate_entry.tenant_id
    }
  end

  defp semantic_compatibility(runtime_semantic, entry, candidate_entry, run) do
    runtime_defaults = get_in(run.metadata || %{}, ["runtime"]) || %{}
    entry_source = entry || candidate_entry

    %{
      prompt_ref: entry_source && entry_source.prompt_ref || Map.get(runtime_defaults, "prompt_ref"),
      prompt_version: entry_source && entry_source.prompt_version || Map.get(runtime_defaults, "prompt_version"),
      policy_key: entry_source && entry_source.policy_key || Map.get(runtime_defaults, "policy_key"),
      policy_fingerprint: entry_source && entry_source.policy_fingerprint,
      source_fingerprint: entry_source && entry_source.source_fingerprint,
      provider: entry_source && entry_source.provider || Map.get(runtime_defaults, "provider"),
      model: entry_source && entry_source.model || Map.get(runtime_defaults, "model"),
      lane_key: semantic_lane_key(runtime_semantic, entry_source),
      lane_module: map_value(runtime_semantic, "lane_module") || (entry_source && entry_source.lane_module)
    }
  end

  defp semantic_provenance(runtime_semantic, step_semantic, entry, candidate_entry, run) do
    entry_source = entry || candidate_entry

    %{
      entry_id: entry && entry.id,
      candidate_entry_id: candidate_entry && candidate_entry.id,
      origin_run_id:
        map_value(runtime_semantic, "origin_run_id") ||
          map_value(step_semantic, "origin_run_id") ||
          (entry_source && entry_source.origin_run_id),
      origin_span_id: entry_source && entry_source.origin_span_id,
      origin_retrieval_run_id: entry_source && entry_source.origin_retrieval_run_id,
      workflow_run_id: run.id,
      workflow_run_href: "/workflows/#{run.id}",
      origin_run_href: origin_run_href(runtime_semantic, step_semantic, entry_source),
      actor_id: semantic_actor_id(runtime_semantic, entry_source),
      tenant_id: map_value(runtime_semantic, "tenant_id") || (entry_source && entry_source.tenant_id)
    }
  end

  defp semantic_lifecycle(entry, candidate_entry, step_semantic) do
    entry_source = entry || candidate_entry

    %{
      status:
        (entry_source && entry_source.status) ||
          map_value(step_semantic, "status"),
      state_reason_code: entry_source && entry_source.state_reason_code,
      expires_at: entry_source && entry_source.expires_at,
      invalidated_at: entry_source && entry_source.invalidated_at,
      hit_count: entry_source && entry_source.hit_count,
      last_hit_at: entry_source && entry_source.last_hit_at,
      inserted_at: entry_source && entry_source.inserted_at,
      updated_at: entry_source && entry_source.updated_at
    }
  end

  defp fallback_outcome("hit", _step_semantic), do: "semantic_reuse"
  defp fallback_outcome(status, %{} = step_semantic) when status in ["bypass", "miss", "reject"] do
    case map_value(step_semantic, "status") do
      "admitted" -> "live_execution_admitted"
      "writeback_rejected" -> "live_execution_writeback_rejected"
      _ -> "normal_runtime_path_executed"
    end
  end

  defp fallback_outcome(status, _step_semantic) when status in ["bypass", "miss", "reject"],
    do: "normal_runtime_path_executed"

  defp fallback_outcome(_status, _step_semantic), do: nil

  defp semantic_lane_key(runtime_semantic, entry_source) do
    map_value(runtime_semantic, "lane_key") || (entry_source && entry_source.lane_key)
  end

  defp origin_run_href(runtime_semantic, step_semantic, entry_source) do
    case map_value(runtime_semantic, "origin_run_id") ||
           map_value(step_semantic, "origin_run_id") ||
           (entry_source && entry_source.origin_run_id) do
      run_id when is_binary(run_id) -> "/workflows/#{run_id}"
      _ -> nil
    end
  end

  defp semantic_actor_id(runtime_semantic, entry_source) do
    case map_value(runtime_semantic, "scope_kind") || (entry_source && entry_source.scope_kind) do
      "actor_scoped" -> map_value(runtime_semantic, "actor_id") || (entry_source && entry_source.actor_id)
      _ -> nil
    end
  end

  defp map_value(map, key) when is_map(map) do
    atom_key =
      try do
        String.to_existing_atom(key)
      rescue
        ArgumentError -> nil
      end

    Map.get(map, key, atom_key && Map.get(map, atom_key))
  end

  defp map_value(_map, _key), do: nil

  defp load_source_run(%Run{execution_mode: "replay", source_run_id: source_run_id})
       when is_binary(source_run_id) do
    Workflows.get_run_tree!(source_run_id)
  rescue
    NoResultsError -> nil
  end

  defp load_source_run(_run), do: nil
end
