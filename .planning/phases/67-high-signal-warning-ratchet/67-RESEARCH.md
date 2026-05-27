# Phase 67: High-Signal Warning Ratchet — Research

**Researched:** 2026-05-27
**Domain:** Elixir compiler WAE, warning inventory clusters, staged ratchet gates
**Confidence:** HIGH (builds on Phase 66 shipped SSOT; CONTEXT locked scope)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Fix p3 in `test/scoria/` + targeted `test/scoria_web/live/`; defer p2 CI WAE; hold p0+p1; keep p4 baselined unless compile WAE
- Five plans in serial waves 67-00 → 67-04; no full-suite WAE as plan gate
- `Scoria.WarningRatchet` SSOT for high-signal paths; no path derivation from baseline JSON
- Knowledge migrator: migrate-once + scoped `ignore_module_conflict` (D-11); structural DDL refactor deferred
- Overlay stays in `priv/host_app_proof/overlay/test/`; generator/runner WAE-clean
- Inventory `--write` + `warning_baseline.check` at end of each fix plan

### Deferred Ideas (OUT OF SCOPE)
- Full-suite WAE in CI (Phase 68 / WARN-07)
- `mix scoria.warning_ratchet.test` in CI test job (Phase 68)
- CI-03 documentation bundle (Phase 69)
- `mix scoria.warning_inventory --fix`
- Baselining `:unclassified_compile` or `:host_proof_*` counts

### Claude's Discretion
- WarningRatchet API naming; new cluster atoms; contract test placement; schema_version bumps
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Plans |
|----|-------------|-------|
| WARN-05 | `mix compile --warnings-as-errors` + canonical lane-contract tests remain green | 67-01 |
| WARN-06 | High-signal test surfaces pass under scoped WAE via WarningRatchet SSOT | 67-00, 67-02, 67-03, 67-04 |
</phase_requirements>

## Executive Summary

Phase 67 turns Phase 66's warning inventory into a **staged ratchet**: hold compile and policy-job lane contracts (WARN-05), then clear p3 clusters in `test/scoria/` and targeted LiveView tests while documenting deferred p2/p4 debt (WARN-06). The implementation extends existing `Scoria.WarningInventory` / `mix scoria.warning_inventory` rather than new parallel tooling.

**Primary recommendation:** Ship `Scoria.WarningRatchet` + `mix scoria.warning_ratchet.test` in plan 67-00, verify WARN-05 in 67-01, fix clusters tier-by-tier in 67-02–67-04, refresh committed inventory artifacts after each wave.

## Standard Stack

### Core
| Component | Version | Purpose |
|-----------|---------|---------|
| Elixir / Mix | 1.19 / project | `compile --warnings-as-errors`, `test --warnings-as-errors` |
| ExUnit | built-in | Lane-contract and ratchet path tests |
| Jason | project | `warning-inventory.baseline.json` |
| Scoria.WarningInventory | Phase 66 | Classify, `ratchet_tier/1`, `--write` artifacts |
| Scoria.WarningBaseline | Phase 66 | Expiry meta-gate before ratchet |
| Scoria.VerificationLanes | prior | Closeout order unchanged |

### Supporting
| Component | Purpose |
|-----------|---------|
| `Mix.Tasks.Scoria.Test.Adoption` | `adoption_test_files/0` for p2 path SSOT |
| `Scoria.TestSupport.Migrations` | Knowledge migrator isolation (D-11) |
| `test/scoria/ci_policy_contract_test.exs` | Policy job order; extend for WarningRatchet docs |

### Alternatives Considered
| Instead of | Use | Why |
|------------|-----|-----|
| Per-line warning JSON in git | Cluster-count baseline JSON | Phase 66 D-17; merge-friendly |
| Full-suite WAE in 67 | Scoped `warning_ratchet.test` | WARN-07 deferred; avoids false confidence |
| Global `ignore_module_conflict` in test.exs | Scoped in `migrate_knowledge!/0` | CONTEXT D-11; Rust-style boundary |

## Architecture Patterns

### Staged ratchet pipeline
```
warning_baseline.check → compile WAE → lane-contract WAE (CI policy)
  → warning_ratchet.test (maintainer / Phase 67 verify)
  → full mix test WAE (Phase 68)
```

### WarningRatchet path composition
```elixir
# lib/scoria/warning_ratchet.ex (sketch)
def high_signal_wae_paths do
  adoption = Mix.Tasks.Scoria.Test.Adoption.adoption_test_files()
  live_globs = Path.wildcard("test/scoria_web/live/**/*_test.exs")
  scoria_unit = Path.wildcard("test/scoria/**/*_test.exs")

  (adoption ++ live_globs ++ scoria_unit)
  |> Enum.uniq()
  |> Enum.sort()
end
```
Paths are **code SSOT**, not parsed from `.planning/warning-inventory.baseline.json` (cluster counts only).

### Inventory capture (unchanged from 66)
```elixir
System.cmd("mix", ["do", "compile", "--force", "+", "test"],
  env: [{"MIX_ENV", "test"}],
  stderr_to_stdout: true
)
```
Capture mode tolerates non-zero exit; WAE gates do not.

### Knowledge migration fix (D-11)
- `ensure_knowledge_migrated!/0` with `:persistent_term` gate
- `Code.put_compiler_option(:ignore_module_conflict, true)` only inside `migrate_knowledge!/0` `try/after`
- Double-call retained only in `migration_lane_compatibility_test.exs`

### Anti-Patterns
- Running DB tests in `policy` job — violates D-17
- Baselining `:unclassified_compile` in high-signal paths — use registry or fix code
- Using `test/support/.../overlay/test/` for host proof — regression; guard in 67-02

## Don't Hand-Roll

| Problem | Use Instead |
|---------|-------------|
| Path lists for WAE | `WarningRatchet.high_signal_wae_paths/0` |
| Warning classification | `WarningInventory.Cluster.match/1` |
| Adoption file list | `adoption_test_files/0` |
| CI closeout order | `VerificationLanes.closeout_order/0` |

## Common Pitfalls

1. **Dirty `test/tmp/`** — inventory preflight raises; document cleanup in operator_verification.md
2. **p1 not in `ratchet_tier/1`** — lane-contract files enforced via explicit CI list, not cluster tier (D-28)
3. **Inventory before fixes** — 67-00 establishes baseline; each fix plan ends with `--write` + `warning_baseline.check`
4. **Full-suite WAE as plan verify** — forbidden per D-24; use scoped paths only

## Code Examples

### Scoped ratchet test command
```bash
MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors
# internally: mix test --warnings-as-errors <paths from WarningRatchet>
```

### Fail on unclassified high-signal
```elixir
def fail_on_unclassified_high_signal!(rows) do
  offenders =
    Enum.filter(rows, fn row ->
      row.cluster_id == :unclassified_compile and high_signal_path?(row.file)
    end)

  if offenders != [] do
    Mix.raise("unclassified compile warnings in high-signal paths: #{inspect(offenders)}")
  end
end
```

### Overlay regression guard
```elixir
test "host proof overlay is not under test/support" do
  refute File.exists?("test/support/scoria/host_app_proof/overlay/test")
  assert File.dir?("priv/host_app_proof/overlay/test")
end
```

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Quick run** | `MIX_ENV=test mix test test/scoria/warning_inventory/` |
| **WARN-05 gate** | `MIX_ENV=test mix compile --warnings-as-errors` + lane-contract WAE |
| **WARN-06 gate** | `MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` |
| **Inventory refresh** | `MIX_ENV=test mix scoria.warning_inventory --write --scope full` |
| **Meta-gate** | `mix scoria.warning_baseline.check` |
| **CI proof (67)** | Policy job unchanged; contract test asserts WarningRatchet SSOT non-empty |

Nyquist: Every plan task has `<automated>` verify; no full-suite inventory in unit tests.

## State of the Art

| Pattern | Scoria mapping |
|---------|----------------|
| Braintrust/Langfuse baseline compare | `warning-inventory.baseline.json` cluster counts shrink per phase |
| ESLint unused-directive reporting | Cluster registry atoms, not per-line caps |
| Oban lint-before-proof | policy job before Postgres test job |

## Open Questions

1. **Exact LiveView glob for WARN-06** — Recommendation: `test/scoria_web/live/**/*_test.exs` only; exclude non-live paths unless inventory shows compile warnings elsewhere.
2. **`--fail-on-unclassified` on inventory vs ratchet.check** — Recommendation: implement on `mix scoria.warning_ratchet.check` calling inventory parser; inventory `--write` stays capture-only.
3. **New cluster atoms for MCP unused import** — Recommendation: add `:test_unused_import` if message stable; else fix inline in same PR as registry rule.

## RESEARCH COMPLETE
