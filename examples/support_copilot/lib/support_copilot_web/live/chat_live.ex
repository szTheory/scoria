defmodule SupportCopilotWeb.ChatLive do
  use SupportCopilotWeb, :live_view

  alias Scoria.SupportJourney
  alias SupportCopilot.Tickets

  import SupportCopilotWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    ticket = Tickets.current_ticket()
    persona = Tickets.persona()

    {:ok,
     socket
     |> assign(:ticket, ticket)
     |> assign(:persona, persona)
     |> assign(:run_id, nil)
     |> assign(:run_status, nil)
     |> assign(:run_detail, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section style="border: 1px solid #e2e8f0; border-radius: 0.5rem; padding: 1rem; margin-bottom: 1rem;">
      <h2 style="margin-top: 0;">Active ticket</h2>
      <p><strong><%= @ticket["id"] %></strong> — <%= @ticket["subject"] %></p>
      <p>Customer: <%= @ticket["customer"] %> · Plan: <%= @ticket["plan"] %></p>
      <p>Persona: <%= @persona["persona"] %> @ <%= @persona["company"] %></p>
    </section>

    <section style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
      <.button phx-click="lookup_ticket">Lookup ticket</.button>
      <.button phx-click="start_refund_review">Start refund review run</.button>
      <.button phx-click="escalate_billing">Escalate to billing specialist</.button>
      <.button phx-click="run_semantic_faq">Run semantic FAQ lane</.button>
      <.button phx-click="run_knowledge_lane">Run knowledge lane</.button>
      <.button phx-click="run_connector_lane">Run connector lane</.button>
      <a href="/scoria" style="align-self: center;">Open Scoria operator dashboard</a>
    </section>

    <section :if={@run_id} style="margin-top: 1.5rem; padding: 1rem; background: #f8fafc; border-radius: 0.5rem;">
      <h3 style="margin-top: 0;">Latest Scoria run</h3>
      <p>Run: <code><%= @run_id %></code></p>
      <p>Status: <strong><%= @run_status %></strong></p>
      <p :if={@run_detail}><%= @run_detail %></p>
      <p>
        <a href={SupportJourney.operator_route(@run_id)}>Inspect operator evidence</a>
      </p>
    </section>
    """
  end

  @impl true
  def handle_event("lookup_ticket", _params, socket) do
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        initial_step: %{sequence: 1, kind: "tool", role_id: "support_agent", status: "queued"},
        handlers: %{"tool" => {SupportCopilot.RuntimeHandlers, :lookup_support_ticket}}
      )

    {:noreply,
     socket
     |> assign(:run_id, started.run_id)
     |> assign(:run_status, "completed")
     |> assign(:run_detail, "Ticket lookup via #{SupportJourney.ticket_lookup_tool()}")}
  end

  @impl true
  def handle_event("start_refund_review", _params, socket) do
    identity = SupportJourney.runtime_identity()

    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {SupportCopilot.RuntimeHandlers, :wait_for_approval}
    })

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        initial_step: %{sequence: 1, kind: "approval", role_id: "support_agent", status: "queued"},
        handlers: %{"approval" => {SupportCopilot.RuntimeHandlers, :wait_for_approval}}
      )

    {:noreply,
     socket
     |> assign(:run_id, started.run_id)
     |> assign(:run_status, SupportJourney.waiting_status())
     |> assign(:run_detail, nil)}
  end

  @impl true
  def handle_event("escalate_billing", _params, socket) do
    identity = SupportJourney.runtime_identity()

    {:ok, started} = Scoria.start_run(identity, root_role_id: "support_agent")

    {:ok, handoff_run} =
      Scoria.start_handoff_run(identity, SupportJourney.handoff_role_id(),
        root_role_id: "support_agent",
        delegated_kind: SupportJourney.delegated_kind(),
        handoff_input: SupportJourney.handoff_input(),
        projected_context: SupportJourney.projected_context()
      )

    _started = started

    {:noreply,
     socket
     |> assign(:run_id, handoff_run.run_id)
     |> assign(:run_status, "delegated")
     |> assign(:run_detail, "Handoff to #{SupportJourney.handoff_role_id()}")}
  end

  @impl true
  def handle_event("run_semantic_faq", _params, socket) do
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        input: "What is the refund policy?",
        semantic_cache: [lane: SupportCopilot.SemanticLane],
        initial_step: %{sequence: 1, kind: "answer", role_id: "support_agent", status: "queued"},
        handlers: %{"answer" => {SupportCopilot.RuntimeHandlers, :faq_answer}}
      )

    {:noreply,
     socket
     |> assign(:run_id, started.run_id)
     |> assign(:run_status, "semantic")
     |> assign(:run_detail, "Semantic FAQ lane")}
  end

  @impl true
  def handle_event("run_knowledge_lane", _params, socket) do
    SupportCopilot.Knowledge.ensure_refund_policy_source!()
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        input: "Summarize refund policy",
        initial_step: %{sequence: 1, kind: "answer", role_id: "support_agent", status: "queued"},
        handlers: %{"answer" => {SupportCopilot.RuntimeHandlers, :knowledge_answer}}
      )

    {:noreply,
     socket
     |> assign(:run_id, started.run_id)
     |> assign(:run_status, "knowledge")
     |> assign(:run_detail, SupportJourney.knowledge_source_title())}
  end

  @impl true
  def handle_event("run_connector_lane", _params, socket) do
    connector = SupportCopilot.Connectors.ensure_billing_connector!()
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        initial_step: %{sequence: 1, kind: "tool", role_id: "support_agent", status: "queued"},
        handlers: %{"tool" => {SupportCopilot.RuntimeHandlers, :connector_lookup}}
      )

    {:noreply,
     socket
     |> assign(:run_id, started.run_id)
     |> assign(:run_status, "connector")
     |> assign(:run_detail, connector.label)}
  end
end
