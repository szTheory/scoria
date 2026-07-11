# Phase 50: Release readiness and `0.1.3` cut - Context

Gathered: 2026-07-10

## Phase Aim

Phase 50 makes the release train green, keeps package truth current, publishes Hex `0.1.3`, and captures post-publish proof.

This phase is a release-readiness phase, not a feature phase. The job is to remove known release blockers, preserve the public Scoria boundary, and make the release evidence easy for a maintainer and reviewer to inspect.

## Scope

In scope:

- REL-01: repair planning-ledger drift so the required archived milestone breadcrumb remains visible to policy.
- REL-02: fix or legitimately narrow browser e2e regressions observed on PR #12: IA orientation, release-workbench modal focus, and theme-toggle visibility/clickability.
- REL-03: align README, maintainer docs, CHANGELOG, release automation, and package metadata around live `0.1.2` baseline and `0.1.3` target, with no stale `0.1.1` release guidance.
- REL-04: get release PR #12 green through `ci-gate`, publish Hex `0.1.3`, then prove fresh install and live-lineage upgrade.

Out of scope:

- New Scoria product capabilities.
- Broad docs re-architecture; Phases 47-49 already locked the public docs posture.
- Editing generated `doc/` output.
- Large test-harness rewrites unless narrowly required to remove a release blocker.
- UI redesigns or new IA; only fix release-blocking user flows.
- Presenting deferred future seeds as current shipped capabilities.

## Research Inputs

Research covered local planning state, code, release automation, failed GitHub checks, official ecosystem docs, brand/prompts guidance, and four subagent reviews:

- Policy and verification gate review.
- Browser e2e and LiveView UI regression review.
- Release Please, Hex publish, and post-publish smoke review.
- Ecosystem, DX, and architecture review across Phoenix/Elixir and comparable AI ops tools.

The consolidated recommendation is to make a narrow, evidence-first release hardening pass: fix policy truth, fix real e2e evidence gaps, keep Release Please as the normal release path, and publish only after CI and package proof are inspectable.

## Decisions

### Release Strategy

- D-01: Use the normal Release Please path. Forward-fix `main`, let Release Please refresh PR #12, and keep PR #12 as the release vehicle unless it becomes unusably stale.
- D-02: Use manual `hex-publish.yml` only after a `v0.1.3` tag exists and Hex lacks `0.1.3`. Fully manual publish is an emergency recovery path, not the happy path.
- D-03: Keep `CI / ci-gate` as the required aggregate release gate. Do not change branch-protection topology to bypass known failures.
- D-04: Treat release completion as unproven until Hex lists `0.1.3` and post-publish smoke proves both fresh install and live-lineage upgrade. Capture the workflow/run URL or ID in closeout state.

### Policy And Planning Ledger

- D-05: Keep the strict `CiPolicyContractTest` breadcrumb requirement for `v2.15 Connector Adoption Lane`. Do not loosen this into a generic archived-milestone check.
- D-06: Repair the durable `ROADMAP.md` breadcrumb path and ensure the release branch picks it up. Do not regenerate or rewrite unrelated planning ledgers unless a focused check reveals additional drift.

### Browser E2E And UI Truth

- D-07: Do not downgrade, skip, or blanket-descoped browser e2e. These failures represent user-visible release proof and should stay meaningful.
- D-08: Heal deterministic dev seed/idempotency/tenant-scoped evidence for IA trace stream, incident run path, eval prompt-release link, and pending `prompt_release` approval.
- D-09: Harden the theme-toggle test around the visible/actionable control, preferably using a role, data attribute, or viewport-scoped locator. Avoid `force: true`; use lower-level dispatch only when verifying an overlay or z-order contract.
- D-10: Change product UI only if valid seeded evidence still lacks the expected user-facing verbs. Preserve approval semantics and release gates.
- D-11: If the root cause is shared-fixture interference, isolate or serialize only the narrow specs that mutate the same seeded entities. Do not slow the entire suite first.

### Version, Docs, And Package Truth

- D-12: Before the release PR merges, `main` remains live baseline `0.1.2`; Release Please owns the `0.1.3` version bump, manifest update, and changelog entry on the release branch.
- D-13: Public and release-facing docs should describe `0.1.2` as live and `0.1.3` as target. Remove stale `0.1.1` guidance from README, guides, workflow comments, and release helper copy except in historical changelog entries.
- D-14: Check package metadata and docs URLs against Hex's 2026 HexDocs URL changes. Treat this as release metadata correctness, not a new docs restructure.
- D-15: Keep generated `doc/` output as an inspection artifact. Edit README, guides, Mix tasks, release config, and tests instead.
- D-16: If docs-contract tests still read `docs/MAINTAINERS.md` or `docs/operator_verification.md` as canonical source, update the contracts to the canonical `guides/` paths or assert compatibility-stub behavior. Do not copy full guide content back into `docs/` stubs to satisfy old expectations.

### DX, Architecture, And Brand

- D-17: Keep the maintainer path boring and copy-pasteable: focused verification commands, explicit evidence, and a documented recovery path.
- D-18: Preserve Scoria's Phoenix-native boundary: host app owns auth, tenants, role values, prompts, business truth, product UI, and provider calls; Scoria records runs, traces, evidence, approval, evals, connector activity, semantic cache decisions, and optional knowledge proof.
- D-19: Keep release and UI language operator-grade: calm, exact, and evidence-based. Avoid backend topology as the first reader path unless it is part of the public contract.
- D-20: Use current vocabulary consistently: run, trace, reviewer, capability, verification suite, scoped context, semantic cache, optional knowledge base, evidence, and grounding.
- D-21: Favor official and ecosystem-idiomatic primitives: Mix tasks for maintainer workflows, Ecto changesets/queries for release evidence, LiveViewTest for server-rendered interaction contracts, Playwright user-facing locators for e2e, Release Please for version/changelog/tag orchestration, and Hex workflows for publish proof.

## Claude's Discretion

The execution plan may decide:

- How to split Phase 50 into implementation waves.
- Whether e2e fixture healing belongs in seed data, task setup, focused test helpers, or a small UI adjustment.
- The exact locator strategy for theme toggle tests.
- Whether to add one focused regression test or rely on the existing failing e2e/contracts after fixing the root cause.
- How to refresh PR #12 after `main` is fixed, as long as Release Please remains the normal release mechanism.

Do not use discretion to:

- Skip e2e release blockers without a contract-level replacement.
- Publish manually before a green release gate unless documenting an emergency recovery.
- Move maintainer-only release details into README first-run copy.
- Edit generated `doc/` output.

## Canonical Local References

Planning and phase context:

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/MILESTONES.md`
- `.planning/milestones/v2.15-ROADMAP.md`
- `.planning/phases/47-readme-first-screen-positioning-and-scope-doctrine/47-CONTEXT.md`
- `.planning/phases/48-exdoc-and-guide-ladder-restructure/48-CONTEXT.md`
- `.planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-CONTEXT.md`

Docs, brand, and prompt research:

- `README.md`
- `CHANGELOG.md`
- `guides/maintainers.md`
- `guides/reviewer-verification.md`
- `guides/reference/glossary.md`
- `brandbook/brand-book.md`
- `prompts/sztheory-elixir-dna.md`
- `prompts/phoenix-ai-lib-deep-research.md`
- `prompts/ai-eval-best-practices-deep-research.md`
- `prompts/ai-architectural-patterns-deep-research.md`
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md`

Release and package automation:

- `mix.exs`
- `lib/mix/tasks/scoria.release_preview.ex`
- `lib/mix/tasks/scoria.post_publish_smoke.ex`
- `lib/scoria/verification_suites.ex`
- `lib/scoria/verification_lanes.ex`
- `.github/workflows/ci.yml`
- `.github/workflows/ci-verify.yml`
- `.github/workflows/release-please.yml`
- `.github/workflows/hex-publish.yml`
- `.github/workflows/post-publish-smoke.yml`
- `release-please-config.json`
- `.release-please-manifest.json`
- `test/scoria/ci_policy_contract_test.exs`
- `test/scoria/package_surface_test.exs`
- `test/mix/tasks/scoria.release_preview_test.exs`
- `test/scoria/verification_lanes_test.exs`

Browser e2e and UI:

- `priv/dev/e2e/ia_orientation.spec.mjs`
- `priv/dev/e2e/modal_focus.spec.mjs`
- `priv/dev/e2e/phase16_parity.spec.mjs`
- `priv/dev/e2e/playwright.config.mjs`
- `priv/dev/e2e/lib/ready.mjs`
- `lib/mix/tasks/scoria.ui.e2e.ex`
- `priv/repo/dev_seed.exs`
- `dev/dev_router.ex`
- `lib/scoria_web/components/layouts/app.html.heex`
- `lib/scoria_web/live/orchestrator_live.ex`
- `lib/scoria_web/live/eval_spec_live/index.ex`
- `lib/scoria_web/live/incidents_live/show.ex`
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex`
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs`
- `assets/css/04-components.css`

## External References

- Release Please official docs: `https://github.com/googleapis/release-please`
- Hex publish docs: `https://hex.pm/docs/publish`
- HexDocs URL change note, 2026-06-01 Hex blog: `https://hex.pm/blog`
- Playwright locators and actionability docs: `https://playwright.dev/docs/locators`
- Playwright locator assertions: `https://playwright.dev/docs/api/class-locatorassertions`
- ExDoc `mix docs` docs: `https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html`
- Phoenix LiveViewTest docs: `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html`
- Phoenix LiveDashboard project docs: `https://github.com/phoenixframework/phoenix_live_dashboard`

## Code Context

Known PR #12 failures:

- PR: `https://github.com/szTheory/scoria/pull/12`
- Failing run: `29043718187`
- Policy failure: `test/scoria/ci_policy_contract_test.exs:692`, where release PR branch lacked required `v2.15` roadmap breadcrumb.
- E2E failures:
  - `priv/dev/e2e/ia_orientation.spec.mjs`: home trace stream expected seeded records but saw `#traces-empty`.
  - `priv/dev/e2e/ia_orientation.spec.mjs`: incident ingress/open run/return chip path timed out.
  - `priv/dev/e2e/ia_orientation.spec.mjs`: eval workbench expected `Open prompt release`.
  - `priv/dev/e2e/modal_focus.spec.mjs`: release workbench lacked `Reject Release` because seeded pending approval was not visible.
  - `priv/dev/e2e/phase16_parity.spec.mjs`: theme-toggle locator selected a hidden mobile control at desktop width.

Useful local observations:

- Local `ROADMAP.md` already contains the `v2.15 Connector Adoption Lane` breadcrumb; PR #12 release branch likely needs refresh after main is fixed.
- `mix.exs` currently reports `@version "0.1.2"`, which is correct for `main` before Release Please lands `0.1.3`.
- `Mix.Tasks.Scoria.ReleasePreview` cleans `doc/`, runs docs with `--warnings-as-errors`, builds package preview, and checks required package paths.
- `Mix.Tasks.Scoria.PostPublishSmoke` requires `SCORIA_REGISTRY_VERSION` and verifies fresh install plus upgrade proof for versions newer than `0.1.0`.
- The release-workbench UI renders `Reject Release` only when a tenant-scoped pending approval exists for tool name `prompt_release`.
- The theme-toggle test uses a combined selector and `.first()`, which can pick the hidden mobile toggle in desktop layout.

Focused local verification on 2026-07-10:

```bash
MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

Result: failed with 7 `Scoria.CiPolicyContractTest` failures. The failures point at contracts that still read `docs/MAINTAINERS.md` and `docs/operator_verification.md` as if they contained canonical maintainer/reviewer guide content. Current project instructions say README and `guides/` are canonical, while `docs/*.md` files are compatibility stubs. Phase 50 planning should treat this as an additional release-readiness blocker: repair the public docs contracts or source references so they reflect the Phase 47-49 guide ladder without duplicating canonical content into compatibility stubs.

## Recommended Execution Shape

1. Policy and release metadata audit:
   - Confirm `ROADMAP.md` breadcrumb is present on `main`.
   - Repair docs-contract path drift between `docs/` compatibility stubs and canonical `guides/`.
   - Run the focused policy and verification contract tests.
   - Grep release-facing docs and workflow files for stale `0.1.1` release guidance.

2. Browser e2e root-cause pass:
   - Reproduce targeted specs locally where feasible.
   - Fix deterministic dev seed or e2e setup so IA, incident, eval, and prompt-release evidence exists in the expected tenant context.
   - Fix the theme-toggle locator around the visible control.
   - Add or adjust a focused regression only if existing coverage does not pin the repaired behavior.

3. Release-preview proof:
   - Run docs and package preview through the release-preview suite.
   - Keep docs edits in README/guides/tests/tasks, never generated `doc/`.

4. Release PR and publish:
   - Let Release Please refresh PR #12 after `main` is green.
   - Require `CI / ci-gate` green before merge.
   - Publish through the release workflow.
   - Run post-publish smoke with `SCORIA_REGISTRY_VERSION=0.1.3`.

## Focused Verification Commands

Use the smallest relevant suite first:

```bash
MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

Docs and package preview:

```bash
MIX_ENV=dev mix docs --warnings-as-errors
MIX_ENV=dev mix scoria.release_preview
```

Browser e2e, with the dev server running:

```bash
mix scoria.ui.e2e --base-url http://localhost:4799/scoria
```

Post-publish proof:

```bash
SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke
```

## Deferred Work

- Broad seed determinism refactor beyond the failing release specs.
- OpenTelemetry/OpenInference trace substrate expansion.
- New evaluator, connector, semantic cache, or knowledge base public features.
- UI redesign or design-system overhaul.
- Additional vendor-specific root AI files.
- Broad cleanup of historical changelog entries.
