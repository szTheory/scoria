defmodule Scoria.Observe.TraceProjection do
  @moduledoc """
  UI-safe span and trace projections for operator dashboard live updates.

  Builds curated maps from redacted telemetry metadata — never exposes raw
  attribute maps on PubSub.
  """

  @preview_max_keys 10
  @preview_max_chars 512

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

  def with_depths(spans) when is_list(spans) do
    parent_map = Map.new(spans, &{&1.id, &1})

    Enum.map(spans, fn span ->
      Map.put(span, :depth, depth_for(span, parent_map, 0))
    end)
  end

  defp depth_for(%{parent_id: nil}, _parent_map, depth), do: depth
  defp depth_for(%{parent_id: parent_id}, _parent_map, depth) when is_nil(parent_id), do: depth

  defp depth_for(span, parent_map, depth) do
    case Map.get(parent_map, span.parent_id) do
      nil -> depth
      parent -> depth_for(parent, parent_map, depth + 1)
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
