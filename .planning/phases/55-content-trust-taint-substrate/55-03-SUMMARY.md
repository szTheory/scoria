---
phase: 55-content-trust-taint-substrate
plan: 03
subsystem: security
tags: [prompt-injection, spotlighting, datamark, elixir, telemetry, semconv]

requires:
  - phase: 55-01
    provides: "Scoria.Trust leaf vocabulary (tiers/0, default_tier/0, tier/1, tier_key/0) + the Scoria.Trust.Tiered protocol with the Chunk defimpl"
provides:
  - "Scoria.Spotlight.render/2 -- host-called, pure, content-shape-aware spotlighting seam"
  - "Scoria.Spotlight.Marked struct (marked, instruction, technique, tier, marked?, spans)"
  - "Bounds-safe [:scoria, :spotlight, :marked] telemetry event"
  - "Semconv.spotlight_keys/0 + spotlight_attributes/1 projector + scoria.spotlight.* registry keys"
affects: [55-04, 55-05, 57, 58]

tech-stack:
  added: []
  patterns:
    - "Host-called pure function taking data + opts, mirroring Scoria.Orchestrator's public-entry-point shape"
    - "Per-item nonce mint + collision-check + bounded-retry-then-fallback (defeats closing-delimiter injection)"
    - "Instruction-as-data, never-injected-prompt discipline (D-13)"
    - "Fixed-key attribute projector with no host-map spread, mirroring guardrail_attributes/1"

key-files:
  created:
    - lib/scoria/spotlight.ex
    - lib/scoria/spotlight/marked.ex
    - test/scoria/spotlight_test.exs
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "render/2 resolves each item's trust tier via Scoria.Trust.Tiered.tier/1 for structs (dispatch to the Chunk defimpl from Plan 01) and via Scoria.Trust.tier/1 directly for plain maps (reading item[:metadata] or, absent that, the item map itself) -- both paths are fail-closed, so an item Scoria cannot classify resolves untrusted."
  - "The nonce is minted independently per ITEM (not once for the whole render/2 call) so a collision/retry/fallback decision for one item in a batch never affects a sibling item's marking; 'fresh per call' (D-12) is satisfied because nothing is cached or reused across render/2 invocations."
  - "Content-shape detection: an explicit :content_type item hint (:prose | :structured/:json/:code) takes precedence; absent a hint, a heuristic (JSON-decodable -> structured, code-punctuation-density -> structured, multi-word-with-sentence-punctuation -> prose, else ambiguous) decides -- ambiguous never datamarks, per D-12."
  - "The Marked struct's top-level tier/technique are call-level aggregates (tier = \"untrusted\" if ANY item resolved untrusted; technique = the first marked item's technique, or :none if every item was trusted) -- per-item detail always available on spans for a host that needs it."
  - "marked_bytes measures the byte size of the POST-marking (wrapped/interleaved) text, not the original body -- it answers \"how many bytes did marking touch,\" which is what an operator dashboard cares about."

requirements-completed: [TAINT-03]

coverage:
  - id: D1
    description: "Scoria.Spotlight.render/2 + Marked struct: host-called pure function, trusted content passes through byte-identical, content-shape-aware technique selection (datamark/delimit)"
    requirement: "TAINT-03"
    verification:
      - kind: unit
        ref: "test/scoria/spotlight_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nonce mechanics: crypto-random nonce, boundary/marker collision detection, bounded 8-attempt retry then fallback to :delimit -- defeats closing-delimiter injection"
    requirement: "TAINT-03"
    verification:
      - kind: unit
        ref: "test/scoria/spotlight_test.exs#closing-delimiter injection resistance -- marker-collision retry then :delimit fallback (D-12)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The paired instruction is returned as DATA on Marked.instruction, non-empty, host-overridable -- Spotlight never injects a system prompt"
    requirement: "TAINT-03"
    verification:
      - kind: unit
        ref: "test/scoria/spotlight_test.exs#instruction returned as data (D-13)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Bounds-safe [:scoria, :spotlight, :marked] telemetry: counts/enums only, no nonce, no raw/marked text, wrapped try/rescue -> :ok"
    requirement: "TAINT-03"
    verification:
      - kind: unit
        ref: "test/scoria/spotlight_test.exs#bounds-safe telemetry (D-14)"
        status: pass
    human_judgment: false
  - id: D5
    description: "scoria.spotlight.* Semconv registry keys + spotlight_attributes/1 projector + pinned canary test updated in the same commit"
    requirement: "TAINT-03"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#spotlight_attributes/1 fixed-key projection (D-14)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#attribute_registry/0 registry canary (SEC-01 Test 1)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-27
status: complete
---

# Phase 55 Plan 03: Content Trust & Taint Substrate -- Spotlighting Seam Summary

**`Scoria.Spotlight.render/2`: a host-called, content-shape-aware, injection-resistant datamark/delimit spotlighting seam with instruction-as-data and bounds-safe telemetry, plus the registered `scoria.spotlight.*` Semconv attribute keys.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2 (both `auto`, Task 1 `tdd="true"`)
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments

- `Scoria.Spotlight.render(items, opts \\ [])` -- a standalone, host-called pure function mirroring `Scoria.Orchestrator`'s "data in, data out" shape. The host calls it on its own untrusted content BEFORE assembling its own prompt; `Scoria.Spotlight` never sees or owns the host's final prompt string (D-11).
- `Scoria.Spotlight.Marked` -- a plain struct (`marked, instruction, technique, tier, marked?, spans`) returned by `render/2`. `spans` carries per-item detail (`tier, technique, marked, marked?`) so a host working with a mixed-trust/mixed-shape batch can inspect each item individually, while the top-level fields give a call-level summary.
- Fail-closed tier resolution reusing Plan 01's vocabulary: struct items (e.g. `Scoria.Knowledge.Chunk`) dispatch through `Scoria.Trust.Tiered.tier/1`; plain map items read `Scoria.Trust.tier/1` directly off `:metadata` (or the map itself, as a fallback). Trusted content passes through **byte-identical** -- proven by a dedicated test.
- Content-shape-aware technique selection (D-12): an explicit `:content_type` item hint short-circuits detection; absent a hint, prose (JSON-undecodable, low code-punctuation density, multi-word with sentence punctuation) selects `:datamark`; JSON/code selects `:delimit`; anything genuinely ambiguous also selects `:delimit`, never `:datamark`.
- Nonce mechanics: `:crypto.strong_rand_bytes(16) |> Base.encode32(padding: false)`, minted fresh per item, never logged or persisted. Before use, the boundary tokens (and, for `:datamark`, the interleaved marker character) are verified absent from the item's own content; on collision the nonce/marker regenerate, bounded to 8 attempts, then fall back to `:delimit` -- defeating closing-delimiter injection (OWASP LLM01). Proven deterministically with a fixture body containing every candidate marker character.
- `:technique` opt forces `:datamark` / `:delimit` / `:encode` for a whole `render/2` call, overriding auto-detection; `:encode` (base64) is offered but documented as not-recommended and never the default.
- `Marked.instruction` returns the canonical paired system-prompt instruction as DATA, bundled with the marked text so the two cannot drift, host-overridable via the `:instruction` opt. `Scoria.Spotlight` never injects a system prompt and never decides placement (D-13).
- `[:scoria, :spotlight, :marked]` telemetry: exactly one event per `render/2` call, measurements `%{marked_spans, marked_bytes}` (counts) and metadata `%{technique, tier}` (enums) -- structurally incapable of leaking the nonce or raw/marked text -- wrapped `try/rescue -> :ok` (D-14).
- `Semconv.spotlight_keys/0` + `spotlight_attributes/1` -- a fixed four-key projector mirroring `guardrail_attributes/1`'s no-passthrough shape, plus the four `scoria.spotlight.*` registry entries (`technique`/`tier` `:enum`, `marked_spans`/`marked_bytes` `:count`) merged into `attribute_registry/0` so `Scoria.Observe.Bounds` admits rather than silently drops them. The pinned sorted-key canary test was updated in the same commit as the registry edit.
- Moduledoc documents the D-15 residual (a host reading raw `chunk.body` and self-concatenating bypasses `Spotlight` silently) and states plainly that spotlighting is a signal-separator, never "the defense" -- real containment is blast-radius limiting plus the Phase 57 confluence gate.

## Task Commits

1. **Task 1: Scoria.Spotlight.render/2 + Marked struct (technique selection, nonce, instruction-as-data)** -- `141ac341` (feat, tdd)
2. **Task 2: Semconv scoria.spotlight.* registry keys + spotlight_attributes/1 projector + canary update** -- `6df741c5` (feat)

_Task 1's test file and implementation were authored together and verified green before the single atomic commit, per this plan's `type: execute` frontmatter (not `type: tdd`) -- see TDD Gate Compliance note below._

## Files Created/Modified

- `lib/scoria/spotlight.ex` -- `render/2`, per-item tier/body/shape extraction, nonce/boundary marking mechanics, aggregation, bounds-safe telemetry emission.
- `lib/scoria/spotlight/marked.ex` -- the `Marked` struct + typespecs.
- `test/scoria/spotlight_test.exs` -- trusted byte-identity, per-shape technique selection, technique/instruction overrides, marker-collision retry->fallback (deterministic fixture), bounds-safe telemetry payload assertions, mixed-batch aggregation.
- `lib/scoria/observe/semconv.ex` -- `@spotlight_keys`, `spotlight_keys/0`, `spotlight_attributes/1`, and the four `scoria.spotlight.*` registry entries.
- `test/scoria/observe/semconv_test.exs` -- pinned sorted-key canary updated with the four new keys; `spotlight_attributes/1` fixed-key-projection and nil-field-omission tests.

## Decisions Made

- Nonce minted per-item (not once per `render/2` call): each item's collision/retry/fallback outcome is independent, and "fresh per call" (D-12) is satisfied since nothing is cached/reused across invocations of `render/2` itself.
- Content-shape detection heuristic (JSON-decode attempt, code-punctuation density, prose word-count + sentence punctuation) used only when an item doesn't declare an explicit `:content_type` -- keeps the common no-hint case usable while still respecting an explicit host declaration.
- Top-level `Marked.tier`/`Marked.technique` are call-level aggregates (tier = "untrusted" if any item is untrusted; technique = the first marked item's technique, or `:none` if every item was trusted) -- `spans` carries the authoritative per-item detail for a host that needs finer granularity.
- `marked_bytes` measures post-marking (wrapped/interleaved) byte size, not original body size -- reflects how many bytes marking actually touched.

## Deviations from Plan

None -- plan executed exactly as written. All `must_haves.truths` and `must_haves.prohibitions` from the plan frontmatter are satisfied:

- `render/2` is a standalone host-called function; trusted content passes through byte-identical (proven by test).
- Prose/untyped untrusted content selects `:datamark`; structured (JSON/code) and ambiguous content select `:delimit`, never `:datamark`.
- Nonce = `:crypto.strong_rand_bytes(16) |> Base.encode32(padding: false)`, fresh per item, never logged/persisted (`grep -n "Logger\|persist" lib/scoria/spotlight.ex` shows no nonce-adjacent log/persist call).
- Boundary/marker verified absent from content for both `:delimit` and `:datamark`, bounded 8-attempt retry then fallback to `:delimit` -- proven deterministically.
- `render/2` returns the instruction as DATA on `Marked.instruction`, host-overridable; `Scoria.Spotlight` never injects a system prompt or decides placement.
- `[:scoria, :spotlight, :marked]` telemetry carries only counts/enums, wrapped `try/rescue -> :ok`; nonce and raw/marked text are structurally absent from the payload.
- `scoria.spotlight.*` registry keys added to `attribute_registry/0`; the pinned canary test updated in the same commit.
- `:encode` is offered but is NOT the default technique.
- Spotlighting is documented in the moduledoc as a signal-separator, not "the defense."
- The D-15 residual (host raw-`chunk.body` bypass) is documented, not solved.
- No new `SpanKind` value was added; `scoria.spotlight.*` are registry keys on existing spans.

## TDD Gate Compliance

Task 1's test file and implementation were authored together and verified green before the single atomic commit, rather than as separate RED-then-GREEN commits. This satisfies the plan's per-task `tdd="true"` requirement (tests exist, prove the described behavior, and are green) but does not produce a separate `test(...)` commit preceding the `feat(...)` commit in git history. Flagging this per the TDD Gate Compliance convention since this plan's frontmatter is `type: execute` (not `type: tdd`), so the stricter plan-level RED/GREEN/REFACTOR gate sequence does not apply.

## Issues Encountered

- Initial `code_like?/1` heuristic used `~w({ } ( ) ; = < > [ ])`, which mis-parsed because Elixir's `~w()` sigil uses parentheses as its own delimiter -- the literal `(`/`)` characters inside the word list broke the sigil boundary. Fixed by replacing the sigil with an explicit `["{", "}", "(", ")", ";", "=", "<", ">", "[", "]"]` list literal. Caught immediately by `mix compile` before any test run; not a deviation from the plan, just an implementation-syntax correction.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- `Scoria.Spotlight` is additive and self-contained: it only reads `Scoria.Trust`/`Scoria.Trust.Tiered` (Plan 01) and writes to `Semconv`/`Bounds` (existing observe-layer infrastructure) -- no coupling to Plan 55-02 (tool-output envelope) or 55-04 (`scan/2` hook), which run in the same wave.
- `lib/scoria/observe/semconv.ex` is also touched by Plan 55-05 later in the phase; this plan's edits were additive (new `@spotlight_keys`/`spotlight_attributes/1`/registry entries only, no existing key/function changed), so a downstream merge should be a clean textual union rather than a semantic conflict.
- Scoped verification is green: `mix test test/scoria/spotlight_test.exs test/scoria/observe/semconv_test.exs` (56/56 passing), `mix compile --warnings-as-errors` clean.
- No blockers for Phase 57 (the confluence gate) or Phase 58 (the Govern surface rendering `scoria.spotlight.*`) -- both can read the registered attribute keys and the `Marked` struct shape as-is.

---
*Phase: 55-content-trust-taint-substrate*
*Completed: 2026-07-27*

## Self-Check: PASSED

All 5 created/modified files confirmed present on disk (`lib/scoria/spotlight.ex`, `lib/scoria/spotlight/marked.ex`, `test/scoria/spotlight_test.exs`, `lib/scoria/observe/semconv.ex`, `test/scoria/observe/semconv_test.exs`). Both task commits confirmed in `git log` (`141ac341`, `6df741c5`). Scoped test suite green (56/56, `mix test test/scoria/spotlight_test.exs test/scoria/observe/semconv_test.exs`), `mix compile --warnings-as-errors` clean.
