defmodule ScoriaWeb.WorkflowTreeComponent do
  use Phoenix.Component

  import ScoriaWeb.UI

  attr(:steps, :list, required: true)
  attr(:selected_step_id, :string, default: nil)

  def workflow_tree(assigns) do
    ~H"""
    <div id="workflow-tree" class="workflow-tree">
      <button
        :for={step <- @steps}
        type="button"
        phx-click="select_step"
        phx-value-id={step.id}
        class={[
          "workflow-tree-row scoria-span flex w-full items-center gap-3 border-b px-3 py-2 text-left",
          "scoria-span--#{span_kind(step.kind)}",
          @selected_step_id == step.id && "scoria-row-selected"
        ]}
        style={"--indent-level: #{Map.get(step, :depth, 0)}; padding-left: calc(0.75rem + var(--indent-level) * 1.25rem)"}
      >
        <span class="scoria-span__rail"></span>
        <.badge tone={tone(step.status)} label={status_label(step.status)} dot={false} class="workflow-status-badge" />
        <span class="font-mono text-sm">{step.role_id}</span>
        <span class="text-sm">{step.kind}</span>
        <span :if={step.kind == "handoff"} class="workflow-handoff-marker scoria-badge scoria-badge--trace scoria-badge--bare">
          handoff
        </span>
      </button>
    </div>
    """
  end

  # Map a step kind to a trace span-kind for the colored rail (brand book §8.8).
  defp span_kind(kind) when kind in ~w(llm tool prompt mcp retriever guardrail eval agent),
    do: kind

  defp span_kind("approval"), do: "guardrail"
  defp span_kind("handoff"), do: "agent"
  defp span_kind("answer"), do: "llm"
  defp span_kind(_), do: "agent"
end
