defmodule ScoriaWeb.WorkflowLive.Show do
  use Phoenix.LiveView

  alias Scoria.SRE
  alias Scoria.Workflows
  alias ScoriaWeb.{RemoteInvocationEvidenceComponent, WorkflowDetailPanelComponent}
  alias ScoriaWeb.WorkflowTreeComponent

  @impl true
  def mount(%{"id" => run_id}, _session, socket) do
    if connected?(socket) do
      Workflows.subscribe_run(run_id)
    end

    {:ok, load_run(socket, run_id)}
  end

  @impl true
  def handle_event("select_step", %{"id" => step_id}, socket) do
    {:noreply, assign_selection(socket, step_id)}
  end

  @impl true
  def handle_event("open_promote_modal", %{"step-id" => step_id}, socket) do
    {:noreply, assign(socket, :promote_step_id, step_id)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :promote_step_id, nil)}
  end

  @impl true
  def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}

  def handle_info({:approval_requested, run_id, _approval_id}, socket),
    do: {:noreply, load_run(socket, run_id)}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-stone-50 px-6 py-8 text-stone-900">
      <div class="mx-auto max-w-7xl">
        <header class="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.3em] text-stone-500">Scoria Workflow</p>
            <h1 class="text-3xl font-semibold">Workflow Run</h1>
            <p class="text-sm text-stone-600">Run <span class="font-mono"><%= @run.id %></span></p>
          </div>
          <div class="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-semibold">
            <span class="workflow-run-status"><%= @run.status %></span>
          </div>
        </header>

        <div class="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]">
          <section class="rounded-2xl border border-stone-200 bg-white shadow-sm">
            <div class="border-b border-stone-200 px-4 py-3">
              <h2 class="text-lg font-semibold">Trace-First Workflow Tree</h2>
            </div>
            <WorkflowTreeComponent.workflow_tree steps={@steps} selected_step_id={@selected_step_id} />
          </section>

          <WorkflowDetailPanelComponent.workflow_detail_panel step={@selected_step} checkpoint={@selected_checkpoint} />
        </div>

        <section class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
          <h2 class="text-lg font-semibold">Timeline</h2>
          <ol id="workflow-timeline" class="mt-3 space-y-2">
            <li :for={event <- @events} class="rounded-xl bg-stone-50 px-3 py-2 text-sm">
              <span class="font-medium"><%= event.event_type %></span>
              <span class="ml-2 font-mono text-xs text-stone-500"><%= event.sequence %></span>
            </li>
          </ol>
        </section>

        <RemoteInvocationEvidenceComponent.render
          :if={@remote_invocation_evidence.approvals != []}
          evidence={@remote_invocation_evidence}
        />

        <div :if={@promote_step_id != nil} id="promote-modal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" phx-window-keydown="close_modal" phx-key="escape">
          <div class="w-full max-w-3xl rounded-xl bg-white p-6 shadow-xl relative">
            <button type="button" phx-click="close_modal" class="absolute top-4 right-4 text-stone-500 hover:text-stone-700">
              <span class="sr-only">Close</span>
              &times;
            </button>
            <.live_component
              module={ScoriaWeb.DatasetLive.PromoteComponent}
              id="promote-component"
              step={Enum.find(@steps, &(&1.id == @promote_step_id))}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_run(socket, run_id) do
    run = Workflows.get_run_tree!(run_id)
    steps = decorate_steps(run.steps)
    selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)

    socket
    |> assign(:page_title, "Workflow Run")
    |> assign(:run, run)
    |> assign(:steps, steps)
    |> assign(:events, run.events)
    |> assign(:remote_invocation_evidence, SRE.remote_invocation_evidence(run_id))
    |> assign_new(:promote_step_id, fn -> nil end)
    |> assign_selection(selected_step_id)
  end

  defp assign_selection(socket, nil) do
    socket
    |> assign(:selected_step_id, nil)
    |> assign(:selected_step, nil)
    |> assign(:selected_checkpoint, nil)
  end

  defp assign_selection(socket, step_id) do
    step = Enum.find(socket.assigns.steps, &(&1.id == step_id))

    checkpoint =
      socket.assigns.run.checkpoints
      |> Enum.reverse()
      |> Enum.find(&(&1.step_id == step_id))

    socket
    |> assign(:selected_step_id, step_id)
    |> assign(:selected_step, step)
    |> assign(:selected_checkpoint, checkpoint)
  end

  defp decorate_steps(steps) do
    parent_map = Map.new(steps, &{&1.id, &1})

    Enum.map(steps, fn step ->
      Map.put(step, :depth, depth_for(step, parent_map, 0))
    end)
  end

  defp depth_for(%{parent_step_id: nil}, _parent_map, depth), do: depth

  defp depth_for(step, parent_map, depth) do
    case Map.get(parent_map, step.parent_step_id) do
      nil -> depth
      parent -> depth_for(parent, parent_map, depth + 1)
    end
  end

  defp default_step_id([]), do: nil
  defp default_step_id([step | _]), do: step.id
end
