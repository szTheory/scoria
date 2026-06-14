defmodule ScoriaWeb.MemoryNotebookComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:memories, :list, required: true)
  attr(:runtime_instance_id, :string, required: true)

  def render(assigns) do
    ~H"""
    <.notebook
      id="memory-notebook"
      title="Compacted Memory Timeline"
      eyebrow="memory notebook"
      selected_tab="memory"
    >
      <:tab key="memory" label="Memory">
        <.evidence_section
          title="Memory summaries"
          description="Chronological log of raw session history compacted into durable memory summaries."
        >
          <:actions>
            <a href={runtime_href(@runtime_instance_id)} class="scoria-button scoria-button--ghost scoria-button--sm">
              runtime <%= @runtime_instance_id %>
            </a>
          </:actions>

          <div class="space-y-4">
            <.evidence_section
              :for={memory <- @memories}
              title={"Sequences #{memory.start_sequence} - #{memory.end_sequence}"}
              description={"Archived #{memory.end_sequence - memory.start_sequence + 1} raw events"}
              badge="compacted"
              tone={:pass}
            >
              <.evidence_rows
                rows={[
                  {"Summary", memory.summary_text},
                  {"archived raw tokens", memory.token_count}
                ]}
              />

              <.evidence_action_row>
                <a
                  class="scoria-button scoria-button--ghost scoria-button--sm"
                  href={runtime_href(@runtime_instance_id, memory.start_sequence)}
                >
                  Runtime Context
                </a>
              </.evidence_action_row>
            </.evidence_section>
          </div>
        </.evidence_section>
      </:tab>
    </.notebook>
    """
  end

  defp runtime_href(runtime_instance_id),
    do: "/scoria?runtime=#{URI.encode(to_string(runtime_instance_id))}"

  defp runtime_href(runtime_instance_id, sequence),
    do: "#{runtime_href(runtime_instance_id)}&sequence=#{sequence}"
end
