defmodule Scoria.KnowledgeCase do
  @moduledoc """
  Shared test case for vector-backed knowledge tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :knowledge

      alias Scoria.Repo
      import Ecto.Query
      import Scoria.KnowledgeCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    end

    Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()
    :ok
  end
end
