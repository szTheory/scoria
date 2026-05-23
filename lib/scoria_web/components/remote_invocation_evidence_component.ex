defmodule ScoriaWeb.RemoteInvocationEvidenceComponent do
  use Phoenix.Component

  attr :evidence, :map, required: true

  def render(assigns) do
    assigns =
      assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

    ~H"""
    <section class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Remote evidence notebook</p>
          <h2 class="mt-1 text-lg font-semibold text-stone-900">Remote invocation evidence</h2>
        </div>
        <span class="rounded-full border border-stone-200 bg-stone-50 px-3 py-1 text-xs font-medium text-stone-600">
          <%= length(@approvals) %> approval<%= if length(@approvals) == 1, do: "", else: "s" %>
        </span>
      </div>

      <div class="mt-4 space-y-3">
        <article
          :for={approval <- @approvals}
          class="rounded-xl border border-stone-200 bg-stone-50 px-4 py-3 text-sm text-stone-700"
        >
          <div class="flex flex-wrap items-center gap-2">
            <span class="font-semibold text-stone-900"><%= approval_value(approval, :tool_name) %></span>
            <span class="font-mono text-xs text-stone-500"><%= approval_value(approval, :status) %></span>
          </div>
          <p class="mt-2 text-xs text-stone-500">
            Approval ID: <span class="font-mono"><%= approval_value(approval, :id) %></span>
          </p>
        </article>
      </div>
    </section>
    """
  end

  defp approval_value(approval, key) do
    Map.get(approval, key) || Map.get(approval, to_string(key)) || "unknown"
  end
end
