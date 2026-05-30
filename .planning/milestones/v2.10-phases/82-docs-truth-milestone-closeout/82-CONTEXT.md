# Phase 82: Docs truth + milestone closeout - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **DOCS-HEX-01** and **v2.10 milestone closeout**: align adopter docs with `Scoria.HexConsumerContract` / `Scoria.VerificationLanes`; add executable drift guards in `adoption_surface_test` and `ci_policy_contract_test` for v2.10 tarball-vs-registry anchors; reconcile planning ledgers; run milestone audit; archive v2.10 to `.planning/milestones/`.

**In scope:** README Verification + `docs/adoption_lanes.md` adopter prose; `docs/operator_verification.md` maintainer narrative completion; `HexConsumerContract.adopter_doc_surfaces/0`; `AdopterDocContract` refute extensions; drift pins; `82-VERIFICATION.md`; `v2.10-MILESTONE-AUDIT.md`; `/gsd-complete-milestone` archive (ROADMAP, REQUIREMENTS, phase dirs → `v2.10-phases/`); PROJECT/STATE/MILESTONES evolution for v2.11 queue.

**Out of scope:** New runtime capabilities; widening `VerificationLanes.closeout_order/0`; live Hex in PR CI; cross-minor registry upgrade (`0.1` → `0.2`); retroactive Nyquist validation for phases 78–81; advisory `mix scoria.test.hex_consumer` lane; full handoff overlay on registry path; fixing latent registry semver upgrade until `0.1.1+` publishes (document only).
</domain>

<decisions>
## Implementation Decisions

### Doc surface allocation (adopter vs maintainer)
- **D-90:** **Three-tier audience model** — README + `adoption_lanes.md` = adopters; `operator_verification.md` = maintainers; HexDocs moduledocs = API truth with links to operator guide for CI. Matches Oban/Req/Ecto pattern (short README, deep maintainer tail) and szTheory DNA operator-first DX without polluting adopter install path.
- **D-91:** **README stays adopter-scoped** — keep/ tighten Verification section: `mix test.adoption`, one sentence that CI proves `mix hex.build --unpack` tarball (`{:scoria, path: unpack_root}`) not monorepo `path:`, name `Scoria.HexConsumerContract`, link to operator guide. **Do not** add PR-vs-release table, `mix scoria.post_publish_smoke`, or workflow filenames to README body.
- **D-92:** **`adoption_lanes.md` gets minimal hex-consumer note** — under default runtime lane proof block: adoption closeout exercises packaged tarball artifact (not repo `path:`); link to operator guide for maintainer CI topology. No env vars (`SCORIA_HEX_UNPACK_ROOT`, `SCORIA_PRESERVE_HOST`) in adoption_lanes.
- **D-93:** **`operator_verification.md` is canonical maintainer SSOT** for three-layer trust narrative: (1) PR tarball full overlay + content-revision upgrade, (2) release registry subset + conditional semver upgrade, (3) upgrade sequence distinction (same-semver content-revision vs registry patch bump). Expand existing gate map stub (81 D-89) into full prose — do not duplicate entire paragraphs into README.
- **D-94:** **Version namespace disclaimer** stays operator gate map only (~existing L328 pattern): Hex/git semver vs planning `v2.x` milestones. Guard via `ci_policy_contract_test`; refute planning-milestone install language in README via existing `AdopterDocContract.milestone_banner_refutes/0`.

### Drift guard home (SSOT + test responsibilities)
- **D-95:** **Keep module separation** — `HexConsumerContract` (dep shapes, fingerprints, tarball/registry mechanics); `AdopterDocContract` (capability nouns, install markers, README refutes); `VerificationLanes` (lane commands, closeout order). **Reject** merging HexConsumer into AdopterDoc (78 D-05 continuity).
- **D-96:** **Add `HexConsumerContract.adopter_doc_surfaces/0`** — mirror `SupportJourney.adopter_doc_surfaces/0` pattern: map doc path → scoped fragment list per surface (not one global blob). Fragments are stable substrings derived from contract helpers where possible (`hex_dep_snippet/0`, `tarball_dep_snippet/1` vocabulary, `VerificationLanes.command(:adoption)`).
- **D-97:** **`adoption_surface_test` owns adopter cross-doc coherence** — macro or focused tests iterate `HexConsumerContract.adopter_doc_surfaces/0` for README + adoption_lanes; keep existing `AdopterDocContract` loops and lane hierarchy tests unchanged in spirit.
- **D-98:** **`ci_policy_contract_test` owns maintainer executable topology** — gate map PR/release row substrings, `mix scoria.post_publish_smoke`, `post-publish-smoke.yml`, `post-publish-attest` job names (extend 81 minimal stub to full v2.10 pins). Workflow YAML truth lives here, not in `HexConsumerContract`.
- **D-99:** **`hex_consumer_contract_test.exs` stays unit/API scope** — README active dep line (done), registry semver helpers (done). No operator paragraph pins in this file.
- **D-100:** **Extend `AdopterDocContract.readme_maintainer_command_refutes/0`** with `"mix scoria.post_publish_smoke"` — post-publish smoke is maintainer-only; must never appear in README body copy.

### `adoption_surface_test` pin scope (minimal high-signal set)
- **D-101:** **Pin five adopter anchors** tied to ROADMAP success criteria — not full operator paragraphs:
  1. README active dep = `HexConsumerContract.hex_dep_snippet/0` (already in `hex_consumer_contract_test`; optionally cross-assert in adoption suite or rely on contract test only — prefer single home in `hex_consumer_contract_test`).
  2. README Verification tarball vocabulary: `mix hex.build --unpack`, `HexConsumerContract`, not monorepo `path:`.
  3. `adoption_lanes.md`: `VerificationLanes.command(:adoption)` + tarball/packaged-artifact vocabulary + link to operator guide.
  4. README links to `docs/operator_verification.md` from Verification section (existing pattern — assert preserved).
  5. `AdopterDocContract` refute loop covers new post-publish command + existing maintainer commands.
- **D-102:** **Reject** pinning full PR-vs-release table rows in `adoption_surface_test` — that is maintainer surface; `ci_policy_contract_test` owns it.
- **D-103:** **Reject** pinning `mix scoria.post_publish_smoke` in adopter docs tests as positive assertion — refute-only in README via D-100.

### `ci_policy_contract_test` pin scope (maintainer topology)
- **D-104:** **Pin six maintainer anchors** (extend 81 stub):
  1. `release-please.yml`: `post-publish-attest` needs `publish-hex` (partial — keep).
  2. `post-publish-smoke.yml` referenced from release + hex-publish workflows (partial — keep).
  3. Operator gate map subsection **"PR vs release proof depth"** contains PR row: `mix test.adoption` + tarball full overlay + content-revision upgrade.
  4. Same subsection Release row: `mix scoria.post_publish_smoke` + `post-publish-smoke.yml` + exact-pinned registry dep language.
  5. Upgrade sequence clarity: content-revision (tarball fixture → HEAD) vs registry semver bump — two stable substrings under gate map (not full paragraphs).
  6. Version namespace bullet in gate map (Hex semver vs planning `v2.x`).
- **D-105:** **Use `section_after/2` helper pattern** (existing in `ci_policy_contract_test`) for gate map extraction — avoids brittle full-file pins when unrelated operator sections change.
- **D-106:** **Do not pin** full overlay step lists or Runner internals in doc contract tests — executable proof modules own step contracts (79 D-32).

### Milestone closeout ceremony
- **D-107:** **Three-plan wave structure:**
  - **82-01:** DOCS-HEX-01 prose sweep + `adopter_doc_surfaces/0` + drift pins + fix REQUIREMENTS.md honesty (DOCS-HEX-01 must not read Complete until pins land).
  - **82-02:** `82-VERIFICATION.md` + `/gsd-audit-milestone v2.10` → `v2.10-MILESTONE-AUDIT.md` with `status: passed`.
  - **82-03:** `/gsd-complete-milestone v2.10`: archive ROADMAP/REQUIREMENTS/audit; update PROJECT/STATE/MILESTONES; collapse active ROADMAP to completed list + v2.11 queue; seed v2.11 REQUIREMENTS via `/gsd-new-milestone`.
- **D-108:** **Move phases 78–82 → `.planning/milestones/v2.10-phases/`** — v2.5 gold standard (preserve VERIFICATION/PATTERNS/CONTEXT). **Reject** v2.9-style silent deletion without archive dir.
- **D-109:** **Nyquist: document, do not retroactively validate** — phases 78–81 lack Nyquist sign-off; record `nyquist.overall: missing` in milestone audit tech debt (v2.9 precedent). Non-blocking for archive.
- **D-110:** **Milestone audit scope** — 4/4 requirements (HEX-CONSUMER-01, HEX-UPGRADE-01, HEX-REGISTRY-01, DOCS-HEX-01); 5/5 phases; integration flow 78→79→80→81→82 docs guards; carry latent tech debt (registry semver upgrade until `0.1.1+`, migration-delta assertion, 81-REVIEW follow-ups) as audit notes not blockers.
- **D-111:** **Do not run `complete-milestone` before audit passes** — preflight expects `v2.10-MILESTONE-AUDIT.md` with `status: passed`.
- **D-112:** **Mark DOCS-HEX-01 milestone Complete only in 82-02/82-03** after drift pins green — fixes current ledger inconsistency (REQUIREMENTS.md prematurely `[x]`).

### Ecosystem alignment (research-backed cohesive stance)
- **D-113:** **Layered trust matches npm/cargo/rubygems norm** — PR CI = `npm pack` / `cargo package` artifact proof; release = registry install smoke. Scoria appropriately exceeds typical Hex libs (Oban/Broadway stop at maintainer CI docs) because installer contract is the product — but adopter README must not read like a release runbook.
- **D-114:** **Executable proof over prose** (scoria-gsd-kickoff, phoenix-ai-lib §17) — drift guards tie docs to `HexConsumerContract` and workflows; prose edits without pins do not satisfy Phase 82.
- **D-115:** **Principle of least surprise** — adopters see one verification path (`mix test.adoption`); maintainers see three-layer map in operator guide only; lane commands always from `VerificationLanes.command/1`.
- **D-116:** **Field Engineer brand** (brand book) — docs are evidence-based, composed, no milestone banner noise in README; capability nouns unchanged.

### Claude's Discretion
- Exact `adopter_doc_surfaces/0` fragment strings (prefer contract-derived over hardcoded prose).
- Whether adoption_lanes tarball note is one sentence vs bullet under proof block.
- Single consolidated test vs split tests for new drift pins.
- Milestone audit integration/flow score thresholds (follow v2.9 template).
- Whether to add `HexConsumerContract` `@doc` link to operator guide section anchor.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` — Phase 82 success criteria (4 items)
- `.planning/REQUIREMENTS.md` — DOCS-HEX-01 definition; fix premature Complete status in 82-01
- `.planning/PROJECT.md` — v2.10 milestone intent, archive evolution rules
- `.planning/STATE.md` — deferred Phase 82 queue, D-45/D-46/D-89 continuity

### Prior phase context (locked)
- `.planning/phases/78-hex-consumer-contract-foundation/78-CONTEXT.md` — D-05 module split, D-21–D-23 DOCS-HEX-01 deferral
- `.planning/phases/79-tarball-consumer-overlay-proof/79-CONTEXT.md` — D-46/D-47 minimal prose, no adoption_surface pins in 79
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-CONTEXT.md` — content-revision upgrade narrative
- `.planning/phases/81-post-publish-registry-gate/81-CONTEXT.md` — D-89 gate map stub, D-23 drift pin deferral

### SSOT modules & drift guards
- `lib/scoria/hex_consumer_contract.ex` — extend with `adopter_doc_surfaces/0`
- `lib/scoria/adopter_doc_contract.ex` — extend refutes
- `lib/scoria/verification_lanes.ex` — lane command SSOT
- `lib/scoria/support_journey.ex` — `adopter_doc_surfaces/0` pattern reference
- `test/scoria/hex_consumer_contract_test.exs` — dep snippet guard (done)
- `test/scoria/adoption_surface_test.exs` — adopter cross-doc guards (extend)
- `test/scoria/ci_policy_contract_test.exs` — maintainer topology guards (extend)
- `test/scoria/support_journey_source_test.exs` — macro test pattern reference

### Adopter & maintainer docs
- `README.md` — Verification section (~L191–203)
- `docs/adoption_lanes.md` — default runtime lane proof block
- `docs/operator_verification.md` — CI gate map, PR vs release table (~L287–328), Hex release section

### Workflows
- `.github/workflows/ci-verify.yml` — PR tarball adoption closeout
- `.github/workflows/post-publish-smoke.yml` — registry attest SSOT
- `.github/workflows/release-please.yml` — post-publish-attest chain
- `.github/workflows/hex-publish.yml` — recovery attest parity

### Milestone closeout templates
- `.planning/milestones/v2.9-MILESTONE-AUDIT.md` — audit structure, Nyquist deferral pattern
- `.planning/milestones/v2.9-ROADMAP.md` — archived roadmap shape
- `.planning/milestones/v2.5-phases/` — phase dir archive precedent (if present)

### Project vision & engineering DNA
- `prompts/sztheory-elixir-dna.md` — operator-first DX, batteries-included composable libs
- `prompts/phoenix-ai-lib-deep-research.md` §17 — OSS trust: ExUnit, CI gates, semver, release automation, demo app
- `prompts/scoria-gsd-kickoff.md` — trace-first, executable proof over prose
- `prompts/scoria-brand-book-deep-research.md` — Field Engineer voice, HexDocs precise/example-heavy

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HexConsumerContract.hex_dep_snippet/0`, `tarball_dep_snippet/1`, `registry_dep_snippet_pinned/1` — fragment sources for drift guards
- `SupportJourney.adopter_doc_surfaces/0` + `SupportJourneySourceTest` macro pattern — copy for hex consumer doc surfaces
- `ci_policy_contract_test` `section_after/2`, `index_of/2` — gate map subsection extraction
- `AdopterDocContract` shipped/refute lists — README policy loops already wired
- Phase 79–81 operator prose — expand, don't rewrite from scratch

### Established Patterns
- **Contract module trilogy:** VerificationLanes + HexConsumerContract + AdopterDocContract
- **Test split:** adoption_surface = adopter docs; ci_policy_contract = YAML + operator maintainer topology; hex_consumer_contract = API units
- **Deferred pin discipline:** functional proof phases ship minimal prose; closeout phase adds executable guards (v2.9 DOCS-GALL-01 / 77.1 precedent)
- **Three-layer v2.10 trust:** PR tarball → PR content-revision upgrade → release registry

### Integration Points
- `82-01` edits: `hex_consumer_contract.ex`, `adopter_doc_contract.ex`, README, adoption_lanes, operator_verification (prose polish only if gaps), adoption_surface_test, ci_policy_contract_test
- `82-02` creates: `82-VERIFICATION.md`, `.planning/milestones/v2.10-MILESTONE-AUDIT.md`
- `82-03` moves: `.planning/phases/78-*` through `82-*` → `milestones/v2.10-phases/`; archives ROADMAP/REQUIREMENTS; resets planning for v2.11

</code_context>

<specifics>
## Specific Ideas

Research-backed cohesive stance (user requested one-shot recommendations across all gray areas):

- **Oban/Req/Ecto lesson (do right):** README = install + one verify path; maintainer CI in contributing/operator tail. Scoria already has operator_verification.md — Phase 82 completes it, not README.
- **Oban lesson (footgun):** README as release runbook confuses adopters — keep post-publish out of README refutes loop.
- **npm/cargo lesson (do right):** artifact proof (pack/package) in CI separate from registry publish smoke — Scoria's tarball vs registry split is idiomatic and should be documented maintainer-side only.
- **Typical Hex lib footgun:** docs drift from CI because no test pins — Scoria's contract modules are ahead of ecosystem norm; Phase 82 closes the deferred pin gap without new patterns.
- **SupportJourney lesson (do right):** per-surface fragment maps prevent pinning gallery copy in README — apply same to hex consumer surfaces.
- **v2.9 closeout lesson (do right):** docs gap phase (77.1) before audit; **footgun:** marking requirements Complete before drift pins exist — fix DOCS-HEX-01 ledger in 82-01.
- **v2.5 archive lesson (do right):** move phase dirs to milestone archive — preserve forensics for 78–81 dense artifacts.
- **szTheory DNA:** zero-config adopter path (`mix scoria.install` → `mix test.adoption`); operator depth in dashboard + operator guide, not README walls.
- **phoenix-ai-lib §17:** trusted OSS = ExUnit + CI gates + semver + release automation — doc guards are part of CI gate story, not optional polish.

</specifics>

<deferred>
## Deferred Ideas

- Cross-minor registry upgrade narrative (`0.1` → `0.2`) — future semver policy phase
- Retroactive Nyquist validation for phases 78–81 — optional `/gsd-validate-phase`, non-blocking
- Advisory `mix scoria.test.hex_consumer` lane — rejected in REQUIREMENTS.md
- Live Hex fetch in PR CI — rejected (78 D-09)
- Full handoff overlay on registry attest path — tarball adoption owns HOST-02
- `81-REVIEW.md` dry-run attest guard + extended hex-publish job pins — tech debt, not Phase 82 gate unless trivial
- Registry semver upgrade leg proof — latent until `0.1.1+` publishes (document in audit)
- `SCORIA_ARTIFACT_PATH` general maintainer override — optional future DX

</deferred>

---

*Phase: 82-Docs truth + milestone closeout*
*Context gathered: 2026-05-29*
