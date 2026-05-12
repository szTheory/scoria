defmodule ScoriaWeb.WorkflowTreeComponent do
  use Phoenix.Component

  attr :steps, :list, required: true
  attr :selected_step_id, :string, default: nil

  def workflow_tree(assigns) do
    ~H"""
    <div id="workflow-tree" class="workflow-tree">
      <button
        :for={step <- @steps}
        type="button"
        phx-click="select_step"
        phx-value-id={step.id}
        class={[
          "workflow-tree-row flex w-full items-center gap-3 border-b px-3 py-2 text-left",
          @selected_step_id == step.id && "bg-stone-100"
        ]}
        style={"--indent-level: #{Map.get(step, :depth, 0)}; padding-left: calc(0.75rem + var(--indent-level) * 1.25rem)"}
      >
        <span class={["workflow-status-badge rounded-full px-2 py-1 text-xs font-semibold", badge_class(step.status)]}>
          <%= step.status %>
        </span>
        <span class="font-mono text-sm"><%= step.role_id %></span>
        <span class="text-sm"><%= step.kind %></span>
        <span :if={step.kind == "handoff"} class="workflow-handoff-marker text-xs text-stone-500">
          handoff
        </span>
      </button>
    </div>
    """
  end

  defp badge_class("completed"), do: "bg-emerald-100 text-emerald-700"
  defp badge_class("running"), do: "bg-sky-100 text-sky-700"
  defp badge_class("waiting_for_approval"), do: "bg-amber-100 text-amber-800"
  defp badge_class("retrying"), do: "bg-orange-100 text-orange-800"
  defp badge_class("failed"), do: "bg-rose-100 text-rose-800"
  defp badge_class(_), do: "bg-stone-200 text-stone-700"
end
