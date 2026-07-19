# Phase 53B: `ai_span_events` + `emit_event/1` - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 8 source files (1 new migration + 7 modified) + 6 test files
**Analogs found:** 8 / 8 (all files have an exact or role-match in-repo analog; no "no analog" files this phase)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/repo/migrations/<ts>_drop_ai_span_events_span_id_fk.exs` (NEW) | migration | batch/DDL | `priv/repo/migrations/20260519000000_converge_eval_persistence.exs:117,144` | exact (same `execute("ALTER TABLE ... DROP CONSTRAINT IF EXISTS ...")` idiom) |
| `lib/scoria/observe/semconv.ex` (+`@event_names`/`event_names/0`/`event_name?/1`, +`scoria.prompt.template_ref`) | config/vocabulary | CRUD (lookup) | same file, `@guardrail_names`/`guardrail_names/0` at `:246-250` | exact (mirror in same module) |
| `lib/scoria/observe/buffer.ex` (+`events` state, +`cast_event/2`, +two-phase `do_flush`) | service (GenServer) | event-driven / batch | same file — `spans` state + `cast_span/2` (`:14-16`) + `flush_spans/2` (`:101-169`) | exact (mirror in same module) |
| `lib/scoria/observe/telemetry.ex` (+`:event` `handle_event` clause) | event handler | event-driven | same file — span `handle_event` clause `:62-75` | exact (mirror in same module) |
| `lib/scoria/observe.ex` (+`emit_event/1`) | service (public facade) | request-response | `Guardrail.emit/1` (`is_map` shape) + sibling `emit_retriever_span/1`/`emit_prompt_span/1` in same file | exact (mirror in same module) |
| `lib/scoria/observe/guardrail.ex` (+`emit_event` call in `do_emit`) | service | event-driven | same file — `emit_span(span)` call at `:171`, `do_emit`'s existing span-id (`:163`) + decision (`:137`) locals | exact (in-place addition) |
| `lib/scoria/eval/judge_runner.ex` (+pre-mint `span_id` + post-render `emit_event`) | service | request-response | same file — `build_judge_prompt_span/3` (`:197-206`), existing `opts[:span_id]` own-id seam at `observe.ex:372` | exact (in-place addition) |
| `reject_event/2` (new private helper, `telemetry.ex` or `semconv.ex`) | utility | event-driven | `lib/scoria/observe/reviewer_broadcast.ex:93-106` (`:ets.insert_new` once-per-key dedupe) — also `lib/scoria/observe/bounds.ex:385-395` (`first_warning_for_key?/1`, same idiom, same subsystem) | exact |
| `test/scoria/observe/event_emit_test.exs` (NEW) | test | integration | `test/scoria/observe/prompt_span_test.exs` (full file, scoped-Buffer + real `Telemetry.attach/1` + `flush_now`) | exact (scaffold to copy) |
| `test/scoria/observe/semconv_test.exs` (+event vocab tests, +grep guard) | test | unit | same file, anti-inline grep block `:128-142` | exact (mirror in same file) |
| `test/scoria/observe/buffer_test.exs` (+orphan/fail-closed tests) | test | integration | existing file (span flush tests) | role-match |
| `test/scoria/observe/telemetry_test.exs` (+single-redact-site drift guard) | test | unit | same file (existing span/delta handler tests) + `semconv_test.exs:128-142` grep-guard idiom | role-match |
| `test/scoria/eval/judge_runner_test.exs` (+prompt_rendered assertion) | test | integration | existing file (needs confirm-at-plan-time contents) | role-match |

## Pattern Assignments

### `priv/repo/migrations/<ts>_drop_ai_span_events_span_id_fk.exs` (migration, DDL)

**Analog:** `priv/repo/migrations/20260519000000_converge_eval_persistence.exs:117,144`

**Core pattern to copy verbatim (idiom only, adjust table/constraint names):**
```elixir
execute("ALTER TABLE ai_eval_runs DROP CONSTRAINT IF EXISTS ai_eval_runs_dataset_id_fkey")
# ...
execute("ALTER TABLE ai_scores DROP CONSTRAINT IF EXISTS ai_scores_dataset_item_id_fkey")
```
Target statement for this phase:
```elixir
execute("ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey")
```

**Secondary precedent — the FK-free-by-construction shape** (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:19,31,41`):
```elixir
add :parent_id, :binary_id            # ai_spans — no references(), the target end-state shape
create index(:ai_spans, [:parent_id])
# ...
add :span_id, references(:ai_spans, type: :binary_id, on_delete: :delete_all), null: false  # ai_span_events — the FK being dropped
```
**Do NOT cite** `20260712210000_drop_retrieval_run_trace_span_fk.exs` — confirmed absent from the repo (D-00a). Cite only the two files above.

---

### `lib/scoria/observe/semconv.ex` (config/vocabulary, CRUD-lookup)

**Analog:** same file, `@guardrail_names`/`guardrail_names/0` (lines 246-250):
```elixir
@guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)

@doc "Returns the canonical 4-value closed guardrail-name enum."
@spec guardrail_names() :: [String.t()]
def guardrail_names, do: @guardrail_names
```

**Pattern to add (mirror exactly, atoms not strings per D-03a):**
```elixir
@event_names ~w(prompt_rendered guardrail_triggered user_feedback_received)a

@doc "Returns the canonical closed point-event vocabulary."
@spec event_names() :: [atom()]
def event_names, do: @event_names

@spec event_name?(term()) :: boolean()
def event_name?(name), do: name in @event_names
```

**Registry key addition** (`attribute_registry/0` at `:330`, `@attribute_registry` list at `:283-307`): add one new `:id`-class entry `"scoria.prompt.template_ref"`, mirroring the existing `prompt_context_key/0` naming convention (`semconv.ex:126-131`); suggested accessor name `prompt_template_ref_key/0`.

**Reused verbatim, no new projector:** `guardrail_attributes/1` at `:430` — do not create `guardrail_event_attributes/1` (explicitly cut, D-04c).

---

### `lib/scoria/observe/buffer.ex` (service/GenServer, event-driven + batch)

**Analog:** same file — full span pipeline (state at `:33-41`, `cast_span/2` at `:14-16`, `handle_cast` at `:48-55`, `flush_spans/2` at `:101-169`).

**State shape to extend** (current, `:33-41`):
```elixir
state = %{
  spans: [],
  max_size: Keyword.get(opts, :max_size, @default_max_size),
  flush_interval: Keyword.get(opts, :flush_interval, @default_flush_interval),
  name: Keyword.get(opts, :name, __MODULE__),
  on_flush_error: Keyword.get(opts, :on_flush_error, :log),
  consecutive_failures: 0,
  timer: nil
}
```
Add `events: []`, `max_event_size: Keyword.get(opts, :max_event_size, @default_max_size)`, `event_consecutive_failures: 0`.

**`cast_span/2` to mirror for `cast_event/2`:**
```elixir
def cast_span(span_data, name \\ __MODULE__) do
  GenServer.cast(name, {:cast_span, span_data})
end
```
```elixir
def cast_event(event_data, name \\ __MODULE__) do
  GenServer.cast(name, {:cast_event, event_data})
end
```

**`handle_cast` buffer-full drop+warn to mirror** (`:48-55`):
```elixir
def handle_cast({:cast_span, span_data}, state) do
  if length(state.spans) >= state.max_size do
    Logger.warning("Scoria.Observe.Buffer is full (#{state.max_size}), dropping span.")
    {:noreply, state}
  else
    {:noreply, %{state | spans: [span_data | state.spans]}}
  end
end
```

**Two-phase `do_flush` core pattern** (from RESEARCH.md D-02b, matches the existing `flush_spans/2` shape at `:101-169` for Phase 1 — DO NOT modify Phase 1; add Phase 2 as an independent, separately-rescued `Repo.insert_all`):
```elixir
defp do_flush(state, timer_opts) do
  from_timer? = Keyword.get(timer_opts, :from_timer?, false)

  new_span_failures =
    flush_spans(state.spans, %{name: state.name, max_size: state.max_size,
      on_flush_error: state.on_flush_error, consecutive_failures: state.consecutive_failures,
      from_timer?: from_timer?})

  new_event_failures =
    flush_events(state.events, %{name: state.name, max_size: state.max_event_size,
      on_flush_error: state.on_flush_error, consecutive_failures: state.event_consecutive_failures,
      from_timer?: from_timer?})

  %{state | spans: [], events: [],
    consecutive_failures: new_span_failures,
    event_consecutive_failures: new_event_failures}
end
```

**Error-handling pattern to mirror inside `flush_events/2`** — the existing `flush_spans/2` try/rescue at `:131-168` (insert_all bypasses changesets and raises raw Postgrex errors — must catch in `rescue`, never let it crash the GenServer):
```elixir
try do
  case Scoria.Repo.transaction(multi) do
    {:ok, _changes} -> 0
    {:error, failed_op, failed_value, _changes_so_far} ->
      new_count = surface_flush_error(failed_value, dropped_count, opts, nil, "op=#{inspect(failed_op)}: #{inspect(failed_value)}")
      if opts[:on_flush_error] == :raise and opts[:from_timer?] do
        raise "Scoria.Observe.Buffer flush failed (op=#{inspect(failed_op)}): " <> inspect(failed_value)
      end
      new_count
  end
rescue
  e ->
    new_count = surface_flush_error(e, dropped_count, opts, __STACKTRACE__, Exception.message(e))
    if opts[:on_flush_error] == :raise and opts[:from_timer?] do
      reraise e, __STACKTRACE__
    end
    new_count
end
```
For events, replace the `Ecto.Multi` transaction with a plain `Scoria.Repo.insert_all(Scoria.Repo.SpanEvent, event_entries)` call inside an equivalent `try/rescue` — no Multi needed since there's only one table and no FK-ordering requirement anymore (D-01a/D-02b). `surface_flush_error/4` (defined at `:174` onward) should gain a `signal: :span | :event` parameter for the flush-error telemetry dimension (D-02e) — same function, one new parameter, not a new function.

**`Map.put_new_lazy`/timestamp pattern to mirror** (`:106-112`):
```elixir
span_entries =
  Enum.map(spans, fn span ->
    span
    |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
    |> Map.put_new(:inserted_at, now)
    |> Map.put_new(:updated_at, now)
  end)
```
Apply identically to event entries before `insert_all`.

---

### `lib/scoria/observe/telemetry.ex` (event handler, event-driven)

**Analog:** same file — span `handle_event` clause (lines 62-75) is the exact shape to mirror for the new `:event` clause:
```elixir
def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  redacted = Redactor.redact(metadata)

  case Bounds.enforce(redacted, :span) do
    {:ok, bounded} ->
      ReviewerBroadcast.span_stopped(bounded)
      Buffer.cast_span(buffer_span(bounded), buffer_name)

    :drop ->
      :ok
  end
end
```
New clause to add (per D-03/D-05/D-06 ordering — allow-list re-check → redact → fail-closed time/span_id seam → Bounds → cast):
```elixir
def handle_event([:scoria, :observe, :event, :emit], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  name = Map.get(metadata, :name)

  if Semconv.event_name?(name) do
    redacted = redact(metadata)

    with %{} = safe <- fail_closed_seam(redacted) do
      case Bounds.enforce(safe, :event) do
        {:ok, bounded} -> Buffer.cast_event(buffer_event(bounded), buffer_name)
        :drop -> reject_event(name, :bounds)
      end
    else
      :drop -> reject_event(name, :fail_closed_seam)
    end
  else
    reject_event(name, :unknown_name)
  end
end
```
(Illustrative shape — exact control flow is planner/executor discretion per CONTEXT D-03b/D-05a; the two hard requirements are: (1) `Semconv.event_name?/1` is re-checked here independently of `emit_event/1`, and (2) `time` defaults to `DateTime.utc_now()` / nil `span_id` drops, BEFORE `Bounds.enforce`.)

**`@events` list to extend** (`:7-10`):
```elixir
@events [
  [:scoria, :observe, :span, :stop],
  [:scoria, :observe, :span, :delta]
]
```
Add `[:scoria, :observe, :event, :emit]`.

**Redact collapse (D-03d) — current TWO call sites to collapse to ONE `defp redact/1`:**
- Delta arm, line 55: `metadata |> Redactor.redact() |> scrub_delta_chunk() |> cap_delta_chunk()`
- Span arm, line 65: `redacted = Redactor.redact(metadata)`

Target: introduce `defp redact(m), do: Redactor.redact(m)` and have all handler clauses (span, delta, new event) call `redact/1` instead of `Redactor.redact/1` directly, so exactly one `Redactor.redact(` token remains in this file.

**Drift-guard test scope (critical correction from RESEARCH.md):** `Redactor.redact(` has 5 total call sites repo-wide (`orchestrator_live.ex:269`, `sre.ex:367`, `telemetry.ex:55`, `telemetry.ex:65`, `remote_approval_projection.ex:154`). The single-call-site assertion MUST be scoped via `File.read!("lib/scoria/observe/telemetry.ex")` only — a repo-wide grep will always fail.

**Buffer-field projector to mirror** (`@span_buffer_fields` at `:77-80`):
```elixir
@span_buffer_fields ~w(id trace_id parent_id name span_kind status_code start_time end_time attributes)a

defp buffer_span(bounded) do
  Map.take(bounded, @span_buffer_fields)
  ...
end
```
Mirror with `@event_buffer_fields ~w(span_id name time attributes)a` and `defp buffer_event/1`.

---

### `lib/scoria/observe.ex` (public facade, request-response)

**Analog (shape):** `Guardrail.emit/1`'s `is_map` guard shape + sibling `emit_retriever_span/1`/`emit_prompt_span/1` in this same file.

**Pattern (from RESEARCH.md Pattern 2, verified against `semconv.ex`'s `@guardrail_names`/`guardrail_name?` shape):**
```elixir
def emit_event(%{name: name} = event) when is_map(event) do
  if Semconv.event_name?(name) do
    :telemetry.execute([:scoria, :observe, :event, :emit], %{}, event)
    :ok
  else
    {:error, :unknown_event}
  end
rescue
  _ -> :ok
end
```
Never raises (`try/rescue → :ok`, matching Phase 51 D-05..D-09 loud-but-non-fatal posture). `:name` must be an atom — never `String.to_atom` on inbound data (membership-check only).

**Own-id opt seam this phase reuses** (`observe.ex:372`, inside `build_span_map/7`'s private helper):
```elixir
id: opts[:span_id] || Ecto.UUID.generate(),
```
`with_prompt/3` (lines 153-154) is the thin wrapper `judge_runner.ex` threads `span_id` through.

---

### `lib/scoria/observe/guardrail.ex` (in-place addition, event-driven)

**Analog:** same file — `do_emit/1` (starts line 131), span id at `:163`, decision at `:137`, `emit_span(span)` call at `:171`.

**Current state (verified unmodified) — the "free DRY hook":**
```elixir
defp do_emit(input) do
  gate_name = Map.get(input, :name)
  # ... existing span-building code ...
  # line 163: id: Map.get(input, :span_id) || Ecto.UUID.generate(),
  # line 137: decision: Map.get(input, :decision),
  emit_span(span)   # line 171
end
```

**Pattern to add immediately after `emit_span(span)` (D-04a):**
```elixir
decision = Map.get(input, :decision)
if decision not in [nil, "allow"] do
  Scoria.Observe.emit_event(%{
    name: :guardrail_triggered,
    span_id: Map.get(input, :span_id) || span.id,
    time: end_time,
    attributes: Semconv.guardrail_attributes(%{
      name: gate_name,
      decision: decision,
      reason_code: Map.get(guardrail_fields, :reason_code)
    })
  })
end
```
All 5 real callers (`runtime.ex:131,154`, `workflows/runtime.ex:417,434,452`) get this for free — do not modify caller sites. Outer `emit/1`'s existing `try/rescue → :ok` (lines 125-129) already covers this addition.

---

### `lib/scoria/eval/judge_runner.ex` (in-place addition, request-response)

**Analog:** same file — `build_judge_prompt_span/3` (private, lines 197-206), current shape does NOT pass `:span_id` (confirmed by RESEARCH.md — real, needed edit).

**Pattern to add (D-04b, pre-mint + emit-after-success only):**
```elixir
defp build_judge_prompt_span(dataset_item, subject_output, attrs, eval_spec) do
  span_id = fetch(attrs, :span_id) || Ecto.UUID.generate()

  result =
    Observe.with_prompt(
      "eval.judge_prompt",
      %{
        trace_id: fetch(attrs, :trace_id) || Ecto.UUID.generate(),
        parent_id: fetch(attrs, :parent_id),
        span_id: span_id
      },
      fn -> build_judge_prompt(dataset_item, subject_output) end
    )

  Observe.emit_event(%{
    name: :prompt_rendered,
    span_id: span_id,
    time: DateTime.utc_now(),
    attributes: %{Semconv.prompt_template_ref_key() => "eval-spec-v#{eval_spec.version}"}
  })

  result
end
```
`span/4` reraises on error, so a raised render never reaches the `emit_event` call — no event on failure (correct per D-04b). The free-text `explanation:` literals live at `judge_runner.ex:168,227` (RESEARCH corrected from CONTEXT's `:167,:202`) — both fire strictly after this event, so they can never leak into it.

---

### `reject_event/2` (new private helper)

**Analog:** `lib/scoria/observe/reviewer_broadcast.ex:93-106` — `:ets.insert_new` once-per-key idiom:
```elixir
def first_span_for_trace?(trace_id) do
  ensure_trace_seen_table()
  :ets.insert_new(@trace_seen_table, {trace_id, true})
end
```
Equally valid closer-subsystem analog: `lib/scoria/observe/bounds.ex:385-395` (`first_warning_for_key?/1`, identical `:ets.insert_new` shape, same module family this phase extends — either is fine per RESEARCH.md, `Bounds`'s is arguably the tighter match since it's in the same subsystem).

**Pattern:** `reject_event(name, source)` should emit `[:scoria, :observe, :event, :rejected]` telemetry unconditionally, and gate the `Logger.warning` behind an ETS `insert_new` keyed on `name` (once-per-name-per-node), following the `ensure_trace_seen_table/0` lazy-create pattern.

---

### Test files

**`test/scoria/observe/event_emit_test.exs` (NEW)** — analog: `test/scoria/observe/prompt_span_test.exs` (full file, 85+ lines read). Copy this scaffold exactly:
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

  buffer_name = :"event_emit_test_buffer_#{System.unique_integer([:positive])}"

  pid =
    start_supervised!(
      Supervisor.child_spec(
        {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
        id: buffer_name
      )
    )

  :telemetry.detach("scoria-observe-telemetry")
  Scoria.Observe.Telemetry.attach(buffer_name)

  on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

  %{buffer: buffer_name, buffer_pid: pid}
end
```
Use the same `emit_and_flush/2` pattern (calls the real public emitter, then `Buffer.flush_now(buffer_name)`, no `Process.sleep`) — do NOT hand-synthesize a `:telemetry.execute` call for the "real emission" proofs; DO use raw `:telemetry.execute` deliberately for the SC#2 raw-bus-bypass canary (that IS the point of that specific test).

**`test/scoria/observe/semconv_test.exs`** — analog: same file, anti-inline grep block lines 128-142:
```elixir
test "anti-inline grep: no lib consumer file inlines the \"scoria.retrieval.\" literal" do
  consumer_files = [
    "lib/scoria/knowledge.ex",
    "lib/scoria/observe.ex",
    "lib/scoria/observe/adapters/req_llm.ex",
    "lib/scoria/observe/adapters/jido.ex"
  ]

  for path <- consumer_files, File.exists?(Path.expand(path, File.cwd!())) do
    source = path |> Path.expand(File.cwd!()) |> File.read!()

    refute source =~ "scoria.retrieval.",
           "#{path} must call Semconv.retrieval_config_keys/0, never inline a scoria.retrieval.* literal"
  end
end
```
Mirror for D-04d's `user_feedback_received` zero-emitter guard: assert no `lib/` file contains `name: :user_feedback_received` as a literal.

## Shared Patterns

### Fail-closed try/rescue at every emit boundary
**Source:** `lib/scoria/observe/guardrail.ex` `emit/1` (lines 125-129, existing) and the target pattern for `Observe.emit_event/1`.
**Apply to:** `emit_event/1`, the new `:event` telemetry handler clause, `flush_events/2` in Buffer.
```elixir
rescue
  _ -> :ok
end
```
Never let observability plumbing crash host business logic or the Buffer GenServer.

### `insert_all` bypasses changesets — the only real guarantee is DB `NOT NULL` + handler seam
**Source:** `lib/scoria/observe/buffer.ex:129` (existing span comment/precedent).
**Apply to:** `SpanEvent` flush path. `SpanEvent.changeset/2`'s `validate_required([:span_id, :name, :time])` is irrelevant to `insert_all` — the handler's D-05a fail-closed seam (default `time`, drop nil `span_id`) is the actual guarantee.

### Once-per-key ETS dedupe for warning/log storm control
**Source:** `lib/scoria/observe/reviewer_broadcast.ex:93-106` / `lib/scoria/observe/bounds.ex:385-395`.
**Apply to:** `reject_event/2`'s once-per-name-per-node `Logger.warning`.

### Fixed-key `Map.take` projection — never spread host input
**Source:** `lib/scoria/observe/telemetry.ex:77-80` (`@span_buffer_fields` + `buffer_span/1`) and `semconv.ex:430-437` (`guardrail_attributes/1`, `Enum.reduce` over a fixed keyword list).
**Apply to:** `buffer_event/1` (fixed keys `~w(span_id name time attributes)a`) and the `prompt_rendered` attribute payload (fixed key `scoria.prompt.template_ref` only).

### Real-Postgres integration test discipline — never hand-synthesize telemetry
**Source:** `test/scoria/observe/prompt_span_test.exs` (full scaffold, see excerpt above).
**Apply to:** All new SC#1/SC#3/SC#4 integration tests. Exception: the SC#2 raw-bus-bypass canary deliberately DOES use raw `:telemetry.execute/3` because that IS the attack surface under test.

## No Analog Found

None — every file this phase touches has an exact or role-match in-repo analog (this phase is explicitly "mirror, never invent" per RESEARCH.md's "Don't Hand-Roll" table).

## Metadata

**Analog search scope:** `lib/scoria/observe/`, `lib/scoria/eval/`, `lib/scoria/repo/`, `priv/repo/migrations/`, `test/scoria/observe/`, `test/scoria/eval/` — all files independently re-read this session plus content carried from 53B-RESEARCH.md's own verified anchor citations.
**Files scanned:** `buffer.ex`, `telemetry.ex`, `semconv.ex` (x2 reads), `observe.ex` (via RESEARCH), `guardrail.ex` (via RESEARCH), `judge_runner.ex` (via RESEARCH), `bounds.ex`/`redactor.ex`/`reviewer_broadcast.ex` (via RESEARCH), 2 migrations (via RESEARCH), `prompt_span_test.exs`, `semconv_test.exs` (x1 direct read + RESEARCH).
**Pattern extraction date:** 2026-07-18
