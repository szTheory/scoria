defmodule ScoriaWeb.MemoryNotebookComponent do
  use Phoenix.Component

  attr(:memories, :list, required: true)
  attr(:runtime_instance_id, :string, required: true)

  def render(assigns) do
    ~H"""
    <section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
      <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">memory notebook</p>
          <h3 class="text-lg font-semibold text-stone-900">Compacted Memory Timeline</h3>
          <p class="mt-1 text-sm text-stone-600">
            Chronological log of raw session history compacted into durable memory summaries.
          </p>
        </div>

        <div class="flex flex-wrap gap-2 text-xs text-stone-700">
          <a href={"/scoria?runtime=#{@runtime_instance_id}"} class="rounded-full border border-stone-300 bg-white px-3 py-1 hover:bg-stone-50 text-blue-700 underline font-mono">
            runtime <%= @runtime_instance_id %>
          </a>
        </div>
      </div>

      <div class="mt-4 space-y-4">
        <article :for={memory <- @memories} class="rounded-lg border border-stone-200 bg-white p-4">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-stone-900">Sequences <%= memory.start_sequence %> - <%= memory.end_sequence %></p>
              <p class="mt-1 text-xs text-stone-500">Archived <%= memory.end_sequence - memory.start_sequence + 1 %> raw events</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <span class="rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-emerald-800">
                compacted
              </span>
            </div>
          </div>

          <div class="mt-3 text-sm text-stone-700">
            <p><%= memory.summary_text %></p>
          </div>

          <div class="mt-3 flex flex-wrap gap-3 text-xs">
            <p class="text-stone-600">archived raw tokens <span class="font-medium text-stone-900"><%= memory.token_count %></span></p>
            <a class="text-blue-700 underline" href={"/scoria?runtime=#{@runtime_instance_id}&sequence=#{memory.start_sequence}"}>Runtime Context</a>
          </div>
        </article>
      </div>
    </section>
    """
  end
end
