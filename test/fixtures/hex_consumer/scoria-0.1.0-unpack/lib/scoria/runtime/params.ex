defmodule Scoria.Runtime.Params do
  @moduledoc """
  Normalizes public runtime inputs into explicit start and resume contracts.
  """

  alias Scoria.{Identity, Runtime.Defaults, SemanticLane}

  @dispatch_keys ~w(dispatch handlers timeout budget_context breaker_context)a
  def start(identity, opts \\ []) do
    opts = normalize_map(opts)
    runtime = nested_map(opts, :runtime)
    dispatch = dispatch_opts(opts)
    identity = Identity.normalize(identity)

    with {:ok, resolved_defaults} <- Defaults.resolve(identity, opts),
         {:ok, semantic_cache} <- semantic_cache_config(opts, runtime) do
      root_role_id =
        value(opts, runtime, :root_role_id) ||
          "executor"

      workflow_attrs =
        %{
          root_role_id: root_role_id,
          actor_id: identity.actor_id,
          tenant_id: identity.tenant_id,
          session_id: identity.session_id,
          metadata: start_metadata(opts, runtime, identity, resolved_defaults, semantic_cache)
        }
        |> maybe_put_initial_step(initial_step(opts, runtime))

      {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch}}
    end
  end

  def start_handoff(identity, delegated_role_id, opts \\ [])

  def start_handoff(identity, delegated_role_id, opts)
      when is_binary(delegated_role_id) and delegated_role_id != "" do
    opts = normalize_map(opts)
    runtime = nested_map(opts, :runtime)
    dispatch = dispatch_opts(opts)
    identity = Identity.normalize(identity)

    with {:ok, resolved_defaults} <- Defaults.resolve(identity, opts),
         {:ok, semantic_cache} <- semantic_cache_config(opts, runtime),
         {:ok, root_role_id} <-
           required_string(opts, runtime, :root_role_id, :invalid_root_role_id),
         {:ok, delegated_kind} <-
           required_string(opts, runtime, :delegated_kind, :invalid_delegated_kind),
         {:ok, handoff_input} <-
           required_map(opts, runtime, :handoff_input, :invalid_handoff_input),
         {:ok, projected_context} <-
           required_map(opts, runtime, :projected_context, :invalid_projected_context),
         :ok <- validate_projected_context(projected_context) do
      workflow_attrs = %{
        root_role_id: root_role_id,
        actor_id: identity.actor_id,
        tenant_id: identity.tenant_id,
        session_id: identity.session_id,
        metadata: start_metadata(opts, runtime, identity, resolved_defaults, semantic_cache)
      }

      handoff_attrs = %{
        "delegated_role_id" => delegated_role_id,
        "delegated_kind" => delegated_kind,
        "capability_tags" => capability_tags(opts, runtime),
        "handoff_input" => handoff_input,
        "projected_context" => projected_context
      }

      {:ok,
       %{workflow_attrs: workflow_attrs, handoff_attrs: handoff_attrs, dispatch_opts: dispatch}}
    end
  end

  def start_handoff(_identity, _delegated_role_id, _opts),
    do: {:error, :invalid_delegated_role_id}

  def resume(run_id, opts \\ [])

  def resume(run_id, opts) when is_binary(run_id) and run_id != "" do
    opts = normalize_map(opts)
    {:ok, dispatch_opts(opts)}
  end

  def resume(_run_id, _opts), do: {:error, :invalid_run_id}

  def validate_projected_context(projected_context) when is_map(projected_context) do
    case find_unsafe_projected_context_path(projected_context, []) do
      nil -> :ok
      _path -> {:error, :unsafe_projected_context}
    end
  end

  def validate_projected_context(_projected_context), do: {:error, :invalid_projected_context}

  defp dispatch_opts(opts) do
    Enum.reduce(@dispatch_keys, [], fn key, acc ->
      case canonical_value(opts, key) do
        nil -> acc
        value -> Keyword.put(acc, key, value)
      end
    end)
  end

  defp start_metadata(opts, runtime, identity, resolved_defaults, semantic_cache) do
    metadata =
      opts
      |> value(runtime, :metadata)
      |> normalize_metadata()

    payload =
      opts
      |> value(runtime, :payload)
      |> case do
        nil -> value(opts, runtime, :input)
        value -> value
      end

    runtime_metadata =
      resolved_defaults
      |> Defaults.to_metadata()
      |> maybe_put_semantic_cache(semantic_cache)

    metadata
    |> maybe_put_payload(payload)
    |> maybe_put_identity_metadata(identity)
    |> Map.put("runtime", runtime_metadata)
  end

  defp initial_step(opts, runtime) do
    opts
    |> value(runtime, :initial_step)
    |> case do
      nil -> nil
      step when is_map(step) -> normalize_map(step)
      _ -> nil
    end
  end

  defp maybe_put_initial_step(attrs, nil), do: attrs

  defp maybe_put_initial_step(attrs, step) do
    step =
      step
      |> Map.put_new(:projected_context, canonical_value(step, :projected_context) || %{})
      |> maybe_put_payload_as_context(attrs[:metadata]["payload"])

    Map.put(attrs, :initial_step, step)
  end

  defp maybe_put_payload_as_context(step, nil), do: step

  defp maybe_put_payload_as_context(step, payload) do
    projected_context =
      step
      |> canonical_value(:projected_context)
      |> normalize_metadata()
      |> Map.put_new("payload", payload)

    Map.put(step, :projected_context, projected_context)
  end

  defp maybe_put_payload(metadata, nil), do: metadata
  defp maybe_put_payload(metadata, payload), do: Map.put(metadata, "payload", payload)

  defp maybe_put_semantic_cache(runtime_metadata, nil), do: runtime_metadata

  defp maybe_put_semantic_cache(runtime_metadata, semantic_cache) do
    Map.put(runtime_metadata, "semantic_cache", %{
      "lane" => semantic_cache.lane_module,
      "lane_key" => semantic_cache.lane_key,
      "default_scope" => Atom.to_string(semantic_cache.default_scope),
      "safe_read_only" => semantic_cache.safe_read_only,
      "metadata" => semantic_cache.metadata
    })
  end

  defp capability_tags(opts, runtime) do
    opts
    |> value(runtime, :capability_tags)
    |> List.wrap()
    |> Enum.map(&to_string/1)
  end

  defp maybe_put_identity_metadata(metadata, %Identity{} = identity) do
    if map_size(metadata) == 0 do
      metadata
    else
      Map.put_new(metadata, "identity", Identity.to_map(identity))
    end
  end

  defp value(opts, runtime, key) do
    canonical_value(runtime, key) || canonical_value(opts, key)
  end

  defp nested_map(attrs, key) do
    case canonical_value(attrs, key) do
      value when is_map(value) -> normalize_map(value)
      _ -> %{}
    end
  end

  defp normalize_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(attrs) when is_map(attrs), do: Map.new(attrs)
  defp normalize_map(_attrs), do: %{}

  defp normalize_metadata(metadata) when is_map(metadata), do: Map.new(metadata)
  defp normalize_metadata(_metadata), do: %{}

  defp semantic_cache_config(opts, runtime) do
    case value(opts, runtime, :semantic_cache) do
      nil ->
        {:ok, nil}

      semantic_cache ->
        semantic_cache
        |> normalize_map()
        |> canonical_value(:lane)
        |> SemanticLane.describe()
    end
  end

  defp required_string(opts, runtime, key, error) do
    case value(opts, runtime, key) do
      value when is_binary(value) ->
        value = String.trim(value)

        if value == "" do
          {:error, error}
        else
          {:ok, value}
        end

      _ ->
        {:error, error}
    end
  end

  defp required_map(opts, runtime, key, error) do
    case value(opts, runtime, key) do
      value when is_map(value) -> {:ok, Map.new(value)}
      _ -> {:error, error}
    end
  end

  defp find_unsafe_projected_context_path(value, path) when is_map(value) do
    Enum.find_value(value, fn {key, nested} ->
      normalized_key = normalize_projected_context_key(key)
      nested_path = path ++ [to_string(key)]

      cond do
        unsafe_projected_context_key?(normalized_key) -> nested_path
        true -> find_unsafe_projected_context_path(nested, nested_path)
      end
    end)
  end

  defp find_unsafe_projected_context_path(value, path) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.find_value(fn {nested, index} ->
      find_unsafe_projected_context_path(nested, path ++ ["[#{index}]"])
    end)
  end

  defp find_unsafe_projected_context_path(_value, _path), do: nil

  defp normalize_projected_context_key(key) do
    key
    |> to_string()
    |> String.replace(~r/([a-z0-9])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/[^a-zA-Z0-9]+/, "_")
    |> String.trim("_")
    |> String.downcase()
  end

  defp unsafe_projected_context_key?(key) do
    key in [
      "transcript",
      "transcripts",
      "messages",
      "message_history",
      "history",
      "chat_history",
      "conversation_history",
      "provider_session",
      "provider_state",
      "runtime_state",
      "session",
      "session_state",
      "socket",
      "socket_state",
      "assigns",
      "private",
      "cookies",
      "headers",
      "secrets"
    ] or
      String.ends_with?(key, "_transcript") or
      String.ends_with?(key, "_history") or
      String.ends_with?(key, "_messages") or
      String.ends_with?(key, "_cookies") or
      String.ends_with?(key, "_headers") or
      String.ends_with?(key, "_secrets") or
      String.starts_with?(key, "provider_session_") or
      String.ends_with?(key, "_provider_session") or
      String.starts_with?(key, "socket_") or
      String.ends_with?(key, "_socket")
  end

  defp canonical_value(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp canonical_value(_attrs, _key), do: nil
end
