---
id: SEED-008
status: deferred
planted: 2026-07-03
deferred_on: 2026-07-09
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: next milestone scoped as eval maturity — sequence after SEED-006 (fail-closed) + SEED-007 (traces)
scope: large
priority: medium
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-008: Trustworthy Eval Depth (scorers, calibration, regression)

## Why This Matters

[[SEED-006]] makes the eval engine *fail closed* (stops lying). This seed makes it *actually good* —
the depth that turns Scoria's eval harness from a schema into a trustworthy measurement system. The
audit found the harness has excellent bones (sealed/immutable datasets, prompt-release gates, the
online→review→dataset→gate flywheel) but three depth holes: no real scorer library, no judge
calibration (despite uniquely capturing both sides), and no version-vs-version comparison.

## When to Surface

**Trigger:** eval-maturity milestone, **after [[SEED-006]] and [[SEED-007]]** (real scorers and
regression diffs are meaningless over fake-green scores or attribution-less traces).

## Scope Estimate

**Large** — ≈3–4 phases. All within `lib/scoria/eval/**` + `dataset_item.ex`/`eval_spec.ex`.

## What to build

1. **Real scorer library (BUILD).** A `Scorer` behaviour/contract + a canonical built-in set
   (`exact_match`, `includes`, `regex`, `json_schema`, `numeric_tolerance`) + a custom-scorer callback.
   Ship the *contract + a small canonical set*, not N built-ins (avoid scope creep). *Peers: Braintrust
   `autoevals`, Inspect scorers, OpenAI Evals deterministic-then-model graders.*
2. **Judge calibration + human-label agreement loop (BUILD — differentiator).** Scoria **uniquely
   already captures both** human labels (review-queue accept/dismiss/promote) AND judge verdicts
   (`Score`) — and throws the join away. Compute a confusion matrix + Cohen's kappa between judge verdict
   and majority human label, **per rubric_version**, with a min-N gate and a target (kappa ≥ 0.6; 0.8
   high-stakes). Do NOT auto-tune the judge silently (host approves rubric changes). *Peers: LangSmith
   Align Evals, MLflow judge alignment, Phoenix human-alignment.* The memo undersells this — it's a
   headline capability uniquely available to Scoria, not a checkbox.
3. **Judge prompt as a versioned artifact (BUILD, small).** Today the judge prompt is inlined in
   `JudgeRunner` and `rubric_version` is a derived string. Promote it to a real object via the existing
   `prompt_registry` + `ReleaseGate` machinery (so `rubric_version` points at a pinned artifact) — a
   precondition for meaningful calibration (2) and comparison (4).
4. **Regression comparison engine + offline segment (BUILD).** `baseline_eval_run_id` is stored but
   **never diffed**. Build an engine that diffs a run vs its baseline → per-case status/score deltas +
   aggregate regression verdict (with significance + min-N guardrail) + segment/`dataset_slice`
   breakdown. Introduce a gated **"comparison campaign" mode** that relaxes the
   `@semantic_override_fields` ban (`eval_campaign_target.ex:9-20`) for baseline-vs-candidate + slice
   ONLY (campaigns currently can only fan provider/model). Live-traffic canary *routing* stays DELEGATED
   to the host. *Peers: Braintrust side-by-side + regression detection + output diffs; LangSmith/Phoenix segment comparison.*
5. **Typed risk/intent taxonomy slots (BUILD slots + DOCS values).** Add engine-readable slots on
   `DatasetItem` (risk_tier, intent, segment tags, per-case rubric_ref, owner) and make `risk_tier` a
   gate/comparison dimension. **Do NOT prescribe the tier enum or own privacy/owner classification** —
   that's host identity/policy. Ship the hooks + document the contract; let the host set values.
6. **Reviewer disagreement data model (BUILD data model + DEFER workflow).** Record N reviewer
   dispositions per candidate + an inter-rater agreement flag (majority label = ground truth for
   calibration). Defer the heavyweight adjudicator-assignment workflow UI pre-1.0.

## Disagreements with the memo (recorded)
- Risk-tier/privacy/owner: the memo wants a rich first-class taxonomy owned by the platform; for embedded,
  ship typed *slots* + make risk_tier a gate dimension, but don't prescribe the enum or own classification.
- Canary + SLO ownership: build offline/replay segment comparison; **delegate** live traffic-splitting +
  SLO ownership to the host runtime.
- Full multi-rater adjudication *workflow*: build the data model (calibration needs it); defer the UI.

## Scope doctrine reference
P2 (Scoria owns the eval *mechanism*; host supplies dataset/thresholds/tier values via hooks). The
judge-calibration join is pure mechanism Scoria already has both inputs for — squarely in-scope.

## Breadcrumbs
- `lib/scoria/eval/runner.ex`, `lib/scoria/eval/judge_runner.ex` (inline rubric; baseline write),
  `lib/scoria/eval/online_scoring.ex`, `lib/scoria/eval/review_queue.ex` (human dispositions never joined),
  `lib/scoria/eval/eval_campaign_target.ex` (`@semantic_override_fields` ban), `lib/scoria/eval/eval_run.ex`
  (inert `baseline_eval_run_id`), `lib/scoria/eval/dataset_item.ex` + `eval_spec.ex` (taxonomy slots),
  `lib/scoria/prompt_registry/**` (reuse for versioned rubric).
- Source memo §5,6,14,15,16. Full audit: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`. Related: [[SEED-006]], [[SEED-007]].

## AI-Architecture-Patterns cross-ref (2026-07-03)

Source memo: `.planning/research/ai-architectural-patterns.md` — **Rule 8 ("the eval shape should match
the architecture shape")** is this seed's premise made explicit, plus §1/§2 (single-call + structured
extraction evals). Additions, all annotations riding existing mechanisms:

- **`archetype` as a typed slot** beside the existing `intent` / `risk_tier` slots on `DatasetItem`
  (item 5) — host sets the value; Scoria records/segments, never infers. One more host-supplied slot,
  not new machinery.
- **Rule-8 eval-set-per-archetype preset** (guidance/config on top of the scorer library, never enforced
  values — P2): router → routing-accuracy; rag → retrieval + faithfulness + citation; tool-assistant →
  tool-selection + args + permissions; agent → trace + goal-completion + stop-behavior.
- **The confusion-matrix + Cohen's-kappa machinery (item 2) also serves routing accuracy** — same
  machinery on a different axis (predicted-route vs gold-route instead of judge-verdict vs human-label).
  So Router observability needs no new eval primitive; it reuses item 2.

Together these are the eval half of the [[SEED-012]] archetype lens (the trace-attribute half is in
[[SEED-007]]).

## Operator-UI North-Star cross-ref (2026-07-03)

Source memo: `.planning/research/operator-ui-north-star.md`. This seed owns the **Quality-depth screens**
the [[SEED-013]] IA pivot frames:
- **Eval Run Detail** — candidate-vs-baseline, overall pass rate, a per-segment/per-intent **breakdown
  table**, and an explicit **Decision: Blocked/Passed** with blocker reasons.
- **Eval-case-as-story** — a failed case is inspectable (input, expected/forbidden behavior, baseline vs
  candidate output, per-scorer pass/fail, link back to the source trace), never "just a red number."
- **Release-gate view** — checklist of checks with ✓/✕/⚠ + a note-required, receipt-producing **override**
  (mechanism, not policy — P2).
- **Feeds the Workbench inspector's Diagnosis slot mechanically** — "similar-failure count," "linked
  regression failures: 12" are *counts over eval records*, which is exactly how the North-Star guardrail
  wants Diagnosis driven (mechanical signal, **not** an in-lib LLM opinion). Reinforces, doesn't expand,
  this seed's scope.

## Notes
Planted during v3.3 from a 6-agent adjudicated audit. Judge calibration (item 2) is flagged by the
audit as an under-sold *differentiator* — Scoria captures both signals and discards the join; no other
embedded lib does this.
