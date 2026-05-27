# Phase 66: Baseline Expiry And Inventory - Research

**Researched:** 2026-05-27
**Domain:** Elixir maintainer Mix tasks, markdown policy parsing, compiler-warning capture, GitHub Actions job splitting
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (non-negotiable)
- D-01 through D-08: `Scoria.WarningBaseline` + `mix scoria.warning_baseline.check` SSOT; parse only `## Accepted Warning Debt`; UTC calendar expiry; strict Owner/Expires; `--file` / `--date`; no closeout lane entry
- D-09 through D-13: Split CI into `policy` (no Postgres) + `test` (`needs: policy`); policy order baseline → compile WAE → lane-contract WAE; hard fail WARN-03; CI contract test
- D-14 through D-20: `mix scoria.warning_inventory` capture mode (no WAE); flags; committed cluster-count JSON + WARNING-INVENTORY.md; gitignored full JSON; preflight; `preferred_envs`
- D-21 through D-27: Hybrid cluster registry; row schema; ratchet tiers; 7 clusters + sentinel; lane attribution secondary; exclude Logger/HTTP/SQL noise; dedupe by cluster+file+fingerprint
- D-28 through D-31: No 66-LEARNINGS.md at plan time; execute closeout extracts learnings
- D-32 through D-35: Shared baseline join where sensible; VerificationLanes parity; fixture stderr unit tests; minimal operator_verification subsection

### Claude's Discretion
- Module file layout, shared `@moduledoc` namespace, JSON schema_version policy, test/tmp preflight fail vs warn, CI test file placement

### Deferred (OUT OF SCOPE)
- Full-suite WAE CI (Phase 68), CI-03 docs bundle (Phase 69), auto-fix inventory, duplicate baseline into VerificationLanes
</user_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

Single-tier Elixir library — all capabilities reside in `lib/scoria/` + Mix tasks + CI YAML. No browser or external API tier.

| Capability | Primary Tier | Secondary | Rationale |
|------------|-------------|-----------|-----------|
| Baseline expiry enforcement | Mix task / domain module | CI policy job | Policy meta-gate before compile WAE |
| Warning inventory capture | Mix task (subprocess I/O) | Test fixtures | Heavy I/O; not adopter closeout |
| CI job split | GitHub Actions YAML | ExUnit contract grep | Drift prevention like VerificationLanes |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 66 implements two maintainer-facing tools patterned after `Scoria.VerificationLanes` and `Mix.Tasks.Scoria.ReleasePreview`: a **cheap policy gate** (baseline expiry) and a **heavy measurement tool** (warning inventory). Industry ratchets (ESLint, TypeScript baseline files, Credo) treat calendar expiry and count baselines as **meta-gates outside** the compiler — Scoria follows that with Mix + CI one-liners, not markdown shell hacks.

**Baseline parser:** Use a small dedicated parser module (line-scanner + pipe-table row extraction) rather than a general markdown AST library — the file format is fixed (one table under one heading). NimbleParsex is unnecessary; regex + structural guards match Phase 61 "code SSOT" precedent.

**Inventory capture:** Run `MIX_ENV=test mix do compile --force, test` without `--warnings-as-errors`, capture merged stdout/stderr via `System.cmd/3` with `stderr_to_stdout: true` (same pattern as `Mix.Tasks.Scoria.ReleasePreview` hex.build). Parse Elixir compiler warning lines (`warning: … at FILE:LINE`) and ExUnit diagnostic lines separately (`signal_kind`). Do **not** treat Logger `[warning]` or SQL severity strings as compiler warnings (D-26).

**CI split:** GitHub Actions `needs: policy` on `test` job; `policy` runs on `ubuntu-latest` without `services.postgres`. Order: baseline check → setup-beam → deps → compile WAE → lane-contract WAE tests. Preserves existing closeout substring order inside `test` job (D-11).

**Primary recommendation:** Three-plan wave split — (1) WarningBaseline + check task + fixtures, (2) CI policy job + contract test, (3) WarningInventory cluster registry + inventory task + committed artifacts schema.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Elixir / Mix | 1.19 / OTP 27 | Tasks, compilation | Project pin |
| ExUnit | built-in | Contract + parser tests | Existing lane tests |
| `:binary.match` / regex | stdlib | CI YAML order assertions | `verification_lanes_test.exs` |
| `Date` / `DateTime` | stdlib | UTC expiry (D-03) | No TZ ambiguity with `--date` |
| `Jason` | existing dep | Inventory JSON artifacts | Already in project |

### Supporting
| Component | Purpose | When |
|-----------|---------|------|
| `File.read!` + line split | Baseline markdown parse | Always |
| `System.cmd("mix", …, stderr_to_stdout: true)` | Inventory capture | Maintainer / optional smoke |
| `git rev-parse HEAD` | `git_sha` metadata | `--write` |

### Alternatives Considered
| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Custom table parser | Earmark / MDEx | Overkill for one table; adds dep |
| Shell pipeline in CI | Mix task only | Violates D-01 |
| Full warning JSON in git | Cluster counts only (D-17) | Merge churn — rejected |
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### System Architecture Diagram

```
Maintainer / CI
    │
    ├─► mix scoria.warning_baseline.check ──► Scoria.WarningBaseline
    │         │                                      │
    │         └─ reads .planning/WARNING-BASELINE.md │
    │                                                ├─ accepted_rows/1
    │                                                ├─ expired_rows/1
    │                                                └─ invalid_rows/1
    │
    ├─► mix scoria.warning_inventory ──► Scoria.WarningInventory
    │         │                              │
    │         ├─ subprocess: compile+test    ├─ Capture (stderr merge)
    │         ├─ ClusterRegistry.match/1     ├─ classify rows
    │         └─ --write                     └─ baseline.json + INVENTORY.md
    │
    └─► GitHub Actions
              policy job (no DB) ──needs──► test job (Postgres, closeout chain)
```

### Recommended Project Structure
```
lib/scoria/warning_baseline.ex
lib/scoria/warning_inventory.ex
lib/scoria/warning_inventory/cluster.ex   # optional split
lib/mix/tasks/scoria.warning_baseline.check.ex
lib/mix/tasks/scoria.warning_inventory.ex
test/scoria/warning_baseline_test.exs
test/scoria/warning_inventory/cluster_test.exs
test/scoria/warning_inventory_test.exs      # fixture-only classifier tests
test/scoria/ci_policy_contract_test.exs     # or extend verification_lanes_test
.github/workflows/ci.yml                    # policy + test jobs
.planning/warning-inventory.baseline.json   # committed on --write
.planning/WARNING-INVENTORY.md
tmp/warning-inventory/latest.json           # gitignored
```

### Pattern 1: Markdown table row extraction
**What:** Scan lines after `## Accepted Warning Debt` until next `##`; parse `| col |` rows; skip header separator `|---|`.
**When:** Baseline load only — never scan Resolved section (D-02).

### Pattern 2: Subprocess warning capture
**What:** Single `System.cmd` with `cd: File.cwd!()`, `stderr_to_stdout: true`, env `MIX_ENV=test`.
**When:** Inventory full run; unit tests use fixture strings instead (D-34).

### Pattern 3: CI contract grep
**What:** Read `ci.yml`, assert `index_of(baseline_check) < index_of(compile WAE) < index_of(lane tests)` and closeout chain indices unchanged in `test` job.
**When:** Plan 66-02 — mirrors `verification_lanes_test.exs`.

### Anti-Patterns to Avoid
- **Shell awk on WARNING-BASELINE.md in CI:** Violates D-01; brittle
- **Committing full warning arrays:** Merge hell (D-17, industry lesson)
- **Directory-only taxonomy:** Violates D-21
- **Adding baseline check to closeout_order/0:** Violates D-08
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UTC date comparison | String compare on ISO | `Date.compare/2` with `Date.from_iso8601!/1` | Leap years, invalid dates |
| CI job dependencies | Duplicate workflows | `needs: policy` | Native GHA semantics |
| Warning line parsing | Full compiler protocol | Regex on known `warning:` / `** (` patterns | Stable for inventory v1 |
| Lane file lists | Hardcode paths | `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` + `VerificationLanes` | D-25 |
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Parsing Resolved section dates
**What goes wrong:** False expiry failures from historical resolution dates in prose.
**How to avoid:** Stop at next `##` after Accepted table (D-02).
**Warning signs:** Tests fail after editing Resolved section only.

### Pitfall 2: Inventory polluted by test/tmp host proof
**What goes wrong:** `:host_proof_generated_compile` dominates counts.
**How to avoid:** Preflight detect `test/tmp/` (D-18); document cleanup in failure message.

### Pitfall 3: Policy job still needs Postgres
**What goes wrong:** Slow/flaky policy job; violates D-09 intent.
**How to avoid:** No `services:` block on `policy`; only compile + lane-contract tests that don't hit DB.

### Pitfall 4: `:unclassified_compile` silently grows
**What goes wrong:** Phase 67 ratchet queue lacks signal.
**How to avoid:** Fail or warn when count > 0 without baseline owner (D-24).
</common_pitfalls>

<code_examples>
## Code Examples

### Expiry check with injectable date
```elixir
# Source: Elixir Date docs — calendar comparison
def expired?(expires_date, today \\ Date.utc_today()) do
  Date.compare(today, expires_date) == :gt
end
```

### CI policy job sketch
```yaml
# policy job — no postgres service
jobs:
  policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.19"
      - run: mix scoria.warning_baseline.check
      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs

  test:
    needs: policy
    services:
      postgres: ...
```

### Inventory capture command (capture mode)
```elixir
{output, status} =
  System.cmd("mix", ["do", "compile", "--force", "+", "test"],
    env: [{"MIX_ENV", "test"}],
    stderr_to_stdout: true
  )
# status may be non-zero — still parse warnings (D-15)
```
</code_examples>

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Quick run** | `MIX_ENV=test mix test test/scoria/warning_baseline_test.exs` |
| **Policy contract** | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` (or lanes test extension) |
| **Inventory unit** | `MIX_ENV=test mix test test/scoria/warning_inventory/` |
| **Full inventory smoke** | `MIX_ENV=test mix scoria.warning_inventory --scope high_signal` (manual / tagged `@tag :inventory_smoke`) |
| **CI proof** | `mix scoria.warning_baseline.check` in policy job |

Nyquist: Every plan task gets `<automated>` verify; no full-suite inventory in unit tests (D-34).

<sota_updates>
## State of the Art

| Pattern | Scoria mapping |
|---------|----------------|
| ESLint `--report-unused-disable-directives` + expiry | `WarningBaseline` meta-gate |
| TS baseline file counts | `warning-inventory.baseline.json` cluster counts |
| Braintrust/Langfuse eval → CI gate | Inventory → Phase 67 ratchet queue |
| Oban "lint before proof" | policy job before Postgres test job |
</sota_updates>

<open_questions>
## Open Questions

1. **Exact compiler warning regex for ExUnit vs compile**
   - Recommendation: Start with Elixir 1.19 `warning:` prefix lines; extend in execute if sample run misses LiveView teardown lines.

2. **test/tmp preflight: fail vs warn**
   - Recommendation: `Mix.raise` when `test/tmp/` has entries and not `--quiet` (align with release_preview strictness).

3. **ROADMAP `Phase 66:` vs em dash**
   - Recommendation: Fix headers in 66-02 alongside ci.yml (CONTEXT specifics).
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- `.planning/phases/66-baseline-expiry-and-inventory/66-CONTEXT.md` — locked decisions
- `lib/scoria/verification_lanes.ex`, `test/scoria/verification_lanes_test.exs` — SSOT + CI grep pattern
- `lib/mix/tasks/scoria.release_preview.ex` — subprocess + sectioned output
- `.planning/WARNING-BASELINE.md` — table format

### Secondary (MEDIUM confidence)
- Elixir `Mix.Task` docs — preferred_envs, task structure
- GitHub Actions `needs` — job dependency ordering
</sources>

---

*Phase: 66-baseline-expiry-and-inventory*
*Research completed: 2026-05-27*
*Ready for planning: yes*

## RESEARCH COMPLETE
