# Dev seed — populates the Scoria operator dashboard with realistic data so every
# screen expresses meaningful content. Covers all 9 dashboard screens.
#
#   mix run priv/repo/dev_seed.exs
#
# Safe to run repeatedly — guarded entities (incidents, connectors, eval specs,
# review candidates, prompt templates) are idempotent via Repo.get_by + conditional
# insert. Workflow runs are naturally additive; re-running adds runs but never crashes.

import Ecto.Query, only: [from: 2]

alias Scoria.Repo
alias Scoria.SupportJourney
alias Scoria.Workflows
alias Scoria.Connectors.Connector
alias Scoria.SRE.{Incident, IncidentManager}
alias Scoria.Eval
alias Scoria.Eval.OnlineScoreCandidate
alias Scoria.PromptRegistry
alias Scoria.Workflows.PromptRelease

# SupportJourney spine — do not inline these values
tenant_id = SupportJourney.tenant_id()
session_id = SupportJourney.session_id()
connector_key = SupportJourney.connector_key()

identity = SupportJourney.runtime_identity()

IO.puts("Seeding Scoria dashboard data for tenant #{tenant_id}...")

# ---------------------------------------------------------------------------
# (a) Runs / Workflows + Live Ops
# ---------------------------------------------------------------------------
# Runs are naturally additive — re-running creates new runs but never crashes.
# ≥4 runs spanning: completed, in_progress, failed, pending_approval
# Live Ops metrics derive from these (non-zero counts per D-07).
# ---------------------------------------------------------------------------

try do
  # 1. Completed run
  {:ok, completed_run} =
    Scoria.start_run(identity,
      root_role_id: "support_agent",
      initial_step: %{
        sequence: 1,
        kind: "tool",
        role_id: "support_agent",
        status: "queued"
      },
      handlers: %{"tool" => {Scoria.SupportJourney.Handlers, :lookup_support_ticket}}
    )

  IO.puts("  ✓ ticket-lookup run (completed)")

  # 2. In-progress run (started, not completed — intentionally left running)
  {:ok, _in_progress_run} =
    Scoria.start_run(identity,
      root_role_id: "support_agent",
      initial_step: %{
        sequence: 1,
        kind: "tool",
        role_id: "support_agent",
        status: "queued"
      },
      handlers: %{"tool" => {Scoria.SupportJourney.Handlers, :lookup_support_ticket}}
    )

  IO.puts("  ✓ billing-lookup run (in_progress — left running)")

  # 3. Bounded handoff run — adds lineage to Workflows screen
  {:ok, _} = Scoria.start_run(identity, root_role_id: "support_agent")

  {:ok, _handoff} =
    Scoria.start_handoff_run(identity, SupportJourney.handoff_role_id(),
      root_role_id: "support_agent",
      delegated_kind: SupportJourney.delegated_kind(),
      handoff_input: SupportJourney.handoff_input(),
      projected_context: SupportJourney.projected_context()
    )

  IO.puts("  ✓ billing handoff run")

  # 4. Approval run — creates pending approval in approval_inbox (Pitfall 2)
  # Must have a real UUID so Plan 03's Approvals overlay can open the detail modal.
  Application.put_env(:scoria, :workflow_runtime_handlers, %{
    "approval" => {Scoria.SupportJourney.Handlers, :wait_for_approval}
  })

  {:ok, _approval_run} =
    Scoria.start_run(identity,
      root_role_id: "support_agent",
      initial_step: %{
        sequence: 1,
        kind: "approval",
        role_id: "support_agent",
        status: "queued"
      },
      handlers: %{"approval" => {Scoria.SupportJourney.Handlers, :wait_for_approval}}
    )

  IO.puts("  ✓ refund-review run (pending approval)")

  # Keep a reference to completed_run for downstream use (incidents, review candidates)
  {:ok, completed_run}
rescue
  e ->
    IO.puts("  ! runs skipped: #{Exception.message(e)}")
    {:error, nil}
end
|> then(fn result ->
  completed_run =
    case result do
      {:ok, run} -> run
      _ -> nil
    end

  # ---------------------------------------------------------------------------
  # (b) Incidents
  # ---------------------------------------------------------------------------
  # ≥2 incidents — one warning/open, one critical/resolved
  # Link one to the seeded completed run via workflow_run_id (UI-SPEC minimum)
  # ---------------------------------------------------------------------------

  try do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    # Incident 1: warning / open — linked to completed run if available
    # Guard by incident_key (the field IncidentManager sets as dedupe_key internally)
    existing_1 = Repo.get_by(Incident, incident_key: "quality-regression-seed-001")

    incident_1 =
      if is_nil(existing_1) do
        {:ok, i} =
          IncidentManager.open_incident(%{
            tenant_id: tenant_id,
            incident_key: "quality-regression-seed-001",
            severity: "warning",
            summary: "Quality regression on support-agent refund lane",
            routing_class: "review",
            reason_code: "quality_regression",
            workflow_run_id: completed_run && completed_run.run_id
          })

        IO.puts("  ✓ incident (warning/open)")
        i
      else
        IO.puts("  ✓ incident (warning/open) — already seeded")
        existing_1
      end

    # Incident 2: critical / resolved
    # Guard by incident_key (the field IncidentManager uses for dedup)
    existing_2 = Repo.get_by(Incident, incident_key: "breaker-trip-seed-001")

    _incident_2 =
      if is_nil(existing_2) do
        {:ok, i} =
          IncidentManager.open_incident(%{
            tenant_id: tenant_id,
            incident_key: "breaker-trip-seed-001",
            severity: "critical",
            summary: "Breaker trip on billing connector — resolved after failover",
            routing_class: "page",
            reason_code: "breaker_trip"
          })

        # Mark it resolved after creation
        Repo.update!(Incident.changeset(i, %{status: "resolved"}))
        IO.puts("  ✓ incident (critical/resolved)")
        i
      else
        IO.puts("  ✓ incident (critical/resolved) — already seeded")
        existing_2
      end

    incident_1
  rescue
    e ->
      IO.puts("  ! incidents skipped: #{Exception.message(e)}")
      nil
  end

  # ---------------------------------------------------------------------------
  # (c) Connectors
  # ---------------------------------------------------------------------------
  # ≥2 connectors with health_state mix including "degraded" (D-08)
  # Primary connector reuses connector_key "billing" from the spine.
  # The degraded connector gives the state matrix a non-healthy variant (Plan 03).
  # ---------------------------------------------------------------------------

  try do
    # Primary connector: billing (healthy) — reuse spine connector_key
    existing_primary =
      Repo.get_by(Connector, tenant_id: tenant_id, key: connector_key)

    _primary_connector =
      if is_nil(existing_primary) do
        connector =
          Repo.insert!(
            Connector.changeset(%Connector{}, %{
              tenant_id: tenant_id,
              key: connector_key,
              label: SupportJourney.connector_label(),
              endpoint_url: "https://billing.example/mcp",
              transport_kind: "streamable_http",
              auth_mode: "oauth_pkce",
              status: "ready",
              health_state: "healthy",
              last_refresh_status: "ok"
            })
          )

        IO.puts("  ✓ connector: #{connector.label} (healthy)")
        connector
      else
        IO.puts("  ✓ connector: billing (healthy) — already seeded")
        existing_primary
      end

    # Degraded connector — required by D-08 and UI-SPEC for state matrix
    existing_degraded =
      Repo.get_by(Connector, tenant_id: tenant_id, key: "knowledge-base")

    _degraded_connector =
      if is_nil(existing_degraded) do
        connector =
          Repo.insert!(
            Connector.changeset(%Connector{}, %{
              tenant_id: tenant_id,
              key: "knowledge-base",
              label: "Knowledge Base MCP",
              endpoint_url: "https://kb.example/mcp",
              transport_kind: "streamable_http",
              auth_mode: "none",
              status: "degraded",
              health_state: "degraded",
              last_refresh_status: "stale"
            })
          )

        IO.puts("  ✓ connector: #{connector.label} (degraded)")
        connector
      else
        IO.puts("  ✓ connector: knowledge-base (degraded) — already seeded")
        existing_degraded
      end
  rescue
    e ->
      IO.puts("  ! connectors skipped: #{Exception.message(e)}")
  end
end)

# ---------------------------------------------------------------------------
# (d) Eval Workbench — needs a sealed dataset before creating eval specs (Pitfall 3)
# ---------------------------------------------------------------------------
# ≥2 eval specs, ≥1 with a completed eval run and score (UI-SPEC minimum).
# create_eval_spec validates a real sealed dataset_id.
# ---------------------------------------------------------------------------

eval_spec_1 =
  try do
    # Create dataset — idempotent by checking eval spec name before inserting dataset
    existing_spec_1 =
      Repo.get_by(Scoria.Eval.EvalSpec, name: "Refund Response Quality")

    spec_1 =
      if is_nil(existing_spec_1) do
        {:ok, dataset} =
          Eval.create_dataset(%{
            name: "Refund policy eval dataset v1",
            version: "1",
            items: [
              %{
                input: %{"query" => "refund policy"},
                expected_output: %{"answer" => "30-day refund policy"}
              }
            ]
          })

        # Seal dataset before creating eval spec (Pitfall 3)
        {:ok, sealed_dataset} = Eval.seal_dataset(dataset)

        {:ok, spec} =
          Eval.create_eval_spec(%{
            name: "Refund Response Quality",
            description: "Scores refund policy answers against golden examples",
            dataset_id: sealed_dataset.id,
            dataset_version: sealed_dataset.version,
            eval_mode: :live_judge,
            subject: %{"prompt_template_id" => nil},
            scorers: [%{"scorer_kind" => "llm_judge", "weight" => 1.0}],
            threshold_policy: %{
              "pass_rate_gte" => 0.8,
              "mean_score_gte" => 0.7,
              "max_latency_ms" => 5000
            }
          })

        IO.puts("  ✓ eval spec: #{spec.name}")
        spec
      else
        IO.puts("  ✓ eval spec: Refund Response Quality — already seeded")
        existing_spec_1
      end

    spec_1
  rescue
    e ->
      IO.puts("  ! eval spec 1 skipped: #{Exception.message(e)}")
      nil
  end

_eval_spec_2 =
  try do
    existing_spec_2 =
      Repo.get_by(Scoria.Eval.EvalSpec, name: "Connector Tool Quality")

    spec_2 =
      if is_nil(existing_spec_2) do
        {:ok, dataset} =
          Eval.create_dataset(%{
            name: "Connector tool eval dataset v1",
            version: "1",
            items: [
              %{
                input: %{"tool" => "billing_lookup", "args" => %{"id" => "ticket-42"}},
                expected_output: %{"status" => "found", "amount_cents" => 4999}
              }
            ]
          })

        {:ok, sealed_dataset} = Eval.seal_dataset(dataset)

        {:ok, spec} =
          Eval.create_eval_spec(%{
            name: "Connector Tool Quality",
            description: "Scores connector tool invocation quality",
            dataset_id: sealed_dataset.id,
            dataset_version: sealed_dataset.version,
            eval_mode: :offline_replay,
            subject: %{"prompt_template_id" => nil},
            scorers: [%{"scorer_kind" => "deterministic", "weight" => 1.0}],
            threshold_policy: %{
              "pass_rate_gte" => 0.9,
              "mean_score_gte" => 0.85,
              "max_latency_ms" => 3000
            }
          })

        IO.puts("  ✓ eval spec: #{spec.name}")
        spec
      else
        IO.puts("  ✓ eval spec: Connector Tool Quality — already seeded")
        existing_spec_2
      end

    spec_2
  rescue
    e ->
      IO.puts("  ! eval spec 2 skipped: #{Exception.message(e)}")
      nil
  end

# Create ≥1 completed eval run (so Eval Workbench shows a score)
try do
  if eval_spec_1 do
    existing_run =
      Repo.get_by(Scoria.Eval.EvalRun,
        eval_spec_id: eval_spec_1.id,
        status: "completed"
      )

    if is_nil(existing_run) do
      {:ok, eval_run} =
        Eval.create_eval_run(%{
          eval_spec_id: eval_spec_1.id,
          tenant_id: SupportJourney.tenant_id(),
          runner_mode: :live_judge,
          judge_model: "claude-sonnet",
          judge_provider: "anthropic"
        })

      {:ok, _completed_run} =
        Eval.complete_eval_run(eval_run, %{
          status: "completed",
          total_items: 10,
          passed_items: 8,
          failed_items: 2,
          avg_latency_ms: 420,
          threshold_verdict: "pass"
        })

      IO.puts("  ✓ completed eval run for: #{eval_spec_1.name}")
    else
      IO.puts("  ✓ completed eval run — already seeded")
    end
  end
rescue
  e ->
    IO.puts("  ! eval run skipped: #{Exception.message(e)}")
end

# ---------------------------------------------------------------------------
# (e) Review Queue
# ---------------------------------------------------------------------------
# ≥3 OnlineScoreCandidate rows with mixed statuses.
# Requires real trace_id, workflow_run_id, workflow_step_id (FK constraints).
# At least one carries trace evidence linked to a workflow run.
# ---------------------------------------------------------------------------

try do
  tenant_id = SupportJourney.tenant_id()
  session_id = SupportJourney.session_id()
  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

  # Create a trace row for evidence linkage
  trace =
    case Repo.get_by(Scoria.Repo.Trace, session_id: "seed-review-session-001") do
      nil ->
        Repo.insert!(%Scoria.Repo.Trace{
          session_id: "seed-review-session-001",
          attributes: %{"tenant_id" => tenant_id, "actor_id" => "support-agent-1"}
        })

      existing ->
        existing
    end

  # Create a workflow run + step for FK reference
  review_run =
    case Repo.get_by(Scoria.Workflows.Run,
           tenant_id: tenant_id,
           metadata: %{"seed_key" => "review-queue-run-001"}
         ) do
      nil ->
        {:ok, run} =
          Workflows.create_run(%{
            tenant_id: tenant_id,
            actor_id: "support-agent-1",
            session_id: session_id,
            root_role_id: "support_agent",
            metadata: %{"seed_key" => "review-queue-run-001"}
          })

        run

      existing ->
        existing
    end

  review_step =
    case Repo.one(
           from(s in Scoria.Workflows.Step,
             where: s.run_id == ^review_run.id,
             limit: 1
           )
         ) do
      nil ->
        {:ok, step} =
          Workflows.create_step(review_run.id, %{
            sequence: 1,
            kind: "tool",
            role_id: "support_agent",
            status: "queued"
          })

        step

      existing ->
        existing
    end

  # Candidate 1: needs_review / pending — with trace evidence (UI-SPEC ≥1 with trace)
  existing_1 = Repo.get_by(OnlineScoreCandidate, dedupe_key: "seed-candidate-001")

  if is_nil(existing_1) do
    %OnlineScoreCandidate{}
    |> OnlineScoreCandidate.changeset(%{
      tenant_id: tenant_id,
      trace_id: trace.id,
      workflow_run_id: review_run.id,
      workflow_step_id: review_step.id,
      dedupe_key: "seed-candidate-001",
      status: "needs_review",
      review_status: "pending",
      score: 0.42,
      score_status: "low_quality",
      score_explanation: "Response deviated from refund policy guidelines",
      scorer_kind: "llm_judge",
      scorer_version: "v1",
      judge_model: "claude-sonnet",
      rubric_version: "eval-spec-v1",
      sampled_at: now
    })
    |> Repo.insert!()

    IO.puts("  ✓ review candidate 1 (needs_review/pending) — with trace evidence")
  else
    IO.puts("  ✓ review candidate 1 — already seeded")
  end

  # Candidate 2: promotion_candidate / pending
  # review_status is "pending" so list_review_queue(%{}) (which applies the default
  # review_status: "pending" filter) returns all 3 candidates — UI-SPEC ≥3 minimum.
  existing_2 = Repo.get_by(OnlineScoreCandidate, dedupe_key: "seed-candidate-002")

  if is_nil(existing_2) do
    %OnlineScoreCandidate{}
    |> OnlineScoreCandidate.changeset(%{
      tenant_id: tenant_id,
      trace_id: trace.id,
      workflow_run_id: review_run.id,
      workflow_step_id: review_step.id,
      dedupe_key: "seed-candidate-002",
      status: "promotion_candidate",
      review_status: "pending",
      score: 0.91,
      score_status: "high_quality",
      score_explanation: "Excellent refund policy explanation — strong promotion candidate",
      scorer_kind: "llm_judge",
      scorer_version: "v1",
      judge_model: "claude-sonnet",
      rubric_version: "eval-spec-v1",
      sampled_at: DateTime.add(now, -1800, :second)
    })
    |> Repo.insert!()

    IO.puts("  ✓ review candidate 2 (promotion_candidate/pending)")
  else
    # Repair: ensure review_status is pending so list_review_queue(%{}) returns this row
    if existing_2.review_status != "pending" do
      Repo.update!(OnlineScoreCandidate.changeset(existing_2, %{review_status: "pending"}))
    end

    IO.puts("  ✓ review candidate 2 — already seeded")
  end

  # Candidate 3: approval_requested / pending
  existing_3 = Repo.get_by(OnlineScoreCandidate, dedupe_key: "seed-candidate-003")

  if is_nil(existing_3) do
    %OnlineScoreCandidate{}
    |> OnlineScoreCandidate.changeset(%{
      tenant_id: tenant_id,
      trace_id: trace.id,
      workflow_run_id: review_run.id,
      workflow_step_id: review_step.id,
      dedupe_key: "seed-candidate-003",
      status: "approval_requested",
      review_status: "pending",
      score: 0.78,
      score_status: "acceptable",
      score_explanation: "Acceptable response — approval requested for baseline promotion",
      scorer_kind: "llm_judge",
      scorer_version: "v1",
      judge_model: "claude-sonnet",
      rubric_version: "eval-spec-v1",
      sampled_at: DateTime.add(now, -3600, :second)
    })
    |> Repo.insert!()

    IO.puts("  ✓ review candidate 3 (approval_requested/pending)")
  else
    # Repair: ensure review_status is pending so list_review_queue(%{}) returns this row
    if existing_3.review_status != "pending" do
      Repo.update!(OnlineScoreCandidate.changeset(existing_3, %{review_status: "pending"}))
    end

    IO.puts("  ✓ review candidate 3 — already seeded")
  end
rescue
  e ->
    IO.puts("  ! review queue skipped: #{Exception.message(e)}")
end

# ---------------------------------------------------------------------------
# (f) Prompt Registry + Release Workbench
# ---------------------------------------------------------------------------
# ≥2 prompt templates: ≥1 active, ≥1 draft with a started release workflow.
# Captures and prints the draft template ID for /prompts/:id/release URL.
# ---------------------------------------------------------------------------

try do
  tenant_id = SupportJourney.tenant_id()

  # Template 1: active (already approved and promoted)
  existing_active =
    Repo.get_by(Scoria.PromptRegistry.PromptTemplate,
      status: "active",
      version: 1
    )

  _active_template =
    if is_nil(existing_active) do
      {:ok, template} =
        PromptRegistry.create_draft_template(%{
          entity_id: Ecto.UUID.generate(),
          system_message:
            "You are a support agent for Acme Corp. Always be helpful and accurate about refund policies.",
          user_template:
            "Customer inquiry: {{inquiry}}\n\nProvide a clear, accurate response based on our 30-day refund policy.",
          few_shot_examples: %{
            "examples" => [
              %{
                "input" => "Can I get a refund after 45 days?",
                "output" =>
                  "Our refund policy covers the first 30 days after purchase. Unfortunately, a 45-day request falls outside this window."
              }
            ]
          }
        })

      # Promote to active
      {:ok, active} = PromptRegistry.transition_status(template, "active")
      IO.puts("  ✓ prompt template: Refund Policy v1 (active)")
      active
    else
      IO.puts("  ✓ prompt template: active — already seeded")
      existing_active
    end

  # Template 2: draft with a pending release workflow
  # Guard by checking for any draft template with the seed entity_id sentinel
  seed_entity_id = "00000000-0000-0000-0000-000000000001"

  existing_draft =
    Repo.get_by(Scoria.PromptRegistry.PromptTemplate,
      entity_id: seed_entity_id,
      version: 1
    )

  draft_template =
    if is_nil(existing_draft) do
      {:ok, draft} =
        PromptRegistry.create_draft_template(%{
          entity_id: seed_entity_id,
          system_message:
            "You are a support agent for Acme Corp. You help customers with billing questions and refund requests. Always verify the order date before quoting policy.",
          user_template:
            "Customer question: {{question}}\n\nContext: {{context}}\n\nRespond with policy accuracy.",
          few_shot_examples: %{
            "examples" => [
              %{
                "input" => "What is your refund policy?",
                "output" => "We offer a 30-day money-back guarantee on all purchases."
              }
            ]
          }
        })

      IO.puts("  ✓ prompt template: Refund Policy v2 draft (draft)")
      draft
    else
      IO.puts("  ✓ prompt template: draft — already seeded")
      existing_draft
    end

  # Start release workflow for the draft (creates pending approval in prompt_release lane)
  # Guard: only start if no pending approval exists for this specific draft template
  existing_release_approval =
    Repo.one(
      from(a in Scoria.Observe.Approval,
        where:
          a.tool_name == "prompt_release" and
            a.status == "pending" and
            fragment("?->>'template_id' = ?", a.arguments, ^draft_template.id),
        limit: 1
      )
    )

  if is_nil(existing_release_approval) do
    {:ok, _release_result} = PromptRelease.start_release_workflow(draft_template.id, "operator-1")
    IO.puts("  ✓ prompt release workflow started for draft: #{draft_template.id}")
  else
    IO.puts("  ✓ prompt release workflow — already seeded")
  end

  # Print the seeded draft template ID — harness uses /prompts/<id>/release URL
  IO.puts("  -> Prompt Release Workbench URL: /scoria/prompts/#{draft_template.id}/release")
rescue
  e ->
    IO.puts("  ! prompt registry skipped: #{Exception.message(e)}")
end

IO.puts("Done. Open http://localhost:4000/scoria")
