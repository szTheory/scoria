---
phase: 33
slug: doc-restructure-verification-copy-correction
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 33 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 33-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus targeted `rg` static checks |
| **Config file** | `test/test_helper.exs`; `SCORIA_LANE_CONTRACT_ONLY=true` keeps policy-lane checks off the app boot path |
| **Quick run command** | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~15-90 seconds for the policy test; full suite depends on local DB/cache state |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `rg` gate plus `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`.
- **After every plan wave:** Run all Phase 33 active-doc, planning, and harness sweeps from 33-CONTEXT.md D-26 through D-28.
- **Before `/gsd:verify-work`:** Policy-lane docs contract is green and all active stale-copy hits are either corrected or explicitly classified as allowed implementation evidence / gallery-app copy.
- **Max feedback latency:** one task; no phase closeout with an unclassified stale dev-start hit.

---

## Per-Task Verification Map

Wave 1 has 7 tasks: Plans 01, 02, and 03. Wave 2 has 3 tasks: Plan 04.

### Wave 1

#### 33-01-01 — Plan 01 — DOCS-02

- **Threat refs:** T-33-01, T-33-02
- **Secure behavior:** The Docker DX guide opens with the locked reader/job framing and exposes Docker, native, and stale-instance sections without destructive global cleanup copy.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "solo maintainer|many Phoenix/Elixir|port-conflict-free" docs/docker_dev_dx.md
for h in "Docker daily loop" "Native dev server" "Stale instance hygiene"; do rg -n "^## ${h}$" docs/docker_dev_dx.md >/dev/null; done
for s in "make proxy" "make up-build" "make up" "make url" "make open" "make fleet" "make doctor" "make dev"; do rg -n "$s" docs/docker_dev_dx.md >/dev/null; done
! rg -n "http://localhost:4000/scoria" docs/docker_dev_dx.md
! rg -n "docker (system|volume) prune|make nuke-all" docs/docker_dev_dx.md
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs'
```

#### 33-01-02 — Plan 01 — DOCS-02

- **Threat refs:** T-33-02, T-33-03
- **Secure behavior:** Cache, secrets, adoption, and stale-instance guidance stay accurate and process-scoped.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
for h in "Caching guarantees" "Secrets"; do rg -n "^## ${h}$" docs/docker_dev_dx.md >/dev/null; done
rg -n "mix deps\\.get|mix deps\\.compile|app compile only|full dep rebuild" docs/docker_dev_dx.md
rg -n "CSS|assets|HEEx|mix\\.exs|mix\\.lock" docs/docker_dev_dx.md
rg -n "direnv allow|\\.env\\.op|op run --env-file|ANTHROPIC_API_KEY" docs/docker_dev_dx.md
rg -n "make fleet|make doctor|make down INSTANCE=<project>|make nuke INSTANCE=<project>" docs/docker_dev_dx.md
rg -n "Adopting this in another repo|Converge the fleet" docs/docker_dev_dx.md
! rg -n "docker (system|volume) prune|make nuke-all" docs/docker_dev_dx.md
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs'
```

#### 33-02-01 — Plan 02 — DOCS-01

- **Threat refs:** T-33-05, T-33-06
- **Secure behavior:** Maintainer screenshot/e2e and UAT docs use the native host harness URL and do not reintroduce stale Scoria dashboard startup copy.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "make dev" docs/MAINTAINERS.md docs/uat_automation.md
rg -n "mix scoria\\.ui\\.shots --url http://localhost:4799/scoria" docs/MAINTAINERS.md
rg -n "mix scoria\\.ui\\.e2e --base-url http://localhost:4799/scoria" docs/uat_automation.md
! rg -n "PORT=4010|localhost:4010|mix phx\\.server" docs/uat_automation.md
! rg -n "localhost:4000" docs/operator_verification.md docs/MAINTAINERS.md README.md
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs'
```

#### 33-02-02 — Plan 02 — DOCS-01

- **Threat refs:** T-33-04, T-33-05
- **Secure behavior:** Support-copilot gallery copy remains correct only as separate `examples/support_copilot` app guidance.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "examples/support_copilot" README.md docs/operator_verification.md docs/support_copilot_gallery.md
rg -n "http://localhost:4010/|http://localhost:4010/scoria" docs/support_copilot_gallery.md
! rg -n "localhost:4000" docs/operator_verification.md docs/MAINTAINERS.md README.md
! rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" docs/uat_automation.md
! rg -n "localhost:4000" docs/support_copilot_gallery.md
gallery_hits="$(mktemp)"
if rg -n "PORT=4010|localhost:4010|mix phx\\.server" docs/support_copilot_gallery.md > "$gallery_hits"; then :; else status=$?; test "$status" -eq 1; fi
if test -s "$gallery_hits"; then rg -n "examples/support_copilot|gallery app|gallery-local|host chat|http://localhost:4010/|http://localhost:4010/scoria" docs/support_copilot_gallery.md >/dev/null; fi
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs'
```

#### 33-03-01 — Plan 03 — DOCS-01

- **Threat refs:** T-33-07, T-33-08
- **Secure behavior:** Mix tasks and seed output default to native `localhost:4799` while protected runtime wiring stays unchanged.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "http://localhost:4799/scoria|make dev" lib/mix/tasks/scoria.ui.shots.ex lib/mix/tasks/scoria.ui.e2e.ex priv/repo/dev_seed.exs
rg -n "Done\\. Open http://localhost:4799/scoria" priv/repo/dev_seed.exs
! rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.shots.ex lib/mix/tasks/scoria.ui.e2e.ex priv/repo/dev_seed.exs
make -n dev | rg -n "http://localhost:4799/scoria|PORT=4799"
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs'
```

#### 33-03-02 — Plan 03 — DOCS-01

- **Threat refs:** T-33-07, T-33-08
- **Secure behavior:** Playwright entrypoint defaults and comments use native `localhost:4799` without changing override semantics.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "http://localhost:4799/scoria|make dev|PLAYWRIGHT_BASE_URL" priv/dev/shots.mjs priv/dev/e2e/playwright.config.mjs priv/dev/e2e/uat.spec.mjs
! rg -n "localhost:4000/scoria|mix phx\\.server" priv/dev/shots.mjs priv/dev/e2e/playwright.config.mjs priv/dev/e2e/uat.spec.mjs
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs'
```

#### 33-03-03 — Plan 03 — DOCS-01

- **Threat refs:** T-33-07, T-33-08
- **Secure behavior:** Remaining e2e spec defaults use the native host URL, and the harness-wide stale-copy sweep is a hard zero-hit gate.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
for f in priv/dev/e2e/command_palette.spec.mjs priv/dev/e2e/ia_orientation.spec.mjs priv/dev/e2e/phase16_parity.spec.mjs; do rg -n "process\\.env\\.PLAYWRIGHT_BASE_URL \\|\\| .http://localhost:4799/scoria." "$f" >/dev/null; done
! rg -n "localhost:4000/scoria|mix phx\\.server" priv/dev/e2e/command_palette.spec.mjs priv/dev/e2e/ia_orientation.spec.mjs priv/dev/e2e/phase16_parity.spec.mjs
! rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs'
```

### Wave 2

#### 33-04-01 — Plan 04 — DOCS-01

- **Threat refs:** T-33-11, T-33-12
- **Secure behavior:** Living project-state planning files use canonical Docker/native verification copy, and historical archive paths remain untouched.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "make up|make url|make dev|http://<instance>\\.localhost/scoria|http://localhost:4799/scoria" .planning/PROJECT.md .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/todos/pending/docker-dx-fleet-hardening.md
rg -n "Phase 33|folded" .planning/todos/pending/docker-dx-fleet-hardening.md
! rg -n "localhost:4000/scoria|mix phx\\.server" .planning/PROJECT.md .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/todos/pending/docker-dx-fleet-hardening.md
test -z "$(git diff --name-only -- .planning/milestones .planning/debug .planning/memory .planning/todos/completed ".planning/v*-MILESTONE-AUDIT.md" | sed "/^$/d")"'
```

#### 33-04-02 — Plan 04 — DOCS-01

- **Threat refs:** T-33-11, T-33-12
- **Secure behavior:** Active research guidance is corrected without mutating `.planning/research/.cache/**`.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
rg -n "make up|make url|make dev|http://<instance>\\.localhost/scoria|http://localhost:4799/scoria" .planning/research/ARCHITECTURE.md .planning/research/FEATURES.md .planning/research/PITFALLS.md .planning/research/STACK.md .planning/research/SUMMARY.md
! rg -n "localhost:4000/scoria|mix phx\\.server" .planning/research/ARCHITECTURE.md .planning/research/FEATURES.md .planning/research/PITFALLS.md .planning/research/STACK.md .planning/research/SUMMARY.md
test "$(git diff --name-only -- .planning/research/.cache | sed "/^$/d" | wc -l | tr -d " ")" -eq 0'
```

#### 33-04-03 — Plan 04 — DOCS-01

- **Threat refs:** T-33-10, T-33-11, T-33-12
- **Secure behavior:** Every active planning sweep hit has a current classification row, and stale or unknown classifications fail the gate.
- **Automated command:**

```bash
bash -lc 'set -euo pipefail
sweep=".planning/phases/33-doc-restructure-verification-copy-correction/33-PLANNING-SWEEP.md"
active_hits="$(mktemp)"
active_keys="$(mktemp)"
sweep_keys="$(mktemp)"
stale_rows="$(mktemp)"
if rg -n "mix phx\\.server|localhost:4000/scoria" .planning -g "!**/milestones/**" -g "!v*-MILESTONE-AUDIT.md" -g "!**/debug/**" -g "!**/memory/**" -g "!**/todos/completed/**" > "$active_hits"; then :; else status=$?; test "$status" -eq 1; fi
test -f "$sweep"
rg -n "File \\| Line or pattern \\| Classification \\| Action" "$sweep"
awk -F: "{print \$1 \":\" \$2}" "$active_hits" | sort -u > "$active_keys"
while IFS= read -r key; do test -z "$key" && continue; rg -F "$key" "$sweep" >/dev/null || { echo "missing sweep row for $key" >&2; exit 1; }; done < "$active_keys"
awk -F"|" -v out="$sweep_keys" '\''function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s} /^\|/ {file=trim($2); key=trim($3); class=trim($4); if (file == "File" || file ~ /^-+$/ || file == "") next; if (class !~ /^(correct implementation evidence|current phase decision quotation|current phase verification pattern|quoted historical rationale|defect fixed in this plan)$/) {print "stale or unknown classification: " class > "/dev/stderr"; bad=1} if (key ~ /^[^:]+:[0-9]+$/ && class != "defect fixed in this plan") print key > out} END{exit bad}'\'' "$sweep"
sort -u -o "$sweep_keys" "$sweep_keys"
if test -s "$sweep_keys"; then comm -23 "$sweep_keys" "$active_keys" > "$stale_rows"; test ! -s "$stale_rows" || { sed "s/^/stale sweep row: /" "$stale_rows" >&2; exit 1; }; fi
! rg -n "\\| CURRENT_STALE_START \\||current stale instruction|current stale start" "$sweep"
test -z "$(git diff --name-only -- .planning/milestones .planning/debug .planning/memory .planning/todos/completed ".planning/v*-MILESTONE-AUDIT.md" | sed "/^$/d")"
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs'
```

---

## Static Acceptance Checks

Run these before phase verification. The `rg` commands may print allowed hits only when the plan summary classifies them as Docker-internal, CI self-test, implementation evidence, historical rationale, or the separate support-copilot gallery app.

```bash
rg -n "^## (Docker daily loop|Native dev server|Caching guarantees|Secrets|Stale instance hygiene)" docs/docker_dev_dx.md

rg -n "localhost:4000|mix phx\\.server" \
  README.md \
  docs/operator_verification.md \
  docs/MAINTAINERS.md \
  docs/uat_automation.md \
  docs/support_copilot_gallery.md

rg -n "PORT=4010|localhost:4010|localhost:4000|mix phx\\.server" \
  docs/uat_automation.md \
  docs/support_copilot_gallery.md

rg -n "mix phx\\.server|localhost:4000/scoria" .planning \
  -g '!**/milestones/**' \
  -g '!v*-MILESTONE-AUDIT.md' \
  -g '!**/debug/**' \
  -g '!**/memory/**' \
  -g '!**/todos/completed/**'

rg -n "localhost:4000/scoria|mix phx\\.server" \
  lib/mix/tasks/scoria.ui.*.ex \
  priv/dev \
  priv/repo/dev_seed.exs

make -n dev
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs
```

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 33 requirements. No new test file, fixture, package, or framework is required before implementation. Phase 34 owns the dedicated Docker DX drift-guard test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `docs/docker_dev_dx.md` reads as a top-to-bottom reference standard for a new contributor. | DOCS-02 | Information architecture and reader empathy are document qualities; the static checks only prove required anchors and canonical strings. | Read the first screen and the five required sections. Confirm each section has when to use it, commands, expected URL/output, footguns, and recovery. |
| Remaining stale-copy hits are truly allowed contexts. | DOCS-01 | A grep hit can be valid Docker-internal implementation evidence, CI self-test context, historical rationale, current phase verification pattern, or gallery-app copy. | For every remaining `localhost:4000` or `mix phx.server` hit in active scope, record its exact `path:line` and classification in `33-PLANNING-SWEEP.md` before verification. |

---

## Validation Sign-Off

- [x] All anticipated tasks have automated checks or an explicit manual classification checkpoint.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded to one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
