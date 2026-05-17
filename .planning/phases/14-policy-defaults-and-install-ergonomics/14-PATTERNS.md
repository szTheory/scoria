# Phase 14: Policy Defaults and Install Ergonomics - Pattern Map

**Mapped:** 2026-05-14
**Files analyzed:** 16
**Analogs found:** 9 / 10 anticipated files

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/prompt_policy.ex` | model | transform | `lib/scoria/identity.ex` | role+flow |
| `lib/scoria/runtime/defaults.ex` | service | transform | `lib/scoria/runtime/params.ex` | role+flow |
| `lib/scoria/runtime/params.ex` | utility | request-response | `lib/scoria/runtime/params.ex` | exact |
| `lib/scoria/runtime.ex` | service | request-response | `lib/scoria/runtime.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | service | event-driven | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/mcp/executor.ex` | service | event-driven | `lib/scoria/mcp/executor.ex` | exact |
| `lib/scoria/sre/telemetry_identity.ex` or `lib/scoria/sre/telemetry.ex` | utility | transform | `lib/scoria/sre/telemetry_identity.ex` | exact |
| `lib/mix/tasks/scoria.install.ex` | config | file-I/O | `lib/mix/tasks/scoria.install.ex` | exact |
| `test/mix/tasks/scoria.install_test.exs` | test | file-I/O | `test/mix/tasks/scoria.install_test.exs` | exact |
| `test/scoria/bootstrap/migration_lane_compatibility_test.exs` | test | batch | `test/scoria/bootstrap/migration_lane_compatibility_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/prompt_policy.ex` (model, transform)

**Primary analog:** `lib/scoria/identity.ex`

Use the same pattern as the canonical identity envelope: one small public struct, permissive edge input, immediate normalization, and a `to_map/1` escape hatch.

**Struct + public constructors pattern** ([`lib/scoria/identity.ex:6`](../../../../lib/scoria/identity.ex#L6)-[`35`](../../../../lib/scoria/identity.ex#L35)):
```elixir
@enforce_keys [:metadata]
defstruct actor_id: nil, tenant_id: nil, session_id: nil, metadata: %{}

def new(attrs \\ %{}), do: normalize(attrs)
def from_conn_assigns(assigns), do: normalize(%{assigns: assigns})
def from_session(session), do: normalize(%{session: session})
def from_mount(attrs), do: normalize(%{mount: attrs})
```

**Immediate normalization seam** ([`lib/scoria/identity.ex:36`](../../../../lib/scoria/identity.ex#L36)-[`71`](../../../../lib/scoria/identity.ex#L71)):
```elixir
def normalize(%__MODULE__{} = identity), do: %__MODULE__{identity | metadata: normalize_metadata(identity.metadata)}

def normalize(attrs) do
  attrs = normalize_map(attrs)
  ...

  %__MODULE__{
    actor_id: ...,
    tenant_id: ...,
    session_id: ...,
    metadata: metadata
  }
end
```

**Planner guidance**
- Copy the `Identity` shape, but substitute prompt-policy fields such as `policy_key`, `prompt_ref`, `prompt_version`, and explicit governance constraints.
- Accept sugar at the boundary only. Normalize atoms/strings/maps into `%Scoria.PromptPolicy{}` before runtime, telemetry, audit, or persistence touches it.
- Add a `to_map/1` equivalent so downstream code can snapshot the resolved policy into run metadata without depending on struct internals.

**Anti-pattern to avoid**
- Do not let raw strings/maps flow through runtime code the way `Identity` explicitly prevents for actor/tenant/session.

### `lib/scoria/runtime/defaults.ex` (service, transform)

**Primary analog:** `lib/scoria/runtime/params.ex`

This new module should be the policy/default composition helper that `Params.start/2` calls exactly once.

**Canonical normalization entrypoint pattern** ([`lib/scoria/runtime/params.ex:9`](../../../../lib/scoria/runtime/params.ex#L9)-[`26`](../../../../lib/scoria/runtime/params.ex#L26)):
```elixir
def start(identity, opts \\ []) do
  opts = normalize_map(opts)
  runtime = nested_map(opts, :runtime)
  dispatch = dispatch_opts(opts)
  identity = Identity.normalize(identity)

  workflow_attrs = %{...}

  {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch}}
end
```

**Loose input -> canonical map helpers** ([`lib/scoria/runtime/params.ex:113`](../../../../lib/scoria/runtime/params.ex#L113)-[`133`](../../../../lib/scoria/runtime/params.ex#L133)):
```elixir
defp nested_map(attrs, key) do
  case canonical_value(attrs, key) do
    value when is_map(value) -> normalize_map(value)
    _ -> %{}
  end
end

defp canonical_value(attrs, key) when is_map(attrs) do
  Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
end
```

**Planner guidance**
- Put built-in defaults, app config, optional resolver overlays, and per-run overrides behind one pure function, likely returning a resolved struct/map plus a policy snapshot.
- Keep this module free of workflow, telemetry, MCP, or DB side effects.
- Follow `Params` and `Identity`: normalize boundary input first, then compose.

**Anti-pattern to avoid**
- Do not scatter merge logic across `Runtime`, `Workflows.Runtime`, `MCP.Executor`, and telemetry producers.

### `lib/scoria/runtime/params.ex` (utility, request-response)

**Primary analog:** `lib/scoria/runtime/params.ex`

This is the correct seam to absorb default resolution for `start_run/2`.

**Start contract packaging pattern** ([`lib/scoria/runtime/params.ex:15`](../../../../lib/scoria/runtime/params.ex#L15)-[`25`](../../../../lib/scoria/runtime/params.ex#L25)):
```elixir
workflow_attrs =
  %{
    root_role_id: value(opts, runtime, :root_role_id) || "executor",
    actor_id: identity.actor_id,
    tenant_id: identity.tenant_id,
    session_id: identity.session_id,
    metadata: start_metadata(opts, runtime, identity)
  }
  |> maybe_put_initial_step(initial_step(opts, runtime))
```

**Metadata stamping pattern** ([`lib/scoria/runtime/params.ex:46`](../../../../lib/scoria/runtime/params.ex#L46)-[`63`](../../../../lib/scoria/runtime/params.ex#L63)):
```elixir
metadata
|> maybe_put_payload(payload)
|> maybe_put_identity_metadata(identity)
```

**Planner guidance**
- Extend `start/2`, not `resume/2`, with default composition.
- Resolve prompt policy/provider/model once here or in a helper called from here, then stamp the resolved snapshot into `workflow_attrs.metadata`.
- Keep per-run options as the final explicit override layer.

**Anti-pattern to avoid**
- Do not re-resolve config later from `run.metadata` plus transient runtime maps. Resolve once, persist once, project many times.

### `lib/scoria/runtime.ex` (service, request-response)

**Primary analog:** `lib/scoria/runtime.ex`

The public runtime facade should stay thin and delegate normalization/composition downward.

**Public entrypoint orchestration pattern** ([`lib/scoria/runtime.ex:17`](../../../../lib/scoria/runtime.ex#L17)-[`24`](../../../../lib/scoria/runtime.ex#L24)):
```elixir
def start_run(identity, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start(identity, opts),
       {:ok, run} <- Workflows.create_run(workflow_attrs),
       {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
    {:ok, get_run!(run.id)}
  end
end
```

**Planner guidance**
- Keep Phase 14 default composition at this public boundary or one layer below it.
- `Runtime.start_run/2` is the right place to guarantee “resolved exactly once before workflow/MCP/telemetry/audit.”
- Avoid adding app-facing hidden processes or callbacks here; preserve the small happy-path API.

### `lib/scoria/workflows/runtime.ex` (service, event-driven)

**Primary analog:** `lib/scoria/workflows/runtime.ex`

Use this module as the consumer of already-resolved runtime metadata, not as another default resolver.

**Root identity vs transient context pattern** ([`lib/scoria/workflows/runtime.ex:314`](../../../../lib/scoria/workflows/runtime.ex#L314)-[`341`](../../../../lib/scoria/workflows/runtime.ex#L341)):
```elixir
defp runtime_context(run, attrs) do
  attrs = Map.new(attrs)
  identity = runtime_identity(run, attrs)

  attrs
  |> Map.put(:actor_id, identity.actor_id)
  |> Map.put(:tenant_id, identity.tenant_id)
  |> Map.put(:session_id, identity.session_id)
  |> Map.put(:identity, Identity.to_map(identity))
end
```

**Runtime metadata projection pattern** ([`lib/scoria/workflows/runtime.ex:295`](../../../../lib/scoria/workflows/runtime.ex#L295)-[`311`](../../../../lib/scoria/workflows/runtime.ex#L311)):
```elixir
%{
  actor_id: identity.actor_id,
  tenant_id: identity.tenant_id || "system",
  session_id: identity.session_id,
  subject_kind: "workflow_step",
  policy_key: Map.get(budget_context, :policy_key, "workflow:#{step.kind}"),
  reason_code: outcome,
  trace_id: Map.get(budget_context, :trace_id, step.id),
  run_id: run.id,
  tool_name: step.kind,
  integration_kind: Map.get(budget_context, :integration_kind, "workflow"),
  provider: Map.get(budget_context, :provider),
  model: Map.get(budget_context, :model)
}
```

**Planner guidance**
- Feed this module a resolved `policy_key` / `provider` / `model` / prompt-policy snapshot through the runtime context.
- Preserve the current separation: root identity inherited from durable run truth, policy/runtime details carried as explicit transient attrs.
- If governance checks need enforcement against widened overrides, do it before this seam or at the boundary entering this seam, not by ad hoc merging inside step execution.

### `lib/scoria/mcp/executor.ex` (service, event-driven)

**Primary analog:** `lib/scoria/mcp/executor.ex`

This is the downstream pattern for policy-sensitive execution once the resolved defaults are already canonical.

**Canonical context normalization** ([`lib/scoria/mcp/executor.ex:15`](../../../../lib/scoria/mcp/executor.ex#L15)-[`17`](../../../../lib/scoria/mcp/executor.ex#L17), [`311`](../../../../lib/scoria/mcp/executor.ex#L311)-[`320`](../../../../lib/scoria/mcp/executor.ex#L320)):
```elixir
def execute(tool_module, args, context, timeout \\ 5000) do
  context = canonical_context(context || %{})
  ...
end

defp canonical_context(context) do
  context = Map.new(context)
  identity = Scoria.Identity.normalize(context)

  context
  |> Map.put(:actor_id, identity.actor_id)
  |> Map.put(:tenant_id, identity.tenant_id)
  |> Map.put(:session_id, identity.session_id)
  |> Map.put(:identity, Scoria.Identity.to_map(identity))
end
```

**Audit + telemetry propagation pattern** ([`lib/scoria/mcp/executor.ex:226`](../../../../lib/scoria/mcp/executor.ex#L226)-[`247`](../../../../lib/scoria/mcp/executor.ex#L247), [`292`](../../../../lib/scoria/mcp/executor.ex#L292)-[`308`](../../../../lib/scoria/mcp/executor.ex#L308)):
```elixir
%{
  tenant_id: identity.tenant_id,
  actor_id: identity.actor_id,
  workflow_run_id: Map.get(context, :run_id),
  ...
  policy_key: Map.get(context, :policy_key),
  ...
  metadata: %{
    "integration_kind" => Map.get(context, :integration_kind, "tool"),
    "tool_target" => Map.get(context, :tool_target),
    "breaker_target" => Map.get(context, :breaker_target)
  }
}
```

**Planner guidance**
- Reuse this propagation shape for prompt-policy/provider/model after resolution.
- Keep execution consumers dumb: they should trust pre-resolved fields in `context`, not look up app config again.

### `lib/scoria/sre/telemetry_identity.ex` or `lib/scoria/sre/telemetry.ex` (utility, transform)

**Primary analog:** `lib/scoria/sre/telemetry_identity.ex`

This module is the clearest precedent for operator-visible metadata propagation with low-cardinality discipline.

**Labels vs refs split** ([`lib/scoria/sre/telemetry_identity.ex:6`](../../../../lib/scoria/sre/telemetry_identity.ex#L6)-[`29`](../../../../lib/scoria/sre/telemetry_identity.ex#L29), [`31`](../../../../lib/scoria/sre/telemetry_identity.ex#L31)-[`58`](../../../../lib/scoria/sre/telemetry_identity.ex#L58)):
```elixir
@label_keys [:tenant_id, :subject_kind, :policy_key, :reason_code, :window_bucket, :provider, :model, ...]
@ref_keys [:trace_id, :run_id, :workflow_run_id, :actor_id, :session_id, ...]
```

**Default-safe projection pattern** ([`lib/scoria/sre/telemetry_identity.ex:97`](../../../../lib/scoria/sre/telemetry_identity.ex#L97)-[`106`](../../../../lib/scoria/sre/telemetry_identity.ex#L106)):
```elixir
attrs
|> Map.new()
|> Map.put_new_lazy(:run_id, fn -> Map.get(attrs, :workflow_run_id) end)
|> Map.put_new(:tenant_id, "system")
|> Map.put_new(:subject_kind, "workflow")
|> Map.put_new(:policy_key, "policy")
|> Map.put_new(:reason_code, "unknown")
|> Map.put_new(:window_bucket, "global")
```

**Test precedent:** [`test/scoria/sre/telemetry_test.exs:98`](../../../../test/scoria/sre/telemetry_test.exs#L98)-[`149`](../../../../test/scoria/sre/telemetry_test.exs#L149)

**Planner guidance**
- Project resolved `policy_key`, `provider`, `model`, and prompt-policy identity into telemetry metadata.
- Keep prompt text, tool args, and similar high-cardinality or sensitive fields out of telemetry labels and general metadata unless intentionally added as refs elsewhere.

### `lib/mix/tasks/scoria.install.ex` (config, file-I/O)

**Primary analog:** `lib/mix/tasks/scoria.install.ex`

Reuse the narrow “find files -> patch conservatively -> print next step” flow, but harden it.

**Current install flow** ([`lib/mix/tasks/scoria.install.ex:6`](../../../../lib/mix/tasks/scoria.install.ex#L6)-[`26`](../../../../lib/mix/tasks/scoria.install.ex#L26)):
```elixir
router_paths = Path.wildcard("lib/*_web/router.ex")
tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]

router_path = List.first(router_paths)
tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)

if router_path && tailwind_path do
  do_run(router_path, tailwind_path)
  Mix.shell().info("Scoria installed successfully!")
else
  Mix.shell().error("Could not find router.ex or tailwind.config.js")
end
```

**Idempotent string-patch pattern** ([`lib/mix/tasks/scoria.install.ex:28`](../../../../lib/mix/tasks/scoria.install.ex#L28)-[`71`](../../../../lib/mix/tasks/scoria.install.ex#L71)):
```elixir
if content =~ "import ScoriaWeb.Router" do
  content
else
  Regex.replace(...)
end
```

**Planner guidance**
- Preserve idempotent file edits and explicit path discovery.
- Extend the installer with baseline config scaffolding and core migration guidance in the same conservative style.
- Keep optional knowledge/bootstrap steps out of the default path; print them as separate next steps only.

**Anti-patterns to avoid**
- The current task silently assumes both router and Tailwind must exist and only emits one generic error. Harden detection and messaging.
- The current implementation relies on fragile regex insertion points; avoid expanding that brittleness if a more targeted patching seam is available.

### `test/mix/tasks/scoria.install_test.exs` (test, file-I/O)

**Primary analog:** `test/mix/tasks/scoria.install_test.exs`

**Temporary fixture + internal function test pattern** ([`test/mix/tasks/scoria.install_test.exs:6`](../../../../test/mix/tasks/scoria.install_test.exs#L6)-[`64`](../../../../test/mix/tasks/scoria.install_test.exs#L64)):
```elixir
setup do
  File.mkdir_p!(@tmp_dir)
  ...
  router_path = Path.join(@tmp_dir, "router.ex")
  tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
  File.write!(router_path, router_content)
  File.write!(tailwind_path, tailwind_content)
  ...
end

Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
```

**Planner guidance**
- Keep installer logic factored into testable internal functions.
- Add assertions for config scaffolding and core-lane-only messaging.
- Add idempotency assertions by running the installer twice against the same fixture.

### `test/scoria/bootstrap/migration_lane_compatibility_test.exs` (test, batch)

**Primary analog:** `test/scoria/bootstrap/migration_lane_compatibility_test.exs`

This is the best precedent for “core lane succeeds without knowledge lane.”

**Core-vs-knowledge lane contract** ([`test/scoria/bootstrap/migration_lane_compatibility_test.exs:18`](../../../../test/scoria/bootstrap/migration_lane_compatibility_test.exs#L18)-[`31`](../../../../test/scoria/bootstrap/migration_lane_compatibility_test.exs#L31)):
```elixir
if knowledge_lane_enabled?() do
  assert table_exists?("ai_knowledge_sources")
  ...
else
  refute table_exists?("ai_knowledge_sources")
  refute table_exists?("ai_knowledge_chunks")
end
```

**Explicit environment toggle** ([`test/scoria/bootstrap/migration_lane_compatibility_test.exs:61`](../../../../test/scoria/bootstrap/migration_lane_compatibility_test.exs#L61)-[`72`](../../../../test/scoria/bootstrap/migration_lane_compatibility_test.exs#L72)):
```elixir
defp knowledge_lane_enabled? do
  System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true"
end
```

**Planner guidance**
- Reuse this exact separation for install verification: default core lane should pass with plain Postgres and no knowledge tables.
- If Phase 14 adds verification docs or task output, align them to this existing contract.

## Shared Patterns

### Public Config Surfaces
**Source:** `lib/scoria/observe/redactor.ex:8-20`, `lib/scoria/sre.ex:422-429`

Use plain `Application.get_env/3` with a module key or explicit atom key, plus explicit validation:
```elixir
config = Application.get_env(:scoria, __MODULE__, [])

case Keyword.get(config, :mfa) do
  {mod, fun, args} -> apply(mod, fun, [data | args])
  nil -> ...
end
```

```elixir
module = Application.get_env(:scoria, config_key, default)

if implements_behaviour?(module, behaviour) do
  module
else
  raise ArgumentError, "#{inspect(module)} does not implement #{inspect(behaviour)}"
end
```

**Apply to:** `Scoria.Runtime` defaults config and optional resolver config.

### Canonical Normalization Seams
**Source:** `lib/scoria/identity.ex:36-71`, `lib/scoria/runtime/params.ex:9-26`

Accept loose host-app input, normalize once, and pass canonical nouns inward.

**Apply to:** prompt-policy sugar, runtime default config, optional resolver return values.

### Runtime Metadata Propagation
**Source:** `lib/scoria/workflows/runtime.ex:295-323`, `lib/scoria/mcp/executor.ex:292-320`, `lib/scoria/sre/telemetry_identity.ex:48-58`

Project identity and resolved runtime decisions into explicit metadata fields instead of re-looking them up later.

**Apply to:** run metadata snapshots, telemetry attrs, audit evidence payloads.

### Core-vs-Knowledge Lane Separation
**Source:** `lib/mix/tasks/scoria.pgvector.bootstrap.ex:35-49`, `lib/mix/tasks/scoria.test.knowledge.ex:7-21`, `test/scoria/bootstrap/migration_lane_compatibility_test.exs:18-58`

Keep optional knowledge setup behind explicit commands and env gating:
```elixir
System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")
Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()
Scoria.TestSupport.Migrations.migrate_core!()
Scoria.TestSupport.Migrations.migrate_knowledge!()
```

**Apply to:** installer messaging, verification docs, any new core-lane test tasks.

## Anti-Patterns To Avoid

### Re-resolving defaults in downstream execution seams
Avoid looking up provider/model/prompt-policy from app config inside `Workflows.Runtime`, `MCP.Executor`, or telemetry code. Those modules currently assume explicit attrs and are strongest when they remain consumers of resolved runtime state.

### Letting metadata or merge order define governance
`Identity` keeps canonical fields out of arbitrary metadata drift. Phase 14 should do the same for governance-sensitive prompt-policy boundaries; do not rely on `Map.merge/2` precedence alone for widening or narrowing protections.

### Blurring the core lane with knowledge prerequisites
`mix scoria.pgvector.bootstrap` and the migration lane test already prove knowledge is optional. Do not make `mix scoria.install`, `mix test`, or the default README path depend on pgvector/Docker.

### Copying the current Mix task naming mismatch
`lib/mix/tasks/scoria.test.knowledge.ex` defines `defmodule Mix.Tasks.Test.Knowledge` ([`lib/mix/tasks/scoria.test.knowledge.ex:1`](../../../../lib/mix/tasks/scoria.test.knowledge.ex#L1)), which does not match the file/task naming convention implied by `scoria.test.knowledge`. Do not repeat this mismatch in new installer or verification tasks.

### Expanding regex-only installer edits without stronger assertions
The current installer is acceptable as a base, but its regex insertion points are brittle. If Phase 14 expands file editing, add idempotency tests and narrow path-specific assertions instead of piling on more permissive regexes.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria/prompt_policy.ex` | model | transform | No existing public struct models provider/model/prompt governance as one canonical noun; use `Scoria.Identity` as the direct structural precedent. |

## Metadata

**Analog search scope:** `lib/scoria*`, `lib/mix/tasks`, `test/scoria*`, `test/mix/tasks`, phase 12/13 research docs, `README.md`
**Files scanned:** 16 required files + targeted repo-wide `rg` queries for config, telemetry, and task patterns
**Pattern extraction date:** 2026-05-14
