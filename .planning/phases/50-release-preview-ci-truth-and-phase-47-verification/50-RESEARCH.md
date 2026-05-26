# Phase 50: Release-preview CI truth and Phase 47 verification - Research

**Researched:** 2026-05-26
**Domain:** CI-safe maintainer proof lanes, ExDoc environment boundaries, and backfilled phase verification for Scoria's publish-facing package surface. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: docs/operator_verification.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked From Roadmap, Requirements, And Prior Phase Context
- **D-01:** Phase 50 exists only to close the `ADPT-03` and `ADPT-04` audit gap around the broken release-preview CI lane and the missing `47-VERIFICATION.md`. It should not reopen broader adoption-lane work that Phase 51 already owns. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- **D-02:** The canonical maintainer closeout command remains `mix scoria.release_preview`; support-truth from Phase 49 already locked the public closeout chain as `mix scoria.release_preview` then `mix test.adoption`. [VERIFIED: .planning/phases/49-support-truth-and-adoption-closeout/49-CONTEXT.md] [VERIFIED: docs/operator_verification.md]
- **D-03:** Phase 50 may either support `MIX_ENV=test mix scoria.release_preview` or truthfully re-scope the closeout lane so it no longer depends on dev-only tooling under the test env. [VERIFIED: .planning/ROADMAP.md]
- **D-04:** The release-preview failure is real in the current tree: `MIX_ENV=test mix scoria.release_preview` exits with `The task "docs" could not be found.` because `:ex_doc` is only available in `:dev`. [VERIFIED: mix.exs] [VERIFIED: MIX_ENV=test mix scoria.release_preview]
- **D-05:** The default-lane timeout is also still real, but it belongs to Phase 51, not this phase. `MIX_ENV=test mix test.adoption` still times out after 60000ms in `Scoria.HostAppConsumerProofTest`. [VERIFIED: MIX_ENV=test mix test.adoption] [VERIFIED: .planning/ROADMAP.md]

### No Phase Context Present
- **D-06:** No `50-CONTEXT.md` exists, so this phase should be planned from roadmap scope, requirements, milestone audit evidence, and current codebase state only. Preserve the gap-closure boundary instead of inventing fresh product-surface work. [VERIFIED: gsd-sdk query init.plan-phase 50]

### the Agent's Discretion
- Exact CI expression for running the release-preview lane in the supported env.
- Exact drift-prevention test assertions that keep the closeout command unprefixed and CI-safe.
- Exact bookkeeping files updated after `47-VERIFICATION.md` exists.

### Deferred Ideas (OUT OF SCOPE)
- Fixing the `mix test.adoption` timeout or widening its timeout budget.
- Rewriting the public lane hierarchy established in Phase 49.
- Changing package contents, docs extras, or the release-preview task's required inventory list unless a new regression is discovered while verifying.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-03 | Maintainer can build Scoria's publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `mix scoria.release_preview` as the bounded docs proof, but run it in the env where `mix docs` is actually supported (`:dev`) instead of the CI-global `:test` env. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] |
| ADPT-04 | Maintainer can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing release-preview task and package-surface tests as the bounded proof basis, then backfill `47-VERIFICATION.md` with current command evidence. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex] [VERIFIED: test/scoria/package_surface_test.exs] [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs] |
</phase_requirements>

## Summary

Scoria's release-preview lane is already the right maintainer proof command, but CI wires it through the wrong environment. The task itself runs `mix docs` and a Hex unpack preview; `mix docs` is only available when `:ex_doc` is loaded, and `mix.exs` declares `{:ex_doc, "~> 0.38", only: :dev, runtime: false}`. Because `.github/workflows/ci.yml` exports `MIX_ENV=test` for the whole job, the release-preview step currently fails before it can prove anything useful. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: MIX_ENV=test mix scoria.release_preview]

That means the simplest truthful fix is not to widen the public closeout chain or drag ExDoc into every test run. The stronger fit is to keep `mix scoria.release_preview` as the canonical maintainer command, run it explicitly in `:dev` inside CI, and add drift guards that prevent the repo from accidentally reintroducing a `MIX_ENV=test` release-preview contract. This preserves the Phase 49 support story while removing environment wiring drift from the merge gate. [INFERENCE from verified codebase state]

Phase 47 also still lacks a verification report even though its implementation artifacts exist and local maintainer commands already pass in the supported env. Once the CI env contract is repaired, the phase can close the audit gap by rerunning the bounded release-preview and package-surface checks, then writing `47-VERIFICATION.md` in the same evidence-first format used by later phases. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-01-SUMMARY.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-02-SUMMARY.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-03-SUMMARY.md]

## Alternative Analysis

### Option A: Support `MIX_ENV=test mix scoria.release_preview`
- **How:** make `:ex_doc` available in `:test` or otherwise load the docs task under the test env.
- **Pros:** preserves the exact audit repro command.
- **Cons:** widens dev-only tooling into the test env, adds avoidable compile/load cost to the broader test lane, and keeps the public closeout story entangled with an env prefix the docs never promised. [INFERENCE from `mix.exs` and current docs]

### Option B: Keep `mix scoria.release_preview` canonical and run it in `:dev` inside CI
- **How:** override the release-preview CI step to `MIX_ENV=dev mix scoria.release_preview` while leaving the rest of the job on `MIX_ENV=test`.
- **Pros:** matches the current public docs, respects the dev-only ExDoc boundary, fixes the real merge gate, and minimizes runtime blast radius. [VERIFIED: docs/operator_verification.md] [VERIFIED: .github/workflows/ci.yml]
- **Cons:** the exact `MIX_ENV=test mix scoria.release_preview` repro stays red by design, so docs/tests must make the supported command boundary explicit.

### Recommendation
- Choose **Option B**. Scoria already documents the maintainer lane as plain `mix scoria.release_preview`, not `MIX_ENV=test mix scoria.release_preview`. The truthful repair is to make CI invoke that supported command in the env where it is defined, then backfill Phase 47 verification from that corrected lane. [INFERENCE from verified codebase state]

## Current Repo Evidence

### Release-preview env drift
- `.github/workflows/ci.yml` exports `MIX_ENV=test` for the entire job, including the release-preview step. [VERIFIED: .github/workflows/ci.yml]
- `mix.exs` keeps `:ex_doc` in `only: :dev`, so `mix docs` is not available in `:test`. [VERIFIED: mix.exs]
- `MIX_ENV=test mix scoria.release_preview` currently fails with `The task "docs" could not be found.` [VERIFIED: MIX_ENV=test mix scoria.release_preview]

### Existing proof seam is already good
- `Mix.Tasks.Scoria.ReleasePreview` already bundles the right bounded proof: it runs `mix docs`, builds an unpacked Hex preview, and asserts required package paths. [VERIFIED: lib/mix/tasks/scoria.release_preview.ex]
- `test/mix/tasks/scoria.release_preview_test.exs` already locks the task's required inventory contract without running the heavier shell path. [VERIFIED: test/mix/tasks/scoria.release_preview_test.exs]
- `test/scoria/package_surface_test.exs` already proves docs/package truth at the source/package seam. [VERIFIED: test/scoria/package_surface_test.exs]

### Missing verification artifact
- Phase 47 has three completed summaries and a validation contract, but no `47-VERIFICATION.md`. [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-01-SUMMARY.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-02-SUMMARY.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-03-SUMMARY.md] [VERIFIED: .planning/phases/47-release-packaging-and-docs-truth/47-VALIDATION.md]
- The milestone audit explicitly names the missing verification file and the CI env drift as the blockers to treating ADPT-03 and ADPT-04 as closed. [VERIFIED: .planning/v2.2-MILESTONE-AUDIT.md]

## Recommended Project Structure

```text
.github/workflows/ci.yml
docs/operator_verification.md
test/scoria/adoption_surface_test.exs
.planning/phases/47-release-packaging-and-docs-truth/47-VERIFICATION.md
.planning/REQUIREMENTS.md
.planning/ROADMAP.md
```

This keeps the fix inside the same seams that currently own the gap: CI env wiring, support-truth docs/tests, phase verification evidence, and milestone bookkeeping. [INFERENCE from existing repo structure]

## Plan Shape Recommendation

### Plan 50-01: Restore truthful CI env wiring for release-preview
- Change the CI release-preview step to run `mix scoria.release_preview` in `MIX_ENV=dev`.
- Keep the public maintainer command unprefixed in docs.
- Add or tighten source assertions so the repo does not drift back to a `MIX_ENV=test` release-preview contract.

### Plan 50-02: Backfill Phase 47 verification from the corrected lane
- Re-run the bounded release-preview and package-surface checks after Plan 50-01 lands.
- Create `47-VERIFICATION.md` with observable truths, command evidence, and requirement coverage for `ADPT-03` and `ADPT-04`.

### Plan 50-03: Repair milestone bookkeeping for the now-verified packaging/docs phase
- Mark `ADPT-03` and `ADPT-04` complete in requirement traceability once `47-VERIFICATION.md` exists.
- Update the roadmap's Phase 50 bookkeeping so the gap-closure work no longer reads as `0 plans`.

## Risks And Pitfalls

- If CI keeps exporting `MIX_ENV=test` into the release-preview step, the merge gate will continue to fail for environment reasons before any docs/package regression is actually checked. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: MIX_ENV=test mix scoria.release_preview]
- If Phase 50 "fixes" the issue by silently broadening ExDoc into the test env, Scoria will mask the real contract boundary instead of documenting and enforcing it. [INFERENCE from `mix.exs` and current public docs]
- If `47-VERIFICATION.md` is written from prior summaries alone without rerunning the bounded commands, the phase will still lack fresh executable proof. [INFERENCE from milestone audit findings]
- If bookkeeping updates claim broader milestone closure, they will overstep Phase 51, which still owns the `mix test.adoption` timeout and `49-VERIFICATION.md`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: MIX_ENV=test mix test.adoption]

## Verification Commands

```bash
MIX_ENV=test mix scoria.release_preview
MIX_ENV=dev mix scoria.release_preview
MIX_ENV=test mix test test/scoria/package_surface_test.exs test/mix/tasks/scoria.release_preview_test.exs --trace
MIX_ENV=test mix test.adoption
```

## Recommendation

Plan Phase 50 as three sequential plans: first correct the CI env contract around `mix scoria.release_preview`, then write `47-VERIFICATION.md` from fresh bounded proof, then repair the roadmap/requirements bookkeeping that still treats Phase 47 as summary-only closure. Keep the adoption timeout explicitly deferred to Phase 51.
