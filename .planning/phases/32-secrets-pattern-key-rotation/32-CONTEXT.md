# Phase 32: Secrets pattern + key rotation - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Provider API keys stop living in plaintext repo-local files. This phase delivers the SEC-01/SEC-02 slice only:

- Commit safe examples for the local secrets pattern: `.envrc.example` and `.env.op.example`.
- Add `.envrc` and `.env.op` to `.gitignore`.
- Remove the plaintext `ANTHROPIC_API_KEY=sk-ant-...` stub from `.env.example` and replace it with a 1Password `op://` reference comment.
- Add a compact operator-first Secrets section to `docs/docker_dev_dx.md`.
- Record maintainer-confirmed Anthropic key rotation as non-sensitive phase evidence.

**Out of scope:** sibling repo migration, broader `docs/docker_dev_dx.md` reader-empathy restructure, Docker DX drift guard tests, CI cache-key cleanup, release publish work, and any attempt to inspect or preserve secret material.

</domain>

<decisions>
## Implementation Decisions

Calibration: user asked to discuss all gray areas, research them with subagents, consider ecosystem idioms and footguns, and produce one coherent recommendation set without further decision burden. Four `gsd-advisor-researcher` agents covered secret reference shape, runtime loading, rotation proof, and docs/DX. Decisions below are LOCKED.

### Overall pattern
- **D-01:** Use a **process-scoped 1Password `op run --env-file` pattern** as the default. `direnv` configures the local project and watches the secret-reference file; it does **not** resolve the real Anthropic key into the long-lived interactive shell by default.
- **D-02:** Keep `.env` as the non-secret Docker/Phoenix configuration surface. Do not put `op://` reference values directly into `.env.example` as executable dotenv assignments because plain Docker Compose and Phoenix dotenv readers do not resolve them.
- **D-03:** Keep the runtime variable name `ANTHROPIC_API_KEY`. This matches the existing `compose.yml` critique service and native critique flow, so no app code or Compose service contract needs to change.
- **D-04:** Do **not** read `.env`, shell history, logs, screenshots, or any other likely secret-bearing source during this phase. The roadmap and todo already establish that a plaintext key existed; implementation only removes the pattern and records rotation.

### Example file shape
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

### Runtime commands
- **D-09:** Document these as the canonical secret-consuming command shapes:
  ```bash
  op signin
  op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique
  op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique
  ```
- **D-10:** Make the docs explicit that normal dashboard/dev startup does not need `ANTHROPIC_API_KEY`; only the LLM critique pass needs it. This keeps security setup from feeling like a prerequisite for ordinary local dev.
- **D-11:** Do not add new Make targets or wrapper scripts in Phase 32 unless the planner finds an existing target that must be corrected. Wrapper targets may improve DX later, but the phase success criteria are examples, gitignore, docs, and rotation tracking.

### Rotation proof
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

### Docs placement and tone
- **D-16:** Add a compact `## Secrets (ANTHROPIC_API_KEY)` section to `docs/docker_dev_dx.md` **after** the layer-cache invalidation section and **before** `## Adopting this in another repo`.
- **D-17:** Section outline:
  1. one sentence: critique needs a provider key; normal dashboard/dev does not
  2. `### First-time setup`: install `direnv` + 1Password CLI, add shell hook, `op signin`, copy examples, edit `.env.op`, `direnv allow .`
  3. `### Run the critique pass`: the two canonical `op run --env-file` commands
  4. `### How it works`: `.env.op` stores `op://` secret references only; `op run` resolves them for the child process; Compose inherits shell environment for interpolation
  5. `### Footguns`: never commit `.envrc`/`.env.op`, do not place real keys in `.envrc` or `.env`, sign in/unlock 1Password first, rerun `direnv allow .` after `.envrc` edits, rotate any key that touched disk
- **D-18:** Keep the copy calm, exact, and useful per the brandbook. Use "secret reference" for `op://` values and "plaintext key" for real keys. Avoid security theater and hype. Keep troubleshooting to 4-6 bullets, not a separate runbook.

### Folded Todos
- **docker-dx-fleet-hardening.md:** Fold only the security item into Phase 32: the untracked plaintext `.env` `ANTHROPIC_API_KEY` must be rotated, and the repo should adopt a 1Password CLI / direnv pattern. The cross-repo fleet convergence items remain out of scope.

### Claude's Discretion
- Exact doc prose, example comments, and shell microcopy may be refined as long as the process-scoped `op run --env-file` default, `.env` non-secret boundary, and non-sensitive rotation-attestation standard remain intact.
- The planner may add a small note about the more ergonomic `direnv_load ... direnv dump` variant only as an explicit tradeoff/escape hatch if it does not distract from the default.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` section "Phase 32: Secrets pattern + key rotation" - phase goal and three success criteria.
- `.planning/REQUIREMENTS.md` - SEC-01 and SEC-02 are the locked requirements.
- `.planning/PROJECT.md` section "Current Milestone: v3.2 Drydock" - milestone boundary: Scoria is the reference implementation; sibling repo migration is out of scope.
- `.planning/STATE.md` - current position and pending todo that Anthropic key rotation is a pre-ship requirement.

### Carried-forward decisions
- `.planning/phases/29-makefile-hardening/29-CONTEXT.md` - native `make dev` uses `PORT ?= 4799`; Docker internals stay on `:4000`; docs-wide localhost copy cleanup is Phase 33.
- `.planning/phases/30-launch-banner-native-dev-notice/30-CONTEXT.md` - banner/route work is already handled; Phase 32 should not widen into launch UX.
- `.planning/phases/31-dockerfile-caching-audit-doc/31-CONTEXT.md` - `docs/docker_dev_dx.md` already gained the layer-cache section; place Secrets after that section.

### Files this phase edits
- `.env.example` - remove `ANTHROPIC_API_KEY=sk-ant-...`; replace with comments pointing to `.env.op` / `op://` references.
- `.envrc.example` - add process-scoped direnv/1Password local configuration example.
- `.env.op.example` - add dotenv-formatted 1Password secret-reference example.
- `.gitignore` - add `.envrc` and `.env.op` alongside existing `.env`.
- `docs/docker_dev_dx.md` - add compact Secrets section after the layer-cache invalidation table.
- Phase SUMMARY/VERIFICATION - record non-sensitive rotation attestation; do not store token material.

### Files this phase reads but does NOT change
- `compose.yml` - `critique` service consumes `ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}`; command docs must feed this env var without changing the service.
- `.planning/todos/pending/docker-dx-fleet-hardening.md` - source of the plaintext-key rotation concern.
- `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md` - reviewed and deferred; unrelated to provider secrets.

### External primary references used during discussion
- `https://www.1password.dev/cli/secret-references` - `op://` secret reference model and `op run`/`op read`/`op inject` options.
- `https://www.1password.dev/cli/reference/commands/run` - `op run --env-file` behavior.
- `https://direnv.net/man/direnv-stdlib.1.html` - `direnv_load` exists but is not the chosen default.
- `https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/` - Compose interpolation precedence: shell environment wins over `.env`.
- `https://platform.claude.com/docs/en/manage-claude/authentication` - Anthropic key management reference; rotation/revocation is out-of-band.

### Voice / DX references
- `brandbook/brand-book.md` section "Voice & microcopy" - calm + exact + useful; security docs conservative and explicit.
- `prompts/sztheory-elixir-dna.md` - operator-first DX, batteries-included but composable, solo-maintainer defaults.
- `prompts/scoria-brand-book-deep-research.md` - docs copy-pasteable, precise nouns, no hype/security theater.
- `prompts/phoenix-ai-lib-deep-research.md` - operator-grade DX: redaction, retention, alerts, rollback, CI gates, incident workflows.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.env.example` already documents multi-instance identity for bare `docker compose up`; keep that non-secret role and replace only the Anthropic plaintext stub.
- `.gitignore` already ignores `.env`; add `.envrc` and `.env.op` next to it.
- `docs/docker_dev_dx.md` already has the right reader context and the new Phase 31 layer-cache section; append Secrets immediately after that.
- `compose.yml` already scopes `ANTHROPIC_API_KEY` to the `critique` service, which matches the "critique only" docs wording.

### Established Patterns
- Scoria favors explicit, copy-pasteable operator commands over hidden magic.
- Milestone v3.2 keeps Scoria as the reference implementation and portable docs standard, not a cross-repo migration.
- Security evidence in Scoria should be redacted and status-based, not token-bearing.

### Integration Points
- `op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- docker compose --profile shots run --rm critique` feeds Compose interpolation from the shell environment.
- `op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique` feeds the native Elixir critique flow.
- The actual key rotation is a maintainer action in the Anthropic Console, then recorded in the phase closeout artifacts.

</code_context>

<specifics>
## Specific Ideas

- Recommended `.env.op.example` placeholder: `ANTHROPIC_API_KEY=op://Private/scoria-dev/ANTHROPIC_API_KEY`.
- Recommended `.envrc.example` keeps only `SCORIA_OP_ENV_FILE`, `watch_file`, and a helpful `op` presence check.
- Recommended docs phrase: "The dashboard and normal dev server do not need this key. The screenshot critique pass does."
- Recommended footgun phrase: "A secret reference (`op://...`) is safe to commit in an example. A plaintext key is not."

</specifics>

<deferred>
## Deferred Ideas

- **Automatic `direnv_load op run ... direnv dump` secret loading** - researched and rejected as the default because it resolves the real API key into the active shell environment. May be documented later as an opt-in ergonomic tradeoff.
- **Make targets/wrapper scripts for critique-with-secrets** - useful future DX, but not necessary for SEC-01/SEC-02 and not in Phase 32 success criteria.
- **Dedicated `docs/secrets.md` runbook** - too much structure for this phase; Phase 33 may revisit docs IA.
- **Cross-repo sibling migration** - remains deferred to FLEET-01.

### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` - reviewed because it matched on the word "key"; deferred because it concerns CI cache key naming, not provider API secrets.
- `docker-dx-fleet-hardening.md` - non-security fleet convergence items remain deferred; only the plaintext Anthropic key rotation/secrets-pattern item was folded.

</deferred>

---

*Phase: 32-secrets-pattern-key-rotation*
*Context gathered: 2026-06-18*
