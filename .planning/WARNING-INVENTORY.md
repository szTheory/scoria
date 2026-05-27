# Warning Inventory

Generated: 2026-05-27T23:21:15.126354Z
Git SHA: 9b3d6e81d99cd3365cdacbec87edd4cdf30ce1f5
Scope: full

## Phase 68-03 Closeout (2026-05-27)

Full scope after `rm -rf test/tmp/*` with `SCORIA_DB_PORT=55432`:

| Cluster | Count |
|---------|------:|
| (all clusters) | 0 |

**Outcome:** Path A — full WARN-07 success. `MIX_ENV=test mix test --warnings-as-errors` green locally; baseline ledger moved to `Resolved During v2.6`; `"clusters": {}` committed.

Verified:

- `mix scoria.warning_baseline.check` — pass
- `MIX_ENV=test mix test --warnings-as-errors` — pass (457 tests)
- `MIX_ENV=test mix compile --warnings-as-errors` — pass

## Phase 68-02 Measurement (2026-05-27)

Full scope after `rm -rf test/tmp/*`:

| Cluster | Count |
|---------|------:|
| :host_proof_generated_compile | 0 |
| :host_overlay_test_path | 0 |

**Outcome:** p2 already clean — no support/overlay code changes required.

## Phase 67 Ratchet Queue

| Cluster | Count | Ratchet Tier |
|---------|------:|--------------|


## Phase 67 — Fixed vs Deferred

| Cluster | Action | Owner | Expiry / Notes |
|---------|--------|-------|----------------|
| :test_unused_binding | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :test_dead_default_args | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :knowledge_migration_redefine | fix | @scoria-core | migrate-once + scoped ignore_module_conflict (D-11) |
| :unclassified_compile | fix | @scoria-core | zero in high-signal scope; classify or fix code |
| :host_proof_generated_compile | **verified clean** | @scoria-core | Phase 68-02 — zero rows |
| :host_overlay_test_path | **verified clean** | @scoria-core | Phase 68-02 — zero rows |
| :liveview_async_teardown | **fixed** | @scoria-web-runtime | Phase 68-03 render_async sweep; zero in full inventory |

