# Seeds — index & roadmap

Seeds are durable, context-proof captures of future work: they preserve **why** (not just what),
define **when to surface** (`trigger_when`), and carry breadcrumbs to the exact code. They are
committed to git so they survive any context-window clear.

> ⚠ **Recall caveat (verified 2026-07-03):** `/gsd-new-milestone` only surfaces a seed if its
> `trigger_when` *semantically matches the single theme you type first* — non-matching seeds are
> silently skipped, and seeds are NOT read by the "what's our roadmap" path. So the **ordered
> roadmap of record is `ROADMAP.md` `## Backlog`** (auto-read + preserved across milestone
> completion). This file is the human-facing "why" index that mirrors it. Keep the two in sync.

## Planned milestone order (mirrors ROADMAP.md ## Backlog)

From a 2026-07-03 AI-eval posture audit (6-agent adjudication vs LangSmith/Langfuse/Phoenix/Ragas/
Braintrust/Inspect/OTel). Cadence: **P0 → docs → features** (each feature milestone interleaves its
own feature docs + a release).

| # | Seed | Milestone | Priority | Depends on |
|---|------|-----------|----------|------------|
| 999.1 | [SEED-006](SEED-006-pre-1.0-trust-security-hardening.md) | Pre-1.0 Trust & Security Hardening | 🔴 **P0 — gates next Hex release** | — (first) |
| 999.2 | [SEED-005](SEED-005-documentation-overhaul.md) | Documentation & Positioning (stable docs) + release cut | High (adoption bottleneck) | 006 (release gate) |
| 999.3 | [SEED-007](SEED-007-trace-foundation-otel-openinference.md) | Trace Foundation (OTel/OpenInference) | High (foundational) | 006 |
| 999.4 | [SEED-010](SEED-010-lethal-trifecta-governance.md) | Lethal-Trifecta Governance | ⭐ **Flagship** | 006, 007 |
| 999.5 | [SEED-008](SEED-008-trustworthy-eval-depth.md) | Trustworthy Eval Depth | Medium | 006, 007 |
| 999.6 | [SEED-009](SEED-009-retrieval-eval-depth-and-seams.md) | Retrieval Eval Depth & Seams | Medium | 006 |
| 999.7 | [SEED-011](SEED-011-privacy-and-feedback-governance.md) | Privacy & Feedback Governance | Medium | — |

**Dependency graph (text):**
```
SEED-006 (P0, release gate) ── first, unblocks everything
   ├── SEED-005 (docs; also gates the release cut)
   ├── SEED-007 (trace foundation)
   │      ├── SEED-010 ⭐ (lethal-trifecta; also needs 006)
   │      └── SEED-008 (eval depth; also needs 006)
   ├── SEED-009 (retrieval depth)
   └── SEED-011 (privacy & feedback)
```

**The interleaving rule (why docs aren't wasted):** SEED-005 ships only the *stable* adopter docs
(terminology, positioning/scope-doctrine, ExDoc grouping, glossary, README first-screen) — these
don't go stale as features land. *Feature-specific* docs (RAG guide, SECURITY-BOUNDARY.md, the
"OpenInference-compatible" trace claim, retention/feedback guides) live as doc-deltas **inside**
their build seeds (006/007/009/010/011) and are written as each feature lands. Nothing is
pre-written obsoletely.

## All seeds (by status)

| Seed | Status | Trigger |
|------|--------|---------|
| [SEED-001](SEED-001-agentcore-lessons.md) | archived | — |
| [SEED-002](SEED-002-future-jtbd-capabilities.md) | archived | — |
| [SEED-003](SEED-003-ci-efficiency-overhaul.md) | dormant (largely realized in v3.1) | CI/CD/DX/velocity |
| SEED-004 (no file) | deferred | test-code determinism — tracked in ROADMAP Backlog + STATE.md |
| [SEED-005](SEED-005-documentation-overhaul.md) | dormant | docs / DX / adoption / Hex-release readiness |
| [SEED-006](SEED-006-pre-1.0-trust-security-hardening.md) | dormant | **BEFORE next Hex publish (release gate)** |
| [SEED-007](SEED-007-trace-foundation-otel-openinference.md) | dormant | observability / eval / interop |
| [SEED-008](SEED-008-trustworthy-eval-depth.md) | dormant | eval maturity |
| [SEED-009](SEED-009-retrieval-eval-depth-and-seams.md) | dormant | RAG / knowledge / retrieval quality |
| [SEED-010](SEED-010-lethal-trifecta-governance.md) | dormant | agent security / governance |
| [SEED-011](SEED-011-privacy-and-feedback-governance.md) | dormant | privacy / compliance / HITL feedback |

## Post-v3.3 housekeeping (collision-avoidance — do when the v3.3 window is idle)
- Record the 6-principle **scope doctrine** into `PROJECT.md` (`## Key Decisions` + `## Constraints`).
- Clean up the corrupted `STATE.md` `## Deferred Items` table + add SEED-005…011 rows.

Full session context (the audit, adjudications, decisions): `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`.
