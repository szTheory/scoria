# Requirements: Scoria v2.16

**Defined:** 2026-05-30
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

## v2.16 Requirements

### Dependency Hygiene

- [x] **DEPS-01**: `mix.exs` declares `{:req_llm, "~> 1.13"}` and `mix.lock` resolves to 1.13.x
- [x] **DEPS-02**: Orchestrator, judge runner, and compaction worker compile and pass unit/integration tests against bumped ReqLLM
- [x] **DEPS-03**: `Scoria.Observe.Adapters.ReqLLM` continues to emit normalized span stops from `[:req_llm, :request, :stop]`
- [x] **DEPS-04**: `mix scoria.test.ci_trust` passes with no new warning debt

## Future Requirements

### Ecosystem integration (deferred)

- **ECOS-01**: Optional `:parapet` dev/test dep with Scoria↔Parapet telemetry contract verification
- **ECOS-02**: ReqLLM streaming adapter wiring live trace deltas via `emit_span_delta/1`

## Out of Scope

| Feature | Reason |
|---------|--------|
| Tribunal bump | Already at latest 1.3.6 |
| Optional szTheory Hex deps (parapet, threadline, chimeway) | User chose minimal ReqLLM-only scope |
| ReqLLM streaming → live trace delta adapter | Deferred from v2.11; not part of peer bump |
| Hex publish / semver release | Release queue (`0.1.1`) stays separate |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEPS-01 | Phase 08 | Complete |
| DEPS-02 | Phase 09 | Complete |
| DEPS-03 | Phase 09 | Complete |
| DEPS-04 | Phase 10 | Complete |

**Coverage:**
- v2.16 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-30*
*Last updated: 2026-05-30 after milestone v2.16 roadmap*
