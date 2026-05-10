Research brief: Phoenix-native AI agents + MCP + evals + ops

0. Core recommendation

The best gap to fill is not “another Elixir LLM client” and not simply “Strands for Elixir.” Elixir already has credible pieces: LangChain for Elixir, Jido, ReqLLM, LLMDB, AshAI, MCP SDKs, Tribunal, Aludel, AgentObs, Instructor-style structured output, and smaller specialized libraries. The opportunity is to build the missing Phoenix-native AI application quality layer:

A batteries-included AI runtime + evaluation + observability + admin UI layer for Phoenix apps, with MCP/agent workflows built in, designed around production debugging, regression prevention, trace replay, prompt/version management, cost/latency/SLOs, tool governance, and great LiveView operator UX.

That library should feel like Oban Web + Phoenix LiveDashboard + LangSmith/Braintrust/Langfuse/Phoenix + lightweight agent runtime + MCP gateway, but idiomatic to Elixir/Phoenix/Ecto/Plug. It should compose with the ecosystem rather than replacing every piece.

The concrete product thesis:

For Phoenix teams building AI chat, copilots, RAG, tool-using agents, or MCP-enabled workflows,
this library gives them a sane default runtime, trace/eval store, prompt registry, dashboards,
CI gates, and production debugging tools — all installable in minutes and extensible in layers.

The strategic wedge is AI quality and operations for Phoenix, not “agent framework” alone. Agent libraries are abundant; observable/evaluable agent operations with embedded Phoenix UI is the stronger gap.

⸻

1. Current Elixir/Phoenix landscape, as of May 2026

The ecosystem has moved fast. There are enough mature pieces now that the winning library should compose, normalize, instrument, and operationalize rather than trying to own every primitive.

Area	Existing Elixir/Phoenix options	What they already do well	Gap your library can fill
LLM abstraction / chains	LangChain for Elixir supports many providers including Anthropic, OpenAI, Gemini/Vertex, Ollama, Mistral, Perplexity, Bedrock via Mantle, Bumblebee, ReqLLM, and others; it explicitly says it is not chasing full parity with Python/JS LangChain.  ￼	Provider coverage, chains, tool/function calling, structured conversations.	Production ops/evals/admin UI; Phoenix-native trace replay; dataset-to-CI workflows; opinionated app integration.
OTP-native agents	Jido positions itself as an autonomous agent framework for Elixir workflows and multi-agent systems. Its v2 design emphasizes simpler APIs, agents as data, pure functional decisions, directives for side effects, and testability without network/db/LLM.  ￼	BEAM-native agent thinking: supervision, multi-agent workflows, data-first architecture, testable decision logic.	Make Jido-style agents observable/evaluable in Phoenix; provide “simple chat first” DX and an admin/control plane.
Unified provider client	ReqLLM standardizes LLM requests/responses across providers, offers high-level functions such as text/object generation and streaming, and normalizes conversations, tool calls, streaming chunks, and responses.  ￼	Excellent substrate for provider abstraction, streaming normalization, tool-call normalization.	Don’t reinvent this; wrap/adapt it and add app-level quality/runtime/eval/UI.
Model metadata	LLMDB provides fast, zero-network, capability-aware LLM model metadata, backed by :persistent_term, including token limits, pricing, capabilities, modalities, and lifecycle status.  ￼	Model catalog, cost/capability lookup, router support.	Use it for model pickers, budget estimates, model routing, and eval comparison UI.
Ash integration / MCP	AshAI can generate MCP setup, expose Ash resources/actions via MCP, includes router/server pieces, supports structured prompt actions, vectorization, and embedding model behavior.  ￼	Great for Ash apps exposing typed domain actions/resources as MCP tools.	Support AshAI as an adapter, but keep the core non-Ash and Phoenix/Pure Elixir friendly.
Prompt/eval workbench	Aludel is an embeddable Phoenix LiveView dashboard for evaluating and comparing prompts across providers, with prompt versions, assertions, costs, latency/token metrics, streaming execution, visual test cases, documents, and embedded/standalone modes.  ￼	Prompt lab, provider comparison, assertion-based prompt evals, LiveView UI.	Decide whether to integrate, partner, or differentiate by focusing on production traces, conversations, agent/tool spans, online evals, CI gates, and ops dashboards.
Eval testing	Tribunal is an LLM evaluation framework for Elixir with ExUnit test mode, evaluation mode, deterministic assertions, LLM-as-judge metrics, dataset-driven evals, red-team/adversarial prompts, and CI-oriented thresholds.  ￼	CI/test-oriented eval primitives.	Add persistent datasets, UI, experiment comparison, production trace promotion, dashboards, and potentially use Tribunal as a backend/scorer adapter.
Agent observability	AgentObs tracks agent loops, tool calls, LLM requests, prompts, token/cost metadata, and translates :telemetry to OpenTelemetry spans with OpenInference conventions.  ￼	Good span vocabulary and OTel/OpenInference path.	Add local Ecto trace store, LiveView trace explorer, replay, annotations, eval linkage, and Parapet integration.
MCP SDKs	The Elixir ecosystem has MCP pieces such as Hermes, Anubis, EMCP, and LangChain MCP integrations. Search results show Hermes as a complete MCP SDK, Anubis as a comprehensive SDK, EMCP for Phoenix/Ash tool/resource/prompt exposure, and langchain_mcp for using MCP servers as LangChain tool providers.  ￼	Protocol-level client/server functionality.	Build Phoenix-native MCP gateway/admin/control-plane: registry, policy, auth, audit, test console, tool approval, trace/eval integration.
Structured output	Instructor-style Elixir libraries emphasize Ecto changesets/validation for structured outputs and retry/correction loops.  ￼	Idiomatic validation, schema-driven extraction.	Treat structured output as first-class in evals, tool args, prompt contracts, and dashboards.

The gap: Elixir has components, but not yet a cohesive “AI app ops kit” for Phoenix that makes the full loop easy: run chat/agents, stream UI, trace every step, inspect/debug, collect feedback, promote traces to datasets, run evals in CI, compare prompts/models, govern MCP tools, and alert on cost/quality regressions.

⸻

2. Positioning: what this library should be

A strong positioning statement:

Phoenix AI Ops: a Phoenix-native, batteries-included framework for building, observing, evaluating, debugging, and governing LLM chat, agents, tools, and MCP workflows.

Avoid making it sound like a generic “LLM SDK.” Better names aside, the category should be:

AI runtime + eval workbench + trace explorer + MCP/agent control plane for Phoenix.

This fits your broader “SaaS in a box” ecosystem. Your Hex profile already shows a pattern of Phoenix-adjacent, operator-friendly, batteries-included packages: billing/admin UI, transactional email/admin UI, auth, OAuth/OIDC, search, audit/eventing, rendering/export, locking, notifications, etc.  ￼

This new library can become the AI layer in that ecosystem:

Existing / planned lib	Integration idea
sigra	Admin auth, MFA/passkeys, actor context, RBAC for AI ops UI.
threadline	Audit log for prompts, eval changes, tool invocations, approvals, MCP access.
accrue / accrue_admin	Attribute LLM spend to tenants, products, features, customers, plans.
mailglass / chimeway	Notifications for eval regressions, budget overruns, tool failures, quality alerts.
scrypath	Search over traces, prompts, transcripts, eval failures, datasets.
rendro	Export eval reports, incident postmortems, prompt scorecards.
lockspire	OAuth/OIDC substrate for MCP auth once MCP auth matures.
parapet	Optional deeper SRE layer: SLOs, alerts, dashboards, cost/error budgets, incident workflows.

The library should still stand alone: local Ecto store, own LiveView UI, own telemetry events, own CI tasks. Parapet should be an optional premium-quality integration, not a hard dependency.

⸻

3. Lessons from other ecosystems

OpenAI Agents SDK

OpenAI’s Agents SDK is useful as a design reference because it keeps the primitive set small: agents, handoffs/agents-as-tools, guardrails, tracing, sessions, tools, MCP integration, human-in-loop, and a managed agent loop. It explicitly distinguishes direct API usage from SDK usage: use the lower-level API when you want to own loop/state, and the SDK when the runtime should manage turns, tool execution, guardrails, handoffs, or sessions.  ￼

Lesson for Elixir: don’t introduce 40 abstractions. Use a small vocabulary:

Agent
Run
Step
Message
Tool
ToolCall
Guardrail
Handoff
Session
Trace
Span
Eval
Dataset
Score

The SDK’s built-in tracing captures LLM generations, tool calls, handoffs, guardrails, and custom events, then lets users debug and monitor workflows.  ￼ That is exactly the kind of default your library should have from day zero.

Strands

Strands emphasizes production-ready agents, model-provider abstraction, optional providers, and embedded observability. Its provider docs describe a unified interface that lets developers switch between model providers, and its observability docs say observability APIs are embedded directly in the SDK.  ￼

Lesson for Elixir: make model/provider switching and observability boring. The user should not need to remember to instrument the agent. Every run should trace itself by default.

FastMCP

FastMCP succeeds because it makes MCP feel like normal code: declare a function/tool, generate schema/validation/docs, handle protocol lifecycle/transport/auth for the user. Its docs emphasize going from prototype to production, exposing tools/resources/prompts, connecting clients, and generating schema/validation/documentation from functions.  ￼

Lesson for Elixir: your MCP layer should feel like Phoenix routes/controllers/components, not protocol plumbing.

Example direction:

defmodule MyApp.AI.Tools.RefundCustomer do
  use MyAI.Tool,
    name: "refund_customer",
    description: "Issue a customer refund after policy checks."
  schema do
    field :customer_id, :string, required: true
    field :amount_cents, :integer, required: true
    field :reason, :string, required: true
  end
  policy do
    require_approval amount_cents: {:>, 5_000}
    audit true
    rate_limit per: :tenant, limit: 20, window: :hour
  end
  def call(args, ctx) do
    # host app logic
  end
end

LangGraph

LangGraph’s strongest production lessons are durable execution, human-in-loop, memory, and debugging visibility for complex stateful workflows. It highlights persistence through failures, inspecting/modifying agent state, short/long-term memory, execution-path visualization, state transitions, and runtime metrics.  ￼

Lesson for Elixir: BEAM supervision is great, but long agent workflows also need application-level checkpoints. Use OTP for process resilience, but persist enough run state to resume, replay, evaluate, and audit.

Braintrust / LangSmith / Langfuse / Arize Phoenix

The mature eval/observability platforms converge on a loop:

production traces → annotation/feedback → curated dataset → experiment/eval →
baseline comparison → CI gate → deploy → online scoring/monitoring → repeat

Braintrust describes systematic evals as a way to measure quality, detect regressions before users, use immutable experiment snapshots, run CI/CD gates, score online production traces, and feed production traces back into datasets.  ￼ Langfuse similarly frames evals as repeatable checks for behavior and prompt regressions, with datasets built from inputs/expected outputs and production traces.  ￼ Arize Phoenix emphasizes tracing every LLM/tool/retrieval/generation step, annotations, user reactions, LLM-as-judge, and failure-pattern analysis.  ￼

Lesson for Elixir: evals should not be a separate toy test runner. They should be wired directly into production traces, user feedback, prompt versions, model choices, and CI.

⸻

4. Product shape: the “best of all worlds” package split

You want one installable happy path, but the architecture should be decomposable.

Recommended package layout:

my_ai                  # core structs, behaviours, runtime contracts, telemetry events
my_ai_provider_req_llm # default provider adapter over ReqLLM + LLMDB
my_ai_agents           # lightweight agent loop, sessions, handoffs, tool registry
my_ai_mcp              # MCP client/server/gateway, Phoenix Plug endpoints
my_ai_eval             # datasets, scorers, experiments, CI tasks, baselines
my_ai_observe          # trace/span store, telemetry -> OTel/OpenInference, redaction
my_ai_web              # Phoenix LiveView admin/dashboard/components
my_ai_ash              # optional Ash/AshAI integration
my_ai_oban             # optional async jobs: evals, scoring, exports, ingestion
my_ai_parapet          # optional Parapet SRE/alerts/SLO integration

Public installation should still be simple:

def deps do
  [
    {:my_ai, "~> 0.1"},
    {:my_ai_web, "~> 0.1"}
  ]
end

Then:

mix my_ai.install
mix ecto.migrate

Router:

scope "/admin/ai" do
  pipe_through [:browser, :require_admin]
  live_session :ai_ops do
    MyAIWeb.Router.live_dashboard("/")
  end
end
scope "/mcp" do
  pipe_through [:api, :mcp_auth]
  forward "/", MyAI.MCP.Router
end

The key design principle: a single batteries-included distribution with small internal libraries. This avoids the “god package” trap while keeping day-zero onboarding excellent.

⸻

5. Domain model: nouns, verbs, events

This section is probably the most valuable for future LLM-assisted development. Use this as the canonical domain vocabulary.

5.1 Core conversation nouns

Noun	Meaning	Notes
Thread / Conversation	User-facing continuity container.	Maps to a support chat, copilot session, workspace conversation, etc.
Turn	One user/assistant exchange or one interaction unit.	Useful for eval granularity.
Message	Role-tagged content.	Role: system/developer/user/assistant/tool. Content can be multimodal.
ContentPart	Typed piece of message content.	Text, image, file, tool call, tool result, citation, structured object.
Participant / Actor	User, admin, system, agent, tool, external MCP client.	Important for audit and permissions.
Session	Runtime state across turns.	Distinct from persisted conversation; includes working memory/context.
ContextWindow	Rendered prompt/context actually sent to model.	Critical for debugging “why did it say that?”
UserFeedback	Explicit or implicit signal.	Thumbs, rating, correction, escalation, abandonment, retry, regenerate.

5.2 Runtime nouns

Noun	Meaning	Notes
Run	One end-to-end execution.	A chat response, agent task, eval sample, MCP tool call, etc.
Step	One unit inside a run.	LLM call, tool call, retrieval, guardrail, handoff, eval scorer.
Trace	Tree of spans for a run/workflow.	Should have trace_id, workflow_name, group_id, metadata.
Span	Timed operation inside trace.	LLM, agent, chain, tool, retriever, guardrail, evaluator, prompt, etc.
Event	Point-in-time occurrence.	Token delta, state change, approval request, retry, cancellation.
Artifact	Output attached to a run.	File, rendered prompt, JSON object, chart, generated code, report.
RunState	State machine status.	queued/running/streaming/waiting_for_approval/retrying/completed/failed/cancelled.

OpenInference is a good external semantic anchor: it standardizes AI traces on OpenTelemetry and uses span kinds such as LLM, AGENT, CHAIN, TOOL, RETRIEVER, RERANKER, EMBEDDING, GUARDRAIL, EVALUATOR, and PROMPT.  ￼

5.3 Model/provider nouns

Noun	Meaning
Provider	OpenAI, Anthropic, Google, Bedrock, Ollama, OpenRouter, local vLLM, etc.
Model	Specific provider model identifier.
ModelSpec	Normalized model metadata: context window, modalities, tool support, cost, lifecycle.
Credential	API key, OAuth token, tenant-scoped credential, local provider config.
CredentialPolicy	Who can use which model/key, in which environment, with what budget.
ModelRouter	Selects model based on task, budget, latency, quality, tenant, fallback policy.
Budget	Cost/token/time constraints.
UsageRecord	Tokens, cost, latency, provider request IDs, cache hits, retries.

5.4 Prompt nouns

Noun	Meaning
PromptTemplate	Named reusable template.
PromptVersion	Immutable version with author, commit/ref, metadata, eval status.
PromptRender	Concrete rendered prompt/context for a run.
PromptVariable	Inputs used to render a prompt.
PromptContract	Expected output shape, style, safety, citation, tool-use constraints.
PromptExperiment	A/B or offline comparison across prompt versions/models.

5.5 Tool / MCP nouns

Noun	Meaning
Tool	Host-app function exposed to an agent/model.
ToolSchema	Validated input/output schema.
ToolCall	One invocation request.
ToolResult	Result returned to model/runtime.
ToolPolicy	Allow/deny, tenant restrictions, approval rules, rate limits, side-effect class.
ToolApproval	Human approval request/decision.
MCPServer	External or internal server exposing tools/resources/prompts.
MCPClient	Client connection to an MCP server.
MCPGateway	Policy/audit/auth/registry layer between app and MCP clients/servers.
Resource	MCP-readable contextual data.
Prompt	MCP prompt template/capability.
Root	MCP client-provided filesystem/workspace boundary.
SamplingRequest	MCP server asking client/host to sample from a model.
Elicitation	MCP server asks user for more input via the client/host.

The official MCP spec defines MCP as an open protocol for connecting LLM apps with external data/tools, built on JSON-RPC, with roles for Host, Client, and Server; servers can expose resources, prompts, and tools, while clients can support sampling, roots, and elicitation.  ￼

5.6 Agent nouns

Noun	Meaning
Agent	Configured runtime entity with instructions, model policy, tools, guardrails, memory, eval suite.
AgentConfig	Immutable or versioned config.
AgentRun	Run executed by an agent.
Plan	Proposed steps before action.
Action	Intentional unit of work.
Directive	Runtime-executed side-effect instruction.
Handoff	Delegation to another agent or specialist.
Subagent	Agent used as tool/specialist.
Strategy	ReAct, plan-act, router, critic, verifier, tree/graph workflow, etc.
Checkpoint	Persisted state for resume/replay.

Jido’s v2 design note is a useful Elixir-native lesson: keep decisions pure/testable, represent agents as data, and describe side effects as directives executed by the runtime.  ￼

5.7 RAG / knowledge nouns

Noun	Meaning
Corpus	Collection of indexed material.
Document	Source file/page/item.
Chunk	Retrieval unit.
Embedding	Vector representation.
VectorIndex	Store/query engine.
Retriever	Component that fetches candidate chunks.
Reranker	Component that reorders candidates.
Citation	Link between answer claim and source evidence.
GroundingScore	Eval score for answer support.

5.8 Eval nouns

Noun	Meaning
Dataset	Versioned collection of test cases.
DatasetItem	One input/expected/metadata item.
EvalSpec	Definition of what behavior is evaluated.
EvalRun	One execution of an eval spec against model/prompt/runtime.
Trial / Sample	One dataset item execution within an eval run.
Scorer	Deterministic, heuristic, embedding, LLM-as-judge, or human scorer.
Rubric	Criteria for judgment.
Score	Numeric/categorical result plus explanation.
Annotation	Human label/comment/correction.
Baseline	Previous accepted result used for regression comparison.
RegressionGate	CI/CD threshold that fails when quality/cost/latency regresses.
RedTeamCase	Adversarial/policy/safety test case.

OpenAI’s eval guidance frames evals as describing a task, running with test inputs, analyzing results, and iterating; it also shows eval definitions with data-source config and testing criteria, and representative datasets with ground-truth labels.  ￼ Braintrust similarly defines eval anatomy around data, task, and scores, and emphasizes offline/online evals plus production trace feedback into datasets.  ￼

5.9 Verbs

generate
stream
route
render_prompt
call_model
call_tool
approve_tool
deny_tool
retrieve
rerank
cite
handoff
checkpoint
resume
cancel
retry
redact
trace
annotate
score
evaluate
compare
promote_trace_to_dataset
replay
publish_prompt
rollback_prompt
export_trace
alert
gate_release
rotate_credential

5.10 Telemetry events

Use :telemetry as the internal event bus, with an OTel/OpenInference exporter.

Suggested event names:

[:my_ai, :run, :start]
[:my_ai, :run, :stop]
[:my_ai, :run, :exception]
[:my_ai, :llm, :request, :start]
[:my_ai, :llm, :request, :stop]
[:my_ai, :llm, :request, :exception]
[:my_ai, :llm, :stream, :delta]
[:my_ai, :agent, :step, :start]
[:my_ai, :agent, :step, :stop]
[:my_ai, :agent, :handoff]
[:my_ai, :tool, :call, :start]
[:my_ai, :tool, :call, :approval_requested]
[:my_ai, :tool, :call, :approved]
[:my_ai, :tool, :call, :denied]
[:my_ai, :tool, :call, :stop]
[:my_ai, :tool, :call, :exception]
[:my_ai, :mcp, :request, :start]
[:my_ai, :mcp, :request, :stop]
[:my_ai, :mcp, :transport, :exception]
[:my_ai, :retrieval, :query, :start]
[:my_ai, :retrieval, :query, :stop]
[:my_ai, :guardrail, :check, :start]
[:my_ai, :guardrail, :check, :stop]
[:my_ai, :guardrail, :trip]
[:my_ai, :eval, :run, :start]
[:my_ai, :eval, :sample, :score]
[:my_ai, :eval, :run, :stop]
[:my_ai, :eval, :regression]
[:my_ai, :budget, :exceeded]
[:my_ai, :credential, :used]
[:my_ai, :redaction, :applied]

⸻

6. MCP transport and Phoenix architecture

MCP is important, but it should not be conflated with Phoenix LiveView transport.

The MCP spec says Streamable HTTP replaces the previous HTTP+SSE transport. The current transport uses a single endpoint supporting POST and GET, where client-to-server JSON-RPC messages are POSTed and responses can be JSON or SSE streams. The spec also warns servers to validate Origin headers, bind local servers to localhost when appropriate, and use proper authentication to avoid DNS-rebinding risks.  ￼

Recommended architecture:

Phoenix LiveView/WebSocket:
  - Your app/admin chat UI
  - Operator dashboards
  - Live trace streaming
  - Approval modals
  - Eval workbench
MCP Streamable HTTP endpoint:
  - External MCP clients/hosts
  - JSON-RPC tool/resource/prompt protocol
  - Optional SSE stream responses per MCP spec
  - Auth, Origin validation, audit, policy
Plain HTTP/SSE API:
  - Optional non-LiveView app clients
  - Browser integrations
  - Long-running public chat endpoints

Do not make LiveView the MCP protocol. Let Phoenix be excellent at the UI/control plane, while Plug/Phoenix endpoint handles MCP’s official transport.

Suggested MCP modules:

MyAI.MCP.Router
MyAI.MCP.Server
MyAI.MCP.Client
MyAI.MCP.Gateway
MyAI.MCP.Registry
MyAI.MCP.Transport.StreamableHTTP
MyAI.MCP.Transport.Stdio
MyAI.MCP.Auth
MyAI.MCP.Policy
MyAI.MCP.Audit

MCP gateway responsibilities:

Concern	Default
Authentication	API key in dev; OAuth/OIDC-ready in prod.
Origin validation	Enabled for HTTP transports.
Tool registry	Show all tools/resources/prompts, schemas, policies.
Tool test console	Call tool with sample args, see trace/span/output.
Approval	Side-effecting tools can pause for human approval.
Audit	Every external tool/resource/prompt access gets actor/client context.
Rate limits	Per tenant/client/tool.
Redaction	Apply before persistence/export.
Eval capture	MCP tool calls can become eval examples.

⸻

7. Eval strategy: build the regression flywheel

The eval layer should be the soul of this library.

7.1 Three eval modes

Mode	Purpose	Examples	Where it runs
Deterministic tests	Fast, cheap correctness checks.	JSON schema, exact match, regex, contains, citation present, no forbidden phrase.	ExUnit, CI, dashboard.
Offline evals	Compare prompt/model/runtime changes against curated datasets.	Helpfulness, groundedness, refusal correctness, tool choice accuracy, RAG answer quality.	Mix task, Oban job, dashboard experiment.
Online evals	Monitor real production interactions asynchronously.	LLM-as-judge on sampled traces, user feedback, escalation rate, cost/latency SLOs.	Background jobs, dashboards, alerts.

Braintrust’s docs explicitly distinguish offline evals on known datasets from online scoring of production traces, often with LLM-as-judge when ground truth is unavailable.  ￼ Langfuse also emphasizes datasets, experiments, and live evaluators for repeatable checks and regression detection.  ￼

7.2 The lifecycle

1. Capture traces from real chat/agent runs.
2. Collect user feedback, admin annotations, support outcomes, tool errors.
3. Promote interesting traces to dataset items.
4. Add expected output, rubric, tags, scenario, tenant/domain metadata.
5. Run prompt/model/tool/runtime experiments.
6. Compare against baseline.
7. Gate CI/CD on quality/cost/latency thresholds.
8. Deploy.
9. Continue online scoring and alerting.
10. Feed failures back into datasets.

7.3 Dataset design

Schema sketch:

datasets
  id
  name
  description
  version
  tags
  owner_id
  inserted_at
dataset_items
  id
  dataset_id
  external_id
  input              # map/jsonb
  expected           # map/jsonb
  metadata           # map/jsonb
  source_trace_id
  source_message_id
  tags
  archived_at

Dataset item fields:

%MyAI.Eval.DatasetItem{
  input: %{
    "messages" => [...],
    "tenant_plan" => "pro",
    "user_intent" => "refund_request"
  },
  expected: %{
    "must_include" => ["refund policy"],
    "tool_calls" => [%{"name" => "lookup_order"}],
    "ground_truth_answer" => "...",
    "refusal" => false
  },
  metadata: %{
    "difficulty" => "hard",
    "source" => "production_trace",
    "regression_class" => "tool_misuse",
    "persona" => "support_agent"
  }
}

7.4 Scorer taxonomy

Scorer type	Good for	Bad for	Implementation
Exact/string/regex	Classification, structured labels, formatting constraints.	Open-ended quality.	Pure Elixir.
JSON schema / Ecto changeset	Structured outputs, tool args, contracts.	Subjective quality.	Ecto/NimbleOptions/JSON Schema.
Heuristic/code	Citation count, latency, cost, tool called, field present.	Semantics.	Pure Elixir.
Embedding similarity	Semantic closeness, retrieval matching.	Precise factuality.	Provider/local embedding adapter.
LLM-as-judge	Helpfulness, groundedness, tone, policy judgment.	Bias, drift, cost, judge instability.	Versioned judge prompt/model/rubric.
Human annotation	Gold labels, calibration, high-stakes review.	Scale/cost.	Admin annotation UI.
Pairwise comparison	Prompt/model A vs B.	Absolute quality.	Judge/human preference.

7.5 LLM-as-judge guardrails

LLM-as-judge is useful, but never treat it as objective truth. Store:

judge_model
judge_provider
judge_prompt_version
rubric_version
temperature
input_hash
output_hash
score
rationale_summary
confidence

Calibrate judge scores against human labels. Use stable eval datasets and freeze baselines. Mark judge drift as a first-class risk.

Langfuse’s eval write-up calls out subjective quality, lack of one universal metric, cost/latency, judge drift, and cross-team vocabulary as common LLM-app evaluation challenges.  ￼

7.6 CI interface

Expose both ExUnit helpers and Mix tasks.

defmodule MyApp.AIEvalTest do
  use ExUnit.Case, async: true
  use MyAI.EvalCase
  eval "support refund happy path",
    agent: MyApp.Agents.Support,
    dataset: "support_refunds@v3",
    scorers: [
      MyAI.Scorers.JsonSchema,
      MyAI.Scorers.ToolCall.new(required: "lookup_order"),
      MyAI.Scorers.Judge.new(rubric: "support_helpfulness@v2")
    ],
    threshold: [
      pass_rate: 0.92,
      max_p95_latency_ms: 8_000,
      max_avg_cost_usd: 0.015
    ]
end

CLI:

mix my_ai.eval support_refunds --against prompt:support@candidate
mix my_ai.eval --changed-prompts
mix my_ai.eval --format github_annotations
mix my_ai.eval --fail-on-regression

Tribunal already demonstrates ExUnit mode, eval mode, deterministic assertions, LLM-as-judge metrics, dataset-driven evals, and CI thresholds; your best move is to interoperate where possible and add the broader persisted UI/control-plane layer.  ￼

⸻

8. Observability: trace everything, but redact aggressively

8.1 Trace tree

Every chat response, agent run, eval sample, and MCP request should produce a trace:

Trace: support_chat_response
  Span: agent.run SupportAgent
    Span: prompt.render support_triage@v12
    Span: guardrail.input pii_check
    Span: llm.request anthropic/...
      Event: stream.delta
      Event: tool_call.requested lookup_order
    Span: tool.call lookup_order
    Span: retrieval.query refund_policy
    Span: llm.request final_answer
    Span: guardrail.output citation_check
    Span: eval.online helpfulness_judge

OpenTelemetry’s GenAI semantic conventions are still marked as development status, while OpenInference offers a mature AI-observability semantic layer on top of OTel. Design your own stable internal schema and provide exporters to both.  ￼

8.2 Trace fields

Store:

trace_id
parent_trace_id
group_id / thread_id
workflow_name
actor_id
tenant_id
environment
prompt_version_ids
agent_version
model_provider
model_id
tool_names
input_preview_redacted
output_preview_redacted
usage tokens/cost
latency
status
error_class
metadata

8.3 Redaction as architecture, not a checkbox

Redaction should happen at three boundaries:

before local persistence
before external export
before LLM-as-judge/eval scoring when possible

Redaction policies:

config :my_ai, :redaction,
  mode: :default_safe,
  redact: [:api_keys, :emails, :phone_numbers, :credit_cards],
  keep: [:tenant_id, :trace_id, :tool_name, :model_id],
  raw_payload_retention: [dev: :keep, prod: {:days, 7}],
  export_raw_payloads?: false

OpenAI’s tracing docs note that tracing is unavailable for organizations under Zero Data Retention policies, which is a useful reminder that tracing/retention policy must be explicit and configurable.  ￼

⸻

9. Dashboard/admin UI

The UI is where this library can shine in Phoenix LiveView.

9.1 Core screens

Screen	Purpose
AI Ops Overview	Quality, cost, latency, volume, failure rate, eval pass rate, alerts.
Conversations	Browse/search real chats; filter by score, feedback, model, prompt, tenant, failure.
Trace Explorer	Waterfall/tree of agent/LLM/tool/retrieval/guardrail/eval spans.
Replay Playground	Re-run a trace with changed prompt/model/tools/context.
Prompt Registry	Prompt templates, versions, diffs, approvals, eval status, rollback.
Eval Workbench	Datasets, experiments, scorers, baselines, CI gates, score breakdown.
Dataset Builder	Promote production traces to dataset items; annotate expected behavior.
Model Router	Provider keys, model capabilities, costs, fallbacks, routing rules.
Tool Registry	Tool schemas, side-effect levels, approval policies, call history.
MCP Control Plane	Servers, clients, capabilities, resources, prompts, auth, audit, test console.
Guardrails	Input/output/tool policies, tripwires, violations.
Feedback Inbox	User thumbs-down, admin annotations, eval failures, support escalations.
Cost Ledger	Token/cost by tenant/user/feature/model/prompt/agent.
Incidents	Regressions, budget spikes, tool failures, drift alerts; Parapet integration.

9.2 LiveView-specific wins

Phoenix LiveView gives you a high-quality primitive for:

streaming tokens into the chat UI
live trace trees
approval modals while a run is paused
real-time eval run progress
model comparison grids
operator dashboards
tool-call inspection

Implementation recommendation:

Runtime process emits telemetry + PubSub events.
LiveView subscribes to run/trace topics.
Token deltas are coalesced to avoid excessive renders.
Trace events update a tree/waterfall incrementally.
Cancellation and approval events go back through the runtime.

9.3 Streaming footguns

Handle these from the beginning:

Footgun	Fix
Rendering every token delta	Coalesce deltas every N ms or N chars.
No cancellation	Keep cancellation tokens/process refs and provider abort support.
Tool call partial JSON	Buffer tool-call args until parseable; show “building tool call…” state.
Backpressure	Bounded queues; drop/merge low-value UI events.
Lost final usage	Ensure final provider usage/cost is recorded after stream close.
Retry ambiguity	Trace retries as child spans with attempt numbers.
LiveView reconnect	Persist run state and let UI resubscribe.

⸻

10. Shape of AI pattern catalog applied to this library

Shape of AI organizes AI UX patterns into categories such as Wayfinders, Inputs/Prompt Actions, Tuners, Governors, Trust builders, and Identifiers.  ￼ The site’s framing is especially relevant because your library is not only a backend runtime; it also needs a reusable AI UX language for Phoenix apps and admin dashboards.

10.1 Wayfinders

Shape of AI defines Wayfinders as patterns that help users construct their first prompt and get started.  ￼

Pattern	How to use in your library	Tradeoff
Example gallery	Admin/demo gallery of “good traces,” prompt examples, eval examples, sample agents.	Great onboarding; can become stale.
Follow up	Agent asks clarifying questions when input is underspecified.	Improves quality; adds latency/friction.
Initial CTA	Big “Ask AI / Run eval / Create agent” entry point.	Good day-zero UX; avoid generic blank chat as only UI.
Nudges	“Add expected output,” “turn this failed trace into dataset item,” “run regression eval.”	Helps users learn workflow; too many nudges feel noisy.
Prompt details	Show rendered prompt/context, variables, model, tools, policies.	Essential for debugging; redact sensitive data.
Randomize	Generate sample prompts/test cases/tool args.	Fun and useful for demos; not for production truth.
Suggestions	Contextual prompt suggestions and eval-scenario suggestions.	Helps blank-canvas problem; must be specific.
Templates	Prompt/eval/agent templates.	Strong DX; avoid rigid templates that block advanced cases.

10.2 Inputs / prompt actions

Shape of AI’s Inputs category covers actions users can direct AI to complete: auto-fill, inline action, regenerate, restructure, summarize, synthesize, transform, and related patterns.  ￼

Pattern	How to use in your library	Tradeoff
Auto-fill	Generate tool schema descriptions, eval rubrics, prompt variables.	Must be reviewable.
Chained action	“Summarize trace → create dataset item → run eval → open diff.”	Powerful; needs visible state.
Describe	Ask AI to explain a tool, agent, prompt, or trace.	Good onboarding; risk of hallucinating internals unless grounded in stored config.
Expand	Turn a terse eval case into detailed rubric/scenarios.	Useful for eval authoring; review needed.
Inline Action	AI actions next to messages, traces, prompts, tool calls.	Excellent LiveView fit; avoid clutter.
Inpainting	Less relevant for text dashboards; use analogous “edit this span/prompt section.”	Useful metaphor, not literal for most apps.
Madlibs	Structured prompt builders: “Given [role], answer [task], cite [sources].”	Good for non-experts; can feel limiting.
Open input	Free-form chat/playground.	Flexible; easy to misuse without guardrails.
Regenerate	Re-run response/eval sample.	Must show model/prompt/version differences.
Restructure	Convert conversation into ticket, trace into eval, output into JSON.	High utility; schema validation required.
Restyle	Tone/voice transformations for outputs/prompts.	Useful; can mask factual problems.
Summary	Summarize conversations/traces/eval failures.	Great operator UX; must link back to evidence.
Synthesis	Cluster failure patterns across traces/evals.	High-value dashboard insight; avoid overconfident conclusions.
Transform	Convert modality: transcript → ticket, trace → report, eval → GitHub annotation.	Very useful for ops/export.

10.3 Tuners

Shape of AI’s Tuners cover attachments, connectors, filters, model management, modes, parameters, styles, prompt enhancement, and voice/tone.  ￼

Pattern	How to use in your library	Tradeoff
Attachments	Attach docs/images/files to prompt/eval cases.	Needs storage, retention, redaction.
Connectors	Connect app data, MCP servers, vector stores, logs.	Huge power; auth and data boundaries matter.
Filters	Filter traces/evals by tenant, model, prompt, score, failure, tool.	Essential admin UX.
Model management	Model/provider picker with capabilities/cost/context.	Use ReqLLM/LLMDB; avoid stale manual lists.
Modes	Chat mode, eval mode, debug mode, draft mode, incognito mode.	Good UX; state must be obvious.
Parameters	Temperature, max tokens, tool choice, budget, citation requirements.	Advanced users need it; hide behind progressive disclosure.
Preset styles	Output tone presets, support personas, brand voice.	Useful for app UX; not central to ops.
Prompt enhancer	Suggest better prompts/eval rubrics.	Needs human approval.
Saved styles	Tenant/team-level tone presets.	Useful in SaaS; version them.
Voice and tone	Make prompt contracts include voice/tone constraints.	Evaluate separately from factuality.

10.4 Governors

Shape of AI defines Governors as human-in-the-loop features for oversight and agency.  ￼ This category is extremely important for agents and MCP.

Pattern	How to use in your library	Tradeoff
Action plan	Show plan before tool execution.	Reduces risk; adds latency.
Branches	Branch/replay a trace with different prompt/model/tool policy.	Great debugging; needs clean lineage.
Citations	Inline evidence for RAG/answers/eval judgments.	Critical for trust; bad citations are worse than none.
Controls	Pause, cancel, retry, edit prompt, approve/deny.	Must be reliable.
Cost estimates	Estimate cost before eval runs/agent tasks.	Estimates can be wrong; show actuals too.
Draft mode	Cheap exploratory eval/prompt runs before full production run.	Great for cost control; may hide production-only bugs.
Memory	Show/control what the AI remembers.	Essential for user trust and privacy.
References	Manage sources/files/tools used in a run.	Helps debugging and compliance.
Sample response	Preview likely output before committing.	Good for high-stakes sends/actions.
Shared vision	Live canvas showing what AI is doing.	Great for agent workflows; complex UI.
Stream of Thought	Show visible plan, tool calls, execution logs, evidence, and summaries.	Do not expose raw hidden chain-of-thought; expose auditable process summaries/tool traces instead. Shape of AI’s page recommends separating plan, execution, and evidence and using clear step states.  ￼
Variations	Compare model/prompt variants side by side.	Core eval workbench feature.
Verification	User/admin confirms AI decision/action.	Required for side-effecting tools; too much verification slows UX.

10.5 Trust builders

Shape of AI’s Trust builders include caveats, consent, data ownership, disclosure, footprints, incognito mode, and watermarking.  ￼

Pattern	How to use in your library	Tradeoff
Caveat	Show model limitations, eval confidence, missing citations.	Avoid vague boilerplate.
Consent	Explicitly ask before using user/customer data in AI workflows.	Important for B2B/compliance.
Data ownership	Tenant/user controls for trace retention, training use, export.	Must be enforced, not decorative.
Disclosure	Mark AI-generated/admin-generated content.	Required for trust.
Footprints	Trace from prompt → model → tools → sources → answer.	Core differentiator.
Incognito Mode	Run without memory/persistence or with minimal logs.	Conflicts with eval/observability; make tradeoff clear.
Watermark	Label generated artifacts/reports.	Useful for exported content, less relevant for internal traces.

10.6 Identifiers

Shape of AI’s Identifiers cover avatar, color, iconography, name, and personality.  ￼

Pattern	How to use in your library	Tradeoff
Avatar	Agent identity in chat/admin UI.	Don’t over-anthropomorphize.
Color	Consistent AI/action/status colors.	Accessibility matters.
Iconography	Icons for AI, tools, evals, traces, guardrails.	Avoid only using sparkles; be specific.
Name	Stable names for agents/tools/eval suites.	Good trace readability.
Personality	Agent tone/persona config.	Keep distinct from capability/safety.

NN/G’s AI design guidance reinforces the same product lesson: adding “AI” is not itself a value proposition, chat is not always the right interface, narrowly scoped AI features are easier to understand/adopt, and prompt assistance is important because users often do not know what the AI can do or how to ask.  ￼ Microsoft’s HAX Toolkit also frames human-AI guidelines as evidence-based best practices to apply across initial interaction, during interaction, when the AI is wrong, and over time.  ￼

⸻

11. Personas and jobs-to-be-done

Persona	Jobs-to-be-done	Library features they need
Solo SaaS founder/operator	Ship AI features quickly without building a whole eval/ops stack.	Install generator, provider config, chat runtime, dashboard, default evals, alerts.
Phoenix application developer	Add AI chat/tools/MCP to an app idiomatically.	Behaviours, Ecto schemas, Plug/Phoenix router, LiveView components, tests.
AI product engineer	Improve quality and prevent regressions.	Prompt versions, datasets, experiments, CI gates, replay, side-by-side comparison.
Support/admin operator	Debug bad chats and user complaints.	Conversation browser, trace explorer, feedback inbox, annotations, replay.
SRE/devops	Watch latency, cost, failures, token spikes, provider outages.	Telemetry, OTel/OpenInference export, SLOs, alerts, Parapet integration.
Security/compliance	Ensure data/tool access is controlled.	Redaction, retention, audit, RBAC, MCP auth, tool policies, approval logs.
Domain expert/reviewer	Label examples and judge quality.	Annotation UI, rubrics, eval queues, human review workflows.
End user	Get useful answers and maintain agency.	Citations, clarifying questions, controls, verification, memory controls.

Day-zero/day-one/day-two flows:

Day 0:
  Install, add provider key, mount dashboard, run first chat.
Day 1:
  Define first agent/tool, capture traces, create prompt version, build first dataset,
  run evals locally/CI.
Day 2:
  Monitor production, sample online traces, catch regressions, manage costs,
  audit tool usage, replay incidents, tune prompts/models, alert through Parapet.

⸻

12. Guardrails and policy

OpenAI’s Agents SDK separates input guardrails, output guardrails, and tool guardrails; it notes that blocking guardrails can prevent expensive model/tool work, while parallel guardrails can reduce latency but may allow some work to begin before cancellation.  ￼

Use that same model.

guardrails do
  input MyAI.Guardrails.PromptInjection
  input MyAI.Guardrails.PII
  tool MyAI.Guardrails.ToolArgsSchema
  tool MyAI.Guardrails.SideEffectApproval
  output MyAI.Guardrails.CitationRequired
  output MyAI.Guardrails.NoPIILeak
end

Guardrail levels:

Level	Example
Input	Prompt injection, unsafe request, off-topic, PII detection.
Retrieval	Source allowlist, tenant boundary, stale document warnings.
Tool input	Schema validation, permission check, side-effect classification.
Tool output	Redact secrets, cap output size, classify sensitivity.
Model output	Citation required, refusal correctness, no PII leak, JSON schema.
Runtime	Budget exceeded, max steps, timeout, loop detection.

Tool side-effect classes:

read_only
internal_write
external_write
financial_action
credential_action
destructive_action

Default policy:

read_only: auto-allow with audit
internal_write: allow if actor has permission
external_write: require approval in prod by default
financial/destructive/credential: require explicit policy + approval + audit

⸻

13. API design sketch

13.1 Agent definition

defmodule MyApp.AI.SupportAgent do
  use MyAI.Agent,
    name: "support_agent",
    description: "Handles customer support triage and refund questions."
  model do
    primary "anthropic:claude-sonnet"
    fallback "openai:gpt"
    max_cost_usd 0.05
    timeout 15_000
  end
  prompt :support_triage, version: :latest
  tools do
    tool MyApp.AI.Tools.LookupOrder
    tool MyApp.AI.Tools.LookupRefundPolicy
    tool MyApp.AI.Tools.CreateRefund
  end
  guardrails do
    input MyAI.Guardrails.PromptInjection
    output MyAI.Guardrails.RequireCitations, when: :uses_retrieval
    tool MyAI.Guardrails.RequireApproval, for: MyApp.AI.Tools.CreateRefund
  end
  eval_suite :support_regression
end

13.2 Running

{:ok, run} =
  MyAI.run(MyApp.AI.SupportAgent,
    input: "Can I get a refund for order A123?",
    actor: current_user,
    thread_id: thread.id,
    stream_to: self(),
    metadata: %{tenant_id: current_tenant.id}
  )

13.3 Streaming LiveView

def handle_info({MyAI.Stream, run_id, {:delta, text}}, socket) do
  {:noreply, update_stream(socket, run_id, text)}
end
def handle_info({MyAI.Stream, run_id, {:tool_call, call}}, socket) do
  {:noreply, show_tool_card(socket, run_id, call)}
end
def handle_info({MyAI.Stream, run_id, {:approval_required, approval}}, socket) do
  {:noreply, show_approval_modal(socket, approval)}
end

13.4 Tool definition

defmodule MyApp.AI.Tools.LookupOrder do
  use MyAI.Tool,
    name: "lookup_order",
    description: "Look up order details by order id.",
    side_effect: :read_only
  schema do
    field :order_id, :string, required: true
  end
  def call(%{order_id: order_id}, ctx) do
    MyApp.Orders.fetch_for_actor(order_id, ctx.actor)
  end
end

13.5 Eval definition

defmodule MyApp.AI.Evals.SupportRegression do
  use MyAI.Eval
  dataset "support_regression@v1"
  subject do
    agent MyApp.AI.SupportAgent
    prompt :support_triage, version: :candidate
  end
  scorers do
    scorer MyAI.Scorers.JsonSchema
    scorer MyAI.Scorers.ToolCallRequired, tool: "lookup_order"
    scorer MyAI.Scorers.GroundednessJudge, rubric: "grounded_support@v2"
    scorer MyAI.Scorers.Cost, max_avg_usd: 0.02
    scorer MyAI.Scorers.Latency, max_p95_ms: 8_000
  end
  gate pass_rate: 0.92,
       groundedness_avg: {:>=, 0.85},
       regression_tolerance: 0.02
end

⸻

14. Ecto schema map

Recommended tables:

ai_threads
ai_messages
ai_runs
ai_run_steps
ai_traces
ai_spans
ai_span_events
ai_artifacts
ai_prompts
ai_prompt_versions
ai_prompt_renders
ai_agents
ai_agent_versions
ai_tools
ai_tool_calls
ai_tool_approvals
ai_mcp_servers
ai_mcp_clients
ai_mcp_capabilities
ai_datasets
ai_dataset_items
ai_eval_specs
ai_eval_runs
ai_eval_samples
ai_scores
ai_annotations
ai_baselines
ai_provider_credentials
ai_model_routes
ai_usage_records
ai_budgets
ai_guardrail_checks
ai_policy_violations

Use migrations generated by mix my_ai.install, but allow host apps to opt out of persistence for lightweight usage.

Important storage decisions:

Decision	Recommendation
Raw prompts/responses	Store in dev by default; in prod store redacted by default with configurable retention.
Trace spans	Store structured metadata even when raw payloads are redacted.
Provider credentials	Encrypted, scoped, never emitted in telemetry/logs.
Datasets	Versioned and immutable-ish; allow archive/new version rather than mutation.
Prompt versions	Immutable once published.
Eval runs	Immutable snapshots of subject/config/dataset/scorers.
Artifacts	Store through app-configurable storage adapter.

⸻

15. Footguns to avoid

Footgun	Why it hurts	Recommendation
Building yet another provider client	ReqLLM/LLMDB already solve much of this.	Use them as default adapters.
Making “agent” too magical	Users cannot debug nondeterministic autonomy.	Trace every step; make plans/tools/state visible.
Treating eval as only CI tests	Production failures never become regression tests.	Build trace → dataset → eval flywheel.
LLM-as-judge without calibration	Judge drift and bias create false confidence.	Version judge prompts/models and compare with human labels.
Storing raw PII forever	Compliance and trust risk.	Redaction, retention, tenant controls by default.
Overusing chat UI	Chat is not always right.	Provide inline actions, structured forms, tool cards, dashboards.
Exposing raw chain-of-thought	Safety/privacy/IP risk.	Expose process summaries, tool traces, plans, evidence, state transitions.
Ignoring MCP auth/policy	External clients can invoke powerful tools.	Gateway, RBAC, audit, approval, Origin validation.
No cancellation/backpressure	Streaming UIs get flaky and expensive.	Cancellation tokens, bounded queues, delta coalescing.
Provider-specific leakage	App code becomes unportable.	Normalize model/tool/message/usage shapes.
No prompt versioning	Regressions become untraceable.	Immutable prompt versions tied to traces/evals.
No cost attribution	Solo operators get surprise bills.	Usage ledger by tenant/user/feature/model/prompt.
Dashboard without actions	Observability but no remediation.	Every failure should support replay, annotate, eval, rollback.

⸻

16. Roadmap

v0.1 — Observable chat runtime

Goal: first useful release.

- Provider adapter over ReqLLM
- Basic conversation/run/message structs
- Streaming chat runtime
- Telemetry events
- Ecto trace/span/message storage
- Basic LiveView dashboard: conversations, traces, costs
- Prompt templates + rendered prompt inspection
- Install generator

v0.2 — Prompt/eval workbench

- Prompt registry and immutable prompt versions
- Dataset CRUD
- Deterministic scorers
- Eval run records
- Side-by-side prompt/model comparison
- CI Mix task
- Trace → dataset item promotion

v0.3 — Production quality loop

- Online evals
- User feedback + annotation inbox
- LLM-as-judge scorers with rubric/version metadata
- Baselines/regression gates
- GitHub Actions annotations
- Alerts for eval/cost/latency regressions

v0.4 — MCP gateway

- Streamable HTTP MCP endpoint
- MCP client registry
- Tool/resource/prompt catalog
- MCP auth/policy/audit
- Tool test console
- Approval workflows

v0.5 — Agents/workflows

- Lightweight agent loop
- Handoffs/subagents
- Durable checkpoints
- Human-in-loop pause/resume
- Jido adapter/integration
- Agent graph/step visualizer

v0.6 — Parapet/SRE integration

- SLOs for quality, cost, latency, failures
- Incident workflows
- Budget alerts
- Parapet dashboard integration
- OTel/OpenInference exporter hardening

⸻

17. OSS / CI / release engineering

For an OSS Hex package intended to be trusted:

- mix format
- ExUnit
- LiveView integration tests
- property tests where useful
- Mox for provider/tool adapters
- Bypass or local fake LLM server for integration tests
- Credo
- Dialyzer
- Sobelow for Phoenix-facing package
- dependency audit
- generated docs with HexDocs
- changelog + semantic versioning
- Release Please or equivalent release automation
- GitHub Actions matrix for supported Elixir/OTP versions
- fake provider fixtures so tests do not need real API keys
- optional nightly integration tests against real providers

Also ship:

- demo Phoenix app
- AGENTS.md for AI-assisted development
- usage-rules.md for Cursor/Claude/Copilot-style agents
- architecture decision records
- “eval cookbook”
- “MCP security checklist”
- “prompt/versioning cookbook”
- “production readiness checklist”

⸻

18. The killer differentiators

The library becomes compelling if it nails these:

1. Installable in minutes: mix my_ai.install, mount dashboard, configure provider, run chat.
2. Trace-first by default: every LLM/tool/MCP/eval action is visible.
3. Eval flywheel: failed production trace becomes regression test in one click.
4. Phoenix-native UI: LiveView trace explorer, replay, prompt diff, eval dashboard, tool approvals.
5. MCP governance: not just protocol support; registry, auth, policy, audit, approval, test console.
6. Cost and quality SLOs: treat AI quality like uptime.
7. Composable with ecosystem: ReqLLM/LLMDB/Jido/AshAI/Tribunal/Aludel/AgentObs adapters instead of NIH.
8. Operator-grade DX: redaction, retention, alerts, rollback, CI gates, incident workflows.
9. Solo-founder friendly: defaults that make sense without a platform team.
10. Advanced-user escape hatches: behaviours/adapters/policies so experts can replace pieces.

⸻

19. A concise final architecture target

                           ┌────────────────────────────┐
                           │ Phoenix LiveView AI Admin   │
                           │ traces evals prompts tools  │
                           └──────────────┬─────────────┘
                                          │
┌──────────────┐     ┌────────────────────▼───────────────────┐
│ App chat UI  │────▶│ MyAI Runtime                            │
│ LiveView/API │     │ agents runs messages tools guardrails    │
└──────────────┘     └───────────────┬───────────────┬────────┘
                                     │               │
                         ┌───────────▼───────┐   ┌──▼─────────────┐
                         │ Provider Adapter  │   │ MCP Gateway     │
                         │ ReqLLM + LLMDB    │   │ Streamable HTTP │
                         └───────────┬───────┘   └──┬─────────────┘
                                     │              │
                              ┌──────▼─────┐  ┌─────▼──────┐
                              │ LLM APIs   │  │ MCP Clients │
                              └────────────┘  └────────────┘
┌────────────────────────────────────────────────────────────────┐
│ Observability / Eval Store                                      │
│ Ecto traces spans events prompts datasets eval_runs scores      │
└──────────────┬────────────────────┬────────────────────────────┘
               │                    │
      ┌────────▼────────┐   ┌───────▼─────────┐
      │ OTel/OpenInfer. │   │ Parapet optional│
      │ external export │   │ SLOs/alerts/SRE │
      └─────────────────┘   └─────────────────┘

The shortest possible “why this wins”:

Elixir/Phoenix already has LLM clients, agent frameworks, and MCP SDKs. What Phoenix developers still need is a cohesive, production-grade AI ops layer: observable by default, evaluable by default, governable by default, with a LiveView dashboard that turns real failures into regression tests and makes agents/tools/MCP understandable. That is the gap worth filling.