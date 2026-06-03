defmodule ScoriaWeb.DashboardNav do
  @moduledoc """
  Information architecture for the Scoria dashboard: the task-oriented navigation model
  (GOV.UK style — grouped by operator job, not by schema) and the `on_mount` hook that
  marks the active nav item per LiveView.

  Nav items point only at routes that exist. Paths are resolved relative to the dashboard
  mount prefix at render time (see `app.html.heex`), so the shell works under any mount path.
  """
  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Component, only: [assign: 3]

  @groups [
    %{
      label: "Operate",
      items: [
        %{key: :live_ops, label: "Live Ops", path: "/", icon: :pulse},
        %{key: :runs, label: "Runs", path: "/workflows", icon: :tree}
      ]
    },
    %{
      label: "Improve",
      items: [
        %{key: :reviews, label: "Review Queue", path: "/reviews", icon: :flag},
        %{key: :evals, label: "Eval Workbench", path: "/eval_specs", icon: :grid},
        %{key: :prompts, label: "Prompt Registry", path: "/prompts", icon: :doc}
      ]
    }
  ]

  @views %{
    ScoriaWeb.OrchestratorLive => :live_ops,
    ScoriaWeb.WorkflowLive.Show => :runs,
    ScoriaWeb.ReviewQueueLive => :reviews,
    ScoriaWeb.EvalSpecLive.Index => :evals,
    ScoriaWeb.PromptLive.Index => :prompts,
    ScoriaWeb.PromptLive.ReleaseWorkbenchLive => :prompts
  }

  @doc "Nav groups for the sidebar."
  def groups, do: @groups

  @doc "Active nav key for a LiveView module."
  def active_key(view), do: Map.get(@views, view, nil)

  @doc """
  on_mount hook: assigns `:scoria_nav` (active key) and `:scoria_base` (mount prefix) so the
  shell can render active state and absolute links regardless of mount path.
  """
  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> assign(:scoria_nav, active_key(socket.view))
      |> attach_hook(:scoria_base, :handle_params, &assign_base/3)

    {:cont, socket}
  end

  # Derive the dashboard mount prefix from the current URI by stripping the matched live path.
  defp assign_base(_params, uri, socket) do
    base =
      case socket.assigns[:scoria_base] do
        nil -> derive_base(uri, socket.view)
        existing -> existing
      end

    {:cont, assign(socket, :scoria_base, base)}
  end

  defp derive_base(uri, view) do
    path = URI.parse(uri).path || "/"

    suffix =
      case view do
        ScoriaWeb.OrchestratorLive -> "/"
        ScoriaWeb.ReviewQueueLive -> "/reviews"
        ScoriaWeb.EvalSpecLive.Index -> "/eval_specs"
        ScoriaWeb.PromptLive.Index -> "/prompts"
        _ -> nil
      end

    cond do
      suffix == "/" -> String.trim_trailing(path, "/")
      suffix && String.ends_with?(path, suffix) -> String.replace_suffix(path, suffix, "")
      true -> strip_known_prefixes(path)
    end
  end

  defp strip_known_prefixes(path) do
    path
    |> String.replace(~r{/(workflows|prompts|reviews|eval_specs)(/.*)?$}, "")
  end
end
