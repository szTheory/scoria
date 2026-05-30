# Phase 82 Research: Docs Truth + Milestone Closeout

**Researched:** 2026-05-29  
**Phase:** 82 — Docs truth + milestone closeout  
**Requirement:** DOCS-HEX-01  
**Objective:** What a planner needs to know before authoring Phase 82 plans.

## Summary

Phase 82 closes the **deferred drift-guard gap** left by Phases 78–81: functional hex consumer proof shipped (tarball adoption, content-revision upgrade, registry attest), but **executable doc pins and ledger honesty remain incomplete**. [VERIFIED: codebase grep] `HexConsumerContract` has no `adopter_doc_surfaces/0`; `AdopterDocContract.readme_maintainer_command_refutes/0` omits `mix scoria.post_publish_smoke`; `adoption_surface_test.exs` has zero hex-consumer pins; `ci_policy_contract_test.exs` pins workflow YAML partially but not gate-map PR/release rows (D-104). [CITED: `.planning/REQUIREMENTS.md`] DOCS-HEX-01 is marked `[x]` Complete despite STATE.md listing Phase 82 drift pins as **queued** — ledger inconsistency D-112 must fix in 82-01.

Prose is **mostly aligned** already: README Verification (~L191–203) states tarball CI vocabulary; `operator_verification.md` has PR vs release table stub (81 D-89); maintainer tarball triage section exists (~L68–72). **Gaps:** `adoption_lanes.md` lacks minimal hex-consumer note (D-92); operator gate map needs upgrade-sequence clarity substrings (D-93/D-104 #5); drift guards are the primary deliverable, not greenfield prose.

Milestone closeout follows **v2.9 three-plan wave** (docs pins → audit → archive) with **v2.5 phase-dir preservation** (`v2.10-phases/`), Nyquist documented as missing for 78–81 (D-109, v2.9 precedent).

**Primary recommendation:** Three-plan wave 82-01/02/03 per D-107 — pins and ledger honesty first, audit second, `/gsd-complete-milestone` last only after `v2.10-MILESTONE-AUDIT.md` status passed.

---

<user_constraints>

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

## Deferred Ideas

- Cross-minor registry upgrade narrative (`0.1` → `0.2`) — future semver policy phase
- Retroactive Nyquist validation for phases 78–81 — optional `/gsd-validate-phase`, non-blocking
- Advisory `mix scoria.test.hex_consumer` lane — rejected in REQUIREMENTS.md
- Live Hex fetch in PR CI — rejected (78 D-09)
- Full handoff overlay on registry attest path — tarball adoption owns HOST-02
- `81-REVIEW.md` dry-run attest guard + extended hex-publish job pins — tech debt, not Phase 82 gate unless trivial
- Registry semver upgrade leg proof — latent until `0.1.1+` publishes (document in audit)
- `SCORIA_ARTIFACT_PATH` general maintainer override — optional future DX

</user_constraints>

---

<phase_requirements>

| ID | Definition | Phase 82 deliverable | Current status |
|----|------------|----------------------|----------------|
| **DOCS-HEX-01** | `Scoria.HexConsumerContract` SSOT pins Hex dep snippet and version; README, `docs/operator_verification.md`, and `docs/adoption_lanes.md` align; `adoption_surface_test` and `ci_policy_contract_test` drift-guard tarball consumer proof; `closeout_order/0` unchanged. | `adopter_doc_surfaces/0`; prose gaps in adoption_lanes + operator upgrade sequence; drift pins D-101/D-104; REQUIREMENTS honesty; milestone audit + archive | **Partial** — SSOT + unit test exist; drift guards + adoption_lanes note missing; REQUIREMENTS falsely Complete [CITED: `.planning/REQUIREMENTS.md` L17, L47] |

</phase_requirements>

---

## Current State vs ROADMAP Success Criteria

| ROADMAP # | Criterion | Current | Gap |
|-----------|-----------|---------|-----|
| 1 | README Verification states adoption proves Hex-shaped tarball artifact | README L201: `mix hex.build --unpack`, `{:scoria, path: unpack_root}`, `Scoria.HexConsumerContract` [CITED: `README.md`] | Executable pin via `adopter_doc_surfaces/0` + adoption macro test missing [VERIFIED: grep] |
| 2 | `operator_verification.md` documents tarball CI vs registry post-publish + upgrade sequence | Gate map table L319–328; tarball triage L68–72 [CITED: `docs/operator_verification.md`] | Upgrade sequence substrings (fixture→HEAD vs registry patch) not explicit enough for D-104 #5 [VERIFIED: grep — no "tarball fixture" or "HEAD" in gate map] |
| 3 | `adoption_surface_test` + `ci_policy_contract_test` guard new anchors | Tests pass (58/58) but no v2.10 hex pins [VERIFIED: shell] | Primary Phase 82 code work |
| 4 | Milestone audit passes; v2.10 archived | No `v2.10-MILESTONE-AUDIT.md`; phases 78–82 still active [VERIFIED: glob] | 82-02/82-03 ceremony |

---

## Architectural Responsibility Map

| Module / file | Owns | Phase 82 action |
|---------------|------|-----------------|
| `Scoria.HexConsumerContract` | Dep tuples/snippets, unpack cache, registry pin helpers | Add `adopter_doc_surfaces/0` (D-96) |
| `Scoria.AdopterDocContract` | Capability nouns, README refutes | Add `mix scoria.post_publish_smoke` to refutes (D-100) |
| `Scoria.VerificationLanes` | Lane commands, `closeout_order/0` | **Read-only** — unchanged per requirement |
| `Scoria.SupportJourney` | Gallery journey SSOT + surface map pattern | **Reference only** — copy pattern |
| `test/scoria/hex_consumer_contract_test.exs` | Unit/API guards | Keep README dep pin here (D-99) |
| `test/scoria/adoption_surface_test.exs` | Adopter cross-doc coherence | Macro over `HexConsumerContract.adopter_doc_surfaces/0` (D-97) |
| `test/scoria/ci_policy_contract_test.exs` | YAML + operator maintainer topology | Extend gate map pins via `section_after/2` (D-98, D-105) |
| `test/scoria/support_journey_source_test.exs` | Macro pattern reference | **Reference only** |
| `README.md` | Adopter install + Verification | Minor tighten only if gaps vs D-91 |
| `docs/adoption_lanes.md` | Lane selection guide | Add minimal tarball note (D-92) |
| `docs/operator_verification.md` | Maintainer CI SSOT | Expand gate map prose (D-93) |
| `.planning/REQUIREMENTS.md` | Requirement ledger | Uncheck DOCS-HEX-01 in 82-01; Complete in 82-02/03 (D-112) |

---

## Standard Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Test framework | ExUnit | Drift guards are async file-read asserts — same as v2.9 DOCS-GALL-01 |
| Doc contract SSOT | Public `lib/scoria/*.ex` modules | Shipped in Hex tarball; tests import constants |
| Surface map pattern | `adopter_doc_surfaces/0` → `%{"path" => [fragments]}` | Established by `SupportJourney` [CITED: `lib/scoria/support_journey.ex` L122–128] |
| Gate map extraction | `section_after/2` in test module | [CITED: `test/scoria/ci_policy_contract_test.exs` L356–367] |
| CI enforcement | Policy job lane-contract WAE step | Runs all three contract test files [CITED: `.github/workflows/ci-verify.yml` L53] |
| Milestone audit | YAML frontmatter + markdown body | Template: `.planning/milestones/v2.9-MILESTONE-AUDIT.md` |
| Phase archive | `.planning/milestones/v2.10-phases/` | Precedent: `.planning/milestones/v2.5-phases/` [VERIFIED: glob] |

---

## Architecture Patterns

### 1. Per-surface fragment maps (SupportJourney → HexConsumer)

`SupportJourney.adopter_doc_surfaces/0` returns a map of doc path → scoped fragment list; `SupportJourneySourceTest` generates one test per surface via compile-time `for` macro. [CITED: `test/scoria/support_journey_source_test.exs` L6–15]

**Phase 82 applies the same to hex consumer surfaces** scoped to README + `adoption_lanes.md` only (not operator gate map — maintainer pins live in `ci_policy_contract_test`).

### 2. Contract module trilogy (locked D-95)

| Module | Concern |
|--------|---------|
| `HexConsumerContract` | Mechanical dep shapes, fingerprints, tarball/registry vocabulary |
| `AdopterDocContract` | Adopter policy: capability nouns, maintainer command refutes |
| `VerificationLanes` | Executable lane command strings |

Do not merge HexConsumer into AdopterDoc — deferred explicitly since Phase 78 D-05. [CITED: `78-CONTEXT.md`]

### 3. Test split by audience

| Test file | Audience | Pins |
|-----------|----------|------|
| `adoption_surface_test.exs` | Adopter docs | Lane hierarchy, capability nouns, refutes, **new** hex consumer surfaces |
| `ci_policy_contract_test.exs` | Maintainer topology | YAML jobs, gate map subsections |
| `hex_consumer_contract_test.exs` | API units | Dep snippet byte match, registry helpers |

### 4. Deferred pin discipline (78 D-23 → 82 closeout)

Phases 79–81 shipped minimal operator prose + functional proof; Phase 82 adds executable guards — same pattern as v2.9 phase 77.1 for DOCS-GALL-01. [CITED: `78-CONTEXT.md` D-23; `v2.9-MILESTONE-AUDIT.md` DOCS-GALL-01 row]

### 5. Milestone closeout three-wave (D-107)

```
82-01  prose + adopter_doc_surfaces/0 + drift pins + REQUIREMENTS honesty
  ↓
82-02  82-VERIFICATION.md + v2.10-MILESTONE-AUDIT.md (status: passed)
  ↓
82-03  complete-milestone → archive ROADMAP/REQUIREMENTS/phases → v2.11 seed
```

Preflight: audit must pass before 82-03 (D-111). Nyquist missing for 78–81 documented, not blocking (D-109).

---

## Don't Hand-Roll

| Need | Use instead | Why |
|------|-------------|-----|
| Adopter lane command strings | `VerificationLanes.command(:adoption)` | SSOT — already used in adoption_surface_test L16 |
| Hex dep line for README | `HexConsumerContract.hex_dep_snippet/0` | Byte-match guard exists in hex_consumer_contract_test L10–22 |
| Tarball dep vocabulary | `mix hex.build --unpack`, `{:scoria, path: unpack_root}` | Matches README L201 and Runner MANIFEST output |
| Registry exact pin language | `{:scoria, "<version>", hex: :scoria}` or `registry_dep_snippet_pinned/1` | Attest-only; operator L326 already uses template form |
| Gate map subsection | `section_after(operator_docs, "### CI gate map (maintainers)")` | Existing helper — do not pin full operator file |
| Workflow job chain | Read `release-please.yml` L237–244 | `post-publish-attest` needs `[release-please, publish-hex]` [VERIFIED: read] |
| Milestone audit structure | Copy v2.9 frontmatter + sections | Scores, gaps, tech_debt, nyquist block |
| Phase dir archive | Move to `v2.10-phases/` preserving all artifacts | v2.5 precedent — reject silent deletion (D-108) |

---

## Common Pitfalls

1. **Marking DOCS-HEX-01 Complete before pins land** — REQUIREMENTS.md already has this bug; fix in 82-01, finalize in 82-02/03 (D-112). [CITED: `.planning/REQUIREMENTS.md` L17, L47]

2. **Pinning maintainer topology in adoption_surface_test** — PR vs release table belongs in `ci_policy_contract_test` only (D-102).

3. **Positive assert for `mix scoria.post_publish_smoke` in adopter tests** — refute-only in README via AdopterDocContract loop (D-103).

4. **Duplicating operator paragraphs into README** — D-91 forbids workflow filenames and post-publish command in README body.

5. **Env vars in adoption_lanes** — D-92 forbids `SCORIA_HEX_UNPACK_ROOT` / `SCORIA_PRESERVE_HOST` in lane guide (README L201 mentions SCORIA_HEX_UNPACK_ROOT in maintainer CI pointer — acceptable per D-91 "see … in maintainer CI").

6. **Merging HexConsumerContract into AdopterDocContract** — rejected D-95; breaks 78 module split.

7. **Running complete-milestone before audit** — D-111; v2.10-MILESTONE-AUDIT.md must exist with `status: passed`.

8. **Brittle full-file operator pins** — use `section_after/2` scoped to gate map and "PR vs release proof depth" subsection (D-105).

9. **Retroactive Nyquist as blocker** — document missing in audit; do not delay archive (D-109).

10. **Widening closeout_order/0** — out of scope; verify unchanged in audit integration check.

---

## Code Examples from Codebase

### SupportJourney surface map (pattern to copy)

```122:128:lib/scoria/support_journey.ex
  def adopter_doc_surfaces do
    %{
      "docs/support_copilot_gallery.md" => doc_fragments(),
      "README.md" => readme_doc_fragments(),
      "docs/operator_verification.md" => operator_doc_fragments()
    }
  end
```

### Macro drift test (pattern to copy)

```6:15:test/scoria/support_journey_source_test.exs
  for {path, fragments} <- SupportJourney.adopter_doc_surfaces() do
    test "adopter doc #{path} stays aligned with SupportJourney fixture SSOT" do
      content = File.read!(unquote(path))

      for fragment <- unquote(Macro.escape(fragments)) do
        assert content =~ fragment,
               "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
      end
    end
  end
```

### Gate map section extraction (maintainer pins)

```356:367:test/scoria/ci_policy_contract_test.exs
  defp section_after(content, heading) do
    case :binary.match(content, heading) do
      {start, _len} ->
        content
        |> String.slice(start, byte_size(content))
        |> String.split("\n### ", parts: 2)
        |> List.first()

      :nomatch ->
        flunk("expected #{inspect(heading)} in content")
    end
  end
```

### README dep guard (keep in hex_consumer_contract_test — D-99)

```10:22:test/scoria/hex_consumer_contract_test.exs
  test "README active dep line matches hex_dep_snippet/0" do
    readme = File.read!("README.md")
    ...
    assert String.trim(hd(active_dep_lines)) == HexConsumerContract.hex_dep_snippet()
  end
```

### AdopterDocContract refute loop (extend with post_publish_smoke)

```72:77:test/scoria/adoption_surface_test.exs
    for refute <-
          AdopterDocContract.milestone_banner_refutes() ++
            AdopterDocContract.readme_maintainer_command_refutes() do
      refute content =~ refute,
             "expected README not to contain #{inspect(refute)}"
    end
```

### Existing workflow partial pins (extend to gate map — D-104)

```49:58:test/scoria/ci_policy_contract_test.exs
  test "release-please.yml includes preflight and publish hardening" do
    ...
    assert release_please =~ "post-publish-attest"
    assert release_please =~ "post-publish-smoke.yml"
  end
```

### Operator gate map stub (expand + pin — D-93/D-104)

```319:328:docs/operator_verification.md
**PR vs release proof depth (v2.10 gate map):**

| Path | Proof depth | Command / workflow | Blocking? |
|------|-------------|-------------------|-----------|
| **PR CI** | Tarball consumer full overlay + content-revision upgrade | `mix test.adoption` via `.github/workflows/ci-verify.yml` | Yes — merge gate |
| **Release** | Live Hex registry subset + conditional semver upgrade | `mix scoria.post_publish_smoke` via `.github/workflows/post-publish-smoke.yml` after `publish-hex` in `release-please.yml` (or recovery `hex-publish.yml`) | Yes — release workflow fails if attest fails |

Registry attest proves install → migrate → route + runtime overlay smokes against exact-pinned `{:scoria, "<version>", hex: :scoria}` — not the shallow compile-only `deps.get` check. When `published_version > 0.1.0`, the attest also runs the registry semver upgrade leg (baseline exact previous → target just-published).

**Version namespaces:** Hex/git releases use semver (`0.1.0`, `v0.1.0`, `{:scoria, "~> 0.1"}`). Planning milestones (`v2.x` in `.planning/`) are internal shipped-work tranches, not a second installable version axis.
```

### Suggested `adopter_doc_surfaces/0` shape [ASSUMED — discretion D-96]

```elixir
def adopter_doc_surfaces do
  adoption_cmd = Scoria.VerificationLanes.command(:adoption)

  %{
    "README.md" => [
      "mix hex.build --unpack",
      "{:scoria, path: unpack_root}",
      "Scoria.HexConsumerContract",
      "docs/operator_verification.md",
      adoption_cmd
    ],
    "docs/adoption_lanes.md" => [
      adoption_cmd,
      "packaged tarball",  # or "mix hex.build --unpack" — planner discretion D-92
      "operator_verification.md"
    ]
  }
end
```

Fragments should prefer contract-derived strings where possible; exact wording is planner discretion per D-96/D-73.

---

## Docs vs Contract Gap Analysis

### README (`README.md` L191–203) [CITED]

**Aligned:** `mix test.adoption`; tarball sentence with `mix hex.build --unpack`; `Scoria.HexConsumerContract`; link to `docs/operator_verification.md`.  
**Drift guard gap:** No `adopter_doc_surfaces/0` iteration; refute list missing `mix scoria.post_publish_smoke` (not in README today — preemptive guard).  
**Note:** Mentions `SCORIA_HEX_UNPACK_ROOT` as maintainer CI pointer — consistent with D-91 "see … in maintainer CI".

### `docs/adoption_lanes.md` [CITED]

**Aligned:** Default lane proof block with `mix test.adoption`; links to operator guide for installer modes.  
**Gap (D-92):** No packaged tarball / hex.build vocabulary under default runtime proof block.  
**Correct:** No env vars present [VERIFIED: grep].

### `docs/operator_verification.md` [CITED]

**Aligned:** Tarball triage section L68–72; PR vs release table L319–324; version namespaces L328; exact-pinned registry language L326.  
**Gap (D-93/D-104 #5):** Upgrade sequence distinction needs explicit stable substrings — e.g. content-revision path (`scoria-0.1.0-unpack` fixture → HEAD tarball) vs registry semver bump (`baseline exact previous → target just-published`). Table mentions "content-revision upgrade" but not fixture→HEAD; paragraph L326 covers registry leg only.

### REQUIREMENTS ledger [CITED: `.planning/REQUIREMENTS.md`]

| Field | Value | Problem |
|-------|-------|---------|
| DOCS-HEX-01 checkbox | `[x]` L17 | Pins not implemented |
| Traceability | Phase 78, 82 — **Complete** L47 | Should be Partial until 82-02 |
| STATE.md | Phase 82 drift pins **queued** L113 | Contradicts REQUIREMENTS |

---

## Milestone Closeout Ceremony

### Audit template (v2.9) [CITED: `.planning/milestones/v2.9-MILESTONE-AUDIT.md`]

Frontmatter fields: `milestone`, `status`, `scores` (requirements/phases/integration/flows), `gaps`, `tech_debt`, `nyquist` block with `overall: missing` for 78–81.

**v2.10 audit scope (D-110):**

| Dimension | Target |
|-----------|--------|
| Requirements | 4/4: HEX-CONSUMER-01, HEX-UPGRADE-01, HEX-REGISTRY-01, DOCS-HEX-01 |
| Phases | 5/5: 78–82 |
| Integration | 78→79 tarball overlay → 80 upgrade → 81 registry → 82 doc guards |
| Tech debt (non-blocking) | Registry semver upgrade latent at 0.1.0; migration-delta D-87; 81-REVIEW Version.parse warning |

### Phase archive (v2.5 precedent) [VERIFIED: glob `v2.5-phases/`]

Move `.planning/phases/78-*` through `82-*` → `.planning/milestones/v2.10-phases/` preserving VERIFICATION, PATTERNS, CONTEXT, SUMMARY, PLAN artifacts. Reject v2.9-style deletion without archive dir (D-108).

### Complete-milestone outputs (D-107 82-03) [ASSUMED from CONTEXT + v2.7/v2.9 patterns]

- Archive: `v2.10-ROADMAP.md`, `v2.10-REQUIREMENTS.md`, `v2.10-MILESTONE-AUDIT.md`
- Reset active `.planning/ROADMAP.md` to v2.11 queue (ORCH-LIVE-01)
- Update `PROJECT.md`, `STATE.md`, `MILESTONES.md`
- Seed v2.11 REQUIREMENTS via `/gsd-new-milestone`

### v2.7 docs-truth precedent [CITED: `.planning/milestones/v2.7-MILESTONE-AUDIT.md`]

Phase 70 delivered capability-based README + adoption_surface tests before milestone audit — analogous to 82-01 pins before 82-02 audit.

---

## Validation Architecture

Nyquist enabled for Phase 82: DOCS-HEX-01 maps to **executable ExUnit drift guards** (not manual doc review). Phases 78–81 Nyquist ledgers remain missing — document in milestone audit, do not retroactively validate (D-109).

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Contract tests | Async file-read substring asserts |
| CI gate | Policy job lane-contract WAE includes all drift guard files |
| Runtime deps | None — no Postgres/Hex for doc contract tests |

### Requirement → test map

| Req ID | Behavior | Test type | Command | Exists? |
|--------|----------|-----------|---------|---------|
| DOCS-HEX-01 | Hex dep snippet SSOT | unit | `mix test test/scoria/hex_consumer_contract_test.exs` | ✅ |
| DOCS-HEX-01 | Adopter surface fragments | contract | `mix test test/scoria/adoption_surface_test.exs` | ❌ extend |
| DOCS-HEX-01 | Maintainer gate map topology | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ extend |
| DOCS-HEX-01 | `closeout_order/0` unchanged | unit | `mix test test/scoria/verification_lanes_test.exs` | ✅ (no change expected) |
| DOCS-HEX-01 | README refutes maintainer commands | contract | adoption_surface refute loop | ❌ extend refute list |
| DOCS-HEX-01 | Milestone traceability | doc/ledger | REQUIREMENTS.md + audit | ❌ 82-02/03 |

### Sampling rate — mix test commands for drift guard files

| When | Command |
|------|---------|
| After 82-01 contract module edits | `MIX_ENV=test mix test --warnings-as-errors test/scoria/hex_consumer_contract_test.exs` |
| After 82-01 adopter pins | `MIX_ENV=test mix test --warnings-as-errors test/scoria/adoption_surface_test.exs` |
| After 82-01 maintainer pins | `MIX_ENV=test mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| **Phase 82-01 gate (all drift guards)** | `MIX_ENV=test mix test --warnings-as-errors test/scoria/hex_consumer_contract_test.exs test/scoria/adoption_surface_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/support_journey_source_test.exs` |
| CI parity (policy job subset) | Same three files as in `ci-verify.yml` L53 plus `verification_lanes_test.exs` |
| After 82-02 audit | Manual review `v2.10-MILESTONE-AUDIT.md` frontmatter `status: passed` |
| Phase 82 complete | `/gsd-complete-milestone v2.10` preflight |

**Baseline verified 2026-05-29:** 58 tests, 0 failures on combined drift guard run [VERIFIED: shell].

### Failure triage

| Symptom | First check |
|---------|-------------|
| adoption_surface fragment miss | Did prose change without updating `adopter_doc_surfaces/0`? |
| ci_policy gate map miss | Use `section_after/2` — is heading exact `### CI gate map (maintainers)`? |
| README refute failure | Maintainer command leaked into README body |
| hex_consumer dep mismatch | `HexConsumerContract.hex_dep_snippet/0` vs README active dep line |
| REQUIREMENTS still Complete before pins | Reset checkbox in 82-01 per D-112 |

---

## Security Domain

**Phase type:** Documentation and test-contract only — no new runtime surfaces, auth paths, or external network calls in Phase 82 deliverables.

**OWASP ASVS applicability:** Limited. Doc drift guards reduce **supply-chain narrative risk** (adopters misunderstanding install path) but do not implement security controls. Relevant ASVS themes:

| Area | Relevance | Phase 82 touch |
|------|-----------|----------------|
| V1 Architecture | Doc truth supports correct dependency resolution | Pins enforce tarball vs registry story |
| V2 Authentication | None | Out of scope |
| V10 Malicious code | Indirect — Hex consumer proof already shipped in 78–81 | Docs must not steer adopters to repo `path:` in production |
| V14 Configuration | Maintainer env vars documented only in operator guide | D-92 keeps env vars out of adoption_lanes |

No STRIDE threats introduced by Phase 82; existing maintainer secrets (`HEX_API_KEY`) remain documented in operator guide only — already guarded by README refute patterns for maintainer commands.

---

## Integration Flow (78 → 82)

```mermaid
flowchart LR
  P78[Phase 78 HexConsumerContract SSOT] --> P79[Phase 79 Tarball full overlay]
  P79 --> P80[Phase 80 Content-revision upgrade]
  P80 --> P81[Phase 81 Registry attest]
  P81 --> P82[Phase 82 Doc drift guards + closeout]
  P82 --> AUDIT[v2.10-MILESTONE-AUDIT]
  AUDIT --> ARCHIVE[v2.10-phases archive]
```

| From → To | Check | Status |
|-----------|-------|--------|
| 78 → 82 | `hex_dep_snippet/0` in README | ✅ unit test |
| 79 → 82 | Tarball vocabulary in adopter docs | ⚠️ README yes; adoption_lanes no |
| 80 → 82 | Content-revision upgrade in operator gate map | ⚠️ partial — needs sequence substrings |
| 81 → 82 | PR vs release table + workflow pins | ⚠️ prose stub yes; ci_policy pins incomplete |
| 82 → REQUIREMENTS | DOCS-HEX-01 Complete only after pins | ❌ ledger premature |

---

## Open Questions for Planner (within discretion bounds)

1. Exact fragment strings for `adopter_doc_surfaces/0` — contract-derived vs prose-stable (D-96, D-73).
2. adoption_lanes note: single sentence vs bullet under proof block (D-73).
3. Operator upgrade sequence prose: dedicated subsection vs bullets under gate map (D-93).
4. Whether to add `@doc` link from `HexConsumerContract` moduledoc to operator gate map anchor (D-77).
5. Milestone audit integration score threshold when registry upgrade leg remains latent at 0.1.0 (D-110, D-73).

---

## Sources

- `.planning/phases/82-docs-truth-milestone-closeout/82-CONTEXT.md` — locked D-90–D-116 [CITED]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` [CITED]
- `.planning/phases/78-hex-consumer-contract-foundation/78-CONTEXT.md` — D-21, D-23 deferral [CITED]
- `.planning/phases/81-post-publish-registry-gate/81-CONTEXT.md` — D-89 stub [CITED]
- `.planning/milestones/v2.9-MILESTONE-AUDIT.md` — audit + Nyquist template [CITED]
- `.planning/milestones/v2.5-phases/` — archive precedent [VERIFIED: glob]
- `lib/scoria/hex_consumer_contract.ex`, `adopter_doc_contract.ex`, `support_journey.ex` [VERIFIED: read]
- `test/scoria/adoption_surface_test.exs`, `ci_policy_contract_test.exs`, `hex_consumer_contract_test.exs`, `support_journey_source_test.exs` [VERIFIED: read + shell]
- `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md` [VERIFIED: read]
- `.github/workflows/ci-verify.yml`, `release-please.yml`, `post-publish-smoke.yml`, `hex-publish.yml` [VERIFIED: read/grep]
