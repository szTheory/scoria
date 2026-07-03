---
id: SEED-006
status: dormant
planted: 2026-07-03
planted_during: v3.3 Design System Stress Test (phase 39 in-flight)
trigger_when: BEFORE the next Hex publish — this GATES the release (maintainer decision 2026-07-03)
scope: medium-large
priority: P0
enriched: 2026-07-03 (from a 6-agent adjudicated audit vs a production-AI-eval memo)
---

# SEED-006: Pre-1.0 Trust & Security Hardening (RELEASE-GATING)

> **This seed GATES the next Hex release.** Maintainer decision (2026-07-03): the pending
> 0.1.3 release-please PR (#12) is held/superseded until the three P0s below are fixed. Scoria
> will not publish a new version with known security + trust bugs. New release order:
> **SEED-006 → clean-spot/release work (see [[SEED-005]] Phase E) → publish.**

## Why This Matters

A 6-agent adjudicated audit of Scoria against a production-AI-eval best-practices memo found
Scoria's architecture is **soundly aimed** (Level 3→4, real differentiators) — but three **P0
correctness/security bugs are live in the already-published 0.1.2**. They are not future
features; they are defects in shipped code that undermine Scoria's core promise ("trustworthy,
governed, inspectable AI ops") and can expose adopters' data. Fix before broadcasting Scoria
more widely or cutting a new release.

## When to Surface

**Trigger:** immediately, as the gate on the next release. Surface at the top of the next
milestone regardless of theme; it precedes the docs milestone ([[SEED-005]]) and the release cut.

## Scope Estimate

**Medium-Large** — one focused hardening milestone (≈3 phases, one per P0, + a bug-sweep
phase). Mostly `lib/scoria/eval/**`, `lib/scoria/knowledge/**`, `lib/scoria_web/router.ex` +
a knowledge migration. Low product-surface risk, high trust payoff. Pre-1.0 (0.1.x) makes the
breaking knowledge migration cheap.

## The Three P0s

### P0-1 — Eval engine is fail-OPEN (fake-green scores)
The library's entire value proposition is trustworthy eval, yet:
- Offline `Eval.Runner.record_scores/4` **hardcodes** `status: "passed", score: 1.0, latency_ms: 0`
  for every dataset item (`lib/scoria/eval/runner.ex:57-79`) — it never compares output to expectation.
- `Eval.OnlineScoring.deterministic_scores/3` decides pass/fail purely on
  `sample_reason == "policy_trigger"` (`lib/scoria/eval/online_scoring.ex:235-272`), never inspecting output.
- **Worse:** `Eval.JudgeRunner.build_subject_output` sets the subject output to
  `dataset_item.expected_output["answer"]` and feeds that same value as "Actual" while "Expected"
  is the full expectation (`lib/scoria/eval/judge_runner.ex:138-150`) — **the subject prompt is
  never executed; the judge grades the sealed expectation against itself.** Offline `live_judge`
  runs pass near-universally regardless of real model behavior.
- Therefore `threshold_verdict` always reads `passed` (pass_rate=1.0, mean=1.0, latency=0 vs any
  threshold), and `Runtime.ReleaseGate` only blocks `status: "draft"` prompts — it never consults
  `threshold_verdict`. **The release gate is decorative for quality.**
- **Fix:** (a) actually execute/replay the subject prompt so "Actual" is a real output (kill the
  `expected_output["answer"]` shortcut); (b) implement at least one real deterministic scorer that
  compares output vs expectation; (c) until a real scorer is configured, emit `:not_scored` and make
  `threshold_verdict`/`ReleaseGate` **fail CLOSED** (verdict `failed`/`inconclusive`), never fake-green.
- *(Deeper real-scorer breadth → [[SEED-008]]; this P0 is only "stop lying / fail closed".)*

### P0-2 — Knowledge/retrieval cross-tenant leak
`ai_knowledge_sources` / `ai_knowledge_chunks` / `ai_retrieval_runs` have **no tenant_id/actor_id/ACL**
(real DDL: `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`; the
same-named file under `priv/repo/migrations/` is a `:ok` stub). `Backends.Pgvector.similar_chunks/2`
filters only an optional `source_id` (`lib/scoria/knowledge/backends/pgvector.ex:18-53`) — a `nil`
silently returns **all tenants' chunks**. → any tenant's query embedding can retrieve another
tenant's raw chunk `body` + citation `quote` (content exfiltration) + embedding membership-inference.
- **Why it's Scoria's job (not the host's):** Scoria *owns the tables and builds the query* — the
  host has no seam to inject scoping. And Scoria already proves this is its responsibility by
  rigorously scoping the SemanticCache (`SemanticCache.Lookup.base_query`) and Connectors
  (`Connectors` `maybe_filter_tenant`) identically. Knowledge is the lone unscoped subsystem.
- **Fix:** add `tenant_id` (+ optional `actor_id`/`scope_kind` mirroring the cache's
  `tenant_shared`/`actor_scoped`) to sources + chunks; propagate to retrieval_runs/results/citations
  for audit; index `[tenant_id]`/`[tenant_id, source_id]`; enforce a **mandatory fail-closed** filter
  in `similar_chunks`, `Scrypath.retrieve`, `list_source_chunks`, `Knowledge.retrieve/ingest`.
  **A nil tenant must RAISE, not match-all** (avoid reproducing the `maybe_filter_source` footgun).

### P0-3 — Dashboard auth bypass
`scoria_dashboard/2` takes `_opts` and **discards them** — `on_mount: ScoriaWeb.DashboardNav` is
hardcoded (`lib/scoria_web/router.ex:20-53`), so a host **cannot inject its own auth `on_mount`
without forking**. Combined with `tenant_id` read from session/params with a `"default"` fallback and
**no enforcement** that the operator may view that tenant, an unauthenticated request can read another
tenant's traces by setting `tenant_id`. This is not "no RBAC" — it's no authentication boundary at all
on a dashboard that renders other tenants' data.
- **Fix (P4 doctrine — delegate authz, but ship the seam):** make `scoria_dashboard/2` accept a
  pass-through `on_mount:` list (host hooks run before `DashboardNav`) + a documented
  tenant-resolution/authorization callback so `tenant_id` is host-asserted, not a spoofable param.
  Do **not** add an in-lib role model. *(Full masking-contract + retention → [[SEED-011]].)*

## Correctness bugs to sweep (same milestone)
- `Knowledge.score_chunk/2` persists a **fake** similarity `1/(1+|Σemb−Σquery|)` (component sums,
  NOT cosine) into `retrieval_results.score` (`lib/scoria/knowledge/backends/pgvector.ex:62-68`);
  ordering uses real `cosine_distance` but the stored score is nonsense → corrupts any downstream
  precision/NDCG and any host reading `score`. Fix to persist real cosine similarity.
- `citation_presence` returns `0.0/"failed"` for empty citations (`lib/scoria/knowledge/grounding.ex:4-8`),
  wrongly penalizing **correct abstention** on unanswerable queries. Make it label-aware. *(Full
  abstention scorer → [[SEED-009]].)*
- `Chunker.Default` overlap is a no-op: `next_offset = max(end-overlap, end)` is always `end`
  (`lib/scoria/knowledge/chunker.ex:31`). Remove the dead param + document Default as non-overlapping
  (real sliding-window overlap → separate chunker, [[SEED-009]]).
- `max_latency_ms` gate compares against latency hardcoded to 0 in the stub scorers — becomes real once
  P0-1's real scorers record actual latency.

## Scope doctrine reference (why these are BUILD/FIX, not DELEGATE)
Per the audit's scope doctrine — **Scoria owns the verb (record, gate, surface, reconstruct); host
owns the noun.** P0-1 is Scoria's eval *mechanism* (P2). P0-2: Scoria owns the query so only Scoria can
enforce scoping (P4/P5). P0-3: authz is *delegated* (P4) but Scoria must ship the *seam* — today it
doesn't. Full doctrine (P1–P6) recorded in [[SEED-005]]; **follow-up: add the 6 principles to
`.planning/PROJECT.md` (decisions SSOT) once v3.3 finishes** (avoid colliding with the live window now).

## Breadcrumbs
- Eval fail-open: `lib/scoria/eval/runner.ex:57-79`, `lib/scoria/eval/judge_runner.ex:138-150`,
  `lib/scoria/eval/online_scoring.ex:235-272`, `lib/scoria/runtime/release_gate.ex`, `eval/eval_run.ex` (inert `baseline_eval_run_id`).
- Knowledge leak: `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`,
  `lib/scoria/knowledge/backends/pgvector.ex`, `lib/scoria/knowledge.ex`; scoping pattern to mirror: `lib/scoria/semantic_cache/lookup.ex`, `lib/scoria/connectors.ex`.
- Dashboard authz: `lib/scoria_web/router.ex` (`scoria_dashboard/2`), `lib/scoria_web/operator_surface.ex` (tenant scoping vs authz).
- Source memo: `prompts/ai-eval-best-practices-deep-research.md`. Full audit + doctrine: `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`.

## Notes
Planted during v3.3 from a 6-agent adjudicated audit (3 posture-mapping + 6 validation agents vs
LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel). These three were the only findings ranked
P0; every other audit finding is a depth/differentiator seed ([[SEED-007]]…[[SEED-011]]). Related:
[[SEED-005]] (docs — its Phase E is the clean-spot/release work this seed now precedes).
