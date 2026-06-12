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
        %{
          key: :live_ops,
          label: "Home",
          path: "/",
          icon: :pulse,
          aliases: ["home", "live ops", "status"]
        },
        %{
          key: :approvals,
          label: "Approvals",
          path: "/approvals",
          icon: :inbox,
          aliases: ["approvals", "approval"]
        },
        %{
          key: :runs,
          label: "Runs",
          path: "/workflows",
          icon: :tree,
          aliases: ["runs", "workflows", "traces"]
        },
        %{
          key: :incidents,
          label: "Incidents",
          path: "/incidents",
          icon: :alert,
          aliases: ["incidents", "incident"]
        }
      ]
    },
    %{
      label: "Improve",
      items: [
        %{
          key: :reviews,
          label: "Review Queue",
          path: "/reviews",
          icon: :flag,
          aliases: ["review", "reviews", "queue"]
        },
        %{
          key: :evals,
          label: "Eval Workbench",
          path: "/eval_specs",
          icon: :grid,
          aliases: ["eval", "evals", "evaluation"]
        },
        %{
          key: :prompts,
          label: "Prompt Registry",
          path: "/prompts",
          icon: :doc,
          aliases: ["prompt", "prompts", "registry"]
        },
        %{
          key: :replay_playground,
          label: "Replay Playground",
          icon: :pulse,
          aliases: ["replay", "playground"],
          soon?: true,
          stub_slug: "replay-playground"
        },
        %{
          key: :cost_ledger,
          label: "Cost Ledger",
          icon: :grid,
          aliases: ["cost", "ledger", "spend"],
          soon?: true,
          stub_slug: "cost-ledger"
        },
        %{
          key: :feedback_inbox,
          label: "Feedback Inbox",
          icon: :inbox,
          aliases: ["feedback", "inbox"],
          soon?: true,
          stub_slug: "feedback-inbox"
        }
      ]
    },
    %{
      label: "Configure",
      items: [
        %{
          key: :connectors,
          label: "Connectors",
          path: "/connectors",
          icon: :plug,
          aliases: ["connectors", "connector"]
        },
        %{
          key: :mcp_gateway,
          label: "MCP Gateway",
          icon: :plug,
          aliases: ["mcp", "gateway"],
          soon?: true,
          stub_slug: "mcp-gateway"
        },
        %{
          key: :tool_registry,
          label: "Tool Registry",
          icon: :doc,
          aliases: ["tools", "tool", "registry"],
          soon?: true,
          stub_slug: "tool-registry"
        }
      ]
    }
  ]

  @views %{
    ScoriaWeb.OrchestratorLive => :live_ops,
    ScoriaWeb.ApprovalsLive.Index => :approvals,
    ScoriaWeb.ConnectorsLive.Index => :connectors,
    ScoriaWeb.IncidentsLive.Index => :incidents,
    ScoriaWeb.WorkflowLive.Index => :runs,
    ScoriaWeb.WorkflowLive.Show => :runs,
    ScoriaWeb.ReviewQueueLive => :reviews,
    ScoriaWeb.EvalSpecLive.Index => :evals,
    ScoriaWeb.PromptLive.Index => :prompts,
    ScoriaWeb.PromptLive.ReleaseWorkbenchLive => :prompts
  }

  @g_chords %{
    live_ops: "g h",
    approvals: "g a",
    runs: "g r",
    incidents: "g i",
    connectors: "g c",
    reviews: "g q",
    evals: "g e",
    prompts: "g p"
  }

  @actions [
    %{id: "command-action-toggle-theme", label: "Toggle theme", action: "toggle-theme"},
    %{
      id: "command-action-shortcuts",
      label: "Keyboard shortcuts",
      action: "show-shortcuts",
      kbd: "?"
    },
    %{id: "command-action-copy-url", label: "Copy current page URL", action: "copy-url"}
  ]

  @doc "Nav groups for the sidebar."
  def groups do
    Enum.map(@groups, fn group ->
      %{group | items: Enum.map(group.items, &normalize_item/1)}
    end)
  end

  @doc "Command palette sections derived from the dashboard navigation source of truth."
  def command_sections(base_path) do
    [
      %{label: "Recent", rows: []},
      %{label: "Navigate", rows: navigate_command_rows(base_path)},
      %{label: "Actions", rows: @actions}
    ]
  end

  @doc "Active nav key for a LiveView module."
  def active_key(view), do: active_key(view, %{})

  @doc "Active nav key for a LiveView module and route params."
  def active_key(ScoriaWeb.ComingSoonLive, %{"screen" => screen}), do: stub_key_for_slug(screen)
  def active_key(view, _params), do: Map.get(@views, view, nil)

  @doc "Allowlisted coming-soon screens from the nav source of truth."
  def stub_screens do
    groups()
    |> Enum.flat_map(& &1.items)
    |> Enum.filter(&Map.get(&1, :soon?, false))
  end

  @doc "Lookup coming-soon metadata by slug."
  def stub_screen(slug) when is_binary(slug),
    do: Enum.find(stub_screens(), &(&1.stub_slug == slug))

  def stub_screen(_slug), do: nil

  @doc "Lookup coming-soon nav key by slug."
  def stub_key_for_slug(slug) do
    case stub_screen(slug) do
      %{key: key} -> key
      _ -> nil
    end
  end

  @doc """
  on_mount hook: assigns `:scoria_nav` (active key) and `:scoria_base` (mount prefix) so the
  shell can render active state and absolute links regardless of mount path.
  """
  def on_mount(:default, params, _session, socket) do
    socket =
      socket
      |> assign(:scoria_nav, active_key(socket.view, params))
      |> attach_hook(:scoria_base, :handle_params, &assign_base/3)

    {:cont, socket}
  end

  # Derive the dashboard mount prefix from the current URI by stripping the matched live path.
  defp assign_base(params, uri, socket) do
    base =
      case socket.assigns[:scoria_base] do
        nil -> derive_base(uri, socket.view)
        existing -> existing
      end

    {:cont,
     socket |> assign(:scoria_base, base) |> assign(:scoria_nav, active_key(socket.view, params))}
  end

  defp derive_base(uri, view) do
    path = URI.parse(uri).path || "/"

    suffix =
      case view do
        ScoriaWeb.OrchestratorLive -> "/"
        ScoriaWeb.ApprovalsLive.Index -> "/approvals"
        ScoriaWeb.ConnectorsLive.Index -> "/connectors"
        ScoriaWeb.IncidentsLive.Index -> "/incidents"
        ScoriaWeb.ReviewQueueLive -> "/reviews"
        ScoriaWeb.EvalSpecLive.Index -> "/eval_specs"
        ScoriaWeb.PromptLive.Index -> "/prompts"
        ScoriaWeb.WorkflowLive.Index -> "/workflows"
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
    |> String.replace(
      ~r{/(workflows|prompts|reviews|eval_specs|approvals|connectors|incidents|coming)(/.*)?$},
      ""
    )
  end

  defp normalize_item(%{soon?: true, stub_slug: slug} = item) do
    Map.put(item, :path, "/coming/#{slug}")
  end

  defp normalize_item(item), do: item

  defp navigate_command_rows(base_path) do
    groups()
    |> Enum.flat_map(& &1.items)
    |> Enum.map(fn item ->
      %{
        id: "command-nav-#{item.key}",
        label: item.label,
        path: dashboard_path(base_path, item.path),
        aliases: item.aliases,
        kbd: Map.get(@g_chords, item.key),
        soon?: Map.get(item, :soon?, false)
      }
    end)
  end

  defp dashboard_path(base_path, "/") do
    normalize_base(base_path) <> "/"
  end

  defp dashboard_path(base_path, path) do
    normalize_base(base_path) <> path
  end

  defp normalize_base(nil), do: ""

  defp normalize_base(base_path) do
    base_path
    |> to_string()
    |> String.trim_trailing("/")
  end
end
