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
     |> assign(:run_status, nil)}
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
      <.button phx-click="start_refund_review">Start refund review run</.button>
      <.button phx-click="escalate_billing">Escalate to billing specialist</.button>
      <a href="/scoria" style="align-self: center;">Open Scoria operator dashboard</a>
    </section>

    <section :if={@run_id} style="margin-top: 1.5rem; padding: 1rem; background: #f8fafc; border-radius: 0.5rem;">
      <h3 style="margin-top: 0;">Latest Scoria run</h3>
      <p>Run: <code><%= @run_id %></code></p>
      <p>Status: <strong><%= @run_status %></strong></p>
      <p>
        <a href={SupportJourney.operator_route(@run_id)}>Inspect operator evidence</a>
      </p>
    </section>
    """
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
     |> assign(:run_status, SupportJourney.waiting_status())}
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
     |> assign(:run_status, "delegated")}
  end
end
