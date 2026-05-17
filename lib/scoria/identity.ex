defmodule Scoria.Identity do
  @moduledoc """
  Canonical runtime identity envelope and Phoenix-edge adapters.

  Use this module where request assigns, session values, or mount params cross
  into Scoria's runtime boundary. It normalizes those host-owned inputs into the
  public identity shape used by `Scoria.start_run/2`.

  `actor_id` and `tenant_id` identify who is acting and for whom. `session_id`
  is the host-owned continuity key that groups related turns. It is not a
  substitute for Scoria's durable `run_id`, which identifies one exact run for
  resume and operator evidence.

  `from_conn_assigns/1`, `from_session/1`, and `from_mount/1` exist so Phoenix
  apps can normalize edge state before they call the public runtime facade.

  ## Examples

      iex> identity =
      ...>   Scoria.Identity.from_session(%{
      ...>     "actor_id" => "actor-1",
      ...>     "tenant_id" => "tenant-1",
      ...>     "session_id" => "session-1"
      ...>   })
      iex> Scoria.Identity.to_map(identity)
      %{actor_id: "actor-1", tenant_id: "tenant-1", session_id: "session-1", metadata: %{}}

      iex> normalized =
      ...>   Scoria.Identity.normalize(%{
      ...>     actor: %{id: "actor-2"},
      ...>     tenant: %{id: "tenant-2"},
      ...>     session: %{id: "session-2"}
      ...>   })
      iex> {normalized.actor_id, normalized.tenant_id, normalized.session_id}
      {"actor-2", "tenant-2", "session-2"}
  """

  @enforce_keys [:metadata]
  defstruct actor_id: nil, tenant_id: nil, session_id: nil, metadata: %{}

  @type t :: %__MODULE__{
          actor_id: String.t() | nil,
          tenant_id: String.t() | nil,
          session_id: String.t() | nil,
          metadata: map()
        }

  @string_key_map %{
    "actor" => :actor,
    "actor_id" => :actor_id,
    "assigns" => :assigns,
    "current_actor" => :current_actor,
    "current_tenant" => :current_tenant,
    "id" => :id,
    "metadata" => :metadata,
    "mount" => :mount,
    "session" => :session,
    "session_id" => :session_id,
    "tenant" => :tenant,
    "tenant_id" => :tenant_id
  }

  def new(attrs \\ %{}), do: normalize(attrs)
  def from_conn_assigns(assigns), do: normalize(%{assigns: assigns})
  def from_session(session), do: normalize(%{session: session})
  def from_mount(attrs), do: normalize(%{mount: attrs})

  def normalize(%__MODULE__{} = identity),
    do: %__MODULE__{identity | metadata: normalize_metadata(identity.metadata)}

  def normalize(attrs) do
    attrs = normalize_map(attrs)
    actor = nested_value(attrs, :actor)
    tenant = nested_value(attrs, :tenant)
    session = nested_value(attrs, :session)
    assigns = nested_map(attrs, :assigns)
    session_map = nested_map(attrs, :session)
    mount_map = nested_map(attrs, :mount)
    metadata = metadata(attrs)

    %__MODULE__{
      actor_id:
        canonical_value(attrs, :actor_id) ||
          id_from(actor) ||
          assigns_value(assigns, :current_actor) ||
          assigns_value(assigns, :actor) ||
          canonical_value(session_map, :actor_id) ||
          canonical_value(mount_map, :actor_id),
      tenant_id:
        canonical_value(attrs, :tenant_id) ||
          id_from(tenant) ||
          assigns_value(assigns, :current_tenant) ||
          assigns_value(assigns, :tenant) ||
          canonical_value(session_map, :tenant_id) ||
          canonical_value(mount_map, :tenant_id),
      session_id:
        canonical_value(attrs, :session_id) ||
          id_from(session) ||
          canonical_value(assigns, :session_id) ||
          canonical_value(session_map, :session_id) ||
          canonical_value(mount_map, :session_id),
      metadata: metadata
    }
  end

  def to_map(%__MODULE__{} = identity) do
    %{
      actor_id: identity.actor_id,
      tenant_id: identity.tenant_id,
      session_id: identity.session_id,
      metadata: identity.metadata
    }
  end

  def metadata(attrs) do
    attrs
    |> normalize_map()
    |> canonical_value(:metadata)
    |> normalize_metadata()
  end

  defp normalize_map(%__MODULE__{} = identity), do: to_map(identity)
  defp normalize_map(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_map()
  defp normalize_map(nil), do: %{}

  defp normalize_map(attrs) do
    Map.new(attrs, fn
      {key, value} when is_binary(key) -> {Map.get(@string_key_map, key, key), value}
      {key, value} -> {key, value}
    end)
  end

  defp nested_map(attrs, key) do
    attrs
    |> canonical_value(key)
    |> case do
      value when is_map(value) -> normalize_map(value)
      _ -> %{}
    end
  end

  defp nested_value(attrs, key), do: canonical_value(attrs, key)

  defp canonical_value(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp canonical_value(_attrs, _key), do: nil

  defp assigns_value(assigns, key) do
    assigns
    |> canonical_value(key)
    |> id_from()
  end

  defp id_from(nil), do: nil
  defp id_from(value) when is_binary(value), do: value
  defp id_from(value) when is_atom(value), do: Atom.to_string(value)

  defp id_from(value) when is_map(value) do
    canonical_value(normalize_map(value), :id)
  end

  defp id_from(_value), do: nil

  defp normalize_metadata(metadata) when is_map(metadata), do: metadata
  defp normalize_metadata(_metadata), do: %{}
end
