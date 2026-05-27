# Phase 68: Full-Suite Warning Closure — Research

**Researched:** 2026-05-27  
**Domain:** CI WAE staging, warning debt closeout, host-proof / LiveView warning remediation  
**Confidence:** HIGH (built on Phase 67 shipped SSOT + live codebase inspection)

<user_constraints>
## User Constraints (from 68-CONTEXT.md)

### Locked Decisions
- Four serial plans: 68-00 hygiene → 68-01 staged ratchet CI → 68-02 p2 adoption debt → 68-03 full WAE closeout
- Fix WR-01 (tmp preflight/cleanup) and WR-02 (JSON encode) **before** CI wiring
- Staged CI: `mix scoria.warning_ratchet.test --warnings-as-errors` after `runtime_to_handoff`, before `mix test`
- Full flip: `mix test --warnings-as-errors` when locally green; same PR as baseline ledger update
- Reject allow-fail parallel full WAE, global suppressions, per-cluster Accepted markdown rows, separate adoption WAE CI step
- p2: fix `:host_proof_generated_compile`, `:host_overlay_test_path` at source — do not baseline subprocess noise
- p4: bounded `render_async/1` sweep on workflow/replay LiveView tests; re-baseline LiveView row only if runtime-only debt remains
- Policy job unchanged: `warning_baseline.check` → compile WAE → lane-contract tests only (no ratchet)

### Deferred (OUT OF SCOPE)
- CI-03 documentation bundle (Phase 69)
- CI diff-on-JSON, `--fix` inventory, global `config/test.exs` WAE
- Explicit `mix test.adoption --warnings-as-errors` CI step

### Claude's Discretion
- `mix test.knowledge --warnings-as-errors` timing in 68-03
- `render_async` helper extraction vs per-test calls
- `high_signal_path?/1` memoization (IN-01)
- Merge 68-02/68-03 if full WAE greens early
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Plans |
|----|-------------|-------|
| WARN-07 | CI runs `mix test --warnings-as-errors` and passes, or remaining debt is explicitly re-baselined with owner + renewed expiry | 68-01 (staged), 68-02, 68-03 (full) |
</phase_requirements>

---

## 1. Executive Summary

Phase 68 closes **WARN-07** by wiring a **staged → full** WAE sequence in the CI test job, fixing maintainer-workflow blockers from 67-REVIEW (WR-01/WR-02), addressing deferred **p2 host-proof** and **p4 LiveView async teardown** debt, and updating `.planning/WARNING-BASELINE.md` before the **2026-06-07** full-suite expiry.

**Primary recommendation:** Execute the four-plan serial wave locked in CONTEXT (68-00 → 68-01 → 68-02 → 68-03). Ship CI ratchet gate only after WR-01/WR-02 hygiene. Do not flip to full `mix test --warnings-as-errors` in CI until local full WAE is green and the baseline ledger is updated in the same PR.

**Current evidence snapshot (2026-05-27):**

| Command | Status | Notes |
|---------|--------|-------|
| `mix scoria.warning_baseline.check` | Pass | Two Accepted rows valid until 2026-06-07 / 2026-06-30 |
| `mix compile --warnings-as-errors` | Pass (STATE.md) | Policy job gate |
| Lane-contract WAE | Pass (STATE.md) | Policy job gate |
| `mix test.adoption --warnings-as-errors` | **Pass locally** (49 tests, 0 failures) | p2 adoption path largely clear |
| `mix scoria.warning_ratchet.test --warnings-as-errors` | **Context: pass in Phase 67** (~421 tests); local re-run hit DB/pgvector env failures unrelated to warnings | CI uses pgvector Postgres service |
| `mix test --warnings-as-errors` | **Not verified this session**; STATE.md lists remaining debt classes | 68-03 target |
| `.planning/warning-inventory.baseline.json` | `"clusters": {}` | Phase 67 closeout |

**Path SSOT:** `Scoria.WarningRatchet.high_signal_wae_paths/0` returns **104 test files** (adoption list + `test/scoria/**/*_test.exs` + `test/scoria_web/live/**/*_test.exs`). CONTEXT’s “~421 tests” refers to **test case count** within those files, not file count.

---

## 2. Current State

### 2.1 Maintainer / CI commands today

**Policy job** (`.github/workflows/ci.yml` lines 15–47, no Postgres):

```
mix scoria.warning_baseline.check
mix deps.get
mix compile --warnings-as-errors
mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

**Test job** (lines 49–116, Postgres pgvector/pg16 on port 55432):

```
MIX_ENV=dev mix scoria.release_preview
mix ecto.create && mix ecto.migrate
mix test.adoption
mix test.runtime_to_handoff
mix test                    # plain — no WAE
mix test.knowledge          # sets SCORIA_TEST_INCLUDE_KNOWLEDGE, pgvector bootstrap
```

**Not in CI yet:** `mix scoria.warning_ratchet.test` (reserved for 68-01 per Phase 67 D-17).

### 2.2 Warning infrastructure SSOT

| Module / task | Role |
|---------------|------|
| `lib/scoria/warning_ratchet.ex` | Composes high-signal WAE paths in code |
| `lib/mix/tasks/scoria.warning_ratchet.test.ex` | Runs `mix test [--warnings-as-errors] <paths>` |
| `lib/mix/tasks/scoria.warning_ratchet.check.ex` | Full capture + fail on unclassified compile warnings in high-signal paths |
| `lib/mix/tasks/scoria.warning_inventory.ex` | Capture, classify, `--write` artifacts; **only** task with `test/tmp/` preflight |
| `lib/scoria/warning_inventory/cluster.ex` | Cluster registry including p2/p4 matchers |
| `lib/scoria/warning_baseline.ex` | Parses Accepted rows + expiry |
| `test/scoria/ci_policy_contract_test.exs` | Gate-order contracts; asserts ratchet **absent** from policy job |

### 2.3 Accepted baseline ledger (`.planning/WARNING-BASELINE.md`)

| Surface | Expires | Owner |
|---------|---------|-------|
| full-suite (non-canonical) | 2026-06-07 | scoria-maintainers |
| workflow/replay LiveView tests | 2026-06-30 | scoria-web-runtime |

Deferred clusters tracked in `.planning/WARNING-INVENTORY.md` prose queue (JSON clusters empty):

- `:host_proof_generated_compile` — p2, Phase 68
- `:host_overlay_test_path` — p2, Phase 68
- `:liveview_async_teardown` — p4, baselined until 2026-06-30

### 2.4 Knowledge lane vs full-suite WAE

`test/test_helper.exs` excludes `@moduletag :knowledge` tests unless `SCORIA_TEST_INCLUDE_KNOWLEDGE=true`. Default `mix test --warnings-as-errors` **does not** run knowledge-tagged tests. CI runs `mix test.knowledge` as a **separate step** after plain `mix test`. Plan 68-03 should decide whether knowledge lane needs its own WAE flag (CONTEXT discretion).

---

## 3. Technical Approaches by Plan

### 68-00 — `ratchet-ci-hygiene`

**Goal:** Unblock maintainer workflow and CI confidence before ratchet wiring.

**WR-01 — shared tmp preflight/cleanup**

Problem: `Mix.Tasks.Scoria.WarningRatchet.Check` calls `WarningInventory.capture_output/0` (full `mix do compile --force + test`) without preflight or cleanup. Install adoption tests write under `test/tmp/installer` (see `test/mix/tasks/scoria.install_test.exs` `@tmp_dir "test/tmp/installer"`). A green ratchet.check leaves pollution that breaks subsequent `mix scoria.warning_inventory`.

Recommended approach (minimal, matches 67-REVIEW):

1. **Extract** `preflight!/0` from `lib/mix/tasks/scoria.warning_inventory.ex` (lines 70–95) into `Scoria.WarningInventory` as a public `ensure_clean_tmp!/0` (or keep name `preflight!/0`).
2. **Call** it at the start of `Mix.Tasks.Scoria.WarningRatchet.Check.run/1` before capture.
3. **Add post-capture cleanup** in ratchet.check (and optionally in capture wrapper): `File.rm_rf/1` on `test/tmp/*` entries created during capture, **or** document+enforce `rm -rf test/tmp/*` in an `after` block when capture invoked from ratchet tasks.

Alternative rejected: “document run order only” — insufficient for CI/maintainer ergonomics (67-REVIEW).

**WR-02 — unify JSON encode**

Problem: `render/3` for `"json"` (lines 123–126) encodes raw rows with tuple `:dedupe_key`; `--write` path already uses `json_encode_rows/1` (lines 214–229).

Fix: one-line route change:

```elixir
defp render(rows, "json", metadata) do
  payload = Map.put(metadata, "rows", json_encode_rows(rows))
  Mix.shell().info(Jason.encode!(payload, pretty: true))
end
```

Add contract test in `test/scoria/warning_inventory/` that classifies a fixture row and asserts `--format json` does not raise (use `host_overlay_test_path.txt` or synthetic classified row).

**IN-01 (optional):** Memoize expanded path set in `Scoria.WarningRatchet` via `:persistent_term` keyed by `File.cwd!()` — low priority today, cheap win if touching the module.

**Verification gate:** `mix scoria.warning_baseline.check` + ratchet.check after clean tmp.

---

### 68-01 — `staged-ratchet-ci-gate`

**Goal:** WARN-06 enforcement in CI without blocking on full-suite debt.

**CI change** — insert in `.github/workflows/ci.yml` test job **after** line 110 (`mix test.runtime_to_handoff`), **before** line 112 (`mix test`):

```yaml
      - name: Run high-signal warning ratchet
        run: mix scoria.warning_ratchet.test --warnings-as-errors
```

`MIX_ENV: test` is already set on the job (line 69). No Postgres config change needed — ratchet paths include DB tests; adoption/handoff steps already migrated DB.

**Note on test/tmp:** Adoption step runs before ratchet and creates `test/tmp/` entries. This does **not** break ratchet.test (no preflight). Only inventory tasks require clean tmp. WR-01 still matters for maintainer chains, not CI ratchet.test.

**ci_policy_contract_test.exs extensions** (D-05):

Add tests mirroring existing patterns (`index_of/2`, `split_jobs/1`):

1. `test "test job runs warning ratchet after runtime_to_handoff and before mix test"` — assert `mix scoria.warning_ratchet.test --warnings-as-errors` index between `VerificationLanes.ci_command(:runtime_to_handoff)` and `"run: mix test"` (or `"mix test\n"` step).
2. `test "policy job does not run warning_ratchet.test"` — extend existing ratchet absence test to cover `.test` variant (partially covered by `scoria.warning_ratchet` refute).

**Operator doc** (`docs/operator_verification.md` lines 221–233): Add subsection under WARN-06 explaining CI maps adoption-file WAE to ratchet bridge (D-14):

- CI runs plain `mix test.adoption` for behavior
- CI enforces adoption-file compile warnings via `mix scoria.warning_ratchet.test --warnings-as-errors` (paths include `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0`)
- Maintainer debug command remains `mix test.adoption --warnings-as-errors`

**Verification gate:** `mix scoria.warning_baseline.check` + `mix scoria.warning_ratchet.test --warnings-as-errors` (CI-parity env with pgvector).

---

### 68-02 — `p2-adoption-wae-debt`

**Goal:** Ensure host-proof warning clusters are fixed at source; adoption lane WAE stays green under full capture.

**Cluster matchers** (`lib/scoria/warning_inventory/cluster.ex`):

| Cluster | Matcher | Meaning |
|---------|---------|---------|
| `:host_proof_generated_compile` | `file` contains `test/support/scoria/host_app_proof/` and **not** `host_app_proof/overlay/test/` | Warnings from generator/runner support code or generated paths under support |
| `:host_overlay_test_path` | `file` contains `host_app_proof/overlay/test/` | Warnings attributed to overlay smoke templates (matches `priv/host_app_proof/overlay/test/` too) |

**Architecture already shipped (Phase 67-02):**

- Overlay templates: `priv/host_app_proof/overlay/test/host_route_smoke_test.exs`, `host_runtime_smoke_test.exs`
- Generator copies overlay via `copy_overlay!/1` (`test/support/scoria/host_app_proof/generator.ex` lines 51–58)
- Generated hosts use `System.tmp_dir!()` not repo `test/tmp` (line 11)
- Regression guard: `test/scoria/host_app_proof_architecture_test.exs`

**Evidence:** `MIX_ENV=test mix test.adoption --warnings-as-errors` passes locally (49 tests). Phase 67 marked p2 “defer” for CI WAE scope, not because adoption WAE was red.

**68-02 work items when full-suite capture still shows p2 clusters:**

1. Run `rm -rf test/tmp/* && MIX_ENV=test mix scoria.warning_inventory --scope full --write` and inspect cluster counts (maintainer gate, not CI).
2. If `:host_proof_generated_compile` appears: trace file paths in inventory output — fix generator/runner compile warnings in `test/support/scoria/host_app_proof/{generator,runner}.ex` (must stay WAE-clean per D-15).
3. If `:host_overlay_test_path` appears: fix overlay templates under `priv/host_app_proof/overlay/test/` — do **not** add `@compile` suppressions (D-08).
4. If warnings come from **subprocess** `phx.new` generated app code: ensure isolation — warnings inside temp host under `System.tmp_dir!()` should not appear in parent capture unless parent compiles those paths; if they do, adjust capture scope or subprocess compile flags (do not baseline — D-14).

**Adoption file SSOT** (`lib/mix/tasks/test.adoption.ex` lines 5–18): 12 files including `host_app_consumer_proof_test.exs`, install tests, migration compatibility.

**Verification gate:** `mix test.adoption --warnings-as-errors` + `mix scoria.warning_ratchet.test --warnings-as-errors` + `mix scoria.warning_baseline.check`.

---

### 68-03 — `warn-07-full-wae-closeout`

**Goal:** Green full-suite WAE, baseline ledger closeout, CI flip from ratchet to full WAE.

**Bounded p4 LiveView fixes**

Cluster `:liveview_async_teardown` matches runtime/ex_unit lines with `async|teardown|sandbox` in message (`cluster.ex` lines 68–71). Fixture example (`test/fixtures/warning_inventory/liveview_async_teardown.txt`):

```
[warning] async LiveView teardown still running in sandbox after 100ms
```

Inventory detection requires `--include-runtime` (`warning_inventory.ex` lines 97–111).

**Established fix pattern:** `render_async(view)` at end of tests that mount LiveView with async UI paths.

| File | Tests | `render_async` today | Priority for p4 sweep |
|------|------:|---------------------|------------------------|
| `test/scoria_web/live/workflow_live_test.exs` | 11 | **None** | **High** — workflow + replay tests; fixture maps here |
| `test/scoria_web/live/review_queue_live_test.exs` | 2 | None | **High** — workflow/replay baseline surface |
| `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` | few | None | **Medium** — replay/offline_replay eval paths |
| `test/scoria_web/live/orchestrator_live_test.exs` | 10 | Yes (line 166) | Done |
| `test/scoria_web/live/orchestrator_live_sre_test.exs` | 2 | Yes (lines 162, 227) | Done |
| `test/scoria_web/live/prompt_live_test.exs` | 1 | None | Low (`async: true` EvalCase) |
| `test/scoria_web/live/dataset_live/promote_component_test.exs` | 4 | None | Low |
| `test/scoria_web/live/eval_spec_live/index_test.exs` | 1 | None | Low |

**Recommended sweep order:** `workflow_live_test.exs` → `review_queue_live_test.exs` → `release_workbench_live_test.exs`. Add `render_async(view)` before test end when test holds a `view` binding from `live/2`. For tests that only use `html` from `live/3`, capture view: `{:ok, view, html} = live(...)` then `render_async(view)` in `try`/`after` or final line.

Optional helper (discretion): `Scoria.TestSupport.LiveViewAsyncDrain.render_async_safely/1` — only if repeated boilerplate exceeds ~3 call sites.

**Measure p4:** After sweep, `MIX_ENV=test mix scoria.warning_inventory --include-runtime --scope full` and confirm `:liveview_async_teardown` count reduced.

**Full WAE attempt:**

```bash
rm -rf test/tmp/*
MIX_ENV=test mix ecto.create && mix ecto.migrate   # CI-parity
MIX_ENV=test mix test --warnings-as-errors
```

**CI flip** — replace 68-01 ratchet step with:

```yaml
      - name: Run tests
        run: mix test --warnings-as-errors
```

Update `ci_policy_contract_test.exs` accordingly (ratchet step removed; full WAE before `mix test.knowledge`).

**Knowledge lane (discretion):** If `mix test.knowledge` emits warnings under pgvector CI, add:

```yaml
      - name: Run knowledge lane
        run: mix test.knowledge --warnings-as-errors
```

`lib/mix/tasks/scoria.test.knowledge.ex` forwards args to `mix test` after bootstrap — `--warnings-as-errors` should propagate.

**Verification gate:** Full WAE + `mix scoria.warning_baseline.check` + inventory `--write --scope full` with clean tmp.

---

## 4. WR-01 / WR-02 Remediation Specifics

### WR-01 — tmp preflight/cleanup

| Item | Location |
|------|----------|
| Preflight (today) | `lib/mix/tasks/scoria.warning_inventory.ex:70-95` — `preflight!/0` private |
| Missing preflight | `lib/mix/tasks/scoria.warning_ratchet.check.ex:15` — calls capture directly |
| Pollution source | `test/mix/tasks/scoria.install_test.exs:7` (`test/tmp/installer`), `scoria.install_route_smoke_test.exs:4`, `scoria.install_check_test.exs`, etc. |
| Full capture | `lib/scoria/warning_inventory.ex:144-155` — `mix do compile --force + test` |
| Operator doc | `docs/operator_verification.md:227` — manual `rm -rf test/tmp/*` |

**Implementation sketch:**

```elixir
# lib/scoria/warning_inventory.ex
def ensure_clean_tmp! do
  # move logic from Mix task preflight
end

# lib/mix/tasks/scoria.warning_ratchet.check.ex
def run(_args) do
  WarningInventory.ensure_clean_tmp!()
  output = WarningInventory.capture_output()
  # optional: cleanup_transient_tmp!()
  ...
end
```

Consider `on_exit`-style cleanup function invoked after capture for ratchet tasks only.

### WR-02 — JSON encode

| Item | Location |
|------|----------|
| Broken path | `lib/mix/tasks/scoria.warning_inventory.ex:123-126` |
| Working path | Same file `:164`, `:214-229` (`json_encode_rows/1`, `json_encode_value/1`) |
| Tuple source | `lib/scoria/warning_inventory.ex:119-127` — `dedupe_key/2` returns `{atom, string, string}` |

**Test:** New case in `test/scoria/warning_inventory/` — pipe fixture through classify + `json_encode_rows` or invoke task with `--format json` on captured fixture output.

---

## 5. p2 Host-Proof Warning Fixes — Concrete Paths

### Files to keep WAE-clean (compiled in repo)

| Path | Role |
|------|------|
| `test/support/scoria/host_app_proof/generator.ex` | `phx.new` + overlay copy |
| `test/support/scoria/host_app_proof/runner.ex` | Subprocess mix steps |
| `test/scoria/host_app_proof_architecture_test.exs` | Overlay path regression guard |

### Overlay templates (copied into generated host, not compiled in Scoria app)

| Path | Role |
|------|------|
| `priv/host_app_proof/overlay/test/host_route_smoke_test.exs` | Router metadata smoke |
| `priv/host_app_proof/overlay/test/host_runtime_smoke_test.exs` | Durable run + LiveView smoke |

### Adoption tests exercising host proof

| Path | Role |
|------|------|
| `test/scoria/host_app_consumer_proof_test.exs` | Full generated-host proof |
| `test/mix/tasks/scoria.install_test.exs` | In-repo install fixtures |
| `test/mix/tasks/scoria.install_route_smoke_test.exs` | Route smoke |

### Cluster classification fixtures (for regression tests)

| Fixture | Cluster |
|---------|---------|
| `test/fixtures/warning_inventory/host_proof_generated_compile.txt` | `:host_proof_generated_compile` |
| `test/fixtures/warning_inventory/host_overlay_test_path.txt` | `:host_overlay_test_path` |

### Anti-patterns (rejected)

- Baselining subprocess `phx.new` noise
- Blanket `@compile {:no_warn_undefined, ...}` on overlay templates
- Moving overlay back to `test/support/scoria/host_app_proof/overlay/test/` (architecture test forbids)

---

## 6. p4 LiveView Async Teardown — Test Files

**Baseline surface name:** `workflow/replay LiveView tests` (WARNING-BASELINE.md row 2).

**High-signal LiveView paths** (all in ratchet SSOT):

```
test/scoria_web/live/dataset_live/promote_component_test.exs
test/scoria_web/live/eval_spec_live/index_test.exs
test/scoria_web/live/orchestrator_live_sre_test.exs      # render_async present
test/scoria_web/live/orchestrator_live_test.exs          # render_async present
test/scoria_web/live/prompt_live/release_workbench_live_test.exs
test/scoria_web/live/prompt_live_test.exs
test/scoria_web/live/review_queue_live_test.exs
test/scoria_web/live/workflow_live_test.exs
```

**Primary fix targets (workflow/replay, no render_async):**

1. `test/scoria_web/live/workflow_live_test.exs` — includes `"replay runs render provenance strip..."` and multiple `live/2` mounts
2. `test/scoria_web/live/review_queue_live_test.exs` — review queue / deep-link evidence
3. `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` — offline_replay eval spec setup

**Detection command:**

```bash
MIX_ENV=test mix scoria.warning_inventory --include-runtime --scope full
```

Runtime rows use `file: "runtime"` (`warning_inventory.ex:104`).

---

## 7. CI Wiring Specifics

### 7.1 `.github/workflows/ci.yml`

**68-01 insertion point** (after runtime_to_handoff step, ~line 110):

```yaml
      - name: Run high-signal warning ratchet
        run: mix scoria.warning_ratchet.test --warnings-as-errors
```

**68-03 replacement:** Change existing `Run tests` step from `mix test` to `mix test --warnings-as-errors`; remove ratchet step.

**Unchanged:**

- Policy job ordering and contents
- `needs: policy` on test job
- Closeout chain: release_preview → adoption → runtime_to_handoff → **WAE gate** → mix test → knowledge
- Postgres service only on test job

### 7.2 `test/scoria/ci_policy_contract_test.exs`

**Existing contracts to preserve:**

- Baseline before compile WAE (lines 10–16)
- Closeout chain order (lines 18–32)
- Postgres only in test job (lines 34–41)
- Ratchet docs in operator_verification (lines 43–49)
- Policy job excludes ratchet (lines 51–56)

**New contracts for 68-01:**

```elixir
@ratchet_wae "mix scoria.warning_ratchet.test --warnings-as-errors"

test "test job runs warning ratchet after runtime_to_handoff and before broad mix test" do
  ci_workflow = File.read!(".github/workflows/ci.yml")
  runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)

  assert ci_workflow =~ @ratchet_wae
  assert index_of(ci_workflow, runtime_to_handoff) < index_of(ci_workflow, @ratchet_wae)
  assert index_of(ci_workflow, @ratchet_wae) < index_of(ci_workflow, "run: mix test")
end
```

**Update for 68-03:** Assert `mix test --warnings-as-errors` in test job; refute ratchet command (or mark ratchet test as conditional on milestone phase — prefer single canonical assertion for shipped state).

**Failure copy (D-25):** CI step names should state what failed and what to run next, e.g. “Run high-signal warning ratchet” with operator doc link in workflow comment if desired.

---

## 8. Baseline Ledger Closeout Procedure

### 8.1 Full WARN-07 success (target)

1. Confirm `MIX_ENV=test mix test --warnings-as-errors` green locally and in CI.
2. Edit `.planning/WARNING-BASELINE.md`:
   - Move both Accepted rows to new section **`## Resolved During v2.6`** (section does not exist yet — add after Accepted table, mirroring `## Resolved During v2.4` pattern at lines 19–23).
   - Columns: Surface | Resolved Debt | Resolution Date
   - Leave **`## Accepted Warning Debt`** header + empty table (headers only per D-16).
3. Run:

   ```bash
   rm -rf test/tmp/*
   MIX_ENV=test mix scoria.warning_inventory --write --scope full
   mix scoria.warning_baseline.check
   ```

4. Commit `.planning/warning-inventory.baseline.json` with `"clusters": {}`.
5. Update `.planning/WARNING-INVENTORY.md` Phase 68 fixed/deferred table (generated by `--write`).
6. Same PR as CI flip — **required** before 2026-06-07 expiry (D-18).

### 8.2 Partial success (compile WAE clean; runtime LiveView noise remains)

1. Remove **full-suite (non-canonical)** row — do not renew umbrella (D-11).
2. Keep **at most one** Accepted row for LiveView async teardown with:
   - Owner: `scoria-web-runtime`
   - Expiry: **2026-07-31** (renewed from 2026-06-30)
   - Reason: evidence from `--include-runtime` inventory showing `:liveview_async_teardown` only
3. Inventory JSON may be non-empty **only** for clusters that truly remain (D-17).
4. CI: full `mix test --warnings-as-errors` must still pass (runtime teardown is log noise under WAE only if ExUnit treats it as failure — verify; may not fail WAE unless configured).

### 8.3 Failure to green by 2026-06-07

Same PR must either fix code **or** re-baseline with **narrow** surface + inventory evidence — never vague “audit not rerun” prose (D-11). `mix scoria.warning_baseline.check` blocks merge on expired rows regardless of test-job progress.

### 8.4 Parser constraints (`lib/scoria/warning_baseline.ex`)

- Only parses rows under `## Accepted Warning Debt` (line 14)
- Resolved sections do not affect expiry checks
- Do not add per-cluster Accepted rows in markdown (D-19) — use cluster registry + JSON counts

---

## 9. Risks and Unknowns

| Risk | Severity | Mitigation |
|------|----------|------------|
| Full-suite WAE still red on non-warning failures | High | Use CI pgvector Postgres; local dev may lack pgvector (observed Postgrex `vector.control` errors) |
| 2026-06-07 expiry before 68-03 merges | High | Baseline update **same PR** as CI flip; policy job runs on every PR |
| Ratchet passes but full suite fails on out-of-ratchet paths | Medium | Expected — 68-01 is intentional staging; inventory identifies clusters |
| p4 runtime noise does not fail WAE | Medium | `--include-runtime` inventory for honest baseline; compile WAE is hard gate |
| `test/tmp` pollution after adoption in CI | Low | Ratchet.test has no preflight; only affects maintainer inventory |
| Knowledge lane warnings excluded from default `mix test` | Medium | Decide in 68-03 on `mix test.knowledge --warnings-as-errors` |
| Path count vs test count confusion | Low | Document: 104 files, ~421 test cases in ratchet scope |
| Early merge 68-02 + 68-03 | Low | Allowed if full WAE greens during p2 work (D-22 discretion) |

**Open unknown:** Exact remaining warning classes in full-suite capture post-67 — requires clean-tmp inventory run in CI-parity environment. Phase 67 deferred queue lists p2/p4; p3 cleared.

---

## 10. Validation Architecture

Nyquist: every plan task gets an `<automated>` verify command; inventory capture is maintainer measurement, not the only gate.

| Plan | Property | Command(s) |
|------|----------|------------|
| **68-00** | WR-01 tmp guard | `MIX_ENV=test mix test test/scoria/warning_inventory/` + manual: run `mix scoria.warning_ratchet.check` then `mix scoria.warning_inventory` without manual rm |
| **68-00** | WR-02 JSON encode | `MIX_ENV=test mix test test/scoria/warning_inventory/` (new JSON encode contract test) |
| **68-00** | Meta-gate | `mix scoria.warning_baseline.check` |
| **68-01** | Staged ratchet WAE | `MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` |
| **68-01** | CI contract | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` |
| **68-01** | Policy unchanged | Same — refute ratchet in policy section |
| **68-02** | Adoption WAE | `MIX_ENV=test mix test.adoption --warnings-as-errors` |
| **68-02** | High-signal WAE | `MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` |
| **68-02** | p2 inventory (maintainer) | `rm -rf test/tmp/* && MIX_ENV=test mix scoria.warning_inventory --scope full` — expect zero `:host_proof_*` |
| **68-03** | Full WARN-07 | `MIX_ENV=test mix test --warnings-as-errors` |
| **68-03** | LiveView runtime measure | `MIX_ENV=test mix scoria.warning_inventory --include-runtime --scope full` |
| **68-03** | Baseline closeout | `mix scoria.warning_baseline.check` + `mix scoria.warning_inventory --write --scope full` |
| **68-03** | Knowledge (optional) | `MIX_ENV=test mix test.knowledge --warnings-as-errors` |
| **All** | WARN-05 regression | `MIX_ENV=test mix compile --warnings-as-errors` + lane-contract WAE (policy job parity) |

**Quick dev loop (68-00/01):**

```bash
mix scoria.warning_baseline.check
rm -rf test/tmp/*
MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors
MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs
```

**CI-parity full closeout (68-03):**

```bash
# Match ci.yml test job env
export MIX_ENV=test SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432
mix ecto.create && mix ecto.migrate
mix test.adoption
mix test.runtime_to_handoff
mix scoria.warning_ratchet.test --warnings-as-errors   # until 68-03 flip
mix test --warnings-as-errors
mix test.knowledge
mix scoria.warning_baseline.check
```

---

## Standard Stack (unchanged from Phase 67)

| Component | Purpose |
|-----------|---------|
| Elixir 1.19 / Mix | WAE via `--warnings-as-errors` |
| ExUnit | Contract + ratchet tests |
| Jason | `warning-inventory.baseline.json` |
| Scoria.WarningInventory / WarningRatchet / WarningBaseline | Classification, paths, expiry |
| GitHub Actions `ci.yml` | Policy vs test job split |
| pgvector/pg16 service | CI test job DB parity |

---

## Don't Hand-Roll

| Problem | Use Instead |
|---------|-------------|
| High-signal path list | `Scoria.WarningRatchet.high_signal_wae_paths/0` |
| Adoption file list | `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` |
| CI closeout order | `Scoria.VerificationLanes.closeout_order/0` + `ci_policy_contract_test.exs` |
| Warning classification | `Scoria.WarningInventory.Cluster.match/1` |
| Baseline expiry | `mix scoria.warning_baseline.check` |

---

## RESEARCH COMPLETE
