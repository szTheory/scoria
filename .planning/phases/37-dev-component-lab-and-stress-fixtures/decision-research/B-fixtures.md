# Phase 37 Decision Research B: Fixture Ownership & Domain Language (D-16..D-21)

**Scope:** D-16 (fixture catalog shape/owner), **D-17 spotlight** (dev_seed.exs vs lab fixtures boundary), D-18 (inventory as coverage anchor, not generator), D-19 (required domains), D-20 (domain-noun scenario naming), D-21 (fixtures-as-evidence, runtime isolation).
**Method:** Read `37-CONTEXT.md`, `37-RESEARCH.md`, `37-PATTERNS.md`, `37-UI-SPEC.md`, `lib/scoria/support_journey.ex` + `handlers.ex`, `priv/repo/dev_seed.exs` (1288 lines), `lib/scoria_web/ui.ex` (1477 lines), `lib/scoria_web/approval_copy.ex`, `lib/scoria_web/components/approval_inbox_component.ex`, `test/support/`, `mix.exs`, `config/dev.exs`, `prompts/phoenix-ai-lib-deep-research.md`, `.planning/phases/36-baseline-and-inventory/36-inventory.json`, `.planning/REQUIREMENTS.md`. Web research on ExMachina, Ecto testing docs, Rails fixtures vs FactoryBot, Storybook args/mocking, PhoenixStorybook variations, golden-file testing, and Fowler's nondeterminism taxonomy (sources cited inline).

---

## 1. Decision pressure-test

### D-17 spotlight: is `dev_seed.exs` really disqualified as the fixture source?

**Verdict: D-17 is correct, and the codebase itself proves it — this isn't a stylistic preference, it's a hard determinism failure.**

Evidence from `priv/repo/dev_seed.exs`:

- Line 1288's header states runs are "naturally additive" and approvals are inserted via real `Scoria.start_run/2` + `mark_waiting_for_approval` calls (lines 82-96). The comment literally says: *"Each approval has a real UUID so the Approvals overlay can open its detail modal."* That UUID is DB-generated at insert time — a fresh value on every `mix run priv/repo/dev_seed.exs` execution and every DB reset.
- `inserted_at` timestamps on those rows come from `NaiveDateTime.utc_now()` at Ecto insert time, not a literal.
- Re-running the script is explicitly *not* idempotent for runs/approvals ("Workflow runs are naturally additive... re-running adds runs but never crashes") — the row count and row set both grow across runs.

This means anything sourced from `dev_seed.exs` fails on **three** independent axes at once: (1) unstable identity (UUID), (2) unstable time (`utc_now()`), (3) unstable cardinality (additive, not reset-free). Per Fowler's "Eradicating Non-Determinism in Tests," the standard remedies are "always wrap the system clock" and prefer "rebuild initial state from scratch" over relying on cleanup — `dev_seed.exs` does neither, because it isn't trying to: its job is to produce a *believable running dashboard* for screenshot/click-through proof, not a byte-stable fixture set. `[CITED: martinfowler.com/articles/nonDeterminism.html]`

D-17's framing — "DB-backed projection for real LiveView page screenshots and click-through proof, NOT the source of every component state" — draws exactly the right line. The two systems have different jobs:

| | `dev_seed.exs` | Component Lab fixtures |
|---|---|---|
| Identity | DB-generated UUIDs | literal strings (`"appr-refund-duplicate-charge"`) |
| Time | `utc_now()` at insert | literal ISO8601 strings or fixed `~N[...]` |
| Cardinality | additive, grows | fixed list length per scenario |
| Reset | requires DB / `mix scoria.dev_db` | none — pure function call |
| Purpose | prove the *real* LiveView pages work against real Ecto/PubSub | prove every *primitive/group* renders correctly across state×domain combinations the seeded DB may never produce (e.g. a `dataset_empty` or `connector_scope_blocked` row the seed script doesn't happen to create) |

The one nuance worth flagging: **D-17 doesn't forbid reuse of `SupportJourney`'s realistic constants** (`tenant_id/0`, `connector_key/0`, `connector_label/0` — pure zero-arg functions returning literal strings). Those are already deterministic and already the "shared domain vocabulary" the CONTEXT.md code-context section points at. Reusing the *scalar identity constants* is good (continuity, avoids inventing a second tenant/connector name); reusing `SupportJourney.ticket_fixture()`/`persona_fixture()` (which read+decode `priv/fixtures/support_journey/*.json`) as the *lab's* bulk-payload mechanism is riskier — see Footgun 2 below — because that JSON is a different module's contract (adopter-facing gallery + doc-fragment drift guards), not the lab's.

### D-16: structs vs bare maps vs JSON files

**Verdict: plain maps for scenario payloads, JSON files only for genuinely bulky/dense data, structs are the wrong tool here — reject them.**

The deciding evidence is `lib/scoria_web/approval_copy.ex:239-241`:

```elixir
def field(approval, field) do
  Map.get(approval, field) || Map.get(approval, Atom.to_string(field))
end
```

Every copy-helper (`ApprovalCopy`, and by the same pattern the other `*_evidence_component.ex`/`*_drawer_component.ex` modules) reads fixture-shaped data through `Map.get/2` duck-typing, not struct pattern-matching or `Ecto.Schema` field access. This has two direct consequences for D-16:

1. **Structs buy nothing and cost something.** A struct forces a fixed field set decided at compile time. But D-19's "ugly and realistic values" requirement needs the *opposite* — fixtures for an `error` or `empty` state legitimately want to **omit** keys (`nil` policy name, missing `arguments_preview`, absent `baseline_target`) to prove the copy-helpers and primitives degrade gracefully. `Map.get/2` returns `nil` for a missing key; a `defstruct` either silently defaults that field (masking the "missing field" case you're trying to test) or requires the struct to declare every optional field as `nil`-able up front — busywork that a plain map gets for free.
2. **Maps double as direct evidence.** D-27/D-29 want a `raw_evidence`/`notebook` disclosure showing "fixture source" and raw payload; `Jason.encode!/1` or `inspect/1` on a plain map is immediately presentable, no `Map.from_struct/1` conversion step, no struct-name leakage into evidence copy (D-28 explicitly wants Ecto/internal names hidden from the primary view).

JSON files (the optional half of D-16) are for **volume**, not for **type safety** — mirror `SupportJourney.ticket_fixture/0` exactly (`File.read!/1` + `Jason.decode!/1` against a `priv/…` path), but rooted at `priv/dev/lab_fixtures/*.json` (excluded from Hex), never `priv/fixtures/` (which **ships** — see Footgun 1). Use JSON for: a long/dense table's 30-40 row dataset for the `dense` state band, a large `raw_evidence`/trace-tree payload for `workflow_failed_step`/`eval_regression_detected`, or any fixture whose literal-Elixir-map form would make `fixtures.ex` unreadable. Everything else — the 13 named D-20 scenarios' primary payload — should be inline Elixir maps: they're small, they benefit from being greppable/diffable in a `.ex` file, and Elixir syntax highlighting reads better than JSON for anyone scanning the module.

### D-16: single fixtures module vs per-domain modules

**Verdict: one public facade module, splitting into private per-domain modules only past a size threshold — don't pre-split.**

`lib/scoria_web/ui.ex` is 1477 lines and stayed a single module because it's one *cohesive vocabulary* (primitives). Fixture data is different: it's inherently partitioned by domain noun (D-20), so a per-domain split (`DevLab.Fixtures.Approvals`, `.Incidents`, `.Reviews`, `.Datasets`, `.Workflows`, `.Connectors`, `.Prompts`, `.Evals`) is a natural seam, not an artificial one. But CONTEXT.md's "Claude's Discretion" note explicitly says *prefer... small modules... over a clever DSL* — the risk with pre-splitting into 8 domain modules on day one is indirection for a maintainer who just wants to add one ugly `connector_degraded` row: they'd need to know which of 8 files to open before they can even start (this directly works against the D-DX goal in section 4 below).

Recommended progression:
- **Phase 37 ships:** one `DevLab.Fixtures` module (`scenario/1`, `scenarios/0`, `states_for/2`, `domain/1`) with all 13 D-20 scenarios as literal `def scenario(:name), do: %{...}` clauses, plus JSON-backed helpers for the 2-3 genuinely bulky payloads.
- **Split trigger:** if `dev/lab/fixtures.ex` crosses roughly 300-400 lines (matching the size discipline visible elsewhere in the repo — `ui.ex` primitives split into function-per-primitive, not folder-per-primitive, until it hit real size), extract domain groups into `dev/lab/fixtures/{approvals,incidents,...}.ex` with `DevLab.Fixtures` becoming a thin `defdelegate`/dispatch facade. This keeps the *public API* (`DevLab.Fixtures.scenario/1`) stable regardless of internal file layout — nothing outside `dev/lab/` should ever need to know whether it's one file or eight.

### D-16/D-17 combined footgun the locked decisions don't fully name: decouple "domain scenario" from "render state"

The 13 D-20 names and the 10 D-11 states are two independent axes, not a 13×10 matrix to hand-author. A naive reading of D-19/D-20 risks "factory explosion" (ExMachina's own documented pitfall, see §2) if someone tries to write 130 distinct fixture literals. The correct shape:

- `scenario/1` returns **one realistic single-record domain payload** per D-20 name (what the data is *about*).
- `states_for/2` (or `states_for(component_key, base_scenario)`) **derives** the 10 state-band variants generically: `empty` → `[]`, `dense` → `List.duplicate/generate N varied rows from 2-3 base scenarios`, `loading` → the same payload plus a `loading: true` flag consumed only by the state-band renderer (never by `ScoriaWeb.UI` primitives themselves), `long_text` → the base scenario with one field swapped for a long-string constant, `disabled`/`selected` → row-level UI flags, not domain-truth changes.
- This is exactly the lesson Storybook's "args" composition and PhoenixStorybook's variation-group model both encode: state/variation is a *rendering* concern layered onto a *data* concern, not baked into the data. `[CITED: storybook.js.org/docs/writing-stories/args]` `[CITED: phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html]`

### D-18: inventory as coverage anchor, not generator

Confirmed correct and low-risk. `36-inventory.json` rows (`required_row_fields: id, name, layer, status, owner_path, evidence, replacement_or_owner, next_action, risk_refs`) contain **zero** domain-payload fields — there is nothing in the inventory schema that could generate a realistic `approval_requested` payload even if someone tried. The only real risk is the inverse temptation: a lab section author treats an inventory row's `next_action`/`evidence` text as if it were fixture content. It isn't — inventory rows are metadata about *components*, fixtures are metadata about *domain events*. Keep the citation (`PRIM-TABLE`, `GROUP-APPROVAL-INBOX-COMPONENT`) as a separate `data-inventory-id` attribute on the state-band wrapper (already the RESEARCH.md Pattern 3 design), never merged into the fixture map itself.

### D-19/D-20: are the 13 named scenarios actually 8 domains, and does the naming hold up?

Counting D-20's example list: `approval_requested`, `approval_denied` (approvals); `incident_opened`, `incident_escalated` (incidents); `review_candidate_flagged` (reviews); `dataset_promoted`, `dataset_empty` (datasets); `workflow_waiting_for_approval`, `workflow_failed_step` (workflow detail); `connector_degraded`, `connector_scope_blocked` (connectors); `prompt_release_blocked` (prompts); `eval_regression_detected` (evals) — **8 domain nouns, 13 scenarios**, with "empty/error paths" (the 9th item in D-19's domain list) folded into scenario names themselves (`dataset_empty`) rather than existing as a 9th noun-domain. That's the right call: "empty" and "error" are D-11 *states*, and D-19 listing them alongside domain nouns is really saying "make sure some domains explicitly demonstrate the empty/error state as a named scenario, not just as a generic band," which `dataset_empty` already satisfies. Recommend the fixture catalog also add one more explicit error-domain example beyond `dataset_empty` — e.g. `workflow_failed_step` already covers workflow-error, but reviews/prompts have no named error/empty scenario in the D-20 list. This is a coverage gap worth closing in planning (not a locked-decision violation — D-19 says "empty/error paths" for **all** listed domains, D-20's example list is illustrative, not exhaustive, per its own "instead of" framing). Concretely add at minimum one more: `review_queue_empty` or `prompt_registry_empty` so every D-19 domain has both a "normal" and an "empty-or-error" named example, not just datasets/workflow.

Naming quality check against `prompts/phoenix-ai-lib-deep-research.md`'s domain model (§5, "Domain model: nouns, verbs, events" — trace/run/workflow, tool/approval, dataset/eval, prompt/version): the D-20 names already match that vocabulary (`approval_requested`, `eval_regression_detected` mirror the research doc's own telemetry-event naming convention, e.g. `[:my_ai, :tool, :call, :approval_requested]` at line 362). No drift found — D-20 is internally consistent with the product's own domain-language research.

### D-21: fixtures are evidence, not truth — is the isolation actually structurally enforced?

**Partially — and the gap matters.** `mix.exs` sets:

```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(:dev), do: ["lib", "dev"]
defp elixirc_paths(_), do: ["lib"]
```

Under `:test` and `:prod`/default (which is what an adopter's host app uses when compiling Scoria as a dependency), `dev/` is absent — a `lib/` module referencing `DevLab.Fixtures` is a hard compile failure there. **But under `:dev`, `lib/` and `dev/` compile together in the same BEAM namespace.** Nothing stops a `lib/scoria_web/live/some_live.ex` module from calling `DevLab.Fixtures.scenario(:approval_requested)` and compiling *successfully* under the maintainer's own local `mix phx.server` (which runs `:dev` by default). It would only fail later — at `mix test` time, or worse, silently at runtime for an adopter who never even sees a compile error (the reference is inside a function body; Elixir doesn't eagerly resolve those, and this repo shows no evidence of a Dialyzer gate in the read files) — the adopter just gets an `UndefinedFunctionError` crash the first time that code path executes in production.

This means: **the `elixirc_paths` split is necessary but not sufficient. The text-scan guard test is not defense-in-depth — it is the only mechanism that closes this gap**, because it's the only check that runs in an environment (`mix test`, gated in CI per `docs/MAINTAINERS.md`'s CI-lane map) where the violation is both (a) present in source and (b) actually checked. Elevate this from "add a guard test" to "the guard test is the D-21 enforcement mechanism, full stop" in the plan.

The second half of D-21 — "fixture defaults must not become hidden business rules" — has **no mechanical verification available**. It's a semantic/judgment property (e.g., is `dataset_baseline_promotion`'s fixture `dataset_version: "v3"` accidentally becoming a magic default because some future refactor copy-pasted it into a `lib/` config default?). No regex catches "this value is suspiciously reused as if it were canonical." Be honest about this in planning: it's a code-review checklist item, not a CI gate (see §5).

---

## 2. Ecosystem lessons table

| Approach | What it got right (adopt) | Documented footgun (avoid) | Citation |
|---|---|---|---|
| **ExMachina** (factories, `build`/`insert`, `sequence`) | Lazy/deferred evaluation (`fn -> build(:user) end`) prevents shared-instance bugs when the same base data is reused across many rows — apply this to `states_for/2`'s `dense` band (generate N varied rows via a function, not N copies of one literal map) | "Factory Overuse in Definitions" and "Splitting Complexity" — factories calling other factories/`insert/2` inside factory bodies creates coupling and unnecessary writes; large factories fragment across modules with maintenance overhead | `ex-machina.hexdocs.pm/readme.html` |
| **Rails fixtures (YAML)** | Fast, simple, globally addressable by name, zero framework overhead — same shape Scoria's `scenario(:name)` API should have | "Fixtures introduce global state... unintended interactions between tests" and struggle to represent complex/polymorphic relationships in flat YAML/CSV | `masilotti.com/rails-test-fixtures`, `harled.ca/blog/the_battle_of_factories_vs_fixtures_when_using_rspec` |
| **FactoryBot** | Dynamic, flexible, override-per-call, build-without-persist | "Over time, factories can grow complex, especially with nested attributes and callbacks" — the direct analogue of the 13×10 matrix explosion risk in §1 | `harled.ca/blog/the_battle_of_factories_vs_fixtures_when_using_rspec` |
| **Storybook `args`** | Plain-object example data, colocated with the story, one-line new-example via object spread + override — this *is* the DX bar for "add one ugly scenario" (§4) | Storybook's own docs on args don't address schema drift between mock args and real component prop types (no compile-time check) | `storybook.js.org/docs/writing-stories/args` |
| **Storybook network mocking (MSW)** | Cleanly separates "mock the boundary" (network layer) from the component under test | Docs explicitly stop short of addressing mock-data-drifts-from-real-schema or mocks-leaking-into-production — confirmed gap, not just an omission I inferred | `storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests` |
| **PhoenixStorybook `Variation`/`VariationGroup`** | Attrs are checked against the real component's declared `attr` types at **compile time** — "Variations attributes type are checked against their matching attribute... will raise a compilation error in case of mismatch." This is the single strongest anti-drift mechanism in any surveyed tool | Requires the macro/DSL Scoria's D-04 explicitly rejects; the type-checking benefit doesn't transfer for free — Scoria's plain function-component approach must get the equivalent protection by **always calling the real `ScoriaWeb.UI`/`components/*.ex` function** with fixture data as `attrs`, so Phoenix's own `attr`/`slot` compile-time validation (which already exists on every `ScoriaWeb.UI` primitive) does the same job PhoenixStorybook's macro does — never hand-roll HEEx that bypasses the real component call | `phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html` |
| **Ecto `testing-with-ecto` / sandbox boundary** | Explicit, single-purpose boundary module (`RepoCase`) that owns all DB-connection lifecycle, keeping "how test data gets a connection" separate from "what the data is" | The official docs are silent on non-DB deterministic fixtures entirely — confirms there's no Ecto-native answer to D-17's problem; Scoria is right to solve it outside Ecto's testing story, not by contorting Sandbox mode for a DB-free lab | `ecto.hexdocs.pm/testing-with-ecto.html` |
| **Golden-file / snapshot testing** | Store fixture provenance metadata alongside golden output (version, config, timestamp) so a diff is diagnosable; rebuild from scratch rather than incrementally patch | Nondeterministic inputs (time, randomness, ordering) silently invalidate goldens — exactly the `dev_seed.exs` failure mode in §1 | search results incl. Flutter/Go golden-test guides |
| **Fowler, "Eradicating Non-Determinism in Tests"** | "Always wrap the system clock, so it can be easily substituted"; prefer rebuilding initial state over cleanup-between-runs | Bare calls to `DateTime.utc_now()`/random/UUID-gen inside what's supposed to be deterministic setup are the #1 concrete failure mode — directly maps to Footgun 3 below | `martinfowler.com/articles/nonDeterminism.html` |

---

## 3. Concrete recommendation: the fixture module

### Name

**`DevLab.Fixtures`**, not `ScoriaWeb.DevLabFixtures`. Both satisfy D-16's suggested names literally (CONTEXT.md delegates the exact name to downstream discretion), but `DevLab.*` is the better choice for a reason D-21 cares about directly: a module namespaced under `ScoriaWeb.*` sits visually inside the same namespace as every shipped runtime module in `lib/scoria_web/`, which is exactly the namespace a contributor's editor autocompletes from inside `lib/`. Naming it `DevLab.Fixtures` (matching sibling modules `DevLab.LabLive`, `DevLab.Sections.*` already chosen in RESEARCH.md/PATTERNS.md) makes any accidental `alias DevLab.Fixtures` inside a `lib/scoria_web/` file visually jarring in code review — a human-legible tripwire on top of the compiler/CI tripwire from §1.

### Public API surface

```elixir
defmodule DevLab.Fixtures do
  @moduledoc """
  Dev-only (:dev env; excluded from Hex — see mix.exs elixirc_paths/1 and
  package/0 files:). Deterministic, reset-free fixture catalog for the
  Component Lab (D-16/D-17). Every function here is a pure, side-effect-free
  read of literal Elixir data or a static priv/dev/ JSON file.

  NEVER reference this module from lib/ (D-21) — see
  test/scoria_web/dev_lab_boundary_test.exs, which is the actual enforcement
  mechanism for that rule (elixirc_paths(:dev) alone does not prevent it).
  """

  # --- Domain-noun scenarios (D-20) -----------------------------------------

  @scenario_names ~w(
    approval_requested approval_denied
    incident_opened incident_escalated
    review_candidate_flagged review_queue_empty
    dataset_promoted dataset_empty
    workflow_waiting_for_approval workflow_failed_step
    connector_degraded connector_scope_blocked
    prompt_release_blocked prompt_registry_empty
    eval_regression_detected
  )a

  @doc "All D-20 scenario names — used by the Fixtures section browser and by coverage checks."
  def scenarios, do: @scenario_names

  @doc "One realistic single-record domain payload for `name` (a plain map, duck-typed for the real copy-helper/component that will render it)."
  def scenario(name)
  def scenario(:approval_requested), do: %{...}
  def scenario(:approval_denied), do: %{...}
  # ... one clause per @scenario_names entry ...

  @doc "Groups scenario names by D-19 domain, for the Fixtures section's browse IA and domain-coverage checks."
  def domains, do: %{
    approvals: ~w(approval_requested approval_denied)a,
    incidents: ~w(incident_opened incident_escalated)a,
    reviews: ~w(review_candidate_flagged review_queue_empty)a,
    datasets: ~w(dataset_promoted dataset_empty)a,
    workflow: ~w(workflow_waiting_for_approval workflow_failed_step)a,
    connectors: ~w(connector_degraded connector_scope_blocked)a,
    prompts: ~w(prompt_release_blocked prompt_registry_empty)a,
    evals: ~w(eval_regression_detected)a
  }

  # --- D-11 state bands (derived, not hand-authored per cell) ---------------

  @doc """
  Returns [{state_atom, fixture}] for all 10 D-11 states, for `component_key`
  (e.g. :approval_inbox, :badge, :table). Composes over scenario/1 — does NOT
  hand-author 13x10 literals (avoids the ExMachina "factory explosion"
  footgun).
  """
  def states_for(component_key, base_scenario \\ nil)

  # --- Bulk/JSON-backed payloads (only where a literal map is unreadable) ---

  @lab_fixture_root Path.join(:code.priv_dir(:scoria), "dev/lab_fixtures")

  defp bulky_payload(file) do
    path = Path.join(@lab_fixture_root, file)
    # @external_resource makes mix recompile (and fail loudly) if the JSON
    # is hand-edited into an invalid/incomplete shape — catches drift at
    # `mix compile` under :dev, not silently at first LiveView render.
    File.read!(path) |> Jason.decode!()
  end
end
```

Note: `@external_resource` must be declared per literal file path (compile-time), so in practice the bulky-payload helper functions each declare their own `@external_resource Path.join(...)` above the `defp`, one per JSON file — sketched here as a single helper for brevity.

### Data shape

- **Plain maps**, atom keys as the primary key type (matching how `ApprovalCopy.field/2` checks atom first) with the string-key fallback available "for free" if a fixture ever needs to simulate raw un-atomized DB output.
- **No structs.** See §1 — `Map.get/2` duck-typing throughout the copy-helper layer means structs add rigidity without adding safety, and actively fight the "ugly/missing data" requirement (D-19).
- Fixture maps carry **domain-truth fields only** (status strings, ids, amounts, policy names) — never a `:tone` key. Visual tone is derived at render time by the *real* `ScoriaWeb.UI.tone/1` (for domain-status-driven components) or by the lab's own separate `state_tone/1` (for D-11 state-band chrome) — never baked into fixture data. This closes RESEARCH.md's Pitfall 4 at the data-modeling layer, not just the call-site layer.

### Where bulky payloads live

`priv/dev/lab_fixtures/*.json` — **never `priv/fixtures/`** (see Footgun 1). Loaded via `File.read!/1` + `Jason.decode!/1`, exactly mirroring `SupportJourney.ticket_fixture/0`'s proven pattern, with `@external_resource` added for compile-time drift detection (a small improvement `SupportJourney` itself doesn't currently have, worth suggesting as a follow-up there too, but out of scope for Phase 37).

### Domain-noun → 13(+2) scenarios → 10 states mapping

| D-19 domain | D-20 scenario(s) | Notes |
|---|---|---|
| approvals | `approval_requested`, `approval_denied` | feeds `ApprovalInboxComponent`/`RuntimeDetailDrawerComponent` |
| incidents | `incident_opened`, `incident_escalated` | feeds `IncidentEvidenceComponent` |
| reviews | `review_candidate_flagged`, `review_queue_empty` (add — see §1) | — |
| datasets | `dataset_promoted`, `dataset_empty` | `dataset_empty` already an explicit empty-state scenario |
| workflow detail | `workflow_waiting_for_approval`, `workflow_failed_step` | feeds `WorkflowTreeComponent`/`WorkflowDetailPanelComponent` |
| connectors | `connector_degraded`, `connector_scope_blocked` | feeds `ConnectorDetailDrawerComponent` |
| prompts | `prompt_release_blocked`, `prompt_registry_empty` (add — see §1) | — |
| evals | `eval_regression_detected` | — |

Each scenario above is a **single row/record**. The 10 D-11 states (`normal, long_text, empty, dense, disabled, selected, loading, warning, danger, error`) are a second, orthogonal axis applied by `states_for/2`, which composes N scenarios (or 0, for `empty`) rather than requiring 8×10 or 13×10 hand-authored literals.

### Runtime/compile isolation enforcement (D-21, concretely)

1. **Structural (necessary, not sufficient):** `elixirc_paths(:test) = ["lib", "test/support"]`, `elixirc_paths(_) = ["lib"]` — `dev/` is absent from both, so any adopter (Hex consumer) or `mix test` run gets a hard compile/load failure if `lib/` referenced `DevLab.Fixtures`.
2. **The actual enforcement (load-bearing, per §1's gap analysis):** `test/scoria_web/dev_lab_boundary_test.exs` (already sketched in `37-PATTERNS.md`) — a pure `File.read!/1` + `Regex`/`String.contains?` scan asserting zero matches for `DevLab\.` (or whatever the chosen prefix is) across `lib/**/*.{ex,heex}`. This is the only check that fires in the one environment (`:dev`, where a maintainer actually edits code) where the violation would otherwise compile silently.
3. This test must run under the required `mix test` CI lane (confirmed already gated per `docs/MAINTAINERS.md`/RESEARCH.md), not as an optional/advisory check.

---

## 4. DX guarantees

**"Add one ugly scenario" must be a single new `def scenario(:new_name), do: %{...}` clause plus (optionally) one line in `@scenario_names`/`domains/0` — nothing else should need to change.** Concretely:

- A contributor adding `connector_auth_expired` should not need to: touch `dev/lab/lab_live.ex`, touch any `dev/lab/sections/*.ex` file, or understand `handle_params` routing. `states_for/2`'s generic derivation (§3) means a brand-new scenario is *automatically* eligible for every state band the moment it exists — sections iterate `DevLab.Fixtures.scenarios()`/`domains()`, they don't hardcode a scenario list.
- Naming discipline: **scenario names are Scoria domain nouns/events/verbs, never table/schema names.** `connector_auth_expired`, not `connector_expired_at_not_null`. This is directly checkable in review by asking "does this read like something you'd say to an operator out loud" — `approval_requested` passes, `approvals_status_pending` fails.
- Discoverability: the `Fixtures` IA section (D-27 "Open fixture matrix") is the browsing surface — `domains/0`'s grouping is what renders there, so a new scenario is visible to every future contributor without grepping source, satisfying D-23 (the "future contributor" persona's job).
- Guardrail that keeps this cheap forever: because `states_for/2` derives states generically, the *cost* of adding a scenario stays O(1) (one map literal) instead of growing to O(states) as the catalog scales — this is the concrete mechanism that prevents the ExMachina/FactoryBot "factory explosion" footgun from ever materializing here (§2).

---

## 5. Coverage-gate classification

Format follows the plan-schema convention used elsewhere in this phase (`37-0X-PLAN.md` `must_haves.truths`/`artifacts`/`key_links`); "prohibitions" below map to negative-assertion `truths` entries (a `refute`/zero-match check) since that's the closest existing schema slot — flag this mapping explicitly to whoever wires the actual `PLAN.md`.

| Decision | Classification | One-line statement | Verification method |
|---|---|---|---|
| **D-17** (spotlight) | `must_haves.truths` | "`DevLab.Fixtures` never calls `Scoria.Repo`/`Ecto.Query`/any DB-backed context module — every scenario is a pure literal-data read." | Source-scan denylist: `Path.wildcard("dev/lab/**/*.ex")` contains no `Repo.`, `Ecto.Query`, `alias Scoria.Repo`, `Scoria.Workflows.`, `Scoria.SRE.` — pure `File.read!` + `refute =~` in `test/`, same tier as the D-21 guard. |
| **D-17** (spotlight) | `must_haves.truths` | "Calling `DevLab.Fixtures.scenario/1` for a given name twice in the same run returns identical data — no `DateTime.utc_now/0`, `NaiveDateTime.utc_now/0`, `Ecto.UUID.generate/0`, `System.unique_integer/1`, `:rand.*`, or `Enum.random/1` appears anywhere under `dev/lab/fixtures*`." | Same source-scan tier: denylist regex over `dev/lab/fixtures*.ex` for the forbidden call names. |
| D-16 | `[informational]` | Struct-vs-map-vs-JSON is a design choice, not independently gate-worthy beyond "the module exists and lives under `dev/`." | n/a — covered by D-21's structural + guard-test checks. |
| D-16 | `must_haves.artifacts` | `dev/lab/fixtures.ex` (or `dev/lab/fixtures/*.ex` once split) exists. | File-existence check, part of normal plan artifact verification. |
| D-18 | `[informational]` | Inventory IDs are a coverage/navigation anchor only; not independently machine-verifiable as a "decision" beyond the existing LAB coverage checks. | Optional stronger check (defer unless requested): cross-reference every `PRIM-*`/`GROUP-*` `canonical` row in `36-inventory.json` against lab section source strings. |
| D-19 | `must_haves.truths` | "The fixture catalog includes at least one scenario for each of: approvals, incidents, reviews, datasets, workflow detail, connectors, prompts, evals — and at least one explicit empty-or-error-state scenario per domain." | Source-scan: for each domain-noun prefix regex (`approval_`, `incident_`, `review_`, `dataset_`, `workflow_`, `connector_`, `prompt_`, `eval_`), assert at least one match in `dev/lab/fixtures*`; separately assert at least one `_empty`/`_blocked`/`_failed`/`_denied`/`_regression` suffix match per domain. |
| D-20 | `must_haves.truths` | "All named D-20 scenario identifiers exist as `DevLab.Fixtures.scenario/1` clauses (exact literal match)." | Literal string source-scan (already sketched in `37-PATTERNS.md`'s `dev_lab_boundary_test.exs` draft) — cheapest, CI-gated, no new tooling. |
| D-21 (isolation half) | `must_haves.truths` (encodes a prohibition) | "No file under `lib/**/*.{ex,heex}` references `DevLab.` (or the chosen fixtures-module prefix)." | `test/scoria_web/dev_lab_boundary_test.exs` zero-match regex scan — this is the actual enforcement mechanism, not defense-in-depth (see §1/§3). |
| D-21 (isolation half) | `must_haves.truths` (encodes a prohibition) | "`mix.exs` `package/0` `files:` never includes `dev` or `priv/dev`." | Source-scan of `mix.exs` text (already sketched in RESEARCH.md's Code Examples). |
| D-21 (hidden-business-rule half) | `[informational]` — **explicitly not mechanically verifiable** | "Fixture defaults must not become hidden business rules." | No regex/CI check catches this; treat as a PR-description/code-review checklist item ("did any `lib/` default value get copy-pasted from a `DevLab.Fixtures` literal?"). State this gap honestly in the plan rather than implying a script covers it. |

---

## 6. Footguns specific to Scoria

1. **`priv/fixtures` vs `priv/dev` directory collision (Hex leakage risk).** `mix.exs`'s `package/0` ships `"priv/fixtures"` verbatim (used today by `SupportJourney.ticket_fixture/0`/`persona_fixture/0`) but excludes `priv/dev` entirely. A contributor extending the lab "by analogy" to `SupportJourney`'s existing JSON-fixture pattern could easily drop a new file under `priv/fixtures/lab/...json` instead of `priv/dev/lab_fixtures/...json` — a one-directory-segment mistake that ships dev-only ugly/stress data straight to Hex adopters. **Mitigation:** name the JSON root unambiguously (`priv/dev/lab_fixtures/`, never anything under `priv/fixtures/`), and add a `mix.exs` package-files source-scan assertion (already recommended under D-21 above) that also greps for any accidental `priv/fixtures/lab` or similar path strings inside `dev/lab/fixtures.ex`.

2. **`SupportJourney`/`dev_seed.exs` entanglement.** `SupportJourney` is the shared spine for the adopter-facing example gallery *and* `dev_seed.exs` *and* doc-fragment drift guards (`SupportJourneySourceTest`, referenced in its moduledoc). It is tempting — and D-17 explicitly does not forbid — reusing its pure scalar constants (`tenant_id/0`, `connector_key/0`). It is a mistake to go further and mutate/extend `SupportJourney`'s JSON fixtures (`ticket.json`, `persona.json`) to add "uglier" values for lab purposes: those files are under a different module's contract (gallery + `adopter_doc_surfaces/0` fragment-matching tests), and editing them for lab-stress purposes risks silently breaking unrelated doc-drift guards or adopter-facing example correctness. **Mitigation:** `DevLab.Fixtures` may `import`/reference `Scoria.SupportJourney`'s zero-arg identity constants read-only; it must own 100% of its own bulk/ugly payload data independently.

3. **Nondeterminism creep via copy-paste from `dev_seed.exs`.** Because `dev_seed.exs` is the most visually similar existing file (same domain, same approval/incident/workflow vocabulary), a contributor drafting lab fixtures is likely to start by copying patterns from it — and `dev_seed.exs` *legitimately* uses `NaiveDateTime.utc_now()`-driven Ecto inserts and DB-generated UUIDs throughout, because that's correct for its job. Copy-pasted into `DevLab.Fixtures`, those same calls silently reintroduce D-17's exact failure mode inside the very module meant to fix it. **Mitigation:** the denylist source-scan in §5 (D-17 rows) catches this mechanically and should ship in the same PR as the fixtures module, not as a follow-up.

4. **State/tone drift baked into fixture data itself.** RESEARCH.md's Pitfall 4 catches the *call-site* mistake (`tone={:warning}` instead of `:warn`). A subtler version: if a fixture map itself carries a `:tone` field with a wrong/D-11-state-shaped value (e.g. `%{tone: :warning, ...}` inside `scenario(:approval_requested)`), any call site that naively does `tone={fixture.tone}` inherits the bug invisibly, and it won't be caught by reviewing the section-renderer code (RESEARCH.md's Pitfall 4 fix) because the bad value lives in the data layer instead. **Mitigation:** fixture maps carry domain-truth fields only (see §3's data-shape rule) — no `:tone` key, ever; tone is always derived, never stored.

5. **Asymmetric `:dev`-env compile boundary (the sharpest version of D-21's risk — detailed in §1/§3).** Restated here as a footgun because it's easy to assume `elixirc_paths` alone is "the fix": it isn't. A `lib/` → `DevLab.Fixtures` reference compiles fine under a maintainer's day-to-day `mix phx.server` (`:dev` env) and would only be caught by `mix test` or by an adopter's production crash. The guard test in `test/` is not optional polish — treat its absence as a phase-blocking gap, not a nice-to-have.

6. **Fixture "factory explosion" from a literal reading of D-19/D-20.** Already covered in §1/§3 — hand-authoring 13×10 (or 8-domain×10-state) literal fixtures is the single most likely way this phase balloons in scope and becomes unmaintainable exactly the way FactoryBot's "nested attributes and callbacks" pitfall describes. The `scenario/1` (data) vs `states_for/2` (rendering-state, derived) split is the concrete guardrail.

7. **Silent JSON drift for bulky payloads.** A hand-edited `priv/dev/lab_fixtures/*.json` file that becomes malformed or drops a key some copy-helper expects fails only at first LiveView render (a runtime crash inside the lab, not a compile error) unless `@external_resource` is declared for it, which forces `mix compile` under `:dev` to reprocess (and therefore re-validate via `Jason.decode!/1`) the file on every edit. Declare `@external_resource` for every JSON-backed fixture file — this is cheap and turns a runtime footgun into an immediate `mix compile` failure.

---

## Sources

- Repo (read in full or targeted sections this session): `.planning/phases/37-dev-component-lab-and-stress-fixtures/{37-CONTEXT.md,37-RESEARCH.md,37-PATTERNS.md,37-UI-SPEC.md,37-03-PLAN.md}`, `lib/scoria/support_journey.ex`, `lib/scoria/support_journey/handlers.ex`, `priv/repo/dev_seed.exs` (lines 1-180 + grep), `lib/scoria_web/ui.ex` (full function/attr/slot index), `lib/scoria_web/approval_copy.ex` (lines 1-50, 235-264), `lib/scoria_web/components/approval_inbox_component.ex`, `test/support/` tree incl. `test/support/scoria/host_install_fixtures.ex`, `mix.exs` (`elixirc_paths/1`, `package/0`), `config/dev.exs`, `prompts/phoenix-ai-lib-deep-research.md` (domain-model/telemetry-event section), `.planning/phases/36-baseline-and-inventory/36-inventory.json` (schema + sample rows), `.planning/REQUIREMENTS.md` (LAB-01/LAB-02/FIXT-01 exact wording).
- `https://ex-machina.hexdocs.pm/readme.html` — factories, sequences, lazy evaluation, documented pitfalls.
- `https://ecto.hexdocs.pm/testing-with-ecto.html` — sandbox boundary model; confirmed silent on non-DB fixture determinism.
- `https://storybook.js.org/docs/writing-stories/args` — args composition/inheritance model.
- `https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests` — MSW mocking pattern; confirmed gap on mock/prod drift.
- `https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Stories.Variation.html` — compile-time attr-type checking against real component attrs.
- `https://martinfowler.com/articles/nonDeterminism.html` — nondeterminism taxonomy and remedies (clock-wrapping, rebuild-over-cleanup).
- Rails fixtures vs FactoryBot: `https://harled.ca/blog/the_battle_of_factories_vs_fixtures_when_using_rspec`, `https://masilotti.com/rails-test-fixtures/`.
- Golden-file testing best-practice summary (search aggregate, various sources incl. Flutter/Go golden-test guides).
