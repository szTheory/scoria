# Phase 56: Tool-Declared Trifecta Classification - Research

**Researched:** 2026-07-27
**Domain:** In-repo Elixir/OTP behaviour design + fail-open remediation across 5 call sites in Scoria's MCP executor / replay-disposition / connector-invocation / workflow-runtime subsystems
**Confidence:** HIGH (every citation below was re-read against the live tree in this worktree; no external library research was needed — this phase adds zero new dependencies)

## Summary

Phase 56 has no external-library research surface: CLASS-01/02/03 are pure in-repo design work — a new `@optional_callbacks` declaration on `Scoria.MCP.Tool`, a new `Scoria.MCP.Classification` struct/enum owner, and a single resolution choke point in `MCP.Executor` whose output must reach four *other* fail-open sites without touching any of the context keys those sites already trust. The dominant risk is not "what library to use" but "don't brick a currently-passing replay call" — `ReplayDisposition.resolve/5`'s `cond` clause order (`lib/scoria/workflows/replay_disposition.ex:21-60`) is the single most load-bearing piece of code in this phase, and every one of the four downstream fail-open sites feeds it a seam map.

All five citations in `56-CONTEXT.md` D-05 were re-verified against the live tree in this session. Four are exact line matches; one (`build_replay_seam/2`, site 1) is a citation of the *function*, and its body spans `executor.ex:181-196` (15 lines, not the stated 181-194 — the closing brace and one field are two lines later than cited; not a meaningful drift, just a note for the planner writing task line-anchors). Everything else — `policy_sensitive_invocation?/1` at `executor.ex:552-554`, `budget_required?/1` at `executor.ex:442-447`, `Connectors.Invocation.build_seam/2` at `invocation.ex:59-76` (with its replay-resolution call at line 26, exactly as cited), and `Workflows.Runtime`'s `%{local_classification: :pure}` default at `runtime.ex:474` — are byte-exact.

The two open questions CONTEXT.md flagged as "re-check against the tree" are now resolved by direct evidence, not inference: (1) no in-repo `MCP.Router`/`MCPController` mapping fronts more than one remote tool per module — both dispatch tables are strictly 1:1 (`method_name => tool_module`), so `classification/0` (not `/1`) is correctly scoped for now; (2) Phase 55's D-20 shipped a **bounded, isolated `Task.Supervisor.async_nolink` + internal `try/catch` + `Task.yield`/`Task.shutdown` timeout**, not bare process-level `try/catch` — this is the actual precedent the planner should decide against for `classification/0`'s isolation, not the try/catch CONTEXT.md's open question speculatively proposed.

**Primary recommendation:** Build `Scoria.MCP.Classification` as a leaf struct+enum module (mirroring `Scoria.Trust`'s leaf discipline), add `@optional_callbacks [classification: 0]` to `Scoria.MCP.Tool` with a `use Scoria.MCP.Tool, reads_private_data: ...` macro copied from `Scoria.SemanticCache.Profile`'s exact shape, resolve once per call in `MCP.Executor.execute/4` before `replay_gate/3`, and thread the resolved classification into all five fail-open sites **only** via new namespaced keys (`:classification`, `:action_class_declared`, etc.) — never by writing into `:approval_sensitive`, `:local_classification`, `:action_class`, `:risk_level`, `:policy_sensitive`, or `:sensitive_tool`, all of which are read directly by `ReplayDisposition.resolve/5`, `policy_sensitive_invocation?/1`, and `BudgetEngine.reserve_step/1` today and would flip live-safe calls to blocked/audited if clobbered.

## Architectural Responsibility Map

Scoria is an embedded Elixir/Phoenix library with no distinct frontend tier in this phase — every capability below lives in the host-process "API/Backend" tier (Scoria's own OTP application), with one secondary touch on the Database/Storage tier for taint/classification persistence.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tool declares trifecta legs + `action_class` (CLASS-01) | API/Backend | — | `Scoria.MCP.Tool` behaviour + `Scoria.MCP.Classification` struct live in the library's core, invoked at tool-module compile/load time, not at request time |
| Unclassified-tool fail-closed default + telemetry (CLASS-02) | API/Backend | — | Resolution logic and `:telemetry.execute/3` calls both execute inside `MCP.Executor`, an in-process OTP module |
| Per-call resolution at `MCP.Executor` (CLASS-03) | API/Backend | — | `MCP.Executor.execute/4` is the single choke point; no HTTP/LiveView layer involved |
| Precedence join across 5 fail-open seams (CLASS-03) | API/Backend | — | `ReplayDisposition`, `Connectors.Invocation`, `Workflows.Runtime` are all backend GenServer/pure-function modules, no client-facing surface |
| Classification persistence to `step.result_envelope` (D-03) | Database/Storage | API/Backend | Postgres jsonb write via `Repo.update_all`/`fragment("? || ?")`; the write call itself originates in `MCP.Executor` |
| Classification telemetry (`[:scoria, :class, *]`) | API/Backend | — | `:telemetry.execute/3` in-process event bus; consumed by host-attached handlers, not rendered by Scoria itself this phase |

No Browser/Client, Frontend-Server(SSR), or CDN/Static tier is touched by this phase (confirmed: Phase 55's `56-CONTEXT.md` `<deferred>` explicitly reserves the read-only Govern UI for Phase 58; this phase ships zero LiveView/controller changes).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLASS-01 | `Tool` behaviour extended so a tool declares `reads_private_data`/`sees_untrusted_content`/`can_exfiltrate` + `action_class` once, on the tool | `Scoria.SemanticCache.Profile` (`lib/scoria/semantic_cache/profile.ex`) verified as the exact behaviour+`__using__`+detection-idiom template to mirror; `Scoria.MCP.Tool` (`lib/scoria/mcp/tool.ex`) is a 4-callback, zero-macro module today — full diff surface identified |
| CLASS-02 | Unclassified tool fails closed to inspectable default + telemetry, closing the seam formerly at `executor.ex:150-165` | `Scoria.Runtime.ReleaseGate.handle_missing_verdict/1` (`lib/scoria/runtime/release_gate.ex:81-93`) verified as the exact `require_X` flag + `[:scoria, X, :ungated]` telemetry precedent to mirror for `require_tool_classification` + `[:scoria, :class, :unclassified]` |
| CLASS-03 | Declared classification resolved at `MCP.Executor` for every tool call, no host-passed default | All 5 fail-open sites re-verified against the live tree (see `## Runtime State Inventory` below for exact citations + prohibition analysis); `ReplayDisposition.resolve/5`'s full `cond` clause order mapped and the exact key-writes that flip `:execute_live` → `:blocked` are enumerated |
</phase_requirements>

## Standard Stack

**No new external dependencies.** This phase is 100% in-repo Elixir/OTP: `Scoria.MCP.Classification` (new struct+enum module), macro extension to the existing `Scoria.MCP.Tool` behaviour, and resolution/wiring logic inside existing `MCP.Executor`, `ReplayDisposition`, `Connectors.Invocation`, and `Workflows.Runtime` modules. `mix.exs` requires no new deps entries.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| (none — stdlib only) | Elixir/OTP as pinned in `mix.exs` | `:persistent_term` for per-module memoization (D-01), `Task.Supervisor`/`Task.yield`/`Task.shutdown` for bounded callback isolation (mirrors D-20 precedent) | Both are already used elsewhere in this codebase (`lib/scoria/sre/budget_engine.ex:361-393` for `:persistent_term`; `lib/scoria/trust/scan.ex:94-111` for the bounded-Task pattern) — no new dependency, no new idiom |

### Supporting
None — no supporting libraries needed.

### Alternatives Considered
Not applicable — no library choice exists in this phase.

**Installation:** N/A — no `mix.exs` change.

**Version verification:** N/A — no package versions to verify.

## Package Legitimacy Audit

**Not applicable.** This phase installs zero external packages (npm/hex/pip/cargo). No `package-legitimacy check` was run because there is nothing to check — `Scoria.MCP.Classification` and all wiring changes are new files/functions inside the existing `lib/scoria/` tree, using only stdlib (`:persistent_term`, `Task.Supervisor`) and already-vendored deps (`:telemetry`, `Ecto`).

## Architecture Patterns

### System Architecture Diagram

```
Tool module (host-defined, `use Scoria.MCP.Tool, reads_private_data: ...`)
        |
        | classification/0 (optional callback, generated by the macro
        | or hand-implemented; absent => no callback at all)
        v
+-------------------------------------------------------------+
|  MCP.Executor.execute/4  (SINGLE resolution choke point)    |
|                                                               |
|  1. canonical_context/1                                      |
|  2. >>> NEW: resolve_classification(tool_module, context) <<< |
|       - Code.ensure_loaded?/1 + function_exported?/3          |
|       - :persistent_term memoized per tool_module             |
|       - tool_declaration U host_declaration (tighten-only)    |
|       - :unclassified_default ONLY if neither exists           |
|       - emits [:scoria, :class, :unclassified] on that path    |
|  3. replay_gate/3 (site 1: build_replay_seam/2)               |
|       reads NEW namespaced keys only, never                   |
|       :approval_sensitive / :local_classification /            |
|       :action_class / :risk_level directly                    |
|  4. execute_live/4                                            |
|       -> reserve_budget (site 3: budget_required?/1)          |
|       -> ensure_policy_sensitive_invocation                    |
|          (site 2: policy_sensitive_invocation?/1)              |
|       -> execute_tool (bounded Task, unrelated to this phase)  |
|       -> persist_taint_to_step (D-08 pattern, jsonb fragment)  |
|            >>> NEW: persist classification the same way <<<    |
+-------------------------------------------------------------+
        ^
        |  (same resolution logic reused, NOT duplicated)
        |
+-------------------------------------------------------------+
| Connectors.Invocation.invoke/4  (site 4: build_seam/2)        |
|   computes ReplayDisposition.resolve/5 at line 26 BEFORE       |
|   ever calling Executor.execute/4 at line 45 -- classification |
|   must be resolved and injected into `context` before THIS     |
|   call, not only inside Executor, or replay decisions for      |
|   connector-routed tools bypass CLASS-03 entirely.              |
+-------------------------------------------------------------+

+-------------------------------------------------------------+
| Workflows.Runtime.replay_execution/8  (site 5: runtime.ex:474)|
|   `Keyword.get(opts, :replay_seam, %{local_classification:    |
|   :pure})` -- total replay bypass at STEP granularity, not     |
|   tool-call granularity. Any workflow handler that calls       |
|   Executor.execute/4 for its own tool invocations is already   |
|   covered by site 1-3 fixes; this site guards the STEP itself  |
|   (e.g. a non-MCP handler function) and needs its OWN resolved  |
|   default, separate from MCP.Executor's.                        |
+-------------------------------------------------------------+

ReplayDisposition.resolve/5  <-- fed by seams from sites 1, 4, 5
   cond clauses in ORDER (see Pitfall section below):
     1. not replay_mode?           -> :execute_live
     2. authority_expanding?       -> :blocked
     3. pure_local?                -> :execute_live  (reads :local_classification)
     4. exact_source_match?        -> :historical_stub
     5. override + ready           -> :execute_live  (reads :approval_sensitive)
     6. override, not ready        -> :blocked
     7. effectful_or_remote?       -> :blocked  (reads :approval_sensitive,
                                                  :action_class, :risk_level,
                                                  :local_classification)
     8. else                       -> :execute_live
```

### Recommended Project Structure

New files (mirrors `lib/scoria/trust/` module layout from Phase 55):

```
lib/scoria/mcp/
├── tool.ex                 # EXTEND: add @callback classification/0,
│                            # @optional_callbacks [classification: 0],
│                            # and the `use Scoria.MCP.Tool, opts` macro
├── classification.ex       # NEW: leaf struct + enum owner (mirrors Scoria.Trust)
│                            #   - action_classes/0, default_action_class/0,
│                            #     normalize_action_class/1
│                            #   - resolve/2 (tool U host, tighten-only join)
│                            #   - unclassified_default/0
├── executor.ex              # EXTEND: single resolution call before replay_gate/3;
│                            #   thread resolved classification into NEW
│                            #   namespaced context keys only
```

No new top-level namespace needed — `Scoria.MCP.Classification` sits directly beside `Scoria.MCP.Tool` and `Scoria.MCP.Executor`, exactly where `Scoria.Trust` sits beside `Scoria.Knowledge`/`Scoria.MCP.Envelope` in Phase 55's layout.

### Pattern 1: Behaviour + `__using__` declaration surface (mirrors `Scoria.SemanticCache.Profile`)

**What:** An `@optional_callbacks` function returning a struct, generated by a `use` macro that captures compile-time options as literal function bodies.
**When to use:** Exactly this case — a per-module static declaration that must never brick an adopter who hasn't implemented it.
**Example (verified against the live file, `lib/scoria/semantic_cache/profile.ex:1-55`):**
```elixir
# Source: lib/scoria/semantic_cache/profile.ex (in-repo, Phase 45-era precedent)
defmodule Scoria.SemanticCache.Profile do
  @callback lane_key() :: String.t()
  @callback default_scope() :: scope_kind()
  @callback safe_read_only?() :: boolean()
  @callback metadata() :: map()

  defmacro __using__(opts) do
    cache_key = Keyword.fetch!(opts, :cache_key)
    default_scope = Keyword.get(opts, :default_scope, :tenant_shared)
    # ... more Keyword.get/3 extraction ...

    quote do
      @behaviour Scoria.SemanticCache.Profile

      @impl true
      def lane_key, do: unquote(cache_key)
      # ... one def per callback, each just returning the captured literal ...
    end
  end
end
```
**Applied to `Scoria.MCP.Tool` (D-01):** the exact same shape, but with `classification/0` marked `@optional_callbacks [classification: 0]` (Profile's four callbacks are ALL required — no `@optional_callbacks` line exists in `profile.ex` today, because every `SemanticCache.Profile` adopter is expected to implement all four). This is the one structural difference the planner must add: Profile's `defmacro __using__` generates `@behaviour` + required `@impl true` defs; the Tool macro must additionally emit `@optional_callbacks` at the behaviour-definition site (in `tool.ex` itself, once, not per-adopter) and the macro-generated `classification/0` def must build a `%Scoria.MCP.Classification{}` struct literal from `reads_private_data:`/`sees_untrusted_content:`/`can_exfiltrate:`/`action_class:` opts, not a bare scalar.

### Pattern 2: `Code.ensure_loaded?/1` + `function_exported?/3` detection idiom

**What:** Safe optional-callback detection that doesn't misread a lazily-loaded module as non-implementing.
**When to use:** Any time code checks whether an `@optional_callbacks` function exists on an arbitrary module handed in at runtime.
**Precision note (verified):** `56-CONTEXT.md` D-01 cites "the idiom already at `executor.ex:678`" for `Code.ensure_loaded?/1` — but the actual line 678 in the live tree is `if function_exported?(tool_module, :name, 0), do: tool_module.name(), else: inspect(tool_module)` (inside `defp tool_name/1`, `executor.ex:677-679`). **This call site does NOT call `Code.ensure_loaded?/1` at all** — it is a bare `function_exported?/3` check. The full `Code.ensure_loaded?/1` + `function_exported?/3` PAIRING that D-01 actually wants is `Scoria.SemanticCache.Profile.describe/1` (`profile.ex:57-76`):
```elixir
# Source: lib/scoria/semantic_cache/profile.ex:57-76 (the actual paired idiom)
def describe(module) when is_atom(module) do
  cond do
    not Code.ensure_loaded?(module) ->
      {:error, :invalid_semantic_cache_lane}

    not function_exported?(module, :lane_key, 0) ->
      {:error, :invalid_semantic_cache_lane}
    # ... one function_exported?/3 clause per required callback ...

    true ->
      normalize_description(module)
  end
end
```
**Recommendation:** copy `Profile.describe/1`'s `cond` shape for `Classification.resolve_tool_declaration/1` — call `Code.ensure_loaded?(tool_module)` once, then `function_exported?(tool_module, :classification, 0)`, not the bare `function_exported?/3` at `executor.ex:678` (which is fine for its own narrow purpose — reading an always-required `name/0` — but is the wrong idiom to imitate for an *optional* callback).

### Pattern 3: Fixed-key attribute projector for trace tagging (mirrors `trust_attributes/1`)

**What:** A function that projects a struct/map onto EXACTLY a closed set of dotted attribute-key strings, never spreading the input map.
**When to use:** Any time a new `scoria.*` attribute group needs to reach a span/telemetry payload without leaking free-form fields.
**Example (verified, `lib/scoria/observe/semconv.ex:276-291,555-563`):**
```elixir
# Source: lib/scoria/observe/semconv.ex
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
**Applied to CLASS-01/02/03:** add a `@classification_keys` list (e.g. `action_class: "scoria.classification.action_class"`, `source: "scoria.classification.source"`, `reads_private_data: "scoria.classification.reads_private_data"`, ...) and a `classification_attributes/1` projector, following the exact same shape. **This registration will trip the `attribute_registry/0` canary test** (`test/scoria/observe/semconv_test.exs:274` `"attribute_registry/0 registry canary (SEC-01 Test 1)"`, which asserts the full sorted key list) — the planner must update that test's expected key list as part of this phase, deliberately, not as an accidental regression.

### Anti-Patterns to Avoid
- **Re-deriving `pure_local?`/`effectful_or_remote?` logic inside `Scoria.MCP.Classification`:** `ReplayDisposition` already owns these predicates and the `@effectful_classes` list. `Scoria.MCP.Classification` must own the enum (`action_classes/0`, `default_action_class/0`, `normalize_action_class/1`) and `ReplayDisposition`'s `@effectful_classes` must **derive from it** (per D-02), not the reverse — otherwise two parallel copies of `~w(read write exec admin)` drift.
- **Writing the resolved classification directly into the seam map's existing prohibited keys** (`:approval_sensitive`, `:local_classification`, `:action_class`, `:risk_level`, `:policy_sensitive`, `:sensitive_tool`) — see `## Common Pitfalls` below for the exact bricking mechanics.
- **Copying `Trust.Scan`'s `most_restrictive/2` operator verbatim for `action_class` joins.** `Scan`'s `@tier_order %{"untrusted" => 0, "trusted" => 1}` takes the **min** (`Map.fetch!(@tier_order, a) <= Map.fetch!(@tier_order, b)` picks the SMALLER-indexed, i.e. more-restrictive-untrusted, value — verified at `lib/scoria/trust/scan.ex:128-130`). `action_class` must tighten **upward** (`read < write < exec < admin`), so the join is **max**, not min. A copy-paste here silently de-escalates every join and no shape-based test catches it (D-04's own warning, now confirmed against the actual operator code).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Optional-callback detection | A bespoke `Code.ensure_loaded?`/`function_exported?` helper scattered ad hoc | `Scoria.SemanticCache.Profile.describe/1`'s exact `cond` shape (copy the pattern into `Scoria.MCP.Classification`) | Already battle-tested in this repo for the identical "optional behaviour resolution, must not brick adopters who skip it" problem |
| Per-module memoization | Hand-rolled `Agent`/`GenServer` cache | `:persistent_term` (already used at `lib/scoria/sre/budget_engine.ex:361-393` for a similar per-key process-cache pattern) | `:persistent_term` reads are effectively free (no message-passing) and this is a per-call hot path per D-01's own framing |
| Bounded callback isolation | Bare `try/rescue` in the caller process | `Task.Supervisor.async_nolink/2` + `Task.yield/2` + `Task.shutdown/2`, exactly as `Scoria.Trust.Scan.run_scanner/3` does (`lib/scoria/trust/scan.ex:94-111`) | A `try/rescue` in the calling process does NOT protect against a hanging/blocking callback (I/O, `Process.sleep`, deadlock) — only isolates raises/throws. Phase 55's own D-20 precedent uses the heavier bounded-Task pattern precisely because a host implementer might do something unexpected inside an "optional" callback. See Open Questions #4 below. |
| Fixed-key trace attribute projection | Ad hoc `Map.take/2` calls scattered at call sites | A `@classification_keys` list + `classification_attributes/1` projector in `Semconv`, mirroring `trust_attributes/1`/`spotlight_attributes/1`/`guardrail_attributes/1` | Structural leak-immunity (a `score`-shaped or free-text field is structurally impossible to emit) is only guaranteed by the fixed-key discipline already established for all three existing projectors |

**Key insight:** every piece of this phase has a direct, already-shipped precedent somewhere in `lib/scoria/` — `Scoria.Trust` (leaf module discipline), `Scoria.SemanticCache.Profile` (optional-callback macro), `Scoria.Runtime.ReleaseGate` (fail-closed-but-inspectable flag), `Scoria.Trust.Scan` (bounded-Task callback isolation), `Semconv.trust_attributes/1` (fixed-key projection), and `MCP.Executor`'s own `persist_taint_to_step/3` (jsonb fragment merge choke point). This is a "wire the same idiom five more times, correctly" phase, not a "design something new" phase.

## Runtime State Inventory

> Included per this research task's explicit instruction to re-verify every D-05 code citation. This is not a rename/refactor phase in the traditional sense, but D-05's citations are exactly the kind of "line numbers may have drifted" risk this section exists to catch.

| Fail-open site | Cited location | Verified location | Drift? | Current default | What breaks if resolution writes here directly |
|---|---|---|---|---|---|
| 1. `build_replay_seam/2` | `executor.ex:181-194` | `executor.ex:181-196` (function body includes 2 more lines than cited — `remote_hint` field + closing brace) | Minor (function is 15 lines, not 13; not a functional drift, just a line-anchor note for task-writing) | `local_classification: :write` (line 183, NOT `:pure`), `action_class: "write"`, `risk_level: "high"`, `approval_sensitive:` falls back to `:policy_sensitive`/`false` | Replay-only; feeds `ReplayDisposition.resolve/5` inside `replay_gate/3`. Writing directly into this seam's returned map bypasses the "tighten-only, no host key = declaration wins" rule (D-04) |
| 2. `policy_sensitive_invocation?/1` | `executor.ex:552-554` | **Exact match** | None | `Map.get(context, :policy_sensitive) \|\| Map.get(context, :sensitive_tool)` — nil-falsy, no explicit default | Live path only. Gates whether a synchronous `tool.invocation` audit-outbox row is written (`ensure_policy_sensitive_invocation/4` at `executor.ex:538-550`) and whether `{:error, _}` aborts the call (`execute_live/4`'s `with` at `executor.ex:40-42`) |
| 3. `budget_required?/1` | `executor.ex:442-447` | **Exact match** | None | `Map.get(context, :estimated_cost_usd) \|\| Map.get(context, :estimated_tokens) \|\| Map.get(context, :estimated_units) \|\| Map.get(context, :sensitive_tool)` | Gates `BudgetEngine.reserve_step/1` (`reserve_budget/3` at `executor.ex:398-422`), a second read-only call site exists at `maybe_emit_budget/4` (`executor.ex:681-696`, not `:682` as a bare line number but the same function) |
| 4. `Connectors.Invocation.build_seam/2` | `invocation.ex:60-75` | `invocation.ex:59-76` (18 lines incl. closing `end`, not 16) | Minor | `action_class: "read"` (line 65), `approval_sensitive: false` (line 67), `local_classification: :read` (line 68) | Computes `replay_resolution/5` at line 26 — **BEFORE** `Executor.execute/4` is ever reached (line 45). A tool routed through `Connectors.Invocation.invoke/4` gets its replay decision made from THIS seam, independent of whatever `MCP.Executor` later resolves. Classification must be injected into `context` before `invoke/4` runs its own `build_seam/2`, or CLASS-03 silently does not cover connector-routed tools |
| 5. `Workflows.Runtime`'s `%{local_classification: :pure}` default | `runtime.ex:474` | **Exact match** | None | `Keyword.get(opts, :replay_seam, %{local_classification: :pure})` inside `replay_execution/8` | **Worst of the five (per D-05).** Total step-granularity replay bypass. `:pure` hits `ReplayDisposition`'s clause 3 (`pure_local?/1`) and short-circuits to `:execute_live` before clause 7 (`effectful_or_remote?/1`) is ever evaluated. Any workflow step handler that does NOT explicitly pass `opts[:replay_seam]` gets this default — silently — on every replay run |

**Additional finding not in D-05's original 5-site list, confirmed by direct code read:** `runtime.ex:993-1001` (cited in D-05's prose, "hardcodes a maximal seam") was NOT independently re-verified in this session (out of the priority-5 list and out of Phase 56 scope per the RAIL-01 split — that code path belongs to `Workflows.ex`'s handoff/other-step machinery, deferred to 56.1 rails scope). Flag for the planner: if a task touches `runtime.ex:993-1001`, re-verify that citation separately; it was not in this session's read set.

**Nothing else found in-repo that fits a "6th fail-open site" pattern:** a targeted grep for `local_classification\|approval_sensitive\|action_class.*"read"\|action_class.*"write"` across `lib/scoria/` (beyond the 5 cited files) returned no additional seam-builder call sites. The five sites in D-05 are exhaustive as far as this session's code search could determine.

## Common Pitfalls

### Pitfall 1: The `pure_local?` short-circuit means seam-key writes are only dangerous on seams that DON'T already hit an earlier `cond` clause

**What goes wrong:** A task naively adds `Map.put(seam, :local_classification, resolved.action_class)` (or similar) to "make classification visible to ReplayDisposition," assuming it's additive.

**Why it happens:** `ReplayDisposition.resolve/5`'s `cond` (lines 21-60) evaluates clauses **in order** and returns on the first match. Clause 3, `pure_local?(seam)` (line 28, reads `Map.get(seam, :local_classification) in [:pure, :local, :in_memory]`), is checked **before** clause 7, `effectful_or_remote?(seam)` (line 55, reads `:approval_sensitive`, `:action_class`, `:risk_level`, AND `:local_classification` again — but against a DIFFERENT list: `[:read, :remote_read, :write, :exec, :admin, :remote]`). Site 5's default seam (`%{local_classification: :pure}`) hits clause 3 and returns `:execute_live` via `"local_safe_to_rerun"` — **before `effectful_or_remote?/1` is ever called.** If resolution logic overwrites `:local_classification` with the tool's resolved `action_class` (e.g. `"admin"`), the seam no longer satisfies clause 3's `in [:pure, :local, :in_memory]` check, falls through the `cond`, and lands in clause 7 — which now matches (`"admin"` is not literally in `[:read, :remote_read, ...]` as an atom, but if resolution ALSO ends up putting the resolved value as an atom `:admin`, it IS in that list) — flipping the call from `:execute_live` to `:blocked`.

**How to avoid:** Resolution must write to brand-new context keys (e.g. `:classification`, or a struct under `context[:tool_classification]`) that `ReplayDisposition` does not read at all. `ReplayDisposition`'s `resolve/5` signature and its 5 input maps (`run`, `seam`, `source_evidence`, `approval_context`, `override_context`) are unchanged by this phase — only the CALLERS that build the `seam` map change, and only by reading the NEW keys as an additional, tighten-only input alongside the seam's EXISTING declared fields, never by overwriting those fields.

**Warning signs:** Any diff that adds a key to `build_replay_seam/2`'s, `Connectors.Invocation.build_seam/2`'s, or `Workflows.Runtime.replay_execution/8`'s existing seam map literal (the `%{...}` under `local_classification:`, `action_class:`, `approval_sensitive:`, `risk_level:` in those three functions) rather than adding a parallel, separately-read field.

### Pitfall 2: `live_override_ready?/2`'s `approval_sensitive` check has an inverted-looking but intentional polarity

**What goes wrong:** Assuming "more restrictive `approval_sensitive: true` is always safer" and writing it unconditionally when a tool's classification implies sensitivity.

**Why it happens:** `live_override_ready?/2` (`replay_disposition.ex:121-126`) is: `policy_ok? and (not truthy?(Map.get(seam, :approval_sensitive)) or replay_approved?)`. If `:approval_sensitive` flips from the host's declared `false` to `true` (because classification resolution wrote it), `not truthy?(...)` becomes `false`, so the clause now requires `replay_approved?` to be true — which most hosts today never set (it comes from `approval_context`, a 5th argument most callers pass as `%{}`). A call that used to satisfy `live_override_ready?/2` and land in clause 5 (`:execute_live`) now fails it and falls through to clause 6 (`:blocked`, `"live_override_requires_policy_and_replay_approval"`).

**How to avoid:** Same fix as Pitfall 1 — never write `:approval_sensitive` directly. The tighten-only join (D-04) happens entirely inside `Scoria.MCP.Classification.resolve/2`'s own logic and is exposed to `ReplayDisposition`/downstream callers as new keys, not as an overwrite of the field `live_override_ready?/2` already reads.

**Warning signs:** Grep the diff for `Map.put(seam, :approval_sensitive` or `|> Map.put(:approval_sensitive` outside of the pre-existing `build_replay_seam/2`/`build_seam/2` host-context-read lines.

### Pitfall 3: `Code.ensure_loaded?/1` alone is not "the idiom at `executor.ex:678`" — don't cite that line as the detection precedent

**What goes wrong:** A task description says "detect via the idiom at `executor.ex:678`" and the implementer copies `function_exported?(tool_module, :classification, 0)` without a preceding `Code.ensure_loaded?/1` call, because that's literally what line 678 does.

**Why it happens:** `executor.ex:678` genuinely is bare `function_exported?/3` with no `Code.ensure_loaded?/1` guard — it works there because `name/0` is a REQUIRED callback (every registered tool module is already loaded by the time `tool_name/1` runs, since `execute/2` was just successfully dispatched to it). `classification/0` is different: it's OPTIONAL, and per D-01's own reasoning, a lazily-loaded module (e.g. under `:interactive` boot mode, or a module referenced by atom before its `.beam` is loaded) would be misread as "doesn't implement `classification/0`" without the `Code.ensure_loaded?/1` guard.

**How to avoid:** Copy `Scoria.SemanticCache.Profile.describe/1`'s full `cond` (`Code.ensure_loaded?/1` THEN `function_exported?/3`), not `executor.ex:678`'s bare check. See Pattern 2 above.

**Warning signs:** A new detection function that calls `function_exported?/3` without a preceding `Code.ensure_loaded?/1` in the same clause chain.

### Pitfall 4: `attribute_registry/0`'s canary test will go RED the moment new `scoria.classification.*` keys are added — this is expected, not a bug to work around

**What goes wrong:** A task adds `classification_attributes/1` + new `@classification_keys` to `Semconv`, runs the focused test suite, sees `test/scoria/observe/semconv_test.exs`'s `"attribute_registry/0 registry canary (SEC-01 Test 1)"` (line 274, asserts an exact sorted key list) go RED, and reverts the registry addition thinking it broke something.

**Why it happens:** This canary test is DESIGNED to fail on any new key (it's the SEC-01 "closed registry, no silent key sprawl" guarantee) — the correct response is to update the test's expected key list, deliberately, in the same commit that adds the keys.

**How to avoid:** Any task that adds classification trace-attribute keys must also update `test/scoria/observe/semconv_test.exs`'s canary assertion list as part of the same task, not as a follow-up fix.

**Warning signs:** A RED `semconv_test.exs` canary after adding new `attribute_registry/0` entries — expected, requires an explicit test-file edit, not a code revert.

## Code Examples

### `require_X` fail-closed-but-inspectable flag (the exact CLASS-02 precedent)

```elixir
# Source: lib/scoria/runtime/release_gate.ex:81-93 (verified against live tree)
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
CLASS-02's `config :scoria, :require_tool_classification` + `[:scoria, :class, :unclassified]` should follow this exact shape: default-off flag reads via `Application.get_env/3`, `:telemetry.execute/3` fires on the ungated path (never on the strict-error path, mirroring this precedent), and the strict path returns a structured `{:error, %{status: :unclassified_tool, ...}}` in the SAME envelope shape as the existing `:access_denied` path (`executor.ex:519-527`, per D-03's own instruction).

### Jsonb fragment merge choke point (the exact D-03 persistence pattern)

```elixir
# Source: lib/scoria/mcp/executor.ex:308-341 (verified against live tree, D-08's
# "scoria.taint" persistence -- D-03 says to reuse this SAME pattern for
# "scoria.classification")
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
D-03's `step.result_envelope["scoria.classification"] = %{...}` write should be a second, near-identical private function (or a parameterized shared helper) following this EXACT `Repo.update_all/2` + `fragment("? || ?", ...)` + `try/rescue -> :ok` best-effort shape — same "no `step_id` in context is not an error" discipline.

### Bounded, isolated Task callback invocation (the actual D-20 precedent for Open Question 4)

```elixir
# Source: lib/scoria/trust/scan.ex:94-111 (verified against live tree)
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
This is a bounded, isolated Task with an internal try/catch AND a timeout — not the caller-process-level `try/catch` CONTEXT.md's Open Question 4 speculatively proposed. Because `classification/0` is memoized ONCE per module (D-01) rather than called per-request, the cost of this heavier pattern is negligible, and it directly neutralizes the open question's own stated concern ("a host doing I/O there would hang the caller"). **Recommendation for the planner: use this exact pattern (a dedicated `Scoria.MCP.TaskSupervisor` or reuse of the existing `Scoria.MCP.TaskSupervisor` already referenced at `executor.ex:387`) for the one-time `classification/0` resolution, not bare `try/rescue`.**

## State of the Art

Not applicable in the traditional "library X replaced library Y" sense — this is a single-repo, single-codebase evolution. The relevant "old -> new" is intra-phase:

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Host passes `approval_sensitive`/`action_class`/`local_classification` per-call via context map, executor trusts it silently | Tool declares trifecta legs once via `classification/0`; executor resolves + tighten-only joins with any host override | This phase (56) | Closes the CLASS-02 fail-open seam; a forgetful/malicious host caller can no longer silently under-declare a sensitive tool's risk |
| `executor.ex:150-165` (pre-Phase-55 citation in the original CLASS-02 requirement text) | `executor.ex:181-196` (`build_replay_seam/2`) + `executor.ex:552-554` (`policy_sensitive_invocation?/1`) | Phase 55 (code moved, not this phase) | The REQUIREMENTS.md citation is already corrected in `56-CONTEXT.md` D-05; no further requirement-text fix needed this phase, only accurate task-level line anchors |

**Deprecated/outdated:** None — no Scoria-internal API is being removed or deprecated by this phase; `Scoria.MCP.Tool`'s 4 existing required callbacks (`name/0`, `description/0`, `input_schema/0`, `execute/2`) are unchanged and remain required.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dedicated `Task.Supervisor` (either reusing `Scoria.MCP.TaskSupervisor` or a new `Scoria.MCP.Classification.TaskSupervisor`) is the right isolation boundary for the ONE-TIME `classification/0` memoization resolution, mirroring D-20's `Scoria.Trust.TaskSupervisor` precedent | Code Examples / Don't Hand-Roll | If wrong (e.g. maintainer prefers bare `try/rescue` given `classification/0` is meant to be a pure constant, per CONTEXT.md's own Open Question 4 framing), the planner should downgrade to `try/rescue` with an explicit documented purity contract — low risk either way since resolution happens once per module, not per-call, so even a hang would only block first-use, not steady-state throughput. This is Open Question 4 in CONTEXT.md, not newly introduced here — flagged as ASSUMED because this session's code evidence (D-20's actual shipped pattern) argues for the heavier option but the maintainer has not confirmed which precedent to follow for this specific optional-and-pure-in-theory callback. |
| A2 | No 6th fail-open site exists beyond the 5 D-05 lists, based on a targeted grep for `local_classification`/`approval_sensitive`/`action_class` literal-string seam-builder patterns across `lib/scoria/` | Runtime State Inventory | If a 6th site exists outside this grep's pattern (e.g. a seam built via a different key name or a computed/interpolated key), CLASS-03's "ALL five fail-open seams" success criterion would understate the true remediation surface. Recommend the planner re-run a broader search (e.g. `grep -rn "local_classification\|:pure\b" lib/scoria/workflows/ lib/scoria/connectors/`) as a pre-flight task before closing CLASS-03. |

## Open Questions

CONTEXT.md's 5 open questions are reproduced with this session's findings layered on top; none are overturned (per this task's explicit instruction not to re-litigate locked recommendations), but 2 and 4 now have direct code evidence rather than inference:

1. **`default_action_class/0` = `"admin"` or `"exec"`?** No new code evidence found this session — genuinely undecidable from the tree, as CONTEXT.md already concluded. Locked to `"admin"` stands.
2. **Proxy/remote MCP tools (`classification/1` vs `classification/0`).** **Confirmed by direct code read this session:** both `Scoria.MCP.Router` (`router.ex:31`, `Map.fetch(tools, request.method)`) and `ScoriaWeb.MCPController` (`mcp_controller.ex:108,134-149`, `find_tool/2`) dispatch strictly 1:1 (one `method`/`name` string maps to exactly one tool module). No in-repo evidence of a module fronting N remote tools. `classification/0` (not `/1`) is correctly scoped; defer `/1` until a proxy tool exists, exactly as CONTEXT.md recommended.
3. **Should `%Classification{}` also absorb `risk_level`/`local_classification`?** No new evidence — CONTEXT.md's "no" recommendation (D-03's write-prohibition already neutralizes them; absorbing `local_classification` would contradict D-02) stands unchanged.
4. **`classification/0` isolation: `try/catch` vs bounded Task.** **Resolved by direct code read this session, but not in the direction CONTEXT.md's open question framed it.** Phase 55's D-20 (cited in CONTEXT.md as the thing to check) shipped a bounded, isolated `Task.Supervisor.async_nolink` + internal `try/catch` + `Task.yield`/`Task.shutdown` (`lib/scoria/trust/scan.ex:94-111`), NOT bare process-level `try/catch`. CONTEXT.md's open question speculated `try/catch` "should be" sufficient because `classification/0` is meant to be pure — that speculation is not what the actual precedent does. This is a genuine decision point for the planner: follow the heavier, precedent-consistent bounded-Task pattern (this research's recommendation, low cost since it's a one-time-per-module memoized call), or deliberately diverge from precedent with a documented rationale (lower implementation complexity, acceptable since `classification/0` has a stated purity CONTRACT even if not structurally enforced). Either choice should be an explicit, named decision in the plan, not an accidental omission.
5. **Is `:policy_sensitive` eventually derived from the classification?** No new evidence — CONTEXT.md's "worth naming, staged deprecation, not this phase" framing stands unchanged.

## Environment Availability

Not applicable — this phase has no external tool/service/runtime dependencies beyond what the existing test suite already requires (Postgres via `SCORIA_DB_PORT`, already documented in `AGENTS.md`). No new environment probes needed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir/OTP, no separate version to pin) |
| Config file | none dedicated — `test/test_helper.exs` + `mix.exs`'s `elixirc_paths(:test)` govern the test tree; no `pytest.ini`/`jest.config.*` equivalent exists in this repo |
| Quick run command | `mix test test/scoria/mcp/executor_test.exs test/scoria/workflows/replay_disposition_test.exs test/scoria/connectors/invocation_test.exs test/scoria/workflows/runtime_span_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` (per `AGENTS.md`: `mix compile --warnings-as-errors` is load-bearing for D-01's `@optional_callbacks` requirement) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLASS-01 | Tool declares trifecta legs + `action_class` once via `classification/0`, absent callback compiles clean under `--warnings-as-errors` | unit | `mix test test/scoria/mcp/classification_test.exs -x --warnings-as-errors` | ❌ Wave 0 — new file |
| CLASS-01 | Existing `@behaviour Scoria.MCP.Tool` fixtures (no `classification/0`) still compile and execute unchanged | integration/regression | `mix test test/scoria/mcp/executor_test.exs --warnings-as-errors` | ✅ exists (`DummyTool`, `ActualUnitsTool`, `BlockingTool` fixtures already implement only the 4 required callbacks — reuse as the "does not brick legacy callers" proof, per this phase's own explicit brief) |
| CLASS-02 | Unclassified tool resolves to the maximal fail-closed default + `[:scoria, :class, :unclassified]` telemetry; `require_tool_classification: true` instead returns `{:error, %{status: :unclassified_tool}}` | unit + telemetry | `mix test test/scoria/mcp/executor_telemetry_test.exs test/scoria/mcp/classification_test.exs --warnings-as-errors` | ❌ Wave 0 for the classification-specific assertions; `executor_telemetry_test.exs` exists as the pattern to extend |
| CLASS-03 | Resolved classification reaches all 5 fail-open sites via new namespaced keys only; a currently-`:execute_live` replay call (`:pure` seam, D-05 site 5) does NOT flip to `:blocked` after wiring | unit (directional, both argument orders per D-04) | `mix test test/scoria/workflows/replay_disposition_test.exs --warnings-as-errors` | ✅ exists — extend with new tests: (a) `join("read","admin") == "admin"` and `join("admin","read") == "admin"` (D-04 directional pair), (b) a regression test asserting the site-5 `%{local_classification: :pure}` default seam STILL resolves `:execute_live` after classification wiring lands |
| CLASS-03 | `Connectors.Invocation.build_seam/2` (site 4) reflects resolved classification before its own `replay_resolution/5` call at line 26 | integration | `mix test test/scoria/connectors/invocation_test.exs --warnings-as-errors` | ✅ exists — extend |
| CLASS-03 | Registry canary (`attribute_registry/0`) updated for new `scoria.classification.*` keys | unit (structural) | `mix test test/scoria/observe/semconv_test.exs --warnings-as-errors` | ✅ exists — MUST be edited (see Pitfall 4), not merely re-run |

### Sampling Rate
- **Per task commit:** the quick-run command above (4 files, DB-backed where needed, `async: false` for `executor_test.exs` per its existing `use ExUnit.Case, async: false` declaration)
- **Per wave merge:** `mix test --warnings-as-errors` (full suite — this repo's CI gate runs the full suite, and `--warnings-as-errors` is explicitly load-bearing for D-01's `@optional_callbacks` correctness, per `AGENTS.md`)
- **Phase gate:** Full suite green before `/gsd-verify-work`, consistent with every prior phase in this milestone

### Wave 0 Gaps
- [ ] `test/scoria/mcp/classification_test.exs` — new file, covers CLASS-01 (struct/enum/macro/detection idiom) and the CLASS-02 unclassified-default + `require_tool_classification` flag behavior
- [ ] `test/scoria/workflows/replay_disposition_test.exs` additions — D-04 directional join tests + the site-5 non-bricking regression test (see table above)
- [ ] `test/scoria/observe/semconv_test.exs` canary list edit — required the moment `classification_attributes/1`'s keys are registered (not a gap in coverage, a REQUIRED edit to an existing structural guard)
- [ ] No new test framework/config install needed — ExUnit + existing `mix.exs` test aliases already cover this domain; there is no dedicated `mix test.classification`-style alias today (unlike `test.knowledge`/`test.connector`), and this research found no evidence one is expected — the planner may add one for developer convenience but it is not required by any existing contract

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Out of scope — this phase governs tool-call risk classification, not identity verification (host-owned per scope doctrine) |
| V3 Session Management | no | Not touched |
| V4 Access Control | yes | Fail-closed-but-inspectable default (D-03) + tighten-only max-join precedence (D-04) is the access-control-adjacent control here — an unclassified tool can never be LESS gated than the maximal default, and a host can never loosen a tool's own declared classification via a per-call, request-derived map (D-04's closing argument: the controller path's context is `Map.new(conn.assigns)`, i.e. request-influenced — loosening authority there would be a privilege-escalation vector) |
| V5 Input Validation | yes | `Scoria.MCP.Classification.normalize_action_class/1` fail-closes any junk `action_class` value to the maximally-restrictive member before any ordinal `Map.fetch!` lookup (mirrors `Semconv.normalize_reason_code/1`'s exact fail-closed idiom, verified at `semconv.ex:487-506`) |
| V6 Cryptography | no | No new cryptographic material this phase (unlike Phase 55's spotlighting nonce) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent under-classification of a sensitive tool (host forgets to pass `approval_sensitive`/`sensitive_tool`, or a malicious/buggy connector omits it) | Elevation of Privilege | CLASS-02's fail-closed maximal default (`reads_private_data: true, sees_untrusted_content: true, can_exfiltrate: true, action_class: "admin"`) — an unclassified tool is now MORE restricted than an under-declared one, not less |
| Request-derived context map used to loosen a tool's declared risk (`mcp_controller.ex:116`'s `Map.new(conn.assigns)` is literally attacker-request-adjacent) | Tampering / Elevation of Privilege | D-04's tighten-only join — a host key can only ADD restriction relative to the tool's own static `classification/0`, never remove it; loosening requires editing the tool module's source (static, reviewable, greppable), not a runtime request path |
| Cascading over-classification causing Phase 57's confluence gate to fire on 100% of legacy traffic (adopter permanently filters/ignores the signal) | Denial of Service (of the security signal itself, not the app) | D-06's obligation: `source: :unclassified_default` is `@enforce_keys` and persisted (D-03), letting Phase 57 give it a separate, operator-selectable disposition from `:tool_declared` — this phase's job is only to make that distinction POSSIBLE, not to implement Phase 57's branching |
| Accidental seam-key clobbering flipping a currently-safe replay call to `:blocked` (functional correctness bug, not classically a security threat, but a fail-**open**-adjacent risk if the fix ever goes the other direction — i.e. a badly-ordered future change could just as easily flip a currently-`:blocked` dangerous call to `:execute_live`) | Tampering (of the replay-safety invariant itself) | Never write into `ReplayDisposition`'s existing read keys (`:approval_sensitive`, `:local_classification`, `:action_class`, `:risk_level`) — always add new, separately-read keys (see Pitfalls 1-2) |

## Sources

### Primary (HIGH confidence — verified in-repo, live tree, this session)
- `lib/scoria/mcp/executor.ex` (full file read) — all 5 fail-open site citations, `persist_taint_to_step/3` jsonb pattern, `tool_name/1` detection idiom, `maybe_wrap_envelope/4` soft-launch flag pattern
- `lib/scoria/mcp/tool.ex` (full file read) — current 4-callback, zero-macro behaviour surface
- `lib/scoria/workflows/replay_disposition.ex` (full file read) — the complete `cond` clause order, all predicate functions, `@effectful_classes` enum
- `lib/scoria/connectors/invocation.ex` (full file read) — `build_seam/2`, `replay_resolution/5` call ordering
- `lib/scoria/workflows/runtime.ex` (full file read) — `replay_execution/8`, site-5 default seam
- `lib/scoria/semantic_cache/profile.ex` (full file read) — the behaviour+`__using__`+detection-idiom template
- `lib/scoria/mcp/router.ex`, `lib/scoria_web/controllers/mcp_controller.ex` (full file reads) — Open Question 2's 1:1 dispatch verification
- `lib/scoria/trust/scan.ex` (full file read) — Open Question 4's bounded-Task isolation precedent
- `lib/scoria/observe/semconv.ex` (partial read, lines 340-600) — `attribute_registry/0`, `trust_attributes/1`/`spotlight_attributes/1`/`guardrail_attributes/1` projector pattern, `normalize_reason_code/1` fail-closed idiom
- `lib/scoria/runtime/release_gate.ex` (full file read) — `require_eval_verdict`/`[:scoria, :release_gate, :ungated]` precedent for D-03's flag
- `test/scoria/mcp/executor_test.exs` (partial read) — existing minimal-callback tool fixtures (`DummyTool` etc.) as the ready-made "doesn't brick legacy callers" test base
- `test/scoria/workflows/replay_disposition_test.exs` (partial read) — hand-built-seam-map unit test style to extend
- `test/scoria/observe/semconv_test.exs` (grep-verified) — canary test location and name
- `AGENTS.md` (full file read) — `--warnings-as-errors` compile constraint, verification command conventions
- `.planning/phases/56-tool-declared-trifecta-classification-per-run-rails/56-CONTEXT.md` — all locked decisions D-01..D-06, deferred D-56.1-*, open questions
- `.planning/phases/55-content-trust-taint-substrate/55-CONTEXT.md` — D-03/D-07/D-08/D-19/D-21/D-22 cross-phase precedent
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — requirement text, phase sequencing, traceability

### Secondary (MEDIUM confidence)
None used — no web/external documentation was consulted this session (this phase has zero external dependencies; the `research-plan` seam's provider config for this project showed `brave_search: false, firecrawl: false, exa_search: false` at init time, and no external lookup was needed given the phase is 100% in-repo).

### Tertiary (LOW confidence)
None.

## Metadata

**Confidence breakdown:**
- Standard stack: N/A (no external stack — HIGH confidence there is nothing to research here)
- Architecture: HIGH — every pattern cited was read directly from the live tree in this session, not from training-data recollection
- Pitfalls: HIGH — all 4 pitfalls trace to specific, quoted, line-numbered code in the live tree, not speculation
- Package legitimacy: N/A — zero packages installed

**Research date:** 2026-07-27
**Valid until:** Until this codebase's `lib/scoria/mcp/`, `lib/scoria/workflows/replay_disposition.ex`, `lib/scoria/connectors/invocation.ex`, or `lib/scoria/workflows/runtime.ex` next change (this is in-repo research, not a stable external API — re-verify line citations if any Wave in this phase's own execution modifies these files ahead of a later Wave that also cites them)
