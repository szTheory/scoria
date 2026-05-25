defmodule ScoriaWeb.DelegatedEvidenceComponent do
  use Phoenix.Component

  attr :delegated_handoffs, :list, required: true

  def render(assigns) do
    ~H"""
    <section id="delegated-evidence" class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <div class="flex flex-col gap-3 border-b border-stone-200 pb-4 md:flex-row md:items-start md:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.22em] text-stone-500">Delegated Evidence</p>
          <h2 class="mt-1 text-lg font-semibold text-stone-900">Delegated handoff inspection</h2>
          <p class="mt-1 max-w-3xl text-sm text-stone-600">
            Review bounded delegated lineage from the curated runtime detail instead of reconstructing it from raw workflow rows.
          </p>
        </div>
        <a href="#delegated-evidence" class="inline-flex items-center gap-2 text-sm font-medium text-blue-700 underline">
          Inspect Delegated Evidence
        </a>
      </div>

      <div :if={@delegated_handoffs == []} class="mt-4 rounded-2xl border border-dashed border-stone-300 bg-stone-50 p-5">
        <p class="text-xs font-semibold uppercase tracking-[0.18em] text-stone-500">No Delegated Handoffs Recorded</p>
        <p class="mt-2 text-sm text-stone-600">
          This run has no bounded delegated handoff yet. Start with the normal runtime flow, or inspect the workflow tree after
          <span class="font-mono text-stone-900">Scoria.start_handoff_run/3</span>
          records a handoff and child step under the same run.
        </p>
      </div>

      <div :if={@delegated_handoffs != []} class="mt-4 space-y-4">
        <article :for={delegated <- @delegated_handoffs} class="rounded-2xl border border-stone-200 bg-stone-50 p-4">
          <div class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Same durable run</p>
              <h3 class="mt-1 text-base font-semibold text-stone-900">
                <span class="font-mono"><%= delegated.parent_role_id || "unknown" %></span>
                <span class="mx-2 text-stone-400">→</span>
                <span class="font-mono"><%= delegated.delegated_role_id %></span>
              </h3>
              <p class="mt-1 text-sm text-stone-600">
                delegated kind <span class="font-mono text-stone-900"><%= delegated.delegated_kind %></span>
              </p>
            </div>

            <span class={["inline-flex w-fit rounded-full px-3 py-1 text-xs font-semibold", badge_class(delegated.status)]}>
              <%= delegated_status_label(delegated.status) %>
            </span>
          </div>

          <dl class="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div class="rounded-xl border border-stone-200 bg-white p-3">
              <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Lineage</dt>
              <dd class="mt-2 text-sm text-stone-700">
                parent step <span class="font-mono text-stone-900"><%= delegated.parent_step_id %></span>
                <br />
                child step <span class="font-mono text-stone-900"><%= delegated.child_step_id || "pending" %></span>
              </dd>
            </div>

            <div class="rounded-xl border border-stone-200 bg-white p-3">
              <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Execution</dt>
              <dd class="mt-2 text-sm text-stone-700">
                child status <span class="font-medium text-stone-900"><%= delegated_status_label(delegated.child_status) %></span>
                <%= if delegated.child_status == "child_step_pending" do %>
                  <p class="mt-2 text-xs text-stone-500">The handoff is recorded, but delegated execution has not produced a child-step readback yet.</p>
                <% end %>
              </dd>
            </div>

            <div class="rounded-xl border border-stone-200 bg-white p-3 md:col-span-2">
              <dt class="text-xs uppercase tracking-[0.16em] text-stone-500">Projected Context Preview</dt>
              <dd class="mt-2">
                <div :if={preview_context(delegated) == []} class="text-sm text-stone-500">
                  No projected context recorded yet.
                </div>
                <div :for={{key, value} <- preview_context(delegated)} class="flex items-start justify-between gap-4 border-t border-stone-100 py-2 first:border-t-0 first:pt-0 last:pb-0 text-sm">
                  <span class="font-mono text-xs text-stone-500"><%= key %></span>
                  <span class="max-w-xl text-right text-stone-700"><%= preview_value(value) %></span>
                </div>
              </dd>
            </div>
          </dl>

          <div class="mt-4 space-y-3">
            <details class="rounded-xl border border-stone-200 bg-white p-3">
              <summary class="cursor-pointer text-sm font-medium text-stone-900">View full context</summary>
              <div class="mt-3 grid gap-3 lg:grid-cols-2">
                <div>
                  <p class="text-xs uppercase tracking-[0.16em] text-stone-500">handoff input</p>
                  <div class="mt-2 space-y-2">
                    <div :for={{key, value} <- sorted_pairs(delegated.handoff_input)} class="flex items-start justify-between gap-4 text-sm">
                      <span class="font-mono text-xs text-stone-500"><%= key %></span>
                      <span class="max-w-md text-right text-stone-700"><%= inspect(value, pretty: true) %></span>
                    </div>
                  </div>
                </div>

                <div>
                  <p class="text-xs uppercase tracking-[0.16em] text-stone-500">projected context</p>
                  <div class="mt-2 space-y-2">
                    <div :for={{key, value} <- sorted_pairs(delegated.projected_context)} class="flex items-start justify-between gap-4 text-sm">
                      <span class="font-mono text-xs text-stone-500"><%= key %></span>
                      <span class="max-w-md text-right text-stone-700"><%= inspect(value, pretty: true) %></span>
                    </div>
                  </div>
                </div>
              </div>
            </details>

            <details :if={delegated.capability_tags != []} class="rounded-xl border border-stone-200 bg-white p-3">
              <summary class="cursor-pointer text-sm font-medium text-stone-900">Capability metadata</summary>
              <div class="mt-3 flex flex-wrap gap-2">
                <span :for={tag <- delegated.capability_tags} class="rounded-full border border-stone-200 bg-stone-50 px-3 py-1 text-xs font-medium text-stone-700">
                  <%= tag %>
                </span>
              </div>
            </details>
          </div>
        </article>
      </div>
    </section>
    """
  end

  defp preview_context(delegated) do
    delegated.projected_context
    |> sorted_pairs()
    |> Enum.take(3)
  end

  defp sorted_pairs(map) when is_map(map), do: Enum.sort_by(map, fn {key, _value} -> to_string(key) end)
  defp sorted_pairs(_), do: []

  defp preview_value(value) when is_binary(value) and byte_size(value) > 80 do
    binary_part(value, 0, 77) <> "..."
  end

  defp preview_value(value) when is_binary(value), do: value
  defp preview_value(value), do: inspect(value, pretty: true, limit: 3)

  defp delegated_status_label("child_step_pending"), do: "child step pending"
  defp delegated_status_label(value) when is_binary(value), do: value
  defp delegated_status_label(_value), do: "unknown"

  defp badge_class("completed"), do: "bg-emerald-100 text-emerald-700"
  defp badge_class("running"), do: "bg-sky-100 text-sky-700"
  defp badge_class("waiting_for_approval"), do: "bg-amber-100 text-amber-800"
  defp badge_class("failed"), do: "bg-rose-100 text-rose-800"
  defp badge_class("child_step_pending"), do: "bg-stone-200 text-stone-700"
  defp badge_class(_status), do: "bg-stone-200 text-stone-700"
end
