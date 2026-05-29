# Phase 79 — Pattern Map

**Phase:** 79 — Tarball consumer overlay proof  
**Generated:** 2026-05-29  
**Inputs read:** `79-CONTEXT.md`, `79-RESEARCH.md`, host proof harness, Phase 78 plan/verification

## Summary

Phase 79 completes HEX-CONSUMER-01 by switching the merge-blocking consumer test from `run_route_proof!/1` to `run_full_proof!/1`, deriving the seven-step contract from `host.overlay_tests`, and layering failure diagnostics (enhanced raises, preserve flag, workspace snapshot, CI artifact). No new proof chain — reuse Phase 78 tarball harness and v2.9 overlay priv sources unchanged.

---

## File Inventory (from CONTEXT + RESEARCH)

| File | Action | Role | Wave | Priority |
|------|--------|------|------|----------|
| `test/scoria/host_app_consumer_proof_test.exs` | modify | Merge-blocking adoption consumer entry | 79-01 | P0 |
| `test/support/scoria/host_app_proof/runner.ex` | modify | Proof orchestration, enhanced failure triage, snapshot hook | 79-01–02 | P0–P1 |
| `test/support/scoria/host_app_proof/generator.ex` | modify | Host map enrichment, preserve flag, cleanup | 79-01–02 | P0 |
| `.github/workflows/ci-verify.yml` | modify | Conditional failure artifact upload | 79-03 | P1 |
| `README.md` | modify (optional) | D-24 Verification one-liner | 79-03 | P2 |
| `docs/operator_verification.md` | modify (optional) | Tarball/preserve/snapshot debug paragraph | 79-03 | P2 |
| `.planning/phases/79-tarball-consumer-overlay-proof/79-VERIFICATION.md` | create | Passed verification ledger | 79-03 | Gate |
| `.planning/REQUIREMENTS.md` | modify | HEX-CONSUMER-01 traceability reconciliation (D-45) | 79-03 | Gate |
| `.planning/ROADMAP.md` | modify | Phase 79 → Complete | 79-03 | Gate |
| `.planning/STATE.md` | modify | Phase pointer → 80 | 79-03 | Gate |
| `.planning/phases/78-hex-consumer-contract-foundation/78-VERIFICATION.md` | modify (optional) | Retro note: Complete deferred to 79 (D-48) | 79-03 | P2 |

**Explicitly untouched:** `lib/mix/tasks/test.adoption.ex`, `lib/scoria/hex_consumer_contract.ex`, `priv/host_app_proof/overlay/test/*.exs`, `run_route_proof!/1`, `VerificationLanes`, `adoption_surface_test`, `ci_policy_contract_test`.

---

## Analog Modules

| Target (modify/create) | Closest analog | Role |
|------------------------|----------------|------|
| `host_app_consumer_proof_test.exs` | Same file (Phase 78 route-only) + `support_copilot_gallery_test.exs` | Adoption integration probe + exact `proof.steps` assertion |
| `runner.ex` enhanced raise / snapshot | Same file (minimal raise) + `support_copilot_gallery/runner.ex` | Subprocess step runner with structured failure output |
| `runner.ex` `expected_steps/1` | `generator.ex` `overlay_test_files/0` + `run_steps/2` flat-map | Derived step SSOT shared by test and runner |
| `generator.ex` preserve flag | Same file `register_cleanup/2` | Opt-in `on_exit` skip (Phoenix `autoremove?: false` idiom) |
| `generator.ex` host map fields | Same file `create_host!/1` return map | Pass `working_root`, `unpack_root`, `dep_mode` to Runner |
| Failure snapshot `tmp/scoria-host-proof-last-failure/` | `HexConsumerContract` `@cache_parent "tmp/scoria-hex-consumer"` | Workspace-relative `tmp/scoria-*` artifact paths |
| CI `upload-artifact` | `ci-verify.yml` existing step blocks (`actions/cache@v4`, job `env:`) | GHA step placement after adoption lane |
| `@moduletag :host_proof` | `eval/offline_runner_test.exs` `@moduletag :eval` | ExUnit tag for targeted local iteration |
| `79-VERIFICATION.md` closeout | `78-VERIFICATION.md` | Frontmatter + requirement table + command matrix |
| README Verification blurb | README `## Verification` (~L191) | Single-sentence maintainer truth after adoption commands |
| Operator debug paragraph | `docs/operator_verification.md` CI gate map (~L281) | Maintainer triage under existing adoption section |

---

## Reusable Patterns and Concrete Analogs

### 1) Consumer proof test — tarball harness + runner swap

**Apply to:** `test/scoria/host_app_consumer_proof_test.exs`

**Current analog (Phase 78 route-only — modify in place):**

```elixir
# test/scoria/host_app_consumer_proof_test.exs
@moduletag timeout: 180_000

setup_all do
  {:ok, unpack_root: Scoria.HexConsumerContract.ensure_current_unpack_root!()}
end

test "generated Phoenix host proves tarball adoption path", %{unpack_root: unpack_root} do
  host = Generator.create_host!(dep_mode: :hex_tarball, unpack_root: unpack_root, cleanup: &on_exit/1)
  mix_exs = File.read!(Path.join(host.root, "mix.exs"))

  refute mix_exs =~ "{:scoria, path: #{inspect(host.repo_root)}}"
  assert mix_exs =~ Scoria.HexConsumerContract.tarball_dep_snippet(unpack_root)

  proof = Runner.run_route_proof!(host)  # → run_full_proof!(host)

  assert proof.steps == [
           :deps_get, :scoria_install, :ecto_create, :ecto_migrate,
           :host_route_smoke_test  # → derived install ++ overlay
         ]
end
```

**Target delta (D-30, D-31, D-32, D-43):**

```elixir
@moduletag timeout: 180_000
@moduletag :host_proof

proof = Runner.run_full_proof!(host)

install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]

overlay =
  host.overlay_tests
  |> Enum.map(fn file -> file |> Path.rootname() |> String.to_atom() end)

assert proof.steps == install ++ overlay
# optional: assert proof.steps == Runner.expected_steps(host)
```

**Gallery step-assertion precedent (exact ordered tuple, slow integration):**

```elixir
# test/scoria/support_copilot_gallery_test.exs
@moduletag timeout: 300_000

proof = Runner.run!()
assert proof.steps == [:deps_get, :gallery_db, :gallery_test]
```

---

### 2) Full proof runner — already shipped; consumer test is the switch

**Apply to:** `test/support/scoria/host_app_proof/runner.ex` (read-only for 79-01; extend in 79-02)

**Analog excerpt — route vs full overlay seam (Phase 78):**

```elixir
# test/support/scoria/host_app_proof/runner.ex
@route_overlay_test "host_route_smoke_test.exs"

def smoke_pair!(host, overlay_files) do
  test_args = ["test"] ++ Enum.map(overlay_files, &("test/" <> &1)) ++ ["--trace"]
  result = run_mix!(host, :overlay_smoke, test_args)

  overlay_files
  |> Enum.map(fn file ->
    step = file |> Path.rootname() |> String.to_atom()
    %{step: step, output: result.output}
  end)
end

def run_route_proof!(host) do
  run_steps(host, [
    &deps_get!/1, &scoria_install!/1, &ecto_create!/1, &ecto_migrate!/1,
    fn h -> smoke_pair!(h, [@route_overlay_test]) end
  ])
end

def run_full_proof!(host) do
  run_steps(host, [
    &deps_get!/1, &scoria_install!/1, &ecto_create!/1, &ecto_migrate!/1,
    &smoke_pair!/1
  ])
end

defp run_steps(host, steps) do
  results = steps |> Enum.flat_map(fn step -> step.(host) |> List.wrap() end)
  %{results: results, steps: Enum.map(results, & &1.step)}
end
```

**Contract notes:**
- `:overlay_smoke` is internal to `run_mix!/1`; `proof.steps` exposes per-file atoms from `smoke_pair!/1` only (D-32).
- Overlay execution order follows **sorted** `host.overlay_tests` from generator — not requirement prose order.
- Keep `run_route_proof!/1` as debug seam; consumer test must not call it (D-33).

---

### 3) Overlay file SSOT — generator sort drives step derivation

**Apply to:** `test/support/scoria/host_app_proof/generator.ex` (existing), consumer step assertion

**Analog excerpt:**

```elixir
# test/support/scoria/host_app_proof/generator.ex
@overlay_test_dir "priv/host_app_proof/overlay/test"

def overlay_test_files do
  Path.wildcard(Path.join([repo_root(), @overlay_test_dir, "*.exs"]))
  |> Enum.map(&Path.basename/1)
  |> Enum.sort()
end

# create_host!/1 return (extend with working_root, unpack_root, dep_mode)
%{
  app_name: app_name,
  db_name: "#{app_name}_test",
  root: host_root,
  repo_root: repo_root,
  overlay_tests: overlay_tests
}
```

**Expected overlay atoms today (sorted basenames):**

| File | Step atom | Requirement |
|------|-----------|-------------|
| `host_handoff_smoke_test.exs` | `:host_handoff_smoke_test` | HOST-02 |
| `host_route_smoke_test.exs` | `:host_route_smoke_test` | route smoke |
| `host_runtime_smoke_test.exs` | `:host_runtime_smoke_test` | HOST-01 |

**Optional shared helper (Claude discretion):**

```elixir
# runner.ex
def expected_steps(host) do
  install = [:deps_get, :scoria_install, :ecto_create, :ecto_migrate]
  overlay = Enum.map(host.overlay_tests, &(&1 |> Path.rootname() |> String.to_atom()))
  install ++ overlay
end
```

---

### 4) Host map enrichment for diagnostics

**Apply to:** `generator.ex` `create_host!/1` return map

**Gap:** `working_root` is local today (`generator.ex:23–24`); Runner cannot snapshot without it on host map.

**Target fields (recommended):**

```elixir
%{
  app_name: app_name,
  db_name: "#{app_name}_test",
  root: host_root,
  working_root: working_root,       # parent dir — preserve + snapshot target
  repo_root: repo_root,
  overlay_tests: overlay_tests,
  dep_mode: dep_mode,
  unpack_root: Keyword.get(opts, :unpack_root)  # when :hex_tarball
}
```

**Tarball dep patch analog (unchanged in 79):**

```elixir
# generator.ex :hex_tarball branch
{:scoria, path: unpack_root} = Scoria.HexConsumerContract.tarball_dep_tuple(unpack_root)
"{:scoria, path: #{inspect(unpack_root)}},"
```

---

### 5) Enhanced Runner raise — extend minimal subprocess failure

**Apply to:** `runner.ex` `run_mix!/1` failure path (D-39)

**Current baseline (extend, do not replace pattern):**

```elixir
# test/support/scoria/host_app_proof/runner.ex
if status != 0 do
  raise """
  host proof step failed: #{step}
  command: mix #{Enum.join(args, " ")}
  host: #{host.root}

  #{output}
  """
end
```

**Gallery runner analog (same raise shape, different prefix):**

```elixir
# test/support/scoria/support_copilot_gallery/runner.ex
if status != 0 do
  raise """
  support copilot gallery step failed: #{step}
  command: mix #{Enum.join(args, " ")}
  root: #{@gallery_root}

  #{output}
  """
end
```

**Target failure path sketch:**

```elixir
if status != 0 do
  maybe_snapshot_failure!(host, step)  # D-41 — before re-raise
  raise triage_message(host, step, args, output)
end
```

**Required triage fields (plain string raise — no custom exception):**

| Field | Source |
|-------|--------|
| `step`, `command` | `run_mix!/1` args |
| `host.root`, `host.app_name`, `host.db_name` | host map |
| `unpack_root` / `SCORIA_HEX_UNPACK_ROOT` | host map + `System.get_env/1` |
| Tarball dep snippet | `HexConsumerContract.tarball_dep_snippet(unpack_root)` |
| Overlay file list | `host.overlay_tests` |
| `SCORIA_DB_*` | env (no password) |
| Replay command | install: `cd #{host.root} && MIX_ENV=test mix …`; overlay: `mix test test/<files> --trace` |
| Preserve hint | `SCORIA_PRESERVE_HOST=1 …` |

**Nested overlay failure extract (`step == :overlay_smoke`):** scan output for first line matching `FAIL` or `** (` and prepend to triage block.

**HexConsumerContract helpers for MANIFEST / triage (read-only import):**

```elixir
# lib/scoria/hex_consumer_contract.ex
def tarball_dep_snippet(unpack_root), do: "{:scoria, path: #{inspect(unpack_root)}}"
def package_fingerprint/0  # 12-char hex for MANIFEST
def published_version/0
```

---

### 6) Preserve flag — opt-in cleanup skip

**Apply to:** `generator.ex` `register_cleanup/2` (D-40)

**Current analog (always rm_rf on exit):**

```elixir
# test/support/scoria/host_app_proof/generator.ex
defp register_cleanup(opts, path) do
  case Keyword.get(opts, :cleanup) do
    nil -> :ok
    register when is_function(register, 1) -> register.(fn -> File.rm_rf!(path) end)
  end
end
```

**Target pattern:**

```elixir
defp preserve_host? do
  System.get_env("SCORIA_PRESERVE_HOST") in ~w(1 true yes)
end

defp register_cleanup(opts, path) do
  case Keyword.get(opts, :cleanup) do
    nil -> :ok
    register when is_function(register, 1) ->
      if preserve_host?() do
        IO.warn("SCORIA_PRESERVE_HOST: preserved host at #{path}")
      else
        register.(fn -> File.rm_rf!(path) end)
      end
  end
end
```

**Maintainer loop:**

```bash
SCORIA_PRESERVE_HOST=1 mix test --only host_proof --trace
```

**Contrast — shared hex cache must never be deleted (Phase 78 D-10):** no `File.rm_rf!` of `tmp/scoria-hex-consumer/` in tests.

---

### 7) Failure snapshot — workspace `tmp/` copy before re-raise

**Apply to:** `runner.ex` (new private functions), triggered from `run_mix!/1` (D-41)

**Workspace tmp precedent:**

```elixir
# lib/scoria/hex_consumer_contract.ex
@cache_parent "tmp/scoria-hex-consumer"
```

**Target destination:**

```
tmp/scoria-host-proof-last-failure/   # replace prior on each failure
├── MANIFEST.txt
└── host/                             # copy of host.working_root
```

**Copy semantics:**

1. `File.rm_rf!("tmp/scoria-host-proof-last-failure")` if exists  
2. `File.mkdir_p!("tmp/scoria-host-proof-last-failure")`  
3. Copy `host.working_root` → `tmp/scoria-host-proof-last-failure/host/`  
4. Write `MANIFEST.txt` (timestamp, failed_step, host paths, fingerprint, replay commands)

**Why workspace copy:** generated host lives under `System.tmp_dir!()`; GHA uploads from repo `tmp/` only.

---

### 8) CI failure artifact — first `upload-artifact` in repo

**Apply to:** `.github/workflows/ci-verify.yml` test job (D-42)

**Existing step block pattern (placement reference):**

```yaml
# .github/workflows/ci-verify.yml (test job)
env:
  SCORIA_HEX_UNPACK_ROOT: tmp/scoria-release-preview

- name: Run adoption closure lane
  run: mix test.adoption
```

**Target step (after adoption lane or end of job):**

```yaml
- name: Upload host proof failure snapshot
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: scoria-host-proof-last-failure
    path: tmp/scoria-host-proof-last-failure/
    retention-days: 7
    if-no-files-found: ignore
```

**Constraints:** failure-only; scoped path; no `_build` or hex cache upload.

---

### 9) Module tag for local iteration

**Apply to:** `host_app_consumer_proof_test.exs` (D-43)

**Analog:**

```elixir
# test/scoria/eval/offline_runner_test.exs
@moduletag :eval
```

**Does not change** `mix test.adoption` file list — tag is additive for `mix test --only host_proof`.

---

### 10) Closeout ceremony — requirement-owning phase bundle

**Apply to:** `79-VERIFICATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` (D-45)

**Verification frontmatter analog:**

```yaml
# .planning/phases/78-hex-consumer-contract-foundation/78-VERIFICATION.md
---
status: passed
phase: 78-hex-consumer-contract-foundation
verified: 2026-05-29T20:00:00Z
requirements:
  - HEX-CONSUMER-01
---
```

**78 partial vs 79 complete narrative (audit hygiene):**

```markdown
| **HEX-CONSUMER-01** | Tarball dep; route smoke only | **Partial (as scoped)** | run_route_proof!/1, five steps |
| Phase 79 | full overlay on tarball | deferred | run_full_proof!/1 |
```

**79 gate:** flip HEX-CONSUMER-01 to milestone Complete only with green `mix test.adoption` + full seven-step evidence. Do **not** mark DOCS-HEX-01 Complete (Phase 82).

**Phase gate commands (from 78-03 verification block):**

```bash
MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs
MIX_ENV=test mix test --only host_proof
MIX_ENV=test mix test.adoption
MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption
MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs
```

---

### 11) Optional docs polish (not gate)

**README (D-47)** — insert under `## Verification` after adoption commands (~L191):

> Adoption closeout in CI exercises Scoria via a `mix hex.build --unpack` tarball (`{:scoria, path: unpack_root}`), not a monorepo root `path:` — see `Scoria.HexConsumerContract` and `SCORIA_HEX_UNPACK_ROOT` in maintainer CI.

**Operator doc** — one paragraph near CI gate map / adoption triage: tarball consumer proof, `SCORIA_PRESERVE_HOST`, `tmp/scoria-host-proof-last-failure/`, `--only host_proof`. No `adoption_surface_test` pins until Phase 82.

---

## Overlay Semantics (priv sources — untouched)

v2.9 validated HOST-01/02 on generated host; Phase 79 re-proves via tarball dep only.

```elixir
# priv/host_app_proof/overlay/test/host_route_smoke_test.exs — router metadata
assert Phoenix.Router.route_info(ScoriaHostProofWeb.Router, "GET", "/scoria", nil).plug == Phoenix.LiveView.Plug

# priv/host_app_proof/overlay/test/host_runtime_smoke_test.exs — HOST-01 sandbox + approval
:ok = Sandbox.checkout(Scoria.Repo)
# … approval/resume/evidence …

# priv/host_app_proof/overlay/test/host_handoff_smoke_test.exs — HOST-02 handoff
assert {:ok, handoff_run} = Scoria.start_handoff_run(identity, SupportJourney.handoff_role_id(), …)
```

---

## File Modification Map (plan waves)

| File | Wave | Pattern to follow |
|------|------|-------------------|
| `test/scoria/host_app_consumer_proof_test.exs` | 79-01 | Phase 78 consumer test + gallery `proof.steps` + eval `@moduletag` |
| `test/support/scoria/host_app_proof/runner.ex` | 79-01–02 | Existing `run_full_proof!/1`; extend gallery-style raise; add snapshot hook |
| `test/support/scoria/host_app_proof/generator.ex` | 79-01–02 | Extend host map; preserve flag in `register_cleanup/2` |
| `.github/workflows/ci-verify.yml` | 79-03 | Job step after adoption; `if: failure()` artifact |
| `README.md` | 79-03 | Verification section single sentence |
| `docs/operator_verification.md` | 79-03 | CI gate map triage bullet |
| `.planning/phases/79-…/79-VERIFICATION.md` | 79-03 | `78-VERIFICATION.md` structure |
| `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` | 79-03 | D-45 ledger bundle |

---

## Key Links

```
host_app_consumer_proof_test.exs
  → HexConsumerContract.ensure_current_unpack_root!/0  (setup_all)
  → Generator.create_host!(dep_mode: :hex_tarball, …)
  → Runner.run_full_proof!/1
  → assert proof.steps == install ++ overlay

Generator.overlay_test_files/0
  → priv/host_app_proof/overlay/test/*.exs (sorted)
  → host.overlay_tests
  → Runner.smoke_pair!/1 (one mix test subprocess)

Runner.run_mix!/1 (on failure)
  → maybe_snapshot_failure! → tmp/scoria-host-proof-last-failure/
  → triage_message/4 → re-raise

ci-verify.yml (test job failure)
  → upload-artifact: tmp/scoria-host-proof-last-failure/
```

---

## Explicit Rejections (do not pattern-match)

| Rejected | Reason |
|----------|--------|
| Remove `run_route_proof!/1` | Debug seam (D-33) |
| Assert `:overlay_smoke` in `proof.steps` | Internal step; flat-map exposes per-file atoms only |
| Subset/`in` step assertions on adoption path | D-32 exact ordered contract |
| Per-overlay separate ExUnit cases | 3× `phx.new` cost (D-38) |
| `@moduletag timeout: 420_000` or global ExUnit widen | D-37 escalation cap 240_000 only after CI evidence |
| Always preserve hosts | Disk hygiene; opt-in env only (D-40) |
| `adoption_surface_test` tarball pins | Phase 82 (D-46) |

---

## PATTERN MAPPING COMPLETE
