# Scoria x Parapet Integration Seeds

*These are GSD planted seeds for future milestone ideation regarding the synergy between Scoria (AI Ops) and Parapet (SRE Substrate).*

## 1. AI Quality & Latency SLOs
Scoria tracks LLM trace latency (Time-to-First-Token, Total Generation Time) and Evaluation pass rates. Parapet can define explicit SLOs (e.g., `Parapet.SLO.define(:ai_generation_latency, ...)`) that map to these metrics. This treats the LLM's user experience just like a traditional HTTP endpoint's Apdex score.

## 2. Cost & Token Burn-Rate Alerts
Scoria emits telemetry on token usage and cost per model. Parapet can translate this into a Prometheus burn-rate alert, treating AI spend like an SRE error budget. If a prompt change causes Groq/OpenAI costs to spike 500x in an hour, Parapet catches the burn-rate anomaly immediately.

## 3. Deploy Correlation to Eval Regressions
Parapet's deploy markers (vertical annotations in Grafana) overlaid on Scoria's LLM-as-a-judge eval scores will immediately prove if a prompt tweak, feature flag flip (Rulestead), or code deploy degraded the AI's helpfulness or groundedness in production. 

## 4. MCP Tool Reliability as an SRE Target
MCP tools (e.g., `refund_customer` or `search_docs`) executed by AI agents can fail or time out. Parapet can monitor these specific tool invocations just like HTTP endpoints or Oban jobs, tracking their failure rates and providing out-of-the-box runbooks for operators when specific agent capabilities degrade.

## 5. High-Cardinality Telemetry Safety
Parapet enforces strict metric label policies to prevent Prometheus cardinality explosions. Scoria must emit "safe" low-cardinality metrics (e.g., `model`, `provider`, `tool_name`, `status`) separated from high-cardinality metadata (e.g., `trace_id`, `prompt_text`, `actor_id`) to perfectly integrate with Parapet's exception-safe telemetry handler. 

## 6. Durable Evidence (via Threadline)
While Parapet bridges the gap to Prometheus (ephemeral), Scoria's Ecto-backed traces act as the durable evidence. When Parapet fires a burn-rate alert for an AI workflow, the alert runbook will seamlessly deep-link into Scoria's LiveView Trace Explorer to show the exact prompt and LLM response that caused the failure.