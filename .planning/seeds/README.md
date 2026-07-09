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
| 999.2 | [SEED-005](SEED-005-documentation-overhaul.md) | Documentation & Positioning (stable docs) + release cut | High (adoption bottleneck) | 006 (release gate) |
| 999.3 | [SEED-007](SEED-007-trace-foundation-otel-openinference.md) | Trace Foundation (OTel/OpenInference) | High (foundational) | 006 |
| 999.4 | [SEED-010](SEED-010-lethal-trifecta-governance.md) | Lethal-Trifecta Governance | ⭐ **Flagship** | 006, 007 |
| 999.5 | [SEED-008](SEED-008-trustworthy-eval-depth.md) | Trustworthy Eval Depth | Medium | 006, 007 |
| 999.6 | [SEED-009](SEED-009-retrieval-eval-depth-and-seams.md) | Retrieval Eval Depth & Seams | Medium | 006 |
| 999.7 | [SEED-011](SEED-011-privacy-and-feedback-governance.md) | Privacy & Feedback Governance | Medium | — |
| 999.8 | [SEED-012](SEED-012-architecture-archetype-awareness.md) | Architecture-Archetype Awareness (Rule-8 lens) | Medium (small capstone) | 007, 008 |
| 999.9 | [SEED-013](SEED-013-operator-ia-pivot.md) | Operator IA Pivot (Control-Room v2) | High (dashboard coherence) | — (shell); composes 005/007/008/010/011/012 |

**Dependency graph (text):**
```
SEED-006 (P0, release gate) ── shipped in v3.4; unblocks everything
   ├── SEED-005 (docs; also gates the release cut)
   ├── SEED-007 (trace foundation)
   │      ├── SEED-010 ⭐ (lethal-trifecta; also needs 006)
   │      ├── SEED-008 (eval depth; also needs 006)
   │      └── SEED-012 (archetype lens / Rule-8; needs 007 + 008 — capstone)
   ├── SEED-009 (retrieval depth)
   └── SEED-011 (privacy & feedback)

SEED-013 (operator IA pivot / Control-Room v2) ── structural shell buildable on today's backend
   (depends_on: none); the umbrella that 005/007/008/010/011/012 each fold a UI slice into.
   Sequence after 006 (P0), alongside/after 005 (vocab).
```

**Source memo for the 2026-07-03 AI-architecture-patterns ingest:** `.planning/research/ai-architectural-patterns.md`
— the 14-pattern field guide the 005/007/008/009/010/011/012 "AI-Architecture-Patterns cross-ref" sections
point at. It *validated* ~85% of Scoria as-built (patterns map ~1:1 onto shipped subsystems), so the ingest
produced annotations + one new capstone seed (012), not new milestones. Sibling memo
`prompts/ai-eval-best-practices-deep-research.md` is a candidate for the same ingest treatment later.

**Source memo for the 2026-07-03 operator-UI storyboard ingest:** `.planning/research/operator-ui-north-star.md`
— the doctrine-filtered UI source-of-record the 005/007/008/009/010/011/012 "Operator-UI North-Star cross-ref"
sections point at (distilled from `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md`). The
storyboard was blank-slate/maximalist; ~40% already ships, so the ingest produced the North-Star doc + one
structural seed (013, the IA pivot / Control-Room v2) + annotations — not a from-scratch redesign. The doc's
"which screen rides which seed" slice map tells each future UI-touching milestone exactly which slice it owns.

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
| [SEED-003](SEED-003-ci-efficiency-overhaul.md) | archived (v3.1 shipped) | — |
| SEED-004 (no file) | deferred | test-code determinism — tracked in ROADMAP Backlog + STATE.md |
| [SEED-005](SEED-005-documentation-overhaul.md) | deferred | docs / DX / adoption / Hex-release readiness |
| [SEED-006](SEED-006-pre-1.0-trust-security-hardening.md) | archived (v3.4 shipped) | — |
| [SEED-007](SEED-007-trace-foundation-otel-openinference.md) | deferred | observability / eval / interop |
| [SEED-008](SEED-008-trustworthy-eval-depth.md) | deferred | eval maturity |
| [SEED-009](SEED-009-retrieval-eval-depth-and-seams.md) | deferred | RAG / knowledge / retrieval quality |
| [SEED-010](SEED-010-lethal-trifecta-governance.md) | deferred | agent security / governance |
| [SEED-011](SEED-011-privacy-and-feedback-governance.md) | deferred | privacy / compliance / HITL feedback |
| [SEED-012](SEED-012-architecture-archetype-awareness.md) | deferred | pattern lens / archetype / router analytics / Rule-8 evals |
| [SEED-013](SEED-013-operator-ia-pivot.md) | deferred | dashboard IA / operator UX / content-hierarchy pivot / control-room redesign |

## Post-v3.3 housekeeping (collision-avoidance — do when the v3.3 window is idle)
- Record the 6-principle **scope doctrine** into `PROJECT.md` (`## Key Decisions` + `## Constraints`).
- Clean up the corrupted `STATE.md` `## Deferred Items` table + add SEED-005…011 rows.

Full session context (the audit, adjudications, decisions): `~/.claude/plans/so-i-m-looking-at-quizzical-widget.md`.
