defmodule Scoria.Observe.TraceProjectionTest do
  use ExUnit.Case, async: true

  alias Scoria.Observe.{Redactor, TraceProjection}

  describe "span_view/1" do
    test "omits raw secret keys from attributes_preview after redaction" do
      metadata =
        Redactor.redact(%{
          name: "llm_call",
          trace_id: Ecto.UUID.generate(),
          attributes: %{
            "password" => "secret_value",
            "api_key" => "sk-live",
            "public" => "visible"
          }
        })

      view = TraceProjection.span_view(metadata)

      refute Map.has_key?(view, :attributes)
      assert view.attributes_preview == %{"public" => "visible"}
      refute Map.has_key?(view.attributes_preview, "password")
      refute Map.has_key?(view.attributes_preview, "api_key")
    end
  end

  describe "attributes_preview cap" do
    test "truncates large attribute maps" do
      attributes =
        for index <- 1..20, into: %{} do
          {"key_#{index}", "value_#{index}_#{String.duplicate("x", 40)}"}
        end

      metadata = %{name: "heavy_span", attributes: attributes}
      view = TraceProjection.span_view(metadata)

      assert map_size(view.attributes_preview) <= 10
      assert String.length(inspect(view.attributes_preview)) <= 512
    end
  end

  describe "with_depths/1" do
    test "assigns depth for nested parent_id chain" do
      root_id = Ecto.UUID.generate()
      child_id = Ecto.UUID.generate()
      grandchild_id = Ecto.UUID.generate()

      spans = [
        %{id: root_id, parent_id: nil, name: "root"},
        %{id: child_id, parent_id: root_id, name: "child"},
        %{id: grandchild_id, parent_id: child_id, name: "grandchild"}
      ]

      [root, child, grandchild] = TraceProjection.with_depths(spans)

      assert root.depth == 0
      assert child.depth == 1
      assert grandchild.depth == 2
    end
  end

  describe "trace_header/1" do
    test "projects trace header fields from metadata" do
      trace_id = Ecto.UUID.generate()

      header =
        TraceProjection.trace_header(%{
          trace_id: trace_id,
          session_id: "session-1",
          workflow_run_id: "run-1",
          tenant_id: "tenant-1"
        })

      assert header == %{
               id: trace_id,
               session_id: "session-1",
               workflow_run_id: "run-1",
               tenant_id: "tenant-1"
             }
    end
  end
end
