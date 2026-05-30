# Phase 81: Post-publish registry gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 81-post-publish registry gate
**Areas discussed:** Overlay proof depth, Harness integration, Release blocking semantics, Real semver upgrade path

**Mode:** User requested all areas with subagent research + one-shot cohesive recommendations (auto-decide).

---

## Overlay proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full overlay (handoff + route + runtime) | 7 steps; duplicates PR tarball proof | |
| Route + runtime subset | 6 steps; install + migrate + HOST-01 runtime + routes | ✓ |
| Route-only | 5 steps; cheapest but misses runtime/HOST-01 | |
| Install + migrate only | No overlay smokes | |

**User's choice:** Route + runtime subset (research-backed recommendation)
**Notes:** Marginal time vs full overlay ~5–10s; decision is coverage philosophy. Handoff proven merge-blocking on tarball. ROADMAP explicitly says "overlay subset." Runtime smoke matches operator_verification core success path.

---

## Harness integration

| Option | Description | Selected |
|--------|-------------|----------|
| Extend Generator/Runner with `:hex_registry` only | Reuse harness; workflow invokes ExUnit | |
| Expand inline YAML shell | Current pattern grown | |
| Hybrid: harness + `mix scoria.post_publish_smoke` | SSOT in Elixir; thin workflow | ✓ |

**User's choice:** Hybrid C
**Notes:** Overlays must come from `deps/scoria/` after deps.get, not checkout. Exact version pin for fresh install. Not added to `mix test.adoption`.

---

## Release blocking semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Job inside release-please.yml only | Inline attest after publish-hex | |
| Reusable workflow_call SSOT | Mirror ci-verify.yml; called from release-please + hex-publish | ✓ |
| Separate workflow + polling | release: published + workflow_run poll | |
| Required check on GitHub Release UI | Not supported for releases | |

**User's choice:** Reusable workflow_call SSOT
**Notes:** Remove release:published race. skip_index_wait when chained after publish-hex. Attest failure = failed release workflow.

---

## Real semver upgrade path

| Option | Description | Selected |
|--------|-------------|----------|
| Live upgrade on every post-publish when version > 0.1.0 | Full registry upgrade proof | ✓ (conditional) |
| Document-only until 0.1.1 | Fails HEX-REGISTRY-01 executable intent | |
| Conditional workflow step | Fresh install always; upgrade when eligible | ✓ |
| workflow_dispatch only | Not release-blocking | |

**User's choice:** Conditional — fresh install always; semver upgrade when `Version.compare(to, "0.1.0") == :gt`. Latent documentation for 0.1.0-only releases.
**Notes:** Reuse run_upgrade_proof!/2 with bump: {:registry, from, to}. Baseline exact pin required. Phase 80 tarball upgrade stays PR CI complement.

---

## Claude's Discretion

- Mix task naming/placement
- Single vs dual workflow jobs for fresh-install vs upgrade
- registry_upgrade_from_version/1 implementation strategy
- deps.get retry count
- Registry proof module timeout (180_000 start)
- Minimal ci_policy_contract_test stub vs Phase 82 full pins

## Deferred Ideas

- Full docs sweep Phase 82
- Cross-minor upgrade
- Advisory hex_consumer lane
- Full handoff on registry path
