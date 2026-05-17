defmodule Scoria.PromptPolicy do
  @moduledoc """
  Canonical public prompt-policy noun for runtime defaults and governance.

  Reach for this after the core `Scoria` runtime path is working. Prompt policy
  is where a host app projects provider/model defaults, grounding
  requirements, tool allowance, and approval expectations into a run's runtime
  metadata.

  In other words: start with identity and run lifecycle first, then use prompt
  policy to make governance and default composition explicit.
  """

  @enforce_keys [:metadata]
  defstruct policy_key: nil,
            prompt_ref: nil,
            prompt_version: nil,
            tools_allowed: true,
            grounding_required: false,
            approval_required: false,
            metadata: %{}

  @type t :: %__MODULE__{
          policy_key: String.t() | nil,
          prompt_ref: String.t() | nil,
          prompt_version: String.t() | nil,
          tools_allowed: boolean(),
          grounding_required: boolean(),
          approval_required: boolean(),
          metadata: map()
        }

  @string_key_map %{
    "approval_required" => :approval_required,
    "approval" => :approval_required,
    "grounding" => :grounding_required,
    "grounding_required" => :grounding_required,
    "key" => :policy_key,
    "metadata" => :metadata,
    "policy" => :policy_key,
    "policy_key" => :policy_key,
    "prompt" => :prompt_ref,
    "prompt_policy" => :prompt_policy,
    "prompt_ref" => :prompt_ref,
    "prompt_version" => :prompt_version,
    "ref" => :prompt_ref,
    "tools" => :tools_allowed,
    "tools_allowed" => :tools_allowed,
    "version" => :prompt_version
  }

  @atom_key_map %{
    approval: :approval_required,
    grounding: :grounding_required,
    key: :policy_key,
    policy: :policy_key,
    prompt: :prompt_ref,
    ref: :prompt_ref,
    tools: :tools_allowed,
    version: :prompt_version
  }

  def new(attrs \\ %{}), do: normalize(attrs)

  def normalize(%__MODULE__{} = policy) do
    %__MODULE__{
      policy
      | policy_key: normalize_string(policy.policy_key),
        prompt_ref: normalize_string(policy.prompt_ref),
        prompt_version: normalize_string(policy.prompt_version),
        tools_allowed: normalize_boolean(policy.tools_allowed, true),
        grounding_required: normalize_boolean(policy.grounding_required, false),
        approval_required: normalize_boolean(policy.approval_required, false),
        metadata: normalize_metadata(policy.metadata)
    }
  end

  def normalize(nil), do: %__MODULE__{metadata: %{}}
  def normalize(value) when is_atom(value), do: %__MODULE__{policy_key: Atom.to_string(value), metadata: %{}}
  def normalize(value) when is_binary(value), do: %__MODULE__{policy_key: value, metadata: %{}}

  def normalize(attrs) do
    attrs = normalize_map(attrs)
    nested_policy = canonical_value(attrs, :prompt_policy)
    attrs = if is_map(nested_policy), do: Map.merge(attrs, normalize_map(nested_policy)), else: attrs
    constraints = nested_map(attrs, :constraints)

    %__MODULE__{
      policy_key: normalize_string(canonical_value(attrs, :policy_key)),
      prompt_ref: normalize_string(canonical_value(attrs, :prompt_ref)),
      prompt_version: normalize_string(canonical_value(attrs, :prompt_version)),
      tools_allowed:
        attrs
        |> first_present([:tools_allowed])
        |> fallback(first_present(constraints, [:tools_allowed]))
        |> normalize_boolean(true),
      grounding_required:
        attrs
        |> first_present([:grounding_required])
        |> fallback(first_present(constraints, [:grounding_required]))
        |> normalize_boolean(false),
      approval_required:
        attrs
        |> first_present([:approval_required])
        |> fallback(first_present(constraints, [:approval_required]))
        |> normalize_boolean(false),
      metadata: normalize_metadata(canonical_value(attrs, :metadata))
    }
  end

  def to_map(%__MODULE__{} = policy) do
    policy = normalize(policy)

    %{
      policy_key: policy.policy_key,
      prompt_ref: policy.prompt_ref,
      prompt_version: policy.prompt_version,
      tools_allowed: policy.tools_allowed,
      grounding_required: policy.grounding_required,
      approval_required: policy.approval_required,
      metadata: policy.metadata
    }
  end

  defp normalize_map(%__MODULE__{} = policy), do: to_map(policy)
  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(nil), do: %{}

  defp normalize_map(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> normalize_map()
  end

  defp normalize_map(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {key, value} when is_binary(key) -> {Map.get(@string_key_map, key, key), value}
      {key, value} when is_atom(key) -> {Map.get(@atom_key_map, key, key), value}
      {key, value} -> {key, value}
    end)
  end

  defp normalize_map(_attrs), do: %{}

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

  defp first_present(attrs, keys) do
    Enum.reduce_while(keys, nil, fn key, _acc ->
      if has_key?(attrs, key) do
        {:halt, canonical_value(attrs, key)}
      else
        {:cont, nil}
      end
    end)
  end

  defp fallback(nil, value), do: value
  defp fallback(value, _fallback), do: value

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_binary(value), do: value
  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_string(value), do: to_string(value)

  defp normalize_boolean(nil, default), do: default
  defp normalize_boolean(value, _default) when is_boolean(value), do: value
  defp normalize_boolean("true", _default), do: true
  defp normalize_boolean("false", _default), do: false
  defp normalize_boolean(_value, default), do: default

  defp normalize_metadata(metadata) when is_map(metadata), do: Map.new(metadata)
  defp normalize_metadata(_metadata), do: %{}

  defp has_key?(attrs, key) when is_map(attrs) do
    Map.has_key?(attrs, key) || Map.has_key?(attrs, Atom.to_string(key))
  end

  defp has_key?(_attrs, _key), do: false
end
