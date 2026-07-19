# Phase 54: Docs Accuracy + Conformance Check - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 8 (1 new test, 1 new guide, 2 doc-contract modules, 4 doc-surface edits treated as one bundle)
**Analogs found:** 8 / 8 (all files have a strong analog; no "no analog" bucket needed)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog(s) | Match Quality |
|---|---|---|---|---|
| `test/scoria/observe/conformance_test.exs` (new) | test | event-driven + transform (telemetry capture → in-test pipeline replay → assertion) | `test/scoria/observe/adapters/req_llm_test.exs` (emit-layer capture) + `test/scoria/observe/semconv_test.exs` / `test/scoria/observe/span_kind_test.exs` (execute-the-SSOT/exhaustiveness/guard-must-bite idiom) | exact (composite of two idioms, both live in this repo) |
| `lib/scoria/adopter_doc_contract.ex` (modify: add 1 string to `@comparison_safe_current_claims`) | config (module-attribute SSOT list) | CRUD (list append) | itself — existing `@comparison_safe_current_claims` / `@comparison_forbidden_current_claims` / `@comparison_deferred_not_current_claims` lists | exact (edit-in-place, no new file) |
| `lib/scoria/ai_doc_contract.ex` (modify: add 1 string to `@required_llms_paths`) | config (module-attribute SSOT list) | CRUD (list append) | itself — existing `@required_llms_paths` / `@forbidden_ai_doc_fragments` lists | exact |
| `guides/capabilities/trace-observability.md` (new) | doc/config (static guide) | transform (Markdown authoring) | `guides/capabilities/support-copilot-gallery.md` (structural analog: heading shape, cross-link style, advisory-vs-merge-blocking framing) | role-match (closest sibling under `guides/capabilities/`) |
| `guides/reference/glossary.md` (modify ~L31, ~L36) | doc | transform | itself (in-place edit; no cross-file analog needed) | exact |
| `guides/scoria-vs-external-llm-ops.md` (modify: add sentence to "What Scoria currently owns") | doc | transform | itself (in-place edit) | exact |
| `README.md`, `llms.txt`, `AGENTS.md` (modify: register new guide / add sentence) | doc/config | transform | `llms.txt`'s existing "Capability Guides" list block (`llms.txt:33-39`) as the insertion-point analog | role-match |
| `test/scoria/adoption_surface_test.exs`, `test/scoria/ai_doc_contract_test.exs` (no new assertions needed — auto-covered) | test | CRUD (list-membership loop) | itself — existing `for current_claim <- AdopterDocContract.comparison_safe_current_claims() do ... end` loop | exact (zero-edit; confirm no new assertion required) |

## Pattern Assignments

### `test/scoria/observe/conformance_test.exs` (new test, event-driven/transform)

**Primary analog A — emit-layer capture harness:** `test/scoria/observe/adapters/req_llm_test.exs`

**Module + setup pattern** (lines 1-22):
```elixir
defmodule Scoria.Observe.Adapters.ReqLLMTest do
  use ExUnit.Case, async: false

  setup do
    :telemetry.detach("scoria-observe-telemetry-test-req")
    :telemetry.detach("scoria-observe-reqllm")

    parent = self()

    :telemetry.attach(
      "scoria-observe-telemetry-test-req",
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, metadata, _config ->
        send(parent, {:span, metadata})
      end,
      nil
    )

    Scoria.Observe.Adapters.ReqLLM.attach()
    :ok
  end
```
Adapt: use a distinct handler id (e.g. `"scoria-observe-telemetry-test-conformance"`) per RESEARCH.md Pitfall 1 — do NOT reuse `"scoria-observe-telemetry-test-req"` or any production id (`"scoria-observe-reqllm"`, `"scoria-observe-mcp"`, `"scoria-observe-jido"`, `"scoria-observe-telemetry"`). Since the conformance test needs no shared Buffer/DB state, it can be `async: true` (RESEARCH's recommendation), unlike this analog's `async: false`.

**Capture helper pattern** (lines 52-56):
```elixir
defp capture_span(metadata) do
  :telemetry.execute([:req_llm, :request, :stop], %{}, metadata)
  assert_receive {:span, span}
  span
end
```
Adapt per-adapter: req_llm fires `[:req_llm, :request, :stop]`; MCP fires `[:scoria, :tool, :completed | :timeout | :failed]` (never `:started` — RESEARCH Pitfall 2); Jido fires `[:jido, :action, :stop]`.

**In-test post-Bounds replay** (new composition, not lifted verbatim from any single file — production order confirmed at `lib/scoria/observe/telemetry.ex:66-79`):
```elixir
# Source: this repo, telemetry.ex:66-79 (production order) + req_llm_test.exs capture idiom
defp record_of_truth(event, metadata) do
  raw = capture_span(event, metadata)
  {:ok, bounded} =
    raw
    |> Scoria.Observe.Redactor.redact()
    |> Scoria.Observe.Bounds.enforce(:span)

  bounded
end
```

**Primary analog B — execute-the-SSOT / exhaustiveness / guard-must-bite idiom:** `test/scoria/observe/span_kind_test.exs`

**Canary + exhaustiveness pattern** (lines 94-106):
```elixir
test "CANARY: kinds/0 is exactly the pinned 8-value list (forces review of CSS + OI map on any change)" do
  assert SpanKind.kinds() == ~w(agent llm prompt tool mcp retriever guardrail eval)
end

test "EXHAUSTIVENESS: every kind is kind?/1-true and has a non-raising to_openinference/1 clause" do
  for kind <- SpanKind.kinds() do
    assert SpanKind.kind?(kind)

    oi = SpanKind.to_openinference(kind)
    assert is_binary(oi)
    assert oi == String.upcase(oi)
  end
end
```
Adapt for D-06: exhaustiveness scoped to the 3 adapter-reachable kinds (`llm`/`mcp`/`tool`), per RESEARCH's correction — NOT all 8 `SpanKind.kinds()` values (5 are unreachable from req_llm/mcp/jido without driving unrelated runtime code).

**Guard-must-bite (negative self-test) pattern** (lines 132-148):
```elixir
test "FALLBACK OBSERVABILITY: normalize/1 on an unrecognized value emits the fallback telemetry event and returns the default \"agent\"" do
  :telemetry.attach(
    "span-kind-drift-guard-fallback",
    [:scoria, :observe, :span_kind, :fallback],
    fn event, measurements, metadata, _config ->
      send(self(), {:drift_guard_telemetry_event, event, measurements, metadata})
    end,
    nil
  )

  on_exit(fn -> :telemetry.detach("span-kind-drift-guard-fallback") end)

  assert SpanKind.normalize("bogus") == "agent"

  assert_receive {:drift_guard_telemetry_event, [:scoria, :observe, :span_kind, :fallback],
                   %{}, %{value: "bogus", default: "agent"}}
end
```
Adapt for D-06's "guard must bite": feed a deliberately bogus key/kind through the SAME `Bounds.enforce/2`/`SpanKind.kind?/1` calls used elsewhere in the file and assert the guard visibly bites (key absent post-enforce; `SpanKind.kind?/1` false) — do not just assert "doesn't crash."

**Registry canary pattern (anti-hand-copy idiom):** `test/scoria/observe/semconv_test.exs` lines 274-306 — `attribute_registry/0` returns an exact pinned sorted key list; "adding a key requires a deliberate edit here." The conformance test must call `Semconv`/`Bounds`/`SpanKind` functions directly (never hand-copy their return values) — this is the "ANTI-INLINE GUARD" discipline also visible at `span_kind_test.exs:123-130`.

**Anti-pattern warning (do not reconstruct):** Do NOT hand-reconstruct the admission rule from `Semconv.attribute_registry/0` / `vendor_key_prefixes/0` / `denied_key_segments/0` / `denied_exact_keys/0`. Call `Bounds.enforce/2` directly — it is the public SSOT (`bounds.ex:137`), and it is stronger anti-drift than reconstructing the predicate.

**Second capture idiom, NOT the primary analog (context only):** `test/scoria/observe/adapters/mcp_test.exs` (lines 30-57, 82-96) drives the real DB-backed Buffer + `Repo.get_by!/2` read-back — this is a *different, heavier* idiom (Sandbox + `async: false`) proving the same "post-Bounds record of truth" layer via a different mechanism. Do NOT lift this for the new test; the in-test `Redactor.redact/1 |> Bounds.enforce/2` replay (Primary analog A + the composition above) reaches the identical layer without DB/Sandbox ceremony, per RESEARCH's explicit recommendation.

---

### `lib/scoria/adopter_doc_contract.ex` (config, list-append)

**Analog:** itself — current list shapes (verbatim, `adopter_doc_contract.ex:59-106`):
```elixir
@comparison_safe_current_claims [
  "runs inside your Phoenix app",
  "host Postgres/Ecto boundary",
  "embedded LiveView reviewer dashboard at `/scoria`",
  "host app owns identity, authorization, role values, and business truth",
  "durable runs",
  "reviewer-visible traces",
  "approvals",
  "fail-closed eval posture",
  "tenant-scoped knowledge retrieval",
  "upgrade-safe verification suites",
  "no separate Scoria-hosted control plane",
  "no required egress for Scoria governance records"
]

@comparison_deferred_not_current_claims [
  "OpenInference export is not a current Scoria claim",     # KEEP
  "Rule-of-Two/lethal-trifecta enforcement is not a current Scoria claim",
  "deeper scorer calibration is not a current Scoria claim",
  "richer retrieval evals are not current Scoria claims",
  "retention, masking, purge, and feedback governance are not current Scoria claims",
  "persistent AI feature grouping is not a current Scoria claim"
]

@comparison_forbidden_current_claims [
  "OpenInference export",                                   # KEEP
  "OpenInference-compatible export",                         # KEEP
  "Rule-of-Two", "lethal-trifecta enforcement", "mature scorer calibration",
  "regression depth", "deep retrieval eval", "faithfulness metrics",
  "retention governance", "masking governance", "purge governance",
  "feedback governance", "persistent AI feature grouping"
]
```

**Edit:** append `"OpenInference-compatible convention keys"` to `@comparison_safe_current_claims`. Do NOT touch the other two lists. **TRAP:** never add bare `"OpenInference-compatible"` to `@comparison_forbidden_current_claims` — it would substring-match and `refute`-fail against the very claim being added.

**Auto-covering test (zero edit needed):** `test/scoria/adoption_surface_test.exs:253-256`:
```elixir
for current_claim <- AdopterDocContract.comparison_safe_current_claims() do
  assert current_section =~ current_claim
end
```

---

### `lib/scoria/ai_doc_contract.ex` (config, list-append)

**Analog:** itself — current list shapes (verbatim, `ai_doc_contract.ex:17-91`):
```elixir
@forbidden_ai_doc_fragments [
  ".planning/", "prompts/", "priv/dev/", "Scoria AI",
  "autonomous agent platform", "OpenInference export",       # KEEP
  "lethal-trifecta", "Rule-of-Two", "Keystone", "v2.0 Relay", "The Four Lanes"
]

@required_llms_paths [                                    # 32 entries currently
  "README.md", "guides/getting-started.md", "guides/golden-path.md",
  "guides/jtbd-and-user-flows.md", "guides/ownership-boundary.md",
  "guides/capabilities/default-runtime.md", "guides/capabilities/bounded-handoffs.md",
  "guides/capabilities/semantic-cache.md", "guides/capabilities/connectors-and-mcp.md",
  "guides/capabilities/support-copilot-gallery.md", "guides/reviewer-verification.md",
  "guides/troubleshooting.md", "guides/scoria-vs-external-llm-ops.md",
  "guides/cheatsheet.cheatmd", "guides/reference/glossary.md", "guides/maintainers.md",
  ... (17 more lib/test entries)
]
```

**Edit:** append `"guides/capabilities/trace-observability.md"` as a 33rd entry to `@required_llms_paths`. Do NOT touch `@forbidden_ai_doc_fragments`.

**Load-bearing downstream requirement:** `test/scoria/ai_doc_contract_test.exs:107-127` ("root llms.txt exposes the required public source map") iterates the LIVE `required_llms_paths()` and asserts `content =~ path` for every one — so `llms.txt` MUST literally contain the string `"guides/capabilities/trace-observability.md"` or this test goes RED. This is the concrete blast-radius item; it is not optional cleanup.

---

### `guides/capabilities/trace-observability.md` (new guide, doc/transform)

**Analog:** `guides/capabilities/support-copilot-gallery.md` (structural sibling under `guides/capabilities/`)

**Heading + framing pattern** (lines 1-7):
```markdown
# Support Copilot Gallery

The support-copilot gallery is repository-local example material that demonstrates Scoria in a realistic B2B support domain. It is not a hosted product surface, SaaS demo, or Hex package feature.

Use this guide with [Connectors and MCP](guides/capabilities/connectors-and-mcp.md), [Default Runtime](guides/capabilities/default-runtime.md), and the [glossary](guides/reference/glossary.md).

The gallery is the human-clickable companion to the merge-blocking generated-host adoption proof. Adopters evaluating from Hex should run `$ mix test.adoption` in their own host app. Clone the repository when you want the full interactive gallery.
```
Adapt: title `# Trace Observability`, cross-link to `guides/reference/glossary.md` and `guides/scoria-vs-external-llm-ops.md`, and open with the exact D-10 locked sentence:
> "Scoria records OpenTelemetry-GenAI / OpenInference-compatible convention keys (`gen_ai.*`, `server.*`, `openinference.span.kind`) in your host Postgres, pinned to OpenTelemetry GenAI semantic-conventions schema 1.37.0 (via `req_llm ~> 1.13`; these GenAI conventions are still experimental upstream). Scoria is not an OpenTelemetry exporter — sending these traces onward to Langfuse, Datadog, or Arize Phoenix is host-owned and opt-in."

Prose beyond the locked sentence (examples, an "export it yourself" snippet) is writer's discretion per CONTEXT.md — must not overclaim.

---

### `guides/reference/glossary.md` (modify ~L31, ~L36)

**Current text (verbatim, in-place edit target):**
```
Line 31: - Industry equivalent: trace or span tree in OpenTelemetry/OpenInference-style observability.
Line 36: Trace vocabulary aligns with OpenTelemetry/OpenInference-style observability language, but Scoria does not claim an OpenInference-compatible export or trace substrate until that future work ships.
```
**Edit:** L31 drop the "-style" softener. L36 REPLACE the softener sentence with the D-10 locked sentence + a link to the new trace guide.

---

### `guides/scoria-vs-external-llm-ops.md` (modify: add sentence)

**Current section boundary (verbatim):** `## What Scoria currently owns` (lines 20-32) currently has NO OpenInference mention — this is a pure ADDITION, not a find/replace. The existing `- OpenInference export is not a current Scoria claim...` line (L77) lives under the separate `## Not current Scoria claims` heading (L73) and stays untouched (export remains deferred).

---

### `llms.txt` / `README.md` / `AGENTS.md` (modify: register + add sentence)

**Analog:** `llms.txt`'s existing "Capability Guides" list block (lines 33-39) — currently exactly 5 entries (`default-runtime`, `bounded-handoffs`, `semantic-cache`, `connectors-and-mcp`, `support-copilot-gallery`). Add `trace-observability.md` as a 6th entry, same list-item shape. `README.md` and `AGENTS.md` have zero existing `OpenInference` mentions — pure additions of the D-10 sentence, no find/replace anchor.

## Shared Patterns

### Execute-the-SSOT + exhaustiveness + guard-must-bite (drift-guard discipline)
**Source:** `test/scoria/observe/semconv_test.exs`, `test/scoria/observe/span_kind_test.exs`
**Apply to:** `test/scoria/observe/conformance_test.exs` (the entire file's structure)
- Never hand-copy a whitelist's values into a test — call the real function (`Bounds.enforce/2`, `SpanKind.kind?/1`, `Semconv.attribute_registry/0`) and iterate its real return.
- Pair every positive assertion with a negative "guard must bite" self-test (deliberately bogus key/kind must visibly fail the check, not merely not-crash).
- Anti-pattern flagged in both analogs: an inline `~w(...)` whitelist literal reappearing in test or production code ("ANTI-INLINE GUARD", `span_kind_test.exs:123-130`).

### Doc-contract list-membership auto-coverage
**Source:** `test/scoria/adoption_surface_test.exs:253-256` (`comparison_safe_current_claims` loop), `test/scoria/ai_doc_contract_test.exs:107-127` (`required_llms_paths` × `llms.txt` content loop)
**Apply to:** both `adopter_doc_contract.ex` and `ai_doc_contract.ex` edits
- Appending a string to `@comparison_safe_current_claims` or `@required_llms_paths` is auto-covered by existing `for`-loops — no new test code needed.
- EXCEPTION: `ai_doc_contract_test.exs`'s `llms.txt` content loop makes the `llms.txt` edit load-bearing, not optional — the new guide's path string must literally appear in `llms.txt`'s body or that test goes RED.

### Post-Bounds "record of truth" pipeline (production order, do not reimplement)
**Source:** `lib/scoria/observe/telemetry.ex:66-79`
```elixir
def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  redacted = redact(metadata)                      # Redactor.redact/1

  case Bounds.enforce(redacted, :span) do
    {:ok, bounded} ->
      ReviewerBroadcast.span_stopped(bounded)
      Buffer.cast_span(buffer_span(bounded), buffer_name)

    :drop ->
      :ok
  end
end
```
**Apply to:** the new conformance test's `record_of_truth/2` helper — call `Redactor.redact/1` then `Bounds.enforce/2` in this exact order, both public functions, no DB/Sandbox/Buffer needed.

## No Analog Found

None — every file in scope has a strong in-repo analog (see table above). Doc-surface single-sentence additions (README.md, AGENTS.md) have no direct cross-file analog because they currently contain zero `OpenInference` mentions, but the edit itself is a trivial addition of the D-10 locked sentence, not a pattern requiring an analog.

## Metadata

**Analog search scope:** `test/scoria/observe/`, `test/scoria/observe/adapters/`, `lib/scoria/observe/`, `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/ai_doc_contract.ex`, `test/scoria/adoption_surface_test.exs`, `test/scoria/ai_doc_contract_test.exs`, `guides/capabilities/`, `guides/reference/glossary.md`, `guides/scoria-vs-external-llm-ops.md`, `llms.txt`, `README.md`, `AGENTS.md`
**Files scanned:** 12 read directly (via CONTEXT.md/RESEARCH.md citations + 4 targeted Reads this pass: `req_llm_test.exs`, `span_kind_test.exs`, `semconv_test.exs`, `support-copilot-gallery.md`)
**Pattern extraction date:** 2026-07-18
