defmodule ScoriaWeb.SemanticCacheTraceNotebookComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias ScoriaWeb.SemanticCacheTraceNotebookComponent

  test "renders semantic cache trace inspection groups" do
    assigns = %{
      semantic_evidence: %{
        summary: %{
          lookup_status: "hit",
          fallback_outcome: "semantic_reuse",
          lane_key: "account_faq",
          scope_kind: "tenant_shared"
        },
        compatibility: %{policy_key: "default"},
        provenance: %{workflow_run_id: "run-123"},
        lifecycle: %{status: "active"},
        candidate: %{},
        events: [%{event_kind: "admitted", entry_role: "selected", reason_code: "admitted"}]
      }
    }

    html =
      rendered_to_string(~H"""
      <SemanticCacheTraceNotebookComponent.render semantic_evidence={@semantic_evidence} />
      """)

    assert html =~ ~s(id="semantic-cache-trace-notebook")
    assert html =~ "Semantic cache trace inspection"
    assert html =~ "Semantic cache trace groups"
    assert html =~ "Cache execution details"
    assert html =~ "Append-only events"
    assert html =~ "account_faq"
  end
end
