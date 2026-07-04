# Phase 42: Eval fails closed - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Scoria's eval engine fail **CLOSED**: no eval run is ever reported green without a real
subject output scored by a real deterministic scorer, and the release gate consults the eval
verdict instead of only the prompt's draft flag. Delivers EVAL-01..05 by killing the four
fake-green sites in the eval subsystem:

1. `judge_runner.ex:138` `build_subject_output/1` self-grades (`expected_output["answer"]` → "Actual").
2. `runner.ex:63-79` `record_scores/4` hardcodes `status: "passed", score: 1.0` for every item.
3. `online_scoring.ex:240-241` fabricates `passed/1.0` for any non-`policy_trigger` trace.
4. `release_gate.ex:15` blocks only `status: "draft"`, never the verdict.

**Method note:** These decisions were produced by five parallel research passes (one per gray
area, coherence-aware) → an adversarial red-team pass against the real code → self-verification of
load-bearing facts. Corrections the red-team forced into the synthesis are marked **(revised)**.

**In scope:** the real fix + deterministic proof (ExUnit, zero live-LLM). **Out of scope:** the
honest `0.1.3` Hex cut (SEED-005 / 999.2 — PR #12 stays held), deeper/semantic scorers (SEED-008),
rerank/abstention (SEED-009), masking/retention (SEED-011), knowledge tenant work (Phase 43).

</domain>

<decisions>
## Implementation Decisions

Hard constraint threaded through all decisions (user-locked): **no live LLM calls in CI/tests** —
`mix test` must never need API keys. Every real path is proven via the existing injected
`orchestrator_module`/`req_llm_module` seam or deterministic DB fixtures.

### D-01 — `Scoria.Eval.Verdict` is the single fail-closed decision point (the spine) [EVAL-03]
- New module `lib/scoria/eval/verdict.ex`. **Unify** the three duplicated verdict functions
  (`runner.ex:125`, `judge_runner.ex:165`, `online_scoring.ex:354`) into it. All three delete their
  local copies and call `Verdict`.
- Contract: `compute(scores, threshold_policy) :: :passed | :failed | :inconclusive`;
  `blocks_release?(verdict) :: boolean` (only `:passed` → false); `item_scored?(score) :: boolean`.
- **Fail-closed semantics:** `:passed` only when real scores clear policy over the *scored-only*
  subset; `:inconclusive` when zero items, no real scorer ran, or coverage falls short;
  `:failed` when scored-but-below-threshold.
- **(revised) This unification also fixes a live fail-OPEN bug:** `online_scoring.ex:354`
  `Enum.all?([], …) == true` returns `"passed"` for an empty score list today. One shared function
  makes fail-closed a single testable property.

### D-02 — Tri-state honest vocabulary; item-level ≠ run-level [EVAL-03]
- **Item level** (`Score.status`, kept free-form string): add `"not_scored"` with `score: nil`
  (nil = "no measurement"; **never `0.0`** — 0.0 pollutes mean-score math and is dishonest).
- **Run level** (`EvalRun.threshold_verdict`, free-form string, no `validate_inclusion` — verified):
  add `"inconclusive"` as a **distinct third state**. Do **not** collapse not-scored into `"failed"`.
- **`EvalRun.status` inclusion list UNCHANGED** (`["pending","running","completed","failed"]` —
  verified `eval_run.ex:80`): an inconclusive run is `status: "completed"` + `threshold_verdict:
  "inconclusive"`. `status: "failed"` stays reserved for the runner itself crashing.
- **`Score.changeset`** (`score.ex:46`, verified requires `:score`): make `:score` required **only
  when** `status != "not_scored"`.
- **Strict coverage default (LOAD-BEARING):** any `not_scored` item ⇒ run `inconclusive`. Optional
  per-spec `threshold_policy["not_scored_tolerance"]` is the escape hatch. **(revised)** Without this
  default, D-02+D-03 create a 1-passed/99-not_scored gaming surface that D-04's empty-capture reality
  makes trivially exploitable — keep strict as the default, tolerance is opt-in.
- **All mean/sum math must become nil-safe** (filter `item_scored?` first). **(revised)** Verified
  crash-on-nil sites: `runner.ex:128`, `judge_runner.ex:168`, `online_scoring.ex:322/351-352`.
- **(revised) Dashboard amber is a real edit, not free:** `ScoriaWeb.UI.tone/1` falls back to
  `:neutral` (gray) for unknown strings (verified `ui.ex:45-50`). Add `not_scored`/`inconclusive` to
  the `:warn` bucket (`ui.ex:35`) → amber (not gray "benign", not red "false regression"). `Copy`/
  `status_label` has a `humanize` fallback so no crash, but curated labels ("Not scored",
  "Inconclusive") should be added.
- **`not_scored_items` counter:** `EvalRun` has `passed_items`/`failed_items` only (verified). Prefer
  **deriving** the not-scored count from scores over adding a column — keep the migration surface
  minimal. (Planner may add the column if a list view needs it; flagged, not mandated.)

### D-03 — `Scoria.Eval.Scorers.ExactMatch` is the first real deterministic scorer [EVAL-02]
- New pure module `lib/scoria/eval/scorers/exact_match.ex` mirroring `Scoria.Knowledge.Grounding`
  style (`score/3 → %{status, score, details}` or `{:not_scored, reason}`). No LLM, key-free.
- **Normalized exact-match:** Unicode NFC → trim → collapse internal whitespace; **case-sensitive by
  default** with a `case_insensitive` opt. **Binary** verdict: match → `1.0/"passed"`, clean
  mismatch → `0.0/"failed"`. Do **not** route through `Grounding.status/1` (its 0.4/0.75 "warning"
  band is meaningless for equality).
- **`scorer_kind: "exact_match"`**, `scorer_version: "exact-match@1"`. Default compares
  `expected_output["answer"]` vs the actual; per-scorer `field` and `match: "map"` (canonical whole-
  map compare) opts read off the `eval_spec.scorers` entry. Coerce string↔atom keys before compare.
- **Runner dispatch on `scorer_kind`:** `"exact_match"` → `ExactMatch`; `"llm_judge"` → existing
  `JudgeRunner` path (unchanged); **unknown → `:not_scored`** (fail-closed, never fake-pass). Writes
  the existing `ai_scores` sink unchanged (no migration).
- **Sharp line (coherence with D-02):** *ran & mismatched* → `"failed"` (a real negative signal that
  fails the gate); *couldn't run* (missing/nil expected field, incomparable types, unknown scorer,
  no actual output) → `{:not_scored, reason}`. Never conflate.
- **(revised) Atom/string normalization:** `scorer_kind` is stored as an atom in some specs
  (`:llm_judge`) but persisted/compared as a string (`runner.ex:121` `to_string`). New dispatch must
  normalize both sides or `"exact_match"` specs silently fall through to `:not_scored`.
- Fuzzy/semantic/Levenshtein/embedding scoring is **explicitly SEED-008** — building it now would be
  the fake-sophistication EVAL-02 exists to kill.

### D-04 — Subject output source: replay-from-capture; live execution DEFERRED [EVAL-01]
- **Kill both self-grade sites:** delete `expected_output["answer"]` as the "Actual"
  (`judge_runner.ex:138`) and the hardcoded `passed/1.0` (`runner.ex:63-79`). Replace with a single
  `subject_output/2` resolver both runners call — one contract, so offline and judge paths can't
  diverge into fake-green again.
- **`offline_replay` replays a frozen `captured_output`** stored on the dataset item (cassette
  pattern) — deterministic, key-free, self-contained, hashable. **Not** a live re-read of the
  `source_trace_id` trace body (traces are mutable/retention-limited/redactable → a sealed eval would
  silently change or vanish). `source_trace_id` stays a provenance breadcrumb.
- **(revised) Live-subject execution (`live_judge` regenerating the subject output) is DEFERRED out
  of Phase 42.** Verified: **no renderer exists** that composes `PromptTemplate.user_template` +
  `input` into a concrete prompt (`user_template` is only used for token estimation + immutable
  versioning). Building that renderer + doubling orchestrator calls in a path currently stubbed for a
  single call is over-reach for "fix + prove." `live_judge` stays **judge-only** for now (documented
  consequence: no independent subject regeneration this phase). This is a **future slice**, not this
  phase.
- **(revised) `captured_output` is written ONLY at promotion (open state).** Verified: the sealed-
  item guard (`dataset_item.ex:22` `add_error` on `:sealed`) forbids re-writing sealed items, and
  runners require `state == :sealed`. Populate `captured_output` (+ `captured_output_sha256`,
  `captured_at`) at promotion from the **real source-trace/step output**, not from the frequently-
  empty `recorded_outcome`/`checkpoint_output` maps. `refresh_capture` (currently a dangling enum
  value with zero usages — verified) may only ever produce a **new dataset version**; it may not
  mutate a sealed item. Full `refresh_capture` wiring travels with the deferred live slice.
- **Empty capture = `nil`-equivalent = `:not_scored`** (an empty map must not read as "real actual =
  {}" and fake-pass an empty-expected item).
- **(revised) Mass re-verdict is expected and intended:** existing promoted datasets have empty
  capture → they flip to `not_scored`/`inconclusive` on next run. That is correct fail-closed
  behavior, not a regression. The offline_runner test that asserts `"passed"` (verified
  `offline_runner_test.exs:24,29`) must be rewritten against a real `captured_output` fixture (or to
  assert `inconclusive`).

### D-05 — ReleaseGate consults the verdict: allowlist + opt-in strict [EVAL-04]
- `ReleaseGate.check/1` gains a verdict consult. **Only `threshold_verdict == "passed"` passes**
  (allowlist — never enumerate a block-list). Any *other completed* verdict →
  `{:error, {:eval_not_passing, verdict}}` (tagged tuple so the host matches one class while still
  rendering the specific verdict). Draft check stays **first** and unchanged
  (`{:error, :unapproved_draft}`).
- **No eval / no completed verdict → `:ok` by default** (least blast radius — most adopter prompts
  have no eval; blocking them on a minor bump would brick the library and betray the trust milestone)
  **+ emit `[:scoria, :release_gate, :ungated]` telemetry** so "no eval governs this prompt" is
  inspectable, never silently green. Opt-in `config :scoria, :require_eval_verdict` (net-new,
  default `false`) → block no-verdict with a distinct `{:error, :eval_required}`.
- Use `Verdict.blocks_release?/1` — do not re-derive the passing set. **Contract locked across
  D-01↔D-05: `"passed"` is the ONLY passing verdict string.**
- **(revised) Lookup joins latest `status == "completed"` `EvalRun` on `prompt_template_id` ONLY.**
  Verified: `prompt_template_id` is already the version-specific row id (`subject` also carries a
  separate `prompt_entity_id`), and `ReleaseGate` resolves `prompt_ref` via `Repo.get(PromptTemplate,
  uuid)` = same row-id space. Do **not** add `prompt_version` to the WHERE — runtime
  `prompt_policy.prompt_version` is a `String.t()` while `EvalRun.prompt_version` is an `:integer`
  (type mismatch).
- **(revised) Exclude ONLINE runs via `campaign.metadata["source"] == "online_scoring"`, NOT by
  `runner_mode`.** Verified: online campaign runs are created with `runner_mode: eval_spec.eval_mode`
  ∈ `{:offline_replay, :live_judge}` (`campaign_enqueuer.ex:172`) — there is **no `:online`
  runner_mode**, so a runner_mode filter cannot remove them, and they carry `prompt_template_id` +
  `threshold_verdict` that would pollute the lookup. Legit *offline* campaign evals should still
  count → use the metadata-source join, not an `is_nil(campaign_id)` check.
- **(revised) Premise correction / teeth:** offline **and** live runs *do* populate
  `prompt_template_id` (`Eval.create_eval_run`, `eval.ex:210` — verified), so the gate is not a
  silent no-op there. Its real limitation: most runtime paths pass `prompt_ref: nil`, so
  `check/1` returns `:ok` before any lookup. **Document "default-off = default-open"** — teeth come
  from `:require_eval_verdict` or from prompts that set `prompt_ref`.
- Add composite index `ai_eval_runs (prompt_template_id, status, inserted_at DESC)` (one indexed
  query per *gated* run; acceptable). **DB errors propagate** — do not `rescue` into a governance
  block or a fake-allow (avoids the fail-closed-self-outage footgun). Denormalizing a verdict column
  onto `PromptTemplate` is the v-next perf seam, out of scope now.

### D-06 — Online scoring becomes a negative-signal detector [EVAL-05]
- In `online_scoring.ex deterministic_scores/3`: **delete the `else → passed/1.0` branch.** A
  reference-free deterministic check can only honestly prove a **negative**; it must never emit
  `passed` for a production sample.
- Trace-level classification: `policy_trigger` (keep) **OR** trace/span `ERROR` status **OR**
  empty/absent output → `"failed"` (terminal → skip judge → route to review). Clean trace → emit
  **`[]` base scores** → `not_scored`; the LLM judge (if configured) is the **only** producer of a
  positive verdict; if no judge → candidate `needs_review`, **never `promotion_candidate`**.
- Fix the vacuous `Enum.all?([])` verdict via `Verdict`. `summarize_scores/1`: any `failed` OR any
  `not_scored`/empty ⇒ `needs_review`; `promotion_candidate` only when scores are non-empty and every
  score `passed` by a real scorer/judge (stops laundering fabricated labels into golden datasets).
- **(revised) Kill the persisted-fabrication leak:** today `run_existing` concatenates
  `base_score_attrs` (the fabricated passes) with judge scores, inflating `mean_score`. Emitting `[]`
  for clean traces removes it — assert a clean-trace online run persists only judge scores (or none),
  never a `deterministic_rule/passed` row.
- **(revised) Buildability needs extra loads:** verified `fetch_trace/1` does `Repo.get(Trace, …)`
  with **no `:spans` preload** — `trace_error?` needs a span preload (`Span.status_code`, OTel
  `"OK"`/`"ERROR"`, is a free-form string field — verified `span.ex:10`). Empty-output signal lives
  in `Workflows.Step.result_envelope` (via `candidate.workflow_step_id`), **not** reliably in
  `trace.attributes` — add a `Step` load into the path. All still offline-provable (seed
  policy_trigger / ERROR-span / empty-output / clean fixtures).

### Claude's Discretion
- Exact normalization ruleset details and `details`-map diff shape for `ExactMatch` (D-03).
- The precise `Verdict.compute/2` threshold math re-expression (must preserve today's
  pass_rate/mean_score/max_latency policy semantics, just nil-safe + coverage-guarded).
- Telemetry event names/metadata beyond the `:ungated` event named in D-05.
- Whether to derive vs. persist `not_scored_items` (D-02) — planner's call per list-view needs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (locked scope)
- `.planning/ROADMAP.md` → "Phase 42: Eval fails closed" — goal + 5 success criteria (the WHAT).
- `.planning/REQUIREMENTS.md` → EVAL-01..05 — requirement text.
- `.planning/PROJECT.md` — product boundary (embedded/Ecto/Telemetry-native, "library not a runtime
  people work around"), n=1 persona, delegated-authz doctrine, v3.4 boundary (fix+prove only,
  `0.1.3` held), SEED-008/009/011 deferrals.

### Eval subsystem (the code being changed)
- `lib/scoria/eval/judge_runner.ex` — `build_subject_output/1:138` (self-grade), `threshold_verdict/2:165`, `run_existing/2` base-score concat.
- `lib/scoria/eval/runner.ex` — `record_scores/4:57-79` (hardcoded pass), `threshold_verdict/2:125`, `scorer_kind/1:116`.
- `lib/scoria/eval/online_scoring.ex` — `deterministic_scores/3:235`, `summarize_scores/1:319`, `threshold_verdict/1:354`, `fetch_trace/1:228`.
- `lib/scoria/eval/score.ex` — `ai_scores` sink; `changeset/2:46` `validate_required([:score,…])`.
- `lib/scoria/eval/eval_run.ex` — `runner_mode` enum:8, `status` inclusion:80, `threshold_verdict` free-form:28, `passed_items`/`failed_items`:24.
- `lib/scoria/eval/eval_spec.ex` — `subject` (`prompt_template_id`/`prompt_version`), `scorers`, `threshold_policy`.
- `lib/scoria/eval/dataset_item.ex` — `captured_output` target; sealed guard:22; `source_trace_id`, `input`, `expected_output`.
- `lib/scoria/eval/dataset_promotion.ex` — `build_item_attrs/1:78-111` (where capture must be populated at open state).
- `lib/scoria/eval/eval.ex` — `create_eval_run/1:202` (populates `prompt_template_id`:210).
- `lib/scoria/eval/campaign_enqueuer.ex` — `eval_run_attrs/3:165` (`runner_mode: eval_spec.eval_mode`:172 — the online-exclusion gotcha).
- `lib/scoria/knowledge/grounding.ex` — scorer STYLE to mirror for `ExactMatch`.

### Runtime gate
- `lib/scoria/runtime/release_gate.ex` — `check/1:15` (draft-only today).
- `lib/scoria/runtime.ex:30` — gate call site in the `with` chain.
- `lib/scoria/prompt_registry/prompt_template.ex` — `id`/`entity_id`/`version`/`status`/`user_template` (renderer gap for deferred live path).
- `lib/scoria/prompt_policy.ex` — `prompt_ref`/`prompt_version` (String) runtime shape.

### Signal sources (online)
- `lib/scoria/repo/trace.ex`, `lib/scoria/repo/span.ex` (`status_code`), `lib/scoria/repo/span_event.ex` (exception events).
- `lib/scoria/workflows/step.ex` — `result_envelope["output"]` (empty-output signal source).
- `lib/scoria/eval/review_queue.ex` — `severity/1` bucketing of `needs_review`/`not_scored`.

### Dashboard surfaces (state vocabulary renders here)
- `lib/scoria_web/ui.ex` — `tone/1:24-50` (add `:warn` amber for new states).
- `lib/scoria_web/copy.ex` — `status_label`/`humanize` fallback (add curated labels).
- `lib/scoria_web/live/eval_spec_live/index.ex`, `lib/scoria_web/live/review_queue_live.ex` — render run/candidate status badges.

### Research corpus (mined for these decisions)
- `prompts/ai-eval-best-practices-deep-research.md` — offline/online split, exact-match brittleness, "no-error ≠ correct", happy-path footgun.
- `prompts/ai-architectural-patterns-deep-research.md`, `prompts/phoenix-ai-lib-deep-research.md`, `prompts/sztheory-elixir-dna.md` — idiomatic Elixir/Ecto library patterns, injected-module test seam.

### Tests that must change (no live LLM)
- `test/scoria/eval/offline_runner_test.exs:24,29` — asserts fake-green `"passed"`; rewrite against real `captured_output` (or `inconclusive`).
- `test/scoria/eval/judge_runner_test.exs:14-15` — single-orchestrator stub; revisit only if/when live-subject ships (deferred).
- New: `ExactMatch`, `Verdict.compute` (nil-safe/empty/coverage), ReleaseGate verdict consult + online-exclusion, online negative-signal classifier against seeded traces.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Scoria.Knowledge.Grounding`** — the pure `%{status, score, details}` scorer shape to clone for `ExactMatch` (do NOT reuse its 0.4/0.75 `status/1` bands for equality).
- **`Scoria.Eval.Score` / `ai_scores` sink** — schema-stable and mode-agnostic; no migration to record real/`not_scored` scores.
- **Injected `orchestrator_module` / `req_llm_module` seam** (`judge_runner.ex:62-64`) — the idiomatic Elixir answer to "prove the live path without live calls." Extend it; don't invent a new mechanism.
- **`SemanticCache.Lookup`** — the milestone's cited precedent for a mandatory fail-closed filter that RAISES on nil scope (mirror its posture for ReleaseGate/Verdict).

### Established Patterns
- **Three duplicated `threshold_verdict` fns already disagree** (runner/judge = fail-closed on empty; online = fail-OPEN on empty). DRY-ing them into `Scoria.Eval.Verdict` is both the coherence win and a bug fix.
- **Free-form status/verdict strings** (no DB enums) — new states are additive, no enum migration; guard canonical values via the `Verdict` module constants + a test/Credo check.
- **Runner modes** `[:offline_replay, :live_judge, :refresh_capture]` — `refresh_capture` is dangling (zero usages); the enum already anticipates capture.

### Integration Points
- `ReleaseGate.check/1` sits in the runtime hot path (`runtime.ex:30`) — the only place a verdict blocks execution.
- Promotion (`dataset_promotion.ex`, open state) is the only legal write point for `captured_output`.
- Online path: `campaign_enqueuer` → `campaign_worker` → `online_scoring.execute_candidate` → `review_queue`.

</code_context>

<specifics>
## Specific Ideas

- User's locked constraint: **no live LLM calls in CI/tests** (deterministic, offline-provable proof only).
- User's method preference (applied here): research each gray area with parallel subagents → adversarial red-team → one coherent one-shot locked spec, not interactive Q&A. Verification shifts left into ExUnit/CI, not manual UAT.
- Honesty doctrine (from v3.0): "honest coming-soon stubs, never fake data" — the same principle drives `not_scored`/`inconclusive` over a fabricated green.
- Framing for the milestone doc (from GA-3): fail-closed on the verdict *value* (unknown verdict = deny), not on eval *absence* — the K8s-admission / OPA "policy says no" (deny) vs "no policy matched" (admit) distinction.

</specifics>

<deferred>
## Deferred Ideas

- **Live-subject execution / subject-prompt renderer** — regenerating the subject output live via
  Orchestrator needs a `user_template + input → prompt` renderer that does not exist. Over-reach for
  fix+prove; ships as its own future slice (SEED-008-adjacent). `live_judge` stays judge-only until then.
- **Full `refresh_capture` runner wiring** (re-capturing into a new dataset version, CLI surface) —
  travels with the deferred live slice. `mix scoria.eval` is currently a `# TODO` stub with no CLI
  eval entrypoint (verified `scoria.eval.ex:28`).
- **Denormalized `latest_threshold_verdict` column on `PromptTemplate`** — O(1) hot-path read; v-next
  perf optimization if the per-gated-run query shows up in profiles. Out of scope now (migration +
  3-path write wiring + staleness bug class).
- **Deeper/semantic scorers** (Levenshtein, embedding similarity, groundedness) — SEED-008.
- **Reference-free online scorer suite** (schema-validity, latency/token anomaly scoring) — SEED-008/009.
- **Distinct `not_scored` severity/label in the review queue UI** — minor honesty polish; not blocking.
- **Should `inconclusive` also block dataset promotion** (`review_queue.ex`/`dataset_promotion.ex`
  currently key on `"failed"` only) — coherence check to raise with the promotion owner; likely a
  small follow-up, flagged not fixed here.

</deferred>

---

*Phase: 42-eval-fails-closed*
*Context gathered: 2026-07-04*
