defmodule ScoriaWeb.SemanticEvidenceNotebookComponentTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias ScoriaWeb.SemanticEvidenceNotebookComponent

  test "renders grouped semantic evidence sections and raw disclosure" do
    assigns = %{
      semantic_evidence: %{
        summary: %{
          lookup_status: "hit",
          fallback_outcome: "semantic_reuse",
          lane_key: "account_faq",
          scope_kind: "tenant_shared",
          scope_reason: "lane_default",
          reason_code: "cache_hit"
        },
        compatibility: %{
          prompt_version: "1",
          policy_key: "default",
          source_fingerprint: "source-v1"
        },
        provenance: %{
          workflow_run_id: "run-123",
          origin_run_id: "run-origin-123"
        },
        lifecycle: %{
          status: "active",
          hit_count: 3
        },
        candidate: %{},
        events: [
          %{event_kind: "admitted", entry_role: "selected", reason_code: "admitted"}
        ],
        raw_metadata: %{
          runtime_semantic_cache: %{"lookup_status" => "hit"}
        }
      }
    }

    html = rendered_to_string(~H"""
    <SemanticEvidenceNotebookComponent.render semantic_evidence={@semantic_evidence} />
    """)

    assert html =~ "Compatibility"
    assert html =~ "Provenance"
    assert html =~ "Lifecycle"
    assert html =~ "Append-only events"
    assert html =~ "lookup status"
    assert html =~ "admitted"
    assert html =~ "Advanced raw evidence"
  end
end
