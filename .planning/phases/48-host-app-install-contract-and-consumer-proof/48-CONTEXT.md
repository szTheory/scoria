# Phase 48: Host-app install contract and consumer proof - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove that a fresh Phoenix host app can adopt Scoria's default lane through the public package, installer, migration, runtime, and operator-visibility path without relying on optional Tailwind, knowledge, or semantic-fast-path surfaces.

Phase 48 owns the installer contract, the host-app proof harness, the default-lane runtime proof, and truthful optional-surface handling for the default adoption path. It does not yet own the full docs/support-language reconciliation across every lane; that belongs to Phase 49.

</domain>

<decisions>
## Implementation Decisions

### Installer contract
- **D-01:** `mix scoria.install` remains Scoria's canonical one-command installer for the default Phoenix lane. Scoria should not fall back to a docs-only/manual-first install path for the primary adopter story.
- **D-02:** The installer contract should stay explicit and host-owned: patch the host router to mount `scoria_dashboard "/scoria"`, copy core migrations into the host app, inject baseline runtime defaults once, and patch Tailwind only when a Tailwind config exists.
- **D-03:** The installer should be hardened rather than widened in Phase 48: idempotency, duplicate prevention, explicit mutation reporting, and truthful fallback/manual guidance for nonstandard host layouts matter more than switching to a heavier installer framework now.
- **D-04:** Copied host-local migrations remain the default-lane posture in Phase 48. Scoria should not introduce a migration-helper abstraction or dependency-path migration contract yet; upgrade-oriented migration abstractions are a later concern.

### Consumer proof harness
- **D-05:** The canonical consumer proof should start from a fresh generated Phoenix app, not a large checked-in dummy host app.
- **D-06:** The recommended proof shape is a hybrid generated-host harness: create a fresh Phoenix app, apply a tiny bounded Scoria patch/template layer, then prove `deps.get`, `mix scoria.install`, `mix ecto.migrate`, and `/scoria` route visibility.
- **D-07:** The generated-host harness must stay deliberately small and Phoenix-version-pinned. It is a proof harness for public adoption truth, not a second long-lived sample application.

### Default-lane proof orchestration
- **D-08:** Scoria should expose one canonical default-lane verification command for adopters and maintainers, but implement it as layered focused proofs under the hood rather than one monolithic end-to-end test.
- **D-09:** The layered proof should combine:
  dependency fetch and host-app install/migrate/route smoke from the generated host harness,
  installer mutation/idempotency tests,
  migration-lane compatibility proof,
  and the existing public runtime/operator-evidence proof around `Scoria.start_run/2`, readback, and workflow visibility.
- **D-10:** The generated-host proof only needs bounded adoption assertions. Deep runtime semantics remain owned by Scoria's existing repo-internal runtime integration and adoption tests rather than being duplicated inside the host harness.

### Optional surfaces and lane messaging
- **D-11:** The installer and proof surfaces must treat Tailwind, knowledge, and semantic-fast-path setup as optional lanes, not hidden prerequisites for the default lane.
- **D-12:** `mix scoria.install` should print a compact lane inventory with three truths:
  what it installed,
  what it intentionally skipped,
  and what remains optional by lane.
- **D-13:** Missing Tailwind should produce explicit "skipped intentionally; default lane still installable" messaging, not silent omission and not a failure.
- **D-14:** Knowledge and semantic-fast-path surfaces should be named as later optional lanes with their own commands. Default-lane output should not imply that adopters must enable pgvector, retrieval, or semantic caching before Scoria is usable.

### Shift-left defaults for GSD
- **D-15:** Future GSD discuss/planning for adoption-path work should treat the following as locked defaults unless a later milestone changes product shape, blast radius, or support posture:
  keep the one-command installer shape,
  keep host-owned copied migrations for the default lane,
  prefer a fresh generated-host proof over a checked-in sample app,
  prefer one canonical umbrella verifier implemented as layered focused checks,
  and make optional surfaces explicit instead of silently assumed.

### the agent's Discretion
- Exact implementation technique for hardening the installer in Phase 48, including whether to stay regex-based with tighter guards or adopt a more semantic patching helper, as long as the public contract above stays unchanged.
- Exact naming and file layout of the generated-host proof harness and any helper scripts/templates.
- Exact composition of the canonical default-lane verification task, as long as adopters get one boring command and the layered seams remain bounded and debuggable.
- Exact wording of the compact lane inventory, as long as installed/skipped/optional truth stays explicit and consistent.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 48 goal, four plan slots, success criteria, and the dependency on Phase 47.
- `.planning/PROJECT.md` — `v2.2 OSS adopter onramp` posture: embedded Phoenix-first adoption, boring installer ergonomics, and default-lane support truth.
- `.planning/REQUIREMENTS.md` — authoritative wording for `INST-01`, `INST-02`, `PROOF-01`, and `PROOF-02`.
- `.planning/STATE.md` — current milestone state and the note that Phase 48 planning is next.
- `.planning/METHODOLOGY.md` — decisive-defaults lens; low-impact adopter/DX choices should be shifted left unless they change product shape or blast radius.

### Existing install and proof surfaces
- `lib/mix/tasks/scoria.install.ex` — current installer behavior, fallback handling, and next-step messaging.
- `test/mix/tasks/scoria.install_test.exs` — current idempotency, copied-migration, runtime-config, and Tailwind-absent proof seam.
- `test/mix/tasks/scoria.install_route_smoke_test.exs` — current route-resolution smoke after installer mutation.
- `lib/mix/tasks/test.adoption.ex` — existing named default-lane verifier wrapper to extend rather than replace.
- `test/mix/tasks/test.adoption_test.exs` — current discovery/coverage contract for the adoption task.
- `test/scoria/runtime_integration_test.exs` — public runtime, resume, and workflow evidence proof seam.
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` — current default-lane versus optional-knowledge migration boundary proof.
- `lib/mix/tasks/scoria.test.semantic_fast_path.ex` — optional semantic-fast-path lane contract and naming precedent.
- `lib/mix/tasks/scoria.test.knowledge.ex` — optional knowledge/full verification lane contract and naming precedent.

### Adopter-facing docs and support truth
- `README.md` — current install story, lane ordering, runtime example, and optional-lane messaging that Phase 48 must keep coherent enough for the host proof.
- `docs/adoption_lanes.md` — lane vocabulary and current ordering across default, semantic, and optional knowledge surfaces.
- `docs/operator_verification.md` — default-lane operator verification story and current command vocabulary.
- `docs/phoenix_runtime_example.md` — current Phoenix-hosted runtime example that the generated host proof should stay close to.
- `docs/semantic_fast_path.md` — explicit optional semantic lane and its dedicated verifier, relevant so default-lane proof does not absorb it accidentally.

### Research and product posture
- `.planning/research/elixir-ai-ecosystem.md` — Scoria's embedded Phoenix-first product boundary and operator-first OSS posture.
- `.planning/research/agentcore-lessons.md` — lessons about explicit session/tool boundaries and avoiding hidden platform drift.
- `prompts/phoenix-ai-lib-deep-research.md` — broader ecosystem/product-shape guidance for a Phoenix-native AI ops library.
- `prompts/scoria-brand-book-deep-research.md` — brand and UX posture: calm, explicit, evidence-based, not magical.
- `prompts/scoria-gsd-kickoff.md` — batteries-included installer and operator-first project objective.
- `prompts/sztheory-elixir-dna.md` — zero-config onboarding, embedded LiveView dashboard, Ecto-native truth, and operator-first DX principles.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Scoria.Install`: already owns router, Tailwind, migration, and config mutation logic; it should remain the public installer seam.
- `Mix.Tasks.Scoria.Test.Adoption`: already gives Scoria a named bounded default-lane verifier and is the right place to preserve one canonical human-facing command.
- `Scoria.RuntimeIntegrationTest`: already proves `Scoria.start_run/2`, resume/readback behavior, and `/scoria/workflows/:run_id` visibility without requiring an external host app.
- `Scoria.TestSupport.Migrations`: already provides migration helpers and default-versus-knowledge lane proof support.
- Existing docs/source tests under `test/scoria/*source*_test.exs` and `test/scoria/adoption_surface_test.exs`: already enforce support-truth wording and should be extended rather than bypassed.

### Established Patterns
- Embedded LiveView/dashboard surfaces are mounted by router imports/macros under the host app's browser pipeline.
- Named Mix verification tasks are Scoria's preferred support-truth mechanism over vague prose or broad full-suite advice.
- Optional lanes are separated into their own commands rather than silently folded into the default path.
- Durable Ecto truth and host-visible migrations are preferred over hidden runtime setup.
- Adoption-facing behavior is proven with bounded tests plus explicit docs, not with a large permanent demo app.

### Integration Points
- Installer hardening work centers on `lib/mix/tasks/scoria.install.ex` and its tests.
- Generated-host consumer proof should connect to the existing `mix test.adoption` lane rather than inventing a second canonical verifier.
- Runtime-proof extensions should reuse `test/scoria/runtime_integration_test.exs` and related public-runtime seams instead of re-implementing runtime logic inside the host harness.
- Messaging changes must stay aligned across installer output, `README.md`, `docs/adoption_lanes.md`, and `docs/operator_verification.md`.

</code_context>

<specifics>
## Specific Ideas

- The default adopter story should feel like: add the dependency, run `mix scoria.install`, run `mix ecto.migrate`, run one canonical verification command, then visit `/scoria`.
- The generated-host proof should behave like a field check, not an application template: fresh Phoenix app, tiny pinned patch, bounded smoke, then hand off to Scoria's internal runtime assertions.
- The installer output should read like a calm checklist:
  installed,
  skipped intentionally,
  optional next lanes.
- Low-impact adopter-path choices should be shifted left inside GSD so future planning does not reopen them unless Scoria's public product boundary materially changes.

</specifics>

<deferred>
## Deferred Ideas

- Moving from copied host migrations to a library-owned migration-helper/version contract — valuable for future upgrade ergonomics, but broader than the first default-lane consumer proof.
- Replacing the installer with a full Igniter-based semantic codemod framework — potentially attractive later if Scoria accumulates more installer and upgrader mutations.
- Expanding the generated-host harness into a full long-lived sample app — would increase maintenance surface and drift risk without improving the Phase 48 proof goal enough.
- Full docs/support-language reconciliation across every lane — Phase 49 owns the final convergence of installer, README, verification, and support wording.

</deferred>

---

*Phase: 48-host-app-install-contract-and-consumer-proof*
*Context gathered: 2026-05-25*
