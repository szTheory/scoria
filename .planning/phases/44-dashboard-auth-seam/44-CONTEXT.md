# Phase 44: Dashboard auth seam - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the embedded `/scoria` dashboard mountable behind host-owned authentication and host-asserted
tenant scope. The host must be able to inject its own `on_mount` hook before Scoria's dashboard
hooks, and Scoria must stop treating `?tenant=` or a missing session as authority to read dashboard
data.

This phase delivers AUTH-01..03 only:

1. `scoria_dashboard/2` accepts pass-through `on_mount:` hooks while preserving the bare
   `scoria_dashboard "/scoria"` form used by the installer, dev router, and example host.
2. A documented host-owned scope resolver makes `tenant_id` host-asserted. Authorization stays
   delegated; Scoria does not add an in-lib RBAC model.
3. Dashboard LiveViews resolve tenant from the shared Scoria dashboard scope assign and close the
   `params["tenant"] || session["tenant_id"] || "default"` spoof path.

**Method note:** The user explicitly delegated all decision points to Claude and requested parallel
subagent research across Phoenix/Plug/Ecto idioms, successful embedded dashboards, cross-framework
lessons, DX, security/SRE, UI/UX, and the local prompt corpus. Four research passes covered router
hook DX, host scope resolver design, LiveView enforcement/proof, and docs/operator UX. This context
synthesizes those recommendations with local code and prior phase decisions.

**In scope:** fix + prove the dashboard auth seam for shipped `0.1.2` before the next Hex release.
**Out of scope:** Hex `0.1.3` publish, Phase 45 correctness sweep, full operator scope bar, tenant
switching UI, in-lib roles/RBAC/policy values, and Sigra-specific coupling.

</domain>

<decisions>
## Implementation Decisions

Hard constraints carried forward:

- **Fix + prove only.** This P0 security milestone does not publish `0.1.3`.
- **Host owns identity and authorization.** Scoria owns the dashboard surface and data-read verb; the
  host supplies trustworthy actor/tenant nouns and decides who may enter.
- **Client params are untrusted.** `?tenant=`, path params, and query filters may narrow UI state but
  never assert dashboard tenant authority.
- **No in-lib RBAC.** Phase 44 ships the seam and fail-closed checks, not roles, permissions, tenant
  membership tables, or policy values.

### D-01 - Router macro: expose native `on_mount:` and append Scoria hooks

- Keep the public shape idiomatic Phoenix:

  ```elixir
  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    scoria_dashboard "/scoria",
      on_mount: [{MyAppWeb.UserAuth, :require_authenticated}]
  end
  ```

- `scoria_dashboard(path, opts \\ [])` must stop discarding `opts`.
- Support Phoenix's normal hook forms: `Module`, `{Module, arg}`, or a list of those forms.
- Normalize with `List.wrap(Keyword.get(opts, :on_mount, []))`.
- Build the live-session hook chain as:

  ```elixir
  host_on_mount_hooks ++ [ScoriaWeb.DashboardScope, ScoriaWeb.DashboardNav]
  ```

  `ScoriaWeb.DashboardScope` may be named differently by the planner, but the chain must preserve
  this order: host auth/scope hooks first, Scoria scope validation second, `DashboardNav` last.
- Keep `root_layout: {ScoriaWeb.Layouts, :root}` Scoria-owned. Do not add a broad
  `live_session_opts:` pass-through in Phase 44; that widens the API and lets callers accidentally
  erase layout or Scoria hooks.
- Bare `scoria_dashboard "/scoria"` must still compile. It should use the default dashboard scope
  resolver described in D-02 for compatibility with existing installer/dev/example paths.
- Invalid hook shapes should fail with Phoenix's normal `on_mount` validation error rather than a
  Scoria-specific parser.

**Why:** This matches `Phoenix.LiveView.Router.live_session/3`, Phoenix generated auth, Phoenix
LiveDashboard, and Oban Web style. Developers already know `on_mount`; inventing `auth_hooks:` or
`before_mount:` would be less discoverable and easier to misuse.

### D-02 - Dashboard scope resolver: host-owned, explicit, fail closed

- Add a public dashboard scope contract, either as a behavior-backed resolver plus MFA shorthand or
  as a small resolver module with the same callback shape. The canonical docs should present the
  behavior; MFA is ergonomic sugar.
- Recommended public API:

  ```elixir
  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
  ```

  or:

  ```elixir
  scoria_dashboard "/scoria",
    scope_resolver: {MyAppWeb.ScoriaDashboardScope, :resolve, []}
  ```

- The resolver returns explicit, normalized data:

  ```elixir
  {:ok,
   %ScoriaWeb.DashboardScope{
     tenant_id: current_account.id,
     actor_id: current_user.id,
     display_tenant: current_account.name
   }}
  ```

  Exact struct/module names are planner discretion. Required fields: non-empty string
  `tenant_id`. Optional fields: `actor_id`, `session_id`, and a host-provided safe display label.
- Accepting a plain map/keyword with the same keys is fine if normalized immediately.
- Supported callback outcomes:
  - `{:ok, scope}` -> assign normalized scope and continue.
  - `{:error, :unauthorized}` or `{:error, :missing_scope}` -> halt before any dashboard query or
    PubSub subscription.
  - `{:redirect, to}` or `{:halt, socket}` -> host-controlled redirect/halt for login flows.
  - Anything else -> raise an explicit invalid-resolver-return error in development/test.
- The default resolver may read host-set `session["tenant_id"]` / `session["actor_id"]` and existing
  socket assigns for backward compatibility, but it must not read `params["tenant"]`, must not fall
  back to `"default"`, and must fail closed when tenant is absent.
- Path/subdomain/query values can be lookup hints inside the host resolver only after host auth and
  membership checks. They are not Scoria authority.
- Do not pass `Plug.Conn` into core Scoria data APIs. The resolver is a Phoenix-edge adapter; core
  Scoria receives explicit tenant/actor data.

**Why:** This follows the Phase 43 scope decision: explicit scope data in, fail closed on missing
tenant, no hidden process tenant, no `Plug.Conn` in core APIs. It also keeps the consumer API designed
from the Phoenix host's perspective: host code already knows current user/account and should return
Scoria's minimal dashboard scope, not implement Scoria-specific RBAC.

### D-03 - Shared LiveView gate: assign once, read assigns only

- Add a shared Scoria dashboard `on_mount` gate that runs for every dashboard LiveView.
- The gate must assign at least:
  - `:scoria_scope` (normalized scope struct/map)
  - `:tenant_id` (for compatibility with current LiveViews)
  - `:actor_id` when present
- Every dashboard LiveView must read `socket.assigns.tenant_id` (or `socket.assigns.scoria_scope`)
  only. Remove local tenant derivations such as:

  ```elixir
  params["tenant"] || session["tenant_id"] || "default"
  ```

- Missing/blank tenant must stop before:
  - PubSub subscribe calls such as `scoria:runs:#{tenant_id}` and `mcp:runtimes:#{tenant_id}`
  - `OperatorSurface` reads
  - direct `Repo` reads that render dashboard data
- Unauthorized or malformed resolver output must never degrade to empty `"default"` data or a global
  list. It should halt/redirect or raise loudly in tests.
- The planner must audit all dashboard pages, not just the obvious tenant-param sites. Current global
  reads without tenant filtering are in the scope of AUTH-03 if they can expose tenant-owned data,
  including runs, eval runs/specs, review candidates, datasets, prompt release evidence, and prompt
  registry views.
- Prefer small helper functions over scattered `assign(:tenant_id, ...)` duplication. A helper such
  as `ScoriaWeb.DashboardScope.assigns(socket)` is acceptable if it reduces mistakes.

**Why:** LiveView `navigate` does not rerun plugs, so the dashboard needs mount-level authorization
and scope validation. Centralizing the gate makes the proof durable and prevents the same
`?tenant=` shortcut from reappearing page by page.

### D-04 - Proof: static guard plus cross-tenant LiveView tests

- Add focused tests for `scoria_dashboard/2`:
  - bare macro still mounts routes
  - single and list `on_mount` hooks compile
  - hook order is host hooks -> dashboard scope gate -> `DashboardNav`
  - `DashboardNav` cannot be omitted by host opts
  - invalid hook shapes fail normally
- Add resolver/gate unit tests:
  - valid session/default resolver assigns tenant/actor
  - nil/blank tenant halts or raises before data access
  - unauthorized result halts/redirects with no data
  - malformed resolver return raises an explicit error
- Add LiveView tests proving spoof closure:
  - mount as tenant A with `?tenant=tenant-b`
  - tenant B runtime/approval/incident/review data does not render
  - PubSub subscriptions use tenant A, not query param tenant B
  - object detail routes 404/empty-state when the ID exists only for tenant B
- Add a source-scan regression guard over dashboard LiveViews forbidding:
  - `params["tenant"]`
  - `session["tenant_id"] || "default"`
  - `|| "default"` near dashboard tenant assignment
- Update existing tests/harnesses that relied on query-param tenant selection to use host-session or
  resolver setup instead.

**Why:** This phase is security-sensitive; a static guard catches future reintroduction, while
cross-tenant tests prove the actual exploit no longer returns foreign data.

### D-05 - Docs and operator UX: docs-first, no tenant selector in this phase

- Update adopter docs to say:

  > The host app authenticates the operator and asserts dashboard tenant scope. Scoria records and
  > reads that scope; query params do not choose tenants.

- Update `docs/adoption_lanes.md` and `docs/operator_verification.md` examples away from “set
  session keys before mounting” as the whole contract; session keys may be the default resolver input,
  but the recommended path is host auth hook + scope resolver.
- Keep UI changes minimal:
  - No tenant picker.
  - No cross-tenant mode.
  - No full persistent scope bar in Phase 44.
  - A read-only `Tenant` / `Scope` receipt may be added only if it uses a host-provided safe display
    label, existing UI primitives, and does not imply switching or authorization inside Scoria.
- Browser-facing failure copy should be generic:

  > This Scoria dashboard is not available for this session.

  Put developer detail in docs/logs/tests, not in the browser. Do not reveal tenant lists, resolver
  internals, session keys, or exact policy failure reasons.
- Optional Sigra recipe is allowed as a secondary example, not as the canonical integration.

**Why:** The North-Star UI wants explicit scope, but Phase 44 is a P0 seam fix. Building a full scope
bar or tenant switcher would imply Scoria owns more identity/product policy than it does today.

### Research Tradeoffs Considered

- **Broad `live_session_opts:` pass-through:** Flexible, but too much surface for a P0 fix; callers
  could accidentally override Scoria-owned layout/hooks.
- **Host-only assigns with no Scoria resolver:** Maximum host ownership, but too easy for adopters to
  miss and too weak as a documented Hex library seam.
- **Session-only tenant:** Better than query params, but still incomplete for dashboard
  authorization and stale across LiveView navigation unless paired with a gate.
- **Param/session compatibility guard:** Cheap migration path, but keeps public params in the trust
  story and fails AUTH-02's host-asserted callback requirement.
- **Global/process tenant:** Familiar from some Rails/Django multitenancy patterns, but risky in
  async Elixir/LiveView tests and contrary to Phase 43's explicit scope posture.
- **Full scope bar or tenant switcher:** Good future UX, over-scoped here and dangerous without a
  host-owned authorization substrate.

### Claude's Discretion

- Exact module names: `ScoriaWeb.DashboardScope`, `ScoriaWeb.DashboardAuth`, or similar.
- Whether the resolver behavior lives under `ScoriaWeb` or core `Scoria`, provided Plug/Phoenix
  details stay at the web edge and core APIs receive explicit scope data.
- Exact error module names and whether unauthorized defaults to a generic empty-state render,
  redirect, or exception in test/dev. Must fail closed either way.
- Exact wording and placement for optional read-only scope receipt, if planner chooses to include it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and Roadmap

- `.planning/ROADMAP.md` - Phase 44 goal and AUTH-01..03 success criteria.
- `.planning/REQUIREMENTS.md` - AUTH-01..03 locked requirement text and v3.4 out-of-scope table.
- `.planning/PROJECT.md` - v3.4 fix-and-prove boundary, n=1 operator lens, and P1-P6 scope doctrine.
- `.planning/seeds/SEED-006-pre-1.0-trust-security-hardening.md` - source analysis for P0-3
  dashboard auth bypass and P4 rationale.
- `.planning/phases/43-knowledge-tenant-isolation/43-CONTEXT.md` - carry-forward explicit
  scope/fail-closed tenant posture.
- `.planning/phases/42-eval-fails-closed/42-CONTEXT.md` - carry-forward fail-closed proof posture
  and no fake-green/default-open shortcuts.

### Existing Dashboard Code

- `lib/scoria_web/router.ex` - `scoria_dashboard/2` currently discards `_opts` and hardcodes
  `on_mount: ScoriaWeb.DashboardNav`.
- `lib/scoria_web/dashboard_nav.ex` - existing nav/base-path `on_mount` hook; keep in chain after
  host auth/scope hooks and the Scoria scope gate.
- `lib/scoria_web/live/orchestrator_live.ex` - current `params["tenant"] || session["tenant_id"] ||
  "default"` spoof path; PubSub and trace hydration use tenant.
- `lib/scoria_web/live/approvals_live/index.ex` - current spoof path plus approval actor fallback.
- `lib/scoria_web/live/connectors_live/index.ex` - current spoof path and runtime presence topic.
- `lib/scoria_web/live/incidents_live/index.ex` - current spoof path and tenant incident list.
- `lib/scoria_web/live/incidents_live/show.ex` - current session/default fallback on object detail.
- `lib/scoria_web/live/workflow_live/index.ex` - currently lists all runs; must be audited for
  tenant-owned data exposure.
- `lib/scoria_web/live/workflow_live/show.ex` - currently loads run detail by ID; must be audited for
  tenant-owned object access.
- `lib/scoria_web/live/review_queue_live.ex` - currently refreshes review queue without visible
  tenant scope in mount.
- `lib/scoria_web/live/eval_spec_live/index.ex` - currently lists eval specs/runs without visible
  dashboard tenant scope.
- `lib/scoria_web/live/dataset_live/index.ex` - currently lists datasets without visible dashboard
  tenant scope.
- `lib/scoria_web/live/prompt_live/index.ex` and
  `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - prompt/release surfaces that need a
  tenant-scope audit where they expose tenant-owned release/eval/approval evidence.
- `lib/scoria_web/operator_surface.ex` - shared dashboard read model; many functions already accept
  tenant and are good targets for centralizing fail-closed reads.

### Existing Scope and Identity Precedents

- `lib/scoria/identity.ex` - canonical runtime identity normalization from assigns/session/mount data.
- `lib/scoria/knowledge/scope.ex` - Phase 43 explicit `tenant_id`/`actor_id`/`scope_kind` validation
  and fail-closed scope helper.
- `lib/scoria/semantic_cache/lookup.ex` - local fail-closed `Map.fetch!` tenant precedent.
- `lib/scoria/observe/operator_broadcast.ex` - tenant-topic PubSub behavior; missing tenant drops
  broadcasts instead of using global/default.
- `docs/semantic_fast_path.md` - tenant-partitioned semantics and operator-visible scope evidence.

### Adopter, Verification, UI, and Brand Docs

- `docs/adoption_lanes.md` - current host session identity guidance; update for resolver seam.
- `docs/operator_verification.md` - default-lane proof and optional knowledge proof language; update
  dashboard auth proof.
- `docs/design_system.md` - dashboard UI conventions if a read-only scope receipt is added.
- `brandbook/brand-book.md` - voice and visual constraints: calm, operator-grade, evidence-based,
  no hype or backend-guts-as-product.
- `.planning/research/operator-ui-north-star.md` - future explicit scope contract; treat full scope
  bar as deferred, not Phase 44 scope.

### Prompt Research Corpus Consulted

- `prompts/phoenix-ai-lib-deep-research.md` - Phoenix-native embedded dashboard, Plug/router,
  LiveView operator UI, tenant/cost/audit fields, auth/policy boundaries.
- `prompts/ai-architectural-patterns-deep-research.md` - normal auth before identity resolution,
  permissions before retrieval, tenant filtering, layered gates.
- `prompts/ai-eval-best-practices-deep-research.md` - wrong-tenant data as a critical security
  failure and deterministic proof expectations.
- `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` - explicit tenant/scope
  orientation and cross-tenant leakage as a cardinal UI failure.
- `prompts/scoria-brand-book-deep-research.md` and `brandbook/brand-book.md` - current brand book
  supersedes older prompt wording where they differ.
- `prompts/sztheory-elixir-dna.md` - embedded LiveView dashboard and auth owned by companion/host
  auth libraries rather than every package inventing RBAC.

### External Primary References Consulted

- Phoenix LiveView official docs: `Phoenix.LiveView.Router.live_session/3` security model and
  `:on_mount` option.
- Phoenix LiveView official docs: `Phoenix.LiveView.on_mount/1` hook return behavior and halt/redirect
  semantics.
- Phoenix generated auth templates: route placement, `live_session` hook usage, and assign-first
  context APIs.
- Phoenix LiveDashboard official router docs: embedded dashboard macro options and `on_mount`
  precedent.
- Oban Web docs: resolver/on_mount-style host integration precedent for embedded operational UI.
- OWASP Authorization Cheat Sheet and Authentication Cheat Sheet: deny-by-default and generic
  unauthorized browser copy.
- Django admin and Rails multitenancy patterns were considered only for lessons/footguns: always
  scope querysets by request/host authority; avoid hidden global current-tenant state as the primary
  library seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ScoriaWeb.Router.scoria_dashboard/2` - narrow macro edit point for `on_mount:` pass-through.
- `ScoriaWeb.DashboardNav` - keep as the final Scoria hook; it already owns nav/base assignment and
  should not absorb auth/scope policy.
- `Scoria.Identity` - reusable normalization vocabulary for actor/tenant/session where helpful.
- `Scoria.Knowledge.Scope` - strongest local model for explicit tenant validation and fail-closed
  scope semantics.
- `ScoriaWeb.OperatorSurface` - shared dashboard read model; good place to keep tenant-scoped reads
  consistent once LiveViews provide validated scope.
- Existing UI primitives (`page_header`, `badge`, `evidence_rows`, `empty_state`, `toast`) - use
  these if a small scope receipt or generic unavailable message is needed.

### Established Patterns

- Scoria favors explicit data contracts and deterministic proof over hidden global state.
- Existing optional lanes use focused test tasks and source-scan guards; Phase 44 should add a
  security-specific static guard for tenant params/defaults.
- The dashboard's v3.3 design-system work means new UI should be restrained and component-native;
  no new shell/route/control for a P0 backend seam unless necessary.
- Host identity is already expected in adopter docs, but current docs over-index on raw session keys;
  this phase should promote a resolver seam while preserving the easy session-backed default.

### Integration Points

- Router macro builds the live-session hook chain.
- New dashboard scope gate receives resolver output and assigns `:tenant_id` before all LiveView
  `mount/3` callbacks.
- LiveViews remove local tenant derivation and use assigns only.
- `OperatorSurface` and direct `Repo` queries get tenant-qualified entry points where they currently
  list globally.
- Docs and installer/example host stay compatible with `scoria_dashboard "/scoria"` while showing
  the recommended authenticated mount.

</code_context>

<specifics>
## Specific Ideas

- User asked for a one-shot recommendation set, not further Q&A, and explicitly chose to follow
  Claude's recommendations.
- User asked to consider Phoenix/Plug/Ecto/Elixir ecosystem idioms, successful libraries in and out
  of ecosystem, DX, SRE/security, UI/UX/JTBD, prompt corpus, and brand/design constraints.
- Four subagents were used as requested:
  - router macro/on_mount pass-through DX
  - tenant-resolution/authorization callback API
  - dashboard LiveView enforcement and proof path
  - operator UX/docs/microcopy boundary
- The coherent recommendation is: **host hooks first; Scoria validates host-asserted dashboard scope;
  dashboard pages read only validated assigns; docs teach host-owned authz; no tenant switching UI.**

</specifics>

<deferred>
## Deferred Ideas

- **Full persistent scope bar** - belongs to SEED-013 / Operator IA Pivot, once host-declared
  feature/time/env scope exists.
- **Tenant switching UI** - future auth/IA work only; Scoria must not imply it can authorize tenant
  choices without host policy.
- **In-lib role/RBAC model** - explicitly out of scope by AUTH-02 and P4 scope doctrine.
- **Sigra-specific auth integration** - useful recipe for the szTheory ecosystem, but not a core
  Scoria dependency or canonical path.
- **Broad `live_session_opts:` pass-through** - possible future API expansion if adopters need more
  embedded-dashboard customization; not needed for the P0 seam.

### Reviewed Todos (not folded)

- `2026-06-20-add-approval-decision-history.md` - approval history UI follow-up; unrelated to
  dashboard auth seam and already treated as stale/forward UI work.
- `ci-policy-job-cache-key-mislabel.md` - CI copy/cache-key cleanup; unrelated to auth or tenant
  spoofing.
- `docker-dx-fleet-hardening.md` - fleet/local Docker DX work; unrelated to dashboard auth seam.

</deferred>

---

*Phase: 44-Dashboard auth seam*
*Context gathered: 2026-07-07*
