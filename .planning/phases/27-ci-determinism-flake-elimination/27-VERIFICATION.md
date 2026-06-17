---
phase: 27-ci-determinism-flake-elimination
verified: 2026-06-16T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 27: CI Determinism & Flake Elimination — Verification Report

**Phase Goal:** CI determinism & flake elimination — fix the fixed-host-port Postgres flake, remove the leftover TEMP e2e diagnostic, document a retry-vs-fix policy.
**Verified:** 2026-06-16
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | No CI Postgres job binds a host port in the ephemeral range (>= 32768); fixed 55432 bind gone from both files (FLAKE-01 / SC1) | VERIFIED | `grep 55432:5432` across both files == 0; `- 5432:5432` count: 4 in ci-verify.yml, 1 in ci.yml; `SCORIA_DB_PORT: 55432` count == 0 across both files |
| 2 | TEMP diagnostic step absent from e2e job in ci.yml (FLAKE-02 / SC2) | VERIFIED | `grep -c 'TEMP diagnose' .github/workflows/ci.yml` == 0; step block starting at old line 115 fully deleted |
| 3 | Retry-vs-fix policy documented in MAINTAINERS.md and contract test guards against retry patterns (FLAKE-03 / SC3) | VERIFIED | `### Flake policy: retry vs fix {#flake-policy}` at line 90 of MAINTAINERS.md; subsection covers all D-07..D-11 content; three new contract assertions green |
| 4 | Local SCORIA_DB_PORT=55432 references in MAINTAINERS.md / verification_lanes.ex / config remain unchanged (D-05); CI=5432 and local=55432 coexist | VERIFIED | Total `55432` refs in MAINTAINERS.md: 14 (was 12 pre-phase; 2 new ones in flake-policy paragraph); all 12 original local-parity refs intact; `verification_lanes.ex:48` still has `SCORIA_DB_PORT=55432`; `pgvector.bootstrap.ex:9` still has `@default_port 55432` |
| 5 | Existing contract tests + verification lanes stay green; no lane removed or demoted (SC4) | VERIFIED | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` → 51 tests, 0 failures; ci_policy_contract_test.exs grew from 42 to 45 tests |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | e2e job Postgres on host port 5432, TEMP step removed | VERIFIED | Line 42: `- 5432:5432`; line 52: `SCORIA_DB_PORT: 5432`; TEMP step gone; topology comment line 17 now includes `full-suite` (WR-02 fix applied) |
| `.github/workflows/ci-verify.yml` | 4 Postgres lanes (test, knowledge, connector, full-suite) on host port 5432 | VERIFIED | Lines 115, 226, 286, 355: all `- 5432:5432`; `SCORIA_DB_PORT: 5432` at lines 125, 236, 296, 365; topology comment line 9 includes `full-suite` |
| `docs/MAINTAINERS.md` | `### Flake policy: retry vs fix` subsection inside `## CI gate map` | VERIFIED | Line 90: `### Flake policy: retry vs fix {#flake-policy}`; heading order confirmed: `## CI gate map` (line 5) → `### Flake policy` (line 90) → `## Hex release & recovery` (line 126) |
| `test/scoria/ci_policy_contract_test.exs` | 3 new durable guards; `ephemeral range` text; 45 tests total | VERIFIED | 45 tests confirmed; 3 occurrences of `ephemeral range`; `TEMP diagnose` refute present; `>= 5` non-empty guard at line 213; `job_blocks/1` defined once; no YAML parser |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ci_policy_contract_test.exs` | `ci.yml` + `ci-verify.yml` | `job_blocks/1` + `body =~ "postgres:"`, asserting `host_port < 32_768` | WIRED | Test at lines 197–242 reads both files, calls `job_blocks/1` on each, asserts `map_size >= 5` then per-binding `host_port < @ephemeral_range_min`; contract suite green |
| `docs/MAINTAINERS.md § Flake policy` | `ci.yml` + `ci-verify.yml` zero-retry posture | Documented banned patterns mirrored by D-07 contract assertion | WIRED | MAINTAINERS.md lines 96–99 ban `continue-on-error`, retry-action slugs; contract test lines 249–264 refutes those patterns in both files; both files contain neither pattern |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces no runtime application code. All artifacts are CI YAML, documentation, and ExUnit contract tests (file-reader pattern, no dynamic data rendering).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 45 contract + lane tests green | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | 51 tests, 0 failures (includes adoption_surface_test.exs loaded by the policy job step) | PASS |
| WR-01 fix: quoted-form regex matches `"55432:5432"` | `Regex.scan(~r/-\s*["']?(\d+):\d+(?:\/tcp)?["']?/, "- \"55432:5432\"")` | `[["- \"55432:5432\"", "55432"]]` — match confirmed | PASS |
| WR-01 fix: per-block non-empty guard fires on no-binding body | `Regex.scan(regex, no-port-body) == []` | `true` — guard would fire, preventing vacuous pass | PASS |
| WR-01 fix: bare short-form `- 55432` intentionally unmatched | `Regex.scan(regex, "- 55432\n") == []` | `true` — per code comment, bare form publishes to *random* host port; not a fixed-bind collision risk; per-block guard would fire loud | PASS |
| Full-suite env block omits SCORIA_DB_NAME | awk extraction of full-suite env | MIX_ENV, SCORIA_DB_HOST, SCORIA_DB_PORT: 5432, SCORIA_DB_USERNAME, SCORIA_DB_PASSWORD, MIX_TEST_PARTITION — no SCORIA_DB_NAME | PASS |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes declared or applicable for this phase. Step skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FLAKE-01 | 27-01-PLAN.md | Postgres service container no longer fails on host-port bind conflicts — fixed `-p 55432:5432` replaced | SATISFIED | All 5 Postgres blocks now bind `5432:5432`; `55432:5432` count == 0 across both workflow files |
| FLAKE-02 | 27-01-PLAN.md | Leftover TEMP diagnostic step removed from e2e job in ci.yml | SATISFIED | `grep -c 'TEMP diagnose' ci.yml` == 0; step deleted cleanly |
| FLAKE-03 | 27-01-PLAN.md | Deliberate retry-vs-fix policy documented; no blanket auto-retries | SATISFIED | Subsection `### Flake policy: retry vs fix` in MAINTAINERS.md; three contract guards enforce it durably; zero retry patterns in both workflow files |

All three phase requirements satisfied. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No `TBD`, `FIXME`, `XXX`, placeholder patterns, empty handlers, or stub returns found in any of the four modified files.

### Code Review Findings Resolution

The REVIEW.md identified two warnings (WR-01, WR-02) and three info items (IN-01..IN-03). All were addressed:

**WR-01 (BLOCKER risk — now resolved):** The original ephemeral-port regex `~r/- (\d+)(?::\d+|\/tcp)/` missed GitHub's quoted `- "55432:5432"` form. The fix (`~r/-\s*["']?(\d+):\d+(?:\/tcp)?["']?/`) was applied along with a per-block non-empty guard (`assert port_bindings != []`). Empirically verified: the new regex matches quoted `"55432:5432"`, the old regex does not. The guard fires on any block that yields zero extractions, preventing vacuous pass. The bare `- NNNN` short form is intentionally unmatched per an inline comment — it publishes to a *random* host port and is not a fixed-bind collision risk.

**WR-02 (WARNING — resolved):** The `ci.yml` header topology comment previously omitted `full-suite`. It now reads: `policy → build → { test, ratchet, knowledge, connector, full-suite } → verify-summary`. Both `ci.yml:17` and `ci-verify.yml:9` now include `full-suite` in the topology.

**IN-01 (INFO — resolved):** `MAINTAINERS.md:7` opening prose also omitted `full-suite`; it now reads `{ test, ratchet, knowledge, connector, full-suite }`. (Confirmed by `MAINTAINERS.md:7` including `full-suite` in the topology sentence.)

**IN-02 (INFO — resolved by WR-01 fix):** The "Durable enforcement" paragraph over-promised before WR-01 was fixed. With WR-01 resolved, the assertion accurately covers all `HOST:CONTAINER` binding spellings in use plus quoted forms.

**IN-03 (INFO — pre-existing, not introduced by this phase):** `job_blocks/1` parses non-job 2-space keys. Noted as latent fragility in the review; not introduced by Phase 27 and not blocking. The `>= 5` non-empty guard is still valid because the postgres-filter step removes pseudo-blocks (they never contain `"postgres:"`).

**NOTE on PLAN acceptance criterion:** The PLAN task 2 verification criterion `grep -c 'SCORIA_DB_PORT=55432' docs/MAINTAINERS.md >= 12` contained a specification error. The RESEARCH doc confirmed "12 occurrences of `55432`" (at lines 24, 26, 27, 28, 30, 41, 45, 50, 54, 77, 87, 88), but several of those lines use the `Postgres on 55432` prose form without the `SCORIA_DB_PORT=` prefix. The actual `SCORIA_DB_PORT=55432` grep count is 9. Total `55432` refs in MAINTAINERS.md are now 14 (12 original + 2 new in the flake-policy paragraph). All 12 original local-parity references remain intact and no contract test asserts this count.

### Human Verification Required

None — all observable truths are machine-verifiable for this CI infrastructure + documentation phase. No visual rendering, real-time behavior, or external service integration involved.

### Gaps Summary

No gaps. All five must-have truths verified, all three requirements satisfied, all four artifacts substantive and wired, contract test suite green at 51 tests / 0 failures, all REVIEW.md findings resolved.

---

_Verified: 2026-06-16T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
