AI evals for productized LLM features: a practitioner research memo

This is optimized for a software engineer / product engineer building AI into a SaaS app: AI chat, suggestions, summarization, content generation, tool use, RAG over app data, UI copilots, and agents that can take actions. The central point is:

Do not treat eval as “benchmark the model.” Treat eval as the operating system for a probabilistic product feature.

A production AI eval program needs to answer five questions continuously:

1. Does the feature help the user accomplish the intended job?
2. Does it obey the product contract: accuracy, tone, format, latency, cost, permissions, and safety?
3. Which component failed when it goes wrong: prompt, retrieval, context builder, tool call, model, memory, policy, UI affordance, or user expectation?
4. Can you safely ship a prompt/model/tool/context change without regressions?
5. Can support, SRE, product, and safety teams investigate incidents from real traces without violating user privacy?

OpenAI’s eval guidance frames evals as structured tests for nondeterministic generative systems, and explicitly recommends eval-driven development, task-specific evals, logging, automation, continuous evaluation, and human-feedback alignment rather than “vibe-based” checks. It also warns against overly generic metrics, non-production-like datasets, ignoring human feedback, and one-time evals.  

⸻

1. The landscape: what “AI eval” means in a SaaS app

In classic software, you test deterministic code. In AI products, you test a probabilistic behavior surface made of prompts, model configuration, user context, retrieval, tools, memory, UI state, safety policy, and user expectations. The useful mental model is not one eval; it is a layered eval stack.

Layer	What it asks	Examples
Product outcome eval	Did the user’s job get done?	Chat resolved support question; user accepted generated draft; suggestion reduced time-to-completion; agent completed workflow.
Behavioral quality eval	Was the answer good?	Correctness, relevance, instruction-following, tone, formatting, completeness, groundedness, helpfulness.
Component eval	Which subsystem worked or failed?	Retriever found right docs; context builder included right state; tool was selected correctly; tool args were valid; output parser succeeded.
Operational eval	Can this run reliably and affordably?	Latency, cost, token usage, rate limits, model errors, retries, time to first token, tool latency, queueing, fallbacks.
Safety/security eval	Can it cause harm, leak data, or be manipulated?	Prompt injection, data exfiltration, PII leakage, unsafe content, excessive agency, untrusted tool output, memory poisoning.

This broader lens matches how current risk frameworks talk about AI systems: not just models, but the full sociotechnical system, users, environment, and deployment context. NIST’s AI Risk Management Framework is intended to improve trustworthiness across AI system design, development, use, and evaluation; NIST also released a generative AI profile to address generative-AI-specific risks.  

A key implication: academic model benchmarks are useful background, but insufficient for your app. Benchmarks such as HELM push the field toward multi-metric evaluation across accuracy, calibration, robustness, fairness, bias, toxicity, and efficiency, but your production evals still need your users, your data, your workflows, your tools, your UI states, and your failure costs.  

⸻

2. The core product contract

For every AI feature, write a product contract before writing evals.

A good contract says:

For user intent X, in context Y, the AI should produce output Z, using allowed sources/tools A, within latency/cost budget B, while avoiding harms C, and escalating to human/user confirmation when uncertainty/risk exceeds threshold D.

Example:

“When a customer support agent asks the AI chat assistant to draft a refund response, it should use the customer’s order history and the refund policy, cite the relevant policy, avoid making irreversible refund decisions itself, produce a professional draft under 150 words, and require human approval before sending.”

That contract immediately creates eval dimensions:

Contract dimension	Eval examples
Intent	Did the AI classify the request as refund-response drafting?
Context	Did it retrieve the correct order and policy?
Output	Was the draft accurate, complete, and tone-appropriate?
Tool permissions	Did it avoid issuing a refund directly?
Latency/cost	Did it return within acceptable p95 latency and token budget?
Safety	Did it avoid leaking unrelated customer data?
Escalation	Did it ask for confirmation before external action?

This is the bridge between product specs, software tests, data-science metrics, SRE dashboards, and safety review.

⸻

3. UI/UX patterns create eval surfaces

Your mention of Shape of AI is important because AI UX patterns are also eval categories. Shape of AI organizes AI product patterns into categories such as Wayfinders, Inputs, Tuners, Governors, Trust builders, and Identifiers. Its catalog includes patterns like prompt suggestions, templates, regenerate, restyle, summarize, connectors, model management, modes, citations, controls, draft mode, memory, references, verification, consent, data ownership, disclosure, incognito mode, watermarking, avatar/name/personality, and more.  

Think of each UX pattern as adding a state to your eval state machine.

UX pattern family	Product purpose	Eval implications
Wayfinders: suggestions, templates, nudges, initial CTAs	Help users know what to ask or do	Test whether suggested prompts are relevant, safe, non-misleading, role-appropriate, and actually improve task success.
Inputs/actions: summarize, transform, regenerate, inline actions, prompt actions	Convert user intent into model action	Each action needs its own contract: input constraints, expected output shape, tone, correctness, reversibility, and failure handling.
Tuners: attachments, connectors, filters, modes, model selection, parameters, style/tone controls	Let users steer context and behavior	Eval permissioning, context inclusion/exclusion, source priority, mode-specific behavior, and whether settings actually affect output as advertised.
Governors: citations, controls, action plans, draft mode, cost estimates, references, verification, variations	Preserve user agency and oversight	Eval whether the AI exposes the right uncertainty, provides sourceable claims, asks before risky actions, and supports correction.
Trust builders: caveats, consent, data ownership, disclosure, footprints, incognito, watermark	Make AI use legible and trustworthy	Eval privacy promises, retention behavior, disclosure accuracy, provenance, and whether users understand AI limitations.
Identifiers: AI avatar, name, iconography, personality	Signal “this is AI” and set expectations	Eval whether identity/personality choices create overtrust, confusion, anthropomorphism, or brand/safety issues.

For a SaaS product, “AI chat” is not one surface. It includes prompt box behavior, suggested follow-ups, retrieval, citations, tool calls, streaming, retries, regenerate, thumbs up/down, escalation, memory, permissions, and session review. Each of those needs observable events and eval cases.

One nuance: some UX catalogs include “show the model’s thinking” patterns. In production, I would usually translate that into action traces, source citations, assumptions, tool-call summaries, and verification steps, not raw chain-of-thought. Users need inspectability and control; they usually do not need unfiltered hidden reasoning.

⸻

4. Architecture patterns and what to evaluate

Anthropic’s agent guidance gives a useful distinction: workflows follow predefined code paths, while agents let the LLM dynamically direct tool use and process flow. Their practical recommendation is to start with the simplest system that works, because more agentic systems often trade extra latency and cost for task performance, and frameworks can obscure prompts/responses if adopted too early.  

OpenAI’s eval guidance similarly recommends identifying where nondeterminism enters the system and evaluating both the full architecture and individual components. It calls out single-turn apps, workflows, single-agent systems, and multi-agent systems as common patterns, with increasing nondeterminism around tool choice, arguments, and handoffs.  

Architecture/eval matrix

Pattern	Typical use	Main failure modes	Eval focus
Single-call generation	Rewrite, summarize, classify, extract, draft	Bad instruction following, wrong format, hallucination, unsafe content	Golden examples, schema validation, rubric judge, human review for subjective quality.
RAG / grounded Q&A	Chat over docs, support answers, policy lookup	Retriever misses source; irrelevant context; answer not grounded; stale docs; citation mismatch	Retrieval recall/precision, answer faithfulness, citation correctness, abstention behavior.
Prompt chain / workflow	Multi-step extraction → analysis → draft	Early-step errors cascade; intermediate schema breakage	Step-level evals plus end-to-end evals; gates between steps.
Router	Send tasks to specialized prompts/models/tools	Misclassification, wrong specialist, inconsistent UX	Intent-routing accuracy, fallback paths, per-route quality.
Parallel/voting	Multiple candidates, guardrails, ensemble review	Cost/latency blowup; correlated failures; false confidence	Candidate diversity, judge reliability, latency/cost budget, disagreement handling.
Tool-calling assistant	Search, CRUD actions, calculations, app workflows	Wrong tool, bad args, unhandled errors, overuse of tools	Tool selection, arg validity, idempotency, tool error recovery, audit trail.
Agentic loop	Open-ended tasks, research, multi-step ops	Compounding errors, runaway loops, excessive agency, prompt injection	Goal completion, step limits, sandbox tests, permission gates, stop conditions.
Multi-agent / handoff	Specialized agents, orchestrator-workers	Handoff ambiguity, context loss, duplicated work, harder debugging	Handoff criteria, role boundaries, transcript traceability, per-agent evals.
Memory/personalization	Remember preferences, account state, long-term context	Stale/poisoned memory, privacy leakage, wrong personalization	Memory write policies, retrieval permissions, deletion, user controls, poisoning tests.

Anthropic’s workflow patterns are especially useful for SaaS engineering: prompt chaining decomposes tasks and can add programmatic gates; routing separates concerns; parallelization can split work or use voting; orchestrator-worker patterns help with dynamic subtasks; evaluator-optimizer loops help when clear criteria exist; open-ended agents require sandboxing, stopping conditions, and extensive testing.  

The engineering bias should be:

Use deterministic code where you can, workflows where you need flexibility, agents only where the task genuinely requires dynamic planning.

⸻

5. Evaluation techniques: pros, cons, and where each fits

OpenAI’s evaluator guidance divides eval approaches into metric-based checks, human evals, and model-graded evals. It notes that exact-match, ROUGE, executable evals, and function-call checks are useful for structured tasks; human evals are high-quality but slower and costlier; LLM-as-judge is scalable but needs bias controls and validation against human labels.  

Technique tradeoff table

Technique	Best for	Pros	Cons / footguns
Exact match / regex	Classification, extraction, fixed labels, simple schemas	Cheap, deterministic, CI-friendly	Too brittle for natural language; misses semantically correct variants.
JSON schema / parser checks	Structured outputs, tool args, API payloads	Fast; catches integration breakage	Says nothing about semantic correctness.
Executable evals	Code, SQL, calculations, workflows with verifiable state	Strong signal; close to real correctness	Requires sandboxing/test fixtures; can be expensive to build.
Reference metrics: BLEU/ROUGE/etc.	Narrow summarization/translation baselines	Cheap, repeatable	Often poor proxy for open-ended usefulness; can reward word overlap over quality.
Embedding similarity	Semantic rough match, clustering failures	Useful for triage and search	Can hide factual errors; not a complete quality metric.
RAG metrics	Retrieval + grounded answers	Component visibility: context precision/recall, faithfulness, answer relevance	Metrics can disagree; still need task-specific examples and human review.
LLM-as-judge	Subjective quality, instruction following, tone, groundedness, pairwise comparison	Scales better than humans; useful for regression testing	Judge bias, verbosity bias, prompt sensitivity, model drift, cost; must be calibrated.
Human expert review	High-stakes, subjective, policy-sensitive, domain-specific tasks	Highest fidelity when reviewers are trained	Slow, expensive, inconsistent without rubrics/calibration.
User feedback	Live product fit: thumbs, accepts, edits, regenerates	Captures real UX value	Noisy; biased by user type, expectations, UI placement, and survivorship.
Red-team/adversarial eval	Safety/security robustness	Finds severe edge cases normal tests miss	Never exhaustive; must be paired with architectural mitigations.
Trace replay	Regression testing real failures	High relevance; reproduces incidents	Needs privacy controls, versioning, deterministic fixtures where possible.
Synthetic eval generation	Coverage expansion, rare edge cases	Fast way to generate candidate tests	Can overfit to generator assumptions; validate with real data and humans.

Research on LLM-as-judge supports both its utility and its limitations. MT-Bench/Chatbot Arena found strong agreement between GPT-4-based judgments and human preferences in many cases, while also documenting biases such as position bias, verbosity bias, self-enhancement bias, and limited reasoning ability. G-Eval similarly showed stronger correlation than older lexical metrics for some generation tasks, while noting bias toward LLM-generated text.  

For RAG, frameworks such as Ragas break evaluation into metrics like context precision, context recall, faithfulness, response relevancy, factual correctness, semantic similarity, tool-call accuracy, and agent-goal accuracy. This is valuable because RAG failures are often component failures: the retriever, reranker, context builder, generator, and citation layer can each fail differently.  

A practical rule:

Use deterministic checks for contracts, LLM judges for nuanced quality, humans for calibration and high-stakes review, and production telemetry for reality.

⸻

6. The eval loop you actually want

A mature AI eval system is a loop, not a dashboard.

The loop

1. Define the intended jobs.
    Enumerate user intents: “summarize this thread,” “draft reply,” “answer from docs,” “suggest next action,” “create content,” “take app action.”
2. Write behavior contracts.
    For each intent: expected output, allowed context, required citations, abstention rules, tone, latency, cost, safety constraints.
3. Instrument traces before optimizing.
    Capture prompt version, model config, context inputs, retrieval results, tool calls, safety decisions, output, user feedback, latency, cost, and errors.
4. Build seed datasets.
    Include real production examples, expert-authored cases, adversarial cases, known failures, edge cases, and golden fixtures.
5. Create layered scorers.
    Combine exact checks, schema checks, reference checks, LLM judges, human review, and product metrics.
6. Run evals in CI and release gates.
    Every prompt/model/tool/context/retrieval change should run against regression datasets before rollout.
7. Canary in production.
    Compare old vs new versions by segment, not just aggregate score.
8. Mine production traces.
    Convert support escalations, thumbs-down sessions, regenerations, tool errors, and human edits into new eval cases.
9. Review incidents.
    Every significant failure should produce a minimal reproducible eval case.
10. Continuously recalibrate.
    Refresh datasets, judge prompts, human rubrics, safety tests, and quality bars as the product evolves.

LangSmith’s documentation makes the same offline/online split: offline evaluation tests before shipping on curated datasets, while online evaluation monitors real user interactions in live traffic. Phoenix similarly supports evaluations on production traces, experiment results, and datasets, with deterministic code evaluators and LLM-as-judge evaluators.  

The incident flywheel

Every production failure should become a durable asset:

bad session → triage → label root cause → create minimal repro → add eval case → fix → backtest → release gate → monitor for recurrence.

This is the AI equivalent of turning outages into regression tests.

⸻

7. What to log and trace

You cannot operate AI features safely if you cannot reconstruct what happened. But you also should not dump raw chats forever with no privacy model. The right pattern is structured tracing with redaction, retention limits, and access control.

OpenTelemetry’s GenAI semantic conventions are a good reference schema. They include concepts such as agent name/version, conversation ID, prompt name, provider, model, request parameters, input/output messages, system instructions, token usage, time to first chunk, retrieved documents, tool definitions, tool-call IDs, tool-call arguments/results, evaluation score/name/explanation, and workflow name.  

Minimum useful trace schema

Category	Fields
Identity	tenant ID, user ID or hashed safety identifier, session/conversation ID, request ID, trace ID.
Feature context	feature name, UI action, user intent, mode, experiment bucket, release version.
Prompt/context	prompt template version, rendered prompt hash, system prompt version, context-builder version, memory state used, truncation events.
Model config	provider, model, temperature/top_p/seed where applicable, max tokens, reasoning mode if relevant.
Retrieval	query, filters, index version, embedding model, top-k docs, scores, citations shown, missing-doc signals.
Tools	tool definitions version, selected tool, args, result, latency, error, retry, side-effect classification.
Safety	policy version, moderation result, jailbreak/prompt-injection signals, PII flags, refusal/escalation.
Output	output hash/full output depending retention policy, schema validity, citations, parser result.
User response	accepted, edited, copied, regenerated, thumb rating, report issue, abandoned, escalated.
Ops	latency, time to first token, cost estimate, tokens in/out/cached, provider error, fallback used.
Eval	online judge score, rubric version, human label, reviewer ID/class, adjudication status.

OpenAI’s safety practices also recommend assigning stable safety identifiers to end users, hashing identifiers when appropriate, using session IDs for non-logged-in users, enabling user reporting, and applying human oversight especially in high-stakes contexts.  

SRE metrics for AI features

Traditional SRE still matters, but AI adds quality and risk SLIs.

SLI category	Examples
Availability	successful response rate, provider error rate, fallback rate, rate-limit rate.
Latency	p50/p95/p99 total latency, time to first token, retrieval latency, tool latency.
Cost	cost/request, cost/tenant, cost/successful task, token growth, cache hit rate.
Quality	eval pass rate, user acceptance, human-review pass rate, groundedness, citation correctness.
Safety	unsafe-output rate, prompt-injection exposure, PII leakage, policy violation, blocked action rate.
Reliability	schema parse failures, tool-call failures, invalid args, retries, loop-limit hits.
Data health	retrieval miss rate, stale-doc rate, index lag, context truncation, memory conflict rate.

A “quality SLO” might be:

“For the support answer feature, at least 95% of sampled production answers for top-20 support intents must be judged grounded, policy-compliant, and helpful by calibrated evals, with p95 latency under 6 seconds and zero P0 privacy leaks.”

That SLO is not perfect, but it is much better than “we tried it and it seemed good.”

⸻

8. Prompt, context, tool, and model versioning

For AI systems, the deployed artifact is not just code. It is a bundle:

* application code
* prompt templates
* rendered prompt logic
* system/developer instructions
* model/provider/version
* model parameters
* tool schemas and descriptions
* retrieval index
* embedding model
* chunking strategy
* reranker
* context-builder logic
* memory policy
* safety policy
* judge prompts/models
* eval dataset versions
* UI affordances and defaults

A prompt edit can be a production release. A retrieval-index rebuild can be a production release. A tool description change can be a production release. A model-provider “minor” change can be a production release.

Anthropic’s tool-use guidance is particularly relevant here: tool definitions are effectively contracts between deterministic software and nondeterministic agents. They recommend designing tools for agents, not merely exposing existing APIs; testing on realistic tasks; collecting accuracy, runtime, number of tool calls, token use, and tool errors; analyzing raw transcripts/tool calls; and improving tool descriptions, parameter names, context efficiency, pagination, error messages, and strict data models.  

Version everything that affects behavior

Artifact	Why it matters
Prompt template	Small wording changes can alter behavior.
System instructions	Defines role, policy, constraints, tone, and priority.
Model ID/provider	Model behavior can shift across versions.
Temperature/top_p/seed	Affects nondeterminism and reproducibility.
Tool schema	Determines whether the model can call tools correctly.
Tool descriptions	Strongly affect tool selection and argument formation.
Context builder	Determines what the model sees.
Retrieval index/chunking	Changes grounding and recall.
Memory policy	Changes personalization and privacy behavior.
Safety policy	Changes refusals, escalations, and moderation.
Judge prompt/model	Changes eval scores.
Dataset version	Changes what “passing” means.

Release workflow

Treat AI changes like code changes:

1. Create immutable prompt/context/tool versions.
2. Require PR-style review for production prompt changes.
3. Run offline evals against stable datasets.
4. Run targeted evals for known affected intents.
5. Run safety/security checks for risk-relevant changes.
6. Canary by tenant/user/traffic slice.
7. Compare against previous version by segment.
8. Roll back quickly if quality, safety, latency, or cost regresses.
9. Record why the change shipped.

OpenAI’s eval process guidance recommends defining objectives, collecting representative datasets, defining metrics, running and comparing evals, and continuously evaluating as data and user behavior evolve.  

⸻

9. Context engineering: the hidden center of eval quality

Prompt engineering is only one piece. For SaaS apps, many failures are actually context failures:

* missing account state
* stale product docs
* wrong tenant data
* too much irrelevant context
* conflicting instructions
* hidden permissions problem
* memory contamination
* retrieved content not visible to user
* context truncation
* wrong tool output format
* docs chunked in a way that destroys meaning

Anthropic’s context-engineering guidance defines context as the full token set available to the model: system instructions, tools, MCP/external data, message history, retrieved information, and other state. It argues that context is finite, that long context can degrade precision, and that good context engineering means providing the smallest high-signal token set needed for the task.  

Context eval checklist

Question	Eval
Did we include the right documents?	Retrieval recall against known-answer cases.
Did we exclude forbidden documents?	Tenant/permission tests, access-control evals.
Was the context too noisy?	Context precision, irrelevant-doc rate, answer degradation tests.
Was key information truncated?	Long-context edge cases, truncation telemetry.
Did the model follow current context over stale memory?	Memory conflict tests.
Did retrieved content contain hostile instructions?	Prompt-injection tests and untrusted-content isolation.
Did the answer cite only sources actually used?	Citation-support eval.
Did the model abstain when context was insufficient?	Unanswerable-question eval.

For complex systems, Anthropic describes techniques such as compaction, note-taking, and subagents to isolate detailed contexts and return distilled summaries. That is useful, but it increases the need for traceability: every summarized or delegated context becomes another place where evidence can be lost.  

⸻

10. RAG evals: separate retrieval from generation

For RAG, do not only ask, “Was the final answer good?” You need to know whether the retriever, context builder, and generator each did their job.

RAG component metrics

Component	Metrics / checks
Query understanding	Did the system generate/search the right query?
Retrieval	Recall@k, precision@k, MRR/NDCG where labels exist, source freshness, permission correctness.
Reranking	Did the best evidence move into the context window?
Context building	Was context concise, non-duplicative, sourceable, and permission-safe?
Generation	Faithfulness, answer relevance, completeness, abstention when unsupported.
Citation layer	Are citations present, correct, and attached to supported claims?
User outcome	Did the user accept the answer, ask follow-up, escalate, or report issue?

Ragas explicitly supports component-wise RAG evaluation and metrics such as context precision, context recall, faithfulness, response relevancy, factual correctness, and related measures.  

RAG footguns

* Treating RAG as a hallucination cure.
* Evaluating only answer text, not retrieval quality.
* Ignoring document freshness and permissions.
* Letting retrieved documents override system/developer instructions.
* Returning citations that merely resemble support, rather than actually supporting the claim.
* Using production docs without a labeled set of answerable and unanswerable questions.
* Not testing “no answer in corpus” cases.
* Not testing multilingual, typo, short-context, long-context, and ambiguous cases; OpenAI explicitly recommends edge cases across language, modalities, multiple intents, typos, context lengths, ambiguous tool properties, tool handoffs, jailbreaks, formatting conflicts, and prompt conflicts.  

⸻

11. Tool-use and agent evals

Tool-use evals are not just “did the final answer look good?” They must inspect the action trace.

Tool-use eval dimensions

Dimension	Example
Tool selection	Did the assistant choose search_docs vs create_invoice correctly?
Argument validity	Did it pass valid JSON, IDs, dates, filters, tenant IDs?
Permissioning	Did it call only tools allowed for this user/task?
Side effects	Did it avoid irreversible actions without approval?
Error recovery	Did it handle 404/rate-limit/validation errors gracefully?
Efficiency	Did it avoid redundant calls and loops?
Final answer	Did it accurately summarize tool results?
Auditability	Can you reconstruct what happened?

Anthropic’s tool guidance recommends using realistic eval tasks that may require many tool calls, pairing prompts with verifiable outcomes, avoiding overly strict verifiers when multiple valid tool paths exist, and collecting top-level accuracy, runtime, number of tool calls, token consumption, and tool errors.  

Agent-specific eval dimensions

Agent risk	Eval / control
Runaway loops	Max steps, loop detection, cost ceilings, timeout tests.
Bad plans	Plan critique, human approval for high-impact plans, plan-vs-execution checks.
Compounding errors	Step-level evals, checkpoints, rollback.
Tool overuse	Tool-call budget, redundant-call detection.
Excessive agency	Explicit allowed actions, side-effect classification, confirmation gates.
Context poisoning	Untrusted-content isolation, memory-write review.
Handoff loss	Handoff summaries, role boundaries, trace continuity.

Anthropic recommends that autonomous agents operate with clear stopping conditions, checkpoints, sandboxing, and guardrails, especially because open-ended agents can compound mistakes.  

⸻

12. Safety, security, and governance evals

For AI apps with tools, connectors, memory, and user data, safety is not just content moderation. It is security architecture plus behavioral evaluation.

OWASP’s 2025 Top 10 for LLM and generative AI applications lists risks including prompt injection, sensitive information disclosure, supply-chain vulnerabilities, data/model poisoning, improper output handling, excessive agency, system prompt leakage, vector/embedding weaknesses, misinformation, and unbounded consumption.  

OpenAI’s prompt-injection guidance emphasizes that agentic systems create new paths for attackers because they can browse, retrieve, and take actions. It argues that defenses should not rely only on detecting prompt injections; systems should be designed so that even successful manipulation has constrained impact.  

The Frontier Model Forum’s emerging security practices make the same point at the system level: deterministic controls in the harness, tools, and execution environment determine blast radius. It highlights sandboxing, scoped filesystems, network egress limits, tool controls, memory poisoning risks, human oversight, audit records, and the “lethal trifecta” of private data access, untrusted content exposure, and external communication.  

Safety eval/control matrix

Risk	Eval	Architectural control
Prompt injection	Malicious docs/emails/webpages telling agent to ignore rules	Treat retrieved/tool content as untrusted; separate instruction hierarchy; limit tools.
Data exfiltration	Can agent leak tenant/customer/private data?	Tenant isolation, scoped tokens, output DLP, approval for external sends.
Excessive agency	Can agent take irreversible action?	Human confirmation, idempotent APIs, dry-run mode, side-effect classification.
Tool misuse	Wrong or dangerous tool calls	Allowlist tools per intent/user; validate args; policy gate before execution.
Memory poisoning	Malicious or wrong info stored long term	Memory-write criteria, user-visible memory controls, periodic review, provenance.
Vector/embedding weakness	Wrong docs retrieved, cross-tenant leakage	Permission-aware retrieval, index audits, adversarial retrieval tests.
Misinformation	Plausible but unsupported claims	Grounding evals, citations, abstention, human review for high stakes.
Unsafe content	Harmful, hateful, sexual, self-harm, etc.	Moderation, refusal policies, risk-tiered review.
Unbounded consumption	Infinite loops, cost blowups	Step limits, token budgets, rate limits, cost alerts.
Improper output handling	LLM output interpreted as trusted code/SQL/HTML	Escaping, validation, sandboxing, no direct execution without checks.

Microsoft’s Foundry safety evaluation documentation is useful because it explicitly warns that AI-assisted safety evals are not comprehensive replacements for manual red-teaming, have limitations, can produce false positives/negatives, and should be used with human-in-the-loop review and holistic risk management.  

OpenAI’s safety best practices also recommend moderation, adversarial testing, human-in-the-loop for high-stakes domains, prompt constraints, limiting input/output length, constrained user inputs where possible, user reporting, and safety identifiers.  

⸻

13. Human review: where it belongs

Human review is expensive, so use it where it has leverage.

Good uses of human review

* Creating initial rubrics.
* Labeling seed datasets.
* Calibrating LLM judges.
* Reviewing high-severity failures.
* Auditing sampled production traces.
* Reviewing high-risk actions before execution.
* Adjudicating ambiguous cases.
* Evaluating tone/brand/domain nuance.
* Updating quality bars as product expectations evolve.

Weak uses of human review

* Asking random employees to “rate vibes” with no rubric.
* Reviewing only cherry-picked examples.
* Reviewing outputs without seeing source context and tool traces.
* Treating a single reviewer’s opinion as ground truth.
* Using human approval for too many low-risk actions, causing fatigue.

Human reviewers need a rubric, examples, access to source materials, and calibration. Otherwise the review process itself becomes nondeterministic.

⸻

14. LLM-as-judge: how to use it without fooling yourself

LLM judges are useful, but they should be treated as measurement instruments, not objective truth.

Recommended judge patterns

Pattern	Use
Pass/fail rubric	“Does answer cite policy and avoid unsupported claims?”
Pairwise comparison	Compare candidate A vs B for release decisions.
Reference-guided judge	Judge against expected facts or source docs.
Aspect-specific judges	Separate correctness, tone, groundedness, format, safety.
Critique + score	Ask for structured rationale plus bounded score.
Human-calibrated judge	Tune rubric until it agrees with trained reviewers enough for its purpose.

OpenAI recommends clear rubrics, pass/fail criteria, pairwise comparisons, controlling for response length, avoiding positional bias, validating LLM judges against human labels, and maintaining agreement with human feedback over time.  

Judge footguns

* Same model generates and judges without calibration.
* Judge prompt changes but historical scores are compared as if unchanged.
* Judge rewards verbosity or style over correctness.
* Judge never sees source documents.
* Judge is asked a vague question like “Is this good?”
* Judge scores are averaged across unrelated intents.
* Judge is used as the only safety mechanism.
* Human labels are never collected to validate judge drift.
* The team optimizes to the judge and degrades real user outcomes.

A strong pattern is to keep small, high-quality, human-labeled calibration sets for each important feature and periodically measure judge agreement.

⸻

15. Building the eval dataset

Your eval dataset should be a living product artifact, not a CSV someone made once.

Dataset sources

Source	Value
Product specs	Encodes intended behavior.
Real production traces	Captures actual user behavior and weirdness.
Support tickets	High-signal failures.
Human expert examples	Domain-correct gold cases.
Synthetic examples	Fill coverage gaps.
Adversarial/red-team cases	Safety/security stress.
Historical incidents	Prevent regressions.
Competitor/manual workflows	Define quality bar.

OpenAI’s guidance recommends production data, expert datasets, and hard-coded correct answers/logs, with task-specific metrics and continuous refresh.  

Dataset structure

Each eval case should usually include:

* case_id
* feature
* user_intent
* risk_tier
* input
* user/app context
* allowed tools
* source docs / expected evidence
* expected behavior
* forbidden behavior
* scoring rubric
* gold answer or reference facts, if available
* metadata: language, tenant type, user role, plan tier, data freshness, edge-case tags
* origin: synthetic, production, support ticket, red-team, incident
* privacy classification
* owner

Segmentation matters

Do not only look at aggregate score. Segment by:

* user intent
* feature surface
* language
* customer tier
* industry/domain
* user role
* new vs power users
* short vs long context
* mobile vs desktop
* document type
* model/prompt version
* retrieval source
* risk tier

A model can improve aggregate performance while harming the most important or highest-risk cases.

⸻

16. Quality bars and release gates

A quality bar should be explicit and risk-weighted.

Example release gate

For a new AI support-chat prompt:

Gate	Required
Smoke tests	100% schema/format pass.
Known regressions	0 P0/P1 regressions.
RAG grounding	≥ 95% pass on top support-policy cases.
Abstention	≥ 90% correct abstention on unanswerable cases.
Tool calls	≥ 98% valid args; 0 unauthorized tool calls.
Safety	0 critical policy violations in red-team set.
Latency	p95 within target on staging/canary.
Cost	Cost/request within budget or approved.
Human review	No unresolved reviewer objections on high-risk cases.

Risk tiers

Tier	Example	Eval posture
Low	Rewrite marketing copy, brainstorm titles	Lightweight evals, user controls, easy undo.
Medium	Summarize customer call, draft support response	RAG/citation checks, human review samples, no direct send by default.
High	Financial/legal/medical advice, employment decisions, account changes	Expert review, stronger safety evals, approvals, audit logs, conservative fallback.
Critical	Irreversible external actions, money movement, data deletion	Deterministic controls, human approval, sandbox/dry run, strict authorization.

The higher the risk, the more you should prefer deterministic constraints, human approval, and verifiable outputs over open-ended generation.

⸻

17. Operational anti-patterns and footguns

These are the mistakes that repeatedly hurt teams.

Product and UX footguns

* Shipping “AI chat” without defining supported intents.
* Making the assistant sound omniscient when it is retrieval-limited.
* Hiding uncertainty, missing sources, or tool failures from users.
* Offering regenerate without learning why users regenerated.
* Asking for thumbs up/down but never linking feedback to traces.
* Adding memory without user controls or memory evals.
* Using “human approval” so often that users rubber-stamp it.
* Showing raw model “thoughts” instead of useful action summaries, assumptions, sources, and verification steps.

Engineering footguns

* No prompt versioning.
* No model/config versioning.
* No trace IDs.
* No reproducible eval harness.
* No regression dataset.
* No separation between retrieval eval and generation eval.
* Tool schemas designed for humans rather than agents.
* Too many tools exposed at once.
* Ambiguous tool names or parameters.
* Tool results too verbose for context windows.
* Irreversible side effects behind LLM decisions.
* Treating provider model swaps as safe config changes.
* Evaluating only happy paths.
* Letting eval data leak into prompt tuning.
* Comparing scores across judge versions.
* Aggregating unrelated evals into one meaningless score.

Data-science footguns

* Overfitting to a small golden set.
* Using synthetic-only evals.
* No holdout set.
* No confidence intervals.
* No segment analysis.
* Optimizing to LLM judge scores without human calibration.
* Ignoring inter-reviewer disagreement.
* Treating user clicks as pure quality labels.

SRE/security footguns

* Logging raw conversations indefinitely.
* Letting on-call debug without source/tool traces.
* No alerts for cost/token explosions.
* No loop limits for agents.
* No tenant-isolation tests for retrieval.
* No prompt-injection tests for connected data.
* Assuming moderation catches security attacks.
* Giving agents private data access, untrusted content access, and external communication in the same flow without strong controls.
* No rollback path for prompt/model changes.

OpenAI explicitly warns against vibe-based evals, overly generic metrics, non-representative datasets, and ignoring human feedback; Anthropic warns against unnecessary framework complexity and poorly designed tools; OWASP and Frontier Model Forum warn about prompt injection, excessive agency, data leakage, tool risks, and blast-radius failures.  

⸻

18. Tooling landscape

You do not need to start with a massive platform. You need five capabilities:

1. Tracing/observability: capture AI calls, retrieval, tools, outputs, feedback.
2. Dataset management: store eval cases, labels, rubrics, versions.
3. Experiment runner: run prompt/model/tool versions against datasets.
4. Scorers: deterministic checks, LLM judges, human labels.
5. Release/monitoring integration: CI gates, dashboards, alerts, canaries.

Examples from the current ecosystem:

Tool/category	What it helps with
OpenTelemetry GenAI conventions	Portable trace/event schema for GenAI spans, prompts, tools, retrieval, tokens, evals.  
LangSmith	Offline eval on curated datasets and online eval on live interactions.  
Phoenix / Arize Phoenix	Traces, datasets, experiments, deterministic evaluators, LLM judges, RAG/tool-calling evals.  
Ragas	RAG and agent metrics such as faithfulness, context precision/recall, response relevance, tool-call accuracy.  
Inspect	Open-source eval framework from UK AISI/METR-oriented ecosystem with datasets, solvers, scorers, tool calling, and sandboxing.  
lm-evaluation-harness	Broad model benchmark harness; useful for model-level benchmark work, less sufficient for product-specific evals.  

A caution: vendor eval platforms change. OpenAI’s own docs currently note that its older Evals platform is being deprecated, with read-only status planned for October 31, 2026 and shutdown on November 30, 2026. That is a good reason to keep your eval data, traces, rubrics, and release gates conceptually portable.  

⸻

19. Domain language: nouns, events, verbs

Core nouns

Term	Meaning
Eval	A structured test or measurement of AI behavior.
Eval case / sample	One input scenario plus expected behavior and scoring criteria.
Dataset	Collection of eval cases.
Golden set	High-confidence labeled dataset used for regression testing.
Holdout set	Dataset not used during prompt/model tuning, reserved for unbiased evaluation.
Rubric	Criteria used by humans or LLM judges to score output.
Scorer / grader / judge	Code, human, or model that evaluates output.
Oracle / verifier	A trusted way to determine correctness, often deterministic.
Trace	End-to-end record of an AI interaction.
Span	One step inside a trace: model call, retrieval call, tool call, guardrail check.
Prompt version	Immutable identifier for prompt template/instructions.
Model config	Provider, model, temperature, max tokens, etc.
Context	Tokens/state supplied to the model for a request.
Context builder	Code that selects and formats context.
RAG	Retrieval-augmented generation: retrieve external context before generating.
Retriever	Component that finds candidate documents.
Reranker	Component that reorders retrieved documents.
Chunk	Indexed unit of a source document.
Embedding	Vector representation used for semantic search.
Grounding	Tying output to supplied evidence.
Faithfulness	Whether generated claims are supported by evidence.
Hallucination	Unsupported or fabricated model output.
Tool call	Model-requested invocation of a function/API.
Tool schema	Machine-readable contract for a tool’s name, parameters, and outputs.
Agent harness	Orchestration layer around the model, tools, memory, policies, and loop.
Workflow	Predefined sequence or graph of steps.
Agent	System where the model dynamically chooses steps/tools toward a goal.
Handoff	Transfer from one agent/tool/workflow/person to another.
Memory	Persisted user/system information reused across sessions.
Guardrail	Preventive or detective control around inputs, outputs, tools, or policies.
Red-team	Adversarial testing to find failures or unsafe behavior.
Jailbreak	Attempt to bypass safety/policy constraints.
Prompt injection	Malicious or conflicting instructions inserted into user or external content.
Quality bar	Minimum acceptable performance for launch or release.
SLI/SLO/error budget	Reliability concepts applied to quality, safety, latency, cost, and availability.
Canary	Limited rollout to detect regressions before full release.
Drift	Behavior changes over time due to data, model, user, or system changes.
Regression	New version performs worse on an existing behavior requirement.
Human label	Human-provided evaluation result.
Adjudication	Resolving disagreement between reviewers or scorers.

Important events to instrument

Event	Why it matters
prompt_rendered	Reproduce exact behavior.
context_built	Debug missing/noisy/stale context.
retrieval_started / retrieval_completed	Measure RAG quality and latency.
model_invoked	Track provider/model/config usage.
tool_selected	Debug agent decisions.
tool_called / tool_completed / tool_failed	Track action correctness and reliability.
guardrail_triggered	Measure safety and false positives.
memory_read / memory_written	Audit personalization and poisoning risk.
output_streamed / output_completed	Measure latency and final answer.
user_feedback_received	Build data flywheel.
human_review_completed	Calibrate quality and safety.
eval_run_started / eval_run_completed	Track release readiness.
regression_detected	Block or roll back releases.
incident_opened / incident_resolved	Connect production failures to eval cases.
approval_requested / approval_granted	Audit high-impact actions.

Common verbs

Verb	Meaning
Curate	Select and maintain eval cases.
Label	Assign human or reference judgment.
Score / grade	Evaluate an output.
Adjudicate	Resolve conflicting labels.
Calibrate	Align judges/reviewers with a rubric.
Replay	Re-run prior traces against a new version.
Trace	Record execution steps.
Sample	Select production interactions for review.
Redact/anonymize	Remove or transform sensitive data.
Segment/stratify	Break metrics down by meaningful cohorts.
Gate	Block release unless criteria pass.
Canary	Roll out to limited traffic.
Rollback	Revert to prior version.
Ground	Support claims with evidence.
Retrieve/rerank	Find and order relevant context.
Sanitize	Make untrusted input/output safe for downstream use.
Sandbox	Restrict execution environment.
Approve	Human confirmation for high-impact action.
Audit	Review historical behavior and decisions.

⸻

20. Personas and jobs-to-be-done

Persona	Jobs-to-be-done	What they need from evals
End user	Get useful help, stay in control, trust the system appropriately	Clear outputs, citations, undo, correction, disclosure, predictable behavior.
Feature PM	Define quality bar and launch criteria	Outcome metrics, segment performance, risk tiers, release readiness.
Product designer	Create AI UX that guides, constrains, and builds trust	Eval feedback by UI state: suggestions, tuners, regenerate, citations, confirmations.
AI/product engineer	Build prompts, tools, RAG, workflows, agents	Reproducible traces, regression tests, component evals, judge/human feedback.
Backend/platform engineer	Operate shared AI infrastructure	Versioning, routing, rate limits, retries, fallbacks, observability.
SRE/on-call	Keep feature reliable and safe in production	SLIs/SLOs, alerts, traces, runbooks, rollback, incident linkage.
Data scientist/ML engineer	Measure behavior rigorously	Datasets, labels, judge calibration, confidence intervals, experiment design.
Domain expert	Ensure correctness in specialized domain	Review queues, rubrics, source context, adjudication workflows.
Trust & Safety	Prevent harmful behavior and abuse	Policy evals, red-team sets, moderation metrics, escalation flows.
Security engineer	Threat-model agent/tool/data risks	Prompt-injection tests, least privilege, sandboxing, audit logs, exfiltration tests.
Privacy/legal/compliance	Ensure lawful and policy-compliant use of data	Consent, retention, redaction, access controls, auditability.
Support/customer success	Understand and resolve user complaints	Session replay with privacy controls, root-cause labels, known-issue linkage.
Finance/exec	Balance ROI, risk, and cost	Cost per successful task, adoption, deflection, quality trend, risk posture.

The important org-design lesson: eval ownership is cross-functional. Engineering can build the harness, but product defines success, domain experts define correctness, SRE defines operability, security defines threat models, and legal/privacy define data boundaries.

⸻

21. Practical maturity model

Level 0 — Prototype

* Prompt in code.
* Manual testing.
* No traceability.
* “Seems good” decisions.

This is fine for exploration, not production.

Level 1 — Observable prototype

* Log request IDs, model, prompt version, latency, cost.
* Capture user feedback.
* Manual review of sampled traces.
* Basic safety filters.

Level 2 — Regression-aware feature

* Version prompts and model configs.
* Curated golden set for top intents.
* Deterministic schema/tool tests.
* LLM judge or human rubric for subjective quality.
* CI eval run before release.

Level 3 — Component-evaluated system

* Separate evals for retrieval, generation, tools, safety, and UI flows.
* Production trace mining.
* Known-failure regression suite.
* Prompt/model canaries.
* Basic quality dashboard.

Level 4 — Operated AI product

* Quality SLOs by feature/intent.
* Online evals and human review queues.
* Incident → eval-case flywheel.
* Cost/latency/error-budget monitoring.
* Risk-tiered release gates.
* Privacy-aware trace access.

Level 5 — Governed AI platform

* Shared eval infrastructure across features.
* Calibrated judges and reviewer workflows.
* Automated red-team suites.
* Formal prompt/tool/context release management.
* Tenant-aware safety and permission evals.
* Executive-level quality/risk/cost reporting.

Most SaaS teams should aim for Level 3 before broad launch and Level 4 for business-critical AI features.

⸻

22. Suggested first 90 days

Days 1–14: inventory and instrumentation

* Inventory all AI features and intended user jobs.
* Define supported intents and unsupported intents.
* Add trace IDs across model calls, retrieval, tools, safety checks, and user feedback.
* Version prompt templates and model configs.
* Create a basic session review view with privacy controls.

Days 15–30: seed evals

* Create 50–200 eval cases for top intents.
* Add known bad cases and edge cases.
* Add deterministic checks for schemas, tool args, and forbidden actions.
* Create a simple rubric for helpfulness, correctness, groundedness, tone, and safety.
* Run current production version as baseline.

Days 31–60: component and release gates

* Split RAG evals into retrieval and generation.
* Split tool-use evals into selection, args, result handling, and final answer.
* Add CI evals for prompt/model/tool changes.
* Add canary comparison for high-traffic features.
* Create a reviewer workflow for sampled production traces.

Days 61–90: operationalization

* Define quality SLOs for top features.
* Add cost/latency/quality dashboards.
* Convert support tickets and thumbs-down traces into regression cases.
* Add red-team tests for prompt injection, PII leakage, and excessive agency.
* Establish release ownership: who can change prompts, tools, models, safety policy, and judges.
* Create an incident runbook for AI failures.

⸻

23. The most important best practices

1. Start from user jobs, not model capabilities.
    The eval unit is “user intent in product context,” not “LLM output in isolation.”
2. Define contracts before metrics.
    Metrics are useless if nobody wrote down what good behavior means.
3. Version every behavior-affecting artifact.
    Prompt, model, context builder, retriever, index, tools, memory policy, safety policy, judge, dataset.
4. Trace everything necessary to reproduce failures.
    But redact, minimize, and govern access.
5. Separate component evals from end-to-end evals.
    Final answer quality does not tell you whether retrieval, tool use, or context failed.
6. Use multiple evaluation methods.
    Deterministic checks, LLM judges, human review, user feedback, and red-team tests each see different failures.
7. Calibrate LLM judges against humans.
    Never treat judge scores as objective truth without validation.
8. Mine production failures into regression tests.
    The best eval cases often come from real incidents.
9. Prefer workflows over agents unless autonomy is necessary.
    More agency means more eval complexity, more security risk, more cost, and harder debugging.
10. Constrain blast radius.
    For tool-using agents, safety comes from architecture: permissions, sandboxing, scoped tools, approval gates, audit logs, and reversible operations.
11. Segment results.
    Aggregate eval scores hide failures in high-value or high-risk cohorts.
12. Keep evals alive.
    User behavior, data, models, prompts, tools, and product expectations drift.

⸻

24. Condensed LLM-context version

Use this as compact context for future design/review conversations:

AI_EVALS_FOR_SAAS_LLM_FEATURES
Core principle:
Treat every AI feature as a probabilistic product subsystem with a behavior contract, traceability, eval datasets, release gates, production monitoring, and incident feedback loops. Do not treat eval as just model benchmarking.
For each AI feature define:
- supported user intents
- expected output contract
- allowed/forbidden sources and tools
- required citations/grounding
- tone/format constraints
- latency/cost budgets
- safety/privacy/security constraints
- uncertainty/abstention/escalation behavior
- human approval requirements for risky actions
Eval layers:
1. Product outcome: did the user’s job get done?
2. Behavioral quality: correctness, relevance, helpfulness, tone, format, instruction-following.
3. Component quality: retrieval, context builder, prompt, model, tool selection, tool args, memory, handoffs.
4. Operational quality: latency, cost, errors, retries, rate limits, fallbacks, token use.
5. Safety/security: prompt injection, PII leakage, unsafe content, excessive agency, data exfiltration, memory poisoning.
Architecture guidance:
- Prefer deterministic code where possible.
- Use workflows for predictable multi-step tasks.
- Use agents only when dynamic planning/tool choice is necessary.
- Every added tool, memory source, connector, or handoff expands eval and security surface.
RAG eval:
- Evaluate retrieval separately from generation.
- Track context recall, context precision, answer faithfulness, answer relevance, citation correctness, abstention on unanswerable cases, permission correctness, source freshness.
Tool/agent eval:
- Score tool selection, argument validity, permissioning, side effects, error recovery, redundant calls, loop limits, final answer correctness, and auditability.
- Require approval for irreversible or high-impact actions.
- Use sandboxing, scoped credentials, and allowlisted tools.
Eval methods:
- deterministic checks: exact match, regex, schema, executable tests
- reference metrics: useful only for narrow tasks
- LLM-as-judge: useful for scalable subjective eval, but calibrate against humans
- human review: use for rubrics, high-stakes cases, calibration, incidents
- online feedback: accept/edit/regenerate/thumbs/report/abandon
- red-team: prompt injection, safety, exfiltration, excessive agency
- trace replay: turn production failures into regression tests
Version:
- prompt templates
- system instructions
- model/provider/config
- tool schemas/descriptions
- context-builder logic
- retrieval index/chunking/embedding/reranker
- memory policy
- safety policy
- judge prompt/model
- eval dataset
Trace:
- tenant/user/session/request/trace IDs
- feature, intent, UI state, experiment bucket
- prompt/context/model config
- retrieval query/docs/scores/index version
- tool calls/args/results/errors
- safety checks
- output/schema/citations
- latency/cost/tokens
- user feedback
- eval scores/human labels
Release process:
- run offline evals before ship
- block P0/P1 regressions
- canary new prompt/model/tool versions
- compare by segment, not just aggregate
- monitor quality/cost/latency/safety in production
- rollback quickly
- convert incidents into eval cases
Anti-patterns:
- vibe-based evals
- no prompt/model/context/tool versioning
- no traces
- only happy-path tests
- synthetic-only datasets
- aggregate-only scores
- uncalibrated LLM judges
- judge version drift
- evaluating final answer only
- exposing too many ambiguous tools
- agents with unbounded loops
- irreversible side effects without approval
- raw chat logging without privacy controls
- treating RAG as hallucination-proof
- relying on prompt-injection detection instead of blast-radius controls

The shortest practical summary is:

A good AI eval program turns product expectations into measurable contracts, turns production behavior into traces, turns failures into regression tests, and turns risky autonomy into constrained, observable, reviewable workflows.