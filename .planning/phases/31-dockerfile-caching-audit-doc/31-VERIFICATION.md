---
phase: 31-dockerfile-caching-audit-doc
verified: 2026-06-18T00:00:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 31: Dockerfile Caching Audit + Doc Verification Report

**Phase Goal:** The Dockerfile layer order is empirically proven to prevent dep refetch on a CSS/HEEx-only edit, and that guarantee is documented as a layer-invalidation table plus an invariant comment so future contributors cannot regress it silently.
**Verified:** 2026-06-18
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dockerfile.dev contains an invariant comment above COPY lib lib carrying the marker `INVARIANT: volatile source` | VERIFIED | `Dockerfile.dev` L51: `# INVARIANT: volatile source (lib/dev/priv) MUST stay below deps.get + deps.compile.`; confirmed directly above the preserved `# 3) Volatile source last` comment at L55, which is directly above `COPY lib lib` at L56 |
| 2 | `docs/docker_dev_dx.md` contains a 4-row layer-invalidation table at the end of the No rebuild section | VERIFIED | `### Layer-cache invalidation (cold docker compose up --build only)` heading at L89; 4-row table at L98–103; positioned after the "Cold builds" bullet and before `## Adopting this in another repo` at L105 |
| 3 | `ci_policy_contract_test.exs` asserts COPY mix.exs mix.lock precedes COPY config precedes COPY lib | VERIFIED | Lines 640–648: flat `test "Dockerfile.dev keeps cache-optimal COPY layer order (deps -> config -> source)"` block with `index_of(df, "COPY mix.exs mix.lock")`, `index_of(df, "COPY config")`, `index_of(df, "COPY lib")`, and assertions `i_lock < i_config` and `i_config < i_lib` |
| 4 | `ci_policy_contract_test.exs` asserts the Dockerfile.dev boundary marker is present via `@layer_invariant_marker` | VERIFIED | L18: `@layer_invariant_marker "INVARIANT: volatile source"`; L647–648: `assert df =~ @layer_invariant_marker` with message naming the marker |
| 5 | `mix test --no-start test/scoria/ci_policy_contract_test.exs` passes with the new COPY-order test | VERIFIED | SUMMARY records "46 tests, 0 failures" and "passes in policy lane (`mix test --no-start`)"; test block uses existing `index_of/2` helper (no bang), which is the correct signature (L716–720 shows `defp index_of/2`) |
| 6 | A cold docker compose build --progress=plain after a CSS/HEEx touch shows mix deps.get only as CACHED, recorded in SUMMARY | VERIFIED | Per phase instructions, the one-time human-run empirical proof is the authoritative evidence. SUMMARY contains verbatim grep output: `#14 [stage-0 7/15] RUN ... mix deps.get` followed by `#14 CACHED` with no download output. VERDICT: PASS recorded in SUMMARY section "Empirical Docker Cache Proof (Criterion 1)" |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Dockerfile.dev` | Boundary invariant comment above `COPY lib lib` containing `INVARIANT: volatile source` | VERIFIED | L51–54: 4-line comment block with marker on first line; `# 3) Volatile source last` at L55 preserved; COPY/RUN order unchanged |
| `docs/docker_dev_dx.md` | Layer-invalidation table + bind-mount-vs-cold-build framing | VERIFIED | L89–103: heading + framing paragraph + 4-row table; all required strings present: `mix deps.get`, `mix deps.compile`, `mix compile`, `app compile only`, `assets/`, `mix.exs`, `mix.lock` |
| `test/scoria/ci_policy_contract_test.exs` | Static COPY-order + marker contract test with `@layer_invariant_marker` | VERIFIED | L18: attribute added to module attribute block; L640–649: new flat `test` block using `index_of/2` (no bang); no new test file created |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `test/scoria/ci_policy_contract_test.exs` | `Dockerfile.dev` | `File.read!` + `index_of/2` substring-order assertions + `df =~ @layer_invariant_marker` | WIRED | L641: `df = File.read!("Dockerfile.dev")`; L642–644: three `index_of` calls; L647: marker assertion. The `@layer_invariant_marker` attribute value `"INVARIANT: volatile source"` matches the literal string on `Dockerfile.dev` L51 — coupling is load-bearing |

### Behavioral Spot-Checks

Criterion 5 requires `mix test --no-start test/scoria/ci_policy_contract_test.exs` to pass. Running the full test suite is not appropriate here (see constraints). The SUMMARY records the green run result (46 tests, 0 failures). The test uses `index_of/2` (not the non-existent `index_of!`), which resolves to the existing `defp index_of/2` helper at L716–720. Both the COPY-order assertions and the marker assertion target strings that are confirmed present in `Dockerfile.dev` by direct file inspection.

The behavioral spot-check for criterion 1 (empirical Docker proof) is satisfied by the recorded SUMMARY evidence as specified in the phase instructions (D-04: one-time human-run snapshot, non-deterministic in CI, daemon-free policy lane).

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `@layer_invariant_marker` attribute in module-attribute block | `grep -n '@layer_invariant_marker' test/scoria/ci_policy_contract_test.exs` | L18: `@layer_invariant_marker "INVARIANT: volatile source"` | PASS |
| Marker present in `Dockerfile.dev` (test would fail otherwise) | `grep -n 'INVARIANT: volatile source' Dockerfile.dev` | L51: exact string present | PASS |
| `# 3) Volatile source last` comment preserved | `grep -n '# 3) Volatile source last' Dockerfile.dev` | L55: present | PASS |
| `COPY mix.exs mix.lock` precedes `COPY config` precedes `COPY lib` | Positional check on file lines | L40, L46, L56 respectively — order confirmed | PASS |
| CSS row does NOT say "app compile only" | Direct inspection of table row | Row says "nothing rebuilds; running container rebuilds assets on the fly" | PASS |
| No standalone apt/system row in table | `grep -n apt docs/docker_dev_dx.md` | `apt` appears in framing paragraph only, not as a table row | PASS |
| Empirical proof: `mix deps.get` only as CACHED on touch | Human-run, recorded in SUMMARY per D-04 | `#14 CACHED` with no download output; PASS verdict recorded | PASS (recorded) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CACHE-01 | 31-01-PLAN.md | CSS/HEEx-only source edit triggers no Mix dependency refetch and no full app recompile — empirically verified and documented as a layer-invalidation table plus a layer-order invariant comment in `Dockerfile.dev` | SATISFIED | All four success criteria met: (1) empirical CACHED proof in SUMMARY, (2) boundary invariant comment in Dockerfile.dev L51–54, (3) 4-row table in docs/docker_dev_dx.md L89–103, (4) static COPY-order + marker test at ci_policy_contract_test.exs L640–649 |

### Anti-Patterns Found

No debt markers (`TBD`, `FIXME`, `XXX`) found in any of the three modified files (`Dockerfile.dev`, `docs/docker_dev_dx.md`, `test/scoria/ci_policy_contract_test.exs`).

No stub patterns detected. No `return null`/empty implementations. No hardcoded empty data passed to rendering paths.

### Prohibition Compliance

| Prohibition | Status | Evidence |
|-------------|--------|---------|
| Do NOT reorder Dockerfile.dev COPY/RUN lines | COMPLIANT | `COPY mix.exs mix.lock` L40, `COPY config config` L46, `COPY lib lib` L56 — identical order to pre-phase; only 4 comment lines inserted at L51–54 |
| Do NOT create a make cache-audit target | COMPLIANT | No such target created; no Makefile modification in SUMMARY key-files |
| Do NOT edit `.github/workflows/ci-verify.yml` | COMPLIANT | git log for `ci-verify.yml` shows last modification was commit `8501578` (Phase 28) — no Phase 31 touch |
| Do NOT create any new test file | COMPLIANT | `test/scoria/` listing contains no `docker_dx_doc_contract_test.exs` or other new file; changes are append-only to `ci_policy_contract_test.exs` |
| Do NOT use `index_of!` | COMPLIANT | No occurrence of `index_of!` in test file; all three calls at L642–644 use `index_of(df, ...)` matching the existing `defp index_of/2` helper |
| Do NOT remove the existing `# 3)` step comment | COMPLIANT | L55: `# 3) Volatile source last — editing these does NOT invalidate the layers above.` present and unmodified |
| Do NOT build Phase 34's doc-string contract test | COMPLIANT | No `docker_dx_doc_contract_test.exs` exists; Phase 34 hand-off is record-only in SUMMARY |

### Human Verification Required

None. All must-haves are statically verifiable or covered by the recorded empirical proof per the phase's D-04 design decision. Criterion 1 (empirical Docker proof) is authoritative per the phase instructions: the SUMMARY contains the required verbatim grep output showing `#14 CACHED` for `mix deps.get` with no following download output.

### Gaps Summary

No gaps. All six must-have truths are VERIFIED against the actual codebase. All three artifacts are substantive and wired. The key link from `ci_policy_contract_test.exs` to `Dockerfile.dev` is established via `File.read!` + `index_of/2` assertions + `df =~ @layer_invariant_marker`. All prohibitions are complied with. CACHE-01 is satisfied.

---

_Verified: 2026-06-18_
_Verifier: Claude (gsd-verifier)_
