# Phase 54: Docs Accuracy + Conformance Check - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the adopter-facing **"OpenInference-compatible"** claim both (a) *allowed* by
Scoria's own doc-contract guards and (b) *backed* by a falsifiable executable
conformance check that would fail if the claim stopped being true.

This is **docs + one test**. No runtime, adapter, schema, or migration changes.
The convention itself already shipped in Phases 51–53B (`Semconv`, `SpanKind`,
adapters emit `gen_ai.*` / `openinference.span.kind`). Phase 54 only makes the
*claim* honest and *proves* it.

Two requirements:
- **DOCS-01** — flip the claim from the v3.5-softened "OpenInference-style" to an
  honest, version-pinned "OpenInference-compatible", updating the banned-phrase
  contract lists in the same change.
- **DOCS-02** — add a Mix-task-or-ExUnit conformance check asserting emitted spans
  use only allow-listed convention keys + a `span_kind` from the shared whitelist.

**Method note:** decisions below were produced by two parallel research subagents
(ecosystem idiom + lessons-from-other-libs across the OpenInference/OTel/Elixir
space, weighted to `prompts/sztheory-elixir-dna.md` and
`prompts/phoenix-ai-lib-deep-research.md`), then red-teamed and reconciled against
live codebase ground truth. The user asked for one coherent locked set, not
interactive Q&A.
</domain>

<decisions>
## Implementation Decisions

### Conformance check — surface (DOCS-02)
- **D-01:** The conformance check is a **plain `ExUnit.Case` test**, not a Mix task
  and not a new verification lane. File: `test/scoria/observe/conformance_test.exs`
  (`Scoria.Observe.ConformanceTest`), `@moduletag :conformance`. This matches the
  repo's established drift-guard idiom (execute the SSOT, assert exact shapes —
  cf. `semconv_test.exs`, `span_kind_test.exs`) and adds **zero** cost to the
  byte-stable `VerificationLanes.closeout_order/0` contract.
- **D-02:** **Do NOT touch `closeout_order/0`** or the CI policy/lane contracts
  (`verification_lanes_test.exs`, `ci_policy_contract_test.exs`). A pure
  maintainer/CI drift-guard is not an adopter-run proof lane; forcing it into the
  closeout chain is off-idiom and taxes a deliberately byte-stable contract.
- **D-03:** For lane visibility without contract cost, **register the new test file
  in the `test.adoption` file list** (`Mix.Tasks.Scoria.Test.Adoption`'s
  `@adoption_test_files`) — a one-line addition — rather than inventing a lane.
  Researcher: confirm this list exists and is the right hook; if not, the plain
  `mix test` suite membership is sufficient.

### Conformance check — corpus & allow-list (DOCS-02)
- **D-04:** **Drive the real adapters live** and capture emitted spans (via the
  `:telemetry.attach` → `assert_receive` harness already used in
  `req_llm_test.exs` / `mcp_test.exs`). Reject a committed golden-span fixture
  (fixture rot — passes forever while real emission drifts) and reject a seeded-DB
  corpus as the *primary* source (wrong layer for key/kind conformance, flake
  surface). Live emission is the only corpus that actually fails on real drift.
- **D-05:** **Derive the allow-list by CALLING the SSOT, never by re-listing keys.**
  Key predicate = the real `Scoria.Observe.Bounds` admission rule expressed from
  `Semconv.attribute_registry/0` (exact) **OR** `Semconv.vendor_key_prefixes/0`
  prefix-match minus `Semconv.denied_key_segments/0` (split-on-`.`, exact-segment)
  minus `Semconv.denied_exact_keys/0`. Kind predicate = `span_kind ∈
  SpanKind.kinds()` and `attributes[Semconv.openinference_span_kind_key()]` equals
  the mapped `SpanKind.to_openinference/1` value. If `Bounds` exposes a public
  `admit?/1`-style predicate, **call it directly** so test and production share one
  rule. This is the anti-drift seam — the check structurally cannot diverge from
  the convention.
- **D-06:** **Guard against a vacuous pass.** Add (1) an exhaustiveness assertion —
  every `SpanKind.kinds()` value an adapter can emit is actually exercised, corpus
  non-empty per adapter; and (2) a **negative self-test** proving a deliberately
  bogus key/kind turns the check RED. Mirror the repo's pervasive "the guard must
  bite / a broken regex cannot vacuously pass" discipline. Failure messages MUST
  name the offending key/kind AND adapter.
- **D-07 (record-of-truth layer — the jido resolution):** The authoritative
  conformance layer is the **post-`Bounds.enforce/2` record of truth** (what
  actually persists to the host's Postgres via `Scoria.Observe.Telemetry`), because
  that is exactly what "OpenInference-compatible" describes to an adopter. The
  `jido` adapter deliberately emits raw `jido.action_name` / `jido.status` vendor
  keys at the `[:scoria, :observe, :span, :stop]` boundary that are **registry-only,
  unregistered**, and are *stripped by Bounds* before persistence. Asserting the
  record of truth makes jido compliant-by-enforcement — **no scope expansion to
  modify the jido adapter or add its keys to the registry.** To keep the record-layer
  assertion non-vacuous, pair it with the emit-layer `span_kind`/mirror strictness
  (fully falsifiable and jido already passes it) + D-06's negative self-test.
  *Researcher must confirm:* the exact capture point post-Bounds, that
  `Scoria.Observe.Telemetry` is the record boundary, and whether to additionally
  assert an emit-layer classification (every emitted key is either SSOT-admitted or
  a known Scoria-owned vendor namespace Bounds is expected to drop) for extra bite.

### Docs claim — placement & version-pin (DOCS-01)
- **D-08:** **Add a dedicated canonical home:** `guides/capabilities/trace-observability.md`
  (the milestone's anticipated "trace doc-delta"). It is the single falsifiable place
  the version-pin lives and the right JTBD moment to answer "can I ship these traces
  to my own Langfuse/Datadog/Arize?". The one canonical sentence (D-10) also lands in
  README (observability/concepts), `guides/reference/glossary.md`, and the comparison
  guide's "What Scoria currently owns" section; CHANGELOG already carries the noun
  phrase. Adding this guide means registering it in `AiDocContract.@required_llms_paths`
  (+ its test), `llms.txt`, and `AGENTS.md` — a known, bounded blast radius.
- **D-09:** **Version-pin BOTH anchors, attributed to the dep so it ages gracefully:**
  `gen_ai.*` / `server.*` → *"OpenTelemetry GenAI semantic-conventions schema 1.37.0"*
  (`https://opentelemetry.io/schemas/1.37.0`, exactly `req_llm ~> 1.13`'s
  `@otel_schema_url`); `openinference.span.kind` → *"the OpenInference span-kind
  taxonomy"* (named, no numeric version). Include the **honesty rider**: upstream
  OTel-GenAI conventions are still experimental/Development status — Scoria pins to
  the schema `req_llm` emits and tracks it forward. Explicitly state **Scoria is not
  an OpenTelemetry exporter** — sending traces onward is host-owned and opt-in.

### Docs claim — exact wording & banned-list surgery (DOCS-01)
- **D-10:** **Guard-locked canonical substring:** `OpenInference-compatible convention keys`.
  Canonical full sentence, reused verbatim across all surfaces (one voice, not five
  variants — reuses CHANGELOG:156's existing noun phrase):
  > *"Scoria records OpenTelemetry-GenAI / OpenInference-compatible convention keys
  > (`gen_ai.*`, `server.*`, `openinference.span.kind`) in your host Postgres, pinned
  > to OpenTelemetry GenAI semantic-conventions schema 1.37.0 (via `req_llm ~> 1.13`;
  > these GenAI conventions are still experimental upstream). Scoria is not an
  > OpenTelemetry exporter — sending these traces onward to Langfuse, Datadog, or
  > Arize Phoenix is host-owned and opt-in."*
- **D-11:** **The banned-list change is PURELY ADDITIVE — no export ban is removed.**
  The forbidden entries all contain the discriminator word `export`
  (`"OpenInference export"`, `"OpenInference-compatible export"`); the honest claim
  contains `convention keys`, not `export`, so it passes the substring `refute`
  guards untouched. Concrete edits:
  - `adopter_doc_contract.ex` `@comparison_safe_current_claims` → **ADD**
    `"OpenInference-compatible convention keys"` (flips it to *required-present*).
  - `adopter_doc_contract.ex` `@comparison_forbidden_current_claims` → **KEEP** (both
    export bans stay).
  - `adopter_doc_contract.ex` `@comparison_deferred_not_current_claims` → **KEEP**
    `"OpenInference export is not a current Scoria claim"` — export genuinely remains
    deferred per locked doctrine; the present-tense *convention* claim and the
    deferred *export* disclaimer coexist honestly.
  - `ai_doc_contract.ex` `@forbidden_ai_doc_fragments` → **KEEP** `"OpenInference export"`.
  - `ai_doc_contract.ex` `@required_llms_paths` → **ADD** `"guides/capabilities/trace-observability.md"`.
  - **TRAP (do not do):** never add bare `"OpenInference-compatible"` to a forbidden
    list — it would `refute`-match the very claim being added.
- **D-12:** **Glossary rewrite** (`guides/reference/glossary.md`): line ~31 drop the
  "-style" softener ("...OpenTelemetry/OpenInference observability."); line ~36
  **replace** the "does not claim an OpenInference-compatible export or trace
  substrate until that future work ships" softener with the D-10 sentence + a link to
  the new trace guide (the convention/substrate *shipped*; only export stays deferred).

### Claude's Discretion
- Exact test module layout, helper names, and how adapter inputs are sampled — planner/executor's call, guided by D-04..D-07.
- Prose beyond the D-10 locked sentence in the new trace guide (examples, an
  "export it yourself" snippet) — writer's discretion, must not overclaim.
- Whether the emit-layer extra-bite assertion in D-07 is worth the complexity — researcher to recommend.

### Reconciliation notes for planner / verifier (read before checking success criteria)
- **ROADMAP says "two adapters"; reality is THREE** span-emitting adapters:
  `req_llm`, `mcp`, **`jido`** (`lib/scoria/observe/adapters/`). This is a factual
  correction, not scope creep — the check covers *all span-emitting adapters*. Success
  Criterion 2's "the two adapters" should be read as "all span-emitting adapters
  (currently three)". jido's boot-wiring is Phase 54.1's concern; jido's *conformance*
  is handled here via D-07 (record-of-truth) without touching the adapter.
- **Success Criterion 1's "old 'not a current claim' string intentionally replaced"**:
  interpret as the *glossary/doc softener* (D-12, replaced), **not** the contract's
  export-deferral disclaimer, which stays true and is retained (D-11). Replacing the
  export disclaimer would be dishonest — Scoria still does not export. DOCS-01's intent
  ("banned lists updated in the same change") is satisfied by the additive
  `@comparison_safe_current_claims` + `@required_llms_paths` edits, not by loosening any
  export ban.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Convention SSOT (the allow-list the check derives from)
- `lib/scoria/observe/semconv.ex` — `attribute_registry/0`, `vendor_key_prefixes/0`,
  `denied_key_segments/0`, `denied_exact_keys/0`, `openinference_span_kind_key/0`;
  moduledoc documents the OTel-GenAI **schema 1.37.0** pin and the "jido./scoria./
  openinference. are registry-only" rule.
- `lib/scoria/observe/span_kind.ex` — canonical 8-value whitelist + `to_openinference/1`.
- `lib/scoria/observe/bounds.ex` — `enforce/2`; the admission rule the check must mirror
  (ideally call directly). Confirm whether a public `admit?/1` predicate exists.

### Span emitters & record boundary
- `lib/scoria/observe/adapters/req_llm.ex`, `.../mcp.ex`, `.../jido.ex` — the three
  adapters emitting `[:scoria, :observe, :span, :stop]`; jido emits raw `jido.*` keys.
- `lib/scoria/observe.ex` + `lib/scoria/observe/telemetry.ex` — the "real boundary of
  record": redact → bounds → persist. The post-Bounds record-of-truth layer (D-07).

### Existing test idioms to match
- `test/scoria/observe/adapters/req_llm_test.exs`, `.../mcp_test.exs` — `:telemetry.attach`
  → `assert_receive` capture harness.
- `test/scoria/observe/semconv_test.exs`, `.../span_kind_test.exs` — execute-the-SSOT
  drift-guard + exhaustiveness idiom.

### Doc-contract guards (the banned/allowed lists)
- `lib/scoria/adopter_doc_contract.ex` — `@comparison_safe_current_claims` (ADD),
  `@comparison_forbidden_current_claims` (KEEP), `@comparison_deferred_not_current_claims` (KEEP).
- `lib/scoria/ai_doc_contract.ex` — `@forbidden_ai_doc_fragments` (KEEP),
  `@required_llms_paths` (ADD trace guide).
- `test/scoria/ai_doc_contract_test.exs`, `test/scoria/adoption_surface_test.exs` — the
  contract tests that pin these lists (the safe-claims loop auto-covers the new string).

### Do-NOT-touch (byte-stable contracts)
- `lib/scoria/verification_lanes.ex` `closeout_order/0` + `test/**/verification_lanes_test.exs`
  + `test/**/ci_policy_contract_test.exs` — the conformance test must NOT be wired here.

### Adopter surfaces the claim lands on
- `README.md`, `guides/reference/glossary.md` (~L31, L36), `guides/scoria-vs-external-llm-ops.md`
  (comparison guide, "What Scoria currently owns"), `llms.txt`, `AGENTS.md`,
  `CHANGELOG.md` (L156-157, already aligned). **New:** `guides/capabilities/trace-observability.md`.

### External / dependency anchors
- `deps/req_llm/lib/req_llm/open_telemetry.ex` — `@otel_schema_url` = OTel-GenAI schema 1.37.0 (the pin source).
- OpenInference spec — https://github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md
- OTel GenAI schema 1.37.0 — https://opentelemetry.io/schemas/1.37.0

### Voice / idiom research inputs
- `prompts/sztheory-elixir-dna.md`, `prompts/phoenix-ai-lib-deep-research.md`,
  `prompts/ai-architectural-patterns-deep-research.md`; `brandbook/brand-book.md`
  (tone — grounded, evidence-based claims; name the keys, not adjectives).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `:telemetry.attach` → `send(parent, {:span, metadata})` → `assert_receive` capture
  harness in `req_llm_test.exs` / `mcp_test.exs` — lift directly for the conformance corpus.
- `Semconv` + `SpanKind` + `Bounds` already expose every function the allow-list
  predicate needs — no new SSOT surface to build.
- The `@comparison_safe_current_claims` `for`-loop in `adoption_surface_test.exs`
  auto-covers any string added to that list — no new test assertion needed for D-11.

### Established Patterns
- Drift guards in this repo = plain ExUnit tests that *call the SSOT and assert exact
  shapes*, plus "the guard must bite" negative cases and non-empty/vacuity guards.
  Golden fixtures are alien to this codebase and should be avoided.
- `closeout_order/0` is byte-stable and contract-guarded; new lanes are expensive and
  reserved for adopter/reviewer-run proofs, not maintainer drift guards.
- Doc claims are enforced by ExUnit contract guards using substring `=~` / `refute` —
  so wording is load-bearing; `convention`/`keys` (allowed) vs `export` (blocked) is the
  discriminator that already holds.

### Integration Points
- The conformance test reads `Semconv`/`SpanKind`/`Bounds` and captures adapter output —
  no production code changes.
- DOCS-01 edits touch the two doc-contract modules + their tests + the adopter doc
  surfaces + one new guide registered in `@required_llms_paths` / `llms.txt` / `AGENTS.md`.
</code_context>

<specifics>
## Specific Ideas

- The claim is only *allowed* to flip because DOCS-02's conformance check now *proves*
  the adapters emit the pinned convention — the doc-contract string and the runtime
  conformance test are two ends of the same evidence chain (the brandbook's
  "grounded, evidence-based claims" posture).
- Honesty framing borrowed from Langfuse/Arize Phoenix: name the exact keys and the
  schema version, describe *record* (into your Postgres) separately from *send-onward*
  (export, opt-in, host-owned). Concrete keys read as honest; adjectives read as hype.
</specifics>

<deferred>
## Deferred Ideas

- **Registering `jido.*` as first-class convention keys / strict emit-layer conformance
  for jido** — would make the check maximally falsifiable at emit time but requires
  touching the jido adapter + `attribute_registry/0`, overlapping Phase 54.1 territory.
  Deferred: D-07's record-of-truth approach makes the current claim honest without it.
- **A `mix scoria.conformance` adopter-facing proof task / verification lane** — only if
  adopters later demand an interactively-runnable conformance command. Not now (D-01/D-02).
- **Actually wiring OTel export** (host → Langfuse/Datadog/Arize) — explicitly out of
  scope forever-until-a-future-seed per locked doctrine; the doc only documents that it's
  host-owned and opt-in.

None of the above blocks Phase 54.
</deferred>

---

*Phase: 54-docs-accuracy-conformance-check*
*Context gathered: 2026-07-18*
