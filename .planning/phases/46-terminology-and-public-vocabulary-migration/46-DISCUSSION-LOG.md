# Phase 46: Terminology and public vocabulary migration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-09
**Phase:** 46-Terminology and public vocabulary migration
**Areas discussed:** Rename blast radius, Evidence vs trace boundary, Glossary shape, Upgrade-note strictness

---

## Rename Blast Radius

| Option | Description | Selected |
|--------|-------------|----------|
| Docs/UI copy only | Lowest release risk, but leaves ExDoc and examples exposing stale vocabulary. | |
| Targeted documented-surface rename with aliases | Rename public/discoverable symbols and examples while preserving compatibility aliases. | yes |
| Full internal symbol rename | Clean source vocabulary, but high regression and compatibility risk. | |
| Hybrid copy now, defer public API/file paths | Improves copy but leaves core public symbols inconsistent. | |

**User's choice:** Discuss all; research through subagents; produce one coherent recommendation.

**Notes:** Selected targeted documented-surface rename with compatibility aliases. Public docs,
ExDoc, examples, and user-visible copy should use final terms. Old public symbols should remain as
compatibility wrappers during the `0.1.x` line unless Phase 50 changes the release plan.

---

## Evidence vs Trace Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Label-only rename | Low churn, but code/test names keep teaching stale language. | |
| Broad code-symbol rename | Strong consistency, but risks schemas, persisted fields, and RAG correctness. | |
| Hybrid boundary rename | Rename run-inspection labels/adapters while preserving RAG/citation evidence. | yes |

**User's choice:** Discuss all; research through subagents; produce one coherent recommendation.

**Notes:** Selected hybrid boundary. Trace names the reviewer-visible run story; evidence remains
for RAG/citation/grounding and supporting proof material. `evidence_refs` must not be renamed.

---

## Glossary Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone adopter glossary | Canonical reference, stable link target, easy to include in ExDoc now. | yes |
| Compact README glossary | Visible but bloats the front door and is weak as a reference surface. | |
| Embed in adoption_lanes | Minimal file churn but hides glossary in a how-to guide. | |
| Future-only in Phase 48 | Avoids temporary IA but fails Phase 46 and blocks Phase 47 vocabulary. | |

**User's choice:** Discuss all; research through subagents; produce one coherent recommendation.

**Notes:** Selected standalone `docs/glossary.md`, included now in ExDoc/package/docs links. Phase
48 may later group it under a reference section.

---

## Upgrade-note Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict breaking-note | Honest if old APIs are removed, but conflicts with target `0.1.3` unless release plan changes. | |
| Lighter cleanup-note | Low alarm, but too weak for docs-as-contract terminology migration. | |
| Hybrid terminology upgrade note | Old-to-new map, compatibility status, unreleased note, no overclaiming. | yes |

**User's choice:** Discuss all; research through subagents; produce one coherent recommendation.

**Notes:** Selected hybrid upgrade note. Add `[Unreleased]` CHANGELOG entry and README upgrade note
with old-to-new mapping, compatibility status, no DB migration, and Phase 50 release ownership.

---

## Claude's Discretion

- Exact wrapper/alias implementation for renamed modules.
- Exact new semantic-cache profile module name, as long as docs expose final vocabulary and old
  `Scoria.SemanticLane` remains accepted.
- Exact terminology guard module names and scan allowlists.
- Exact glossary wording within the locked term set.

## Deferred Ideas

- Phase 47: full README first-screen positioning and scope doctrine table.
- Phase 48: ExDoc grouping, guide ladder, and docs IA.
- Phase 49: curated root `llms.txt` / `AGENTS.md`.
- Phase 50: release cut and final release notes.
- SEED-007/009/013: trace substrate, RAG eval depth, and structural reviewer UI pivot.
