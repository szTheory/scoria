# Phase 32: Multi-Model Fallback Orchestration - Pattern Map

**Mapped:** 2026-05-12
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/orchestrator.ex` | domain wrapper | request-response | `lib/scoria/mcp/executor.ex` | role-match |
| `test/scoria/orchestrator_test.exs` | test | request-response | `test/scoria/compaction/summarize_worker_test.exs` | exact |
| `lib/scoria/compaction/summarize_worker.ex` | worker | caller | (itself) | exact |
| `lib/scoria/eval/judge_runner.ex` | service | caller | (itself) | exact |
| `config/config.exs` | config | static map | (itself) | exact |

## Pattern Assignments

### `lib/scoria/orchestrator.ex` (domain wrapper, request-response)

**Analog:** `lib/scoria/mcp/executor.ex`

**Role/Execution Wrapping Pattern** (lines 43-68):
The Orchestrator should wrap the execution of the `ReqLLM` client similarly to how `Executor` wraps tool calls, emitting telemetry and handling errors elegantly.

```elixir
    :telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)
    
    # ... execution logic ...

    case result do
      {:ok, result} ->
        :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
        {:ok, result}

      {:error, reason} ->
        :telemetry.execute(
          [:scoria, :tool, :failed],
          %{duration: duration},
          Map.put(metadata, :reason, reason)
        )
        {:error, reason}
    end
```

*For Orchestrator, the telemetry will be `[:scoria, :orchestrator, :request, :stop]` and `[:scoria, :orchestrator, :fallback]`.*

**Config Loading Pattern** (similar to `lib/scoria/compaction/summarize_worker.ex` line 117):
```elixir
    req_llm_module = Application.get_env(:scoria, :req_llm_module, ReqLLM)
```

---

### `test/scoria/orchestrator_test.exs` (test, request-response)

**Analog:** `test/scoria/compaction/summarize_worker_test.exs`

**ReqLLM Stubbing Pattern** (lines 10-31):
```elixir
  defmodule ReqLLMStub do
    def generate_text(model_spec, prompt, _opts) do
      send(self(), {:req_llm_called, model_spec, prompt})
      {:ok, %{text: "Summarized text response"}}
    end
  end

  setup do
    previous_llm = Application.get_env(:scoria, :req_llm_module)
    Application.put_env(:scoria, :req_llm_module, ReqLLMStub)

    on_exit(fn ->
      restore_env(:req_llm_module, previous_llm)
    end)

    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:scoria, key)
  defp restore_env(key, value), do: Application.put_env(:scoria, key, value)
```

*For the Orchestrator test, the stub should be extended to simulate errors (like circuit breaker open or HTTP timeouts) to trigger the fallback logic, which can be tracked via `assert_received`.*

---

### `lib/scoria/compaction/summarize_worker.ex` (worker, caller)

**Analog:** (itself)

**Current ReqLLM Usage Pattern** (lines 117-123):
```elixir
    req_llm_module = Application.get_env(:scoria, :req_llm_module, ReqLLM)

    with {:ok, response} <-
           req_llm_module.generate_text(summary_model(), prompt,
             system_prompt: "You compress workflow event history...",
             req_options: Scoria.Req.Steps.req_options(summary_model())
           )
```
*Action for Planner:* This needs to be updated to inject and call `Scoria.Orchestrator.generate_text` instead of calling `ReqLLM` directly.

---

### `lib/scoria/eval/judge_runner.ex` (service, caller)

**Analog:** (itself)

**Current ReqLLM Usage Pattern** (lines 42-53):
```elixir
    req_llm_module =
      fetch(attrs, :req_llm_module) || Application.get_env(:scoria, :req_llm_module, ReqLLM)

    # ...

        {:ok, response} =
          req_llm_module.generate_object(model_spec, prompt, judge_schema(),
            req_options: Scoria.Req.Steps.req_options(model_spec)
          )
```
*Action for Planner:* Similar to the worker, change the injection to use `Scoria.Orchestrator` instead of `ReqLLM` directly.

---

### `config/config.exs` (config, static map)

**Static Configuration Pattern:**
The fallback configuration maps primary model specs to a list of fallback model specs. This natively leverages OTP app config.
```elixir
config :scoria,
  fallback_chains: %{
    "openai:gpt-4o" => ["openai:gpt-4-turbo", "openai:gpt-3.5-turbo"],
    "anthropic:claude-3-opus" => ["anthropic:claude-3-sonnet"]
  }
```

## Shared Patterns

### Dependency Injection
**Source:** `lib/scoria/eval/judge_runner.ex` and `lib/scoria/compaction/summarize_worker.ex`
**Apply to:** `Scoria.Orchestrator`
All domain boundaries calling out to `ReqLLM` rely on application environment resolution (`Application.get_env(:scoria, :req_llm_module, ReqLLM)`) to allow deterministic tests. The Orchestrator MUST use this pattern to call `ReqLLM`, and the callers (Worker/Runner) should similarly look up the Orchestrator or just directly call `Scoria.Orchestrator` while the Orchestrator manages the `ReqLLM` stub internally.

## Metadata

**Analog search scope:** `lib/scoria`, `test/scoria`, `config`
**Files scanned:** 33 telemetry files, 85 ReqLLM matches, 3 manual reviews.
**Pattern extraction date:** 2026-05-12