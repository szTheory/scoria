defmodule Scoria.Knowledge.Scope do
  @moduledoc """
  Canonical scope normalization for tenant-owned knowledge operations.
  """

  import Ecto.Query, warn: false

  @scope_kinds ~w(tenant_shared actor_scoped)
  @known_attr_keys %{
    "actor_id" => :actor_id,
    "scope" => :scope,
    "scope_kind" => :scope_kind,
    "tenant_id" => :tenant_id
  }
  @scope_keys [:tenant_id, :actor_id, :scope_kind]

  defstruct [:tenant_id, :actor_id, :scope_kind]

  def new!(%__MODULE__{} = scope), do: validate!(scope)

  def new!(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)

    %__MODULE__{
      tenant_id: required_id!(Map.get(attrs, :tenant_id), :tenant_id),
      actor_id: optional_id(Map.get(attrs, :actor_id)),
      scope_kind: scope_kind!(Map.get(attrs, :scope_kind, "tenant_shared"))
    }
    |> validate!()
  end

  def from_opts!(%__MODULE__{} = scope), do: new!(scope)

  def from_opts!(opts) when is_map(opts) or is_list(opts) do
    opts = normalize_attrs(opts)

    case Map.fetch(opts, :scope) do
      {:ok, scope_input} ->
        scope = new!(scope_input)
        ensure_no_shorthand_conflicts!(scope, opts)

      :error ->
        opts
        |> Map.take(@scope_keys)
        |> new!()
    end
  end

  def for_write!(input) do
    scope = from_opts!(input)

    if scope.scope_kind == "actor_scoped" and blank?(scope.actor_id) do
      raise ArgumentError, "actor_id is required for actor_scoped scope"
    end

    scope
  end

  def put_source_attrs(attrs, scope_input) when is_map(attrs) or is_list(attrs) do
    scope = for_write!(scope_input)

    attrs
    |> attrs_to_map()
    |> Map.put(:tenant_id, scope.tenant_id)
    |> Map.put(:actor_id, scope.actor_id)
    |> Map.put(:scope_kind, scope.scope_kind)
  end

  def put_audit_attrs(attrs, scope_input) when is_map(attrs) or is_list(attrs) do
    scope = from_opts!(scope_input)

    attrs
    |> attrs_to_map()
    |> Map.put(:tenant_id, scope.tenant_id)
    |> Map.put(:actor_id, scope.actor_id)
  end

  def visible_to(%Ecto.Query{} = query, scope_input) do
    scope_input
    |> from_opts!()
    |> apply_visibility_filter(query)
  end

  def visible_to(queryable, scope_input) when is_atom(queryable) do
    queryable
    |> from(as: :knowledge_scope)
    |> visible_to(scope_input)
  end

  def visible_to(%_{} = row, scope_input), do: row |> Map.from_struct() |> visible_to(scope_input)

  def visible_to(row, scope_input) when is_map(row) do
    scope = from_opts!(scope_input)
    row = normalize_attrs(row)

    row[:tenant_id] == scope.tenant_id and
      case row[:scope_kind] do
        "tenant_shared" -> true
        "actor_scoped" -> present?(scope.actor_id) and row[:actor_id] == scope.actor_id
        _other -> false
      end
  end

  defp apply_visibility_filter(%__MODULE__{} = scope, query) do
    query = where(query, [row], row.tenant_id == ^scope.tenant_id)

    if present?(scope.actor_id) do
      where(
        query,
        [row],
        row.scope_kind == "tenant_shared" or
          (row.scope_kind == "actor_scoped" and row.actor_id == ^scope.actor_id)
      )
    else
      where(query, [row], row.scope_kind == "tenant_shared")
    end
  end

  defp ensure_no_shorthand_conflicts!(%__MODULE__{} = scope, opts) do
    Enum.each(@scope_keys, fn key ->
      if Map.has_key?(opts, key) do
        expected = Map.fetch!(scope, key)
        actual = normalize_scope_value!(key, Map.fetch!(opts, key))

        if actual != expected do
          raise ArgumentError, "conflicting #{key} between scope and shorthand"
        end
      end
    end)

    scope
  end

  defp normalize_scope_value!(:tenant_id, value), do: required_id!(value, :tenant_id)
  defp normalize_scope_value!(:actor_id, value), do: optional_id(value)
  defp normalize_scope_value!(:scope_kind, value), do: scope_kind!(value)

  defp validate!(%__MODULE__{} = scope) do
    %__MODULE__{
      scope
      | tenant_id: required_id!(scope.tenant_id, :tenant_id),
        actor_id: optional_id(scope.actor_id),
        scope_kind: scope_kind!(scope.scope_kind)
    }
  end

  defp normalize_attrs(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_list(attrs),
    do: attrs |> Enum.into(%{}) |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &normalize_pair/1)

  defp normalize_pair({key, value}) when is_binary(key),
    do: {Map.get(@known_attr_keys, key, key), value}

  defp normalize_pair({key, value}), do: {key, value}

  defp attrs_to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp attrs_to_map(attrs) when is_map(attrs), do: attrs

  defp required_id!(value, field) do
    case optional_id(value) do
      nil -> raise ArgumentError, "#{field} is required"
      id -> id
    end
  end

  defp optional_id(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      id -> id
    end
  end

  defp optional_id(nil), do: nil

  defp optional_id(value) do
    raise ArgumentError, "scope identifiers must be strings, got: #{inspect(value)}"
  end

  defp scope_kind!(value) when is_atom(value), do: value |> Atom.to_string() |> scope_kind!()

  defp scope_kind!(value) when is_binary(value) do
    value = String.trim(value)

    if value in @scope_kinds do
      value
    else
      raise ArgumentError, "scope_kind must be one of #{inspect(@scope_kinds)}"
    end
  end

  defp scope_kind!(_value),
    do: raise(ArgumentError, "scope_kind must be one of #{inspect(@scope_kinds)}")

  defp present?(value), do: not blank?(value)
  defp blank?(value), do: is_nil(value) or value == ""
end
