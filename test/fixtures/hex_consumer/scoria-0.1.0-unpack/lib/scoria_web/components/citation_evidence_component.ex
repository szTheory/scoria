defmodule ScoriaWeb.CitationEvidenceComponent do
  use Phoenix.Component

  attr :evidence, :map, required: true

  def render(assigns) do
    ~H"""
    <section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
      <div class="mb-3 flex items-center justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">retrieval evidence</p>
          <h3 class="text-lg font-semibold text-stone-900">side-by-side citation review</h3>
        </div>
        <div class="text-xs text-stone-600">
          freshness: <span class="font-medium"><%= @evidence.freshness %></span>
        </div>
      </div>

      <div class="grid gap-4 lg:grid-cols-2">
        <div class="rounded-lg bg-white p-4">
          <h4 class="mb-2 text-sm font-semibold text-stone-800">Answer + citation anchors</h4>
          <p class="mb-3 text-sm text-stone-700"><%= @evidence.query_text %></p>

          <ul class="space-y-2 text-sm text-stone-700">
            <%= for citation <- @evidence.citations do %>
              <li class="rounded-md border border-stone-200 p-2">
                <span class="font-mono text-xs text-stone-500"><%= citation.label %></span>
                <span class="ml-2 font-medium"><%= citation.title %></span>
                <p class="mt-1 text-xs text-stone-500">locator: <%= citation.locator %></p>
              </li>
            <% end %>
          </ul>
        </div>

        <div class="rounded-lg bg-white p-4">
          <h4 class="mb-2 text-sm font-semibold text-stone-800">Evidence and unsupported claims</h4>

          <ul class="space-y-2 text-sm text-stone-700">
            <%= for chunk <- @evidence.ranked_chunks do %>
              <li class="rounded-md border border-stone-200 p-2">
                <div class="flex items-center justify-between">
                  <span class="font-medium">rank <%= chunk.rank %></span>
                  <span class="text-xs text-stone-500">score <%= chunk.score %></span>
                </div>
                <p class="mt-2 text-sm"><%= chunk.body %></p>
              </li>
            <% end %>
          </ul>

          <div class="mt-3 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
            unsupported: <%= Enum.join(@evidence.unsupported_claims, ", ") %>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
