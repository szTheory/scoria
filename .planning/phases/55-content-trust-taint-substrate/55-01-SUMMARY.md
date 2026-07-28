---
phase: 55-content-trust-taint-substrate
plan: 01
subsystem: knowledge
tags: [trust, taint, elixir, ecto, protocol, jsonb, tenant-isolation]

requires: []
provides:
  - "Scoria.Trust leaf vocabulary (tiers/0, default_tier/0, tier_key/0, normalize_tier/1, tier/1, trusted?/1, put_tier/2)"
  - "Scoria.Trust.Tiered protocol (first defprotocol in the repo) + Chunk defimpl"
  - "Source.metadata[\"scoria.trust.tier\"] storage convention, denormalized onto Chunk.metadata at ingest"
  - "Knowledge.create_source/2 and Knowledge.ingest_source/2 trust: host-override opt"
  - "Knowledge.set_source_trust/3 post-hoc tenant-scoped bulk trust update"
  - "Knowledge.reembed_source/2 and reindex_source/2 trust idempotency (derive from stored Source.metadata)"
affects: [55-02, 55-03, 55-04, 56, 57]

tech-stack:
  added: []
  patterns:
    - "Fail-closed two-branch reader (silent-absent vs logged-junk), mirroring Semconv.normalize_reason_code/1"
    - "Protocol-with-defimpl-in-owning-module to avoid a compile cycle (D-23)"
    - "jsonb metadata denormalization at write-time to avoid a join on the read hot path"
    - "Tenant-scoped bulk jsonb merge update via fragment(\"? || ?\", col, type(^map, :map))"

key-files:
  created:
    - lib/scoria/trust.ex
    - lib/scoria/trust/tiered.ex
    - test/scoria/trust_test.exs
    - test/scoria/knowledge/trust_test.exs
  modified:
    - lib/scoria/knowledge.ex
    - lib/scoria/knowledge/chunk.ex
    - lib/scoria/knowledge/source.ex

key-decisions:
  - "normalize_tier/1 treats EVERY non-member value (including nil) as junk requiring fallback telemetry, unlike tier/1's silent-absent branch — there is no legitimate 'absent override' case at that call site (D-03)."
  - "The map-attrs ingest_source/2 composed path strips :trust from opts before delegating to the internal %Source{} clause, so a first-create trust: override is applied exactly once (on create_source) instead of double-writing Source.metadata and double-firing fallback telemetry on a junk value."
  - "Chunk-metadata bulk writes (set_source_trust/3, reembed/reindex preservation) use a Postgres jsonb merge (`fragment(\"? || ?\", chunk.metadata, type(^partial, :map))`) rather than overwriting the whole metadata column, preserving any other keys a chunk's metadata may carry."

requirements-completed: [TAINT-01]

coverage:
  - id: D1
    description: "Scoria.Trust leaf vocabulary with fail-closed reader (silent-absent, logged-junk, exact-match trusted/untrusted)"
    requirement: "TAINT-01"
    verification:
      - kind: unit
        ref: "test/scoria/trust_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scoria.Trust.Tiered protocol with Chunk defimpl, no Knowledge<->Trust compile cycle"
    requirement: "TAINT-01"
    verification:
      - kind: unit
        ref: "test/scoria/trust_test.exs#Scoria.Trust.Tiered protocol"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "ingest_source/2 denormalizes Source.metadata trust tier onto every chunk at ingest, retrieve reads with no Source join"
    requirement: "TAINT-01"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/trust_test.exs#ingest_source/2 -> Chunk.metadata trust denormalization (D-04)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Host-override trust API: create_source/ingest_source trust: opt fails closed through normalize_tier/1; set_source_trust/3 bulk-updates chunks tenant-scoped"
    requirement: "TAINT-01"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/trust_test.exs#host-override trust API (D-05)"
        status: pass
    human_judgment: false
  - id: D5
    description: "reembed_source/2 and reindex_source/2 are idempotent w.r.t. trust — never revert a declared tier to untrusted"
    requirement: "TAINT-01"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/trust_test.exs#reembed_source/2 and reindex_source/2 trust idempotency (D-04 red-team fix)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-27
status: complete
---

# Phase 55 Plan 01: Content Trust Substrate Summary

**`Scoria.Trust` fail-closed binary tier vocabulary + `Trust.Tiered` protocol + Source-to-Chunk jsonb trust denormalization, with a host-override API and reembed/reindex idempotency, all landed end-to-end through `Knowledge.ingest_source/2`.**

## Performance

- **Duration:** ~10 min
- **Tasks:** 3 (1 tracer, 2 auto), all TDD
- **Files modified:** 7 (3 created, 4 modified — `lib/scoria/knowledge.ex` touched across all 3 tasks)

## Accomplishments

- `Scoria.Trust` — a dependency-free leaf module owning the closed binary tier enum (`~w(trusted untrusted)`), `default_tier/0` = `"untrusted"`, `tier_key/0` = `"scoria.trust.tier"`, the fail-closed reader `tier/1` (silent-absent vs logged-junk, mirroring `Semconv.normalize_reason_code/1`), `normalize_tier/1`, `trusted?/1`, and `put_tier/2`.
- `Scoria.Trust.Tiered` — the first `defprotocol`/`defimpl` pair in the codebase, with the `Chunk` impl living in `lib/scoria/knowledge/chunk.ex` (the owning module) rather than in `Trust` itself, per D-23's leaf-discipline design.
- `Source.metadata["scoria.trust.tier"]` is now the documented storage convention (no new Ecto column); `Knowledge.ingest_source/2` denormalizes it onto every created chunk's own `metadata` at ingest, so `retrieve/2` and any other reader resolves trust with **no `Source` join** on the hot path.
- Host-override API: `create_source(attrs, trust: "trusted")`, `ingest_source(attrs, trust: "trusted")`, and post-hoc `set_source_trust(source, tier, scope: scope)` — the last bulk-updates existing chunk rows scoped by BOTH `source_id` and `tenant_id`, mirroring the existing tenant-scoped `Multi.delete_all` at `ingest_source/2`. Every override value routes through `Trust.normalize_tier/1`, so a typo fails closed to `"untrusted"` + fallback telemetry, never minting a bogus-trusted row.
- `reembed_source/2` (and `reindex_source/2` via delegation) now derive chunk trust from the **stored** `Source.metadata` value before re-embedding, so a re-embed cycle is idempotent w.r.t. trust and never silently reverts a host's declared tier back to `"untrusted"`.

## Task Commits

1. **Task 1: Trust leaf vocab + Tiered protocol + Source→Chunk denormalization end-to-end** — `6adfa94d` (feat, tracer/tdd)
2. **Task 2: Host-override trust API (create_source / ingest_source trust opt + set_source_trust/3)** — `94400ed6` (feat, tdd)
3. **Task 3: reembed/reindex trust idempotency (derive from stored Source.metadata)** — `77dcf413` (feat, tdd)

_All three tasks landed test + implementation together in a single commit each (tests were written alongside the implementation and both were green before committing — see TDD Gate Compliance note below)._

## Files Created/Modified

- `lib/scoria/trust.ex` — the leaf trust vocabulary module.
- `lib/scoria/trust/tiered.ex` — the `Scoria.Trust.Tiered` protocol.
- `lib/scoria/knowledge/chunk.ex` — added the `defimpl Scoria.Trust.Tiered, for: Scoria.Knowledge.Chunk` block.
- `lib/scoria/knowledge/source.ex` — documented the `metadata["scoria.trust.tier"]` storage convention in the moduledoc.
- `lib/scoria/knowledge.ex` — `ingest_source/2` chunk-attrs denormalization; `trust:` opt on `create_source/2` and `ingest_source/2`; new `set_source_trust/3`; `reembed_source/2` trust-preservation step (used by `reindex_source/2` via delegation).
- `test/scoria/trust_test.exs` — leaf unit tests (no DB), covers fail-closed reader, normalize/put_tier, and the `Tiered` protocol dispatch.
- `test/scoria/knowledge/trust_test.exs` — `Scoria.KnowledgeCase` integration tests covering ingest→retrieve denormalization, host-override + tenant isolation, and reembed/reindex idempotency.

## Decisions Made

- `normalize_tier/1` treats every non-member value (including `nil`) as junk requiring fallback telemetry — unlike `tier/1`'s silent-absent branch, there is no legitimate "absent override" case at a host-override call site (D-03 applied consistently).
- The map-attrs `ingest_source/2` composed path (`create_source` then `ingest_source(%Source{}, ...)`) strips `:trust` from `opts` before the internal delegation, so a first-create `trust:` override is applied exactly once — avoiding a redundant Source-row UPDATE and a duplicate fallback-telemetry emission when the override value is junk.
- Bulk chunk-metadata writes (`set_source_trust/3`, and the reembed/reindex trust-preservation step) use a Postgres jsonb merge (`fragment("? || ?", chunk.metadata, type(^partial_map, :map))`) rather than overwriting the whole `metadata` column outright, so any other keys a chunk's metadata may carry survive the update.

## Deviations from Plan

None — plan executed exactly as written. All `must_haves.truths` and `must_haves.prohibitions` from the plan frontmatter are satisfied:

- Absent-key reads `"untrusted"` silently (no log, no telemetry) — proven in `test/scoria/trust_test.exs`.
- Present-but-junk reads `"untrusted"` + `Logger.warning` + `[:scoria, :trust, :fallback]` telemetry — proven in both test files.
- Only the exact string `"trusted"` reads trusted.
- `Scoria.Trust` is a dependency-free leaf (`grep -n "alias Scoria.Knowledge\|alias Scoria.MCP\|alias Scoria.Observe" lib/scoria/trust.ex` returns nothing).
- `Scoria.Trust.Tiered` dispatches on struct type via the `Chunk` impl living in `Knowledge.Chunk`, not in `Trust`.
- `ingest_source/2` denormalizes `Source.metadata` onto every `Chunk.metadata`; `retrieve/2` reads it with no `Source` join (chunks are read directly from `ai_knowledge_chunks` rows carrying their own persisted `metadata`).
- `reembed_source/2`/`reindex_source/2` derive chunk trust from stored `Source.metadata`, never reverting a declared tier — proven by a dedicated regression test.
- `set_source_trust/3` bulk-updates chunk rows scoped by `source_id` AND `tenant_id`, never cross-tenant — proven with a manually-inserted same-`source_id`-different-`tenant_id` chunk row that is asserted untouched after the flip.
- A host typo in a `trust:` override fails closed to `"untrusted"` + telemetry.
- No third/graded trust tier exists — the enum is the closed binary set `~w(trusted untrusted)`.
- No new Ecto column and no new `SpanKind` value were added — trust lives entirely in existing jsonb `metadata` fields.

## TDD Gate Compliance

Each task's test file and implementation were authored together and verified green before the single atomic commit for that task, rather than as separate RED-then-GREEN commits. This satisfies the plan's per-task `tdd="true"` requirement (tests exist, prove the described behavior, and are green) but does not produce a separate `test(...)` commit preceding each `feat(...)` commit in git history. Flagging this per the TDD Gate Compliance convention since this plan's frontmatter is `type: execute` (not `type: tdd`), so the stricter plan-level RED/GREEN/REFACTOR gate sequence does not apply — task-level `tdd="true"` was satisfied by test-and-implementation co-authorship + passing verification, not by commit-order gating.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The `Scoria.Trust` / `Scoria.Trust.Tiered` vocabulary this plan establishes is the foundation Wave 2 plans (55-02 tool-output envelope, 55-03 spotlighting, 55-04 scan hook + trace tagging) build on directly, per the phase's stated dependency structure.
- `lib/scoria/trust.ex` was deliberately kept additive-friendly (a closed-but-simple leaf module) so plan 55-04's later scan-engine surface extension does not require restructuring it.
- No blockers. Scoped verification (`mix test test/scoria/trust_test.exs test/scoria/knowledge/trust_test.exs`) is green (26/26), and `mix compile --warnings-as-errors` is clean.

---
*Phase: 55-content-trust-taint-substrate*
*Completed: 2026-07-27*

## Self-Check: PASSED

All 7 created/modified files confirmed present on disk (`lib/scoria/trust.ex`, `lib/scoria/trust/tiered.ex`, `lib/scoria/knowledge.ex`, `lib/scoria/knowledge/chunk.ex`, `lib/scoria/knowledge/source.ex`, `test/scoria/trust_test.exs`, `test/scoria/knowledge/trust_test.exs`). All 3 task commits confirmed in `git log` (`6adfa94d`, `94400ed6`, `77dcf413`). Scoped test suite green (26/26, `mix test test/scoria/trust_test.exs test/scoria/knowledge/trust_test.exs`), `mix compile --warnings-as-errors` clean.
