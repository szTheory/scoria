# Phase 24: Knowledge lane scope fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 24-knowledge-lane-scope-fix
**Areas discussed:** Selection mechanism, Zero-test safety net, Coverage-preservation proof
**Mode:** advisor (USER-PROFILE.md present; `minimal_decisive` calibration tier, `opinionated` vendor_philosophy; non-technical-owner = false). Two research rounds: (1) ExUnit `--only`/`--exclude` mechanics; (2) deep ecosystem/DX + cross-ecosystem lessons per user request.

---

## Selection mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| `--only knowledge` (tag-based) | Inject `["--only","knowledge" | args]` at `scoria.test.knowledge.ex:19`; auto-includes future `:knowledge` files; keeps the env flag | ✓ |
| Explicit 6-file path list | Pass the 6 known paths; skips loading other files but must be hand-maintained | |

**User's choice:** `--only knowledge`, hardcoded in the task (D-01).
**Notes:** Tag-based is the ExUnit-native idiom for a *category* of tests (vs. path lists for "run one file"); pytest `-m`/RSpec `--tag` agree. Auto-picks up test #7 with zero edits. `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` confirmed still required (un-excludes `:knowledge` before `--only` re-includes it). BEAM-load overhead negligible vs. pgvector bootstrap + migrations. Path-list rejected: brittle + leaves the zero-test guard disarmed.

---

## Zero-test safety net

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on ExUnit built-in guard | Hardcoding `--only` arms ExUnit's non-zero-exit-on-empty; no extra code | ✓ (Layer 1) |
| Add explicit min-count assertion | `after_suite` assertion on top of the built-in guard | ✓ (Layer 2, as `total > 0`) |

**User's choice:** Both layers (D-02) — locked as the full recommendation set.
**Notes:** Built-in guard (armed by D-01's hardcoded `--only`) catches **total** tag loss. Env-gated `after_suite total > 0` in `test_helper.exs` covers what the built-in misses (disarmed filter, future empty `--partitions` shard — Mix documents fail-on-empty for `--only` but not partitions). Use `total > 0`, **not** a count threshold (rot). Cross-ecosystem precedent (Jest/RSpec `fail_if_no_examples`/Go/pytest `--strict-markers`) endorses fail-on-empty. Audit flag: `elixir-lang/elixir#3940` (`:exclude` config can interfere with `--only`).

---

## Coverage-preservation proof (SC#3)

| Option | Description | Selected |
|--------|-------------|----------|
| Automated file-set contract test | Derived `Path.wildcard` set + `use Scoria.KnowledgeCase` assertion, mirroring `adoption_test_files/0` | ✓ |
| Built-in guard + manual log check only | Lean on Layer-1 empty-guard + SC#1 log line-count; no new test | |

**User's choice:** Automated file-set contract test (D-03).
**Notes:** Mirrors the repo's existing `adoption_test_files/0` + `VerificationLanes` contract-test idiom. **Derived** via `Path.wildcard` (not a magic-number count) → ratchet on add/remove. The `use Scoria.KnowledgeCase` assertion makes the file-set a faithful proxy for the tag-set (catches 5-of-6 partial silent loss the empty-guard can't) AND closes D-01's widening footgun (stray `@tag :knowledge` elsewhere). Squarely in the "contract test pays dividends" quadrant (small, stable, coverage-critical set behind one choke point). Optional: pin the lane command string in `verification_lanes_test.exs`.

---

## Claude's Discretion

- Exact placement/wording of the `after_suite` guard and the new contract-test file name (follow repo conventions, `async: true`).
- Whether to add a separate "no OTHER file carries `:knowledge`" guard vs. folding single-choke-point enforcement into the D-03 contract test.

## Deferred Ideas

- `--partitions` zero-shard guarding — relevant for Phase 26 (knowledge-lane sharding); D-02's `after_suite total > 0` provides forward coverage, flagged for Phase 26 to verify.
- No scope creep raised; no matching pending todos surfaced for Phase 24.
