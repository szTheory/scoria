# Phase 55: Content Trust & Taint Substrate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 55-content-trust-taint-substrate
**Areas discussed:** A (trust vocabulary), B (tool-output envelope), C (spotlighting seam), D (scan/2 hook)
**Method:** User selected all four gray areas + the "Research + red-team, synthesize" method — four parallel `gsd-advisor-researcher` passes (one per requirement), each applying software-architecture / library-API / Elixir-idiom / DX / security / backward-compat lenses and mining `prompts/` research + peer libs (Rebuff, LlamaGuard, MSRC spotlighting, MCP, LangChain, Perl/Ruby taint), synthesized and reconciled, then subjected to one adversarial red-team pass on the reconciled spec.

---

## Area A — Trust-tier vocabulary & where the default is stamped (TAINT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Binary `trusted`/`untrusted` | Exactly the axis the Phase 57 gate reads; zero collapse logic; scope-doctrine-clean | ✓ |
| 3-tier `trusted`/`caution`/`untrusted` | Richer, but a middle tier is a graded content opinion (host-owned) + forces a gate collapse rule | |
| Free provenance labels | Descriptive but undecidable; unbounded cardinality; every reader re-derives trust | |
| Origin: Source-provenance inherited by chunks | vs per-chunk-only | ✓ (Source, persisted, denormalized to chunks) |
| Stamped at ingest (denormalized) | vs at-retrieval (Source join, hot-path cost, old rows blank) | ✓ (at ingest) |

**Choice:** Binary enum in a leaf `Scoria.Trust` module; fail-closed reader (absent/junk ⇒ untrusted); trust persisted on `Source.metadata`, denormalized onto `Chunk.metadata` at ingest; host overrides via `trust:` opt + `set_source_trust/3`.
**Notes:** Red-team fix — Source must *store* the canonical tier or `reembed`/`reindex` silently revert host-declared trust to untrusted. Convention over jsonb; no new column/SpanKind (v3.6 precedent).

---

## Area B — Tool-output envelope shape & backward-compat (TAINT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Struct `Scoria.MCP.Envelope` in `{:ok, _}` | Pattern-matchable, `@enforce_keys`, no map-introspection collision | ✓ |
| Plain map | Collides with executor `actual_units` map-introspection; open shape | |
| Tagged tuple | Positional fields don't scale; breaks `{:ok, _}` matches | |
| Side-channel only | Value stays naked/ignorable — undercuts TAINT-02 intent | |
| Wrap at Executor, always-persist, soft-launch return shape | vs opt-in-per-tool (fail-open by omission) | ✓ |

**Choice:** Struct wrapped at the single Executor success choke point (after budget/telemetry read the raw result); taint always computed + persisted + traced; return-shape change behind a default-off `wrap_tool_output` flag; total accessors are the forward-compatible read path.
**Notes:** Red-team fixes — (1) envelope the replay historical-stub under the flag or live/replay diverge; (2) add an `actual_units(_, %Envelope{}, _)` head; (3) the flag honors "never brick 0.1.3 adopters" (ReleaseGate precedent).

---

## Area C — Spotlighting seam location & technique (TAINT-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone host-called `Scoria.Spotlight.render/2` | Idiomatic for a lib that owns no prompt string; ~1-line adoption | ✓ |
| Assembly helper on `Orchestrator` | Forces host to hand Scoria its instructions → owns prompt structure (scope leak) | |
| Fold into tainted-struct rendering only | Doesn't cover host self-concatenation; not an assembly ergonomic | |
| Technique: datamark (prose) / delimit (structured) / ambiguous→delimit | vs encode (not model-agnostic) | ✓ |

**Choice:** `Scoria.Spotlight.render/2` returns marked text + the paired instruction as data; content-shape-aware technique biased to non-destructive `:delimit` for ambiguous/structured, `:datamark` for prose; per-call ≥128-bit nonce verified-absent from the span; instruction template host-overridable.
**Notes:** Premise correction — `Orchestrator` is only an LLM-fallback wrapper; there is no in-lib chunks→prompt assembly, so the seam is host-called. Documented residual (D-15): a host reading `chunk.body` raw bypasses it — mitigated by docs + Phase 58 `SECURITY-BOUNDARY.md`.

---

## Area D — `scan/2` hook contract & trace tagging (TAINT-04)

| Option | Description | Selected |
|--------|-------------|----------|
| `Scoria.Trust.Scanner` behaviour + `Verdict` struct + `NoOp` default | vs bare atom / free map (leak-prone) | ✓ |
| Registration: `Application.get_env(:scoria, :content_scanner, NoOp)` + context override | Mirrors `req_llm_module` | ✓ |
| Invocation: at retrieve + envelope minting sites (NOT only `Spotlight.render`) | Anchoring only in render makes the seam decorative for self-prompting hosts | ✓ |
| Trace tag: `scoria.trust.*` projector on existing spans | vs reuse `Guardrail.emit/1` (wrong axis — classification ≠ decision) | ✓ |

**Choice:** BYO behaviour + `Verdict{tier, score(host-only), reason_code, scanner}`; NoOp default = unchanged behavior; scan batch-fires at `Knowledge.retrieve/2` + `MCP.Executor` envelope creation; monotonic taint law (`most_restrictive`, property-tested — never launder untrusted→trusted); fail-closed error isolation (scanner error/timeout ⇒ untrusted + reason_code, run never crashes); fixed `scoria.trust.*` projector (no `score` key) on the existing RETRIEVER/tool span.
**Notes:** Sharpest red-team fix — scan anchored to taint-minting chokepoints, not `render`, or the whole scanner seam is decorative. Cross-phase constraint recorded (D-22): Phase 57 must branch on `reason_code` + an infra-fail disposition so a slow/misconfigured scanner doesn't escalate 100% of runs.

---

## Claude's Discretion

- Private helper/field names beyond the named public API; test-file layout; instruction-template shape (module attr vs function), provided it stays host-overridable.
- **No UI in this phase** — the only observable surface is trace attributes, rendered by the Phase 58 Govern surface. UI/UX, accessibility, brand, and creative-direction lenses are N/A here.

## Deferred Ideas

- Phase 56 tool-declared per-tool tier (feeds the envelope default); Phase 57 confluence gate (reads this substrate + the D-22 constraint); Phase 58 Govern surface + eval-seam moderation/output hooks + `SECURITY-BOUNDARY.md`.
- Non-blocking defense-in-depth: Credo/telemetry nudge for raw `chunk.body` bypass; changeset-side trust normalization.
- Permanently host-owned (scope doctrine): injection/moderation detector, per-user allowlists, output sanitizer.
