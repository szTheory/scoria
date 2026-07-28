# Requirements: Scoria — v3.7 Portcullis (Lethal-Trifecta Governance)

**Defined:** 2026-07-19
**Core Value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.
**Milestone goal:** Be the first embedded framework that escalates to a human when one run touches private data, untrusted content, and an exfil channel at once — by shipping the missing untrusted-content taint leg and a confluence-escalation gate enforced at `MCP.Executor`, audited and replayable. (SEED-010 · ⭐ flagship differentiator.)

**Scope doctrine (build-vs-delegate):** Scoria owns the *mechanism* (taint substrate, classification, confluence gate, rails, hook seams); the host owns the *decision* (approve/deny), *identity/policy* (allowlists), and the *content model* (detectors, sinks, moderation opinions). P2 (mechanism, not policy value) + P4 (identity delegated by reference). Fail-closed-but-inspectable defaults (v3.4 `ReleaseGate` precedent) — no adopter gets bricked; strict enforcement is opt-in.

---

## v1 Requirements

Requirements for this milestone (v3.7). Each maps to exactly one roadmap phase.

### Content Trust & Spotlighting (TAINT)

Supplies the missing untrusted-content leg — the substrate the confluence gate reads.

- [x] **TAINT-01**: Retrieved knowledge chunks carry a trust-tier/taint tag on `Knowledge.Chunk` metadata reflecting provenance, defaulting to untrusted for externally-sourced/retrieved content.
- [x] **TAINT-02**: Tool outputs are wrapped in an envelope carrying a trust tier, so tool results are treated as potentially-untrusted content rather than implicitly-trusted context.
- [x] **TAINT-03**: At prompt assembly in the orchestrator, untrusted content is spotlighted/datamarked (delimited with a model-agnostic marking) so the model can distinguish instructions from untrusted data.
- [x] **TAINT-04**: Scoria exposes a `scan/2` behaviour hook (default no-op) for BYO content scanners (e.g. Rebuff/LlamaGuard) and tags scanned/untrusted content in traces — no detector or classifier is shipped in-lib.

### Tool-Declared Trifecta Classification (CLASS)

- [ ] **CLASS-01**: The `Tool` behaviour is extended so a tool declares its trifecta legs (`reads_private_data`, `sees_untrusted_content`, `can_exfiltrate`) plus an `action_class`, declared once on the tool rather than passed per-call.
- [ ] **CLASS-02**: Unclassified tools resolve to a fail-closed-but-inspectable default (no silent `approval_sensitive: false`; unclassified/ungated use emits telemetry), closing the fail-open seam (code moved during Phase 55; see 56-CONTEXT.md D-05 for all five sites).
- [ ] **CLASS-03**: The declared classification is resolved at the `MCP.Executor` enforcement point for every tool call, so per-call taint derives from the tool's declaration and cannot rely on host-passed defaults.

### Per-Run Agent Rails (RAIL)

- [ ] **RAIL-01**: A single run enforces `max_steps` / `max_tool_calls` / `timeout` rails (distinct from tenant-level budgets/breakers) and halts a run that exceeds them, with the halt audited.

### Confluence Escalation Policy (GATE) — the differentiator

- [ ] **GATE-01**: A confluence evaluator classifies a tainted execution path by which of the three legs are present, mirroring `ReplayDisposition`'s seam-classification style.
- [ ] **GATE-02**: When private-data + untrusted-content + exfil co-occur in one tainted execution path, the run escalates to approval / human-in-the-loop at `MCP.Executor` before the exfil action executes.
- [ ] **GATE-03**: Confluence escalation decisions are audited (audit outbox) and replayable, consistent with existing approval and replay evidence.
- [ ] **GATE-04**: Confluence enforcement has a fail-closed-but-inspectable default plus an opt-in strict mode; ungated confluence emits telemetry so adopters are never silently bricked (mirrors the v3.4 `ReleaseGate` compatibility doctrine).

### Safety Hooks (HOOK)

- [ ] **HOOK-01**: A moderation scorer hook runs through the existing `Eval.online_scoring` / `judge_runner` scorer seam (BYO, default off) — no opinionated moderation content shipped.
- [ ] **HOOK-02**: An output-scanner hook runs through the same eval seam and tags model output as "untrusted" in traces.

### Security Boundary Doc (BOUND)

- [ ] **BOUND-01**: A `SECURITY-BOUNDARY.md` shared-responsibility doc states what Scoria enforces (taint substrate, tool classification, confluence gate, per-run rails, hook seams) versus what the host must own (detector/classifier, per-user allowlists, sinks, content/moderation policy), spanning improper-output-handling, moderation, system-prompt-leakage, and per-user allowlists.

### Govern Surface (GOVERN)

- [ ] **GOVERN-01**: A minimal read-only Govern surface names the dangerous combination for a tainted run ("private data + untrusted content + external egress → **exfiltration path**") and shows per-tool trifecta classification — read-only only; the policy-builder and simulate-on-history are deferred to SEED-013.

## v2 Requirements (deferred)

Acknowledged, not in this roadmap.

### Govern UI depth (→ SEED-013 Operator IA Pivot)

- **GOV2-01**: Plain-language approval-policy builder (`When … Then pause & require approval`).
- **GOV2-02**: Simulate-policy-on-past-runs ("would have matched 38 runs — 32 correct, 4 unnecessary, 2 need review") as an approval-fatigue preventer.
- **GOV2-03**: Full Tools & blast-radius panel (per tool/connector compound-risk matrix; guardrail gate-location screens).

### Host-BYO reference implementations (host-owned)

- **HOST-01**: Reference moderation / injection scanner implementations for the `scan/2` and eval-seam hooks (host or example gallery, not in-lib).

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Injection / prompt-injection detector or classifier in-lib | Model layer / host; Scoria owns the taint substrate + delimiting + BYO hook only. Building a detector is the over-reach anti-pattern (observability peers ship none; Anthropic hardens at the model). |
| Per-user / per-intent tool allowlists | Host identity/policy (scope doctrine P4). Only tool-*declared* classification is Scoria's. |
| Opinionated moderation content policy / output sanitizer / sinks | Host/jurisdiction (P2: hooks, not opinions). Scoria ships the seam + docs, not the content. |
| Modeling or inferring `feature`/`archetype`/`route` | Host-declared attributes only — Scoria segments by them, never infers (existing v3.6/SEED-012 doctrine). |
| Full Govern policy-builder UI + simulate-on-history + blast-radius panel | SEED-013 owns the IA shell those plug into; this milestone ships a minimal read-only surface only. |
| Hex release cut this milestone | `0.1.4` convention/feature change stays staged under CHANGELOG Unreleased; the cut is a maintainer call at closeout after the seam is proven. |

## Traceability

Which phases cover which requirements. Phase numbering continues from v3.6 (next phase is 55).

| Requirement | Phase | Status |
|-------------|-------|--------|
| TAINT-01 | Phase 55 | Complete |
| TAINT-02 | Phase 55 | Complete |
| TAINT-03 | Phase 55 | Complete |
| TAINT-04 | Phase 55 | Complete |
| CLASS-01 | Phase 56 | Pending |
| CLASS-02 | Phase 56 | Pending |
| CLASS-03 | Phase 56 | Pending |
| RAIL-01 | Phase 56.1 | Pending |
| GATE-01 | Phase 57 | Pending |
| GATE-02 | Phase 57 | Pending |
| GATE-03 | Phase 57 | Pending |
| GATE-04 | Phase 57 | Pending |
| HOOK-01 | Phase 58 | Pending |
| HOOK-02 | Phase 58 | Pending |
| BOUND-01 | Phase 58 | Pending |
| GOVERN-01 | Phase 58 | Pending |

**Coverage:**

- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-19*
*Last updated: 2026-07-19 after ROADMAP creation (Phases 55–58)*
