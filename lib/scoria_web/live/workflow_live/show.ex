defmodule ScoriaWeb.WorkflowLive.Show do
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import Ecto.Query, warn: false

  import ScoriaWeb.UI,
    only: [
      badge: 1,
      evidence_action_row: 1,
      evidence_rows: 1,
      modal: 1,
      object_header: 1,
      panel: 1,
      skeleton: 1
    ]

  alias Scoria.PromptRegistry.PromptTemplate
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.Workflows
  alias ScoriaWeb.ReviewerSurface

  alias ScoriaWeb.{
    DelegatedEvidenceComponent,
    MemoryNotebookComponent,
    RemoteInvocationEvidenceComponent,
    WorkflowDetailPanelComponent
  }

  alias ScoriaWeb.WorkflowTreeComponent

  @comparison_sources ~w(original replay)
  @origin_nouns ~w(incident review run dataset eval prompt)

  @impl true
  def mount(%{"id" => run_id} = params, _session, socket) do
    review_candidate_id = Map.get(params, "review_candidate_id")
    tenant_id = socket.assigns.tenant_id

    socket = load_run(socket, tenant_id, run_id)

    socket =
      socket
      |> assign(
        :review_candidate,
        load_review_candidate(tenant_id, socket.assigns.run, review_candidate_id)
      )
      |> maybe_subscribe_to_run()
      |> maybe_load_compacted_memories()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(
       socket,
       :origin_context,
       origin_context(params["from"], socket.assigns[:scoria_base] || "")
     )}
  end

  @impl true
  def handle_event("select_step", %{"id" => step_id}, socket) do
    {:noreply, assign_selection(socket, step_id)}
  end

  @impl true
  def handle_event("select_comparison_source", %{"source" => source}, socket)
      when source in @comparison_sources do
    {:noreply,
     socket
     |> assign(:selected_source_variant, source)
     |> assign_selection(socket.assigns.selected_step_id)}
  end

  @impl true
  def handle_event("open_promote_modal", %{"step-id" => step_id}, socket) do
    {:noreply, assign(socket, :promote_step_id, step_id)}
  end

  @impl true
  def handle_event("open_promote_next_step", %{"step-id" => step_id}, socket) do
    {:noreply, assign(socket, :promote_step_id, step_id)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :promote_step_id, nil)}
  end

  @impl true
  def handle_info({:workflow_updated, run_id}, socket),
    do: {:noreply, load_run(socket, socket.assigns.tenant_id, run_id)}

  def handle_info({:approval_requested, run_id, _approval_id}, socket),
    do: {:noreply, load_run(socket, socket.assigns.tenant_id, run_id)}

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
    <div class="scoria-dashboard">
      <.panel :if={!@run} class="mb-6">
        <:title>Workflow run not found</:title>
        <p>This workflow run either does not exist or is not available for the current tenant.</p>
      </.panel>

      <div :if={@run}>
        <.object_header
          parent_label="Runs"
          parent_path={(assigns[:scoria_base] || "") <> "/workflows"}
          object_type="Run"
          object_id={@run.id}
          status={@run.status}
          key_scalar={run_key_scalar(@run)}
          provenance={replay_provenance(@run, @replay_provenance_strip)}
          origin={@origin_context}
        />

        <.evidence_action_row class="mb-6" aria-label="Run next steps">
          <a href={replay_run_path(@run, assigns[:scoria_base] || "")} class="scoria-button scoria-button--ghost scoria-button--sm">
            Replay run
          </a>
          <a
            :if={!promote_span_disabled?(@selected_step_id, %{})}
            href={workflow_dataset_builder_path(@run, @selected_step_id, @selected_source_variant, assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--primary scoria-button--sm"
          >
            Promote in Dataset Builder
          </a>
          <a
            :if={@linked_incident}
            href={linked_incident_path(@run, @linked_incident, assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Open incident
          </a>
          <a
            :if={@prompt_target_id}
            href={prompt_release_path(@prompt_target_id, @run, assigns[:scoria_base] || "")}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Open prompt
          </a>
          <a :if={@run.session_id} href={runtime_presence_path(@run, assigns[:scoria_base] || "")} class="scoria-button scoria-button--ghost scoria-button--sm">
            View associated runtime presence
          </a>
        </.evidence_action_row>

        <.panel :if={@run.execution_mode == "replay" and map_size(@replay_provenance_strip) > 0} class="mb-6">
          <:eyebrow>Replay branch</:eyebrow>
          <:title>Replay provenance strip</:title>
          <:actions>
            <.badge tone={:trace} label="Replay branch" dot={false} />
          </:actions>
          <p>
            Typed replay lineage stays visible on the workflow page instead of hiding in raw payloads.
          </p>
          <.evidence_rows rows={[
            {"source run", provenance_value(@replay_provenance_strip.source_run_id)},
            {"source checkpoint", provenance_value(@replay_provenance_strip.source_checkpoint_id)},
            {"execution mode", provenance_value(@replay_provenance_strip.execution_mode)},
            {"Override summary", override_summary(@replay_provenance_strip)},
            {"Latest replay disposition summary", disposition_summary(@replay_provenance_strip)},
            {"Run identity", "replay run #{@run.id}"}
          ]} />
        </.panel>

        <div :if={@promotion_notice || @baseline_notice} class="mb-6 space-y-3">
        <.panel :if={@promotion_notice}>
          <:eyebrow>Promotion succeeded</:eyebrow>
          <:actions>
            <.badge tone={:pass} label="Dataset draft" dot={false} />
          </:actions>
          <p>
            <span class="font-semibold"><%= variant_label(@promotion_notice[:source_variant] || @promotion_notice["source_variant"]) %></span>
            promoted into
            <span class="font-semibold"><%= @promotion_notice[:dataset_name] || @promotion_notice["dataset_name"] %></span>
            <span class="font-mono">v<%= @promotion_notice[:dataset_version] || @promotion_notice["dataset_version"] %></span>.
          </p>
        </.panel>

        <.panel :if={@baseline_notice}>
          <:eyebrow>Baseline approval requested</:eyebrow>
          <:actions>
            <.badge tone={:warn} label="Approval requested" dot={false} />
          </:actions>
          <p>
            Approval requested for
            <span class="font-semibold"><%= @baseline_notice[:dataset_name] || @baseline_notice["dataset_name"] %></span>
            <span class="font-mono">v<%= @baseline_notice[:dataset_version] || @baseline_notice["dataset_version"] %></span>.
          </p>
        </.panel>
        </div>

        <.panel :if={@review_candidate} class="mb-6">
          <:eyebrow>Review candidate evidence</:eyebrow>
          <:title>{@review_candidate.rationale}</:title>
          <.evidence_rows rows={[
            {"Severity", @review_candidate.severity},
            {"trace", @review_candidate.trace_id},
            {"candidate", @review_candidate.id}
          ]} />
        </.panel>

        <div class="scoria-page-split">
          <.panel flush={true}>
            <:title>Trace-First Workflow Tree</:title>
            <WorkflowTreeComponent.workflow_tree steps={@steps} selected_step_id={@selected_step_id} />
          </.panel>

          <WorkflowDetailPanelComponent.workflow_detail_panel
            step={@selected_step}
            checkpoint={@selected_checkpoint}
            comparison={@selected_comparison}
            semantic_evidence={@run_detail.semantic_evidence}
            selected_source_variant={@selected_source_variant}
            selected_comparison_entry={@selected_comparison_entry}
            promotion_context={@promotion_context}
          />
        </div>

        <DelegatedEvidenceComponent.render delegated_handoffs={@delegated_handoffs} />

        <.async_result :let={memories} assign={@compacted_memories}>
          <:loading><.skeleton rows={3} class="mt-6" /></:loading>
          <:failed :let={_failure}>
            <.panel class="mt-6">
              <:title>Memory evidence unavailable</:title>
              <:actions>
                <.badge tone={:fail} label="Load failed" dot={false} />
              </:actions>
              <p>Failed to load memories.</p>
            </.panel>
          </:failed>
          <MemoryNotebookComponent.render :if={memories != []} memories={memories} runtime_instance_id={@run.session_id || "unknown"} />
        </.async_result>

        <.panel class="mt-6">
          <:title>Timeline</:title>
          <ol id="workflow-timeline" class="space-y-2">
            <li :for={event <- @events} class="scoria-span">
              <span class="font-medium"><%= event.event_type %></span>
              <span class="ml-2 font-mono text-xs"><%= event.sequence %></span>
            </li>
          </ol>
        </.panel>

        <RemoteInvocationEvidenceComponent.render
          :if={@remote_invocation_evidence.approvals != []}
          evidence={@remote_invocation_evidence}
        />

        <.modal id="promote-modal" show={@promote_step_id != nil} on_dismiss="close_modal" max_width="768px">
          <:title_slot>Promote workflow evidence</:title_slot>
          <.live_component
            module={ScoriaWeb.DatasetLive.PromoteComponent}
            id="promote-component"
            step={Enum.find(@steps, &(&1.id == @promote_step_id))}
            promotion_context={@promotion_context}
            scoria_base={assigns[:scoria_base] || ""}
          />
        </.modal>
      </div>
    </div>
    """
  end

  defp load_run(socket, tenant_id, run_id) do
    case ReviewerSurface.fetch_tenant_run_detail(tenant_id, run_id) do
      nil -> assign_run_not_found(socket)
      detail -> assign_run_detail(socket, detail)
    end
  end

  defp assign_run_not_found(socket) do
    socket
    |> assign(:page_title, "Workflow run not found")
    |> assign(:run, nil)
    |> assign(:linked_incident, nil)
    |> assign(:prompt_target_id, nil)
    |> assign(:run_detail, nil)
    |> assign(:steps, [])
    |> assign(:events, [])
    |> assign(:comparison_by_step, %{})
    |> assign(:replay_provenance_strip, %{})
    |> assign(:delegated_handoffs, [])
    |> assign(:selected_source_variant, "original")
    |> assign(:remote_invocation_evidence, %{approvals: []})
    |> assign_new(:promote_step_id, fn -> nil end)
    |> assign_new(:promotion_notice, fn -> nil end)
    |> assign_new(:baseline_notice, fn -> nil end)
    |> assign_selection(nil)
  end

  defp assign_run_detail(socket, %{run: run, detail: detail} = run_detail) do
    steps = decorate_steps(detail.steps)
    selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)

    selected_source_variant =
      default_source_variant(run, socket.assigns[:selected_source_variant])

    socket
    |> assign(:page_title, "Workflow Run")
    |> assign(:run, run)
    |> assign(:linked_incident, Map.get(run_detail, :linked_incident))
    |> assign(:prompt_target_id, prompt_target_id(run))
    |> assign(:run_detail, detail)
    |> assign(:steps, steps)
    |> assign(:events, run.events)
    |> assign(:comparison_by_step, detail.comparison_by_step)
    |> assign(:replay_provenance_strip, detail.replay_provenance_strip)
    |> assign(:delegated_handoffs, detail.delegated_handoffs)
    |> assign(:selected_source_variant, selected_source_variant)
    |> assign(
      :remote_invocation_evidence,
      Map.get(run_detail, :remote_invocation_evidence, %{approvals: []})
    )
    |> assign_new(:promote_step_id, fn -> nil end)
    |> assign_new(:promotion_notice, fn -> nil end)
    |> assign_new(:baseline_notice, fn -> nil end)
    |> assign_selection(selected_step_id)
  end

  defp maybe_subscribe_to_run(%{assigns: %{run: %{id: run_id}}} = socket) do
    if connected?(socket), do: Workflows.subscribe_run(run_id)

    socket
  end

  defp maybe_subscribe_to_run(socket), do: socket

  defp maybe_load_compacted_memories(%{assigns: %{run: %{id: run_id}}} = socket) do
    assign_async(socket, :compacted_memories, fn ->
      {:ok, %{compacted_memories: Runtime.list_compacted_memories_for_run(run_id)}}
    end)
  end

  defp maybe_load_compacted_memories(socket), do: socket

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

  defp default_source_variant(%{execution_mode: "replay"}, current)
       when current in @comparison_sources,
       do: current

  defp default_source_variant(%{execution_mode: "replay"}, _current), do: "replay"

  defp default_source_variant(_run, "original"), do: "original"
  defp default_source_variant(_run, _current), do: "original"

  defp selected_comparison_entry(nil, _source_variant), do: nil

  defp selected_comparison_entry(comparison, source_variant),
    do: Map.get(comparison, String.to_existing_atom(source_variant))

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
      notes: "",
      expected_output: %{}
    }
  end

  defp provenance_value(nil), do: "not available"
  defp provenance_value(value), do: value

  defp override_summary(%{live_tool_allowlist: allowlist})
       when is_list(allowlist) and allowlist != [] do
    "live tool allowlist: " <> Enum.join(allowlist, ", ")
  end

  defp override_summary(%{replay_posture: posture}) when is_binary(posture), do: posture
  defp override_summary(_strip), do: "No overrides recorded"

  defp disposition_summary(%{replay_disposition: disposition, replay_reason_code: reason})
       when is_binary(disposition) and is_binary(reason) do
    "#{disposition} (#{reason})"
  end

  defp disposition_summary(%{replay_disposition: disposition}) when is_binary(disposition),
    do: disposition

  defp disposition_summary(_strip), do: "No replay disposition recorded"

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"

  defp run_key_scalar(%{session_id: session_id}) when is_binary(session_id),
    do: "session #{session_id}"

  defp run_key_scalar(%{root_role_id: role_id}) when is_binary(role_id), do: role_id
  defp run_key_scalar(_run), do: nil

  defp replay_provenance(%{execution_mode: "replay"} = run, strip) when is_map(strip) do
    source_run_id = Map.get(strip, :source_run_id) || run.source_run_id
    source_checkpoint_id = Map.get(strip, :source_checkpoint_id) || run.source_checkpoint_id

    if source_run_id do
      "Replayed from run #{source_run_id} via checkpoint #{provenance_value(source_checkpoint_id)} - #{run_date(run)}"
    end
  end

  defp replay_provenance(_run, _strip), do: nil

  defp run_date(%{inserted_at: %DateTime{} = inserted_at}) do
    inserted_at
    |> DateTime.to_date()
    |> Date.to_iso8601()
  end

  defp run_date(_run), do: "date unavailable"

  defp origin_context(nil, _base_path), do: nil

  defp origin_context(from, base_path) when is_binary(from) do
    case String.split(from, ":", parts: 2) do
      [noun, id] when noun in @origin_nouns and id != "" ->
        %{noun: noun, id: id, path: origin_path(noun, id, base_path)}

      _ ->
        nil
    end
  end

  defp origin_context(_from, _base_path), do: nil

  defp origin_path("incident", _id, base_path), do: base_path <> "/incidents"
  defp origin_path("review", _id, base_path), do: base_path <> "/reviews"
  defp origin_path("run", id, base_path), do: base_path <> "/workflows/#{id}"
  defp origin_path("dataset", _id, base_path), do: base_path <> "/eval_specs"
  defp origin_path("eval", _id, base_path), do: base_path <> "/eval_specs"
  defp origin_path("prompt", _id, base_path), do: base_path <> "/prompts"

  defp promote_span_disabled?(nil, _promotion_context), do: true
  defp promote_span_disabled?(_step_id, _promotion_context), do: false

  defp replay_run_path(run, base_path) do
    "#{base_path}/coming/replay-playground?#{origin_query("run", run.id)}"
  end

  defp linked_incident_path(run, %{id: incident_id}, base_path) do
    "#{base_path}/incidents/#{incident_id}?#{origin_query("run", run.id)}"
  end

  defp prompt_release_path(prompt_id, run, base_path) do
    "#{base_path}/prompts/#{prompt_id}/release?#{origin_query("run", run.id)}"
  end

  defp runtime_presence_path(%{session_id: session_id}, base_path) when is_binary(session_id) do
    "#{base_path}?#{URI.encode_query([{"runtime", session_id}])}"
  end

  defp workflow_dataset_builder_path(run, step_id, source_variant, base_path) do
    query =
      URI.encode_query([
        {"promote", "workflow"},
        {"run_id", run.id},
        {"step_id", step_id},
        {"source_variant", source_variant},
        {"from", "run:#{run.id}"}
      ])

    "#{base_path}/datasets?#{query}"
  end

  defp origin_query(noun, id), do: URI.encode_query([{"from", "#{noun}:#{id}"}])

  defp prompt_target_id(run) do
    [run.metadata, run.replay_overrides]
    |> Kernel.++(
      Enum.flat_map(run.steps, &[&1.projected_context, &1.result_envelope, &1.handoff_input])
    )
    |> Kernel.++(Enum.flat_map(run.checkpoints, &[&1.metadata, &1.snapshot]))
    |> Kernel.++(Enum.map(run.events, & &1.payload))
    |> Enum.find_value(&prompt_candidate_id/1)
    |> existing_prompt_id()
  end

  defp prompt_candidate_id(value) when is_map(value) do
    direct =
      value["prompt_template_id"] ||
        value[:prompt_template_id] ||
        value["template_id"] ||
        value[:template_id] ||
        value["prompt_ref"] ||
        value[:prompt_ref]

    direct || Enum.find_value(Map.values(value), &prompt_candidate_id/1)
  end

  defp prompt_candidate_id(values) when is_list(values),
    do: Enum.find_value(values, &prompt_candidate_id/1)

  defp prompt_candidate_id(value) when is_binary(value), do: nil
  defp prompt_candidate_id(_value), do: nil

  defp existing_prompt_id(nil), do: nil

  defp existing_prompt_id(candidate) do
    with {:ok, prompt_id} <- Ecto.UUID.cast(candidate),
         true <- Repo.exists?(from(prompt in PromptTemplate, where: prompt.id == ^prompt_id)) do
      prompt_id
    else
      _ -> nil
    end
  end

  defp load_review_candidate(_tenant_id, _run, nil), do: nil

  defp load_review_candidate(_tenant_id, nil, _candidate_id), do: nil

  defp load_review_candidate(tenant_id, run, candidate_id) do
    ReviewerSurface.fetch_tenant_review_candidate(tenant_id, run, candidate_id)
  end
end
