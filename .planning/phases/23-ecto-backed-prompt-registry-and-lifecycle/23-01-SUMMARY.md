---
phase: 23
plan: 01
subsystem: Prompt Registry
tags: prompts, tokenizer, tiktoken
---

# Phase 23 Plan 01: Setup the Tiktoken dependency and create the token estimation utility Summary

**Plan:** 23-01
**Subsystem:** Prompt Registry
**Tags:** prompts, tokenizer, tiktoken

## Dependency Graph
- **Requires:** Phoenix/Ecto (core)
- **Provides:** Token estimation capability via `Scoria.PromptRegistry.Tokenizer`
- **Affects:** Operator warnings for context limits

## Tech Stack
- **Added:** `{:tiktoken, "~> 0.4.2"}`
- **Patterns:** Stateless utility module (similar to `lib/scoria/observe/redactor.ex`)

## Key Files
- **Created:** `lib/scoria/prompt_registry/tokenizer.ex`
- **Created:** `test/scoria/prompt_registry/tokenizer_test.exs`
- **Modified:** `mix.exs`
- **Modified:** `mix.lock`

## Decisions Made
- Used the `tiktoken` hex package with the native Rust bindings to handle accurate prompt token estimation for `gpt-4o`.
- Handled potential string or atom keys in prompt template maps uniformly.
- Implemented robust nil-handling and concatenation strategies for upper-bound token estimation without risking crashes.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## TDD Gate Compliance
- A `test(...)` commit exists (`c23b54c test(23-01): add failing test for tokenizer utility`).
- A `feat(...)` commit exists (`269ad3b feat(23-01): implement tokenizer utility`).

## Performance Metrics
- **Duration:** 10 minutes
- **Completed Date:** 2026-05-18

## Self-Check: PASSED
