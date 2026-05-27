# Warning Inventory

Generated: 2026-05-27T19:11:53.625377Z
Git SHA: 078901ac472f5107a597221c77bd70d87f70dccb
Scope: full

## Phase 67 Ratchet Queue

| Cluster | Count | Ratchet Tier |
|---------|------:|--------------|


## Phase 67 — Fixed vs Deferred

| Cluster | Action | Owner | Expiry / Notes |
|---------|--------|-------|----------------|
| :test_unused_binding | **fixed** | @scoria-core | Phase 67 plans 67-03/67-04 — zero rows in full inventory |
| :test_dead_default_args | **fixed** | @scoria-core | Phase 67 plans 67-03/67-04 — zero rows in full inventory |
| :knowledge_migration_redefine | **fixed** | @scoria-core | migrate-once + scoped ignore_module_conflict (D-11) |
| :unclassified_compile | **fixed** | @scoria-core | zero in high-signal scope (WARN-06 ratchet.check) |
| :host_proof_generated_compile | defer | @scoria-core | p2 — adoption CI WAE deferred to Phase 68 (D-16) |
| :host_overlay_test_path | defer | @scoria-core | p2 — adoption CI WAE deferred to Phase 68 (D-16) |
| :liveview_async_teardown | defer | @scoria-web-runtime | p4 baselined until **2026-06-30** (D-04) |

