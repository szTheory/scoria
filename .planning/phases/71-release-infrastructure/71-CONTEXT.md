# Phase 71: Release Infrastructure - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Prepare szTheory-standard release automation and maintainer runbook **without publishing to Hex yet**: `CHANGELOG.md`, release-please config + workflow, publish workflow prep (CI topology mirror), manual recovery workflow documentation, Hex name attestation, `.tool-versions` pin, and v2.6 remote CI gate-zero attestation (or bounded waiver).

**Non-goals (unchanged):** `mix hex.publish` to production registry, README Hex badge, `package_surface_test` Hex-first flip, merging the Release Please PR, removing `release-as` pin (Phase 72).

</domain>

<decisions>
## Implementation Decisions

### CHANGELOG [0.1.0] narrative (HEX-02 prep)
- **D-01:** Add `CHANGELOG.md` with Keep a Changelog boilerplate plus **Planning milestones vs Hex releases** preamble (szTheory/bootstrap template): `[0.x.y]` = published Hex releases; `v2.x` in `.planning/MILESTONES.md` = internal planning tranches, not a second install axis; **no** Hex `2.7.0` to match GSD milestone.
- **D-02:** Hand-author **`## [0.1.0]`** once (not release-please commit dump): 2–4 sentence integrator lead (first public Hex packaging of in-repo capability through v2.6 closeout).
- **D-03:** **`### Added`** uses **five capability bullets** aligned with Phase 70 README / `Scoria.AdopterDocContract` nouns: default runtime, bounded handoff, semantic fast path, optional knowledge, upgrade-safe install — each with proof command or public API; **no** milestone theme names (Relay, Crucible, etc.) in this section.
- **D-04:** Add one **maintainer CI trust** bullet under `### Added` (warning baseline/ratchet, policy→test topology, `mix scoria.test.ci_trust`) — not framed as adopter feature.
- **D-05:** Add **`### Roadmap traceability`** (maintainer-only within the release section): table or bullets for **v2.1, v2.3, v2.4, v2.5, v2.6** with ship dates and links to `.planning/MILESTONES.md` anchors; **do not invent v2.2** (no tranche in MILESTONES.md).
- **D-06:** **No** `### Summary` subsections under version headings (sigra convention breaks publish if wired; bootstrap gotcha #6).
- **D-07:** Keep `## [Unreleased]` for release-please after bootstrap; preamble is release SSOT for semver vs planning (Phase 70 D-08 — not duplicated in README).

### Publish workflow CI topology (HEX-01 prep)
- **D-08:** Extract PR CI jobs into **`.github/workflows/ci-verify.yml`** with `on: workflow_call` — contains today’s **policy** job (baseline expiry, compile WAE, lane-contract WAE) and **test** job (Postgres pgvector:55432, `MIX_ENV=dev mix scoria.release_preview`, ecto, closeout lanes, tmp_preflight, full WAE, knowledge).
- **D-09:** Slim **`.github/workflows/ci.yml`** to triggers + `jobs.verify: uses: ./.github/workflows/ci-verify.yml`.
- **D-10:** **`.github/workflows/release-please.yml`** — oarlock base (no `sync_release_summary`); `release-please` job; conditional **`verify`** calling `ci-verify.yml` when `release_created`; Phase 72 **`publish-hex`** `needs: verify` then hex steps (Phase 71 may land workflow with publish job disabled/stubbed or dry-run only until Phase 72).
- **D-11:** **`.github/workflows/hex-publish.yml`** — `workflow_dispatch` with `tag` + `release_version` inputs; **`verify`** via `ci-verify.yml` at tag, then publish steps (same as auto path).
- **D-12:** Extend **`ci.yml` triggers**: `push` to `release-please--**` branches + `workflow_dispatch` (lattice_stripe pattern) so Release PRs get CI without relying on `GITHUB_TOKEN` alone.
- **D-13:** Extend **`test/scoria/ci_policy_contract_test.exs`** to assert lane-command order in **`ci-verify.yml`** (or that `ci.yml` / release workflows `uses:` it and reusable file contains ordered commands).
- **D-14:** **Reject** publish-only `mix test` bar (oarlock minimal) and **reject** gate-only-on-green-CI without re-running verify on tag (lattice_stripe under-ships HEX-01 for Scoria).

### release-please bootstrap
- **D-15:** **`.release-please-manifest.json`**: `{ ".": "0.0.0" }` (not `0.1.0` pre-publish — gotcha #4).
- **D-16:** **`release-please-config.json`**: `release-type: elixir`, `bootstrap-sha` = full SHA of last commit before release-infra lands, `bump-minor-pre-major: false`, `bump-patch-for-minor-pre-major: true`, package `"."` with `changelog-path`, `include-v-in-tag: true`, **`release-as: "0.1.0"`** (one-time pin; remove in Phase 72 after successful publish).
- **D-17:** Before first release-please run: set GitHub **workflow permissions** — `default_workflow_permissions=write`, `can_approve_pull_request_reviews=true` (gotcha #3).
- **D-18:** Document optional **`RELEASE_PLEASE_TOKEN`** in maintainer section if `GITHUB_TOKEN` cannot open Release PRs or chain-trigger CI.
- **D-19:** Phase 71 verification: after merge to `main`, confirm Release PR targets **`0.1.0`** (not `0.1.1`, `0.2.0`, `1.0.0`); **do not merge** Release PR in Phase 71.
- **D-20:** **`.tool-versions`**: OTP **27** and Elixir **1.19** aligned with `.github/workflows/ci.yml` (not sigra’s OTP 28 pin).
- **D-21:** Confirm **`package/0`** includes `name: "scoria"` and `CHANGELOG.md` in files list; record Hex name availability (`https://hex.pm/api/packages/scoria` → 404) in `71-VERIFICATION.md`.

### Gate-zero remote CI attestation (69-02-04 carryover)
- **D-22:** **Do not** block Phase 71 on `origin/main` already green while local `main` is 212 commits ahead.
- **D-23:** **Preferred:** open integration PR with current tree → record green **`ci.yml`** workflow run URL, SHA, `policy` + `test` job success in **`71-VERIFICATION.md`** — attestation scoped to **v2.6 / existing ci.yml** before first `release-please.yml` commit if feasible.
- **D-24:** **Waiver path** (only if push/CI blocked): explicit gate-zero waiver in `71-VERIFICATION.md` with `waiver_id`, local evidence (`mix scoria.test.ci_trust`, v2.6 audit reference), `deferred_to: Phase 72 publish commit` — not open-ended.
- **D-25:** Phase 72 remains **non-waivable** full remote CI on publish commit.

### Maintainer runbook & recovery
- **D-26:** **SSOT:** new section **`## Hex release & recovery (maintainers)`** in `docs/operator_verification.md` immediately **after** CI gate map — not README, not separate `RELEASE.md` in Phase 71.
- **D-27:** Document **`HEX_API_KEY`**: `mix hex.user key generate` (api scope) → `gh secret set HEX_API_KEY --repo szTheory/scoria`; repo-level secret default; note Hex org keys if package gains `organization:` later.
- **D-28:** Document **default path**: Release Please → review Release PR (CI green on release branch) → merge → `publish-hex` (Phase 72).
- **D-29:** Document **manual recovery**: `hex-publish.yml` `workflow_dispatch` when publish job failed/skipped and version **not** on Hex; inputs `tag` + `release_version`; **do not** re-publish version already on hex.pm; post-recovery sync `.release-please-manifest.json` if needed.
- **D-30:** **README:** one-line maintainer tease + anchor link to operator section only.
- **D-31:** **Workflow YAML headers:** 3–5 lines pointing to operator guide anchor + `HEX_API_KEY` requirement.

### Claude's Discretion
- Exact CHANGELOG prose polish (capability nouns and traceability rows locked).
- Whether Phase 71 lands `publish-hex` as dry-run-only vs commented stub vs full job with Phase 72 feature flag — must not publish to Hex in Phase 71.
- Optional contract test asserting CHANGELOG preamble + capability nouns + no milestone-banner refutes.
- `bootstrap-release-pr-ci` optional job (lattice_stripe) if Release PR CI remains flaky with `GITHUB_TOKEN`.
- Backfill `69-VERIFICATION.md` human section vs adjust `ci_policy_contract_test` ledger path if 69 phase dir missing.

### Folded Todos
- None (`todo.match-phase` returned empty).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 71 goal, success criteria, non-goals
- `.planning/REQUIREMENTS.md` — HEX-01, HEX-02 (prep portions)
- `.planning/PROJECT.md` — v2.7 milestone, szTheory release pattern, preserve CI/lane contracts
- `.planning/STATE.md` — gate-zero carryover, deferred SEM-CI-01

### Prior phase context
- `.planning/phases/70-docs-truth-foundation/70-CONTEXT.md` — capability banner, version namespaces in operator guide only, CHANGELOG deferred to Phase 71
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md` — passed; remote CI attestation pending
- `.planning/MILESTONES.md` — traceability targets for Roadmap traceability subsection

### Product vision and DX
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI/CD, composable libraries
- `prompts/phoenix-ai-lib-deep-research.md` — executable proof, CI gates, adoption closeout
- `prompts/scoria-brand-book-deep-research.md` — direct README tone; capability vocabulary

### Executable SSOT (code)
- `.github/workflows/ci.yml` — current two-job topology (to refactor into ci-verify)
- `lib/scoria/verification_lanes.ex` — closeout order, lane commands
- `test/scoria/ci_policy_contract_test.exs` — CI string/order contracts
- `test/scoria/package_surface_test.exs` — pre-publish GitHub install guard (unchanged Phase 71)
- `mix.exs` — version `0.1.0`, package metadata

### szTheory release templates (read-only reference)
- `~/projects/oarlock/.github/workflows/release-please.yml` — elixir release-please + publish (adapt CI bar)
- `~/projects/oarlock/.github/workflows/hex-publish.yml` — manual recovery shape
- `~/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — gotchas manifest, release-as, permissions, no sync_release_summary

### Docs under change
- `CHANGELOG.md` — new
- `docs/operator_verification.md` — Hex release & recovery maintainer section
- `README.md` — one-line maintainer tease only

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml` — policy + test jobs to extract verbatim into `ci-verify.yml`
- `Scoria.VerificationLanes` + `ci_policy_contract_test` — enforce publish/CI parity
- `mix scoria.release_preview` — maintainer pre-publish proof (stays in verify workflow)
- `mix.exs` — already `0.1.0`, Hex metadata, `source_ref: "v#{version}"`

### Established Patterns
- Phase 70 doc SSOT: README teases; `operator_verification.md` for maintainer depth
- szTheory siblings: release-please + hex-publish recovery; manifest `0.0.0` + `release-as` for first ship
- Scoria outlier vs oarlock: full two-job CI with Postgres and lane closeout — publish must match

### Integration Points
- `release-please-config.json` / manifest at repo root
- GitHub repo settings API for workflow permissions
- `HEX_API_KEY` repository secret (Phase 72 activation)
- `71-VERIFICATION.md` — gate-zero attestation or waiver artifact

</code_context>

<specifics>
## Specific Ideas

- **Ecosystem alignment:** Oban/Phoenix release notes use themes, not planning codenames; Scoria CHANGELOG `Added` = capabilities, traceability = maintainer table.
- **First release discipline:** Hand-write `0.1.0`; automate from `0.1.1+` via release-please conventional commits.
- **Integration PR before release workflows:** record v2.6 remote green on representative SHA without blocking CHANGELOG/workflow authoring.
- **Phase 72 coordination:** merge Release PR, publish, remove `release-as`, flip README + `package_surface_test`, Hex badge.

</specifics>

<deferred>
## Deferred Ideas

- **README Hex badge + `{:scoria, "~> 0.1"}` primary install** — Phase 72 (HEX-02)
- **`package_surface_test` Hex-first flip** — Phase 72
- **`mix hex.publish` to registry** — Phase 72
- **Remove `release-as: "0.1.0"` pin** — Phase 72 after successful publish
- **Optional `MAINTAINING.md` extract** — only if operator Hex section exceeds ~120 lines

### Reviewed Todos (not folded)
- None surfaced by `todo.match-phase`.

</deferred>

---

*Phase: 71-release-infrastructure*
*Context gathered: 2026-05-28*
