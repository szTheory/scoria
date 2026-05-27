# Warning Inventory

Generated: 2026-05-27T18:25:05.152755Z
Git SHA: f00a650ccc01dad2896faeee3092d9834d7a9be4
Scope: full

## Phase 67 Ratchet Queue

| Cluster | Count | Ratchet Tier |
|---------|------:|--------------|
| test_unused_binding | 2 | p3_high_signal_tests |
| test_dead_default_args | 2 | p3_high_signal_tests |

## Phase 67 — Fixed vs Deferred

| Cluster | Action | Owner | Expiry / Notes |
|---------|--------|-------|----------------|
| :knowledge_migration_redefine | fixed | @scoria-core | Plan 67-02 D-11 migrate-once + scoped ignore_module_conflict |
| :unclassified_compile | fixed | @scoria-core | Plan 67-02 adoption-lane cleared; cluster rules for install fixtures |
| :test_unused_import | fixed | @scoria-core | Plan 67-02 registry rule for install host router compile |
| :install_fixture_undefined_ref | fixed | @scoria-core | Plan 67-02 registry rule for PageController in install tests |
| :test_unused_binding | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :test_dead_default_args | fix | @scoria-core | Phase 67 plan 67-03/67-04 |
| :host_proof_generated_compile | defer | @scoria-core | p2 guard only; overlay stays in priv/ |
| :host_overlay_test_path | defer | @scoria-core | p2 guard only; no CI adoption WAE in Phase 67 |
| :liveview_async_teardown | defer | @scoria-web-runtime | p4 baselined until 2026-06-30 |

