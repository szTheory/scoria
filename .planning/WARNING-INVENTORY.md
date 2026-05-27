# Warning Inventory

Generated: 2026-05-27T19:01:21.429677Z
Git SHA: 689868b26ee52d2cffea05095f145ebf300b7965
Scope: full

## Phase 67 Ratchet Queue

| Cluster | Count | Ratchet Tier |
|---------|------:|--------------|
| test_unused_binding | 2 | p3_high_signal_tests |
| test_dead_default_args | 1 | p3_high_signal_tests |

## Phase 67 — Fixed vs Deferred

| Cluster | Action | Owner | Expiry / Notes |
|---------|--------|-------|----------------|
| :test_unused_binding | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :test_dead_default_args | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :knowledge_migration_redefine | fix | @scoria-core | migrate-once + scoped ignore_module_conflict (D-11) |
| :unclassified_compile | fix | @scoria-core | zero in high-signal scope; classify or fix code |
| :host_proof_generated_compile | defer | @scoria-core | p2 guard only; overlay stays in priv/ |
| :host_overlay_test_path | defer | @scoria-core | p2 guard only; no CI adoption WAE in Phase 67 |
| :liveview_async_teardown | defer | @scoria-web-runtime | p4 baselined until 2026-06-30 |

