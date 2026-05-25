defmodule Scoria.Connectors.GrantRefresh do
  @moduledoc """
  Lightweight post-auth hook placeholder for connector grant refresh work.
  """

  def enqueue_post_auth(_connector, _grant, _attrs \\ []) do
    {:ok, %{status: :queued}}
  end
end
