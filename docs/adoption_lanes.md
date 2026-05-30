# Choosing An Adoption Lane

Scoria is easiest to adopt when you treat it as a layered Phoenix runtime, not a platform you have to swallow whole.

Start with the narrowest lane that solves your current problem. Expand only when the previous lane already feels boring in your host app.
Start with the default runtime lane. It proves identity-aware durable runs, approvals, and operator evidence with mix test.adoption. Use mix test.runtime_to_handoff as the bounded escalation proof lane when the same durable run needs narrow same-run delegation, host-controlled projected context, and operator-visible delegated lineage.

## The Four Lanes

### 1. Default runtime lane

Start here.

Choose it when you need:

- canonical actor, tenant, and session identity
- durable runs with exact `run_id` resume
- approval pauses and operator evidence
- one public facade for `identity -> start -> inspect -> resume`

Core APIs:

- `Scoria.identity/1`
- `Scoria.start_run/2`
- `Scoria.get_run/1`
- `Scoria.resume_run/2`
- `Scoria.list_runs_for_session/1`

Operator surfaces:

- `/scoria`
- `/scoria/workflows/:run_id`

Proof lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Adoption closeout exercises a packaged tarball from `mix hex.build --unpack` (not a monorepo root `path:` dep). Maintainer CI topology — PR tarball vs release registry attest — lives in [`docs/operator_verification.md`](operator_verification.md).

If you are not sure where to start, start here.

After upgrades, run `mix scoria.install --check` as a no-write verification step. See
[Installer verification modes (upgrade-safe)](operator_verification.md#installer-verification-modes-upgrade-safe)
for the dry-run → check → remediate → apply workflow. See
[Check vs apply drift detection](operator_verification.md#check-vs-apply-drift-detection)
for manifest fingerprint roles at check vs apply time.

This lane does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

### 2. Bounded handoff lane

Add this only when the default runtime lane is already working.

Choose it when:

- one role needs to delegate a narrow slice of work to another role
- the delegated role should stay under the same durable run
- projected context must stay least-privilege and inspectable

Core API:

- `Scoria.start_handoff_run/3`

Key rule:

- projected context stays narrow and host-controlled
- broad runtime-state keys such as `transcript`, `messages`, `provider_session`, `session`, and `secrets` are rejected explicitly

Use this for review, critique, classification, or bounded specialist work. Do not use it to build a broad autonomous multi-agent platform by default.

Validate the base runtime lane with `mix test.adoption` before you intentionally expand into `Scoria.start_handoff_run/3`.
Use `mix test.runtime_to_handoff` as the bounded runtime-to-handoff escalation verifier for the same `Scoria.get_run_detail/1` and `delegated_handoffs` readback path.

### 3. Semantic fast-path lane

Add this only after the default runtime lane is already boring.

Choose it when:

- you want answer reuse for explicitly safe read-only work
- tenant partitioning and compatibility truth matter more than aggressive hit-rate chasing
- operators need to inspect why reuse happened, missed, bypassed, or was rejected

Core API surface:

- `use Scoria.SemanticLane`
- `Scoria.start_run(..., semantic_cache: [lane: MyLane], ...)`

Key behavior:

- reuse is opt-in
- hits remain inside the normal durable run story
- `bypass`, `miss`, `reject`, and stale outcomes fall through to the normal runtime path
- lifecycle truth stays explicit as `active`, `stale`, `invalidated`, and `writeback_rejected`

Proof lane:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Use this lane when latency and cost matter, but only if you can keep the work safe, tenant-scoped, and operator-visible.

Semantic fast path is optional troubleshooting, not a prerequisite for first adoption.

### 4. Optional knowledge lane

Add this only when you are intentionally validating retrieval, citations, and grounding.

Choose it when:

- you need pgvector-backed retrieval
- you need citation and grounding evidence
- you are ready to own the knowledge setup in your app

Proof lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

This lane is explicitly optional. It is not required to prove the core runtime, handoff, or semantic fast-path adoption story, and it is not a prerequisite for first adoption.

## A Good Default Order

Adopt Scoria in this order:

1. `identity -> start -> inspect -> resume`
2. bounded handoffs if one role truly needs delegation
3. semantic fast path if safe read-only reuse is worth it
4. optional knowledge lane if retrieval and grounding are part of your product

## What You Do Not Need To Adopt First

You do not need:

- pgvector
- broad multi-agent orchestration
- a hosted control plane
- external semantic cache backends
- advanced ANN tuning

Start narrow. Expand only when the current lane already feels boring.
