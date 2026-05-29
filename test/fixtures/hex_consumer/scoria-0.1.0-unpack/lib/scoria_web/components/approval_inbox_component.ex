defmodule ScoriaWeb.ApprovalInboxComponent do
  use Phoenix.Component

  attr :approvals, :list, required: true

  def render(assigns) do
    ~H"""
    <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <p class="text-xs uppercase tracking-[0.24em] text-stone-500">approvals</p>
      <h2 class="text-lg font-semibold text-stone-900">Approval inbox</h2>
      <div :if={@approvals == []} class="mt-4 rounded-xl border border-dashed border-stone-200 bg-stone-50 p-4 text-sm text-stone-600">
        No pending approvals.
      </div>
      <div :if={@approvals != []} class="mt-4 space-y-3">
        <article :for={approval <- @approvals} class="rounded-xl border border-stone-200 bg-stone-50 p-3">
          <p class="text-sm font-semibold text-stone-900"><%= approval_field(approval, :tool_name) %></p>
          <p class="mt-1 text-xs text-stone-600">
            status <%= approval_field(approval, :status) %>
            <span :if={approval_field(approval, :connector_label)}>· <%= approval_field(approval, :connector_label) %></span>
          </p>
        </article>
      </div>
    </section>
    """
  end

  defp approval_field(approval, field) do
    Map.get(approval, field) || Map.get(approval, Atom.to_string(field))
  end
end
