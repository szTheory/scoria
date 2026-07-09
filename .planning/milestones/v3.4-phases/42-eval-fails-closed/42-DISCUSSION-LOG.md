# Phase 42: Eval fails closed - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 42-eval-fails-closed
**Areas discussed:** Subject output source (GA-1), Deterministic scorer semantics (GA-2), ReleaseGate blast radius (GA-3), not_scored/inconclusive state model (GA-4), Online scoring depth (GA-5)

**Method:** User declined interactive Q&A in favor of their standing preference — five parallel
research subagents (one per gray area, coherence-aware) → one adversarial red-team pass against the
real code → self-verified load-bearing facts → one coherent locked spec. Red-team corrections are
marked **(revised)** in CONTEXT.md. Hard constraint set by user: **no live LLM calls in CI/tests**;
remaining constraints left to research to recommend.

---

## GA-1 — Subject output source (EVAL-01)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Live-execute always | Run the subject prompt live via Orchestrator at eval time | |
| (b) Replay from live `source_trace_id` trace body | Re-read the promoted trace's output | |
| (b′) Replay from frozen `captured_output` on the item (cassette) | Deterministic, self-contained, sealable | ✓ |
| (c) Both, keyed by `runner_mode` (b′ as replay) | offline_replay → capture; live_judge → live | ✓ (replay half) |

**Choice:** Replay from a frozen `captured_output` for `offline_replay`. **Live-subject execution
DEFERRED (revised):** no `user_template → prompt` renderer exists; building it + doubling stubbed
orchestrator calls is over-reach for fix+prove. `live_judge` stays judge-only this phase.
**Notes (revised):** capture writable only in `:open` state (sealed guard verified); existing
datasets flip to `not_scored`/`inconclusive` (intended mass re-verdict); `offline_runner_test`
asserting `"passed"` must be rewritten.

---

## GA-2 — Deterministic scorer semantics (EVAL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Raw exact equality | `==` with no normalization | |
| Normalized exact-match (NFC+trim+ws-collapse, binary) | `Scoria.Eval.Scorers.ExactMatch`, `scorer_kind:"exact_match"` | ✓ |
| Fuzzy/threshold (Levenshtein/cosine via status bands) | Graded similarity | (SEED-008) |

**Choice:** Normalized exact-match, binary 1.0/0.0, default compares `expected_output["answer"]`,
dispatched off `eval_spec.scorers`; unknown scorer → `:not_scored`.
**Notes:** sharp `failed` (ran & mismatched) vs `:not_scored` (couldn't run) line. **(revised)**
normalize atom↔string `scorer_kind` or `"exact_match"` specs silently fall through.

---

## GA-3 — ReleaseGate blast radius (EVAL-04)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Honor verdict only; no-eval → allow | Least blast radius | ✓ (default) |
| (b) Full fail-closed; no passing verdict → block | Bricks non-eval adopters on a minor bump | |
| (c) Opt-in strict flag | `config :scoria, :require_eval_verdict` (default false) | ✓ (opt-in layer) |
| (d) Denormalized verdict column | O(1) read; migration + staleness | (v-next) |

**Choice:** Allowlist — only `threshold_verdict == "passed"` passes; other completed verdict →
`{:error, {:eval_not_passing, verdict}}`; no eval → `:ok` + `:ungated` telemetry by default,
`:eval_required` under opt-in strict. Draft check stays first.
**Notes (revised):** join on `prompt_template_id` only (already version-specific; `prompt_version`
type-mismatches String vs integer); exclude online runs via `campaign.metadata["source"] ==
"online_scoring"` (NOT runner_mode — no `:online` mode exists); offline/live DO populate
`prompt_template_id`, so document "default-off = default-open," teeth via strict flag or `prompt_ref`.

---

## GA-4 — not_scored / inconclusive state model (EVAL-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Binary; fold not-scored into `"failed"` | Fewer states | |
| Tri-state: add `"inconclusive"` (run) + `"not_scored"` (item, score nil) | Preserves inspectability; both block | ✓ |
| Keep 3 duplicated verdict fns | Patch each | |
| Unify into `Scoria.Eval.Verdict` | Single fail-closed decision point | ✓ |

**Choice:** Tri-state vocabulary; `score: nil` for not_scored; unify the three verdict fns into
`Scoria.Eval.Verdict`; `EvalRun.status` unchanged (completed + inconclusive verdict); strict
coverage default (any not_scored ⇒ inconclusive) with opt-in `not_scored_tolerance`.
**Notes (revised):** unification fixes a live fail-OPEN bug (`Enum.all?([])`); nil-safe math at three
sites; amber requires a real `tone/1` `:warn` edit (fallback is neutral gray).

---

## GA-5 — Online scoring depth (EVAL-05)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Reuse GA-2 scorer online | No sealed reference exists for prod traces | |
| (b-naive) Positive heuristics → passed | Over-trusts "ran without error" | |
| (b-negative)+(c) Negative signals → failed; else not_scored + judge/review | Only honest reference-free option | ✓ |
| (d) Always not_scored | Throws away real error signals | |

**Choice:** Negative-signal detector — `policy_trigger`/trace-ERROR/empty-output → `failed`
(terminal); clean → `[]` scores → `not_scored`, judge is the only positive verdict, else
`needs_review`; never deterministic `passed`. Fix vacuous `Enum.all?([])`; `promotion_candidate` only
on real passes.
**Notes (revised):** needs `:spans` preload (status_code) + a `Step` load (`result_envelope` output);
emitting `[]` also kills the persisted-fabrication leak in `run_existing`.

---

## Claude's Discretion

- `ExactMatch` normalization details + `details` diff shape.
- `Verdict.compute/2` threshold-math re-expression (preserve current policy semantics, nil-safe + coverage-guarded).
- Telemetry event names beyond `:ungated`.
- Derive vs. persist `not_scored_items`.

## Deferred Ideas

- Live-subject execution + subject-prompt renderer (future slice); full `refresh_capture` wiring; `mix scoria.eval` is a TODO stub.
- Denormalized verdict column on `PromptTemplate` (v-next perf).
- Deeper/semantic scorers (SEED-008); reference-free online scorer suite (SEED-008/009).
- Distinct `not_scored` severity/label in review queue UI.
- Whether `inconclusive` should also block dataset promotion (currently keys on `"failed"` only).
