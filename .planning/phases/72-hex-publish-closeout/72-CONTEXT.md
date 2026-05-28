# Phase 72: Hex Publish Closeout - Context

**Gathered:** 2026-05-28 (updated 2026-05-28 — research-backed discretion resolved)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **first public Hex release** `0.1.0` at git tag `v0.1.0` with coordinated adopter-facing flip and v2.7 milestone closeout — **without** weakening v2.4 lane contracts, v2.5 installer truth, v2.6 CI gates, or Phase 70 capability-based docs.

**In scope:** Enable `publish-hex` + recovery publish jobs, satisfy non-waivable remote CI on publish commit, execute publish (Release Please default path), flip README + `package_surface_test` + Hex badge, remove one-time `release-as` pin, sync manifest, v2.7 audit + REQUIREMENTS closeout.

**Non-goals:** SEM-CI-01 in PR CI, knowledge WAE in default closeout, new runtime features, semver `2.7.0` to match GSD milestone, `sync_release_summary` (sigra footgun), local-only production publish, merging Release PR before publish is ready, GitHub Environment approval on first ship.

**Phase 71 handoff:** Workflows exist with `publish-hex` / `hex-publish` publish jobs **`if: false`**; operator runbook in `docs/operator_verification.md#hex-release--recovery-maintainers`; gate-zero waiver `gate-zero-71` approved with **remote CI deferred to this phase publish commit** (non-waivable).

</domain>

<decisions>
## Implementation Decisions

### Publish path (HEX-01 closeout)
- **D-72-01:** **Primary path:** Release Please on `main` → human-reviewed Release PR targeting **`0.1.0` only** → merge → tag `v0.1.0` + GitHub Release → `publish-hex` with `needs: [release-please, verify]` → full **`ci-verify.yml`** → `mix hex.publish --dry-run --yes` → `mix hex.publish --yes` with `HEX_API_KEY`.
- **D-72-02:** **Secondary path (recovery only):** `hex-publish.yml` `workflow_dispatch` with `tag` + `release_version` and `--ref` matching tag — **only** when git tag exists and `https://hex.pm/api/packages/scoria/releases/{version}` is **404**. Never re-publish a version already on Hex; sync `.release-please-manifest.json` to `"0.1.0"` after recovery if manifest drifted.
- **D-72-03:** **Reject** tag-only publish without Release Please review, publish job that only runs `mix test` (oarlock-minimal bar), and production `mix hex.publish` from a maintainer laptop for `0.1.0`.
- **D-72-04:** **Do not merge** the Release PR until `HEX_API_KEY` is set, workflow permissions (D-72-08) are applied, publish jobs enabled in **both** workflows (D-72-07), and `@version` fix (D-72-06) is landed.

### Pre-publish gates (HEX-01, gate-zero closeout)
- **D-72-05:** **Integration PR first:** Open PR with current tree (Phase 71+72 blockers) → record **green remote `ci-verify`** run URL + SHA + `policy` + `test` job success **before** treating publish as complete. Phase 71 gate-zero waiver does **not** waive this on the publish commit (71-CONTEXT D-25).
- **D-72-06:** **Blocking fix — `mix.exs` version shape:** Refactor to module attribute `@version "0.1.0"` and `version: @version` in `project/0`. Publish workflows grep `@version "${{ ... }}"` (oarlock pattern); inline `version = "0.1.0"` will fail verify step even when correct. **`docs/0`** MUST use `@version` for `source_ref: "v#{@version}"` (drop `docs(version)` parameter). Release Please `release-type: elixir` expects this shape.
- **D-72-07:** **Enable publish jobs in both workflows:** In `release-please.yml` (`publish-hex`): change `if: false` → `if: ${{ needs.release-please.outputs.release_created == 'true' }}`. In `hex-publish.yml` (`publish`): change `if: false` → success gate on `needs.verify` (e.g. `if: ${{ needs.verify.result == 'success' }}`). Uncomment dry-run + `mix hex.publish --yes` in **both**; keep `needs: verify`, tag checkout, and `@version` grep before publish.
- **D-72-08:** **Secrets & permissions (human, before first Release Please run):** `HEX_API_KEY` via `mix hex.user key generate` → `gh secret set`; workflow permissions via `gh api` (`default_workflow_permissions=write`, `can_approve_pull_request_reviews=true`). Optional `RELEASE_PLEASE_TOKEN` only if `GITHUB_TOKEN` cannot open Release PRs or chain-trigger CI on `release-please--**` branches.
- **D-72-09:** **Release PR review checklist:** Confirm Release PR targets **`0.1.0`** (not `0.1.1`, `0.2.0`, `1.0.0`); CI green on `release-please--**` branch; do not merge until D-72-04 satisfied.
- **D-72-10:** **Pre-merge maintainer smoke (local):** `mix hex.build`, `MIX_ENV=test mix test test/scoria/package_surface_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/changelog_contract_test.exs`, `mix scoria.test.ci_trust` — evidence for verification ledger, not a substitute for D-72-05.
- **D-72-24:** **Pre-publish manifest invariant:** `.release-please-manifest.json` MUST remain `{ ".": "0.0.0" }` until Hex API confirms `0.1.0` exists. Do not pre-set `0.1.0` on main to "prepare" (bootstrap gotcha #4).
- **D-72-25:** **Optional pre-publish name check:** Immediately before first live `mix hex.publish`, re-check `curl -fsS https://hex.pm/api/packages/scoria` → **404** (name still available). Low-cost guard against squatting between Phase 71 attestation and publish.

### Contract test co-flips (HEX-01)
- **D-72-22:** When enabling publish (D-72-07), **update `test/scoria/ci_policy_contract_test.exs` in the same change set**: flip assertions from Phase 71 `if: false` / stubbed publish to Phase 72 enabled publish + dry-run/publish steps present; refute `sync_release_summary`.
- **D-72-23:** After successful Hex publish and manifest sync (D-72-17), **update contract tests** that assert manifest `0.0.0` / `release-as` pin to post-ship expectations (`0.1.0`, no `release-as`) in the same commit series as D-72-18.

### Doc / install flip timing (HEX-02 closeout)
- **D-72-11:** **Flip README + contract tests only after Hex lists `0.1.0`:** Gate = `curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.0` succeeds **and** smoke `mix deps.get` in a clean project with `{:scoria, "~> 0.1", hex: :scoria}`.
- **D-72-12:** **Do not** flip README on Release PR merge alone — avoids window where `main` says Hex dep but registry returns 404 (top first-release support failure for integration libs).
- **D-72-13:** **Post-flip README install block — Hex-primary + install-in-minutes path:** One framing line → primary deps block → three-command next steps → installer summary → Verification link. Do **not** duplicate Quickstart API samples in Install (brand book: README fast-scan; HexDocs example-heavy).
- **D-72-14:** **Hex badge:** Add `[![Hex.pm](https://img.shields.io/hexpm/v/scoria.svg)](https://hex.pm/packages/scoria)` near existing CI badge (Ecto/Phoenix pattern); no full release runbook in README (operator guide SSOT per Phase 70/71).
- **D-72-15:** **`package_surface_test` flip:** Invert pre-publish assertions — require `~> 0.1` / `hex: :scoria` uncommented; refute stale "until the first Hex publish lands" github-only block; assert github tag string still present as **commented** fallback; refute two uncommented `{:scoria, …}` entries; rename test to `"Hex-primary install with optional GitHub fallback"`.
- **D-72-16:** **Version namespace discipline:** Install docs use Hex semver + git tag only; never `v2.x` planning milestone labels as deps (CHANGELOG preamble remains SSOT for planning vs Hex — Phase 70/71).

### Post-flip README structure (HEX-02 — research-locked)
- **D-72-26:** **Primary dep (uncommented):** `{:scoria, "~> 0.1", hex: :scoria}` — idiomatic first `0.x` public API; explicit `hex: :scoria` for name-collision defense (brand book collision screen).
- **D-72-27:** **GitHub fallback — inline comment, not subsection:** Same `def deps` block with one commented line: `# Fork or pinned patch only: {:scoria, github: "szTheory/scoria", tag: "v0.1.0"}`. One prose line after block: "Tagged GitHub installs are for forks and pinned patches; prefer Hex for normal adoption." **Reject** `### Bleeding edge` subsection (elevates git to co-primary; Scrypath/szTheory DNA is Hex-only in README).
- **D-72-28:** **Next steps (3 commands):** `mix deps.get` → `mix scoria.install` → `mix ecto.migrate` — then link to `## Verification` (`mix test.adoption`). Preserves szTheory `mix *.install` DNA vs Ecto-style deps-only minimalism.
- **D-72-29:** **Installer summary:** Keep one short bullet list (dashboard at `/scoria`, migrations, runtime defaults, Tailwind optional) — unchanged substance from pre-flip README.
- **D-72-30:** **Remove on flip:** Pre-publish disclaimer ("until the first Hex publish lands…"); `## Status` "Hex metadata is ready" paragraph → replace with one line: "Current release: `0.1.0` on [Hex](https://hex.pm/packages/scoria)."
- **D-72-31:** **Keep unchanged:** `## Quickstart` (runtime API), `### Upgrading or re-running install`, capability banner, lane guide, maintainer tease link to operator guide.

### Publish job hardening
- **D-72-32:** **No GitHub Environment approval for 0.1.0:** Treat Release PR merge + D-72-04 checklist + full `ci-verify` + dry-run as the human approval boundary (oarlock/sigra szTheory default). **Reject** Environment on default path only — recovery must use same gate if Environment is added later.
- **D-72-33:** **Post-0.1.0 optional hardening:** Document optional `hex-publish` Environment + required reviewers in operator guide subsection only — adopt only if team wants named approver after CI green; apply to **both** `publish-hex` and `hex-publish.yml` if enabled.

### Post-publish verification surface
- **D-72-20:** **Ship proof ledger (`72-VERIFICATION.md`):** Record dated evidence — hex.pm version check, publish workflow run URL + SHA, remote CI green on publish commit, hexdocs `0.1.0` / `source_ref` spot-check, smoke `deps.get`, optional `mix scoria.install --check`, 24h follow-up row. **URLs/SHAs never go in operator guide.**
- **D-72-34:** **Evergreen operator appendix (~15–25 lines):** Add `### Post-publish registry checks (maintainers)` under existing Hex section in `docs/operator_verification.md` — curl hex.pm, hexdocs `source_ref`, clean-project `deps.get` + compile, optional `--check`; pointer to flip README only after step 1 returns 200; "record dated evidence in phase verification ledger."
- **D-72-35:** **24h smoke split:** Repeatable commands in operator appendix; first-ship dated results in `72-VERIFICATION.md` only. Do not extract `MAINTAINING.md` until combined Hex + post-publish block exceeds ~120 lines.

### Post-publish cleanup (HEX-01, HEX-02, v2.7 closeout)
- **D-72-17:** **Verify manifest:** `.release-please-manifest.json` must read `{ ".": "0.1.0" }` after successful publish (Release Please usually sets on merge; **manually fix** if recovery path used).
- **D-72-18:** **Remove one-time pin:** Delete `"release-as": "0.1.0"` from `release-please-config.json` in dedicated commit `chore: remove release-as pin (0.1.0 shipped)` on `main` — **after** README flip (plan 72-03 task order), never before Hex lists `0.1.0`.
- **D-72-19:** **Do not** bump to `0.1.1` solely to retry failed publish within Hex republish window (~1 hour for public packages).
- **D-72-21:** **Milestone closeout:** Write `.planning/milestones/v2.7-MILESTONE-AUDIT.md`; mark HEX-01 and HEX-02 complete in `.planning/REQUIREMENTS.md` traceability; align `.planning/PROJECT.md` validated requirements.

### Plan wave split (locked for planner)
- **D-72-36:** **Four plans / four waves** (matches Phase 71 precedent; isolates D-72-11 at plan boundary):

| Plan | Name | Locked steps | `autonomous` |
|------|------|--------------|--------------|
| **72-01** | `integration-blockers` | 1–2: integration PR + green ci-verify attestation; `@version`; enable both publish jobs; D-72-22 contract flip; human secrets/permissions checklist | `false` |
| **72-02** | `release-publish-verify` | 3–5: Release PR `0.1.0` review → merge → tag; `publish-hex`; hex.pm + deps.get smoke; `72-VERIFICATION.md` publish evidence | `false` |
| **72-03** | `adopter-flip-cleanup` | 6–7: README + badge + D-72-15; D-72-34 operator appendix; D-72-18 `release-as` removal; D-72-23 manifest/pin contract flip | `true` (blocked until 72-02 must_haves) |
| **72-04** | `v27-milestone-closeout` | 8: v2.7 audit + REQUIREMENTS + PROJECT alignment | `true` |

- **D-72-37:** **72-03 hard gate:** First task acceptance MUST cite live Hex `0.1.0` (re-run or reference 72-02-SUMMARY). **`README.md` MUST NOT appear in 72-01 or 72-02 `files_modified`.**
- **D-72-38:** **72-03 task order:** Registry gate → README/test/badge flip → operator appendix → `release-as` removal → manifest confirm → D-72-23.

### Rejected patterns (locked — do not replan)
- **R-72-01:** Merge Release PR before publish jobs enabled → tag without tarball.
- **R-72-02:** README Hex-primary before registry lists `0.1.0`.
- **R-72-03:** `sync_release_summary` job or `needs:` dependency (sigra publish blocker).
- **R-72-04:** Manifest `"0.1.0"` before first successful Hex publish (next Release PR wrong bump).
- **R-72-05:** Weaker CI on publish than PR (`mix test` only).
- **R-72-06:** Hex semver `2.7.0` matching GSD milestone label.
- **R-72-07:** `### Bleeding edge` GitHub subsection as co-equal install path.
- **R-72-08:** GitHub Environment on `publish-hex` only without matching `hex-publish.yml` recovery.

### Claude's Discretion
- Exact wording polish within D-72-26–31 constraints (tone: brand book README = direct, fast scan).
- Whether optional D-72-25 name re-check is run (recommended but not blocking).
- Hex badge placement relative to CI/License badges (near CI per D-72-14).

### Folded Todos
- None (`todo.match-phase` returned empty).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 72 goal, success criteria, non-goals
- `.planning/REQUIREMENTS.md` — HEX-01, HEX-02 (closeout portions)
- `.planning/PROJECT.md` — v2.7 milestone, docs truth before publish, preserve CI/lane contracts
- `.planning/STATE.md` — current focus, gate-zero deferred to publish commit

### Prior phase context
- `.planning/phases/71-release-infrastructure/71-CONTEXT.md` — deferred items now in scope
- `.planning/phases/71-release-infrastructure/71-VERIFICATION.md` — Hex 404 attestation, bootstrap-sha, gate-zero waiver approved
- `.planning/phases/70-docs-truth-foundation/70-CONTEXT.md` — capability banner, pre-publish README contract
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md` — CI closeout baseline

### Product vision and DX
- `prompts/sztheory-elixir-dna.md` — operator-first DX, robust CI/CD, `mix *.install` onboarding
- `prompts/phoenix-ai-lib-deep-research.md` — §17 OSS/release (Release Please, trusted CI, HexDocs); §install-in-minutes
- `prompts/scoria-gsd-kickoff.md` — trace-first, batteries-included Phoenix integration
- `prompts/scoria-brand-book-deep-research.md` — README direct/fast-scan; HexDocs example-heavy; collision screen for `hex: :scoria`

### Executable SSOT (code)
- `.github/workflows/ci-verify.yml` — reusable policy + test bar (publish must use this)
- `.github/workflows/release-please.yml` — enable `publish-hex` (currently stubbed)
- `.github/workflows/hex-publish.yml` — manual recovery (publish job stubbed)
- `release-please-config.json` / `.release-please-manifest.json` — remove `release-as` post-ship
- `test/scoria/package_surface_test.exs` — flip pre-publish → Hex-first guards
- `test/scoria/ci_policy_contract_test.exs` — co-flip with workflow enablement (D-72-22/23)
- `lib/scoria/adopter_doc_contract.ex` — capability nouns unchanged in README flip
- `mix.exs` — `@version` refactor required (D-72-06)
- `CHANGELOG.md` — preamble + `[0.1.0]`; release-please owns `[Unreleased]` after bootstrap

### szTheory release templates (read-only reference)
- `~/projects/oarlock/.github/workflows/release-please.yml` — publish job shape, `@version` grep
- `~/projects/oarlock/.github/workflows/hex-publish.yml` — recovery shape
- `~/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — manifest, release-as, permissions gotchas

### Docs under change
- `README.md` — Hex-primary install + badge (timing per D-72-11; structure per D-72-26–31)
- `docs/operator_verification.md` — post-publish registry checks appendix (D-72-34)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 71 landed full release infra; only enablement + flip + audit remain.
- `ci-verify.yml` already mirrors PR topology (policy → test with Postgres, closeout lanes, full WAE).
- `package_surface_test.exs` explicitly guards pre-publish github install — must invert in 72-03 only.
- `mix scoria.release_preview` — stays in verify path on publish (docs lane before registry ship).
- Hex name **404** recorded in `71-VERIFICATION.md` (2026-05-28).

### Established Patterns
- szTheory: release-please + manifest `0.0.0` + one-time `release-as` + recovery workflow; oarlock/sigra secrets-only publish (no Environment on first ship).
- Mature Elixir integration libs post-Hex: Ecto/Oban/Req Hex-only README; git fallback relegated to comments or guides.
- Scoria outlier vs oarlock: publish must run **full ci-verify**, not `mix test` only.
- Scrypath (szTheory sibling): Hex-only in Installation — Scoria keeps commented github line for fork/patch only.

### Integration Points
- `HEX_API_KEY` repository secret — activate in Phase 72.
- GitHub workflow permissions API — human step before first Release Please.
- `72-VERIFICATION.md` — publish commit remote CI + hex.pm evidence (non-waivable).
- `ci_policy_contract_test.exs` currently **requires** `if: false` — must co-flip with D-72-07.

### Known blockers
- `mix.exs` uses `version = "0.1.0"` but workflows expect `@version` string — fix in 72-01 (D-72-06).

</code_context>

<execution_order>
## Locked execution order (planner must preserve)

```
1. Integration PR → remote ci-verify green (record URL/SHA)
2. Fix @version + enable publish jobs (both workflows) + HEX_API_KEY + permissions + D-72-22
3. Release PR review (0.1.0) → merge → tag
4. publish-hex: ci-verify → dry-run → publish
5. Verify hex.pm 0.1.0 + smoke deps.get → 72-VERIFICATION.md evidence
6. Flip README + package_surface_test + Hex badge + operator appendix (D-72-34)
7. Remove release-as; confirm manifest 0.1.0; D-72-23 contract flip
8. v2.7 milestone audit + REQUIREMENTS closeout
```

Steps 5–6 order is critical for adopter least surprise (D-72-11). Plans 72-02 → 72-03 enforce this boundary.

</execution_order>

<specifics>
## Research synthesis (2026-05-28 discuss update)

**Ecosystem lessons (what to copy):**
- Ecto/Oban/Req: Hex-only primary README after ship; depth in HexDocs/guides.
- szTheory oarlock/sigra: Release Please + secrets-only CI publish; Release PR merge = human gate.
- Phoenix AI lib research §17: trusted CI before publish; Release Please; install-in-minutes via `mix *.install`.
- Devise/Rails pattern: registry dep → one setup command → verify elsewhere.

**Footguns avoided:**
- README flip before registry (#1 integration-lib support failure — D-72-11).
- Two equal install paths (Bleeding edge subsection — R-72-07).
- Environment on publish only, not recovery (R-72-08).
- Contract tests still asserting `if: false` after enablement (D-72-22).
- `release-as` removal before Hex lists version (wrong next Release PR bump).
- Copy-paste both dep lines (duplicate `:scoria` key — inline comment only).

**Coherent package:** Hex-primary README with install-in-minutes path; commented github fallback; no Environment on 0.1.0; ledger + thin operator appendix for verification; 4-plan wave split isolating doc flip from publish.

</specifics>

<deferred>
## Deferred beyond Phase 72

- SEM-CI-01 semantic lane in PR CI (document local command only — Phase 70).
- Knowledge WAE in default CI closeout.
- GitHub Environment approval on publish (optional — document in operator guide per D-72-33; adopt post-0.1.0 if desired).
- `MAINTAINING.md` extract (only if operator Hex section exceeds ~120 lines).

</deferred>

---

*Phase: 72-hex-publish-closeout*
*Context gathered: 2026-05-28*
