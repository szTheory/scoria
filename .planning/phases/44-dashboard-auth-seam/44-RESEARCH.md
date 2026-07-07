# Phase 44: Dashboard auth seam - Research

**Researched:** 2026-07-07
**Domain:** Phoenix LiveView embedded dashboard authentication and tenant-scope seam
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/44-dashboard-auth-seam/44-CONTEXT.md` `[VERIFIED: local context]`.

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

### the agent's Discretion

Copied verbatim from `.planning/phases/44-dashboard-auth-seam/44-CONTEXT.md` `[VERIFIED: local context]`.

- Exact module names: `ScoriaWeb.DashboardScope`, `ScoriaWeb.DashboardAuth`, or similar.
- Whether the resolver behavior lives under `ScoriaWeb` or core `Scoria`, provided Plug/Phoenix
  details stay at the web edge and core APIs receive explicit scope data.
- Exact error module names and whether unauthorized defaults to a generic empty-state render,
  redirect, or exception in test/dev. Must fail closed either way.
- Exact wording and placement for optional read-only scope receipt, if planner chooses to include it.

### Deferred Ideas (OUT OF SCOPE)

Copied verbatim from `.planning/phases/44-dashboard-auth-seam/44-CONTEXT.md` `[VERIFIED: local context]`.

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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | `scoria_dashboard/2` accepts a pass-through `on_mount:` list; host hooks run before `DashboardNav`, `DashboardNav` stays in the chain, and the bare macro still compiles. | Phoenix LiveView `live_session/3` supports `:on_mount`; Phoenix LiveDashboard exposes the same option; local router currently discards opts and hardcodes `DashboardNav`. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]` `[CITED: https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.Router.html]` `[VERIFIED: local code]` |
| AUTH-02 | A documented tenant-resolution/authorization callback makes `tenant_id` host-asserted, not spoofable by `?tenant=`; no in-lib role/RBAC model is added. | LiveView params are public user input while session is private app data; OWASP requires server-side authorization, deny-by-default, and protection against tamperable lookup IDs. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |
| AUTH-03 | Dashboard LiveViews resolve tenant from the host-asserted source; the `params["tenant"] -> "default"` spoof path is closed. | Local dashboard LiveViews currently contain param/session/default tenant derivations and several global read paths; LiveView navigation does not rerun plug pipelines, so mount-level scope validation is required. `[VERIFIED: local code]` `[CITED: https://phoenix-live-view.hexdocs.pm/security-model.html]` |
</phase_requirements>

## Summary

Phase 44 should implement a narrow Phoenix-native auth seam, not a new authorization product. The host injects authentication and any membership checks through normal `on_mount:` hooks; Scoria then runs one internal dashboard scope gate that accepts only host-asserted scope and assigns `:scoria_scope`, `:tenant_id`, and optional actor/session metadata before `DashboardNav` and before any dashboard data read. `[VERIFIED: local context]` `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]`

The current vulnerability is concrete: `scoria_dashboard/2` discards `_opts`, and multiple dashboard LiveViews use `params["tenant"] || session["tenant_id"] || "default"` or session/default fallbacks. Some dashboard pages also read tenant-owned data globally by ID or list without tenant-qualified APIs. The planner must treat AUTH-03 as both a tenant-source cleanup and a tenant-filtering audit across dashboard surfaces, not only the four obvious `params["tenant"]` call sites. `[VERIFIED: local code]`

**Primary recommendation:** implement `ScoriaWeb.DashboardScope` as the on-mount gate, normalize `opts[:on_mount]` with `List.wrap/1`, build `host_hooks ++ [ScoriaWeb.DashboardScope, ScoriaWeb.DashboardNav]`, document a host-owned `scope_resolver`, and fail closed whenever no non-empty host-asserted tenant exists. `[VERIFIED: local context]` `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]`

## Project Constraints (from CLAUDE.md / AGENTS.md)

- No `./CLAUDE.md`, `./.claude/CLAUDE.md`, or root `./AGENTS.md` file was present in the project root during research. `[VERIFIED: local filesystem]`
- No project-specific skills were found under `.claude/skills/` or `.agents/skills/`. `[VERIFIED: local filesystem]`
- Nested `AGENTS.md` files under vendored/example dependency trees were not treated as project-wide directives. `[VERIFIED: local filesystem]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Host authentication hook | Frontend Server / Phoenix Router | Host API / auth context | Phoenix `live_session` accepts `:on_mount` callbacks, and host auth must run before Scoria dashboard hooks. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]` |
| Tenant scope assertion | Frontend Server / LiveView edge | Host authorization layer | LiveView mount receives session and params; params are public, so a host-asserted resolver must turn trusted host state into Scoria scope. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]` |
| Dashboard data filtering | API / Backend contexts | Database / Storage | Scoria must apply validated tenant IDs to `OperatorSurface`, context functions, PubSub topics, and Repo queries before rendering. `[VERIFIED: local code]` |
| Dashboard navigation/base path | Browser / LiveView UI | Frontend Server | `ScoriaWeb.DashboardNav` already owns dashboard nav/base assigns and should remain after auth/scope hooks. `[VERIFIED: local code]` |
| Authorization policy decisions | Host application | Scoria seam validates outcome | Project doctrine delegates identity and authz nouns to the host; Scoria must not model roles/RBAC. `[VERIFIED: local context]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | locked `1.8.7` published 2026-05-06; latest checked `1.8.9` published 2026-07-07 | Router macros, pipelines, embedded web surface. | Existing project dependency; no upgrade needed for this phase. `[VERIFIED: mix.lock + Hex registry]` |
| Phoenix LiveView | locked `1.1.30` published 2026-05-05; latest checked `1.2.6` published 2026-07-07 | `live_session/3`, `on_mount/1`, dashboard LiveViews. | Locked version already documents the required `:on_mount` API and hook semantics. `[VERIFIED: mix.lock + Hex registry]` `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]` |
| Plug | locked `1.19.2` published 2026-05-14; latest checked `1.20.2` published 2026-06-30 | Host pipeline/session setup before LiveView mount. | Existing Phoenix stack dependency; host auth pipelines remain external to Scoria. `[VERIFIED: mix.lock + Hex registry]` |
| Ecto SQL | locked `3.13.5` published 2026-03-03; latest checked `3.14.0` published 2026-05-19 | Tenant-qualified reads and object lookup hardening. | Existing persistence layer; use query filters and context APIs instead of global reads. `[VERIFIED: mix.lock + Hex registry]` `[VERIFIED: local code]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveDashboard | docs checked current | External precedent for embedded dashboard `:on_mount` option. | Use as API precedent only; Scoria does not depend on it in this phase. `[CITED: https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.Router.html]` |
| OWASP ASVS / Cheat Sheets | ASVS Index based on 5.0.x | Security control framing for authn/authz and IDOR. | Use for validation/security review requirements. `[CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `on_mount:` pass-through | Custom `auth_hooks:` or `before_mount:` option | Custom names hide Phoenix semantics and create a second hook dialect. `[VERIFIED: local context]` |
| Narrow `scope_resolver:` | Broad `live_session_opts:` pass-through | Broad opts let callers accidentally replace Scoria layout/hooks during a P0 fix. `[VERIFIED: local context]` |
| Explicit per-request tenant scope | Process-global current tenant | Hidden global tenant state is riskier in concurrent LiveView/test execution and contradicts Phase 43 explicit scope decisions. `[VERIFIED: local context]` |

**Installation:**

```bash
# No new packages are required for Phase 44.
mix deps.get
```

## Package Legitimacy Audit

No external packages are recommended or installed for this phase. The package legitimacy gate is therefore not applicable. `[VERIFIED: local dependency audit]`

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No install |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Host HTTP request
  -> Host Phoenix pipeline
  -> Host auth plug/session setup
  -> scoria_dashboard "/scoria", on_mount: host_hooks, scope_resolver: resolver
  -> Phoenix live_session
  -> host on_mount hook(s)
       -> unauthenticated? halt/redirect
       -> authenticated? assign host identity/account
  -> Scoria dashboard scope gate
       -> call configured resolver/default resolver
       -> invalid/missing/unauthorized? halt before reads/subscriptions
       -> ok? assign :scoria_scope, :tenant_id, :actor_id
  -> ScoriaWeb.DashboardNav
  -> Dashboard LiveView mount/handle_params
       -> read tenant only from assigns
       -> tenant-filtered context/Repo/PubSub calls
  -> rendered dashboard data for asserted tenant only
```

### Recommended Project Structure

```text
lib/scoria_web/
├── router.ex                    # scoria_dashboard/2 opts normalization and hook chain
├── dashboard_scope.ex           # scope struct, resolver behavior, on_mount gate
├── dashboard_nav.ex             # existing nav/base hook; remains last Scoria hook
└── live/                        # LiveViews consume assigned scope only

test/scoria_web/
├── router_test.exs              # bare macro and hook-chain tests
├── dashboard_scope_test.exs     # resolver/gate behavior tests
└── live/                        # cross-tenant spoof-closure tests
```

### Pattern 1: Native Phoenix hook composition

**What:** Accept `opts[:on_mount]`, normalize with `List.wrap/1`, and append Scoria-owned hooks in a fixed order. `[VERIFIED: local context]`

**When to use:** Use in `ScoriaWeb.Router.scoria_dashboard/2` so host auth hooks run before Scoria scope validation and nav setup. `[VERIFIED: local code]`

**Example:**

```elixir
# Source: Phoenix LiveView Router docs and Phase 44 context
host_on_mount_hooks = List.wrap(Keyword.get(opts, :on_mount, []))
on_mount_hooks = host_on_mount_hooks ++ [ScoriaWeb.DashboardScope, ScoriaWeb.DashboardNav]

live_session :scoria_dashboard,
  root_layout: {ScoriaWeb.Layouts, :root},
  on_mount: on_mount_hooks do
  live path, OrchestratorLive, :index
end
```

### Pattern 2: Fail-closed dashboard scope gate

**What:** A Scoria on-mount hook converts trusted host state into a normalized dashboard scope, assigns it once, and halts on missing/invalid tenant before any dashboard LiveView data access. `[VERIFIED: local context]` `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]`

**When to use:** Use for every route inside `scoria_dashboard/2`; do not duplicate tenant derivation in each LiveView. `[VERIFIED: local code]`

**Example:**

```elixir
# Source: Phoenix LiveView on_mount docs; callback shape adapted for Scoria
def on_mount(:default, _params, session, socket) do
  with {:ok, scope} <- resolve_scope(socket, session),
       {:ok, normalized} <- normalize_scope(scope) do
    socket =
      socket
      |> Phoenix.Component.assign(:scoria_scope, normalized)
      |> Phoenix.Component.assign(:tenant_id, normalized.tenant_id)
      |> Phoenix.Component.assign(:actor_id, normalized.actor_id)

    {:cont, socket}
  else
    {:error, _reason} ->
      {:halt, Phoenix.LiveView.put_flash(socket, :error, "This Scoria dashboard is not available for this session.")}
  end
end
```

### Pattern 3: Tenant-qualified object access

**What:** Dashboard object/detail pages should fetch by both tenant and object ID when the object is tenant-owned. `[VERIFIED: local code]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]`

**When to use:** Use for run details, incidents, approvals, eval runs, review candidates, and release evidence. `[VERIFIED: local code]`

**Example:**

```elixir
# Source: local Ecto patterns; tenant check required by AUTH-03
def get_run_tree_for_tenant!(tenant_id, run_id) when is_binary(tenant_id) and tenant_id != "" do
  Run
  |> where([r], r.tenant_id == ^tenant_id and r.id == ^run_id)
  |> Repo.one!()
  |> preload_run_tree()
end
```

### Anti-Patterns to Avoid

- **Query-param authority:** `params["tenant"]` may be a UI hint for a host resolver, but Scoria must not treat it as authority. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]`
- **Default-open tenant:** Falling back to `"default"` when no tenant exists reopens the spoof path and conflicts with fail-closed local scope precedent. `[VERIFIED: local code]`
- **Global dashboard reads:** List/detail pages that omit tenant filters can leak tenant-owned data even after the source of `tenant_id` is fixed. `[VERIFIED: local code]`
- **In-lib roles/RBAC:** Adding roles, membership tables, or policy values violates AUTH-02 and project doctrine. `[VERIFIED: local context]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView auth hook lifecycle | Custom hook runner or router wrapper | Phoenix `live_session/3` with `:on_mount` | Official API already handles disconnected/connected mounts and hook order. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]` |
| Dashboard authorization policy | Scoria roles/RBAC/membership tables | Host auth hook plus host-owned resolver result | Project requires delegated authz and no in-lib RBAC. `[VERIFIED: local context]` |
| Tenant context propagation | Process-global tenant/current-account state | Explicit `:scoria_scope` and `:tenant_id` assigns | Local Phase 43 precedent favors explicit, fail-closed scope and avoids hidden ambient state. `[VERIFIED: local code]` |
| IDOR protection | Guess-resistant IDs or query param checks | Tenant-qualified server-side reads | OWASP warns that tamperable IDs/query params require server-side authorization checks. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |

**Key insight:** this phase is a seam and proof phase: use Phoenix's existing lifecycle, then make every Scoria dashboard read consume the validated host scope. `[VERIFIED: local context]`

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Existing tenant-owned tables include rows with `tenant_id` that dashboard views already read; schemas without visible tenant fields include datasets, eval specs, and prompt templates. `[VERIFIED: local code]` | Add tenant-filtered reads where tenant fields exist; for tenant-less dashboard surfaces, planner must either classify them as global metadata or add/hide tenant-owned rendering so AUTH-03 can be proven. |
| Live service config | No repo-managed external live service config is required for the dashboard auth seam. `[VERIFIED: local project scan]` | None for Phase 44; host apps configure hooks/resolvers in their own routers. |
| OS-registered state | No OS registration change is part of this non-rename dashboard seam. `[VERIFIED: phase scope]` | None. |
| Secrets/env vars | No new secret or environment variable is required; resolver uses host-authenticated session/assigns or host code. `[VERIFIED: local context]` | None. |
| Build artifacts | BEAM compilation artifacts may contain old macro code until recompilation; no installed package rename or runtime artifact migration is required. `[ASSUMED]` | Normal `mix test`/compile cycle. |

**Nothing found in category:** OS-registered state and secrets/env vars have no Phase 44 action. `[VERIFIED: phase scope]`

## Common Pitfalls

### Pitfall 1: Passing host hooks but dropping Scoria hooks

**What goes wrong:** The host can authenticate, but `DashboardNav` or the Scoria scope gate disappears from the chain. `[VERIFIED: local context]`

**Why it happens:** A broad `live_session_opts:` merge or direct `opts` pass-through lets caller options replace Scoria-owned options. `[VERIFIED: local context]`

**How to avoid:** Build an explicit hook list: `List.wrap(opts[:on_mount] || []) ++ [DashboardScope, DashboardNav]`; keep root layout Scoria-owned. `[VERIFIED: local context]`

**Warning signs:** Tests can mount with host hooks but fail to assign nav/base path, or hook order assertions show `DashboardNav` missing. `[VERIFIED: local test patterns]`

### Pitfall 2: Removing `params["tenant"]` only from obvious pages

**What goes wrong:** Main pages stop spoofing, but run detail, review queue, prompt release, or list pages still expose tenant-owned data through global reads. `[VERIFIED: local code]`

**Why it happens:** The exploit starts with tenant source, but AUTH-03 also requires data reads to be scoped by the asserted tenant. `[VERIFIED: local context]`

**How to avoid:** Audit every route in `scoria_dashboard/2`, every `Repo` read, every `OperatorSurface` call, and every PubSub topic for tenant source and tenant filter. `[VERIFIED: local code]`

**Warning signs:** Tests pass for `OrchestratorLive` but object-detail routes can render another tenant's run/incident/review candidate by ID. `[VERIFIED: local code]`

### Pitfall 3: Treating a missing tenant as `"default"`

**What goes wrong:** Unauthenticated or partially configured dashboard sessions get a valid-looking tenant and can read shared/default data. `[VERIFIED: local code]`

**Why it happens:** Existing dashboard code uses `"default"` as a compatibility fallback. `[VERIFIED: local code]`

**How to avoid:** Default resolver may read `session["tenant_id"]`, but it must halt when absent or blank and never consult params. `[VERIFIED: local context]`

**Warning signs:** Source guard finds `|| "default"` near dashboard tenant assignment or tests can mount without a tenant and still render dashboard data. `[VERIFIED: local code]`

### Pitfall 4: Overexplaining authorization failures in the browser

**What goes wrong:** The dashboard reveals whether a tenant exists, which session key is missing, or how the resolver decided. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]`

**Why it happens:** Developer diagnostics are rendered directly into operator-facing failure copy. `[ASSUMED]`

**How to avoid:** Browser copy should be generic; put detail in tests/logs/docs. `[VERIFIED: local context]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]`

**Warning signs:** Failure pages mention tenant IDs, resolver internals, or exact policy reasons. `[ASSUMED]`

## Code Examples

Verified patterns from official sources and local code:

### Host router integration

```elixir
# Source: Phoenix live_session/on_mount docs; Phase 44 locked API shape
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

### Resolver contract

```elixir
# Source: Phase 44 context; no in-lib RBAC, host asserts scope
defmodule MyAppWeb.ScoriaDashboardScope do
  @behaviour ScoriaWeb.DashboardScope.Resolver

  @impl true
  def resolve(socket, _params, _session) do
    current_user = socket.assigns.current_user
    current_account = socket.assigns.current_account

    if current_account do
      {:ok,
       %{
         tenant_id: current_account.id,
         actor_id: current_user.id,
         display_tenant: current_account.name
       }}
    else
      {:error, :missing_scope}
    end
  end
end
```

### LiveView mount after scope gate

```elixir
# Source: local dashboard pattern after Phase 44 refactor
def mount(_params, _session, socket) do
  tenant_id = socket.assigns.tenant_id

  if connected?(socket) do
    Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
  end

  {:ok, assign(socket, summary: OperatorSurface.status_home_summary(tenant_id))}
end
```

### Source-scan regression guard

```elixir
# Source: Phase 44 context and local ExUnit patterns
test "dashboard live views do not derive tenant from params/default" do
  files = Path.wildcard("lib/scoria_web/live/**/*.ex")

  forbidden = [
    ~s(params["tenant"]),
    ~s(session["tenant_id"] || "default")
  ]

  for file <- files, pattern <- forbidden do
    refute File.read!(file) =~ pattern, "#{file} still contains #{pattern}"
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trusting route/query params as tenant authority | Treat params as public user input; use session/host assigns/resolver for trusted state | Phoenix LiveView docs checked at `1.1.30` | Planner must remove `params["tenant"]` from Scoria authority paths. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]` |
| Auth only in plug pipeline | Combine plug/session auth with LiveView `on_mount` checks inside `live_session` | Phoenix LiveView security model checked current | Live navigation skips regular HTTP requests, so mount-level checks are required. `[CITED: https://phoenix-live-view.hexdocs.pm/security-model.html]` |
| Dashboard package owns roles | Embedded dashboard accepts host auth hooks/resolver | Phase 44 locked decision | Scoria ships the seam, not an RBAC system. `[VERIFIED: local context]` |
| Global object reads by ID | Tenant-qualified reads by asserted tenant and ID | OWASP authorization/IDOR guidance checked current | Object detail pages must prove same-tenant access. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |

**Deprecated/outdated:**

- `params["tenant"] || session["tenant_id"] || "default"`: closes AUTH-03 only if removed from dashboard authority paths and replaced with assigned host scope. `[VERIFIED: local code]`
- Broad `live_session_opts:` in Phase 44: deferred because it widens the public API and can overwrite Scoria-owned hooks/layout. `[VERIFIED: local context]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | BEAM compilation artifacts are the only build artifacts affected by the macro/hook refactor. | Runtime State Inventory | Low; planner may add a clean compile task if stale artifacts are suspected. |
| A2 | Developer diagnostics in browser failure copy can leak useful auth state to attackers. | Common Pitfalls | Low; OWASP supports generic auth failure copy, but exact threat severity depends on host deployment. |
| A3 | Tenant-less dashboard schemas may be either global metadata or missing tenant scope depending on product intent. | Runtime State Inventory / Open Questions | Medium; planner must resolve before claiming AUTH-03 for those surfaces. |

## Open Questions

1. **How should unauthorized/missing-scope render in production?**
   - What we know: Phase context allows generic empty-state render, redirect, or exception in test/dev, but all options must fail closed. `[VERIFIED: local context]`
   - What's unclear: Whether the first implementation should render an in-dashboard generic unavailable state or redirect to host login by default. `[VERIFIED: local context]`
   - Recommendation: default to a generic unavailable state for Scoria's built-in resolver failures, while accepting `{:redirect, to}` and `{:halt, socket}` from host resolver outcomes. `[VERIFIED: local context]`

2. **Are datasets, eval specs, and prompt templates tenant-owned for AUTH-03?**
   - What we know: The context says global reads exposing tenant-owned data are in scope; local schemas for some dashboard resources lack visible `tenant_id`. `[VERIFIED: local context]` `[VERIFIED: local code]`
   - What's unclear: Whether these resources are intended as global catalog metadata or tenant-isolated records before 1.0. `[VERIFIED: local code]`
   - Recommendation: planner must decide per surface: add tenant fields/filtering where tenant-owned, or suppress tenant-owned evidence from global pages until scoped. `[VERIFIED: local context]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | compile/tests | yes | 1.19.5 | none needed `[VERIFIED: local command]` |
| Erlang/OTP | compile/tests | yes | 28 | none needed `[VERIFIED: local command]` |
| Mix | dependency/test runner | yes | 1.19.5 | none needed `[VERIFIED: local command]` |
| PostgreSQL | integration tests | yes | localhost:55432 accepting connections | use existing test DB config `[VERIFIED: local command]` |
| ripgrep | source audit/static guard discovery | yes | 15.1.0 | `grep` if unavailable `[VERIFIED: local command]` |
| Git | commit/status | yes | 2.41.0 | none needed `[VERIFIED: local command]` |

**Missing dependencies with no fallback:** none

**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView test helpers `[VERIFIED: local tests]` |
| Config file | `mix.exs`, `test/support/**/*.ex`, local test modules `[VERIFIED: local code]` |
| Quick run command | `mix test test/scoria_web/router_test.exs --warnings-as-errors` |
| Full suite command | `mix test --warnings-as-errors` |

Baseline checked during research: `mix test test/scoria_web/router_test.exs --warnings-as-errors` returned 5 tests, 0 failures. `[VERIFIED: local command]`

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| AUTH-01 | Bare macro compiles; host `on_mount` single/list hooks compile; hook order is host -> scope gate -> `DashboardNav`; `DashboardNav` cannot be omitted. | unit/router compile | `mix test test/scoria_web/router_test.exs --warnings-as-errors` | Existing file yes; new cases required `[VERIFIED: local tests]` |
| AUTH-02 | Resolver accepts valid host scope, rejects nil/blank/malformed scope, supports unauthorized/redirect/halt outcomes, and never reads params/default. | unit | `mix test test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` | Missing; Wave 0 add `[VERIFIED: local tests]` |
| AUTH-03 | Mount as tenant A with `?tenant=tenant-b`; dashboard renders A or empty data only, PubSub topics use A, object detail routes reject B-only IDs. | integration/LiveView | `mix test test/scoria_web/live --warnings-as-errors` | Partial existing coverage; new cross-tenant cases required `[VERIFIED: local tests]` |
| AUTH-03 | Static guard forbids `params["tenant"]`, `session["tenant_id"] || "default"`, and suspicious `|| "default"` near dashboard tenant assignment. | source guard | `mix test test/scoria_web/dashboard_scope_source_guard_test.exs --warnings-as-errors` | Missing; Wave 0 add `[VERIFIED: local tests]` |

### Sampling Rate

- **Per task commit:** `mix test test/scoria_web/router_test.exs test/scoria_web/dashboard_scope_test.exs --warnings-as-errors`
- **Per wave merge:** `mix test test/scoria_web/live --warnings-as-errors`
- **Phase gate:** `mix test --warnings-as-errors` plus source guard green before `$gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/scoria_web/dashboard_scope_test.exs` - resolver/gate behavior for AUTH-02.
- [ ] `test/scoria_web/dashboard_scope_source_guard_test.exs` - static regression guard for AUTH-03.
- [ ] Additional cases in `test/scoria_web/router_test.exs` - hook pass-through/order for AUTH-01.
- [ ] Cross-tenant fixtures/tests for dashboard LiveViews that read tenant-owned rows.

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not explicitly set `security_enforcement: false`. `[VERIFIED: local config]`

### Applicable ASVS Categories

The current OWASP ASVS Index is based on ASVS 5.0.x; the GSD template uses older category labels, so this table lists current ASVS categories with template-compatible meaning. `[CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]`

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V6 Authentication | yes | Host app authenticates before Scoria dashboard entry; Scoria accepts host hook chain. `[CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]` |
| V7 Session Management | yes | Host session/assigns are resolver inputs; LiveView mount validates scope for disconnected and connected lifecycle. `[CITED: https://phoenix-live-view.hexdocs.pm/security-model.html]` |
| V8 Authorization | yes | Host-owned resolver plus Scoria fail-closed tenant-qualified reads. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |
| V2 Validation and Business Logic | yes | Normalize non-empty tenant scope; reject malformed resolver outputs. `[CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]` |
| V11 Cryptography | no new cryptography | Do not add custom crypto; rely on Phoenix/Plug session stack already configured by host. `[ASSUMED]` |
| V16 Security Logging and Error Handling | yes | Generic browser failure copy; developer detail in docs/logs/tests. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]` |

### Known Threat Patterns for Phoenix LiveView Dashboard Scope

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Query-param tenant spoofing / IDOR | Elevation of privilege / Information disclosure | Treat params as public input; derive tenant from host resolver; tenant-filter every read. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |
| Live navigation bypasses plug pipeline | Elevation of privilege | Use `live_session` `:on_mount` checks for all dashboard LiveViews. `[CITED: https://phoenix-live-view.hexdocs.pm/security-model.html]` |
| Missing tenant defaults to global/default data | Information disclosure | Fail closed on nil/blank tenant; static guard against `"default"` fallbacks. `[VERIFIED: local code]` |
| Detail route object ID from another tenant | Information disclosure | Fetch by `{tenant_id, id}` or return not found/empty state. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]` |

## Sources

### Primary (HIGH confidence)

- Local phase context `.planning/phases/44-dashboard-auth-seam/44-CONTEXT.md` - locked decisions, deferred scope, canonical local hotspots. `[VERIFIED: local context]`
- Local requirements `.planning/REQUIREMENTS.md` - AUTH-01..03 text. `[VERIFIED: local context]`
- Local code under `lib/scoria_web/**`, `lib/scoria/**`, and `test/scoria_web/**` - router macro, dashboard LiveViews, scope precedents, tests. `[VERIFIED: local code]`

### Secondary (MEDIUM confidence)

- Phoenix LiveView Router docs `1.1.30` - `live_session/3`, `:on_mount`, navigation authorization note. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]`
- Phoenix LiveView docs `1.1.30` - params/session trust boundary and `on_mount` return behavior. `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.html]`
- Phoenix LiveView security model - plug plus `on_mount` authorization guidance. `[CITED: https://phoenix-live-view.hexdocs.pm/security-model.html]`
- Phoenix LiveDashboard Router docs - embedded dashboard `:on_mount` precedent. `[CITED: https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.Router.html]`
- Phoenix LiveDashboard docs - production authentication-in-front guidance. `[CITED: https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.html]`
- OWASP Authorization Cheat Sheet - deny-by-default, server-side checks, tamperable IDs/query params. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html]`
- OWASP Authentication Cheat Sheet - generic failure copy. `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]`
- OWASP ASVS Index - ASVS 5.0.x category mapping. `[CITED: https://cheatsheetseries.owasp.org/IndexASVS.html]`
- Hex registry checks for locked/current package versions. `[VERIFIED: Hex registry]`

### Tertiary (LOW confidence)

- Build artifact impact is inferred from normal BEAM compilation behavior, not separately audited. `[ASSUMED]`

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing locked dependencies and Hex registry versions were checked; no new package install is recommended. `[VERIFIED: mix.lock + Hex registry]`
- Architecture: HIGH - constrained by local context, local code, and Phoenix official docs. `[VERIFIED: local context]` `[CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveView.Router.html]`
- Pitfalls: MEDIUM - key exploit paths are locally verified; UI failure-copy leakage severity is partly inferred from OWASP generic-auth guidance. `[VERIFIED: local code]` `[CITED: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html]`

**Research date:** 2026-07-07
**Valid until:** 2026-08-06 for local implementation guidance; re-check Phoenix/LiveView docs and Hex versions before dependency upgrades.
