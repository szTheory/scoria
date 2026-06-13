# Phase 17: Consistency sweep + proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 17-consistency-sweep-proof
**Areas discussed:** Final audit method, Contact sheet form, Component catalog home, Proof report + zero-claim
**Mode:** Advisor (`minimal_decisive`); 4 parallel `gsd-advisor-researcher` passes (sonnet); user approved the synthesized set as a whole.

---

## Final Audit Method (PROOF-01 delta)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Re-run LLM critique only | Method-matched to baseline, full 9-dim coverage; but non-deterministic + ~9 API calls, unfalsifiable as proof | |
| (B) Deterministic structured scoring only | Reproducible, no API cost; but breaks method-match → the "delta" is not honest | |
| (C) Hybrid: LLM critique delta + deterministic 11-P1 resolution checklist | Method-matched headline delta AND a re-runnable, zero-API-cost falsifiable artifact | ✓ |

**User's choice:** Create context with (C) Hybrid.
**Notes:** Honest delta requires same method as the 2026-06-04 baseline (LLM vision critique); repo's executable-proof culture requires a re-runnable artifact, supplied by the deterministic P1 checklist. LLM run stamped with date + model id.

---

## Contact Sheet Form (PROOF-02)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Committed HTML generator + committed markdown index; rendered images gitignored/regenerable | Durable, regenerable, zero binaries, extends existing shots harness | ✓ |
| (B) Committed markdown index only (links to gitignored PNGs) | Trivial; but dead links anywhere but the author's disk — fails PROOF-02 intent | |
| (C) Commit a curated montage image | Visible in GitHub; but introduces a committed binary (violates zero-binary posture) | |

**User's choice:** Create context with (A) generator + index.
**Notes:** Generator takes `--before/--after` dated dirs so future milestone passes re-run with no code change; output stays under gitignored `priv/shots/` and excluded from the Hex package via `mix.exs package.files`.

---

## Component Catalog Home (PROOF-03)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Dedicated `docs/design_system.md` linked from MAINTAINERS.md | Cohesive separate doc; but hand-written prose drifts from `ui.ex` | |
| (B/C) `ui.ex` moduledocs (attr/slot/@doc) as SSOT via `mix docs` + a glance section in MAINTAINERS.md | Zero drift by construction; PROOF-03 entry-point stays in MAINTAINERS.md | ✓ |

**User's choice:** Create context with the moduledoc-SSOT + MAINTAINERS.md catalog section.
**Notes:** `ui.ex` already uses `attr`/`slot`; backfill moduledocs so ExDoc renders the full reference. MAINTAINERS.md already documents harness usage (half of PROOF-03 done) — only the catalog entry-point is added.

---

## Proof Report + Zero-Claim (PROOF-01)

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Single consolidated report `priv/shots/gap_register_final.md` citing DS-06 guard for the zero-claim | Mirrors committed baseline naming; one citable file; honest (cites the executable, doesn't re-prove) | ✓ |
| (B) Dated subdir + separate PROOF doc | Archive-shaped; but splits the story across two files, overkill for a one-time close | |

**User's choice:** Create context with (A) consolidated report; merged with the Final Audit Method artifacts.
**Notes:** Raw-color count is already 0 and guarded by `ds06_drift_guard_test.exs` + empty `ds06_baseline.txt`; the report cites that executable rather than adding a redundant counting script. The report holds the delta table + the 11-P1 checklist + the zero-claim in one file.

---

## Claude's Discretion

- Exact filenames (`contact_sheet.mjs` vs a `shots.mjs` flag; `gap_register_final.md` vs an equivalent name), markdown layout of the delta table and P1 checklist, contact-sheet grid HTML/CSS, plan slicing, final dated dir name.
- Whether the final critique covers all 9 screens or screens-with-P1s + a representative sample (but the per-screen delta table must cover the same 9 baseline screens).
- Whether the MAINTAINERS.md catalog section sits inside or adjacent to the existing harness section.

## Deferred Ideas

- Standing browser-a11y lane (axe across all screens/themes/viewports) and CI visual-regression baselines — out of v3.0 scope; harness stays dev-only.
- Adding screenshot/critique or contact-sheet generation to merge-blocking CI.
- Recurring multi-date audit archive (dated subdirs per audit) — only if a recurring cadence is planned.
- Standalone `docs/design_system.md` — rejected for the `ui.ex` moduledoc SSOT.
- Release `0.1.1` publish via release-please — tracked in PROJECT.md Release Queue.
- No todo matches were found for Phase 17.
