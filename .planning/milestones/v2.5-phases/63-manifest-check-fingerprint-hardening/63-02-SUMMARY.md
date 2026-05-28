---
phase: 63-manifest-check-fingerprint-hardening
plan: 02
subsystem: install
tags: [installer, report, json, operator-output]

requires:
  - phase: 63-01
    provides: manifest_state and manifest_path on plan map
provides:
  - Contract manifest role SSOT
  - Additive JSON manifest map and human context lines
  - mix help Apply freshness section
affects: [63-03]

key-files:
  modified:
    - lib/scoria/install/contract.ex
    - lib/scoria/install/report.ex
    - lib/mix/tasks/scoria.install.ex
    - test/scoria/install/report_test.exs

requirements-completed: [INST-07]

completed: 2026-05-27
---

# Phase 63 Plan 02 Summary

**Exposed manifest check vs apply roles in human, JSON, and mix help without changing tri-state semantics.**

## Accomplishments

- Contract functions for `manifest_check_role`, `manifest_apply_role`, and `manifest_json_keys`
- Report JSON `manifest` map and human context lines for present/absent states
- `mix help scoria.install` documents apply freshness with operator guide pointer

## Self-Check: PASSED

- report_test.exs and install_check_test.exs green
- mix help includes Apply freshness
