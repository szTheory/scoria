# Phase 63: Manifest Check Fingerprint Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 63-manifest-check-fingerprint-hardening
**Areas discussed:** Check-time contract, Hardening depth, Missing manifest, Documentation placement, Check output shape (all five — user requested full research + one-shot recommendations)

---

## Research method

User requested subagent research across all gray areas with ecosystem comparison (Elixir/Phoenix, Terraform/Ansible, Igniter/Oban patterns), prompts/ subdir vision alignment, and a single coherent recommendation set without further interactive selection.

Five parallel research agents returned structured analysis. Main agent synthesized into locked decisions D-01 through D-19 in CONTEXT.md.

---

## Check-time fingerprint contract

| Option | Description | Selected |
|--------|-------------|----------|
| Live-host contract (document) | Check = live analysis; manifest = apply/persistence only | ✓ |
| Manifest-baseline contract | Check compares live vs stored manifest hashes | |
| Hybrid (live blocking + manifest advisory) | Two drift vocabularies in one report | |

**User's choice:** Live-host contract (D-01, D-02, D-03) — recommended default after research
**Notes:** Matches shipped behavior. Phase 59 rejected hash-only ownership due to false positives. Ansible/Terraform idioms support live reconciliation at check/plan time.

---

## Hardening depth

| Option | Description | Selected |
|--------|-------------|----------|
| Document + minimal honest code fix | Remove dead fingerprint merge; document; targeted tests | ✓ |
| Documentation only | Leave misleading Manifest.load + put_new path | |
| Full manifest-driven check integration | Manifest drives check drift classification | |

**User's choice:** Document + minimal honest code fix (D-04, D-05, D-06)
**Notes:** Ecosystem pattern: don't load-then-ignore (Bundler/mix.lock enforce or omit). Critical: remove dead path, do NOT switch put_new → put.

---

## Missing / first-run manifest

| Option | Description | Selected |
|--------|-------------|----------|
| Same as today, spelled out | No manifest → live only; first apply writes manifest | ✓ |
| Missing manifest = manual_review | Stricter; false-positive CI | |
| Synthetic empty baseline | "Never applied" on all surfaces | |

**User's choice:** Same as today, spelled out (D-07 through D-10)
**Notes:** Compliant host without manifest must stay exit 0. Greenfield fails check for markers/migrations — correct signal, not manifest.

---

## Documentation audience and placement

| Option | Description | Selected |
|--------|-------------|----------|
| Split (operator guide + maintainer @moduledoc) | Layered SSOT per Phase 61 | ✓ |
| Operator-only | Single adopter section | |
| Maintainer-only | Code docs only | |

**User's choice:** Split (D-11 through D-13)
**Notes:** Hex norm: mix help + adoption guide + module docs. README stays lane-oriented (v2.4 lesson).

---

## Check output shape

| Option | Description | Selected |
|--------|-------------|----------|
| Additive non-breaking | Optional manifest object + calm human line | ✓ |
| No output change | Docs only | |
| Rich drift block | manifest_fingerprint vs live_fingerprint per entry | |

**User's choice:** Additive non-breaking (D-14 through D-17) with docs companion (not B alone)
**Notes:** Phase 60 trailer freeze preserved. Terraform additive JSON pattern. Reject C for default check UX noise.

---

## Claude's Discretion

- Exact manifest absent/present human copy wording
- JSON schema_version minor bump vs additive 1.0
- Contract module manifest key constants

---

## Deferred Ideas

- Manifest-baseline check at `--check` time
- Rich hash-diff blocks in default check JSON
- Rename `fingerprint` field in JSON output
