# Phase 46: Terminology and public vocabulary migration - Pattern Map

**Mapped:** 2026-07-09
**Files analyzed:** 59
**Analogs found:** 55 / 59

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `docs/glossary.md` | documentation | transform/reference | `docs/connector_adoption.md` + README docs list | partial |
| `README.md` | documentation | transform | `README.md` current docs/install sections | exact |
| `CHANGELOG.md` | documentation | transform | `CHANGELOG.md` release headings | exact |
| `mix.exs` | config | transform/package I/O | `mix.exs` docs/package lists | exact |
| `lib/mix/tasks/scoria.release_preview.ex` | utility | file-I/O/batch | `lib/mix/tasks/scoria.release_preview.ex` required path list | exact |
| `docs/adoption_lanes.md` | documentation | transform | `docs/adoption_lanes.md` current capability guide | exact |
| `docs/bounded_handoffs.md` | documentation | transform | `docs/bounded_handoffs.md` current handoff guide | exact |
| `docs/operator_verification.md` | documentation | transform | `docs/operator_verification.md` verification guide | exact |
| `docs/phoenix_runtime_example.md` | documentation | transform | `test/scoria/phoenix_example_source_test.exs` source-contract pattern | role-match |
| `docs/semantic_fast_path.md` | documentation | transform | `docs/semantic_fast_path.md` semantic guide | exact |
| `docs/connector_adoption.md` | documentation | transform | `docs/connector_adoption.md` short guide shape | exact |
| `docs/support_copilot_gallery.md` | documentation | transform | `docs/support_copilot_gallery.md` journey guide shape | exact |
| `docs/MAINTAINERS.md` | documentation | transform | `docs/operator_verification.md` lane-reference pattern | role-match |
| `lib/scoria.ex` | service/facade | request-response | `lib/scoria.ex` public facade docs | exact |
| `lib/scoria/runtime/params.ex` | utility | transform/request-response | `lib/scoria/runtime/params.ex` option normalization | exact |
| `lib/scoria/semantic_cache/profile.ex` | public behavior | transform | `lib/scoria/semantic_lane.ex` behavior/macro | exact |
| `lib/scoria/semantic_lane.ex` | compatibility wrapper/public behavior | transform | `lib/scoria/semantic_lane.ex` current public behavior | role-match |
| `lib/scoria/semantic_cache.ex` | service | CRUD/transform | `lib/scoria/semantic_cache.ex` normalized attrs + storage fields | exact |
| `lib/scoria/semantic_cache/entry.ex` | model | CRUD | `lib/scoria/semantic_cache/entry.ex` Ecto schema | exact |
| `lib/scoria/verification_suites.ex` | utility/config | transform | `lib/scoria/verification_lanes.ex` command SSOT | exact |
| `lib/scoria/verification_lanes.ex` | compatibility wrapper | transform | `lib/scoria/verification_lanes.ex` current command SSOT | role-match |
| `lib/scoria/observe/reviewer_broadcast.ex` | service | event-driven/pub-sub | `lib/scoria/observe/operator_broadcast.ex` | exact |
| `lib/scoria/observe/operator_broadcast.ex` | compatibility wrapper/service | event-driven/pub-sub | `lib/scoria/observe/operator_broadcast.ex` | role-match |
| `lib/scoria/workflows.ex` | service | event-driven/CRUD | `lib/scoria/observe/operator_broadcast.ex` + existing call sites | role-match |
| `lib/scoria/observe/telemetry.ex` | service | streaming/event-driven | `lib/scoria/observe/operator_broadcast.ex` | role-match |
| `lib/scoria_web/reviewer_surface.ex` | service/read model | request-response/CRUD | `lib/scoria_web/operator_surface.ex` | exact |
| `lib/scoria_web/operator_surface.ex` | compatibility wrapper/read model | request-response/CRUD | `lib/scoria_web/operator_surface.ex` | role-match |
| `lib/scoria_web/live/orchestrator_live.ex` | component/liveview | event-driven/request-response | `lib/scoria_web/live/workflow_live/show.ex` alias/read model usage | role-match |
| `lib/scoria_web/live/workflow_live/index.ex` | component/liveview | request-response | `lib/scoria_web/live/workflow_live/show.ex` alias/read model usage | role-match |
| `lib/scoria_web/live/workflow_live/show.ex` | component/liveview | event-driven/request-response | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/live/connectors_live/index.ex` | component/liveview | request-response | `lib/scoria_web/operator_surface.ex` read model usage | role-match |
| `lib/scoria_web/live/incidents_live/index.ex` | component/liveview | request-response | `lib/scoria_web/operator_surface.ex` incident reads | role-match |
| `lib/scoria_web/live/incidents_live/show.ex` | component/liveview | request-response | `lib/scoria_web/operator_surface.ex` incident reads | role-match |
| `lib/scoria_web/live/dataset_live/index.ex` | component/liveview | request-response | `lib/scoria_web/operator_surface.ex` run detail read | role-match |
| `lib/scoria_web/components/delegated_trace_component.ex` | component | request-response/render | `lib/scoria_web/components/delegated_evidence_component.ex` | exact |
| `lib/scoria_web/components/replay_trace_notebook_component.ex` | component | request-response/render | `lib/scoria_web/components/replay_evidence_notebook_component.ex` | exact |
| `lib/scoria_web/components/semantic_cache_trace_notebook_component.ex` | component | request-response/render | `lib/scoria_web/components/semantic_evidence_notebook_component.ex` | exact |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | component | request-response/render | same file | exact |
| `lib/scoria_web/components/incident_evidence_component.ex` | component | request-response/render | same file | exact |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | component | request-response/render | same file | exact |
| `test/scoria/terminology_contract_test.exs` | test | transform/file-I/O | `test/scoria/adoption_surface_test.exs` + `test/scoria/scope_doctrine_contract_test.exs` | exact |
| `test/scoria/no_schema_rename_contract_test.exs` | test | file-I/O/transform | `test/scoria/scope_doctrine_contract_test.exs` source-scan guard | role-match |
| `test/scoria/package_surface_test.exs` | test | file-I/O/package | same file | exact |
| `test/scoria/adoption_surface_test.exs` | test | file-I/O/transform | same file | exact |
| `test/scoria/changelog_contract_test.exs` | test | file-I/O/transform | same file | exact |
| `test/scoria/hex_consumer_contract_test.exs` | test | file-I/O/package | same file | exact |
| `test/scoria/verification_suites_test.exs` | test | transform | `test/scoria/verification_lanes_test.exs` | exact |
| `test/scoria/verification_lanes_test.exs` | test | transform | same file compatibility assertions | exact |
| `test/scoria/semantic_cache/profile_test.exs` | test | request-response/transform | `test/scoria/semantic_cache/lane_test.exs` | exact |
| `test/scoria/semantic_cache/lane_test.exs` | test | request-response/transform | same file compatibility assertions | exact |
| `test/scoria/observe/reviewer_broadcast_test.exs` | test | event-driven/pub-sub | `test/scoria/observe/operator_broadcast_test.exs` | exact |
| `test/scoria/observe/operator_broadcast_test.exs` | test | event-driven/pub-sub | same file compatibility assertions | exact |
| `test/scoria_web/components/semantic_cache_trace_notebook_component_test.exs` | test | request-response/render | `test/scoria_web/components/semantic_evidence_notebook_component_test.exs` | exact |
| `test/scoria_web/components/semantic_evidence_notebook_component_test.exs` | test | request-response/render | same file compatibility/source guard | exact |
| `test/scoria_web/components/incident_evidence_component_test.exs` | test | request-response/render | same file | exact |
| `test/scoria_web/live/workflow_live_test.exs` | test | event-driven/request-response | same file | exact |
| `test/scoria/semantic_fast_path_example_source_test.exs` | test | file-I/O/transform | same file | exact |
| `test/scoria/phoenix_example_source_test.exs` | test | file-I/O/transform | same file | exact |
| `test/scoria/ci_policy_contract_test.exs` | test | file-I/O/transform | `test/scoria/verification_lanes_test.exs` command SSOT assertions | role-match |
| `test/scoria/knowledge_lane_contract_test.exs` | test | file-I/O/transform | `test/scoria/verification_lanes_test.exs` command SSOT assertions | role-match |

## Pattern Assignments

### `docs/glossary.md` (documentation, transform/reference)

**Analog:** `docs/connector_adoption.md` for compact guide structure; `README.md` and `mix.exs` for discoverability wiring.

**Markdown guide shape** (`docs/connector_adoption.md` lines 1-10):
```markdown
# Remote connector adoption

Scoria registers **remote MCP connectors** inside your Phoenix app. Scoria owns discovery, auth storage, tool policy, approvals, and audit evidence - not a hosted connector platform.

## When to use connectors

Use remote connectors after the **default runtime lane** is green (`mix test.adoption`). Connectors add optional tool surfaces; they do not replace core runtime, identity, or approval contracts.

Skip connectors on first adoption if you only need durable runs, operator evidence, and bounded handoff.
```

**Table pattern** (`docs/connector_adoption.md` lines 11-19):
```markdown
## Embedded boundary

| Your app owns | Scoria owns |
|---------------|-------------|
| Host routing, session, and tenant identity | Connector records, grants, and health state |
| When to escalate to human review | Tool policy, approval gates, and invocation audit |
| Business-specific tool allowlists | Curated connector profiles and boring install defaults |
```

**Apply:** Use compact reference entries for each required term: Scoria term, short definition, industry equivalent/adjacent term, use when, do not use when, related APIs/docs. Add a legacy-terms table. Do not move guide folders in this phase.

---

### `README.md`, `docs/*.md`, `CHANGELOG.md` (documentation, transform)

**Analog:** Current README/docs structure and changelog release headings.

**README docs list pattern** (`README.md` lines 44-52):
```markdown
Docs:

- [Lane selection guide](docs/adoption_lanes.md)
- [Phoenix runtime example](docs/phoenix_runtime_example.md)
- [Bounded handoffs](docs/bounded_handoffs.md)
- [Semantic fast path](docs/semantic_fast_path.md)
- [Operator verification](docs/operator_verification.md)
- [Remote connector adoption](docs/connector_adoption.md)
- [Support copilot gallery](docs/support_copilot_gallery.md) - clone repo for `examples/support_copilot`
```

**README install/upgrade placement** (`README.md` lines 54-79):
````markdown
## Install

Add Scoria from Hex, then mount the dashboard and run the installer:

```elixir
def deps do
  [
    {:scoria, "~> 0.1", hex: :scoria}
    # Fork or pinned patch only: {:scoria, github: "szTheory/scoria", tag: "v0.1.1"}
  ]
end
```

Tagged GitHub installs are for forks and pinned patches; prefer Hex for normal adoption.

**Next steps:** `mix deps.get` -> `mix scoria.install` -> `mix ecto.migrate` - then see [Verification](#verification) for `mix test.adoption`.

### Upgrading or re-running install
````

**Changelog heading pattern** (`CHANGELOG.md` lines 1-14 and 332-349):
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

## [0.1.2](https://github.com/szTheory/scoria/compare/v0.1.1...v0.1.2) (2026-06-19)
...
## [Unreleased]

## [0.1.0]
```

**Apply:**
- Add/merge one top `## [Unreleased]` before `## [0.1.2]`; current file already has a late duplicate at line 332, so planner should consolidate, not add a third heading.
- Put "Pre-1.0 terminology migration" under `### Changed`.
- Do not rewrite historical release entries unless they are current upgrade guidance.
- Rename current public docs copy sense-aware: reviewer, trace, capabilities, verification suite, scoped context, semantic cache, knowledge base.
- Preserve RAG/citation/grounding evidence wording where it means proof material.

---

### `mix.exs`, `lib/mix/tasks/scoria.release_preview.ex`, package/docs tests (config, file-I/O)

**Analog:** `mix.exs`, `test/scoria/package_surface_test.exs`, `lib/mix/tasks/scoria.release_preview.ex`.

**ExDoc extras pattern** (`mix.exs` lines 123-140):
```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    extras: [
      "README.md",
      "LICENSE",
      "CHANGELOG.md",
      "docs/adoption_lanes.md",
      "docs/phoenix_runtime_example.md",
      "docs/bounded_handoffs.md",
      "docs/semantic_fast_path.md",
      "docs/operator_verification.md",
      "docs/connector_adoption.md",
      "docs/support_copilot_gallery.md",
      "docs/MAINTAINERS.md"
    ]
  ]
end
```

**Package files pattern** (`mix.exs` lines 143-179):
```elixir
defp package do
  [
    name: "scoria",
    files: [
      "lib",
      "priv/fixtures",
      "priv/host_app_proof",
      "priv/repo/migrations",
      "priv/repo/knowledge_migrations",
      "priv/static",
      "mix.exs",
      ".formatter.exs",
      "CHANGELOG.md",
      "README.md",
      "LICENSE",
      "docs/adoption_lanes.md",
      "docs/phoenix_runtime_example.md",
      "docs/bounded_handoffs.md",
      "docs/semantic_fast_path.md",
      "docs/operator_verification.md",
      "docs/connector_adoption.md",
      "docs/support_copilot_gallery.md",
      "docs/MAINTAINERS.md"
    ],
```

**Package test pattern** (`test/scoria/package_surface_test.exs` lines 6-18, 19-34, 36-53, 91-98):
```elixir
@docs_extras [
  "README.md",
  "LICENSE",
  "CHANGELOG.md",
  "docs/adoption_lanes.md",
  "docs/phoenix_runtime_example.md",
  "docs/bounded_handoffs.md",
  "docs/semantic_fast_path.md",
  "docs/operator_verification.md",
  "docs/connector_adoption.md",
  "docs/support_copilot_gallery.md",
  "docs/MAINTAINERS.md"
]

@required_package_paths [
  "README.md",
  "LICENSE",
  "mix.exs",
  "lib/scoria.ex",
  "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
  "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
  "docs/adoption_lanes.md",
  ...
]

test "docs extras stay explicit and ordered" do
  project = Mix.Project.config()
  assert project[:docs][:extras] == @docs_extras
end

test "hex preview includes the required release surface" do
  unpack_root = HexConsumerContract.ensure_current_unpack_root!()

  for relative_path <- @required_package_paths do
    assert File.exists?(Path.join(unpack_root, relative_path)),
           "expected #{relative_path} to exist in unpacked artifact"
  end
end
```

**Release-preview path pattern** (`lib/mix/tasks/scoria.release_preview.ex` lines 5-20):
```elixir
@required_package_paths [
  "README.md",
  "LICENSE",
  "mix.exs",
  "lib/scoria.ex",
  "priv/repo/migrations/20260511000100_create_workflow_tables.exs",
  "priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs",
  "docs/adoption_lanes.md",
  "docs/phoenix_runtime_example.md",
  "docs/bounded_handoffs.md",
  "docs/semantic_fast_path.md",
  "docs/operator_verification.md"
]

def required_package_paths, do: @required_package_paths
```

**Apply:** Add `docs/glossary.md` consistently to `mix.exs` docs extras, package files, package tests, README docs list, and release-preview required paths if the release-preview proof is meant to assert glossary packaging.

---

### `lib/scoria/verification_suites.ex` and `lib/scoria/verification_lanes.ex` (utility/config, transform)

**Analog:** `lib/scoria/verification_lanes.ex`.

**Imports/module docs pattern** (`lib/scoria/verification_lanes.ex` lines 1-7):
```elixir
defmodule Scoria.VerificationLanes do
  @moduledoc """
  Canonical verification lane contract for adopter-facing and maintainer-facing proofs.

  Each lane maps one command contract to its environment, prerequisites, and explicit
  exclusions so docs, tests, and CI can share one source of truth.
  """
```

**Single source of truth list pattern** (`lib/scoria/verification_lanes.ex` lines 16-83):
```elixir
@lanes [
  %{
    id: :release_preview,
    name: "Release preview lane",
    command: "mix scoria.release_preview",
    ci_command: "MIX_ENV=dev mix scoria.release_preview",
    env: :dev,
    prerequisites: [],
    exclusions: []
  },
  %{
    id: :adoption,
    name: "Default runtime lane",
    command: "mix test.adoption",
    ci_command: "mix test.adoption",
    env: :test,
    prerequisites: ["mix scoria.install", "mix ecto.migrate"],
    exclusions: @no_optional_setup_exclusions
  }
]
@lane_by_id Map.new(@lanes, &{&1.id, &1})
@closeout_order [:release_preview, :adoption, :runtime_to_handoff]
```

**Public function pattern** (`lib/scoria/verification_lanes.ex` lines 85-126):
```elixir
def all, do: @lanes
def ids, do: Enum.map(@lanes, & &1.id)
def fetch!(id), do: Map.fetch!(@lane_by_id, id)
def command(id), do: fetch!(id).command
def ci_command(id), do: fetch!(id).ci_command
def env(id), do: fetch!(id).env
def prerequisites(id), do: fetch!(id).prerequisites
def exclusions(id), do: fetch!(id).exclusions
def closeout_order, do: @closeout_order

def closeout_chain do
  @closeout_order
  |> Enum.map(&command/1)
  |> Enum.join("\n")
end
```

**Test pattern** (`test/scoria/verification_lanes_test.exs` lines 6-28 and 30-44):
```elixir
test "lane contract defines command, env, prerequisites, and exclusions for every lane" do
  lane_ids = VerificationLanes.ids()

  assert lane_ids == [
           :release_preview,
           :adoption,
           :runtime_to_handoff,
           :semantic_fast_path,
           :knowledge,
           :connector,
           :support_copilot_gallery
         ]

  for lane <- VerificationLanes.all() do
    assert is_atom(lane.id)
    assert is_binary(lane.name)
    assert is_binary(lane.command)
    assert is_binary(lane.ci_command)
    assert lane.env in [:dev, :test]
    assert is_list(lane.prerequisites)
    assert is_list(lane.exclusions)
  end
end

test "closeout chain stays pinned to release-preview, adoption, and runtime-to-handoff" do
  assert VerificationLanes.closeout_order() == [
           :release_preview,
           :adoption,
           :runtime_to_handoff
         ]
end
```

**Apply:**
- Make `Scoria.VerificationSuites` the final public SSOT. Use "suite" in moduledoc and public names, but preserve ids/commands unless explicitly changing command names.
- Keep `Scoria.VerificationLanes` as a soft compatibility wrapper during `0.1.x`. No exact wrapper analog exists in the repo; use `@moduledoc false` or a short legacy note and delegate all public functions to `Scoria.VerificationSuites`.
- Update public docs/tests to lead with `VerificationSuites`. Existing internal CI/tests can migrate to the new module to prevent stale public symbols from staying discoverable.

---

### `lib/scoria/semantic_cache/profile.ex`, `lib/scoria/semantic_lane.ex`, `lib/scoria/runtime/params.ex` (public behavior and option aliases)

**Analog:** `lib/scoria/semantic_lane.ex` and `lib/scoria/runtime/params.ex`.

**Behavior/macro pattern** (`lib/scoria/semantic_lane.ex` lines 1-38):
```elixir
defmodule Scoria.SemanticLane do
  @moduledoc """
  Public semantic-lane contract for explicit semantic-cache admission.
  """

  @type scope_kind :: :tenant_shared | :actor_scoped

  @callback lane_key() :: String.t()
  @callback default_scope() :: scope_kind()
  @callback safe_read_only?() :: boolean()
  @callback metadata() :: map()

  defmacro __using__(opts) do
    lane_key = Keyword.fetch!(opts, :lane_key)
    default_scope = Keyword.get(opts, :default_scope, :tenant_shared)
    safe_read_only = Keyword.get(opts, :safe_read_only, true)
    metadata = Keyword.get(opts, :metadata, %{})

    quote do
      @behaviour Scoria.SemanticLane

      @impl true
      def lane_key, do: unquote(lane_key)
      @impl true
      def default_scope, do: unquote(default_scope)
      @impl true
      def safe_read_only?, do: unquote(safe_read_only)
      @impl true
      def metadata, do: unquote(metadata_ast)
    end
  end
```

**Describe/validation pattern** (`lib/scoria/semantic_lane.ex` lines 41-86):
```elixir
def describe(module) when is_atom(module) do
  cond do
    not Code.ensure_loaded?(module) ->
      {:error, :invalid_semantic_cache_lane}

    not function_exported?(module, :lane_key, 0) ->
      {:error, :invalid_semantic_cache_lane}

    not function_exported?(module, :default_scope, 0) ->
      {:error, :invalid_semantic_cache_lane}

    not function_exported?(module, :safe_read_only?, 0) ->
      {:error, :invalid_semantic_cache_lane}

    true ->
      normalize_description(module)
  end
end

defp normalize_description(module) do
  with lane_key when is_binary(lane_key) and lane_key != "" <- module.lane_key(),
       scope when scope in [:tenant_shared, :actor_scoped] <- module.default_scope(),
       safe_read_only when is_boolean(safe_read_only) <- module.safe_read_only?() do
    {:ok,
     %{
       lane: module,
       lane_key: lane_key,
       lane_module: Atom.to_string(module),
       default_scope: scope,
       safe_read_only: safe_read_only,
       metadata: normalize_metadata(module_metadata(module))
     }}
  else
    _ -> {:error, :invalid_semantic_cache_lane}
  end
end
```

**Runtime option normalization pattern** (`lib/scoria/runtime/params.ex` lines 35-54, 63-69):
```elixir
def start_handoff(identity, delegated_role_id, opts)
    when is_binary(delegated_role_id) and delegated_role_id != "" do
  opts = normalize_map(opts)
  runtime = nested_map(opts, :runtime)

  with {:ok, root_role_id} <-
         required_string(opts, runtime, :root_role_id, :invalid_root_role_id),
       {:ok, delegated_kind} <-
         required_string(opts, runtime, :delegated_kind, :invalid_delegated_kind),
       {:ok, handoff_input} <-
         required_map(opts, runtime, :handoff_input, :invalid_handoff_input),
       {:ok, projected_context} <-
         required_map(opts, runtime, :projected_context, :invalid_projected_context),
       :ok <- validate_projected_context(projected_context) do
    handoff_attrs = %{
      "delegated_role_id" => delegated_role_id,
      "delegated_kind" => delegated_kind,
      "capability_tags" => capability_tags(opts, runtime),
      "handoff_input" => handoff_input,
      "projected_context" => projected_context
    }
```

**Semantic cache config pattern** (`lib/scoria/runtime/params.ex` lines 213-223):
```elixir
defp semantic_cache_config(opts, runtime) do
  case value(opts, runtime, :semantic_cache) do
    nil ->
      {:ok, nil}

    semantic_cache ->
      semantic_cache
      |> normalize_map()
      |> canonical_value(:lane)
      |> SemanticLane.describe()
  end
end
```

**Canonical atom/string key lookup pattern** (`lib/scoria/runtime/params.ex` lines 314-322):
```elixir
defp canonical_value(attrs, key) when is_map(attrs) do
  cond do
    Map.has_key?(attrs, key) -> Map.get(attrs, key)
    Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
    true -> nil
  end
end
```

**Apply:**
- Create `Scoria.SemanticCache.Profile` with the same behavior/macro/describe contract, but public docs and examples should use `use Scoria.SemanticCache.Profile, cache_key: "account_faq"`.
- Preserve accepted legacy aliases: `Scoria.SemanticLane`, `semantic_cache: [lane: OldModule]`, `lane_key`, and internal storage fields.
- Update `Runtime.Params.semantic_cache_config/2` to accept final `:profile` first, falling back to legacy `:lane`. Normalize both through the same describe path so validation is not bypassed.
- Add `scoped_context:` as a public alias for `projected_context:` in handoff options. Store and workflow DTO fields may remain `projected_context`.

---

### Storage-preservation files (models, migrations, no-schema guard)

**Analog:** `lib/scoria/semantic_cache.ex`, `lib/scoria/semantic_cache/entry.ex`, migration occurrences.

**Known attr normalization pattern** (`lib/scoria/semantic_cache.ex` lines 13-44):
```elixir
@known_attr_keys %{
  "actor_id" => :actor_id,
  "answer_payload" => :answer_payload,
  "evidence_refs" => :evidence_refs,
  "expires_at" => :expires_at,
  "hit_count" => :hit_count,
  "invalidated_at" => :invalidated_at,
  "lane_key" => :lane_key,
  "lane_module" => :lane_module,
  ...
  "workflow_run_id" => :workflow_run_id
}
```

**Persisted semantic-cache fields** (`lib/scoria/semantic_cache/entry.ex` lines 11-27 and 46-89):
```elixir
schema "ai_semantic_cache_entries" do
  field :tenant_id, :string
  field :actor_id, :string
  field :scope_kind, :string
  field :scope_reason, :string
  field :lane_key, :string
  field :lane_module, :string
  ...
  field :answer_payload, :map, default: %{}
  field :evidence_refs, :map, default: %{}
end

def changeset(entry, attrs) do
  entry
  |> cast(attrs, [
    :tenant_id,
    :actor_id,
    :scope_kind,
    :scope_reason,
    :lane_key,
    :lane_module,
    ...
    :evidence_refs,
    ...
  ])
  |> validate_required([
    :tenant_id,
    :scope_kind,
    :scope_reason,
    :lane_key,
    :query_text,
    :answer_payload,
    :status
  ])
end
```

**Current persisted fields to preserve** (grep results):
```text
priv/repo/migrations/20260511000100_create_workflow_tables.exs:37:      add :projected_context, :map, null: false, default: %{}
priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs:11:      add :lane_key, :string, null: false
priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs:21:      add :evidence_refs, :map, null: false, default: %{}
priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs:78:      add(:evidence_refs, :map, null: false, default: %{})
priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs:134:      add :evidence_refs, :map, null: false, default: %{}
```

**Source-scan test helper pattern** (`test/scoria/scope_doctrine_contract_test.exs` lines 72-100):
```elixir
test "phase 45 repaired code paths reject fake measurement leftovers" do
  pgvector = active_source(@pgvector)
  chunker = active_source(@chunker)
  eval_sources = @eval_paths |> Enum.map(&active_source/1) |> Enum.join("\n")

  assert pgvector =~ "not is_nil(chunk.embedding)"
  refute pgvector =~ "score_chunk"
  refute Regex.match?(~r/latency_ms"\s*=>\s*0\b/, eval_sources)
end

defp active_source(path) do
  path
  |> File.read!()
  |> String.split("\n")
  |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
  |> Enum.join("\n")
end
```

**Apply:** New terminology/no-schema contract should scan active sources and migrations for forbidden schema renames:
- `refute source =~ "trace_refs"`
- `assert source =~ "evidence_refs"` where relevant
- `assert source =~ "projected_context"` and/or no migration that replaces it with `scoped_context`
- `assert source =~ "lane_key"` and no migration replacing it with `cache_key`

---

### `lib/scoria/observe/reviewer_broadcast.ex`, `lib/scoria/observe/operator_broadcast.ex`, event call sites

**Analog:** `lib/scoria/observe/operator_broadcast.ex` and `test/scoria/observe/operator_broadcast_test.exs`.

**PubSub module pattern** (`lib/scoria/observe/operator_broadcast.ex` lines 1-24):
```elixir
defmodule Scoria.Observe.OperatorBroadcast do
  @moduledoc """
  Tenant-scoped PubSub fan-out for operator dashboard live events.

  Publishes incremental trace deltas to `scoria:runs:{tenant_id}`. Tracks seen
  `trace_id` values per BEAM node in ETS (`:scoria_observe_operator_broadcast_trace_seen`)
  so `{:trace_opened, _}` is emitted only on the first span stop for a trace on
  this node.

  Missing `tenant_id` drops broadcast (fail closed) with a debug log - no global
  topic fallback.
  """

  require Logger

  alias Scoria.Observe.TraceProjection

  @topic_prefix "scoria:runs:"
  @trace_seen_table :scoria_observe_operator_broadcast_trace_seen

  def tenant_topic(tenant_id), do: @topic_prefix <> tenant_id

  def broadcast(tenant_id, message) when is_binary(tenant_id) do
    Phoenix.PubSub.broadcast(Scoria.PubSub, tenant_topic(tenant_id), message)
  end
```

**Fail-closed event handling pattern** (`lib/scoria/observe/operator_broadcast.ex` lines 27-45 and 48-77):
```elixir
def span_stopped(metadata) when is_map(metadata) do
  case Map.get(metadata, :tenant_id) do
    tenant_id when is_binary(tenant_id) and tenant_id != "" ->
      trace_id = Map.get(metadata, :trace_id)

      if trace_id && first_span_for_trace?(trace_id) do
        broadcast(tenant_id, {:trace_opened, TraceProjection.trace_header(metadata)})
      end

      if trace_id do
        broadcast(tenant_id, {:trace_span, trace_id, TraceProjection.span_view(metadata)})
      end

      :ok

    _ ->
      Logger.debug("OperatorBroadcast.span_stopped/1 dropped: missing tenant_id")
      :dropped
  end
end

def span_delta(_metadata) do
  Logger.debug("OperatorBroadcast.span_delta/1 dropped: missing tenant_id")
  :dropped
end
```

**PubSub test setup pattern** (`test/scoria/observe/operator_broadcast_test.exs` lines 1-14 and 30-43):
```elixir
defmodule Scoria.Observe.OperatorBroadcastTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.OperatorBroadcast

  setup do
    OperatorBroadcast.reset_trace_seen!()
    tenant_id = "tenant-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(Scoria.PubSub, OperatorBroadcast.tenant_topic(tenant_id))

    on_exit(fn -> OperatorBroadcast.reset_trace_seen!() end)

    %{tenant_id: tenant_id}
  end

  test "first span emits trace_opened and trace_span", %{tenant_id: tenant_id} do
    trace_id = Ecto.UUID.generate()
    metadata = base_metadata(tenant_id, trace_id)

    assert :ok = OperatorBroadcast.span_stopped(metadata)

    assert_receive {:trace_opened, header}
    assert header.id == trace_id
    assert header.tenant_id == tenant_id
  end
```

**Apply:**
- New `ReviewerBroadcast` should own implementation. Old `OperatorBroadcast` should delegate for `0.1.x`.
- Update implementation call sites such as `lib/scoria/workflows.ex` and `lib/scoria/observe/telemetry.ex` to use `ReviewerBroadcast` unless the planner intentionally keeps internal references legacy-only.
- Keep topic strings stable unless changing them is explicitly required; no phase requirement asks for a PubSub topic migration.

---

### `lib/scoria_web/reviewer_surface.ex`, `lib/scoria_web/operator_surface.ex`, LiveView call sites

**Analog:** `lib/scoria_web/operator_surface.ex` and `lib/scoria_web/live/workflow_live/show.ex`.

**Read model import/alias pattern** (`lib/scoria_web/operator_surface.ex` lines 1-23):
```elixir
defmodule ScoriaWeb.OperatorSurface do
  @moduledoc """
  Read model shared by the operator dashboard pages (Live Ops, Approvals,
  Connectors, Incidents).

  Extracted from `ScoriaWeb.OrchestratorLive` so the slimmed Live Ops page and
  the routed `/connectors` / `/incidents` pages query the same projections
  instead of duplicating the fleet and SRE read logic. Functions are pure reads:
  they take a tenant/trace/run scope and return plain maps ready for rendering.
  """
  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Scoria.Connectors
  alias Scoria.Connectors.Connector
  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Run
```

**Tenant-scoped read/fallback pattern** (`lib/scoria_web/operator_surface.ex` lines 195-224):
```elixir
@doc "Recent workflow runs for a tenant, newest first - the /workflows list."
def list_tenant_runs(tenant_id) when is_binary(tenant_id) and tenant_id != "" do
  Run
  |> where([run], run.tenant_id == ^tenant_id)
  |> order_by([run], desc: run.inserted_at)
  |> limit(50)
  |> Repo.all()
rescue
  _error -> []
end

def list_tenant_runs(_tenant_id), do: []

@doc "Tenant-scoped workflow detail lookup for routed workflow pages."
def fetch_tenant_run_detail(tenant_id, run_id)
    when is_binary(tenant_id) and tenant_id != "" and is_binary(run_id) do
  with {:ok, id} <- Ecto.UUID.cast(run_id),
       %Run{} <- fetch_visible_run(tenant_id, id) do
    %{
      run: Workflows.get_run_tree!(id),
      detail: Runtime.get_run_detail!(id),
      linked_incident: find_tenant_incident_for_run(tenant_id, id),
      remote_invocation_evidence: SRE.remote_invocation_evidence(id)
    }
  else
    _ -> nil
  end
rescue
  _error -> nil
end
```

**LiveView alias/callsite pattern** (`lib/scoria_web/live/workflow_live/show.ex` lines 21-28 and 291-295):
```elixir
alias ScoriaWeb.OperatorSurface

alias ScoriaWeb.{
  DelegatedEvidenceComponent,
  MemoryNotebookComponent,
  RemoteInvocationEvidenceComponent,
  WorkflowDetailPanelComponent
}

defp load_run(socket, tenant_id, run_id) do
  case OperatorSurface.fetch_tenant_run_detail(tenant_id, run_id) do
    nil -> assign_run_not_found(socket)
    detail -> assign_run_detail(socket, detail)
  end
end
```

**Apply:**
- Move/copy implementation to `ScoriaWeb.ReviewerSurface` and update moduledoc to reviewer language.
- Keep `ScoriaWeb.OperatorSurface` as compatibility wrapper with `@moduledoc false` or explicit legacy note.
- Update public/discoverable LiveView aliases to `ReviewerSurface`. Keep host-owned auth/scope wording intact.

---

### Trace component renames and copy updates

**Analog:** old evidence-named components and their tests.

**Delegated component pattern** (`lib/scoria_web/components/delegated_evidence_component.ex` lines 1-42):
```elixir
defmodule ScoriaWeb.DelegatedEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:delegated_handoffs, :list, required: true)

  def render(assigns) do
    ~H"""
    <.notebook
      id="delegated-evidence"
      title="Delegated handoff inspection"
      eyebrow="Delegated Evidence"
      selected_tab="delegated"
      empty={@delegated_handoffs == []}
    >
      <:empty_slot>
        <.evidence_empty title="No Delegated Handoffs Recorded">
          This run stayed on the default runtime lane. No bounded handoff is required for first adoption; use Scoria.start_handoff_run/3 only when a same-run delegation needs narrow projected context.
        </.evidence_empty>
      </:empty_slot>

      <:tab key="delegated" label="Delegated">
        <div class="space-y-4">
          <.evidence_section
            title="Delegated handoffs"
            description="Review bounded delegated lineage from the curated runtime detail instead of reconstructing it from raw workflow rows."
          >
```

**Replay notebook pattern** (`lib/scoria_web/components/replay_evidence_notebook_component.ex` lines 1-24 and 46-74):
```elixir
defmodule ScoriaWeb.ReplayEvidenceNotebookComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:step, :map, default: nil)
  attr(:checkpoint, :map, default: nil)
  attr(:comparison, :map, default: nil)
  attr(:selected_source_variant, :string, default: "original")
  attr(:selected_comparison_entry, :map, default: nil)

  def render(assigns) do
    ~H"""
    <.notebook
      id="replay-evidence-notebook"
      title="Original-versus-replay comparison"
      eyebrow="replay evidence notebook"
      selected_tab="comparison"
    >
      <:tab key="comparison" label="Comparison">
        <div class="space-y-4">
          <.evidence_section
            title="Trace comparison"
            description="Grouped operator evidence stays structured by provenance, overrides, outcome, safety, and promotion readiness."
          >
...
            <% else %>
              <.evidence_empty title="No Replay Comparison Available">
                Select a workflow step with durable checkpoint evidence to compare the original run against its replay branch. Promotion stays disabled until Scoria can freeze an evidence snapshot for the selected trace.
              </.evidence_empty>
            <% end %>
```

**Semantic cache trace pattern** (`lib/scoria_web/components/semantic_evidence_notebook_component.ex` lines 1-20 and 46-98):
```elixir
defmodule ScoriaWeb.SemanticEvidenceNotebookComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:semantic_evidence, :map, default: %{})

  def render(assigns) do
    ~H"""
    <.notebook
      :if={present?(@semantic_evidence)}
      id="semantic-evidence-notebook"
      title="Semantic fast-path inspection"
      eyebrow="semantic evidence notebook"
      selected_tab="semantic"
    >
      <:tab key="semantic" label="Semantic">
        <div class="space-y-4">
          <.evidence_section
            title="Semantic evidence groups"
            description="Workflow evidence keeps semantic verdict, compatibility, provenance, lifecycle, and append-only events on one page."
```

**Workflow detail alias/render pattern** (`lib/scoria_web/components/workflow_detail_panel_component.ex` lines 1-10 and 51-63):
```elixir
defmodule ScoriaWeb.WorkflowDetailPanelComponent do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import ScoriaWeb.UI, only: [evidence_rows: 1, panel: 1]

  alias ScoriaWeb.ReplayEvidenceNotebookComponent
  alias ScoriaWeb.SemanticEvidenceNotebookComponent

  ...

  <ReplayEvidenceNotebookComponent.render
    step={@step}
    checkpoint={@checkpoint}
    comparison={@comparison}
    selected_source_variant={@selected_source_variant}
    selected_comparison_entry={@selected_comparison_entry}
  />

  <SemanticEvidenceNotebookComponent.render semantic_evidence={@semantic_evidence} />
```

**Component source-guard test pattern** (`test/scoria_web/components/semantic_evidence_notebook_component_test.exs` lines 10-33):
```elixir
test "semantic and replay adapters use shared notebook evidence primitives" do
  adapter_paths = [
    "lib/scoria_web/components/replay_evidence_notebook_component.ex",
    "lib/scoria_web/components/semantic_evidence_notebook_component.ex"
  ]

  for path <- adapter_paths do
    source = File.read!(path)

    assert source =~ "<.notebook"
    assert source =~ "evidence_section"
    assert source =~ "evidence_rows"
    refute source =~ @palette_regex
  end

  replay_source = File.read!("lib/scoria_web/components/replay_evidence_notebook_component.ex")
  semantic_source = File.read!("lib/scoria_web/components/semantic_evidence_notebook_component.ex")

  assert replay_source =~ ~s(phx-click="select_comparison_source")
  assert semantic_source =~ "Advanced raw evidence"
  assert semantic_source =~ "raw_evidence"
end
```

**Workflow rendered proof pattern** (`test/scoria_web/live/workflow_live_test.exs` lines 366-427 and 498-617):
```elixir
test "workflow page renders delegated evidence from the curated runtime DTO and keeps step selection on the right rail" do
  ...
  {:ok, view, html} = live(conn, "/scoria/workflows/#{run.id}")

  assert html =~ "Delegated Evidence"
  assert html =~ "Inspect Delegated Evidence"
  assert html =~ ~s(href="#delegated-evidence")
  assert length(Regex.scan(~r/id="delegated-evidence"/, html)) == 1
  ...

  selected_html =
    view
    |> element("button[phx-click='select_step'][phx-value-id='#{child_step.id}']")
    |> render_click()

  assert selected_html =~ "Delegated Evidence"
end

test "workflow page renders the semantic evidence notebook for semantic hits" do
  ...
  assert html =~ "semantic evidence notebook"
  assert html =~ "Compatibility"
  assert html =~ "Provenance"
  assert html =~ "Lifecycle"
end
```

**Apply:**
- Rename component modules/files to `DelegatedTraceComponent`, `ReplayTraceNotebookComponent`, and `SemanticCacheTraceNotebookComponent`.
- Update ids/eyebrows/titles for reviewer-visible copy: `delegated-trace`, "Delegated trace", "replay trace notebook", "semantic cache trace".
- Keep `evidence_section`, `evidence_rows`, `raw_evidence`, and other internal helper names unless aliases are cheap and low-risk.
- Preserve "evidence" in incident/audit/budget/citation/grounding contexts where it names proof material.
- Update LiveView and test aliases/render calls in lockstep.

---

### `lib/scoria_web/components/remote_invocation_evidence_component.ex` and `incident_evidence_component.ex`

**Analog:** same files.

**Remote invocation top-level labels** (`lib/scoria_web/components/remote_invocation_evidence_component.ex` lines 9-28):
```elixir
def render(assigns) do
  assigns =
    assign(assigns, :approvals, Map.get(assigns.evidence || %{}, :approvals, []))

  ~H"""
  <.notebook
    id="remote-invocation-notebook"
    title="Remote invocation evidence"
    eyebrow="Remote evidence notebook"
    selected_tab={@selected_tab}
    on_tab_change={@on_tab_change}
    empty={@approvals == []}
  >
    <:empty_slot>
      <.evidence_empty title="No remote approvals recorded">
        No remote approvals recorded.
      </.evidence_empty>
    </:empty_slot>

    <:tab key="remote_invocation" label="Remote">
```

**Incident proof-material wording pattern** (`lib/scoria_web/components/incident_evidence_component.ex` lines 14-21, 60-83, 101-121):
```elixir
<header class="scoria-incident-detail__header">
  <p class="scoria-eyebrow">Incident evidence</p>
  <h2 id="incident-evidence-title" class="scoria-incident-detail__title">
    Trace-first incident evidence
  </h2>
  <p class="scoria-incident-detail__description">
    Start with the selected run state, then inspect the proof behind the route, budget, breaker, and relay signals.
  </p>
</header>

<.evidence_section
  title="Incident notebook"
  description="Operator-facing incident facts before raw transport and persistence details."
>

<.evidence_section
  title="Budget evidence"
  description="Reservation actuals, policy, reason, and provider/tool references."
>

<.evidence_section
  title="Audit and delivery"
  description={@evidence.health_rollup.relay_detail}
>
```

**Incident component test pattern** (`test/scoria_web/components/incident_evidence_component_test.exs` lines 28-46 and 78-83):
```elixir
test "renders incident evidence through the incident detail adapter" do
  html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

  assert html =~ ~s(id="incident-evidence-notebook")
  assert html =~ "scoria-incident-detail"
  assert html =~ "Trace-first incident evidence"
  refute html =~ "scoria-notebook__tab"
end

test "preserves triage, budget, incident, breaker, and relay evidence sections" do
  html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

  assert html =~ "Triage summary"
  assert html =~ "Budget evidence"
  assert html =~ "Reservation actuals"
  assert html =~ "Incident notebook"
  assert html =~ "Breaker evidence"
  assert html =~ "Audit and delivery"
end

test "escapes raw evidence values through HEEx" do
  html = render_component(&IncidentEvidenceComponent.render/1, evidence: evidence())

  refute html =~ "<script>alert(&quot;incident&quot;)</script>"
  assert html =~ "&lt;script&gt;alert(&quot;incident&quot;)&lt;/script&gt;"
end
```

**Apply:** Rename only top-level run/workflow inspection copy to trace. Preserve incident, audit, budget, breaker, citation, and policy evidence labels where they name proof material.

---

### `test/scoria/terminology_contract_test.exs` and doc contract updates

**Analog:** `Scoria.AdopterDocContract`, `Scoria.AdoptionSurfaceTest`, `Scoria.ChangelogContractTest`, `ScopeDoctrineContractTest`.

**Contract helper pattern** (`lib/scoria/adopter_doc_contract.ex` lines 1-17 and 42-60):
```elixir
defmodule Scoria.AdopterDocContract do
  @moduledoc """
  Single source of truth for adopter-facing README and support-doc contracts.

  Exports capability nouns, upgrade-safe install markers, and refute patterns for
  milestone banner language and maintainer-only commands. Maintainer CI commands
  belong in the operator guide, not in adopter README assertions.
  """

  @shipped_capability_nouns [
    "default runtime",
    "bounded handoff",
    "semantic fast path",
    "optional knowledge",
    "remote connector",
    "upgrade-safe install"
  ]

  def shipped_capability_nouns, do: @shipped_capability_nouns
  def upgrade_safe_install_markers, do: @upgrade_safe_install_markers
  def milestone_banner_refutes, do: @milestone_banner_refutes
  def readme_maintainer_command_refutes, do: @readme_maintainer_command_refutes
end
```

**Generated docs-surface test pattern** (`test/scoria/adoption_surface_test.exs` lines 7-16):
```elixir
for {path, fragments} <- HexConsumerContract.adopter_doc_surfaces() do
  test "adopter doc #{path} stays aligned with HexConsumerContract surface SSOT" do
    content = File.read!(unquote(path))

    for fragment <- unquote(Macro.escape(fragments)) do
      assert content =~ fragment,
             "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
    end
  end
end
```

**Doc assertion/refute pattern** (`test/scoria/adoption_surface_test.exs` lines 73-93):
```elixir
test "README shipped truth is capability-based" do
  content = File.read!(@readme)
  lower = String.downcase(content)

  for noun <- AdopterDocContract.shipped_capability_nouns() do
    assert lower =~ String.downcase(noun),
           "expected README to mention capability noun #{inspect(noun)}"
  end

  for marker <- AdopterDocContract.upgrade_safe_install_markers() do
    assert content =~ marker,
           "expected README to include upgrade-safe marker #{inspect(marker)}"
  end

  for refute <-
        AdopterDocContract.milestone_banner_refutes() ++
          AdopterDocContract.readme_maintainer_command_refutes() do
    refute content =~ refute,
           "expected README not to contain #{inspect(refute)}"
  end
end
```

**Changelog contract pattern** (`test/scoria/changelog_contract_test.exs` lines 8-23):
```elixir
test "CHANGELOG satisfies adopter release contract" do
  content = File.read!(@changelog)

  assert content =~ "Planning milestones vs Hex releases"

  for noun <- AdopterDocContract.shipped_capability_nouns() do
    assert String.contains?(String.downcase(content), String.downcase(noun)),
           "expected CHANGELOG to mention capability noun #{inspect(noun)}"
  end

  for refute <- AdopterDocContract.milestone_banner_refutes() do
    refute content =~ refute
  end

  refute content =~ "### Summary"
end
```

**Apply:** Add a final-vocabulary SSOT/helper or local lists in `terminology_contract_test.exs`:
- required terms in glossary: run, reviewer, trace, evidence, capability, verification suite, scoped context, semantic cache, knowledge base, grounding, bounded handoff
- blocked surface-sense strings in adopter docs: "operator evidence", "semantic evidence notebook", "default runtime lane", "verification lane", "proof lane", "adoption lane", `Keystone`, `v2.0 Relay`, and "The Four Lanes"
- allowlist evidence contexts: citation, grounding, policy, audit, incident, budget, `evidence_refs`
- assert public docs/examples prefer `Scoria.SemanticCache.Profile`, `semantic_cache: [profile: ...]`, `scoped_context:`, `Scoria.VerificationSuites`, `ReviewerSurface`, and `ReviewerBroadcast`

## Shared Patterns

### Compatibility Aliases
**Source:** current final-target modules after move; no exact existing wrapper analog found.
**Apply to:** `SemanticLane`, `VerificationLanes`, `OperatorBroadcast`, `OperatorSurface`.

Use soft compatibility for `0.1.x`: old modules remain accepted but ExDoc should lead with final names. Prefer:
```elixir
defmodule Old.PublicName do
  @moduledoc false

  defdelegate public_fun(arg), to: New.PublicName
end
```

Do not emit hard deprecation warnings unless the plan explicitly chooses warning noise.

### Option Aliases
**Source:** `lib/scoria/runtime/params.ex` lines 194-223 and 314-322.
**Apply to:** `scoped_context` -> `projected_context`; semantic `profile` -> legacy `lane`.

Keep alias normalization at the input boundary:
```elixir
defp value(opts, runtime, key) do
  canonical_value(runtime, key) || canonical_value(opts, key)
end

defp canonical_value(attrs, key) when is_map(attrs) do
  cond do
    Map.has_key?(attrs, key) -> Map.get(attrs, key)
    Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
    true -> nil
  end
end
```

### Read Models Fail Closed
**Source:** `lib/scoria_web/operator_surface.ex` lines 195-224 and 262-307.
**Apply to:** reviewer surface and LiveView call sites.

Tenant-scoped reads return `[]` or `nil` on invalid scope/error. Do not turn URL params into authority.

### Component UI Helpers
**Source:** `lib/scoria_web/components/*_evidence*_component.ex`.
**Apply to:** renamed trace components.

Keep shared helper primitives:
```elixir
use Phoenix.Component
import ScoriaWeb.UI

attr(:..., ..., required: true)

def render(assigns) do
  ~H"""
  <.notebook ...>
    <.evidence_section ...>
      <.evidence_rows rows={...} />
    </.evidence_section>
  </.notebook>
  """
end
```

Renaming user-visible text does not require renaming `evidence_section`, `evidence_rows`, or `raw_evidence`.

### Docs-As-Contract
**Source:** `test/scoria/adoption_surface_test.exs`, `test/scoria/package_surface_test.exs`, `test/scoria/scope_doctrine_contract_test.exs`.
**Apply to:** all docs/README/CHANGELOG updates.

Every docs vocabulary change should have an assertion and a refute. Use active-source helpers when scanning source code to avoid comments skewing guards.

### No Schema Rename
**Source:** migration/schema grep results and `ScopeDoctrineContractTest.active_source/1`.
**Apply to:** terminology guard tests.

Preserve:
- `evidence_refs`
- `projected_context` storage field
- `lane_key` storage field

Block:
- `trace_refs`
- schema/migration rename to `scoped_context`
- schema/migration rename to `cache_key`

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `docs/glossary.md` | documentation | transform/reference | No existing glossary/reference-term page exists; use compact docs style plus phase entry schema. |
| compatibility wrapper modules | utility/service wrappers | transform/event-driven/request-response | Repo has public modules but no direct old-name-to-new-name compatibility wrapper pattern. Use simple `defdelegate` wrappers and hide/legacy-doc them. |
| `test/scoria/no_schema_rename_contract_test.exs` | test | file-I/O/transform | No exact no-schema-rename test exists; copy active source-scan style from `ScopeDoctrineContractTest`. |
| `Scoria.SemanticCache.Profile` public `cache_key:` naming | public behavior | transform | Existing implementation uses `SemanticLane` and `lane_key`; new final vocabulary should wrap the existing behavior without storage rename. |

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`, `docs/**/*.md`, `README.md`, `CHANGELOG.md`, `mix.exs`, selected `priv/repo/**/*` migration grep.
**Files scanned:** 620 source/doc/test/config files from `rg --files`; targeted migration grep for persisted field names.
**Pattern extraction date:** 2026-07-09
