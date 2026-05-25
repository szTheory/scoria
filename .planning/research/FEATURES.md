# Project Research - Features

**Milestone:** `v2.2 OSS adopter onramp`
**Date:** 2026-05-25
**Question:** How should a release-grade OSS adoption milestone behave for Scoria, and which features are table stakes versus differentiators?

## Category 1: Release Packaging And Docs

**Table stakes**

- publishable Hex metadata is present and truthful
- `mix docs` builds cleanly from repo state
- public docs expose one clear entry path for the default runtime lane
- the package includes migrations and required runtime assets

**Differentiators**

- docs are lane-based, so teams understand what to adopt first versus later
- source links and docs extras point to real maintained guides instead of stale placeholders

**Research notes**

For a public Elixir package, release readiness is not just "can compile." The package metadata, docs build, and included file inventory are part of the adopter-facing surface.

## Category 2: Host-App Install Contract

**Table stakes**

- `mix scoria.install` works against a normal Phoenix router layout
- copied migrations are enough to make the default lane bootable
- Tailwind remains optional instead of a hidden install prerequisite
- runtime defaults are injected exactly once

**Differentiators**

- installer output explains the next proof steps in the same lane vocabulary used by the docs
- install behavior degrades cleanly when optional assets or optional knowledge features are absent

**Research notes**

The installer is not just scaffolding convenience anymore. It is part of Scoria's product contract with a host app.

## Category 3: Consumer-App Proof

**Table stakes**

- one fresh Phoenix app path proves dependency fetch, install, migrate, and route visibility
- the default runtime lane is verified without first requiring pgvector or semantic-cache setup
- proof can be run reproducibly in CI or on a maintainer machine

**Differentiators**

- a canonical fixture or script proves the exact adoption path maintainers recommend publicly
- bounded follow-up lanes for handoffs and semantic fast path remain additive, not mixed into the default proof

**Research notes**

The most valuable proof is the one that mirrors a new adopter's first 15 minutes. Anything that requires repo-only context weakens support truth.

## Category 4: Support Truth And Scope Guard

**Table stakes**

- docs name the default lane, optional knowledge lane, bounded handoff lane, and semantic fast-path lane consistently
- each lane states prerequisites and denial/fallback behavior
- maintainers can point support questions at one canonical verification lane per surface

**Differentiators**

- operator verification, README, and Mix-task output all reinforce the same adoption order
- the package clearly separates "core adoption" from "optional advanced surfaces"

**Research notes**

This is where Scoria can stay boring to adopt without collapsing into a giant feature checklist. The win is clear sequencing and truthful prerequisites.

## Anti-Features

- first publish blocked on optional knowledge setup
- docs that imply Hex publishability while `mix docs` still fails locally
- installer flows that silently depend on Tailwind, pgvector, or repo-only assumptions
- consumer proof that exercises internal test hooks but not a real host-app path

## Recommended Scope Shape

`v2.2` should focus on:

1. release packaging and docs truth
2. install-contract closure for the default Phoenix lane
3. a canonical consumer-app proof path
4. support-truth alignment across docs, tasks, and verification

Defer:

- package-family decomposition
- advanced examples beyond what the default adoption lane requires
- external semantic-cache infrastructure

## External References

- Hex publish guide: https://hex.pm/docs/publish
- ExDoc configuration: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
