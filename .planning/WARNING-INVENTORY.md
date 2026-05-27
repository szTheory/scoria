# Warning Inventory

Generated: 2026-05-27T18:13:56.713139Z
Git SHA: 60ca8043838ac8b1f00473a60d4e21f417698765
Scope: full

## Phase 67 Ratchet Queue

| Cluster | Count | Ratchet Tier |
|---------|------:|--------------|
| test_unused_binding | 2 | p3_high_signal_tests |
| knowledge_migration_redefine | 2 | p4_baselined_deferred |
| unclassified_compile | 4 | p5_out_of_scope |

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

