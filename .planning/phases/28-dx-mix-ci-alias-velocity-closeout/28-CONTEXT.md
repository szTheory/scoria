# Phase 28: DX `mix ci` alias + velocity closeout - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the v3.1 milestone closeout: (1) a single `mix ci` command that reproduces
the merge gate locally and exits non-zero on any failure (DX-01), and (2) a durable,
honest before/after proof of the headline velocity outcome — ~77 min serial baseline →
≤ ~15 min (target ~12 min) warm-cache critical path — measured via `gh run view --json`
(VELO-01).

**JTBD:** a contributor runs ONE command before pushing and gets the same verdict CI
will give — fast feedback, no surprises, and a green that never lies.

**In scope:** the `mix ci` task + alias; its preamble (deps-lock/format/compile-WAE) and
lane orchestration driven off `Scoria.VerificationLanes`; preflight infra check + opt-out
ergonomics; the committed velocity-proof artifact; the doc note describing the local-vs-CI
asymmetry.

**Not in scope:** further CI parallelization/sharding/caching (Phases 23–26, done); flake
fixes (Phase 27, done); adding format/deps-lock gates to CI workflows (deferred — see
Deferred Ideas); reworking local dev DB setup (stays on the deliberate fixed `55432`
mapping); deeper test-code async work (SEED-004).
</domain>

<decisions>
## Implementation Decisions

Calibration: `minimal_decisive` (opinionated maintainer profile; `technical_background:
true` so no plain-language reframing). Each decision was researched via parallel
subagents (idiomatic Elixir/Phoenix/Ecto DX, ecosystem lessons, footguns). UI/UX/brand
lens N/A — DevOps/DX phase. The four decisions cohere around one spine: **`mix ci` is a
`Mix.Task` driven off `Scoria.VerificationLanes` (the single source of truth) whose
verdict is trustworthy because it never silently weakens.**

### D-A — Form & run semantics: `Mix.Task`, run-all-aggregate, SSOT-driven
- **D-A1:** Implement as a dedicated `Mix.Task` — `lib/mix/tasks/scoria.ci.ex`
  (`Mix.Tasks.Scoria.Ci`) — exposed as `ci: ["scoria.ci"]` in `mix.exs` `aliases/0`
  (line 108). NOT a plain `mix.exs` alias-list: Mix only surfaces the **last** chained
  sub-command's exit code (elixir-lang/elixir#4318) → false-green footgun; an alias list
  also can't aggregate, conditionally skip, or time.
- **D-A2:** Derive the step list from `Scoria.VerificationLanes` (`closeout_order/0` +
  per-lane `command/1`), **not** a hardcoded command list. A hardcoded list would drift
  from the lane contract and dodge the `verification_lanes_test` / `ci_policy_contract_test`
  byte-order guards. The module's local `command` field already encodes the local-vs-CI
  divergence (e.g. `SCORIA_DB_PORT=… MIX_ENV=test mix test.semantic_fast_path` locally vs
  the bare `ci_command`), so reuse it.
- **D-A3:** **Run-all-then-aggregate** failure semantics: run every step (via `System.cmd`
  or `Mix.shell().cmd`) capturing each exit status, print a per-step PASS/FAIL summary,
  then `System.halt(1)` if ANY step failed (use `halt`, not `Mix.raise`, so aggregation
  completes first). This mirrors CI's `verify-summary` fan-in (which aggregates every
  lane's result and fails on any non-success) — fail-fast would give a narrower verdict
  than the gate it claims to mirror and reintroduce the multi-iteration fix loop.

### D-B — Optional lanes & environment: hard-fail with preflight, exclude advisory gallery
- **D-B1:** `mix ci` runs the full **merge-GATING** lane set and **hard-fails** (exits
  non-zero) when Postgres/pgvector is absent — silently skipping merge-gating lanes
  produces a green that lies, which is strictly worse than no local mirror and violates
  the JTBD. Matches the in-repo idiom: `Scoria.Pgvector.Bootstrap` raises a `Next step:`
  block rather than auto-skipping.
- **D-B2:** Start with a fast **preflight probe** (TCP reach to configured Postgres + a
  `vector`-extension check) before running any lane; reuse `mix scoria.pgvector.bootstrap
  --check` mode. On failure, exit non-zero with actionable CLI microcopy (no styling),
  modeled on the existing `Next step:` convention — e.g.:
  ```
  mix ci: merge-gate lanes require a pgvector-capable Postgres, but none is reachable
    at localhost:55432 (vector extension not found / connection refused).
  These lanes gate merge and cannot be skipped silently — a green here must match CI.
  Next step:
    mix scoria.pgvector.bootstrap   # starts pgvector Postgres on :55432
    mix ci                          # re-run the full merge gate
  No Docker / docs-only change? Run a PARTIAL check (exits non-zero, NOT a gate pass):
    mix ci --skip-optional
  ```
- **D-B3:** Provide ONE opt-out — `mix ci --skip-optional` (and/or
  `SCORIA_CI_SKIP_OPTIONAL=1`) — for docs-only / no-Docker contributors. It MUST (a) print
  exactly which lanes were skipped, (b) stamp the final line
  `RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)`,
  and (c) **still exit non-zero** so it can never be mistaken for a clean gate or wired into
  a pre-push hook as authoritative.
- **D-B4:** **Exclude** the advisory `support_copilot_gallery` lane from `mix ci` — it is
  explicitly non-merge-blocking (`exclusions` contains "merge-blocking closeout"). `mix ci`'s
  contract is "reproduce the MERGE GATE only"; an advisory lane adds runtime and a second
  non-gating signal that dilutes the binary verdict. Optional future `--with-advisory` flag
  whose result never touches the exit code (deferred, not required).

### D-C — Format/deps-lock parity: strict superset locally, leave CI untouched
- **D-C1:** `mix ci` preamble runs in this order (cheap/static checks first, format before
  compile, lanes last):
  `mix deps.unlock --check-unused` → `mix deps.get --check-locked` →
  `mix format --check-formatted` → `mix compile --warnings-as-errors` → lane chain.
  Both deps commands are the canonical hex-lib pair: `--check-unused` flags orphan entries
  left in `mix.lock`; `--check-locked` asserts the lock is in sync with `mix.exs` (fails
  instead of silently rewriting).
- **D-C2:** `mix ci` is a deliberate **strict superset** of CI's `policy` job (CI runs
  NEITHER format-check NOR deps-lock-check today). Local-stricter is correct shift-left —
  more safety locally, never less — so "preserve or strengthen the bar" is honored.
- **D-C3:** Do **NOT** add format/deps-lock to `ci-verify.yml`'s `policy` job this phase.
  Editing the contract-guarded workflow at milestone CLOSEOUT is scope creep and risks the
  `ci_policy_contract_test` ordering invariants. Document the intentional asymmetry in
  `docs/MAINTAINERS.md`. (CI symmetry deferred — see Deferred Ideas.)
- **D-C4 (footgun):** ensure `mix format --check-formatted` is scoped via `.formatter.exs`
  inputs so it does NOT try to format `examples/` vendored deps; watch `--check-unused`
  false positives.

### D-D — Velocity proof: committed artifact + MILESTONES.md headline
- **D-D1:** Canonical artifact: a committed
  `.planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md` with pinned
  before/after run IDs **and the raw `gh run view --json …` JSON captured inline** (so the
  proof survives GitHub run-retention purge). Add a one-line headline entry to
  `.planning/MILESTONES.md` ("v3.1: PR CI critical-path 77m→~12m, before `<id>` / after
  `<id>`"); back-reference it from `28-VERIFICATION.md`. NOT timing-in-VERIFICATION-only —
  that doc gets archived and the headline outcome would become undiscoverable.
- **D-D2 (computation — load-bearing):** Critical path = **sum of stage maxima** along the
  dependency chain `policy → build → max(test, ratchet, knowledge, connector, full-suite
  shards) → verify-summary`, using each job's `startedAt → completedAt` (active run time,
  EXCLUDES queue time); for matrix lanes take the slowest shard. Report the run-level
  wall-clock = `max(completedAt) − min(startedAt)` across jobs as the headline ≤~15m number.
  Capture raw JSON first, then compute. **Never** quote summed billable minutes as
  wall-clock. Example:
  ```bash
  gh run view <RUN_ID> --json databaseId,headSha,createdAt,jobs,workflowName,url > 28-after-<RUN_ID>.json
  jq -r '.jobs[] | [.name, ((.completedAt|fromdateiso8601)-(.startedAt|fromdateiso8601))] | @tsv' \
    28-after-<RUN_ID>.json | sort -t$'\t' -k2 -nr   # per-job durations, slowest first
  ```
- **D-D3 (baseline anchor):** Do NOT reconstruct the old serial workflow. Pin a **real
  historical serial run ID** from the pre-milestone `verify / test` era — SEED-003 cites
  `27508317719` / `27505520774` (~76m serial lane). Capture its JSON **now** before
  retention purges it. If already purged, fall back to citing the SEED-003 profiling +
  tagged pre-milestone commit/run, and say so plainly rather than fabricating a number.
  Pin immutable run URLs alongside IDs.
- **D-D4 (honesty caveats — state in the doc):** the after-run must be a warm-cache run
  on a stable cache key (captioned as such); same-workload (comparable test count / commit
  scope, no skipped lanes); single warm run is honestly defensible at this rigor but note
  runner variance (cite median-of-2–3 if cheap).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### `mix ci` source of truth & form
- `lib/scoria/verification_lanes.ex` — SSOT for the lane set; drive `mix ci` off
  `closeout_order/0`, `command/1`, `closeout_chain/0`. Exclude `:support_copilot_gallery`.
- `mix.exs` §`aliases/0` (line 108) — add `ci: ["scoria.ci"]`.
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` (lines ~41–58) — existing `Next step:`
  microcopy idiom to match; reuse its `--check` mode for the preflight probe.
- `test/scoria/ci_policy_contract_test.exs`, `test/scoria/verification_lanes_test.exs` —
  byte-order/closeout contracts that a hardcoded command list would violate; keep green.

### CI gate `mix ci` must mirror
- `.github/workflows/ci-verify.yml` — the reusable workflow; the `verify-summary`
  `needs:` list is the exact gate `mix ci` must reproduce (policy → build → {test,
  ratchet, knowledge, connector, full-suite×4} → verify-summary).
- `.github/workflows/ci.yml` — top-level `verify` + `e2e` + the stable `ci-gate` required
  check (do not rename).

### Docs to update (DX-02 already shipped Phase 25; this phase adds the asymmetry note)
- `docs/MAINTAINERS.md` — document `mix ci` and the deliberate local-vs-CI asymmetry
  (format/deps-lock run locally only).
- `docs/operator_verification.md`, `README.md` — mention `mix ci` as the one-command gate.

### Velocity proof
- `.planning/seeds/SEED-003-ci-efficiency-overhaul.md` — baseline anchor source; run IDs
  `27508317719` / `27505520774`, ~76m serial-lane profiling.
- `.planning/MILESTONES.md` — durable rolling record; headline 77m→~12m line lands here.
- `.planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md` — to create.

### Project DNA
- `prompts/sztheory-elixir-dna.md` — Operator-First DX, Batteries-Included but Composable,
  Unix philosophy, Robust CI/CD; the lens for `mix ci`'s ergonomics.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.VerificationLanes` — single source of truth for lanes (8 lanes, `command` vs
  `ci_command`, `closeout_order`, `boundary_sentence`). `mix ci` orchestrates from here.
- `Scoria.Pgvector.Bootstrap` (`mix scoria.pgvector.bootstrap`) — has a `--check` mode and
  the `Next step:` microcopy idiom; reuse for the `mix ci` preflight + failure message.
- ~24 existing `scoria.*` / `test.*` Mix tasks under `lib/mix/tasks/` — the lane commands
  `mix ci` will invoke (`test.adoption`, `test.runtime_to_handoff`, `test.semantic_fast_path`,
  `test.knowledge`, `test.connector`, `scoria.release_preview`, …).

### Established Patterns
- `mix.exs` `aliases/0` currently holds only `assets.build/deploy`, `dev.setup` — `ci` joins
  as a thin alias delegating to the new task.
- CI policy job (`ci-verify.yml`) order: deps.get → warning baseline/inventory → compile WAE
  → contract tests. `mix ci` adds deps-lock + format ahead of compile (the DX-01 superset).
- Byte-order contract tests pin lane command strings — the new task must read lanes from the
  module, not duplicate strings.

### Integration Points
- `mix.exs` aliases → `Mix.Tasks.Scoria.Ci`.
- `Mix.Tasks.Scoria.Ci` → `Scoria.VerificationLanes` (steps) + `Scoria.Pgvector.Bootstrap`
  (`--check` preflight) + `System.cmd`/`System.halt`.
- Velocity proof → `gh` CLI + `.planning/MILESTONES.md` + `28-VERIFICATION.md`.
</code_context>

<specifics>
## Specific Ideas

- The maintainer wanted a researched, coherent, one-shot recommendation set ("so i dont
  have to think") — all four decisions were derived via parallel domain-expert research and
  validated as mutually coherent (single spine: SSOT-driven task that never silently weakens).
- Failure UX must mirror CI's fan-in (show ALL failures), use honest non-zero exits for
  git-hook/script use, and give actionable `Next step:` microcopy on missing infra.
- The velocity proof must be REAL (pinned run IDs + raw JSON), not asserted — and must
  survive milestone archive via `MILESTONES.md`.
</specifics>

<deferred>
## Deferred Ideas

- **Add format + deps-lock checks to CI's `policy` job** (true local↔CI symmetry). Genuinely
  low-risk in isolation (not covered by the byte-order assertions), but scope creep at
  milestone close — slate for a follow-up phase. For now `mix ci` is a documented strict
  superset.
- **`mix ci --with-advisory` flag** to optionally run the `support_copilot` gallery as a
  non-failing tail (result never affects exit code). Nice-to-have, not required for DX-01.
- **Median-of-N warm runs** for the velocity proof if single-run variance proves noisy —
  only if cheap; single warm run is defensible at this rigor.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 28-dx-mix-ci-alias-velocity-closeout*
*Context gathered: 2026-06-17*
