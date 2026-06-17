# Phase 24: Knowledge lane scope fix - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

The CI knowledge verification lane runs **only** its `:knowledge`-tagged tests instead
of re-running the entire suite, reclaiming ~22 min with zero coverage loss and an
unchanged merge bar.

**The actual bug (confirmed in code):** `lib/mix/tasks/scoria.test.knowledge.ex:19` is a
bare `Mix.Task.run("test", args)`. Combined with `SCORIA_TEST_INCLUDE_KNOWLEDGE=true`
(set at line 11), this *un-excludes* `:knowledge` and runs the **whole suite + knowledge
tests** — the ~22 min re-run. The fix scopes that inner `mix test` invocation.

**Locked by ROADMAP success criteria (do not relitigate):**
1. Lane runs only the 6 knowledge-tagged files (via `--only knowledge`) — log line-count drops from full-suite re-run to scoped set.
2. Same warnings-as-errors bar; literal `mix test.knowledge --warnings-as-errors` contract string in `ci-verify.yml` is **unchanged** → the filter is injected **inside the mix task**, never in YAML.
3. Knowledge coverage preserved: every knowledge-tagged test that ran before still runs.
4. `ci_policy_contract_test` + `verification_lanes_test` stay green.

**In scope:** the inner test invocation of the knowledge mix task; a fail-loud zero-test
guard; an automated coverage-preservation contract test. **Out of scope:** lane
parallelization (Phase 25), partition sharding (Phase 26), the fixed-host-port Postgres
flake (Phase 27) — even though research touches `--partitions` interactions.

</domain>

<decisions>
## Implementation Decisions

All three decisions interlock and were locked after two research rounds (ExUnit
mechanics + ecosystem/DX). They are mutually reinforcing — see "coherence" note at end.

### D-01 — Selection mechanism: `--only knowledge`, hardcoded in the task
- Change `scoria.test.knowledge.ex:19` from `Mix.Task.run("test", args)` to
  `Mix.Task.run("test", ["--only", "knowledge" | args])`.
- **Filter first, `args` appended** — lets callers still pass `--seed`, `--max-failures`,
  `file:line` without fighting the tag filter or creating path/path conflicts.
- Tag-based (not an explicit file list): ExUnit-native idiom for a *category* of tests;
  auto-includes any future `use Scoria.KnowledgeCase` file (least surprise for a
  contributor adding knowledge test #7); single choke point = the `:knowledge` tag.
- **Keep `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` (line 11) — STILL REQUIRED, not redundant.**
  It stops `test/test_helper.exs:14` from pre-excluding `{:knowledge, true}` at
  `ExUnit.start` before `--only` can re-include it. Verified: `--only knowledge` →
  `exclude: [:test]` + `include: [knowledge: true]`; includes evaluated before excludes.
- Rejected: explicit 6-path list — brittle to renames/moves, silently shrinks coverage
  on a stale path, and (critically) leaves the zero-test guard disarmed (see D-02).

### D-02 — Zero-test safety net: both layers (≈6 lines, NO magic-number threshold)
- **Layer 1 (built-in, free):** hardcoding `--only` in D-01 *arms* ExUnit's built-in
  guard — an empty `--only` exits non-zero ("The --only option was given to mix test but
  no test was executed"). Fires through the custom-task wrapper because
  `Mix.Task.recursing?()` is false (non-umbrella). Catches **total** tag loss.
- **Layer 2 (belt-and-suspenders):** add an env-gated `ExUnit.after_suite/1` in
  `test_helper.exs` asserting `total > 0` (only arms when
  `SCORIA_TEST_INCLUDE_KNOWLEDGE == "true"`, so the default `mix test` run never trips
  it). Use `total > 0` — **NOT** a count threshold (threshold rot → false-greens when too
  low / false-reds when stale). Covers cases Layer 1 misses: a disarmed filter, and a
  future empty `--partitions` shard (Phase 26 sharding) — Mix does **not** document a
  zero-shard fail guarantee for `--partitions`, only for `--only`.
- Exit via `exit({:shutdown, 1})` to mirror ExUnit's own failure mechanism.

### D-03 — Coverage-preservation proof (SC#3): derived file-set contract test
- New `test/scoria/knowledge_lane_contract_test.exs` mirroring the repo's existing
  `test/mix/tasks/test.adoption_test.exs` (`adoption_test_files/0`) precedent and the
  `Scoria.VerificationLanes` contract-test idiom.
- Expose `knowledge_test_files/0` **derived via `Path.wildcard`** over the two known
  locations (`test/scoria/knowledge_test.exs` + `test/scoria/knowledge/**/*_test.exs`) —
  **not** a hardcoded count. Assert the sorted set == the 6 known files (ratchet:
  add/remove a knowledge file → loud, reviewable one-line diff).
- **AND** assert each file `=~ "use Scoria.KnowledgeCase"`. This does double duty:
  (a) makes the file-set a *faithful proxy* for the tag-set → catches the **5-of-6
  partial silent loss** that Layer 1's empty-guard structurally cannot; (b) neutralizes
  D-01's one footgun — a stray `@tag :knowledge`/`@moduletag :knowledge` elsewhere
  silently *widening* the lane (enforce the single choke point).
- Optional: pin the `:knowledge` lane command string (`mix test.knowledge`) in
  `verification_lanes_test.exs` so the lane-shape layer also reflects the scope change.

### Claude's Discretion
- Exact placement/wording of the `after_suite` guard and the contract-test file name —
  follow existing repo conventions (`async: true` like its siblings).
- Whether to also add the optional grep-guard CI step vs. folding the single-choke-point
  enforcement entirely into the D-03 contract test (the `use Scoria.KnowledgeCase`
  assertion already covers the known files; planner decides if a "no OTHER file carries
  the tag" assertion is worth adding).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope / requirements
- `.planning/ROADMAP.md` §"Phase 24: Knowledge lane scope fix" — goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — KNOW-01 (the single requirement this phase satisfies).
- `.planning/PROJECT.md` §"Current Milestone: v3.1 CI/CD Velocity" — hard constraint:
  preserve/strengthen the verification bar; single fast PR+main gate (no nightly tier).
- `prompts/sztheory-elixir-dna.md` — engineering DNA the recommendations align with
  (operator-first DX, automation over manual, robust CI/CD, idiomatic Elixir, least
  surprise, don't over-engineer).

### Files this phase touches / models on
- `lib/mix/tasks/scoria.test.knowledge.ex` — the task to change (line 19; keep line 11 env).
- `test/test_helper.exs` — `:knowledge` exclude logic (line 14); home for the D-02
  `after_suite` guard; **audit for `elixir-lang/elixir#3940`** (an `:exclude` set in
  `ExUnit.configure`/`start` can interfere with `--only`).
- `test/support/knowledge_case.exs` — single `@moduletag :knowledge` choke point.
- `.github/workflows/ci-verify.yml:188` — `mix test.knowledge --warnings-as-errors`
  (contract string — must stay unchanged).
- `lib/scoria/verification_lanes.ex` (`:knowledge` lane, ~lines 54–62) +
  `test/scoria/verification_lanes_test.exs` + `test/scoria/ci_policy_contract_test.exs`
  — the contract-test pattern D-03 slots into; must stay green (SC#4).
- `lib/mix/tasks/test.adoption.ex` + `test/mix/tasks/test.adoption_test.exs` — the
  `adoption_test_files/0` precedent D-03 mirrors.

The 6 `:knowledge`-tagged files: `test/scoria/knowledge_test.exs`,
`test/scoria/knowledge/{retrieval,citation_formatter,scrypath,grounding,pgvector}_test.exs`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`adoption_test_files/0` + `test.adoption_test.exs`** — exact precedent for exposing a
  test-file accessor from a mix task and asserting the set in a contract test (D-03).
- **`Scoria.VerificationLanes` + `ci_policy_contract_test`/`verification_lanes_test`** —
  established "CI invariant as ExUnit test" pattern; D-03's lane assertion fits here.
- **`Scoria.KnowledgeCase`** (`test/support/knowledge_case.exs`) — single `using` block
  that applies `@moduletag :knowledge` to all 6 files; the choke point D-01/D-03 rely on.

### Established Patterns
- **Env-flag-gated test behavior** — `test_helper.exs` already toggles excludes on
  `SCORIA_TEST_INCLUDE_KNOWLEDGE` / `SCORIA_TEST_INCLUDE_REGISTRY` / `SCORIA_LANE_CONTRACT_ONLY`;
  D-02's `after_suite` guard follows the same env-gate convention.
- **Custom mix tasks wrapping `mix test`** — `scoria.test.knowledge.ex` bootstraps pgvector
  + migrations then runs `test`; the lane already pays setup cost, so D-01's BEAM-load
  overhead is negligible.

### Integration Points
- The change is internal to the mix task + test_helper + one new test file. The CI YAML
  contract string and `VerificationLanes` command records are intentionally untouched
  (SC#2/SC#4) — except the optional D-03 lane-string pin.

</code_context>

<specifics>
## Specific Ideas

- User invoked deep multi-subagent research per area (idiomatic Elixir/ecosystem, lessons
  from popular libs + cross-ecosystem, DX/footguns) and asked for a single coherent
  one-shot recommendation set. UI/UX lens explicitly discarded (CI/devops phase); DX/JTBD
  lens retained (the "user" is a maintainer who must never get a false-green CI).
- **Coherence note (why the three lock together):** D-01 (hardcoded `--only`) *arms*
  D-02's built-in guard and is the exact thing D-03's contract test pins; D-03's
  `use KnowledgeCase` assertion closes D-01's lone widening footgun. All four success
  criteria covered; matches szTheory DNA (fail-loud, automation over manual, least
  surprise, derived-not-magic-number).
- Cross-ecosystem precedent for fail-on-empty: Jest fails by default on no tests
  (`--passWithNoTests` is the opt-out), RSpec `fail_if_no_examples` exists "to prevent
  false positive builds", Go core "it would be bad if `go test` with no test files
  succeeded silently", pytest `--strict-markers`. The instinct to harden is endorsed.

</specifics>

<deferred>
## Deferred Ideas

- **`--partitions` zero-shard guarding** — relevant when Phase 26 shards the knowledge
  lane; Mix documents the fail-on-empty guarantee for `--only` but not for `--partitions`.
  D-02's `after_suite total > 0` guard already provides forward coverage; flagged for
  Phase 26 to verify the guard still arms under a sharded knowledge lane.
- No scope creep raised — discussion stayed within the phase boundary. No matching
  pending todos surfaced for Phase 24.

</deferred>

---

*Phase: 24-knowledge-lane-scope-fix*
*Context gathered: 2026-06-15*
