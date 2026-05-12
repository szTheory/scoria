---
phase: 06
slug: corpus
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-11
---

# Phase 6 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test test/scoria/knowledge_test.exs` |
| Full suite command | `MIX_ENV=test mix test` |
| Estimated runtime | ~20 seconds |

## Sampling Rate

- After every task commit: Run `MIX_ENV=test mix test <targeted files>`
- After every plan wave: Run `MIX_ENV=test mix test`
- Before `$gsd-verify-work`: Full suite must be green
- Max feedback latency: 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-00-01 | 00 | 0 | RAG-02,RAG-08 | T-06-00-01 | pgvector support is provisioned or positively verified before vector-backed verification starts | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres SCORIA_DB_NAME=scoria_dev mix scoria.pgvector.bootstrap --check` | ✅ | ✅ passed |
| 06-00-02 | 00 | 0 | RAG-02,RAG-08 | T-06-00-02 | Shared test scaffolding enforces the prerequisite consistently | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge_test.exs` | ✅ | ✅ passed |
| 06-01-01 | 01 | 1 | RAG-02,RAG-03 | T-06-01-01 | Corpus tables and indexes are explicit and additive | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge_test.exs` | ✅ | ✅ passed |
| 06-01-02 | 01 | 1 | RAG-01,RAG-03,RAG-08 | T-06-01-02 | Durable schemas validate explicit corpus and provenance nouns | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge_test.exs` | ✅ | ✅ passed |
| 06-01-03 | 01 | 1 | RAG-01,RAG-03,RAG-08 | T-06-01-03 | Public context exposes explicit lifecycle APIs over the durable nouns | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge_test.exs` | ✅ | ✅ passed |
| 06-02-01 | 02 | 2 | RAG-01,RAG-02 | T-06-02-01 | Backend boundary keeps pgvector default but replaceable | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/pgvector_test.exs` | ✅ | ✅ passed |
| 06-02-02 | 02 | 2 | RAG-07 | T-06-02-02 | Scrypath is normalized as an optional adapter only | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/scrypath_test.exs` | ✅ | ✅ passed |
| 06-03-01 | 03 | 3 | RAG-03,RAG-04 | T-06-03-01 | Retrieval and citation writes preserve durable provenance | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/retrieval_test.exs` | ✅ | ✅ passed |
| 06-03-02 | 03 | 3 | RAG-04 | T-06-03-02 | Citation anchors are machine-readable and offset-valid | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/citation_formatter_test.exs` | ✅ | ✅ passed |
| 06-04-01 | 04 | 4 | RAG-05 | T-06-04-01 | Deterministic citation and grounding checks gate before judge review | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/grounding_test.exs` | ✅ | ✅ passed |
| 06-04-02 | 04 | 4 | RAG-05 | T-06-04-02 | Judge rubric versions are persisted and auditable | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria/knowledge/grounding_test.exs` | ✅ | ✅ passed |
| 06-05-01 | 05 | 5 | RAG-06,RAG-08 | T-06-05-01 | Evidence projection is async and trace-first | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs` | ✅ | ✅ passed |
| 06-05-02 | 05 | 5 | RAG-06,RAG-08 | T-06-05-02 | Install and routing changes stay additive and idempotent | unit | `env SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/scoria_web/router_test.exs` | ✅ | ✅ passed |

## Wave 0 Requirements

- [x] Wave 0 bootstrap slice exists: `06-00-PLAN.md`
- [x] pgvector prerequisite is enforced before vector-backed verification
- [x] `test/scoria/knowledge_test.exs` - corpus context and schema coverage
- [x] `test/scoria/knowledge/pgvector_test.exs` - default backend query and index coverage
- [x] `test/scoria/knowledge/scrypath_test.exs` - optional adapter normalization coverage
- [x] `test/scoria/knowledge/retrieval_test.exs` - retrieval run/result persistence coverage
- [x] `test/scoria/knowledge/citation_formatter_test.exs` - machine-readable citation contract coverage
- [x] `test/scoria/knowledge/grounding_test.exs` - deterministic and judge score coverage

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evidence readability on long chunk bodies | RAG-06 | Human judgment on operator ergonomics | Load a trace with multiple retrieval results, expand evidence, and confirm async load keeps the page responsive. |

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no three consecutive tasks without automated verify
- [x] Wave 0 covers all missing test references
- [x] No watch-mode flags
- [x] Feedback latency target is under 30 seconds
- [x] `nyquist_compliant: true` set after Wave 0 bootstrap exists

**Approval:** passed on 2026-05-11 using the bundled pgvector service on `localhost:55432`
