# Project Research Summary

**Milestone:** `v2.2 OSS adopter onramp`
**Date:** 2026-05-25

## Recommendation

Treat `v2.2` as adoption closure, not capability expansion: make Scoria publishable, installable in a fresh Phoenix host, and supportable through one truthful default-lane verification story.

## Stack Additions

- add `:ex_doc` so `mix docs` is real, not aspirational
- add a release-preview lane for docs build and package inventory
- add a canonical consumer-app fixture or generated host-app harness
- keep publish/adoption helpers inside Mix-task and test-support seams

## Feature Table Stakes

- truthful Hex metadata and docs build
- default-lane install contract that works without optional Tailwind or knowledge prerequisites
- consumer proof for dependency -> install -> migrate -> runtime -> operator inspection
- canonical lane-based support wording across README, guides, and task output

## Watch Out For

- metadata claiming publishability before docs actually build
- repo-only proof mistaken for fresh-adopter proof
- optional knowledge or semantic lanes bleeding into the default adoption path
- installer/docs/task-output drift
- incorrect package file inventory at first publish

## Architecture Direction

Keep the milestone inside the embedded Scoria boundary:

- `core`: package metadata, docs build, installer contract, consumer proof, support-truth alignment
- `defer`: advanced handoff examples, package splits, external semantic-cache backends

## Suggested Requirement Categories

1. Packaging and docs truth
2. Host-app install contract
3. Consumer-app proof
4. Support-truth alignment

## Sources

- STACK: `.planning/research/STACK.md`
- FEATURES: `.planning/research/FEATURES.md`
- ARCHITECTURE: `.planning/research/ARCHITECTURE.md`
- PITFALLS: `.planning/research/PITFALLS.md`
- Hex publish guide: https://hex.pm/docs/publish
- Mix project configuration: https://hexdocs.pm/mix/Mix.Project.html
- ExDoc configuration: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
