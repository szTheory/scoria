# Operator UI North-Star (IA & content-hierarchy target)

> **Provenance:** doctrine-filtered synthesis of the external ChatGPT deep-research storyboard
> `prompts/scoria-ideal-admin-operator-ui-ux-storyboard-deep-research.md` (2914 lines), ingested
> 2026-07-03 via 3 Explore agents (storyboard extraction + as-built UI map + GSD-state map) and a
> red-team pass against the scope doctrine and the n=1 persona.
>
> **How to read this doc.** The source storyboard was generated **blank-slate and maximalist** ("design
> the ideal operator UI from first principles, breadth + depth, best-in-class"). It therefore paints an
> **end-state** that (a) over-scopes for the n=1 persona (10 top-level nav sections, a 9-tab Feature
> Cockpit, per-span-kind tab sets) and (b) presupposes the **entire SEED-006…012 backlog is already
> shipped** (privacy, real evals, retrieval metrics, archetype, cost aggregation). Read it as the
> **North Star each UI-touching milestone lands a slice of — not a build spec.** ~40% of its best ideas
> we already ship (task-oriented nav, ⌘K, breadcrumbs, object headers, evidence notebooks, right-side
> drawers, honest stubs, dark volcanic brand, Run/Trace explorer, approvals-as-blocking-gates), so this
> is a **pivot/evolution, not a from-scratch redesign** — the v3.0 Control Room IA spine was sound.
>
> This doc is the **UI source-of-record** (peer of `ai-architectural-patterns.md`). The structural
> pivot it describes is owned by **[[SEED-013]]**; the feature-specific screens ride their backend
> seeds (map in the last section).

---

## 1. The one-line reframe

The dashboard should feel less like "LLM observability" and more like **an AI control room for one
engineer** who arrives reactive and under pressure, needing to answer fast: *"Is anything wrong? Does
anything need me? What happened? Can I stop it, approve it, replay it, or prove a fix?"* The storyboard's
organizing insight is to structure the product around **operator moments (Orient → Act → Investigate →
Recover → Improve → Govern → Audit), not Scoria's internal modules.** That reframe — plus two new
organizing objects (a unified **Queue** and the **AI Feature**) and the elevation of **Governance** — is
the whole pivot. Everything else is refinement of surfaces we already have.

## 2. Adopt / Adapt / Reject (the doctrine filter)

Every idea was run through the scope doctrine (P1–P6) and the falsifiable persona test — *"can one
person operate every surface unaided?"* — before landing here.

| Verdict | Idea | Why |
|---|---|---|
| **ADOPT** | **Unified Queue** — one ranked inbox for all human work (approvals + incidents + reviews now; release gates + privacy tasks later) | Strongest pure-n=1 idea: don't make a solo operator poll 5 pages. Pure IA, no backend, serves the persona test directly. P3 (operator surface). |
| **ADOPT** | **"AI Feature" as central object → Feature Cockpit** (runs+prompts+evals+tools+knowledge+budgets+policies for one feature) | Operators think "which feature is unhealthy?", not "show me spans." **Doctrine-safe only as a host-declared attribute Scoria segments by** — never a modeled business noun. This is a large expansion of [[SEED-012]]'s segment-by-attribute facet. |
| **ADOPT** | **Governance elevated to a first-class section** (tools & blast-radius, connectors, policies, guardrails, budgets, breakers) | "Don't bury the differentiator under Settings." Our weakest current group ("Configure"). Blast-radius = the lethal trifecta ([[SEED-010]]) made visual. P2 is Scoria's core verb. |
| **ADOPT** | **Persistent, explicit scope contract** (Tenant / Feature / Time / Live; cross-tenant visually loud) | Coherence win + hardens the exact cross-tenant-leak class that is a live P0 ([[SEED-006]]). "Cross-tenant leakage is a cardinal sin." P4. |
| **ADOPT** | **3-pane Run Workbench** (story-spine / evidence-canvas / inspector), evidence canvas adapts **per span-kind** and per-archetype | Enhancement of the existing `workflow_live/show.ex` (today ~2 panes). "Everything eventually leads to the run trace." Realizes Rule-8 pattern-adaptivity ([[SEED-012]]). |
| **ADOPT** | **Progressive-disclosure law** (`Summary \| Details \| Raw JSON` on every evidence surface) + **receipts** on every consequential action + **"create policy rule from this"** | Cheap, doctrine-central (P1 reconstructability), and is exactly the v3.3 coherence goal. Turns one-off judgment into durable governance. |
| **ADOPT** | **"Story spine with vesicles" trace viz** — porous basalt span-nodes whose *shape* encodes state (filled = evidence, hollow = redacted, ring = human decision, split ring = branch/replay, glowing rim = live, broken rim = error) | Graphic-design gem fusing the volcanic brand to the core data-viz. Distinctive, doctrine-neutral, signature identity. |
| **ADAPT** | The **10-section nav** | For n=1 it is *more* orientation cost, not less. Keep the organizing insight; re-map onto a **tighter nav** (see §3). |
| **ADAPT** | **Diagnosis / "most likely failure" / prompt-diff "behaviorally dangerous" warnings** | Keep the *slots*, but drive them from **mechanical signals** (linked regression counts, error-class correlation, trifecta flags) or **host-supplied** values — **never an in-lib LLM opinion** (P2: mechanism, not opinions). |
| **REJECT** | **"Env" (prod/staging/dev) as a Scoria-modeled concept** | Embedded = one deploy; multi-env is a SaaS-platform assumption. At most a host-declared optional attribute in the scope bar. |
| **REJECT** | **Big-bang rewrite** | The storyboard's end-state presupposes unbuilt backends. Land it incrementally; the structural shell first, feature-screens with their seeds. |

## 3. Target IA (the re-grouping)

A tighter re-grouping that keeps our "orient in seconds" bar while absorbing the two new organizing
objects (Queue, Features) and elevating Governance. `[today]` = exists; `[→seed]` = rides a backend seed.

```
Home         attention router (calm when healthy; routes attention when not)         [today]
Queue        unified human-work inbox — approvals + incidents + reviews now;
             release gates + privacy tasks fold in as those land                     [today → seed]
Features     feature list → Feature Cockpit (host-declared feature attribute)         [SEED-013 shell / SEED-012 content]
Runs         Live Runs + Run Explorer → 3-pane Run Workbench                          [today, enhanced]
Quality      reviews · datasets · evals · prompts/releases                            [today → SEED-008 / SEED-009]
Govern       connectors · tools & blast-radius · approval policies · guardrails ·
             budgets · circuit breakers                                               [today → SEED-010]
Data&Privacy retention · PII masking · memory · semantic cache · forget-actor         [→ SEED-011]
Audit        immutable-feeling receipts ledger                                        [→ seed]
```

**Mapping from today's 3 groups → target:** `Operate` (Home/Approvals/Runs/Incidents) splits into
**Home + Queue + Runs** (Approvals & Incidents become Queue categories); `Improve` becomes **Quality**
(reviews/datasets/evals/prompts) with **Features** lifted out as its own top-level object; `Configure`
is re-themed and elevated to **Govern**, with **Data & Privacy** + **Audit** as new future homes for
[[SEED-011]] and the receipts ledger. This is a re-label + re-slot of mostly-existing surfaces plus two
genuinely new objects (Queue, Feature Cockpit) — not a rebuild.

**Cross-cutting (apply on every screen):** persistent scope bar; `Summary | Details | Raw JSON` on
every evidence surface (summary default, raw never first); a **receipt** on every consequential action;
**append-and-mark** live updates (never auto-reorder/jump rows while the operator is reading — new items
arrive as a "N new" pill); right-side **inspector drawer** before full-page navigation; a single
`key:value` search grammar reused by global search and Run Explorer, with **saved views**;
**status never encoded by color alone** (already our `tone/status_label` rule).

## 4. The signature moves (each with doctrine + n=1 rationale)

1. **Unified Queue.** Collect every human-blocking item into one ranked list (rank: blocking end-user
   impact → security/privacy risk → incident severity → age → blast radius → release risk → cost).
   **Bulk actions only for low-risk review cases** — *"bulk approval of high-risk tool actions should not
   exist."* n=1: eliminates polling. Doctrine: P3, no new backend (composes existing approval/incident/
   review records).

2. **AI Feature + Feature Cockpit.** A cockpit per host-declared feature (`support_copilot`,
   `billing_refund_assistant`, …) with tabs `Overview · Runs · Quality · Releases · Access · Knowledge ·
   Policies · Cost · Audit`, and a **clickable architecture map** whose nodes open runs/releases/evals/
   governance and which shows **hard limits as first-class UI** (max steps, $/run, no-deploy, no-secrets).
   Doctrine guardrail: **Scoria segments by a host-declared feature attribute; it never models "Feature"
   as an owned entity and never infers it** (same posture as [[SEED-012]] archetype, [[SEED-010]]
   tool-declared trifecta). The cockpit **shell** is [[SEED-013]]; tabs populate incrementally as the
   backend seeds land.

3. **Governance as a first-class section + blast-radius panels.** Per-tool/connector risk shown as
   compound facts — *reads private data · reads untrusted content · external egress · side effect ·
   irreversible · approval required* — and dangerous **combinations named** ("private data + untrusted
   content + external egress → **exfiltration path**"). Approval-policy builder reads as
   plain-language `When … Then pause & require approval`, with **policy test-on-past-runs** ("would have
   matched 38 runs — 32 correct, 4 unnecessary, 2 need review") as an explicit **approval-fatigue**
   preventer. This is the flagship [[SEED-010]] rendered for humans.

4. **3-pane Run Workbench.** Left = **story spine** (chronological nested trace, vesicle nodes). Center
   = **evidence canvas** that changes by span kind (prompt / LLM / retrieval / tool / guardrail / eval /
   error), each with its own `Summary … Raw` tabs, and adapts to the archetype (Rule 8). Right =
   **inspector** (Diagnosis / Risk / Actions / **Related**: same actor/prompt/tool/error/dataset). Run
   actions: Resume · **Branch from checkpoint** · **Replay (must always declare fidelity)** · Compare ·
   **Create eval case** · **Mark root cause** (structured label set). Guardrail: the inspector's
   "Diagnosis" and "Related" are **mechanical correlations / linked-record counts**, not an LLM verdict.

5. **Progressive disclosure + receipts + policy-from-decision.** Three consistent layers everywhere;
   every consequential action ends with a copyable receipt (action, decider-ref, run, policy, reason,
   time, receipt id); a one-off approval can become a durable policy. Doctrine: P1 (durable
   reconstructable record) + P5 (zero egress). Directly serves the v3.3 coherence bar.

6. **Persistent scope contract.** Tenant / Feature / Time / Live follow the operator through every major
   screen; cross-tenant and any non-prod scope render **visually loud** so scope is never implicit.
   Hardens the [[SEED-006]] P0 cross-tenant class at the UI layer. (No "Env" object — host-declared
   attribute only, if at all.)

7. **Story-spine-with-vesicles trace visualization + operator-grade copy.** The porous-node motif is the
   brand's signature data-viz. Copy is plain and consequence-first: *"Run paused before calling
   send_email. No external message has been sent."* — every risky screen must distinguish **proposed /
   completed / blocked / approved / denied** so the operator instantly knows *whether damage happened or
   was prevented.* Emotional target: **from anxious uncertainty to grounded control, because every action
   left a receipt.**

## 5. Recorded guardrails (binding on all future UI work)

These are the doctrine boundaries any milestone drawing from this North Star must hold:

- **Host-declared only.** Feature, archetype, route, env, intent, risk-tier are **host-supplied
  attributes Scoria records and segments by** — Scoria never infers or models them as owned business
  nouns (P1/P2/P4). Segmenting is a mechanism; the values are the host's.
- **No in-lib opinion.** No in-lib LLM "diagnosis," "most likely failure," or "behaviorally dangerous"
  judgment. Diagnosis/danger slots are driven by **mechanical signals** (linked regression counts,
  error-class correlation, trifecta flags) or host-supplied values (P2: mechanism, not opinions).
- **No Env-as-concept.** Scoria is embedded in one deploy; multi-environment is not a Scoria model.
- **Tighter nav, not 10 sections.** Optimize for "one person orients in seconds," not maximal breadth.
- **Incremental, not big-bang.** The structural shell ([[SEED-013]]) is buildable on today's backend;
  feature-screens ride their backend seeds and are only built when the backend exists (no fake data —
  honest stubs, per the v3.0 precedent).
- **Scope is an explicit contract**, never implicit; cross-tenant/non-prod always visually loud (P4).
- **Everything reconstructable, zero required egress** (P5) — receipts, traces, evidence all live in the
  host's own Postgres/BEAM.
- **Operator/reviewer surface only** (P3) — `/scoria` is never an end-user surface.

## 6. Which screen rides which seed (the slice map)

So every future UI-touching milestone knows exactly which slice of the North Star it owns:

| Screen / capability | Owning seed | Notes |
|---|---|---|
| Nav re-group, persistent scope bar, unified **Queue** (over existing surfaces), 3-pane **Run Workbench** shell, progressive-disclosure law, receipts, **story-spine viz**, **Feature Cockpit shell** | **[[SEED-013]]** | Structural pivot; buildable on today's backend. |
| **Feature Cockpit content** (per-archetype eval presets, router confusion-matrix, pattern-adaptive trace view, segment-by-attribute) | **[[SEED-012]]** | Populates the Cockpit's Overview/Quality tabs. Composes with 013's shell. |
| **Govern** section, **tools & blast-radius** panel, exfiltration-path framing, approval-policy builder + policy-test-on-past-runs, guardrail screens | **[[SEED-010]]** | Flagship; richest match in the storyboard. |
| **Data & Privacy** surface, forget-actor-with-preserved-receipt, retention/mask display, memory & semantic-cache-inspectable-like-a-run | **[[SEED-011]]** | |
| **Quality** depth — eval-run-detail + segment breakdown, eval-case-as-story, release-gate view, candidate-vs-baseline compare | **[[SEED-008]]** | |
| **Retrieval Explorer**, citation map, **retrieval-vs-generation failure classification** (mechanical) | **[[SEED-009]]** | |
| Per-span-kind evidence tabs, Feature/route attributes, scope-bar attribute substrate | **[[SEED-007]]** | OTel attribute foundation the scope bar + evidence canvas read from. |
| The **"AI Feature" vocabulary**, operator-moments framing, plain-language operator-grade copy standards | **[[SEED-005]]** | Positioning/docs rewrite carries the vocabulary. |

## 7. Antipatterns & footguns the storyboard flags (worth heeding)

- Bulk-approving high-risk tool actions must not exist.
- Never let scope become implicit; cross-tenant leakage is the cardinal sin; non-prod must look different.
- Don't bury Governance under Settings — it is the differentiator.
- Don't flatten every feature into a generic "agent trace" — make the architecture shape visible.
- Don't make the policy builder a rules-engine dumping ground — keep it plain-language and testable.
- Live updates append-and-mark; never jump rows while the operator reads; pause control always visible.
- Replay must always declare fidelity (exact vs approximate, e.g. "raw prompt redacted after 7-day TTL").
- Cache reuse must be inspectable like a run, not an invisible optimization.
- Purge must preserve an anonymized audit receipt even while deleting payloads.
- Motion is operational, not playful: no shimmer, no animated backgrounds, no auto-scroll outside tail.
- Home is an attention router, not a BI dashboard; when healthy, its CTA is "review sampled production
  cases" (turn calm into the improvement loop).

## 8. Standards the storyboard leans on (prior art)

No direct competitor products are named; it grounds in standards/vendor guidance: **Phoenix LiveView**
(real-time without an SPA), **progressive disclosure** (general UX), **OpenTelemetry GenAI semconv**
(breadth of traceable material — dovetails [[SEED-007]]), **Anthropic agent guidance** (simple composable
patterns; make architecture shape visible), **OpenAI Agents SDK guardrails** (Scoria's edge is *inline
blocking, not passive observation*), **OpenAI eval guidance** (eval shape matches architecture shape),
**NIST AI RMF** (incidents connect impact/evidence/mitigation/governance, not just logs), **OWASP LLM
Top-10** (prompt injection + insecure output handling → the blast-radius/governance emphasis).
