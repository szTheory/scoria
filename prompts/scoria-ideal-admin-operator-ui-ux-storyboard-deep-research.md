Scoria ideal admin/operator UI/UX storyboard

North-star framing

Scoria’s dashboard should feel less like “LLM observability” and more like an AI control room for one engineer: a place where the operator can instantly answer:

Is anything wrong? Does anything need me? What happened? Can I stop it, approve it, replay it, or prove a fix?

The organizing principle should be operator moments, not Scoria modules. The person arrives in a reactive state, often under pressure. So the product should be structured around the sequence:

Orient → Act → Investigate → Recover → Improve → Govern → Audit

This also fits the technical canvas: Phoenix LiveView is well-suited to a real-time admin surface because LiveViews start as normal server-rendered HTML and then push updates when socket assigns change, which supports live queues, streaming runs, and incident updates without turning Scoria into a separate SPA platform.  

A second core design principle is progressive disclosure: the first layer should be plain-language, status-first, and action-oriented; raw prompts, JSON, IDs, span attributes, and policy receipts should be one deliberate click away. This is exactly the type of complexity-management problem progressive disclosure is meant for.  

⸻

1. Core product model

The UI should introduce one user-facing concept that may or may not exist as a first-class Scoria object today:

AI Feature

An AI Feature is the operator’s mental grouping for runs, prompts, evals, tools, knowledge sources, budgets, and policies.

Examples:

* support_copilot
* billing_refund_assistant
* contract_summarizer
* sales_email_drafter
* repo_agent
* internal_analytics_assistant

The operator should rarely start from “spans” or “eval specs.” They should start from:

Which AI feature is unhealthy, expensive, risky, blocked, or changing?

Each feature gets a Feature Cockpit: one place that shows its health, architecture pattern, active versions, recent runs, eval status, cost, tool access, knowledge sources, memory policy, and current gates.

This becomes the main organizing bridge between the Scoria domain nouns and the solo engineer’s actual job.

⸻

2. Top-level information architecture

Recommended primary navigation

Home
Queue
Features
Runs
Quality
Releases
Governance
Data & Privacy
Audit
Settings

This is deliberately not a pure noun taxonomy. It mixes moments and objects so the n=1 operator can enter from the reason they came.

Navigation rationale

Nav item	Primary question it answers	Main jobs served
Home	“Is my AI healthy right now?”	Orient, spot problems, route attention
Queue	“What needs a human decision?”	Approvals, incidents, reviews, release gates, privacy tasks
Features	“How is this AI feature behaving?”	Feature-level health, versions, runs, quality, access, policies
Runs	“What happened on this execution?”	Live runs, search, trace forensics, replay, branch
Quality	“Is behavior improving or regressing?”	Evals, datasets, review queue, online scoring, regressions
Releases	“Can this prompt/model/tool/context change ship?”	Prompt registry, version diffs, eval gates, canaries, rollback
Governance	“What can the AI touch, spend, or do?”	Tools, connectors, budgets, breakers, guardrails, approvals
Data & Privacy	“What did Scoria store, and can I forget it?”	Retention, PII masking, memory, semantic cache, purge
Audit	“Who decided what, when, and why?”	Receipts, approvals, policy changes, release decisions
Settings	“How is Scoria configured?”	Mount-level configuration, defaults, integrations

The ideal shell has a persistent left nav, but the real power is a global scope bar across the top.

⸻

3. Persistent shell

Every screen should preserve orientation. The operator should always know where, for whom, in what environment, and under what time window they are looking.

Global top bar

[Scoria]  Env: Prod ▾  Tenant: Acme Corp ▾  Feature: All ▾  Time: Last 60m ▾
          Search runs / prompts / tools / actors…      ⌘K
          Live: On • 12 updates/min     Queue: 7     Incidents: 1

Required controls

Environment selector

Prod, Staging, Dev, All

Prod should carry a subtle but always-visible production badge. Staging and dev should have visually distinct framing so operators never approve or replay in the wrong environment.

Tenant selector

Default should be one tenant. Cross-tenant views should be explicit:

Tenant: Acme Corp

or

Tenant: All tenants — cross-tenant view

“All tenants” should use a visible striped or bordered treatment. Cross-tenant leakage is a cardinal sin, so the UI should never let scope become implicit.

Feature selector

All features, or one feature.

Feature scope should follow the operator through all major screens.

Time selector

Common defaults:

* Last 15 min
* Last 60 min
* Last 24h
* Last 7d
* Custom

For live views, the time selector should pair with:

Live updates: On / Paused

Global search

Search should accept natural keywords and structured IDs.

Examples:

run_8J3
trace_id:abc
tenant:acme status:failed
tool:send_email guardrail:blocked
prompt:support_reply_v12
actor:usr_1234

Command palette

⌘K should expose fast operator actions:

* Open run
* Search traces
* View pending approvals
* Pause live updates
* Create eval case from current run
* Open feature cockpit
* Open tool blast radius
* Compare prompt versions
* Re-run eval suite
* Branch from selected checkpoint
* Purge actor data
* Copy audit receipt

⸻

4. Shared layout primitives

Scoria should reuse a few very strong primitives everywhere.

4.1 Object header

Every object detail page starts with a dense but readable header.

Example: run header.

Run run_8J3K9
Support Copilot • Prod • Tenant: Acme Corp • Actor ref: user_4821 • Session: sess_91
Status: Paused — awaiting approval
Risk: High
Cost: $0.042
Duration: 14.2s
Prompt: support_reply_v12
Model: gpt-4.1-mini
Eval: grounded_pass, tone_pass, policy_warn
[Resume] [Branch] [Replay] [Create eval case] [Copy IDs] [More ▾]

4.2 Evidence card

Every claim should be backed by evidence.

Evidence
Why Scoria says this is risky:
• Tool would send an external email.
• Retrieved context includes private customer billing history.
• Recipient domain is outside the tenant.
• Policy “external_message_with_private_data” requires approval.
[Open policy] [Open retrieval span] [Open tool args]

4.3 Receipt

Every consequential action ends with a receipt.

Decision receipt
Action: Denied tool call
Decider: host_user_ref:42
Run: run_8J3K9
Policy: external_message_with_private_data
Reason: Customer billing data present; response should be edited first.
Time: 2026-07-03 14:22:10 EDT
Receipt ID: audit_77KQ

4.4 Inspector drawer

Most lists should open details in a right-side drawer before taking the operator to a full page.

Use this for:

* Approval preview
* Run preview
* Eval case preview
* Tool preview
* Prompt version preview
* Incident preview

The drawer lets the operator stay in flow.

4.5 Raw mode

Every evidence surface should have:

Summary | Details | Raw JSON

The summary is default. Raw JSON is never hidden, but it is never the first thing.

OpenTelemetry’s GenAI attributes show the breadth of traceable material a Scoria-style UI should make navigable: agent identity, conversation IDs, prompt names, model request parameters, input/output messages, retrieval documents, tool call arguments/results, eval scores, token usage, and workflow names.  

⸻

5. Home: the at-a-glance control room

Purpose

Home answers:

“Do I need to do anything right now?”

This is not an analytics dashboard first. It is an attention router.

Layout

┌──────────────────────────────────────────────────────────────────────────────┐
│ Overall state: Needs attention                                               │
│ 3 blocking approvals • 1 active incident • cost +42% vs baseline             │
└──────────────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────┬─────────────────────────────┬─────────────────┐
│ Needs human decision         │ Active incidents             │ Cost / budget    │
│ 3 approvals                  │ 1 SEV2                       │ 68% monthly      │
│ Oldest waiting: 8m           │ Support Copilot              │ Spike detected   │
│ [Open queue]                 │ [Triage]                     │ [Investigate]    │
└─────────────────────────────┴─────────────────────────────┴─────────────────┘
┌─────────────────────────────────────────────┬───────────────────────────────┐
│ Attention stack                              │ Live activity                 │
│ 1. Approve external message?                 │ support_copilot run paused    │
│ 2. SEV2: groundedness dropped                │ billing_assistant running     │
│ 3. Cost spike in repo_agent                  │ contract_summarizer complete  │
│ 4. Prompt draft awaiting release             │ ...                           │
└─────────────────────────────────────────────┴───────────────────────────────┘
┌──────────────────────────────────────────────────────────────────────────────┐
│ Feature health grid                                                           │
│ Feature              Health   Runs   Quality   Cost   Risk   Pending   Active │
│ support_copilot      Warn     1.2k   -6.4%     +12%   High   3         v12    │
│ billing_assistant    OK       248    stable    +2%    Med    0         v4     │
│ repo_agent           Watch    19     n/a       +88%   High   1         v2     │
└──────────────────────────────────────────────────────────────────────────────┘

Content hierarchy

Primary

* Overall state
* Human-blocking items
* Active incidents
* Budget/cost anomalies
* Feature health grid

Secondary

* Live run stream
* Recent release changes
* Quality trend cards
* Guardrail and breaker posture

Progressive disclosure

* Raw metrics
* Full incident timelines
* Full run traces
* Eval score distributions
* Model/token/provider details

Home status states

Healthy

The home screen should be calm:

All AI features healthy
0 pending approvals
0 active incidents
Cost within budget
Quality stable across monitored features

The primary CTA becomes:

Review sampled production cases

because when nothing is burning, the improvement loop is the best next action.

Warning

2 features need review
Quality regression detected in Support Copilot
Cost spike detected in Repo Agent

Warnings should route to diagnosis, not panic.

Critical

Action required
1 approval blocking a user
1 circuit breaker tripped
Potential cross-tenant retrieval blocked

Critical home should prioritize one primary CTA:

Open queue

Interaction details

* Clicking any card opens a drawer with the top 3 linked objects.
* Clicking a feature row opens Feature Cockpit.
* Clicking a live run opens Run Workbench.
* Home should never auto-reorder the attention stack while the operator is reading. New items should appear with a “3 new updates” pill.
* A “pause live updates” control should be visible whenever live data is streaming.
* Every alert card should answer: what changed, since when, what is affected, and what should I do next?

⸻

6. Queue: one place for everything that needs a human

Purpose

Queue answers:

“What is waiting on me?”

For an n=1 team, this is one of the most important surfaces. Separate queues for approvals, eval reviews, incidents, releases, and privacy would force the operator to poll the product. Scoria should collect all human work into one ranked queue.

Queue categories

All
Approvals
Incidents
Review cases
Release gates
Stalled runs
Privacy tasks

Queue item card

Approval required • High risk • Waiting 8m
Support Copilot wants to send an external customer email
Tenant: Acme Corp
Actor ref: user_4821
Run: run_8J3K9
Why risky: private billing data + external egress
Consequence: sends message to customer@example.com
[Review decision] [Open run] [Deny quick]

Content hierarchy

Primary

* Type of decision
* Risk/severity
* What is blocked
* Consequence in plain language
* Tenant and feature
* Age/SLA
* Primary action

Secondary

* Linked run
* Triggering policy
* Suggested diagnosis
* Related incidents
* Similar previous decisions

Progressive disclosure

* Full tool args
* Full prompt/rendered context
* Raw guardrail result
* Policy JSON
* Audit history

Queue ranking

Default ranking should combine:

1. Blocking end-user impact
2. Security/privacy risk
3. Incident severity
4. Age
5. Blast radius
6. Release risk
7. Cost exposure

A privacy/security approval that blocks external egress should rank above a routine review case.

Bulk actions

Bulk actions are allowed only for low-risk review cases.

Examples:

* Mark 20 sampled cases as “needs no follow-up”
* Promote selected thumbs-down cases to dataset
* Dismiss duplicate cost alerts

Bulk approval of high-risk tool actions should not exist.

⸻

7. Approval flow

Entry points

* Queue item
* Run Workbench paused state
* Incident timeline
* Tool governance screen
* Home attention stack

Approval detail layout

┌──────────────────────────────────────────────────────────────────────────────┐
│ Approval required                                                            │
│ Run paused until a human decides.                                             │
│                                                                              │
│ Requested action: Send customer email                                         │
│ Risk: High                                                                    │
│ Policy: external_message_with_private_data                                    │
└──────────────────────────────────────────────────────────────────────────────┘
┌──────────────────────────────┬───────────────────────────────────────────────┐
│ Consequence                   │ Evidence                                      │
│ This will send an email to:   │ • Retrieved billing history                   │
│ customer@example.com          │ • Tool call: send_email                       │
│                               │ • Private data present                       │
│ Subject: Refund update        │ • External recipient                         │
│                               │                                               │
│ [Preview outgoing message]    │ [Open retrieval] [Open tool args] [Open run] │
└──────────────────────────────┴───────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────────────────────┐
│ Decision                                                                    │
│ [Approve once] [Deny] [Request edit] [Halt feature]                          │
│ Reason / note:                                                              │
│ __________________________________________________________________________  │
└──────────────────────────────────────────────────────────────────────────────┘

Required content

The approval page must answer these before showing the approve button prominently:

1. What will happen if I approve?
2. Who or what is affected?
3. What data is involved?
4. Why did this require approval?
5. What evidence did the model use?
6. What happens if I deny?
7. Will the run resume, fail, branch, or wait for edit?

Approval actions

Approve once

Approves this specific action only.

Receipt records:

* run
* tool call
* policy
* decider ref
* timestamp
* note
* exact args approved

Deny

Denies the action and returns a structured denial to the run.

Optional denial reasons:

* unsupported claim
* wrong recipient
* private data present
* wrong tenant
* needs human edit
* policy violation
* other

Request edit

Creates a correction checkpoint. The run stays paused or branches.

Halt feature

Emergency action when approval reveals systemic risk.

This should open a confirmation modal:

Halt Support Copilot in Prod?
This will prevent new runs for this feature.
Existing runs: pause / allow to finish / cancel
Reason required.

Open run

Takes the operator to the exact span that requested approval.

Post-decision state

After approval or denial:

Decision recorded
Run resumed
Receipt: audit_77KQ
[Open resumed run] [Copy receipt] [Create policy rule from this]

The “create policy rule from this” action is important: one-off decisions should feed governance.

⸻

8. Features: the main operational object

Feature list

Feature             Pattern        Health  Runs  Quality  Cost  Risk  Pending
Support Copilot     RAG + tools     Warn    1.2k  -6.4%    +12%  High  3
Billing Assistant   Workflow        OK      248   stable   +2%   Med   0
Repo Agent          Agentic loop    Watch   19    n/a      +88%  High  1
Contract Summary    Single-call     OK      91    +1.1%    -4%   Low   0

Feature Cockpit

The Feature Cockpit is the “homepage” for one AI feature.

Support Copilot
Prod • Tenant: All tenants • Pattern: Router → RAG → tool-calling workflow
Agency: Medium-high
Active prompt: support_reply_v12
Active model: gpt-4.1-mini
Active knowledge index: support_kb_2026_07_01
Risk posture: High — external communication enabled with approvals
[Open live runs] [Run evals] [Review pending approvals] [Rollback] [Edit policies]

Tabs

Overview
Runs
Quality
Releases
Access
Knowledge
Policies
Cost
Audit

Feature overview content hierarchy

Primary

* Health summary
* Active human work
* Current incidents
* Active versions
* Quality trend
* Cost trend
* Risk posture

Secondary

* Recent runs
* Recent feedback
* Recent guardrail triggers
* Top failure modes
* Dataset coverage

Progressive disclosure

* Full span-level metrics
* Prompt raw text
* Tool schemas
* Policy rules
* Raw eval results

Feature architecture map

Every Feature Cockpit should show a small architecture diagram.

Example:

Input
  ↓
Router: support_intent_v3
  ↓
RAG: support_kb_index_2026_07_01
  ↓
LLM: support_reply_v12
  ↓
Gate: citation + policy check
  ↓
Tool: draft_reply / send_email requires approval
  ↓
Output

For an agent:

Goal
  ↓
Agent loop: repo_agent_v2
  ↺ observe → decide → tool → gate
  Tools: search_repo, read_file, edit_file, run_tests, create_pr_draft
  Hard limits: 20 steps, $2/run, no deploy, no secrets

This map is not decoration. Every node should be clickable into runs, releases, evals, or governance.

Anthropic’s agent guidance is relevant here because it emphasizes simple, composable patterns over unnecessary complexity; Scoria’s UI should therefore make the actual architecture shape visible instead of flattening every feature into a generic “agent trace.”  

⸻

9. Runs: live activity and historical search

Runs should have two modes:

Live
History

They can share the same shell, but the operator’s mental posture is different.

⸻

9.1 Live Runs

Purpose

Live Runs answers:

“What is happening right now?”

Layout

┌──────────────────────────────────────────────────────────────────────────────┐
│ Live runs • Prod • Last 15m • 12 active • 3 paused • 1 failing               │
│ [Pause updates] [Filter] [Only risky] [Only paused] [Group by feature]       │
└──────────────────────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────────────────────┐
│ run_8J3K9  Support Copilot  Paused: approval required  14.2s  $0.042        │
│ timeline: input → retrieval → llm → guardrail → tool approval                │
│ latest: wants to send external email                                         │
│ [Review approval] [Open trace]                                               │
├──────────────────────────────────────────────────────────────────────────────┤
│ run_8J4P2  Repo Agent        Running step 12/20          82.0s  $0.61        │
│ timeline: goal → search → read → edit → tests failed → edit                  │
│ latest: rerunning test suite                                                 │
│ [Open trace] [Stop run]                                                      │
└──────────────────────────────────────────────────────────────────────────────┘

Interaction details

* Live updates should append and mark changes, not jump rows unexpectedly.
* A “freeze row” interaction should let the operator inspect a live run without losing state.
* Paused and failing runs should float to the top.
* Each row shows a mini trace, not just a status.
* A live run card should include current step, elapsed time, cost so far, budget remaining, and last meaningful event.
* “Stop run” should be available for high-agency/looping systems.
* “Open trace” opens the Run Workbench at the current span.

⸻

9.2 Run History / Explorer

Purpose

Run Explorer answers:

“Find the exact execution or pattern of executions I need to inspect.”

Layout

Search: [ run ID, tenant, actor, prompt, model, tool, error, feedback... ]
Filters:
Feature ▾ Status ▾ Tenant ▾ Actor ▾ Prompt version ▾ Model ▾
Tool ▾ Guardrail ▾ Eval score ▾ Cost ▾ Latency ▾ Feedback ▾
Saved views:
[Failed last hour] [High cost] [Thumbs down] [Approvals denied] [RAG misses]
Table:
Status  Run       Feature          Tenant   Intent     Cost   Duration  Key events
Fail    run_91A   Support Copilot  Acme     refund     $0.03  4.2s      retrieval_miss
Paused  run_8J3   Support Copilot  Acme     refund     $0.04  14.2s     approval_required
OK      run_7Q2   Contract Sum.    Beta     summary    $0.01  1.1s      schema_pass

Search affordances

Run search should support:

* status:failed
* tool:send_email
* guardrail:blocked
* prompt_version:support_reply_v12
* eval:grounded_fail
* cost:>1.00
* latency:>30s
* feedback:thumbs_down
* tenant:acme
* actor:user_4821
* model:gpt-4.1

Result row hierarchy

Primary

* Status
* Feature
* Tenant
* Intent
* Failure / key event
* Cost and duration

Secondary

* Prompt version
* Model
* Eval summary
* Guardrails
* Feedback
* Span count

Progressive disclosure

* Row expand shows mini trace and top attributes.
* Click opens full Run Workbench.

⸻

10. Run Workbench: the core forensic experience

This is the most important screen in the product.

Purpose

Run Workbench answers:

“What happened on this run, why did it happen, and what can I do about it?”

Core layout: three-pane forensic workbench

┌──────────────────────────────────────────────────────────────────────────────┐
│ Run run_8J3K9 • Paused • Support Copilot • Prod • Tenant: Acme Corp          │
│ Cost $0.042 • Duration 14.2s • Prompt v12 • Model gpt-4.1-mini              │
│ [Resume] [Branch] [Replay] [Create eval case] [Copy IDs] [More ▾]           │
└──────────────────────────────────────────────────────────────────────────────┘
┌───────────────────────┬────────────────────────────────────┬────────────────┐
│ Story spine            │ Evidence canvas                    │ Inspector      │
│                        │                                    │                │
│ 1 Input                │ Selected span: Tool approval        │ Diagnosis      │
│ 2 Context built        │                                    │ Risk           │
│ 3 Retrieval            │ Plain summary                       │ Related runs   │
│ 4 LLM call             │ Tool args                           │ Eval scores    │
│ 5 Guardrail            │ Policy decision                     │ Actions        │
│ 6 Tool call paused ◀   │ Raw result                          │ Receipts       │
│                        │                                    │                │
└───────────────────────┴────────────────────────────────────┴────────────────┘

10.1 Story spine

The left pane is a chronological, nested trace.

Each span has:

* Kind icon
* Status
* Duration
* Cost/tokens where relevant
* Risk marker
* Expand/collapse
* Mini summary
* Click target

Example:

✓ Input received
  actor_ref:user_4821 • session:sess_91
✓ Prompt rendered
  support_reply_v12 • 1,242 tokens
✓ Retrieval
  support_kb • 5 chunks • grounding: medium
✓ LLM call
  gpt-4.1-mini • 860ms • $0.018
⚠ Guardrail
  private_data_external_egress → escalate
⏸ Tool call
  send_email(args) → awaiting approval

For high-agency runs, the spine becomes nested:

Goal: Add dark-mode toggle
└─ Step 1 Observe repo
   ├─ search_repo
   └─ read_file
└─ Step 2 Edit theme provider
   ├─ edit_file
   └─ run_tests failed
└─ Step 3 Repair failure
   ├─ edit_file
   └─ run_tests passed
└─ Step 4 Create PR draft
   └─ approval required

10.2 Evidence canvas

The center pane changes by selected span kind.

Prompt span

Shows:

* Prompt template name/version
* Rendered prompt summary
* Variables table
* Token count
* System/developer/user/message sections
* Redaction status
* Diff from previous active version
* “Copy prompt hash”
* “Open prompt version”
* “Create eval case with this prompt”

Tabs:

Summary | Rendered prompt | Variables | Diff | Raw

LLM call span

Shows:

* Provider/model/config
* Input/output token usage
* Cost
* Streaming timing / time to first token
* Finish reason
* Output
* Schema validation
* Safety checks
* Retry/fallback info

Tabs:

Summary | Input messages | Output | Model config | Validation | Raw

Retrieval span

Shows:

* Query text
* Query rewrite, if any
* Filters
* Tenant/permission filters
* Index/source version
* Top-k retrieved chunks
* Scores
* Freshness
* Which chunks were cited
* Which chunks were ignored
* Grounding/citation score

Visual:

Claim in answer                        Supporting chunk
"The duplicate charge is refundable" → refund_policy_v8 chunk 12
"Two charges occurred on June 1"      → billing_lookup result
Unsupported claim                     → no evidence

Tabs:

Summary | Retrieved chunks | Citation map | Filters | Index version | Raw

Tool span

Shows:

* Tool name/version
* Side-effect class
* Read/write scope
* Args
* Result
* Latency
* Retries
* Idempotency key
* Auth/policy gate
* External service status
* Whether approval was required

For risky tools, the page should show a blast radius panel:

Blast radius
Reads private data: yes
Reads untrusted content: yes
External egress: yes
Side effect: sends message
Irreversible: no
Approval required: yes

Guardrail span

Shows:

* Guardrail name/version
* Gate location: input, context, tool, output, memory
* Decision: allow, warn, block, escalate
* Triggering evidence
* Policy rule
* False positive/false negative feedback
* Recent similar triggers

OpenAI’s Agents SDK documentation frames guardrails as checks and validations for user input and agent output; Scoria’s UI should extend that idea across context, tools, memory, and release gates because Scoria’s differentiator is inline blocking, not passive observation.  

Eval span

Shows:

* Eval name/version
* Score
* Label
* Rubric
* Judge model/version, if applicable
* Human label, if present
* Explanation
* Calibration status
* Links to dataset item

Tabs:

Summary | Rubric | Scores | Judge details | Human labels | Raw

Error span

Shows:

* Error class
* Stack or sanitized error
* Provider/tool error
* Retry attempts
* Fallback
* Breaker state
* Related incident
* Suggested next action

Actions:

[Replay from previous checkpoint]
[Create incident]
[Create eval case]
[Mark root cause]

10.3 Inspector pane

The right pane is the operator’s tactical assistant.

Sections:

Diagnosis
- Most likely failure: retrieval miss
- Evidence: answer lacked support for claim X
- Similar failures: 14 in last 24h
Risk
- Private data involved
- External egress requested
- Approval policy matched
Actions
[Approve / Deny]
[Branch from checkpoint]
[Replay against draft prompt]
[Promote to eval case]
[Open related incident]
[Add root-cause label]
Related
- Same actor/session
- Same prompt version
- Same tool
- Same error
- Same dataset case

10.4 Run-level actions

Resume

For paused or stalled runs.

Requires confirmation if the previous state includes risk.

Branch

Creates a fork from a checkpoint.

Flow:

Select checkpoint
Choose modification:
  - prompt version
  - model/config
  - context source/index
  - tool mock/dry-run
  - memory off/on
  - guardrail override in sandbox
Run branch
Compare against original

Replay

Re-runs with the same captured inputs, subject to retention and privacy constraints.

Replay should always say whether it is exact or approximate:

Replay fidelity: partial
Reason: raw prompt redacted after 7-day TTL; using prompt hash + retained variables.

Compare

Compare original vs replay/branch.

Original                 Branch
Prompt v12               Prompt v13-draft
Model gpt-4.1-mini       Model gpt-4.1-mini
Cost $0.042              Cost $0.039
Groundedness fail        Groundedness pass
Approval required        Approval not required

Create eval case

Turns run into regression asset.

Fields prefilled:

* feature
* intent
* input
* retained context
* source evidence
* expected behavior
* forbidden behavior
* root cause
* risk tier
* privacy classification
* tags

Mark root cause

Root cause labels should be structured:

* prompt
* retrieval
* context builder
* model behavior
* tool selection
* tool args
* tool runtime error
* guardrail false positive
* guardrail false negative
* memory
* policy
* budget/breaker
* user input unsupported
* unknown

⸻

11. Pattern-adaptive trace views

The same Run Workbench should adapt to the architecture pattern. The user should not need separate products for RAG, agents, workflows, and single calls.

Architecture pattern	Default trace visualization	Primary diagnostic panels	Eval focus
Single-call	Compact input → prompt → model → validation → output	Prompt, model config, schema/output validation	Output quality, format, tone, safety
Structured extraction	Input → extraction → schema validation → downstream use	Field-level extracted values, confidence, parser result	Field precision/recall, enum accuracy, unknown handling
Prompt chain/workflow	Linear pipeline with gates between steps	Step outputs, gate decisions, cascade points	Step-level + end-to-end
RAG	Retrieval-focused trace with citation map	Query, filters, retrieved chunks, citations, grounding	Retrieval, faithfulness, citation correctness
Router	Branching route decision	Route confidence, alternatives, chosen branch, fallback	Routing accuracy, confusion matrix, per-route quality
Tool-calling	Tool/action timeline	Tool selection, args, auth, result, side effects	Tool selection, args, permissions, final answer
Parallelization	Fan-out/fan-in map	Candidate/checker outputs, disagreement, aggregator	Per-check precision/recall, disagreement, cost
Evaluator-optimizer	Iteration loop	Drafts, critiques, pass/fail criteria, revisions	Judge quality, improvement per iteration
Orchestrator-workers	Orchestrator with worker subtrees	Task decomposition, worker artifacts, synthesis	Coverage, synthesis faithfulness, duplicate/missing work
Agentic loop	Step loop with budget/stop rail	Goal, observation, action, tool result, stop condition	Goal completion, tool use, stop behavior, budget
Multi-agent	Swimlanes by agent	Handoff packets, role boundaries, per-agent tools	Handoff quality, per-agent eval, end-to-end

This directly operationalizes the rule: the eval shape should match the architecture shape. OpenAI’s eval guidance also emphasizes defining objectives, collecting production and expert data, running/comparing evals, and continuously evaluating as new nondeterministic cases appear.  

⸻

12. Incidents

Purpose

Incidents answer:

“Something crossed a threshold. What happened, what is affected, and what do I do?”

Incident list

Severity  Incident                  Feature          Started   Status
SEV2      Groundedness drop          Support Copilot  22m ago   Active
SEV3      Cost spike                 Repo Agent       1h ago    Investigating
SEV3      Connector failures         Google Drive     3h ago    Mitigated

Incident detail

Incident inc_42 — Groundedness drop
Severity: SEV2
Feature: Support Copilot
Started: 2026-07-03 13:52 EDT
Status: Active
Impact: 18% sampled answers failed groundedness over last 30m
Likely related change: support_reply_v13 canary began 42m ago
[Pause canary] [Rollback prompt] [Open affected runs] [Create eval cases]

Incident layout

What happened
- Metric crossed threshold
- Triggering policy
- Affected feature/tenant/segments
Timeline
13:10 prompt v13 canary started
13:22 groundedness warnings begin
13:52 incident opened
14:01 first human review confirms unsupported claims
Evidence
- Linked runs
- Eval failures
- Prompt diff
- Retrieval/citation failures
Mitigation
- Rollback available
- Pause canary
- Disable tool
- Tighten guardrail
Follow-up
- Create regression cases
- Add dataset coverage
- Resolve incident

Incident flow

1. Open incident from Home or Queue.
2. Read “what changed” summary.
3. Inspect affected segment.
4. Open representative run.
5. Confirm root cause.
6. Mitigate: rollback, pause feature, tighten budget, trip breaker, disable connector, or change policy.
7. Create eval cases from affected runs.
8. Resolve with receipt.

NIST frames AI risk management as a discipline for managing risks to people, organizations, and society; Scoria’s incident UX should therefore avoid treating AI failures as only technical logs and instead connect impact, evidence, mitigation, and governance receipts.  

⸻

13. Quality: evals, review, datasets, regression loop

Purpose

Quality answers:

“Is this AI feature getting better or worse, and can I prove it?”

Quality Home

Quality
Prod • All features • Last 7d
Feature cards:
Support Copilot
  Offline eval: 91.2% pass, -4.8% vs baseline
  Online judge: 87.0% grounded, -6.4%
  Human review: 14 pending
  Top failing segment: billing_refund intent
  [Open]
Billing Assistant
  Offline eval: 98.1% pass
  Tool args: 99.4% valid
  [Open]
Review queue
  14 sampled cases need label
  5 thumbs-down traces untriaged
  2 incident cases awaiting promotion
Dataset health
  Top intents covered: 16/20
  High-risk cases: 42
  Holdout untouched: yes

Eval suite detail

Eval suite: support_copilot_release_gate
Purpose: Block prompt/model changes that degrade support-answer quality.
Datasets:
- top_support_intents_v6
- refund_policy_regressions_v3
- prompt_injection_red_team_v2
Scorers:
- schema_valid
- groundedness_judge_v4
- citation_support
- forbidden_action_check
- human_label_sample
Release gate:
- 0 P0/P1 safety failures
- ≥95% citation support on policy cases
- ≥90% abstention on unanswerable cases
- no regression >2% on top intents

Eval run detail

Eval run eval_2026_07_03_01
Candidate: support_reply_v13
Baseline: support_reply_v12
Overall:
Pass rate: 91.2% vs 96.0% baseline
Decision: Blocked
Primary regression: refund_policy cases
Segment breakdown:
Intent                  Baseline  Candidate  Δ
password_reset          99%       99%        0
refund_duplicate_charge 96%       84%        -12
account_cancellation    94%       93%        -1
unanswerable            91%       89%        -2

Eval case comparison

Case: refund_duplicate_charge_017
Input
Customer says they were charged twice.
Expected behavior
Use duplicate-charge policy. Do not promise refund. Require verification.
Baseline output
Correctly says billing team must verify.
Candidate output
Says refund has been approved.
Scores
Forbidden claim: fail
Groundedness: fail
Tone: pass
Schema: pass
[Open source trace] [Promote to regression] [Mark release blocker]

Review queue

The review queue is where live production behavior becomes eval data.

Card:

Sampled production case
Feature: Support Copilot
Reason: online groundedness judge failed
Risk: Medium
Trace: run_91A
Reviewer task:
Was the answer supported by retrieved evidence?
[Supported] [Unsupported] [Unclear]
Notes:
[Promote to dataset] [Open trace]

Dataset screen

Dataset rows:

Case ID   Feature   Intent      Origin      Risk   Last result   Tags
case_017  support   refund      incident    High   fail v13      policy, billing
case_018  support   password    production  Low    pass          faq
case_019  support   jailbreak   red-team    High   pass          injection

Dataset detail should include:

* input
* app context
* expected behavior
* forbidden behavior
* source evidence
* rubric
* risk tier
* privacy class
* origin trace
* labels
* history of versions that passed/failed

Key interaction: promote trace to dataset

1. From Run Workbench, click “Create eval case.”
2. Scoria pre-fills input, context, evidence, output, scores, and root cause.
3. Operator edits expected/forbidden behavior.
4. Operator chooses dataset and split.
5. Case becomes part of future release gate.
6. Receipt links original incident/run to dataset case.

This is the improvement flywheel:

bad run → triage → root cause → eval case → fix → release gate → monitor

⸻

14. Releases: prompts, models, tools, context, and policies as ship events

Purpose

Releases answers:

“Can this AI behavior change safely go live?”

A prompt edit, model swap, context-builder change, retrieval index change, judge prompt change, tool schema change, or safety policy change can all alter behavior. The UI should treat these as release events.

Releases Home

Releases
Awaiting review
- support_reply_v13 prompt draft — eval blocked
- refund_tool_schema_v5 — eval passed, needs approval
- support_kb_index_2026_07_03 — canary running
Recently shipped
- billing_router_v4 — shipped 2d ago
- pii_guardrail_v7 — shipped 4d ago
Rollback-ready
- support_reply_v12 active backup
- support_kb_index_2026_07_01

Prompt registry

Prompt              Active  Draft  Features          Last changed  Quality
support_reply       v12     v13    Support Copilot   2h ago        v13 blocked
billing_extract     v4      —      Billing Assist.   4d ago        stable
contract_summary    v8      v9    Contract Summary  1d ago        eval running

Prompt detail

Prompt: support_reply
Active: v12
Draft: v13
Used by: Support Copilot
Risk: High — customer-facing support output
Tabs:
Overview | Versions | Diff | Rendered examples | Evals | Release history | Audit

Prompt diff view

Active v12                              Draft v13
────────────────────────────────        ────────────────────────────────
Do not promise refunds.                 You may tell the customer they
Say billing will verify duplicate        are eligible for a refund if
charges.                                duplicate charges are found.

The diff should highlight behaviorally dangerous changes, not just text changes.

Example warning:

Potential policy conflict:
Draft softens “Do not promise refunds” into “eligible for a refund.”
Linked regression failures: 12

Release review flow

1. Operator opens draft.
2. Sees plain-language summary of what changed.
3. Reviews diff.
4. Runs required eval suites.
5. Compares candidate vs baseline by segment.
6. Inspects failing cases.
7. Chooses:
    * approve full release
    * canary
    * reject
    * request edit
    * rollback
8. Receipt records decision.

Release gate view

Release gate: support_reply_v13 → prod
Checks
✓ Schema/format checks
✓ Tool authorization checks
✕ Refund policy regression
✓ Prompt injection red-team
✓ Cost within budget
⚠ Human review sample: 3 unresolved
Decision: Blocked
[Open failing cases] [Edit draft] [Override with reason] [Reject]

Override should be possible because Scoria provides mechanism, not business policy. But it must require a note and produce a receipt.

⸻

15. Governance: tools, connectors, guardrails, budgets, breakers

Purpose

Governance answers:

“What can the AI touch, what can it spend, and what stops it?”

This is Scoria’s differentiator. It should not be buried under settings.

OWASP’s LLM risk list includes prompt injection and insecure output handling, both of which are highly relevant when AI systems consume untrusted context and produce outputs that downstream software may act on.  

Governance Home

Governance
Risk posture
- 4 high-risk tools
- 2 external-egress tools
- 1 connector unhealthy
- 3 approval policies active
- 1 circuit breaker tripped in last 24h
Sections
[Tools & blast radius]
[Connectors]
[Approval policies]
[Guardrails]
[Budgets]
[Circuit breakers]
[Audit]

⸻

15.1 Tools & blast radius

Tool inventory

Tool                  Reads private  Untrusted input  Egress  Side effect  Approval
send_email            yes            yes              yes     external msg yes
search_payments       yes            no               no      read         no
issue_refund          yes            no               yes     money move   disabled
create_ticket_note    yes            yes              no      internal     no
delete_customer       yes            no               no      destructive  blocked

Blast radius matrix

Each tool should have a card:

send_email
Purpose: Send customer-facing email
Used by: Support Copilot
Status: Enabled
Risk: High
Blast radius
[✓] Reads private tenant data
[✓] May include untrusted retrieved content
[✓] External egress
[✓] Side effect
[ ] Irreversible
[✓] Human approval required
Recent calls: 142
Approval rate: 78%
Denied: 12%
Blocked by guardrail: 10%
[Open calls] [Edit policy] [Disable tool] [Test with past runs]

The tool page should make dangerous combinations obvious. For example:

Private data + untrusted content + external egress
This combination requires approval.

Tool detail tabs

Overview
Schema
Policies
Recent calls
Failures
Approvals
Audit

Tool schema tab

Shows:

* tool name
* description
* parameters
* examples
* side-effect class
* idempotency behavior
* allowed features/routes
* version history

The operator should be able to inspect whether a tool was designed narrowly enough for AI use.

⸻

15.2 Connectors

Connector list:

Connector      Status    Grants   Scopes              Last sync   Used by
Google Drive   Healthy   14       read docs           2m ago      Support RAG
Stripe         Warning   3        read payments       12m ago     Billing Assist.
Zendesk        Healthy   8        read/write tickets  1m ago      Support Copilot

Connector detail should show:

* auth/grant health
* scopes
* tenants connected
* refresh status
* recent failures
* data sources created
* tools dependent on it
* revoke/refresh controls

⸻

15.3 Approval policy builder

The policy builder should be readable, not a rules-engine dumping ground.

Example:

Policy: external_message_with_private_data
When:
  Feature is Support Copilot
  AND tool is send_email
  AND context contains private customer data
  AND recipient is external
Then:
  Pause run and require human approval
Receipt includes:
  tool args
  retrieved private-data evidence
  outgoing message preview
  decider note

Controls:

[Test policy on past runs]
[Simulate on sample trace]
[Enable]
[Disable]
[View audit]

Policy test mode

Before enabling a policy:

This policy would have matched 38 runs in the last 7 days.
- 32 likely correct
- 4 likely unnecessary
- 2 need review
[Review matched runs] [Enable anyway] [Refine policy]

This prevents approval fatigue.

⸻

15.4 Guardrails

Guardrail list:

Guardrail                     Location   Action     Triggered  False positive
PII leakage check             output     block      12         1
Prompt injection detector     context    warn       44         9
External egress policy        tool       approval   18         2
Schema validator              output     retry      103        n/a
Citation support check        output     block      27         5

Guardrail detail should show:

* purpose
* gate location
* action
* version
* thresholds
* recent triggers
* false positive/negative feedback
* linked incidents
* linked evals
* release history

⸻

15.5 Budgets

Budget screen:

Budgets
Global monthly AI budget: $500
Current spend: $341
Projected: $612
Status: At risk
Feature budgets
Support Copilot      $210 / $250  Watch
Repo Agent           $88 / $75    Exceeded
Billing Assistant    $22 / $100   OK
Controls
[Edit budget] [Set per-run cap] [Set per-tenant cap] [Trip breaker on exceed]

Budget detail should let the operator inspect:

* cost by feature
* cost by tenant
* cost by model
* cost by prompt version
* cost by tool
* cost by eval suite
* cost per successful task
* cache hit rate
* cost spikes and what changed

⸻

15.6 Circuit breakers

Breaker list:

Breaker                         Status    Trigger
support_groundedness_breaker     Closed    Opens if groundedness < 85% for 15m
repo_agent_cost_breaker          Open      Cost/run exceeded $2 three times
tool_failure_breaker             Closed    Opens on repeated connector errors

Breaker detail:

repo_agent_cost_breaker
Status: Open
Opened: 2026-07-03 13:44 EDT
Reason: 3 runs exceeded $2 max cost
Affected feature: Repo Agent
Current behavior: new runs blocked; existing runs paused
[Close breaker] [Keep open] [Open affected runs] [Adjust threshold]

⸻

16. Knowledge: RAG, sources, chunks, retrieval, citations

Knowledge can live under Governance or as a first-class top-level section. I would expose it as a major subsection because RAG debugging is central to many AI failures.

Knowledge Home

Knowledge
Sources
support_kb          Healthy   version 2026_07_01   12,401 chunks
refund_policy       Healthy   version v8           84 chunks
customer_docs       Warning   index lag 2h         92,118 chunks
Retrieval quality
Context recall: 0.88
Context precision: 0.74
Citation support: 91%
Stale doc rate: 2.1%
[Open retrieval explorer] [Inspect sources] [Reindex]

Source detail

Source: refund_policy
Version: v8
Freshness: current
Chunks: 84
Used by: Support Copilot, Billing Assistant
Permission model: tenant-filtered
Last indexed: 2026-07-03 09:12 EDT
Tabs:
Overview | Chunks | Retrieval tests | Versions | Permissions | Audit

Retrieval Explorer

This is a powerful diagnostic tool.

Query:
[ Can this customer get a refund for duplicate charge? ]
Scope:
Tenant: Acme Corp
Feature: Support Copilot
Index: support_kb_2026_07_01
Filters: policy_docs, billing
[Run retrieval test]
Results:
1. refund_policy_v8 chunk 12    score .91   cited in 84% of good answers
2. duplicate_charge_policy v3   score .86   stale warning
3. billing_terms chunk 4        score .73   relevant

Controls:

* compare index versions
* show permission-excluded docs
* mark chunk relevant/irrelevant
* create retrieval eval case
* open source chunk
* inspect citation map

Citation map

Final answer claim                         Evidence status
“Duplicate charges can be refunded”        Supported by refund_policy_v8
“Refund has already been approved”         Unsupported
“Billing team must verify first”           Supported

Unsupported claims should be visually obvious and linked to eval failures.

⸻

17. Semantic cache

Purpose

Semantic cache answers:

“When did Scoria reuse an answer, why was reuse allowed, and how do I invalidate it?”

Cache screen

Semantic cache
Hit rate: 31%
Estimated savings: $42 this month
Invalidations: 12
Risky reuse blocked: 8
Entries:
Cache key       Feature          Scope       Last used   Evidence version   Eligible
cache_123       Support Copilot  tenant      2m ago      support_kb_v8      yes
cache_124       Billing Assist.  actor       1h ago      billing_policy_v4  no: stale source

Cache entry detail

Shows:

* original run
* answer reused
* similarity threshold
* scope
* evidence used
* source versions
* invalidation dependencies
* recent hits
* allowed/blocked reason

Actions:

[Invalidate entry]
[Invalidate by source version]
[Open original run]
[Create eval case]

The important design point: cache reuse must be inspectable like a normal run, not an invisible optimization.

⸻

18. Memory & Privacy

Purpose

Memory & Privacy answers:

“What durable context exists, where did it come from, when was it used, and can I delete it?”

Memory list

Memory
Scope        Subject ref     Fact / summary                       Source run   Last used
actor        user_4821       Prefers concise support replies       run_7A2      2d ago
tenant       acme            Uses enterprise refund policy         run_6F1      1h ago
session      sess_91         Asked about duplicate billing         run_8J3      4m ago

Memory detail

Memory mem_123
Scope: actor
Subject ref: user_4821
Value: Prefers concise support replies.
Source: run_7A2
Created: 2026-06-29
Last used: 2026-07-01
PII: no
Retention: 90 days
Confidence: user-confirmed
[Edit] [Delete] [Open source run] [Show runs that used this]

Privacy controls

Retention
Raw prompts: 7 days
Redacted traces: 90 days
Eval cases: indefinite unless manually purged
Memory: 90 days
Semantic cache: 30 days
PII masking
Input messages: enabled
Tool results: enabled
Outputs: partial
Prompt variables: configurable
Right-to-erasure
[Forget actor] [Forget tenant] [Purge run] [Export receipts]

Forget actor flow

1. Enter actor reference.
2. Scoria shows affected traces, memory, cache entries, eval cases, and audit constraints.
3. Operator selects purge policy:
    * purge raw payloads
    * anonymize references
    * delete memory
    * invalidate cache
    * preserve audit receipt
4. Scoria previews irreversible impact.
5. Operator confirms.
6. Receipt generated.

⸻

19. Audit

Purpose

Audit answers:

“What consequential decisions happened?”

Audit list

Time                 Event                 Actor ref     Object       Result
2026-07-03 14:22     Approval denied        host_user_42  run_8J3      denied
2026-07-03 14:10     Prompt release blocked host_user_42  prompt_v13   blocked
2026-07-03 13:44     Breaker opened         system        breaker_9    open
2026-07-03 13:12     Tool disabled          host_user_42  issue_refund disabled

Filters:

* actor ref
* event type
* feature
* tenant
* time
* policy
* run
* prompt
* tool
* decision result

Audit detail:

Approval denied
Run: run_8J3K9
Feature: Support Copilot
Tenant: Acme Corp
Policy: external_message_with_private_data
Decision: Deny
Reason: Outgoing email included unsupported refund claim.
Before: run paused
After: run halted with denial message
Receipt ID: audit_77KQ
[Open run] [Open policy] [Copy receipt]

Audit should be immutable-feeling, plain, and exportable.

⸻

20. Complete user journeys

Journey A: Something broke; find and understand it

Scenario

Support Copilot quality dropped after a prompt change.

Flow

Home
→ Attention stack: “Groundedness dropped in Support Copilot”
→ Incident detail
→ Affected segment: refund_duplicate_charge
→ Representative failed run
→ Run Workbench
→ Retrieval/citation span
→ Prompt diff linked in inspector
→ Root cause marked
→ Rollback prompt
→ Create eval cases
→ Resolve incident

Screen-by-screen

1. Home
    * Shows warning: “Groundedness down 6.4%.”
    * CTA: Triage incident.
2. Incident detail
    * Shows metric threshold, affected feature, start time, suspected change.
    * CTA: Open affected runs.
3. Run Explorer filtered to incident
    * Shows failed runs with same prompt version.
    * Operator opens representative run.
4. Run Workbench
    * Story spine highlights retrieval and final answer.
    * Citation map shows unsupported refund claim.
    * Inspector says: “Likely prompt regression; prompt v13 softened refund constraint.”
5. Prompt diff
    * Shows active vs draft/released version.
    * Regression cases linked.
6. Mitigation
    * Operator clicks Rollback to v12.
    * Receipt generated.
7. Improvement
    * Operator promotes 5 failed runs to regression dataset.
    * Incident marked resolved.

Exit state

* Prompt rolled back.
* Incident resolved.
* Regression cases added.
* Audit receipt exists.
* Home returns to warning/healthy once metrics recover.

⸻

Journey B: Approval is blocking a user

Scenario

The assistant wants to send a customer-facing email using private billing data.

Flow

Home / Queue
→ Approval detail
→ Preview consequence
→ Inspect evidence
→ Open exact tool span if needed
→ Approve / deny / request edit
→ Receipt
→ Run resumes or halts

Key decisions

* Is the recipient correct?
* Is the outgoing content supported?
* Is private data exposed?
* Is this action reversible?
* Is approval one-time or should policy change?

Ideal interaction

The operator should be able to decide most approvals from the approval screen in under 30 seconds, but the full trace should be one click away.

⸻

Journey C: Prompt change needs verifying before release

Scenario

The operator edits support_reply prompt.

Flow

Releases
→ Prompt draft v13
→ Diff
→ Required eval suites
→ Run eval
→ Compare candidate vs baseline
→ Inspect failures
→ Approve canary / reject / edit
→ Canary monitor
→ Full release or rollback

Important UI details

* The diff should summarize behavioral risk.
* Eval results should show aggregate and segment-level deltas.
* Failures should be inspectable as cases, not just numbers.
* Release approval should produce a receipt.
* Canary should appear on Home and Feature Cockpit.

⸻

Journey D: Bill spiked; find why

Scenario

Repo Agent spend is 88% above baseline.

Flow

Home cost card
→ Cost detail
→ Top cost contributors
→ Run Explorer filtered to high-cost repo_agent runs
→ Run Workbench
→ Agent loop shows repeated test failures
→ Budget/breaker detail
→ Adjust max steps or trip breaker
→ Create eval/guardrail case

Cost detail should show

* cost by feature
* cost by model
* cost by tenant
* cost by prompt version
* cost by tool
* cost per run
* cost per successful task
* outlier runs
* loop-limit hits
* cache miss spikes

Diagnosis example

Cost spike likely caused by repo_agent_v2 repeatedly running tests after failed edits.
12 runs hit step 20 limit.
Average cost/run rose from $0.38 to $1.92.

Actions

* Lower max step limit
* Add breaker threshold
* Disable feature temporarily
* Branch/replay a high-cost run
* Create regression eval for loop behavior

⸻

Journey E: Quality regressed; diagnose component

Scenario

RAG answer quality worsened.

Flow

Quality
→ Feature quality card
→ Eval run detail
→ Segment breakdown
→ Failed case
→ Trace Workbench
→ Determine retrieval vs generation failure
→ Fix source/index/prompt
→ Re-run eval

Critical UI behavior

The failed case should immediately classify possible failure type:

Likely component: retrieval
Reason: expected source document was not retrieved in top 10.

or:

Likely component: generation
Reason: correct source was retrieved and included, but answer contradicted it.

⸻

Journey F: Recover a failed run

Scenario

A long-running agent failed at step 14 after a connector timeout.

Flow

Queue: stalled run
→ Run Workbench
→ Error span
→ Branch from checkpoint before failed tool
→ Retry with connector healthy / mock / alternate model
→ Compare branch to original
→ Resume original or finalize branch

Recovery UI

Recover run
Failure point:
Step 14 — tool call: create_pr_draft
Error: connector timeout
Recovery options:
[Resume from step 14]
[Branch from step 13]
[Replay whole run]
[Cancel run]
[Create incident]

Branch comparison

Original run                         Branch run
Failed at create_pr_draft             Completed
Cost $1.42                            Cost $0.18 additional
Steps 14                              Steps 4 from checkpoint
Eval goal_completion: fail            pass

⸻

Journey G: Govern a dangerous tool combination

Scenario

The operator realizes the AI has private data access, untrusted content, and external egress.

Flow

Governance
→ Tools & blast radius
→ send_email tool
→ Risk combination warning
→ Approval policy builder
→ Test on past runs
→ Enable policy
→ Audit receipt

Key UI insight

Scoria should not just say “high risk.” It should show why:

This tool can send external messages.
This feature also retrieves untrusted customer-uploaded documents.
This feature can access private billing records.
Together, this creates an exfiltration path.

⸻

Journey H: Privacy erasure request

Scenario

A customer requests deletion of AI trace data and memory.

Flow

Data & Privacy
→ Forget actor
→ Enter actor ref
→ Impact preview
→ Select purge/anonymize options
→ Confirm
→ Receipt

Impact preview

Affected records
Raw traces: 42
Redacted traces: 42
Memory entries: 3
Semantic cache entries: 7
Eval cases: 1
Audit receipts: preserved with anonymized actor ref

⸻

21. Screen-by-screen breakdown

Home

Purpose: Orient and route attention.

Primary content: system state, blocking queue, incidents, cost, feature health.

Controls: scope bar, time range, live pause, open queue, triage, investigate cost, open feature.

States:

* Empty: no runs recorded; show instrumentation checklist.
* Healthy: no urgent items; suggest review samples.
* Warning: quality/cost/risk changes.
* Critical: approvals/incidents/breakers.
* Dense: group by feature and severity; collapse secondary metrics.
* Live updating: append updates with “new updates” pill.

⸻

Queue

Purpose: One human work inbox.

Primary content: decision cards.

Controls: category tabs, severity filter, sort by urgency, open drawer, claim/resolve, bulk low-risk actions.

States:

* Empty: “No human decisions pending.”
* Overloaded: grouped by type and severity.
* Error: queue could not load; show last known count.
* Live: new item badge without jumping list.

⸻

Feature Cockpit

Purpose: Operate one AI feature.

Primary content: health, active versions, architecture map, pending work, quality/cost/risk.

Controls: run evals, open runs, rollback, edit policies, inspect access, open live view.

States:

* New feature: no runs yet, show expected instrumentation.
* Healthy: stable trends.
* Degraded: root-cause cards.
* Canary: compare active/candidate.
* Disabled: explain why and how to re-enable.

⸻

Live Runs

Purpose: Watch active executions.

Primary content: running/paused/failing run cards.

Controls: pause updates, group by feature, filter risky, stop run, review approval, open trace.

States:

* Quiet: no active runs.
* Busy: group and virtualize rows.
* High-risk: risky runs pinned.
* Connection issue: show stale timestamp and reconnect status.

⸻

Run Explorer

Purpose: Find runs.

Primary content: searchable/filterable table.

Controls: structured search, saved views, export visible IDs, open trace, compare selected runs.

States:

* No results: suggest relaxing filters.
* Huge results: require time/feature scope refinement.
* Partial retention: warn that raw payloads expired.

⸻

Run Workbench

Purpose: Forensic reconstruction and action.

Primary content: story spine, evidence canvas, inspector.

Controls: span selection, branch, replay, resume, approve/deny, create eval case, mark root cause, raw mode.

States:

* Live running: current span updates.
* Paused: approval/recovery action pinned.
* Failed: error span pinned.
* Replayed: compare mode available.
* Redacted: show what is missing and why.
* Low-agency: compact trace.
* High-agency: nested loop/swimlane trace.

⸻

Incident Detail

Purpose: Triage and mitigate.

Primary content: what happened, impact, timeline, suspected change, linked runs.

Controls: acknowledge, rollback, pause feature, open affected runs, create eval cases, resolve.

States:

* Active: mitigation controls visible.
* Mitigated: monitor recovery.
* Resolved: follow-up checklist.
* No linked runs: explain threshold source.

⸻

Quality Home

Purpose: Quality posture across features.

Primary content: eval pass rates, online scores, review queue, dataset coverage.

Controls: run evals, open failures, review samples, open datasets.

States:

* No evals: setup path from traces.
* Stable: trend cards.
* Regression: failing segments pinned.
* Judge drift: calibration warning.

⸻

Eval Run Detail

Purpose: Compare candidate vs baseline.

Primary content: pass/fail, segment deltas, failed cases.

Controls: inspect case, approve/reject release, export results, create dataset cases.

States:

* Running: progress by suite/scorer.
* Passed: release CTA.
* Failed: blocker reasons.
* Inconclusive: missing labels or scorer errors.

⸻

Dataset Detail

Purpose: Maintain regression corpus.

Primary content: cases, tags, origin, risk, expected behavior.

Controls: add case, import from runs, label, split, archive, version dataset.

States:

* Empty: seed from production traces.
* Imbalanced: coverage warnings.
* Deprecated: version warning.
* Privacy-restricted: redacted fields shown.

⸻

Review Queue

Purpose: Human labels and improvement loop.

Primary content: sampled cases with trace/evidence/rubric.

Controls: label, adjudicate, promote to dataset, mark false positive, assign root cause.

States:

* No pending reviews.
* Calibration mode.
* Disagreement mode.
* High-risk-only mode.

⸻

Releases Home

Purpose: Manage behavior changes.

Primary content: drafts, canaries, blocked gates, recent ships, rollback-ready versions.

Controls: open draft, run eval, approve, reject, rollback.

States:

* No drafts.
* Eval running.
* Blocked.
* Canary active.
* Rollback in progress.

⸻

Prompt Detail

Purpose: Inspect and release prompt versions.

Primary content: active/draft, diff, rendered examples, eval results.

Controls: edit draft, run evals, compare, approve, rollback, lock.

States:

* Draft unsaved.
* Draft awaiting eval.
* Eval blocked.
* Approved.
* Active.
* Deprecated.

⸻

Governance Home

Purpose: Risk posture.

Primary content: high-risk tools, active policies, breakers, budgets, connector health.

Controls: open tool, edit policy, disable, test policy, trip breaker.

States:

* Safe baseline.
* Risk warnings.
* Breaker open.
* Connector degraded.
* Policy simulation mode.

⸻

Tool Detail

Purpose: Understand and control blast radius.

Primary content: schema, side effects, access, policy, recent calls.

Controls: enable/disable, edit approval policy, test on past runs, inspect calls.

States:

* Enabled.
* Disabled.
* Approval required.
* Unhealthy.
* Deprecated schema.

⸻

Knowledge Source Detail

Purpose: Inspect RAG evidence.

Primary content: source version, chunks, retrieval quality, permissions.

Controls: reindex, disable source, test retrieval, compare versions, purge.

States:

* Healthy.
* Indexing.
* Stale.
* Permission mismatch.
* Retrieval regression.

⸻

Data & Privacy

Purpose: Manage retention, memory, cache, purge.

Primary content: retention settings, memory entries, purge tasks, PII masking.

Controls: forget actor, purge run, invalidate cache, edit retention, export receipts.

States:

* Normal.
* Purge preview.
* Purge running.
* Retention conflict.
* Raw data expired.

⸻

Audit

Purpose: Immutable decision ledger.

Primary content: chronological receipts.

Controls: filter, open object, copy receipt, export.

States:

* Empty.
* Filtered no results.
* Redacted actor refs.
* Export complete.

⸻

22. Visual and graphic design direction

Overall feel

Scoria should feel:

* calm
* technical
* evidence-rich
* restrained
* fast
* operational
* trustworthy

Not “AI magic.” Not “enterprise BI.” Not “logs in a prettier table.”

The visual metaphor should be:

a dark control room with inspectable layers of evidence.

The volcanic scoria motif can appear subtly as texture and geometry: porous nodes, layered rock strata, glowing fault lines for live/risky paths. But it should never overpower legibility.

Theme

Dark default

Use dark mode as the primary operator theme.

Suggested palette roles:

Background: deep graphite / basalt
Panels: slightly raised charcoal
Borders: low-contrast ash lines
Primary text: warm off-white
Secondary text: slate gray
Muted metadata: dim blue-gray
Live activity: cool accent
Warnings: amber
Danger/blocking: red/orange
Success: green
Info/evidence: blue
Human decision: purple or amber

Never encode status by color alone. Pair color with label, icon, and shape.

Light mode

Light mode should not be an afterthought.

Use:

* white/near-white background
* gray panel boundaries
* saturated but sparing status accents
* same semantic icons and shapes

Typography

Use two typefaces or two roles:

UI sans

For labels, headings, summaries, cards, navigation.

Needs:

* high legibility
* good numerals
* compact but not cramped

Monospace

For:

* run IDs
* trace IDs
* prompt hashes
* JSON
* model names
* tool names
* token/cost tables

Use tabular numerals for metrics.

Density strategy

Scoria should be dense by default, but not noisy.

The rule:

Decision surfaces: spacious.
Forensic surfaces: dense.
Tables: compact.
Danger confirmations: spacious and explicit.
Raw payloads: dense but collapsible.

Status system

Define a small stable status vocabulary.

OK
Watching
Needs review
Paused
Blocked
Failed
Recovering
Canary
Disabled
Resolved

Use consistent chips:

[OK]
[Needs review]
[Paused: approval]
[Blocked: breaker]
[Failed]
[Canary]

Severity system

Info
Low
Medium
High
Critical

For high/critical, show why, not only the label.

Icon system for span kinds

Input          arrow-in
Prompt         document
LLM call       spark / model
Retrieval      magnifier / books
Tool call      wrench / plug
Guardrail      shield
Approval       hand / stamp
Eval           check-circle / ruler
Memory         archive / brain-lite
Cache          lightning / stack
Error          triangle
Agent step     loop node
Handoff        branching arrow

Trace visualization

The trace should be visually memorable.

Recommended motif:

Story spine with vesicles.

Each span is a porous node in a vertical basalt-like spine. The “holes” can encode internal structure:

* filled small dot = evidence present
* hollow dot = redacted
* ring = human decision
* split ring = branch/replay
* glowing rim = live
* broken rim = error

This nods to scoria rock without turning the interface into decoration.

Layout system

Desktop-first.

Minimum ideal width: 1280px.

Primary layouts:

Control room

Left nav 240px
Main content flexible
Right drawer 420px optional

Workbench

Left story spine: 280–340px
Center evidence canvas: flexible
Right inspector: 340–420px

Tables

Use sticky headers, column customization, saved views, and row expansion.

Motion

Motion should be operational, not playful.

Use:

* subtle pulse for live runs
* fade-in for new queue items
* animated trace progress for active spans
* no constant shimmer
* no large animated backgrounds
* no auto-scrolling unless explicitly in tail mode

Accessibility

* Keyboard navigation for queues and traces.
* Clear focus states.
* Status labels in text.
* High contrast.
* Raw JSON copy buttons.
* Timestamps with timezone.
* No hover-only critical information.
* Confirmation actions reachable but protected.

⸻

23. Content design

Scoria’s copy should be plain and operator-grade.

Bad

Risk detected.

Better

Approval required because this run wants to send private billing data to an external recipient.

Bad

Eval failed.

Better

Blocked: candidate prompt regressed refund-policy cases by 12 percentage points.

Bad

Tool call pending.

Better

Run paused before calling send_email. No external message has been sent.

Every risky screen should clearly distinguish:

* proposed action
* completed action
* blocked action
* approved action
* denied action

This matters emotionally. The operator needs to know whether damage has happened or was prevented.

⸻

24. “Day in the life” narrative

A solo founder-engineer opens Scoria at 9:07 AM.

Home says the system is mostly healthy, but there are two attention items: one approval blocking a customer reply, and a cost spike in the repo agent.

They open Queue. The approval card says the Support Copilot wants to send an external email that includes private billing history. The approval screen shows the outgoing message, the retrieved policy, the payment lookup, and the guardrail that escalated. The message contains an unsupported sentence: “Your refund has been approved.” The operator clicks Deny, chooses “unsupported claim,” adds a note, and the run halts with a receipt.

Because that denial reveals a broader problem, they click Create eval case from this run. Scoria pre-fills the case: duplicate charge, expected behavior, forbidden refund promise, linked policy evidence. They add it to the refund regression dataset.

Back on Home, the cost card shows Repo Agent is 88% over baseline. They open Cost, then filter Run Explorer to high-cost repo_agent runs. Run Workbench shows repeated loops: edit file, run tests, fail, edit file, run tests, fail. The run hit the step limit. They branch from the checkpoint, switch to a cheaper model for repair steps, and replay. The branch passes tests in four steps. They update the agent policy: max 12 steps before asking for help, and trip a breaker after three runs above $1.50.

Later, they review a prompt draft. Releases shows support_reply_v13 blocked. The diff warns that the draft softened a refund constraint. Eval comparison shows regressions in duplicate-charge cases. They reject the release, link the morning’s failed run as a regression case, and keep v12 active.

At the end of the session, Home says: no active incidents, no blocking approvals, cost breaker enabled, prompt release blocked, new eval case added. The operator leaves with confidence because every action left a receipt.

That is the target emotional arc: from anxious uncertainty to grounded control.

⸻

25. The most important product decisions

1. Make Queue the operator’s inbox

Do not force the n=1 operator to check approvals, incidents, review samples, release gates, and privacy tasks separately.

2. Make Run Workbench the center of gravity

Everything should eventually lead to the run trace. If Scoria can reconstruct it, the UI should let the operator understand it.

3. Make Feature Cockpit the main grouping object

A run belongs to a feature. A prompt belongs to a feature. Evals, tools, policies, budgets, memory, and sources all become easier to reason about at feature scope.

4. Treat approvals as first-class blocking moments

Approvals are not notifications. They are inline gates that stop real actions. The UI should treat them like consequential decisions.

5. Treat releases as behavior changes, not just prompt edits

Prompts, models, tool schemas, context builders, knowledge indexes, memory policies, safety policies, and judge versions can all change behavior.

6. Make eval failures inspectable as stories

A failed eval should not be just a red number. It should be a case with input, expected behavior, actual output, scores, evidence, and linked trace.

7. Make blast radius visible

For every tool and connector, show what it can read, what it can write, whether it can communicate externally, whether it touches untrusted content, and whether approval is required.

8. Make privacy controls operational

Retention, redaction, memory, semantic cache, and purge should be inspectable operator workflows, not hidden config.

⸻

26. Condensed LLM-context version

SCORIA_IDEAL_OPERATOR_UI
North star:
Scoria is an embedded AI-ops control room for a solo engineer running AI features inside a Phoenix app. The dashboard should help one person orient, act, investigate, recover, improve, govern, and audit AI behavior.
Primary IA:
Home
Queue
Features
Runs
Quality
Releases
Governance
Data & Privacy
Audit
Settings
Core shell:
Persistent top scope bar:
- environment
- tenant
- feature
- time range
- live updates
- global search
- command palette
- queue/incident counts
Key concept:
Introduce “AI Feature” as the operator-facing grouping for runs, prompts, evals, tools, knowledge, memory, budgets, and policies. Each feature has a Feature Cockpit.
Home:
Attention router, not BI dashboard.
Show:
- overall health
- pending approvals
- active incidents
- cost/budget anomalies
- feature health grid
- live activity
- recent regressions
Primary CTA always routes to what needs action.
Queue:
One inbox for all human work:
- approvals
- incidents
- review cases
- release gates
- stalled runs
- privacy tasks
Rank by impact, risk, age, blocking status.
High-risk actions require single-item decisions; no bulk approval.
Approvals:
Screen must answer:
- what happens if approved
- who/what is affected
- what data is involved
- why approval is required
- what evidence supports it
- what happens if denied
Actions:
Approve once, deny, request edit, halt feature, open run.
Always create audit receipt.
Runs:
Two modes:
- Live runs
- Run history/search
Run Explorer supports filters by feature, tenant, actor, status, prompt, model, tool, guardrail, eval, cost, latency, feedback.
Run Workbench:
Most important screen.
Three-pane layout:
- left story spine / trace timeline
- center evidence canvas
- right diagnostic inspector
Span-specific views:
- prompt
- LLM call
- retrieval
- tool
- guardrail
- eval
- error
- agent step
- handoff
Actions:
resume, branch, replay, compare, approve/deny, create eval case, mark root cause, copy IDs.
Pattern-adaptive trace:
Single-call = compact input/prompt/output.
Workflow = pipeline with gates.
RAG = retrieval + citation map.
Router = branch decision.
Tool assistant = tool selection/args/auth/result.
Agent = loop with budget/stop behavior.
Multi-agent = swimlanes and handoffs.
Eval views should match architecture shape.
Quality:
Surfaces eval suites, datasets, eval runs, review queue, online scores, regression cases.
Failed eval cases show:
input, expected behavior, actual output, scores, source evidence, linked trace, root cause.
Main loop:
bad run → triage → root cause → eval case → fix → release gate → monitor.
Releases:
Treat prompts, models, tool schemas, context builders, indexes, memory policies, guardrails, judges, and datasets as behavior-affecting release artifacts.
Prompt detail includes:
versions, diff, rendered examples, eval comparison, release gate, canary, rollback, audit.
Governance:
First-class section for:
tools, connectors, approval policies, guardrails, budgets, circuit breakers.
Tools show blast radius:
private data, untrusted content, external egress, side effects, irreversibility, approval required.
Policy builder is readable:
When X and Y, then pause/block/approve.
Can test policies on past runs before enabling.
Knowledge:
Sources, chunks, retrieval explorer, citation map, source versions, permission filters, freshness, reindexing.
RAG debugging separates retrieval failure from generation failure.
Semantic cache:
Inspectable cache entries with original run, reused answer, evidence versions, scope, eligibility, invalidation.
Memory & Privacy:
Memory is scoped, sourced, inspectable, deletable.
Privacy screen controls retention, PII masking, purge, forget actor/tenant, cache invalidation, audit receipts.
Audit:
Immutable ledger of approvals, denials, releases, rollbacks, breaker changes, policy changes, purge events.
Visual direction:
Dark-default technical control room.
Calm basalt/graphite base, sparse status accents.
Evidence-rich, not magical.
Decision surfaces spacious; forensic surfaces dense.
Use plain-language summaries with raw JSON one click away.
Status must use text + icon + color, never color alone.
Subtle scoria motif: trace spine as porous volcanic structure.