# Warning Inventory

Generated: 2026-05-27T19:11:53.625377Z
Git SHA: 078901ac472f5107a597221c77bd70d87f70dccb
Scope: full

## Phase 68-02 Measurement (2026-05-27)

Full scope after `rm -rf test/tmp/*` (`MIX_ENV=test mix scoria.warning_inventory --scope full --format table`):

| Cluster | Count |
|---------|------:|
| :host_proof_generated_compile | 0 |
| :host_overlay_test_path | 0 |

**Outcome:** p2 already clean at measurement — targeted support/overlay code fixes skipped (68-02-02/03).

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
| :host_proof_generated_compile | **verified clean** | @scoria-core | Phase 68-02 — zero rows; no support-path code changes required |
| :host_overlay_test_path | **verified clean** | @scoria-core | Phase 68-02 — zero rows; overlay templates unchanged |
| :liveview_async_teardown | defer | @scoria-web-runtime | p4 baselined until **2026-06-30** (D-04) |

