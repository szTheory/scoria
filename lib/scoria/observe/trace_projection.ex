defmodule Scoria.Observe.TraceProjection do
  @moduledoc """
  UI-safe span and trace projections for operator dashboard live updates.

  Builds curated maps from redacted telemetry metadata — never exposes raw
  attribute maps on PubSub.
  """

  @preview_max_keys 10
  @preview_max_chars 512

  # Hard cap on depth_for/3's parent-chain walk (T-53-07). `parent_id` is
  # host-declared (D-02a) — a buggy host call can self-parent a span or
  # produce a cycle, and depth_for/3 runs inside the operator's LiveView
  # process. 100 is generous for any real trace and tight enough to bound
  # the worst case even if the visited-set guard below has a bug.
  @max_depth 100

  @deny_list MapSet.new([
               "password",
               "api_key",
               "token",
               "secret",
               :password,
               :api_key,
               :token,
               :secret
             ])

  def trace_header(redacted_metadata) when is_map(redacted_metadata) do
    %{
      id: Map.get(redacted_metadata, :trace_id),
      session_id: Map.get(redacted_metadata, :session_id),
      workflow_run_id: Map.get(redacted_metadata, :workflow_run_id),
      tenant_id: Map.get(redacted_metadata, :tenant_id)
    }
  end

  def span_view(redacted_metadata) when is_map(redacted_metadata) do
    attributes = Map.get(redacted_metadata, :attributes, %{})

    %{
      id: Map.get(redacted_metadata, :id) || Ecto.UUID.generate(),
      name: Map.get(redacted_metadata, :name),
      span_kind: Map.get(redacted_metadata, :span_kind),
      status_code: Map.get(redacted_metadata, :status_code, "OK"),
      parent_id: Map.get(redacted_metadata, :parent_id),
      start_time: Map.get(redacted_metadata, :start_time),
      end_time: Map.get(redacted_metadata, :end_time),
      attributes_preview: attributes_preview(attributes)
    }
  end

  @doc """
  Assigns `:depth` to each span by walking its `parent_id` chain via
  `depth_for/3`.

  Cycle-safe (a `visited` `MapSet` accumulator prevents re-entering a span
  already on the walk) AND depth-capped (`@max_depth`, currently
  #{@max_depth}) — both guards are independent: the visited set catches a
  cycle, the cap bounds the worst case even if the visited-set logic has a
  bug (T-53-07). An orphan span (`parent_id` not present in `spans`) stays
  a root at depth 0 (D-07f).
  """
  @spec with_depths([map()]) :: [map()]
  def with_depths(spans) when is_list(spans) do
    parent_map = Map.new(spans, &{&1.id, &1})

    Enum.map(spans, fn span ->
      Map.put(span, :depth, depth_for(span, parent_map, 0))
    end)
  end

  @doc """
  Pre-order depth-first-search over the `parent_id` graph. Roots (`nil`
  `parent_id`, or a `parent_id` not present in `spans` — an orphan, D-07f)
  come first in their existing relative order; each root is immediately
  followed by its subtree, and siblings appear in the same relative order
  they had in the input list (tree position, NOT `start_time` — two
  concurrent tool calls under one agent must render in a stable, declared
  order rather than being re-sorted by wall-clock arrival).

  Cycle-safe by construction: a visited set guarantees a span already
  emitted is never emitted again, so a self-parent or an N-cycle
  terminates. Emits EVERY input span exactly once — a span belonging
  entirely to a cycle with no reachable root (e.g. a bare self-parent) is
  still force-emitted in a second pass, so a malformed graph can never
  silently swallow a span.
  """
  @spec tree_order([map()]) :: [map()]
  def tree_order(spans) when is_list(spans) do
    id_index = Map.new(spans, &{&1.id, &1})
    children_by_parent = Enum.group_by(spans, & &1.parent_id)

    {ordered, visited} =
      Enum.reduce(spans, {[], MapSet.new()}, fn span, {acc, visited} ->
        if not MapSet.member?(visited, span.id) and root?(span, id_index) do
          visit(span, children_by_parent, visited, acc)
        else
          {acc, visited}
        end
      end)

    {ordered, _visited} =
      Enum.reduce(spans, {ordered, visited}, fn span, {acc, visited} ->
        if MapSet.member?(visited, span.id) do
          {acc, visited}
        else
          visit(span, children_by_parent, visited, acc)
        end
      end)

    Enum.reverse(ordered)
  end

  defp root?(%{parent_id: nil}, _id_index), do: true
  defp root?(%{parent_id: parent_id}, id_index), do: not Map.has_key?(id_index, parent_id)

  defp visit(span, children_by_parent, visited, acc) do
    if MapSet.member?(visited, span.id) do
      {acc, visited}
    else
      visited = MapSet.put(visited, span.id)
      acc = [span | acc]
      children = Map.get(children_by_parent, span.id, [])

      Enum.reduce(children, {acc, visited}, fn child, {acc2, visited2} ->
        visit(child, children_by_parent, visited2, acc2)
      end)
    end
  end

  defp depth_for(span, parent_map, depth), do: depth_for(span, parent_map, depth, MapSet.new())

  defp depth_for(%{parent_id: nil}, _parent_map, depth, _visited), do: depth

  defp depth_for(span, parent_map, depth, visited) do
    cond do
      depth >= @max_depth ->
        depth

      MapSet.member?(visited, span.id) ->
        depth

      true ->
        case Map.get(parent_map, span.parent_id) do
          nil -> depth
          parent -> depth_for(parent, parent_map, depth + 1, MapSet.put(visited, span.id))
        end
    end
  end

  defp attributes_preview(attributes) when is_map(attributes) do
    attributes
    |> Enum.reject(fn {key, _value} -> MapSet.member?(@deny_list, key) end)
    |> Enum.take(@preview_max_keys)
    |> Map.new()
    |> cap_preview_size()
  end

  defp attributes_preview(_), do: %{}

  defp cap_preview_size(preview) do
    if preview_char_count(preview) > @preview_max_chars do
      preview
      |> Enum.take(div(@preview_max_keys, 2))
      |> Map.new()
      |> cap_preview_size()
    else
      preview
    end
  end

  defp preview_char_count(preview), do: preview |> inspect() |> String.length()
end
