defmodule ScoriaWeb.DashboardScopeSourceGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  AUTH-03 dashboard tenant-authority guard.

  Dashboard LiveViews may use public params as selectors, filters, and object
  IDs, but tenant authority must come from ScoriaWeb.DashboardScope assigns.
  """

  @scan_glob "lib/scoria_web/live/**/*.ex"
  @scan_paths @scan_glob |> Path.wildcard() |> Enum.sort()

  test "scans every dashboard LiveView source file" do
    assert "lib/scoria_web/live/orchestrator_live.ex" in @scan_paths
    assert "lib/scoria_web/live/prompt_live/release_workbench_live.ex" in @scan_paths
  end

  test "dashboard LiveViews do not derive tenant authority from params or hardcoded defaults" do
    offenders = dashboard_tenant_authority_offenders()

    assert offenders == [],
           """
           AUTH-03 dashboard tenant-authority guard found public or default tenant authority in a dashboard LiveView.
           Dashboard tenant authority must come from ScoriaWeb.DashboardScope assigns. Query params may remain
           selectors, filters, or object IDs, but they must not assert tenant scope.

           Offenders:
           #{Enum.map_join(offenders, "\n", &format_offender/1)}
           """
  end

  test "detects the old public tenant param authority expression" do
    source = ~S'''
    def mount(params, _session, socket) do
      tenant_id = params["tenant"]
      assign(socket, :tenant_id, tenant_id)
    end
    '''

    assert [%{reason: :public_tenant_param}] = scan_source(source, "fixture.ex")
  end

  test "detects the old session-plus-hardcoded-default authority expression" do
    source = ~S'''
    def mount(_params, session, socket) do
      tenant_id = session["tenant_id"] || "default"
      assign(socket, :tenant_id, tenant_id)
    end
    '''

    assert [%{reason: :session_default_tenant}] = scan_source(source, "fixture.ex")
  end

  test "detects hardcoded default fallback near dashboard tenant assignment" do
    source = ~S'''
    def mount(params, _session, socket) do
      tenant_id = params["account_id"] || "default"
      assign(socket, :tenant_id, tenant_id)
    end
    '''

    assert [%{reason: :hardcoded_default_tenant}] = scan_source(source, "fixture.ex")
  end

  test "does not block unrelated default UI copy or comments" do
    source = ~S'''
    # tenant_id = params["tenant"] || session["tenant_id"] || "default"
    def render(assigns) do
      assigns = assign(assigns, :label, "default")
      ~H"<p>default view</p>"
    end
    '''

    assert scan_source(source, "fixture.ex") == []
  end

  defp dashboard_tenant_authority_offenders do
    Enum.flat_map(@scan_paths, fn path ->
      path
      |> File.read!()
      |> scan_source(path)
    end)
  end

  defp scan_source(source, path) do
    lines = code_lines(source)

    lines
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      line_offenders(lines, path, line, line_number)
    end)
  end

  defp line_offenders(lines, path, line, line_number) do
    cond do
      public_tenant_param?(line) ->
        [offender(path, line_number, :public_tenant_param, line)]

      session_default_tenant?(line) ->
        [offender(path, line_number, :session_default_tenant, line)]

      hardcoded_default_tenant?(lines, line, line_number) ->
        [offender(path, line_number, :hardcoded_default_tenant, line)]

      true ->
        []
    end
  end

  defp code_lines(source) do
    source
    |> String.split("\n")
    |> Enum.map(&strip_comment_line/1)
  end

  defp strip_comment_line(line) do
    trimmed = String.trim_leading(line)

    if String.starts_with?(trimmed, "#") or String.starts_with?(trimmed, "<%!--") do
      ""
    else
      line
    end
  end

  defp public_tenant_param?(line), do: Regex.match?(~r/params\[\s*"tenant"\s*\]/, line)

  defp session_default_tenant?(line) do
    Regex.match?(~r/session\[\s*"tenant_id"\s*\]\s*\|\|\s*"default"/, line)
  end

  defp hardcoded_default_tenant?(lines, line, line_number) do
    Regex.match?(~r/\|\|\s*"default"/, line) and tenant_assignment_near?(lines, line_number)
  end

  defp tenant_assignment_near?(lines, line_number) do
    lines
    |> Enum.slice(max(line_number - 2, 0), 3)
    |> Enum.join("\n")
    |> then(
      &Regex.match?(
        ~r/(tenant_id\s*=|assign\([^,\n]+,\s*:tenant_id|assign\(\s*:tenant_id|scoria_scope)/,
        &1
      )
    )
  end

  defp offender(path, line_number, reason, line) do
    %{path: path, line: line_number, reason: reason, text: String.trim(line)}
  end

  defp format_offender(%{path: path, line: line, reason: reason, text: text}) do
    "#{path}:#{line} #{reason} #{inspect(text)}"
  end
end
