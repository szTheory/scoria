defmodule ScoriaWeb.DashboardScope do
  @moduledoc """
  Host-asserted tenant scope for the embedded Scoria dashboard.

  The dashboard scope is resolved at the LiveView mount boundary. Host apps own
  authentication and authorization; Scoria normalizes the resulting tenant data
  and fails closed when no tenant is asserted.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias Phoenix.LiveView.Socket

  @unavailable_copy "This Scoria dashboard is not available for this session."
  @known_attr_keys %{
    "actor_id" => :actor_id,
    "display_tenant" => :display_tenant,
    "session_id" => :session_id,
    "tenant_id" => :tenant_id
  }
  @scope_keys [:tenant_id, :actor_id, :session_id, :display_tenant]

  defstruct [:tenant_id, :actor_id, :session_id, :display_tenant]

  @type t :: %__MODULE__{
          tenant_id: String.t(),
          actor_id: String.t() | nil,
          session_id: String.t() | nil,
          display_tenant: String.t() | nil
        }

  defmodule Resolver do
    @moduledoc """
    Resolver contract for host-owned Scoria dashboard scope.

    A resolver receives public LiveView params, private session data, and the
    current socket. Params may be used as hints by host code, but Scoria's
    default resolver ignores params as tenant authority.
    """

    @callback resolve(map(), map(), Socket.t()) ::
                {:ok, ScoriaWeb.DashboardScope.t() | map() | keyword()}
                | {:error, :unauthorized | :missing_scope}
                | {:redirect, String.t()}
                | {:halt, Socket.t()}
  end

  defmodule InvalidReturnError do
    defexception [:message]
  end

  @doc "Normalize explicit dashboard scope attrs into a struct or raise."
  def new!(%__MODULE__{} = scope), do: validate!(scope)

  def new!(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)

    %__MODULE__{
      tenant_id: required_id!(Map.get(attrs, :tenant_id), :tenant_id),
      actor_id: optional_id(Map.get(attrs, :actor_id)),
      session_id: optional_id(Map.get(attrs, :session_id)),
      display_tenant: optional_label(Map.get(attrs, :display_tenant))
    }
    |> validate!()
  end

  @doc "Normalize the default host session keys into dashboard scope."
  def from_session(session) when is_map(session) or is_list(session) do
    session
    |> normalize_attrs()
    |> Map.take(@scope_keys)
    |> new!()
  end

  @doc """
  Resolve dashboard scope from the default resolver, resolver module, or MFA tuple.
  """
  def resolve(:default, _params, session, %Socket{} = socket) do
    attrs =
      socket.assigns
      |> normalize_attrs()
      |> Map.take(@scope_keys)
      |> Map.merge(session |> normalize_attrs() |> Map.take(@scope_keys))

    {:ok, new!(attrs)}
  rescue
    ArgumentError -> {:error, :missing_scope}
  end

  def resolve(resolver, params, session, %Socket{} = socket) when is_atom(resolver) do
    resolver
    |> apply(:resolve, [params, session, socket])
    |> normalize_resolver_return(resolver)
  end

  def resolve(
        {resolver, function, extra_args} = resolver_form,
        params,
        session,
        %Socket{} = socket
      )
      when is_atom(resolver) and is_atom(function) and is_list(extra_args) do
    resolver
    |> apply(function, [params, session, socket | extra_args])
    |> normalize_resolver_return(resolver_form)
  end

  @doc false
  def on_mount(resolver, params, session, %Socket{} = socket) do
    case resolve(resolver, params, session, socket) do
      {:ok, %__MODULE__{} = scope} ->
        {:cont, assign_scope(socket, scope)}

      {:error, reason} when reason in [:unauthorized, :missing_scope] ->
        {:halt, put_unavailable_flash(socket)}

      {:redirect, to} when is_binary(to) ->
        {:halt, redirect(socket, to: to)}

      {:halt, %Socket{} = socket} ->
        {:halt, socket}
    end
  end

  defp normalize_resolver_return({:ok, scope}, _resolver), do: {:ok, new!(scope)}

  defp normalize_resolver_return({:error, reason}, _resolver)
       when reason in [:unauthorized, :missing_scope],
       do: {:error, reason}

  defp normalize_resolver_return({:redirect, to}, _resolver) when is_binary(to),
    do: {:redirect, to}

  defp normalize_resolver_return({:halt, %Socket{} = socket}, _resolver), do: {:halt, socket}

  defp normalize_resolver_return(other, resolver) do
    raise InvalidReturnError,
      message:
        "invalid dashboard scope resolver return from #{inspect(resolver)}: #{inspect(other)}"
  end

  defp assign_scope(socket, %__MODULE__{} = scope) do
    socket
    |> assign(:scoria_scope, scope)
    |> assign(:tenant_id, scope.tenant_id)
    |> maybe_assign(:actor_id, scope.actor_id)
    |> maybe_assign(:session_id, scope.session_id)
  end

  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, value), do: assign(socket, key, value)

  defp put_unavailable_flash(socket) do
    socket
    |> ensure_flash()
    |> put_flash(:error, @unavailable_copy)
  end

  defp ensure_flash(%Socket{} = socket) do
    if Map.has_key?(socket.assigns, :flash) do
      socket
    else
      assign(socket, :flash, %{})
    end
  end

  defp validate!(%__MODULE__{} = scope) do
    %__MODULE__{
      tenant_id: required_id!(scope.tenant_id, :tenant_id),
      actor_id: optional_id(scope.actor_id),
      session_id: optional_id(scope.session_id),
      display_tenant: optional_label(scope.display_tenant)
    }
  end

  defp normalize_attrs(nil), do: %{}
  defp normalize_attrs(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_list(attrs),
    do: attrs |> Enum.into(%{}) |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &normalize_pair/1)

  defp normalize_pair({key, value}) when is_binary(key),
    do: {Map.get(@known_attr_keys, key, key), value}

  defp normalize_pair({key, value}), do: {key, value}

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

  defp optional_label(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      label -> label
    end
  end

  defp optional_label(nil), do: nil

  defp optional_label(value) do
    raise ArgumentError, "display_tenant must be a string, got: #{inspect(value)}"
  end
end
