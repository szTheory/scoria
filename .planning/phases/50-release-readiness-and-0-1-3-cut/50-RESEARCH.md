# Phase 50: Release readiness and `0.1.3` cut - Research

**Researched:** 2026-07-10
**Domain:** Release engineering — CI policy/docs contracts, Playwright e2e regressions, Elixir/Hex package/version truth, Release Please + Hex publish automation
**Confidence:** HIGH (all four requirement areas verified against the live repo, live PR #12 CI run, and live external Hex/HexDocs behavior — not assumed)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Release Strategy
- D-01: Use the normal Release Please path. Forward-fix `main`, let Release Please refresh PR #12, and keep PR #12 as the release vehicle unless it becomes unusably stale.
- D-02: Use manual `hex-publish.yml` only after a `v0.1.3` tag exists and Hex lacks `0.1.3`. Fully manual publish is an emergency recovery path, not the happy path.
- D-03: Keep `CI / ci-gate` as the required aggregate release gate. Do not change branch-protection topology to bypass known failures.
- D-04: Treat release completion as unproven until Hex lists `0.1.3` and post-publish smoke proves both fresh install and live-lineage upgrade. Capture the workflow/run URL or ID in closeout state.

#### Policy And Planning Ledger
- D-05: Keep the strict `CiPolicyContractTest` breadcrumb requirement for `v2.15 Connector Adoption Lane`. Do not loosen this into a generic archived-milestone check.
- D-06: Repair the durable `ROADMAP.md` breadcrumb path and ensure the release branch picks it up. Do not regenerate or rewrite unrelated planning ledgers unless a focused check reveals additional drift.

#### Browser E2E And UI Truth
- D-07: Do not downgrade, skip, or blanket-descoped browser e2e. These failures represent user-visible release proof and should stay meaningful.
- D-08: Heal deterministic dev seed/idempotency/tenant-scoped evidence for IA trace stream, incident run path, eval prompt-release link, and pending `prompt_release` approval.
- D-09: Harden the theme-toggle test around the visible/actionable control, preferably using a role, data attribute, or viewport-scoped locator. Avoid `force: true`; use lower-level dispatch only when verifying an overlay or z-order contract.
- D-10: Change product UI only if valid seeded evidence still lacks the expected user-facing verbs. Preserve approval semantics and release gates.
- D-11: If the root cause is shared-fixture interference, isolate or serialize only the narrow specs that mutate the same seeded entities. Do not slow the entire suite first.

#### Version, Docs, And Package Truth
- D-12: Before the release PR merges, `main` remains live baseline `0.1.2`; Release Please owns the `0.1.3` version bump, manifest update, and changelog entry on the release branch.
- D-13: Public and release-facing docs should describe `0.1.2` as live and `0.1.3` as target. Remove stale `0.1.1` guidance from README, guides, workflow comments, and release helper copy except in historical changelog entries.
- D-14: Check package metadata and docs URLs against Hex's 2026 HexDocs URL changes. Treat this as release metadata correctness, not a new docs restructure.
- D-15: Keep generated `doc/` output as an inspection artifact. Edit README, guides, Mix tasks, release config, and tests instead.
- D-16: If docs-contract tests still read `docs/MAINTAINERS.md` or `docs/operator_verification.md` as canonical source, update the contracts to the canonical `guides/` paths or assert compatibility-stub behavior. Do not copy full guide content back into `docs/` stubs to satisfy old expectations.

#### DX, Architecture, And Brand
- D-17: Keep the maintainer path boring and copy-pasteable: focused verification commands, explicit evidence, and a documented recovery path.
- D-18: Preserve Scoria's Phoenix-native boundary: host app owns auth, tenants, role values, prompts, business truth, product UI, and provider calls; Scoria records runs, traces, evidence, approval, evals, connector activity, semantic cache decisions, and optional knowledge proof.
- D-19: Keep release and UI language operator-grade: calm, exact, and evidence-based. Avoid backend topology as the first reader path unless it is part of the public contract.
- D-20: Use current vocabulary consistently: run, trace, reviewer, capability, verification suite, scoped context, semantic cache, optional knowledge base, evidence, and grounding.
- D-21: Favor official and ecosystem-idiomatic primitives: Mix tasks for maintainer workflows, Ecto changesets/queries for release evidence, LiveViewTest for server-rendered interaction contracts, Playwright user-facing locators for e2e, Release Please for version/changelog/tag orchestration, and Hex workflows for publish proof.

### Claude's Discretion

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

### Deferred Ideas (OUT OF SCOPE)
- Broad seed determinism refactor beyond the failing release specs.
- OpenTelemetry/OpenInference trace substrate expansion.
- New evaluator, connector, semantic cache, or knowledge base public features.
- UI redesign or design-system overhaul.
- Additional vendor-specific root AI files.
- Broad cleanup of historical changelog entries.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Release train no longer fails on planning-ledger drift; roadmap includes archived milestone breadcrumbs incl. `v2.15 Connector Adoption Lane`. | The `v2.15`/breadcrumb assertion **already passes** locally `[VERIFIED: mix test]`. The 7 real `CiPolicyContractTest` failures are a *different*, undocumented regression: docs-contract tests still read compatibility-stub files (`docs/MAINTAINERS.md`, `docs/operator_verification.md`) as if they held canonical content that Phase 48 moved into `guides/maintainers.md` / `guides/reviewer-verification.md`. See Pitfall 1 and Code Examples for the exact fix. |
| REL-02 | Release train no longer fails on browser e2e regressions: theme-toggle hidden click, modal focus, orientation walkthrough. | Root-caused from the live PR #12 CI log (run `29043718187`): 4 of 5 failures trace to one stale 2-arity call to `Scoria.Workflows.PromptRelease.start_release_workflow/2` in `priv/repo/dev_seed.exs` (the real function is arity-3 since the Phase 44-06 tenant-scoping change). The 5th (theme-toggle) is a DOM-order/locator bug, confirmed via markup + CSS. See Pitfall 2/3 and Code Examples. |
| REL-03 | README/maintainer docs/release notes/release automation reflect live `0.1.2` baseline and `0.1.3` target, no stale `0.1.1` guidance. | README, `mix.exs`, `.release-please-manifest.json` are **already correct** (Phase 47 fixed README; confirmed via repo-wide grep). Two small residual items found: (a) 4 workflow/mix-task header comments still point at `docs/MAINTAINERS.md`/`docs/operator_verification.md#hex-release--recovery-maintainers` instead of `guides/maintainers.md`; (b) `scoria.post_publish_smoke.ex` moduledoc example still shows `SCORIA_REGISTRY_VERSION=0.1.1`. Neither blocks CI; both are D-13 polish. |
| REL-04 | Release PR reaches green `ci-gate`, publishes to Hex, passes post-publish smoke (fresh install + live-lineage upgrade). | Confirmed via `gh pr view 12`: PR is OPEN, MERGEABLE, base `main` — blocked only by the policy (REL-01) and e2e (REL-02) failures above; `mix scoria.release_preview` and `mix docs --warnings-as-errors` both pass clean today. Release/publish/smoke workflow topology (`release-please.yml`, `hex-publish.yml`, `post-publish-smoke.yml`) already matches D-01..D-04; no workflow-topology change is needed — REL-04 is a **consequence** of fixing REL-01/REL-02, then letting the existing pipeline run. |
</phase_requirements>

## Summary

This is not a build phase — it is a repair phase for a release pipeline that is already 90% correct. Three of the four requirements (REL-01's breadcrumb, REL-03's version truth, REL-04's workflow topology) are **already satisfied on `main`**; the CI failures on PR #12 come from two narrow, well-evidenced defects, both confirmed against the live GitHub Actions run (`29043718187`) rather than assumed:

1. **`test/scoria/ci_policy_contract_test.exs` docs-contract drift (7 failures, REL-01).** Phase 48 moved canonical maintainer/reviewer content from `docs/MAINTAINERS.md` / `docs/operator_verification.md` into `guides/maintainers.md` / `guides/reviewer-verification.md`, leaving those two files as compatibility stubs. Six `CiPolicyContractTest` tests never got updated to read the new canonical files, and they assert specific content strings that Phase 48's guide rewrite genuinely dropped (a "PR vs release proof depth" table, a "Version namespaces" section, `RELEASE_PLEASE_TOKEN` documentation, the `## Hex release & recovery` heading). The 7th (`README links maintainers to maintainer guide`) asserts a stale `docs/MAINTAINERS.md` link that README correctly no longer has. **The `v2.15`/roadmap-breadcrumb assertion itself already passes** — this is not the reported failure.

2. **`priv/repo/dev_seed.exs` calls a function with the wrong arity (4 of 5 e2e failures, REL-02).** `Scoria.Workflows.PromptRelease.start_release_workflow/2` no longer exists — Phase 44-06's tenant-scoping change made it arity-3, requiring `tenant_id` in an `attrs` map/list. Both dev-seed call sites (line 959, block f; line 1047, block g) still call the old 2-arity form. Both raise `UndefinedFunctionError`, caught by the seed script's own `rescue`, and printed only as a silent one-line warning nobody was watching — but *the entire remainder of each `try` block never runs*, so the seeded prompt-release approval, IA demo run, IA trace, and IA incident are all silently absent. This single 2-call-site fix should resolve `modal_focus.spec.mjs`'s failure and 3 of `ia_orientation.spec.mjs`'s failures.

3. **The 5th e2e failure (`phase16_parity.spec.mjs` theme-toggle) is a locator bug**, confirmed from markup: `#scoria-theme-toggle-mobile` (hidden via `display:none` at `>=768px`) appears *before* `#scoria-theme-toggle` in the DOM, so `page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first()` always resolves to the hidden mobile control at Playwright's default desktop viewport, and `.click()` times out. Fix by reusing the codebase's existing `.filter({ visible: true })` convention (already used elsewhere in `ia_orientation.spec.mjs`).

**Primary recommendation:** Fix the two root causes above (dev_seed.exs arity + ci_policy_contract_test.exs docs-path/content drift), fix the theme-toggle locator, then let Release Please refresh PR #12 and flow through the *unchanged* existing publish/smoke pipeline — do not redesign any workflow topology.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Planning-ledger/policy contract truth | Repo docs/tests (CI `policy` job) | — | Pure static-file assertions; no runtime tier involved. |
| Dev-seed fixture generation | Backend/Mix task (`priv/repo/dev_seed.exs`, dev-only) | Database (Postgres) | Seed script writes through the same `Scoria.Workflows`/`Scoria.PromptRegistry` API surface adopters use; a stale call site is a backend-tier defect, not a browser-tier one. |
| Browser e2e assertions | Browser/Client (Playwright) | Frontend Server (LiveView) | Playwright drives the real rendered DOM; failures here reflect either missing *backend* seed data (tier: backend) or a *browser*-tier locator/DOM defect — this phase has one of each. |
| Release/version/package metadata | Release tooling (Mix tasks, `mix.exs`, GitHub Actions) | — | `mix.exs`, `release-please-config.json`, workflow YAML — no application runtime tier. |
| Publish + post-publish proof | CI/CD (GitHub Actions) → Hex registry (external) | Database (Postgres, for smoke test overlay) | `hex-publish.yml`/`post-publish-smoke.yml` orchestrate an external service (Hex) and a throwaway DB-backed consumer overlay. |

## Standard Stack

This phase adds **no new dependencies**. It repairs existing release/test tooling. Relevant already-adopted tools, version-verified against the live repo:

### Core (existing, unchanged)
| Tool | Version (verified) | Purpose | Why Standard |
|------|---------------------|---------|---------------|
| `googleapis/release-please-action` | `v5` (pinned in `release-please.yml`) [VERIFIED: `.github/workflows/release-please.yml`] | Version bump / changelog / tag / PR orchestration from conventional commits | Official Google tool; D-21 mandates keeping it as the release mechanism (D-01). |
| Hex (`mix hex.publish`) | n/a (Mix built-in) | Package publish | D-21; no alternative considered. |
| `@playwright/test` | pinned via `priv/dev/package.json`; Docker image `mcr.microsoft.com/playwright:v<version>-noble` kept in lockstep by an existing `ci_policy_contract_test.exs` assertion [VERIFIED: test/scoria/ci_policy_contract_test.exs:787] | Browser e2e assertion lane | D-21; already the established e2e tool, no change needed. |
| ExDoc | `~> 0.38`, `only: :dev` [VERIFIED: mix.exs:100] | HexDocs generation | Confirmed `MIX_ENV=dev mix docs --warnings-as-errors` builds clean today. |

### Alternatives Considered
Not applicable — this phase repairs existing tooling; it does not evaluate new libraries. Per CONTEXT.md scope fences, do not introduce new release/test tooling.

**Installation:** None required. No `mix.exs` dependency changes.

## Package Legitimacy Audit

Not applicable — this phase installs no new external packages. No `npm install` / `mix deps.get` additions are in scope. (Skip per the protocol's own "whenever this phase installs external packages" trigger — it does not.)

## Architecture Patterns

### System Architecture Diagram — release pipeline data flow

```
 developer PRs (fix:/docs:/chore:) ──merge──▶ main
                                                 │
                                                 ▼
                                   ┌─────────────────────────┐
                                   │ release-please.yml        │
                                   │ (push: main)               │
                                   │  - detect already-tagged   │
                                   │  - Release Please action   │
                                   │  - opens/updates PR #12    │
                                   └────────────┬───────────────┘
                                                 │ prs_created / release_created
                    ┌────────────────────────────┼────────────────────────────┐
                    ▼                                                          ▼
      bootstrap-release-pr-ci                                     (on later merge → tag)
      dispatches ci.yml on                                        release-please.yml
      release-please--branches--main                              outputs: release_created=true
                    │                                                          │
                    ▼                                                          ▼
        ci.yml → { verify (ci-verify.yml: policy→build→          verify (ci-verify.yml, same bar)
                    {test,ratchet,knowledge,connector,                          │
                    full-suite[x4]}→verify-summary), e2e }                     ▼
                    │                                              gate-ci-green (polls ci.yml
                    ▼                                              on tag SHA for `ci-gate`)
              ci-gate (needs verify+e2e, must be                              │
              ALL success) ◀──────────────────────── required for            ▼
                    │                                 branch protection  publish-hex
                    ▼                                 AND release gate    (mix hex.publish --yes,
        release-pr-automerge.yml                                          idempotent skip-if-listed)
        (on CI success on release-please--**                                  │
         branch) merges PR #12                                                ▼
                    │                                              Wait for Hex.pm index
                    ▼                                                          │
              dispatches CI on main, then                                     ▼
              Release Please (tags v0.1.3)                        post-publish-attest
                                                                    (post-publish-smoke.yml:
                                                                     fresh install + registry
                                                                     semver upgrade proof)
```

The **policy** job (static-file assertions, no DB) and the **e2e** job (real browser against a seeded dev server) are two independent CI lanes that both roll up into `ci-gate`. Phase 50's two defects sit one in each lane — `ci_policy_contract_test.exs` in `policy`, `dev_seed.exs`/theme-toggle in `e2e` — which is why PR #12 shows both `verify / policy: FAILURE` and `e2e: FAILURE` today `[VERIFIED: gh pr view 12]`.

### Recommended Project Structure

No new files/directories. All fixes land in existing files:
```
test/scoria/ci_policy_contract_test.exs   # repoint @maintainer_docs/@operator_docs constants + assertions
guides/maintainers.md                      # restore dropped maintainer content (see Pitfall 1)
priv/repo/dev_seed.exs                     # fix 2 stale start_release_workflow/2 call sites
priv/dev/e2e/phase16_parity.spec.mjs       # harden theme-toggle locator (3 call sites)
mix.exs                                    # optional: update @hexdocs_url to subdomain form (D-14)
lib/mix/tasks/scoria.post_publish_smoke.ex # optional: refresh stale 0.1.1 example (D-13 polish)
.github/workflows/*.yml                    # optional: refresh stale docs/ path comments (D-13 polish)
```

### Pattern: Silent-rescue seed scripts hide real regressions
**What:** `priv/repo/dev_seed.exs` wraps each seed block in `try/rescue`, printing `"! <thing> skipped: #{Exception.message(e)}"` on failure rather than crashing the seed run. This is intentional (Phase-by-phase seed evolution shouldn't hard-fail `make dev` for an unrelated schema change), but it means a genuine API drift (like this phase's arity bug) prints one easy-to-miss line and otherwise looks like a clean, green seed run.
**When to use:** Keep the rescue pattern (do not remove it — that's outside this phase's scope per "no broad seed-determinism refactor"), but the planner should have the execution phase **grep the seed script's own stdout** (`mix dev.setup` output, or the `Prepare dev database and seed` CI step log) as a required verification step before trusting `#traces-empty`-style DOM assertions, since a swallowed exception there produces exactly the "flaky/failing e2e" symptom this phase is chasing.
**Example (the actual bug, confirmed from PR #12 run `29043718187`):**
```text
! prompt registry skipped: function Scoria.Workflows.PromptRelease.start_release_workflow/2 is undefined or private
! IA linkage scenario skipped: function Scoria.Workflows.PromptRelease.start_release_workflow/2 is undefined or private
```

### Anti-Patterns to Avoid
- **Loosening `CiPolicyContractTest` to "fix" REL-01:** D-05/D-16 explicitly forbid this. The correct fix is repointing file paths/content to the current canonical `guides/` source, not weakening assertions.
- **Copying full guide content back into `docs/*.md` stubs:** D-16/D-15 forbid this explicitly — it would re-fork the content Phase 48 deliberately consolidated.
- **Adding `force: true` or a fixed `sleep` to fix the theme-toggle test:** D-09 explicitly asks for a role/data-attribute/viewport-scoped locator fix instead.
- **Publishing to Hex manually before `ci-gate` is green:** D-02/D-03 — manual `hex-publish.yml` is an emergency-recovery path only, gated by its own `gate-ci-green` job.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release PR / version bump / changelog | A custom version-bump script | Release Please (already wired) | D-21; already correctly configured (`release-please-config.json` has no `release-as` override, uses `bootstrap-sha`). |
| Hidden-element-safe locators | `force: true` clicks or fixed sleeps | Playwright `.filter({ visible: true })` (already used elsewhere in this codebase, e.g. `ia_orientation.spec.mjs:160,210`) | D-09; matches existing project convention exactly — no new pattern needed. |
| Post-publish registry proof | A hand-rolled `curl`+`mix deps.get` script | The existing `mix scoria.post_publish_smoke` task + `host_app_registry_proof_test.exs` / `host_app_registry_upgrade_proof_test.exs` | Already implemented (Phase 35/81); D-21. |

**Key insight:** Every piece of infrastructure this phase needs already exists and is correctly designed. The work is entirely *defect repair* (two stale call sites, one drifted contract file, one locator bug) — resist the temptation to add new abstractions.

## Common Pitfalls

### Pitfall 1: Docs-contract tests assert content that moved, not content that's missing
**What goes wrong:** `test/scoria/ci_policy_contract_test.exs` has 7 failing tests, but they are NOT about the `v2.15` roadmap breadcrumb (REL-01's literal wording) — that specific test (`"planning ledgers reflect shipped hex consumer and connector milestones"`, line 692) **already passes** `[VERIFIED: MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs — 94 tests, 7 failures, none is this one]`. The 7 real failures read `@maintainer_docs = "docs/MAINTAINERS.md"` and `@operator_docs = "docs/operator_verification.md"` (both now Phase-48 compatibility stubs) and assert content strings that live in `guides/maintainers.md` today, or that Phase 48's rewrite dropped outright:
  - `"Normal patch release (fully automated)"`, `"RELEASE_PLEASE_TOKEN"`, `"no manual merge"` — **genuinely absent** from `guides/maintainers.md` (its "Hex release and recovery" section uses different wording and never mentions `RELEASE_PLEASE_TOKEN`).
  - `"## Hex release & recovery"` — current guide heading is `"## Hex release and recovery"` (different text, `and` not `&`); the old anchor-suffix pattern `{#hex-release--recovery-maintainers}` used in the pre-Phase-48 `docs/MAINTAINERS.md` (recovered via `git show c40bc630:docs/MAINTAINERS.md`) is gone too.
  - `"CI gate map"` **PR vs release proof depth** subsection (`content-revision upgrade`, `Tarball consumer full overlay`, `scoria-0.1.0-unpack`, `HEAD tarball`, `baseline exact previous`, `target just-published`) — **entirely absent** from the current guide; this whole comparison table existed in the pre-Phase-48 doc and was dropped.
  - `"Version namespaces"` subsection — **entirely absent** from the current guide.
  - README `"docs/MAINTAINERS.md"` link — README correctly now links `guides/maintainers.md` (Phase 48); the test's expectation is simply stale.
**Why it happens:** Phase 48 rewrote `guides/maintainers.md` as a lighter-weight guide and never re-synced `ci_policy_contract_test.exs`'s literal string assertions (which predate the Phase 48 restructure) against the new canonical file.
**How to avoid:** Per D-16, update the test file's `@maintainer_docs`/`@operator_docs` constants to point at `guides/maintainers.md` (both — the WARN-06 ratchet-commands content also lives only in `guides/maintainers.md`, not `guides/reviewer-verification.md`), AND restore the genuinely-dropped content (PR-vs-release-proof-depth table, Version namespaces, `RELEASE_PLEASE_TOKEN` secret doc, exact `## Hex release & recovery` heading) into `guides/maintainers.md` in the guide's current voice/format — this is real maintainer-facing content, not padding to satisfy a test. Fix the README assertion to expect `guides/maintainers.md` instead of `docs/MAINTAINERS.md`.
**Warning signs:** Any `CiPolicyContractTest` failure whose left-hand value in the assertion diff visibly reads *"Compatibility note: this old ... source path is kept ..."* is this exact bug class — the test is reading a Phase-48 stub, not the canonical guide.

### Pitfall 2: A stale 2-arity call silently kills 4 of 5 e2e "unrelated" failures
**What goes wrong:** `priv/repo/dev_seed.exs` calls `Scoria.Workflows.PromptRelease.start_release_workflow(draft_template.id, "operator-1")` (2 args) at two call sites (line 959, block "(f) Prompt Registry + Release Workbench"; line 1047, inside block "(g) Phase 13 IA linkage scenario"). The real function is now `start_release_workflow/3` (`template_id, actor_id, attrs`), requiring a `tenant_id` in `attrs` — added by the Phase 44-06 dashboard-tenant-scoping change (`lib/scoria/workflows/prompt_release.ex:13`, `attrs |> fetch_attr(:tenant_id) |> required_id!(:tenant_id)`; the real caller in `lib/scoria_web/live/prompt_live/release_workbench_live.ex:117` already passes `tenant_id: tenant_id`). Both stale calls raise `UndefinedFunctionError`, caught by each block's own `rescue`, and print a one-line warning — but because the raise happens *before* any of the block's other seed writes, **the entire rest of each try-block is skipped**: block (f)'s prompt-release approval never gets created (→ `modal_focus.spec.mjs` can't find "Reject Release"); block (g)'s demo run / trace spans / IA incident / eval-linked prompt release never get created either, since the failing call sits early in block (g)'s body (→ 3 of `ia_orientation.spec.mjs`'s 5 tests fail: `#traces-empty` stays present, the "Refund tool returned an error" incident link is never found, and "Open prompt release" is never rendered).
**Why it happens:** Phase 44-06 changed a public function's arity/contract for a good reason (tenant-scoping security fix) but `dev_seed.exs` — a maintainer dev tool, not part of the adopted package — wasn't updated in lockstep, and its `rescue`-and-print-and-continue design (intentional, for resilience across phases) hid the break from ordinary `make dev` use.
**How to avoid:** Fix both call sites to the current 3-arity contract:
```elixir
# line 959 (block f) — tenant_id is already bound as `tenant_id` earlier in the seed script
{:ok, _release_result} =
  PromptRelease.start_release_workflow(draft_template.id, "operator-1", tenant_id: tenant_id)

# line 1047 (block g) — `tenant_id` is bound at line 991 (`tenant_id = SupportJourney.tenant_id()`)
{:ok, _} =
  PromptRelease.start_release_workflow(draft.id, "operator-1", tenant_id: tenant_id)
```
Confirm the fix by re-running `mix run priv/repo/dev_seed.exs` (or `mix dev.setup`) and checking stdout no longer prints `"! ... skipped: function Scoria.Workflows.PromptRelease.start_release_workflow/2 is undefined or private"` — both `"✓ prompt release workflow started for draft: ..."` and the IA-linkage `"✓ IA demo run"`/`"✓ IA trace spans"`/`"✓ IA incident"` lines should appear instead. Then re-run `mix scoria.ui.e2e` and confirm all 4 previously-failing specs go green.
**Warning signs:** Any e2e failure whose error message is "element not found" (not a real assertion mismatch) for something the seed script is supposed to guarantee is present should prompt checking the seed script's own console output for a swallowed `rescue` warning before assuming a browser/locator bug.

### Pitfall 3: A dual desktop/mobile locator with `.first()` silently binds to the wrong element
**What goes wrong:** `phase16_parity.spec.mjs` (3 call sites: lines 513-514, 533, 575) locates the theme toggle with `page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first()`. In the DOM, `#scoria-theme-toggle-mobile` (inside `.scoria-mobile-topbar`, `lib/scoria_web/components/layouts/app.html.heex:22`) is rendered **before** `#scoria-theme-toggle` (inside the desktop `.scoria-topbar`, same file line 131). `.first()` resolves by DOM order, not visibility, so at Playwright's default `devices['Desktop Chrome']` viewport (≥768px), it always picks the hidden mobile toggle — `.scoria-mobile-topbar { display: none }` at `>=768px` per `assets/css/04-components.css:194-197`. `.click()` then waits up to its actionability timeout for the element to become visible and times out (~30s observed in the CI log, matching two internal retries of the 15s action timeout).
**Why it happens:** The combined selector was written assuming `.first()` would degrade gracefully across viewports, but Playwright's `.first()` is DOM-order-based, not CSS-visibility-aware.
**How to avoid:** Follow the codebase's own existing convention (already used elsewhere in `priv/dev/e2e/ia_orientation.spec.mjs:160,210`, e.g. `page.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first()`): change all 3 call sites to `page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').filter({ visible: true }).first()`. This satisfies D-09 (data-attribute/role + visibility scoping, no `force: true`).
**Warning signs:** Any Playwright test combining a desktop+mobile dual-ID selector with a bare `.first()` (no `.filter({ visible: true })`) is at risk of this exact bug whenever DOM order doesn't match viewport-priority order.

## Code Examples

### Fix 1 — `dev_seed.exs` stale arity (REL-02, root cause of 4/5 e2e failures)
```elixir
# Source: lib/scoria/workflows/prompt_release.ex:13 (current, correct contract)
def start_release_workflow(template_id, actor_id, attrs) when is_map(attrs) or is_list(attrs) do
  attrs = Map.new(attrs)
  tenant_id = attrs |> fetch_attr(:tenant_id) |> required_id!(:tenant_id)
  ...

# priv/repo/dev_seed.exs:959 — BEFORE (raises UndefinedFunctionError)
{:ok, _release_result} = PromptRelease.start_release_workflow(draft_template.id, "operator-1")

# AFTER
{:ok, _release_result} =
  PromptRelease.start_release_workflow(draft_template.id, "operator-1", tenant_id: tenant_id)

# priv/repo/dev_seed.exs:1047 — BEFORE
{:ok, _} = PromptRelease.start_release_workflow(draft.id, "operator-1")

# AFTER
{:ok, _} = PromptRelease.start_release_workflow(draft.id, "operator-1", tenant_id: tenant_id)
```

### Fix 2 — theme-toggle locator (REL-02, 5th e2e failure)
```javascript
// Source: priv/dev/e2e/phase16_parity.spec.mjs — existing project convention
// (mirrors priv/dev/e2e/ia_orientation.spec.mjs:160,210's `.filter({ visible: true })`)

// BEFORE (3 call sites: lines 513-514, 533, 575)
const toggle = page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first();

// AFTER
const toggle = page
  .locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile')
  .filter({ visible: true })
  .first();
```

### Fix 3 — `ci_policy_contract_test.exs` docs-path repoint (REL-01)
```elixir
# Source: test/scoria/ci_policy_contract_test.exs — current (stale)
@maintainer_docs "docs/MAINTAINERS.md"
@operator_docs "docs/operator_verification.md"

# Repoint to canonical guide paths (per D-16). Both WARN-06-style ratchet-command
# assertions and Hex-release-section assertions currently target content that
# lives ONLY in guides/maintainers.md — do not split @operator_docs to
# guides/reviewer-verification.md, since that guide does not carry ratchet or
# release commands (those are explicitly maintainer-only per guides/maintainers.md's
# own intro paragraph).
@maintainer_docs "guides/maintainers.md"
@operator_docs "guides/maintainers.md"
```
Then restore the dropped content in `guides/maintainers.md` (heading text, Version namespaces, RELEASE_PLEASE_TOKEN, PR-vs-release-proof-depth table) so the now-repointed assertions pass without weakening them. The pre-Phase-48 wording (recoverable via `git show c40bc630:docs/MAINTAINERS.md`) is a good drafting reference — adapt it to the current guide's numbered-list style rather than pasting verbatim.

Also fix the stale README assertion in the same test file:
```elixir
# BEFORE
assert readme =~ "docs/MAINTAINERS.md"
# AFTER (README already links here — Phase 48)
assert readme =~ "guides/maintainers.md"
```

### Fix 4 (optional, D-13 polish, non-blocking) — stale docs/ path comments and example version
```yaml
# .github/workflows/release-please.yml:3 and hex-publish.yml:3 — BEFORE
# Maintainer guide: docs/operator_verification.md#hex-release--recovery-maintainers
# AFTER
# Maintainer guide: guides/maintainers.md#hex-release-and-recovery

# .github/workflows/ci.yml:18 and ci-verify.yml:11 — BEFORE
# Maintainer narrative: docs/MAINTAINERS.md — CI gate map + flake policy.
# AFTER
# Maintainer narrative: guides/maintainers.md — CI gate map + flake policy.
```
```elixir
# lib/mix/tasks/scoria.post_publish_smoke.ex:20-21 — BEFORE
#     SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
#     SCORIA_REGISTRY_VERSION=0.1.1 mix scoria.post_publish_smoke
# AFTER
#     SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
#     SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke
```

### Fix 5 (optional, D-14, non-blocking — see State of the Art) — HexDocs subdomain URL
```elixir
# mix.exs:6-7 — BEFORE
@hexdocs_url "https://hexdocs.pm/scoria"
@release_docs_url "#{@hexdocs_url}/#{@version}"
# AFTER (matches Hex's June 2026 per-package-subdomain change; old form still 301s)
@hexdocs_url "https://scoria.hexdocs.pm"
@release_docs_url "#{@hexdocs_url}/#{@version}"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `hexdocs.pm/<package>` path-based docs URL | `<package>.hexdocs.pm` subdomain-based docs URL (private org docs: `org.hexorgs.pm/package`) | 2026-06-01, Hex.pm blog post "New HexDocs URLs: per-package subdomains" (Eric Meadows-Jönsson, Jonatan Männchen) — motivated by per-package browser-origin isolation from a Hex.pm security audit `[CITED: hex.pm/blog]` | Old-style URLs 301-redirect to the new form today (confirmed live: `curl`/WebFetch of `https://hexdocs.pm/scoria` → 301 → `https://scoria.hexdocs.pm/`), so this is a **correctness/D-14 polish item, not a release blocker**. `mix.exs`'s `@hexdocs_url`/`@release_docs_url`/`package()[:links]["Documentation"]` still use the old path form. |

**Deprecated/outdated:** None of Scoria's own tooling is deprecated by this change — only the literal URL string in `mix.exs` is stale relative to the new canonical form.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact restored wording for `guides/maintainers.md`'s dropped sections (Version namespaces, RELEASE_PLEASE_TOKEN, PR-vs-release-proof-depth table, `## Hex release & recovery` heading) should be adapted from the pre-Phase-48 `docs/MAINTAINERS.md` content (recovered via `git show c40bc630:docs/MAINTAINERS.md`) rather than invented fresh. | Pitfall 1 / Code Example 3 | Low — if the planner drafts different wording that still satisfies the literal test assertions and stays accurate, no functional risk. Only risk is losing some already-battle-tested phrasing (e.g., the exact secrets-setup `gh secret set` commands). |
| A2 | Repointing `@operator_docs` to `guides/maintainers.md` (not `guides/reviewer-verification.md`) is correct because WARN-06's ratchet commands and the Hex-release section are maintainer-only content that Phase 48 consolidated into `guides/maintainers.md`. | Pitfall 1 / Code Example 3 | Medium — if a plan instead tries to add ratchet/release commands to `guides/reviewer-verification.md` to satisfy the old `@operator_docs` path unchanged, it would violate D-16 (adopter guide getting maintainer-only content) and D-19 (keeping guides in the correct persona lane). Verify against `guides/maintainers.md`'s own intro line ("Adopter-first docs should start with Getting Started... do not move maintainer-only commands into README") before finalizing. |
| A3 | No live reproduction of `mix scoria.ui.e2e` against a locally-booted `make dev` server was performed in this research pass (root causes were instead derived from static analysis + the live PR #12 CI log, which is authoritative for what actually failed). | Pitfall 2 / Pitfall 3 | Low — the PR #12 CI log gives byte-exact error messages/locators for all 5 failures, and the `dev_seed.exs` arity bug and theme-toggle DOM-order bug are both confirmed by reading the actual current source (not guessed). Residual risk: after the fix, a *new* previously-masked seed issue could surface (e.g., another downstream block in dev_seed.exs implicitly depending on the now-fixed release-workflow return value) — the execution phase should re-run `mix scoria.ui.e2e` locally against a fresh `make dev` before pushing, per CONTEXT.md's own "Reproduce targeted specs locally where feasible." |

## Open Questions

1. **Does fixing the `dev_seed.exs` arity bug fully resolve all 4 e2e failures it's implicated in, or does block (g) have a second latent issue further down?**
   - What we know: The rescued exception happens early in block (g) (before any of that block's `IO.puts` checkmarks print), so everything downstream of line 1047 in that `try` — including the eval-runs-linked-to-prompt-versions section around line 1209+ — never ran in the failing CI run. Once the arity bug is fixed, that downstream code will execute for the first time in this exact form.
   - What's unclear: Whether the previously-never-executed code after line 1047 (eval runs, regressed score, dataset item linkage) is itself correct, since it has apparently never successfully run in CI.
   - Recommendation: After applying Fix 1, the execution phase must actually run `mix dev.setup` (or `mix run priv/repo/dev_seed.exs`) end-to-end against a fresh database and confirm **all** of block (g)'s `IO.puts` success lines print (not just the ones needed for the 3 currently-failing ia_orientation tests), before trusting the seed script is fully healthy.

2. **Should the maintainer-guide content restoration (Pitfall 1) be scoped narrowly to just what the 6 failing tests assert, or restore the full pre-Phase-48 richness (e.g., the full "What to expect in Actions" table, "Avoiding duplicate CI on Release PRs" section)?**
   - What we know: D-17 wants the maintainer path to stay "boring and copy-pasteable" with "explicit evidence" — richer content serves that goal. D-16 only requires making the *contracts* accurate, not maximizing content.
   - What's unclear: Whether restoring the full pre-Phase-48 depth risks re-introducing verbosity Phase 48 intentionally trimmed for a different reason (guide-ladder simplification for adopters — though `guides/maintainers.md` is maintainer-only, so adopter-simplicity concerns may not apply here).
   - Recommendation: Restore at minimum everything the 6 failing tests assert (narrowest fix, satisfies D-16 literally); additionally restore the "What to expect in Actions" and "Avoiding duplicate CI" sections only if the planner judges they add real maintainer value (they explain non-obvious automerge/dispatch skip behavior) — this is Claude's Discretion territory, not a locked decision.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres (local, port 5432) | Reproducing e2e/seed locally | ✓ (confirmed in this research session: `pg_isready` succeeded on `localhost:5432`) | not queried | — |
| Docker | `make dev` full-stack local repro | ✓ (`docker info` succeeded, client v29.5.2) | 29.5.2 | — |
| `gh` CLI | Inspecting live PR #12 / workflow run logs | ✓ (used extensively in this research pass) | not queried | — |
| Node.js / Playwright browsers | `mix scoria.ui.e2e` | Not verified in this research session (no e2e run attempted) | — | Execution phase must confirm `npm --prefix priv/dev ci` + `npx playwright install --with-deps chromium` succeed locally before trusting a local e2e repro. |

**Missing dependencies with no fallback:** None identified as blocking.
**Missing dependencies with fallback:** Node/Playwright browser install status unverified — execution phase should verify before relying on local e2e reproduction; CI already has this wired correctly regardless.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`) + Playwright `@playwright/test` (browser e2e) |
| Config file | `test/test_helper.exs` (ExUnit); `priv/dev/e2e/playwright.config.mjs` (Playwright) |
| Quick run command | `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |
| Full suite command | `mix ci` (local merge-gate reproduction; see `guides/maintainers.md`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Docs-contract paths/content match canonical `guides/` source; `v2.15` breadcrumb stays present | unit/contract | `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ |
| REL-02 | Seeded IA trace/incident/eval-prompt-release/pending-approval evidence renders; theme toggle is clickable at desktop width | e2e (Playwright) | `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` (against `make dev` + `mix run priv/repo/dev_seed.exs`) | ✅ |
| REL-03 | No stale `0.1.1` guidance outside historical CHANGELOG; live `0.1.2`/target `0.1.3` stated correctly | unit/contract | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs` (`"README does not contain stale 0.1.1 release or GitHub fallback guidance"`, already green) | ✅ |
| REL-04 | Release preview/docs build clean; `ci-gate` required aggregate green; Hex lists `0.1.3`; post-publish smoke passes fresh install + upgrade | contract + live CI + external registry check | `MIX_ENV=dev mix scoria.release_preview` (already green); `gh pr checks 12`; `curl https://hex.pm/api/packages/scoria/releases/0.1.3`; `SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke` | ✅ (all commands exist; final two require a live publish to actually execute) |

### Sampling Rate
- **Per task commit:** the focused policy-lane command above (REL-01 fixes) or `mix scoria.ui.e2e` (REL-02 fixes).
- **Per wave merge:** `mix ci` locally, then push and let `ci-verify.yml` + `ci.yml`'s `e2e` job run in full.
- **Phase gate:** `CI / ci-gate` green on PR #12's latest head, then the full release-please → publish-hex → post-publish-attest chain, captured per D-04 (workflow/run URL or ID in closeout state).

### Wave 0 Gaps
None — existing test infrastructure (ExUnit contract tests + Playwright e2e specs + `mix scoria.release_preview`/`mix scoria.post_publish_smoke`) already covers every phase requirement. This phase repairs existing tests/fixtures rather than adding new coverage, per its "no large test-harness rewrites" scope fence. The only new coverage the planner might add (Claude's Discretion, per CONTEXT.md) is one focused regression test pinning the `dev_seed.exs` call-site fix if the existing e2e specs are judged insufficient to catch a future regression of the same class — not required.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Out of scope — host app owns auth per D-18; unchanged by this phase. |
| V4 Access Control (tenant isolation) | Yes, incidentally | The root-cause bug this phase fixes (Pitfall 2) is a *consumer* of Phase 44-06's tenant-scoping hardening (`PromptRelease.start_release_workflow/3` now requires an explicit `tenant_id`, closing a cross-tenant approval-write gap). This phase's fix is purely updating a dev-only seed script to the already-secured contract — it does not touch or weaken that control. |
| V5 Input Validation | No | Not touched by this phase's fixes. |
| V6 Cryptography | No | Not touched by this phase's fixes (`HEX_API_KEY`/`RELEASE_PLEASE_TOKEN` remain GitHub Actions secrets, unchanged). |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Manual Hex publish before CI is green (bypassing release gate) | Tampering / Elevation of Privilege | `hex-publish.yml`'s own `gate-ci-green` job (already present, unchanged) — D-02/D-03 forbid bypassing this. |
| Re-publishing an already-listed Hex version | Tampering | Existing `Skip if version already on Hex` idempotency step in both `hex-publish.yml` and `release-please.yml`'s `publish-hex` job — already present, unchanged. |
| Dev-seed script silently degrading to a weaker (untenanted) data shape after an API contract tightens | Tampering (of test evidence) / Information Disclosure (if it silently re-widened scope instead) | This phase's fix restores the seed script to the *already-secured* Phase 44-06 contract (explicit `tenant_id` required) — no new mitigation needed, just correct usage of the existing one. |

## Sources

### Primary (HIGH confidence)
- Live repo source: `test/scoria/ci_policy_contract_test.exs`, `priv/repo/dev_seed.exs`, `lib/scoria/workflows/prompt_release.ex`, `lib/scoria_web/components/layouts/app.html.heex`, `assets/css/04-components.css`, `mix.exs`, `.github/workflows/*.yml`, `guides/maintainers.md` — read directly in this session.
- `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` — run in this session (94 tests, 7 failures, exact assertions captured).
- `MIX_ENV=dev mix docs --warnings-as-errors` and `MIX_ENV=dev mix scoria.release_preview` — both run in this session, both green.
- `gh pr view 12` / `gh run view 29043718187 --log-failed` / `gh run view 29043718187 --log` — live GitHub Actions state and logs pulled in this session (PR #12 status, exact e2e failure stack traces, and the seed script's own `! ... skipped: function ... is undefined or private` console output).
- `git show c40bc630:docs/MAINTAINERS.md` — recovered pre-Phase-48 canonical maintainer-guide content for drafting reference.

### Secondary (MEDIUM confidence)
- [New HexDocs URLs: per-package subdomains](https://hex.pm/blog) — Hex.pm blog post, 2026-06-01, fetched via WebFetch in this session (title, authors, and URL-format details confirmed).
- Live redirect check: `https://hexdocs.pm/scoria` → 301 → `https://scoria.hexdocs.pm/` (confirmed via WebFetch in this session).

### Tertiary (LOW confidence)
- None — every claim in this document was either read directly from the repo, executed as a command in this session, or fetched from a cited external source.

## Metadata

**Confidence breakdown:**
- REL-01 (policy/docs contract): HIGH — reproduced the exact 7 failures locally, confirmed the breadcrumb test independently passes, confirmed exact content gaps in `guides/maintainers.md` via grep.
- REL-02 (e2e regressions): HIGH — root-caused 4/5 failures to a single exact `UndefinedFunctionError` message pulled from the live PR #12 CI log, confirmed the correct function signature in source, confirmed the 5th (theme-toggle) via DOM-order + CSS media query inspection.
- REL-03 (version/docs truth): HIGH — repo-wide grep confirmed README/mix.exs/manifest are already correct; residual stale references are enumerated exactly (file:line).
- REL-04 (release/publish/proof): HIGH — confirmed release/publish/smoke workflow topology already matches locked decisions; confirmed PR #12's live, current CI status via `gh pr view`.

**Research date:** 2026-07-10
**Valid until:** 7 days (release-in-flight; PR #12 status, CI run IDs, and Hex/HexDocs external state can change quickly — re-verify `gh pr view 12` and re-run the focused test command before planning execution if more than a few days pass).
