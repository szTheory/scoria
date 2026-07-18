---
phase: 53B-ai-span-events-emit-event-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - priv/repo/migrations/<ts>_drop_ai_span_events_span_id_fk.exs
  - lib/scoria/observe/semconv.ex
  - test/scoria/observe/semconv_test.exs
autonomous: true
requirements: [EVENT-02, EVENT-03]
must_haves:
  truths:
    - "A new core-lane migration drops the ai_span_events.span_id FK; an event row whose span_id has no matching span becomes INSERTABLE rather than raising Postgrex 23503 (D-01a — gates SC#4)."
    - "The migration keeps ai_span_events.span_id NOT NULL and its index (D-01b)."
    - "Semconv exposes a closed 3-atom event vocabulary via event_names/0 + event_name?/1 that cannot widen without editing @event_names (D-03c)."
    - "scoria.prompt.template_ref is registered as an :id-class attribute key with a prompt_template_ref_key/0 accessor (D-04c)."
    - "No lib/ file wires a user_feedback_received emitter — a grep-guard goes RED if one is added (D-04d)."
  artifacts:
    - "priv/repo/migrations/<ts>_drop_ai_span_events_span_id_fk.exs (core-lane)"
    - "Semconv.@event_names, Semconv.event_names/0, Semconv.event_name?/1"
    - "Semconv scoria.prompt.template_ref registry key + Semconv.prompt_template_ref_key/0"
  key_links:
    - "Semconv.event_name?/1 is the single membership source of truth consumed by both emit_event/1 and the :event telemetry handler (both built in Plan 03) — neither may inline a name list."
    - "The FK drop is the DB-level half of the D-01 orphan-isolation guarantee; the separate event transaction (Plan 02) is the other half."
---

<objective>
Lay the two greenfield foundations that gate everything downstream: (1) the core-lane migration that DROPs the immediate FK on `ai_span_events.span_id` so an orphan event is insertable, not fatal (D-01a — the DB half of SC#4); and (2) the closed `Semconv` event vocabulary (`@event_names` / `event_names/0` / `event_name?/1`) plus the one new `scoria.prompt.template_ref` registry key that the emitter, handler, and judge call site all consume.

Purpose: SC#4's "an orphan event can never take down a batch of good spans" is only reachable once the DB-level FK is gone; the allow-list (SC#2) and the drift-proof vocabulary only exist once `Semconv` owns them.
Output: one new migration, the `Semconv` vocabulary + registry additions, and the unit + grep-guard tests that lock them.
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

# Real-code anchors (verify line numbers at edit time)
@priv/repo/migrations/20260519000000_converge_eval_persistence.exs
@priv/repo/migrations/20260510015813_create_ai_observability_tables.exs
@lib/scoria/observe/semconv.ex
@test/scoria/observe/semconv_test.exs
</context>

<artifacts>
NEW symbols this plan produces (downstream consumers depend on these):
- The new migration file `priv/repo/migrations/<ts>_drop_ai_span_events_span_id_fk.exs`
- `Semconv.@event_names` (`~w(prompt_rendered guardrail_triggered user_feedback_received)a`)
- `Semconv.event_names/0`, `Semconv.event_name?/1`
- Registry key string `"scoria.prompt.template_ref"` (class `:id`) + accessor `Semconv.prompt_template_ref_key/0`
</artifacts>

<tasks>

<task type="auto">
  <name>Task 1: Core-lane migration dropping the ai_span_events.span_id FK</name>
  <files>priv/repo/migrations/&lt;ts&gt;_drop_ai_span_events_span_id_fk.exs</files>
  <read_first>
    - priv/repo/migrations/20260519000000_converge_eval_persistence.exs:117,144 (the REAL in-repo `execute("ALTER TABLE ... DROP CONSTRAINT IF EXISTS ...")` precedent)
    - priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:19,31,41 (ai_spans.parent_id FK-free-by-construction end-state; ai_span_events.span_id:41 is the exact FK being dropped)
  </read_first>
  <action>
    Create a new core-lane migration (NOT dev-only) whose `up` runs `execute("ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey")`, following the D-00a precedent at converge_eval_persistence.exs:117,144. Do NOT drop or alter the `span_id` column itself and do NOT touch its index — `span_id` stays NOT NULL and indexed (D-01b: orphans persist dangling, never null). Provide a `down` that re-adds the constraint via `execute("ALTER TABLE ai_span_events ADD CONSTRAINT ai_span_events_span_id_fkey FOREIGN KEY (span_id) REFERENCES ai_spans(id) ON DELETE CASCADE")` so rollback is exact. Leave the `Scoria.Repo.SpanEvent` `belongs_to`/`has_many` Ecto associations untouched (D-01c — dropping the DB constraint breaks no reader; there is no join on ai_span_events anywhere in lib/). Do NOT cite the phantom `20260712210000_*` migration anywhere (D-00a).
  </action>
  <verify>
    <automated>mix ecto.migrate 2>&1 | tail -5 &amp;&amp; mix ecto.rollback --step 1 2>&1 | tail -3 &amp;&amp; mix ecto.migrate 2>&1 | tail -3</automated>
  </verify>
  <acceptance_criteria>
    - `mix ecto.migrate` applies the new migration with no error.
    - After migrate, `psql`/Ecto reflection shows constraint `ai_span_events_span_id_fkey` ABSENT (verify via `SELECT conname FROM pg_constraint WHERE conname = 'ai_span_events_span_id_fkey'` returning 0 rows, or an inline test that inserts an `ai_span_events` row with a `span_id` that matches no `ai_spans` row and succeeds).
    - `mix ecto.rollback --step 1` then `mix ecto.migrate` round-trips cleanly (rollback re-adds, re-migrate re-drops).
    - `span_id` column remains NOT NULL and its index remains present after migrate.
  </acceptance_criteria>
  <done>The immediate FK on ai_span_events.span_id is dropped in a core-lane migration; an orphan event is insertable; column stays NOT NULL + indexed; rollback/reapply is exact.</done>
</task>

<task type="auto">
  <name>Task 2: Add the closed event vocabulary + template_ref registry key to Semconv</name>
  <files>lib/scoria/observe/semconv.ex</files>
  <read_first>
    - lib/scoria/observe/semconv.ex:246-250 (@guardrail_names/guardrail_names/0 — the exact shape to mirror)
    - lib/scoria/observe/semconv.ex:283-307 (@attribute_registry list), :330 (attribute_registry/0), :126-131 (prompt_context_key/0 naming convention), :430 (guardrail_attributes/1 — reused verbatim later, do NOT add a new projector)
  </read_first>
  <action>
    Mirror `@guardrail_names`/`guardrail_names/0` (semconv.ex:246-250) to add `@event_names ~w(prompt_rendered guardrail_triggered user_feedback_received)a` (ATOMS, per D-03a — drift-proof, pattern-matchable), plus `event_names/0` returning `@event_names` and `event_name?(name)` returning `name in @event_names` (membership only — NEVER `String.to_atom` on inbound data, D-03a). Add a short moduledoc/attr note on `@event_names` stating that `user_feedback_received` is reserved-only in v3.6 with NO emitter — its emission is SEED-011 / FB-01 (D-04d). Add one new `:id`-class registry entry with the exact key STRING `"scoria.prompt.template_ref"` to `@attribute_registry` (:283-307) and an accessor `prompt_template_ref_key/0` returning that string, mirroring `prompt_context_key/0` (:126-131) per D-04c. Do NOT add `scoria.prompt.tokens` and do NOT add `guardrail_event_attributes/1` (both cut, D-04c). Do NOT inline the `"scoria.prompt."` literal anywhere except this registry declaration.
  </action>
  <verify>
    <automated>mix compile --warnings-as-errors 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `Semconv.event_names/0` returns exactly `[:prompt_rendered, :guardrail_triggered, :user_feedback_received]`.
    - `Semconv.event_name?(:prompt_rendered)` is `true`; `Semconv.event_name?(:nope)` and `Semconv.event_name?("prompt_rendered")` (string) are `false`.
    - `Semconv.prompt_template_ref_key/0` returns `"scoria.prompt.template_ref"` and that key is admitted by `Semconv.attribute_registry/0` as class `:id`.
    - No `String.to_atom` appears on any inbound-name path; `mix compile --warnings-as-errors` is clean.
  </acceptance_criteria>
  <done>The 3-atom closed vocabulary and the one new template_ref registry key exist in Semconv, mirroring the guardrail-name shape; no new projector, no tokens key.</done>
</task>

<task type="auto">
  <name>Task 3: Vocabulary unit tests + user_feedback_received zero-emitter grep guard</name>
  <files>test/scoria/observe/semconv_test.exs</files>
  <read_first>
    - test/scoria/observe/semconv_test.exs:128-142 (the existing anti-inline grep-guard template — hardcoded consumer path list, File.read!/1 guarded by File.exists?/1, refute source =~ literal)
  </read_first>
  <action>
    Add a describe block asserting the vocabulary contract: `event_names/0` returns the exact 3-atom list; `event_name?/1` is `true` for each member and `false` for a non-member atom and for a string variant (drift-proof per D-03a); `prompt_template_ref_key/0` returns the exact registry string and is registry-admitted as class `:id`. Add a second describe block mirroring the :128-142 anti-inline template for the D-04d reserved-only guard: over a hardcoded list of the real lib/ producer files (`lib/scoria/observe.ex`, `lib/scoria/observe/guardrail.ex`, `lib/scoria/eval/judge_runner.ex`, `lib/scoria/observe/telemetry.ex`), `refute` that any source contains the emitter-call literal for the reserved feedback name (assert absence of a `name:` key paired with the `user_feedback_received` atom in an emit call) — so wiring an emitter turns this test RED. Use `File.read!/1` guarded by `File.exists?/1` exactly as the template does.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/semconv_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - All new vocabulary assertions pass.
    - The reserved-only grep guard is GREEN on arrival (no lib/ emitter exists yet) and its failure message names the fix ("emission is SEED-011 / FB-01; do not wire an emitter").
    - The grep guard reads real files via File.read!/1 guarded by File.exists?/1; it is scoped to the hardcoded producer list, not `Path.wildcard`.
  </acceptance_criteria>
  <done>The vocabulary + template_ref key are unit-locked and a RED-on-regression guard structurally enforces user_feedback_received's reserved-only status.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| host/adapter → raw `:telemetry` bus | Any BEAM caller can `:telemetry.execute` the event tuple directly; the vocabulary is the only admission gate. |
| app → Postgres DDL | The FK-drop migration changes the durability/insertability contract of ai_span_events. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-53B-02 | Tampering/DoS | Event vocabulary / atom table | high | mitigate | Closed `@event_names` atom list + `event_name?/1` membership check; NEVER `String.to_atom` on inbound data (atom-table exhaustion blocked). Re-checked at the handler in Plan 03. |
| T-53B-03 | DoS (data integrity) | ai_span_events.span_id FK | high | mitigate | Drop the immediate FK (D-01a) so an orphan event is insertable, not a batch-rolling raise; column stays NOT NULL (dangling, never null). Separate event transaction (Plan 02) is the second defense. |
| T-53B-SC | Tampering | package installs | low | accept | No new packages; mix.exs untouched (RESEARCH Package Legitimacy Audit: N/A). |
</threat_model>

<verification>
- `mix ecto.migrate` / `mix ecto.rollback --step 1` / `mix ecto.migrate` round-trips clean.
- `mix test test/scoria/observe/semconv_test.exs` green.
- `mix compile --warnings-as-errors` clean.
</verification>

<success_criteria>
The FK is dropped (orphan insertable), the closed 3-atom vocabulary + `event_name?/1` + the `scoria.prompt.template_ref` key exist in Semconv, and the reserved-only guard is GREEN. Gates SC#4 (FK) and SC#2 (vocabulary) for downstream plans.
</success_criteria>

<output>
Create `.planning/phases/53B-ai-span-events-emit-event-1/53B-01-SUMMARY.md` when done.
</output>
