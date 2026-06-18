# Phase 33: Doc restructure + verification-copy correction - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase turns `docs/docker_dev_dx.md` into the readable reference fleet standard for Scoria local development, then corrects stale dev-start verification copy that still points maintainers or agents at `mix phx.server` -> `http://localhost:4000/scoria`.

The implementation should assemble the completed Stream A work from Phases 29-32 into one coherent docs truth:

- `make dev` uses native `PORT ?= 4799` and the native pgvector helper.
- Docker remains Traefik-routed at `http://<instance>.localhost/scoria`; container `:4000` is internal.
- `docs/docker_dev_dx.md` already contains layer-cache and Secrets material, but needs a front-to-back information architecture pass.
- Stale verification copy should be corrected in active docs, current planning prose, and user-facing dev-harness copy.

Out of scope: new drift-guard tests (Phase 34), release work (Phase 35), sibling-repo migration, proxy bake-offs, changing Docker-internal `:4000` wiring, changing `config/dev.exs` fallback, or rewriting archived milestone history.

</domain>

<decisions>
## Implementation Decisions

Calibration: the user selected all gray areas and asked for subagent-backed research, ecosystem comparison, pros/cons, footguns, and one cohesive recommendation set. Five `gsd-advisor-researcher` agents researched document IA, `.planning` sweep boundary, command wording, adjacent docs, and prompt/brand voice. Decisions below are LOCKED.

### Document IA and emphasis
- **D-01:** Rewrite `docs/docker_dev_dx.md` as a **guided reference narrative**, not a troubleshooting-only page and not an architecture-first design memo. The order should be: persona/JTBD -> TL;DR gameplan -> short mental model -> task sections -> appendices.
- **D-02:** The top of the doc must make the reader and job explicit: a solo maintainer running many Phoenix/Elixir library demos on one Mac wants a hands-off, port-conflict-free loop. This is the reason for Traefik, per-instance Compose names, unpublished DB ports, native `4799`, `make fleet`, `make doctor`, and scoped cleanup.
- **D-03:** Preserve the strongest existing content, but change the emphasis. Keep the multi-instance model, layer-cache table, process-scoped 1Password/direnv secrets pattern, and adoption appendix. Move stale-instance hygiene out of buried multi-instance prose into its own readable section.
- **D-04:** Required standalone sections in `docs/docker_dev_dx.md`: Docker daily loop, Native dev server, Caching guarantees, Secrets, Stale instance hygiene. Each section should be digestible alone using this pattern: when to use it -> commands -> expected URL/output -> footguns -> recovery.
- **D-05:** Put returning-maintainer commands up front without losing the why. The doc should be fast to scan like successful framework quickstarts, but still teach the invariant that avoids future drift: user-facing browser URLs are Traefik `*.localhost` or native `localhost:4799`; Docker container `:4000` is not the browser start URL.

### Command wording pattern
- **D-06:** Use **context-specific wording** as the canonical replacement pattern. Docker-first is the default for "run the Scoria repo dashboard"; native-first is only for host Mix iteration, screenshots, Playwright/e2e, or other tasks that explicitly require the BEAM running on the host.
- **D-07:** Canonical Scoria repo dashboard wording:
  ```text
  Run `make proxy` once, `make up-build` on first run, then `make up`.
  Use `make url` or `make open` and open the printed `http://<instance>.localhost/scoria` URL.
  ```
- **D-08:** Canonical native host wording:
  ```text
  Run `make dev` and open `http://localhost:4799/scoria`.
  ```
  If useful, add that `make dev PORT=5000` is supported and prints the matching URL.
- **D-09:** Canonical maintainer screenshot/e2e wording:
  ```text
  Start the dashboard with `make dev`, then run:
  `mix scoria.ui.shots --url http://localhost:4799/scoria`
  `mix scoria.ui.e2e --base-url http://localhost:4799/scoria`
  ```
- **D-10:** Canonical GSD/planning wording:
  ```text
  Verify with Docker: `make up` -> `make url` -> `http://<instance>.localhost/scoria`.
  Verify native: `make dev` -> `http://localhost:4799/scoria`.
  ```
- **D-11:** Never present `http://localhost:4000/scoria` as a Scoria browser dev-start URL. If `:4000` appears, it must be explicitly qualified as Docker-internal container listener, Traefik service target, CI self-test port, or ephemeral loopback mechanism.

### Verification-copy sweep boundary
- **D-12:** Use an **active/current sweep with explicit archive exclusions**, not a blanket `.planning` rewrite. Correct current docs and current planning instructions. Preserve `.planning/milestones/**` and old shipped audit artifacts as historical records.
- **D-13:** Include in the active sweep: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/research/**`, pending todos, and active `.planning/phases/**` files where they give current verification/how-to-start instructions or handoff notes.
- **D-14:** Exclude archived or historical evidence from the failure gate: `.planning/milestones/**`, top-level old `v*-MILESTONE-AUDIT.md` files, `.planning/debug/**`, `.planning/memory/**`, and `.planning/todos/completed/**`. These may be inventoried as historical hits, but Phase 33 should not mutate them.
- **D-15:** Do not rewrite correct implementation evidence such as `PORT=$(PORT) mix phx.server` in Phase 29/30 artifacts when it describes what `make dev` does internally. The stale-copy target is user-facing "start/open/visit/verify at localhost:4000" guidance, not every literal occurrence of `mix phx.server`.

### Docs and code-adjacent surfaces
- **D-16:** At minimum, update the named Phase 33 docs: `README.md`, `docs/operator_verification.md`, and `docs/MAINTAINERS.md`.
- **D-17:** Also include `docs/uat_automation.md`; Phase 29 explicitly deferred this doc to Phase 33 and it still instructs direct `mix phx.server` / `PORT=4010` for the Scoria dashboard. Replace with `make dev` and `http://localhost:4799/scoria`.
- **D-18:** Include `docs/support_copilot_gallery.md`, but do **not** blindly replace the gallery app's `mix phx.server`. The support-copilot gallery is a separate Phoenix app configured for `http://localhost:4010`; keep its command and qualify the URLs explicitly as gallery-app URLs (`http://localhost:4010/` and `http://localhost:4010/scoria`).
- **D-19:** Include user-facing dev-harness copy/defaults that Phase 29 parked under DOCS: `lib/mix/tasks/scoria.ui.shots.ex`, `lib/mix/tasks/scoria.ui.e2e.ex`, `priv/dev/shots.mjs`, `priv/dev/e2e/*.spec.mjs`, and `priv/repo/dev_seed.exs` when they present Scoria dashboard URLs or start instructions. Preferred default URL for host harnesses is `http://localhost:4799/scoria`.
- **D-20:** Do not edit generated `priv/static/scoria/app.js` just because it contains bundled strings. Do not change Docker Compose service ports, Traefik labels, `Dockerfile.dev EXPOSE 4000`, CI `PORT: 4000`, or `config/dev.exs` runtime fallback.

### Voice and UX constraints
- **D-21:** `brandbook/` is canonical for voice and docs style. `prompts/` are supporting DNA only.
- **D-22:** Write in Scoria's voice: calm, exact, useful. Lead with concrete commands, URLs, expected output, failure mode, and recovery. Avoid "seamless", "magic", "powerful", "just works", and any copy that hides the mechanism.
- **D-23:** Use operator-first nouns: instance, route, proxy, fallback, native DB, cache, secret, scope. Do not shame the reader for prior wrong commands; state what changed and what is canonical now.
- **D-24:** For destructive commands, always show scope. `make nuke` is allowed only as scoped instance cleanup, not as a vague "if things are weird" fix. Do not introduce `docker system prune`, `docker volume prune`, or a fleet-wide nuke target.
- **D-25:** Docs accessibility rules apply if any rendered docs/HTML examples are touched: meaningful link text, code blocks for copy-pasteable commands, visible text labels for status/warnings, no color-only status, and brandbook contrast/focus constraints.

### Verification recommendations
- **D-26:** Recommended active-doc checks:
  ```bash
  rg -n "localhost:4000|mix phx\\.server" README.md docs/operator_verification.md docs/MAINTAINERS.md docs/uat_automation.md
  rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" docs/uat_automation.md docs/support_copilot_gallery.md
  ```
  `docs/support_copilot_gallery.md` may still contain `mix phx.server` if it is clearly the gallery app startup, not Scoria repo dashboard startup.
- **D-27:** Recommended active-planning check:
  ```bash
  rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
    -g '!milestones/**' \
    -g '!v*-MILESTONE-AUDIT.md' \
    -g '!debug/**' \
    -g '!memory/**' \
    -g '!todos/completed/**'
  ```
  Then classify remaining hits as implementation evidence, current stale instruction, or quoted historical rationale.
- **D-28:** Recommended dev-harness checks:
  ```bash
  rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs
  make -n dev
  ```
- **D-29:** Recommended regression tests after implementation, selected by touched surfaces: `mix test test/scoria/ci_policy_contract_test.exs`, `mix test test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs`, and any existing docs/source-contract test that guards README/operator/maintainer copy.

### Folded Todos
- **docker-dx-fleet-hardening.md:** Fold the doc/plan drift item and docs-reader-empathy requirement into Phase 33. The folded problem: stale GSD plans/agents/docs told verifiers to run `mix phx.server` -> `http://localhost:4000/scoria`, which is wrong for Scoria's fleet-routed dev model. Phase 33 corrects that copy and turns `docs/docker_dev_dx.md` into the portable standard.

### Claude's Discretion
- Exact prose, section titles, and command comments may be refined as long as D-01 through D-29 hold.
- The planner may decide whether to do the code-adjacent dev-harness copy/default updates in the same plan or a second plan, but they should remain part of Phase 33 unless a blocking risk appears.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 33: Doc restructure + verification-copy correction" - phase goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` - DOCS-01 and DOCS-02 are the locked requirements for this phase; DOCS-03 belongs to Phase 34.
- `.planning/PROJECT.md` section "Current Milestone: v3.2 Drydock" - milestone boundary and Scoria-only Docker dev-DX scope.
- `.planning/STATE.md` - current position, recent decisions, and Phase 33 pending todo.

### Carried-forward decisions
- `.planning/phases/29-makefile-hardening/29-CONTEXT.md` - `PORT ?= 4799` is Makefile-only; Docker internals stay on `:4000`; mix-task default URL/docs copy correction is Phase 33.
- `.planning/phases/30-launch-banner-native-dev-notice/30-CONTEXT.md` - `make dev` echo, live-derived Docker banner route list, Traefik admin link, and native notice are already handled; Phase 34 owns parity tests.
- `.planning/phases/31-dockerfile-caching-audit-doc/31-CONTEXT.md` - layer-cache section/table is already researched; keep CSS-vs-HEEx truth and cold `make up-build` scope.
- `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md` - Secrets section uses process-scoped `op run --env-file`; keep `.env` non-secret boundary and no token material.

### Target docs and source surfaces
- `docs/docker_dev_dx.md` - primary rewrite target and Phase 34 doc-contract input.
- `README.md` - stale local demo/dev-start copy under support-copilot gallery section.
- `docs/operator_verification.md` - stale dev-start copy in operator verification docs.
- `docs/MAINTAINERS.md` - screenshot/critique harness instructions and stale default URL.
- `docs/uat_automation.md` - browser UAT local-run instructions; should use `make dev` / `localhost:4799`.
- `docs/support_copilot_gallery.md` - gallery app quickstart; qualify its separate `localhost:4010` app.
- `lib/mix/tasks/scoria.ui.shots.ex` - user-facing task docs/default URL for screenshot harness.
- `lib/mix/tasks/scoria.ui.e2e.ex` - user-facing task docs/default URL for Playwright harness.
- `priv/dev/shots.mjs` - script-level default URL and usage comments.
- `priv/dev/e2e/*.spec.mjs` and `priv/dev/e2e/playwright.config.mjs` - browser harness default URL/comments.
- `priv/repo/dev_seed.exs` - printed post-seed URL.

### Runtime and command truth
- `Makefile` - canonical `proxy`, `up-build`, `up`, `url`, `open`, `fleet`, `doctor`, `dev`, `shots-native`, and cleanup target behavior.
- `compose.yml` - Docker web service uses Traefik, unpublished DB, ephemeral loopback fallback, and internal service port `4000`.
- `docker/dev-entrypoint.sh` - Docker banner route list and native-dev notice.
- `config/dev.exs` - runtime fallback `"4000"` is deliberately preserved for container/Traefik; do not change.
- `dev/dev_endpoint.ex` and `dev/dev_router.ex` - native dev harness surface served through `make dev`.
- `examples/support_copilot/config/dev.exs` - gallery app uses its own port; do not confuse this with Scoria repo dashboard startup.

### Voice, brand, and project DNA
- `brandbook/brand-book.md` - canonical voice, microcopy, docs/UI guidance, accessibility constraints.
- `brandbook/README.md` - current brandbook source priority and defaults.
- `prompts/sztheory-elixir-dna.md` - supporting Operator-First DX and batteries-included/composable philosophy.
- `prompts/scoria-brand-book-deep-research.md` - supporting historical brand and voice research; subordinate to `brandbook/`.
- `prompts/phoenix-ai-lib-deep-research.md` - supporting Phoenix-native library/product vision.

### Folded and reviewed todos
- `.planning/todos/pending/docker-dx-fleet-hardening.md` - folded doc/plan drift and reader-empathy items into Phase 33; fleet convergence remains deferred.
- `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md` - reviewed and deferred; unrelated to documentation restructure and dev-start copy truth.

### External primary references used during discussion
- `https://diataxis.fr/` - documentation IA lens: tutorial/how-to/reference/explanation; supports guided reference structure.
- `https://developers.google.com/style` - developer docs style reference; project-specific style takes precedence, clarity and consistency matter.
- `https://docs.docker.com/compose/how-tos/project-name/` - Compose project names isolate multiple local environments.
- `https://docs.docker.com/compose/how-tos/networking/` - Compose service-name networking and per-project default networks.
- `https://docs.docker.com/reference/compose-file/services/#expose` - internal ports are distinct from published host ports.
- `https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/` - Compose interpolation and environment precedence.
- `https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Server.html` - `mix phx.server` starts endpoints by setting server behavior; explains why Makefile wrapping remains Phoenix-idiomatic.
- `https://phoenix.hexdocs.pm/Phoenix.Endpoint.html` - Phoenix endpoint runtime config and URL/host/port semantics.
- `https://mix.hexdocs.pm/Mix.Project.html` - Mix CLI/default task conventions; supports command wrappers and project-specific task docs.
- `https://nextjs.org/docs` and `https://nextjs.org/docs/app/getting-started/installation` - successful framework docs pattern: quick start first, guides/reference split, concrete dev server commands.
- `https://guides.rubyonrails.org/` - successful framework guide pattern: make readers productive and explain how pieces fit together.
- `https://vite.dev/guide/` - successful dev-tool docs pattern: simple `dev/build/preview` script surface and explicit dev server command.
- `https://www.1password.dev/cli/secret-references` and `https://www.1password.dev/cli/reference/commands/run` - secret references and `op run --env-file` behavior already adopted in Phase 32.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/docker_dev_dx.md` already contains correct raw material: TL;DR, Traefik model, multi-instance identity, native dev, cache table, Secrets, adoption appendix, Safari/dnsmasq note, and file-role table.
- `Makefile` is the command SSOT. It already exposes `proxy`, `up-build`, `up`, `url`, `open`, `fleet`, `doctor`, `dev`, `shots-native`, `clean`, `down`, and `nuke`.
- `docker/dev-entrypoint.sh` already prints the Docker banner, route list, Traefik link, and native-dev notice from Phase 30.
- `test/scoria/ci_policy_contract_test.exs` is the existing policy-lane contract-test home for fast no-DB doc/config invariants; Phase 34 will likely extend or complement it.
- Existing source-contract tests (`package_surface_test`, support-journey source tests) may catch README/docs drift depending on touched docs.

### Established Patterns
- Scoria favors copy-pasteable commands over prose-only guidance.
- Drift resistance favors dynamic truth (`make url`, derived route list, Makefile variables) over hardcoded examples.
- Docker-internal `:4000` is deliberate and must not be "fixed" to `4799`.
- Native 4799 is a Makefile policy, not a Phoenix endpoint global default.
- Archived milestone artifacts are historical records; active planning instructions are living docs.
- Brand voice is practical and evidence-based: no hype, no vague success/failure copy, no "AI magic" framing.

### Integration Points
- Phase 33 produces the final doc strings Phase 34 will pin mechanically.
- `docs/docker_dev_dx.md` must remain the reference standard for future sibling-repo migration, without performing that migration now.
- README/operator/maintainer docs must point readers to the right local-dev doc and avoid sending them to stale `localhost:4000`.
- Browser/screenshot/e2e harness docs and defaults should line up with `make dev` / `localhost:4799`.
- The support-copilot gallery remains a separate example Phoenix app; its startup copy should be explicit, not normalized to Scoria repo Docker commands.

</code_context>

<specifics>
## Specific Ideas

- Recommended `docs/docker_dev_dx.md` opening:
  ```text
  This guide is for the maintainer running several Phoenix/Elixir demo repos on one Mac. The goal is one predictable Scoria dashboard URL, no `:4000`/`:5432` port juggling, and scoped cleanup when an old instance gets in the way.
  ```
- Recommended stale-route microcopy:
  ```text
  Stale route? Run `make fleet`, identify the matching instance, then stop only that instance with `make down INSTANCE=<project>` or wipe it with `make nuke INSTANCE=<project>`.
  ```
- Recommended cache microcopy:
  ```text
  Use `make up-build` after dependency, Dockerfile, or config changes. Source, HEEx, CSS, and JS edits use `make up`.
  ```
- Recommended docs stance: do not remove every `mix phx.server` literal; remove or qualify stale start instructions. Some `mix phx.server` mentions are correct implementation evidence or separate example-app startup.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 34 Docker DX drift guard:** contract tests for the final `docs/docker_dev_dx.md` strings, absence of stale dev-start `localhost:4000`, and CI/post-publish smoke port extension.
- **Sibling-repo fleet convergence:** remains FLEET-01 and out of v3.2 implementation scope. Phase 33 only makes Scoria the reference standard.
- **Fleet-wide `make nuke-all`:** remains FLEET-02 and out of scope due to high blast radius.
- **Release publish and post-publish registry smoke:** Phase 35.
- **CI cache-key mislabel cleanup:** reviewed via todo match; still post-ship cleanup and unrelated to Phase 33.

### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` - reviewed because it matched on `mix` and `phase`; deferred because it concerns CI cache key/env labeling, not Docker dev-DX documentation or stale local-dev verification copy.
- `docker-dx-fleet-hardening.md` - non-doc fleet convergence items remain deferred; only the doc/plan drift and reader-empathy items were folded into Phase 33.

</deferred>

---

*Phase: 33-doc-restructure-verification-copy-correction*
*Context gathered: 2026-06-18*
