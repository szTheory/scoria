defmodule ScoriaWeb.WorkflowLive.Show do
  use Phoenix.LiveView

  alias Scoria.Runtime
  alias Scoria.SRE
  alias Scoria.Workflows
  alias ScoriaWeb.{MemoryNotebookComponent, RemoteInvocationEvidenceComponent, WorkflowDetailPanelComponent}
  alias ScoriaWeb.WorkflowTreeComponent

  @comparison_sources ~w(original replay)

  @impl true
  def mount(%{"id" => run_id}, _session, socket) do
    if connected?(socket) do
      Workflows.subscribe_run(run_id)
    end

    socket = 
      socket
      |> load_run(run_id)
      |> assign_async(:compacted_memories, fn ->
        {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_step", %{"id" => step_id}, socket) do
    {:noreply, assign_selection(socket, step_id)}
  end

  @impl true
  def handle_event("select_comparison_source", %{"source" => source}, socket)
      when source in @comparison_sources do
    {:noreply, socket |> assign(:selected_source_variant, source) |> assign_selection(socket.assigns.selected_step_id)}
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
  def handle_info({:promote_successful}, socket) do
    {:noreply, assign(socket, :promote_step_id, nil)}
  end

  @impl true
  def handle_info({:promote_successful, payload}, socket) when is_map(payload) do
    {:noreply,
     socket
     |> assign(:promote_step_id, nil)
     |> assign(:promotion_notice, payload)}
  end

  @impl true
  def handle_info({:baseline_promotion_requested, payload}, socket) when is_map(payload) do
    {:noreply,
     socket
     |> assign(:promote_step_id, nil)
     |> assign(:baseline_notice, payload)}
  end

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
            <a :if={@run.session_id} href={"/scoria?runtime=#{@run.session_id}"} class="mt-2 inline-flex items-center gap-2 text-sm font-medium text-blue-700 underline">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4"><path fill-rule="evenodd" d="M17 10a.75.75 0 0 1-.75.75H5.612l4.158 3.96a.75.75 0 1 1-1.04 1.08l-5.5-5.25a.75.75 0 0 1 0-1.08l5.5-5.25a.75.75 0 1 1 1.04 1.08L5.612 9.25H16.25A.75.75 0 0 1 17 10Z" clip-rule="evenodd" /></svg>
              View associated runtime presence
            </a>
          </div>
          <div class="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-semibold">
            <span class="workflow-run-status"><%= @run.status %></span>
          </div>
        </header>

        <section
          :if={@run.execution_mode == "replay" and map_size(@replay_provenance_strip) > 0}
          class="mb-6 rounded-2xl border border-blue-200 bg-blue-50 p-4 shadow-sm"
        >
          <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.24em] text-blue-700">Replay branch</p>
              <h2 class="mt-1 text-lg font-semibold text-stone-900">Replay provenance strip</h2>
              <p class="mt-1 text-sm text-stone-600">
                Typed replay lineage stays visible on the workflow page instead of hiding in raw payloads.
              </p>
            </div>

            <div class="flex flex-wrap gap-2 text-xs text-stone-700">
              <span class="rounded-full border border-blue-200 bg-white px-3 py-1">
                source run <span class="font-mono"><%= provenance_value(@replay_provenance_strip.source_run_id) %></span>
              </span>
              <span class="rounded-full border border-blue-200 bg-white px-3 py-1">
                source checkpoint <span class="font-mono"><%= provenance_value(@replay_provenance_strip.source_checkpoint_id) %></span>
              </span>
              <span class="rounded-full border border-blue-200 bg-white px-3 py-1">
                execution mode <span class="font-mono"><%= provenance_value(@replay_provenance_strip.execution_mode) %></span>
              </span>
            </div>
          </div>

          <dl class="mt-4 grid gap-3 text-sm text-stone-700 lg:grid-cols-3">
            <div class="rounded-xl border border-blue-100 bg-white p-3">
              <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Override summary</dt>
              <dd class="mt-2 font-medium text-stone-900"><%= override_summary(@replay_provenance_strip) %></dd>
            </div>
            <div class="rounded-xl border border-blue-100 bg-white p-3">
              <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Latest replay disposition summary</dt>
              <dd class="mt-2 font-medium text-stone-900"><%= disposition_summary(@replay_provenance_strip) %></dd>
            </div>
            <div class="rounded-xl border border-blue-100 bg-white p-3">
              <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Run identity</dt>
              <dd class="mt-2 text-xs text-stone-600">
                replay run <span class="font-mono text-stone-900"><%= @run.id %></span>
              </dd>
            </div>
          </dl>
        </section>

        <section :if={@promotion_notice || @baseline_notice} class="mb-6 space-y-3">
          <article
            :if={@promotion_notice}
            class="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-900 shadow-sm"
          >
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-emerald-700">Promotion succeeded</p>
            <p class="mt-2">
              <span class="font-semibold"><%= variant_label(@promotion_notice[:source_variant] || @promotion_notice["source_variant"]) %></span>
              promoted into
              <span class="font-semibold"><%= @promotion_notice[:dataset_name] || @promotion_notice["dataset_name"] %></span>
              <span class="font-mono">v<%= @promotion_notice[:dataset_version] || @promotion_notice["dataset_version"] %></span>.
            </p>
          </article>

          <article
            :if={@baseline_notice}
            class="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 shadow-sm"
          >
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-amber-700">Baseline approval requested</p>
            <p class="mt-2">
              Approval requested for
              <span class="font-semibold"><%= @baseline_notice[:dataset_name] || @baseline_notice["dataset_name"] %></span>
              <span class="font-mono">v<%= @baseline_notice[:dataset_version] || @baseline_notice["dataset_version"] %></span>.
            </p>
          </article>
        </section>

        <div class="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]">
          <section class="rounded-2xl border border-stone-200 bg-white shadow-sm">
            <div class="border-b border-stone-200 px-4 py-3">
              <h2 class="text-lg font-semibold">Trace-First Workflow Tree</h2>
            </div>
            <WorkflowTreeComponent.workflow_tree steps={@steps} selected_step_id={@selected_step_id} />
          </section>

          <WorkflowDetailPanelComponent.workflow_detail_panel
            step={@selected_step}
            checkpoint={@selected_checkpoint}
            comparison={@selected_comparison}
            selected_source_variant={@selected_source_variant}
            selected_comparison_entry={@selected_comparison_entry}
            promotion_context={@promotion_context}
          />
        </div>

        <.async_result :let={memories} assign={@compacted_memories}>
          <:loading>
            <div class="mt-6 flex items-center justify-center rounded-2xl border border-stone-200 bg-white p-8 shadow-sm">
              <p class="text-sm text-stone-500">Loading compacted memories...</p>
            </div>
          </:loading>
          <:failed :let={_failure}>
            <div class="mt-6 flex items-center justify-center rounded-2xl border border-red-200 bg-red-50 p-8 shadow-sm">
              <p class="text-sm text-red-600">Failed to load memories.</p>
            </div>
          </:failed>
          <MemoryNotebookComponent.render :if={memories != []} memories={memories} runtime_instance_id={@run.session_id || "unknown"} />
        </.async_result>

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
              promotion_context={@promotion_context}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_run(socket, run_id) do
    run = Workflows.get_run_tree!(run_id)
    detail = Runtime.get_run_detail!(run_id)
    steps = decorate_steps(detail.steps)
    selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)
    selected_source_variant = default_source_variant(run, socket.assigns[:selected_source_variant])

    socket
    |> assign(:page_title, "Workflow Run")
    |> assign(:run, run)
    |> assign(:run_detail, detail)
    |> assign(:steps, steps)
    |> assign(:events, run.events)
    |> assign(:comparison_by_step, detail.comparison_by_step)
    |> assign(:replay_provenance_strip, detail.replay_provenance_strip)
    |> assign(:selected_source_variant, selected_source_variant)
    |> assign(:remote_invocation_evidence, SRE.remote_invocation_evidence(run_id))
    |> assign_new(:promote_step_id, fn -> nil end)
    |> assign_new(:promotion_notice, fn -> nil end)
    |> assign_new(:baseline_notice, fn -> nil end)
    |> assign_selection(selected_step_id)
  end

  defp assign_selection(socket, nil) do
    socket
    |> assign(:selected_step_id, nil)
    |> assign(:selected_step, nil)
    |> assign(:selected_checkpoint, nil)
    |> assign(:selected_comparison, nil)
    |> assign(:selected_comparison_entry, nil)
    |> assign(:promotion_context, nil)
  end

  defp assign_selection(socket, step_id) do
    step = Enum.find(socket.assigns.steps, &(&1.id == step_id))

    checkpoint =
      socket.assigns.run_detail.checkpoints
      |> Enum.reverse()
      |> Enum.find(&(&1.step_id == step_id))

    selected_comparison = Map.get(socket.assigns.comparison_by_step, step_id)

    selected_comparison_entry =
      selected_comparison_entry(selected_comparison, socket.assigns.selected_source_variant)

    socket
    |> assign(:selected_step_id, step_id)
    |> assign(:selected_step, step)
    |> assign(:selected_checkpoint, checkpoint)
    |> assign(:selected_comparison, selected_comparison)
    |> assign(:selected_comparison_entry, selected_comparison_entry)
    |> assign(:promotion_context, promotion_context(selected_comparison_entry))
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

  defp default_source_variant(%{execution_mode: "replay"}, current) when current in @comparison_sources,
    do: current

  defp default_source_variant(%{execution_mode: "replay"}, _current), do: "replay"

  defp default_source_variant(_run, "original"), do: "original"
  defp default_source_variant(_run, _current), do: "original"

  defp selected_comparison_entry(nil, _source_variant), do: nil
  defp selected_comparison_entry(comparison, source_variant), do: Map.get(comparison, String.to_existing_atom(source_variant))

  defp promotion_context(nil), do: nil

  defp promotion_context(selected_entry) do
    provenance = Map.get(selected_entry, :provenance, %{})
    checkpoint_output = Map.get(selected_entry, :checkpoint_output, %{})
    safety = Map.get(selected_entry, :safety, %{})
    promotion_snapshot = Map.get(selected_entry, :promotion_snapshot, %{})

    %{
      workflow_run_id: workflow_run_id,
      workflow_step_id: workflow_step_id,
      source_variant: source_variant,
      source_checkpoint_id: _source_checkpoint_id,
      replay_disposition: _replay_disposition,
      replay_reason_code: _replay_reason_code
    } = provenance

    %{
      workflow_run_id: workflow_run_id,
      workflow_step_id: workflow_step_id,
      source_variant: source_variant,
      provenance: provenance,
      checkpoint_output: checkpoint_output,
      safety: safety,
      promotion_snapshot: promotion_snapshot,
      notes: %{},
      expected_output: %{}
    }
  end

  defp provenance_value(nil), do: "not available"
  defp provenance_value(value), do: value

  defp override_summary(%{live_tool_allowlist: allowlist}) when is_list(allowlist) and allowlist != [] do
    "live tool allowlist: " <> Enum.join(allowlist, ", ")
  end

  defp override_summary(%{replay_posture: posture}) when is_binary(posture), do: posture
  defp override_summary(_strip), do: "No overrides recorded"

  defp disposition_summary(%{replay_disposition: disposition, replay_reason_code: reason})
       when is_binary(disposition) and is_binary(reason) do
    "#{disposition} (#{reason})"
  end

  defp disposition_summary(%{replay_disposition: disposition}) when is_binary(disposition), do: disposition
  defp disposition_summary(_strip), do: "No replay disposition recorded"

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"
end
