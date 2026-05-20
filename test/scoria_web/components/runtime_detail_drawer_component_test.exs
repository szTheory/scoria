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
          current_run_id: nil
        }
      }

      html = rendered_to_string(~H"""
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
          current_run_id: "run-abc-123"
        }
      }

      html = rendered_to_string(~H"""
      <RuntimeDetailDrawerComponent.render drawer={@drawer} />
      """)

      assert html =~ "rt-5678"
      assert html =~ "online"
      assert html =~ "run-abc-123"
      assert html =~ "href=\"/workflows/run-abc-123\""
      refute html =~ "Terminal offline reason"
    end
  end
end