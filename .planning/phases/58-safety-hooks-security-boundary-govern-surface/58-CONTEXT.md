---
phase: 58
slug: safety-hooks-security-boundary-govern-surface
created: 2026-07-29
method: 5 parallel area researchers → 2 opposed-lens red teams → adjudicated synthesis
requirements: [HOOK-01, HOOK-02, BOUND-01, GOVERN-01]
---

# Phase 58 — Context

Decisions below are **locked**. Entries marked **(revised)** were changed by the red-team
pass — including one reversal of the orchestrator's own draft decision. Entries marked
**(reversal)** overturn a position a research agent recommended.

Method: five parallel per-area researchers (each aware of the others), then two red teams
with deliberately opposed lenses — code-truth vs adopter-harm/coherence/scope — both
attacking the reconciled draft rather than the five inputs. Where the red teams disagreed,
the disagreement was adjudicated explicitly rather than averaged; see D-03 and D-14.

---

## Corrections to the shipped record

Three prior-phase records are factually wrong. All three were found independently by more
than one agent and confirmed by the code-truth red team. Correcting them is bookkeeping,
landed as doc commits against the owning phase's artifacts — not feature work.

- **D-01** — `Trust.Scan.scan/2` has exactly TWO production call sites, not one:
  `lib/scoria/mcp/executor.ex:1606` (tool output) and `lib/scoria/knowledge.ex:434` (RAG
  retrieval). Neither is model output.

- **D-02** — Scanner-derived taint does NOT feed the confluence gate today.
  `confluence_input/2` builds leg witnesses solely from the tool's declared
  `%Classification{}` (`executor.ex:705-728`), and `leg_witness(true)` hardcodes
  `%{source: :declared}` (`executor.ex:731`). The comment at `executor.ex:737-739` states
  `:default_tier` and `:scanner_infra` are not constructible through any live call path.
  Phase 57's D-13 promised observed-scanner taint would light the untrusted-content leg;
  that half was never wired. **Consequence: the only leg source ever written in production
  is `:declared`, so `Confluence.grade/1` can return only `nil` or `"declared"` today.**

- **D-03** — Phase 57's `57-CONTEXT.md:261` cross-phase obligation 2 is FALSE. It says
  per-tool classification "comes from `scoria.classification.*` on the TOOL span." The
  executor merges those keys onto `[:scoria, :tool, :completed]` telemetry metadata
  (`executor.ex:1359-1365`), but `Observe.Adapters.MCP.emit_tool_span/4`
  (`observe/adapters/mcp.ex:85-108`) projects a fixed 8-key map plus
  `Semconv.merge_host_declared/2`, whose `@host_declared_keys` is
  `~w(feature route archetype intent)a` (`semconv.ex:116`). The classification keys never
  reach `ai_spans`. Phase 58 must correct `57-CONTEXT.md:261` in place.

---

## Hook seam

- **D-04** — HOOK-01 and HOOK-02 ride `Scoria.Trust.Scanner`, NOT the eval seam. Amend both
  requirements and the two matching ROADMAP success criteria, using the GATE-02/GATE-04
  amendment precedent. Grounds: `lib/scoria/eval/` declares zero `@callback`/`@behaviour`;
  `Runner.score_dataset_item/6` dispatches on two hardcoded literals (`runner.ex:140`,
  `:173`) and turns any host `scorer_kind` into `{:not_scored, :unknown_scorer}`
  (`:179-192`); `SubjectOutput.resolve/2` returns the frozen `dataset_item.captured_output`
  in BOTH modes (`subject_output.ex:16-17`), so the eval path structurally cannot observe
  live production output; `JudgeRunner.run_live/1` hard-requires `provider`+`model`
  (`:22-23`) and a sealed dataset; `OnlineScoreSampler` is prod-env-gated, host-invoked,
  sampled, fire-and-forget (`online_score_sampler.ex:19-25`, `:104-110`). The seam the
  requirement describes already shipped in Phase 55, with `:moderation_flag` already in the
  closed reason-code enum (`verdict.ex:45`).

- **D-05 (revised)** — HOOK-01 requires ZERO new code. Phase 55 already shipped the `scan/2`
  callback (`trust/scanner.ex:34-35`), `NoOp` as the shipped default (`:48-51`), and the
  moderation reason code. A host registering a moderation scanner via
  `config :scoria, :content_scanner, MyModerator` satisfies HOOK-01 in full today. HOOK-01
  is therefore one requirement amendment plus one documentation section. The draft treated
  it as new mechanism and inflated the phase accordingly.

- **D-06 (reversal)** — Model-output taint is span evidence ONLY this milestone. It does NOT
  write a confluence leg witness. Both red teams independently reached this from opposed
  lenses, overturning the orchestrator's draft preference for the conditional-witness design.
  - Code-truth grounds: the traced "100% pause rate on shipped defaults, day one" that
    justified the draft's choice is FALSE. Enforcement gates on the combination, not the
    decision (`executor.ex:630-657`), and `exfil` comes only from a declared
    `can_exfiltrate` (`:722`), which is never overwritten from the accumulator (`:608-609`).
    Unconditional tainting is inert at ladder rung 1. The real hazard is narrower and
    different: for rung-2+ adopters it silently collapses the three-leg test into a two-leg
    test. The written requirement also supports span-only — `REQUIREMENTS.md:46` and
    `ROADMAP.md:188` both say "in traces" and neither mentions the gate.
  - Adopter-harm grounds: a correctly-written Phase-55 scanner receives a THIRD, undefined
    content shape at the new seam (`normalize_payload/1`'s arbitrary host-shaped map,
    `runtime.ex:946-947`), raises `FunctionClauseError`, is caught by the isolation task
    (`scan.ex:107-111`), and fail-closes to `:scanner_error` on every LLM step. Under the
    witness design that is a `scanner_infra` witness; under `strict: true` (`confluence.ex:311-312`)
    it becomes unconditional escalate. The conditional design's safety proof was sound for
    the paths it enumerated but did not enumerate the path its own contract change creates.
  - Wiring scanner-derived taint into the gate is deferred to Phase 58.1 (D-21).

- **D-07 (revised)** — CUT the automatic `kind: "llm"` step-boundary scan seam. Ship only the
  explicit, host-invoked `Scoria.Trust.scan_model_output/2`, mirroring the
  `Observe.emit_prompt_span/1` precedent. Amend HOOK-02's success criterion to "a host can
  scan model output and see it tagged in traces", and state plainly that Scoria does not
  automatically scan model output. Three independent grounds:
  - Zero `kind: "llm"` steps exist anywhere in `lib/`, `examples/`, or `dev/`. The reference
    example registers LLM-ish steps as `kind: "answer"`
    (`examples/support_copilot/lib/support_copilot_web/live/chat_live.ex:127-128`), and
    Scoria's own UI hard-codes `defp span_kind("answer"), do: "llm"`
    (`components/workflow_tree_component.ex:40`). Every `kind: "llm"` occurrence is a test
    fixture.
  - `SpanKind.normalize/2` defaults unrecognized values to `"agent"` (`span_kind.ex:56+`),
    so the gate is false for the exact steps HOOK-02 targets, and it logs a warning while
    being false.
  - Category error: `step.kind` is a UI display taxonomy (`span_kind.ex:2-4`), not a
    declaration that a step calls a model. Gating a safety control on it means the only way
    to opt into scanning is to rename a workflow step so it renders under a different rail —
    the decorative-hook pattern this project has caught before.

- **D-08 (revised)** — Scan latency must never be charged to the rails without accounting.
  `Trust.Scan.scan/2` is synchronous with a 5000 ms default (`scan.ex:35`, `:38`), and
  `rail_max_active_ms` is wall time minus PAUSE time only (`rails.ex:94-102`), frozen at run
  creation. A synchronous in-step scan can therefore trip a non-resurrectable rail halt on
  latency alone, with no scanner verdict involved. This is a second, independent reason for
  D-07. The latency-vs-rails interaction must be documented in the boundary guide. If an
  automatic seam ever ships, excluding scan time from `max_active_ms` is its own design —
  `rail_paused_at`/`rail_paused_ms` are deliberately uncastable and derived only inside
  `Run.changeset/2`.

- **D-09 (revised)** — A `:site` discriminator on the scan context is DEFERRED to 58.1, and
  when it lands, absent means `nil` / unspecified — never a defaulted `:tool_output`.
  Defaulting would fabricate a value (violating the never-fabricate doctrine) and would
  silently mislabel the live retrieval call site at `knowledge.ex:434`, which is not tool
  output. The two in-lib call sites pass their own value explicitly.

- **D-10** — The `incoming_tier` inversion is the sharpest implementation trap and applies to
  `scan_model_output/2`. `Trust.default_tier/0` is `"untrusted"` (`trust.ex:36`) and
  `Scan.scan/2` defaults `:incoming_tier` to it (`scan.ex:67`), so the monotonic fold clamps
  a CLEAN verdict back to untrusted. Copy `executor.ex:1597-1604` exactly: seed
  `incoming_tier: "trusted"` only when a real scanner resolves, leave it unset under NoOp.
  Branch on `scanner_tier`, never on `tier` — NoOp leaves `scanner_tier: nil`
  (`scan.ex:71-74`).

- **D-11** — `Eval.online_scoring` keeps a documented but demoted role: the offline
  measurement and human-review destination for scanner-flagged traces, never the enforcement
  path. Documentation only in this phase; no eval-seam code ships.

---

## Security boundary document

- **D-12** — BOUND-01 ships as `guides/security-boundary.md`, NOT a root
  `SECURITY-BOUNDARY.md`. Amend the requirement's literal filename. Grounds: no root
  `SECURITY.md` exists, so a root file would be read as the missing vulnerability-reporting
  policy and would squat that name; `mix.exs` `package/0` `files:` is an explicit list, not a
  glob; and `guides/maintainers.md:88` states verbatim that canonical public docs live under
  `guides/`.

- **D-13** — Two docs with a strict one-way refinement: `ownership-boundary.md` is the
  general case (who owns which noun in normal operation); `security-boundary.md` is the
  adversarial case (which control stops an attacker, and which you must still build). Every
  security scenario refines exactly one ownership row, so no fact is stated twice and there
  is nothing to drift. Registered in the ExDoc "Start Here" group immediately after
  ownership-boundary. Ownership-boundary cannot absorb it — `scope_doctrine_contract_test.exs`
  pins its exact table title, 5 headers, 5 rows and 14 host-owned words across BOTH README and
  the guide.

- **D-14 (revised)** — WR-01 is FIXED, not published, AND gets a CHANGELOG entry. The red
  teams split here and both were partly right. The boundary doc is the wrong home — an
  adopter can take no action, so publishing it there is a mis-addressed message. But
  "inert today" is not the standard for silence: the inertness is a defense-in-depth accident
  (`run_tool_scope_granted?/3` independently re-checks at `executor.ex:474`), nothing pins it,
  and a future refactor reopens the hole with no adopter-visible record that it ever existed.
  Resolution: land the server-side `confluence_approval?/1` check in the `approve_run_scoped`
  handler plus a regression test as `T-58-01`, AND add one CHANGELOG line under `### Security`
  stating what was hardened and that no adopter action is required.

- **D-15** — Residual inclusion test: a residual belongs in an adopter-facing doc only if the
  adopter can do something about it. ABSORB four of Phase 57's five accepted limitations —
  step-scoped pause, unpausable call sites, a host `catch :exit` disarming escalation, and the
  retrieval residual. LINK only the second-row-lock cost (AR-57-01) — it is a throughput cost,
  not a responsibility split.

- **D-16** — Honest scenario content. Scoria enforces NOTHING on model output, NOTHING on
  system-prompt leakage (Spotlight is adjacent and silently bypassed if the host
  self-concatenates), and NO per-user tool allowlist (`live_tool_allowlist` is replay-scoped
  narrowing; connector grants are credential state, not policy). The doc says so plainly.

- **D-17** — Gate shape and claims, never prose. Six accessors on `adopter_doc_contract.ex`
  (path, required sections, required scenarios, required residuals, forbidden claims, and
  required CURRENT claims per the D-53 positive pattern), one test appended to
  `adoption_surface_test.exs`. Do NOT gate prose: that file is 741 lines and runs in CI's
  blocking `policy` job under `mix test --no-start --warnings-as-errors` with NO Postgres, so
  the new test must be app-free and DB-free — and gating prose would train maintainers to
  weaken assertions rather than update docs.

- **D-18 (revised)** — SEVEN registrations, not six. The draft's six are correct and correctly
  located, but there is a second, independent `@canonical_guides` list at
  `test/mix/tasks/scoria.release_preview_test.exs:8-24` that is not derived from the first and
  already diverges from it. Adding a guide to only one list fails CI.

- **D-19 (blocker)** — Broken-window entry 4 must be cleared FIRST.
  `mix docs --warnings-as-errors` is already RED (missing
  `guides/capabilities/trace-observability.md` referenced by README/glossary, plus filtered-module
  warnings), and `mix scoria.release_preview` is the canonical warnings-as-errors docs/package
  gate that D-12's registrations must pass. The boundary-doc work lands on a red gate and cannot
  be proven green until this is fixed. This is a wave-0 plan, not a footnote.

---

## Govern surface

- **D-20** — GOVERN-01 is NOT amended. The red teams split and the adopter-lens position wins:
  amending it to "two of three legs" because the accumulator structurally cannot hold `:exfil`
  is trimming the requirement to fit the implementation — the mirror image of the
  tracking-outruns-code failure Phase 57's own verification caught. The requirement is
  satisfied in the escalation-events section, where frozen audit rows genuinely carry the full
  combination string. The run panel's structural inability to say "exfiltration path" is a
  FEATURE, not grounds to weaken the requirement.
  - Amendment legitimacy test, adopted project-wide: an amendment is legitimate iff the
    original wording named a mechanism that does not exist or was misidentified, AND the
    amended wording delivers the same adopter-observable outcome. It is laundering iff the
    adopter-observable outcome shrinks. An amendment that shrinks outcome requires an explicit
    "Reduced scope" note in the requirement line, never a silent rewrite. By this test D-04,
    D-12 are legitimate; D-07 is legitimate but shrinking and must be labelled as such;
    amending GOVERN-01 would be laundering.

- **D-21** — Data sources are split by subject and never merged into one value. The run panel
  reads `ai_workflow_runs.confluence_legs` — designated in writing three times
  (`run.ex:56-58`, `:77-82`, `executor.ex:1664-1667`) — and re-derives combination and grade in
  memory via `Confluence.classify/1` + `grade/1` (both verified public, total, pure, DB-free).
  The events section reads frozen audit rows directly by `workflow_run_id`; the approval
  back-link hop is unnecessary when the run is the entry point.

- **D-22** — The structural honesty guarantee, pinned by a property test: `:exfil` is per-call
  and is NEVER accumulated (`executor.ex:589-600`, `run.ex:56-58`, `decode_confluence_legs/1`
  at `:937-944`), so `classify/1` fed from the accumulator can return only 4 of 8 combinations.
  It is structurally impossible for the run panel to say "exfiltration path". The phrase can
  appear only in the events section, which exists only when a frozen row exists.

- **D-23 (revised)** — The events section must SEGMENT on `metadata["decision"]`.
  `record_confluence_audit/5` has FIVE call sites, not three — `executor.ex:385` (rejected
  approval), `:645` (host-tightened block), `:1046` (halted run), `:1077` (escalate),
  `:1167` (unattributed non-allow) — and all five write the same
  `event_type: "tool.confluence.escalated"`. Reading by run id therefore returns BLOCK rows
  too. Two further consequences: `executor.ex:385` writes a SYNTHETIC
  `combination: "exfiltration_path"` with no measured evidence
  (`confluence_rejected_evidence/4`, `:772-782`), which D-22's property test will not catch;
  and `executor.ex:1167` passes a `nil` run id, so those rows are invisible to a run-scoped
  read by construction. A section headed "escalations" that renders block rows is exactly the
  dishonesty this phase exists to prevent.

- **D-24** — The mandatory coverage footnote, verified true: the allow branch
  (`executor.ex:656`) emits `[:scoria, :gate, :confluence, :observed]` (`:1313`) and nothing
  else, and NO handler anywhere in `lib/` attaches to that event. A trifecta that fires and is
  allowed at an ungated grade leaves zero durable trace. The screen must say so.

- **D-25 (revised)** — The four presentation states, with the grade logic corrected. S0
  (`legs == %{}`): no banner, no green check, and the load-bearing line "This is not a
  statement that the run was safe." S1 (lit, gated): warn tone, chip "Enforced". S2 (lit,
  ungated): neutral tone, chip "Recorded, not enforced". S3 (frozen events, rendered only when
  rows exist): the only place the full combination string and the fail tone appear.
  - Correction the draft got wrong: the three grade-keyed S2 action lines (unclassified /
    default_tier / scanner_infra) are ALL UNREACHABLE today, a direct corollary of D-02 — only
    `:declared` is ever written. And there was no line for `declared`, the only grade S2 can
    actually have. Write the reachable line first; keep the others behind 58.1.
  - Correction: undeclared tools produce NO witnesses (`executor.ex:715-716`, `:726-727`), so
    the grade is `nil` and the decision short-circuits at `executor.ex:661` before `decide/2`
    is called. The screen is still justified — that run has zero surface today — but the causal
    chain is "no witness, grade nil", not "grade unclassified".
  - Correction: `ApprovalCopy.combination_tone/1` is THREE-valued, not unconditionally warn
    (`approval_copy_test.exs:205`, `:209`, `:215`). Only the two-leg
    `private_data_and_untrusted_content` case conflicts. Build `GovernCopy.posture_tone/2` for
    that one case; reuse `combination_label/1`; promote `witness_source_label/1` and
    `grade_label/1` from `defp` to public rather than duplicating the tables.

- **D-26** — One object, two views, one nav entry under Operate, mirroring the shipped
  Incidents precedent (two modules, one nav key). Do NOT create a fourth top-level section for
  one item, and do NOT promote the `tool-registry` stub — `confluence.ex:74-80` states as
  locked design fact that "there is no tool registry to enumerate" and that a partial scan
  claiming completeness is "false assurance, worse than no scan at all." The Exposure page must
  state in one line why its per-tool table is historical evidence and not the registry, since
  the "Tool Registry — soon" stub remains visible under Configure.

- **D-27 (revised)** — SIX nav registrations, not three. The draft named `@views`,
  `derive_base/3` and `strip_known_prefixes/1`. Also mandatory: `@groups`
  (`dashboard_nav.ex:13-132`, the declared navigation source of truth, which drives both the
  sidebar and the command palette), `@g_chords` (`:149-159`, or the chord does not exist), and
  a params-carrying `derive_base/3` clause for the detail view mirroring the Incidents one
  (`:250`). Note `ScoriaWeb.WorkflowLive.Show` is in `@views` with no `derive_base` clause — an
  existing gap not to replicate.

- **D-28** — Per-tool classification ships as a historical evidence ledger with a
  self-limiting header ("Tools with recorded confluence evidence"), never a completeness
  claim. Static enumeration is out (no registry; the `:persistent_term` memo is node-local so a
  multi-node deploy shows a different list per request). `result_envelope` is out
  (wholesale-replaced by `complete_step/3`, and one key per step so two tool calls overwrite).
  Ledger rows must disclose that blocked and refused calls produce no tool span
  (`adapters/mcp.ex:73-83`) and are sourced from audit rows instead.

- **D-29** — Merge the five `scoria.classification.*` keys into `emit_tool_span/4`'s existing
  fixed-key projection (`adapters/mcp.ex:93-108`). This is the one write-path change inside an
  otherwise read-only requirement, and it is justified: it is the difference between the
  per-tool half of GOVERN-01 being verifiable on a healthy run or only on a failed one, it
  preserves D-04b (project, never spread), and it makes Phase 57's obligation 2 (D-03) true
  instead of false. `classification_attributes_for_telemetry/1` reads
  `context[:tool_classification]` (`executor.ex:1638-1639`), so unlike the step-envelope write
  it also fires for connector-routed calls.

- **D-30** — Read model is a new `Scoria.Workflows.ConfluenceProjection` sibling module, never
  an insertion into `workflows.ex` (whose line-pinned guard test pins `:481` and `:1143`).
  `tenant_id` is the first positional argument everywhere so a call site that forgets it fails
  to compile. Never `Workflows.get_run!/1` — it is unscoped (`workflows.ex:30`). Copy the D-51
  batched-page discipline verbatim: page-size-independent query counts, and no query at all
  when a page holds no confluence rows. One new index required:
  `index(:ai_audit_outbox_events, [:workflow_run_id, :event_type])`, with concurrent-build
  guidance in the migration note.

- **D-31** — Absence rules extend Phase 57's never-fabricate doctrine. Leg absent renders no
  row (never a "not lit" row — `lit` is only ever written true). Unrecognized source renders
  "Unknown source" with an unclassified grade, never upgraded or blank-defaulted. Missing
  `first_step_id` renders no row, never the run id. Zero audit rows OMITS the events section
  entirely, because a "no escalations" empty state would read as a safety claim. Tenant
  mismatch drops the row entirely rather than rendering it partially.

- **D-32 (revised)** — The semantic fast path bypasses the gate entirely.
  `Runtime.prepare_semantic_fast_path/1` completes a step via
  `complete_semantic_fast_path_hit/2` without reaching `execute_step/2`, so a semantic-hit run
  carries ZERO confluence evidence and renders as S0. S0's copy must be written with this case
  in mind — it is precisely the "reads as a safety claim" failure D-31 exists to prevent.

- **D-33** — Nav label. "Exposure" is the working label but it is coined — absent from both the
  brand word bank and `guides/reference/glossary.md`, while every other nav label is
  glossary-backed. Whichever label ships gets a glossary entry in this phase. "Govern" is
  rejected: it is jargon, it promises configuration this phase defers, and it collides with the
  locked feature name "Tool Governance".

- **D-34** — Scope fence, enforced structurally rather than by convention: no form, no
  `phx-submit`, no `phx-change`, no mutating `phx-click`, no policy or threshold editor, no
  allowlist control, no simulate/what-if affordance, no composite risk score (a locked brand
  anti-trait), no writable Repo call. The strongest and cheapest enforcement is a structural
  test asserting the detail LiveView exports NO `handle_event/3` at all — a module with no
  event handler cannot mutate. Phase 57's obligation 5 explicitly bans a policy builder and
  per-tool allowlist; cite it as the lock.

- **D-35** — No documentation link from the LiveView. No dashboard screen links docs today, and
  the ExDoc URL is version-pinned so it drifts every release; an adopter on a mounted dashboard
  may not be able to reach it. The S0/S2 copy carries the operative sentences inline instead.

---

## Scope

- **D-36 (revised)** — Phase 58 SPLITS. The draft inventoried at roughly 15–17 plans against
  Phase 57's 12, in a closing phase with no Phase 59 to absorb overflow. D-05 removes HOOK-01's
  code entirely and D-06/D-07 remove the witness write and the automatic seam, which brings the
  closing phase back to a deliverable size. Phase 58 ships: the record corrections, the HOOK
  amendments, `scan_model_output/2` as span-only evidence, the boundary guide with its seven
  registrations and drift gating, the WR-01 fix, the tool-span classification projection, the
  Exposure surface with its projection and migration, and the CHANGELOG. Phase 58.1 ships:
  scanner-to-gate wiring (Phase 57's unwired D-13 debt), the `:site` discriminator and the
  published `:model_output` content shape as one deliberate contract change, the stuck-escalation
  queue, grade-segmented would-have-paused counts, and scan-latency-versus-rails accounting.

- **D-37 (revised, critical)** — Phase 57 assigned SIX cross-phase obligations to Phase 58; the
  draft silently dropped two, and both red teams found this independently.
  - Obligation 4, which Phase 57 called "load-bearing, not nice-to-have": the stuck-escalation
    queue. Approval expiry was deferred to a Phase 57.1 that **does not exist in ROADMAP.md**,
    on the explicit assumption that Phase 58's queue would supply the human trigger. With
    `NULL = never expires` and no queue, a forgotten escalation is an immortal
    `waiting_for_approval` run whose only surface is the pending inbox. This is the most likely
    real-world failure of the milestone's flagship differentiator.
  - Obligation 6: would-have-paused counts segmented by grade, never a raw firing count (100%
    by construction). Named in shipped code at `executor.ex:1282-1287` as Phase 58's to render
    — but nothing attaches to the carrying telemetry event (D-24), so no durable sink exists,
    and neither of D-21's data sources can produce a per-call count.
  - Both move to 58.1 with a named owner, and the adopter workaround for the stuck-escalation
    case is documented in the boundary guide rather than left silent.

- **D-38** — CHANGELOG `0.1.4` is a Phase 58 deliverable, not an afterthought. It must cover
  the new guide, the tool-span classification attributes (an adopter-visible trace-schema
  change), the new index migration with its ordering and cost note, the WR-01 hardening under a
  Security heading, and any `ApprovalCopy` visibility promotions. `0.1.4` is already staged and
  the Hex cut is a maintainer call at closeout, so the CHANGELOG is the milestone-close artifact.

- **D-39 (revised)** — The milestone claim must be revised at close. PROJECT.md claims Scoria
  "escalates to a human when one run touches private data, untrusted content, and an exfil
  channel at once." Per D-02, what ships escalates when a tool DECLARES all three legs — a
  self-declaration gate over host-authored metadata, not an observation gate. That is still a
  real and rare capability, but it must be claimed at that precision. The boundary guide states
  "the untrusted-content leg is lit by a tool's own declaration; a registered scanner's verdict
  does not currently light it," and PROJECT.md is revised to match. If 58.1 wires it, both are
  upgraded together.

- **D-40** — Fixtures are unowned and blocking. `examples/support_copilot/` has zero
  `MCP.Executor.execute/4` calls, so the new Exposure screens have no realistic fixture and the
  project's automated-verification preference has nothing to point at. Phase 57 already recorded
  the fix — declaring the example's tools and routing one through the executor. Phase 58 owns a
  plan for it, or the flagship screen ships unverifiable end to end.

---

## Deferred

- Scanner-derived taint lighting the confluence untrusted-content leg (Phase 57's unwired D-13)
  → Phase 58.1, per D-06.
- The `:site` / `:content_kind` scan-context discriminator and the published `:model_output`
  content shape, as one deliberate contract change → Phase 58.1, per D-09.
- The automatic model-output scan seam, if ever wanted, keyed off an explicit host declaration
  rather than a display taxonomy → Phase 58.1, per D-07.
- The stuck-escalation queue and grade-segmented would-have-paused counts → Phase 58.1, per D-37.
- Approval expiry — already deferred by Phase 57 to a phase that does not exist; must be
  re-homed onto 58.1 alongside the queue it depends on.
- Policy builder and simulate-on-history → SEED-013, per Phase 57 obligation 5 and D-34.
- A real `Scoria.Eval.Scorer` behaviour enabling offline moderation-regression scoring → v2
  requirement, the honest deferred version of what HOOK-01 originally gestured at.

## Reviewed but not folded

- `2026-07-18-flaky-capture-parity-test.md` — keyword match only, not scope. Remains open.
- `2026-07-29-halt-run-confluence-cleanup-stale-entry-race.md` (CR-01) — phase-adjacent, since
  it touches the subsystem Phase 58 reads from, but it is a correctness fix in `halt_run/3`,
  not a Phase 58 requirement. Remains open; re-evaluate at milestone close.

## Canonical refs

- `.planning/REQUIREMENTS.md` — HOOK-01 `:45`, HOOK-02 `:46`, BOUND-01 `:50`, GOVERN-01 `:54`
- `.planning/ROADMAP.md` — Phase 58 block, success criteria 1–4
- `.planning/phases/57-confluence-escalation-gate/57-CONTEXT.md` — six cross-phase obligations
  (`:261` is factually wrong per D-03; `:263` and `:265` are dropped and re-homed per D-37)
- `.planning/phases/57-confluence-escalation-gate/57-SECURITY.md` — WR-01 at `:105`, AR-57-01
- `lib/scoria/confluence.ex` — the five-rung adoption ladder `:82-102`, accepted limitations
  `:104-145`
- `guides/ownership-boundary.md` — the doc `security-boundary.md` refines
- `guides/maintainers.md:88` — canonical public docs live under `guides/`
- `brandbook/` — canonical brand system; wins over older `prompts/` references
- `.planning/WINDOWS.md` entry 4 — the red docs gate blocking D-12, per D-19
