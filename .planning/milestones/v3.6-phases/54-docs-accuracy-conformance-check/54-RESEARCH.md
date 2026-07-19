# Phase 54: Docs Accuracy + Conformance Check - Research

**Researched:** 2026-07-18
**Domain:** Elixir/OTel-GenAI/OpenInference doc-contract + telemetry conformance testing
**Confidence:** HIGH (all findings below are read directly from live repo source; no external-package lookups were needed — this phase adds zero new dependencies)

## Summary

This phase requires no new libraries and no runtime changes — it is a pure "read the SSOT, confirm the exact seams" research task. All eight "researcher must confirm" items in 54-CONTEXT.md are now answered against live code, with file:line citations below. Two of CONTEXT's working assumptions turn out to be imprecise in ways that matter for planning (both flagged loudly in Corrections below); everything else the CONTEXT locked is confirmed exactly as written.

**Primary recommendation:** Capture the conformance corpus at the emit layer (`:telemetry.attach` on `[:scoria, :observe, :span, :stop]`, driving the real adapters — mirroring `req_llm_test.exs`'s idiom, not `mcp_test.exs`'s DB-backed idiom), then derive the post-Bounds "record of truth" **in-test** by calling the exact same two production functions `Scoria.Observe.Telemetry.handle_event/4` calls, in the same order: `Scoria.Observe.Redactor.redact/1` then `Scoria.Observe.Bounds.enforce/2`. Both are public functions. This is 100% faithful to production (same functions, same order, zero re-implementation of the admission rule) and needs no Postgres/Sandbox/async ceremony — a plain, fast, deterministic `ExUnit.Case, async: true`-eligible test.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Attribute-key admission (allow-list enforcement) | API/Backend (`Scoria.Observe.Bounds`) | — | Write-time choke point inside the host's own BEAM process; no DB or browser tier involved |
| Span-kind taxonomy + OpenInference mirroring | API/Backend (`Scoria.Observe.SpanKind`, `Semconv`) | — | Pure compile-time constant modules, no I/O |
| Conformance test itself | API/Backend (ExUnit test process) | — | Runs entirely in-process; optionally touches Postgres only if the DB-backed idiom is chosen (not recommended, see below) |
| Doc-contract guards (`AdopterDocContract`/`AiDocContract`) | API/Backend (compile-time module attributes) + Static docs | — | Module attributes are the SSOT; enforcement is via ExUnit tests reading `File.read!/1` on Markdown, a static-docs concern |
| New guide (`guides/capabilities/trace-observability.md`) | Static/Docs | — | Plain Markdown, no runtime surface |

This phase touches zero Browser/Client, CDN, or Database/Storage tier code — it is entirely Backend module + static-doc work, matching the CONTEXT's "docs + one test only" framing.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Flip the claim from "OpenInference-style" to version-pinned "OpenInference-compatible"; update banned-phrase contract lists in the same change | Exact current wording of every doc surface quoted below (glossary L31/L36, comparison guide L77, CHANGELOG L156-157, README/llms.txt/AGENTS.md gaps); exact `@comparison_safe_current_claims`/`@comparison_forbidden_current_claims`/`@comparison_deferred_not_current_claims`/`@forbidden_ai_doc_fragments`/`@required_llms_paths` contents quoted verbatim; confirmed additive-only edit path is substring-safe |
| DOCS-02 | Add a falsifiable ExUnit/Mix-task conformance check that emitted spans use only allow-listed keys + a `span_kind` from the shared whitelist | Confirmed `Bounds.enforce/2` (public) is the exact function to call for the post-Bounds record; confirmed the redact→bounds pipeline order in `Telemetry.handle_event/4`; confirmed adapter-reachable span_kind set (llm/mcp/tool, not all 8); confirmed `Mix.Tasks.Scoria.Test.Adoption.@adoption_test_files` hook; confirmed capture-harness idioms in `req_llm_test.exs`/`mcp_test.exs` |
</phase_requirements>

## Corrections to CONTEXT.md Assumptions (read this first)

### Correction 1 — `Bounds` exposes NO public `admit?/1`-style predicate (D-05)

`lib/scoria/observe/bounds.ex` exports exactly two public functions: `enforce/2` (`bounds.ex:137`) and `max_delta_chunk_bytes/0` (`bounds.ex:169`). Every classification helper is `defp`:
`classify_key/2` (`:233`), `vendor_admitted?/1` (`:242`), `denied_segment?/1` (`:250`), `host_admitted?/2` (`:256`).

D-05 anticipated this ("if `Bounds` exposes a public `admit?/1`-style predicate, call it directly... if not, the exact Semconv-derived predicate the test must reconstruct"). **The correct resolution is neither branch as literally written** — the test does NOT need to reconstruct the admission rule from `Semconv.attribute_registry/0`/`vendor_key_prefixes/0`/`denied_key_segments/0`/`denied_exact_keys/0` by hand. `enforce/2` **is** the public SSOT function; it already runs the exact three-tier admission `Bounds`'s moduledoc documents (registry exact match → vendor prefix minus denylist → host prefix), plus size/count/depth bounding. Call `Bounds.enforce(%{attributes: captured_attrs}, :span)` directly and inspect the surviving keys of the returned `{:ok, bounded_metadata}` map's `:attributes`. This is *stronger* anti-drift than reconstructing the rule from the four `Semconv` functions, because it also proves the byte/count/depth bounding path didn't unexpectedly evict a conformance-relevant key — reconstructing the predicate manually would only prove key-admission, not the full enforcement contract.

### Correction 2 — D-04's citation conflates two different capture idioms; only one is "the assert_receive harness"

D-04 says: *"drive the real adapters live and capture emitted spans (via the `:telemetry.attach` → `assert_receive` harness already used in `req_llm_test.exs` / `mcp_test.exs`)."* Reading both files line-by-line:

- **`test/scoria/observe/adapters/req_llm_test.exs`** (lines 11-22, 52-56): literally attaches to `[:scoria, :observe, :span, :stop]`, sends `{:span, metadata}` to the test process, and `assert_receive {:span, span}`. This captures the **pre-Bounds, pre-Redactor emit-layer** span — the raw metadata the adapter builds, before `Scoria.Observe.Telemetry.handle_event/4` ever runs.
- **`test/scoria/observe/adapters/mcp_test.exs`** (lines 30-57, 82-96): does **NOT** use `:telemetry.attach` + `assert_receive` at all for span capture. It starts a real scoped `Buffer` GenServer, detaches/reattaches the real `Scoria.Observe.Telemetry` handler onto it, fires the real upstream event (`[:scoria, :tool, :completed]`), calls `Buffer.flush_now/1`, and then reads the **persisted Postgres row** via `Repo.get_by!(Span, trace_id: ...)`. This is the actual **post-Bounds record of truth** (D-07's target) — but it requires `Ecto.Adapters.SQL.Sandbox`, a real supervised `Buffer`, and `async: false`.

These are two different idioms proving two different layers. The planner should pick ONE per D-07's stated target (post-Bounds record of truth) — see Primary recommendation above: lift `req_llm_test.exs`'s lightweight attach idiom for the emit-layer capture, then call `Redactor.redact/1` + `Bounds.enforce/2` in-test to reach the post-Bounds layer without needing `mcp_test.exs`'s DB/Sandbox/`async: false` machinery. This keeps the new `conformance_test.exs` fast and `async: true`-eligible (no shared Buffer state, no Postgres), which better matches D-01's "plain ExUnit.Case, adds zero cost" framing than duplicating `mcp_test.exs`'s DB-backed setup would.

## Confirmed Seams (per CONTEXT.md's Focus/Confirm list)

### 1. D-05 — Bounds admission predicate

**Answer:** No public `admit?/1`. Call `Bounds.enforce/2` directly (see Correction 1). Exact signature:

```elixir
# lib/scoria/observe/bounds.ex:137
@spec enforce(term(), :span | :event) :: {:ok, map()} | :drop
def enforce(metadata, kind) when kind in [:span, :event] do
```

It expects `metadata` to be a map with an optional `:attributes` sub-map (`bounds.ex:144-158`) — every other top-level key (`:id`, `:trace_id`, `:span_kind`, etc.) passes through untouched. This exactly matches the shape a captured `[:scoria, :observe, :span, :stop]` event's `metadata` already has (see the adapter span maps below), so no reshaping is needed before calling `enforce/2` in the conformance test.

The three-tier rule it implements internally (for documentation/exhaustiveness purposes, not for hand-reconstruction):
1. `Map.has_key?(Semconv.attribute_registry(), key)` → `:ok` (`bounds.ex:235`)
2. `Enum.any?(Semconv.vendor_key_prefixes(), &String.starts_with?(key, &1))` AND `key not in Semconv.denied_exact_keys()` AND no dot-segment in `Semconv.denied_key_segments()` → `:ok` (`bounds.ex:242-246`)
3. `config :scoria, Bounds, allowed_key_prefixes: [...]` (host config, default `[]`) → `:ok` (`bounds.ex:256-258`)
4. else → `:denied`, key dropped (never truncated)

`Semconv.vendor_key_prefixes/0` = `~w(gen_ai. server. openai. req_llm. error.)` (`semconv.ex:369`). `Semconv.denied_exact_keys/0` = the four req_llm content-promoted keys (`semconv.ex:381`). `Semconv.denied_key_segments/0` = `~w(messages content completion prompt text body)` (`semconv.ex:399`). `scoria.`, `openinference.`, `jido.`, and all bare keys are registry-only (no prefix escape) — confirmed by both the moduledoc and by `vendor_key_prefixes/0`'s actual list (no `scoria.`/`openinference.`/`jido.` entry).

### 2. D-07 — the post-Bounds "record of truth" capture point

**(a) Exact boundary — `lib/scoria/observe/telemetry.ex:66-79`:**

```elixir
def handle_event([:scoria, :observe, :span, _type], _measurements, metadata, %{
      buffer_name: buffer_name
    }) do
  redacted = redact(metadata)                      # Redactor.redact/1, telemetry.ex:144

  case Bounds.enforce(redacted, :span) do
    {:ok, bounded} ->
      ReviewerBroadcast.span_stopped(bounded)
      Buffer.cast_span(buffer_span(bounded), buffer_name)

    :drop ->
      :ok
  end
end
```

The pipeline is exactly: `redact/1` → `Bounds.enforce/2` → (`ReviewerBroadcast.span_stopped/1`, `Buffer.cast_span/2`). This is the SINGLE handler clause for `[:scoria, :observe, :span, :stop]` (and `:delta`, but that arm branches separately at `telemetry.ex:56` and never reaches `Bounds`). `bounded` (the `:attributes` sub-map of the `{:ok, bounded}` return) is exactly what `Buffer.cast_span/2` receives (after a further `Map.take/2` projection at `telemetry.ex:120-124`, which only restricts *top-level* span fields, not `:attributes` contents) and is exactly what lands in Postgres's `ai_spans.attributes` jsonb column.

**(b) Is `Scoria.Observe.Telemetry` the record boundary?** Yes — confirmed. There is no other consumer of `[:scoria, :observe, :span, :stop]` in `lib/` that persists to Postgres; `ReviewerBroadcast.span_stopped/1` is a LiveView PubSub broadcast (browser-facing, not persistence), and `Buffer.cast_span/2` is the sole path into the DB (via the existing `Buffer` flush machinery from Phase 51).

**(c) How can a test capture the post-Bounds record?** There is **no telemetry event emitted between `Bounds.enforce/2` and persistence** — `handle_event/4` calls `Bounds.enforce/2` and immediately pattern-matches its return inline; nothing re-emits an event for a test to attach to at that exact point. Two viable capture mechanisms exist:

1. **DB read-back** (the `mcp_test.exs` idiom, Correction 2): drive the real adapter, let it flow through the real `Telemetry.attach/1` handler into a real scoped `Buffer`, flush, then `Repo.get_by!(Span, trace_id: ...)`. Fully faithful, but requires Sandbox + `async: false` + supervised `Buffer` boilerplate.
2. **In-test pipeline replay (RECOMMENDED)**: attach to `[:scoria, :observe, :span, :stop]` directly (the `req_llm_test.exs` idiom), capture the raw pre-Bounds `metadata`, then call `metadata |> Redactor.redact() |> Bounds.enforce(:span)` in the test body — the exact two production function calls, in the exact production order, both public. This reaches the identical post-Bounds record with zero DB dependency. Recommended per the Primary recommendation above.

### 3. D-03 — adoption test-file registration hook

**Confirmed.** `Mix.Tasks.Scoria.Test.Adoption` exists at `lib/mix/tasks/test.adoption.ex:1`. The exact attribute is `@adoption_test_files` (`test.adoption.ex:5-19`), currently a 13-entry list ending with `"test/scoria/bootstrap/migration_lane_compatibility_test.exs"`. Adding `"test/scoria/observe/conformance_test.exs"` as a 14th entry is a one-line diff, exactly as D-03 anticipated. `def adoption_test_files, do: @adoption_test_files` (`:21`) is the public reader; no test currently asserts an exact/closed list length for this attribute (confirmed by grepping `test/mix/tasks/test.adoption_test.exs` — it does not enumerate the list), so the addition is a pure append with no companion test edit required.

**Note on tag exclusion:** `test/test_helper.exs` (`ExUnit.start(exclude: excluded_tags)`, `test_helper.exs:9-20`) only excludes `:knowledge`, `:registry_proof`, and `:registry_upgrade` tags by default. A `@moduletag :conformance` on the new test file will **not** be excluded by default `mix test` — it runs in the default suite and, once registered, under `mix test.adoption` too. No `test_helper.exs` change needed.

### 4. Adapter emit reality (three adapters)

All three confirmed to emit `[:scoria, :observe, :span, :stop]`:

| Adapter | Source event | Emit line | `span_kind` produced |
|---|---|---|---|
| `Scoria.Observe.Adapters.ReqLLM` | `[:req_llm, :request, :stop]` | `req_llm.ex:80` | `"llm"` (default) — `SpanKind.normalize(metadata[:span_kind] \|\| "llm")` at `req_llm.ex:53`; host-overridable |
| `Scoria.Observe.Adapters.MCP` | `[:scoria, :tool, :completed\|:timeout\|:failed]` (NOT `:started`) | `mcp.ex:127` | `"mcp"` always — `SpanKind.normalize("mcp")` at `mcp.ex:91`, hardcoded, not host-overridable |
| `Scoria.Observe.Adapters.Jido` | `[:jido, :action, :stop]` | `jido.ex:73` | `"tool"` (default) — `SpanKind.normalize(metadata[:span_kind] \|\| "tool")` at `jido.ex:41`; host-overridable |

`SpanKind.to_openinference/1` maps: `"llm"→"LLM"`, `"mcp"→"TOOL"`, `"tool"→"TOOL"` (`span_kind.ex:26-35`).

**jido's raw vendor keys, confirmed dropped by Bounds:** `jido.ex:48-49` puts `"jido.action_name"` and `"jido.status"` onto the span's attributes map, unconditionally (subject to nil-rejection at `:54`). Neither key matches any `Semconv.vendor_key_prefixes/0` entry (`gen_ai. server. openai. req_llm. error.` — no `jido.` prefix) nor any `Semconv.attribute_registry/0` key. `Bounds.classify_key/2` therefore returns `:denied` for both — they are dropped before persistence, exactly as D-07 states. This is a structural (not incidental) property: `jido.`-prefixed keys are registry-only per the `Bounds` moduledoc's own claim (`bounds.ex:33-34`), and no registry entry exists for either bare string.

**`SpanKind.kinds()` exhaustiveness scope — important clarification for D-06:** The three adapters, by default, can only ever emit **3 of the 8** canonical kinds: `"llm"` (req_llm), `"mcp"` (mcp, hardcoded), `"tool"` (jido default). The other 5 kinds (`"agent"`, `"prompt"`, `"retriever"`, `"guardrail"`, `"eval"`) are emitted elsewhere in the codebase via `Observe.span/4` and its wrappers/legacy emitters — `lib/scoria/workflows/runtime.ex:222` (`Observe.span(span_kind, ...)`, `span_kind` derived from `step.kind`), `lib/scoria/knowledge.ex:301,329` (`emit_retriever_span/1` → `"retriever"`), `lib/scoria/eval/judge_runner.ex:202` (`Observe.with_prompt/3` → `"prompt"`) — none of which are req_llm/mcp/jido "adapters" per the Reconciliation notes' scope ("the check covers all span-emitting adapters"). **Recommendation:** scope D-06's exhaustiveness assertion to "every `span_kind` value the three adapters can actually produce" (llm/mcp/tool, plus a host-override test proving the override path is honored) rather than attempting to exercise all 8 `SpanKind.kinds()` values — doing the latter would require driving `Workflows.Runtime`/`Knowledge`/`JudgeRunner` code paths, which is out of D-04's "drive the real [three] adapters" scope and would silently expand this docs-only phase into runtime-adjacent integration testing.

### 5. Capture harness idiom

See Correction 2 for the full comparison. Concrete idiom to lift (from `req_llm_test.exs:11-22,52-56`):

```elixir
setup do
  :telemetry.detach("scoria-observe-telemetry-test-conformance")

  parent = self()
  :telemetry.attach(
    "scoria-observe-telemetry-test-conformance",
    [:scoria, :observe, :span, :stop],
    fn _name, _measurements, metadata, _config -> send(parent, {:span, metadata}) end,
    nil
  )

  Scoria.Observe.Adapters.ReqLLM.attach()
  # Scoria.Observe.Adapters.Jido.attach() -- if not already attached at boot
  :ok
end

defp capture_span(event, metadata) do
  :telemetry.execute(event, %{}, metadata)
  assert_receive {:span, span}
  span
end
```

Both `ReqLLM.attach/0` and `Jido.attach/0` are idempotent-safe to call in `setup` (return `{:error, :already_exists}` harmlessly if already attached at boot — confirmed by the `MCPTest` "Test 9: boot attach" pattern at `mcp_test.exs:221-225`). The MCP adapter's handler (`"scoria-observe-mcp"`) is attached once at `Scoria.Application` boot per `mcp_test.exs`'s moduledoc (`mcp_test.exs:15-18`) and does not need re-attaching in the conformance test — the test can fire `[:scoria, :tool, :completed\|:timeout\|:failed]` directly, exactly like `mcp_test.exs`'s `emit_and_flush/4` helper (minus the DB flush step).

The `semconv_test.exs`/`span_kind_test.exs` "execute-the-SSOT + exhaustiveness + guard-must-bite" idiom to mirror:
- **Execute-the-SSOT:** call the real `Semconv`/`SpanKind`/`Bounds` functions directly rather than hand-copying their return values (e.g. `span_kind_test.exs:94-96`'s `SpanKind.kinds() == ~w(...)` canary).
- **Exhaustiveness:** `for kind <- SpanKind.kinds() do ... end` loops that touch every member (`span_kind_test.exs:98-106`).
- **Guard-must-bite (negative self-test):** `span_kind_test.exs:132-148`'s fallback-telemetry test proves a bogus input actually trips the fallback path and telemetry event, not just that valid inputs pass. The conformance test's D-06 negative self-test should mirror this shape: feed a deliberately bogus key/kind through the exact same `Bounds.enforce/2`/`SpanKind.kind?/1` calls and assert the guard visibly bites (key absent post-enforce; `SpanKind.kind?/1` false), not merely that it doesn't crash.

### 6. Doc-contract guard mechanics

**`lib/scoria/adopter_doc_contract.ex`** — exact current contents (verbatim):

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
]                                                          # adopter_doc_contract.ex:59-72

@comparison_deferred_not_current_claims [
  "OpenInference export is not a current Scoria claim",     # adopter_doc_contract.ex:84 (KEEP)
  "Rule-of-Two/lethal-trifecta enforcement is not a current Scoria claim",
  "deeper scorer calibration is not a current Scoria claim",
  "richer retrieval evals are not current Scoria claims",
  "retention, masking, purge, and feedback governance are not current Scoria claims",
  "persistent AI feature grouping is not a current Scoria claim"
]                                                          # adopter_doc_contract.ex:83-90

@comparison_forbidden_current_claims [
  "OpenInference export",                                   # adopter_doc_contract.ex:93 (KEEP)
  "OpenInference-compatible export",                         # adopter_doc_contract.ex:94 (KEEP)
  "Rule-of-Two", "lethal-trifecta enforcement", "mature scorer calibration",
  "regression depth", "deep retrieval eval", "faithfulness metrics",
  "retention governance", "masking governance", "purge governance",
  "feedback governance", "persistent AI feature grouping"
]                                                          # adopter_doc_contract.ex:92-106
```

**D-11's substring-safety claim CONFIRMED:** both forbidden entries contain the discriminator word `export` (`"OpenInference export"`, `"OpenInference-compatible export"`). The honest claim string `"OpenInference-compatible convention keys"` contains neither `"OpenInference export"` nor `"OpenInference-compatible export"` as a substring (it has `"OpenInference-compatible "` followed by `"convention"`, not `"export"`) — `refute current_section =~ forbidden_claim` (`adoption_surface_test.exs:258-261`) stays green when the new string is added to `@comparison_safe_current_claims`. The **TRAP** D-11 names (never add bare `"OpenInference-compatible"` to a forbidden list) is real: `"OpenInference-compatible"` IS a substring of `"OpenInference-compatible convention keys"` and of `"OpenInference-compatible export"` — adding the bare phrase to `@comparison_forbidden_current_claims` would make the `refute` in the current-section check fail against the very claim D-10 adds.

**`lib/scoria/ai_doc_contract.ex`** — exact current contents (verbatim):

```elixir
@forbidden_ai_doc_fragments [
  ".planning/", "prompts/", "priv/dev/", "Scoria AI",
  "autonomous agent platform", "OpenInference export",       # ai_doc_contract.ex:85 (KEEP)
  "lethal-trifecta", "Rule-of-Two", "Keystone", "v2.0 Relay", "The Four Lanes"
]                                                          # ai_doc_contract.ex:79-91

@required_llms_paths [                                    # ai_doc_contract.ex:17-49, 32 entries
  "README.md", "guides/getting-started.md", "guides/golden-path.md",
  "guides/jtbd-and-user-flows.md", "guides/ownership-boundary.md",
  "guides/capabilities/default-runtime.md", "guides/capabilities/bounded-handoffs.md",
  "guides/capabilities/semantic-cache.md", "guides/capabilities/connectors-and-mcp.md",
  "guides/capabilities/support-copilot-gallery.md", "guides/reviewer-verification.md",
  "guides/troubleshooting.md", "guides/scoria-vs-external-llm-ops.md",
  "guides/cheatsheet.cheatmd", "guides/reference/glossary.md", "guides/maintainers.md",
  "lib/scoria.ex", "lib/scoria/identity.ex", "lib/scoria/runtime.ex",
  "lib/scoria/verification_suites.ex", "lib/scoria_web/reviewer_surface.ex",
  "lib/scoria/observe/reviewer_broadcast.ex", "lib/scoria/semantic_cache/profile.ex",
  "lib/scoria/semantic_cache.ex", "lib/scoria/knowledge.ex", "lib/scoria/connectors.ex",
  "lib/scoria/connectors/auth.ex", "lib/scoria/mcp/tool.ex", "lib/scoria/eval.ex",
  "test/scoria/adoption_surface_test.exs", "test/scoria/terminology_contract_test.exs"
]
```

Adding `"guides/capabilities/trace-observability.md"` is a 33rd list entry.

**Confirmed test auto-coverage (D-11's claim):**
- `test/scoria/adoption_surface_test.exs:253-256` — a `for current_claim <- AdopterDocContract.comparison_safe_current_claims() do assert current_section =~ current_claim end` loop. Any new string appended to `@comparison_safe_current_claims` is automatically checked with zero test-file edit — confirmed exact mechanism.
- `test/scoria/ai_doc_contract_test.exs:17-49` (`required_llms paths` test) checks a **hardcoded subset list is a member of** `AiDocContract.required_llms_paths()` (`assert path in required_paths`) plus a no-duplicates check (`:48`) — it does NOT assert exact-equality against the full list, so appending a new path requires **no edit to this test**. However, `test/scoria/ai_doc_contract_test.exs:107-127` (`"root llms.txt exposes the required public source map"`) DOES iterate the live `required_llms_paths()` and asserts `content =~ path` for every one (`:116-118`) — so `llms.txt` itself MUST literally reference the new guide's path string, or this test goes RED. This is the concrete "blast radius" D-08 names.
- `test/scoria/ai_doc_contract_test.exs:87-105` similarly iterates a hardcoded subset of `forbidden_ai_doc_fragments()` — adding nothing here (D-11 keeps `"OpenInference export"` unchanged) requires no edit.

### 7. Doc surfaces + current wording (exact quotes)

| Surface | Current content (verbatim) | Location |
|---|---|---|
| `guides/reference/glossary.md` (line ~31) | `- Industry equivalent: trace or span tree in OpenTelemetry/OpenInference-style observability.` | `glossary.md:31` |
| `guides/reference/glossary.md` (line ~36) | `Trace vocabulary aligns with OpenTelemetry/OpenInference-style observability language, but Scoria does not claim an OpenInference-compatible export or trace substrate until that future work ships.` | `glossary.md:36` |
| `guides/scoria-vs-external-llm-ops.md` ("Not current Scoria claims" section) | `- OpenInference export is not a current Scoria claim. Scoria uses trace vocabulary, but export compatibility belongs to the future trace-foundation seed.` | `scoria-vs-external-llm-ops.md:77` — note: this line lives under `## Not current Scoria claims` (`:73`), NOT under `## What Scoria currently owns` (`:20-32`, the section D-10's new sentence must land in per D-08). `## What Scoria currently owns` currently has NO OpenInference mention at all — this is a pure addition, not a replace. |
| `README.md` | No `OpenInference` mention found (`grep` returned zero matches) — pure addition, no find/replace anchor needed | — |
| `llms.txt` | No `OpenInference` mention found; Capability Guides section (`llms.txt:33-39`) lists exactly 5 guides (default-runtime, bounded-handoffs, semantic-cache, connectors-and-mcp, support-copilot-gallery) — `trace-observability.md` is a 6th entry to add | `llms.txt:33-39` |
| `AGENTS.md` | No `OpenInference` mention found — pure addition | — |
| `CHANGELOG.md` (lines 156-157) | `now emits OTel-GenAI / OpenInference convention keys (\`gen_ai.*\`, \`server.*\`,` / `` `openinference.span.kind`) instead of Scoria's own ad hoc keys. `` | `CHANGELOG.md:156-157` — **already aligned**, confirmed byte-for-byte; the CONTEXT's claim that D-10's sentence "reuses CHANGELOG:156's existing noun phrase" is accurate (`OTel-GenAI / OpenInference convention keys` vs. D-10's `OpenTelemetry-GenAI / OpenInference-compatible convention keys` — near-identical phrasing, CHANGELOG needs no edit per D-10/D-11's scope). |

**`guides/capabilities/trace-observability.md` confirmed NOT to exist.** `ls guides/capabilities/` shows exactly 6 files: `bounded-handoffs.md`, `connectors-and-mcp.md`, `default-runtime.md`, `llm-and-tool-adapters.md`, `semantic-cache.md`, `support-copilot-gallery.md`. (Side note, out of this phase's scope: `llm-and-tool-adapters.md` already exists and is NOT currently in `@required_llms_paths` — a pre-existing gap, not something Phase 54 needs to fix, but worth flagging to the planner in case it's confused with the new trace guide.)

**`deps/req_llm/lib/req_llm/open_telemetry.ex:112`:**
```elixir
@otel_schema_url "https://opentelemetry.io/schemas/1.37.0"
```
Confirmed exact match to D-09's pin. `mix.exs:98` pins `{:req_llm, "~> 1.13"}`.

### 8. D-07 emit-layer extra-bite recommendation

**Recommendation: YES, add a lightweight emit-layer classification, but as a secondary/supporting assertion, not the primary falsifiable claim.**

Rationale: the record-of-truth assertion alone (what survives `Bounds.enforce/2`) proves the *positive* claim (persisted spans only carry allow-listed keys). It does NOT distinguish "this key was correctly dropped because it's a known Scoria-owned vendor key like `jido.action_name`" from "this key was dropped because of an unrelated regression that silently ate a key adopters actually need." Pairing with a classification of the DROPPED-key set — asserting every key present pre-Bounds but absent post-Bounds is either (a) in a documented drop-list (`jido.action_name`, `jido.status` today) or (b) a Bounds marker key artifact — makes an unexpected future drop loudly visible instead of silently passing. This is cheap to add (a `MapSet.difference/2` between pre- and post-enforce attribute key sets, then an assertion the difference is a subset of a small documented allow-to-drop list) and directly serves D-06's "guard must bite" discipline: it turns "the check happens to still pass" into "the check would fail if a NEW key started being silently dropped." Keep it scoped to the known 3 adapters' actual key sets — do not attempt to enumerate every theoretically-droppable key across the whole `Semconv` surface, which would balloon this into a second registry-canary test duplicating `semconv_test.exs`'s existing "SEC-01 Test 1" canary (`semconv_test.exs:274-307`).

## Standard Stack

No new dependencies. This phase uses only:

| Module | Purpose | Already exists |
|---|---|---|
| `ExUnit.Case` | Test harness | stdlib |
| `:telemetry` | Event bus | existing dep (already used throughout `lib/scoria/observe/`) |
| `Scoria.Observe.Semconv` | Allow-list SSOT | `lib/scoria/observe/semconv.ex` |
| `Scoria.Observe.SpanKind` | Kind taxonomy SSOT | `lib/scoria/observe/span_kind.ex` |
| `Scoria.Observe.Bounds` | Admission enforcement SSOT | `lib/scoria/observe/bounds.ex` |
| `Scoria.Observe.Redactor` | Pre-Bounds redaction (call before `Bounds.enforce/2` to mirror production order) | `lib/scoria/observe/redactor.ex` |
| `Scoria.Observe.Adapters.{ReqLLM,MCP,Jido}` | The three producers under test | `lib/scoria/observe/adapters/*.ex` |

No `npm view`/`pip index`/`cargo search` verification needed — no external packages are installed or upgraded by this phase.

## Package Legitimacy Audit

Not applicable. This phase adds zero dependencies (docs + one test file only, per the CONTEXT's explicit scope boundary). No packages to audit.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────┐
│  Real adapter emit call     │  (test drives these directly, exactly
│  [:req_llm,:request,:stop]  │   like req_llm_test.exs / mcp_test.exs
│  [:scoria,:tool,:completed] │   already do for their own suites)
│  [:jido,:action,:stop]      │
└──────────────┬───────────────┘
               │ adapter handle_event/4 builds span map
               ▼
┌─────────────────────────────┐
│ [:scoria,:observe,:span,:stop] │  <-- CONFORMANCE TEST ATTACHES HERE
│  (emit layer — pre-Bounds)     │      (assert_receive, req_llm_test.exs idiom)
└──────────────┬───────────────┘
               │ captured raw metadata
               ▼
┌─────────────────────────────┐
│ Redactor.redact/1 (in-test  │  <-- mirrors Telemetry.handle_event/4's
│  replay, same fn, no I/O)   │      exact production call, telemetry.ex:69
└──────────────┬───────────────┘
               ▼
┌─────────────────────────────┐
│ Bounds.enforce(_, :span)    │  <-- mirrors telemetry.ex:71 — THE
│  (in-test replay)            │      post-Bounds "record of truth"
└──────────────┬───────────────┘
               │ {:ok, bounded} — bounded.attributes is what
               │ Buffer.cast_span/2 would persist verbatim
               ▼
      ┌────────┴─────────┐
      │  ASSERT:          │
      │  - every key in    │
      │    bounded.attrs   │
      │    ∈ SSOT allow-   │
      │    list            │
      │  - span_kind ∈     │
      │    SpanKind.kinds()│
      │  - openinference.  │
      │    span.kind =     │
      │    to_openinference│
      │    (span_kind)     │
      │  - dropped-key set │
      │    (pre minus post)│
      │    ⊆ documented    │
      │    drop-list        │
      └───────────────────┘

(Production path, NOT re-walked by the test — shown for context only:)
Telemetry.handle_event/4 → Bounds.enforce/2 → ReviewerBroadcast.span_stopped/1
                                              → Buffer.cast_span/2 → Postgres ai_spans
```

### Recommended Project Structure

```
test/scoria/observe/
└── conformance_test.exs     # Scoria.Observe.ConformanceTest, @moduletag :conformance
                              # ExUnit.Case, async: true (no shared Buffer/DB state needed
                              # per the recommended in-test-replay capture strategy)
```

### Pattern 1: In-test pipeline replay (recommended capture strategy)

**What:** Capture at the emit-layer telemetry event, then call the exact two production functions (`Redactor.redact/1`, `Bounds.enforce/2`) in the test body, in production order, to derive the post-Bounds record without touching Buffer/Postgres.

**When to use:** Whenever a test needs the "what actually persists" answer but doesn't need to prove the Buffer/flush/Ecto layer itself (that's already covered by `mcp_test.exs`, `telemetry_test.exs`, `prompt_span_test.exs`).

**Example:**
```elixir
# Source: this repo, telemetry.ex:66-79 (production order) +
# req_llm_test.exs:11-22,52-56 (capture idiom)
defp record_of_truth(event, metadata) do
  raw = capture_span(event, metadata)  # emit-layer :telemetry.attach + assert_receive
  {:ok, bounded} = raw |> Scoria.Observe.Redactor.redact() |> Scoria.Observe.Bounds.enforce(:span)
  bounded
end
```

### Pattern 2: Execute-the-SSOT + exhaustiveness + guard-must-bite (existing repo idiom)

**What:** Never hand-copy a whitelist's values into a test; call the real function and iterate its real return. Then negatively prove the guard actually bites on a bogus input.
**When to use:** Every drift-guard test in this codebase — `semconv_test.exs`, `span_kind_test.exs` are the canonical examples; the conformance test should match this shape exactly.
**Example:** see `span_kind_test.exs:94-106` (canary + exhaustiveness) and `:132-148` (guard-must-bite fallback proof).

### Anti-Patterns to Avoid

- **Golden-span fixture files:** rejected by D-04 — passes forever while real emission drifts. Not idiomatic to this repo (confirmed: no `.exs`/`.json` golden-fixture files exist anywhere under `test/scoria/observe/`).
- **Re-listing allow-listed keys as a literal `~w(...)` in the test:** this is exactly the anti-pattern `span_kind_test.exs`'s "ANTI-INLINE GUARD" (`:123-130`) exists to catch elsewhere in the codebase — the conformance test must call `Semconv`/`Bounds` functions, never hand-copy their values.
- **Reconstructing `Bounds`'s admission rule from the four `Semconv` functions instead of calling `Bounds.enforce/2` directly:** see Correction 1 — this would create a second, driftable copy of the exact logic `Bounds` already encapsulates.
- **Exhaustively covering all 8 `SpanKind.kinds()` values via the three adapters:** see item 4 above — 5 of the 8 kinds are unreachable from req_llm/mcp/jido without driving unrelated runtime code (`Workflows.Runtime`, `Knowledge`, `JudgeRunner`), which is out of this phase's scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Key admission logic | A hand-copied allow-list check reading `Semconv.attribute_registry/0` etc. directly | `Bounds.enforce/2` | It's the actual production SSOT function; calling it directly means the test cannot drift from what production does (see Correction 1) |
| Span-kind validity check | A hardcoded `~w(llm mcp tool ...)` list | `SpanKind.kind?/1` / `SpanKind.kinds()` | Existing SSOT, already drift-guarded elsewhere (`span_kind_test.exs`) |
| OpenInference mirror check | Manually mapping `"llm"→"LLM"` etc. | `SpanKind.to_openinference/1` | Same reasoning |

**Key insight:** every piece of "allow-list logic" this conformance check needs already exists as a public function in `Semconv`/`SpanKind`/`Bounds`. The entire task is composition + capture, not new logic.

## Common Pitfalls

### Pitfall 1: Attaching a NEW handler under the SAME id as an already-attached production handler

**What goes wrong:** `:telemetry.attach/4` raises/returns `{:error, :already_exists}` if the handler id collides with one attached at boot (e.g. `"scoria-observe-reqllm"`, `"scoria-observe-mcp"`, `"scoria-observe-jido"`, `"scoria-observe-telemetry"`).
**Why it happens:** `Scoria.Application` boot already attaches all adapter handlers (confirmed via `mcp_test.exs`'s "Test 9: boot attach" and its moduledoc).
**How to avoid:** Use a distinct handler id for the test's OWN capture attach (e.g. `"scoria-observe-telemetry-test-conformance"`), exactly like `req_llm_test.exs:12` does (`"scoria-observe-telemetry-test-req"`, distinct from production's `"scoria-observe-telemetry"`). Do NOT detach/reattach `"scoria-observe-reqllm"`/`"scoria-observe-mcp"`/`"scoria-observe-jido"` — those can stay live; just fire the raw upstream events.
**Warning signs:** `{:error, :already_exists}` from `attach/4`, or duplicate span captures if the test's own attach ID happens to collide with a production one across parallel `async: true` test runs.

### Pitfall 2: Forgetting the MCP adapter's `:started` event emits nothing

**What goes wrong:** Firing `[:scoria, :tool, :started]` alone produces zero spans (confirmed `mcp.ex:71`: `def handle_event([:scoria, :tool, :started], _measurements, _metadata, _config), do: :ok`).
**Why it happens:** A span needs a duration; only the three terminal events (`:completed`/`:timeout`/`:failed`) carry `%{duration: duration}`.
**How to avoid:** The conformance corpus for the MCP adapter must fire one of the three terminal events, per kind (OK-path via `:completed`, ERROR-path via `:timeout` or `:failed`).
**Warning signs:** An "empty corpus for MCP adapter" failure in the D-06 non-empty-per-adapter guard.

### Pitfall 3: Reading `metadata[:operation]` instead of `metadata[:span_kind]` for req_llm's kind

**What goes wrong:** `req_llm`'s own telemetry vocabulary (`:chat`/`:embedding`/`:object`, from `ReqLLM.Telemetry.new_context/3`) looks superficially like a "kind," but it is a DIFFERENT taxonomy than Scoria's `span_kind`. Reading it would defeat `SpanKind.normalize/2`'s fallback (documented explicitly in `req_llm.ex:50-52`).
**How to avoid:** Always read/override via `metadata[:span_kind]`, never `metadata[:operation]`, when constructing conformance-test fixtures for the req_llm adapter's host-override path.

### Pitfall 4: Asserting on `metadata[:reason]` for MCP's `:failed` event

**What goes wrong:** `metadata[:reason]` on `[:scoria, :tool, :failed]` is an arbitrary raw Elixir term (may embed leaked data) and is deliberately NEVER read by the adapter (`mcp.ex:35`: "This is NEVER read"). A conformance test that reads it to build assertions would test something the production code intentionally ignores.
**How to avoid:** Only assert on the adapter's actual output fields (`"status"`, `"duration_ms"`, `"tool_ref"`, etc.), never on `:reason` directly.

## Code Examples

### Deriving the post-Bounds record (recommended primary idiom)

```elixir
# Source: this repo — Scoria.Observe.Telemetry.handle_event/4, telemetry.ex:66-79
# (production order: redact/1, then Bounds.enforce/2)
{:ok, bounded} =
  raw_metadata
  |> Scoria.Observe.Redactor.redact()
  |> Scoria.Observe.Bounds.enforce(:span)

# bounded.attributes is byte-identical to what Buffer.cast_span/2 would receive
# and what Postgres's ai_spans.attributes jsonb column would store.
```

### Allow-list membership assertion (never hand-copy the list)

```elixir
# Source: this repo — Scoria.Observe.Bounds's own admission tiers, expressed via
# calling enforce/2 rather than reconstructing them (see Correction 1)
for {key, _value} <- bounded.attributes, key not in Semconv.bounds_marker_keys() |> Map.values() do
  assert Map.has_key?(Semconv.attribute_registry(), key) or
           Enum.any?(Semconv.vendor_key_prefixes(), &String.starts_with?(key, &1)),
         "unexpected surviving key #{inspect(key)} — Bounds.enforce/2 should have dropped this"
end
```

(Note: since `Bounds.enforce/2` already dropped everything it would drop, this loop is really a sanity check that no key OUTSIDE the documented admission tiers slipped through some other path — belt-and-suspenders, not the primary falsifiable claim, which is simply "call `enforce/2`, inspect what survives.")

### Span-kind + OpenInference mirror assertion

```elixir
# Source: this repo — span_kind_test.exs:64-74's to_openinference/1 idiom
assert SpanKind.kind?(span.span_kind)
assert span.attributes[Semconv.openinference_span_kind_key()] ==
         SpanKind.to_openinference(span.span_kind)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| "OpenInference-style observability" (softened, no version pin) | "OpenTelemetry-GenAI / OpenInference-compatible convention keys" (version-pinned, honest) | Phase 54 (this phase) | Adopter-facing claim becomes falsifiable; doc-contract lists gate it |
| No conformance proof for the compatibility claim | `test/scoria/observe/conformance_test.exs` calling the real `Semconv`/`SpanKind`/`Bounds` SSOT against live adapter output | Phase 54 (this phase) | The claim and the runtime become structurally linked — a future drift in any adapter's key/kind emission trips this test |

**Deprecated/outdated:** the glossary's "does not claim an OpenInference-compatible export or trace substrate until that future work ships" softener (`glossary.md:36`) becomes outdated once this phase ships — the *convention* (not *export*) now IS a current, proven claim; only export stays deferred (D-12).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The D-07 emit-layer extra-bite recommendation (dropped-key classification as a secondary assertion) is worth the added ~10-15 lines of test code | Confirmed Seams §8 | Low — this is a `Claude's Discretion` item per CONTEXT; if the planner disagrees, the primary record-of-truth assertion alone still satisfies DOCS-02 |
| A2 | D-06 exhaustiveness should be scoped to the 3 adapter-reachable span_kind values (llm/mcp/tool), not all 8 `SpanKind.kinds()` values | Confirmed Seams §4 | Medium — if the planner instead wants full 8-kind coverage, the conformance test would need to additionally drive `Workflows.Runtime`/`Knowledge.retrieve/2`/`JudgeRunner`, which expands scope beyond "the three adapters" and beyond a docs-only phase; flagged loudly above so the planner can make this call explicitly rather than by omission |

Everything else in this document is `[VERIFIED]` by direct file read against the live repository at HEAD (commit `ff9715f8` per git status) — no `[ASSUMED]` claims beyond the two above.

## Open Questions

1. **Should the conformance test also exercise the host-override path on req_llm/jido (`metadata[:span_kind]` override)?**
   - What we know: both adapters support a host override (`req_llm.ex:53`, `jido.ex:41`); this is the only way those two adapters could ever emit one of the other 7 `SpanKind.kinds()` values.
   - What's unclear: whether D-06's "every kind an adapter CAN emit" should be read narrowly (only the *default* kind each adapter emits without host input) or broadly (every kind reachable via the documented override mechanism).
   - Recommendation: include ONE host-override test per overridable adapter (e.g., req_llm with `metadata[:span_kind] => "agent"`) to prove the override path itself is honored end-to-end through `Bounds`/`SpanKind`, without attempting to enumerate all 7 non-default kinds — this satisfies "the check must bite on drift in the override mechanism" without ballooning into full 8-kind coverage (see A2 above).

## Environment Availability

Skipped — this phase has no external tool/service/runtime dependencies beyond what's already running in CI (Elixir/Postgres, both already provisioned for every other test in this suite). No new dependency to probe.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir; no config needed) |
| Config file | `test/test_helper.exs` (existing; only needs the tag-exclusion note in §3 above — no edit required for `:conformance`) |
| Quick run command | `mix test test/scoria/observe/conformance_test.exs` |
| Full suite command | `mix test` (default suite; also `mix test.adoption` once registered per D-03) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-01 | Doc-contract lists updated additively; substrings stay refute-safe | unit (ExUnit, existing files) | `mix test test/scoria/adoption_surface_test.exs test/scoria/ai_doc_contract_test.exs` | ✅ both exist |
| DOCS-01 | New guide + doc surfaces carry the D-10 sentence | unit (ExUnit, existing doc-content assertions in `adoption_surface_test.exs`/`ai_doc_contract_test.exs`, extended) | same as above | ✅ (extend existing test bodies; no new file) |
| DOCS-02 | Emitted spans use only allow-listed keys + valid `span_kind` | unit (new ExUnit test) | `mix test test/scoria/observe/conformance_test.exs` | ❌ Wave 0 — new file per D-01 |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/observe/conformance_test.exs` (fast, no DB per the recommended in-test-replay strategy)
- **Per wave merge:** `mix test.adoption` (once the file is registered in `@adoption_test_files` per D-03)
- **Phase gate:** `mix test` full suite green; `mix test.adoption` green; `mix scoria.release_preview` green (docs/ExDoc gate, unaffected by this phase's changes but part of the existing closeout chain per D-02's "do not touch" — confirmed `verification_lanes.ex:25` `defdelegate closeout_order, to: VerificationSuites` stays byte-identical since this phase adds no lane)

### Wave 0 Gaps

- [ ] `test/scoria/observe/conformance_test.exs` — new file, covers DOCS-02 (all seams confirmed above; no framework/fixture gap — reuses existing `req_llm_test.exs`/`mcp_test.exs`/`semconv_test.exs`/`span_kind_test.exs` idioms verbatim)
- [ ] No new shared fixtures needed — `Semconv`, `SpanKind`, `Bounds`, `Redactor` are all directly callable, and the three adapters' `attach/0` functions are idempotent

*(DOCS-01's test coverage has no Wave 0 gap — both `adopter_doc_contract.ex` and `ai_doc_contract.ex` already have exhaustive ExUnit contract tests that auto-cover additive list changes, per §6 above.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Not touched by this phase |
| V3 Session Management | No | Not touched by this phase |
| V4 Access Control | No | Not touched by this phase |
| V5 Input Validation | Yes (indirectly) | `Bounds.enforce/2`'s closed-registry admission is the existing SEC-01 control this phase's test PROVES rather than introduces; no new validation logic is added |
| V6 Cryptography | No | Not touched by this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A future adapter change silently widens the persisted key surface (e.g. a new vendor key that leaks free-text) | Information Disclosure | This phase's conformance test is itself the mitigation — it fails RED the moment an adapter starts emitting a key `Bounds.enforce/2` doesn't drop and that isn't in the registry |
| A doc claim overclaims a capability the runtime doesn't back (marketing-drift) | Tampering (of adopter trust/expectations) | The existing `AdopterDocContract`/`AiDocContract` substring guards, extended additively by this phase, are the standard mitigation already in place |

No new threat surface is introduced — this phase closes an existing gap (claim without proof) rather than opening one.

## Sources

### Primary (HIGH confidence — direct file reads against live repo at HEAD)
- `lib/scoria/observe/bounds.ex` — admission rule, public API surface
- `lib/scoria/observe/semconv.ex` — allow-list SSOT
- `lib/scoria/observe/span_kind.ex` — kind taxonomy SSOT
- `lib/scoria/observe/telemetry.ex` — the record-boundary handler
- `lib/scoria/observe.ex` — `span/4` and legacy emitters (`emit_retriever_span/1`, `emit_prompt_span/1`)
- `lib/scoria/observe/adapters/req_llm.ex`, `mcp.ex`, `jido.ex` — the three adapters
- `lib/mix/tasks/test.adoption.ex` — `@adoption_test_files`
- `lib/scoria/adopter_doc_contract.ex`, `lib/scoria/ai_doc_contract.ex` — the doc-contract SSOT modules
- `test/scoria/observe/adapters/req_llm_test.exs`, `mcp_test.exs` — capture-harness idioms
- `test/scoria/observe/semconv_test.exs`, `span_kind_test.exs` — execute-the-SSOT/exhaustiveness/guard-must-bite idioms
- `test/scoria/adoption_surface_test.exs`, `test/scoria/ai_doc_contract_test.exs` — doc-contract test auto-coverage mechanics
- `test/test_helper.exs` — tag exclusion behavior
- `guides/reference/glossary.md`, `guides/scoria-vs-external-llm-ops.md`, `CHANGELOG.md`, `llms.txt`, `README.md`, `AGENTS.md` — current doc wording
- `deps/req_llm/lib/req_llm/open_telemetry.ex` — `@otel_schema_url`
- `mix.exs` — `req_llm ~> 1.13` pin

No `[CITED]` or `[ASSUMED]` sources were needed beyond the two Assumptions Log items — this research required zero external package/API lookups since the phase adds no new dependencies.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, all modules read directly
- Architecture: HIGH — pipeline order confirmed by reading `telemetry.ex` line-by-line
- Pitfalls: HIGH — each pitfall is a direct quote/citation from adapter source, not inferred
- Doc-contract mechanics: HIGH — every list and test assertion quoted verbatim

**Research date:** 2026-07-18
**Valid until:** Stable indefinitely for the confirmed seams (they are this repo's own SSOT modules, not an external dependency); re-verify only if Phase 54.1 (wiring req_llm/jido adapters at boot) or any future phase changes `Bounds`/`Semconv`/`SpanKind`/`Telemetry` internals before Phase 54 executes.
