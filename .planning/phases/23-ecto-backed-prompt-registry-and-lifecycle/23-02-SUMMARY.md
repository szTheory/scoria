---
phase: 23
plan: 02
subsystem: prompt_registry
tags:
  - ecto
  - schema
  - migrations
requires:
  - ecto
provides:
  - Scoria.PromptRegistry.PromptTemplate
  - ai_prompt_templates table
affects:
  - Database schema
tech-stack:
  added: []
  patterns:
    - Immutable table pattern with versioning
    - Structured Ecto schema for text generation maps
key-files:
  created:
    - priv/repo/migrations/20260518211100_create_ai_prompt_templates.exs
    - lib/scoria/prompt_registry/prompt_template.ex
    - test/scoria/prompt_registry/prompt_template_test.exs
  modified: []
decisions:
  - Used exact table pattern analog of ai_eval_specs for ai_prompt_templates via unique version constraints.
  - Test helper errors_on recreated locally since standard Scoria.DataCase wasn't immediately available, avoiding structural modification of test support.
duration: 10m
completed: 2026-05-18
---

# Phase 23 Plan 02: Ecto Prompt Schema Summary

Ecto schema and database migration created for storing versioned, structured prompt templates.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

**Warning:** Task 2 was marked `tdd="true"` but implemented in a single commit (`2a1161b`) spanning RED and GREEN phases simultaneously. Separate `test(...)` and `feat(...)` commits were missing in the timeline.

## Known Stubs

None.

## Threat Flags

None.
