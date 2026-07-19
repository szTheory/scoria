# Phase 54: Docs Accuracy + Conformance Check - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 54-docs-accuracy-conformance-check
**Areas discussed:** Conformance check surface, Conformance corpus, Claim placement + version pin, Claim wording + banned-list surgery
**Method:** User elected the research + red-team path (not interactive Q&A): two parallel `gsd-advisor-researcher` subagents (one per decision cluster) mined the OpenInference/OTel/Elixir ecosystem, lessons from other libs, and the `prompts/` DNA/vision docs; the orchestrator then red-teamed the findings against live codebase ground truth and reconciled them into one coherent locked set.

---

## Conformance check — surface (DOCS-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Plain ExUnit test (`@tag :conformance`) | Runs in the normal suite; matches the repo's execute-the-SSOT drift-guard idiom; zero contract cost | ✓ |
| Dedicated Mix task / verification lane | Adopter/CI-runnable named command; but edits the byte-stable `closeout_order/0` + two contract tests + CI YAML for near-zero marginal value | |
| Both (thin lane wraps ExUnit) | Best of both; pure ceremony here | |

**User's choice:** Plain ExUnit test (D-01/D-02); register in the `test.adoption` file list for lane visibility without contract cost (D-03).
**Notes:** A maintainer/CI drift guard is not an adopter-run proof lane; forcing it into the closeout chain is off-idiom. Lessons: OTel Weaver `live-check`, opentelemetry-erlang, Ecto, Oban all ship conformance as ordinary tests, not bespoke tasks.

---

## Conformance check — corpus (DOCS-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Live-drive the adapters | Capture real emitted spans; only corpus that fails on real drift; reuses existing telemetry-capture harness | ✓ |
| Committed golden span fixture | Deterministic but rots — passes forever while real emission drifts (footgun) | |
| Seeded DB span set | Wrong layer for key/kind conformance; flake surface | |

**User's choice:** Live-drive all real adapters; derive the allow-list by calling `Semconv`/`SpanKind`/`Bounds` (never a re-listed set); assert on the post-Bounds record-of-truth layer; add exhaustiveness + negative self-test guards (D-04..D-07).
**Notes:** Red-team surfaced two ground-truth corrections. (1) There are **three** span-emitting adapters (req_llm, mcp, jido), not the ROADMAP's "two." (2) The `jido` adapter emits raw `jido.*` vendor keys that are stripped by `Bounds.enforce/2` before persistence — so asserting the post-Bounds record of truth (what the "compatible" claim actually describes) makes jido compliant-by-enforcement without expanding scope. Langfuse's over-broad usage allow-list bug is the canonical "check that can't fail" footgun — countered by deriving from the closed registry + narrow vendor-prefix list + a negative self-test.

---

## Docs claim — placement + version-pin (DOCS-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal (README + glossary + comparison only) | Smallest diff; but version-pin scattered, no canonical home | |
| Dedicated trace guide (`guides/capabilities/trace-observability.md`) | The milestone's anticipated "doc-delta"; one falsifiable home for the pin + export boundary; answers the adopter JTBD | ✓ |

**User's choice:** Dedicated guide (D-08); pin both anchors — OTel-GenAI semconv schema 1.37.0 via `req_llm ~> 1.13` + the OpenInference span-kind taxonomy — with an experimental-status honesty rider and an explicit "not an exporter" statement (D-09).
**Notes:** Attribute the pin to the dep so it ages with `req_llm`, not a hand-copied number. Lessons: Langfuse hedges on experimental status and describes *record/map*, never "export"; Arize Phoenix anchors credibility on naming the exact attribute + taxonomy.

---

## Docs claim — wording + banned-list surgery (DOCS-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Additive only | Add the positive claim to `@comparison_safe_current_claims`; keep every export ban + the deferred disclaimer | ✓ |
| Rewrite the bans | Move/relax export bans, add a "compatible" guard — triggers the self-blocking trap | |

**User's choice:** Purely additive (D-10/D-11). Guard-locked substring `OpenInference-compatible convention keys`; one canonical full sentence reused across all surfaces; keep all three export bans and the export-deferral disclaimer (export genuinely still not a claim).
**Notes:** The ROADMAP's premise that the lists "block that exact phrase" is slightly off — they block `...export`, not the convention claim (they share no substring). The trap: never add bare `"OpenInference-compatible"` to a forbidden list — it would `refute`-match the new claim. Reconciliation: Success Criterion 1's "old 'not a current claim' string replaced" = the glossary softener (replaced), not the contract export-deferral disclaimer (retained — still true).

---

## Claude's Discretion

- Test module layout, helper names, adapter input sampling (guided by D-04..D-07).
- Prose in the new trace guide beyond the locked D-10 sentence.
- Whether the emit-layer extra-bite assertion in D-07 is worth the complexity (researcher to recommend).

## Deferred Ideas

- Registering `jido.*` as first-class convention keys / strict emit-layer conformance for jido (overlaps Phase 54.1; not needed given D-07).
- A `mix scoria.conformance` adopter-facing proof task / verification lane (only if later demanded).
- Actually wiring OTel export (host → Langfuse/Datadog/Arize) — out of scope per locked doctrine; documented as host-owned + opt-in only.
