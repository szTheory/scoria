---
phase: 54-docs-accuracy-conformance-check
reviewed: 2026-07-18T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - guides/capabilities/trace-observability.md
  - guides/reference/glossary.md
  - guides/scoria-vs-external-llm-ops.md
  - lib/mix/tasks/test.adoption.ex
  - lib/scoria/adopter_doc_contract.ex
  - lib/scoria/ai_doc_contract.ex
  - test/scoria/observe/conformance_test.exs
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 54: Code Review Report

**Reviewed:** 2026-07-18T00:00:00Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed the Phase 54 documentation-accuracy changes: the "OpenInference-compatible
convention keys" claim flip across three guides, the two additive doc-contract
allow-list entries, the new `test.adoption` registration, and the new falsifiable
conformance test.

Cross-checked all four concerns the orchestrator flagged:

1. **Doc-contract self-refutation traps — none found.** The new safe claim
   `"OpenInference-compatible convention keys"` (AdopterDocContract:72) lands inside
   the `## What Scoria currently owns` section, which is exactly the scope
   `adoption_surface_test.exs:246-261` checks safe/forbidden claims against
   (`section_between!`). It does not collide with any `@comparison_forbidden_current_claims`
   substring (`"OpenInference export"`, `"OpenInference-compatible export"` — neither is a
   substring of the new claim). The forbidden refute is scoped to the current-Scoria
   section only, so the pre-existing `"OpenInference export"` line in the deferred section
   (guide:83) does not trip it. Safe.
2. **AiDocContract additive path — satisfied, not broken.** Adding
   `guides/capabilities/trace-observability.md` to `@required_llms_paths` (AiDocContract:49)
   is backed by an actual reference in `llms.txt:40`, so `ai_doc_contract_test.exs:116-117`
   (`content =~ path`) passes. The file contains no `@forbidden_ai_doc_fragments` substring.
3. **Version/schema claims are accurate.** `req_llm ~> 1.13` matches `mix.exs:98`; the
   `1.37.0` schema pin matches `Semconv`'s moduledoc. The current-vs-deferred distinction
   (records convention keys now / export deferred) is internally consistent.
4. **The test's core falsifiers do bite** (OI-mirror survival, D-07 drop-classification,
   both negative self-tests). See I-03 for the one assertion that is inert.

The one substantive defect is a test-isolation regression (W-01): the new conformance
test is `async: true` while every sibling test that uses the same node-global telemetry
capture idiom is `async: false`. No BLOCKER-class correctness or security defects.

## Warnings

### WR-01: Conformance test is `async: true` despite node-global telemetry capture — cross-module contamination / flakiness

**File:** `test/scoria/observe/conformance_test.exs:18`
**Issue:**
The module attaches a node-global `:telemetry` handler on
`[:scoria, :observe, :span, :stop]` (lines 36-41) and drives node-global adapter handlers
(`scoria-observe-reqllm`, `scoria-observe-jido`, `scoria-observe-mcp`, all attached at
`Scoria.Application` boot). `:telemetry` handlers are process-global, not test-scoped:
this module's handler will receive **every** `span:stop` emitted anywhere on the node
during its run, and `assert_receive {:span, span}` (lines 66, 72) returns the first
matching mailbox message — which under `async: true` can be a span from a **concurrently
running** async test module. The moduledoc explicitly says it copies "the
`req_llm_test.exs` capture idiom", but that file — and every other test that uses this
same global-capture pattern — is `async: false` precisely to get isolation:

```
adapters/req_llm_test.exs:2   async: false
adapters/jido_test.exs:2      async: false
adapters/mcp_test.exs:21      async: false
observe/telemetry_test.exs:2  async: false
observe/bounds_test.exs:19    async: false
observe/span_test.exs:15      async: false
```

Concrete failure mode: a concurrent async module fires `[:req_llm, :request, :stop]` (or
any `span:stop`); the global reqllm adapter emits a `span:stop`; this module's handler
enqueues a foreign `{:span, ...}` into the test process mailbox; the next
`assert_receive` grabs the foreign span; `assert bounded.span_kind == "mcp"` (etc.) fails
intermittently. This produces flaky RED that erodes trust in a check whose entire purpose
is to be a reliable drift alarm. A secondary hazard: `Redactor.redact/1` and
`Bounds.enforce/2` both read mutable `Application.get_env` at call time, so a concurrent
async test mutating `:scoria, Scoria.Observe.Redactor` config would also perturb this
test's pipeline.

**Fix:** Match the established pattern for global-telemetry tests.

```elixir
use ExUnit.Case, async: false
```

## Info

### IN-01: Test is not isolated from the boot-attached production span pipeline; "No DB, no Sandbox" moduledoc is misleading

**File:** `test/scoria/observe/conformance_test.exs:9-11`
**Issue:**
`Scoria.Application` attaches the production `scoria-observe-telemetry` handler on
`[:scoria, :observe, :span, :stop]` at boot (`application.ex:59`,
`observe/telemetry.ex:11-18`). Because this test drives the real adapters, every captured
span **also** flows through that production handler
(`Redactor.redact |> Bounds.enforce |> Buffer.cast_span |> ReviewerBroadcast`) as a live
side effect. The moduledoc's "No DB, no Sandbox" is true only for the test's own
assertions; the production handler still runs and casts to `Buffer`. This is tolerated
today (the sibling `async: false` adapter tests fire the same events), but the moduledoc
implies an isolation that does not exist and is worth wording accurately, especially given
W-01.
**Fix:** Reword the moduledoc to "the test makes no DB/Sandbox assertions" rather than
implying the pipeline is inert, or explicitly detach `scoria-observe-telemetry` for the
duration of the test if true isolation is desired.

### IN-02: `trace-observability.md` lists `chain` as a span role — not a Scoria `SpanKind`

**File:** `guides/capabilities/trace-observability.md:24`
**Issue:**
The guide says the OpenInference span-kind key makes "the span's role (LLM call,
retriever, tool, chain, agent) legible". Scoria's actual taxonomy
(`SpanKind.kinds/0`) is `agent llm prompt tool mcp retriever guardrail eval` — there is
no `chain` kind, and Scoria never emits one. Meanwhile Scoria-specific kinds (`prompt`,
`mcp`, `guardrail`, `eval`) are omitted from the illustrative list. A reader could infer
Scoria emits `chain`-kind spans. Since the sentence is framed as OpenInference vocabulary
generally, this is minor, but the example set is inconsistent with what Scoria records.
**Fix:** Use a Scoria-emitted example set, e.g. "(LLM call, tool, MCP tool, retriever,
agent)", or explicitly caveat that the parenthetical lists OpenInference vocabulary, not
Scoria's emitted kinds.

### IN-03: `assert_conforms/2` per-key SSOT loop is inert under default config (no falsification power)

**File:** `test/scoria/observe/conformance_test.exs:151-161`
**Issue:**
The loop `for {key, _} <- bounded.attributes, do: assert ssot_admitted?(key)` can never
fail in the default configuration. `Bounds.enforce/2` only admits a key via
registry-exact, vendor-prefix, or host-prefix match (`bounds.ex:233-258`);
`ssot_admitted?/2` checks registry-exact OR vendor-prefix (`conformance_test.exs:158-161`).
The only surviving key that could fail `ssot_admitted?` is a host-prefix-admitted key, but
`allowed_key_prefixes` defaults to `[]` (`bounds.ex:115`), so that path is unreachable in
test. The moduledoc honestly labels this "belt-and-suspenders", so it is not a bug — but
it contributes zero drift-detection and could give a false sense of coverage. The real
falsifiers (OI-mirror equality at :147-149, the D-07 drop-classification at :303-319, and
the negative self-tests at :272-289) carry the actual bite.
**Fix:** Either drop the loop, or make it non-tautological by asserting against
`Semconv.attribute_registry()` membership plus an explicit exclusion of the boot-configured
host prefixes so a real host-prefix leak would be caught.

---

_Reviewed: 2026-07-18T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
