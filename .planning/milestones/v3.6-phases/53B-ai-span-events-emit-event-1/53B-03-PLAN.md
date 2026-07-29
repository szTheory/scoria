---
phase: 53B-ai-span-events-emit-event-1
plan: 03
type: execute
wave: 2
depends_on: [53B-01, 53B-02]
files_modified:
  - lib/scoria/observe.ex
  - lib/scoria/observe/telemetry.ex
  - CHANGELOG.md
  - test/scoria/observe/telemetry_test.exs
  - test/scoria/observe/observe_test.exs
autonomous: true
requirements: [EVENT-02]
must_haves:
  truths:
    - "Scoria.Observe.emit_event/1 takes a single map %{name: atom, span_id: binary, attributes: map, time: DateTime.t()}, up-front checks Semconv.event_name?/1 (returns {:error, :unknown_event} for a non-member), executes [:scoria, :observe, :event, :emit] telemetry for a member, and NEVER raises (try/rescue → :ok) (D-03a/D-03b)."
    - "The [:scoria, :observe, :event, :emit] handler is the boundary of record: it INDEPENDENTLY re-checks Semconv.event_name?/1 (catches the raw-bus SC#2 bypass), then redact → fail-closed seam → Bounds.enforce(_, :event) → Buffer.cast_event (D-03b/D-05/D-06)."
    - "The fail-closed seam defaults missing time to DateTime.utc_now() and DROPS (via reject_event) a nil span_id BEFORE Bounds.enforce — the only two NOT NULL raise classes reachable via the raw bus are closed at the handler (D-05a)."
    - "telemetry.ex has exactly ONE Redactor.redact( token: span, delta, and event clauses all funnel through a single defp redact/1 (D-03d)."
    - "The event tuple is added to Telemetry.attach/1's @events; without it the handler never fires (D-03f). Bounds.enforce(_, :event) is activated (no new Bounds code, D-06a)."
  artifacts:
    - "Scoria.Observe.emit_event/1"
    - "Telemetry [:scoria, :observe, :event, :emit] handle_event clause; @events entry; defp redact/1; @event_buffer_fields + buffer_event/1; reject_event/2"
    - "[:scoria, :observe, :event, :rejected] telemetry event"
  key_links:
    - "emit_event/1 and the handler both call Semconv.event_name?/1 (Plan 01) — neither inlines a name list (anti-divergence lock, D-03b)."
    - "The handler calls Buffer.cast_event/2 (Plan 02) with a fixed-key buffer_event/1 projection."
    - "reject_event/2 reuses the ETS once-per-key dedupe idiom from reviewer_broadcast.ex / bounds.ex."
---

<objective>
Build the phase's HARD PREREQUISITE: the public `Scoria.Observe.emit_event/1` verb and the `[:scoria, :observe, :event, :emit]` telemetry handler that every path (direct call AND raw bus) funnels through. The handler is the boundary of record — it re-checks the allow-list, collapses redaction to a single shared call site, closes the two NOT NULL raise classes (`time`, `span_id`) reachable via the raw bus, activates `Bounds.enforce(_, :event)`, and casts to the Buffer event list.

Purpose: SC#1 (identical redact), SC#2 (allow-list re-check incl. raw bus), SEC-01 (Bounds :event), and D-05 (fail-closed batch atomicity) all converge in this handler; it gates EVENT-03's real call sites (Plan 04) and every SC canary (Plan 05).
Output: `emit_event/1`, the handler clause + `@events` entry + single `defp redact/1` + `reject_event/2` + `buffer_event/1`, a CHANGELOG entry, and the single-call-site drift guard + emit_event return-contract unit test.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-CONTEXT.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-RESEARCH.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-PATTERNS.md

@lib/scoria/observe.ex
@lib/scoria/observe/telemetry.ex
@lib/scoria/observe/bounds.ex
@lib/scoria/observe/reviewer_broadcast.ex
@lib/scoria/observe/redactor.ex
@test/scoria/observe/telemetry_test.exs
</context>

<artifacts>
NEW symbols this plan produces:
- `Scoria.Observe.emit_event/1`
- `Telemetry` `[:scoria, :observe, :event, :emit]` `handle_event/4` clause
- `Telemetry` `@events` gains `[:scoria, :observe, :event, :emit]`
- `Telemetry` `defp redact/1` (the single collapsed redaction call site)
- `Telemetry` `@event_buffer_fields ~w(span_id name time attributes)a` + `defp buffer_event/1`
- `Telemetry` `defp reject_event/2` + the `[:scoria, :observe, :event, :rejected]` telemetry event
</artifacts>

<tasks>

<task type="auto">
  <name>Task 1: Scoria.Observe.emit_event/1 + moduledoc + CHANGELOG</name>
  <files>lib/scoria/observe.ex, CHANGELOG.md</files>
  <read_first>
    - lib/scoria/observe.ex:212 (emit_retriever_span/1), :277 (emit_prompt_span/1), :154 (with_prompt/3), :372 (the id: opts[:span_id] || generate own-id seam)
    - lib/scoria/observe/semconv.ex (event_name?/1 from Plan 01)
    - CHANGELOG.md:151-153 (the existing Unreleased / 0.1.4 heading)
  </read_first>
  <action>
    Add `emit_event(%{name: name} = event) when is_map(event)` beside `emit_retriever_span/1`/`emit_prompt_span/1` (D-03a — observe-domain fact, NOT top-level Scoria). If `Semconv.event_name?(name)` → `:telemetry.execute([:scoria, :observe, :event, :emit], %{}, event)` and return `:ok`; else return `{:error, :unknown_event}` (synchronous DX + a clean bus — do NOT execute telemetry for an unknown name). Wrap in `rescue _ -> :ok` (never raises, Phase 51 D-05..D-09 continuity). `:name` is an ATOM checked by membership only — NEVER `String.to_atom` on inbound data (D-03a). Add a moduledoc/doc note on `emit_event/1`: the closed vocabulary, that `user_feedback_received` is reserved-only (SEED-011 / FB-01, D-04d), and the D-00b forward flag (if Scoria ever adds an OTLP exporter, `guardrail_triggered` must be exported as a log record / separate signal, NEVER an OTel span event). Add a CHANGELOG entry under the existing Unreleased heading (:151) announcing the new `emit_event/1` public surface + the reserved point-event vocabulary, and stating the deliberate v3.6 gap: a fired `guardrail_triggered` lands in Postgres with NO operator UI yet (Phase 53 D-08 / D-07).
  </action>
  <verify>
    <automated>mix test test/scoria/observe/observe_test.exs 2>&amp;1 | tail -10</automated>
  </verify>
  <acceptance_criteria>
    - `Scoria.Observe.emit_event(%{name: :prompt_rendered, span_id: id, attributes: %{}, time: DateTime.utc_now()})` returns `:ok`.
    - `Scoria.Observe.emit_event(%{name: :not_a_real_event, span_id: id})` returns `{:error, :unknown_event}` and executes NO telemetry.
    - emit_event/1 never raises (a deliberately malformed input still returns `:ok` or `{:error, :unknown_event}`, never an exception).
    - No `String.to_atom` on the name path; moduledoc cites the reserved-only + OTLP-export forward flag; CHANGELOG Unreleased names the new surface + the no-operator-UI gap.
  </acceptance_criteria>
  <done>emit_event/1 exists as an observe-domain, never-raising, allow-list-gated public verb; the public surface + deliberate gap are documented.</done>
</task>

<task type="auto">
  <name>Task 2: :event telemetry handler — allow-list re-check, single redact, fail-closed seam, Bounds, cast_event</name>
  <files>lib/scoria/observe/telemetry.ex</files>
  <read_first>
    - lib/scoria/observe/telemetry.ex:7-10 (@events, event tuple ABSENT today), :55 + :65 (the TWO Redactor.redact( sites to collapse), :62-75 (span handle_event clause incl. Bounds.enforce(_, :span) case at :67-74), :77-80 (@span_buffer_fields + buffer_span/1), :12 (attach/1)
    - lib/scoria/observe/bounds.ex:137 (enforce/2 already accepts :event — activate only, D-06)
    - lib/scoria/observe/reviewer_broadcast.ex:93-106 OR lib/scoria/observe/bounds.ex:385-395 (ETS :ets.insert_new once-per-key dedupe idiom)
    - lib/scoria/observe/semconv.ex (event_name?/1)
  </read_first>
  <action>
    Add `[:scoria, :observe, :event, :emit]` to `@events` (:7-10) so `attach/1` subscribes it (D-03f — verified absent; without it the handler never fires). Add a new `handle_event([:scoria, :observe, :event, :emit], _measurements, metadata, %{buffer_name: buffer_name})` clause mirroring the span clause (:62-75) with this order (D-03/D-05/D-06): (1) read `name = Map.get(metadata, :name)` and RE-CHECK `Semconv.event_name?(name)` independently of emit_event/1 (D-03b — this is the SC#2 raw-bus boundary of record; unknown → `reject_event(name, :unknown_name)`, STOP); (2) `redacted = redact(metadata)` via the collapsed helper; (3) fail-closed seam (D-05a — NEW handler logic, NOT in Bounds): default a missing/nil `time` to `DateTime.utc_now()`; if `span_id` is nil → `reject_event(name, :nil_span_id)` and STOP (never reaches insert_all); (4) `case Bounds.enforce(safe, :event) do {:ok, bounded} -> Buffer.cast_event(buffer_event(bounded), buffer_name); :drop -> reject_event(name, :bounds) end` (D-06 — activates the already-built/unit-tested :event arm, same {:ok,_}|:drop contract as :span). Collapse redaction to ONE `defp redact(m), do: Redactor.redact(m)` and route the span (:65), delta (:55), and new event clauses all through `redact/1` so exactly ONE `Redactor.redact(` token remains in this file (D-03d). Add `@event_buffer_fields ~w(span_id name time attributes)a` and `defp buffer_event(bounded)` mirroring `buffer_span/1` (:77-80) — fixed-key `Map.take`, never spread host input. Add `defp reject_event(name, source)`: emit `[:scoria, :observe, :event, :rejected]` telemetry UNCONDITIONALLY, and gate a `Logger.warning` (microcopy naming the fix: "edit Semconv @event_names") behind an ETS `:ets.insert_new` keyed on `name` (once-per-name-per-node, D-03e) using the lazy-create table pattern from the cited analog. Never persist a rejected event.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/telemetry_test.exs 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - `@events` contains `[:scoria, :observe, :event, :emit]`.
    - Exactly one `Redactor.redact(` token exists in `lib/scoria/observe/telemetry.ex` (span/delta/event all call `defp redact/1`).
    - The handler re-checks `Semconv.event_name?/1`, defaults `time`, drops nil `span_id` via `reject_event`, calls `Bounds.enforce(_, :event)`, and casts via `buffer_event/1`.
    - `reject_event/2` emits `[:scoria, :observe, :event, :rejected]` every time and logs at most once per name per node.
    - `mix compile --warnings-as-errors` clean.
  </acceptance_criteria>
  <done>The event handler is the boundary of record: independent allow-list re-check, single redaction site, fail-closed time/span_id seam, Bounds :event activation, fixed-key cast, deduped rejection.</done>
</task>

<task type="auto">
  <name>Task 3: Single-redact-site drift guard + emit_event return-contract unit test</name>
  <files>test/scoria/observe/telemetry_test.exs, test/scoria/observe/observe_test.exs</files>
  <read_first>
    - test/scoria/observe/semconv_test.exs:128-142 (File.read!/1 + count/refute source-scan template)
    - test/scoria/observe/telemetry_test.exs (existing span/delta handler tests)
    - test/scoria/observe/observe_test.exs (existing structure)
  </read_first>
  <action>
    In telemetry_test.exs, add a source-scan drift guard (D-03d) that reads ONLY `lib/scoria/observe/telemetry.ex` via `File.read!/1` and asserts exactly ONE `Redactor.redact(` occurrence in that file. CRITICAL: scope to this file path alone — a repo-wide grep will always fail because `Redactor.redact(` has 5 legitimate call sites across lib/ (orchestrator_live.ex:269, sre.ex:367, telemetry.ex x2, remote_approval_projection.ex:154) per RESEARCH. Count occurrences of the token in the single file's source; assert the count is 1. In observe_test.exs, add a unit test for `emit_event/1`'s synchronous return contract: a known name returns `:ok`, an unknown name returns `{:error, :unknown_event}`, and a malformed map never raises. (The full DB-persistence rejection proof for both the direct and raw-bus paths — SC#2 — is Plan 05; this is the fast synchronous contract only.)
  </action>
  <verify>
    <automated>mix test test/scoria/observe/telemetry_test.exs test/scoria/observe/observe_test.exs 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - The drift guard reads `lib/scoria/observe/telemetry.ex` by literal path (never `Path.wildcard`) and asserts exactly 1 `Redactor.redact(` occurrence; it fails if a second is reintroduced.
    - The emit_event contract test proves `:ok` for a member, `{:error, :unknown_event}` for a non-member, and no-raise for a malformed input.
    - Both test files green.
  </acceptance_criteria>
  <done>The single-call-site redaction invariant and emit_event's return contract are locked by fast, correctly-scoped tests.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| host/adapter → `emit_event/1` | Public API; validates name up-front for good DX. |
| raw `:telemetry.execute` → `:event` handler | The bypass path that skips `emit_event/1` entirely — the handler is the ONLY boundary of record. |
| handler → Buffer | Only redacted, bounded, fixed-key-projected, non-null events cross into the durable path. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-53B-01 | Information Disclosure | event attributes redaction | high | mitigate | Single shared `defp redact/1` (D-03d) — span, delta, event funnel through one `Redactor.redact/1` call site (recurses into nested :attributes); fixed-key `buffer_event/1` projection never spreads host input; drift guard asserts exactly one call site. Integration proof: SC#1 in Plan 05. |
| T-53B-02 | Tampering/EoP (of vocabulary) | raw-bus name bypass | high | mitigate | Handler re-checks `Semconv.event_name?/1` independently of `emit_event/1` (D-03b); unknown → `reject_event`, never persisted. SC#2 proof in Plan 05. |
| T-53B-03 | Tampering (data integrity) | fail-closed seam | high | mitigate | Default `time`, drop nil `span_id` BEFORE Bounds (D-05a) — the only two NOT NULL raise classes reachable via the raw bus are closed at the handler, so batch atomicity is safe with zero per-event savepoints. |
| T-53B-04 | Information Disclosure | free-text leak | high | mitigate | Fixed-key `~w(span_id name time attributes)a` projection + `Bounds.enforce(_, :event)` closed registry — free-text (e.g. a judge explanation) can never reach a persisted event even if passed. |
| T-53B-SC | Tampering | package installs | low | accept | No new packages; mix.exs untouched. |
</threat_model>

<verification>
- `mix test test/scoria/observe/telemetry_test.exs test/scoria/observe/observe_test.exs` green.
- `mix compile --warnings-as-errors` clean.
- Manual grep confirmation: exactly one `Redactor.redact(` in telemetry.ex (also asserted by the drift guard).
</verification>

<success_criteria>
`emit_event/1` and the `:event` handler exist; the handler is the boundary of record (independent allow-list re-check, single redaction site, fail-closed time/span_id seam, Bounds :event activation, fixed-key cast_event, deduped rejection). Gates EVENT-03 (Plan 04) and all SC canaries (Plan 05).
</success_criteria>

<output>
Create `.planning/phases/53B-ai-span-events-emit-event-1/53B-03-SUMMARY.md` when done.
</output>
