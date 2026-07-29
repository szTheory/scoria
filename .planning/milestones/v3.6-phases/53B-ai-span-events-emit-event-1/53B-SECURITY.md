---
phase: 53B
slug: ai-span-events-emit-event-1
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-18
---

# Phase 53B — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| host/adapter → raw `:telemetry` bus | Any BEAM caller can `:telemetry.execute` the `[:scoria, :observe, :event, :emit]` tuple directly, bypassing `emit_event/1`; the event vocabulary is the only admission gate. | Event name (atom) + arbitrary metadata map |
| raw `:telemetry.execute` → `:event` handler | The bypass path that skips `emit_event/1`; the handler (`telemetry.ex:95-118`) is the ONLY boundary of record. | Unvalidated event name + host-controlled attributes |
| handler → Buffer | Only redacted, bounded, fixed-key-projected, non-null events cross into the durable path. | `~w(span_id name time attributes)a` projection only |
| Buffer GenServer → Postgres | Batched `insert_all` bypasses changesets; a raw Postgrex raise in one flush phase must not roll back the other. | Span rows + event rows (separate transactions) |
| judge / guardrail inference output → durable event | Free-text `explanation` is the single most likely leak; only low-cardinality enums / refs may cross into a persisted event. | `scoria.prompt.template_ref`, guardrail enums |
| app → Postgres DDL | The FK-drop migration changes the durability/insertability contract of `ai_span_events`. | Schema constraint change (span_id FK) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-53B-01 | Information Disclosure | event attributes redaction | high | mitigate | Single shared `defp redact/1` → one `Redactor.redact/1` call site (`telemetry.ex:144`) funnels span/delta/event; fixed-key `buffer_event/1` projection never spreads host input; drift guard asserts exactly one call site (`grep -c` → 1). Test-proven: SC#1 in `event_emit_test.exs` (deny-listed key `[REDACTED]`). | closed |
| T-53B-02 | Tampering / EoP (vocabulary) | raw-bus name bypass | high | mitigate | Closed `@event_names` atom list (`semconv.ex:277`) + `event_name?/1` membership check; NEVER `String.to_atom` on inbound data. Handler independently re-checks `Semconv.event_name?/1` (`telemetry.ex:100`, `observe.ex:461`); unknown → `reject_event`, never persisted. Test-proven: SC#2 (direct + raw-bus paths). | closed |
| T-53B-03 | Tampering / DoS (data integrity) | FK drop + fail-closed seam + two-phase flush | high | mitigate | Immediate FK on `ai_span_events.span_id` dropped (migration `20260718230000`), column stays NOT NULL — orphans persist, never batch-rolling raise. Handler defaults `time` + drops nil/non-UUID `span_id` BEFORE `Bounds.enforce/2` (`telemetry.ex:152-180`, CR-01 gap closed). Events flush in a SEPARATE `Repo.insert_all` in its own try/rescue (`buffer.ex:210-254`, D-02b). Test-proven: SC#4 + D-05a regression (52 rows, batch never rolled back). | closed |
| T-53B-04 | Information Disclosure | judge explanation / free-text leak | high | mitigate | Fixed-key `~w(span_id name time attributes)a` projection (`@event_buffer_fields`, `telemetry.ex:126-137`) + `Bounds.enforce(_, :event)` closed registry. `prompt_rendered` fires at render time before `explanation` exists; guardrail events reuse `Semconv.guardrail_attributes/1` (enums only; subject_ref/policy_key omitted). Free-text can never reach a persisted event. | closed |
| T-53B-05 | Denial of Service | orphan-event retry / unbounded memory | medium | accept | Persist-dangling, never retry (D-01b) — bounded retry cannot converge for a permanently-dropped span and is itself an unbounded-memory DoS. Independent event cap drops newest on overflow (`buffer.ex:67`, `max_event_size`). Below `high` block threshold. | closed |
| T-53B-SC | Tampering (supply chain) | package installs | low | accept | No new packages; `mix.exs` untouched (RESEARCH Package Legitimacy Audit: N/A). Below `high` block threshold. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-53B-01 | T-53B-05 | Orphan events persist dangling rather than retry; bounded retry cannot converge for a permanently-dropped span and would be an unbounded-memory DoS. Independent event cap bounds memory by dropping newest on overflow. | szTheory | 2026-07-18 |
| AR-53B-02 | T-53B-SC | No new third-party packages introduced; `mix.exs` unchanged this phase, so no new supply-chain surface. | szTheory | 2026-07-18 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-18 | 6 | 6 | 0 | gsd-secure-phase (L1 grep-depth, register authored at plan time) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-18
