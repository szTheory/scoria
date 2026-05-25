defmodule Scoria.SemanticCache.Eligibility do
  @moduledoc """
  Conservative semantic-cache eligibility and scope derivation.
  """

  alias Scoria.PromptPolicy

  def evaluate(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_map(attrs)
    tenant_id = present_string(attrs, :tenant_id)
    actor_id = present_string(attrs, :actor_id)
    semantic_cache = nested_map(attrs, :semantic_cache)
    prompt_policy = PromptPolicy.normalize(nested_map(attrs, :prompt_policy))

    cond do
      is_nil(present_string(semantic_cache, :lane_key)) -> {:bypass, :lane_not_registered}
      is_nil(tenant_id) -> {:bypass, :tenant_scope_missing}
      prompt_policy.approval_required -> {:bypass, :approval_required}
      truthy?(value(attrs, semantic_cache, :write_side_step_present)) -> {:bypass, :write_side_step_present}
      truthy?(value(attrs, semantic_cache, :personalized_tool)) -> {:bypass, :personalized_tool}
      true -> eligible_result(attrs, semantic_cache, tenant_id, actor_id)
    end
  end

  defp eligible_result(attrs, semantic_cache, tenant_id, actor_id) do
    scope_kind = derive_scope_kind(attrs, semantic_cache, actor_id)
    scope_reason = derive_scope_reason(attrs, semantic_cache, scope_kind)

    payload =
      %{
        tenant_id: tenant_id,
        actor_id: if(scope_kind == :actor_scoped, do: actor_id),
        scope_kind: scope_kind,
        scope_reason: scope_reason,
        lane_key: present_string(semantic_cache, :lane_key),
        lane_module: present_string(semantic_cache, :lane_module),
        safe_read_only: truthy?(Map.get(semantic_cache, :safe_read_only, true))
      }
      |> maybe_put(:policy_key, present_string(attrs, :policy_key))
      |> maybe_put(:prompt_ref, present_string(attrs, :prompt_ref))
      |> maybe_put(:prompt_version, present_string(attrs, :prompt_version))
      |> maybe_put(:provider, present_string(attrs, :provider))
      |> maybe_put(:model, present_string(attrs, :model))

    case scope_kind do
      :actor_scoped -> {:eligible_actor_scoped, payload}
      :tenant_shared -> {:eligible, payload}
    end
  end

  defp derive_scope_kind(attrs, semantic_cache, actor_id) do
    cond do
      truthy?(value(attrs, semantic_cache, :actor_scope_required)) and is_binary(actor_id) and actor_id != "" ->
        :actor_scoped

      truthy?(value(attrs, semantic_cache, :personalized_response)) and is_binary(actor_id) and actor_id != "" ->
        :actor_scoped

      value(semantic_cache, attrs, :default_scope) in [:actor_scoped, "actor_scoped"] and
          is_binary(actor_id) and actor_id != "" ->
        :actor_scoped

      true ->
        :tenant_shared
    end
  end

  defp derive_scope_reason(attrs, semantic_cache, :actor_scoped) do
    cond do
      truthy?(value(attrs, semantic_cache, :personalized_response)) -> "personalized_response"
      truthy?(value(attrs, semantic_cache, :actor_scope_required)) -> "actor_scope_required"
      true -> "lane_default_actor"
    end
  end

  defp derive_scope_reason(_attrs, _semantic_cache, :tenant_shared), do: "lane_default"

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp value(primary, secondary, key) do
    canonical_value(primary, key) || canonical_value(secondary, key)
  end

  defp nested_map(attrs, key) do
    case canonical_value(attrs, key) do
      value when is_map(value) -> normalize_map(value)
      value when is_list(value) -> normalize_map(value)
      _ -> %{}
    end
  end

  defp present_string(attrs, key) do
    case canonical_value(attrs, key) do
      nil ->
        nil

      value when is_binary(value) ->
        trimmed = String.trim(value)
        if trimmed == "", do: nil, else: trimmed

      value when is_atom(value) ->
        Atom.to_string(value)

      _ ->
        nil
    end
  end

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_map()
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(_attrs), do: %{}

  defp canonical_value(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp canonical_value(_attrs, _key), do: nil
end
