defmodule Scoria.Runtime.Defaults do
  @moduledoc """
  Resolves baseline and identity-aware runtime defaults exactly once.
  """

  alias Scoria.{Identity, PromptPolicy}

  @built_in_defaults %{
    provider: "openai",
    model: "gpt-5-mini",
    prompt_policy: %PromptPolicy{policy_key: "default", metadata: %{}}
  }

  @sensitive_prompt_fields [:tools_allowed, :grounding_required, :approval_required]

  def built_in_defaults do
    normalize_defaults(@built_in_defaults)
  end

  def app_defaults do
    runtime_config()
    |> Keyword.get(:defaults, %{})
    |> normalize_defaults()
  end

  def resolver_module do
    runtime_config()
    |> Keyword.get(:resolver)
  end

  def resolve(identity, opts \\ []) do
    opts = normalize_map(opts)
    runtime = nested_map(opts, :runtime)
    identity = Identity.normalize(identity)

    with {:ok, overlays} <- resolve_overlays(identity, opts, runtime),
         :ok <- validate_runtime_override(overlays, runtime) do
      defaults =
        built_in_defaults()
        |> merge_defaults(app_defaults())
        |> merge_defaults(Map.get(overlays, :tenant_defaults, %{}))
        |> merge_defaults(Map.get(overlays, :actor_defaults, %{}))
        |> merge_defaults(runtime_defaults(runtime, opts))

      {:ok, defaults}
    end
  end

  def to_metadata(defaults) do
    defaults = normalize_defaults(defaults)
    prompt_policy = PromptPolicy.normalize(defaults.prompt_policy || %{})

    %{
      "provider" => defaults.provider,
      "model" => defaults.model,
      "policy_key" => prompt_policy.policy_key,
      "prompt_ref" => prompt_policy.prompt_ref,
      "prompt_version" => prompt_policy.prompt_version,
      "prompt_policy" => PromptPolicy.to_map(prompt_policy)
    }
  end

  def to_context(defaults) do
    defaults = normalize_defaults(defaults)
    prompt_policy = PromptPolicy.normalize(defaults.prompt_policy || %{})

    %{
      provider: defaults.provider,
      model: defaults.model,
      policy_key: prompt_policy.policy_key,
      prompt_ref: prompt_policy.prompt_ref,
      prompt_version: prompt_policy.prompt_version,
      prompt_policy: PromptPolicy.to_map(prompt_policy)
    }
  end

  defp runtime_config do
    Application.get_env(:scoria, Scoria.Runtime, [])
  end

  defp runtime_defaults(runtime, opts) do
    default_fields(opts)
    |> merge_default_fields(default_fields(runtime))
    |> normalize_defaults()
  end

  defp resolve_overlays(identity, opts, runtime) do
    case resolver_module() do
      nil ->
        {:ok, %{tenant_defaults: %{}, actor_defaults: %{}}}

      module ->
        context = %{
          defaults: app_defaults(),
          runtime: runtime_defaults(runtime, opts),
          opts: opts,
          runtime_opts: runtime
        }

        resolved = invoke_resolver(module, identity, context)
        normalize_overlays(resolved)
    end
  end

  defp invoke_resolver(module, identity, context) do
    cond do
      function_exported?(module, :resolve_defaults, 2) -> module.resolve_defaults(identity, context)
      function_exported?(module, :resolve, 2) -> module.resolve(identity, context)
      true -> {:error, {:invalid_defaults_resolver, module}}
    end
  end

  defp normalize_overlays({:ok, overlays}), do: normalize_overlays(overlays)
  defp normalize_overlays({:error, _reason} = error), do: error

  defp normalize_overlays(overlays) when is_map(overlays) do
    overlays = normalize_map(overlays)

    {:ok,
     %{
       tenant_defaults:
         overlays
         |> Map.get(:tenant_defaults, Map.get(overlays, :tenant, %{}))
         |> normalize_defaults(),
       actor_defaults:
         overlays
         |> Map.get(:actor_defaults, Map.get(overlays, :actor, %{}))
         |> normalize_defaults()
     }}
  end

  defp normalize_overlays(overlays) when is_list(overlays) do
    overlays
    |> Enum.into(%{})
    |> normalize_overlays()
  end

  defp normalize_overlays(_overlays), do: {:error, :invalid_defaults_overlay}

  defp validate_runtime_override(overlays, runtime) do
    baseline_policy =
      built_in_defaults()
      |> merge_defaults(app_defaults())
      |> merge_defaults(Map.get(overlays, :tenant_defaults, %{}))
      |> merge_defaults(Map.get(overlays, :actor_defaults, %{}))
      |> Map.fetch!(:prompt_policy)

    runtime_policy = explicit_prompt_policy_fields(canonical_value(runtime, :prompt_policy))

    Enum.reduce_while(@sensitive_prompt_fields, :ok, fn field, _acc ->
      baseline = Map.get(baseline_policy, field)
      override = Map.get(runtime_policy, field)

      case widening?(field, baseline, override, Map.has_key?(runtime_policy, field)) do
        true -> {:halt, {:error, {:unsafe_runtime_override, field}}}
        false -> {:cont, :ok}
      end
    end)
  end

  defp widening?(:tools_allowed, false, true, true), do: true
  defp widening?(:grounding_required, true, false, true), do: true
  defp widening?(:approval_required, true, false, true), do: true
  defp widening?(_field, _baseline, _override, _present?), do: false

  defp merge_defaults(left, right) do
    left = normalize_defaults(left)
    right = normalize_defaults(right)

    %{
      provider: right.provider || left.provider,
      model: right.model || left.model,
      prompt_policy: merge_prompt_policy(left.prompt_policy, right.prompt_policy) || PromptPolicy.new()
    }
  end

  defp merge_prompt_policy(left, nil), do: left
  defp merge_prompt_policy(nil, right), do: merge_prompt_policy(PromptPolicy.new(), right)

  defp merge_prompt_policy(left, right) do
    left = PromptPolicy.normalize(left)
    right_fields = explicit_prompt_policy_fields(right)

    left
    |> PromptPolicy.to_map()
    |> Map.merge(right_fields, fn
      :metadata, current, incoming -> Map.merge(current, incoming)
      _key, _current, incoming -> incoming
    end)
    |> PromptPolicy.normalize()
  end

  defp normalize_defaults(defaults) do
    defaults = normalize_map(defaults)
    prompt_policy =
      if Map.has_key?(defaults, :prompt_policy) || Map.has_key?(defaults, "prompt_policy") do
        explicit_prompt_policy_fields(canonical_value(defaults, :prompt_policy))
      end

    %{
      provider: normalize_string(canonical_value(defaults, :provider)),
      model: normalize_string(canonical_value(defaults, :model)),
      prompt_policy: prompt_policy
    }
  end

  defp default_fields(attrs) do
    attrs = normalize_map(attrs)

    %{
      provider: canonical_value(attrs, :provider),
      model: canonical_value(attrs, :model),
      prompt_policy: canonical_value(attrs, :prompt_policy)
    }
  end

  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_map()
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(_attrs), do: %{}

  defp merge_default_fields(left, right) do
    %{
      provider: right.provider || left.provider,
      model: right.model || left.model,
      prompt_policy: right.prompt_policy || left.prompt_policy
    }
  end

  defp nested_map(attrs, key) do
    case canonical_value(attrs, key) do
      value when is_map(value) or is_list(value) -> normalize_map(value)
      _ -> %{}
    end
  end

  defp canonical_value(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp canonical_value(_attrs, _key), do: nil

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_binary(value), do: value
  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_string(value), do: to_string(value)

  defp explicit_prompt_policy_fields(nil), do: %{}

  defp explicit_prompt_policy_fields(%PromptPolicy{} = policy) do
    PromptPolicy.to_map(policy)
  end

  defp explicit_prompt_policy_fields(value) when is_atom(value) or is_binary(value) do
    %{policy_key: normalize_string(value)}
  end

  defp explicit_prompt_policy_fields(value) do
    attrs = normalize_map(value)
    normalized = PromptPolicy.to_map(PromptPolicy.normalize(attrs))

    %{}
    |> maybe_put_prompt_field(:policy_key, attrs, normalized)
    |> maybe_put_prompt_field(:prompt_ref, attrs, normalized)
    |> maybe_put_prompt_field(:prompt_version, attrs, normalized)
    |> maybe_put_prompt_field(:tools_allowed, attrs, normalized)
    |> maybe_put_prompt_field(:grounding_required, attrs, normalized)
    |> maybe_put_prompt_field(:approval_required, attrs, normalized)
    |> maybe_put_prompt_field(:metadata, attrs, normalized)
  end

  defp maybe_put_prompt_field(acc, key, attrs, normalized) do
    if prompt_policy_field_present?(attrs, key) do
      Map.put(acc, key, Map.fetch!(normalized, key))
    else
      acc
    end
  end

  defp prompt_policy_field_present?(attrs, :policy_key), do: present?(attrs, [:policy_key, :policy, :key])
  defp prompt_policy_field_present?(attrs, :prompt_ref), do: present?(attrs, [:prompt_ref, :prompt, :ref])
  defp prompt_policy_field_present?(attrs, :prompt_version), do: present?(attrs, [:prompt_version, :version])
  defp prompt_policy_field_present?(attrs, :tools_allowed), do: present?(attrs, [:tools_allowed, :tools])
  defp prompt_policy_field_present?(attrs, :grounding_required), do: present?(attrs, [:grounding_required, :grounding])
  defp prompt_policy_field_present?(attrs, :approval_required), do: present?(attrs, [:approval_required, :approval])
  defp prompt_policy_field_present?(attrs, :metadata), do: present?(attrs, [:metadata])

  defp present?(attrs, keys) do
    Enum.any?(keys, fn key ->
      Map.has_key?(attrs, key) || Map.has_key?(attrs, Atom.to_string(key))
    end)
  end
end
