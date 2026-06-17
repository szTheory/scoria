# Phase 25: Lane parallelization + topology docs - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

The single serial `verify / test` job in `.github/workflows/ci-verify.yml` fans out into
**parallel `needs:`-jobs** gated by **one stable `verify-summary` fan-in check**, the
canonical lane order is preserved as YAML byte-order **where order is real**, and the docs
the contract tests assert describe the topology move **in the same commit**.

**Parallel topology (locked by ROADMAP SC#1) — each sibling `needs: build`:**

```
policy → build → { test, ratchet, knowledge, connector(+gallery tail) } → verify-summary
```

- **`test:`** — the closeout chain that carries `services: postgres`: `release_preview →
  adoption → runtime_to_handoff → semantic_fast_path → full-suite (mix test --WAE)` as
  *sequential steps sharing one DB*. (The full suite stays one step here; Phase 26 shards it.)
- **`ratchet:`** — the maintainer ratchet-hygiene preflight
  (`MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs`).
- **`knowledge:`** — `mix test.knowledge --warnings-as-errors` (pgvector; needs DB).
- **`connector:`** — `mix test.connector --warnings-as-errors`, with the advisory
  `mix scoria.test.support_copilot` gallery as its tail step.
- **`verify-summary:`** — the single fan-in (`if: always()`, `needs:` all children, fails
  on any non-`success`). The reusable-workflow `verify` result reflects it; `ci.yml`'s
  `ci-gate` (`needs: [verify, e2e]`) name is **unchanged** so branch protection needs no edit.

**Locked by ROADMAP success criteria (do not relitigate):**
1. Heavy lanes run as sibling parallel jobs, each `needs: build`, instead of one serial job.
2. One `verify-summary` fan-in (`needs:` all children, `if: always()`, each child
   `result == 'success'`) is the only required check; individual children are never independently required.
3. `CI / ci-gate` required-check name is unchanged (`ci.yml` `ci-gate` still `needs: [verify, e2e]`).
4. `VerificationLanes` byte-order/closeout-order contract tests stay green — every canonical
   lane command string stays in its pinned order, with **one `test:` job carrying Postgres
   and no `services:` before it**.
5. `docs/MAINTAINERS.md`, `docs/operator_verification.md`, `README` describe the new
   parallel topology and the "docs describe topology" contract stays green (docs in lockstep).

**In scope:** the `ci-verify.yml` job split + `verify-summary` fan-in; the topology-aware
contract-test refactor; the derived fan-in-completeness test; per-job inline setup; the
DX-02 docs + doc-naming assertions; the WR-01 policy cache-key/MIX_ENV fix (folded).

**Out of scope (later phases):** full-suite `--partitions 4` sharding (Phase 26 — slots the
`test:` job's full-suite step into the matrix under this fan-in); the fixed-host-port
Postgres flake `-p 55432:5432` + TEMP e2e diagnostic removal + retry policy (Phase 27);
`mix ci` alias + velocity closeout (Phase 28). No new test-code async work (SEED-004).

</domain>

<decisions>
## Implementation Decisions

All decisions were locked after four parallel deep-research rounds (advisor mode,
`minimal_decisive` tier). They interlock — see the **Coherence** note at the end. They
carry Phase 24's DNA (derived-not-magic-number, fail-loud, contracts that faithfully proxy
the real property) into the CI **topology** layer.

### Contract-test adaptation (PAR-03, SC#4)

- **D-01 — Topology-aware refactor, NOT byte-order preservation.**
  Read "stays green" as *the contract suite is green AND canonical order is still pinned
  **where order is real***, not "existing byte-order assertions pass unchanged." After the
  split, asserting byte-position of independent parallel jobs is a byte-accident that would
  cry-wolf RED on a *safe* parallel-job reorder — that is tech debt, against DNA.
  - Add a **`job_blocks/1`** helper to `ci_policy_contract_test.exs` that parses the YAML
    `jobs:` into a `%{job_name => job_body}` map (regex on indent-2 top-level job names,
    ~15 lines). **Keep `split_jobs/1`** for the policy/build-vs-test-side slice tests that
    still work correctly (`test:` is still the first non-policy/build job).
  - **KEEP** the intra-`test:`-job step-order assertions: `release_preview < adoption <
    runtime_to_handoff < semantic < full-suite` — these are *real* sequential steps sharing
    one Postgres service; the order is load-bearing.
  - **REWRITE** the ~4 assertions that become cross-job under the split — `semantic < ratchet`,
    `full-suite < knowledge`, `knowledge < connector < gallery` — into **parallel-shape**
    assertions: each of `ratchet:`/`knowledge:`/`connector:` is a top-level job with
    `needs: build`, declared *outside* the `test:` steps block; no inter-sibling ordering.
  - **KEEP** the `refute ... in VerificationLanes.closeout_order()` asserts for `:connector`
    and `:support_copilot_gallery` (still true and meaningful).
  - Apply the same intra-vs-cross split to `verification_lanes_test.exs`'s
    "ci lane ordering follows the canonical closeout chain" test (keep closeout+semantic+
    full-suite step order; replace the `knowledge<connector<gallery` byte-chain with
    parallel-shape asserts).

### Anti-false-green fan-in (PAR-02, SC#2 + hard constraint "never weaken the bar")

- **D-02 — Derived fan-in-completeness test + name-agnostic aggregation.**
  - **GitHub semantics confirmed:** a parallel job that is *not* in `verify-summary.needs`
    and itself **fails** still fails the overall reusable-workflow `verify` result → `ci-gate`
    catches it (no `continue-on-error`). So a *failing* unwired lane cannot silently pass.
    The genuine residual risk is a **`skipped`** lane (a misconfigured `needs:` chain), and
    fan-in cleanliness for the "only required check" design.
  - **`verify-summary` aggregation = name-agnostic:** `if: always()`, `needs: [policy, build,
    test, ratchet, knowledge, connector]`, and a bash loop over `${{ join(needs.*.result, ' ') }}`
    that `exit 1`s on any result `!= "success"` (**skipped = fail**). Mirrors the existing
    `ci-gate` bash *idiom* but is name-agnostic, so adding a lane to `needs:` auto-includes
    its result check — no per-child bash edit (which would be the very manual-vigilance gap
    we're closing). Do **not** replicate `ci-gate`'s per-child named checks in the new fan-in.
  - **Derived contract test** (mirrors Phase 24 D-03): parse `ci-verify.yml`, derive the set
    of top-level jobs with `needs: build` (the parallel verify lanes, excluding
    `verify-summary` itself), and assert each ∈ `verify-summary.needs` (**subset**, not
    equality — `needs:` legitimately also lists `policy`/`build`). Include a **non-empty
    guard** so a broken regex can't vacuously pass. Adding a lane without wiring the fan-in →
    loud red. Reuses D-01's `job_blocks/1` parser.

### Per-job setup sharing (PAR-01)

- **D-03 — Inline duplication; no composite action.**
  - Decisive blockers against extraction: (a) `services:` is **job-level only** — GitHub
    forbids it in composite actions, so any extraction is a half-measure that still
    duplicates the riskiest block; (b) the contract tests grep `ci-verify.yml` for **literal**
    DB-prep strings (`mix ecto.migrate --to 20260511000300`, `Scoria.TestSupport.Migrations.migrate_knowledge!()`,
    `mix archive.install hex phx_new`) — relocating them into an action file silently breaks
    those greps. The repo has **zero** composite actions today; introducing the first one here
    is a "new pattern" cost not justified for ~3 jobs under "don't over-engineer."
  - Duplicate the preamble (`checkout → setup-beam version-file:.tool-versions → download+unpack
    build-test-env artifact → mix deps.get`) and the DB-prep block inline across the
    **Postgres-needing** jobs, with a `# DB-prep: keep in sync with sibling parallel jobs`
    marker comment so drift is grep-visible (`grep -r 20260511000300 .github/`).
  - **DB-prep needed by:** `test` ✓, `knowledge` ✓ (pgvector), `connector` ✓.
  - **`ratchet`** runs only `tmp_preflight_test.exs` (warning-inventory WAE) — **planner
    must verify** whether it touches Ecto. If it does *not*, the `ratchet:` job carries **no**
    `services:` and **no** DB-prep (keeps the "Postgres only on the test-side / one `test:`
    job carrying Postgres" contract clean and honest).

### Docs topology depth (DX-02, SC#5)

- **D-04 — Prose + structure + new contract assertions (Option C).**
  The phase is literally named "…topology docs" and the repo already enforces docs-as-contract,
  so the extra assertions are on-DNA, not over-engineering.
  - `docs/MAINTAINERS.md` `## CI gate map`: add the topology line
    `policy → build → { test, ratchet, knowledge, connector } → verify-summary`, and a
    **job → local-reproduction-command table** (the highest-value maintainer artifact now
    that "which job failed?" ≠ "which step?"). Rename the now-false `**Test job closeout**`
    heading to an accurate parallel-jobs heading.
  - Update `ci_policy_contract_test.exs` `"maintainer CI gate map documents topology, parity,
    ratchet, and failure diagnosis"`: change `=~ "Test job closeout"` to the new heading, and
    **ADD** asserts that the gate map names each parallel lane (`ratchet`, `knowledge`,
    `connector`) **and** the `verify-summary` fan-in — so docs can't drift from the YAML topology.
  - `docs/operator_verification.md` (CI gate map narrative) and the `README` CI-topology line
    updated in **lockstep** in the same commit.

### Folded Todos

- **WR-01 — Policy job cache-key / MIX_ENV mislabel** (`ci-policy-job-cache-key-mislabel.md`).
  The `policy` job runs `mix compile --warnings-as-errors` under the default `MIX_ENV=dev`
  but restores/saves under a `-test-mix-` cache key. Fold the fix while the YAML is open:
  **recommended** — set `MIX_ENV: test` on the `policy` job so its compile matches the
  `-test-mix-` key (and warms the `build` job's cache); alternative — relabel the policy key
  to `-dev-mix-`. **Constraint:** whichever is chosen, the cache-key contract test
  (`assert ci_verify =~ ~r/key:.*-test-mix-/` and `assert ci_entry =~ ~r/key:.*-dev-mix-/`,
  plus the `refute ... runner.os }}-mix-` too-broad-fallback guards) must stay green —
  `build` already supplies a `-test-mix-` key, so moving policy to `-dev-mix-` is safe for
  that assertion. Planner picks the mechanism.

### Claude's Discretion
- Exact regex for `job_blocks/1` and whether new parallel/fan-in assertions live in
  `ci_policy_contract_test.exs` or a sibling `ci_verify_contract_test.exs` if the file grows
  too long — follow existing repo conventions.
- Exact YAML file ordering of the parallel sibling jobs (no longer load-bearing once D-01
  asserts parallel-shape instead of byte-order) and the `verify-summary` step phrasing.
- WR-01 fix mechanism (set `MIX_ENV: test` vs relabel key), subject to the cache-key contract.
- Whether the `connector` gallery tail is a step inside `connector:` vs a tiny separate job
  (ROADMAP calls it a "tail" — default to a step inside `connector:`; it is advisory).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope / requirements
- `.planning/ROADMAP.md` §"Phase 25: Lane parallelization + topology docs" — goal + 5 success criteria.
- `.planning/REQUIREMENTS.md` — PAR-01, PAR-02, PAR-03, DX-02 (the four requirements this phase satisfies; mapping table at lines 80–83).
- `.planning/PROJECT.md` §"Current Milestone: v3.1 CI/CD Velocity" — hard constraint:
  preserve/strengthen the verification bar (nothing demoted to nightly); single fast PR+main gate.
- `prompts/sztheory-elixir-dna.md` — engineering DNA the decisions align with (automation over
  manual, fail-loud, derived-not-magic-number, docs-as-contract, least surprise, don't over-engineer).

### Prior-phase context this phase depends on
- `.planning/phases/23-cache-correctness-build-once-job/23-CONTEXT.md` — the `build` job +
  `build-test-env` artifact (D-01..D-10): every parallel job `needs: build` and restores the
  artifact (no cold compile); env-scoped cache keys; `split_jobs/1` splits at `"\n  test:"`,
  policy-side stays services-free.
- `.planning/phases/24-knowledge-lane-scope-fix/24-CONTEXT.md` — knowledge lane is `--only
  knowledge` scoped; **the derived-not-magic-number / fail-loud contract-test DNA (D-02/D-03)
  that D-01 and D-02 here mirror.**

### CI files this phase modifies
- `.github/workflows/ci-verify.yml` — reusable `workflow_call` SSOT: today `policy → build →
  test` (serial). Where the parallel split + `verify-summary` fan-in goes. Holds the literal
  DB-prep strings the contract greps depend on (keep inline, D-03).
- `.github/workflows/ci.yml` — PR/main entry: `verify` (uses `ci-verify.yml`), `e2e`
  (`MIX_ENV=dev`), `ci-gate` (`needs: [verify, e2e]`, `if: always()`). **`ci-gate` is the
  mirror for the `verify-summary` bash idiom.** `ci-gate` name + branch protection untouched.
- `.tool-versions` — `erlang 27.3.2`, `elixir 1.19.5-otp-27` (the `version-file:` source).

### Contract tests (must stay green — SC#4) + the SSOT module
- `test/scoria/ci_policy_contract_test.exs` — `split_jobs/1` + all byte-order/topology asserts;
  home of the new `job_blocks/1` parser, the rewritten parallel-shape asserts (D-01), the
  derived fan-in-completeness test (D-02), and the updated docs-topology asserts (D-04).
- `test/scoria/verification_lanes_test.exs` — pins lane set + the "ci lane ordering follows the
  canonical closeout chain" byte-order test (D-01 intra-vs-cross split applies here too).
- `lib/scoria/verification_lanes.ex` (`Scoria.VerificationLanes`) — SSOT for lane command
  strings + `closeout_order/0` (`[:release_preview, :adoption, :runtime_to_handoff]`). Command
  strings stay byte-identical.

### Docs to update in lockstep (DX-02)
- `docs/MAINTAINERS.md` §"## CI gate map" — rename `**Test job closeout**`, add topology line +
  job→command table (D-04).
- `docs/operator_verification.md` — CI gate map / lane narrative.
- `README.md` — the "For maintainers" / "CI topology" line.

### Folded-todo source
- `.planning/todos/ci-policy-job-cache-key-mislabel.md` — WR-01 (folded; see D-04 Folded Todos).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`ci-gate` bash** (`ci.yml`) — the `needs.<job>.result != "success" → exit 1` idiom the
  `verify-summary` aggregation mirrors; D-02 generalizes it to a name-agnostic
  `join(needs.*.result)` loop instead of per-child named checks.
- **`split_jobs/1`** (`ci_policy_contract_test.exs`) — kept for policy/build-vs-test slice
  tests; the new `job_blocks/1` parser sits alongside it for parallel-shape + fan-in asserts.
- **Phase 24 derived file-set contract test** (`knowledge_lane_contract_test.exs`,
  `adoption_test_files/0` precedent) — the derived-not-hardcoded pattern D-02's fan-in
  completeness test reuses.
- **`build` job + `build-test-env` artifact** (`ci-verify.yml`, Phase 23) — every parallel
  job restores it via `download-artifact` + `tar -xzf` instead of cold-compiling.

### Established Patterns
- **Contract-as-ExUnit-test** — CI invariants (job topology, lane order, docs content) are
  asserted in `ci_policy_contract_test.exs` / `verification_lanes_test.exs`. New invariants
  (parallel shape, fan-in completeness, doc lane-naming) follow the same pattern.
- **`version-file: .tool-versions` + `version-type: strict` setup-beam** — copied across all
  workflows; each new parallel job uses it verbatim (D-03 inline preamble).
- **Per-job `services: postgres`** — job-level only; carried by the Postgres-needing jobs,
  never by the policy-side slice (the `refute policy_section =~ "services:"` contract).

### Integration Points
- `ci.yml` `verify:` job (`uses: ./.github/workflows/ci-verify.yml`) — its result now reflects
  the `verify-summary` fan-in; `ci-gate` consumes `needs.verify.result` unchanged.
- Phase 26 slots the `test:` job's full-suite step into a `--partitions 4` matrix **under this
  same `verify-summary` fan-in** — keep the fan-in derivation tolerant of a future matrix job.

</code_context>

<specifics>
## Specific Ideas

- User invoked deep parallel multi-subagent research (advisor mode, `minimal_decisive` tier:
  one decisive locked recommendation per area, no menus). Selected all four gray areas to
  research; chose to fold WR-01 opportunistically.
- **Coherence note (why the decisions lock together):** D-01 and D-02 share one new
  `job_blocks/1` YAML parser. D-03 (inline) keeps the literal DB-prep strings in
  `ci-verify.yml` so D-01's and the existing contract greps keep resolving. D-04 completes the
  docs-as-contract triad (topology asserted in code *and* in docs). All four mirror Phase 24's
  derived/fail-loud DNA — a contract that goes RED only on *real* drift, never on a safe
  parallel-job reorder, and that makes a forgotten fan-in lane a loud one-line red.
- **JTBD lens retained, UI/UX discarded** (CI/devops phase): the "user" is a maintainer who
  must (a) never get a false-green, and (b) map a failed *parallel job* → the exact local mix
  command to reproduce — hence D-02 (anti-false-green) + D-04 (job→command table).
- **Key GitHub-semantics finding (D-02):** an unwired *failing* lane still fails the
  reusable-workflow result → `ci-gate`; the real residual risk is a *skipped* lane → so
  `skipped = fail` in the `verify-summary` aggregation.

</specifics>

<deferred>
## Deferred Ideas

- **Full-suite `--partitions 4` sharding (Phase 26)** — the `test:` job's full-suite step
  becomes a runner matrix under this fan-in; keep `verify-summary` derivation matrix-tolerant.
- **Fixed-host-port Postgres flake, TEMP e2e diagnostic removal, retry-vs-fix policy (Phase 27)** —
  `-p 55432:5432` is untouched here; parallel jobs run on separate runners so the split does
  not worsen the host-port flake.
- **`mix ci` local alias + velocity closeout (Phase 28).**

### Reviewed Todos (not folded)
- **`docker-dx-fleet-hardening.md`** (Docker dev-DX fleet hardening — port-conflict-free
  multi-lib local DX) — matched weakly (score 0.4, keyword "phase" only); unrelated to CI
  topology. Belongs to the v3 Docker DX track, not this phase.

</deferred>

---

*Phase: 25-lane-parallelization-topology-docs*
*Context gathered: 2026-06-15*
