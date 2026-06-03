defmodule ScoriaWeb.WorkflowLive.Index do
  @moduledoc """
  Runs index — recent durable workflow runs (Trace Explorer entry point).
  Operator job: find a run to inspect.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import Ecto.Query, warn: false
  import ScoriaWeb.UI

  alias Scoria.Repo
  alias Scoria.Workflows.Run

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Runs") |> assign(:runs, list_runs())}
  end

  defp list_runs do
    Repo.all(from(r in Run, order_by: [desc: r.inserted_at], limit: 50))
  rescue
    _ -> []
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-pagehead">
      <div class="scoria-pagehead__title">
        <h1>Runs</h1>
      </div>
      <p class="text-stone-600 mt-1">Durable workflow runs. Open one to inspect its trace, steps, and evidence.</p>
    </div>

    <.panel variant={:flat} class="scoria-panel--flush">
      <div :if={@runs == []} class="p-6">
        <.empty_state title="No runs yet">
          Start a run through <span class="font-mono">Scoria.start_run/2</span> and it will appear here with full trace evidence.
        </.empty_state>
      </div>

      <div :if={@runs != []} class="overflow-x-auto">
        <table class="scoria-table">
          <thead>
            <tr>
              <th>Run</th>
              <th>Status</th>
              <th>Mode</th>
              <th>Session</th>
              <th>Started</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={run <- @runs}>
              <td><.id value={short_id(run.id)} copy={run.id} /></td>
              <td><.badge tone={tone(run.status)} label={status_label(run.status)} /></td>
              <td class="text-stone-600">{run.execution_mode}</td>
              <td class="font-mono text-stone-600">{run.session_id}</td>
              <td class="text-stone-600">{format_ts(run.started_at || run.inserted_at)}</td>
              <td class="text-right">
                <.link navigate={(assigns[:scoria_base] || "") <> "/workflows/#{run.id}"} class="scoria-button scoria-button--ghost scoria-button--sm">
                  Open trace
                </.link>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </.panel>
    """
  end

  defp short_id(nil), do: "—"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp format_ts(nil), do: "—"
  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_ts(other), do: to_string(other)
end
