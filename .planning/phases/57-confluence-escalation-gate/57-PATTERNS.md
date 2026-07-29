# Phase 57: Confluence Escalation Gate - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 15 (new + modified)
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/confluence.ex` (new) | service/classifier | transform (pure) | `lib/scoria/workflows/replay_disposition.ex` | exact |
| `lib/scoria/confluence/evidence.ex` (new, may be inline) | model (struct) | transform | `lib/scoria/mcp/classification.ex` (`%Classification{}`) | exact |
| `lib/scoria/mcp/executor.ex` (modified — `scan_tool_output/2` fix + gate insertion) | controller/orchestrator | request-response | `lib/scoria/knowledge.ex` (`aggregate_incoming_tier/1` — the correct mint pattern) | exact (for the fix) |
| `lib/scoria/trust/verdict.ex` (modified — add `:scanner_tier`) | model | transform | itself (additive field) | exact |
| `lib/scoria/workflows/runtime.ex` (modified — new exit clause) | service/runtime | event-driven | existing `{:exit, reason}` clause at same function | exact |
| `lib/scoria/workflows/resume.ex` (modified — `retry_failed_step/2` guard) | service | CRUD | itself + `lib/scoria/workflows.ex` (`halt_run/3` guard style) | role-match |
| `lib/scoria/observe/semconv.ex` (modified — `@confluence_keys` + `confluence_attributes/1` + registry) | utility/projector | transform | `trust_attributes/1` / `classification_attributes/1` in same file | exact |
| `lib/scoria/sre.ex` (reused unmodified — new call sites elsewhere) | service | event-driven | `create_audit_outbox_event/1` / `build_audit_metadata/1` | exact |
| `lib/scoria_web/approval_copy.ex` (modified — evidence rows) | component/view-helper | transform | itself (`request_rows/1`/`evidence_rows/1`) | exact |
| `priv/repo/migrations/<ts>_add_confluence_columns.exs` (new) | migration | batch | `priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs` | exact |
| `lib/scoria/adopter_doc_contract.ex` (modified — D-53) | config/contract | transform | itself | exact |
| `guides/scoria-vs-external-llm-ops.md` (modified — D-53) | doc | — | itself | exact |
| `test/scoria/confluence_test.exs` (new) | test | transform | `test/scoria/workflows/replay_disposition_test.exs` (property-style enum coverage), `test/scoria/observe/semconv_test.exs` (canary style) | exact |
| `test/scoria/mcp/executor_test.exs` (modified) | test | request-response | itself | exact |
| `test/scoria/workflows/runtime_test.exs` (modified) | test | event-driven | itself | exact |
| `test/scoria/observe/semconv_test.exs` (modified) | test | transform | itself | exact |
| `test/scoria/adoption_surface_test.exs` (modified) | test | transform | itself | exact |

## Pattern Assignments

### `lib/scoria/confluence.ex` (service/classifier, pure transform)

**Analog:** `lib/scoria/workflows/replay_disposition.ex:13-61`

**Core pattern — `cond` ladder returning `{atom, evidence}`** (verified in worktree):
```elixir
# Source: lib/scoria/workflows/replay_disposition.ex:13-61
@spec resolve(map(), map(), map(), map(), map()) :: {disposition(), map()}
def resolve(run, seam, source_evidence, approval_context, override_context) do
  # normalize_map/1 each operand ...
  cond do
    replay_mode?(run) == false ->
      {:execute_live, evidence(:execute_live, "run_not_in_replay_mode", seam, source_evidence, true)}
    authority_expanding?(seam) ->
      {:blocked, evidence(:blocked, "authority_expanding_change", seam, source_evidence, false)}
    # ... more clauses ...
    true ->
      {:execute_live, evidence(:execute_live, "local_safe_to_rerun", seam, source_evidence, true)}
      # DO NOT MIRROR THIS in Confluence.classify/1 — D-06 requires the
      # terminal clause to be {:unevaluable, "confluence_resolver_fallthrough"}
      # (unreachable-by-construction, fail-neither-open-nor-escalate).
  end
end
```

**What to copy:** the `cond`-ladder shape, the `{atom, %Evidence{}}` return contract, operands passed as plain struct arguments (no context map, no aliasing of `Semconv`/`Workflows`/`Trust`/`MCP.Executor` per D-03). Diverge deliberately at the terminal clause (D-06) — comment the divergence in the moduledoc.

**Struct precedent — `@derive Jason.Encoder` closed struct** (mirror `%Classification{}`):
```elixir
# Pattern to mirror: lib/scoria/mcp/classification.ex — @enforce_keys + @derive Jason.Encoder,
# closed enum fields, no reason/note/score field (classification.ex:38-45 shape).
```

**Reason-code enum precedent — domain-owned closed enum, never widen Semconv's**:
```elixir
# Source: lib/scoria/trust/verdict.ex:35-59 shape — mirror exactly for
# Confluence.reason_codes/0 + normalize_reason_code/1 (D-09). Fallback: "unknown".
```

---

### `lib/scoria/mcp/executor.ex` — D-01 fix at `scan_tool_output/2`

**Analog (the CORRECT pattern to copy):** `lib/scoria/knowledge.ex:427-448`

```elixir
# Source: lib/scoria/knowledge.ex:427-448 (verified)
defp resolve_trust_attributes(result_rows, opts) do
  scanner = Keyword.get(opts, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))
  incoming_tier = aggregate_incoming_tier(result_rows)

  {:ok, verdict} =
    Trust.scan(%{chunks: result_rows}, %{content_scanner: scanner, incoming_tier: incoming_tier})
end

defp aggregate_incoming_tier(result_rows) do
  Enum.reduce(result_rows, "trusted", fn row, acc ->
    if Trust.tier(row.metadata) == "untrusted", do: "untrusted", else: acc
  end)
end
```

**The bug to fix** (verified at `lib/scoria/mcp/executor.ex:526-541`):
```elixir
defp scan_tool_output({:ok, value}, context) do
  scanner = Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scanner.NoOp))
  {:ok, verdict} = Trust.scan(value, Map.put(context, :content_scanner, scanner))
  # No :incoming_tier set -> Trust.Scan.scan/2 defaults to Trust.default_tier()
  # ("untrusted"), and most_restrictive/2 is min-wins, so result is ALWAYS
  # "untrusted" regardless of scanner verdict.
  # Fix: Map.put(context, :incoming_tier, "trusted") — a freshly minted tool
  # output has no PRIOR taint, so "trusted" is correct here (mint, not read).
end
```

**Executor top-of-file imports/alias convention** (verified `executor.ex:1-22`):
```elixir
defmodule Scoria.MCP.Executor do
  import Ecto.Query, warn: false
  require Logger

  alias Scoria.MCP.Classification
  alias Scoria.MCP.Envelope
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.SRE.BudgetEngine
  alias Scoria.SRE.BreakerRegistry
  alias Scoria.SRE
  alias Scoria.SRE.Telemetry
  alias Scoria.Trust
  alias Scoria.Trust.Scanner
  alias Scoria.Workflows
  alias Scoria.Workflows.Rails
  alias Scoria.Workflows.ReplayDisposition
  alias Scoria.Workflows.Run
  alias Scoria.Workflows.Step
  # Per D-03, do NOT add `alias Scoria.Confluence` reasoning to Confluence
  # itself — but the EXECUTOR (caller) legitimately aliases it here.
```

**Pipeline ordering to extend** (verified `executor.ex:31-63`, this is where the gate slots in per D-14 — between `replay_gate/3`'s `{:continue, context}` and `execute_live/4`):
```elixir
def execute(tool_module, args, context, timeout \\ 5000) do
  context = canonical_context(context || %{})

  case admit_tool_call_rail(context, tool_module) do
    {:ok, context} ->
      context = Map.delete(context, :rail_admission)

      case resolve_classification(tool_module, context) do
        {:ok, context} ->
          case replay_gate(tool_module, args, context) do
            {:continue, context} ->
              # <<< NEW: Confluence gate slots here (D-14) >>>
              execute_live(tool_module, args, context, timeout)

            other ->
              other
          end

        other ->
          other
      end

    {:error, envelope} ->
      {:error, envelope}
  end
end
```

**Atomic single-statement CAS shape (for D-15 leg-accumulator fold and D-26 approval-consume CAS)** — analog `lib/scoria/workflows/rails.ex:110-124`:
```elixir
# Source: lib/scoria/workflows/rails.ex:110-124 (admit_tool_call/2, verified)
def admit_tool_call(run_id, now \\ DateTime.utc_now()) do
  query =
    from(r in Run,
      where: r.id == ^run_id,
      where: is_nil(r.rail_max_tool_calls) or r.rail_tool_calls < r.rail_max_tool_calls,
      select: r.rail_tool_calls
    )

  case Repo.update_all(query, inc: [rail_tool_calls: 1]) do
    {1, [count]} -> {:ok, count}
    {0, _} -> :denied
  end
end
# D-17's confluence_legs fold and D-26's approval-consume CAS both need this
# exact shape: single statement (use `returning:` instead of `inc:` where the
# updated value itself — not a count — must be read back), {N, result} match,
# no read-then-write round trip.
```

---

### `lib/scoria/trust/verdict.ex` — add `:scanner_tier`

**Analog:** itself, current struct shape (`verdict.ex:26`, D-01 part b): `[:tier, :score, :reason_code, :scanner]` → add `:scanner_tier`. This is additive only; the monotonic law (`tier` stays clamped) is untouched. `scanner_tier` carries the scanner's raw pre-clamp opinion as evidence, never authority.

---

### `lib/scoria/workflows/runtime.ex` — new escalation exit clause

**Analog:** the existing `{:exit, reason}` clause in the same `case`, immediately below the insertion point (verified `runtime.ex:769-770` area):
```elixir
# Source: lib/scoria/workflows/runtime.ex (verified, exact lines ~760-771)
{:ok, {:error, reason}} ->
  {:error, {:handler_error, reason, elapsed_ms(started_at)}}

{:ok, other} ->
  {:ok, {:other, other, elapsed_ms(started_at)}}

nil ->
  {:error, {:timeout, elapsed_ms(started_at)}}

{:exit, reason} ->
  {:error, {:execution_failed, reason, elapsed_ms(started_at)}}
```

**New clause to add ABOVE the generic `{:exit, reason}` clause** (must be a more specific pattern match, ordered first):
```elixir
{:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} ->
  {:ok, {:waiting_for_approval, attrs, elapsed_ms(started_at)}}

{:exit, reason} ->
  {:error, {:execution_failed, reason, elapsed_ms(started_at)}}
```

**Why `exit({:shutdown, ...})` and not `raise`:** D-20, measured — `exit({:shutdown, term})` from a `Task.Supervisor.async_nolink` task yields `{:exit, {:shutdown, term}}` at `Task.yield` with no SASL log line, and is defeated only by the rare `catch :exit` (not the common `try/rescue _ ->`).

---

### `lib/scoria/observe/semconv.ex` — `@confluence_keys` + `confluence_attributes/1`

**Analog:** `@trust_keys` / `trust_attributes/1` and `@classification_keys` / `classification_attributes/1`, same file (verified `semconv.ex` ~283-330):
```elixir
# Source: lib/scoria/observe/semconv.ex (verified, keyword-list-of-pairs shape)
@trust_keys [
  tier: "scoria.trust.tier",
  scanner: "scoria.trust.scanner",
  reason_code: "scoria.trust.reason_code",
  scanned_count: "scoria.trust.scanned_count"
]

@classification_keys [
  action_class: "scoria.classification.action_class",
  source: "scoria.classification.source",
  reads_private_data: "scoria.classification.reads_private_data",
  sees_untrusted_content: "scoria.classification.sees_untrusted_content",
  can_exfiltrate: "scoria.classification.can_exfiltrate"
]
```

**Projector — no-passthrough fixed-key reduce** (verified pattern, `trust_attributes/1`/`classification_attributes/1` are byte-identical in shape):
```elixir
def trust_attributes(input) when is_map(input) do
  Enum.reduce(@trust_keys, %{}, fn {field, key}, acc ->
    case Map.get(input, field) do
      nil -> acc
      value -> Map.put(acc, key, value)
    end
  end)
end
# confluence_attributes/1 MUST follow this exact reduce-over-@confluence_keys
# shape — NEVER Map.merge(%{...}, input) (that would leak arbitrary fields
# through the drop-list-vs-allowlist gap D-39 warns about elsewhere).
```

**New keys to add** (D-08):
```elixir
@confluence_keys [
  combination: "scoria.confluence.combination",
  decision: "scoria.confluence.decision",
  grade: "scoria.confluence.grade",
  reason_code: "scoria.confluence.reason_code",
  approval_ref: "scoria.confluence.approval_ref"
]
```

**Enum precedent to reuse verbatim (`decision`):**
```elixir
# Source: lib/scoria/observe/semconv.ex (verified)
@guardrail_decisions ~w(allow block escalate)
def guardrail_decisions, do: @guardrail_decisions
# scoria.confluence.decision reuses this exact 3-value set — do not invent
# a parallel enum.
```

**Registry canary — DO NOT widen `guardrail_reason_codes/0` or `guardrail_names/0`:**
```elixir
# Source: lib/scoria/observe/semconv.ex (verified)
@guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)
@guardrail_reason_codes ~w(
  unapproved_draft eval_not_passing eval_required approval_required
  budget_rejected breaker_open
)
# Both pinned by exact-match tests in test/scoria/observe/semconv_test.exs.
# Confluence gets its OWN reason-code enum (Confluence.reason_codes/0,
# mirroring Trust.Verdict.reason_codes/0) instead of widening these.
```

**`@attribute_registry` addition** — add the 5 new `scoria.confluence.*` keys with their classes (`:enum`/`:id`) to the `Map.merge(%{...}, ...)` registry (verified registry construction begins ~`semconv.ex:399`), and to the sorted canary literal in `test/scoria/observe/semconv_test.exs` (currently pins an exact 44-key list — becomes 49).

---

### `lib/scoria/sre.ex` — audit outbox write (reused unmodified, new call site elsewhere)

**Analog:** `create_audit_outbox_event/1` / in-txn insert / metadata drop-list / dedupe-key builder, all in this file (verified):
```elixir
# Source: lib/scoria/sre.ex (verified, ~line 374-416) — DROP-LIST not allowlist
defp build_audit_metadata(envelope) do
  envelope
  |> normalize_envelope()
  |> Map.drop([
    :actor_id, :actor_ref, :alert_event_id, :approval_id, :args, :arguments,
    :attempt_count, :dedupe_key, :event_type, :payload_hash, :pending_at,
    :policy_class, :raw_args, :redacted_refs, :sent_at, :sink_status,
    :step_id, :tenant_id, :trace_id, :workflow_run_id, :session_id,
    # ... same keys duplicated as strings ...
  ])
  |> Enum.into(%{}, fn {key, value} -> {to_string(key), normalize_ref_value(value)} end)
  |> stringify_nested_keys()
end

defp build_audit_dedupe_key(envelope) do
  [
    Map.get(envelope, :event_type) || Map.get(envelope, "event_type"),
    Map.get(envelope, :tenant_id) || Map.get(envelope, "tenant_id"),
    Map.get(envelope, :approval_id) || Map.get(envelope, "approval_id"),
    Map.get(envelope, :trace_id) || Map.get(envelope, "trace_id"),
    Map.get(envelope, :access_decision) || Map.get(envelope, "access_decision")
  ]
  |> Enum.reject(&is_nil/1)
  |> Enum.join(":")
end
```

**Why this matters for D-42:** the auto dedupe key collapses to `event_type:tenant_id:<run_id>` when `approval_id`/`access_decision` are both nil (which they are for a confluence row written BEFORE the approval exists) — pass `dedupe_key` **explicitly** as `"tool.confluence.escalated:<run_id>:<step_id>:<args_fingerprint>"` rather than relying on the auto-builder.

**Verdict rides `metadata` as projector output, never a spread** (D-39) — reuse `Confluence`'s own small evidence map, feed it through a dedicated small projector (mirroring `confluence_attributes/1`'s shape, not `build_audit_metadata/1`'s drop-list — this is a NEW small closed map, not the general envelope).

---

### `lib/scoria/observe/approval.ex` — schema fields already present, reuse verbatim

**Analog:** itself — verified schema (`ai_approvals`) already has `blocker_kind` and `blocker_audit_outbox_event_id`:
```elixir
# Source: lib/scoria/observe/approval.ex (verified schema excerpt)
schema "ai_approvals" do
  field(:tool_name, :string)
  field(:arguments, :map, default: %{})
  field(:status, :string, default: "pending")
  field(:blocker_kind, :string)
  field(:blocker_workflow_event_id, :binary_id)
  field(:blocker_audit_outbox_event_id, :binary_id)
  field(:audit_outbox_event_id, :binary_id)
  field(:replay_disposition, :string)
  # ...
end
```
No new fields needed for `blocker_kind: "confluence"` linkage — set the existing columns exactly as `Connectors.Auth` already does (`auth.ex:325-328,348-349`). New migration-only additions: `consumed_at` + `consumed_by_step_id` (D-26) — these must appear in the schema/migration but **never** in `Approval.changeset/2`'s `cast/3` list (disjointness rule, mirrors the `Run.changeset/2` pattern below).

---

### `lib/scoria/workflows/run.ex` — counter/changeset writer disjointness (pattern to mirror for `confluence_legs`)

**Analog:** itself, verified cast list + load-bearing comment (`run.ex:66-118` area):
```elixir
# Source: lib/scoria/workflows/run.ex (verified)
def changeset(run, attrs) do
  run
  |> cast(attrs, [
    :session_id, :actor_id, :tenant_id, :root_role_id, :source_run_id,
    :source_checkpoint_id, :status, :execution_mode, :replay_overrides,
    :current_step_id, :latest_checkpoint_id, :lock_version, :metadata,
    :error_envelope, :started_at, :completed_at, :last_heartbeat_at,
    # Only the three configured LIMITS are cast here. The four
    # counter/pause fields (:rail_steps, :rail_tool_calls, :rail_paused_ms,
    # :rail_paused_at) are DELIBERATELY absent -- see the LOAD-BEARING
    # comment below for why that separation is load-bearing.
    :rail_max_steps, :rail_max_tool_calls, :rail_max_active_ms
  ])
  |> validate_replay_allowlist_immutability()
  |> derive_rail_pause_accounting()
  |> validate_required([:root_role_id, :status])
  |> validate_inclusion(:status, @statuses)
  # ...
  |> optimistic_lock(:lock_version)
end

# LOAD-BEARING: counter fields are never cast by changeset/2 -- written
# only by Repo.update_all(inc: ...) / returning: updates, which never
# touch :lock_version, so the increment can never provoke
# Ecto.StaleEntryError. The two writer classes are disjoint by
# construction, not by convention.
```

**Apply verbatim to `confluence_legs`:** it must NOT appear in `Run.changeset/2`'s `cast/3` list (D-15) — same disjointness rule, same reasoning, same style of load-bearing comment placed just above/below the cast list. Ship the structural test asserting its absence (mirrors whatever existing test asserts `:rail_steps`/`:rail_tool_calls` absence, if one exists — grep `test/scoria/workflows/run_test.exs`).

---

### `priv/repo/migrations/<ts>_add_confluence_columns.exs` (new, consolidated)

**Analog:** `priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs` (verified, full file read):
```elixir
defmodule Scoria.Repo.Migrations.AddRailColumnsToAiWorkflowRuns do
  use Ecto.Migration

  def up do
    alter table(:ai_workflow_runs) do
      add_if_not_exists :rail_max_steps, :integer
      add_if_not_exists :rail_max_tool_calls, :integer
      add_if_not_exists :rail_max_active_ms, :bigint
      add_if_not_exists :rail_steps, :bigint, null: false, default: 0
      add_if_not_exists :rail_tool_calls, :bigint, null: false, default: 0
      add_if_not_exists :rail_paused_ms, :bigint, null: false, default: 0
      add_if_not_exists :rail_paused_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:ai_workflow_runs) do
      remove_if_exists :rail_paused_at
      remove_if_exists :rail_paused_ms
      remove_if_exists :rail_tool_calls
      remove_if_exists :rail_steps
      remove_if_exists :rail_max_active_ms
      remove_if_exists :rail_max_tool_calls
      remove_if_exists :rail_max_steps
    end
  end
end
```

**Apply to D-47's consolidated migration:**
```elixir
def up do
  alter table(:ai_workflow_runs) do
    add_if_not_exists :confluence_legs, :map, null: false, default: %{}
  end

  alter table(:ai_approvals) do
    add_if_not_exists :consumed_at, :utc_datetime_usec
    add_if_not_exists :consumed_by_step_id, :binary_id
  end

  create_if_not_exists index(:ai_audit_outbox_events, [:tenant_id, :event_type, "inserted_at DESC"])
end
```
Note: Postgres `'{"a":1}'::jsonb || NULL` is `NULL` — the `null: false, default: %{}` is load-bearing (Pitfall 2), not stylistic. House style: `add_if_not_exists`/`remove_if_exists`, no backfill (catalog-only default), comment block referencing decision IDs, "never edit this file after release" footer.

---

### `lib/scoria_web/approval_copy.ex` — D-48 evidence rows

**Analog:** itself, current `request_rows/1`/`evidence_rows/1` shape (verified fixed-row + `detail/1` fallthrough at `approval_copy.ex:309-329`). Add rows for: combination label (D-49's enum→string mapping, `"exfiltration_path"` → `"Private data + untrusted content + external egress → exfiltration path"` verbatim, U+2192 not `->`), the three legs with sources, and the grade. Tone: `:fail` for `exfiltration_path`, `:warn` for the three 2-leg combinations, `:neutral` fallback for single-leg/`none` (never raise on an unknown value).

---

### `lib/scoria/adopter_doc_contract.ex` + `guides/scoria-vs-external-llm-ops.md` + `test/scoria/adoption_surface_test.exs` — D-53

**Analog:** itself, three-file coupled edit. Verified: `adopter_doc_contract.ex:86` requires the literal denial sentence; `:96-97` forbid `"Rule-of-Two"`/`"lethal-trifecta enforcement"` in the current-claims section; guide line `guides/scoria-vs-external-llm-ops.md:84` currently carries the denial; asserted by `test/scoria/adoption_surface_test.exs:253-280`. Edit all three atomically, and add a POSITIVE assertion (guide MUST contain a confluence claim) so the *absence* of the edit fails loud, not just the presence of forbidden strings.

---

### Test files

- `test/scoria/confluence_test.exs` (new) — analog: property-style enum coverage pattern used for `ReplayDisposition` (grep `test/scoria/workflows/replay_disposition_test.exs` for the per-clause table-driven style) plus the exact-match canary style from `test/scoria/observe/semconv_test.exs`. Cover all 8 combination inputs (D-05) and the 4-grade weakest-evidence ranking (D-29).
- `test/scoria/mcp/executor_test.exs` (modified) — extend existing `describe` blocks; add a new `describe "confluence gate"` block per the RESEARCH.md test map; regression-test the D-01 fix (assert a `"trusted"` outcome is reachable, not just `"untrusted"` everywhere).
- `test/scoria/workflows/runtime_test.exs` (modified) — new case for the `{:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}}` clause resolving to `{:ok, {:waiting_for_approval, attrs, elapsed_ms}}`.
- `test/scoria/observe/semconv_test.exs` (modified) — canary literal update (44 → 49 keys, verified count), new exact-match tests for `@confluence_keys`/`confluence_attributes/1`, assert `guardrail_names/0`/`guardrail_reason_codes/0` remain unwidened.
- `test/scoria/adoption_surface_test.exs` (modified) — positive assertion per D-53.

## Shared Patterns

### No-passthrough fixed-key projector (Semconv family)
**Source:** `lib/scoria/observe/semconv.ex` — `trust_attributes/1`, `classification_attributes/1`
**Apply to:** `Semconv.confluence_attributes/1` (new). Always `Enum.reduce(@keys, %{}, fn {field,key}, acc -> ... end)`, never `Map.merge`/spread.

### Pure `cond`-ladder classifier returning `{atom, evidence}`
**Source:** `lib/scoria/workflows/replay_disposition.ex:13-61`
**Apply to:** `Scoria.Confluence.classify/1`. Deliberately diverge at the terminal clause (D-06) — do not mirror the fail-open fallthrough.

### Atomic single-statement CAS (`Repo.update_all` with `where` guard)
**Source:** `lib/scoria/workflows/rails.ex:110-124` (`admit_tool_call/2`)
**Apply to:** D-17's `confluence_legs` merge+read fold, D-26's approval-consume CAS. Always `{N, result}` pattern match, never read-then-write.

### Counter/changeset writer disjointness
**Source:** `lib/scoria/workflows/run.ex:66-118` (the LOAD-BEARING comment)
**Apply to:** `confluence_legs` (excluded from `Run.changeset/2` cast), `consumed_at`/`consumed_by_step_id` (excluded from `Approval.changeset/2` cast, opposite-polarity rule per D-26).

### Migration house style
**Source:** `priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs`
**Apply to:** D-47's consolidated migration. `add_if_not_exists`/`remove_if_exists`, explicit `null:`/`default:`, no backfill, decision-ID comment block, "never edit after release" footer.

### Reuse existing lifecycle functions, never reimplement
**Source:** `lib/scoria/workflows.ex` (`mark_waiting_for_approval/3`, `resume_run/1`, `approve/3`, `halt_run/3`)
**Apply to:** GATE-02's pause (D-19, D-46) — zero new lifecycle functions; only widen `resume_run/1`'s three predicates (D-26) and add the escalation-exit clause to `runtime.ex`.

### Domain-owned closed enum without widening Semconv's frozen one
**Source:** `lib/scoria/trust/verdict.ex:35-59` (`reason_codes/0`)
**Apply to:** `Confluence.reason_codes/0` (D-09) — never touch `Semconv.guardrail_reason_codes/0`, which is pinned by an exact-equality test.

### Config resolution: never at boot, log-once on typo, tighten-only precedence
**Source:** `lib/scoria/runtime/rails.ex` (`validate_app_env/0`, two-rung `Application.get_env` resolution)
**Apply to:** `Confluence`'s own config surface and `validate_app_env/0` (D-32, D-33, D-34).

## No Analog Found

None — every file in scope has a strong (exact or role-match) analog already in the codebase, consistent with RESEARCH.md's conclusion that this phase is pure composition, not new mechanism.

## Metadata

**Analog search scope:** `lib/scoria/`, `lib/scoria_web/`, `priv/repo/migrations/`, `test/scoria/` (targeted reads guided by RESEARCH.md's pre-verified file:line citations; no blind directory-wide search was needed since RESEARCH.md already identified every load-bearing seam).
**Files scanned:** ~15 source files directly read/grepped this session (`executor.ex`, `knowledge.ex`, `trust/verdict.ex`, `workflows/replay_disposition.ex`, `workflows/runtime.ex`, `workflows/rails.ex`, `workflows/run.ex`, `observe/semconv.ex`, `observe/approval.ex`, `sre.ex`, the latest rail migration, plus CONTEXT.md/RESEARCH.md's own verified excerpts for `mcp/classification.ex`, `approval_copy.ex`, `adopter_doc_contract.ex`, `runtime_span_test.exs`).
**Pattern extraction date:** 2026-07-28
