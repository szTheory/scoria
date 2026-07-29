defmodule Scoria.MCP.Executor do
  @moduledoc """
  Executes MCP tools in an isolated Task with strict timeouts.
  Emits telemetry events for auditing.
  """

  import Ecto.Query, warn: false
  require Logger

  # Per D-03, `Scoria.Confluence` itself aliases nothing Scoria-side -- but
  # the EXECUTOR (caller) legitimately aliases it here; the executor
  # already holds every edge this decision needs.
  alias Scoria.Confluence
  alias Scoria.MCP.Classification
  alias Scoria.MCP.Envelope
  alias Scoria.Observe.Approval
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.SRE.BudgetEngine
  alias Scoria.SRE.BreakerRegistry
  alias Scoria.SRE
  alias Scoria.SRE.Telemetry
  alias Scoria.Trust
  alias Scoria.Trust.Scanner
  alias Scoria.Workflows
  alias Scoria.Workflows.Rails
  alias Scoria.Workflows.ReplayDisposition
  alias Scoria.Workflows.Run
  alias Scoria.Workflows.Step

  @rail_warned_table :scoria_mcp_executor_rail_warned

  @doc """
  Executes a tool module with the given arguments and context.
  """
  def execute(tool_module, args, context, timeout \\ 5000) do
    context = canonical_context(context || %{})

    case admit_tool_call_rail(context, tool_module) do
      {:ok, context} ->
        # Rule 1: `:rail_admission` is a purely internal cross-module
        # idempotence marker (this function <-> `Connectors.Invocation`),
        # never a tool-visible fact -- unlike `:tool_classification`, which
        # IS deliberately surfaced. Drop it immediately once the admission
        # decision above is made, so it never reaches
        # `tool_module.execute/2`'s own context (a tool that echoes its
        # context back, e.g. in `MCP.Router`'s test fixture, must see the
        # exact context it was handed, not this implementation detail).
        context = Map.delete(context, :rail_admission)

        case resolve_classification(tool_module, context) do
          {:ok, context} ->
            case replay_gate(tool_module, args, context) do
              {:continue, context} ->
                case confluence_gate(tool_module, args, context) do
                  {:continue, context} ->
                    execute_live(tool_module, args, context, timeout)

                  other ->
                    other
                end

              other ->
                other
            end

          other ->
            other
        end

      {:error, envelope} ->
        {:error, envelope}
    end
  end

  # RAIL-01 (56.1-CONTEXT.md D-08/D-09/D-19): the FIRST statement of
  # `execute/4`'s dispatch, AHEAD of `resolve_classification/2` -- a
  # runaway loop of `:unclassified_tool` refusals must still count against
  # `max_tool_calls`, so the rail has to trip before that refusal can. Guarded
  # by the `:rail_admission` context marker, mirroring
  # `resolve_classification/2`'s own struct-match idempotence guard just
  # below: a logical call already admitted at
  # `Connectors.Invocation.invoke/4` carries this marker into `live_context`
  # (additive, survives `canonical_context/1`) and is never re-admitted --
  # and never double-counted -- when it reaches here.
  defp admit_tool_call_rail(%{rail_admission: _} = context, _tool_module), do: {:ok, context}

  defp admit_tool_call_rail(context, tool_module) do
    case Map.get(context, :run_id) do
      nil ->
        # D-19 -- SC#4's no-run-attribution no-op. This is NOT a refusal:
        # the tool's own return value is unaffected. Guarded HERE (the
        # executor) rather than in `MCP.Router`, since `MCPController` and
        # direct host `execute/4` calls have the identical gap and this
        # covers all of them by construction, with `site` distinguishing.
        site = rail_site(context, :mcp_executor)
        maybe_warn_unattributed_rail_call(site)
        emit_rail_skipped(context, tool_module, site, :no_run_id)
        {:ok, Map.put(context, :rail_admission, :skipped)}

      run_id ->
        case Rails.admit_tool_call(run_id) do
          {:ok, _count} ->
            {:ok, Map.put(context, :rail_admission, :ok)}

          :denied ->
            # Rule 1: disambiguate via the cold-path `Rails.deny_reason/1`
            # BEFORE treating this as a real rail trip -- `:denied` fires
            # identically whether the run is genuinely at its limit OR
            # `run_id` never matched any persisted `%Run{}` row (a
            # synthetic/trace-only id, an established test/adopter
            # pattern that predates this plan). A run that does not exist
            # has no counter to admit against; halting it would raise
            # `Ecto.NoResultsError` instead of the SC#4 no-op this
            # context deserves.
            case Rails.deny_reason(run_id) do
              :no_run ->
                site = rail_site(context, :mcp_executor)
                emit_rail_skipped(context, tool_module, site, :no_run)
                {:ok, Map.put(context, :rail_admission, :skipped)}

              _reason ->
                {:error, tool_call_rail_denied_envelope(run_id, context)}
            end
        end
    end
  end

  defp rail_site(context, default), do: Map.get(context, :rail_site, default)

  # Volume equals `[:scoria, :tool, :started]` (`:545` below), which already
  # fires on every call -- the count IS the deliverable (D-19). Wrapped in
  # `try/rescue` so a broken adopter handler cannot break a tool call.
  #
  # `:no_run_id` (D-19, SC#4) is the documented, public reason: the context
  # carried no `:run_id` at all. `:no_run` is the cold-path disambiguation
  # (D-09) for the OTHER way admission can find nothing to enforce against:
  # a `:run_id` was present but matched no persisted `%Run{}` row (a
  # synthetic/trace-only id) -- there is no counter to admit against, so
  # this is the same class of no-op, not a rail trip.
  defp emit_rail_skipped(context, tool_module, site, :no_run_id) do
    emit_rail_skipped_event(context, tool_module, %{reason: :no_run_id, site: site})
  end

  defp emit_rail_skipped(context, tool_module, site, :no_run) do
    emit_rail_skipped_event(context, tool_module, %{reason: :no_run, site: site})
  end

  defp emit_rail_skipped_event(context, tool_module, base_metadata) do
    try do
      :telemetry.execute(
        [:scoria, :run, :rail, :skipped],
        %{},
        Map.merge(base_metadata, %{
          tool_ref: inspect(tool_module),
          tenant_id: Map.get(context, :tenant_id),
          session_id: Map.get(context, :session_id),
          trace_id: Map.get(context, :trace_id)
        })
      )
    rescue
      _ -> :ok
    end
  end

  # Once per boot per `site`, and ONLY when `max_tool_calls` is actually
  # configured somewhere -- D-19 explicitly cuts an info-level "rail not
  # configured" line, since given the run-attribution gap that would fire
  # for every adopter forever. Mirrors `Observe.Bounds`' ETS `log_once`
  # idiom (`bounds.ex:375-395`).
  defp maybe_warn_unattributed_rail_call(site) do
    if max_tool_calls_configured?() and first_rail_warning_for_site?(site) do
      Logger.warning(
        "Scoria.MCP.Executor: max_tool_calls is configured, but a tool call " <>
          "arrived with no :run_id in its context (site: #{inspect(site)}) and is " <>
          "NOT railed. See [:scoria, :run, :rail, :skipped] telemetry to measure " <>
          "this gap; forward run_id/step_id from run.metadata[\"runtime\"] to close it."
      )
    end
  end

  defp max_tool_calls_configured? do
    :scoria
    |> Application.get_env(Scoria.Runtime.Rails, [])
    |> Keyword.get(:max_tool_calls)
    |> is_integer()
  end

  defp first_rail_warning_for_site?(site) do
    ensure_rail_warned_table()
    :ets.insert_new(@rail_warned_table, {site, true})
  end

  defp ensure_rail_warned_table do
    case :ets.whereis(@rail_warned_table) do
      :undefined ->
        :ets.new(@rail_warned_table, [:named_table, :set, :public, read_concurrency: true])

      _table ->
        :ok
    end
  end

  # Cold path (D-09): only reached on `:denied`, which under the CAS means
  # `observed == limit` exactly (the UPDATE never fired) and
  # `attempted == limit + 1`. The atom-keyed return mirrors
  # `unclassified_tool_envelope/2`'s shape; the string-keyed envelope handed
  # to `halt_run/3` mirrors 56.1-CONTEXT.md D-03's error-envelope contract.
  defp tool_call_rail_denied_envelope(run_id, context) do
    run = Workflows.get_run!(run_id)
    step_id = Map.get(context, :step_id)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    limit = run.rail_max_tool_calls
    observed = run.rail_tool_calls

    halt_envelope = %{
      "status" => "run_halted",
      "reason_code" => "max_tool_calls_exceeded",
      "rail" => "max_tool_calls",
      "limit" => limit,
      "observed" => observed,
      "attempted" => (observed || 0) + 1,
      "run_id" => run_id,
      "step_id" => step_id,
      "halted_at" => DateTime.to_iso8601(now),
      "site" => "mcp_executor"
    }

    Workflows.halt_run(run_id, step_id, halt_envelope)

    %{
      status: :run_halted,
      reason_code: "max_tool_calls_exceeded",
      rail: "max_tool_calls",
      limit: limit,
      observed: observed
    }
  end

  # D-05: resolution happens exactly once, here, before `replay_gate/3`.
  # Idempotent and single-shot -- if `context` already carries a resolved
  # `%Classification{}` under `:tool_classification` (a connector call site
  # may inject one ahead of this), it is reused unchanged and no telemetry
  # fires a second time. Otherwise the tool's own declaration (or the
  # fail-closed-but-inspectable maximal default, D-03) is resolved and
  # carried forward on that same new context key.
  #
  # Plan 56-02: when `config :scoria, :require_tool_classification` is
  # truthy (default `false`) AND the resolved classification's `source` is
  # `:unclassified_default`, this now returns `{:error, envelope}` instead --
  # a genuine refusal, never reached for a host-tightened or tool-declared
  # resolution. `execute/4`'s call site matches only `{:ok, context}` plus a
  # catch-all `other -> other`, so this branch flows straight back to the
  # caller with zero further side effects (no `replay_gate/3`, no budget
  # reservation, no audit insert, no tool Task -- mirrors
  # `Scoria.Runtime.ReleaseGate.handle_missing_verdict/1`).
  # Plan 57-05 (D-35): gated on `source` -- a classification already on
  # `context` short-circuits ONLY when its `source` is anything other than
  # `:unclassified_default`. Before this fix the clause matched ANY
  # `%Classification{}` struct regardless of source, and BOTH
  # `Connectors.Invocation.invoke/4`'s `resolve_tool_classification/2` and
  # `Workflows.Runtime`'s `default_replay_seam/2` inject exactly a
  # pre-resolved `%Classification{source: :unclassified_default}` onto the
  # context ahead of this call -- so an undeclared tool's fail-closed
  # default was bypassing `refuse_unclassified_tool?/1` entirely on both
  # of those seams, silently defeating `require_tool_classification` for
  # connector-routed and replay-default-seam calls. A genuinely resolved
  # classification (`:tool_declared`/`:host_tightened`) still short-
  # circuits unchanged.
  @spec resolve_classification(module(), map()) :: {:ok, map()} | {:error, map()}
  defp resolve_classification(tool_module, context) do
    case Map.get(context, :tool_classification) do
      %Classification{source: source} when source != :unclassified_default ->
        {:ok, context}

      _ ->
        declaration = Classification.tool_declaration(tool_module)
        resolved = Classification.resolve(declaration, context)

        if refuse_unclassified_tool?(resolved) do
          {:error, unclassified_tool_envelope(tool_module, context)}
        else
          maybe_emit_unclassified(declaration, tool_module, context)
          persist_classification_to_step(context, tool_module, resolved)
          {:ok, Map.put(context, :tool_classification, resolved)}
        end
    end
  end

  # Gate on `source == :unclassified_default` specifically (D-03) -- a
  # host-tightened resolution is a real classification and must never be
  # refused by this flag. Mirrors `release_gate.ex:82`'s
  # `Application.get_env(:scoria, :require_eval_verdict, false)` --
  # default-off, no config-file entry (grep-verified in acceptance
  # criteria), so no existing adopter inherits the strict behavior.
  defp refuse_unclassified_tool?(%Classification{source: :unclassified_default}) do
    Application.get_env(:scoria, :require_tool_classification, false)
  end

  defp refuse_unclassified_tool?(_resolved), do: false

  defp unclassified_tool_envelope(tool_module, context) do
    %{
      status: :unclassified_tool,
      reason_code: "tool_classification_required",
      tool_ref: inspect(tool_module),
      trace_id: Map.get(context, :trace_id),
      policy_key: Map.get(context, :policy_key)
    }
  end

  defp maybe_emit_unclassified(:none, tool_module, context) do
    try do
      :telemetry.execute(
        [:scoria, :class, :unclassified],
        %{},
        %{
          tool: tool_module,
          tool_ref: inspect(tool_module),
          trace_id: Map.get(context, :trace_id),
          step_id: Map.get(context, :step_id),
          site: :mcp_executor
        }
      )
    rescue
      _ -> :ok
    end
  end

  defp maybe_emit_unclassified({:ok, _declared}, _tool_module, _context), do: :ok

  # D-14: positioned between `replay_gate/3`'s `{:continue, context}` branch
  # and `execute_live/4` -- after the rail (already run above), after
  # classification (`context[:tool_classification]` IS the leg source),
  # and after the replay gate (a `:historical_stub` never executes the
  # exfil action, so the gate must not fire for it); before
  # `execute_live/4` and therefore before `maybe_capture_sensitive_mcp_access/3`
  # and `reserve_budget/3`, so an escalated call reserves no budget and
  # writes no `mcp.access.granted` row for an action that never happened.
  #
  # Reads the resolved `%Classification{}` from `context[:tool_classification]`
  # -- never from the persisted step `result_envelope` jsonb, which
  # `complete_step/3` wholesale-replaces and connector-routed calls never
  # write. A single tool declaring all three legs escalates on itself (a
  # single call's own declared legs are sufficient per D-11), so no
  # per-run accumulator read is needed for this tracer slice.
  #
  # Plan 57-05: the gate's FIRST action is now the atomic approval-consume
  # CAS (D-26) -- BEFORE any classification, accumulation or evaluation
  # work, mirroring `Rails.admit_tool_call/2`'s single-statement shape.
  # `:consumed` passes the call through unevaluated (the SAME approval can
  # never be consumed twice, so a resumed run never re-escalates the
  # identical call). `:rejected` denies with the confluence-rejected
  # reason code and never re-escalates. `:no_match` (including a `nil`
  # args fingerprint, which fails CLOSED as no-match) falls through to a
  # genuine evaluation. Every exit path emits exactly one
  # `[:scoria, :gate, :confluence, :observed]` event (D-36) -- evaluation,
  # persistence and telemetry are ALWAYS ON with no off switch (D-32).
  #
  # Plan 57-07 (D-38): a rejected-approval deny ALSO writes a confluence
  # audit outbox row here -- it is a decision (the reviewer already denied
  # this exact call once) and has no other durable record: the
  # tool-completed event never fires on a refusal. `evidence` does not
  # exist yet at this point in the pipeline (evaluation hasn't run), so a
  # minimal synthetic `%Confluence.Evidence{}` is built carrying only what
  # is already known -- `combination: "exfiltration_path"` is always
  # correct here because only that combination ever reaches
  # `resolve_escalation/6` and creates the approval this rejection is
  # matching against.
  defp confluence_gate(tool_module, args, context) do
    run_id = Map.get(context, :run_id)
    step_id = Map.get(context, :step_id)
    args_fingerprint = Map.get(context, :args_fingerprint)

    case consume_confluence_approval(run_id, step_id, args_fingerprint) do
      :consumed ->
        emit_confluence_observed(context, tool_module, nil, "allow", nil)
        {:continue, context}

      :rejected ->
        reason_code = Confluence.normalize_reason_code(:confluence_rejected)

        emit_confluence_observed(context, tool_module, nil, "block", reason_code)

        record_confluence_audit(
          context,
          confluence_rejected_evidence(tool_module, run_id, step_id, reason_code),
          run_id,
          step_id,
          args_fingerprint
        )

        {:error, confluence_rejected_envelope(tool_module, run_id, context)}

      :no_match ->
        evaluate_confluence(tool_module, args, context, run_id, step_id)
    end
  end

  # D-26: single-statement `Repo.update_all` CAS mirroring
  # `Rails.admit_tool_call/2` exactly: a query with guard clauses in
  # `where`, one update, a two-element tuple match distinguishing the
  # consumed case from everything else. Never a read-then-write round
  # trip. A `nil` args fingerprint FAILS CLOSED -- `build_replay_seam/2`
  # reads it with no default, so nil is reachable, and a nil-matches-
  # anything query would be a universal bypass; it is guarded here by
  # simply never attempting the match (both the call-scope CAS and the
  # rejected lookup require a non-nil fingerprint).
  defp consume_confluence_approval(nil, _step_id, _args_fingerprint), do: :no_match
  defp consume_confluence_approval(_run_id, _step_id, nil), do: :no_match

  defp consume_confluence_approval(run_id, step_id, args_fingerprint) do
    case consume_call_scope(run_id, step_id, args_fingerprint) do
      :consumed -> :consumed
      :no_match -> resolve_non_consuming_match(run_id, args_fingerprint)
    end
  end

  defp consume_call_scope(run_id, step_id, args_fingerprint) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    query =
      from(a in Approval,
        where: a.workflow_run_id == ^run_id,
        where: a.blocker_kind == "confluence",
        where: a.status == "approved",
        where: is_nil(a.consumed_at),
        where: a.args_fingerprint == ^args_fingerprint,
        # Only a `"call"` (or legacy-NULL, which means `"call"`) scoped
        # approval is ever consumed here -- a `"run_tool"`-scoped grant is
        # matched separately below and is DELIBERATELY never consumed, so
        # it stays usable for the remainder of the granting run.
        where: is_nil(a.confluence_scope) or a.confluence_scope == "call",
        select: a.id
      )

    case Repo.update_all(query, set: [consumed_at: now, consumed_by_step_id: step_id]) do
      {1, [_id]} -> :consumed
      {0, _} -> :no_match
    end
  end

  defp resolve_non_consuming_match(run_id, args_fingerprint) do
    rejected_query =
      from(a in Approval,
        where: a.workflow_run_id == ^run_id,
        where: a.blocker_kind == "confluence",
        where: a.status == "rejected",
        where: a.args_fingerprint == ^args_fingerprint
      )

    if Repo.exists?(rejected_query), do: :rejected, else: :no_match
  end

  # D-44/D-50 (checkpoint-resolved `d50-scope`, recorded verbatim in
  # 57-01-SUMMARY.md): a `"run_tool"`-scoped approval matches on workflow
  # run id, `blocker_kind`, approved status, `tool_name`, AND the recorded
  # grade -- DELIBERATELY NOT on the args fingerprint (every call of a
  # per-message reply tool has different arguments) -- and is NEVER
  # consumed here, so the grant remains usable for the rest of THIS run.
  # There is no separate persisted "grade" column on `ai_approvals`: a
  # `"run_tool"` approval can only ever have been created for an
  # escalation this executor actually paused on, which is what the
  # `"declared"` guard clause below makes STRUCTURAL rather than
  # assumed -- a differently-graded escalation of the SAME tool (reachable
  # only under a host's own `strict: true` override extending enforcement
  # to the weaker grades) never matches a run_tool grant, because that
  # grant was never issued for it. Bounded by the run's own lifetime and
  # rails -- it is NOT a standing exfiltration grant: it cannot match a
  # different run, a different tool, or a different grade. Do NOT
  # "generalize" this scope across runs, tools, or grades.
  defp run_tool_scope_granted?(nil, _tool_module, _grade), do: false

  defp run_tool_scope_granted?(run_id, tool_module, "declared") do
    Repo.exists?(
      from(a in Approval,
        where: a.workflow_run_id == ^run_id,
        where: a.blocker_kind == "confluence",
        where: a.status == "approved",
        where: a.confluence_scope == "run_tool",
        where: a.tool_name == ^tool_module.name()
      )
    )
  end

  defp run_tool_scope_granted?(_run_id, _tool_module, _other_grade), do: false

  defp confluence_rejected_envelope(tool_module, run_id, context) do
    %{
      status: :confluence_denied,
      reason_code: "confluence_rejected",
      tool_ref: inspect(tool_module),
      run_id: run_id,
      step_id: Map.get(context, :step_id),
      trace_id: Map.get(context, :trace_id)
    }
  end

  # -- Plan 57-07: confluence audit outbox (D-37..D-42) -------------------
  #
  # Every confluence ESCALATE and every confluence BLOCK writes exactly one
  # audit outbox row; an ALLOW writes none (D-38). Reuses the existing
  # `SRE.create_audit_outbox_event/1` machinery UNMODIFIED -- no new
  # columns, no bespoke insert path.
  @confluence_audit_event_type "tool.confluence.escalated"
  @confluence_audit_policy_class "confluence_gate"
  @confluence_audit_actor_ref "system:scoria.confluence"

  # D-42: the dedupe key is set EXPLICITLY from event type + run id + step
  # id + args fingerprint. The AUTOMATIC builder
  # (`SRE.build_audit_dedupe_key/1`, out of this plan's file scope) composes
  # from event type + tenant + approval id + trace id + access decision --
  # for a row written BEFORE the approval exists, approval id and access
  # decision are both nil, and `Observe`'s trace-id-for-run helper returns
  # the run id itself, so the auto key would collapse to
  # `event_type:tenant:run_id` and silently merge two genuine escalations
  # in the SAME run into one row against the tenant-and-dedupe-key unique
  # index. Composing from step id (not trace id) instead avoids that
  # collapse by construction.
  defp confluence_audit_dedupe_key(run_id, step_id, args_fingerprint) do
    [@confluence_audit_event_type, run_id, step_id, args_fingerprint]
    |> Enum.map(&to_string_or_empty/1)
    |> Enum.join(":")
  end

  # D-40/D-41: writes ONE row and returns the persisted
  # `%SRE.AuditOutboxEvent{}` struct (or `nil` on a genuine write failure --
  # read defensively, this column carries no foreign key). Callers that
  # need the id (the escalate path, so it can be threaded into
  # `mark_waiting_for_approval/3`'s attrs as `blocker_audit_outbox_event_id`)
  # write this FIRST, before creating the approval (D-40): if the pause
  # transition then fails, the orphan audit row saying the trifecta fired
  # is the truth and is preferred over a silent unaudited exfil.
  #
  # `metadata:` rides `Confluence.audit_metadata/1`'s OUTPUT verbatim (plan
  # 57-07 Task 2) -- never assembled inline here, so there is exactly one
  # place the closed key set is defined (D-39). Every OTHER envelope key
  # below is one `SRE.build_audit_metadata/1`'s own drop-list already
  # excludes from the persisted `metadata` jsonb, so the two never collide
  # and the persisted row's metadata key set is EXACTLY the projector's key
  # set, nothing more.
  defp record_confluence_audit(context, evidence, run_id, step_id, args_fingerprint) do
    dedupe_key = confluence_audit_dedupe_key(run_id, step_id, args_fingerprint)

    envelope =
      %{
        tenant_id: Map.get(context, :tenant_id, "system"),
        actor_ref: @confluence_audit_actor_ref,
        workflow_run_id: run_id,
        step_id: step_id,
        trace_id: Map.get(context, :trace_id),
        event_type: @confluence_audit_event_type,
        policy_class: @confluence_audit_policy_class,
        dedupe_key: dedupe_key
      }
      |> Map.merge(Confluence.audit_metadata(evidence))

    case SRE.create_audit_outbox_event(envelope) do
      {:ok, event} -> event
      {:error, _reason} -> nil
    end
  end

  # Built at the rejected-approval-consume site (`confluence_gate/3`), the
  # ONE audit-worthy decision point that precedes `evaluate_confluence/5`
  # and therefore has no real `%Confluence.Evidence{}` yet. `combination`
  # is hardcoded to `"exfiltration_path"` because that is the only
  # combination `resolve_escalation/6` ever creates an approval for -- a
  # rejected match can only exist against a row that was, in fact, an
  # exfiltration_path escalation.
  defp confluence_rejected_evidence(tool_module, run_id, step_id, reason_code) do
    %Confluence.Evidence{
      combination: "exfiltration_path",
      decision: "block",
      reason_code: reason_code,
      run_id: run_id,
      step_id: step_id,
      tool_ref: inspect(tool_module)
    }
  end

  # Plan 57-06 (D-11, D-14): the fold happens HERE, after the D-26
  # approval-consume CAS (`confluence_gate/3` only reaches this function on
  # `:no_match`) and BEFORE `Confluence.classify/1` -- exactly the order
  # the gate already establishes. `call_input` is THIS call's own witness
  # map (unchanged from the pre-accumulator shape: `:private_data`,
  # `:untrusted_content`, `:exfil`, plus the `:run_id`/`:step_id`/
  # `:tool_ref`/`:action_class` correlation keys `Confluence.classify/1`
  # also reads). Only `:private_data` and `:untrusted_content` -- the two
  # EXPOSURE legs -- are ever folded into the per-run accumulator; `:exfil`
  # is read from `call_input` UNCHANGED below and is NEVER accumulated
  # (D-11): `reads_private_data`/`sees_untrusted_content` describe what the
  # agent has been EXPOSED TO (monotone, run-scoped), `can_exfiltrate`
  # describes what THIS CALL can do. Accumulating exfil too would pause a
  # later harmless read merely because an earlier, unrelated call in the
  # same run happened to be exfil-capable. A single tool declaring all
  # three legs still escalates on itself, because its OWN legs fold into
  # the accumulator before this same call's classify input is built --
  # per-call is a strict subset of the accumulated model, never a second
  # mode.
  defp evaluate_confluence(tool_module, args, context, run_id, step_id) do
    call_input = confluence_input(tool_module, context)

    classify_input =
      case fold_confluence_legs(run_id, step_id, call_input, tool_module) do
        {:ok, accumulated_legs} ->
          call_input
          |> Map.put(:private_data, Map.get(accumulated_legs, :private_data))
          |> Map.put(:untrusted_content, Map.get(accumulated_legs, :untrusted_content))

        {:error, _reason} ->
          # D-16: a failed accumulator write must not be silently
          # swallowed (fallback telemetry already fired inside
          # `fold_confluence_legs/4`), but it must also not crash this
          # tool call (the observe-layer "never break host business
          # logic" rule). Fail closed on the ACCUMULATOR read only, never
          # on the call: fall back to evaluating on this call's OWN
          # witnesses alone -- never weaker than the pre-accumulator
          # tracer's behavior (a single tool declaring all three legs
          # still escalates on itself), and never stronger than what this
          # call itself can prove.
          call_input
      end

    {combination, evidence} = Confluence.classify(classify_input)
    evidence = attach_confluence_idempotency_key(evidence, context, tool_module)
    config = Confluence.resolve_config(context)
    decision = confluence_decision(evidence, config)

    cond do
      combination == "exfiltration_path" and decision == "escalate" ->
        if run_tool_scope_granted?(run_id, tool_module, evidence.grade) do
          emit_confluence_observed(context, tool_module, evidence, "allow", nil)
          {:continue, context}
        else
          resolve_escalation(tool_module, args, context, evidence, run_id, step_id)
        end

      combination == "exfiltration_path" and decision == "block" ->
        # Reachable only when a host has tightened `declared: :block` via
        # per-call context or application env (D-33) -- never under
        # shipped defaults (D-31 ships `declared: :escalate`).
        emit_confluence_observed(context, tool_module, evidence, "block", nil)

        record_confluence_audit(
          context,
          %{evidence | decision: "block"},
          run_id,
          step_id,
          Map.get(context, :args_fingerprint)
        )

        {:error, confluence_rejected_envelope(tool_module, run_id, context)}

      true ->
        emit_confluence_observed(context, tool_module, evidence, "allow", nil)
        {:continue, context}
    end
  end

  defp confluence_decision(%Confluence.Evidence{grade: nil}, _config), do: "allow"

  defp confluence_decision(%Confluence.Evidence{grade: grade}, config),
    do: Confluence.decide(grade, config)

  # Recommendation, not a lock (57-CONTEXT.md "Claude's Discretion"):
  # `Confluence.classify/1` already computes a `confluence_idempotency_key`
  # from run id + tool ref alone (`confluence.ex` is out of this plan's
  # file scope). This overrides it with the richer key the plan
  # describes -- run id, tool identifier, args fingerprint and policy key
  # -- reusing `ReplayDisposition.replay_idempotency_key/2`'s call shape
  # (join with `:`, sha256, hex-encode) rather than hand-rolling a
  # different one.
  defp attach_confluence_idempotency_key(evidence, context, tool_module) do
    run_id = Map.get(context, :run_id)

    if is_nil(run_id) do
      evidence
    else
      raw =
        [
          run_id,
          inspect(tool_module),
          Map.get(context, :args_fingerprint),
          Map.get(context, :policy_key)
        ]
        |> Enum.map(&to_string_or_empty/1)
        |> Enum.join(":")

      key = "confluence:" <> Base.encode16(:crypto.hash(:sha256, raw), case: :lower)
      %{evidence | confluence_idempotency_key: key}
    end
  end

  defp to_string_or_empty(nil), do: ""
  defp to_string_or_empty(value), do: to_string(value)

  defp confluence_input(tool_module, context) do
    base = %{
      run_id: Map.get(context, :run_id),
      step_id: Map.get(context, :step_id),
      tool_ref: inspect(tool_module)
    }

    case Map.get(context, :tool_classification) do
      # The fail-closed-but-inspectable `unclassified_default/0` (56 D-06)
      # is NEVER an operand here (mirrors `Classification.declared_sensitive?/1`'s
      # own explicit `source: :unclassified_default` guard) -- an
      # undeclared tool's maximal-caution default must never be folded
      # into a "declared" leg witness, or every undeclared tool call
      # would spuriously escalate. Grading the unclassified cascade is a
      # later plan's job (D-29/D-31); this task only proves the declared
      # path, so an unclassified tool simply produces no witnesses and
      # falls to `Confluence.classify/1`'s terminal fallback.
      %Classification{source: :unclassified_default} ->
        Map.merge(base, %{private_data: nil, untrusted_content: nil, exfil: nil})

      %Classification{} = classification ->
        Map.merge(base, %{
          private_data: leg_witness(classification.reads_private_data),
          untrusted_content: leg_witness(classification.sees_untrusted_content),
          exfil: leg_witness(classification.can_exfiltrate),
          action_class: classification.action_class
        })

      _no_classification ->
        Map.merge(base, %{private_data: nil, untrusted_content: nil, exfil: nil})
    end
  end

  defp leg_witness(true), do: %{source: :declared}
  defp leg_witness(_falsy), do: nil

  # `@doc false` (not `defp`), mirroring `actual_units/3`'s precedent
  # elsewhere in this module ("exists so ... is directly unit-testable"):
  # exposes the leg-fold primitive directly so its STRONGEST-WINS ranking
  # can be unit-tested with synthetic witness sources (`:default_tier`,
  # `:scanner_infra`) that are NOT constructible through any live call
  # path via `Executor.execute/4`'s public API today -- `confluence_input/2`
  # only ever constructs `source: :declared` witnesses in this plan's
  # scope (D-13), so the ordering-independence proof this accumulator's
  # correctness depends on (D-15.1) is otherwise unreachable from a
  # black-box test. This is an internal function, not a published API.
  @doc false
  def fold_confluence_legs_for_test(run_id, step_id, call_input, tool_module \\ __MODULE__) do
    fold_confluence_legs(run_id, step_id, call_input, tool_module)
  end

  # -- Plan 57-06: per-run leg accumulator (D-15, D-16, D-17) -------------
  #
  # D-12: legs are MONOTONE within a run, and the only reset is a new run.
  # There is, and must never be, any clearing/reset/downgrade/untaint
  # primitive anywhere in this section -- Perl's `untaint` is the canonical
  # footgun this deliberately avoids (a taint substrate with a clearing
  # primitive becomes a rubber stamp, and the clearing call becomes the
  # attack surface; it is also why the Ruby `$SAFE` post-mortem reads the
  # way it does). An approval clears the GATE (`consume_confluence_approval/3`,
  # keyed by the idempotency key), never the LEGS -- do NOT add a
  # convenience "clear this run's confluence_legs" helper for an approval,
  # an admin action, or a replay; every function below only ever WRITES a
  # leg to `true`/stronger, never to `false`/weaker/absent.
  #
  # Ranks a leg witness's `:source` for STRONGEST-WINS comparison (D-15.1).
  # Mirrors `Scoria.Confluence.grade/1`'s weakest-first `@grade_rank`
  # ordering, but inverted in USE (this ranks a SINGLE witness so a
  # per-leg maximum can be taken across calls, not the weakest across
  # legs within one call, which is `Confluence.grade/1`'s own job and
  # stays untouched). An unrecognized or missing source fails closed to
  # rank 0 (the weakest, `:unclassified`), mirroring `Confluence`'s own
  # D-30 fallback -- a garbage source must never win a "strongest" compare
  # against a genuine one.
  @confluence_leg_source_rank %{
    declared: 3,
    scanner_infra: 1,
    default_tier: 2,
    unclassified: 0
  }

  defp confluence_leg_source_rank(source), do: Map.get(@confluence_leg_source_rank, source, 0)

  # Builds the jsonb "candidates" parameter the merge fragment below
  # iterates via `jsonb_each/1`: ONLY the two accumulated exposure legs
  # (D-11), and ONLY the ones THIS call actually lit (D-15.2 -- a `nil`
  # witness contributes no candidate at all, never a `false`/absent
  # placeholder). An empty result (`%{}`, when this call lights neither
  # exposure leg) makes `jsonb_each` iterate zero rows, so the merge below
  # degrades to a pure READ of the current accumulator state -- still a
  # single statement, still takes the second row lock every call (T-57-32,
  # accepted and documented below), never a separate read-then-write.
  defp confluence_leg_candidates(private_witness, untrusted_witness) do
    %{}
    |> maybe_put_confluence_leg_candidate("private_data", private_witness)
    |> maybe_put_confluence_leg_candidate("untrusted_content", untrusted_witness)
  end

  defp maybe_put_confluence_leg_candidate(candidates, _leg_key, nil), do: candidates

  defp maybe_put_confluence_leg_candidate(candidates, leg_key, witness) do
    source = to_string(witness.source)
    reason_code = Map.get(witness, :reason_code)

    Map.put(candidates, leg_key, %{
      "source" => source,
      "reason_code" => reason_code && to_string(reason_code),
      "rank" => confluence_leg_source_rank(witness.source)
    })
  end

  # No run to persist against (D-19/D-22's unattributed gap -- a call with
  # no `:run_id` at all): return THIS call's own witnesses unchanged, with
  # NO database round trip. This is not a degraded case -- there is
  # genuinely no accumulator row to read or write, and this mirrors the
  # historical pre-accumulator tracer behavior exactly (a single call's
  # own declared legs are the only evidence there ever was for an
  # unattributed call).
  defp fold_confluence_legs(nil, _step_id, call_input, _tool_module) do
    {:ok,
     %{
       private_data: Map.get(call_input, :private_data),
       untrusted_content: Map.get(call_input, :untrusted_content)
     }}
  end

  # D-17: the merge and the read happen in ONE statement -- a single
  # `Repo.update_all` whose `update:` clause computes the new per-leg
  # values and whose `select:` clause (Ecto's `update_all` reads the
  # second `{count, results}` element ONLY when the update query itself
  # carries a `select:` -- there is no separate `returning:` opt for
  # `update_all/3`, unlike `insert_all/3`; mirrors `consume_call_scope/3`'s
  # and `Rails.admit_tool_call/2`'s own `select:` shape above) reads the
  # POST-merge value back in the SAME statement, never a
  # read-then-decide-then-write pair. This is a SECOND exclusive
  # row lock on the run, per tool call, on top of the rail counter's own
  # lock (`admit_tool_call_rail/2` -> `Rails.admit_tool_call/2`) --
  # accepted and documented (T-57-32, 56.1 D-09 precedent), not papered
  # over: this fold runs on EVERY evaluated call, including one that
  # lights no leg at all, because the accumulator must still be READ to
  # pick up legs a different call already lit.
  #
  # The `jsonb_each(candidates)` / `jsonb_object_agg(...)` shape handles
  # zero, one, or two lit legs UNIFORMLY in one fragment -- no per-count
  # branching. For each candidate leg: the EXISTING witness's rank is
  # computed from its stored `"source"` string via a fixed `CASE` (absent
  # entirely -> `NULL` -> `COALESCE(..., -1)`, always beaten by a real
  # witness's rank 0-3); a STRICTLY GREATER candidate rank wins and
  # replaces the leg (STRONGEST-WINS, D-15.1 -- a plain `||` cannot
  # express this, it always keeps the FIRST witness, which is exactly the
  # bug D-15.1 corrects); a tied-or-weaker candidate changes nothing, so
  # the existing map (source, reason_code, first_step_id, all of it) is
  # left byte-identical. On a win, `first_step_id` is preserved from
  # whatever was already stored (`COALESCE(existing, this_call's step_id)`)
  # even though `source` itself is upgraded -- the step that FIRST lit a
  # leg does not change just because a later call proves it more strongly.
  # Legs this call does not light are never touched at all: they are
  # absent from `candidates`, so `jsonb_each` never visits their key, so
  # neither their presence NOR their absence is ever written (D-15.2) --
  # this is also what makes a later call's `false` for an already-lit leg
  # a pure no-op (there is no candidate for it, so nothing merges).
  defp fold_confluence_legs(run_id, step_id, call_input, tool_module) do
    candidates =
      confluence_leg_candidates(
        Map.get(call_input, :private_data),
        Map.get(call_input, :untrusted_content)
      )

    query =
      from(r in Run,
        where: r.id == ^run_id,
        update: [
          set: [
            confluence_legs:
              fragment(
                """
                (SELECT ? || COALESCE(
                   jsonb_object_agg(
                     cand.key,
                     CASE
                       WHEN (cand.value->>'rank')::int > COALESCE(
                         CASE (?->cand.key->>'source')
                           WHEN 'declared' THEN 3
                           WHEN 'scanner_infra' THEN 1
                           WHEN 'default_tier' THEN 2
                           WHEN 'unclassified' THEN 0
                           ELSE NULL
                         END,
                         -1
                       )
                       THEN jsonb_set(
                         jsonb_build_object(
                           'lit', true,
                           'source', cand.value->>'source',
                           'reason_code', cand.value->'reason_code',
                           'strongest_source', cand.value->>'source'
                         ),
                         '{first_step_id}',
                         to_jsonb(COALESCE(?->cand.key->>'first_step_id', ?::text))
                       )
                       ELSE ?->cand.key
                     END
                   ),
                   '{}'::jsonb
                 )
                 FROM jsonb_each(?::jsonb) AS cand(key, value))
                """,
                r.confluence_legs,
                r.confluence_legs,
                r.confluence_legs,
                ^step_id,
                r.confluence_legs,
                type(^candidates, :map)
              )
          ]
        ],
        select: r.confluence_legs
      )

    result =
      try do
        case Repo.update_all(query, []) do
          {1, [legs]} -> {:ok, decode_confluence_legs(legs)}
          {0, _} -> {:error, :run_not_found}
        end
      rescue
        exception -> {:error, exception}
      end

    case result do
      {:ok, _} = ok ->
        ok

      {:error, reason} = error ->
        emit_confluence_accumulator_fallback(run_id, step_id, tool_module, reason)
        error
    end
  end

  defp decode_confluence_legs(legs) when is_map(legs) do
    %{
      private_data: decode_confluence_leg(Map.get(legs, "private_data")),
      untrusted_content: decode_confluence_leg(Map.get(legs, "untrusted_content"))
    }
  end

  defp decode_confluence_legs(_other), do: %{private_data: nil, untrusted_content: nil}

  defp decode_confluence_leg(%{"lit" => true} = leg) do
    %{
      source: safe_confluence_leg_source(Map.get(leg, "source")),
      reason_code: safe_confluence_leg_reason_code(Map.get(leg, "reason_code"))
    }
  end

  defp decode_confluence_leg(_other), do: nil

  defp safe_confluence_leg_source("declared"), do: :declared
  defp safe_confluence_leg_source("scanner_infra"), do: :scanner_infra
  defp safe_confluence_leg_source("default_tier"), do: :default_tier
  defp safe_confluence_leg_source("unclassified"), do: :unclassified
  # D-30-style fail-closed fallback: a stored source string this reader
  # does not recognize must never be treated as strong evidence.
  defp safe_confluence_leg_source(_other), do: :unclassified

  defp safe_confluence_leg_reason_code(nil), do: nil

  defp safe_confluence_leg_reason_code(code) when is_binary(code) do
    Confluence.reason_codes()
    |> Enum.find(&(Atom.to_string(&1) == code))
    |> case do
      nil -> :unknown
      atom -> atom
    end
  end

  defp safe_confluence_leg_reason_code(_other), do: nil

  # D-16: a failed accumulator write (or a run row that no longer exists,
  # `{:error, :run_not_found}`) must NOT be silently swallowed --
  # `persist_taint_to_step/4` and `persist_classification_to_step/3` both
  # `rescue _ -> :ok`, and copying that discipline here would mean a
  # failed `confluence_legs` merge produces no leg, no escalation, and no
  # signal: a silent fail-open on the security control under strict mode.
  # Wrapped so a raising host telemetry handler still cannot break the
  # tool call, mirroring every other telemetry emit in this module.
  defp emit_confluence_accumulator_fallback(run_id, step_id, tool_module, reason) do
    try do
      :telemetry.execute(
        [:scoria, :gate, :confluence, :fallback],
        %{},
        %{
          run_id: run_id,
          step_id: step_id,
          tool_ref: inspect(tool_module),
          reason: inspect(reason)
        }
      )
    rescue
      _ -> :ok
    end
  end

  # D-18/D-22 attribution + D-21 containment resolution, evaluated in order
  # BEFORE the escalation body proper: (1) unattributed (no run/step to
  # pause) resolves the `unattributed` configuration key -- shipped
  # default `:allow` -- rather than deny-by-default, because Scoria's own
  # reference handler (`test/scoria/workflows/runtime_span_test.exs`,
  # fixed alongside this plan) does not forward the keys the gate depends
  # on, and denying would refuse every tool call from the canonical
  # copy-paste example (D-22); (2) a halt is terminal and beats
  # EVERYTHING (D-24, checked here verbatim mirroring the pre-existing
  # order -- a halted run is denied without ever creating an approval row,
  # and this check does NOT depend on containment: `Run.halted?/1` never
  # signals `exit`, so it carries none of the risk containment guards
  # against); (3) uncontained (no proof this process is inside a Task
  # lineage `Workflows.Runtime.execute_handler/6` -- or an equivalent host
  # wrapper -- can catch the `exit` below from) is left to run, exactly
  # mirroring the unattributed default, because exiting a process the gate
  # cannot prove is safely caught would crash an arbitrary caller (D-21);
  # unattributed and uncontained both emit the skipped telemetry event
  # mirroring the shipped rail-skipped idiom and NEVER create an approval
  # row -- a pending approval nobody can consume is decorative; (4)
  # otherwise the escalation body proper runs (D-19, D-23, D-28, D-46):
  # build atom-keyed attrs that always carry `:tool_name`
  # (`Approval.changeset/2` requires it and `mark_waiting_for_approval/3`
  # uses `repo.insert!`, so mixed atom/string keys would raise in
  # `cast/3`) plus `blocker_kind: "confluence"` plus `args_fingerprint`
  # (so a LATER approval of this row is consumable by
  # `consume_call_scope/3` above), reuse the EXISTING
  # `Workflows.mark_waiting_for_approval/3` (no bespoke `Approval` insert,
  # no new lifecycle function -- that single call yields all twelve
  # GATE-03 artifacts for free), then signal the runtime with an `exit`,
  # never a `raise` (D-20): a raise is defeated by the common
  # `try/rescue _ ->` adopter pattern; an `exit({:shutdown, term})` from a
  # `Task.Supervisor.async_nolink` task is defeated only by the rare
  # `catch :exit`.
  defp resolve_escalation(tool_module, _args, context, evidence, run_id, step_id) do
    cond do
      is_nil(run_id) or is_nil(step_id) ->
        emit_confluence_skipped(context, tool_module, :unattributed)
        apply_unattributed_disposition(tool_module, context, evidence)

      Run.halted?(Workflows.get_run!(run_id)) ->
        reason_code = Confluence.normalize_reason_code(:unknown)

        emit_confluence_observed(context, tool_module, evidence, "block", nil)

        record_confluence_audit(
          context,
          %{evidence | decision: "block", reason_code: reason_code},
          run_id,
          step_id,
          Map.get(context, :args_fingerprint)
        )

        {:error, confluence_halted_envelope(tool_module, run_id, step_id)}

      not confluence_contained?() ->
        emit_confluence_skipped(context, tool_module, :uncontained)
        emit_confluence_observed(context, tool_module, evidence, "allow", nil)
        {:continue, context}

      true ->
        args_fingerprint = Map.get(context, :args_fingerprint)

        # D-40/D-41: the audit row is written FIRST, and its id threaded
        # into `mark_waiting_for_approval/3`'s attrs as
        # `blocker_audit_outbox_event_id` -- `mark_waiting_for_approval/3`
        # merges caller attrs straight through, so no `workflows.ex` change
        # is needed. Deliberately NO `dedupe_key` in `attrs` (D-41): it
        # would be consumed for the approval-requested row that function
        # also writes, and a second escalation in the same run would then
        # hit the unique index inside that function's OWN transaction,
        # rolling back and failing the entire pause -- not just the audit
        # insert. If the pause transition below fails for any other
        # reason, this row survives as an orphan: the trifecta fired is the
        # truth, and that beats a silent unaudited exfil.
        audit_event =
          record_confluence_audit(
            context,
            %{evidence | decision: "escalate"},
            run_id,
            step_id,
            args_fingerprint
          )

        attrs = %{
          tool_name: tool_module.name(),
          blocker_kind: "confluence",
          reason: "confluence gate: #{evidence.combination}",
          args_fingerprint: args_fingerprint,
          blocker_audit_outbox_event_id: audit_event && audit_event.id
        }

        emit_confluence_observed(context, tool_module, evidence, "escalate", nil)

        case mark_confluence_waiting_for_approval(run_id, step_id, attrs) do
          {:ok, _approval} ->
            exit({:shutdown, {:scoria_confluence_escalation, attrs}})

          {:error, :stale_entry} ->
            {:error, confluence_concurrent_envelope(tool_module, run_id, step_id)}
        end
    end
  end

  # D-28 (MANDATORY, not optional): `Workflows.mark_waiting_for_approval/3`
  # has no stale-entry rescue the way `Workflows.halt_run/3` does (its own
  # explicit `rescue _e in Ecto.StaleEntryError`). A sibling step completing
  # between that function's internal `run = repo.get!(Run, run_id)` read and
  # its own `repo.update!(Run.changeset(run, ...))` write -- a genuine race
  # under Task-dispatched concurrent steps against a real connection pool,
  # not merely theoretical -- raises `Ecto.StaleEntryError`. Left uncaught,
  # this crashes the unlinked dispatch task (`Workflows.Runtime`'s step
  # executor rescues only its OWN step-failure signal, never this), and
  # because the whole `mark_waiting_for_approval/3` transaction rolls back
  # together, the escalating step's own status write rolls back too --
  # stranding the step in "running" forever with no exit signal ever
  # firing. Normalize fail-closed instead: explicitly fail the step (via
  # the ordinary `Workflows.fail_step/3` path every other step failure in
  # this codebase already goes through, so it is never left stuck running)
  # and return the executor's existing confluence-denied refusal-envelope
  # shape rather than propagating. Telemetry/audit for this evaluation
  # already fired "escalate" above (D-36's one-event-per-evaluation
  # invariant is preserved -- this path emits nothing further); the audit
  # row survives as an orphan exactly like any other post-audit pause
  # failure, per plan 57-07's own accepted design (the trifecta fired IS
  # the truth).
  defp mark_confluence_waiting_for_approval(run_id, step_id, attrs) do
    Workflows.mark_waiting_for_approval(run_id, step_id, attrs)
  rescue
    _e in Ecto.StaleEntryError ->
      Workflows.fail_step(step_id, %{
        "reason_code" => "confluence_concurrent_run_mutation",
        "reason" => "a sibling step mutated the run concurrently with this escalation"
      })

      {:error, :stale_entry}
  end

  defp confluence_concurrent_envelope(tool_module, run_id, step_id) do
    %{
      status: :confluence_denied,
      reason_code: "confluence_concurrent_run_mutation",
      tool_ref: inspect(tool_module),
      run_id: run_id,
      step_id: step_id
    }
  end

  # D-22: `unattributed` defaults to `:allow`. Anything else a host
  # configures cannot literally be honored as a PAUSE (there is no
  # run/step to pause), so it is honored as a DENIAL instead -- never an
  # approval row (there is nothing resumable to attach one to).
  defp apply_unattributed_disposition(tool_module, context, evidence) do
    config = Confluence.resolve_config(context)
    disposition = Map.get(config, :unattributed, :allow) |> to_string()

    case disposition do
      "allow" ->
        emit_confluence_observed(context, tool_module, evidence, "allow", nil)
        {:continue, context}

      _other ->
        reason_code = Confluence.normalize_reason_code(:unknown)

        emit_confluence_observed(context, tool_module, evidence, "block", reason_code)

        record_confluence_audit(
          context,
          %{evidence | decision: "block", reason_code: reason_code},
          Map.get(context, :run_id),
          Map.get(context, :step_id),
          Map.get(context, :args_fingerprint)
        )

        {:error, confluence_unattributed_envelope(tool_module, context)}
    end
  end

  defp confluence_halted_envelope(tool_module, run_id, step_id) do
    %{
      status: :confluence_denied,
      reason_code: "run_halted",
      tool_ref: inspect(tool_module),
      run_id: run_id,
      step_id: step_id
    }
  end

  defp confluence_unattributed_envelope(tool_module, context) do
    %{
      status: :confluence_denied,
      reason_code: "unattributed",
      tool_ref: inspect(tool_module),
      trace_id: Map.get(context, :trace_id)
    }
  end

  # D-21: proves this process is running inside a Task lineage
  # `Workflows.Runtime.execute_handler/6` (or an equivalent host wrapper)
  # can safely catch the `exit({:shutdown, ...})` escalation signal from,
  # rather than directly in an arbitrary caller process (a LiveView, a
  # Phoenix controller, a bare GenServer) the gate has no business
  # exiting -- there is genuinely no channel from `Workflows.Runtime` into
  # the executor's `context` to carry an explicit flag instead
  # (`decorate_run_with_trace_context/4` writes onto an ephemeral run copy
  # the host handler must hand-forward, which cannot be guaranteed).
  #
  # `self()` is checked FIRST via `@confluence_containment_key`, an
  # explicit Scoria-owned marker this function caches once containment is
  # proven, so a synchronous nested `Executor.execute/4` call in the SAME
  # process is an O(1) hit. `Process.get(:"$callers", [])` is checked
  # SECOND, over every pid it names: `Task.async/1`, `Task.Supervisor.async(_nolink)/2,3`,
  # and `Task.async_stream/3` (itself `Task.Supervisor`-backed) all
  # propagate `:"$callers"` to the spawned process automatically and
  # TRANSITIVELY (a doubly-nested `Task.async` chains the full ancestor
  # lineage back to the very first non-Task process), so a non-emptiness
  # check on self()'s OWN `$callers` already covers arbitrary nesting
  # depth of both idioms with zero additional Scoria-side wiring --
  # exactly the "no channel exists" finding above. Each named pid is ALSO
  # checked for the explicit marker directly, in case a host process was
  # marked without itself being Task-spawned. A raw `spawn/1` propagates
  # NEITHER the process dictionary NOR `$callers` -- the honest,
  # telemetried residual; never papered over.
  @confluence_containment_key :scoria_confluence_contained

  defp confluence_contained? do
    contained =
      Process.get(@confluence_containment_key, false) == true or
        Process.get(:"$callers", []) != [] or
        Enum.any?(Process.get(:"$callers", []), &confluence_ancestor_marked?/1)

    if contained, do: Process.put(@confluence_containment_key, true)
    contained
  end

  defp confluence_ancestor_marked?(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dict} -> Keyword.get(dict, @confluence_containment_key, false) == true
      _other -> false
    end
  end

  # Mirrors the shipped `[:scoria, :run, :rail, :skipped]` idiom
  # (`emit_rail_skipped_event/3` above) exactly -- same naming shape, same
  # metadata discipline, wrapped so a raising host handler cannot break
  # the tool call.
  defp emit_confluence_skipped(context, tool_module, reason) do
    try do
      :telemetry.execute(
        [:scoria, :gate, :confluence, :skipped],
        %{},
        %{
          reason: reason,
          tool_ref: inspect(tool_module),
          site: :mcp_executor,
          tenant_id: Map.get(context, :tenant_id),
          session_id: Map.get(context, :session_id),
          trace_id: Map.get(context, :trace_id),
          run_id: Map.get(context, :run_id),
          step_id: Map.get(context, :step_id)
        }
      )
    rescue
      _ -> :ok
    end
  end

  # D-36: exactly ONE event per confluence evaluation, on ALL THREE
  # dispositions (allow/escalate/block), `decision` carried as a metadata
  # TAG rather than as separate per-decision events -- an ungated-only
  # event has no denominator, which is exactly how truncated dry-run
  # signals have historically failed operators. Measurements are an empty
  # map, copying the shipped unclassified-classification event's shape.
  # The span-bound half (`combination`/`decision`/`grade`/`reason_code`/
  # `approval_ref`) is projected through `Semconv.confluence_attributes/1`
  # so no unregistered field can ride along; `run_id`/`step_id`/`trace_id`
  # ride as CORRELATION identifiers only and must never be used as metric
  # dimensions. Wrapped so a raising host handler cannot break the tool
  # call -- the deliberate asymmetry from plan 06's accumulator write,
  # where a write failure must NOT be silently swallowed.
  #
  # Operator guidance (D-36): the adopter-facing number must be
  # would-have-paused counts segmented by `grade`, never a raw firing
  # count -- in observe posture the trifecta fires on effectively all
  # legacy traffic, and a 100%-by-construction number is the one that
  # makes operators stop looking. Phase 58 owns rendering it; this event's
  # shape is what makes that segmentation possible.
  defp emit_confluence_observed(context, tool_module, evidence, decision, reason_code_override) do
    try do
      span_attrs =
        %{
          combination: evidence && evidence.combination,
          decision: decision,
          grade: evidence && evidence.grade,
          reason_code: reason_code_override || (evidence && evidence.reason_code),
          approval_ref: nil
        }
        |> Semconv.confluence_attributes()

      metadata =
        Map.merge(span_attrs, %{
          action_class: evidence && evidence.action_class,
          private_data_source: evidence && evidence.private_data_source,
          untrusted_content_source: evidence && evidence.untrusted_content_source,
          exfil_source: evidence && evidence.exfil_source,
          tool_ref: inspect(tool_module),
          site: :mcp_executor,
          run_id: Map.get(context, :run_id),
          step_id: Map.get(context, :step_id),
          trace_id: Map.get(context, :trace_id)
        })

      :telemetry.execute([:scoria, :gate, :confluence, :observed], %{}, metadata)
    rescue
      _ -> :ok
    end
  end

  defp execute_live(tool_module, args, context, timeout) do
    with {:ok, access_context} <- maybe_capture_sensitive_mcp_access(tool_module, args, context),
         {:ok, reservation_context} <- reserve_budget(tool_module, args, access_context),
         {:ok, execution_context} <-
           ensure_policy_sensitive_invocation(
             tool_module,
             args,
             access_context,
             reservation_context
           ) do
      metadata =
        access_context
        |> Map.merge(%{tool: tool_module, args: args})
        |> attach_budget_metadata(execution_context)
        |> Map.put_new(:tool_ref, inspect(tool_module))

      breaker_context =
        access_context
        |> Map.put_new(:tool_ref, inspect(tool_module))

      case BreakerRegistry.run(breaker_context, fn ->
             execute_tool(tool_module, args, access_context, timeout, metadata)
           end) do
        {:ok, {:completed, result, duration}} ->
          # D-07 load-bearing ordering: reconcile_budget/emit_sre_telemetry
          # read the RAW `result` before any scan/envelope wrapping happens
          # below. Do not reorder this.
          reconcile_budget(execution_context, access_context, result, "completed")
          emit_sre_telemetry(tool_module, access_context, "completed", duration, result)

          # D-18/D-21: scan the tool output at THIS envelope-creation choke
          # point (after billing has read the raw result) and tag the SAME
          # [:scoria, :tool, :completed] telemetry event with the resolved
          # scoria.trust.* attributes -- no second span (D-21).
          {trust_attrs, verdict, scan_slot} = scan_tool_output(result, access_context)

          # Plan 56-02: the resolved scoria.classification.* attributes join
          # the SAME [:scoria, :tool, :completed] event alongside trust_attrs
          # -- no new span, no second :telemetry.execute/3 call (D-21 no-
          # second-span discipline applies unchanged).
          class_attrs = classification_attributes_for_telemetry(access_context)

          :telemetry.execute(
            [:scoria, :tool, :completed],
            %{duration: duration},
            metadata |> Map.merge(trust_attrs) |> Map.merge(class_attrs)
          )

          finalize_tool_result(result, tool_module, access_context, verdict, scan_slot)

        {:error, {:timeout, duration}} ->
          reconcile_budget(execution_context, access_context, %{}, "timeout")
          emit_sre_telemetry(tool_module, access_context, "timeout", duration, %{})
          :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
          {:error, :timeout}

        {:error, {:execution_failed, duration, reason}} ->
          reconcile_budget(execution_context, access_context, %{}, "execution_failed")
          emit_sre_telemetry(tool_module, access_context, "execution_failed", duration, %{})

          :telemetry.execute(
            [:scoria, :tool, :failed],
            %{duration: duration},
            Map.put(metadata, :reason, reason)
          )

          {:error, :execution_failed}

        {:error, %{status: :breaker_open} = envelope} ->
          reconcile_budget(execution_context, access_context, %{}, "breaker_open")
          emit_breaker_open_telemetry(tool_module, access_context, envelope)

          :telemetry.execute(
            [:scoria, :tool, :failed],
            %{duration: 0},
            Map.put(metadata, :reason, :breaker_open)
          )

          {:error, envelope}
      end
    else
      {:error, envelope} ->
        emit_access_denied_telemetry(tool_module, context, envelope)
        {:error, envelope}
    end
  end

  defp replay_gate(tool_module, _args, context) do
    case load_replay_run(context) do
      %Run{execution_mode: "replay"} = run ->
        seam = build_replay_seam(tool_module, context)
        source_evidence = Map.get(context, :source_evidence, %{})
        approval_context = Map.get(context, :approval_context, %{})
        override_context = Map.get(context, :override_context, run.replay_overrides || %{})

        case ReplayDisposition.resolve(
               run,
               seam,
               source_evidence,
               approval_context,
               override_context
             ) do
          {:historical_stub, evidence} ->
            record_replay_audit(context, tool_module, evidence, "tool.replay.stubbed")

            raw_result = Map.get(source_evidence, :result) || Map.get(source_evidence, "result")

            {:ok,
             %{
               status: :historical_stub,
               replay_disposition: :historical_stub,
               replay_reason_code: evidence.replay_reason_code,
               # D-10: wrapped under the SAME flag as the live success path so
               # a consumer written against `{:ok, %Envelope{}}` never diverges
               # on replay.
               result:
                 maybe_wrap_envelope(raw_result, tool_module, context,
                   provenance_overrides: %{source: :replay_stub}
                 )
             }}

          {:blocked, evidence} ->
            audit_id = record_replay_audit(context, tool_module, evidence, "tool.replay.blocked")

            {:error,
             %{
               status: :replay_blocked,
               replay_disposition: :blocked,
               replay_reason_code: evidence.replay_reason_code,
               source_run_id: evidence.source_run_id,
               source_checkpoint_id: evidence.source_checkpoint_id,
               source_step_id: evidence.source_step_id,
               source_approval_id: evidence.source_approval_id,
               source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
               audit_outbox_event_id: audit_id
             }}

          {:execute_live, evidence} ->
            {:continue,
             context
             |> Map.put(:replay_disposition, evidence.replay_disposition)
             |> Map.put(:replay_reason_code, evidence.replay_reason_code)
             |> Map.put(:replay_idempotency_key, evidence.replay_idempotency_key)
             |> Map.put(:source_run_id, evidence.source_run_id)
             |> Map.put(:source_checkpoint_id, evidence.source_checkpoint_id)
             |> Map.put(:source_step_id, evidence.source_step_id)
             |> Map.put(:source_approval_id, evidence.source_approval_id)
             |> Map.put(:source_audit_outbox_event_id, evidence.source_audit_outbox_event_id)
             |> Map.put(:args_fingerprint, evidence.args_fingerprint)
             |> Map.put(:executed_live, true)}
        end

      _ ->
        {:continue, context}
    end
  end

  defp load_replay_run(context) do
    case Map.get(context, :run) do
      %Run{} = run ->
        run

      _ ->
        try do
          case Map.get(context, :run_id) do
            nil -> nil
            run_id -> Workflows.get_run!(run_id)
          end
        rescue
          Ecto.NoResultsError -> nil
        end
    end
  end

  defp build_replay_seam(tool_module, context) do
    %{
      tool_classification: Map.get(context, :tool_classification),
      local_classification: Map.get(context, :local_classification, :write),
      tool_id: Map.get(context, :tool_id, inspect(tool_module)),
      action_class: Map.get(context, :action_class, "write"),
      risk_level: Map.get(context, :risk_level, "high"),
      approval_sensitive:
        Map.get(context, :approval_sensitive, Map.get(context, :policy_sensitive, false)),
      args_fingerprint: Map.get(context, :args_fingerprint),
      subject_ref: Map.get(context, :subject_ref),
      required_scopes: Map.get(context, :required_scopes, []),
      grant_state: Map.get(context, :grant_state),
      policy_key: Map.get(context, :policy_key),
      authority_expanding: Map.get(context, :authority_expanding),
      remote_hint: Map.get(context, :remote_hint)
    }
  end

  defp record_replay_audit(context, tool_module, evidence, event_type) do
    case SRE.create_audit_outbox_event(%{
           tenant_id: Map.get(context, :tenant_id, "system"),
           actor_id: Map.get(context, :actor_id),
           workflow_run_id: Map.get(context, :run_id),
           step_id: Map.get(context, :step_id),
           trace_id: Map.get(context, :trace_id),
           event_type: event_type,
           policy_class: "replay_execution",
           policy_key: evidence.policy_key,
           tool_ref: inspect(tool_module),
           replay_disposition: evidence.replay_disposition,
           replay_reason_code: evidence.replay_reason_code,
           source_run_id: evidence.source_run_id,
           source_checkpoint_id: evidence.source_checkpoint_id,
           source_step_id: evidence.source_step_id,
           source_approval_id: evidence.source_approval_id,
           source_audit_outbox_event_id: evidence.source_audit_outbox_event_id,
           args_fingerprint: evidence.args_fingerprint,
           executed_live: false
         }) do
      {:ok, event} -> event.id
      _ -> nil
    end
  end

  # D-07: only the `{:ok, value}` leg's inner `value` is ever wrapped — never
  # the raw `{:ok, value} | {:error, reason}` tuple itself (that would
  # double-nest `%Envelope{value: {:ok, v}}`, RESEARCH.md Pitfall 1).
  # `{:error, _}` passes through untouched under both flag states.
  defp finalize_tool_result({:ok, value}, tool_module, context, verdict, scan_slot) do
    persist_taint(context, tool_module, verdict)

    {:ok,
     maybe_wrap_envelope(value, tool_module, context,
       tier: verdict && verdict.tier,
       scan: scan_slot
     )}
  end

  defp finalize_tool_result({:error, _} = error, _tool_module, _context, _verdict, _scan_slot),
    do: error

  # Defensive fallback: `Scoria.MCP.Tool.execute/2`'s callback contract is
  # `{:ok, any()} | {:error, any()}`, but a misbehaving tool returning
  # something else must not crash the executor.
  defp finalize_tool_result(other, _tool_module, _context, _verdict, _scan_slot), do: other

  # D-18: scans the tool output at the envelope-creation choke point. Only
  # the `{:ok, value}` leg is scanned -- an `{:error, _}` result never
  # minted taint content in the first place. The scanner is resolved via
  # `Map.get(context, :content_scanner, ...)` (D-17 -- `context` is a MAP
  # throughout the executor, unlike `Knowledge.retrieve/2`'s keyword-list
  # `opts`, so this reads via `Map.get/3`, never `Keyword.pop`).
  #
  # `scanner == Scanner.NoOp` is the D-17 true no-op: `Trust.scan/2` still
  # resolves (zero Task overhead, `Scan.scan/2`'s own internal
  # short-circuit), but the `Envelope.scan` slot stays `nil` (byte-identical
  # Plan 02 behavior) -- only a REAL scanner's verdict is ever exposed
  # there.
  #
  # D-01 (plan 57-03 fix): a freshly minted tool output has no PRIOR taint,
  # so omitting `:incoming_tier` here previously left `Trust.Scan.scan/2` to
  # silently default it to `Trust.default_tier/0` ("untrusted"), and the
  # min-wins `most_restrictive/2` fold then pinned EVERY tool output to
  # untrusted regardless of what a real scanner returned. When a real
  # scanner is actually going to evaluate `value`, seed `:incoming_tier` at
  # the trusted identity explicitly (mirroring `Knowledge.retrieve/2`'s
  # `aggregate_incoming_tier/1` pattern of computing the incoming tier
  # rather than relying on the callee's default) so the scanner's own
  # verdict decides the outcome. When the resolved scanner is the shipped
  # NoOp (nothing evaluates `value`), `:incoming_tier` is deliberately left
  # unset so `Trust.Scan.scan/2` keeps its existing fail-closed default --
  # "untrusted" is the correct identity for content nobody looked at;
  # "trusted" is only correct once something is about to look. The reader
  # path's default (`Trust.tier/1`) is a completely separate code path and
  # is NOT touched by this fix.
  defp scan_tool_output({:ok, value}, context) do
    scanner =
      Map.get(
        context,
        :content_scanner,
        Application.get_env(:scoria, :content_scanner, Scanner.NoOp)
      )

    scan_context = Map.put(context, :content_scanner, scanner)

    scan_context =
      if scanner == Scanner.NoOp do
        scan_context
      else
        Map.put(scan_context, :incoming_tier, "trusted")
      end

    {:ok, verdict} = Trust.scan(value, scan_context)

    # Plan 57-05 reconciliation: `scanner_tier` now rides `Semconv.trust_attributes/1`'s
    # closed five-key projector (`:scanner_tier` registered phase 57 plan
    # 05) rather than the hand-injected `Map.put("scoria.trust.scanner_tier",
    # ...)` plan 57-03 used as a stopgap because `lib/scoria/observe/semconv.ex`
    # was outside that plan's file scope. Fixes the SEC-01 closed-registry
    # hole 57-03 flagged: an unregistered key emitted at runtime that the
    # registry canary (which only pins the registry literal) could not
    # catch.
    trust_attrs =
      %{
        tier: verdict.tier,
        scanner: verdict.scanner && inspect(verdict.scanner),
        reason_code: verdict.reason_code,
        scanner_tier: verdict.scanner_tier
      }
      |> Semconv.trust_attributes()

    scan_slot = if scanner == Scanner.NoOp, do: nil, else: verdict

    {trust_attrs, verdict, scan_slot}
  end

  defp scan_tool_output(_other, _context), do: {%{}, nil, nil}

  # Plan 56-02: projects the resolved `%Classification{}` already carried on
  # `context` (put there by `resolve_classification/2`) through
  # `Semconv.classification_attributes/1`'s fixed-key projector. `source` is
  # converted with `to_string/1` so the emitted attribute is a string enum,
  # not an Elixir atom literal. Absent classification (never expected on the
  # live path, since resolution always runs first) yields an empty map.
  defp classification_attributes_for_telemetry(context) do
    case Map.get(context, :tool_classification) do
      %Classification{} = classification ->
        classification
        |> Map.from_struct()
        |> Map.update!(:source, &to_string/1)
        |> Semconv.classification_attributes()

      _ ->
        %{}
    end
  end

  # D-08: taint is ALWAYS computed, and is durably persisted -- but NOT
  # ALWAYS via the step's jsonb `result_envelope`. Corrected (plan 57-06):
  # this used to claim taint is "always ... inspectable via the step's
  # jsonb result_envelope", which is false for the completing workflow
  # path. `persist_taint_to_step/4` below best-effort merges the taint map
  # onto the step's `result_envelope` immediately after this call, but
  # `Scoria.Workflows.complete_step/3` WHOLESALE-REPLACES that envelope
  # from the handler's own return on every successful step, and
  # `Scoria.Workflows.retry_step/1` zeroes it entirely on retry -- so this
  # merge (and the Phase 56 classification merge in
  # `persist_classification_to_step/3`) survives only for a step that is
  # NOT currently completed-and-replaced at read time (failed, timed out,
  # or paused `waiting_for_approval`), and is destroyed on every
  # successful completion. The durable, run-scoped record Phase 57 (and
  # Phase 58's read path) actually relies on is
  # `ai_workflow_runs.confluence_legs` (`Scoria.Workflows.Run`), written
  # independently of the step result envelope's own lifecycle by this
  # phase's dedicated accumulator fold. The flag below only gates the
  # RETURN SHAPE, never this computation. `verdict` is the resolved
  # `Scoria.Trust.Scan` verdict (D-18) -- under `Scanner.NoOp` this resolves
  # to the same `Trust.default_tier/0` value persisted here before this
  # plan, so NoOp behavior is byte-identical (D-17).
  defp persist_taint(context, tool_module, verdict) do
    tier = (verdict && verdict.tier) || Trust.default_tier()
    scanner_tier = verdict && verdict.scanner_tier

    emit_taint_telemetry(context, tool_module, tier)
    persist_taint_to_step(context, tool_module, tier, scanner_tier)
  end

  defp emit_taint_telemetry(context, tool_module, tier) do
    try do
      :telemetry.execute(
        [:scoria, :trust, :taint],
        %{},
        %{
          tool: tool_module,
          tier: tier,
          trace_id: Map.get(context, :trace_id),
          step_id: Map.get(context, :step_id)
        }
      )
    rescue
      _ -> :ok
    end
  end

  # Persists the always-COMPUTED (not always-DURABLE -- see the corrected
  # note on `persist_taint/3` above) taint map onto the step's
  # `result_envelope` jsonb via a Postgres jsonb merge (mirrors
  # `Knowledge.set_source_trust/3`'s `fragment("? || ?", ...)` pattern) — no
  # new Ecto column (D-08). Best-effort: a standalone/non-workflow tool
  # invocation with no `step_id` in context, or no matching step row, is not
  # an error — taint has already been telemetried above. This value is
  # WHOLESALE-REPLACED by `Scoria.Workflows.complete_step/3` on every
  # successful completion and zeroed by `Scoria.Workflows.retry_step/1` on
  # retry -- it is inspectable here only transiently, never durably.
  #
  # `scanner_tier` (plan 57-03, D-01b) rides alongside `tier` here as the
  # SAME kind of confluence-facing evidence `persist_classification_to_step/3`
  # writes for classification -- a plain jsonb string, never an Elixir atom
  # literal (unlike the pre-existing `verdict.reason_code` passthrough into
  # `Semconv.trust_attributes/1`, which stays a bare atom on the telemetry
  # side because that projector is out of this plan's file scope; this
  # value must not repeat that pattern). Omitted from the map entirely when
  # nil (NoOp path, or no scanner opinion) rather than persisted as a
  # placeholder.
  defp persist_taint_to_step(context, tool_module, tier, scanner_tier) do
    case Map.get(context, :step_id) do
      nil ->
        :ok

      step_id ->
        taint =
          %{
            "tier" => tier,
            "tool_ref" => inspect(tool_module),
            "args_fingerprint" => Map.get(context, :args_fingerprint)
          }
          |> maybe_put_scanner_tier(scanner_tier)

        try do
          from(step in Step,
            where: step.id == ^step_id,
            update: [
              set: [
                result_envelope:
                  fragment(
                    "? || ?",
                    step.result_envelope,
                    type(^%{"scoria.taint" => taint}, :map)
                  )
              ]
            ]
          )
          |> Repo.update_all([])
        rescue
          _ -> :ok
        end

        :ok
    end
  end

  defp maybe_put_scanner_tier(taint, nil), do: taint

  defp maybe_put_scanner_tier(taint, scanner_tier) when is_binary(scanner_tier),
    do: Map.put(taint, "scanner_tier", scanner_tier)

  # Persists every resolved classification (declared, host-tightened, or
  # unclassified-default) onto the step's `result_envelope` jsonb, mirroring
  # `persist_taint_to_step/4`'s choke point and best-effort discipline
  # exactly (D-03/D-06): a `nil` `:step_id`, or one matching no row, is `:ok`
  # and never an error. `source` round-trips through `to_string/1` so
  # Phase 57 can branch on it after a plain jsonb read (never an Elixir atom
  # literal). Called at RESOLUTION time (from `resolve_classification/2`'s
  # non-refusal branch), not from `finalize_tool_result/5` -- unlike taint,
  # which is only meaningful for a completed `{:ok, value}` result, Phase 57
  # needs the classification of blocked and stubbed calls too. Never called
  # on the strict-refusal branch: a refused call never runs and has no step
  # evidence to attach.
  defp persist_classification_to_step(context, tool_module, %Classification{} = resolved) do
    case Map.get(context, :step_id) do
      nil ->
        :ok

      step_id ->
        data = %{
          "action_class" => resolved.action_class,
          "source" => to_string(resolved.source),
          "reads_private_data" => resolved.reads_private_data,
          "sees_untrusted_content" => resolved.sees_untrusted_content,
          "can_exfiltrate" => resolved.can_exfiltrate,
          "tool_ref" => inspect(tool_module)
        }

        try do
          from(step in Step,
            where: step.id == ^step_id,
            update: [
              set: [
                result_envelope:
                  fragment(
                    "? || ?",
                    step.result_envelope,
                    type(^%{"scoria.classification" => data}, :map)
                  )
              ]
            ]
          )
          |> Repo.update_all([])
        rescue
          _ -> :ok
        end

        :ok
    end
  end

  # Soft-launch flag (D-08): the return VALUE stays byte-identical to 0.1.3
  # unless `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: true` is
  # set (default off). `opts[:provenance_overrides]` lets the replay-stub
  # call site (D-10) tag its provenance distinctly while sharing this same
  # gate. `opts[:tier]` carries the resolved `Scoria.Trust.Scan` verdict
  # tier (D-18, already monotonic-resolved over the default by `Scan`
  # itself) -- defaults to `Trust.default_tier/0` when absent (the
  # replay-stub call site below never scans, so it keeps the pre-Plan-05
  # default). `opts[:scan]` carries the `Envelope.scan` slot (D-06) -- `nil`
  # for the replay-stub path and for a `Scanner.NoOp` resolution.
  defp maybe_wrap_envelope(value, tool_module, context, opts) do
    if wrap_tool_output?() do
      provenance =
        %{
          tool_ref: Map.get(context, :tool_ref, inspect(tool_module)),
          tool_name: tool_name(tool_module),
          trace_id: Map.get(context, :trace_id),
          workflow_run_id: Map.get(context, :run_id),
          step_id: Map.get(context, :step_id),
          args_fingerprint: Map.get(context, :args_fingerprint)
        }
        |> Map.merge(Keyword.get(opts, :provenance_overrides, %{}))

      Envelope.wrap(value,
        tier: Keyword.get(opts, :tier) || Trust.default_tier(),
        provenance: provenance,
        scan: Keyword.get(opts, :scan)
      )
    else
      value
    end
  end

  defp wrap_tool_output? do
    :scoria
    |> Application.get_env(Envelope, [])
    |> Keyword.get(:wrap_tool_output, false)
  end

  defp execute_tool(tool_module, args, context, timeout, metadata) do
    :telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

    start_time = System.monotonic_time()

    task =
      Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
        tool_module.execute(args, context)
      end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} ->
        {:ok, {:completed, result, System.monotonic_time() - start_time}}

      nil ->
        {:error, {:timeout, System.monotonic_time() - start_time}}

      {:exit, reason} ->
        {:error, {:execution_failed, System.monotonic_time() - start_time, reason}}
    end
  end

  defp reserve_budget(tool_module, args, context) do
    if budget_required?(context) do
      identity = context_identity(context)

      BudgetEngine.reserve_step(%{
        tenant_id: identity.tenant_id,
        actor_id: identity.actor_id,
        run_id: Map.get(context, :run_id),
        step_id: Map.get(context, :step_id),
        trace_id: Map.get(context, :trace_id),
        resource: budget_resource(context),
        reason_code: Map.get(context, :reason_code, "mcp.execute"),
        estimated_units: estimated_units(context),
        integration_kind: Map.get(context, :integration_kind, "tool"),
        tool_ref: inspect(tool_module),
        audit_envelope: policy_sensitive_audit_envelope(tool_module, args, context),
        metadata:
          context
          |> Map.get(:metadata, %{})
          |> Map.put_new("tool_hash", Integer.to_string(:erlang.phash2({tool_module, args})))
      })
    else
      {:ok, nil}
    end
  end

  defp reconcile_budget(nil, _context, _result, _outcome), do: :ok

  defp reconcile_budget(%{audit_outbox_event: _audit_outbox_event}, _context, _result, _outcome),
    do: :ok

  defp reconcile_budget(%{reservation: reservation}, _context, _result, "breaker_open") do
    BudgetEngine.reconcile_breaker_open(reservation)
  end

  defp reconcile_budget(%{reservation: reservation}, context, result, outcome) do
    BudgetEngine.reconcile_usage(reservation, %{
      actual_units: actual_units(context, result, outcome),
      metadata: %{"outcome" => outcome}
    })
  end

  defp attach_budget_metadata(metadata, nil), do: metadata

  defp attach_budget_metadata(metadata, %{audit_outbox_event: audit_outbox_event}),
    do: Map.put(metadata, :audit_outbox_event_id, audit_outbox_event.id)

  defp attach_budget_metadata(metadata, %{reservation: reservation}),
    do: Map.put(metadata, :budget_reservation_id, reservation.id)

  # Site 3 (D-05, plan 56-03): the SAME shared declared-only sensitivity
  # predicate used by site 2 (`policy_sensitive_invocation?/1`) is the
  # fifth OR operand -- one origin for "does this declaration count as
  # sensitive" is what keeps the two sites from drifting apart. This also
  # widens the read-only `maybe_emit_budget/4` call site (`:843-858`): a
  # declaring tool now emits budget telemetry too, which is intended and
  # consistent with reserving budget for it.
  defp budget_required?(context) do
    Map.get(context, :estimated_cost_usd) ||
      Map.get(context, :estimated_tokens) ||
      Map.get(context, :estimated_units) ||
      Map.get(context, :sensitive_tool) ||
      Classification.declared_sensitive?(Map.get(context, :tool_classification))
  end

  defp budget_resource(context) do
    cond do
      Map.get(context, :resource) -> Map.get(context, :resource)
      Map.get(context, :estimated_cost_usd) -> "cost_usd"
      Map.get(context, :estimated_tokens) -> "token_in"
      true -> "tool_calls"
    end
  end

  defp estimated_units(context) do
    cond do
      Map.get(context, :estimated_units) -> Map.get(context, :estimated_units)
      Map.get(context, :estimated_cost_usd) -> Map.get(context, :estimated_cost_usd)
      Map.get(context, :estimated_tokens) -> Map.get(context, :estimated_tokens)
      true -> 1
    end
  end

  # `@doc false` (not `defp`) so the D-07 defense-in-depth `%Envelope{}` head
  # below is directly unit-testable even though the current (correct)
  # `execute_live/4` ordering never routes a wrapped value through here —
  # billing runs on the raw result before `finalize_tool_result/3` wraps it.
  # This is an internal function, not a published API.
  @doc false
  def actual_units(_context, _result, outcome) when outcome in ["timeout", "execution_failed"],
    do: 0

  def actual_units(context, {:ok, result}, outcome), do: actual_units(context, result, outcome)

  # Defense-in-depth (D-07): billing runs on the RAW result before any
  # envelope wrap happens (see `finalize_tool_result/3`), so this head never
  # fires in the current ordering. It exists so a future reorder that wraps
  # before billing can't silently mis-bill against `%Envelope{}`'s own struct
  # shape instead of its inner `value`.
  def actual_units(context, %Envelope{value: v}, outcome), do: actual_units(context, v, outcome)

  def actual_units(context, result, _outcome) do
    cond do
      is_map(result) && Map.has_key?(result, :actual_units) ->
        Map.fetch!(result, :actual_units)

      is_map(result) && Map.has_key?(result, "actual_units") ->
        Map.fetch!(result, "actual_units")

      is_map(result) && Map.has_key?(result, :actual_cost_usd) ->
        Map.fetch!(result, :actual_cost_usd)

      is_map(result) && Map.has_key?(result, "actual_cost_usd") ->
        Map.fetch!(result, "actual_cost_usd")

      true ->
        estimated_units(context)
    end
  end

  defp maybe_capture_sensitive_mcp_access(tool_module, args, context) do
    if Map.get(context, :sensitive_mcp_access) do
      decision = Map.get(context, :access_decision, "granted")
      identity = context_identity(context)

      with {:ok, audit_outbox_event} <-
             SRE.create_audit_outbox_event(%{
               tenant_id: identity.tenant_id,
               actor_id: identity.actor_id,
               workflow_run_id: Map.get(context, :run_id),
               step_id: Map.get(context, :step_id),
               trace_id: Map.get(context, :trace_id),
               event_type: "mcp.access.#{decision}",
               policy_class: "sensitive_mcp_access",
               access_decision: decision,
               access_reason: Map.get(context, :access_reason),
               policy_key: Map.get(context, :policy_key),
               tool_ref: inspect(tool_module),
               args: args,
               metadata: %{
                 "integration_kind" => Map.get(context, :integration_kind, "remote_mcp"),
                 "mcp_endpoint" => Map.get(context, :mcp_endpoint) || Map.get(context, :endpoint)
               }
             }) do
        case decision do
          "denied" ->
            {:error,
             %{
               status: :access_denied,
               reason_code: Map.get(context, :access_reason, "policy_denied"),
               audit_outbox_event_id: audit_outbox_event.id,
               trace_id: Map.get(context, :trace_id),
               policy_key: Map.get(context, :policy_key)
             }}

          _ ->
            {:ok, context}
        end
      end
    else
      {:ok, context}
    end
  end

  defp ensure_policy_sensitive_invocation(tool_module, args, context, nil) do
    if policy_sensitive_invocation?(context) do
      case SRE.create_audit_outbox_event(
             policy_sensitive_audit_envelope(tool_module, args, context)
           ) do
        {:ok, audit_outbox_event} -> {:ok, %{audit_outbox_event: audit_outbox_event}}
        {:error, value} -> {:error, value}
      end
    else
      {:ok, nil}
    end
  end

  defp ensure_policy_sensitive_invocation(_tool_module, _args, _context, reservation_context),
    do: {:ok, reservation_context}

  # Site 2 (D-05, plan 56-03): the first two operands stay byte-identical --
  # a host value still wins and a host-`false` is still falsy exactly as
  # before this plan. The third OR term is declared-only (D-A2): a tool
  # that declares `can_exfiltrate: true` or an `action_class` of `"exec"`/
  # `"admin"` now trips this predicate even when the host passed neither
  # `:policy_sensitive` nor `:sensitive_tool` -- the fail-open seam
  # actually closing for adopters who opt in, never for legacy traffic
  # (the shared predicate below returns `false` for `:unclassified_default`).
  defp policy_sensitive_invocation?(context) do
    Map.get(context, :policy_sensitive) || Map.get(context, :sensitive_tool) ||
      Classification.declared_sensitive?(Map.get(context, :tool_classification))
  end

  defp policy_sensitive_audit_envelope(tool_module, args, context) do
    if policy_sensitive_invocation?(context) do
      identity = context_identity(context)

      %{
        tenant_id: identity.tenant_id,
        actor_id: identity.actor_id,
        workflow_run_id: Map.get(context, :run_id),
        step_id: Map.get(context, :step_id),
        trace_id: Map.get(context, :trace_id),
        event_type: "tool.invocation",
        policy_class: "policy_sensitive",
        dedupe_key: Map.get(context, :replay_idempotency_key),
        policy_key: Map.get(context, :policy_key),
        tool_ref: inspect(tool_module),
        args: args,
        replay_disposition: Map.get(context, :replay_disposition),
        replay_reason_code: Map.get(context, :replay_reason_code),
        source_run_id: Map.get(context, :source_run_id),
        source_checkpoint_id: Map.get(context, :source_checkpoint_id),
        source_step_id: Map.get(context, :source_step_id),
        source_approval_id: Map.get(context, :source_approval_id),
        source_audit_outbox_event_id: Map.get(context, :source_audit_outbox_event_id),
        args_fingerprint: Map.get(context, :args_fingerprint),
        executed_live: Map.get(context, :executed_live, false),
        replay_idempotency_key: Map.get(context, :replay_idempotency_key),
        metadata: %{
          "integration_kind" => Map.get(context, :integration_kind, "tool"),
          "tool_target" => Map.get(context, :tool_target),
          "breaker_target" => Map.get(context, :breaker_target)
        }
      }
    end
  end

  defp emit_sre_telemetry(tool_module, context, outcome, duration_native, result) do
    attrs =
      base_attrs(tool_module, context, outcome)
      |> Map.put(:duration_ms, System.convert_time_unit(duration_native, :native, :millisecond))
      |> Map.put(:success, outcome == "completed")

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    maybe_emit_budget(attrs, context, outcome, result)
  end

  defp emit_breaker_open_telemetry(tool_module, context, envelope) do
    attrs =
      base_attrs(tool_module, context, "breaker_open")
      |> Map.merge(%{
        duration_ms: 0,
        success: false,
        breaker_key: Map.get(envelope, :breaker_key),
        state: "open",
        threshold: 1,
        trip_count: 1
      })

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    Telemetry.emit_breaker_state(attrs)
    maybe_emit_budget(attrs, context, "breaker_open", %{})
  end

  defp emit_access_denied_telemetry(tool_module, context, %{status: :access_denied}) do
    attrs =
      base_attrs(tool_module, context, "access_denied")
      |> Map.put(:duration_ms, 0)
      |> Map.put(:success, false)

    Telemetry.emit_latency(attrs)
    Telemetry.emit_tool_reliability(attrs)
    maybe_emit_budget(attrs, context, "access_denied", %{})
  end

  defp emit_access_denied_telemetry(_tool_module, _context, _envelope), do: :ok

  defp base_attrs(tool_module, context, outcome) do
    context = canonical_context(context)
    identity = context_identity(context)

    %{
      actor_id: identity.actor_id,
      tenant_id: identity.tenant_id || "system",
      session_id: identity.session_id,
      subject_kind: "mcp_tool",
      policy_key: Map.get(context, :policy_key, inspect(tool_module)),
      reason_code: outcome,
      trace_id: Map.get(context, :trace_id),
      run_id: Map.get(context, :run_id),
      tool_name: tool_name(tool_module),
      integration_kind: Map.get(context, :integration_kind, "tool"),
      provider: Map.get(context, :provider),
      model: Map.get(context, :model)
    }
  end

  defp canonical_context(context) do
    context = Map.new(context)
    identity = Scoria.Identity.normalize(context)
    runtime = runtime_context(context)

    context
    |> maybe_alias_run_id()
    |> maybe_put_runtime_field(:provider, Map.get(runtime, :provider))
    |> maybe_put_runtime_field(:model, Map.get(runtime, :model))
    |> maybe_put_runtime_field(:policy_key, Map.get(runtime, :policy_key))
    |> maybe_put_runtime_field(:prompt_ref, Map.get(runtime, :prompt_ref))
    |> maybe_put_runtime_field(:prompt_version, Map.get(runtime, :prompt_version))
    |> maybe_put_runtime_field(:prompt_policy, Map.get(runtime, :prompt_policy))
    |> Map.put(:actor_id, identity.actor_id)
    |> Map.put(:tenant_id, identity.tenant_id)
    |> Map.put(:session_id, identity.session_id)
    |> Map.put(:identity, Scoria.Identity.to_map(identity))
  end

  # D-22: `:workflow_run_id` is an alias for `:run_id` -- Scoria's own
  # reference handler (`test/scoria/workflows/runtime_span_test.exs`)
  # forwards `workflow_run_id:`, not `run_id:`, into the executor context,
  # so the confluence gate's attribution check (which reads `:run_id`)
  # must recognize both. `:run_id` (if already present) always wins --
  # this is additive, never destructive.
  defp maybe_alias_run_id(%{run_id: _} = context), do: context

  defp maybe_alias_run_id(%{workflow_run_id: workflow_run_id} = context)
       when not is_nil(workflow_run_id),
       do: Map.put(context, :run_id, workflow_run_id)

  defp maybe_alias_run_id(context), do: context

  defp context_identity(context) do
    context
    |> Map.get(:identity, %{})
    |> Scoria.Identity.normalize()
  end

  defp tool_name(tool_module) do
    if function_exported?(tool_module, :name, 0),
      do: tool_module.name(),
      else: inspect(tool_module)
  end

  defp maybe_emit_budget(attrs, context, outcome, result) do
    if budget_required?(context) do
      actual = actual_units(context, result, outcome)
      estimated = estimated_units(context)
      burn_rate = numeric_ratio(actual, estimated)

      Telemetry.emit_cost(Map.put(attrs, :cost_usd, actual))

      Telemetry.emit_budget_burn(
        attrs
        |> Map.put(:burn_rate, burn_rate)
        |> Map.put(:budget_remaining, budget_remaining(actual, estimated))
        |> Map.put(:threshold, estimated)
      )
    end
  end

  defp numeric_ratio(actual, estimated)
       when is_number(actual) and is_number(estimated) and estimated != 0,
       do: actual / estimated

  defp numeric_ratio(_actual, _estimated), do: 0

  defp budget_remaining(actual, estimated) when is_number(actual) and is_number(estimated),
    do: max(estimated - actual, 0)

  defp budget_remaining(_actual, estimated), do: estimated || 0

  defp maybe_put_runtime_field(context, _key, nil), do: context

  defp maybe_put_runtime_field(context, key, value) do
    Map.put_new(context, key, value)
  end

  defp runtime_context(context) do
    runtime =
      Map.get(context, :runtime) ||
        Map.get(context, "runtime") ||
        Map.get(context, :runtime_defaults) ||
        Map.get(context, "runtime_defaults") ||
        %{}

    runtime = Map.new(runtime)

    %{
      provider: Map.get(runtime, :provider) || Map.get(runtime, "provider"),
      model: Map.get(runtime, :model) || Map.get(runtime, "model"),
      policy_key: Map.get(runtime, :policy_key) || Map.get(runtime, "policy_key"),
      prompt_ref: Map.get(runtime, :prompt_ref) || Map.get(runtime, "prompt_ref"),
      prompt_version: Map.get(runtime, :prompt_version) || Map.get(runtime, "prompt_version"),
      prompt_policy: Map.get(runtime, :prompt_policy) || Map.get(runtime, "prompt_policy")
    }
  end
end
