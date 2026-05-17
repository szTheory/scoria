defmodule Scoria.IdentityTest do
  use ExUnit.Case, async: true

  alias Scoria.Identity

  test "normalizes canonical and legacy loose identity attrs" do
    identity =
      Identity.normalize(%{
        "tenant_id" => "tenant-1",
        actor_id: "actor-1",
        session: "session-1",
        metadata: %{"source" => "legacy"}
      })

    assert identity == %Identity{
             actor_id: "actor-1",
             tenant_id: "tenant-1",
             session_id: "session-1",
             metadata: %{"source" => "legacy"}
           }
  end

  test "normalizes top-level actor tenant and session sugar" do
    identity =
      Identity.new(%{
        actor: %{id: "actor-2"},
        tenant: "tenant-2",
        session: %{id: "session-2"}
      })

    assert identity.actor_id == "actor-2"
    assert identity.tenant_id == "tenant-2"
    assert identity.session_id == "session-2"
  end

  test "normalizes plug assigns into the canonical envelope" do
    identity =
      Identity.from_conn_assigns(%{
        current_actor: %{id: "actor-3"},
        current_tenant: %{id: "tenant-3"},
        session_id: "session-3"
      })

    assert identity.actor_id == "actor-3"
    assert identity.tenant_id == "tenant-3"
    assert identity.session_id == "session-3"
  end

  test "normalizes liveview session maps into the canonical envelope" do
    identity =
      Identity.from_session(%{
        "actor_id" => "actor-4",
        "tenant_id" => "tenant-4",
        "session_id" => "session-4"
      })

    assert identity.actor_id == "actor-4"
    assert identity.tenant_id == "tenant-4"
    assert identity.session_id == "session-4"
  end

  test "normalizes on-mount extracted attrs into the canonical envelope" do
    identity =
      Identity.from_mount(%{
        actor_id: "actor-5",
        tenant_id: "tenant-5",
        session_id: "session-5"
      })

    assert Identity.to_map(identity) == %{
             actor_id: "actor-5",
             tenant_id: "tenant-5",
             session_id: "session-5",
             metadata: %{}
           }
  end
end
