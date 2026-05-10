defmodule Scoria.EvalCase do
  @moduledoc """
  This module defines the test case to be used by
  evaluation tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Scoria.EvalCase
      import Tribunal
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    end

    :ok
  end
end
