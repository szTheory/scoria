defmodule Scoria.Runtime.Params do
  @moduledoc """
  Normalizes public runtime inputs into explicit start and resume contracts.
  """

  alias Scoria.{Identity, Runtime.Defaults}

  @dispatch_keys ~w(dispatch handlers timeout budget_context breaker_context)a
  def start(identity, opts \\ []) do
    opts = normalize_map(opts)
    runtime = nested_map(opts, :runtime)
    dispatch = dispatch_opts(opts)
    identity = Identity.normalize(identity)

    with {:ok, resolved_defaults} <- Defaults.resolve(identity, opts) do
      workflow_attrs =
        %{
          root_role_id: value(opts, runtime, :root_role_id) || "executor",
          actor_id: identity.actor_id,
          tenant_id: identity.tenant_id,
          session_id: identity.session_id,
          metadata: start_metadata(opts, runtime, identity, resolved_defaults)
        }
        |> maybe_put_initial_step(initial_step(opts, runtime))

      {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch}}
    end
  end

  def resume(run_id, opts \\ [])

  def resume(run_id, opts) when is_binary(run_id) and run_id != "" do
    opts = normalize_map(opts)
    {:ok, dispatch_opts(opts)}
  end

  def resume(_run_id, _opts), do: {:error, :invalid_run_id}

  defp dispatch_opts(opts) do
    Enum.reduce(@dispatch_keys, [], fn key, acc ->
      case canonical_value(opts, key) do
        nil -> acc
        value -> Keyword.put(acc, key, value)
      end
    end)
  end

  defp start_metadata(opts, runtime, identity, resolved_defaults) do
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

    metadata
    |> maybe_put_payload(payload)
    |> maybe_put_identity_metadata(identity)
    |> Map.put("runtime", Defaults.to_metadata(resolved_defaults))
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

  defp canonical_value(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp canonical_value(_attrs, _key), do: nil
end
