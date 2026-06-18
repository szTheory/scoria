# Phase 31: Dockerfile caching audit + doc — Research

**Researched:** 2026-06-18
**Domain:** Docker BuildKit layer caching, Elixir CI policy-lane contract tests
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Layer order is already correct. `COPY mix.exs mix.lock` → `mix deps.get` (L40–42) → `COPY config config` → `mix deps.compile` (L46–49) → `COPY lib`/`dev`/`priv` → `mix compile` (L52–56). No reordering.
- **D-02:** CSS edits invalidate zero image layers. `assets/` is never `COPY`'d — it is bind-mounted at runtime. A HEEx edit invalidates only `COPY lib lib` → incremental `mix compile`. The roadmap's row "CSS/HEEx-only edit → app compile only" conflates two behaviors; the deliverables must tell this honestly.
- **D-03:** `assets/css/app.css` does not exist. Use `assets/css/06-utilities.css`.
- **D-04:** No `make cache-audit` target. Ship a documented, repeatable command + one-time recorded snapshot in SUMMARY.
- **D-05:** Proof mechanics: `docker compose build web` (warm cache), then `touch` target files, then `docker compose build --progress=plain web 2>&1 | tee /tmp/scoria-cacheproof.log`, then `grep -nE 'mix deps\.get' /tmp/scoria-cacheproof.log`. Pass = `mix deps.get` appears only as `CACHED` step.
- **D-06:** Ship accurate 4-row table appended to END of §"No rebuild on source/style edits" with bind-mount-vs-cold-build framing.
- **D-07:** No standalone apt/system layer row — fold into framing sentence.
- **D-08:** Append COPY-order test to existing `test/scoria/ci_policy_contract_test.exs`. No new file. Zero CI-YAML edit.
- **D-09:** Assertion strategy: relative `index_of` on stable substrings. Test pins `@layer_invariant_marker`.
- **D-10:** Add invariant comment immediately above `COPY lib lib` (~L51). Marker must be distinct from the header phrase "Layer order is deliberate" at L7.
- **D-11:** Phase 34 hand-off: assert table's three load-bearing strings in `docs/docker_dev_dx.md`. Record, don't build here.

### Claude's Discretion

- Exact wording of SUMMARY evidence block, table cell prose (keep D-08's load-bearing strings), invariant-comment phrasing, `index_of!` helper implementation.
- Whether to cross-link from Dockerfile header (L6–11) to new table.
- Whether to record proof for `up --build` in addition to `build --progress=plain`.

### Deferred Ideas (OUT OF SCOPE)

- `make cache-audit` target (D-04 rejected).
- Standalone apt/system layer table row (D-07 rejected).
- Phase 34 table-string assertions (D-11, built in Phase 34).
- `docs/docker_dev_dx.md` reader-empathy rewrite (Phase 33).
- `docker_dx_doc_contract_test.exs` doc-string contract test (Phase 34).
- `post-publish-smoke.yml` ephemeral-port scan extension (Phase 34).
- Secrets/rotation (Phase 32), maintenance release (Phase 35).
- Sibling-repo migration (out of scope for entire milestone).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CACHE-01 | A CSS/HEEx-only source edit triggers no Mix dependency refetch and no full app recompile — empirically verified and documented as a layer-invalidation table plus a layer-order invariant comment in `Dockerfile.dev`. | Layer order verified at L40–56 [VERIFIED: Dockerfile.dev:40-56]; `assets/` never COPY'd confirmed [VERIFIED: Dockerfile.dev grep]; CSS file exists [VERIFIED: assets/css/06-utilities.css]; HEEx files under `lib/` confirmed [VERIFIED: lib/scoria_web/components/layouts/]; static test pattern validated against existing `index_of` helper [VERIFIED: test/scoria/ci_policy_contract_test.exs:704-709] |
</phase_requirements>

---

## Summary

Phase 31 is a documentation + static-guard phase, not a code change phase. The caching order in `Dockerfile.dev` is already correct and has been independently verified line-by-line against the codebase. This research confirms every load-bearing claim in CONTEXT.md D-01 through D-10 with exact file/line evidence, identifies the precise insertion points for each deliverable, and surfaces two implementation details the planner must act on (the existing `index_of` helper vs the proposed `index_of!`, and the exact `COPY mix.exs mix.lock ./` trailing `./` that does not affect substring matching).

The three deliverables interlock cleanly: (A) the empirical proof run once locally and recorded in SUMMARY; (B) the invariant comment at `Dockerfile.dev:L51` + the 4-row table appended after `docs/docker_dev_dx.md:L87`; (C) the COPY-order test appended to `test/scoria/ci_policy_contract_test.exs` before the first `defp` at L639.

**Primary recommendation:** Execute the three deliverables in order A → B → C. No Docker daemon is needed to run or verify deliverables B and C; only the empirical proof (A) requires a live Docker build. Record the `--progress=plain` grep output in SUMMARY as the permanent evidence for criterion 1.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Layer-order correctness (runtime) | Docker image builder | — | BuildKit decides layer reuse; layer order in Dockerfile is the control surface |
| Layer-order correctness (structural guard) | CI policy lane (no DB) | — | Static `File.read!` test — no Docker daemon needed; runs on every `mix test` |
| Human documentation of the invariant | Dockerfile.dev comment | docs/docker_dev_dx.md | Comment is the authoritative human signal at the boundary; doc provides the mental model |
| Empirical proof (criterion 1) | Developer workstation | — | Requires live Docker daemon + real BuildKit cache; inherently local/one-time |

---

## Verification of D-01: Layer Order Line Numbers

**Source: `Dockerfile.dev` — verified by direct read** [VERIFIED: Dockerfile.dev]

```
L40:  COPY mix.exs mix.lock ./          ← Step 1: dep manifests
L41:  RUN --mount=type=cache,target=/root/.hex,sharing=locked \
L42:      mix deps.get
L43:  (blank)
L44:  # 2) Compile-time config before deps.compile
L45:  #    (comment continues)
L46:  COPY config config                 ← Step 2: compile-time config
L47:  RUN --mount=type=cache,...
L48:      --mount=type=cache,...
L49:      mix deps.compile
L50:  (blank)
L51:  # 3) Volatile source last — editing these does NOT invalidate the layers above.
L52:  COPY lib lib                       ← Step 3: volatile source
L53:  COPY dev dev
L54:  COPY priv priv
L55:  (blank)
L56:  RUN mix compile
```

**CONTEXT D-01 line claims vs reality:**

| CONTEXT claim | Reality | Match? |
|---|---|---|
| `COPY mix.exs mix.lock` at L40 | L40: `COPY mix.exs mix.lock ./` | YES (note trailing `./` — see Static Test section) |
| `mix deps.get` at L42 | L42: `    mix deps.get` | YES |
| `COPY config` at L46 | L46: `COPY config config` | YES |
| `mix deps.compile` at L46–49 | L47–49 (RUN at 47, option at 48, mix at 49) | YES |
| `COPY lib`/`dev`/`priv` at L52–54 | L52–54 | YES |
| `mix compile` at L56 | L56: `RUN mix compile` | YES |
| Header rationale at L6–11 | L6–11: `# Layer order is deliberate...` at L7 | YES |

**Conclusion:** D-01 line number claims are exact. [VERIFIED: Dockerfile.dev:36-56]

---

## Verification of D-02/D-03: CSS + HEEx Facts

**`assets/css/app.css` existence:**
```
$ ls assets/css/
00-fonts.css  01-reset.css  02-tokens.css  03-base.css
04-components.css  05-motion.css  06-utilities.css
```
`assets/css/app.css` does NOT exist. D-03 is confirmed. [VERIFIED: filesystem]

**`assets/css/06-utilities.css` existence:** Confirmed present. [VERIFIED: filesystem]

**HEEx files:**
```
lib/scoria_web/components/layouts/root.html.heex
lib/scoria_web/components/layouts/app.html.heex
```
Confirmed 2 HEEx files under `lib/`. Editing either invalidates `COPY lib lib` (L52). [VERIFIED: filesystem]

**`assets/` in build context but never COPY'd:**
- `.dockerignore` does NOT exclude `assets/` → `assets/` IS in the build context [VERIFIED: .dockerignore]
- No `COPY` line in `Dockerfile.dev` references `assets/` → never copied into image [VERIFIED: Dockerfile.dev grep]
- `priv/static/scoria/` IS excluded from build context via `.dockerignore:25` [VERIFIED: .dockerignore:25]

**Conclusion:** CSS edits invalidate zero layers (assets never COPY'd). A HEEx edit (under `lib/`) invalidates `COPY lib lib` → `mix compile` only. D-02 is confirmed exactly as stated. [VERIFIED: Dockerfile.dev + .dockerignore]

---

## Verification of D-05: BuildKit Proof Mechanics

**Docker version:** 29.5.2 [VERIFIED: `docker --version`]
**Docker Compose version:** v5.1.3 [VERIFIED: `docker compose version`]
**BuildKit version:** buildx v0.34.0-desktop.1 [VERIFIED: `docker buildx version`]

**Compose service name:** `web` (confirmed in `compose.yml:45` — no `profiles:` restriction on the `web` service). [VERIFIED: compose.yml:45]

**`--progress=plain` behavior with BuildKit:** With `--progress=plain`, BuildKit emits `CACHED` on the line for each cached step in the form:
```
#N CACHED
```
or inline with the step description. The proof grep `grep -nE 'mix deps\.get'` on a warm-cache run will match the RUN step that contains `mix deps.get` — it will show `CACHED` in the BuildKit output before that step's content line. Pass condition: the word `CACHED` appears on or before the line matching `mix deps\.get`; no download/fetching output follows it.

**`docker compose up --build` vs `docker compose build --progress=plain`:** `up --build` uses `--progress=auto`, which collapses cached steps entirely (they don't appear at all in terminal output), making it impossible to grep for `CACHED`. Use `docker compose build --progress=plain web` for the proof; `up --build` is the user-facing command the criterion specifies for the success criterion — it will simply show no deps activity, which is the user experience being guaranteed. D-05's proof approach is sound.

**Important nuance for the executor:** The `--progress=plain` output format has changed slightly between BuildKit versions. The `CACHED` marker appears as a prefix to the step number line, e.g.:
```
#12 CACHED
```
The `grep -nE 'mix deps\.get'` command in D-05 targets the RUN step that *contains* `mix deps.get` as its command text. In `--progress=plain` output, BuildKit prints each step's command after the step header. The executor should grep for both the step header and the command text to confirm the `CACHED` status. A reliable proof check:
```bash
grep -E 'CACHED|mix deps\.get' /tmp/scoria-cacheproof.log
```
This shows the `CACHED` header lines alongside any `mix deps.get` mentions, making the association clear in the recorded output.

---

## Verification of D-08/D-09: Static Test Mechanics

### Existing `index_of` helper (NO new helper needed)

The existing `index_of/2` private helper at `ci_policy_contract_test.exs:704-709` already provides the "flunk on `:nomatch`" behavior that D-09 describes as `index_of!`. [VERIFIED: test/scoria/ci_policy_contract_test.exs:704-709]

```elixir
defp index_of(content, needle) do
  case :binary.match(content, needle) do
    {index, _length} -> index
    :nomatch -> flunk("Expected to find #{inspect(needle)} in content")
  end
end
```

**Implication for the planner:** The new test block uses the **existing** `index_of/2` helper (no bang, no new helper). D-09's pseudocode calls it `index_of!` but the actual function is `index_of`. This is the only name difference from D-09's pseudocode; the behavior is identical.

### Substring verification

All three D-09 substrings appear exactly once in `Dockerfile.dev`: [VERIFIED: Dockerfile.dev via Python `:binary.match` simulation]

| Substring | Line | Full line text | Occurrences |
|-----------|------|----------------|-------------|
| `"COPY mix.exs mix.lock"` | L40 | `COPY mix.exs mix.lock ./` | 1 |
| `"COPY config"` | L46 | `COPY config config` | 1 |
| `"COPY lib"` | L52 | `COPY lib lib` | 1 |

**Ordering assertion results (simulated with Python `str.find()` = `:binary.match` equivalent):**
```
i_lock   = 1913  (byte offset of "COPY mix.exs mix.lock")
i_config = 2172  (byte offset of "COPY config")
i_lib    = 2418  (byte offset of "COPY lib")

i_lock < i_config  → True  ✓
i_config < i_lib   → True  ✓
```

**`COPY lib` substring specificity:** `"COPY lib"` matches `COPY lib lib` at L52 and nothing else. No other COPY line starts with `COPY lib`. The substrings `COPY dev` and `COPY priv` (L53–54) do not appear in any assertion — only `COPY lib` is used as the anchor for the volatile-source boundary, which is correct since the `assert df =~ @layer_invariant_marker` covers the full boundary via the comment test. [VERIFIED: Dockerfile.dev]

**Note on trailing `./`:** `COPY mix.exs mix.lock ./` has a trailing `./` destination. The assertion substring `"COPY mix.exs mix.lock"` (without `./`) is a valid prefix match — `:binary.match` finds the first occurrence of the needle as a subsequence, so `"COPY mix.exs mix.lock"` will match inside `"COPY mix.exs mix.lock ./"`. This is correct and does not need changing. [VERIFIED: Python simulation]

### `@layer_invariant_marker` coupling

D-10 specifies the invariant comment must carry a distinct string the test pins. The existing header at L7 contains: `"Layer order is deliberate"`. The proposed marker `"INVARIANT: volatile source"` is distinct from this phrase. The test's `assert df =~ @layer_invariant_marker` will fail if the boundary comment is removed or renamed, but will not match the pre-existing header. [VERIFIED: Dockerfile.dev:7]

### Module attribute pattern to mirror

The file uses `@attr_name "string_value"` at module level (lines 6–17), all two-space indented. The new `@layer_invariant_marker` follows this pattern: [VERIFIED: ci_policy_contract_test.exs:6-17]

```elixir
@layer_invariant_marker "INVARIANT: volatile source"
```

### Test insertion point

The last `test` block ends at line ~637 (`"planning ledgers..."` test). The first `defp` begins at line 639 (`defp lane_contract_step`). The new test block is appended after the last `test` block and before the first `defp`. [VERIFIED: ci_policy_contract_test.exs:626-639]

### `async: true` and `--no-start` compatibility

The module is `use ExUnit.Case, async: true`. The new test uses only `File.read!("Dockerfile.dev")` — a pure filesystem read with no process state, no DB, no app start. It is fully compatible with `async: true` and `--no-start`. The policy lane runs: [VERIFIED: .github/workflows/ci-verify.yml:56]

```
mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

No CI-YAML change is needed. Appending a test block to `ci_policy_contract_test.exs` is automatically covered by this policy lane step.

### No `describe` blocks

There are zero `describe` blocks in `ci_policy_contract_test.exs`. All tests are flat at module level. The new test block follows this pattern. [VERIFIED: ci_policy_contract_test.exs grep]

---

## Verification of D-10: Invariant Comment Placement

**Current state of line 51:** [VERIFIED: Dockerfile.dev:51]
```dockerfile
# 3) Volatile source last — editing these does NOT invalidate the layers above.
COPY lib lib
```

The invariant comment is inserted **immediately above `COPY lib lib`**, replacing the existing `# 3)` comment OR prepending above it. The CONTEXT suggests inserting `above` `COPY lib lib` — the most natural approach is to add the `# INVARIANT:` block after the blank line at L50 and before `COPY lib lib`. The existing `# 3)` comment at L51 is the current only comment at this boundary; the new invariant comment either replaces it or precedes it.

**Recommendation for the planner:** The executor should ADD the invariant comment block above the existing `# 3)` comment. Do not remove the `# 3)` comment — it is load-bearing as a step-number marker cited in the docs table ("step 3"). The result will be:

```dockerfile
# INVARIANT: volatile source (lib/dev/priv) MUST stay below deps.get + deps.compile.
# Reordering re-fetches/recompiles deps on every source edit. Layer order is deliberate
# — see docs/docker_dev_dx.md (layer-invalidation table). Guarded by
# test/scoria/ci_policy_contract_test.exs.
# 3) Volatile source last — editing these does NOT invalidate the layers above.
COPY lib lib
```

**Existing header distinctness:** Header at L6–11 contains `"Layer order is deliberate"`. The invariant comment also contains this phrase (from D-10's suggested wording). The `@layer_invariant_marker` must use `"INVARIANT: volatile source"` (a string that does NOT appear in the header), not `"Layer order is deliberate"` (which DOES appear in the header). This is explicitly called out in D-10 and confirmed here. [VERIFIED: Dockerfile.dev:7]

---

## Verification of D-06: Table Insertion Point in docs/docker_dev_dx.md

**Section structure:** [VERIFIED: docs/docker_dev_dx.md]

```
L68:  ## No rebuild on source/style edits
...
L85:  - **Cold builds** reuse BuildKit cache mounts for apt + the Hex/rebar caches —
L86:    see [Dockerfile.dev](../Dockerfile.dev). Use VirtioFS in Docker Desktop;
L87:    `:cached`/`:delegated` mount flags are legacy no-ops now — don't add them.
L88:  (blank line)
L89:  ## Adopting this in another repo
```

The table is appended **after line 87** (end of "Cold builds" bullet), before the blank line and before `## Adopting this in another repo`. The file is 151 lines total. [VERIFIED: docs/docker_dev_dx.md:85-89, wc -l]

**Table appended = new content inserted between L87 and L88 (blank).** The planner should insert after the `don't add them.` line and before `## Adopting this in another repo`.

---

## Verification of compose.yml and .dockerignore

**Named volumes confirmed:** [VERIFIED: compose.yml:60-63]
```yaml
volumes:
  - .:/app                 # live source (bind mount)
  - deps:/app/deps         # named volume — shadows bind mount
  - build:/app/_build      # named volume — shadows bind mount
  - hex:/root/.hex
  - mix:/root/.mix
```

The named volumes `deps` and `build` are declared at the top level of compose.yml. The bind mount `.:/app` plus named volumes `deps:/app/deps` and `build:/app/_build` together create the "no layer rebuild on source edits" guarantee during `docker compose up`. [VERIFIED: compose.yml:135-141]

**`.dockerignore` confirms the CSS-rebuilds-nothing mechanism:** [VERIFIED: .dockerignore]
- `_build/` excluded → host build artifacts don't leak in
- `deps/` excluded → host deps don't leak in
- `priv/static/scoria/` excluded (line 25) → in-container built output not in build context
- `assets/` NOT listed → is in build context, but never COPY'd by Dockerfile.dev

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Layer-order structural guard | Custom shell script / Make target | Elixir `File.read!` + `:binary.match` in existing test file | Zero Docker cost, deterministic, runs in ms on every `mix test` |
| Proof of layer caching | CI job running Docker build | One-time local `--progress=plain` build + grep recorded in SUMMARY | CI BuildKit cache is non-deterministic per runner; local proof is the only reliable cache evidence |
| `index_of!` bang helper | New private helper | Existing `index_of/2` (already flunks on `:nomatch`) | Already present at ci_policy_contract_test.exs:704; avoid duplicating |

---

## Common Pitfalls

### Pitfall 1: `@layer_invariant_marker` matches the header, not the boundary

**What goes wrong:** The marker string `"Layer order is deliberate"` appears at Dockerfile.dev:7 (header). If used as `@layer_invariant_marker`, the `assert df =~ @layer_invariant_marker` assertion passes even if the boundary comment is removed — it finds the header, not the boundary.

**Why it happens:** CONTEXT D-10 says "not the pre-existing header phrase `'Layer order is deliberate'` at L7" but the suggested invariant comment wording includes that phrase in passing.

**How to avoid:** Set `@layer_invariant_marker "INVARIANT: volatile source"`. This string does NOT appear anywhere in the current Dockerfile.dev; it will only exist after the boundary comment is added. The test then truly pins the boundary comment. [VERIFIED: Dockerfile.dev grep for "INVARIANT"]

**Warning signs:** If the test passes before the boundary comment is added, the marker is wrong.

### Pitfall 2: Using `index_of!` instead of `index_of`

**What goes wrong:** D-09 pseudocode uses `index_of!` (bang). The actual helper is `index_of/2` (no bang). Writing `index_of!(df, ...)` will produce a `UndefinedFunctionError` at test runtime.

**How to avoid:** Use `index_of(df, ...)` — the existing `defp index_of/2` already flunks on `:nomatch`, providing the same semantics. [VERIFIED: ci_policy_contract_test.exs:704]

### Pitfall 3: Proof run with cold Docker cache

**What goes wrong:** If the executor runs `docker compose build --progress=plain web` without first warming the cache (`docker compose build web`), ALL steps will execute (no `CACHED` markers) — the grep passes vacuously wrong and shows no deps.get at all, but that's because nothing is cached, not because the cache works.

**How to avoid:** Always run `docker compose build web` (no `--progress=plain`) first to warm the cache, THEN run the `touch` + `docker compose build --progress=plain web` sequence. The D-05 proof mechanics are already sequenced correctly — just don't skip step 1.

### Pitfall 4: Inserting above `COPY lib lib` removes the `# 3)` step comment

**What goes wrong:** The existing `# 3) Volatile source last` comment at L51 is cited in the docs table as "step 3". If the executor replaces it rather than prepending above it, the docs table refers to a comment that no longer exists.

**How to avoid:** Add the `# INVARIANT:` block BEFORE (above) the existing `# 3)` line. Keep both comments. [VERIFIED: Dockerfile.dev:51]

### Pitfall 5: Table row for CSS says "app compile only"

**What goes wrong:** The table's CSS row must say "nothing rebuilds" — not "app compile only". Using "app compile only" for CSS is the roadmap's inaccurate conflation (D-02 corrects this). The roadmap-literal-but-wrong row would make the docs dishonest and the Phase 34 doc-string guard (D-11) would encode the wrong string.

**How to avoid:** The CSS row explicitly says `assets/` is not `COPY`'d and nothing rebuilds. Only the HEEx/`lib/` row says "app compile only". D-06's table markdown has the correct text — use it verbatim.

---

## Code Examples

### New test block to append (before first `defp` at ci_policy_contract_test.exs:639)

```elixir
test "Dockerfile.dev keeps cache-optimal COPY layer order (deps -> config -> source)" do
  df = File.read!("Dockerfile.dev")
  i_lock   = index_of(df, "COPY mix.exs mix.lock")
  i_config = index_of(df, "COPY config")
  i_lib    = index_of(df, "COPY lib")
  assert i_lock < i_config,  "COPY mix.exs mix.lock must precede COPY config"
  assert i_config < i_lib,   "COPY config must precede COPY lib"
  assert df =~ @layer_invariant_marker,
         "Dockerfile.dev must contain the boundary invariant comment (#{inspect(@layer_invariant_marker)})"
end
```

Notes:
- Uses existing `index_of/2` (no bang, no new helper needed)
- `@layer_invariant_marker` must be added to module attributes block (lines 6-17) as `@layer_invariant_marker "INVARIANT: volatile source"`
- Readable assertion messages included (not in D-09 pseudocode but good practice matching the existing style)

### Module attribute to add (in the `@attr` block at lines 6-17)

```elixir
@layer_invariant_marker "INVARIANT: volatile source"
```

### Invariant comment for Dockerfile.dev (insert before line 51)

```dockerfile
# INVARIANT: volatile source (lib/dev/priv) MUST stay below deps.get + deps.compile.
# Reordering re-fetches/recompiles deps on every source edit. Layer order is deliberate
# — see docs/docker_dev_dx.md (layer-invalidation table). Guarded by
# test/scoria/ci_policy_contract_test.exs.
```

Followed immediately by the existing `# 3) Volatile source last` line (keep it).

### Table and framing to append to docs/docker_dev_dx.md (after line 87)

```markdown

### Layer-cache invalidation (cold `docker compose up --build` only)

Day-to-day you run `docker compose up`: source is bind-mounted and `deps`/`_build`
are named volumes, so **editing anything rebuilds no image layer at all** — you just
restart the app. The table below applies only to a cold `--build`, where the
`Dockerfile.dev` COPY order decides what the BuildKit cache can reuse. (The base
image + `apt` layer sit above all of these and rebuild only when the base image or
package list changes.)

| You edit | First invalidated layer | What re-runs |
|----------|-------------------------|--------------|
| CSS (`assets/css/*.css`) or any `assets/` file | **none** — `assets/` is not `COPY`'d (built in-container at runtime; `priv/static/scoria/` is `.dockerignore`'d) | nothing rebuilds; running container rebuilds assets on the fly |
| A `.heex` template or any `lib/`, `dev/`, `priv/` source file | `COPY lib lib` (step 3) | `mix compile` — **app compile only**; deps untouched |
| Anything under `config/` | `COPY config config` (step 2) | `mix deps.compile` + `mix compile` |
| `mix.exs` or `mix.lock` | `COPY mix.exs mix.lock` (step 1) | `mix deps.get` → `mix deps.compile` → `mix compile` (full dep rebuild) |
```

---

## Architecture Patterns

### Recommended Project Structure (no new files)

```
Dockerfile.dev              # add invariant comment above COPY lib lib (L51)
docs/docker_dev_dx.md       # append table after L87 (Cold builds bullet)
test/scoria/
  ci_policy_contract_test.exs  # append test block before first defp (L639)
.planning/phases/31-.../
  SUMMARY.md (new)            # record empirical proof output
```

### Pattern: Policy-Lane Static Contract Test

All tests in `ci_policy_contract_test.exs` use the same idiom: [VERIFIED: ci_policy_contract_test.exs]

1. Module attribute declares a path constant
2. `File.read!/1` loads the file by path
3. `assert content =~ substring` or `index_of/2` comparisons
4. `async: true`, no DB, no app start — compatible with `--no-start`

The new COPY-order test is identical in shape to the existing `"policy job runs ci_policy_contract_test in lane-contract step"` test at line 596.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Empirical proof (D-05) | ✓ | 29.5.2 | — |
| Docker Compose | Empirical proof (D-05) | ✓ | v5.1.3 | — |
| BuildKit | `--progress=plain` proof | ✓ | buildx v0.34.0 | — |
| `assets/css/06-utilities.css` | Proof touch target | ✓ | exists | — |
| `lib/scoria_web/components/layouts/root.html.heex` | Proof touch target | ✓ | exists | — |

---

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` → treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir/Mix) |
| Config file | `config/test.exs` |
| Quick run command | `mix test --no-start test/scoria/ci_policy_contract_test.exs` |
| Full suite command | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CACHE-01 (structural) | COPY order is lock → config → lib | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) |
| CACHE-01 (marker) | Boundary invariant comment present | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) |
| CACHE-01 (empirical) | No deps.get on CSS/HEEx touch | manual (local Docker) | `docker compose build --progress=plain web 2>&1 | grep -nE 'mix deps\.get'` | N/A (one-time, record in SUMMARY) |

### Sampling Rate

- **Per task commit:** `mix test --no-start test/scoria/ci_policy_contract_test.exs`
- **Per wave merge:** `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- **Phase gate:** Full suite + empirical proof recorded in SUMMARY

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. No new file, framework install, or shared fixture needed.

---

## Security Domain

No security-sensitive changes in this phase (no auth, no secrets, no network endpoints, no input validation). ASVS categories V2/V3/V4/V5/V6 do not apply. `security_enforcement` is not explicitly `false` in config.json, but this phase is purely documentation + a static file-read test.

---

## Open Questions (RESOLVED)

1. **Invariant comment: replace or prepend above the `# 3)` comment?**
   - What we know: L51 is `# 3) Volatile source last — editing these does NOT invalidate the layers above.`
   - What's unclear: D-10 says "immediately above `COPY lib lib`" — this could mean replacing the `# 3)` comment or prepending above it.
   - Recommendation: PREPEND above `# 3)` (keep both). The `# 3)` comment is cited as "step 3" in the table. Removing it would make the table's "step 3" label dangle. This is Claude's Discretion per CONTEXT.md.

2. **Should the proof record both `--progress=plain` output AND `up --build` behavior?**
   - What we know: D-05 is authoritative for the proof mechanics; D-04 says no standing harness.
   - What's unclear: Whether the SUMMARY should note that `up --build` shows no deps activity (the success criterion's command).
   - Recommendation: Record the `--progress=plain` grep as the primary evidence; add a one-line note that `docker compose up --build` shows no deps activity (collapsed by `--progress=auto`). This satisfies criterion 1 and is within Claude's Discretion.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | With BuildKit v0.34.0 and Docker 29.5.2, `--progress=plain` emits `CACHED` for cached steps in a format greppable as described | BuildKit Proof Mechanics | Proof command may need a different grep pattern; adjust based on actual output |

**All other claims in this research were verified directly against the live codebase files.** The only assumed claim (A1) is about runtime Docker output format, which can only be confirmed by running the proof locally.

---

## Sources

### Primary (HIGH confidence)

- `Dockerfile.dev` — full file read; line numbers, COPY strings, layer order verified [VERIFIED]
- `test/scoria/ci_policy_contract_test.exs` — full file read; `index_of/2` helper, module attributes, insertion point, `async: true`, no `describe` blocks [VERIFIED]
- `.github/workflows/ci-verify.yml` — policy lane command at L56 verified [VERIFIED]
- `docs/docker_dev_dx.md` — §"No rebuild" section structure, Cold builds bullet at L85-87, insertion point at L87/L89 boundary [VERIFIED]
- `compose.yml` — `web` service name, bind mount, named volumes confirmed [VERIFIED]
- `.dockerignore` — `assets/` not excluded, `priv/static/scoria/` excluded [VERIFIED]
- `.planning/config.json` — no `nyquist_validation: false` key [VERIFIED]
- `.planning/REQUIREMENTS.md` — CACHE-01 definition [VERIFIED]
- `.planning/ROADMAP.md` — Phase 34 criteria confirmed no Dockerfile layer order [VERIFIED]
- `.planning/PROJECT.md` — `closeout_order/0` byte-stable constraint, policy-lane-only new tests [VERIFIED]
- Python simulation of `:binary.match` ordering on Dockerfile.dev content — all D-09 assertions pass [VERIFIED]

### Secondary (MEDIUM confidence)

- Docker 29.5.2 + BuildKit v0.34.0 `--progress=plain` output format (A1) [ASSUMED — runtime behavior]

---

## Metadata

**Confidence breakdown:**
- D-01 line numbers: HIGH — directly verified from file
- D-02/D-03 CSS/HEEx facts: HIGH — filesystem verified
- D-09 static test assertions: HIGH — Python simulation + direct substring counts
- D-05 proof mechanics: HIGH (with caveat A1 on BuildKit output format)
- D-10 marker distinctness: HIGH — grepped for "INVARIANT" in Dockerfile.dev (not present)
- D-06 insertion point: HIGH — exact line numbers verified

**Research date:** 2026-06-18
**Valid until:** Stable (no external dependencies; all claims are against committed files in the repo)
