# Requirements: Scoria — v3.4 Pre-1.0 Trust & Security Hardening

**Defined:** 2026-07-04
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

> 🔴 **P0 milestone — GATES the next Hex release.** Fixes three P0 correctness/security bugs live in
> shipped `0.1.2` (validated against current `main`, 2026-07-04) plus a correctness sweep. Backing
> analysis: `.planning/seeds/SEED-006-pre-1.0-trust-security-hardening.md` (from the 2026-07-03
> 6-agent AI-eval posture audit). Scope doctrine (P1–P6) in `PROJECT.md ## Constraints`.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### EVAL — Eval fails CLOSED (P0-1)

The library's core promise is trustworthy eval, yet offline `Eval.Runner.record_scores/4` hardcodes
`passed/1.0/latency 0`, `Eval.JudgeRunner.build_subject_output` grades the sealed expectation against
itself, `Eval.OnlineScoring.deterministic_scores/3` decides on `sample_reason` alone, and
`Runtime.ReleaseGate` never consults `threshold_verdict`. The engine fails OPEN (fake-green).

- [x] **EVAL-01**: Offline/judge eval executes or replays the real subject prompt so the "Actual"
  output is a real result — the `expected_output["answer"]` shortcut in `build_subject_output` is removed.
- [ ] **EVAL-02**: At least one real deterministic scorer compares actual output vs expectation,
  reusing the existing `Scoria.Knowledge.Grounding` scorer style and the `Scoria.Eval.Score` write sink.
- [x] **EVAL-03**: When no real scorer is configured, eval emits `:not_scored` and `threshold_verdict`
  / `ReleaseGate` fail CLOSED (`failed`/`inconclusive`) — a run is never reported green by default.
- [ ] **EVAL-04**: `Runtime.ReleaseGate` consults `threshold_verdict` before allowing a release, not
  only the prompt's `status: "draft"`.
- [ ] **EVAL-05**: Online scoring stops fabricating pass/fail from `sample_reason == "policy_trigger"`
  alone — it inspects real trace output or marks the candidate `:not_scored`.

### KNOW — Knowledge tenant isolation (P0-2)

`ai_knowledge_sources` / `ai_knowledge_chunks` / `ai_retrieval_runs` (+ results/citations) carry no
tenant/actor/ACL, and `Backends.Pgvector.similar_chunks/2` filters only an optional `source_id` — a
nil silently returns every tenant's chunks. Any tenant's query embedding can retrieve another
tenant's raw chunk body + citation quote. Scoria owns the tables and builds the query, so only Scoria
can enforce scoping (it already does so for `SemanticCache` and `Connectors`).

- [ ] **KNOW-01**: A new knowledge migration adds `tenant_id` (+ optional `actor_id`/`scope_kind`
  mirroring `SemanticCache`) to sources + chunks, with `[tenant_id]` and `[tenant_id, source_id]`
  indexes. (Migration runs via the separate `KnowledgeMigrationRepo` / `schema_migrations_knowledge`
  path; confirm the production run path is documented.)
- [ ] **KNOW-02**: `retrieval_runs`, `retrieval_results`, and `citations` carry tenant/actor for audit.
- [ ] **KNOW-03**: `similar_chunks`, `Scrypath.retrieve`, `list_source_chunks`, and
  `Knowledge.retrieve/ingest` enforce a mandatory fail-closed tenant filter — a nil tenant RAISES
  (mirrors `SemanticCache.Lookup.base_query`'s `Map.fetch!`), never match-all.
- [ ] **KNOW-04**: A cross-tenant isolation test proves tenant A's query returns zero of tenant B's chunks.

### AUTH — Dashboard auth seam (P0-3)

`scoria_dashboard/2` discards its `_opts` and hardcodes `on_mount: ScoriaWeb.DashboardNav`, so a host
cannot inject its own auth hook without forking; each LiveView resolves `tenant_id` as
`params["tenant"] || session["tenant_id"] || "default"` with no check that the caller may view that
tenant — so `?tenant=<victim>` reads another tenant's data. Authz is *delegated* (P4), but Scoria must
ship the *seam*.

- [ ] **AUTH-01**: `scoria_dashboard/2` accepts a pass-through `on_mount:` list (host hooks run before
  `DashboardNav`, which stays in the chain); the bare `scoria_dashboard "/scoria"` form still compiles
  (installer, dev router, and example host all emit it).
- [ ] **AUTH-02**: A documented tenant-resolution/authorization callback makes `tenant_id`
  host-asserted, not a spoofable `?tenant=` param. No in-lib role/RBAC model is added.
- [ ] **AUTH-03**: Dashboard LiveViews resolve tenant from the host-asserted source; the
  unauthenticated `params["tenant"] → "default"` spoof path is closed.

### FIX — Correctness sweep

- [ ] **FIX-01**: `Knowledge.Backends.Pgvector.score_chunk/2` persists real cosine similarity matching
  the `cosine_distance` ranking metric, not the fake `1/(1+|Σemb−Σquery|)` component-sum score.
- [ ] **FIX-02**: `Knowledge.Grounding.score_citation_presence` is label-aware — correct abstention on
  unanswerable queries is not penalized as `0.0/"failed"`.
- [ ] **FIX-03**: `Chunker.Default`'s dead `overlap` param (the `max(end - overlap, end)` no-op) is
  removed and the chunker is documented as non-overlapping.
- [ ] **FIX-04**: The `max_latency_ms` gate operates on real recorded latency (enabled once EVAL's real
  scorers record actual latency instead of a hardcoded 0).

### DOC — Scope doctrine SSOT

- [ ] **DOC-01**: The 6-principle scope doctrine ("Scoria owns the verb; host owns the noun", P1–P6) is
  recorded in `PROJECT.md ## Constraints` + `## Key Decisions` and cross-linked from the eval /
  knowledge / dashboard fix rationale. *(Note: the doctrine was already recorded at v3.3 close —
  `PROJECT.md:349` Constraints + Key Decisions rows — so this is a confirm-and-cross-link task, not
  net-new authoring.)*

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Hex `0.1.3` publish / release-please PR #12 | The honest release cut belongs to SEED-005 (999.2); this milestone is fix + prove only. `0.1.3` stays held. |
| Deeper real-scorer breadth, regression-comparison engine, judge calibration | SEED-008 (999.5). EVAL here is only "stop lying / fail closed". |
| Full label-aware abstention scorer, sliding-window overlap chunker, faithfulness/rerank hooks | SEED-009 (999.6). FIX-02/FIX-03 here are the minimal correctness fixes only. |
| In-lib role/RBAC model, PII masking contract, retention/purge | Authz stays delegated (P4); masking/retention → SEED-011 (999.7). |
| Online-scoring output-inspection depth beyond fail-closed | SEED-008. EVAL-05 here only stops fabrication. |
| Full OTel-GenAI/OpenInference trace attribution | SEED-007 (999.3). |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVAL-01 | Phase 42 | Complete |
| EVAL-02 | Phase 42 | Pending |
| EVAL-03 | Phase 42 | Complete |
| EVAL-04 | Phase 42 | Pending |
| EVAL-05 | Phase 42 | Pending |
| KNOW-01 | Phase 43 | Pending |
| KNOW-02 | Phase 43 | Pending |
| KNOW-03 | Phase 43 | Pending |
| KNOW-04 | Phase 43 | Pending |
| AUTH-01 | Phase 44 | Pending |
| AUTH-02 | Phase 44 | Pending |
| AUTH-03 | Phase 44 | Pending |
| FIX-01 | Phase 45 | Pending |
| FIX-02 | Phase 45 | Pending |
| FIX-03 | Phase 45 | Pending |
| FIX-04 | Phase 45 | Pending |
| DOC-01 | Phase 45 | Pending |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 17 (proposed; finalized by roadmapper)
- Unmapped: 0

---
*Requirements defined: 2026-07-04*
*Last updated: 2026-07-04 after initial definition*
