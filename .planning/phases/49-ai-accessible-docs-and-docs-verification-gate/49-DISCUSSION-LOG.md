# Phase 49: AI-accessible docs and docs verification gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 49-AI-accessible docs and docs verification gate
**Areas discussed:** Root AI Entry Point, Curated Source vs Generated ExDoc Boundary, Docs Warning Gate Shape, Drift Contract Strictness

---

## Root AI Entry Point

| Option | Description | Selected |
|--------|-------------|----------|
| Root `llms.txt` only | Strong public AI docs map, but weak coding-agent operating guidance. | |
| Root `AGENTS.md` only | Strong coding-agent DX, but not the public llms.txt docs convention. | |
| Expanded `GEMINI.md` only | Uses the existing file, but is Gemini-specific and weak as a public AI docs surface. | |
| Root `llms.txt` + `AGENTS.md` | Clean concern split between public docs map and coding-agent instructions. | |
| Root `llms.txt` + `AGENTS.md` + minimal `GEMINI.md` adapter | Broad coverage without vendor-specific duplication; preserves existing Ash non-goal. | yes |

**User's choice:** User asked to discuss and research all options and produce a one-shot recommendation so they do not need to decide manually.
**Notes:** Subagent research recommended root `llms.txt`, concise `AGENTS.md`, and a tiny `GEMINI.md` bridge. This fits the repo's existing generated `doc/llms.txt`, current root `GEMINI.md`, and missing root `llms.txt`/`AGENTS.md`.

---

## Curated Source vs Generated ExDoc Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Source-first | Simple source truth under `README.md` and `guides/`, but underuses ExDoc generated markdown. | |
| Generated-first | Makes ExDoc markdown primary, but risks treating ignored `doc/` output as editable truth. | |
| Hybrid mirrored | Gives both source and generated surfaces equal weight, but duplicates truth and creates stale-file risk. | |
| Generated-as-derived | Source docs are canonical; generated ExDoc output is useful derived reference. | yes |

**User's choice:** User delegated the tradeoff decision after requesting deep research across ecosystem, architecture, DX, and user-flow lenses.
**Notes:** Phase 48 already locked `guides/` as canonical and `docs/` as compatibility-only. Phase 49 should not reverse that. Root AI files should point at source docs and label `doc/llms.txt` as generated.

---

## Docs Warning Gate Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Harden `mix scoria.release_preview` with `docs --warnings-as-errors` | One canonical release proof, already wired in `VerificationSuites` and CI. | |
| Add dedicated docs check task | Better diagnostics, but adds another command and can drift from release preview. | |
| Wire raw `mix docs --warnings-as-errors` directly into CI policy | Fast fail-left, but creates dev/test CI environment churn and bypasses the verification-suite model. | |
| Release-preview hard gate plus direct docs diagnostic command | Keeps release preview authoritative while documenting raw docs command for troubleshooting. | yes |

**User's choice:** User delegated the tradeoff decision.
**Notes:** Local evidence on 2026-07-10: `MIX_ENV=dev mix docs --warnings-as-errors` failed on ExDoc warnings; `MIX_ENV=dev mix scoria.release_preview` passed while printing the same warnings. Recommendation is to fix warnings and harden release preview.

---

## Drift Contract Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal smoke | Low maintenance, but misses silent AI front-door drift. | |
| Exact section contract | Predictable, but brittle and likely to harm docs prose. | |
| Forbidden vocabulary/source-boundary contract | High signal for stale terminology and internal leakage, but incomplete alone. | |
| Generated artifact contract | Tests generated docs, but risks overfitting artifact text. | |
| Layered contract | Positive coverage, forbidden-boundary checks, docs warning gate, and light generated artifact checks. | yes |

**User's choice:** User delegated the tradeoff decision.
**Notes:** Recommendation is to extend Scoria's existing docs-as-contract pattern. Tests should pin facts and boundaries, not exact prose snapshots.

---

## Claude's Discretion

- Exact names for a new AI docs contract module are left to planner/executor judgment.
- Exact `llms.txt` and `AGENTS.md` headings are flexible as long as the source-of-truth, guide, glossary, verification, and generated-artifact contracts are present.
- Exact ExDoc warning fixes are left to implementation after inspecting ExDoc autolink behavior.

## Deferred Ideas

- Committed full generated docs mirror or `llms-full.txt`.
- New vendor-specific root instruction files beyond the existing `GEMINI.md` bridge.
- New future-feature docs for unbuilt seeds.
- Moving docs warning proof into the CI policy job.
