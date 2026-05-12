defmodule ScoriaWeb.WorkflowDetailPanelComponent do
  use Phoenix.Component

  attr :step, :map, default: nil
  attr :checkpoint, :map, default: nil

  def workflow_detail_panel(assigns) do
    ~H"""
    <aside id="workflow-detail-panel" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <%= if @step do %>
        <h2 class="text-lg font-semibold">Step Detail</h2>
        <dl class="mt-4 space-y-2 text-sm">
          <div>
            <dt class="font-medium text-stone-600">Role</dt>
            <dd><%= @step.role_id %></dd>
          </div>
          <div>
            <dt class="font-medium text-stone-600">Kind</dt>
            <dd><%= @step.kind %></dd>
          </div>
          <div>
            <dt class="font-medium text-stone-600">Projected Context</dt>
            <dd class="workflow-projected-context whitespace-pre-wrap font-mono text-xs"><%= inspect(@step.projected_context) %></dd>
          </div>
          <div :if={@checkpoint}>
            <dt class="font-medium text-stone-600">Checkpoint</dt>
            <dd class="workflow-checkpoint-metadata whitespace-pre-wrap font-mono text-xs"><%= inspect(@checkpoint.snapshot) %></dd>
          </div>
          <div :if={map_size(@step.error_envelope || %{}) > 0}>
            <dt class="font-medium text-stone-600">Failure Reason</dt>
            <dd class="workflow-failure-reason whitespace-pre-wrap font-mono text-xs"><%= inspect(@step.error_envelope) %></dd>
          </div>
        </dl>
      <% else %>
        <p class="text-sm text-stone-500">Select a step to inspect checkpoint metadata and failure reasons.</p>
      <% end %>
    </aside>
    """
  end
end
