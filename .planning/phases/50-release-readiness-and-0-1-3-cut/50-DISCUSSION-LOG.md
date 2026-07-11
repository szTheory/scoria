# Phase 50: Release readiness and `0.1.3` cut - Discussion Log

Gathered: 2026-07-10

## User Direction

The user asked to discuss and consider all Phase 50 decision points in one pass, using subagent research and existing prompt/brand context. The requested lens was broad and deep: idiomatic Elixir/Phoenix/Ecto/Plug practice, lessons from comparable libraries and apps, release/devops/SRE concerns, DX, user-friendly API design, and UI/UX where applicable.

## Decision Areas

| Area | Options Considered | Recommendation | Reasoning |
| --- | --- | --- | --- |
| Release vehicle | Continue Release Please PR #12; abandon and publish manually; change release workflow topology | Continue PR #12 after forward-fixing `main` | Release Please is the idiomatic automation boundary for version/changelog/tag orchestration. Manual publish is harder to audit and should remain recovery-only. |
| Policy failure | Loosen `CiPolicyContractTest`; move breadcrumb checks elsewhere; restore required roadmap breadcrumb | Keep strict check and restore/refresh breadcrumb | The failure is valuable because it catches drift in release-visible planning truth. A narrower exception would reduce release trust. |
| Browser e2e failures | Skip flaky tests; rewrite suite; fix seed and locator truth | Fix deterministic evidence and visible locators | The failing flows represent reviewer/operator proof. Skipping them would ship broken proof paths; rewriting the suite is too broad for a release cut. |
| Theme toggle | Force-click first matching element; dispatch raw events; choose visible user-facing control | Use a visible/actionable locator | Playwright's strength is user-facing actionability. The current selector asks the wrong question by choosing the first hidden/visible union. |
| Release workbench modal | Make buttons unconditional; seed tenant-scoped pending approval; weaken assertions | Seed/fix real pending approval evidence | Approval controls should remain evidence-gated. The test should prove the same condition a reviewer would see. |
| IA/eval flows | Make links unconditional; seed required traces/releases; descoped tests | Heal seeded trace, incident, eval, and prompt-release evidence | Scoria's value proposition is evidence and grounding. UI verbs should appear because the evidence exists, not because the UI hides missing state. |
| Version truth | Bump `main` to `0.1.3`; leave stale copy; keep `main` at `0.1.2` and let Release Please bump | Keep `main` at `0.1.2`, align copy around live baseline and target | This preserves normal release semantics and avoids double-owning the version bump. |
| Docs contract drift | Refill old `docs/` files with full guide content; update contracts to canonical `guides/`; leave failures for release PR | Update contracts/source refs to canonical `guides/` or compatibility-stub assertions | Project instructions make README and `guides/` canonical while `docs/` are stubs. Duplicating content into stubs would create a new source-of-truth split. |
| Hex publish | Publish immediately; wait for PR green/tag; use manual workflow for all releases | Publish after green release gate and tag, with manual workflow only as recovery | Hex versions are immutable release events. Publish should be the final evidence-backed step, not a workaround for CI. |
| Docs/brand posture | Add release details to first-run README; create vendor-specific root docs; keep maintainer docs focused | Keep first-run docs adopter-focused, maintainer release path explicit in maintainer docs | This follows Phases 47-49 and the brandbook: calm, operator-grade, Phoenix adopter first. |

## Subagent Research Summary

Policy and verification review:

- Keep strict fact-level release policy.
- Repair durable roadmap breadcrumb truth rather than weakening the test.
- Do not move policy evidence into generated docs or unrelated ledgers.

Browser e2e and UI review:

- The best path is a blended fix: repair seeded evidence and harden the selector that currently selects a hidden control.
- Preserve UI gating for approval and release verbs.
- Avoid blanket descoping; if concurrency or shared fixture mutation is proven, isolate the narrow specs only.

Release path review:

- Forward-fix `main`, let Release Please refresh PR #12, require green `CI / ci-gate`, then merge.
- Use the publish workflow after the release tag exists.
- Use manual publishing only as documented maintainer recovery.

Ecosystem and DX review:

- Mature libraries optimize for boring, inspectable integration contracts.
- Scoria should preserve host-owned boundaries, explicit docs, telemetry/evidence, and a recoverable release process.
- The release is not done until proof is visible to maintainers and reviewers.

## Ecosystem Lessons Applied

Elixir/Phoenix:

- Prefer Mix tasks for maintainer workflows because they are discoverable, scriptable, and fit Phoenix library DX.
- Keep Ecto data repair and seed truth deterministic/idempotent.
- Use LiveViewTest for server-rendered interaction contracts and Playwright for browser-level proof.
- Keep LiveView UI noun/verb language user-facing: run, trace, reviewer, approval, evidence, capability, release.

Comparable AI ops/eval tools:

- Successful tools make traces and eval evidence first-class and inspectable.
- Footguns include hiding missing evidence behind cheerful UI, turning evals into one-off dashboards, and letting release gates drift from production truth.
- The durable pattern is production trace -> dataset/eval -> CI gate -> release proof -> reviewer-visible evidence.

Release automation:

- Release Please should own version/changelog/tag choreography.
- Hex publish should be tied to an immutable version and followed by external smoke proof.
- Manual release paths should be documented and rare.

UI/UX:

- For Phase 50, the relevant UI job is not visual redesign. It is making proof paths work reliably.
- The operator should be able to answer: "Do I need to do anything, what evidence supports that, and what action is available next?"
- Controls should be visible, accessible, and stateful for real reasons. Hidden duplicate controls should not confuse tests or users.

## Coherent Recommendation

Plan Phase 50 as a four-wave release-hardening phase:

1. Fix release policy, docs-contract path drift, and version truth.
2. Fix browser e2e evidence and visible control regressions.
3. Run docs/package preview and focused verification.
4. Refresh/merge PR #12, publish Hex `0.1.3`, and record post-publish smoke proof.

This path keeps the release train honest, avoids new scope, honors the Phoenix-native library boundary, and preserves the user/reviewer promise that Scoria shows evidence rather than implementation guts.

## Deferred Ideas

- Broader seed/test-harness determinism work.
- UI IA redesign or design-system expansion.
- New AI ops feature surface.
- Broad docs rewrite beyond release truth.
- New vendor root docs.
