# Summary: Phase 32, Plan 02

## Objective
Integrate `Scoria.Orchestrator` into existing LLM call sites (`SummarizeWorker` and `JudgeRunner`) and ensure environment compatibility for persisted memories.

## Accomplishments
- **SummarizeWorker Integration**: Updated `Scoria.Compaction.SummarizeWorker` to use `Scoria.Orchestrator.generate_text/3`, enabling automatic fallback if the primary summary model (GPT-4o) fails.
- **JudgeRunner Integration**: Updated `Scoria.Eval.JudgeRunner` to use `Scoria.Orchestrator.generate_object/4`, streamlining judge requests and ensuring resiliency during live evaluation runs.
- **Environment Compatibility**: Switched `ai_compacted_memories` embedding storage to `:binary` serialization (`:erlang.term_to_binary`) to ensure the system remains portable and functional in environments without the `pgvector` Postgres extension.
- **Test Stabilization**: 
    - Updated `CompactedMemoryTest` to handle binary embedding verification.
    - Increased database connection pool size in `test.exs` to 20.
    - Disabled `async: true` in flaky database-intensive tests (`OfflineRunnerTest`, `JudgeRunnerTest`, `EvalSpecLive.IndexTest`, `MCPControllerTest`) to prevent sandbox ownership conflicts.
    - Refactored `test_helper.exs` to remove redundant migration runs.

## Verification Results
- `Scoria.Compaction.SummarizeWorkerTest`: PASSED
- `Scoria.Eval.JudgeRunnerTest`: PASSED
- `Scoria.Eval.OfflineRunnerTest`: PASSED
- `Scoria.Runtime.CompactedMemoryTest`: PASSED
- `ScoriaWeb.MCPControllerTest`: PASSED
- Full test suite verified for stability.

## Key Artifacts
- `lib/scoria/compaction/summarize_worker.ex`
- `lib/scoria/eval/judge_runner.ex`
- `lib/scoria/runtime/compacted_memory.ex`
- `priv/repo/migrations/20260519010100_create_ai_compacted_memories.exs`
