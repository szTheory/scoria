# Scoria

## What This Is

Scoria is a Phoenix-native AI application quality layer for Elixir teams. It gives existing Phoenix apps trace-first observability, durable workflow state, knowledge grounding, approvals, operator-visible evidence, and a public runtime surface without forcing teams into a hosted agent platform shape.

The product boundary stays embedded and Ecto/Telemetry-native: Scoria should feel like a library and dashboard surface that fits into a normal Phoenix application, not a separate runtime people have to work around.

## Core Value

Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Persona is roles-not-headcount (n=1 default).** Scoria's CORE roles — AI/product engineer, software architect, backend/platform, SRE/devops, reviewer/approver/operator, prompt-writer, eval-checker (full list in `SEED-005` persona strategy) — are *hats one person wears*, not separate people. The design default is the **smallest-viable team (n=1)**: every `/scoria` surface must be operable by one SWE with **no dedicated ML/platform/Trust-&-Safety team**. It **degrades gracefully to a few** — so n=1 is the default *lens*, not an invariant (e.g. `SEED-008` builds a multi-reviewer inter-rater agreement model, and `SEED-011` serves an ADJACENT privacy/legal persona). This sharpens P3 into a falsifiable test: *can one person operate every surface unaided?*

## Next Milestone: SEED-010 Lethal-Trifecta Governance (⭐ flagship — to be scoped)

**Goal (seed intent, not yet scoped into a versioned milestone):** Content trust tiers + spotlighting + tool-declared trifecta classification + confluence-escalation policy (Meta Rule-of-Two) + moderation/output hooks + `SECURITY-BOUNDARY.md`. No peer ships this as a runtime seam; Scoria is 2/3 built. It consumes v3.6's taint substrate (`span_kind`, host-declared `feature`/`route`/`archetype`/`intent`, structured spans) — highest external/positioning payoff, cheapest to build while the trace work is fresh. Next step: `/gsd-new-milestone` to question → research → define requirements → roadmap. (ROADMAP `## Backlog` 999.4; ordered execution order there.)

## Current State

**Shipped version:** `v3.6 Trace Foundation` (2026-07-19) — trace substrate complete; Hex `0.1.3` still LIVE (no publish this milestone)

**What shipped (v3.6):**
- The pre-existing silent FK gap that swallowed every span insert is closed (`Buffer.flush_spans/1` does an Ecto.Multi trace-upsert-then-span-insert with loud `[:scoria, :observe, :buffer, :flush_error]` telemetry instead of a bare `rescue`), and the observe pipeline (`Buffer` + `Telemetry.attach/1`) now boots under `Scoria.Application`, so a real host app's spans persist to Postgres without hand-wiring.
- Spans carry an OTel-GenAI / OpenInference **naming convention over the existing `attributes` map** (no typed columns, no schema rewrite): `Scoria.Observe.SpanKind` (8-value taxonomy, consumed by both UI tree components) and version-pinned `Scoria.Observe.Semconv` are the single origins for `span_kind` and every `gen_ai.*`/`openinference.*` key; LLM spans capture the four model-config params together via `ReqLLM.OpenTelemetry.Attributes`; legacy `llm.*`/`req.url` keys clean-replaced per CHANGELOG `0.1.4`.
- `tool`/`prompt`/`retrieval`/`guardrail` emit as real duration/failure-bearing child spans through one `Observe.span/4` primitive with `parent_id` linkage rendered in the trace tree; a linked `RETRIEVER` span is dual-written alongside `ai_retrieval_runs` (kept as system-of-record); host-declared `feature`/`route`/`archetype`/`intent` pass through unmodified.
- `ai_span_events` is resurrected via an allow-listed, never-raising, redaction-safe public `emit_event/1` (ordered Buffer flush; `prompt_rendered`/`guardrail_triggered` fire from real call sites); all attribute payloads are bounded to IDs-and-counts at a single write-time choke point (`Observe.Bounds`, a closed positive-allowlist registry, fail-closed).
- The adopter claim is now an honest, version-pinned "OpenInference-compatible" (doc-contract allow/ban lists updated in lockstep), backed by a falsifiable `Scoria.Observe.ConformanceTest` that replays the real redact→bounds pipeline across all three adapters; ReqLLM/Jido adapters are boot-attached (54.1) so LLM/TOOL spans persist with zero host hand-wiring.
- Locked with durable proof: 6/6 phases verified, 28/28 plans, 16/16 requirements complete; milestone audit `passed` (16/16 requirements, 12/12 integration seams, 1/1 boot→span-persist E2E flow). Closed `override_closeout` with one acknowledged pre-existing test flake (SEED-004-class, not a v3.6 regression) deferred at close.

**Latest shipped before this:** `v3.5 Documentation & Release Readiness` (2026-07-11) — Hex `0.1.3` LIVE

**What shipped:**
- Adopter-facing terminology is final and glossary-backed: a committed `guides/reference/glossary.md` maps Scoria terms (run, reviewer/operator, trace, evidence, capability, verification suite, scoped context, semantic cache, knowledge base, grounding, bounded handoff) to industry equivalents; README/guides/`llms.txt`/`AGENTS.md`/CHANGELOG use the final vocabulary consistently; `evidence_refs` RAG/citation storage is preserved (no schema migration); leaked code names (`Keystone`, `v2.0 Relay`, `Four Lanes`) are gone from the adopter surface; and CHANGELOG carries a pre-1.0 terminology upgrade note.
- The README front door is plain-English first: it opens with embedded-Phoenix positioning before coined vocabulary, states the n=1 reviewer persona and CORE/ADJACENT/NOT-OURS boundaries, publishes a concrete owns-vs-delegates scope-doctrine table, and links an honest Scoria-vs-hosted-LLM-ops comparison guide.
- HexDocs is a navigable product surface: `mix.exs` groups modules by domain and extras by an adopter/maintainer guide ladder, source/ref/doc links are version-aware (no `-dev` links to missing tags), a stable `guides/` tree covers getting-started → golden-path → JTBD/flows → troubleshooting → comparison → cheatsheet, and public moduledocs point at the reorganized guide paths.
- AI/agent navigation ships deliberately: curated root `llms.txt` + `AGENTS.md` point to the public facade, guide ladder, glossary, capabilities, and verification suites, distinguish curated source docs from generated ExDoc artifacts, and `mix scoria.release_preview` is the canonical warnings-as-errors docs/package gate (green).
- The honest `0.1.3` release cut landed: release-blocking policy/e2e/version drift was fixed, PR #12 reached green `ci-gate` and merged through release-please (`b904c22a`, tag `v0.1.3`), Hex lists `0.1.3` (HTTP 200, `has_docs`), and the post-publish registry attest proved fresh install + `0.1.0 → 0.1.3` live-lineage upgrade (run 29162646314).
- Locked with durable proof: 5/5 phases, 39/39 plans, and 18/18 requirements are complete; milestone audit `passed` after inline closure of two gaps (release-train branch drift reconciled onto origin/main; Phase 46 verification-doc gap closed via gsd-verifier, corroborated by 19 passing terminology/glossary/changelog guard tests).

**Current posture:**
- **The trace substrate is complete and live-tested.** Every span Scoria emits persists to Postgres with a portable OTel-GenAI/OpenInference key convention, correct `span_kind`, model config, structured child spans, a linked RETRIEVER span, host-declared attributes, and bounded IDs-only payloads — the foundational substrate that 008 (eval scorers), 010 (taint), 012 (archetype facet), and every 013 screen read. Hex is still `0.1.3` (no publish this milestone; the convention change is CHANGELOG-documented under Unreleased `0.1.4`).
- **Hex `0.1.3` is LIVE** and the adopter front door (README, ExDoc guide ladder, glossary, AI-nav) is stable and warning-gated. All three previously-blocking gates are closed: SEED-006 P0 trust/security (v3.4), SEED-005 docs/positioning + honest release (v3.5), and now SEED-007 trace foundation (v3.6).
- The next work is the ordered feature backlog: **SEED-010 Lethal-Trifecta Governance (999.4, ⭐ flagship)** is the sequenced next candidate — it consumes v3.6's taint substrate and has the highest positioning payoff — followed by SEED-008 eval depth (999.5) then SEED-012 (999.8, pulled forward). SEED-004 test-code determinism remains a carried-forward cleanup candidate (and now owns the one deferred v3.6 flake).
- Scoria remains the reference implementation for the embedded Traefik + `*.localhost` stack; sibling-repo migration and proxy bake-offs remain out of scope.

## Latest Shipped Milestone: v3.5 Documentation & Release Readiness (2026-07-11)

**Goal:** Make Scoria adoption-ready again after the v3.4 trust/security fixes by replacing jargon-first adopter docs with stable positioning, repairing release-blocking CI/browser drift, and cutting the honest `0.1.3` Hex release.

**Delivered:** Final glossary-backed terminology across the adopter surface (leaked code names removed, `evidence_refs` preserved, CHANGELOG upgrade note); a plain-English README front door with n=1 reviewer persona, CORE/ADJACENT/NOT-OURS boundaries, a concrete owns-vs-delegates scope table, and an honest hosted-LLM-ops comparison; a grouped, version-aware ExDoc guide ladder (getting-started → golden-path → JTBD → troubleshooting → comparison → cheatsheet) with aligned public moduledocs; curated `llms.txt`/`AGENTS.md` AI-navigation plus `mix scoria.release_preview` as the canonical warnings-as-errors docs/package gate; and the honest **`0.1.3` Hex release** — PR #12 green `ci-gate` → release-please merge (`b904c22a`, tag `v0.1.3`) → Hex live → post-publish registry attest proving fresh install + `0.1.0 → 0.1.3` upgrade.

**Boundary held:** Stable adopter docs + release readiness only. Feature-specific guides for trace foundation, lethal-trifecta governance, eval depth, retrieval depth, and privacy/feedback stayed with their owning future seeds.

**Close:** Audit `passed` — 18/18 requirements, 5/5 phases verified, 5/5 integration seams wired — after inline closure of two gaps found at audit time: (1) local `main` had diverged from `origin/main` and lacked the `0.1.3` release commit (reconciled by rebasing the planning-only commits onto `b904c22a`); (2) Phase 46 lacked a VERIFICATION.md (produced via gsd-verifier, `passed` 5/5, corroborated by 19 passing guard tests). Archived in `.planning/milestones/v3.5-*`.

## Previous Shipped Milestone: v3.4 Pre-1.0 Trust & Security Hardening

**Goal:** Fix the three P0 correctness/security bugs live in shipped `0.1.2` — making eval fail CLOSED, knowledge retrieval tenant-isolated, and the dashboard auth boundary host-injectable — plus a correctness sweep, so Scoria's "trustworthy, governed, inspectable" promise holds before the next Hex release. (🔴 P0 · SEED-006.)

**Delivered:** Eval fail-closed semantics, tenant-isolated knowledge retrieval, host-owned dashboard scope resolution, and the correctness sweep are implemented and verified. The milestone audit now passes with 17/17 requirements and 4/4 phases complete.

**Boundary held:** fix + prove only — the honest `0.1.3` Hex release cut belongs to SEED-005 (999.2). Deeper scorers → SEED-008; full abstention/rerank → SEED-009; masking/retention → SEED-011.

**Sequencing:** Phases 42 (eval) / 43 (knowledge) / 44 (dashboard) completed their independent subsystem work; Phase 45 closed the shared correctness and doctrine proof. Full ordered backlog now continues at SEED-005 / 999.2 in `ROADMAP.md ## Backlog`.

## Previous Shipped Milestone: v3.0 Control Room (2026-06-14)

**Goal:** Take the embedded `/scoria` operator dashboard to "insane polish" — a tightened, fully-adopted design system, a clear persona/JTBD information architecture, brand-tied motion, full light/dark parity, and seed data that exercises every screen — proven by a committed screenshot+critique evaluation loop.

**Delivered:** Design system fully adopted — `ui.ex` exposes the table/drawer/modal/field/form_section/notebook/skeleton/toast component set as the enforced token gateway; raw-palette count is a verified **zero** across `lib/scoria_web/`, guarded by the unconditional DS-06 drift ratchet. Persona/JTBD IA spine shipped: three-group nav (Operate/Improve/Configure) with route-aware active state, a Status Home, object-aware breadcrumbs, a ⌘K command palette + keyboard shortcuts, cross-screen quality-loop threading, and 5 honest reserved-name "coming soon" stubs (no fabricated data). All 13 screen modules converted to shared components; a real Dataset Builder `/datasets` index converges the duplicated promote affordances; 13 evidence components collapsed into thin notebook adapters. Brand-tied motion + full light/dark WCAG-AA parity (22/22 Playwright parity smoke), and a committed dev-only `mix scoria.ui.shots` screenshot + ReqLLM 9-dimension critique loop with seed data exercising every screen.

**Closed `gaps_found` (accepted as tech debt):** 18/28 requirements fully satisfied, 10 partial, **0 unsatisfied**. The 10 partials are verification-doc gaps — Phases 13 (IA-01..06) and 14 (SCREEN-01..02) were never run through gsd-verifier, plus documented IA-05 threading and PROOF-01/02 proof gaps. None is a functional regression. See `.planning/MILESTONES.md` → v3.0 Known Gaps and `.planning/milestones/v3.0-MILESTONE-AUDIT.md`.

**Core finding that drove the milestone:** Scoria's design system was under-*adopted*, not under-built. The token-first CSS already defined tables, drawers, modals, span rails, and disciplined motion, but `lib/scoria_web/ui.ex` never exposed them as components — so ~22/25 view files leaked raw Tailwind (`stone-*/rose-*/...`), worst in the least-iterated screens. The work: expose components → delete leaked classes → consolidate → orient → polish → prove.

## Previous Shipped Milestone: v3.1 CI/CD Velocity (2026-06-17)

**Goal:** Cut CI wall-clock from ~77 min to ~12 min and eliminate known flakes — without weakening the verification bar (every lane that gates merge today still gates merge; nothing demoted to nightly).

**Delivered:** Realized SEED-003 as an infra/docs-only milestone (Phases 23–28). PR CI critical path cut from ~77 min (one serial `verify / test` job) to **7m38s MEASURED** in real GitHub Actions run 27709716751 — VELO-01 MET. The serial job fanned out into the parallel topology `policy → build → { test, ratchet, knowledge, connector, full-suite[×4 matrix] } → verify-summary`: a build-once job compiles deps+app once under `MIX_ENV=test` WAE and ships a `_build/test`+`deps` artifact every downstream lane restores (CACHE-01/02); the knowledge lane runs `--only knowledge` instead of the whole suite (KNOW-01); heavy lanes run as parallel `needs:` jobs behind one stable `if: always()` + skipped-as-failure `verify-summary` fan-in (PAR-01/02/03); the full suite shards 4-way via `mix test --partitions 4` on isolated `scoria_test1..4` DBs with zero coverage loss (SHARD-01); the ephemeral-range Postgres host-port flake is fixed, the leftover TEMP e2e diagnostic removed, and a zero-retry-default policy documented (FLAKE-01/02/03); and a `mix ci` alias reproduces the merge gate locally (DX-01) with MAINTAINERS/operator_verification/README describing the topology in contract-guarded lockstep (DX-02).

**The bar was preserved (hard constraint held):** `Scoria.VerificationLanes.closeout_order/0` byte-stable, the byte-order lane contracts (`ci_policy_contract_test`, `verification_lanes_test`) green at every phase (51/0 at close), the `CI / ci-gate` required-check name unchanged (branch protection needs no edit), single fast PR+main gate, standard `ubuntu-latest` runners. Node-24 actions modernization shipped separately (PR #10, merged).

**Close:** Audit `passed` — 13/13 requirements satisfied, 6/6 phases verified, 9/9 cross-phase integration edges wired. Deeper test-code async work (de-globalizing `IntegrationCase`, removing `Process.sleep` sites) was deliberately deferred to SEED-004. Archived in `.planning/milestones/v3.1-*`.

## Previous Shipped Milestone: v2.17 Vesicle (2026-06-11)

**Goal:** Ship a pressure-tested, repo-canonical Scoria brand system in `brandbook/` — audited brand book, locked design tokens, user-chosen programmatically generated logo system, and a professional standalone HTML brand book — wired into README, dashboard favicon/mark, and Hex/GitHub/HexDocs copy.

**Delivered:** brandbook/ canonical brand system (pressure-test.md 1,311 lines, 14 sections; TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup chosen across 2 gallery rounds; 8-variant logo set; tokens.json/tokens.css 4-source consistency; brand-book.md 543-line canonical rewrite; standalone index.html 55 KB; 7 examples; 458 KB total); integration (README picture header, dashboard TV-1 mark + data-URI favicon, mix.exs + GitHub descriptions); tagline locked "AI ops for Phoenix apps." (user override at gate #1); mix test 632 green, DS-06 untouched. BRAND-09 conditional did not fire (propagation: not-required). quality-gate.mjs 8/8 PASS.

**Why it mattered:** The AI-generated brand book seed had never been pressure-tested and no logo or collateral existed. v2.17 closed this gap before v3.0 phases 13–17 so the new navigation spine, screen polish, and motion work all ship under a tested brand identity.

## Previous Shipped: v2.16 ReqLLM Peer Bump (2026-05-30)

**Goal:** Keep Scoria's LLM orchestration peer current on Hex without widening product scope.

**Delivered:** ReqLLM `~> 1.13` (1.13.0 locked); integration slice (17 tests) + `mix scoria.test.ci_trust` (43 tests) green. Phase 10.1 closed retroactive VERIFICATION process gap — milestone audit `passed`, `requirements_process: 4/4`.

**Why it mattered:** LLM orchestration peer stays current on Hex without product scope creep or CI regression.

## Previous Shipped: v2.15 Connector Adoption Lane (2026-05-30)

**Goal:** Named connector adoption proof lane with docs/CI/drift-guard parity to semantic and knowledge lanes.

**Delivered:** `mix test.connector`, VerificationLanes `:connector` entry, SupportJourney integration proof, PR CI WAE. Phase 07.1 closed retroactive VERIFICATION/SUMMARY process gap — milestone audit `passed`, `requirements_process: 6/6`.

**Why it mattered:** Connector adoption now has the same executable lane contract, docs truth, and CI posture as semantic and knowledge — without widening closeout order.

## Release Queue

- No active release queue. `0.1.1` was superseded by `0.1.2`; `0.1.2` is live on Hex and verified by post-publish registry smoke.

## Latest Shipped Milestone: v2.11 Orchestrator Live Wiring

**Goal:** Wire runtime→PubSub trace broadcast and HITL approval modal from real approvals (ORCH-LIVE-01).

**Delivered:**
- `OperatorBroadcast` tenant PubSub fan-out from telemetry with redact→broadcast→buffer ordering.
- HITL modal and inbox from real `Workflows.mark_waiting_for_approval/3` / approve/reject paths.
- `OrchestratorLive` DB hydrate, incremental trace merge, token coalesce, producer-path integration tests.
- Phase 01.1 hardening: delta/hydrate redaction, approval E2E, public `emit_span_delta/1`.

**Why it mattered:** Operators see live traces and real approval pauses without hollow LiveView test paths — closes the post-Hex operator UX gap.

## Previous Shipped: v2.10 Hex Consumer Proof & Upgrade Smoke

**Goal:** Close the post-Hex adopter-trust gap — prove packaged artifact installs, upgrades, and matches v2.9 overlay depth.

**Delivered:**
- Tarball consumer proof in merge-blocking `mix test.adoption`.
- Content-revision upgrade smoke (`0.1.0` fixture → HEAD).
- Blocking post-publish registry attest via `mix scoria.post_publish_smoke`.
- `adopter_doc_surfaces/0` + executable drift guards (DOCS-HEX-01).

**Why it mattered:** Adopters and maintainers share one SSOT for Hex dep shapes, CI topology, and doc pins before orchestrator live wiring.

## Previous Shipped: v2.9 Adoption Journey & Reference Demo

**Goal:** Battle-test Scoria through a realistic support-copilot domain with shared journey fixtures, extended host-proof overlay, and a human-clickable gallery — without weakening v2.4–v2.8 lane contracts.

**Delivered:**
- `Scoria.SupportJourney` fixture SSOT + multi-surface source contract drift guards.
- Merge-blocking host-proof overlay (resume + handoff smokes).
- `examples/support_copilot/` gallery with advisory `mix scoria.test.support_copilot` lane.
- CI contract for gallery-after-knowledge ordering; `closeout_order/0` unchanged.

**Why it mattered:** Adopters get a realistic domain story with executable overlay proof, clickable gallery, and doc↔fixture alignment before Hex consumer proof (v2.10).

## Latest Shipped Release Milestone: v2.7 OSS Release + Docs Truth

**Goal:** Docs truth, then Hex `0.1.0` / `v0.1.0` — without weakening v2.4–v2.6 contracts.

**Delivered:** DOCS-03/04, INST-DX-01, HEX-01/02, Hex-primary README, `package_surface_test` flip.

## Current State

- **v3.4 complete (2026-07-09, Pre-1.0 Trust & Security Hardening):** SEED-006's P0 gate is fixed and verified across eval fail-closed behavior, knowledge tenant isolation, dashboard host-owned scope, and the correctness sweep. Phase 42-45 verification/validation artifacts are present, 24/24 plans and 17/17 requirements are complete, and focused eval/knowledge/dashboard-auth/scope-doctrine tests passed during closeout. The Hex release remains intentionally deferred to SEED-005.
- **Phase 37 complete (2026-07-02, v3.3 Design System Stress Test):** Dev-only Component Lab + fixture matrix (LAB-01, LAB-02, FIXT-01) — component quality is now visible across states, themes, and ugly data without touching runtime `lib/`. Built the deterministic fixture catalog (`dev/lab/fixtures.ex`: 15 scenarios across 8 domains) and the lab-state→visual-tone vocabulary + reusable state-band renderer (`dev/lab/sections/states.ex`: 10 D-11 states); seven section modules (Foundations, Primitives, Groups, FixturesView, Overlays, Viewports) under `dev/lab/sections/`; the param-driven `DevLab.LabLive` mounted at `/scoria/_lab` via `dev/dev_router.ex` (allowlist-validated params, no `String.to_atom`); a 17-test Playwright proof (`priv/dev/e2e/lab.spec.mjs`) and a MAINTAINERS.md Component Lab section. A source-scan boundary/coverage guard (`test/scoria_web/dev_lab_boundary_test.exs`) plus the extended DS-06 drift guard (`test/scoria_web/ds06_drift_guard_test.exs`) prove the lab stays out of the public macro, the Hex tarball, and runtime `lib/` (13/13 green; `lib/scoria_web/router.ex` untouched). Executed sequentially on `main` after the worktree harness forked a stale base and the executor's base-safety guard correctly halted it. Verified passed (5/5 must-haves, independently re-executed incl. live-server curl 200 + full Playwright run). Pre-existing unrelated full-suite failures logged in `deferred-items.md`.
- **Phase 36 complete (2026-06-20, v3.3 Design System Stress Test):** Baseline and inventory artifacts are complete and verified (17/17 must-haves). `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` and `36-inventory.json` preserve the recent UI cleanup as baseline truth, define the canonical Markdown/JSON artifact contract, and provide a source-reconciled design-system inventory: 86 rows, 236 documented exclusions, all 9 layers, all 5 statuses, and all 5 required risk IDs. The Phase 37+ gate now blocks implementation phases unless the inventory artifacts exist, parse, retain required risk IDs, cover layer/status enums, validate rows, pass source reconciliation, and preserve the no-runtime-source-change boundary. Broad `mix test --no-start --warnings-as-errors` has unrelated residual failures recorded in `36-VERIFICATION.md`; Phase 36-specific validators and GSD verification passed.
- **Phase 35 complete (2026-06-19, v3.2 Drydock):** Maintenance release `0.1.2` shipped to Hex and post-publish smoke is green (REL-01..03). Plan 35-01 kept README Hex-primary while narrowing the GitHub fallback contract and made `registry_upgrade_pair("0.1.2")` use previous live Hex release `0.1.0`. Plan 35-02 refreshed PR #3 through Release Please, proved the diff stayed only `.release-please-manifest.json` / `CHANGELOG.md` / `mix.exs`, and merged release commit `26eb9a5e686fe4957196dfa5c6654121bda65c03` after latest-head `CI / ci-gate` success. Plan 35-03 classified the canceled post-merge publish path, used exact `hex-publish.yml` recovery inputs `tag=v0.1.2` / `release_version=0.1.2`, verified Hex latest `0.1.2`, then fixed smoke setup/harness issues and passed final post-publish run `27834739958` with fresh install plus live-lineage upgrade `0.1.0 -> 0.1.2`. No `0.1.1` publish/backfill path was used.
- **Phase 34 complete (2026-06-18, v3.2 Drydock):** Docker DX drift guard + CI guard extension (DOCS-03) — `Scoria.DockerDxDocContractTest` now pins reader-facing Docker/native dev-DX truth from `docs/docker_dev_dx.md` under the existing no-start policy lane, including `make up`, `make dev`, `make nuke`, native `:4799`, process-scoped secrets nouns, and Phase 31 cache-table strings. The stale fixed-port browser-start guard rejects `localhost:4000` / fixed loopback `4000` guidance, including wrapped paragraph copy, while allowing qualified Docker-internal/Traefik/service-target mechanics. `ci_policy_contract_test.exs` now scans `.github/workflows/post-publish-smoke.yml`, exactly asserts both `ci.yml:e2e` and `post-publish-smoke.yml:smoke` FLAKE-01 coverage, and keeps broad Docker DX doc-token ownership in the dedicated contract. `.github/workflows/post-publish-smoke.yml` uses `5432:5432` and `SCORIA_DB_PORT: 5432`; `.github/workflows/ci-verify.yml` appends the doc contract to the existing policy-lane file list only. Verified passed (8/8 must-haves), final code review clean, policy lane 83/0, and zero `55432` / stale fixed-port docs hits.
- **Phase 30 complete (2026-06-18, v3.2 Drydock):** Launch banner + native-dev notice (DXCLI-05) — starting the dev server (native or Docker) now shows the operator where to go, with every advertised element traced to a single source of truth (drift-proof). `make dev` prints `==> Scoria dev (native) → http://localhost:$(PORT)/scoria` (honoring `PORT ?= 4799`) before Phoenix boot noise; `make dev PORT=5000` echoes `:5000`. The Docker `dev-entrypoint.sh` banner derives its `/scoria` route list live from `mix phx.routes ScoriaWeb.DevRouter` (9 literal GET paths incl. `/scoria/datasets`, no `:`-param routes) — replacing the drifted hand-maintained `Screens:` block — plus a bare Traefik admin link (`http://localhost:8080`) and a `Native dev server: make dev → http://localhost:4799/scoria` notice, all on distinct copy-pasteable lines. Boot-safe under `set -euo pipefail` (`|| true` + empty-check fallback), shellcheck-clean. No edits to `lib/scoria_web/router.ex`, `config/dev.exs`, or container `:4000` wiring. Verified passed (6/6 must-haves). The route-derivation pipeline is left as the seam for Phase 34's banner↔router parity contract test.
- **Phase 29 complete (2026-06-18, v3.2 Drydock):** Makefile hardening (DXCLI-01..04) — the Makefile is now the single trustworthy dev entry point. `PORT ?= 4799` is the SSOT threaded through `make dev` and `shots-native` (`--url http://localhost:$(PORT)/scoria`); `config/dev.exs:33` runtime fallback stays `"4000"` by design (D-08 — changing it breaks Traefik/container). `.DEFAULT_GOAL := help` + a BSD-awk `## name: desc` parser self-documents all 17 targets (verified live under darwin onetrueawk). Cleanup ladder is scope-safe: `clean` = `docker compose down` (keeps volumes), `down: clean` body-less alias (no drift), `nuke` = `docker compose down -v` with a COMPOSE_PROJECT_NAME warning banner enumerating volumes (no TTY prompt); zero `volume prune`/`system prune` hits. `fleet` dual-filters `name=scoria-` AND `label=traefik.enable=true` with a `-q` empty-state guard. Verified passed (5/5 must-haves); code review advisory 0 critical / 2 warning (doc-vs-behavior PORT notes WR-01/WR-02, accepted per D-08).
- **v3.1 CI/CD Velocity SHIPPED + archived (2026-06-17):** All 6 phases (23–28), 9 plans, 13 tasks. PR CI critical path 77m→**7m38s MEASURED** (run 27709716751); audit `passed` (13/13 requirements). Build-once artifact job, knowledge `--only knowledge`, parallel `verify-summary` fan-out, 4-way sharding, Postgres flake fix, `mix ci` alias. Bar preserved: `closeout_order/0` byte-stable, `CI / ci-gate` required-check name unchanged, contract suite 51/0, nothing demoted to nightly. Tag `v3.1` created locally (unpushed). Archived in `.planning/milestones/v3.1-*`.
- **Phase 27 complete (2026-06-17, v3.1 CI/CD Velocity):** CI determinism & flake elimination (FLAKE-01..03). Replaced the fixed `55432:5432` Postgres host-port bind (in the GitHub-runner ephemeral range 32768–60999, root cause of run 27508317719) with `5432:5432` across all 5 job blocks in `ci.yml` + `ci-verify.yml`; deleted the leftover TEMP e2e diagnostic step; documented a zero-retry-default "retry vs fix" policy in `docs/MAINTAINERS.md`. Pinned by 3 durable contract guards in `ci_policy_contract_test.exs` (42→45 tests): an ephemeral-port ban (host_port < 32768, hardened post-review to also catch quoted `- "55432:5432"` binds + a per-block non-empty guard so a broken regex fails loud), a no-TEMP-step guard, and a no-retry-on-test-workflows guard (D-08 carve-outs excluded). Local `SCORIA_DB_PORT=55432` parity and the full-suite `SCORIA_DB_NAME` omission preserved. Verified passed (5/5 must-haves).
- **Phase 17 complete (2026-06-13, v3.0 Control Room — final phase):** Consistency sweep + proof (PROOF-01..03). Committed final-audit report `priv/shots/gap_register_final.md` with a 9-screen baseline→final rubric delta table, a deterministic 11-P1 resolution checklist (each P1 mapped to its resolving phase + re-verifiable code evidence, no API key required), and a raw-color-zero assertion citing the `ds06_drift_guard_test` guard (3/3 green). Committed reusable contact-sheet generator `priv/dev/contact_sheet.mjs` (`--before/--after/--out`, HTML-escaped + URL-encoded, crash-safe on partial dirs) plus `priv/shots/contact_sheet_index.md`; rendered HTML stays gitignored/regenerable. `mix docs` now renders a drift-free `ScoriaWeb.UI` component catalog (7 sparse `@doc`s backfilled) with a `docs/MAINTAINERS.md` catalog + harness entry-point. Fresh 2026-06-13 shot set partial (approvals + live_ops; rest blocked by pre-existing Phase-13 modal-overlay timeout) — deterministic checklist is the falsifiable proof. v3.0 Control Room milestone requirements fully delivered.
- **Phase 16 complete (2026-06-13, v3.0 Control Room):** Motion + responsive + theme parity (MOTION-01..04). Mobile-first dashboard shell + accessible off-canvas nav drawer (Hooks.MobileNav), responsive `table/1` (overflow viewport + opt-in `mobile_summary` cards on the 4 scan tables), named responsive grid classes replacing unsupported `sm:/lg:/xl:grid-cols` utilities, and focus-visible/non-color-only-status/motion-contract hardening with full light+dark parity. Mechanically proven by `priv/dev/e2e/phase16_parity.spec.mjs` (22/22 Playwright, MOTION-01..04). Next: Phase 17 consistency sweep + proof.
- **Phase 15 complete (2026-06-13, v3.0 Control Room):** High-traffic control-room screens now use shared table/drawer/modal/notebook primitives across Live Ops, Workflows, Approvals, and Connectors; remaining evidence adapters are thin notebook/evidence adapters; DS-06 raw-palette baseline is zero. SCREEN-03 and SCREEN-04 are complete.
- **v2.17 Vesicle shipped (2026-06-11):** Brand system complete — pressure-test.md (1,311 lines), TV-1 mark + LK-B lockup chosen by user (2 rounds), 8-variant logo set, brandbook/ (458 KB, zero binaries), README picture header, dashboard TV-1 mark + data-URI favicon, mix.exs/GitHub descriptions, quality-gate.mjs 8/8 PASS, mix test 632 green, DS-06 untouched. Archived in `.planning/milestones/v2.17-*`.
- **Phase 12 complete (2026-06-04, v3.0 Control Room):** Design-system component layer — `ui.ex` now exposes table/drawer/modal/field/form_section/notebook/skeleton/toast contracts, `flash_group` routes through semantic tokens, and the DS-06 raw-color drift guard runs unconditionally in `mix test` (baseline `test/support/ds06_baseline.txt`, `ui.ex` at zero raw palette). Known polish debt deferred to Phases 14–16 (toast overlap CR-01, drawer positioning WR-03, dialog `aria-labelledby` WR-02) — see `12-REVIEW.md`.
- **v2.16 shipped (2026-05-30):** ReqLLM peer bump to `~> 1.13` (1.13.0); archived in `.planning/milestones/v2.16-*`.
- **v2.15 shipped (2026-05-30):** Connector adoption lane — `mix test.connector`, PR CI WAE after knowledge, drift guards; archived in `.planning/milestones/v2.15-*`.
- **v2.12 shipped (2026-05-30):** Adoption confidence reference demo — SupportJourney.Handlers SSOT, gallery optional lane journeys, orchestrator producer smoke, MAINTAINERS.md split; Hex `0.1.1` prepared.
- **v2.11 shipped (2026-05-30):** ORCH-LIVE-01 complete — orchestrator live trace broadcast and HITL from real runtime/workflow paths; phases 01 + 01.1 in `.planning/milestones/v2.11-phases/`.
- **v2.10 shipped (2026-05-30):** Hex consumer proof milestone archived — phases 78–82 in `.planning/milestones/v2.10-phases/`; audit at `v2.10-MILESTONE-AUDIT.md`.
- **Phase 81 (v2.10):** Post-publish registry gate — `mix scoria.post_publish_smoke` proves live Hex install with exact version pins; blocking `post-publish-attest` wired in release-please and hex-publish workflows.
- **Phase 79 complete (2026-05-29):** Merge-blocking tarball consumer proof runs full v2.9 overlay depth (handoff → route → runtime) via `mix hex.build` unpack dep; operator triage, `SCORIA_PRESERVE_HOST`, and CI failure snapshot artifact wired.
- **Hex:** `0.1.1` prepared locally; `0.1.0` live at https://hex.pm/packages/scoria (tag `v0.1.0`, 2026-05-29).
- Phase 73 CI hardening complete (2026-05-29): semantic lane + knowledge WAE + inventory baseline check in `ci-verify.yml`; operator gate map updated.
- Phase 72 Hex publish closeout complete (2026-05-29): README Hex-primary; release-please without `release-as` pin.
- CI policy→test topology: `warning_baseline.check` → `warning_inventory.check_baseline` → compile WAE → lane-contract WAE (policy); closeout lanes → semantic WAE → ratchet hygiene → full-suite WAE → knowledge WAE (test).
- Warning inventory and ratchet maintainer paths (`mix scoria.warning_inventory`, `mix scoria.warning_ratchet.*`) classify and clear debt by surface; baseline ledger empty (`"clusters": {}`).
- Full-suite `mix test --warnings-as-errors` is green locally; `mix scoria.test.ci_trust` bundles Phase 69 contract verification.
- Installer preview/check/apply truth from v2.5 remains SSOT; canonical lane order unchanged.
- Milestone archives: `.planning/milestones/v2.6-ROADMAP.md`, `v2.6-REQUIREMENTS.md`, `v2.6-MILESTONE-AUDIT.md`.

**Preserve:** v2.4 `VerificationLanes.closeout_order/0`, v2.5 installer truth, v2.6 warning-ratchet gates, v2.7 Hex adopter flip, v2.8 CI topology, v2.9 SupportJourney + gallery advisory lane.

## Requirements

### Validated

- ✓ Canonical actor, tenant, and session identity are explicit public runtime nouns. — `v1.4 Keystone`
- ✓ Developers can start, resume, and inspect app-facing runs through the public `Scoria` runtime surface. — `v1.4 Keystone`
- ✓ Provider/model/prompt-policy defaults are installable through one documented application-facing surface. — `v1.4 Keystone`
- ✓ Adoption docs and verification flows align to executable proof lanes instead of prose-only guidance. — `v1.4 Keystone`
- ✓ Remote MCP connectors can be registered through a Phoenix-native Scoria boundary with boring defaults for discovery, auth, and capability refresh. — `v1.5 Switchyard`
- ✓ Remote connector invocation preserves Scoria identity, tool policy, approval, and audit evidence without turning Scoria into a hosted connector platform. — `v1.5 Switchyard`
- ✓ Operators can inspect connector health, granted scopes, approvals, and remote invocation evidence through the embedded dashboard surface. — `v1.5 Switchyard`
- ✓ Scoria ships a small curated connector/profile layer that improves DX for common remote-tool adoption paths without widening the core product boundary. — `v1.5 Switchyard`
- ✓ Multi-model runtime calls automatically degrade through breaker-aware fallback chains instead of failing at the first unhealthy model. — `v1.8 Vanguard`
- ✓ Large evaluation campaigns can fan out durably across many runtime targets through Oban-backed coordinator and worker flows. — `v1.8 Vanguard`
- ✓ Operators can inspect model health, fallback usage, and campaign progress through the embedded dashboard surface. — `v1.8 Vanguard`
- ✓ Operators can branch replay runs from durable checkpoint truth without mutating source history. — `v1.9 Crucible`
- ✓ Replay defaults preserve operator trust by blocking or stubbing unsafe external effects while keeping provenance explicit. — `v1.9 Crucible`
- ✓ Operators can compare replay vs original evidence and promote frozen workflow-source snapshots into draft datasets. — `v1.9 Crucible`
- ✓ Production traces can be scored asynchronously and surfaced in an operator review queue with workflow/runtime deep links. — `v1.9 Crucible`
- ✓ Draft promotion candidates remain reviewable and sealed baselines stay approval-gated instead of auto-mutating release truth. — `v1.9 Crucible`
- ✓ Developers can start a bounded delegated run through `Scoria.start_handoff_run/3` with inspectable projected context and operator-visible delegated lineage. — post-`v1.9` repo-local current truth, 2026-05-24
- ✓ Developers can enable semantic fast-path evaluation only for explicitly safe read-only runtime lanes. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Scoria refuses semantic reuse for write-side, approval-sensitive, or personalized-tool-backed flows unless they are explicitly classified as safe. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Semantic cache lookups stay tenant-partitioned and compatibility-aware across prompt, policy, and source truth. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Operators can inspect semantic cache hit, miss, reject, stale, and invalidation evidence through runtime and workflow surfaces. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Scoria ships a named semantic proof lane that verifies partitioning, fallback, invalidation, and operator-evidence behavior together. — `v2.1 Tenant-scoped semantic fast path`
- ✓ Maintainers can build publish-facing docs locally through `mix docs`, with Hex metadata, source links, and docs extras aligned to the real public package surface. — `v2.2 OSS adopter onramp`
- ✓ Maintainers can preview the package artifact before first Hex publish and confirm the shipped file inventory includes required runtime code, migrations, README, and adoption guides. — `v2.2 OSS adopter onramp`
- ✓ A Phoenix host app can run `mix scoria.install` once to mount the dashboard, copy core migrations, and inject baseline runtime defaults without duplicate or misleading mutations. — `v2.2 OSS adopter onramp`
- ✓ The default Phoenix lane installs cleanly when Tailwind or optional knowledge surfaces are absent, and the installer states the skipped or optional steps explicitly. — `v2.2 OSS adopter onramp`
- ✓ A fresh Phoenix consumer app can prove dependency fetch, install, migration, and `/scoria` route visibility through the public adoption path. — `v2.2 OSS adopter onramp`
- ✓ That same consumer proof path can start one durable run through `Scoria.start_run/2`, read it back through the public runtime facade, and inspect operator evidence without enabling optional knowledge or semantic lanes. — `v2.2 OSS adopter onramp`
- ✓ README, operator verification, and installer output now describe the same lane ordering and prerequisite boundaries for default, bounded-handoff, semantic fast path, and optional knowledge surfaces. — `v2.2 OSS adopter onramp`
- ✓ Scoria now names one canonical verification command per lane and documents denial or fallback behavior when optional prerequisites are missing. — `v2.2 OSS adopter onramp`
- ✓ Phoenix developers can follow one example that starts with the default runtime lane and escalates into `Scoria.start_handoff_run/3` without new public API assumptions. — Phase 52 `runtime-to-handoff-example-contract`
- ✓ The example makes bounded projected context, rejection behavior, and operator-visible delegated lineage understandable from adopter-facing docs or sample code. — Phase 52 `runtime-to-handoff-example-contract`
- ✓ Operators can inspect default runs, delegated lineage, projected-context summaries, and delegated outcome through curated runtime and workflow evidence surfaces. — Phase 53 `operator-evidence-and-lane-guidance`
- ✓ README and adopter/operator guides now state when to stay on the default runtime lane versus when to escalate into bounded handoff. — Phase 53 `operator-evidence-and-lane-guidance`
- ✓ The runtime-to-handoff path is backed by an executable proof lane that remains independent of optional semantic or knowledge setup. — Phase 54 `executable-proof-and-closeout-truth`
- ✓ Canonical lane contract source now defines release-preview, adoption, runtime-to-handoff, semantic fast-path, and optional knowledge lanes with one command/env/prerequisite/exclusion schema. — `v2.4 Adoption Reliability Contract`
- ✓ Adoption/support drift tests now consume lane-contract command and boundary nouns, and unsupported alias regressions remain blocked. — `v2.4 Adoption Reliability Contract`
- ✓ Release-preview/docs warning policy now runs warning-clean with remaining debt tracked in a scoped owner+expiry baseline ledger. — `v2.4 Adoption Reliability Contract`
- ✓ CI now enforces warning gates and canonical lane ordering for release-preview, adoption, and runtime-to-handoff proofs. — `v2.4 Adoption Reliability Contract`
- ✓ Installer contract remains idempotent while supporting root browser scopes that use list-form `pipe_through`. — `v2.4 Adoption Reliability Contract`
- ✓ Installer `--dry-run` now uses a deterministic planner contract that reports per-surface classification and rationale without host writes. — Phase 59 `planner-contract-foundation`
- ✓ Installer `--check` now uses deterministic tri-state semantics (`0/1/2`) and emits one stable machine trailer line for CI parsing. — Phase 59 `planner-contract-foundation`
- ✓ Planner/check coverage now includes subprocess status/trailer assertions and no-write regression checks that keep v2.4 lane guardrails green. — Phase 59 `planner-contract-foundation`
- ✓ Maintainer can run `mix scoria.install --dry-run` for a deterministic no-write mutation plan with per-surface classification. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Maintainer can run `mix scoria.install --check` with stable `0/1/2` exits and `SCORIA_CHECK_RESULT` trailer semantics. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Installer apply mode executes planner-led mutations with manifest-aware drift preflight and explicit manual-review blocking. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ Installer output stays truthful and idempotent across preview/check/apply with operator-ordered summaries and contract SSOT. — `v2.5 Installer Safety & Upgrade Confidence`
- ✓ CI fails when `.planning/WARNING-BASELINE.md` contains expired or invalid accepted debt rows. — Phase 66 `baseline-expiry-and-inventory`
- ✓ Maintainer can reproduce a classified full-suite warning inventory by surface/area. — Phase 66 `baseline-expiry-and-inventory`
- ✓ Canonical compile and lane-contract surfaces remain warning-clean under warnings-as-errors. — Phase 67 `high-signal-warning-ratchet`
- ✓ High-signal test surfaces pass under warnings-as-errors without new accepted debt. — Phase 67 `high-signal-warning-ratchet` (WARN-06)
- ✓ Full `mix test --warnings-as-errors` passes in CI with baseline ledger closed. — Phase 68 `full-suite-warning-closure` (WARN-07)
- ✓ CI preserves canonical closeout order with Postgres-free policy job first and full-suite WAE after closeout lanes. — `v2.6` Phase 69 (CI-03)
- ✓ README and support docs use capability-based shipped truth with upgrade-safe install guidance; `adoption_surface_test` guards via `AdopterDocContract`. — Phase 70 (DOCS-03)
- ✓ Maintainer docs clarify semantic lane local-only (not PR CI) and planning-milestone vs Hex semver namespaces. — Phase 70 (DOCS-04)
- ✓ `mix scoria.test.install_contract` runs deep installer contract proofs as maintainer-only task with adoption-lane boundary tests. — Phase 70 (INST-DX-01)
- ✓ First Hex publish at `0.1.0` with git tag `v0.1.0`; release automation runs same test topology as PR CI before publish. — `v2.7` (HEX-01)
- ✓ CHANGELOG, GitHub release, Hex badge, and README install flip to Hex-primary with GitHub tag fallback. — `v2.7` (HEX-02)
- ✓ Semantic fast-path WAE in PR CI after closeout lanes without widening `closeout_order/0`. — `v2.8` (SEM-CI-01)
- ✓ `mix test.knowledge --warnings-as-errors` runs in CI after full-suite WAE. — `v2.8` (CI-KNOW-01)
- ✓ `mix scoria.warning_inventory.check_baseline` enforces empty inventory clusters in CI policy job. — `v2.8` (CI-INV-01)
- ✓ `Scoria.SupportJourney` exposes shared adoption journey identities, handler contracts, seeds, and doc fragments as fixture SSOT. — `v2.9` (JOURN-01)
- ✓ Source contract tests pin `SupportJourney` fragments across overlay, gallery, and adopter docs (multi-surface drift guards). — `v2.9` (JOURN-02, DOCS-GALL-01)
- ✓ Generated-host overlay proves resume and bounded handoff using `SupportJourney` identities. — `v2.9` (HOST-01, HOST-02)
- ✓ `examples/support_copilot/` gallery demonstrates support-copilot domain with LiveView journey tests. — `v2.9` (GALL-01, GALL-02)
- ✓ Advisory `mix scoria.test.support_copilot` runs gallery proof outside `closeout_order/0`; CI ordering contract enforced. — `v2.9` (CI-GALL-01)
- ✓ Generated Phoenix host in `mix test.adoption` consumes Scoria via Hex-shaped tarball dependency and proves full overlay depth (handoff + route + runtime smokes). — Phase 79 (HEX-CONSUMER-01)
- ✓ Same host proves upgrade-safe install after simulated version bump (`--dry-run` / `--check` / apply / migrate). — `v2.10` (HEX-UPGRADE-01)
- ✓ Post-publish workflow proves live Hex fetch + install/migrate/overlay subset; release-blocking upgrade on real semver bump. — `v2.10` (HEX-REGISTRY-01)
- ✓ README, operator verification, and drift guards stay aligned via `HexConsumerContract` / `AdopterDocContract`. — `v2.10` (DOCS-HEX-01)
- ✓ Runtime span events fan out to tenant-scoped PubSub; OrchestratorLive merges live trace deltas and HITL approval pauses from real workflow paths (not test `send/2`). — `v2.11` (ORCH-LIVE-01)
- ✓ Shared `Scoria.SupportJourney.Handlers` used by host overlay and gallery with no duplicated handler logic. — `v2.12` (DEMO-01)
- ✓ Gallery optional lane journeys (semantic, knowledge, connector) with LiveView tests via advisory `mix scoria.test.support_copilot`. — `v2.12` (LANE-01–03)
- ✓ Gallery producer-path orchestrator smoke and honest gallery docs with SupportJourney drift guards. — `v2.12` (ORCH-01, DOCS-01–02)
- ✓ Adopter vs maintainer docs split (`docs/MAINTAINERS.md`); Hex metadata and connector_adoption in package extras. — `v2.13` (DOCS-03, DOCS-04)
- ✓ Maintenance release `0.1.1` prepared with adopter-readable CHANGELOG and release-please manifest. — `v2.14` (HEX-03)
- ✓ Named connector adoption lane `mix test.connector` with VerificationLanes entry, SupportJourney proof, docs truth, and PR CI WAE. — `v2.15` (CONN-LANE-01–03, CONN-DOCS-01–02, CONN-CI-01)
- ✓ ReqLLM peer dependency bumped to `~> 1.13` (1.13.0); orchestrator, judge runner, compaction worker, and observe adapter verified — `v2.16` (DEPS-01–04)
- ✓ Brand book pressure-tested (1,311 lines, 14 sections, 15-dim scorecard, 52-pairing WCAG table, 0 FAIL), decisions locked with user approval, `propagation: not-required` machine-readable verdict. — `v2.17 Vesicle` (BRAND-01, BRAND-02)
- ✓ User chose logo direction from ≥6 programmatic SVG options (2 rounds: TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup); all LOGO-01..07 constraints verified. — `v2.17 Vesicle` (BRAND-03)
- ✓ 8-variant logo set (primary dark/light, mark, monochrome, subtitle, integrated logotype, favicon, social card) with clear-space/min-size spec and optical-correction pass. — `v2.17 Vesicle` (BRAND-04)
- ✓ Self-contained `brandbook/` with tokens.json/css (4-source hex consistency), 543-line canonical brand-book.md, 7 SVG examples, standalone index.html (file:// offline, zero network refs) — 458 KB, zero binaries. — `v2.17 Vesicle` (BRAND-05, BRAND-06)
- ✓ Brand live on real surfaces: README picture-element header, dashboard TV-1 mark + data-URI favicon, mix.exs/GitHub descriptions; quality-gate.mjs 8/8 PASS; mix test 632 green; DS-06 byte-identical (BRAND-09 did not fire). — `v2.17 Vesicle` (BRAND-07, BRAND-08)
- ✓ Operators get a committed dev-only screenshot + LLM-critique evaluation loop and seed data that exercises every dashboard screen. — `v3.0 Control Room` (EVAL-01..05)
- ✓ The design system is fully adopted: shared `ui.ex` components replace hand-rolled markup, with zero raw-palette class leakage enforced by the DS-06 drift guard (verified zero across `lib/scoria_web/`). — `v3.0 Control Room` (DS-01..06, SCREEN-01..04)
- ✓ A newcomer dropped on the dashboard immediately understands what Scoria does and how to reach their job; power users keep a zero-click path (Status Home, three-group nav, breadcrumbs, ⌘K palette, cross-screen threading). — `v3.0 Control Room` (IA-01..06; IA-05 quality-loop threading partial — see Known Gaps)
- ✓ Every screen reaches a consistent high-polish bar in both light and dark themes, with restrained brand-tied motion and mobile-first responsive behavior (22/22 parity smoke). — `v3.0 Control Room` (MOTION-01..04)
- ✓ Redesigned controls and flows are proven operable, readable, and stable across accessibility, motion, and viewport constraints: keyboard focus trap + restore on drawer/modal, axe-core WCAG 2.2 AA assert-zero on all 7 seeded pages (both themes), reduced-motion duration collapse, and a 6-width responsive geometry harness — browser-proven plus browserless source-scan guards. — `v3.3 Design System Stress Test` (A11Y-01, A11Y-02, MOTION-01, RESP-01)
- ✓ Reserved brand-name screens read as complete in the IA via honest "coming soon" stubs (no fake data). — `v3.0 Control Room` (IA-06)
- ✓ The iteration is proven and documented: baseline→final rubric delta, raw-color count zero, before/after contact sheets, MAINTAINERS.md catalog + harness usage. — `v3.0 Control Room` (PROOF-01..03; PROOF-01/02 partial — see Known Gaps)
- ✓ CI cache keys are env-scoped (OS+OTP+Elixir+MIX_ENV+lock) and a `build` job compiles once and ships `_build/test`+`deps` as an artifact every downstream job restores. — `v3.1 CI/CD Velocity` (CACHE-01, CACHE-02)
- ✓ The knowledge verification lane runs only knowledge-tagged tests (`--only knowledge`), not the full suite, with the WAE bar and `mix test.knowledge` contract string unchanged. — `v3.1 CI/CD Velocity` (KNOW-01)
- ✓ Heavy `verify / test` lanes run as parallel `needs:` jobs behind one stable `verify-summary` fan-in; `CI / ci-gate` required-check name unchanged; byte-order/closeout contract tests stay green. — `v3.1 CI/CD Velocity` (PAR-01, PAR-02, PAR-03)
- ✓ The full ExUnit suite shards 4-way via `mix test --partitions 4` across a runner matrix on isolated per-shard DBs with zero coverage loss. — `v3.1 CI/CD Velocity` (SHARD-01)
- ✓ The Postgres host-port bind flake is fixed, the leftover TEMP e2e diagnostic removed, and a deliberate zero-retry-default retry-vs-fix policy documented + contract-guarded. — `v3.1 CI/CD Velocity` (FLAKE-01, FLAKE-02, FLAKE-03)
- ✓ A `mix ci` alias reproduces the merge gate locally, and MAINTAINERS/operator_verification/README describe the parallel topology in contract-guarded lockstep. — `v3.1 CI/CD Velocity` (DX-01, DX-02)
- ✓ Warm-cache PR CI critical-path wall-clock is ≤ ~15 min — MEASURED 7m38s in run 27709716751, down from the ~77 min baseline. — `v3.1 CI/CD Velocity` (VELO-01)
- ✓ Maintainer can start v3.3 from a clean baseline that preserves the recent Scoria UI cleanup as committed prior art. — Phase 36 `baseline-and-inventory` (BASE-01)
- ✓ Maintainer can inspect a current inventory of UI foundations, `ScoriaWeb.UI` primitives, component groups, LiveView pages, CSS/JS hooks, fixtures, tests, and known one-off patterns. — Phase 36 `baseline-and-inventory` (INV-01)
- ✓ Maintainer can see which components and page patterns are canonical, legacy, duplicated, missing, or intentionally page-specific. — Phase 36 `baseline-and-inventory` (INV-02)
- ✓ Maintainer can browse every `ScoriaWeb.UI` primitive and recurring component group across all ten states, six proof viewports, and curated overlay flows in a dev-only lab. — Phase 37 `dev-component-lab-and-stress-fixtures` (LAB-01, LAB-02)
- ✓ Maintainer can stress components with a deterministic fixture matrix (ugly/edge-case data) and inspect the catalog itself. — Phase 37 `dev-component-lab-and-stress-fixtures` (FIXT-01)
- ✓ Operator-facing UI uses semantic tokens, primitive controls are coherent, one shared design-system language spans stats/overlays/evidence/drawers/tables, and approval toasts stay readable over dense UI in both themes — with opaque toast tokens + drift guards for stats/copy/focus/size invariants. — `v3.3 Design System Stress Test` (DS-01, DS-02, DS-03, DS-04)
- ✓ Operator flows are JTBD-first: every page has clear orientation via `page_header/1` (7/7 index pages), consistent scan/IA conventions, a decision-first approval drawer with progressive disclosure, and a Pending|Decided decision-history surface with audit-sourced receipts that never implies in-place reversal. — `v3.3 Design System Stress Test` (FLOW-01, FLOW-02, FLOW-03, FLOW-04)
- ✓ UI copy uses operator-flow language first with technical detail as evidence, sourced from a single copy SSOT — `ScoriaWeb.UI.status_label/1` delegates to `ScoriaWeb.Copy.status_label/1` and `dataset_live` sources labels/titles/version tokens from the wired `Copy`/`DatasetCopy` modules (COPY-01 SSOT closed by Phase 41.1), byte-stable with parity + literal-absence guards. — `v3.3 Design System Stress Test` (COPY-01)
- ✓ The milestone is locked into durable proof: focused ExUnit + Playwright cover lab states/themes/overlays/flows, `docs/design_system.md` (Rule→SSOT→Guard→Example) is CI-policy-lane wired, and drift guards prevent regressions to headers/palette/toasts/stats/copy/icon-buttons/untested-states. — `v3.3 Design System Stress Test` (PROOF-01, PROOF-02, PROOF-03)
- ✓ Eval fails CLOSED: real subject output, real deterministic scoring, `not_scored` verdict semantics, ReleaseGate verdict consultation, and no fake pass/fail online scoring. — `v3.4 Pre-1.0 Trust & Security Hardening` (EVAL-01..05)
- ✓ Knowledge retrieval is tenant-isolated end to end, with tenant/actor/scope audit evidence and fail-closed nil-tenant behavior across public APIs, pgvector, Scrypath, and citations. — `v3.4 Pre-1.0 Trust & Security Hardening` (KNOW-01..04)
- ✓ Dashboard tenant authority is host-asserted: `scoria_dashboard/2` accepts the auth seam, URL tenant values are no longer authoritative, and tenant-owned reads use DashboardScope. — `v3.4 Pre-1.0 Trust & Security Hardening` (AUTH-01..03)
- ✓ Correctness sweep closed real cosine persistence, label-aware citation presence, dead chunker overlap, measured eval latency gates, and scope-doctrine cross-links. — `v3.4 Pre-1.0 Trust & Security Hardening` (FIX-01..04, DOC-01)
- ✓ A Phoenix adopter reads the README first screen and understands Scoria as an embedded Phoenix library for durable, inspectable AI/LLM work before coined vocabulary; persona/not-ours boundaries, the owns-vs-delegates scope table, and an honest hosted-LLM-ops comparison are all present. — `v3.5 Documentation & Release Readiness` (POS-01..04)
- ✓ Adopter docs use the final terminology strategy backed by a committed glossary mapping Scoria terms to industry equivalents; `evidence_refs` RAG/citation storage is preserved (no schema migration), leaked code names are removed, and CHANGELOG carries a pre-1.0 terminology upgrade note. — `v3.5 Documentation & Release Readiness` (TERM-01..04)
- ✓ ExDoc groups modules by domain and extras by an adopter/maintainer guide ladder with version-aware source/ref/doc links; the stable `guides/` tree covers getting-started → golden-path → JTBD → troubleshooting → comparison → cheatsheet, and public moduledocs point at the reorganized paths. — `v3.5 Documentation & Release Readiness` (DOCS-01..03)
- ✓ Public moduledocs and guide links are warning-clean under `mix scoria.release_preview`; curated `llms.txt`/`AGENTS.md` point agents to the facade, guide ladder, glossary, capabilities, and verification suites while distinguishing curated source docs from generated ExDoc artifacts. — `v3.5 Documentation & Release Readiness` (DOCS-04, AI-01, AI-02)
- ✓ The `0.1.3` release was cut only after release-blocking policy/e2e/version drift was fixed: PR #12 reached green `ci-gate`, merged via release-please (tag `v0.1.3`), Hex lists `0.1.3`, and post-publish smoke proved fresh install + `0.1.0 → 0.1.3` live-lineage upgrade. — `v3.5 Documentation & Release Readiness` (REL-01..04)
- ✓ Operators' spans actually persist — the silent `ai_spans.trace_id` FK gap in `Buffer.flush_spans/1` is closed via Ecto.Multi trace-upsert, failures surface via loud telemetry, one shared `SpanKind` whitelist + one version-pinned `Semconv` module are the single origins for `span_kind` and all `gen_ai.*`/`openinference.*` keys, and both adapters emit correct model-config + `span_kind` with legacy keys clean-replaced per CHANGELOG. — `v3.6 Trace Foundation` (FOUND-01..03, SPAN-01..02, COMPAT-01)
- ✓ Retrieval is a linked `RETRIEVER` span dual-written alongside `ai_retrieval_runs` (system-of-record preserved) with `embedding_model`/`index_version`/`reranker` convention keys + consistency guard; host-declared `feature`/`route`/`archetype`/`intent` pass through unmodified; context-pack composition (chunk/memory IDs + token split, never raw text) is captured on the `PROMPT` span. — `v3.6 Trace Foundation` (RETR-01..02, ATTR-01..02)
- ✓ `tool`/`prompt`/`retrieval`/`guardrail` emit as real duration/failure-bearing child spans with `parent_id` linkage on a pipeline that boots under `Scoria.Application`; `ai_span_events` is resurrected via an allow-listed, redaction-safe `emit_event/1` with ordered Buffer flush and two real point-event call sites; all payloads are IDs-and-counts, bounded at a single write-time choke point. — `v3.6 Trace Foundation` (EVENT-01..03, SEC-01)
- ✓ The adopter claim is a version-pinned "OpenInference-compatible" (doc-contract lists updated in the same change) backed by a falsifiable conformance test asserting only allow-listed convention keys + whitelisted `span_kind` across all three adapters. — `v3.6 Trace Foundation` (DOCS-01..02)

### Active

**No milestone is currently scoped** — v3.6 Trace Foundation (SEED-007 · 999.3) shipped 2026-07-19 (16/16 requirements, 6/6 phases, audit `passed`; moved to Validated above). All three adoption-blocking gates are now closed (SEED-006 P0 trust/security in v3.4; SEED-005 docs/positioning + honest `0.1.3` release in v3.5; SEED-007 trace substrate in v3.6), so the roadmap is the ordered feature backlog. Next: `/gsd-new-milestone` to scope SEED-010.

**Next candidates (execution order — see `ROADMAP.md ## Backlog`, refined 2026-07-11):**
- [ ] **SEED-010 — Lethal-Trifecta Governance (999.4) ⭐ flagship — NEXT:** content trust tiers + spotlighting + tool-declared trifecta classification + confluence-escalation policy + moderation/output hooks. Consumes v3.6's taint substrate. No peer ships this as a runtime seam; Scoria is 2/3 built; highest external/positioning payoff.
- [ ] **SEED-008 — Trustworthy Eval Depth (999.5):** real scorer library + regression-comparison + judge calibration + versioned rubric. Reads v3.6 spans. Emits the confusion-matrix/archetype slot 012 reuses.
- [ ] **SEED-012 — Architecture-Archetype Awareness (999.8) — pulled forward** to run immediately after 008 (pure dividend of 007 attrs + 008 machinery).
- [ ] **SEED-009 / SEED-011 (999.6 / 999.7):** independent tracks (retrieval depth; privacy & feedback) — order between them is a priority call.
- [ ] **SEED-013 — Operator IA Pivot (999.9) — split:** early cross-cutting shell (buildable today) + late feature screens that ride their backends.

_(Carried-forward: SEED-004 test-code determinism; FLEET-01/02 cross-repo convergence. Post-ship cleanup todo `ci-policy-job-cache-key-mislabel` and v3.0 verification-doc gaps for Phases 13 & 14 remain optional.)_

### Out of Scope

- Full package-family decomposition into multiple Hex libraries — valuable later, but too wide for the first boring adopter closeout.
- Hosted demo environments or managed onboarding services — gallery is local `examples/` only; no hosted onboarding.
- Adding gallery tests to `mix test.adoption` closeout chain — gallery stays advisory via `mix scoria.test.support_copilot`.
- Broad bounded-handoff example expansion beyond one runtime-to-handoff path — too wide until one canonical example proves useful.
- External semantic cache backends or ANN tuning controls — adjacent capability expansion, not the highest-leverage adoption closure.
- Folding optional knowledge or semantic verification into the default adoption lane — would weaken the clear prerequisite boundary that this milestone is trying to strengthen.
- Net-new runtime capability families — feature-strong; v2.10 is adoption proof only.
- Widening `VerificationLanes.closeout_order/0` for hex proof — tarball consumer proof stays inside existing adoption lane.
- Wallaby/browser CI for hex consumer host — LiveViewTest overlay smokes only.
- A broad installer engine rewrite beyond plan/check + drift-safe apply — too wide for the next milestone's leverage target.
- Connector adoption guides without explicit embedded-boundary framing — risks hosted-connector-platform drift; defer or keep narrow after v2.7.
- Combining `WARN-03` with Hex publish, semantic CI gate, or connector docs in one milestone — dilutes focus; sequence v2.6 then v2.7.
- Combining maintainer-trust work with broad capability expansion in one milestone — dilutes focus; sequence narrowly.

<details>
<summary>v2.8 CI Hardening & Post-Ship Hygiene (shipped 2026-05-29)</summary>

**Delivered:** SEM-CI-01, CI-KNOW-01, CI-INV-01; post-publish smoke fix; operator gate map update.

</details>

<details>
<summary>v2.7 OSS Release + Docs Truth (shipped 2026-05-29)</summary>

**Delivered:** DOCS-03/04, INST-DX-01, HEX-01/02, Hex-primary README, `package_surface_test` flip, `0.1.0` on Hex.

</details>

<details>
<summary>v2.6 Warning Ratchet (shipped 2026-05-28)</summary>

**Goal:** Close full-suite warning debt with staged warnings-as-errors ratchet and executable baseline-expiry policy.

**Delivered:**
- Executable `mix scoria.warning_baseline.check` in CI policy job (WARN-03).
- Classified warning inventory path and maintainer ratchet tasks (WARN-04, WARN-06).
- Green compile, lane-contract, high-signal, and full-suite WAE (WARN-05, WARN-06, WARN-07).
- CI gate map and contract-tested policy→test topology without reordering closeout lanes (CI-03).

**Why it mattered:** Maintainer trust now matches executable CI truth — warning debt cannot silently expire or regress past canonical lanes.

</details>

## Context

- **Latest shipped:** v3.6 Trace Foundation (SEED-007 — closed the silent span-FK gap, semconv key convention over the attributes map, model config, structured child spans + linked RETRIEVER span, `ai_span_events` via `emit_event/1`, write-time IDs-only bounds, honest "OpenInference-compatible" claim + conformance test, boot-attached adapters) — archived 2026-07-19; audit `passed` (16/16, 6/6 phases, 12/12 seams). No Hex publish (convention staged under Unreleased `0.1.4`).
- **Previous shipped:** v3.5 Documentation & Release Readiness (SEED-005 — final terminology + glossary, plain-English README/scope doctrine, grouped version-aware ExDoc guide ladder, curated `llms.txt`/`AGENTS.md`, and the honest `0.1.3` Hex release) — archived 2026-07-11; audit `passed` (18/18, 5/5 phases). Hex `0.1.3` LIVE (tag `v0.1.3`, post-publish attest green).
- **Previous shipped:** v3.4 Pre-1.0 Trust & Security Hardening (SEED-006 P0 gate — eval fail-closed, knowledge tenant isolation, dashboard auth seam, correctness sweep, scope-doctrine proof) — archived 2026-07-09; audit `passed` (17/17). Fix + prove only; no Hex publish.
- **Next up:** planning a feature milestone from `ROADMAP.md ## Backlog` — SEED-010 Lethal-Trifecta Governance (999.4, ⭐ flagship) is the sequenced next candidate, then SEED-008 eval depth (999.5). Scope via `/gsd-new-milestone`.
- v3.3 Design System Stress Test (`/scoria` UI coherence foundation→proof — inventory + Component Lab, tightened primitives/tokens, JTBD operator flows, WCAG 2.2 AA + reduced-motion + 6-width proof, docs/screenshots/drift-guards, COPY-01 SSOT) — archived 2026-07-04; tag `v3.3` local. Audit `passed` (22/22).
- v3.2 Drydock (Docker dev-DX hardening + maintenance release — 4799 default, router-derived banner, docs contract, `0.1.2` live) — archived 2026-06-19; tag `v3.2` pending.
- v3.0 Control Room (dashboard design-system / IA / motion / proof) — archived 2026-06-14; tag `v3.0` local-only.
- v2.17 Vesicle (brand system) — archived 2026-06-11.
- v2.16 ReqLLM peer bump (`~> 1.13`) — archived 2026-05-30.
- v2.15 connector adoption lane (`mix test.connector`) — archived 2026-05-30.
- v2.12–v2.14 shipped 2026-05-30; v2.13/v2.14 bundled with v2.12 closeout pass.
- Hex `0.1.1` prepared locally; `0.1.0` live at https://hex.pm/packages/scoria — publish via release-please.
- CI: policy job (baseline → inventory baseline → compile WAE → lane-contract) → test job (closeout → semantic WAE → ratchet hygiene → full WAE → knowledge WAE → connector WAE → advisory gallery).
- `Scoria.SupportJourney` + `examples/support_copilot/` gallery; advisory `mix scoria.test.support_copilot` outside closeout.
- Archives: `.planning/milestones/v2.17-*`, `v2.16-*`, `v2.15-*`, `v2.11-*`, `v2.10-*`, `v2.9-*`, `v2.8-*`, `v2.7-*`, `v2.6-*`

## Constraints

- **Product shape**: Stay embedded and Phoenix-first — Scoria must remain a library plus dashboard surface, not a hosted connector platform.
- **Runtime boundary**: Keep package and docs concerns inside Mix tasks, tests, and CI lanes instead of pulling Mix project metadata into runtime behavior.
- **DX**: Keep installation and verification boring for a normal Phoenix app path; only ask the user for materially impactful security or blast-radius choices.
- **Support truth**: Default-lane docs, installer output, and proof commands must agree on prerequisites and order of adoption.
- **Optionality**: Default-lane proof must not require pgvector, retrieval, grounding, or semantic fast-path setup.
- **Shift-left defaults**: Push low-impact milestone decisions left inside Scoria and future GSD flows; reserve interruptions for materially consequential product or blast-radius choices.
- **Scope doctrine (build-vs-delegate SSOT, from the 2026-07-03 eval-posture audit)**: *Scoria owns the verb (record, gate, surface, reconstruct); the host owns the noun (identity, business truth, policy value, end-user).* **P1** durable record, not business truth (reference host state by ID). **P2** governance *mechanism* (budgets/breakers/gates/approvals), not policy values — hooks, not opinions. **P3** reviewer/operator surface (`/scoria`), never the end-user surface. **P4** identity/authz delegated by reference, never modeled. **P5** everything persisted is reconstructable in the host's own Postgres/BEAM with zero required egress (anti-SaaS invariant). **P6** prefer BEAM-native primitives (Ecto/Oban/PubSub/OTP/Telemetry); don't re-implement platform infra. Persona strategy (CORE/ADJACENT/NOT-OURS) + full rationale in `.planning/seeds/SEED-005` and `SEED-006`.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| `v1.5` focuses on remote connector productization, not release ops | Connector breadth is the next missing adoption boundary after Keystone; release discipline can layer cleanly afterward | — Resolved |
| Remote connector support is stateless-first by default | This yields real value without forcing stateful session complexity or multi-node surprises into the default milestone path | — Resolved |
| Operator/audit visibility is the primary user-facing outcome | Scoria's differentiator is evidence and governance, not merely "can connect a tool" breadth | — Resolved |
| Browser/code-exec stays out of scope for `v1.5` | It introduces a separate privileged-execution risk class before connector policy and evidence are proven boring | — Resolved |
| `v1.9` should prioritize replayable debugging and online scoring over semantic caching or broad handoff productization | It compounds existing trace/eval/operator surfaces with less platform-drift risk and a clearer Phoenix-first value proposition | — Resolved |
| Online scoring must never auto-mutate sealed baseline datasets | Observed production behavior is not reviewed ground truth; operator trust depends on keeping those lanes separate | — Resolved |
| Post-`v1.9` public handoff work should stay narrow and ship together with docs/install/verification alignment | The real adopter value was a bounded `Scoria` lane with inspectable projected context, not broader orchestration surface area or support-truth drift | — Resolved |
| `v2.0 Relay` should formalize current bounded handoff truth before Scoria opens another net-new capability milestone | The implementation wedge already exists; the remaining risk is proof and support-truth drift, not raw feature absence | — Resolved |
| `v2.1` semantic caching stays Scoria-owned, tenant-partitioned, and evidence-first instead of relying on provider prompt caches or invisible global reuse | Latency wins are only acceptable if partitioning, invalidation, and operator truth remain inspectable | — Resolved |
| Post-`v2.1` milestone selection should prioritize OSS adopter readiness over adjacent capability expansion | The repo is already feature-strong; the main remaining leverage is making package/install/proof surfaces boring for a serious Phoenix adopter | — Resolved |
| Scoria supports the full **architecture ladder** (single-call → structured extraction → workflow/chain → RAG → tool-calling → router → parallelization → evaluator-optimizer → orchestrator-workers → agentic loop → multi-agent) but its **defaults + education are opinionated toward workflows + RAG + tools + gates**; higher-agency patterns are supported, not encouraged (research doc Rule 4 "workflows are underrated", Rule 6 "multi-agent is an optimization not a start"). | The n=1 persona needs bounded, observable, debuggable systems; agency is a cost, not a goal. Source: `.planning/research/ai-architectural-patterns.md`. | — Resolved 2026-07-03 |
| `v2.2` should close the OSS adopter onramp before Scoria reopens broader capability expansion | Publishability, install truth, consumer proof, and support truth are now part of the product surface, not ancillary release chores | — Resolved |
| `v2.3` should clarify the runtime-to-handoff adoption path before adding new capability families | The default onramp was executable in `v2.2`; the next likely support risk was lane escalation and bounded-handoff comprehension | — Resolved |
| `v2.4` should prioritize adoption reliability contracts over net-new capability expansion | Existing lanes already deliver value; highest leverage is keeping docs, CI, warnings, and installer behavior in lock-step truth | — Resolved |
| Next milestone should preserve v2.4 reliability contracts while selecting one focused expansion axis | Reliability contract closure is now shipped; follow-up scope should be narrow and requirement-led | ✓ Good — v2.6 WARN-03 selected |
| Next milestone should prioritize installer safety + upgrade confidence (`INST-03`, `INST-04`) before warning ratchet work | Host-app mutation surprise remains the highest adopter-trust risk after v2.4, and installer contracts are the narrowest high-leverage wedge | ✓ Good — shipped v2.5 |
| `WARN-03` should execute immediately after installer safety milestone closeout | Warning debt remains important, but installer plan/apply + drift contracts are a bigger first-order adoption risk reducer | ✓ Good — shipped v2.6 |
| No new runtime families until `WARN-03` and v2.7 OSS/docs closeout | Repo is ~84% done for embedded scope; highest leverage is warning trust + Hex/docs truth, not capability expansion | ✓ Good — v2.7/v2.8 shipped |
| Milestone sequencing: v2.6 WARN-03 → v2.7 Hex/docs-truth → v2.8 CI hardening | Confirmed by milestone next-step assessment 2026-05-27 | ✓ Good — sequence complete |
| Deferred CI lanes (semantic, knowledge, inventory) land in v2.8 without widening closeout order | Keeps v2.4 lane contract intact while closing maintainer trust gap | ✓ Good — shipped v2.8 |
| v2.9 adopts phased hybrid demo: overlay (merge-blocking) + gallery (advisory) with `SupportJourney` SSOT | Closes adoption confidence gap before real adopters without hosted demo scope creep | ✓ Good — shipped v2.9 |
| v2.10 closes Hex consumer proof with tarball in adoption closeout + registry post-publish gate | Path dep in merge-blocking CI misleads post-Hex adopters; tarball proves packaged artifact | ✓ Good — shipped v2.10 |
| v2.11 closes orchestrator live wiring with producer-path integration proof | Post-Hex adopters need operator UX without hollow LiveView test paths | ✓ Good — shipped v2.11 |
| Phase 01.1 inserted after audit for ORCH-LIVE-01 hardening | Audit found redaction, approval E2E, and token coalesce gaps | ✓ Good — shipped 01.1 |
| Check-time manifest fingerprints are live-host-only; apply-time freshness gate uses stored manifest | Honest operator contract avoids misleading stored-fingerprint merge at check | ✓ Good — shipped Phase 63 |
| v2.15 connector lane as PR WAE after knowledge, not in closeout | Parity with semantic/knowledge lanes; preserve v2.4 closeout contract | ✓ Good — shipped v2.15 |
| v2.16 minimal ReqLLM-only peer bump; no optional szTheory deps | User chose narrow dependency hygiene scope; Tribunal already current | ✓ Good — shipped v2.16 |
| Phase 10.1 inserted after audit for v2.16 VERIFICATION gap | Phases 08–10 shipped without GSD execute artifacts; retroactive ledgers | ✓ Good — shipped 10.1 |
| v2.17 Vesicle interjected before v3.0 phases 13–17 | Brand book never pressure-tested, no logo/collateral exists; clean phase boundary; planning versions decoupled from Hex semver keeps archive chronology aligned | ✓ Good — shipped v2.17 |
| `brandbook/` is canonical brand source; dashboard CSS updated only on material audit failures | Avoids thrash to freshly shipped v3.0 token gateway + DS-06 ratchet | ✓ Good — shipped v2.17; BRAND-09 did not fire |
| v3.0 keeps the token-first scoped CSS; `ui.ex` is the enforced component gateway (no Tailwind/BEM switch); raw palette fails the build via DS-06 ratchet | The token SSOT was sound — the gap was adoption, not the tokens; a build-failing guard makes the win permanent | ✓ Good — shipped v3.0; raw-palette count verified zero |
| v3.0 reserved-name screens with no backend ship as honest "coming soon" stubs, never fake data | "Evidence over intuition" brand voice; fabricated data would erode operator trust | ✓ Good — shipped v3.0; 5 honest stubs |
| Closed v3.0 `gaps_found` rather than reopening Phases 13 & 14 for verification docs | All 10 partials are verification-doc/proof gaps, 0 functionally unsatisfied; cheaper to track as documented tech debt than to block an already-shipped UI milestone | — Pending — Known Gaps recorded; optional retroactive verify-work |
| Next milestone is v3.1 CI/CD Velocity (SEED-003), not a new capability family | Repo is feature-strong; CI wall-clock + reliability is the highest-leverage maintainer-trust axis after the dashboard polish milestone | ✓ Good — shipped v3.1; 77m→7m38s measured, bar preserved |
| v3.1 parallelizes lanes into `needs:` jobs behind one `verify-summary` fan-in rather than reordering/widening `closeout_order/0` | The byte-order lane contract only asserts YAML order, not serial execution — so heavy lanes can fan out safely while keeping the merge bar and the `CI / ci-gate` required-check name byte-stable | ✓ Good — shipped v3.1; contract tests green 51/0, ci-gate name unchanged |
| v3.1 keeps a single fast PR+main gate (no nightly tier) and standard `ubuntu-latest` runners | After parallelization everything fits in ~8 min; a second pipeline or larger runners adds ops/cost without preserving the "nothing demoted" guarantee | ✓ Good — shipped v3.1; nothing demoted |
| Deferred deep test-code async/`Process.sleep` refactor to SEED-004; v3.1 stays infra/docs-only | Async refactor touches 9+ test files (higher product risk); keeping v3.1 to CI infra/docs got the velocity win without that blast radius | — Pending — SEED-004 is the leading next-milestone candidate |
| 2026-07-03 eval-posture audit validated Scoria's direction (Level 3→4, embedded-governance differentiator) and codified the 6-principle scope doctrine (see Constraints) as the build-vs-delegate SSOT | 6-agent adjudication vs peer LLM-ops libs (LangSmith/Langfuse/Phoenix/Ragas/Braintrust/Inspect/OTel) found Scoria correctly aimed but with 3 P0 bugs in shipped 0.1.2 + the flagship differentiator unbuilt; a durable doctrine prevents future scope drift | ✓ Good — SEED-006 shipped in v3.4; SEED-005 and SEED-007..013 remain ordered backlog |
| SEED-006 (P0 trust/security hardening) GATES the next Hex release; lethal-trifecta-as-policy is the flagship differentiator | Fake-green eval + 2 cross-tenant exposures are live in 0.1.2 (must not publish over them); no peer ships trifecta enforcement and Scoria is 2/3 built | ✓ Good — SEED-006 gate shipped in v3.4; lethal-trifecta remains ROADMAP 999.4 |
| 2026-07-03 operator-UI storyboard ingest → adopt `.planning/research/operator-ui-north-star.md` as the UI source-of-record + plant SEED-013 (Operator IA Pivot) as the structural pivot; feature-screens ride their backend seeds. Guardrails: **Feature/archetype/route/env are host-declared attributes Scoria segments by, never modeled/inferred**; **no in-lib LLM diagnosis/opinion** (mechanical signals or host-supplied only); **tighter nav, not the storyboard's 10 sections**; **incremental, not big-bang**. | A blank-slate/maximalist storyboard over-scopes for n=1 and presupposes the unbuilt backlog; ~40% already ships (v3.0 IA spine sound). Doctrine-filtering it to a North-Star doc + one structural seed + annotations prevents scope bloat while capturing the coherence win. | — Pending — ROADMAP ## Backlog 999.9; North-Star doc is the UI source-of-record |
| v3.3 stress-tests the design system as a whole (inventory → dev-only Component Lab → tightened primitives → JTBD flows → a11y/motion/responsive proof → durable guards) rather than continuing one-off page tweaks; the dev lab stays out of the public macro + Hex footprint | The prior UX cleanup was per-page and unproven; a systematic pass with a stress harness + drift guards makes coherence durable and idempotently improving without runtime-surface risk | ✓ Good — shipped v3.3; audit `passed` 22/22, 6/6 seams wired |
| v3.3 milestone audit surfaced a COPY-01 SSOT drift (orphaned `ScoriaWeb.Copy`/`DatasetCopy`); closed it via inserted Phase 41.1 rather than deferring | An unwired copy SSOT invites silent divergence; wiring it byte-stable with parity + literal-absence guards closed the only open audit tech-debt item before close | ✓ Good — shipped 41.1; COPY-01 SSOT closed, re-verified against live code |
| v3.4 (SEED-006) is **fix + prove only** — no Hex publish; the honest `0.1.3` release cut is deferred to SEED-005 (999.2) | The seed's stated order is *SEED-006 → SEED-005 Phase E → publish*; separating the fixes from the release keeps the security milestone focused and lets the docs milestone own the clean-spot/release work | ✓ Good — v3.4 completed without publishing; `0.1.3` PR #12 stays held for SEED-005 |
| v3.4 fixes fail CLOSED and isolate by tenant by **mirroring proven in-repo patterns** (eval reuses `Knowledge.Grounding`+`Eval.Score`; knowledge mirrors `SemanticCache.Lookup.base_query`'s mandatory-tenant raise; dashboard ships an `on_mount:` seam, authz delegated) rather than inventing new machinery | The safe scoping + scoring patterns already exist and are contract-guarded elsewhere; reusing them minimizes blast radius and keeps the P4 "delegate authz, ship the seam" doctrine intact | ✓ Good — implemented and verified in v3.4 |
| v3.5 promotes SEED-005 before any new feature seed | SEED-006 removed the release gate, but the front door and release train are still blocked: Hex is still `0.1.2`, PR #12 is failing deterministic policy/e2e checks, and the README/ExDoc surface still exposes too much lane-era jargon before plain-English positioning. | ✓ Good — shipped v3.5; Hex `0.1.3` live, README/ExDoc/glossary stable, release train green |
| v3.5 keeps `evidence_refs` RAG/citation storage and does the terminology migration as docs + user-visible copy only (no schema migration, no global rename) | The RAG/citation `evidence` sense is correct and load-bearing; a storage rename would be a breaking migration for adopters over a pre-1.0 vocabulary cleanup | ✓ Good — shipped v3.5; `trace_refs` blocked by contract test, `evidence_refs` preserved |
| v3.5 release cut goes through release-please + `0.1.3`, not a hand-published tag; `mix scoria.release_preview` is the canonical warnings-as-errors docs/package gate | Keeps the release train reproducible and the docs/package surface drift-guarded rather than trusting a one-off manual publish | ✓ Good — shipped v3.5; PR #12 → `v0.1.3` → Hex + post-publish attest green |
| v3.5 milestone audit found local `main` had diverged from `origin/main` (missing the `0.1.3` release commit) and Phase 46 lacked a VERIFICATION.md; both closed inline before close rather than deferred | Tagging/archiving a milestone against a branch that predates the release it celebrates would be dishonest; the gaps were mechanically cheap (conflict-free rebase; gsd-verifier corroborated by 19 passing guard tests), so closing beat documenting as debt | ✓ Good — reconciled + verified at v3.5 close; audit `passed` 18/18 |
| Next milestone is v3.6 Trace Foundation (SEED-007), first feature seed after both adoption gates closed | Scorers, eval attribution, and regression detection all read spans, but the trace store is a thin generic 3-table shape (attrs blob, dead `ai_span_events`, only 2 adapters, no model config); it's the foundational substrate 008/010/012/013 consume. Adopt semconv as a naming convention over the existing map (not typed columns / not a schema rewrite) to keep it pre-1.0-migration-free | ✓ Good — shipped v3.6; 16/16 requirements, audit `passed`, convention-over-columns held (zero schema-column additions), boot-attached pipeline live-tested |
| v3.6 adopts the semconv key **convention over the existing `attributes` jsonb map** rather than typed columns, keeps `ai_retrieval_runs` as system-of-record (dual-write the RETRIEVER span, never collapse), bounds all payloads to IDs-and-counts at one write-time choke point, and boot-attaches the ReqLLM/Jido adapters (54.1) so spans persist with zero host hand-wiring | Typed columns invite pre-1.0 migration churn; the table is richer than a span; IDs-only + a closed positive-allowlist registry is the only safe way to bound a key-name-only redactor against PII/cardinality; and an adapter that only tests attach fires into a void in production | ✓ Good — shipped v3.6; conformance test + Bounds registry + boot-attach test all green, milestone-audit integration gap closed by inserted Phase 54.1 |
| v3.6 milestone closed `override_closeout` with one pre-existing test flake deferred rather than blocking the close to fix it | `capture_parity_test.exs:53` flakes only under full-suite `--seed 0` ordering, passes in isolation, and git-confirms as pre-existing (untouched by v3.6) — a SEED-004-class test-determinism item, not a milestone gap; blocking an otherwise-complete, audit-`passed` milestone on unrelated test-harness debt is the wrong trade | — Pending — deferred to SEED-004; recorded in STATE.md Deferred Items |
| Seed execution order refined 2026-07-11 (dividend re-analysis): 007 → 010 → 008 → 012 → {009, 011} → 013; pulled 012 forward after 008; split 013 into early shell + late screens | The 2026-07-03 audit set the base order; a dependency+dividend pass found 012 is cheapest immediately after 008 (reuses its confusion-matrix warm) and 013's cross-cutting shell has no backend dep (build early so feature seeds slot into the frame, avoiding re-slot rework). Recorded in `ROADMAP.md ## Backlog` so it survives context clears | — Pending — recorded in backlog + seeds/README |

## Milestone History

- `v1.0 MVP`: Core observability, MCP governance, operator UX, and evaluation flywheel.
- `v1.1 Caldera`: Durable agent workflows, recovery, and handoffs.
- `v1.2 Corpus`: RAG primitives, citations, grounding, and evidence projection.
- `v1.3 Seismograph`: SRE budgets, breakers, telemetry, audit export, incident delivery, and milestone closeout verification.
- `v1.4 Keystone`: Canonical runtime identity, public runtime API, install defaults, adoption docs, verification backfills, and executable adoption guards.
- `v1.5 Switchyard`: Remote MCP connector registration, stateless-first invocation, operator evidence UX, and curated profiles.
- `v1.6 Flightpath`: Ecto-backed prompt registry, LiveView dataset curation, regression integration, and release gates.
- `v1.7 Outrider`: MCP SSE boundary, asynchronous session compaction engine, and external runtime observability UX.
- `v1.8 Vanguard`: Multi-model fallback orchestration, distributed evaluation fan-out, real-time operator dashboards, and reconciled shipped-state planning truth.
- `v1.9 Crucible`: Replayable debugging, replay-safe execution, workflow-source dataset promotion, and online scoring review queues.
- `v2.0 Relay`: Explicit bounded handoff contract truth, delegated evidence visibility, canonical adoption proof, and clean closeout verification.
- `v2.1 Tenant-scoped semantic fast path`: Tenant-partitioned semantic reuse, compatibility-aware invalidation, operator-visible semantic evidence, and a named semantic proof lane.
- `v2.2 OSS adopter onramp`: Publish-facing package truth, generated-host adoption proof, and canonical lane-based support closure.
- `v2.3 Runtime-to-handoff adoption example`: Default-to-handoff adopter example, operator evidence alignment, canonical runtime-to-handoff proof lane, and closeout ledger.
- `v2.4 Adoption Reliability Contract`: Canonical lane contract source, drift-proof docs checks, warning-policy enforcement, CI lane-order trust, and installer list-form hardening.
- `v2.5 Installer Safety & Upgrade Confidence`: Planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT, Nyquist closeout, and adoption discoverability parity.
- `v2.6 Warning Ratchet`: Executable baseline expiry, classified inventory, staged high-signal ratchet, full-suite WAE in CI, CI-03 gate map and contract tests.
- `v2.7 OSS Release + Docs Truth`: Capability-based docs truth, release-please bootstrap, Hex `0.1.0` publish, README Hex-primary flip.
- `v2.8 CI Hardening & Post-Ship Hygiene`: Semantic/knowledge WAE and inventory baseline gate in PR CI; post-publish smoke fix.
- `v2.9 Adoption Journey & Reference Demo`: SupportJourney SSOT, host-proof overlay expansion, support copilot gallery, advisory CI lane, multi-surface drift guards.
- `v2.10 Hex Consumer Proof & Upgrade Smoke`: Tarball consumer proof, upgrade smoke, registry attest, DOCS-HEX-01 drift guards.
- `v2.11 Orchestrator Live Wiring`: ORCH-LIVE-01 live trace + HITL from runtime; Phase 01.1 hardening slice.
- `v2.15 Connector Adoption Lane`: Named `mix test.connector` lane, SupportJourney proof, docs/CI/drift guards; Phase 07.1 process closeout.
- `v2.17 Vesicle`: Brand system — pressure-tested brand book, programmatically generated logo system (TV-1 mark + LK-B lockup chosen by user), 8-variant logo set, canonical brandbook/ (tokens, brand book, examples, standalone HTML), README/dashboard/Hex integration; quality-gate.mjs 8/8 PASS; BRAND-09 conditional did not fire.
- `v2.16 ReqLLM Peer Bump`: ReqLLM `~> 1.13` peer bump with integration + CI trust verification; Phase 10.1 process closeout.
- `v3.0 Control Room`: Dashboard "insane polish" — fully-adopted `ui.ex` design system with build-failing DS-06 raw-palette guard (verified zero), persona/JTBD IA spine (3-group nav, Status Home, breadcrumbs, ⌘K palette, honest reserved stubs), full screen conversion + thin notebook evidence adapters, brand-tied motion + light/dark WCAG-AA parity, and a committed screenshot+critique evaluation loop. Closed `gaps_found` (10 verification-doc/proof partials, 0 unsatisfied).
- `v3.1 CI/CD Velocity`: Infra/docs CI overhaul (SEED-003) — build-once artifact job, knowledge lane `--only knowledge`, serial→parallel lane fan-out behind one `verify-summary`, 4-way partition sharding, Postgres host-port flake fix + zero-retry policy, and a `mix ci` local-gate alias. PR CI critical path 77m→7m38s MEASURED, bar preserved (`closeout_order/0` byte-stable, `CI / ci-gate` name unchanged, nothing demoted). Audit `passed` (13/13).
- `v3.2 Drydock`: Docker dev-DX hardening + maintenance release (Phases 29–35) — Makefile as single entry point (`PORT ?= 4799`, self-documenting targets, scope-safe cleanup ladder), router-derived launch banner, Docker-DX docs drift guard in the policy lane, and the `0.1.2` Hex release with green post-publish smoke (fresh install + `0.1.0→0.1.2` upgrade). Audit `passed` (14/14).
- `v3.3 Design System Stress Test`: `/scoria` operator-UI coherence foundation→proof (Phases 36–41.1) — design-system inventory baseline, dev-only Component Lab (`/scoria/_lab`, 10 states × 6 viewports × ugly-data, zero macro/Hex footprint), opaque toast tokens + coherent primitives, `page_header/1` adoption across 7 pages, decision-first approval drawer + decision-history surface, domain Copy SSOT, WCAG 2.2 AA assert-zero + focus trap/restore + reduced-motion + 6-width responsive proof, and durable docs/screenshots/drift-guards. COPY-01 SSOT closed by inserted Phase 41.1. Audit `passed` (22/22, 6/6 seams).
- `v3.4 Pre-1.0 Trust & Security Hardening`: SEED-006 P0 gate (Phases 42–45) — eval fails CLOSED (real subject output, real deterministic `ExactMatch` scorer, `not_scored` semantics, ReleaseGate verdict consultation), knowledge retrieval tenant-isolated end-to-end (fail-closed nil-tenant raise, tenant/actor/scope audit evidence), host-injectable dashboard auth seam (`scoria_dashboard/2` `on_mount:` + scope resolver, URL tenant = hint only), and a correctness sweep (real cosine persistence, answerability-aware citations, measured latency gates, scope-doctrine cross-links). Fix + prove only — no Hex publish. Audit `passed` (17/17, 4/4 phases).
- `v3.5 Documentation & Release Readiness`: SEED-005 stable docs + honest release (Phases 46–50) — final glossary-backed terminology across the adopter surface (leaked code names removed, `evidence_refs` preserved), plain-English README front door (n=1 reviewer persona, CORE/ADJACENT/NOT-OURS, owns-vs-delegates table, hosted-LLM-ops comparison), grouped version-aware ExDoc guide ladder + aligned moduledocs, curated `llms.txt`/`AGENTS.md` AI-nav + `mix scoria.release_preview` warnings-as-errors gate, and the honest **`0.1.3` Hex release** (PR #12 → release-please `v0.1.3` → Hex live → post-publish attest proving fresh install + `0.1.0 → 0.1.3` upgrade). Audit `passed` (18/18, 5/5 phases, 5/5 seams) after inline closure of release-train branch drift + a Phase 46 verification-doc gap.
- `v3.6 Trace Foundation`: SEED-007 OTel-GenAI/OpenInference trace substrate (Phases 51–54.1) — closed the pre-existing silent FK gap that swallowed every span (`Buffer` Ecto.Multi trace-upsert + loud flush-error telemetry, pipeline boots under `Scoria.Application`); a naming **convention over the existing `attributes` map** (no typed columns) with `SpanKind`(8-value) + version-pinned `Semconv` as single key origins, model-config capture, `tool`/`prompt`/`retrieval`/`guardrail` as real child spans with `parent_id`, a linked `RETRIEVER` span dual-written alongside `ai_retrieval_runs`, host-declared `feature`/`route`/`archetype`/`intent`, `ai_span_events` resurrected via allow-listed redaction-safe `emit_event/1`, all payloads IDs-and-counts bounded at one write-time choke point (`Observe.Bounds`), and an honest version-pinned "OpenInference-compatible" claim backed by a falsifiable conformance test + boot-attached ReqLLM/Jido adapters. No Hex publish (convention change staged under Unreleased `0.1.4`). Audit `passed` (16/16, 6/6 phases, 12/12 seams, 1/1 E2E); closed `override_closeout` with one pre-existing SEED-004-class test flake deferred. Inserted Phase 54.1 closed the audit-found adapter boot-attach integration gap.

## Archived Planning Notes

<details>
<summary>Pre-ship v2.11 framing</summary>

`v2.11` wired orchestrator live trace broadcast and HITL from real runtime/workflow events. Phase 01.1 inserted after audit for redaction, approval E2E, and token coalesce hardening. Archived in `.planning/milestones/v2.11-ROADMAP.md`, `.planning/milestones/v2.11-REQUIREMENTS.md`, and `.planning/milestones/v2.11-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.9 framing</summary>

`v2.9` battle-tested adoption through support-copilot domain: overlay merge-blocking, gallery advisory, `SupportJourney` spine. Archived in `.planning/milestones/v2.9-ROADMAP.md`, `.planning/milestones/v2.9-REQUIREMENTS.md`, and `.planning/milestones/v2.9-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.8 framing</summary>

`v2.8` closed deferred SEM-CI-01, CI-KNOW-01, and CI-INV-01 without widening `closeout_order/0`. Archived in `.planning/milestones/v2.8-ROADMAP.md`, `.planning/milestones/v2.8-REQUIREMENTS.md`, and `.planning/milestones/v2.8-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.6 framing</summary>

`v2.6` closed warning debt with policy→test CI topology, inventory/ratchet maintainer paths, and full-suite WAE without changing closeout lane order. Archived in `.planning/milestones/v2.6-ROADMAP.md`, `.planning/milestones/v2.6-REQUIREMENTS.md`, and `.planning/milestones/v2.6-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.5 framing</summary>

`v2.5` focused on installer mutation confidence: no-write planner/check, manifest-aware drift classification, truthful idempotent apply, and audit gap closure (Nyquist, manifest fingerprint, adoption discoverability). Archived in `.planning/milestones/v2.5-ROADMAP.md`, `.planning/milestones/v2.5-REQUIREMENTS.md`, and `.planning/milestones/v2.5-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>Pre-ship v2.2 framing</summary>

`v2.2` focused on turning Scoria's post-`v2.1` repo truth into a public adoption story: publishable Hex metadata, a real docs-build lane, a truthful installer contract, fresh-host proof, and lane-based support wording. That milestone is now shipped and archived in `.planning/milestones/v2.2-ROADMAP.md` and `.planning/milestones/v2.2-REQUIREMENTS.md`.

</details>

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-19 after v3.6 Trace Foundation milestone completion — trace substrate shipped (6/6 phases, 16/16 requirements, audit `passed`); next candidate SEED-010 Lethal-Trifecta Governance.*
