defmodule Scoria.Connectors.AuthState do
  @moduledoc """
  Minimal PKCE-style state envelope for connector auth redirects.
  """

  def new(connector_id, attrs \\ %{}) do
    attrs = Map.new(attrs)
    verifier = Ecto.UUID.generate()

    %{
      "connector_id" => connector_id,
      "state" => Ecto.UUID.generate(),
      "code_verifier" => verifier,
      "code_challenge" => verifier,
      "trace_id" => Map.get(attrs, "trace_id") || Map.get(attrs, :trace_id) || "connector-auth-#{connector_id}",
      "actor_id" => Map.get(attrs, "actor_id") || Map.get(attrs, :actor_id) || "operator"
    }
  end
end
