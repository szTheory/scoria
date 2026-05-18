# Phase 22: Curated Connector Profiles and Boring Adoption Path - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/connectors/profiles.ex` | config | transform | `lib/scoria/connectors/params.ex` | exact |
| `lib/scoria/connectors.ex` | context | CRUD | `lib/scoria/connectors.ex` (existing) | exact |
| `lib/mix/tasks/test.adoption.ex` | test runner | verification | `lib/mix/tasks/test.adoption.ex` (existing) | exact |
| `test/scoria/connectors/profiles_test.exs` | test | verification | `test/scoria/connectors_test.exs` | exact |
| `docs/operator_verification.md` | documentation | docs | `docs/operator_verification.md` (existing) | exact |

## Pattern Assignments

### `lib/scoria/connectors/profiles.ex` (config, transform)

**Analog:** `lib/scoria/connectors/params.ex`

**Module structure and defaults pattern** (lines 6-12):
```elixir
  @default_transport_kind "streamable_http"
  @default_auth_mode "oauth_pkce"
  @default_profile_defaults %{
    "generic" => %{},
    "stateless" => %{"transport_kind" => "streamable_http", "auth_mode" => "none"}
  }
```

**Data transformation / normalization pattern** (lines 107-116):
```elixir
  defp profile_defaults(profile) do
    profile_key = profile_key(profile)

    @default_profile_defaults
    |> Map.get(profile_key || "generic", %{})
    |> Map.merge(normalize_map(profile))
  end
```

---

### `lib/scoria/connectors.ex` (context, CRUD)

**Analog:** `lib/scoria/connectors.ex`

**Boundary function pattern with Ecto Multi** (lines 20-39):
```elixir
  def register_connector(attrs \\ %{}) do
    with {:ok, normalized} <- Params.register(attrs) do
      Multi.new()
      |> Multi.insert(
        :connector,
        Connector.changeset(%Connector{}, connector_insert_attrs(normalized))
      )
      |> Multi.run(:audit_outbox_event, fn repo, %{connector: connector} ->
        {:ok, SRE.insert_audit_outbox_event(repo, connector_registered_envelope(connector))}
      end)
      |> Discovery.enqueue_multi(:sync_job, :connector,
        trigger_cause: "registration",
        requester: requester(attrs)
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{connector: connector}} -> {:ok, preload_connector(connector)}
        {:error, _operation, value, _changes} -> {:error, value}
      end
    end
  end
```

---

### `lib/mix/tasks/test.adoption.ex` (test runner, verification)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Test runner pattern list addition** (lines 5-15):
```elixir
  @adoption_test_files [
    "test/scoria_test.exs",
    "test/scoria/identity_doctest_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/phoenix_example_source_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/mix/tasks/scoria.install_test.exs",
    "test/mix/tasks/scoria.install_route_smoke_test.exs",
    "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
    # Will add remote connector profile proof test here
  ]
```

---

### `test/scoria/connectors/profiles_test.exs` (test, verification)

**Analog:** `test/scoria/connectors_test.exs`

**Test setup and execution pattern** (lines 20-37):
```elixir
  test "register_connector persists connector truth and enqueues explicit discovery work" do
    assert {:ok, connector} =
             Connectors.register_connector(%{
               tenant_id: "tenant-register",
               key: "github",
               label: "GitHub",
               endpoint_url: "https://api.github.example/mcp",
               transport_kind: "streamable_http",
               auth_mode: "oauth_pkce",
               discovery_metadata_url:
                 "https://api.github.example/.well-known/oauth-authorization-server",
               metadata: %{
                 "catalog" => %{"tools" => [%{"name" => "issues.list"}]},
                 "catalog_version" => "v2026-05-17"
               }
             })

    assert connector.key == "github"
    assert connector.status == "registered"
    assert connector.last_refresh_status == "pending"

    assert_enqueued(
      worker: Scoria.Connectors.DiscoveryJob,
      queue: :connector_sync,
      args: %{"connector_id" => connector.id, "trigger_cause" => "registration"}
    )
  end
```

---

## Shared Patterns

### Durable Config / Metadata Updates
**Source:** `lib/scoria/connectors/params.ex`
**Apply to:** Normalization inside `Profiles.ex`.
```elixir
  defp normalized_metadata(attrs, profile) do
    attrs
    |> canonical_value(:metadata)
    |> normalize_map()
    |> stringify_nested_keys()
    |> maybe_put_profile_key(profile)
    |> maybe_put_tenant_scope(attrs, profile)
  end
```

### Repo-Native Subordination / Single Truth
**Source:** `lib/scoria/connectors.ex`
**Apply to:** All updates to `Connectors.ex` handling profiles. Ensure the profile logic feeds into `register_connector` attrs, not bypassing the durable Ecto truth.

## No Analog Found

All necessary files had direct analogs within the context boundary.

## Metadata

**Analog search scope:** `lib/`, `test/`, `docs/`
**Files scanned:** ~10 relevant context files
**Pattern extraction date:** 2026-05-18
