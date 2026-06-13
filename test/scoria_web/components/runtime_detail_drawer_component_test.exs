defmodule ScoriaWeb.RuntimeDetailDrawerComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias ScoriaWeb.RuntimeDetailDrawerComponent

  describe "RuntimeDetailDrawerComponent" do
    test "renders runtime ID, status chips, and typed offline reason" do
      assigns = %{
        drawer: %{
          id: "rt-1234",
          status: "offline",
          host_session_id: "sess-999",
          transport_kind: "websocket",
          terminal_offline_reason: "Connection lost",
          current_run_id: nil,
          semantic: nil
        }
      }

      html =
        rendered_to_string(~H"""
        <RuntimeDetailDrawerComponent.render drawer={@drawer} />
        """)

      assert html =~ "rt-1234"
      assert html =~ "offline"
      assert html =~ "Connection lost"
      assert html =~ "sess-999"
      assert html =~ "websocket"
      refute html =~ "View run"
    end

    test "renders reciprocal hyperlink to the active workflow/session" do
      assigns = %{
        drawer: %{
          id: "rt-5678",
          status: "online",
          host_session_id: "sess-888",
          transport_kind: "sse",
          terminal_offline_reason: nil,
          current_run_id: "run-abc-123",
          semantic: %{
            lookup_status: "hit",
            fallback_outcome: "semantic_reuse",
            lane_key: "account_faq",
            scope_kind: "tenant_shared",
            scope_reason: "lane_default",
            reason_code: "cache_hit",
            actor_id: nil,
            workflow_href: "/workflows/run-abc-123",
            origin_run_href: "/workflows/run-origin-123"
          }
        }
      }

      html =
        rendered_to_string(~H"""
        <RuntimeDetailDrawerComponent.render drawer={@drawer} />
        """)

      assert html =~ "rt-5678"
      assert html =~ "online"
      assert html =~ "run-abc-123"
      assert html =~ "href=\"/workflows/run-abc-123\""
      assert html =~ "lookup_status"
      assert html =~ "scope_kind"
      assert html =~ "View workflow evidence"
      assert html =~ "View origin run"
      assert html =~ "Semantic fast path reused a cached answer."
      refute html =~ "Terminal offline reason"
    end

    test "renders explicit fallback evidence without notebook-only content" do
      assigns = %{
        drawer: %{
          id: "rt-9012",
          status: "online",
          host_session_id: "sess-777",
          transport_kind: "websocket",
          terminal_offline_reason: nil,
          current_run_id: "run-fallback-123",
          semantic: %{
            lookup_status: "reject",
            fallback_outcome: "normal_runtime_path_executed",
            lane_key: "account_faq",
            scope_kind: "actor_scoped",
            scope_reason: "lane_default_actor",
            reason_code: "prompt_version_mismatch",
            actor_id: "actor-42",
            workflow_href: "/workflows/run-fallback-123",
            origin_run_href: nil
          }
        }
      }

      html =
        rendered_to_string(~H"""
        <RuntimeDetailDrawerComponent.render drawer={@drawer} />
        """)

      assert html =~ "reject"
      assert html =~ "prompt_version_mismatch"
      assert html =~ "Normal runtime path executed."
      assert html =~ "Actor scope: "
      assert html =~ "View workflow evidence"
      refute html =~ "Advanced raw evidence"
    end
  end
end
