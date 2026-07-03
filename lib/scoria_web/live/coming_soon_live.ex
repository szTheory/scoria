defmodule ScoriaWeb.ComingSoonLive do
  @moduledoc """
  Shared honest stub page for reserved dashboard capabilities.

  The route param is allowlisted through `DashboardNav.stub_screen/1`; unknown values
  never get titleized or echoed back into the page.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI, only: [empty_state: 1, page_header: 1, stub_page: 1]

  alias ScoriaWeb.DashboardNav

  @impl true
  def mount(%{"screen" => screen}, _session, socket) do
    stub = DashboardNav.stub_screen(screen)

    socket =
      socket
      |> assign(:stub, stub)
      |> assign(:page_title, page_title(stub))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @stub do %>
      <.stub_page
        title={@stub.label}
        description={stub_description(@stub.stub_slug)}
        works_today={works_today(@stub.stub_slug, assigns[:scoria_base] || "")}
        tracking_url={tracking_url(@stub.label)}
      />
    <% else %>
      <.page_header title="Capability not found" />
      <.empty_state title="Capability not found. Choose a screen from the dashboard navigation.">
        <:action>
          <a class="scoria-button scoria-button--ghost scoria-button--sm" href={(assigns[:scoria_base] || "") <> "/"}>
            Home
          </a>
        </:action>
      </.empty_state>
    <% end %>
    """
  end

  defp page_title(nil), do: "Capability not found"
  defp page_title(%{label: label}), do: label

  defp stub_description("cost-ledger") do
    "Cost Ledger will reconcile model spend per run, tenant, and prompt version — traced from span evidence, not estimated."
  end

  defp stub_description("replay-playground") do
    "Replay Playground will let you branch a run from any checkpoint, swap the prompt or model, and compare replayed evidence against the original side by side."
  end

  defp stub_description("feedback-inbox") do
    "Feedback Inbox will collect operator review notes from traces and releases so teams can audit quality feedback before it shapes datasets."
  end

  defp stub_description("mcp-gateway") do
    "MCP Gateway will reconcile remote server access, scopes, and invocation evidence so integrators can govern tool connectivity from Scoria."
  end

  defp stub_description("tool-registry") do
    "Tool Registry will catalog approved local and remote tools so operators can inspect policy, ownership, and runtime evidence in one place."
  end

  defp works_today("cost-ledger", base) do
    [
      %{label: "Open a run in Runs to inspect per-span usage.", path: base <> "/workflows"},
      %{label: "Review eval campaign cost in Eval Workbench.", path: base <> "/eval_specs"}
    ]
  end

  defp works_today("replay-playground", base) do
    [
      %{
        label: "Open a run in Runs and choose Replay from the evidence page.",
        path: base <> "/workflows"
      },
      %{
        label: "Review replay provenance on run evidence before promotion.",
        path: base <> "/workflows"
      }
    ]
  end

  defp works_today("feedback-inbox", base) do
    [
      %{label: "Review flagged traces in Review Queue.", path: base <> "/reviews"},
      %{
        label: "Open incidents that already preserve runtime evidence.",
        path: base <> "/incidents"
      }
    ]
  end

  defp works_today("mcp-gateway", base) do
    [
      %{label: "Inspect connector health and grants in Connectors.", path: base <> "/connectors"},
      %{label: "Review remote approval evidence in Approvals.", path: base <> "/approvals"}
    ]
  end

  defp works_today("tool-registry", base) do
    [
      %{label: "Inspect connector-backed tools in Connectors.", path: base <> "/connectors"},
      %{label: "Review tool-call approvals in Approvals.", path: base <> "/approvals"}
    ]
  end

  defp tracking_url(label) do
    "https://github.com/szTheory/scoria/issues?q=is%3Aissue+" <> URI.encode_www_form(label)
  end
end
