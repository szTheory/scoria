# Phase 32: Secrets pattern + key rotation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 32-secrets-pattern-key-rotation
**Areas discussed:** Secret reference shape, Runtime loading path, Rotation proof wording, Docs placement and tone

---

## Secret Reference Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Separate `.env.op.example`, `.envrc.example`, comments-only secret guidance in `.env.example` | Keeps `.env` non-secret; uses 1Password `op://` references in a dedicated env-file example. | yes |
| Direct `op read` in `.envrc.example` | Simple for one secret, but scales poorly and increases shell-script fragility. | |
| `.env.op.example` only with explicit command wrappers | Strong process scope but less connected to SEC-01's direnv example requirement if used alone. | |
| Put `ANTHROPIC_API_KEY=op://...` directly in `.env.example` | Fewer files, but confuses plain Compose/Phoenix dotenv consumers. | |

**User's choice:** Discuss all areas with subagent research and produce one coherent recommendation.
**Notes:** The final recommendation keeps the separate-file pattern but uses process-scoped `op run --env-file` as the default, not automatic `direnv_load` secret resolution.

---

## Runtime Loading Path

| Option | Description | Selected |
|--------|-------------|----------|
| `op run --env-file .env.op -- <command>` with direnv tracking local config | Secrets are resolved only for the child process; works for Docker Compose and native `mix`. | yes |
| `.envrc` exports `op://` references and commands use bare `op run` | Easier command shape, but bare commands receive unresolved references. | |
| `.envrc` resolves secrets into the shell environment | Best bare-command DX but makes a long-lived shell hold the plaintext key. | |
| Generate plaintext `.env` from 1Password | Familiar tooling, but recreates the current plaintext-on-disk risk. | |
| 1Password Environments | Clean future option, but more setup friction than this phase needs. | |

**User's choice:** Research all options; make the final call.
**Notes:** Process-scoped `op run --env-file` wins on security and least surprise. Direnv remains useful for `SCORIA_OP_ENV_FILE`, file watching, and local trust flow.

---

## Rotation Proof Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Date-only maintainer attestation | Low friction but weak audit trail. | |
| Structured redacted remediation attestation | Captures who/when/what without storing secret material. | yes |
| External evidence retained out-of-band with repo pointer | Stronger evidence but more private evidence management. | |
| Provider/API audit verification record | Highest confidence if available, overkill for this local pre-ship item. | |

**User's choice:** Research all options; make the final call.
**Notes:** The phase record should state maintainer-attested rotation/revocation and explicitly say no token material was stored. Do not read `.env`.

---

## Docs Placement and Tone

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal quickstart only | Smallest change but under-documents common setup footguns. | |
| Compact operator-first section in `docs/docker_dev_dx.md` | Balances copy-pasteable setup, footguns, and Phase 32 scope. | yes |
| Deep troubleshooting runbook | Comprehensive but too much for this phase and likely to bloat the portable standard. | |
| Separate `docs/secrets.md` | Cleaner long-term IA, but fragmented for this one-secret local dev pattern. | |

**User's choice:** Research all options; make the final call.
**Notes:** Place `## Secrets (ANTHROPIC_API_KEY)` after the layer-cache invalidation table and before `## Adopting this in another repo`. Tone should follow brandbook: calm, exact, useful.

---

## Claude's Discretion

- Exact docs prose and example comments.
- Whether to mention automatic `direnv_load` as an opt-in tradeoff, provided it does not become the default.
- Whether to add small convenience wrappers later; Phase 32 should not widen unless planning discovers an existing target that must be corrected.

## Deferred Ideas

- Automatic shell-wide secret loading through `direnv_load`.
- Make targets/wrapper scripts for critique-with-secrets.
- Dedicated secrets runbook.
- Cross-repo sibling migration.
- CI policy cache-key cleanup.
