# Phase 35: Maintenance release — 0.1.2 publish + post-publish smoke - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase gets the queued `0.1.2` Scoria maintenance release from open Release Please PR to verified live Hex package.

The implementation should deliver:

- Fix the current Release PR #3 CI failure without expanding release automation into unrelated docs churn.
- Confirm the Phase 34 post-publish smoke port fix is present before release (`5432:5432`, no `55432`).
- Build docs/package preview locally with no warnings or release-surface drift before merge.
- Merge the release PR only on latest-SHA green `CI / ci-gate`.
- Publish `0.1.2` to Hex through the existing release automation and prove it with a live-registry post-publish smoke.
- Make REL-02 mean actual live-registry lineage for this release: `0.1.0 -> 0.1.2`, because Hex currently lists only `0.1.0`.

Out of scope: publishing or backfilling `0.1.1`, changing CI topology, renaming required checks, changing release-please/automerge file allowlists unless a deliberately new release-file policy is chosen, sibling-repo Docker fleet work, UI polish, and broad runtime/installer refactors unrelated to the release block.

</domain>

<decisions>
## Implementation Decisions

Calibration: the user selected all gray areas and asked for subagent-backed research, pros/cons/tradeoffs, ecosystem lessons, prompt/brandbook context, and one cohesive recommendation set. Four `gsd-advisor-researcher` agents covered the registry version path, Release PR CI repair, pre-merge verification, and post-publish recovery. Decisions below are LOCKED.

### Current release facts
- **D-01:** Treat these as the 2026-06-18 pre-state facts for planning:
  - GitHub PR #3, `chore(main): release 0.1.2`, is open from `release-please--branches--main` to `main`.
  - PR #3 changes only `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs`.
  - PR #3 is `UNSTABLE`; `verify / full-suite (3/4)`, `verify / verify-summary`, and `ci-gate` are failing.
  - The observed failure is `Scoria.PackageSurfaceTest`: README fallback guidance expects a GitHub tag matching `published_version()` after the release PR bumps `mix.exs` to `0.1.2`, while the README still references `v0.1.1`.
  - Hex live registry state is `latest_version: "0.1.0"` with only `0.1.0` listed.
- **D-02:** Do not rely on `.planning/PROJECT.md`, README, or changelog prose implying `0.1.1` is already live. For Phase 35, Hex itself is the source of truth for live package state.
- **D-03:** Treat the REL-03 port-fix implementation as already completed by Phase 34. Phase 35 must verify it before release, not redo it.

### Todo folding and scope
- **D-04:** Fold no pending todos into Phase 35. The phase already has a narrow release objective; adding adjacent cleanup increases release risk.
- **D-05:** Review but defer `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md`. It remains post-ship CI cleanup and is not blocking `0.1.2`.
- **D-06:** Review but defer `.planning/todos/pending/docker-dx-fleet-hardening.md`. Phase 34 already absorbed the Scoria-local Docker DX guard work; the remaining sibling-repo fleet convergence is outside this release.
- **D-07:** Review but defer `.planning/todos/pending/2026-06-18-make-approval-toasts-legible.md`. It is unrelated UI polish.

### Registry version path
- **D-08:** Publish `0.1.2` directly. Do not publish, restore, or backfill `0.1.1` first.
- **D-09:** REL-02 means "prove upgrade from the previous live Hex release," not "subtract one patch version." For Phase 35, the expected upgrade pair is `0.1.0 -> 0.1.2`.
- **D-10:** Update `Scoria.HexConsumerContract` and its tests so registry upgrade semantics follow actual live lineage for this release. The current arithmetic `patch - 1` assumption is wrong when a prepared but unpublished patch was skipped.
- **D-11:** Keep the fresh install proof exact-pinned to `0.1.2`. The upgrade leg should use `0.1.0 -> 0.1.2`; the fresh install leg should prove `0.1.2` installs from live Hex.
- **D-12:** Do not skip the upgrade leg. Skipping would make REL-02 materially weaker and recreate the blind spot the registry smoke exists to close.
- **D-13:** Record this in code/test names or failure messages as "previous live registry release" so future maintainers do not reintroduce patch-arithmetic assumptions.

### Release PR CI repair
- **D-14:** Keep the active README dependency guidance Hex-primary:
  ```elixir
  {:scoria, "~> 0.1", hex: :scoria}
  ```
- **D-15:** Treat the GitHub fallback as exceptional fork/pinned-patch guidance, not as a release-candidate version contract. A pending release PR should not make README point at a tag that does not exist yet.
- **D-16:** Change `test/scoria/package_surface_test.exs` so it still asserts one active Hex dependency and the existence/shape of fallback repo/tag guidance, but stops comparing the fallback tag to `HexConsumerContract.published_version()`.
- **D-17:** Do not add README to Release Please `extra-files` or to `.github/workflows/release-pr-automerge.yml`'s allowed files just to keep a commented fallback tag synchronized with `mix.exs`.
- **D-18:** Fix the contract on `main`, then refresh PR #3 by rerunning `release-please.yml` or otherwise letting Release Please update the release branch. Do not patch the release branch by hand unless automation cannot refresh it and the manual change is documented.
- **D-19:** Leave `.github/workflows/release-pr-automerge.yml`'s allowed-file policy unchanged for this release unless Phase 35 deliberately chooses to make README a managed release artifact. The recommended path does not need that.

### Pre-merge verification bar
- **D-20:** Use a staged verification bar:
  1. confirm live pre-state and PR state;
  2. run local docs/package preview;
  3. run focused release contract tests;
  4. require remote `CI / ci-gate` green on the latest release PR SHA;
  5. allow the release workflow to publish;
  6. require live Hex lookup and post-publish smoke.
- **D-21:** Minimum local release-surface checks before merge:
  ```bash
  MIX_ENV=dev mix docs --warnings-as-errors
  MIX_ENV=dev mix scoria.release_preview
  MIX_ENV=test mix test --warnings-as-errors \
    test/scoria/package_surface_test.exs \
    test/scoria/hex_consumer_contract_test.exs \
    test/scoria/ci_policy_contract_test.exs \
    test/mix/tasks/scoria.release_preview_test.exs
  ```
- **D-22:** Also verify the Phase 34 port fix remains intact:
  ```bash
  rg -n "55432" .github/workflows/post-publish-smoke.yml
  ```
  Expected: zero hits.
- **D-23:** If Phase 35 touches non-release runtime, DB, installer, or workflow plumbing beyond the narrow package-surface fix, run full `mix ci` as well. Do not count `mix ci --skip-optional` as a green release gate.
- **D-24:** Remote merge authority remains latest-SHA GitHub `CI / ci-gate`. Do not merge based on stale successful checks, skipped checks, or local-only verification.

### Post-publish proof and recovery
- **D-25:** After publish, verify registry state directly:
  ```bash
  mix hex.info scoria 0.1.2
  curl -fsS https://hex.pm/api/packages/scoria | jq '.latest_version, [.releases[].version]'
  ```
- **D-26:** The post-publish smoke should run with `SCORIA_REGISTRY_VERSION=0.1.2` and prove both exact-pinned fresh install and live-lineage upgrade where eligible.
- **D-27:** If publish appears to succeed but index wait or smoke fails, classify state before mutating the registry:
  - If `0.1.2` is visible and the failure is index lag, runner network, Postgres service, or another transient, hold announcement and rerun `post-publish-smoke.yml` only.
  - If publish completion is uncertain or `0.1.2` is not visible after bounded checks, use existing `.github/workflows/hex-publish.yml` manual recovery with exact `tag` and `release_version` inputs.
  - If exact-pinned fresh install or semver upgrade fails against a visible `0.1.2`, stop and investigate package contents/version consistency.
  - Only revert/retire and ship a patch for a confirmed bad artifact, security issue, invalid package, or materially wrong published content.
- **D-28:** Do not blind-rerun publish or mutate Hex just because the smoke is red. Public Hex releases are effectively durable artifacts; recovery should minimize blast radius.

### Voice, docs, and UX applicability
- **D-29:** No product UI or visual-design work belongs in this phase.
- **D-30:** Docs, release notes, commit messages, workflow summaries, and failure text should follow `brandbook/brand-book.md`: calm, exact, useful. State what happened, what was verified, and the next action. Avoid hype, vague automation claims, and "Scoria AI" phrasing.
- **D-31:** Developer ergonomics matter most here: make release failures actionable, keep commands copy-pasteable, keep release automation boring, and avoid surprising adopters with README fallback tags for unpublished versions.

### Claude's Discretion
- Exact helper names and test names may be refined as long as D-08 through D-28 hold.
- The planner may choose whether the live-lineage upgrade pair is represented as a small explicit table, a function with a documented floor, or another local pattern, but it must be deterministic in CI and must not call Hex from unit tests.
- The planner may include a short maintainer note if needed, but should not broaden Phase 35 into a documentation rewrite.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 35: Maintenance release — 0.1.2 publish + post-publish smoke" - phase goal and success criteria.
- `.planning/REQUIREMENTS.md` - REL-01, REL-02, and REL-03.
- `.planning/PROJECT.md` section "Release Queue" and current milestone notes - release intent; verify live registry state rather than trusting stale release prose.
- `.planning/STATE.md` - current position and recent Phase 34/35 decisions.
- `.planning/phases/34-docker-dx-drift-guard-ci-guard-extension/34-CONTEXT.md` - Phase 34 D-05 through D-09 completed the `post-publish-smoke.yml` port fix and defined Phase 35's re-verification duty.

### Release automation and CI
- `.github/workflows/release-please.yml` - Release Please PR creation/update and publish workflow after release PR merge.
- `.github/workflows/release-pr-automerge.yml` - release PR auto-merge policy, allowed files, label/branch checks, and `ci-gate` dependency.
- `.github/workflows/hex-publish.yml` - manual recovery workflow for uncertain publish completion; includes CI/ref checks and post-publish smoke chaining.
- `.github/workflows/post-publish-smoke.yml` - reusable/manual live-registry smoke workflow; must stay on `5432:5432` / `SCORIA_DB_PORT: 5432`.
- `.github/workflows/ci.yml` - required `CI / ci-gate` topology and full-suite failure context.
- `.github/workflows/ci-verify.yml` - existing policy/release-preview lane wiring.
- `release-please-config.json` - release type, changelog path, tag format, and bootstrap configuration.
- `.release-please-manifest.json` - current local Release Please last-version marker.

### Package and smoke source
- `mix.exs` - local package version and Hex package metadata.
- `CHANGELOG.md` - release-note surface produced by Release Please.
- `README.md` - Hex-primary install guidance and GitHub fallback text that triggered the current PR failure.
- `lib/scoria/hex_consumer_contract.ex` - central install-snippet, version, and registry-upgrade contract; update here instead of scattering release strings.
- `lib/mix/tasks/scoria.post_publish_smoke.ex` - exact-pinned live-registry smoke orchestration.
- `lib/mix/tasks/scoria.release_preview.ex` - local docs + unpacked Hex package preview task.
- `test/scoria/package_surface_test.exs` - current failing release PR contract; narrow fallback semantics here.
- `test/scoria/hex_consumer_contract_test.exs` - registry lineage/version contract tests.
- `test/scoria/host_app_registry_proof_test.exs` - fresh live Hex install proof.
- `test/scoria/host_app_registry_upgrade_proof_test.exs` - live registry upgrade proof.
- `test/scoria/ci_policy_contract_test.exs` - policy guard including the post-publish smoke port scan.
- `test/mix/tasks/scoria.release_preview_test.exs` - release preview task contract.
- `docs/MAINTAINERS.md` - maintainer release/CI map and release communication surface.
- `docs/operator_verification.md` - operator-facing verification language that should remain exact if touched.

### Brand, project DNA, and prompt research
- `brandbook/brand-book.md` - canonical voice, naming, docs, accessibility, and microcopy direction.
- `brandbook/README.md` - current brandbook source priority; current brandbook supersedes older prompt research where they conflict.
- `prompts/sztheory-elixir-dna.md` - Operator-First DX, batteries-included but composable, robust CI/CD posture.
- `prompts/scoria-gsd-kickoff.md` - project vision and release engineering expectations.
- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native library/product posture and OSS/CI/release-engineering recommendations.
- `prompts/scoria-brand-book-deep-research.md` - supporting historical brand research; subordinate to `brandbook/`.
- `prompts/brand-book-pressure-test-prompt.md` - pressure-test lens for developer credibility, Elixir ecosystem fit, docs/Hex package/release notes, and useful microcopy.

### Reviewed todos
- `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md` - reviewed and deferred as unrelated post-ship cleanup.
- `.planning/todos/pending/docker-dx-fleet-hardening.md` - reviewed and deferred; remaining work is sibling-repo fleet convergence.
- `.planning/todos/pending/2026-06-18-make-approval-toasts-legible.md` - reviewed and deferred as unrelated UI polish.

### External primary references used during discussion
- `https://hex.pm/packages/scoria` - live package page; on 2026-06-18 it listed `0.1.0` as the only visible version.
- `https://hex.pm/api/packages/scoria` - live package API used to confirm `latest_version: "0.1.0"` and releases `["0.1.0"]`.
- `https://github.com/szTheory/scoria/pull/3` - open Release Please PR #3 for `0.1.2`.
- `https://hex.pm/docs/publish` - Hex publish guide: metadata in `mix.exs`, build/docs expectations, publish flow, and post-publish package testing.
- `https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html` - `mix hex.publish`, `--dry-run`, `--replace`, and `--revert` behavior.
- `https://hex.pm/docs/faq` - Hex docs troubleshooting and public package immutability expectations.
- `https://hex.pm/docs/usage` - Hex dependency syntax and separation between Hex deps and SCM deps.
- `https://github.com/googleapis/release-please` - Release Please lifecycle and what it automates.
- `https://github.com/googleapis/release-please-action` - GitHub Action behavior for Release PRs and releases.
- `https://github.com/googleapis/release-please/blob/main/docs/customizing.md#updating-arbitrary-files` - arbitrary file update support and why README should not be added casually.
- `https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows` - reusable workflow input/secret semantics and local workflow call behavior.
- `https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html` - `mix docs` and `--warnings-as-errors`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Release Please already opens and refreshes PR #3; use that path rather than hand-maintaining a release branch.
- `release-pr-automerge.yml` already restricts release PR files to `.release-please-manifest.json`, `CHANGELOG.md`, and `mix.exs`; keep that guard unless there is a deliberate policy change.
- `hex-publish.yml` already exists as an idempotent manual recovery lane and chains post-publish smoke.
- `post-publish-smoke.yml` is already reusable/manual and already carries the Phase 34 `5432` fix.
- `Scoria.HexConsumerContract` centralizes package dependency snippets and registry upgrade pairing; it is the right place to encode "previous live registry release."
- `mix scoria.release_preview` builds docs and an unpacked Hex preview, then checks required package paths.

### Established Patterns
- Scoria release and policy work favors narrow contract tests over broad workflow churn.
- Protected check name `CI / ci-gate` stays byte-stable.
- Release PRs should stay machine-generated and low-churn; arbitrary docs changes belong on `main` before Release Please refreshes the branch, not as ad hoc release branch edits.
- Hex registry proof should use exact published versions, while adopter docs should use normal Hex version requirements.
- Unit tests should be deterministic and offline; live Hex checks belong in explicit smoke/release commands.
- Failure text should be operational: what drifted, what command proves it, and what to do next.

### Integration Points
- `package_surface_test.exs` currently blocks PR #3; fixing its fallback semantics is the first unblocker.
- `hex_consumer_contract_test.exs` must change with `HexConsumerContract` so the `0.1.0 -> 0.1.2` upgrade pair is deliberate.
- `host_app_registry_upgrade_proof_test.exs` consumes `registry_upgrade_pair/1`; update expectations so the post-publish smoke tests the right live lineage.
- `release-please.yml` and `release-pr-automerge.yml` should handle PR refresh/merge after `main` has the contract fix.
- `hex-publish.yml` is recovery, not the normal path when Release Please publish completes.

</code_context>

<specifics>
## Specific Ideas

- Recommended Release PR unblock summary:
  ```text
  Keep README Hex-primary. The commented GitHub fallback is fork/pinned-patch guidance, not a release-candidate tag contract. PackageSurfaceTest should guard the fallback shape without requiring it to match Mix.Project.config()[:version].
  ```
- Recommended registry-lineage test expectation:
  ```elixir
  assert HexConsumerContract.registry_upgrade_pair("0.1.2") == %{
           from: "0.1.0",
           to: "0.1.2"
         }
  ```
- Recommended pre-release command block:
  ```bash
  MIX_ENV=dev mix docs --warnings-as-errors
  MIX_ENV=dev mix scoria.release_preview
  MIX_ENV=test mix test --warnings-as-errors \
    test/scoria/package_surface_test.exs \
    test/scoria/hex_consumer_contract_test.exs \
    test/scoria/ci_policy_contract_test.exs \
    test/mix/tasks/scoria.release_preview_test.exs
  rg -n "55432" .github/workflows/post-publish-smoke.yml
  ```
- Recommended post-release command block:
  ```bash
  mix hex.info scoria 0.1.2
  SCORIA_REGISTRY_VERSION=0.1.2 mix scoria.post_publish_smoke
  ```
- Recommended recovery microcopy:
  ```text
  0.1.2 is visible on Hex, but registry smoke failed during index/network/service verification. Hold announcement, rerun post-publish smoke, and do not rerun publish unless visibility or artifact integrity is uncertain.
  ```

</specifics>

<deferred>
## Deferred Ideas

### Reviewed Todos (not folded)
- **ci-policy-job-cache-key-mislabel.md:** Deferred as unrelated post-ship CI cleanup.
- **docker-dx-fleet-hardening.md:** Deferred because remaining work is sibling-repo fleet convergence; Scoria-local Docker DX guards were completed in Phase 34.
- **2026-06-18-make-approval-toasts-legible.md:** Deferred as unrelated UI polish.

### Other Deferred Items
- Backfilling `0.1.1` is explicitly rejected for Phase 35.
- README as a Release Please-managed arbitrary file is explicitly rejected for this release.
- UI/visual design work is not applicable to this phase.

</deferred>

---

*Phase: 35-Maintenance release — 0.1.2 publish + post-publish smoke*
*Context gathered: 2026-06-18*
