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

    test "orphan span (parent not in fetched set) stays a root at depth 0 (D-07f)" do
      spans = [%{id: "child", parent_id: "missing-parent", name: "orphan"}]

      [result] = TraceProjection.with_depths(spans)

      assert result.depth == 0
    end
  end

  describe "with_depths/1 cycle guard (T-53-07)" do
    test "self-parent terminates rather than hanging" do
      task =
        Task.async(fn ->
          TraceProjection.with_depths([%{id: "a", parent_id: "a"}])
        end)

      result = Task.await(task, 1000)

      assert [%{id: "a", depth: depth}] = result
      assert is_integer(depth)
    end

    test "2-cycle terminates and both spans get an integer depth" do
      task =
        Task.async(fn ->
          TraceProjection.with_depths([
            %{id: "a", parent_id: "b"},
            %{id: "b", parent_id: "a"}
          ])
        end)

      result = Task.await(task, 1000)

      assert [%{depth: depth_a}, %{depth: depth_b}] = result
      assert is_integer(depth_a)
      assert is_integer(depth_b)
    end

    test "depth is clamped at the hard cap for a pathologically deep chain" do
      spans =
        for i <- 0..149 do
          parent_id = if i == 0, do: nil, else: "span-#{i - 1}"
          %{id: "span-#{i}", parent_id: parent_id}
        end

      result = TraceProjection.with_depths(spans)
      deepest = Enum.max_by(result, & &1.depth)

      assert deepest.depth == 100
    end
  end

  describe "tree_order/1" do
    test "pre-order DFS orders by tree position, not start_time" do
      parent = %{id: "p", parent_id: nil, start_time: ~U[2026-01-01 00:00:00.000000Z]}
      child1 = %{id: "c1", parent_id: "p", start_time: ~U[2026-01-01 00:00:02.000000Z]}
      child2 = %{id: "c2", parent_id: "p", start_time: ~U[2026-01-01 00:00:01.000000Z]}

      ordered = TraceProjection.tree_order([parent, child1, child2])

      assert Enum.map(ordered, & &1.id) == ["p", "c1", "c2"]
    end

    test "tolerates cycles (terminates) and emits orphan spans as roots" do
      task =
        Task.async(fn ->
          TraceProjection.tree_order([%{id: "a", parent_id: "a"}])
        end)

      result = Task.await(task, 1000)

      assert Enum.map(result, & &1.id) == ["a"]

      orphan = %{id: "orphan", parent_id: "missing"}
      root = %{id: "root", parent_id: nil}

      ordered = TraceProjection.tree_order([root, orphan])

      assert Enum.sort(Enum.map(ordered, & &1.id)) == ["orphan", "root"]
      assert length(ordered) == 2
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
