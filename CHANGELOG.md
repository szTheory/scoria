# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

Published Hex releases use `[0.x.y]` version headings in this file. Internal planning
milestones (`v2.x` in [`.planning/MILESTONES.md`](.planning/MILESTONES.md)) track delivery
tranches inside the repository — they are **not** a second install axis and do not map to
Hex versions (there is no Hex `2.7.0` matching a GSD milestone label).

## [Unreleased]

## [0.1.0]

First public Hex packaging of Scoria's in-repo capability through the v2.6 warning-ratchet
closeout. Integrators get a Phoenix-native runtime with durable runs, bounded escalation,
optional semantic reuse, and executable adoption lanes — without adopting internal planning
milestone names as product releases.

### Added

- **Default runtime** — identity-aware durable runs, approvals, and operator evidence via
  `Scoria.start_run/2`, `Scoria.resume_run/2`, and `/scoria` inspection surfaces; prove with
  `mix scoria.test.adoption`.
- **Bounded handoff** — narrow same-run delegation with projected context and visible lineage
  through `Scoria.start_handoff_run/3`; prove with `mix scoria.test.runtime_to_handoff`.
- **Semantic fast path** — tenant-scoped reuse for explicitly safe read-only lanes via
  `Scoria.SemanticLane`; prove with `mix scoria.test.semantic_fast_path`.
- **Optional knowledge** — pgvector-backed retrieval when chosen; prove with
  `mix scoria.test.knowledge`.
- **Upgrade-safe install** — planner/check/apply paths via `mix scoria.install --dry-run`,
  `mix scoria.install --check`, and `mix scoria.install`.
- **Maintainer CI trust** — warning baseline and ratchet enforcement, policy→test topology
  guarded by contract tests, and local parity via `mix scoria.test.ci_trust` (maintainer-only;
  not an adopter integration requirement).

### Roadmap traceability

| Planning tranche | Shipped | Reference |
|------------------|---------|-----------|
| v2.1 | 2026-05-25 | [`.planning/MILESTONES.md#v21-tenant-scoped-semantic-fast-path`](.planning/MILESTONES.md) |
| v2.3 | 2026-05-27 | [`.planning/MILESTONES.md#v23-runtime-to-handoff-adoption-example`](.planning/MILESTONES.md) |
| v2.4 | 2026-05-27 | [`.planning/MILESTONES.md#v24-adoption-reliability-contract`](.planning/MILESTONES.md) |
| v2.5 | 2026-05-27 | [`.planning/MILESTONES.md#v25-installer-safety--upgrade-confidence`](.planning/MILESTONES.md) |
| v2.6 | 2026-05-28 | [`.planning/MILESTONES.md#v26-warning-ratchet`](.planning/MILESTONES.md) |
