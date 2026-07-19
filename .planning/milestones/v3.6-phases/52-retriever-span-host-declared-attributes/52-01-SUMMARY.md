---
phase: 52-retriever-span-host-declared-attributes
plan: 01
subsystem: observability
tags: [elixir, otel-genai, openinference, semconv, telemetry]

# Dependency graph
requires:
  - phase: 51-req-llm-peer-and-span-kind-taxonomy
    provides: "Scoria.Observe.Semconv single-origin key-string module (openinference_span_kind_key/0, merge_req_llm_attributes/2) and the SpanKind normalize/to_openinference vocabulary this plan extends"
provides:
  - "Scoria.Observe.Semconv.retrieval_config_keys/0 and retrieval_config_attributes/1 (RETR-02 scoria.retrieval.* keys with none-sentinel-never-nil projection)"
  - "Scoria.Observe.Semconv.host_declared_keys/0 and merge_host_declared/2 (ATTR-01 bare feature/route/archetype/intent seam, shared by RETRIEVER, prompt, and adapter spans)"
  - "Scoria.Observe.Semconv.prompt_context_key/0 and prompt_context/1 (ATTR-02 scoria.prompt.context never-text id/tokens-only projection with 100-item cap + truncated marker)"
  - "19 drift-guard tests (canary, sentinel, never-default, byte-for-byte pass-through, never-text structural, cap, anti-inline grep) proving single-origin key ownership"
affects: [52-03-emitters, 52-04-retrieve-integration, 52-05-adapter-wiring, 52-06-closeout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "module-attribute constant + @doc + @spec + thin function shape (mirrors openinference_span_kind_key/0 / merge_req_llm_attributes/2)"
    - "sentinel-never-nil projection for optional config maps (\"none\" instead of nil/omission)"
    - "Enum.reduce skip-nil seam for optional host-declared metadata (absent-if-omitted, never defaulted)"
    - "structural allow-list projection (only %{\"id\" =>, \"tokens\" =>}) to prevent raw host data from reaching a span"
    - "anti-inline grep guard: refute a reserved key literal in any lib consumer file except the owning semconv.ex"

key-files:
  created: []
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "Followed PATTERNS.md's three-sibling-family factoring (not one generic projection) per RESEARCH.md Recommendation 4 — retrieval_config, host_declared, and prompt_context each own their own key(s) and projection function."
  - "prompt_context/1 builds the value only; omit-when-empty is explicitly left to the emitter (52-03), documented in the @doc per D-ATTR02-7."
  - "Anti-inline grep guards read lib/scoria/knowledge.ex, lib/scoria/observe.ex (File.exists?-filtered since it doesn't exist until 52-03), lib/scoria/observe/adapters/req_llm.ex, and lib/scoria/observe/adapters/jido.ex — scoped to lib consumer files only, not semconv.ex or the test file itself."

patterns-established:
  - "Sentinel-never-nil projection: retrieval_config_attributes/1 always emits all three dotted keys with \"none\" replacing nil/absent, never omitting or nulling a key."
  - "Skip-nil host-declared seam: merge_host_declared/2 is the single reusable function every span builder and adapter calls instead of hand-rolling a reduce."
  - "Never-text structural allow-list: prompt_context/1 rebuilds each item from scratch (%{\"id\" =>, \"tokens\" =>}) rather than filtering/rejecting keys on the host's raw map, so no future host field can leak through by omission of a denylist entry."

requirements-completed: [RETR-02, ATTR-01, ATTR-02]

coverage:
  - id: D1
    description: "Semconv.retrieval_config_keys/0 + retrieval_config_attributes/1 — RETR-02 config keys always emit all three dotted scoria.retrieval.* keys with a \"none\" sentinel, never nil"
    requirement: "RETR-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#retrieval_config_keys/0 + retrieval_config_attributes/1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Semconv.host_declared_keys/0 + merge_host_declared/2 — ATTR-01 bare feature/route/archetype/intent seam skips absent host keys entirely (never defaults)"
    requirement: "ATTR-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#host_declared_keys/0 + merge_host_declared/2"
        status: pass
    human_judgment: false
  - id: D3
    description: "Semconv.prompt_context_key/0 + prompt_context/1 — ATTR-02 never-text id/tokens-only context-pack projection with ≤100-item cap and truncated marker"
    requirement: "ATTR-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#prompt_context_key/0 + prompt_context/1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Anti-inline grep guards prove each reserved key family (scoria.retrieval.*, feature/route/archetype/intent, scoria.prompt.context) is inlined only in semconv.ex, not in any lib consumer file"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs — anti-inline grep tests in all three new describe blocks"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 01: Semconv Retrieval-Config, Host-Declared, and Prompt-Context Projections Summary

**Extended `Scoria.Observe.Semconv` with three sibling key-string-owning projection families (retrieval-config, host-declared, prompt-context) plus 19 drift-guard tests proving single-origin key ownership across the codebase.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-12T19:22:00Z (approx.)
- **Completed:** 2026-07-12T19:28:13Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- `Semconv.retrieval_config_keys/0` and `retrieval_config_attributes/1` give RETR-02 a single origin for the three `scoria.retrieval.*` keys, with the `"none"` sentinel-never-nil guarantee proven by a canary + sentinel test.
- `Semconv.host_declared_keys/0` and `merge_host_declared/2` give ATTR-01 the single reusable skip-nil seam that the RETRIEVER span, the prompt span, and both adapters will all call — proven never-default (`refute Map.has_key?` on empty metadata) and byte-for-byte pass-through.
- `Semconv.prompt_context_key/0` and `prompt_context/1` give ATTR-02 a structurally never-text context-pack builder — every chunk/memory item is rebuilt from scratch as `%{"id" =>, "tokens" =>}` only, so no raw host field (`text`/`content`/`body`) can reach a span even if the host over-shares. Cap-and-truncate behavior (≤100 items, `"truncated" => true`) is proven with a 101-item fixture.
- Anti-inline grep guards (one per key family) assert the reserved key literals appear nowhere in `lib/scoria/knowledge.ex`, `lib/scoria/observe.ex` (not yet created), `lib/scoria/observe/adapters/req_llm.ex`, or `lib/scoria/observe/adapters/jido.ex` — structurally proving single-origin ownership ahead of the sibling plans (52-03/04/05) that will wire these functions in.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add retrieval-config projection (RETR-02 keys + sentinel)** - `e7ecb7b7` (feat)
2. **Task 2: Add host-declared seam (ATTR-01 bare keys + merge)** - `91fafc96` (feat)
3. **Task 3: Add prompt-context builder (ATTR-02 never-text) + anti-inline grep guards** - `2cf4ab78` (feat)

**Plan metadata:** (recorded in this commit's follow-up)

## Files Created/Modified
- `lib/scoria/observe/semconv.ex` - Added `retrieval_config_keys/0`, `retrieval_config_attributes/1`, `host_declared_keys/0`, `merge_host_declared/2`, `prompt_context_key/0`, `prompt_context/1`; updated moduledoc to state these are implemented.
- `test/scoria/observe/semconv_test.exs` - Added 3 new `describe` blocks (13 new tests) covering canary, sentinel/never-default/pass-through, never-text structural guard, cap behavior, and anti-inline grep for all three new key families.

## Decisions Made
- Kept the three key families as separate sibling functions rather than one generic projection (RESEARCH.md Recommendation 4 / Claude's Discretion in 52-CONTEXT.md) — each family has a distinct shape (keyword-list-of-strings vs. atom-list vs. single-string-key) that doesn't factor cleanly into one generic helper without losing the exact per-family guarantees (sentinel vs. skip-nil vs. structural-rebuild).
- `prompt_context/1` intentionally does not implement omit-when-empty (D-ATTR02-7) — that decision belongs to the emitter built in 52-03, which will decide whether to attach the built value to a span at all. Documented explicitly in the function's `@doc`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. `mix compile --warnings-as-errors --force` is clean, `mix test test/scoria/observe/semconv_test.exs` is 19/19 green, and `mix test test/scoria/observe/` (full observe suite, no regression) is 93/93 green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Semconv.retrieval_config_attributes/1`, `Semconv.merge_host_declared/2`, and `Semconv.prompt_context/1` are ready for 52-03 (`emit_retriever_span/1`, `emit_prompt_span/1`), 52-04 (`Knowledge.retrieve/2` wiring), and 52-05 (adapter wiring) to call.
- No blockers. The anti-inline grep tests will start exercising real content once `lib/scoria/observe.ex` exists (52-03) and the adapters are edited (52-05) — until then they pass vacuously against the current adapter/knowledge source, which is expected and correct.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: lib/scoria/observe/semconv.ex
- FOUND: test/scoria/observe/semconv_test.exs
- FOUND commit: e7ecb7b7
- FOUND commit: 91fafc96
- FOUND commit: 2cf4ab78
