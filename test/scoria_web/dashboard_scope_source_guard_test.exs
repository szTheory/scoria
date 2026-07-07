defmodule ScoriaWeb.DashboardScopeSourceGuardTest do
  use ExUnit.Case, async: true

  @moduledoc """
  AUTH-03 dashboard tenant-authority guard.

  Dashboard LiveViews may use public params as selectors, filters, and object
  IDs, but tenant authority must come from ScoriaWeb.DashboardScope assigns.
  """

  @scan_glob "lib/scoria_web/live/**/*.ex"
  @scan_paths Path.wildcard(@scan_glob)

  test "scans every dashboard LiveView source file" do
    assert "lib/scoria_web/live/orchestrator_live.ex" in @scan_paths
    assert "lib/scoria_web/live/prompt_live/release_workbench_live.ex" in @scan_paths
  end

  test "dashboard LiveViews do not derive tenant authority from params or hardcoded defaults" do
    assert dashboard_tenant_authority_offenders() == []
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
end
