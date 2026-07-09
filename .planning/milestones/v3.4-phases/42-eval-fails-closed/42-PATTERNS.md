# Phase 42: Eval fails closed - Pattern Map

**Mapped:** 2026-07-04
**Files analyzed:** 11 (2 new, 8 modified, 1 new migration)
**Analogs found:** 11 / 11 (all in-repo; no RESEARCH.md — CONTEXT.md carries verified line numbers)

Every analog below is a real file in this repo. Plans should copy these idioms verbatim, not invent new ones. Load-bearing constraint threaded through all of them: **no live-LLM calls in tests** — prove real paths via the injected `orchestrator_module`/`req_llm_module` seam (`judge_runner.ex:62-64`) or deterministic DB fixtures.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/eval/verdict.ex` **(new)** | service (pure decision) | transform | 3 dup `threshold_verdict` fns + `semantic_cache/lookup.ex` fail-closed posture | exact (extract-from-3) |
| `lib/scoria/eval/scorers/exact_match.ex` **(new)** | service (pure scorer) | transform | `lib/scoria/knowledge/grounding.ex` | exact (style clone) |
| `lib/scoria/eval/runner.ex` | service (runner) | batch | self (delete local `threshold_verdict`, add dispatch) | self |
| `lib/scoria/eval/judge_runner.ex` | service (runner) | request-response (judge) | self (kill `build_subject_output`, call `Verdict`) | self |
| `lib/scoria/eval/online_scoring.ex` | service (runner) | event-driven | self (negative-signal detector) | self |
| `lib/scoria/eval/score.ex` | model (Ecto schema) | CRUD | self (`changeset/2:46` conditional required) | self |
| `lib/scoria/eval/eval_run.ex` | model (Ecto schema) | CRUD | self (free-form `threshold_verdict`) | self |
| `lib/scoria/eval/dataset_item.ex` | model (Ecto schema) | CRUD | self (add `captured_output` + sealed guard) | self |
| `lib/scoria/eval/dataset_promotion.ex` | service (builder) | transform | self (`build_item_attrs/1:78`) | self |
| `lib/scoria/runtime/release_gate.ex` | middleware (guard) | request-response | self + `semantic_cache/lookup.ex` query join | self + role-match |
| `priv/repo/migrations/*_add_eval_runs_verdict_index.exs` **(new)** | migration | schema | `priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs` | exact |

## Pattern Assignments

### `lib/scoria/eval/verdict.ex` (new — service, transform) — D-01, D-02

**Analogs:** the three duplicated verdict fns to unify, and `SemanticCache.Lookup`'s raise-on-missing posture.

**Source A — `lib/scoria/eval/runner.ex:125-152` (fail-CLOSED on empty; the good copy):**
```elixir
defp threshold_verdict(eval_spec, scores) do
  total = length(scores)
  pass_rate = if total == 0, do: 0.0, else: Enum.count(scores, &(&1.status == "passed")) / total
  mean_score = if total == 0, do: 0.0, else: Enum.sum(Enum.map(scores, & &1.score)) / total
  avg_latency = if total == 0, do: 0, else: Enum.sum(Enum.map(scores, &latency_ms/1)) / total

  pass_rate_gte = fetch(eval_spec.threshold_policy, :pass_rate_gte) || 0.0
  mean_score_gte = fetch(eval_spec.threshold_policy, :mean_score_gte) || 0.0
  max_latency_ms = fetch(eval_spec.threshold_policy, :max_latency_ms) || 0

  if pass_rate >= pass_rate_gte and mean_score >= mean_score_gte and avg_latency <= max_latency_ms do
    "passed"
  else
    "failed"
  end
end
```
`judge_runner.ex:165-182` is byte-identical (also on `latency_ms/1:184-192` + `fetch/2:201`). Delete both local copies plus their private `latency_ms`/`fetch` helpers once `Verdict` owns the math.

**Source B — `lib/scoria/eval/online_scoring.ex:354-356` (the fail-OPEN bug this unification fixes):**
```elixir
defp threshold_verdict(scores) do
  if Enum.all?(scores, &(&1.status == "passed")), do: "passed", else: "failed"
end
```
`Enum.all?([], …) == true` → an empty score list returns `"passed"` today. This is the live fail-open D-01 kills.

**nil-safe requirement (D-02):** the mean/sum lines above (`runner.ex:128`, `judge_runner.ex:168`, `online_scoring.ex:322` `average_score/1`, `online_scoring.ex:351-352`) crash on `score: nil`. `Verdict` must filter to the scored-only subset via `item_scored?/1` before any `Enum.sum`. `online_scoring.ex:351-352` already models the nil-guard idiom to reuse:
```elixir
defp average_score([]), do: nil
defp average_score(scores), do: Enum.sum(scores) / length(scores)
```

**Fail-closed posture to mirror — `lib/scoria/semantic_cache/lookup.ex:83-92`:** mandatory scope keys use `Map.fetch!` (raise, never silently default) rather than `Map.get`:
```elixir
defp base_query(attrs) do
  tenant_id = Map.fetch!(attrs, :tenant_id)
  lane_key = Map.fetch!(attrs, :lane_key)
  actor_id = Map.get(attrs, :actor_id)   # genuinely-optional key uses get
  ...
```
Apply this discipline to `Verdict.compute/2`: an empty/zero-coverage/no-real-scorer input yields `:inconclusive` (deny), never `:passed`.

**Contract (from D-01):** `compute(scores, threshold_policy) :: :passed | :failed | :inconclusive`; `blocks_release?(verdict) :: boolean` (only `:passed` → false); `item_scored?(score) :: boolean`. Canonical strings guarded by module constants + a test (free-form string columns have no DB enum — see `eval_run.ex:80`).

---

### `lib/scoria/eval/scorers/exact_match.ex` (new — service, transform) — D-03

**Analog:** `lib/scoria/knowledge/grounding.ex` (pure, key-free, returns `%{status, score, details}`).

**Binary-verdict shape to clone — `grounding.ex:4-10`:**
```elixir
def score_citation_presence(%{citations: citations}) when is_list(citations) do
  score = if citations == [], do: 0.0, else: 1.0
  status = if score == 1.0, do: "passed", else: "failed"
  %{status: status, score: score, details: %{count: length(citations)}}
end

def score_citation_presence(_payload), do: %{status: "failed", score: 0.0, details: %{count: 0}}
```
Copy the `%{status, score, details}` return shape and the binary 1.0/0.0 pattern. Two deliberate deviations (locked in D-03):
- **Do NOT route through `grounding.ex:78-80` `status/1`** — its `>= 0.75 → "passed"`, `>= 0.4 → "warning"` bands are meaningless for equality.
- Add a fourth outcome `{:not_scored, reason}` (missing/nil expected field, incomparable types, no actual output, unknown scorer) that Grounding does not have. Sharp line: *ran & mismatched* → `%{status: "failed", score: 0.0, …}`; *couldn't run* → `{:not_scored, reason}`. Never conflate.

**Signature:** `score/3` (mirror Grounding's arity-2/3 arg order: `(actual, expected/labels, opts)`). Fields: `scorer_kind: "exact_match"`, `scorer_version: "exact-match@1"`. Default compares `expected_output["answer"]`; per-scorer `field` + `match: "map"` opts read off the `eval_spec.scorers` entry. Coerce string↔atom keys before compare. Normalize: Unicode NFC → trim → collapse internal whitespace; case-sensitive by default, `case_insensitive` opt.

---

### `lib/scoria/eval/runner.ex` (modified — service, batch) — D-03, D-04

**Kill the hardcoded pass — `record_scores/4:63-79`:** today every item gets `status: "passed", score: 1.0`. Replace the map with per-item dispatch on `scorer_kind` and a shared `subject_output/2` resolver.

**Dispatch normalization idiom already present — `scorer_kind/1:116-123`:**
```elixir
defp scorer_kind(eval_spec) do
  eval_spec.scorers
  |> List.first()
  |> case do
    nil -> "llm_judge"
    scorer -> scorer |> fetch(:scorer_kind) |> Kernel.||("llm_judge") |> to_string()
  end
end
```
Reuse this `|> to_string()` coercion for the D-03 dispatch — `scorer_kind` is stored as an atom (`:llm_judge`) in some specs but compared as a string. Normalize both sides or `"exact_match"` specs silently fall through to `:not_scored` (revised note in D-03). Dispatch: `"exact_match"` → `ExactMatch`; `"llm_judge"` → existing JudgeRunner path; **unknown → `:not_scored`** (fail-closed). Then `threshold_verdict(...)` at `:17` becomes `Verdict.compute(...)`.

---

### `lib/scoria/eval/judge_runner.ex` (modified — service, request-response) — D-01, D-04

**Kill the self-grade — `build_subject_output/1:138-140`:**
```elixir
defp build_subject_output(dataset_item) do
  get_in(dataset_item.expected_output || %{}, ["answer"]) || ""   # grades expected as "Actual"
end
```
Called at `:106`, injected into the prompt at `build_judge_prompt/2:142-150` as `Actual:`. Replace with the shared `subject_output/2` resolver (reads frozen `captured_output`, D-04). Delete local `threshold_verdict/2:165` + call `Verdict`.

**Injected-module seam to extend (do NOT invent a new one) — `judge_dataset/5:62-64`:**
```elixir
orchestrator_module =
  fetch(attrs, :orchestrator_module) ||
    Application.get_env(:scoria, :orchestrator_module, Scoria.Orchestrator)

opts = if rlm = fetch(attrs, :req_llm_module), do: [req_llm_module: rlm], else: []
```
This is the idiomatic "prove the live path without live calls" hook. Tests pass a stub `orchestrator_module`.

**Persisted-fabrication concat to watch — `run_existing/2:44` + `judge_dataset/5:84`:** `List.wrap(base_score_attrs) ++ score_attrs` concatenates online's fabricated deterministic passes with judge scores. D-06 removes the fabricated rows upstream; this concat then carries only judge scores.

---

### `lib/scoria/eval/online_scoring.ex` (modified — service, event-driven) — D-01, D-06

**Delete the fabricated-pass branch — `deterministic_scores/3:240-241`:**
```elixir
score_status = if(policy_triggered?, do: "failed", else: "passed")   # else → fake pass
score_value = if(policy_triggered?, do: 0.0, else: 1.0)
```
Replace with negative-signal classification: `policy_trigger` OR span `ERROR` OR empty/absent output → `"failed"` (terminal); clean trace → emit **`[]`** base scores → judge is the only positive-verdict producer.

**Extra loads buildability needs (D-06 revised):** `fetch_trace/1:228-233` does `Repo.get(Trace, trace_id)` with **no `:spans` preload** — `trace_error?` needs `Span.status_code` (free-form OTel `"OK"`/`"ERROR"` string, `lib/scoria/repo/span.ex:10`). Empty-output signal lives in `Workflows.Step.result_envelope["output"]` (`lib/scoria/workflows/step.ex:19` `field :result_envelope, :map`) via `candidate.workflow_step_id`, **not** reliably in `trace.attributes`. Add a Span preload + a Step load into the path.

**Verdict + summarize fixes:** `threshold_verdict/1:354` → `Verdict`. `summarize_scores/1:319-349`: any `failed` OR any `not_scored`/empty ⇒ `needs_review`; `promotion_candidate` (`:338`) only when scores non-empty and every score really `passed`. `average_score/1:351-352` stays the nil-guard model.

**Online-exclusion tag for the gate (D-05):** these runs are created with `metadata["source"] => "online_scoring"` (`campaign_attrs/2:119`) — that string, NOT `runner_mode`, is how ReleaseGate excludes them (there is no `:online` runner_mode).

---

### `lib/scoria/eval/score.ex` (modified — model, CRUD) — D-02

**Conditional-required target — `changeset/2:46`:**
```elixir
|> validate_required([:score, :status, :scorer_kind, :eval_run_id, :dataset_item_id])
```
Make `:score` required **only when** `status != "not_scored"` (nil = "no measurement", never `0.0`). Split into a base `validate_required` (drop `:score`) + a `validate_required([:score])` applied conditionally. `normalize_attrs/1:51` already models conditional attr shaping. No migration — `ai_scores` accepts nil score.

---

### `lib/scoria/eval/eval_run.ex` (modified — model, CRUD) — D-02

**Free-form `threshold_verdict` — `:28`** `field(:threshold_verdict, :string)` has **no `validate_inclusion`** (verified) → adding `"inconclusive"` is additive, zero enum migration.

**`status` inclusion stays UNCHANGED — `:80`:**
```elixir
|> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
```
An inconclusive run is `status: "completed"` + `threshold_verdict: "inconclusive"`. `status: "failed"` stays reserved for a crashing runner. `passed_items`/`failed_items:24-25` are the only counters — prefer **deriving** `not_scored_items` over adding a column (planner's call, D-02).

---

### `lib/scoria/eval/dataset_item.ex` (modified — model, CRUD) — D-04

**Add `captured_output` (+ `captured_output_sha256`, `captured_at`) fields to the schema (`:5-13`) and cast list (`:17`).** Sealed-write guard to preserve — `validate_dataset_state/2:22-24`:
```elixir
defp validate_dataset_state(changeset, :sealed) do
  add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
end
```
Capture is written ONLY at promotion (open state) — this guard forbids re-writing sealed items, so `refresh_capture` may only ever produce a new dataset version (D-04). This is an Ecto migration + schema edit (unlike `ai_scores`).

---

### `lib/scoria/eval/dataset_promotion.ex` (modified — service, transform) — D-04

**Populate capture here — `build_item_attrs/1:78-93`:**
```elixir
defp build_item_attrs(attrs) do
  %{
    "input" => %{ ... },
    "expected_output" => normalize_map(attrs["expected_output"]),
    "metadata" => build_metadata(attrs)
  }
end
```
Add `"captured_output"` (+ sha256 + captured_at) here, from the **real source-trace/step output**, NOT the frequently-empty `checkpoint_output`/`recorded_outcome` maps (`:85`, `:110`). Empty capture = nil-equivalent = `:not_scored` downstream. `build_promotion_attrs/4:35` and `@required_keys:10` may need the capture source threaded in.

---

### `lib/scoria/runtime/release_gate.ex` (modified — middleware, request-response) — D-05

**Draft check stays first and unchanged — `check/1:15-16`:**
```elixir
def check(%PromptTemplate{status: "draft"}), do: {:error, :unapproved_draft}
def check(%PromptTemplate{}), do: :ok   # <- add verdict consult HERE, before :ok
```
The `%PromptTemplate{}` clause is where the verdict consult inserts. Contract (locked D-01↔D-05): use `Verdict.blocks_release?/1`; **only `threshold_verdict == "passed"` passes** (allowlist). Any other completed verdict → `{:error, {:eval_not_passing, verdict}}`. No completed verdict → `:ok` by default + emit `[:scoria, :release_gate, :ungated]` telemetry; opt-in `config :scoria, :require_eval_verdict` → `{:error, :eval_required}`.

**Lookup query analog — `lib/scoria/semantic_cache/lookup.ex:63-92`** (latest-row join, ordered, limited, fail-closed keys):
```elixir
Entry
|> where([entry], entry.tenant_id == ^tenant_id and entry.lane_key == ^lane_key)
|> where([entry], entry.status in ^@rankable_statuses)
|> order_by([entry], desc: entry.updated_at)
```
Mirror for the gate: join latest `status == "completed"` `EvalRun` on `prompt_template_id` ONLY (`eval.ex:209` populates it via `put_new_attr(:prompt_template_id, …)`); do NOT add `prompt_version` (type mismatch: runtime String vs EvalRun integer). Exclude online runs via `campaign.metadata["source"] == "online_scoring"`. **DB errors propagate** — do NOT `rescue` into a fake-allow (avoids fail-closed self-outage). Existing UUID-cast + `Repo.get` pattern at `check/1:29-33` stays.

---

### `priv/repo/migrations/*_add_eval_runs_verdict_index.exs` (new — migration) — D-05

**Analog:** `priv/repo/migrations/20260523000300_expand_ai_scores_and_create_online_score_candidates.exs` (composite-index + idempotent-guard idiom).

**Composite-index pattern — lines 44-46, 94:**
```elixir
create_if_not_exists(index(:ai_scores, [:eval_run_id, :status]))
create_if_not_exists(index(:ai_online_score_candidates, [:tenant_id, :status, :review_status]))
```
For this phase: `create index(:ai_eval_runs, [:prompt_template_id, :status, "inserted_at DESC"])` (the DESC ordering supports the gate's latest-completed lookup). Use `create_if_not_exists` + a matching `down/0` `drop_if_exists` (see `:106-129`). One indexed query per *gated* run — acceptable per D-05.

## Shared Patterns

### Fail-closed decision (the spine)
**Source:** new `Scoria.Eval.Verdict` + `semantic_cache/lookup.ex:83-92` posture.
**Apply to:** `runner.ex`, `judge_runner.ex`, `online_scoring.ex`, `release_gate.ex`.
`"passed"` is the ONLY passing verdict string, defined once. Unknown/empty/zero-coverage → deny (`:inconclusive`/block). Never enumerate a block-list.

### Injected-module test seam
**Source:** `judge_runner.ex:62-64` (`orchestrator_module` / `req_llm_module`).
**Apply to:** every plan that touches a live/judge path. No live-LLM in `mix test` — extend this seam or use DB fixtures; never add API-key-dependent tests.

### String↔atom key coercion
**Source:** `runner.ex:121` `|> to_string()`, `semantic_cache/lookup.ex:107-123` `normalize_pair/1`, `online_scoring.ex:207-217` `normalize_map/1`.
**Apply to:** `ExactMatch` field compare, runner `scorer_kind` dispatch, ReleaseGate metadata reads. `scorer_kind` is atom-in-spec / string-in-DB — normalize both sides or specs silently fall through to `:not_scored`.

### nil-safe aggregation
**Source:** `online_scoring.ex:351-352` `average_score/1`.
**Apply to:** all mean/sum math in `Verdict` — filter `item_scored?` before `Enum.sum`. Verified crash-on-nil sites: `runner.ex:128`, `judge_runner.ex:168`, `online_scoring.ex:322/351-352`.

### Free-form status strings are additive
**Source:** `eval_run.ex:28` (`threshold_verdict` has no inclusion), `score.ex:9` (`status` free-form).
**Apply to:** `"not_scored"` / `"inconclusive"` need no enum migration. Guard canonical values with a `Verdict` module constant + a test, not a DB enum.

### Dashboard tone bucketing (state must render, never crash)
**Source:** `lib/scoria_web/ui.ex:34-36` (`:warn` amber bucket).
**Apply to:** add `not_scored`/`inconclusive` to the `~w(... needs_review)` `:warn` list so they render amber, not the `:neutral` gray fallback (`ui.ex:45-46`). Add curated `Copy.status_label` entries ("Not scored", "Inconclusive"); the `humanize` fallback prevents a crash but the labels are honesty polish.

## No Analog Found

None. Every new behavior has an in-repo idiom to copy — the two "new" modules (`Verdict`, `ExactMatch`) are extractions/clones of existing code (`threshold_verdict` ×3, `Grounding`), and both new persistence surfaces reuse existing migration/schema idioms.

## Metadata

**Analog search scope:** `lib/scoria/eval/`, `lib/scoria/knowledge/`, `lib/scoria/semantic_cache/`, `lib/scoria/runtime/`, `lib/scoria/repo/`, `lib/scoria/workflows/`, `lib/scoria_web/`, `priv/repo/migrations/`.
**Files scanned:** 14 read in full or targeted.
**Pattern extraction date:** 2026-07-04
