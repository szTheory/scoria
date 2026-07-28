# Phase 56: Tool-Declared Trifecta Classification - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 7 (2 new, 5 modified)
**Analogs found:** 7 / 7

Scope fence honored: RAIL-01 (Phase 56.1) is NOT mapped here. Only CLASS-01/02/03 files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/mcp/classification.ex` | model (leaf struct+enum owner) | transform | `lib/scoria/semantic_cache/profile.ex` (macro/detection) + `lib/scoria/workflows/replay_disposition.ex` (enum ownership) + `lib/scoria/trust/scan.ex` (join operator + bounded-Task isolation) | exact (composite) |
| `lib/scoria/mcp/tool.ex` | model/behaviour | request-response | `lib/scoria/semantic_cache/profile.ex` | exact (same `@behaviour` + `__using__` shape, extended with `@optional_callbacks`) |
| `lib/scoria/mcp/executor.ex` (extend) | controller/orchestrator | request-response | itself (`persist_taint_to_step/3`, `build_replay_seam/2`, `policy_sensitive_invocation?/1`, `budget_required?/1`) — phase-55 D-08 precedent in the same file | exact |
| `lib/scoria/workflows/replay_disposition.ex` (extend) | service (pure resolver) | transform | itself — `@effectful_classes` becomes derived from `Classification.action_classes/0` | exact |
| `lib/scoria/connectors/invocation.ex` (extend, site 4) | service | event-driven / request-response | itself — `build_seam/2` | exact |
| `lib/scoria/workflows/runtime.ex` (extend, site 5) | service | event-driven | itself — `replay_execution/8`'s `Keyword.get(opts, :replay_seam, ...)` default | exact |
| `lib/scoria/observe/semconv.ex` (extend) | utility (projector) | transform | itself — `trust_attributes/1`/`@trust_keys`, `guardrail_attributes/1`/`normalize_reason_code/1` | exact |
| `test/scoria/mcp/classification_test.exs` | test | — | `test/scoria/mcp/executor_test.exs` (minimal-callback tool fixtures) | role-match |
| `test/scoria/workflows/replay_disposition_test.exs` (extend) | test | — | itself | exact |
| `test/scoria/observe/semconv_test.exs` (extend, canary edit) | test | — | itself, `"attribute_registry/0 registry canary"` at line 274 | exact |

## Pattern Assignments

### `lib/scoria/mcp/classification.ex` (NEW — model, transform)

**Analog 1 — behaviour/macro shape:** `lib/scoria/semantic_cache/profile.ex:1-107`

Copy the full `@callback` + `defmacro __using__(opts)` + `describe/1` `cond`-based detection shape. Key excerpt (imports/detection idiom, lines 57-76):
```elixir
def describe(module) when is_atom(module) do
  cond do
    not Code.ensure_loaded?(module) ->
      {:error, :invalid_semantic_cache_lane}

    not function_exported?(module, :lane_key, 0) ->
      {:error, :invalid_semantic_cache_lane}

    true ->
      normalize_description(module)
  end
end
```
Apply this exact `cond` shape to `Classification.resolve_tool_declaration/1`, substituting `Code.ensure_loaded?(tool_module)` then `function_exported?(tool_module, :classification, 0)` — do NOT imitate the bare `function_exported?/3` at `executor.ex:678` (that idiom lacks `Code.ensure_loaded?/1` and is only safe there because `name/0` is a *required* callback).

The `__using__` macro (lines 28-55) is the direct template for `Scoria.MCP.Tool`'s new `use Scoria.MCP.Tool, reads_private_data: ..., action_class: ...` macro — one `Keyword.get(opts, :field, default)` extraction per field, then a `quote do ... def classification, do: %Scoria.MCP.Classification{...} end`. Note Profile's callbacks are ALL required (no `@optional_callbacks`); Tool's `classification/0` must add `@optional_callbacks [classification: 0]` at the `Scoria.MCP.Tool` definition site, which Profile has no precedent for — this is a genuinely new line, not copied from anywhere in-repo.

**Analog 2 — enum ownership + closed-list hazard:** `lib/scoria/workflows/replay_disposition.ex:11,92-95`
```elixir
@effectful_classes ~w(read write exec admin)
...
action_class in Enum.drop(@effectful_classes, 1)
```
`Classification` becomes the *owner* of this list (`action_classes/0`, `default_action_class/0` = `"admin"`, `normalize_action_class/1` fail-closing to `"admin"`). `ReplayDisposition` must change its own `@effectful_classes` to `Scoria.MCP.Classification.action_classes()` (module attributes can call a function at compile time via `@effectful_classes Scoria.MCP.Classification.action_classes()` since it's just a list literal returned from a pure `def`). **List order is load-bearing** — `Enum.drop(@effectful_classes, 1)` pins `"read"` at index 0; assert this order in a test.

**Analog 3 — join operator polarity (INVERTED, do not copy verbatim):** `lib/scoria/trust/scan.ex:40,128-130`
```elixir
@tier_order %{"untrusted" => 0, "trusted" => 1}
...
defp most_restrictive(a, b) do
  if Map.fetch!(@tier_order, a) <= Map.fetch!(@tier_order, b), do: a, else: b
end
```
This takes the **min** (lower index = more restrictive tag = "untrusted"). `Classification`'s `action_class` join must take the **max** over `read < write < exec < admin` — copy the `Map.fetch!/2` ordinal-lookup shape only, invert the comparison direction (`>=` picks higher-index / more-restrictive-because-higher). Normalize both operands through `normalize_action_class/1` before any `Map.fetch!` lookup (mirrors this file's own `Map.fetch!` raise-on-junk risk). Ship directional tests: `join("read","admin") == "admin"` AND `join("admin","read") == "admin"`.

**Analog 4 — bounded-Task isolation for one-time `classification/0` resolution + `:persistent_term` memoization:** `lib/scoria/trust/scan.ex:94-111` (Task pattern) + `lib/scoria/sre/budget_engine.ex:361-393` (persistent_term precedent, not re-read this session — cited by RESEARCH.md, reuse the shape):
```elixir
defp run_scanner(scanner, content, context) do
  timeout = Map.get(context, :timeout, @default_timeout)

  task =
    Task.Supervisor.async_nolink(Scoria.Trust.TaskSupervisor, fn ->
      try do
        scanner.scan(content, context)
      catch
        kind, reason -> {:__scan_caught__, kind, reason}
      end
    end)

  case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
    {:ok, result} -> to_verdict(result, scanner)
    nil -> fail_closed(:scanner_timeout, scanner)
    {:exit, _reason} -> fail_closed(:scanner_error, scanner)
  end
end
```
Apply the identical `Task.Supervisor.async_nolink/2` + `Task.yield/Task.shutdown` + internal `try/catch` shape for the ONE-TIME (`:persistent_term`-memoized per tool_module) `classification/0` call, using either the existing `Scoria.MCP.TaskSupervisor` (already referenced at `executor.ex:387`) or a new dedicated supervisor. This is Open Question 4's resolution per RESEARCH.md — the heavier pattern is the precedent-consistent choice.

---

### `lib/scoria/mcp/tool.ex` (EXTEND — behaviour)

**Analog:** `lib/scoria/semantic_cache/profile.ex:23-26` (existing callbacks) — current file (full content, 27 lines):
```elixir
@doc "Name of the tool"
@callback name() :: String.t()
@doc "Description of what the tool does"
@callback description() :: String.t()
@doc "Ecto schemaless map definition for tool arguments"
@callback input_schema() :: map()
@doc "Executes the tool with validated arguments and context"
@callback execute(args :: map(), context :: map()) :: {:ok, any()} | {:error, any()}
```
Add:
```elixir
@callback classification() :: Scoria.MCP.Classification.t()
@optional_callbacks [classification: 0]

defmacro __using__(opts) do
  # mirrors Profile.__using__/1's Keyword.get/3 extraction shape, then
  # quote do: @behaviour Scoria.MCP.Tool; @impl true; def classification, do: %Scoria.MCP.Classification{...} end
end
```
`@optional_callbacks` is load-bearing (per D-01) — omitting it turns every adopter's build red under `--warnings-as-errors` (AGENTS.md's documented workflow), the same never-brick-an-adopter constraint as phase 55's D-08.

---

### `lib/scoria/mcp/executor.ex` (EXTEND — controller/orchestrator, 5 fail-open sites, D-03 persistence)

**Analog for persistence choke point:** `lib/scoria/mcp/executor.ex:308-341` (`persist_taint_to_step/3`, verified in this session):
```elixir
defp persist_taint_to_step(context, tool_module, tier) do
  case Map.get(context, :step_id) do
    nil ->
      :ok

    step_id ->
      taint = %{
        "tier" => tier,
        "tool_ref" => inspect(tool_module),
        "args_fingerprint" => Map.get(context, :args_fingerprint)
      }

      try do
        from(step in Step,
          where: step.id == ^step_id,
          update: [
            set: [
              result_envelope:
                fragment(
                  "? || ?",
                  step.result_envelope,
                  type(^%{"scoria.taint" => taint}, :map)
                )
            ]
          ]
        )
        |> Repo.update_all([])
      rescue
        _ -> :ok
      end

      :ok
  end
end
```
D-03 requires a near-identical second function (or parameterized shared helper) writing `%{"scoria.classification" => %{...}}` via the same `fragment("? || ?")` + `Repo.update_all/2` + `try/rescue -> :ok` best-effort discipline — "no `step_id` in context" is not an error.

**Fail-open site 1 (`build_replay_seam/2`, executor.ex:181-196, verified 15 lines not 13):**
```elixir
defp build_replay_seam(tool_module, context) do
  %{
    local_classification: Map.get(context, :local_classification, :write),
    tool_id: Map.get(context, :tool_id, inspect(tool_module)),
    action_class: Map.get(context, :action_class, "write"),
    risk_level: Map.get(context, :risk_level, "high"),
    approval_sensitive: Map.get(context, :approval_sensitive, Map.get(context, :policy_sensitive, false)),
    ...
  }
end
```
**PROHIBITION:** do not `Map.put` resolved classification values into any of these existing keys (`:local_classification`, `:action_class`, `:risk_level`, `:approval_sensitive`). Add new, separately-read keys instead (e.g. `context[:classification]` or a `%Scoria.MCP.Classification{}` struct under a new namespaced key), consumed later by `ReplayDisposition` only if wired as an *additional* input, not an overwrite. See RESEARCH.md Pitfall 1/2 for exact bricking mechanics.

**Fail-open site 2 (`policy_sensitive_invocation?/1`, executor.ex:552-554, exact match):**
```elixir
defp policy_sensitive_invocation?(context) do
  Map.get(context, :policy_sensitive) || Map.get(context, :sensitive_tool)
end
```
**Fail-open site 3 (`budget_required?/1`, executor.ex:442-447, exact match):**
```elixir
defp budget_required?(context) do
  Map.get(context, :estimated_cost_usd) ||
    Map.get(context, :estimated_tokens) ||
    Map.get(context, :estimated_units) ||
    Map.get(context, :sensitive_tool)
end
```
Neither of these two may have `:policy_sensitive`/`:sensitive_tool` clobbered directly by resolution — both gate `{:error,_}`-capable paths (`executor.ex:97-100`, `BudgetEngine.reserve_step/1`).

**Where resolution runs:** `execute/4` (lines 26-36) — insert `resolve_classification(tool_module, context)` between `canonical_context/1` (line 27) and `replay_gate/3` (line 29), per the RESEARCH.md architecture diagram.

**Unclassified fallback + telemetry (D-03), fail-closed flag precedent:** `lib/scoria/runtime/release_gate.ex:81-93` (exact match, full function):
```elixir
defp handle_missing_verdict(%PromptTemplate{} = template) do
  if Application.get_env(:scoria, :require_eval_verdict, false) do
    {:error, :eval_required}
  else
    :telemetry.execute(
      [:scoria, :release_gate, :ungated],
      %{},
      %{prompt_template_id: template.id}
    )

    :ok
  end
end
```
Mirror exactly for `config :scoria, :require_tool_classification` (default `false`) + `[:scoria, :class, :unclassified]` telemetry on the ungated path, `{:error, %{status: :unclassified_tool, ...}}` (same envelope shape as the existing `:access_denied` path at `executor.ex:519-527`) on the strict path.

---

### `lib/scoria/workflows/replay_disposition.ex` (EXTEND — service, pure resolver)

**Analog:** itself, full file (189 lines) already read. Only change: `@effectful_classes ~w(read write exec admin)` (line 11) becomes derived from `Scoria.MCP.Classification.action_classes/0` rather than a duplicated literal. `cond` clause order (lines 21-60) is UNCHANGED — Pitfall 1 in RESEARCH.md explains exactly why `pure_local?/1` (line 28, reads `:local_classification` against `[:pure, :local, :in_memory]`) must not be fed the resolved `action_class` value directly, since clause evaluation order means an overwritten `:local_classification` can fall through to clause 7 (`effectful_or_remote?/1`, lines 86-96) and flip `:execute_live` → `:blocked`.

Add directional join tests here (D-04): `join("read","admin") == "admin"` and `join("admin","read") == "admin"`, plus a regression test asserting the site-5 `%{local_classification: :pure}` default seam (runtime.ex:474) still resolves `:execute_live` after wiring lands.

---

### `lib/scoria/connectors/invocation.ex` (EXTEND — service, fail-open site 4)

**Analog:** itself, `build_seam/2` at lines 59-76 (verified 18 lines incl. `end`, not 16):
```elixir
defp build_seam(context, opts) do
  defaults = Keyword.get(opts, :seam, %{})

  defaults
  |> Map.new()
  |> Map.put_new(:tool_id, Map.get(context, :tool_id) || Map.get(context, :tool_ref))
  |> Map.put_new(:action_class, Map.get(context, :action_class, "read"))
  |> Map.put_new(:risk_level, Map.get(context, :risk_level, "low"))
  |> Map.put_new(:approval_sensitive, Map.get(context, :approval_sensitive, false))
  |> Map.put_new(:local_classification, Map.get(context, :local_classification, :read))
  ...
end
```
This defaults `action_class: "read"`, `approval_sensitive: false`, `local_classification: :read` — and `replay_resolution/5` is called at line 26, **before** `Executor.execute/4` (line 45). Classification must be resolved and injected into `context` (a NEW key, per the same prohibition) before `invoke/4` runs `build_seam/2`, or connector-routed tools bypass CLASS-03 entirely.

---

### `lib/scoria/workflows/runtime.ex` (EXTEND — service, fail-open site 5, WORST per D-05)

**Analog:** itself, `replay_execution/8` at line 474 (exact match):
```elixir
seam = Keyword.get(opts, :replay_seam, %{local_classification: :pure})
```
Total step-granularity replay bypass — `:pure` hits `ReplayDisposition` clause 3 and short-circuits before `effectful_or_remote?/1` runs. This site guards the STEP itself (non-MCP handler functions), needs its own resolved default separate from `MCP.Executor`'s per-tool-call resolution — cite this exact line when writing the task; do not conflate with executor-covered tool calls.

---

### `lib/scoria/observe/semconv.ex` (EXTEND — utility, fixed-key projector)

**Analog:** `trust_attributes/1` + `@trust_keys` (lines 276-291, 556-563, exact match):
```elixir
@trust_keys [
  tier: "scoria.trust.tier",
  scanner: "scoria.trust.scanner",
  reason_code: "scoria.trust.reason_code",
  scanned_count: "scoria.trust.scanned_count"
]

def trust_attributes(input) when is_map(input) do
  Enum.reduce(@trust_keys, %{}, fn {field, key}, acc ->
    case Map.get(input, field) do
      nil -> acc
      value -> Map.put(acc, key, value)
    end
  end)
end
```
Add `@classification_keys` (e.g. `action_class: "scoria.classification.action_class"`, `source: "scoria.classification.source"`, `reads_private_data: "scoria.classification.reads_private_data"`, `sees_untrusted_content: "scoria.classification.sees_untrusted_content"`, `can_exfiltrate: "scoria.classification.can_exfiltrate"`) + `classification_attributes/1`, identical `Enum.reduce` shape — never spread the input map (structural leak-immunity).

**Fail-closed normalizer idiom analog:** `normalize_reason_code/1` (~487-506, guardrail variant shown, trust variant is the direct sibling):
```elixir
def normalize_reason_code(value) do
  normalized = to_string(value)

  if normalized in @guardrail_reason_codes do
    normalized
  else
    Logger.warning("Unrecognized guardrail reason_code #{inspect(value)}, defaulting to \"unknown\"")

    try do
      :telemetry.execute([:scoria, :observe, :guardrail, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    "unknown"
  end
end
```
Mirror this shape (`Logger.warning` + defensively-wrapped `:telemetry.execute` + fail-closed default) for `Classification.normalize_action_class/1`, defaulting to `"admin"` (most-restrictive) instead of `"unknown"`.

**MUST update:** `test/scoria/observe/semconv_test.exs:274` `"attribute_registry/0 registry canary (SEC-01 Test 1)"` — this canary WILL go red the moment `@classification_keys` are registered; update its expected sorted-key list in the SAME commit, do not revert.

---

## Shared Patterns

### Fail-closed-but-inspectable flag (CLASS-02 exact precedent)
**Source:** `lib/scoria/runtime/release_gate.ex:81-93`
**Apply to:** `MCP.Executor`'s unclassified-tool resolution path
```elixir
if Application.get_env(:scoria, :require_eval_verdict, false) do
  {:error, :eval_required}
else
  :telemetry.execute([:scoria, :release_gate, :ungated], %{}, %{prompt_template_id: template.id})
  :ok
end
```

### Jsonb `fragment("? || ?")` merge choke point (D-03 persistence)
**Source:** `lib/scoria/mcp/executor.ex:308-341` (`persist_taint_to_step/3`)
**Apply to:** New `persist_classification_to_step/3`-style function in `executor.ex`
```elixir
from(step in Step, where: step.id == ^step_id,
  update: [set: [result_envelope: fragment("? || ?", step.result_envelope, type(^%{"scoria.classification" => data}, :map))]])
|> Repo.update_all([])
```

### `Code.ensure_loaded?/1` + `function_exported?/3` optional-callback detection
**Source:** `lib/scoria/semantic_cache/profile.ex:57-76` (`describe/1`)
**Apply to:** `Scoria.MCP.Classification`'s tool-declaration resolver — NOT `executor.ex:678`'s bare `function_exported?/3` (that lacks `Code.ensure_loaded?/1` and is only safe for the always-required `name/0`).

### Bounded, isolated Task callback invocation
**Source:** `lib/scoria/trust/scan.ex:94-111` (`run_scanner/3`)
**Apply to:** One-time, `:persistent_term`-memoized `classification/0` resolution in `Scoria.MCP.Classification`
```elixir
task = Task.Supervisor.async_nolink(SupervisorName, fn ->
  try do
    callback.()
  catch
    kind, reason -> {:__caught__, kind, reason}
  end
end)
case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
  {:ok, result} -> ...
  nil -> fail_closed(:timeout)
  {:exit, _} -> fail_closed(:error)
end
```

### Max-join ordinal operator (D-04 — INVERTED polarity vs Trust.Scan)
**Source:** `lib/scoria/trust/scan.ex:40,128-130` (`most_restrictive/2`, takes MIN)
**Apply to:** `Classification`'s `action_class` join — same `Map.fetch!/2` ordinal-lookup shape, but comparison direction flipped to take the MAX (tighten upward: `read < write < exec < admin`). Do not copy the `<=` comparison verbatim.

### Fixed-key attribute projector, never spread
**Source:** `lib/scoria/observe/semconv.ex:276-291,556-563` (`@trust_keys` / `trust_attributes/1`)
**Apply to:** New `@classification_keys` / `classification_attributes/1` in `Semconv` — requires the canary test edit at `test/scoria/observe/semconv_test.exs:274`.

## No Analog Found

None — every file in scope has a strong (exact-match) analog already shipped in this repo. This is a "wire the same idiom five more times, correctly" phase per RESEARCH.md's own framing.

## Metadata

**Analog search scope:** `lib/scoria/mcp/`, `lib/scoria/semantic_cache/`, `lib/scoria/trust/`, `lib/scoria/workflows/`, `lib/scoria/connectors/`, `lib/scoria/observe/`, `lib/scoria/runtime/`
**Files scanned:** 9 (all fully read: `tool.ex`, `profile.ex`, `replay_disposition.ex`, `executor.ex`, `scan.ex`, `invocation.ex`, `runtime.ex` (partial, lines 460-480), `semconv.ex` (partial), `release_gate.ex` (partial))
**Pattern extraction date:** 2026-07-28
