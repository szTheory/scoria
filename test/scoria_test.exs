defmodule ScoriaTest do
  use ExUnit.Case
  doctest Scoria

  test "normalizes canonical identity input" do
    identity = Scoria.identity(%{actor_id: "user_123", tenant_id: "tenant_456"})

    assert identity.actor_id == "user_123"
    assert identity.tenant_id == "tenant_456"
    assert identity.session_id == nil
    assert identity.metadata == %{}
  end

  test "exports the canonical public runtime facade" do
    assert function_exported?(Scoria, :start_run, 2)
    assert function_exported?(Scoria, :resume_run, 2)
    assert function_exported?(Scoria, :get_run, 1)
    assert function_exported?(Scoria, :get_run_detail, 1)
    assert function_exported?(Scoria, :list_runs_for_session, 1)
  end
end
