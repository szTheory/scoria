---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
plan: 04
subsystem: observability
tags: [otel-genai, openinference, req_llm, elixir, telemetry]

# Dependency graph
requires:
  - phase: 51-01
    provides: Scoria.Observe.SpanKind (canonical 8-value span_kind taxonomy module)
  - phase: 51-02
    provides: Scoria.Observe.Semconv (openinference_span_kind_key/0, merge_req_llm_attributes/2)
  - phase: 51-03
    provides: Buffer.flush_spans/2 auto-upserted trace FK + loud flush-error surfacing (so spans this adapter emits actually persist)
provides:
  - "Scoria.Observe.Adapters.ReqLLM.handle_event/4 rewritten to emit gen_ai.*/openinference.* keys via Semconv + SpanKind, with the legacy llm.model_name/llm.token_count/req.url keys dropped entirely"
  - "0.1.4 CHANGELOG breaking-change entry (old->new key mapping table + FOUND-01 flush_error/on_flush_error announcement)"
affects: [51-05, 52-retriever-span-and-host-declared-attributes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Adapter-layer attribute construction: base Scoria-domain map (tenant_id/workflow_run_id) merged with Semconv.merge_req_llm_attributes/2, never a hand-written gen_ai.* literal"
    - "Host-override + flat-default span_kind seam: metadata[:span_kind] || \"<adapter's natural kind>\" piped through SpanKind.normalize/2 -- matches the sibling Jido adapter's convention, deliberately avoids reading req_llm's own metadata[:operation] key (different taxonomy: :chat/:embedding/:object, not agent/llm/prompt/...)"

key-files:
  created: []
  modified:
    - lib/scoria/observe/adapters/req_llm.ex
    - test/scoria/observe/adapters/req_llm_test.exs
    - CHANGELOG.md

key-decisions:
  - "span_kind reads metadata[:span_kind] (a host-override seam that is virtually always nil in production, defaulting to \"llm\") rather than metadata[:operation] as PLAN.md/PATTERNS.md literally wrote -- metadata[:operation] is req_llm's OWN telemetry vocabulary (:chat/:embedding/:object, confirmed via deps/req_llm/lib/req_llm/telemetry.ex new_context/3), a different taxonomy than Scoria's 8-value span_kind; reading it as the normalize/2 value would make every real production LLM span silently fall back to the default \"agent\" kind and fire a fallback-telemetry warning on every single call, defeating SPAN-02. Mirrors the Jido sibling adapter's already-established metadata[:span_kind] || \"tool\" override pattern."
  - "CHANGELOG breaking-change content lands inside the file's existing (pre-dated, from Phase 46) '## [Unreleased]' heading as a new '### BREAKING CHANGES' subsection, rather than a second '## [Unreleased]' heading -- keeps one canonical Unreleased section per Keep-a-Changelog convention; the existing terminology-migration prose under it was left untouched (out of this plan's scope)."

patterns-established: []

requirements-completed: [SPAN-01, SPAN-02, COMPAT-01]

coverage:
  - id: D1
    description: "A persisted LLM span carries gen_ai.request.model/.temperature/.top_p/.max_tokens/.seed AND gen_ai.usage.* together, sourced via Semconv.merge_req_llm_attributes/2 (SC#2 -- never a partial subset)"
    requirement: SPAN-01
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/req_llm_test.exs#SPAN-01: gen_ai.* completeness (SC#2 -- never a partial subset)#all four model-config params + a usage key are present together"
        status: pass
    human_judgment: false
  - id: D2
    description: "The ReqLLM adapter sets a native-lowercase span_kind via SpanKind.normalize/2 and a mirrored openinference.span.kind attribute keyed by Semconv.openinference_span_kind_key/0"
    requirement: SPAN-02
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/req_llm_test.exs#SPAN-02: span_kind + mirrored openinference.span.kind#span_kind is native-lowercase \"llm\" and the openinference mirror is UPPERCASE"
        status: pass
    human_judgment: false
  - id: D3
    description: "Legacy keys llm.model_name/llm.token_count/req.url are absent from new span attributes (clean replacement, no dual-emit)"
    requirement: COMPAT-01
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/req_llm_test.exs#COMPAT-01: legacy keys are gone (clean replacement, no dual-emit)#attributes do not contain the old llm.model_name/llm.token_count/req.url keys"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every gen_ai.*/openinference.* key the adapter writes comes from Semconv, never an inline string literal in req_llm.ex"
    requirement: SPAN-01
    verification:
      - kind: unit
        ref: "source assertion: grep -Ec '\"(gen_ai\\.|openinference\\.span\\.kind)\"' lib/scoria/observe/adapters/req_llm.ex == 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "CHANGELOG.md documents the 0.1.4 breaking-change key mapping table (all 3 legacy keys + replacements) and the FOUND-01 flush_error/on_flush_error announcement"
    requirement: COMPAT-01
    verification:
      - kind: cli
        ref: "grep -Eq 'gen_ai.request.model' CHANGELOG.md && grep -Eq 'server.address' CHANGELOG.md && grep -Eq 'flush_error' CHANGELOG.md -> OK"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-12
status: complete
---

# Phase 51 Plan 04: ReqLLM Adapter Key Convention + Span-Kind Rewrite Summary

**`Scoria.Observe.Adapters.ReqLLM` now merges the full `gen_ai.*` attribute set through `Semconv.merge_req_llm_attributes/2`, sets a correct native-lowercase `span_kind` with a mirrored `openinference.span.kind` via `SpanKind`, drops the legacy `llm.model_name`/`llm.token_count`/`req.url` keys entirely, and incidentally fixes the `%LLMDB.Model{}`-struct-in-jsonb bug — shipped with the `0.1.4` CHANGELOG breaking-change entry.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-12T11:20:00-04:00 (approx)
- **Completed:** 2026-07-12T11:27:00-04:00 (approx)
- **Tasks:** 3
- **Files modified:** 3 (1 lib, 1 test, 1 docs)

## Accomplishments
- Rewrote `Scoria.Observe.Adapters.ReqLLM.handle_event/4`: attribute construction now starts from a base Scoria-domain map (`tenant_id`/`workflow_run_id`, non-nil only), merges the req_llm-owned `gen_ai.*` set via `Scoria.Observe.Semconv.merge_req_llm_attributes/2` (delegating wholesale to `ReqLLM.OpenTelemetry.Attributes.start/1`+`.terminal/1`), and mirrors `openinference.span.kind` (from `Semconv.openinference_span_kind_key/0` + `SpanKind.to_openinference/1`) — zero inline `gen_ai.*`/`openinference.*` string literals anywhere in the adapter.
- `span_kind` now comes from `SpanKind.normalize/2` (native lowercase `"llm"` by default, host-overridable via `metadata[:span_kind]`) instead of the hardcoded `"LLM"` literal, fixing the confirmed casing bug (Pitfall 2) where every span silently rendered as the generic `"agent"` UI rail.
- Fixed the incidental second bug (Pitfall 1): `metadata[:model]` — a real `%LLMDB.Model{}` struct in production — is no longer stuffed raw into `attributes`; `ReqLLM.OpenTelemetry.Attributes.request_model/1` (called internally by `Semconv.merge_req_llm_attributes/2`) extracts `.id` for a clean model-id string.
- Rewrote `test/scoria/observe/adapters/req_llm_test.exs` with a realistic `LLMDB.Model.new!/1`-based fixture (replacing the old unrealistic `model: "gpt-4"` string) and 5 named tests split across SPAN-01 (gen_ai.* completeness), SPAN-02 (span_kind + openinference mirror), COMPAT-01 (legacy-key absence), and span-shape/passthrough checks.
- Shipped the `0.1.4` CHANGELOG breaking-change entry: the literal old→new key mapping table (with the `req.url`→`server.address`+`server.port` lossiness and the request-vs-response model split called out explicitly), one upgrade-guide sentence, and the FOUND-01 `[:scoria, :observe, :buffer, :flush_error]`/`:on_flush_error` announcement — no dual-emit/shim language.

## Task Commits

Each task was committed atomically (TDD RED/GREEN for Task 1):

1. **Task 1: Rewrite ReqLLM adapter — Semconv gen_ai.* merge, SpanKind wiring, drop legacy keys** (TDD)
   - `b3eb4dea` (test) — add failing test for gen_ai.* attrs + span_kind + legacy-key absence
   - `2e4ed0da` (feat) — rewrite ReqLLM adapter to Semconv gen_ai.* merge + SpanKind wiring
2. **Task 2: Update req_llm_test.exs — realistic %LLMDB.Model{} fixture + SPAN-01/SPAN-02/COMPAT-01 assertions**
   - `86927f44` (test) — restructure req_llm_test.exs into SPAN-01/SPAN-02/COMPAT-01 describe blocks
3. **Task 3: CHANGELOG 0.1.4 breaking-change entry (COMPAT-01 mapping + FOUND-01 announcement)**
   - `701bdd86` (docs) — add 0.1.4 breaking-change entry for ReqLLM key rename + flush_error

**Plan metadata:** (final docs commit, see below)

## Files Created/Modified
- `lib/scoria/observe/adapters/req_llm.ex` — rewritten attribute + span-map construction; `Semconv`/`SpanKind` aliases added; legacy keys dropped.
- `test/scoria/observe/adapters/req_llm_test.exs` — realistic `%LLMDB.Model{}` fixture, 5 tests across span-shape/SPAN-01/SPAN-02/COMPAT-01.
- `CHANGELOG.md` — `0.1.4` breaking-change entry inside the existing `## [Unreleased]` section.

## Decisions Made
- **span_kind override key (Rule 1 auto-fix vs. literal plan text):** `PLAN.md`/`51-PATTERNS.md` both literally wrote `SpanKind.normalize(metadata[:operation] || "llm")`. Direct source confirmation (`deps/req_llm/lib/req_llm/telemetry.ex` `new_context/3`) shows `metadata[:operation]` is req_llm's OWN always-present telemetry field (`:chat`/`:embedding`/`:object` — defaulting to `:chat`), a completely different taxonomy from Scoria's 8-value `span_kind`. Reading it literally as the `normalize/2` *value* would mean every real production LLM span fails `SpanKind.kind?/1` and silently falls back to the default `"agent"` kind (plus fires the fallback-telemetry warning on every single call) — directly defeating SPAN-02's "every span carries a correct span_kind" requirement and the plan's own stated test behavior (`span_kind == "llm"`). Implemented `metadata[:span_kind] || "llm"` instead — mirroring the already-implemented Jido sibling adapter's `metadata[:span_kind] || "tool"` host-override convention (per `51-PATTERNS.md`'s Jido section and CONTEXT.md's note that Jido "dropped the action-name classifier in favor of host-declared override + flat default"). This produces the correct, always-"llm" behavior for req_llm.ex while preserving a real host-override seam and matching the sibling adapter's shape.
- **CHANGELOG placement:** the repo's `CHANGELOG.md` already has a `## [Unreleased]` heading (added in Phase 46-08 for terminology-migration prose, left in place beneath the auto-generated `## [0.1.3]` section by release-please's own PR flow — a pre-existing file-structure quirk out of this plan's scope to fix). Added the new breaking-change content as a `### ⚠ BREAKING CHANGES (0.1.4 cut)` subsection at the top of that existing `## [Unreleased]` heading rather than creating a second `## [Unreleased]` heading, keeping one canonical section per Keep-a-Changelog convention.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `span_kind` normalize source: `metadata[:span_kind]` instead of the plan-literal `metadata[:operation]`**
- **Found during:** Task 1 (TDD RED — writing the failing test per the plan's stated behavior `span_kind == "llm"`)
- **Issue:** The plan's `<action>` text and `51-PATTERNS.md` both specify `SpanKind.normalize(metadata[:operation] || "llm")`. `metadata[:operation]` is confirmed (via direct read of `deps/req_llm/lib/req_llm/telemetry.ex`) to always be a req_llm-domain atom (`:chat`/`:embedding`/`:object`), never one of Scoria's 8 canonical span kinds — so implementing the plan literally would make `SpanKind.normalize/2` fall back to `"agent"` on every real production call, breaking SPAN-02.
- **Fix:** Used `metadata[:span_kind] || "llm"` — a host-override seam (nil in all current real callers, so always resolves cleanly to `"llm"`) — matching the already-established Jido sibling-adapter convention.
- **Files modified:** `lib/scoria/observe/adapters/req_llm.ex`
- **Verification:** `test/scoria/observe/adapters/req_llm_test.exs` SPAN-02 test (`span_kind is native-lowercase "llm"...`) passes; regression suite (`test/scoria/observe/`, 76 tests) green.
- **Committed in:** `2e4ed0da` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (Rule 1, adapter source — a genuine correctness bug in the literal plan text, not the executor's own introduced error).

## Issues Encountered

Full-suite `mix test` (1159 tests + 3 doctests) reported `1 failure` — re-confirmed as the exact same pre-existing, environment-dependent flake already logged under Plan 51-03 in `deferred-items.md` (`test/scoria/warning_inventory/capture_parity_test.exs`, passes standalone, only fails under full-suite parallel subprocess isolation, zero relationship to `lib/scoria/observe/adapters/*`). Logged a Plan 51-04 recurrence note in `deferred-items.md`; not fixed (out of this plan's scope boundary). This plan's own verification lanes are all green:
- `mix test test/scoria/observe/adapters/req_llm_test.exs` — 5 tests, 0 failures
- `mix test test/scoria/observe/adapters/req_llm_test.exs test/scoria/observe/` (regression) — 76 tests, 0 failures
- CHANGELOG grep gate — `OK`

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- SPAN-01, SPAN-02, and COMPAT-01 are complete for the ReqLLM adapter. Combined with Plan 51-03's FK fix, a span emitted through `Scoria.Observe.Adapters.ReqLLM` now both persists correctly and carries the full OTel-GenAI/OpenInference key convention.
- Plan 51-05 (the sibling `jido.ex` adapter rewrite) can now proceed using the same `Semconv`/`SpanKind` wiring pattern and the corrected `metadata[:span_kind] || "<default>"` host-override convention confirmed here.
- No blockers.

---
*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files (`lib/scoria/observe/adapters/req_llm.ex`, `test/scoria/observe/adapters/req_llm_test.exs`, `CHANGELOG.md`, this SUMMARY.md) verified present on disk; all 4 task commit hashes (`b3eb4dea`, `2e4ed0da`, `86927f44`, `701bdd86`) verified present in `git log`.
