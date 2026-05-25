# Project Research - Architecture

**Milestone:** `v2.2 OSS adopter onramp`
**Date:** 2026-05-25
**Question:** How should an OSS adopter-readiness milestone integrate with Scoria's existing architecture?

## Existing Integration Points

- `Scoria` already exposes the public runtime facade that the default adoption story should prove.
- `Mix.Tasks.Scoria.Install` is the central host-app mutation seam for router wiring, migration copy, and baseline config defaults.
- `Mix.Tasks.Test.Adoption` already acts as the bounded proof lane for install, docs, route, and runtime-surface assertions.
- `Scoria.TestSupport.Migrations` already contains the pattern for task-scoped setup of optional data surfaces without leaking repo lore into docs.

## Proposed Flow

### 1. Release-surface verification

At maintainer time, verify that the package boundary itself is coherent:

- `mix.exs` metadata is complete
- docs build through `mix docs`
- package file inventory includes required code, migrations, README, and guides

### 2. Host-app installation proof

From a fresh Phoenix consumer path:

- add dependency
- run `mix deps.get`
- run `mix scoria.install`
- run `mix ecto.migrate`
- boot the host app and verify `/scoria` routes resolve

### 3. Runtime facade proof

From that same host-app path, prove one durable run can be:

- started through `Scoria.start_run/2`
- read back through `Scoria.get_run/1` or `Scoria.list_runs_for_session/1`
- inspected through `/scoria/workflows/:run_id`

### 4. Optional lane isolation

Keep bounded handoffs, semantic fast path, and the knowledge lane separate:

- default lane proof must not require optional knowledge setup
- semantic fast path retains its own named proof lane
- docs and task output should explicitly tell adopters when they are leaving the default lane

## Recommended Boundaries

### Core

- package metadata and docs buildability
- installer contract
- migration-copy truth
- default-lane consumer proof
- support-truth docs alignment

### Companion / later

- polished example apps beyond the canonical proof harness
- wider demo stories for replay, handoffs, or eval operations
- package splitting or adapter families

## Capability Selection Rubric

| Capability family | Route-owner expectation | Bridge frequency | Policy sensitivity | Support-matrix impact | Proof required | Package classification |
|-------------------|-------------------------|------------------|--------------------|-----------------------|----------------|------------------------|
| Default runtime lane adoption | High | Native screen | Medium | High | Merge-blocking | `core` |
| Consumer-app fixture / proof harness | High | Low-frequency semantic | Low | High | Merge-blocking | `core` |
| Bounded-handoff docs/examples | Medium | Defer | Medium | Medium | Advisory unless scope expands | `defer` |
| Semantic-cache backend expansion | Low for this milestone | Defer | Medium | High | Not required now | `defer` |

## Packaging Ledger

| Surface | Classification | Reason |
|---------|----------------|--------|
| Hex metadata and docs configuration | `core` | Public package trust starts here |
| `mix scoria.install` contract | `core` | Primary host-app adoption seam |
| Consumer-app proof fixture or harness | `core` | Closes the adopter reality gap |
| Lane-based docs and verification guides | `core` | Support truth depends on them |
| Advanced handoff example expansion | `defer` | Only needed if support evidence shows confusion |
| External semantic cache backends | `defer` | Capability expansion, not adoption closure |

## Proof Posture Gate

- Merge-blocking hermetic proof:
  - package metadata and docs build locally
  - installer and adoption lanes pass
  - consumer-app proof or equivalent harness passes
- Advisory proof:
  - semantic fast path remains green on its dedicated lane
  - broader full-suite repo health remains informative but non-blocking for this milestone

## Support Truth Gate

- Missing Tailwind: installer skips component-content injection and says so explicitly
- Missing optional knowledge setup: default lane still installs and proves core runtime behavior
- Semantic fast path requested: docs route the user to `mix test.semantic_fast_path`
- Native rebuilds required: any host-app route or asset mutation must be explicit in installer output and docs

## Build Order

1. release metadata and docs build closure
2. installer contract hardening and file-inventory proof
3. consumer-app proof harness
4. docs/support-truth alignment and closeout verification

## External References

- Hex publish guide: https://hex.pm/docs/publish
- Mix project configuration: https://hexdocs.pm/mix/Mix.Project.html
- ExDoc configuration: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
