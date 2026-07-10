# Troubleshooting

This guide maps common Scoria adoption failures to the smallest proof that explains them. Use it with [Reviewer Verification](guides/reviewer-verification.md), [Default Runtime](guides/capabilities/default-runtime.md), [Semantic Cache](guides/capabilities/semantic-cache.md), [Ownership Boundary](guides/ownership-boundary.md), and the [Glossary](guides/reference/glossary.md).

Start by identifying which verification suite is failing. Do not jump to optional knowledge, semantic cache, connector, or release preview work until the default runtime path is proven.

## Quick failure map

| Symptom | Likely cause | First check |
|---------|--------------|-------------|
| `/scoria` shows unavailable copy | missing or rejected dashboard scope | verify host auth, resolver return, and session scope keys |
| reviewer trace does not show the run | `tenant_id` mismatch or wrong `run_id` | compare runtime identity with dashboard tenant scope |
| resume opens the wrong execution | confused `session_id` with `run_id` | persist and resume the exact `started.run_id` |
| semantic reuse never hits | unsafe profile, compatibility mismatch, or stale lifecycle | run semantic cache verification and inspect `bypass`/`miss`/`reject` |
| knowledge proof fails but default runtime passes | optional knowledge base setup is incomplete | bootstrap pgvector and run only the knowledge suite |
| `mix scoria.release_preview` fails | docs or package inventory drift | inspect the reported missing package path or docs build warning |

## `session_id` versus `run_id`

Use `session_id` to group related host turns. Use `run_id` to inspect or resume one exact Scoria execution.

Good:

```elixir
{:ok, started} = Scoria.start_run(identity, root_role_id: "executor")
{:ok, summary} = Scoria.get_run(started.run_id)
{:ok, resumed} = Scoria.resume_run(started.run_id, handlers: handlers)
```

Risky:

```elixir
Scoria.resume_run(identity.session_id, handlers: handlers)
```

If a paused approval cannot resume or the reviewer page says the run cannot be found, check the stored value first:

- `session_id` should be reused for another turn in the same host conversation.
- `run_id` should be stored when you need exact readback, approval, resume, or `/scoria/workflows/:run_id`.
- the dashboard trace URL must use the exact `run_id`.

## Missing dashboard scope

The host authenticates the reviewer and asserts dashboard scope. Scoria does not accept a tenant query param as authority.

Recommended mount:

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

If `/scoria` renders unavailable copy:

1. Confirm the route sits behind the host app's authentication pipeline.
2. Confirm your resolver returns `{:ok, %{tenant_id: ..., actor_id: ...}}`.
3. Confirm the resolver checks membership before returning tenant scope.
4. Confirm the runtime `identity.tenant_id` matches the dashboard tenant scope.
5. Confirm `/scoria?tenant=other-account` does not change the asserted scope.

The generic unavailable copy is fail-closed behavior, not an instruction to expose public dashboard access.

## Runtime trace is missing

If `/scoria/workflows/:run_id` cannot find the run:

- verify the route uses `run_id`, not `session_id`.
- verify the run belongs to the same tenant scope asserted by the dashboard resolver.
- verify the run was committed before the browser opened the trace.
- verify reviewer live broadcast infrastructure is started if you expect live trace updates.

The dashboard is a reviewer trace, not the product system of record. Your Phoenix app still owns customer, ticket, order, account, prompt intent, expected output, and success meaning.

## Semantic cache confusion

The semantic cache is not a knowledge base. Semantic cache reuses compatible answers for explicitly safe read-only work; the optional knowledge base owns retrieval, citations, and grounding.

If semantic reuse never hits:

1. Confirm the run still uses the normal `Scoria.start_run/2` facade.
2. Confirm the call passes `semantic_cache: [profile: MyApp.AI.AccountFaqCache]`.
3. Confirm the profile declares `safe_read_only: true`.
4. Confirm tenant, prompt, policy, source, and lifecycle compatibility still hold.
5. Inspect the reviewer trace outcome: `bypass`, `miss`, `reject`, or `hit`.

Use the semantic cache verification suite:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Compatibility note: `Scoria.SemanticLane`, `lane:`, and `lane_key` remain accepted as 0.1.x aliases. New public docs and examples should prefer `Scoria.SemanticCache.Profile`, `profile:`, and `cache_key:`. `lane_key` remains stored compatibility vocabulary, not a new host-facing setup concept.

## Optional knowledge base setup

Do not debug a knowledge failure by widening the default runtime setup. Knowledge is optional.

Use this only when validating retrieval, citations, and grounding:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

If knowledge proof fails:

- confirm pgvector is available for the configured database.
- confirm knowledge migrations have been applied through the knowledge migration path.
- confirm tenant identity is present; nil tenant scope must not read every tenant's content.
- confirm metadata filters are treated as narrowing inside tenant scope, not as security proof.

Default runtime, bounded handoffs, semantic cache, and connector proof do not require knowledge setup.

## Release preview and package proof

Use release preview when validating publish-facing docs and package inventory:

```bash
mix scoria.release_preview
```

If release preview fails:

1. Read the reported missing or unexpected path.
2. Check whether the path is a canonical `guides/` file, an old `docs/*.md` compatibility stub, a required brand asset, or a runtime/migration package file.
3. Run `mix docs` only if the failure is in docs generation.
4. Keep dev-only docs such as design-system, Docker dev DX, UAT automation, and component-lab material out of adopter HexDocs unless a plan explicitly packages them.

`mix scoria.release_preview` is a maintainer verification suite. It is not a substitute for `mix test.adoption` or `mix test.runtime_to_handoff`.

## Installer check and apply drift

For upgrade-safe installer work, use no-write modes before applying:

```bash
mix scoria.install --dry-run
mix scoria.install --check
mix scoria.install
```

If `--check` reports drift or manual review:

- do not edit `.scoria/install/manifest.json` by hand.
- remediate the printed file or migration issue.
- rerun `--dry-run` and `--check` before apply.
- avoid changing managed files between check and apply.

`--check` classifies live host surfaces. The stored manifest is an informational last-applied snapshot, not the source of check truth.

## Which proof to run next

| You changed | Run |
|-------------|-----|
| install, dashboard mount, or default runtime docs | `mix test.adoption` |
| bounded handoff behavior or docs | `mix test.runtime_to_handoff` |
| semantic cache profile behavior | `mix test.semantic_fast_path` |
| optional knowledge base behavior | `mix test.knowledge` |
| connector/MCP behavior | `mix test.connector` |
| canonical guides, ExDoc extras, package files, or release docs | `mix scoria.release_preview` |
| broad repo health before pushing | `mix ci` |

Keep failures local to the relevant capability first. Broad suites are useful for classification after the smallest verification suite explains the failure.
