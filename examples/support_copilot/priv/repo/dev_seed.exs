# Dev seed — populates the Scoria operator dashboard with realistic data so every
# screen expresses meaningful content. Mirrors the gallery chat flows server-side.
#
#   mix run priv/repo/dev_seed.exs
#
# Safe to run repeatedly (creates additional runs each time).

alias Scoria.SupportJourney

identity = SupportJourney.runtime_identity()

IO.puts("Seeding Scoria dashboard data for tenant #{identity.tenant_id}...")

# 1. Completed tool-lookup run
{:ok, _} =
  Scoria.start_run(identity,
    root_role_id: "support_agent",
    initial_step: %{sequence: 1, kind: "tool", role_id: "support_agent", status: "queued"},
    handlers: %{"tool" => {SupportCopilot.RuntimeHandlers, :lookup_support_ticket}}
  )

IO.puts("  ✓ ticket-lookup run")

# 2. Run that pauses for a pending approval (populates the approval inbox + modal)
Application.put_env(:scoria, :workflow_runtime_handlers, %{
  "approval" => {SupportCopilot.RuntimeHandlers, :wait_for_approval}
})

{:ok, _} =
  Scoria.start_run(identity,
    root_role_id: "support_agent",
    initial_step: %{sequence: 1, kind: "approval", role_id: "support_agent", status: "queued"},
    handlers: %{"approval" => {SupportCopilot.RuntimeHandlers, :wait_for_approval}}
  )

IO.puts("  ✓ refund-review run (pending approval)")

# 3. Bounded handoff lineage
{:ok, _} = Scoria.start_run(identity, root_role_id: "support_agent")

{:ok, _handoff} =
  Scoria.start_handoff_run(identity, SupportJourney.handoff_role_id(),
    root_role_id: "support_agent",
    delegated_kind: SupportJourney.delegated_kind(),
    handoff_input: SupportJourney.handoff_input(),
    projected_context: SupportJourney.projected_context()
  )

IO.puts("  ✓ billing handoff run")

# 4. Knowledge-grounded answer (registers a knowledge source)
try do
  SupportCopilot.Knowledge.ensure_refund_policy_source!()

  {:ok, _} =
    Scoria.start_run(identity,
      root_role_id: "support_agent",
      input: "Summarize refund policy",
      initial_step: %{sequence: 1, kind: "answer", role_id: "support_agent", status: "queued"},
      handlers: %{"answer" => {SupportCopilot.RuntimeHandlers, :knowledge_answer}}
    )

  IO.puts("  ✓ knowledge-lane run")
rescue
  e -> IO.puts("  ! knowledge lane skipped: #{Exception.message(e)}")
end

# 5. Connector lane (registers a billing connector for the fleet posture)
try do
  connector = SupportCopilot.Connectors.ensure_billing_connector!()

  {:ok, _} =
    Scoria.start_run(identity,
      root_role_id: "support_agent",
      initial_step: %{sequence: 1, kind: "tool", role_id: "support_agent", status: "queued"},
      handlers: %{"tool" => {SupportCopilot.RuntimeHandlers, :connector_lookup}}
    )

  IO.puts("  ✓ connector-lane run (#{connector.label})")
rescue
  e -> IO.puts("  ! connector lane skipped: #{Exception.message(e)}")
end

IO.puts("Done. Open http://localhost:4010/scoria")
