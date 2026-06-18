# Phase 32: Secrets pattern + key rotation - Research

**Researched:** 2026-06-18
**Domain:** local secret-reference loading, Docker Compose interpolation, provider-key rotation evidence
**Confidence:** HIGH for repo state and official-docs facts; MEDIUM for external operator availability because `op` is not installed locally. [VERIFIED: codebase grep] [CITED: https://www.1password.dev/cli/secret-references] [CITED: https://www.1password.dev/cli/reference/commands/run] [CITED: https://direnv.net/] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/] [CITED: https://platform.claude.com/docs/en/manage-claude/authentication]

## User Constraints (from CONTEXT.md)

All constraints in this section are copied from `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`; they are the planning boundary for this research. [VERIFIED: codebase grep]

### Locked Decisions

Calibration: user asked to discuss all gray areas, research them with subagents, consider ecosystem idioms and footguns, and produce one coherent recommendation set without further decision burden. Four `gsd-advisor-researcher` agents covered secret reference shape, runtime loading, rotation proof, and docs/DX. Decisions below are LOCKED.

#### Overall pattern
- **D-01:** Use a **process-scoped 1Password `op run --env-file` pattern** as the default. `direnv` configures the local project and watches the secret-reference file; it does **not** resolve the real Anthropic key into the long-lived interactive shell by default.
- **D-02:** Keep `.env` as the non-secret Docker/Phoenix configuration surface. Do not put `op://` reference values directly into `.env.example` as executable dotenv assignments because plain Docker Compose and Phoenix dotenv readers do not resolve them.
- **D-03:** Keep the runtime variable name `ANTHROPIC_API_KEY`. This matches the existing `compose.yml` critique service and native critique flow, so no app code or Compose service contract needs to change.
- **D-04:** Do **not** read `.env`, shell history, logs, screenshots, or any other likely secret-bearing source during this phase. The roadmap and todo already establish that a plaintext key existed; implementation only removes the pattern and records rotation.

#### Example file shape
- **D-05:** Add `.env.op.example` with dotenv syntax and an obviously replaceable secret reference:
  ```dotenv
  # Copy to .env.op (gitignored), then update the vault/item/field path.
  # 1Password secret reference format:
  #   op://<vault>/<item>/<field>
  ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY
  ```
- **D-06:** Add `.envrc.example` as local configuration, not a secret resolver:
  ```bash
  # Copy to .envrc (gitignored), then run: direnv allow .
  #
  # Secrets are resolved only for op-wrapped commands:
  #   op run --env-file "$SCORIA_OP_ENV_FILE" -- <command>
  export SCORIA_OP_ENV_FILE="${SCORIA_OP_ENV_FILE:-.env.op}"
  watch_file "$SCORIA_OP_ENV_FILE"
  
  if ! has op; then
    log_error "1Password CLI not found. Install op before running critique commands."
  fi
  ```
- **D-07:** Do **not** use `direnv_load op run --env-file .env.op --no-masking -- direnv dump` as the default. It is idiomatic and ergonomic, but it resolves the real API key into the shell environment for as long as the repo directory is active. That is a deliberate opt-in escape hatch for a future doc, not the baseline for this security-remediation phase.
- **D-08:** Replace the `.env.example` plaintext stub with comments only. Recommended shape:
  ```dotenv
  # ANTHROPIC_API_KEY is loaded from .env.op through 1Password.
  # Example secret reference:
  #   op://Private/scoria-dev/ANTHROPIC_API_KEY
  #
  # Run secret-consuming commands with:
  #   op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- <command>
  ```

#### Runtime commands
- **D-09:** Document these as the canonical secret-consuming command shapes:
  ```bash
  op signin
  op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
  op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
  ```
- **D-10:** Make the docs explicit that normal dashboard/dev startup does not need `ANTHROPIC_API_KEY`; only the LLM critique pass needs it. This keeps security setup from feeling like a prerequisite for ordinary local dev.
- **D-11:** Do not add new Make targets or wrapper scripts in Phase 32 unless the planner finds an existing target that must be corrected. Wrapper targets may improve DX later, but the phase success criteria are examples, gitignore, docs, and rotation tracking.

#### Rotation proof
- **D-12:** Treat SEC-02 as a **ship blocker until maintainer attestation is recorded**. Source files cannot prove Anthropic-side revocation or rotation.
- **D-13:** The phase record may store only a structured redacted attestation:
  - maintainer name/handle
  - UTC date of Anthropic console rotation/revocation
  - affected environment label, e.g. "local critique key"
  - evidence class reviewed privately, e.g. "Anthropic Console API Keys page" or "private ticket"
  - explicit statement: no secret value, prefix, suffix, screenshot, or token material was recorded in the repo
- **D-14:** Do not claim agent-verified rotation unless the executor personally reviewed redacted evidence. If not reviewed, write "maintainer attested" rather than "verified."
- **D-15:** Recommended SUMMARY/VERIFICATION wording:
  ```text
  SEC-02: Maintainer attested that the previously on-disk ANTHROPIC_API_KEY was rotated/revoked in the Anthropic Console on <UTC date>. Evidence was reviewed out of band (<evidence class>). No secret value, prefix, suffix, screenshot, or token material is stored in this repository.
  ```

#### Docs placement and tone
- **D-16:** Add a compact `## Secrets (ANTHROPIC_API_KEY)` section to `docs/docker_dev_dx.md` **after** the layer-cache invalidation section and **before** `## Adopting this in another repo`.
- **D-17:** Section outline:
  1. one sentence: critique needs a provider key; normal dashboard/dev does not
  2. `### First-time setup`: install `direnv` + 1Password CLI, add shell hook, `op signin`, copy examples, edit `.env.op`, `direnv allow .`
  3. `### Run the critique pass`: the two canonical `op run --env-file` commands
  4. `### How it works`: `.env.op` stores `op://` secret references only; `op run` resolves them for the child process; Compose inherits shell environment for interpolation
  5. `### Footguns`: never commit `.envrc`/`.env.op`, do not place real keys in `.envrc` or `.env`, sign in/unlock 1Password first, rerun `direnv allow .` after `.envrc` edits, rotate any key that touched disk
- **D-18:** Keep the copy calm, exact, and useful per the brandbook. Use "secret reference" for `op://` values and "plaintext key" for real keys. Avoid security theater and hype. Keep troubleshooting to 4-6 bullets, not a separate runbook.

#### Folded Todos
- **docker-dx-fleet-hardening.md:** Fold only the security item into Phase 32: the untracked plaintext `.env` `ANTHROPIC_API_KEY` must be rotated, and the repo should adopt a 1Password CLI / direnv pattern. The cross-repo fleet convergence items remain out of scope.

### the agent's Discretion
- Exact doc prose, example comments, and shell microcopy may be refined as long as the process-scoped `op run --env-file` default, `.env` non-secret boundary, and non-sensitive rotation-attestation standard remain intact.
- The planner may add a small note about the more ergonomic `direnv_load ... direnv dump` variant only as an explicit tradeoff/escape hatch if it does not distract from the default.

### Deferred Ideas (OUT OF SCOPE)
- **Automatic `direnv_load op run ... direnv dump` secret loading** - researched and rejected as the default because it resolves the real API key into the active shell environment. May be documented later as an opt-in ergonomic tradeoff.
- **Make targets/wrapper scripts for critique-with-secrets** - useful future DX, but not necessary for SEC-01/SEC-02 and not in Phase 32 success criteria.
- **Dedicated `docs/secrets.md` runbook** - too much structure for this phase; Phase 33 may revisit docs IA.
- **Cross-repo sibling migration** - remains deferred to FLEET-01.

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the repository root, so there are no additional AGENTS.md directives for this phase. [VERIFIED: `test -f AGENTS.md`]

No project-local `.codex/skills/` or `.agents/skills/` directory exists, so there are no project skill rules to fold into the plan. [VERIFIED: `test -d .codex/skills` and `test -d .agents/skills`]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-01 | Maintainer can keep provider API keys out of plaintext on disk via a documented direnv + 1Password (`op run`) pattern, with committed `.envrc.example` and `.env.op.example`, the plaintext key removed from `.env.example`, and `.envrc`/`.env.op` gitignored. [VERIFIED: `.planning/REQUIREMENTS.md:24-27`] | Use process-scoped `op run --env-file`, commit examples containing only secret references/comments, add `.envrc` and `.env.op` to `.gitignore`, and update `docs/docker_dev_dx.md` with setup/run/footgun copy. [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `.env.example:11-16`] |
| SEC-02 | The previously on-disk `ANTHROPIC_API_KEY` is rotated as an out-of-band maintainer action on the Anthropic console and tracked as a pre-ship requirement. [VERIFIED: `.planning/REQUIREMENTS.md:24-27`] | Source files cannot prove provider-side revocation, so the plan must include a human checkpoint for redacted maintainer attestation and must forbid token material, prefixes, suffixes, and screenshots in the repo. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised] |

## Summary

Phase 32 is a narrow remediation slice: remove the committed plaintext Anthropic example pattern from `.env.example`, add committed examples for `.envrc` and `.env.op`, gitignore the real local files, document the process-scoped command pattern in `docs/docker_dev_dx.md`, and record non-sensitive rotation attestation. [VERIFIED: `.planning/ROADMAP.md:270-279`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

The recommended implementation keeps `.env` non-secret and lets `direnv` export only `SCORIA_OP_ENV_FILE`, while `op run --env-file` resolves `op://` references only for the wrapped child process. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/reference/commands/run] This matches the existing `compose.yml` contract because the `critique` service already reads `ANTHROPIC_API_KEY` from Compose interpolation, and the native critique flow already checks `System.get_env("ANTHROPIC_API_KEY")`. [VERIFIED: `compose.yml:109-133`] [VERIFIED: `lib/scoria/ui_critique.ex:75-100`]

**Primary recommendation:** implement only the five file-surface changes plus a redacted SEC-02 attestation checkpoint; do not inspect `.env`, shell history, logs, screenshots, process environments, or other likely secret-bearing sources. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Current State Observations

| Area | Observation | Planning Implication |
|------|-------------|----------------------|
| Phase scope | Phase 32 success criteria require committed `.envrc.example` and `.env.op.example`, `.gitignore` entries for `.envrc`/`.env.op`, removal of the plaintext `.env.example` Anthropic stub, a Docker DX Secrets section, and maintainer-confirmed rotation. [VERIFIED: `.planning/ROADMAP.md:270-279`] | Plan one docs/examples slice plus one human SEC-02 checkpoint. [VERIFIED: `.planning/ROADMAP.md:270-279`] |
| Requirements | SEC-01 and SEC-02 are the only phase requirements. [VERIFIED: `.planning/REQUIREMENTS.md:24-27`] | Do not widen into DOCS-01/02/03, release, or cross-repo fleet work. [VERIFIED: `.planning/REQUIREMENTS.md:29-39`] |
| `.env.example` | The file currently documents the LLM critique pass and ends with `ANTHROPIC_API_KEY=sk-ant-...`. [VERIFIED: `.env.example:11-16`] | Replace that assignment with comment-only guidance and an `op://` example reference. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| `.gitignore` | `.gitignore` currently ignores `.env` but not `.envrc` or `.env.op`. [VERIFIED: `.gitignore:48`] | Add `.envrc` and `.env.op` next to `.env`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Example files | `.envrc.example` and `.env.op.example` do not exist. [VERIFIED: `ls -la .envrc.example .env.op.example`] | Create both new committed examples. [VERIFIED: `.planning/ROADMAP.md:277`] |
| Docs placement | `docs/docker_dev_dx.md` currently ends the layer-cache table at line 103 and begins `## Adopting this in another repo` at line 105. [VERIFIED: `docs/docker_dev_dx.md:89-105`] | Insert `## Secrets (ANTHROPIC_API_KEY)` between those sections. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Docker contract | The `critique` service already has `ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}` and is profile-gated under `shots`. [VERIFIED: `compose.yml:109-133`] | Do not change `compose.yml`; feed the existing variable through `op run`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Native contract | `Scoria.UICritique` raises if `ANTHROPIC_API_KEY` is not set when the critique call fails, and the Mix task marks `--critique` as requiring that variable. [VERIFIED: `lib/scoria/ui_critique.ex:75-100`] [VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex:14-16`] | Keep the runtime env var name unchanged. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Existing Make target | `make critique` currently shells `docker compose --profile shots run --rm critique` with no secret wrapper. [VERIFIED: `Makefile:98-100`] | Do not add a Phase 32 wrapper target; document the explicit `op run` command instead. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Source of rotation concern | The pending Docker DX todo states that untracked `.env` held a real-looking plaintext `ANTHROPIC_API_KEY` and says to rotate it. [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] | Treat SEC-02 as an out-of-band maintainer action; do not inspect `.env`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Tooling availability | `direnv` 2.36.0, Docker 29.5.2, Docker Compose v5.1.3, and Mix 1.19.5 are installed locally; `op` is not installed locally. [VERIFIED: `direnv version`] [VERIFIED: `docker --version`] [VERIFIED: `docker compose version`] [VERIFIED: `mix --version`] [VERIFIED: `command -v op`] | Implementation can write docs/examples locally, but actual secret-resolution and rotation verification require a maintainer/operator checkpoint. [VERIFIED: environment probe] |
| Graph context | `.planning/graphs/graph.json` is absent. [VERIFIED: `find .planning/graphs -name graph.json`] | No graph-derived dependencies are available for this phase. [VERIFIED: `find .planning/graphs -name graph.json`] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Secret-reference storage | Local developer config | 1Password vault | `.env.op` should store only `op://` references locally, while real key material stays in 1Password. [CITED: https://www.1password.dev/cli/secret-references] |
| Project-local activation | Local shell / direnv | None | `.envrc` should export only `SCORIA_OP_ENV_FILE` and watch the reference file; it should not resolve real secrets into the interactive shell. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://direnv.net/] |
| Docker critique execution | Docker Compose CLI / child process | 1Password CLI | `op run --env-file` resolves the env file into the subprocess environment, then Compose interpolates `ANTHROPIC_API_KEY` into the `critique` service. [CITED: https://www.1password.dev/cli/reference/commands/run] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/] [VERIFIED: `compose.yml:124-133`] |
| Native critique execution | Mix child process | 1Password CLI | `op run --env-file ... -- mix scoria.ui.shots --critique` gives the Mix task the same env var expected by `Scoria.UICritique`. [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `lib/scoria/ui_critique.ex:98-100`] |
| Rotation evidence | Phase closeout artifacts | Anthropic Console / maintainer | Source code can record only a redacted attestation; Anthropic-side revoke/create actions happen outside the repo. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised] |

## Standard Stack

### Core

| Tool | Version / Status | Purpose | Why Standard |
|------|------------------|---------|--------------|
| 1Password CLI `op` | Not installed locally; official docs current as of 2026-06-18. [VERIFIED: `command -v op`] [CITED: https://www.1password.dev/cli/reference/commands/run] | Resolve `op://` secret references from `.env.op` only for the wrapped child process. [CITED: https://www.1password.dev/cli/reference/commands/run] | `op run --env-file` is the locked default and official 1Password mechanism for env-file secret-reference loading. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/reference/commands/run] |
| `direnv` | 2.36.0 installed locally. [VERIFIED: `direnv version`] | Provide project-local non-secret config, watch `.env.op`, and surface missing `op` with `log_error`. [VERIFIED: `direnv stdlib`] [CITED: https://direnv.net/man/direnv-stdlib.1.html] | `direnv` hooks into shells and loads authorized `.envrc` changes into the current shell environment; using it only for `SCORIA_OP_ENV_FILE` avoids long-lived provider-key materialization. [CITED: https://direnv.net/] |
| Docker Compose | v5.1.3 installed locally. [VERIFIED: `docker compose version`] | Run the existing `critique` service with `ANTHROPIC_API_KEY` interpolated from the `op run` child environment. [VERIFIED: `compose.yml:124-133`] | Compose officially interpolates variables from shell environment and `.env` sources, and shell variables have top precedence for interpolation. [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/] |
| Mix / Elixir task | Mix 1.19.5 installed locally. [VERIFIED: `mix --version`] | Run native `mix scoria.ui.shots --critique` under `op run`. [VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex:14-16`] | The existing native critique path already consumes `ANTHROPIC_API_KEY`; no app contract change is needed. [VERIFIED: `lib/scoria/ui_critique.ex:98-100`] |

### Supporting

| Tool | Version / Status | Purpose | When to Use |
|------|------------------|---------|-------------|
| Anthropic Console | Not accessible to the agent; maintainer required. [ASSUMED] | Revoke/delete the previously exposed key and create or select the replacement key. [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised] | SEC-02 closeout; the planner must add a human checkpoint. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| 1Password account / vault | Not checked by the agent to avoid secret-bearing inspection. [ASSUMED] | Store the replacement `ANTHROPIC_API_KEY` field addressed by `.env.op`. [CITED: https://www.1password.dev/cli/secret-references] | First-time setup before running critique commands. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Process-scoped `op run --env-file` | `direnv_load op run --env-file .env.op --no-masking -- direnv dump` | Rejected as default because it resolves the real key into the active shell for the directory session. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| `.env.op` secret references | Plain `.env` dotenv key | Rejected because plaintext local dotenv keeps real provider keys on disk. [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] [CITED: https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure] |
| `op run` | `op inject --out-file` | Rejected for this phase because it can materialize resolved secrets into files; the locked default keeps resolution process-scoped. [CITED: https://www.1password.dev/cli/secret-references] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Explicit commands in docs | New `make critique-secret` wrapper | Deferred because Phase 32 success criteria are examples, gitignore, docs, and rotation tracking, not Makefile wrapper DX. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

**Installation:**

```bash
# No project dependency installation is required for Phase 32.
# Operator prerequisites are external tools/accounts:
# - Install 1Password CLI from official 1Password documentation.
# - Install direnv and enable the shell hook for the operator's shell.
```

**Version verification:** external project packages are not installed in this phase, so npm/PyPI/crates registry verification is not applicable. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Package Legitimacy Audit

No external npm, PyPI, crates, or Hex packages are added by this phase. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No package install required. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package recommendations]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package recommendations]

## Architecture Patterns

### System Architecture Diagram

```text
Operator setup
  |
  | copy examples
  v
.env.op (gitignored, op:// references only) -----> 1Password vault item field
  |
  | watched by
  v
.envrc (gitignored, exports SCORIA_OP_ENV_FILE only)
  |
  | direnv allow loads non-secret config
  v
interactive shell has SCORIA_OP_ENV_FILE, not ANTHROPIC_API_KEY
  |
  | secret-consuming command
  v
op run --env-file "$SCORIA_OP_ENV_FILE" -- <child command>
  |
  | resolves secret references for child process only
  +--> docker compose --profile shots run --rm critique
  |       |
  |       v
  |     Compose interpolates ANTHROPIC_API_KEY into critique service
  |
  +--> mix scoria.ui.shots --critique
          |
          v
        Scoria.UICritique reads System.get_env("ANTHROPIC_API_KEY")
```

This diagram reflects the locked process-scoped secret boundary and existing Compose/native runtime contracts. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [VERIFIED: `compose.yml:124-133`] [VERIFIED: `lib/scoria/ui_critique.ex:98-100`]

### Recommended Project Structure

```text
.
├── .env.example          # non-secret Docker/Phoenix config comments only
├── .envrc.example        # committed direnv example, no secret resolution
├── .env.op.example       # committed dotenv example with op:// reference only
├── .gitignore            # ignores .env, .envrc, and .env.op
└── docs/
    └── docker_dev_dx.md  # Secrets section after layer-cache invalidation
```

The recommended structure is limited to the surfaces named in the Phase 32 context. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Pattern 1: Process-Scoped Secret Resolution

**What:** Keep real provider keys out of `.envrc`, `.env`, and `.env.op`; store only `op://` references in `.env.op`, then wrap the specific critique command with `op run --env-file`. [CITED: https://www.1password.dev/cli/secret-references] [CITED: https://www.1password.dev/cli/reference/commands/run]

**When to use:** Use this for the Docker and native critique commands only, because normal dashboard/dev startup does not require `ANTHROPIC_API_KEY`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [VERIFIED: `compose.yml:85-133`]

**Example:**

```bash
# Source: 1Password op run docs + Phase 32 locked command shape.
op signin
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
```

`op run --env-file` loads variables from the environment file and provides resolved secret values to the subprocess only for the subprocess duration. [CITED: https://www.1password.dev/cli/reference/commands/run]

### Pattern 2: Direnv Configures the Path, Not the Secret

**What:** `.envrc` should export `SCORIA_OP_ENV_FILE`, watch that file, and warn if `op` is missing; it should not call `op run`, `op read`, `op inject`, or `direnv_load` in the default path. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://direnv.net/man/direnv-stdlib.1.html]

**When to use:** Use this whenever a developer enters the repo and wants a stable pointer to the secret-reference dotenv file. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Example:**

```bash
# Source: Phase 32 D-06, direnv stdlib has/watch_file/log_error.
export SCORIA_OP_ENV_FILE="${SCORIA_OP_ENV_FILE:-.env.op}"
watch_file "$SCORIA_OP_ENV_FILE"

if ! has op; then
  log_error "1Password CLI not found. Install op before running critique commands."
fi
```

`has` returns success when a command is available, and `watch_file` causes direnv to reload after the watched file changes. [CITED: https://direnv.net/man/direnv-stdlib.1.html] The local `direnv stdlib` output also confirms `log_error` is available in the installed direnv version. [VERIFIED: `direnv stdlib`]

### Pattern 3: Keep `.env.example` Comment-Only for Secrets

**What:** `.env.example` should continue documenting non-secret Compose/Phoenix config, but the `ANTHROPIC_API_KEY` section should be comments only. [VERIFIED: `.env.example:1-16`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**When to use:** Use this because plain Docker Compose and dotenv readers do not resolve 1Password secret references, while `op run` does. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/reference/commands/run] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]

**Example:**

```dotenv
# Source: Phase 32 D-08.
# ANTHROPIC_API_KEY is loaded from .env.op through 1Password.
# Example secret reference:
#   op://Private/scoria-dev/ANTHROPIC_API_KEY
#
# Run secret-consuming commands with:
#   op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- <command>
```

### Anti-Patterns to Avoid

- **Resolving secrets in `.envrc`:** This turns a per-command key into a long-lived shell variable for the directory session. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://direnv.net/]
- **Using `--no-masking` in docs or examples:** 1Password documents that this flag disables output masking, so it should not appear in Phase 32 examples. [CITED: https://www.1password.dev/cli/reference/commands/run]
- **Putting `op://` assignments directly in `.env.example`:** Docker Compose can interpolate environment files but does not resolve 1Password references; the comments should point to `.env.op` and `op run`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]
- **Writing resolved keys to files with `op read --out-file` or `op inject --out-file`:** 1Password supports those flows, but Phase 32 requires no plaintext provider key on disk. [CITED: https://www.1password.dev/cli/secret-references] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]
- **Recording screenshots or token fragments as SEC-02 proof:** The phase evidence must record redacted attestation only. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Recommended Implementation Approach

### `.env.op.example`

Create the file exactly as a committed dotenv-format example with one `op://` reference and no plaintext secret. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/secret-references]

```dotenv
# Copy to .env.op (gitignored), then update the vault/item/field path.
# 1Password secret reference format:
#   op://<vault>/<item>/<field>
ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY
```

The placeholder vault/item path is intentionally replaceable; the real vault/item/field naming is an operator-local choice. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [ASSUMED]

### `.envrc.example`

Create the file as a local configuration example that exports only `SCORIA_OP_ENV_FILE`, watches the referenced file, and logs a missing-CLI warning. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://direnv.net/man/direnv-stdlib.1.html]

```bash
# Copy to .envrc (gitignored), then run: direnv allow .
#
# Secrets are resolved only for op-wrapped commands:
#   op run --env-file "$SCORIA_OP_ENV_FILE" -- <command>
export SCORIA_OP_ENV_FILE="${SCORIA_OP_ENV_FILE:-.env.op}"
watch_file "$SCORIA_OP_ENV_FILE"

if ! has op; then
  log_error "1Password CLI not found. Install op before running critique commands."
fi
```

Do not add `dotenv`, `op read`, `op inject`, `direnv_load`, `--no-masking`, or a direct `ANTHROPIC_API_KEY` export to `.envrc.example`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/reference/commands/run]

### `.env.example`

Replace lines 11-16's plaintext critique stub with comment-only guidance that names `.env.op`, shows an `op://` reference as an example, and shows the generic `op run` wrapper form. [VERIFIED: `.env.example:11-16`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

Keep the multi-instance identity section unchanged because `.env` remains the non-secret Compose/Phoenix configuration surface. [VERIFIED: `.env.example:1-10`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### `.gitignore`

Add `.envrc` and `.env.op` directly adjacent to the existing `.env` ignore rule. [VERIFIED: `.gitignore:48`] This keeps the real local direnv file and real secret-reference dotenv file out of Git. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### `docs/docker_dev_dx.md`

Insert `## Secrets (ANTHROPIC_API_KEY)` after the layer-cache table and before `## Adopting this in another repo`. [VERIFIED: `docs/docker_dev_dx.md:89-105`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

The section should say that normal dashboard/dev startup does not need a provider key and that only the screenshot critique pass needs `ANTHROPIC_API_KEY`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [VERIFIED: `compose.yml:85-133`]

The section should include `### First-time setup`, `### Run the critique pass`, `### How it works`, and `### Footguns` subsections. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

The run commands should be exactly the two canonical wrapped commands from D-09, plus `op signin` before them. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Rotation Attestation

Add a SEC-02 closeout item to the phase SUMMARY or VERIFICATION artifact after the maintainer completes Anthropic Console rotation/revocation. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] Anthropic docs say leaked or suspected-compromised keys should be revoked, and a replacement key can be created from the API Keys page. [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised]

The attestation must include maintainer name/handle, UTC date, affected environment label, evidence class reviewed privately, and the explicit statement that no secret value, prefix, suffix, screenshot, or token material was recorded in the repo. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

If the executor did not personally review redacted evidence, the wording must say "maintainer attested" rather than "verified". [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret-reference resolution | Custom parser for `op://` URIs | `op run --env-file` | 1Password CLI already scans env vars/files for secret references and loads resolved values into the subprocess environment. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| Local secret storage | Plaintext `.env` with real provider key | `.env.op` with `op://` reference plus 1Password vault | Anthropic recommends secrets managers and revoking leaked keys; local plaintext dotenv is the pattern being remediated. [CITED: https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure] [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] |
| Shell activation | `direnv_load op run ... direnv dump` default | `direnv` exports only `SCORIA_OP_ENV_FILE` | `direnv_load` adopts a child process environment, which conflicts with the locked no-long-lived-key default. [CITED: https://direnv.net/man/direnv-stdlib.1.html] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Docker wrapper DX | New Make target in Phase 32 | Explicit docs command | Make wrapper work is deferred unless an existing target must be corrected. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Rotation proof | Token screenshots, prefixes, suffixes, or copied values | Redacted structured attestation | Secret material in evidence would reintroduce the exposure the phase is removing. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

**Key insight:** the safe boundary is not "dotenv versus no dotenv"; it is "secret references on disk, resolved only into the child process that needs them." [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Runtime Secret State Inventory

This phase is not a rename/refactor, but SEC-02 is a secret-rotation remediation, so the planner needs an explicit state inventory without inspecting likely secret-bearing sources. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | No repository database or app table was identified as storing `ANTHROPIC_API_KEY` for this phase; the critique flow reads the variable from process env. [VERIFIED: `lib/scoria/ui_critique.ex:98-100`] | No data migration. [VERIFIED: `lib/scoria/ui_critique.ex:98-100`] |
| Live service config | Anthropic Console holds API keys and supports API-key creation/revocation. [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised] | Maintainer must revoke/rotate the previously exposed key and attest the action. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| OS-registered state | Not inspected, because shell profiles/history/process environments can be secret-bearing. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Do not inspect from the agent; docs can advise operators not to keep `ANTHROPIC_API_KEY` in shell profiles. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Secrets/env vars | The todo and context establish that untracked `.env` previously held a plaintext Anthropic key; `.env` itself was not inspected. [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Remove the committed `.env.example` plaintext pattern, add ignored `.env.op` pattern, and rotate/revoke the actual exposed key out of band. [VERIFIED: `.planning/ROADMAP.md:277-279`] |
| Build artifacts | No build artifact surface was identified as a provider-key source in the allowed files. [VERIFIED: allowed-file grep] | No artifact cleanup task recommended; do not search logs/screenshots for secret material. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

## Common Pitfalls

### Pitfall 1: Resolving the Key into the Long-Lived Shell

**What goes wrong:** `direnv_load op run ... direnv dump`, direct `export ANTHROPIC_API_KEY=...`, or sourcing a plaintext dotenv file leaves a real key in the interactive shell. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Why it happens:** `direnv` is designed to load exported variables into the current shell after an authorized `.envrc` runs. [CITED: https://direnv.net/]

**How to avoid:** `.envrc.example` should export only `SCORIA_OP_ENV_FILE`; wrap only the child critique command with `op run --env-file`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://www.1password.dev/cli/reference/commands/run]

**Warning signs:** `.envrc.example` contains `ANTHROPIC_API_KEY`, `direnv_load`, `op read`, `op inject`, or `--no-masking`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Pitfall 2: Putting Secret References Where Plain Readers Expect Plain Values

**What goes wrong:** A user puts `ANTHROPIC_API_KEY=op://...` into `.env` or as an executable `.env.example` assignment, then Docker Compose or a dotenv reader passes the unresolved reference instead of the real key. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]

**Why it happens:** Compose interpolates strings from shell or `.env`; it does not call 1Password. [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]

**How to avoid:** Keep `.env.example` as comments for the Anthropic key and put executable secret-reference assignments only in `.env.op`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Warning signs:** `.env.example` has a live `ANTHROPIC_API_KEY=` assignment. [VERIFIED: `.env.example:16`]

### Pitfall 3: Disabling 1Password Masking

**What goes wrong:** Adding `--no-masking` to examples can print actual secrets to stdout or stderr. [CITED: https://www.1password.dev/cli/reference/commands/run]

**Why it happens:** The flag exists for debugging and examples in upstream docs, but it is unsafe for this remediation phase. [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**How to avoid:** Do not include `--no-masking` in `.envrc.example`, docs, verification commands, or phase artifacts. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Warning signs:** `rg -- '--no-masking' .envrc.example .env.op.example .env.example docs/docker_dev_dx.md` returns any match. [VERIFIED: proposed validation command]

### Pitfall 4: Treating File Edits as Rotation Proof

**What goes wrong:** The repo removes plaintext examples but the exposed Anthropic key remains active. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Why it happens:** Anthropic API key revocation happens in Anthropic Console, not in source control. [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised]

**How to avoid:** Make SEC-02 a human checkpoint and block closeout until redacted maintainer attestation is recorded. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

**Warning signs:** SUMMARY says "rotated" without UTC date, maintainer handle, evidence class, or redaction statement. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Code Examples

### `.env.op.example`

```dotenv
# Source: Phase 32 D-05 and 1Password secret reference syntax.
# Copy to .env.op (gitignored), then update the vault/item/field path.
# 1Password secret reference format:
#   op://<vault>/<item>/<field>
ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY
```

1Password secret-reference syntax uses `op://<vault-name>/<item-name>/[section-name/]<field-name>`. [CITED: https://www.1password.dev/cli/secret-references]

### `.envrc.example`

```bash
# Source: Phase 32 D-06 and direnv stdlib.
# Copy to .envrc (gitignored), then run: direnv allow .
#
# Secrets are resolved only for op-wrapped commands:
#   op run --env-file "$SCORIA_OP_ENV_FILE" -- <command>
export SCORIA_OP_ENV_FILE="${SCORIA_OP_ENV_FILE:-.env.op}"
watch_file "$SCORIA_OP_ENV_FILE"

if ! has op; then
  log_error "1Password CLI not found. Install op before running critique commands."
fi
```

`direnv allow .` is required after creating or changing an authorized `.envrc`. [CITED: https://direnv.net/] `watch_file` reloads direnv after the watched file changes. [CITED: https://direnv.net/man/direnv-stdlib.1.html]

### `.env.example` Anthropic Section

```dotenv
# Source: Phase 32 D-08.
# --- LLM critique pass -------------------------------------------------------
# Only needed for the screenshot critique pass; the screenshot-only pass needs
# no key.
#
# ANTHROPIC_API_KEY is loaded from .env.op through 1Password.
# Example secret reference:
#   op://Private/scoria-dev/ANTHROPIC_API_KEY
#
# Run secret-consuming commands with:
#   op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- <command>
```

This keeps `.env.example` non-executable for provider secrets while still pointing operators to the executable `.env.op` path. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### `docs/docker_dev_dx.md` Run Commands

```bash
# Source: Phase 32 D-09.
op signin
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
```

`op run --env-file` enables dotenv integration for the specified env file. [CITED: https://www.1password.dev/cli/reference/commands/run]

### Redacted Rotation Attestation Template

```text
SEC-02: Maintainer attested that the previously on-disk ANTHROPIC_API_KEY was rotated/revoked in the Anthropic Console on <UTC date>. Evidence was reviewed out of band (<evidence class>). No secret value, prefix, suffix, screenshot, or token material is stored in this repository.
```

This is the locked attestation wording for Phase 32 closeout. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plaintext provider key in local dotenv and a plaintext-looking `.env.example` assignment. [VERIFIED: `.env.example:11-16`] [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] | Secret reference in `.env.op`, resolved by `op run --env-file` for the exact child command. [CITED: https://www.1password.dev/cli/reference/commands/run] | Phase 32 implementation. [VERIFIED: `.planning/ROADMAP.md:270-279`] | Real key material no longer needs to live in committed examples or repo-local plaintext files. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Treating local docs cleanup as enough. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Redacted maintainer attestation of Anthropic Console revoke/rotate before closeout. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Phase 32 implementation. [VERIFIED: `.planning/ROADMAP.md:277-279`] | SEC-02 remains a ship blocker until provider-side key state is addressed. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Broad secret runbook. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Compact Docker DX section tied to the critique pass. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Phase 32 implementation. [VERIFIED: `.planning/ROADMAP.md:278`] | Keeps ordinary local dev from feeling blocked by provider-key setup. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

**Deprecated/outdated:**
- `.env.example` live `ANTHROPIC_API_KEY=sk-ant-...` assignment: remove it and replace with comments only. [VERIFIED: `.env.example:16`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]
- Native docs suggesting `set -a; . ./.env; set +a; mix scoria.ui.shots --critique`: remove this from `.env.example` because it teaches plaintext dotenv sourcing for a secret-consuming path. [VERIFIED: `.env.example:14-15`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The maintainer has or can obtain access to the Anthropic Console API Keys page for the affected key. [ASSUMED] | Standard Stack, Rotation Attestation | SEC-02 cannot be closed without a maintainer who can rotate/revoke. |
| A2 | The maintainer has or can create a 1Password vault/item/field path for `ANTHROPIC_API_KEY`. [ASSUMED] | Standard Stack, `.env.op.example` | `.env.op` setup remains blocked until a real secret reference is chosen. |
| A3 | The affected key should be labelled "local critique key" unless the maintainer supplies a more precise environment label. [ASSUMED] | Rotation Attestation | Ambiguous evidence could make future audits unclear. |

## Open Questions (RESOLVED)

1. **RESOLVED - What exact 1Password vault/item/field should the maintainer use?** [ASSUMED]
   - What we know: examples should use `op://Private/scoria-dev/ANTHROPIC_API_KEY`. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]
   - Resolution for planning: keep the committed example generic and require the operator to edit `.env.op` locally. The real vault/item/field path is an operator-local setup value, not a planning blocker. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

2. **RESOLVED - Who records the SEC-02 attestation and what evidence class is available?** [ASSUMED]
   - What we know: SEC-02 requires maintainer confirmation before ship. [VERIFIED: `.planning/ROADMAP.md:277-279`]
   - Resolution for planning: Plan 02 must pause for maintainer-provided redacted attestation fields and default wording to "maintainer attested" unless redacted evidence is personally reviewed by the executor. The evidence class is recorded as a redacted label only. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

3. **RESOLVED - Should `docs/MAINTAINERS.md` be updated in this phase?**
   - What we know: Phase 32 context names `docs/docker_dev_dx.md` as the docs edit surface and defers broader docs IA to Phase 33. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]
   - Resolution for planning: do not expand Phase 32. Leave broader docs harmonization to Phase 33 unless the maintainer explicitly changes scope. [VERIFIED: `.planning/ROADMAP.md:283-294`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| 1Password CLI `op` | Running secret-consuming critique commands | No [VERIFIED: `command -v op`] | n/a | Human/operator installs `op`; implementation of examples/docs is not blocked. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| 1Password account/vault | Resolving `.env.op` references | Not checked [ASSUMED] | n/a | Human/operator supplies vault/item/field; do not inspect secrets from agent. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| `direnv` | `.envrc` workflow | Yes [VERIFIED: `direnv version`] | 2.36.0 [VERIFIED: `direnv version`] | None needed for docs/examples; users without direnv cannot use the `.envrc` convenience. [CITED: https://direnv.net/] |
| Docker | Docker critique command | Yes [VERIFIED: `docker --version`] | 29.5.2 [VERIFIED: `docker --version`] | Native `mix scoria.ui.shots --critique` under `op run` if Docker is unavailable. [VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex:14-16`] |
| Docker Compose | Docker critique command | Yes [VERIFIED: `docker compose version`] | v5.1.3 [VERIFIED: `docker compose version`] | Native `mix scoria.ui.shots --critique` under `op run` if Compose is unavailable. [VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex:14-16`] |
| Mix / Elixir | Native critique command and static tests | Yes [VERIFIED: `mix --version`] | Mix 1.19.5 / OTP 28 [VERIFIED: `mix --version`] | Docker critique command if native Mix is unavailable. [VERIFIED: `compose.yml:109-133`] |
| Anthropic Console access | SEC-02 rotation | Not available to agent [ASSUMED] | n/a | Maintainer checkpoint is required; no repo-only fallback can prove rotation. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

**Missing dependencies with no fallback:**
- Anthropic Console access for SEC-02 rotation/revocation is a human-required ship blocker. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised]
- 1Password CLI is missing locally for actually running `op run`, but this does not block writing the examples/docs. [VERIFIED: `command -v op`]

**Missing dependencies with fallback:**
- Docker or Compose absence would have a native Mix critique fallback, but both are available locally. [VERIFIED: `docker --version`] [VERIFIED: `docker compose version`] [VERIFIED: `lib/mix/tasks/scoria.ui.shots.ex:14-16`]

## Verification Architecture

Use targeted checks only; do not scan `.env`, shell history, logs, screenshots, process environments, or any other likely secret-bearing source. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Static Acceptance Checks

```bash
# SEC-01 file presence
test -f .envrc.example
test -f .env.op.example

# SEC-01 gitignore
grep -qxF '.env' .gitignore
grep -qxF '.envrc' .gitignore
grep -qxF '.env.op' .gitignore

# SEC-01 example boundaries
grep -qxF 'ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY' .env.op.example
grep -q 'SCORIA_OP_ENV_FILE' .envrc.example
grep -q 'watch_file "$SCORIA_OP_ENV_FILE"' .envrc.example
grep -q 'has op' .envrc.example

# SEC-01 no live Anthropic assignment in .env.example
! grep -nE '^ANTHROPIC_API_KEY=' .env.example
grep -q 'op://Private/scoria-dev/ANTHROPIC_API_KEY' .env.example

# SEC-01 docs
grep -q '^## Secrets (ANTHROPIC_API_KEY)' docs/docker_dev_dx.md
grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique' docs/docker_dev_dx.md
grep -q 'op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique' docs/docker_dev_dx.md

# Footgun guards on touched safe files only
! grep -n -- '--no-masking' .envrc.example .env.op.example .env.example docs/docker_dev_dx.md
! grep -nE 'direnv_load|op read|op inject|export ANTHROPIC_API_KEY' .envrc.example docs/docker_dev_dx.md
! grep -nE 'ANTHROPIC_API_KEY=sk-ant-|ANTHROPIC_API_KEY=.*sk-ant-' .env.example .envrc.example .env.op.example docs/docker_dev_dx.md
```

These checks intentionally target only files Phase 32 edits or creates. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Rotation Attestation Checks

```bash
# Run after phase closeout artifacts exist; target only phase artifacts.
grep -q 'SEC-02:' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md
grep -q 'Maintainer attested' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md
grep -q 'No secret value, prefix, suffix, screenshot, or token material' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md
! grep -nE 'sk-ant-[A-Za-z0-9_-]+' .planning/phases/32-secrets-pattern-key-rotation/32-02-SUMMARY.md .planning/phases/32-secrets-pattern-key-rotation/32-VERIFICATION.md
```

The attestation check cannot prove provider-side rotation; it only verifies the repo contains the required redacted record and no obvious Anthropic token material in phase closeout artifacts. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5. [VERIFIED: `mix --version`] |
| Config file | `mix.exs`; test files are loaded from `test/**/*_test.exs` excluding fixtures/host overlay paths. [VERIFIED: `mix.exs:20-26`] [VERIFIED: `mix.exs:62-66`] |
| Quick run command | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` [VERIFIED: `.github/workflows/ci-verify.yml:53-56`] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: `.github/workflows/ci-verify.yml`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SEC-01 | `.envrc.example` and `.env.op.example` exist, `.envrc`/`.env.op` are gitignored, `.env.example` has no live Anthropic assignment, docs contain the process-scoped command pattern, and touched safe files avoid footguns. [VERIFIED: `.planning/REQUIREMENTS.md:24-27`] | static shell acceptance | Run the `Static Acceptance Checks` block above. [VERIFIED: proposed validation command] | Not a test file; shell checks are sufficient for this docs/examples phase. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| SEC-02 | Redacted maintainer attestation exists and phase artifacts do not store obvious Anthropic token material. [VERIFIED: `.planning/REQUIREMENTS.md:24-27`] | human checkpoint + static artifact check | Run the `Rotation Attestation Checks` block after closeout artifacts exist. [VERIFIED: proposed validation command] | Requires `32-02-SUMMARY.md` / `32-VERIFICATION.md` after execution. [VERIFIED: GSD phase artifact convention] |

### Sampling Rate

- **Per task commit:** run the targeted static acceptance checks for the files touched in that task. [VERIFIED: proposed validation command]
- **Per wave merge:** run `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` to ensure existing policy-lane contracts still pass. [VERIFIED: `.github/workflows/ci-verify.yml:53-56`]
- **Phase gate:** require SEC-02 maintainer attestation before `$gsd-verify-work`; no repo-only command can close SEC-02. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]

### Wave 0 Gaps

- No new ExUnit test is required for Phase 32 because Phase 34 is already scoped to add the Docker DX doc contract test and Phase 32's locked file list is examples/docs/attestation. [VERIFIED: `.planning/ROADMAP.md:296-305`] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`]
- If the planner chooses to add a durable SEC-01 static guard now, append it to `test/scoria/ci_policy_contract_test.exs`, which already runs in the policy lane with no DB and no app start. [VERIFIED: `test/scoria/ci_policy_contract_test.exs:1-2`] [VERIFIED: `.github/workflows/ci-verify.yml:53-56`]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Yes, for provider API authentication, not user login. [CITED: https://platform.claude.com/docs/en/manage-claude/authentication] | Keep API key in 1Password and expose it only as `ANTHROPIC_API_KEY` to the child process that calls Claude. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| V3 Session Management | No app-session change in this phase. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | No session-control work. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| V4 Access Control | Yes, for access to secret material and rotation evidence. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | 1Password vault permissions and redacted attestation; no token material in Git. [CITED: https://www.1password.dev/cli/secret-references] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| V5 Input Validation | Limited. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Do not parse or validate custom secret-reference syntax in app code; leave resolution to `op run`. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| V6 Cryptography | Yes, for secret storage. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Use 1Password/Anthropic-managed secret storage and key rotation; do not hand-roll encryption or local secret files. [CITED: https://www.1password.dev/cli/secret-references] [CITED: https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext provider key committed or copied into example files. [VERIFIED: `.env.example:16`] | Information Disclosure | Remove live secret assignments from `.env.example`; commit only comments and `op://` examples. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Real key remains active after local exposure. [VERIFIED: `.planning/todos/pending/docker-dx-fleet-hardening.md:56-58`] | Elevation of Privilege / Information Disclosure | Revoke/delete the exposed key in Anthropic Console and create/use a replacement stored in a secrets manager. [CITED: https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised] |
| Secret resolved into a long-lived shell environment. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Information Disclosure | Keep direnv non-secret and run only critique commands through `op run --env-file`. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| Secret printed during debugging. [CITED: https://www.1password.dev/cli/reference/commands/run] | Information Disclosure | Do not use `--no-masking`; do not print `env`, `printenv`, or command output containing key material. [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |
| Unresolved `op://` value passed to app. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Denial of Service / Misconfiguration | Keep `op://` assignments in `.env.op` and require `op run --env-file` around the command. [CITED: https://www.1password.dev/cli/reference/commands/run] |
| Evidence artifact leaks token fragment. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] | Information Disclosure | Store only structured attestation fields and forbid secret value, prefix, suffix, screenshot, or token material. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- Local phase context: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md` - locked decisions D-01..D-18, file-surface scope, and rotation-attestation contract. [VERIFIED: codebase grep]
- Local roadmap/requirements: `.planning/ROADMAP.md:270-279` and `.planning/REQUIREMENTS.md:24-27` - Phase 32 goal and SEC-01/SEC-02. [VERIFIED: codebase grep]
- Local implementation surfaces: `.env.example`, `.gitignore`, `docs/docker_dev_dx.md`, `compose.yml`, `Makefile`, `lib/scoria/ui_critique.ex`, and `lib/mix/tasks/scoria.ui.shots.ex`. [VERIFIED: codebase grep]
- 1Password Developer - secret references and `op run --env-file`: `https://www.1password.dev/cli/secret-references` and `https://www.1password.dev/cli/reference/commands/run`. [CITED: official docs]
- direnv docs - shell behavior, stdlib `has`, `direnv_load`, and `watch_file`: `https://direnv.net/` and `https://direnv.net/man/direnv-stdlib.1.html`. [CITED: official docs]
- Docker Compose docs - variable interpolation and shell/environment-file precedence: `https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/`. [CITED: official docs]
- Anthropic/Claude docs and support - API key auth, storage, rotation, and revoke/create actions: `https://platform.claude.com/docs/en/manage-claude/authentication`, `https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure`, and `https://support.claude.com/en/articles/8384961-what-should-i-do-if-i-suspect-my-api-key-has-been-compromised`. [CITED: official docs]

### Secondary (MEDIUM confidence)

- Local environment probes for CLI availability and versions. [VERIFIED: `command -v`, `--version`, `direnv stdlib`]

### Tertiary (LOW confidence)

- Assumptions about maintainer Anthropic Console access and the real 1Password vault/item/field path. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH for chosen pattern and docs, MEDIUM for local `op` execution because `op` is not installed here. [CITED: https://www.1password.dev/cli/reference/commands/run] [VERIFIED: `command -v op`]
- Architecture: HIGH because it follows locked Phase 32 decisions and existing Compose/native runtime contracts. [VERIFIED: `.planning/phases/32-secrets-pattern-key-rotation/32-CONTEXT.md`] [VERIFIED: `compose.yml:124-133`] [VERIFIED: `lib/scoria/ui_critique.ex:98-100`]
- Pitfalls: HIGH for `--no-masking`, `direnv_load`, and Compose interpolation footguns because they are grounded in official docs and locked decisions. [CITED: https://www.1password.dev/cli/reference/commands/run] [CITED: https://direnv.net/man/direnv-stdlib.1.html] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]

**Research tooling note:** `gsd_run query research-plan` and `gsd_run query classify-confidence` failed locally with `Cannot find module '../../../package.json'` from `/Users/jon/.codex/gsd-core/bin/lib/runtime-artifact-conversion.cjs`; official docs were fetched directly and claims are tagged as `CITED` or `VERIFIED` instead of cached research-store entries. [VERIFIED: command output]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for docs/examples guidance; re-check 1Password, Docker Compose, direnv, and Anthropic docs before changing the pattern after that date. [ASSUMED]
