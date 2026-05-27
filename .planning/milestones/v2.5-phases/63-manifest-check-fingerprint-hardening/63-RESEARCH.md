# Phase 63 Research — Manifest Check Fingerprint Hardening

**Researched:** 2026-05-27  
**Phase:** 63 — Manifest Check Fingerprint Hardening  
**Confidence:** HIGH

## Summary

Phase 63 closes the v2.5 audit integration gap `manifest-check-fingerprint` without changing tri-state check semantics or apply-time freshness gates. The bug is **documentation and dead-code honesty**, not missing drift detection: surface analyzers already set live `:fingerprint` on every entry; `Planner.normalize_contract_fields/4` uses `Map.put_new(:fingerprint, manifest_entry[:fingerprint] || "unavailable")` which **never runs** because analyzers always pre-populate `:fingerprint`.

Check classification and exit codes derive from live surface analysis only (`Report.check_result/1`). Apply blocks stale plans via `Manifest.validate_freshness/2` comparing plan entry fingerprint (built at plan time) to live disk — independent of stored manifest file at check time.

## Current State (Evidence)

| Surface | Fingerprint source at plan build | Manifest influence today |
|---------|-----------------------------------|--------------------------|
| Router | `Router.analyze/2` → `fingerprint(content)` | `put_new` no-op |
| Tailwind | `Tailwind.analyze/2` | `put_new` no-op |
| Runtime config | `RuntimeConfig.analyze/2` | `put_new` no-op |
| Migrations | `Migrations.analyze/2` structural hash | `put_new` no-op |
| Check exit | Entry `:classification` only | None |
| Apply gate | `validate_freshness/2` plan vs disk | None from manifest file |

### Audit gap (v2.5-MILESTONE-AUDIT.md)

```yaml
- id: manifest-check-fingerprint
  severity: low
  evidence: Planner loads manifest but Map.put_new(:fingerprint) never overrides surface fingerprints
```

### Locked decisions (63-CONTEXT.md)

- **Live-host-only check** — reject manifest-baseline drift at check time (D-01–D-03).
- **Remove dead merge** — do not switch to `Map.put/3` (D-04).
- **Informational manifest only** at check — `manifest_state`, optional `manifest_fingerprint` per entry (D-05, D-14–D-17).
- **Split docs** — operator guide subsection + maintainer `@moduledoc` (D-11–D-13).
- **Tests** — tampered manifest unchanged exit; absent manifest no tri-state change (D-18–D-19).

## Recommended Approach

Three implementation waves (two plans + doc/test plan):

1. **Planner honesty** — Remove `put_new(:fingerprint, …)` from manifest; attach `manifest_state: :absent | :present` on plan; optional per-entry `manifest_fingerprint` when stored entry exists; add `@moduledoc` on `Planner` and `Manifest` describing check vs apply roles.
2. **Report additive output** — Top-level JSON `manifest` object; one human manifest context line (present and absent variants pinned); extend `Contract` with manifest metadata key constants; `Mix.Tasks.Scoria.Install` `## Apply freshness` moduledoc slice.
3. **Docs + contract tests** — `docs/operator_verification.md` subsection; adoption_surface pins; tests proving tampered manifest / absent manifest do not alter check classification or exit.

Keep `Contract.schema_version/0` at `"1.0"` — additive fields only (CONTEXT discretion).

## Risks

| Risk | Mitigation |
|------|------------|
| Accidentally using `Map.put` for fingerprint | Remove manifest branch entirely; surface fingerprint is authoritative |
| Breaking mode equivalence | Same manifest metadata in dry-run and check render paths |
| False CI signal on missing manifest | D-07/D-09: absent manifest informational only |
| Regressing stale-apply test | Do not change `validate_freshness/2` or apply_executor gate |

## Validation Architecture

| Check | Command / method |
|-------|------------------|
| Dead merge removed | `rg 'put_new\\(:fingerprint, manifest_entry' lib/scoria/install/planner.ex` returns no match |
| manifest_state present | `rg 'manifest_state' lib/scoria/install/planner.ex` returns match |
| JSON manifest block | `rg '\"manifest\"' lib/scoria/install/report.ex` or `rg 'check_role' lib/scoria/install/report.ex` |
| Operator doc subsection | `rg 'Check vs apply drift detection' docs/operator_verification.md` |
| Tampered manifest test | `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs --only manifest` or dedicated test file |
| Stale apply preserved | `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs` includes stale fingerprint test green |
| Mode equivalence | `MIX_ENV=test mix test test/scoria/install/mode_equivalence_test.exs` exits 0 |
| Adoption pins | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` exits 0 |

Quick run: `MIX_ENV=test mix test test/scoria/install/ test/mix/tasks/scoria.install_check_test.exs test/mix/tasks/scoria.install_test.exs`  
Full installer slice: `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs test/scoria/install/mode_equivalence_test.exs test/scoria/adoption_surface_test.exs`

## RESEARCH COMPLETE
