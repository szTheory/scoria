# Phase 31: Dockerfile caching audit + doc - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Empirically prove that `Dockerfile.dev`'s layer order prevents a Mix dependency refetch (and a full app recompile) on a CSS/HEEx-only edit, then lock that guarantee against silent regression with three coherent, non-overlapping guards: an **invariant comment** at the COPY boundary (humans), a **layer-invalidation table** in `docs/docker_dev_dx.md` (the mental model), and a **static COPY-order test** folded into the existing policy lane (machines). The empirical proof is recorded once in the phase record + documented as a repeatable command.

**Out of scope (belongs to other phases / deferred):**
- The `docs/docker_dev_dx.md` reader-empathy rewrite and correcting `localhost:4000` copy across `docs/`/`priv/dev/e2e`/`.planning/` — DOCS reqs, **Phase 33**.
- The `docker_dx_doc_contract_test.exs` doc-STRING contract test + `post-publish-smoke.yml` ephemeral-port scan extension — **Phase 34** (Docker DX drift guard). Phase 34's stated criteria do **not** cover Dockerfile layer order — that gap is closed here (see D-09).
- Secrets/rotation (Phase 32), maintenance release (Phase 35).
- No Dockerfile **reordering** unless the empirical audit proves the current order is wrong (it is not — see D-01). This phase documents + guards the existing correct order; it does not redesign the image.
- Sibling-repo migration is out of scope for the whole milestone.
</domain>

<decisions>
## Implementation Decisions

Calibration: user profile is `opinionated` / `minimal_decisive`. The user asked for deep, subagent-backed research on three gray areas (proof permanence, table accuracy, regression guard) and a one-shot coherent recommendation set. Three parallel `gsd-advisor-researcher` agents researched these against Docker BuildKit best practice, the Elixir/Phoenix ecosystem, and the project's Operator-First DX DNA; their recommendations interlock as **prove (A) → comment + table (B) → static test (C)** — three cheap guards over one invariant, with zero standing Docker builds and zero CI-topology change. Decisions below are LOCKED.

### Audit finding (the ground truth all three decisions build on)
- **D-01:** The current `Dockerfile.dev` layer order is **already correct** and cache-optimal: `COPY mix.exs mix.lock` → `mix deps.get` (L40–42) → `COPY config config` → `mix deps.compile` (L46–49) → `COPY lib`/`dev`/`priv` → `mix compile` (L52–56), with the apt/system layer above all of them. This phase **documents and guards** this order; it does not change it.
- **D-02:** **CSS edits invalidate ZERO image layers.** CSS source lives in `assets/css/*.css` (7 numbered files `00-fonts`..`06-utilities`) and `assets/` is **never `COPY`'d** into the image — it is bind-mounted at runtime and built in-container into `priv/static/scoria/` (which is `.dockerignore`'d). A HEEx edit (only 2 files, under `lib/scoria_web/components/layouts/`) invalidates `COPY lib lib` → incremental `mix compile` (app only), never the deps layers. ⇒ The roadmap's mandated row "CSS/HEEx-only edit → app compile only" **conflates two behaviors**: CSS = nothing rebuilds; HEEx = app compile only. The deliverables must tell this honestly (drift-resistance / honesty DNA from Phases 29–30).
- **D-03 (fact for the executor):** The roadmap's literal path `assets/css/app.css` **does not exist**. The empirical proof and any examples must edit a **real** CSS file (e.g. `assets/css/06-utilities.css`).

### Gray Area A — empirical proof permanence (success criterion 1)
- **D-04:** Ship a **documented, repeatable command + a one-time recorded snapshot in SUMMARY**. Do **NOT** build a `make cache-audit` target — a Make target that shells a real `docker compose build` is heavy (minutes/run), brittle (BuildKit progress format + grep string), and a footgun if it ever leaks into CI (per-runner cache makes build-cache assertions non-deterministic). A dev-only image's cache behavior is guarded by structure + docs + the static test (C), not a standing build harness.
- **D-05:** Proof mechanics (record the verdict in SUMMARY as the empirical evidence):
  ```bash
  docker compose build web                         # warm the cache once
  touch assets/css/06-utilities.css \
        lib/scoria_web/components/layouts/root.html.heex
  docker compose build --progress=plain web 2>&1 | tee /tmp/scoria-cacheproof.log
  grep -nE 'mix deps\.get' /tmp/scoria-cacheproof.log
  ```
  **Pass = the `mix deps.get` step appears only as a `CACHED` step** (BuildKit prints `CACHED ... RUN ... mix deps.get`), never as an executing step with download output. Paste the grepped line(s) + the `CACHED` markers for the deps.get/deps.compile steps into SUMMARY. Note for the planner: `docker compose up --build` (the criterion's user-facing command) uses `--progress=auto`, which collapses cached steps — use `docker compose build --progress=plain` for the *proof*; `up --build` will simply show no deps.get activity. Prove **both** edit classes (CSS → no layer; HEEx → app compile only) so the table rows (D-06) are cited.

### Gray Area B — layer-invalidation table accuracy (success criterion 3)
- **D-06:** Ship the **accurate, COPY-boundary-correct table** (not the roadmap-literal-but-wrong 3 rows), preceded by a one-line **bind-mount-vs-cold-build framing**, appended to the END of the existing §"No rebuild on source/style edits" section in `docs/docker_dev_dx.md` (the natural home — it already establishes the bind-mount reality and ends with the "Cold builds" BuildKit bullet). It still **literally satisfies** criterion 3's three mandated rows ("at minimum"). Recommended markdown (the planner may refine wording, must keep the load-bearing strings in D-08):
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
- **D-07:** Do **not** add a standalone apt/system table row — fold the apt/base layer into the framing sentence (it is not a layer a contributor edits day-to-day). Keep the table scoped to what a contributor actually changes.

### Gray Area C — static layer-order regression guard (closes the "cannot regress silently" goal mechanically)
- **D-08:** Add the order guard **NOW**, **appended to the existing `test/scoria/ci_policy_contract_test.exs`** — do **NOT** create a new test file. Verified: that file is `async: true`, uses the `File.read!`-of-repo-files idiom, and already runs in the **policy lane** (`.github/workflows/ci-verify.yml:56`: `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs ...` — no Postgres, no app start). Appending content there means **zero new file, zero CI-YAML edit, no DB, no app boot** — honoring PROJECT.md's "new tests run in the existing policy lane only; no CI topology changes; `VerificationLanes.closeout_order/0` byte-stable" (closeout_order is untouched — this adds test *content*, not a lane).
- **D-09:** Assertion strategy — robust **relative `index-of` on stable substrings**, never exact-line/whitespace matches:
  ```elixir
  test "Dockerfile.dev keeps cache-optimal COPY layer order (deps -> config -> source)" do
    df = File.read!("Dockerfile.dev")
    i_lock   = index_of!(df, "COPY mix.exs mix.lock")
    i_config = index_of!(df, "COPY config")
    i_lib    = index_of!(df, "COPY lib")
    assert i_lock < i_config   # deps.get layer before deps.compile (config)
    assert i_config < i_lib    # compile-time config before volatile source
    assert df =~ @layer_invariant_marker  # couple the human comment to the machine guard
  end
  # index_of! raises a clear message if a substring is absent, so a renamed/removed
  # COPY fails loud rather than passing vacuously.
  ```
  Use `:binary.match`/`String.split` index logic (tolerant of comments, blank lines, added `COPY dev`/`COPY priv`). This guard is **complementary, not redundant**, to D-04's empirical proof: D-04 proves *runtime behavior* once (heavy, manual/local, real Docker build); D-08 proves the *structural precondition* on every `mix test` (fast, deterministic, no daemon). State this explicitly so a reviewer doesn't try to collapse them.

### Gray Area C cont. — invariant comment (success criterion 2)
- **D-10:** Add an explicit invariant comment **at the COPY/RUN boundary** (immediately above `COPY lib lib`, ~L51–52) — criterion 2 requires the comment *at the boundary*; today's ordering rationale lives only in the top-of-file header (L6–11). The boundary comment carries a **stable marker the test (D-09) pins**, so the human comment and machine guard can't silently diverge. Suggested:
  ```dockerfile
  # INVARIANT: volatile source (lib/dev/priv) MUST stay below deps.get + deps.compile.
  # Reordering re-fetches/recompiles deps on every source edit. Layer order is deliberate
  # — see docs/docker_dev_dx.md (layer-invalidation table). Guarded by
  # test/scoria/ci_policy_contract_test.exs.
  ```
  Set the test's `@layer_invariant_marker` to a distinct boundary string (e.g. `"INVARIANT: volatile source"`) so the assertion truly pins the *boundary* comment, not merely the pre-existing header phrase `"Layer order is deliberate"` at L7.

### Claude's Discretion
- Exact wording/format of the SUMMARY evidence block, the table cell prose (keep D-08's load-bearing strings: `mix deps.get`, `mix deps.compile`, `mix compile`, `app compile only`, `assets/`, `mix.exs`, `mix.lock`), the invariant-comment phrasing, and the `index_of!` helper implementation.
- Whether to also add a one-line cross-link from the Dockerfile header comment (L6–11) to the new table.
- Whether to record the proof for `up --build` (criterion's literal command) in addition to the `build --progress=plain` proof, or just cite the latter as the authoritative evidence.

### Phase 34 hand-off (record, do not build here)
- **D-11:** Phase 34's `docker_dx_doc_contract_test.exs` should assert the table's three load-bearing strings survive in `docs/docker_dev_dx.md` — recommend it check presence of `mix deps.get`, `mix deps.compile`, and `app compile only`. (Phase 34 guards the *doc strings*; D-08 guards the *Dockerfile order*; no overlap.) Flag for the Phase 34 planner: Dockerfile layer-order was absent from every phase's stated criteria until this phase closed it via D-08 — if D-08 were ever dropped, Phase 34's criteria must absorb a Dockerfile-order assertion.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 31: Dockerfile caching audit + doc" — goal + 3 success criteria (the verification bar).
- `.planning/REQUIREMENTS.md` — **CACHE-01** (the single locked requirement: CSS/HEEx-only edit triggers no Mix dep refetch and no full app recompile — empirically verified + documented as a layer-invalidation table + a layer-order invariant comment in `Dockerfile.dev`).
- `.planning/PROJECT.md` §"Current Milestone: v3.2 Drydock" — milestone goal + "Docker dev-DX hardening (Scoria-only)" target features; locked constraint: new tests run in the existing **policy lane only**, no CI topology changes, `closeout_order/0` byte-stable.
- `.planning/ROADMAP.md` §"Phase 34: Docker DX drift guard + CI guard extension" — read to confirm the doc-string contract test + port-scan are Phase 34, and that Dockerfile layer order is NOT in Phase 34's criteria (the gap D-08 closes).

### Carried-forward DNA (Phases 29–30 — MUST honor)
- `.planning/phases/29-makefile-hardening/29-CONTEXT.md` — drift-resistance via dynamic enumeration; honesty about real cost ("`nuke` honest about the cold-recompile cost"); `## name: desc` help convention; container listens on `:4000`, native policy `4799`.
- `.planning/phases/30-launch-banner-native-dev-notice/30-CONTEXT.md` — "the current static list already drifted" precedent (derive/be-accurate over curate); Phase 30 explicitly deferred its parity contract test to Phase 34 (precedent for where guards live — note D-08 deliberately lands a guard *earlier* to close a gap Phase 34 doesn't cover).

### Files this phase edits
- `Dockerfile.dev` — add the boundary invariant comment (D-10) above `COPY lib lib` (~L51–52). Order itself is unchanged (D-01).
- `docs/docker_dev_dx.md` — append the layer-invalidation table + bind-mount framing to the END of §"No rebuild on source/style edits" (after the "Cold builds" bullet, ~L85–87) (D-06/D-07).
- `test/scoria/ci_policy_contract_test.exs` — append the static COPY-order + marker test (D-08/D-09). No new file.
- Phase SUMMARY — record the empirical proof verdict (D-04/D-05).

### Files this phase reads but does NOT change
- `compose.yml` — the `web` service `build:` + `.:/app` bind mount + named `deps`/`build` volumes (the day-to-day "no rebuild" reality the table's framing describes).
- `.dockerignore` — confirms `assets/` is in the build context but `priv/static/scoria/`, `_build/`, `deps/` are excluded (why a CSS edit invalidates nothing).
- `.github/workflows/ci-verify.yml` (~L16, L56) — confirms the policy lane runs `ci_policy_contract_test.exs` with `--no-start`, no Postgres. Reference only — do NOT edit (editing it would be a topology touch).

### DX philosophy
- `prompts/sztheory-elixir-dna.md` — Operator-First DX / least-surprise compass behind "document + structure + cheap static guard, not a standing build harness".
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scoria/ci_policy_contract_test.exs` — `async: true`, `File.read!`-of-repo-files contract-test idiom already established (asserts strings in CI YAML / docs). The new COPY-order test (D-08) is one more `test` block in the same `describe`-free module; reuse the module's existing `@const "path"` + `File.read!` pattern.
- `Dockerfile.dev:6–11` — existing top-of-file ordering rationale comment; the boundary comment (D-10) is a focused, marker-bearing complement, not a duplicate.
- `docs/docker_dev_dx.md` §"No rebuild on source/style edits" (L69–87) — already explains bind-mount + named volumes + BuildKit cache mounts; the table is the precise expansion of its final "Cold builds" bullet.

### Established Patterns
- **Policy lane = no DB, no app start, `--no-start`, `File.read!` on repo files** — the COPY-order guard fits this exactly (millisecond, deterministic, daemon-free).
- **Drift-resistance / honesty over curation** (Phases 29–30): the table tells the CSS-rebuilds-nothing truth rather than restating the roadmap's convenient-but-wrong row.
- **BuildKit cache mounts** already in `Dockerfile.dev` (apt cache, `/root/.hex`, rebar3 cache) — orthogonal to layer order; mention in framing only if it aids the reader.

### Integration Points
- Empirical proof (D-04/D-05) → human runs `docker compose build --progress=plain` locally → verdict recorded in SUMMARY.
- Static guard (D-08) → runs in the existing CI policy lane on every `mix test` and `mix ci`.
- Table + invariant comment (D-06/D-10) → read by future contributors; pinned downstream by Phase 34's doc-string test (D-11).

### Verification note (shift-left to automation)
- The static COPY-order test (D-08) is the automated, repeatable guarantee — preferred over a manual UAT checklist. The one-time empirical `docker compose build` proof (D-04) is the human-run evidence for criterion 1 that the static test cannot replicate (it needs a real Docker daemon); keep it as a documented, re-runnable command, not a manual-only ritual.
</code_context>

<specifics>
## Specific Ideas

- Proof command shape the research endorsed: `docker compose build --progress=plain web 2>&1 | grep -nE 'mix deps\.get'` after `touch`-ing a real CSS file + a HEEx file; pass = `mix deps.get` shows only as `CACHED`.
- Table shape the research endorsed: 4 rows (CSS→none, HEEx/lib→app compile only, config→deps.compile+compile, mix.exs/lock→full rebuild) + a bind-mount-vs-cold-build framing sentence; apt layer folded into prose, not a row.
- Guard shape the research endorsed: relative `index_of!` substring-order assertions appended to `ci_policy_contract_test.exs` + an `@layer_invariant_marker` assertion coupling the Dockerfile boundary comment to the test.
</specifics>

<deferred>
## Deferred Ideas

- **`make cache-audit` target** (re-runnable docker-build cache check) — considered and rejected (D-04): heavy, brittle, CI-flake footgun for a dev-only image; the static COPY-order test (D-08) provides the repeatable machine guard at zero Docker cost.
- **Standalone apt/system layer table row** — folded into the framing sentence instead (D-07); a layer contributors don't edit day-to-day.
- **Phase 34 asserting the table's strings** — recorded as a hand-off (D-11), built in Phase 34, not here.

### Reviewed Todos (not folded)
- `docker-dx-fleet-hardening.md` (matched on keywords docker/dev/lib) — **out of scope**: sibling-repo fleet convergence is FLEET-01, explicitly deferred for the whole v3.2 milestone (Scoria is the reference impl + portable docs only). Not Phase 31.
- `ci-policy-job-cache-key-mislabel.md` (matched on keywords mix/cache) — **out of scope**: a CI `MIX_ENV` cache-key labeling cleanup carried from v3.1 close, unrelated to Dockerfile image-layer caching. Post-ship cleanup, not Phase 31.

</deferred>

---

*Phase: 31-dockerfile-caching-audit-doc*
*Context gathered: 2026-06-18*
</content>
</invoke>
