# Phase 55: Content Trust & Taint Substrate - Research

**Researched:** 2026-07-27
**Domain:** Elixir/OTP embedded-lib mechanism — content provenance tagging, tool-output wrapping, prompt-assembly signal-separation, BYO scanner seam
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-01..D-23 as recorded verbatim in `.planning/phases/55-content-trust-taint-substrate/55-CONTEXT.md` `<decisions>` — this research does not re-litigate any of them. Summary of the binding surface (full text in CONTEXT.md, treat that file as authoritative, not this summary):

- **D-01:** Binary tier vocabulary `~w(trusted untrusted)`, `default_tier() = "untrusted"`. No third tier.
- **D-02:** `Scoria.Trust` — dependency-free leaf. `tiers/0`, `default_tier/0`, `tier_key/0` = `"scoria.trust.tier"`, `normalize_tier/1`, `tier/1`, `trusted?/1`, `put_tier/2`.
- **D-03:** Fail-closed reader: absent key ⇒ silently `"untrusted"`; junk value ⇒ `"untrusted"` + `Logger.warning` + `[:scoria, :trust, :fallback]` telemetry. Only exact string `"trusted"` reads trusted.
- **D-04:** Trust is a `Source` property, denormalized onto `Chunk.metadata` at ingest. Canonical value stored at `Source.metadata["scoria.trust.tier"]`. `ingest_source`/`reembed_source`/`reindex_source` derive chunk trust from stored Source value (idempotent w.r.t. trust). No new Ecto column, no new `SpanKind`.
- **D-05:** Host-override API: `Knowledge.create_source(attrs, trust: "trusted")`, `Knowledge.ingest_source(attrs, trust: "trusted")`, `Knowledge.set_source_trust(source, "trusted", scope: ...)` — the last bulk-UPDATEs existing chunk rows scoped by `tenant_id` (mirrors `knowledge.ex:73`'s tenant-scoped pattern). All override values route through `Trust.normalize_tier/1`.
- **D-06:** `Scoria.MCP.Envelope` struct, `@enforce_keys [:value, :tier]`, fields `value, tier, provenance, scan, enveloped_at`. `provenance`: `tool_ref, tool_name, trace_id, workflow_run_id, step_id, args_fingerprint` (id/enum only, no free text). `scan` is `nil` in Phase 55.
- **D-07:** Wrap at `MCP.Executor`'s `{:ok, {:completed, result, duration}}` success branch, AFTER `reconcile_budget`/`emit_sre_telemetry` read the raw value (load-bearing ordering). Add an `actual_units(_ctx, %Envelope{value: v}, o)` defense-in-depth head. Only success/content leg enveloped; `{:error, _}` passes through untouched.
- **D-08:** Taint ALWAYS computed + persisted to `step.result_envelope["scoria.taint"]` (jsonb) + telemetry. Return-SHAPE change is soft-launched behind `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: true` (default off).
- **D-09:** Total accessors `Envelope.wrap/2` (idempotent), `envelope?/1`, `tier/1`, `value/1`, `scan/1`, `unwrap/1`. All total over `Envelope.t() | term()` — unknown/raw value reads `tier ⇒ "untrusted"`, `value ⇒ itself`.
- **D-10:** Replay-stub path (`executor.ex` historical_stub return block) must wrap under the flag too — live and replay return the SAME shape.
- **D-11:** `Scoria.Spotlight.render(items, opts) :: Marked.t()` — standalone, host-called. `Scoria.Orchestrator` is confirmed LLM-fallback-only (no prompt-assembly path); no assembly helper added to it.
- **D-12:** Technique: prose/untyped ⇒ `:datamark`; structured/ambiguous ⇒ `:delimit`. `:encode` offered, documented not-recommended. Nonce = `:crypto.strong_rand_bytes(16) |> Base.encode32(padding: false)`, fresh per call, never logged/persisted. Boundary verified absent from span (bounded retries, e.g. 8, then fall back to `:delimit`). Trusted content passes through byte-identical.
- **D-13:** `render/2` returns the paired instruction as DATA on `Marked{instruction}`, overridable by host template. Scoria never injects a system prompt or decides placement.
- **D-14:** `[:scoria, :spotlight, :marked]` telemetry, measurements `%{marked_spans, marked_bytes}`, metadata `%{technique, tier}` — counts/enums only. `try/rescue -> :ok`. Optional `scoria.spotlight.*` registry keys added to `Semconv.attribute_registry/0`.
- **D-15:** Known residual: host reading `chunk.body` raw bypasses `Spotlight` silently. Docs-only mitigation this phase (`SECURITY-BOUNDARY.md` is Phase 58).
- **D-16:** `Scoria.Trust.Scanner` behaviour: `@callback scan(content, context) :: {:ok, Verdict.t()} | {:ok, :not_scanned} | {:error, term()}`. Default `Scoria.Trust.Scanner.NoOp` returns `{:ok, :not_scanned}`. `Scoria.Trust.Verdict`: `@enforce_keys [:tier]`, fields `tier, score (host-only, never persisted), reason_code, scanner`.
- **D-17:** `Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp)` + per-call `context[:content_scanner]` override — mirrors `req_llm_module` idiom.
- **D-18:** Scan fires at taint-MINTING chokepoints: `Knowledge.retrieve/2` (batch-scan) and `MCP.Executor` envelope creation — NOT solely `Spotlight.render`. `NoOp` short-circuits. Public `Scoria.Trust.scan/2` also callable per-leg. Orchestration lives in `Scoria.Trust.Scan` (separate from the leaf `Scoria.Trust`).
- **D-19:** Monotonic taint law: `resolved = most_restrictive(incoming_tier, verdict_tier)`. Scanner may only ADD taint, never launder untrusted→trusted. Property-tested, single most security-critical invariant.
- **D-20:** Error isolation fails CLOSED: scanner raise/throw/exit/`{:error,_}` ⇒ `%Verdict{tier: "untrusted", reason_code: :scanner_error}`; timeout ⇒ `:scanner_timeout`. Run never crashes, never gains trust from failure. Scan is synchronous by default.
- **D-21:** Trace tagging is a fixed-projector `scoria.trust.*` group on the EXISTING span at each minting site — NOT `Guardrail.emit/1` (classification, not decision). `Semconv.trust_attributes/1`: `tier :enum`, `scanner :id`, `reason_code :enum`, `scanned_count :count`. No `score` key. `reason_code` closed enum `~w(prompt_injection moderation_flag untrusted_source scanner_error scanner_timeout unknown)`, fallback `unknown`.
- **D-22 (cross-phase, Phase 57 inherits):** Phase 57's gate must distinguish content-untrusted from infra-failure-untrusted via `reason_code`; must NOT blindly escalate on `:scanner_error`/`:scanner_timeout`.
- **D-23 (module layout):** `Scoria.Trust` leaf; protocol `Scoria.Trust.Tiered` with `impl` blocks in `Knowledge.Chunk`/`MCP.Envelope` (owning modules) delegating to `Trust.tier(metadata)` — avoids `Knowledge↔Trust`/`MCP↔Trust` compile cycle. Separate modules: `Scoria.Trust.Scanner` (+`NoOp`), `Scoria.Trust.Scan`, `Scoria.Trust.Verdict`, `Scoria.MCP.Envelope`, `Scoria.Spotlight` (+`.Marked`).

### Claude's Discretion

- Exact field names inside `provenance`/`Marked`/`Verdict` beyond those named above, private helper names, and test-file layout — provided the public names in D-01..D-23 are honored.
- Whether the default spotlight instruction template ships as a module attribute vs a function — must be host-overridable per D-13.
- **No UI this phase.** Only operator-observable surface is `scoria.trust.*`/`scoria.spotlight.*` trace attributes (Phase 58 renders them). No `/scoria` screen, LiveView, or brandbook work.

### Deferred Ideas (OUT OF SCOPE)

- **Phase 56:** tool-declared trifecta classification (per-tool declared tier the envelope's default_tier will eventually read); per-run rails.
- **Phase 57:** the confluence evaluator/gate that READS this substrate, including the D-22 reason_code-branching constraint.
- **Phase 58:** read-only Govern surface, moderation/output-scanner eval-seam hooks (separate from `scan/2`), `SECURITY-BOUNDARY.md`.
- **Defense-in-depth follow-ups (not blocking):** Credo/telemetry nudge for raw `chunk.body` access bypassing `Spotlight`; changeset-side trust normalization on `Chunk`/`Source`.
- **Permanently host-owned:** any injection/moderation detector or classifier; per-user/per-intent tool allowlists; opinionated moderation content policy/output sanitizer.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TAINT-01 | Retrieved chunks carry a trust-tier/taint tag on `Knowledge.Chunk` metadata, defaulting to untrusted for externally-sourced/retrieved content | `Scoria.Trust` leaf (D-01..D-03) + `Source.metadata`→`Chunk.metadata` denormalization at `ingest_source/2` (D-04) + host-override API (D-05); verified exact code seams in `## Verified Code Seams` below |
| TAINT-02 | Tool outputs wrapped in an envelope carrying a trust tier | `Scoria.MCP.Envelope` struct (D-06) wrapped at `MCP.Executor`'s success choke point (D-07), soft-launched (D-08), total accessors (D-09), replay-stub parity (D-10); verified executor.ex line-exact anchors below, including a nested-shape correction not present in CONTEXT.md |
| TAINT-03 | At prompt assembly, untrusted content is spotlighted/datamarked with a model-agnostic delimiter | `Scoria.Spotlight.render/2` (D-11..D-15), host-called (confirmed no in-lib assembly path exists); nonce/marker mechanics pinned in D-12 |
| TAINT-04 | Host can register a `scan/2` hook (Rebuff/LlamaGuard-shaped); default no-op leaves behavior unchanged | `Scoria.Trust.Scanner` behaviour + `NoOp` (D-16), registration mirrors `req_llm_module` (D-17), scan anchored at minting chokepoints (D-18), monotonic law (D-19), fail-closed error isolation (D-20), trace tagging via fixed projector (D-21) |
</phase_requirements>

## Summary

This phase adds a pure-mechanism trust substrate on top of code that already has every seam the design assumes — nothing in CONTEXT.md's `<canonical_refs>` breadcrumb list is stale in a way that blocks planning, and one nested-shape detail in `MCP.Executor`'s success branch needs to be made explicit for the planner (see below). The codebase has zero existing `defprotocol`/`defimpl` usage, so D-23's `Scoria.Trust.Tiered` protocol will be the first protocol in Scoria — this is idiomatic, standard Elixir, and exactly the right tool for the stated no-compile-cycle constraint, but the planner should not expect an existing in-repo protocol to mirror; the closest analog is the `Semconv.normalize_reason_code/1` fail-closed-log-telemetry idiom (function-based, not protocol-based) that D-03 explicitly asks `Trust.normalize_tier/1` to mirror.

All four requirement areas share one deliberate constraint that shaped every verified seam: nothing in this phase adds a new Ecto column, a new `SpanKind`, a new dependency, or a new detector. It is jsonb-convention-over-columns (mirroring v3.6), one new `Task.Supervisor` child for scan orchestration (mirroring the existing two), eight new `Semconv.attribute_registry/0` keys (which will deliberately trip the registry canary test at `test/scoria/observe/semconv_test.exs:274-306` — this is D-14/D-21's intended proof-of-work, not a bug to route around), and standard-library crypto (`:crypto.strong_rand_bytes/1`, already used nowhere else in `lib/` — first use — but a zero-risk stdlib call).

**Primary recommendation:** Implement the four requirement areas as four largely-independent module additions (`Scoria.Trust` + `.Tiered`/`.Scanner`/`.Scan`/`.Verdict`, `Scoria.MCP.Envelope`, `Scoria.Spotlight` + `.Marked`) wired into exactly the chokepoints CONTEXT.md names, in this order: (1) `Scoria.Trust` leaf + `Knowledge` integration (TAINT-01) first since it has zero cross-module dependencies; (2) `Scoria.MCP.Envelope` (TAINT-02) second since it depends only on `Scoria.Trust`'s vocabulary via the protocol; (3) `Scoria.Trust.Scanner`/`.Scan`/`.Verdict` (TAINT-04) third since it needs both `Knowledge.retrieve/2` and `MCP.Executor` as call sites; (4) `Scoria.Spotlight` (TAINT-03) last/independently since it has no runtime dependency on the other three (only a shared trust-tier vocabulary read via `Trust.Tiered`).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Chunk/Source trust-tier storage + fail-closed read | Database/Storage (jsonb `metadata` convention) | API/Backend (`Scoria.Trust`, `Scoria.Knowledge`) | Denormalized at write time (ingest), read at query time (retrieve) with zero join — a storage-convention decision (D-04), enforced by an API-tier leaf module |
| Tool-output trust tagging | API/Backend (`Scoria.MCP.Executor`, `Scoria.MCP.Envelope`) | Database/Storage (`step.result_envelope` jsonb) | Minted at the single executor choke point; persisted for inspectability regardless of the soft-launch return-shape flag (D-08) |
| Spotlighting/datamarking | Consumer-owned (host prompt-assembly code) — Scoria exposes a pure function | — | `Scoria.Spotlight.render/2` is a library function the HOST calls before it builds its own prompt string; Scoria owns no prompt-assembly tier at all (confirmed: `Orchestrator` is LLM-fallback-only, no chunks→prompt path exists in-lib) |
| BYO scanner hook + verdict resolution | API/Backend (`Scoria.Trust.Scan` orchestration) | — | Scan fires inside Scoria's own request path (`retrieve/2`, `MCP.Executor`) but the classifier itself is 100% host-supplied via `Application.get_env`/context override (D-17) — Scoria owns the *seam*, host owns the *model* |
| Trace tagging of trust/scan verdicts | Observability tier (`Scoria.Observe`, `Semconv`, existing spans at minting sites) | — | Attaches to spans that already exist (RETRIEVER span from `retrieve/2`, tool telemetry from `MCP.Executor`) rather than minting a new span kind — D-21 explicitly rejects a new `SpanKind` |

## Verified Code Seams

Every file/line CONTEXT.md's `<canonical_refs>`/`<code_context>` named was read directly against the current working tree. All are accurate; one nested-shape clarification is called out.

| CONTEXT.md claim | Verified | Notes |
|---|---|---|
| `knowledge.ex` `ingest_source/2` ~L58-101 | **Exact.** `def ingest_source(source_or_attrs, opts \\ [])` head at L58; the two clauses span L60-94 and L96-101. | No drift. |
| `knowledge.ex` scope stamp ~L78 | **Exact.** L78: `|> Enum.map(&(&1 \|> Map.put(:source_id, source.id) \|> Scope.put_source_attrs(scope)))` inside `Multi.run(:chunks, ...)`. | This is where D-04's chunk-trust derivation from `Source.metadata` must be added (a `Map.put(:metadata, ...)` step alongside the existing `Scope.put_source_attrs/2` call). |
| `knowledge.ex` tenant-scoped update ~L73 | **Present but is a DELETE, not an UPDATE.** L70-75 is `Multi.delete_all(:delete_chunks, from(chunk in Chunk, where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id))`. | D-05 says "mirror the tenant-scoped update at `knowledge.ex:73`" — the actual code at that line is a tenant-scoped `where` clause inside a delete, not an update. The *pattern* (scope by `source_id` AND `tenant_id`) is exactly right to mirror for `set_source_trust/3`'s bulk chunk update; the verb in CONTEXT.md's description is imprecise. Additional idiomatic precedent for the actual `Repo.update_all`/`Multi.update_all` call: `lib/scoria/prompt_registry.ex:114,121`, `lib/scoria/sre/relay.ex:108,143`, `lib/scoria/semantic_cache/invalidation.ex:115`. |
| `knowledge.ex` `retrieve/2` ~L245 | **Exact.** `def retrieve(query_text, opts \\ []) do` at L245. | `retrieve/2` already threads `opts` as a keyword list and computes `trace_id`/`span_id` before calling `backend.similar_chunks/3` — the scan-at-retrieve hook (D-18) has a natural insertion point after `result_rows` is bound (~L282) and before `create_retrieval_run/1` persists metadata, so a scan verdict's `reason_code`/`scanned_count` can be folded into the same `Semconv`-projected metadata map already built at L295-298. |
| `mcp/executor.ex` success branch ~L48-52 | **Exact.** L48-52 is `{:ok, {:completed, result, duration}} -> reconcile_budget(...) ; emit_sre_telemetry(...) ; :telemetry.execute(...) ; result`. | **Nested-shape clarification (not in CONTEXT.md, load-bearing for the planner):** the `result` bound at L48 is NOT the tool's raw return value — it is the tool's own `{:ok, value} \| {:error, reason}` tuple (per the `Tool` behaviour's `@callback execute/2` contract, confirmed in `mcp/tool.ex:26`), because `execute_tool/5`'s `Task.yield` at L202-203 wraps `tool_module.execute(args, context)`'s full return in `{:completed, result, duration}` without unwrapping it. So wrapping per D-07 means: at L52, pattern-match `result` as `{:ok, value} -> {:ok, Envelope.wrap(value, tier: ..., provenance: ...)}` / `{:error, _} = error -> error` — NOT `Envelope.wrap(result, ...)` directly, which would wrap the whole tagged tuple. |
| `mcp/executor.ex` `actual_units` ~L280-289 | **Close, off by 2 at the start.** The full clause set spans L278-290 (a 3-clause multi-head function); the CONTEXT.md range covers the two clauses most relevant to D-07's defense-in-depth ask. L280 already has `defp actual_units(context, {:ok, result}, outcome), do: actual_units(context, result, outcome)` — an existing `{:ok, result}` unwrap head, so an `%Envelope{}`-aware head must be added AFTER that unwrap (i.e. a new clause matching `actual_units(context, %Envelope{value: v}, outcome)` placed before the generic `is_map(result)` clause at L282, or the `is_map` clause's own `Map.has_key?` checks will spuriously miss/hit against a struct). | Struct pattern-matching order matters here: the existing `is_map(result) && Map.has_key?(result, :actual_units)` clause at L284 will NOT match an `%Envelope{}` (Envelope has no `:actual_units` field), so it falls through to `estimated_units(context)` — functionally safe today, but D-07's defense-in-depth head should be added explicitly so a future envelope-carrying tool that DOES report `actual_units` inside `.value` still gets billed correctly. |
| `mcp/executor.ex` `replay_gate` historical-stub block ~L91-97 | **Exact.** L91-97 is the `{:ok, %{status: :historical_stub, ..., result: Map.get(source_evidence, :result) \|\| Map.get(source_evidence, "result")}}` return tuple inside the `{:historical_stub, evidence} ->` branch (branch starts L88). | This is nested one level inside `replay_gate/3` (which itself starts at L79, not L91 — CONTEXT.md's "~L91-97" correctly scopes to the return block, not the function head). D-10's wrap-under-flag applies to the `result:` field's value specifically. |
| `mcp/executor.ex` `build_replay_seam` ~L150-165 | **Exact.** `defp build_replay_seam(tool_module, context) do` spans L150-165. | No drift. |
| `mcp/tool.ex` `@callback execute/2 :: {:ok, any()} \| {:error, any()}` | **Exact**, confirmed at L26. | Confirms the nested-shape finding above — the behaviour itself returns a tagged tuple, not a bare value. |
| `orchestrator.ex` `req_llm_module` swap idiom | **Exact.** L21: `{req_llm_module, options} = Keyword.pop(options, :req_llm_module, Application.get_env(:scoria, :req_llm_module, ReqLLM))`. | This is a Keyword-list per-call override (`options` is a keyword list in `Orchestrator`). D-17's `content_scanner` override sites are different shapes: `retrieve/2`'s `opts` is ALSO a keyword list (so `Keyword.get(opts, :content_scanner, ...)` fits directly, matching the existing `Keyword.get(opts, :retriever)`/`Keyword.get(opts, :embedder, ...)` style at L248-252), but `MCP.Executor`'s `context` is a MAP throughout (confirmed via `canonical_context/1`, `Map.get(context, ...)` used pervasively) — so the executor's override reads as `Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))`. Both are "the `req_llm_module` precedent" per D-17, but the accessor differs by call-site container type; note this for the planner so a task doesn't literally copy `Keyword.pop` into the executor's map-based context. |
| `observe/semconv.ex` `attribute_registry/0`, `normalize_reason_code/1`, `retrieval_config_attributes/1`, `merge_host_declared/2` | **All exact**, confirmed by direct read of `observe/semconv.ex`. | `attribute_registry/0` is a **compile-time module attribute** (`@attribute_registry Map.merge(...)`), not computed per-call — adding `scoria.trust.*`/`scoria.spotlight.*` keys means editing that `@attribute_registry` literal directly (semconv.ex L319-347) plus every downstream reference. |
| `observe/span_kind.ex` fixed 8-value taxonomy | **Exact.** `@kinds ~w(agent llm prompt tool mcp retriever guardrail eval)` at L24 — 8 values. | Confirms "do NOT add a taint kind" is enforceable; no code change needed there, this phase adds zero new span kinds (D-04/D-21 both explicit on this). |
| `observe/bounds.ex` | **Exact**, read directly. Registry-only admission (`Semconv.attribute_registry/0` exact match, or vendor/host prefix) — confirmed `scoria.` keys are REGISTRY-ONLY (no prefix escape), so `scoria.trust.*`/`scoria.spotlight.*` MUST be added to `attribute_registry/0` or `Scoria.Observe.Bounds.enforce/2` will silently DROP them at the tollbooth (not truncate — drop). | This is a hard requirement, not optional: skipping the registry edit means the new attributes never reach Postgres even if the span code emits them correctly. |
| `observe.ex` `emit_retriever_span/1`, `emit_event/1` | **Both exact**, confirmed by direct read. `emit_retriever_span/1` is success-path-only (called after `retrieve/2`'s with-chain succeeds, L301 in `knowledge.ex`) and already builds its span via `build_span_map/7` — the trust/scan attributes (D-21) attach to the SAME span-map builder call, not a second span. | No new emitter function needed for D-21's projector attachment — it merges into the `attributes` map already passed to `emit_retriever_span/1`'s internal `Semconv.retrieval_config_attributes/1 \|> Semconv.merge_host_declared/2` pipeline (`observe.ex` L242-244). |
| `workflows/step.ex` `result_envelope :map` field | **Exact.** Schema field at L19 (`field :result_envelope, :map, default: %{}`), cast in `changeset/2` at L47. | Confirmed jsonb home for D-08's always-persisted taint data exists and is already writable via the standard changeset. |

**No stale line numbers found.** All canonical_refs anchors are current against the working tree at research time.

## Module-Layout Feasibility (D-23)

**Confirmed feasible, and confirmed to be the FIRST protocol usage in this codebase.** `grep -rn "defprotocol\|defimpl" lib/` returns zero matches — Scoria currently has no protocols anywhere. This is not a red flag: `Scoria.Trust.Tiered` (a two-function protocol dispatching on struct type, with `impl` blocks living in `Knowledge.Chunk` and `MCP.Envelope`) is the textbook Elixir solution to "a leaf vocabulary module needs polymorphic dispatch over structs defined in modules that would otherwise have to depend on it" — it is standard, idiomatic, and exactly what protocols exist for. There is no existing in-repo analog to point to for "how we do protocols here" (this will BE that analog going forward), but the closest sibling pattern (a leaf module other modules "reach into" without a compile dependency in the other direction) is `Semconv`'s registration-by-reference of `Scoria.Trust.tier_key/0` etc. — a plain function reference, not a protocol, but the same "leaf owns vocabulary, callers reach in" shape D-02/D-23 describe.

⚠ No design-conflict finding — this is confirmed achievable exactly as specified.

**application.ex landmine:** `Scoria.Trust.Scan`'s bounded-timeout scanner orchestration (D-20, mirroring "the `MCP.Executor` supervised-Task discipline") needs a `Task.Supervisor`. `lib/scoria/application.ex` L10-21 currently registers exactly two: `{Task.Supervisor, name: Scoria.MCP.TaskSupervisor}` (L18) and `{Task.Supervisor, name: Scoria.Workflow.TaskSupervisor}` (L19). **Reusing `Scoria.MCP.TaskSupervisor` from `Scoria.Trust.Scan` would create a `Knowledge`/`Trust` → `MCP` dependency** (since `Scoria.Trust.Scan` orchestrates scanning for BOTH `Knowledge.retrieve/2` and `MCP.Executor` call sites) — this is exactly the kind of coupling D-23's leaf-module discipline is trying to avoid one layer up. The clean fix: add a third named supervisor, `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}`, to `application.ex`'s children list (mirroring the existing two-supervisor pattern at L18-19), and have `Scoria.Trust.Scan` own it independently. This is a one-line `application.ex` addition the planner should schedule as an explicit task — it is easy to miss because CONTEXT.md's breadcrumbs don't mention `application.ex` at all.

## Standard Stack

### Core

No new Hex dependencies. This phase is pure Elixir/OTP + the existing `:crypto`/`:telemetry`/`Ecto` stack already in `mix.exs`.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (Erlang/OTP stdlib) | ships with OTP (Scoria pins `elixir: "~> 1.19"`, OTP 26+ implied) | `:crypto.strong_rand_bytes/1` for the D-12 per-call nonce | Cryptographically-secure RNG, zero new dependency, already the OTP-standard choice for nonce/token generation across the Elixir ecosystem `[ASSUMED — training knowledge; :crypto is part of the OTP standard library shipped with every Elixir install, not independently version-pinned by Scoria]` |
| `:telemetry` | already a transitive dep (via `phoenix`/`ecto_sql`) | `[:scoria, :trust, :fallback]`, `[:scoria, :spotlight, :marked]` events | Existing Scoria-wide event-emission convention (`[:scoria, :observe, :*]`, `[:scoria, :orchestrator, :*]`) — no new library |

### Supporting

None required. `Base.encode32/2` (Elixir stdlib) for the nonce string encoding per D-12; no new dep.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Exhaustive ExUnit enumeration for D-19's "property-tested" monotonic law | `stream_data` (property-based testing lib) | **Not needed.** The trust enum is binary (`trusted`/`untrusted`), so the full input space for `most_restrictive/2` is 2×2 = 4 combinations plus a handful of junk-input fail-closed cases — exhaustive `ExUnit` enumeration IS complete property coverage here, not an approximation of it. `stream_data` is not in `mix.exs` today; adding it purely for this law would be a new test-only dependency for a domain small enough not to need one. See `## Validation Architecture` below. |
| Hand-rolled fixed-string delimiter | `:crypto.strong_rand_bytes/1` + `Base.encode32/2` nonce (as locked in D-12) | Locked decision, not open — noted here only to confirm the exact stdlib call names resolve correctly: `:crypto.strong_rand_bytes(16)` returns a 16-byte binary; `Base.encode32(binary, padding: false)` is a valid 2-arity call (confirmed against Elixir's `Base` module, which accepts `padding:` as a boolean opt) `[ASSUMED — training knowledge, Base.encode32/2 API surface not independently verified via doc lookup this session]` |

## Package Legitimacy Audit

**Not applicable — this phase installs zero external packages.** No `npm view`/`pip index`/`cargo search` verification needed; every module added is new first-party `lib/scoria/**` code, and every runtime call (`:crypto`, `:telemetry`, `Ecto`, `Task.Supervisor`) is either OTP-stdlib or an existing `mix.exs` dependency already in the tree.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────────┐
                         │  HOST APPLICATION                        │
                         │  (owns prompt assembly, calls Spotlight  │
                         │   before building its own prompt string) │
                         └───────────────┬───────────────────────────┘
                                         │ calls
                                         ▼
   ┌──────────────────────────────────────────────────────────────────────┐
   │                         Scoria.Spotlight.render/2                    │
   │  reads tier via Scoria.Trust.Tiered protocol on each item            │
   │  untrusted → :datamark (prose) | :delimit (structured/ambiguous)     │
   │  trusted   → byte-identical passthrough                              │
   │  returns %Marked{marked, instruction, technique, tier, spans}        │
   │  emits [:scoria, :spotlight, :marked] (counts/enums only)            │
   └──────────────────────────────────────────────────────────────────────┘
                ▲ reads tier                          ▲ reads tier
                │                                     │
   ┌────────────┴─────────────┐         ┌─────────────┴──────────────────┐
   │  Scoria.Knowledge          │         │  Scoria.MCP.Executor            │
   │  ─────────────────────     │         │  ─────────────────────          │
   │  ingest_source/2:          │         │  execute_live/4 success branch: │
   │   Source.metadata["tier"]  │         │   {:completed, result, dur} ->  │
   │   → denormalized onto      │         │    reconcile_budget (raw)       │
   │   Chunk.metadata (D-04)    │         │    emit_sre_telemetry (raw)     │
   │                             │         │    result = {:ok,v}|{:error,r} │
   │  retrieve/2:                │         │    → wrap v in Envelope        │
   │   result_rows → scan        │         │      (soft-launch flag, D-08)  │
   │   (Scoria.Trust.Scan,       │         │    → replay_gate historical-   │
   │    D-18) → tag RETRIEVER    │         │      stub wraps too (D-10)     │
   │   span (scoria.trust.*)     │         │    → Scan at envelope creation │
   └─────────────────────────────┘         │      (D-18) tags tool span     │
                ▲                          └──────────────────────────────────┘
                │ reads/normalizes                    ▲
                │                                      │
   ┌────────────┴──────────────────────────────────────┴──────────────────┐
   │                         Scoria.Trust  (LEAF — no deps)                │
   │  tiers/0, default_tier/0, tier_key/0, normalize_tier/1,               │
   │  tier/1 (fail-closed), trusted?/1, put_tier/2                        │
   │  protocol Scoria.Trust.Tiered  (impls live in Chunk, Envelope)        │
   └─────────────────────────────────────────────────────────────────────┘
                ▲
                │ orchestrates (separate module, D-23)
   ┌────────────┴──────────────────────────────────────────────────────────┐
   │  Scoria.Trust.Scan → Scoria.Trust.Scanner (behaviour) → host impl      │
   │  bounded Task (own Scoria.Trust.TaskSupervisor) → Scoria.Trust.Verdict │
   │  monotonic law (D-19): resolved = most_restrictive(incoming, verdict) │
   │  fail-closed on error/timeout (D-20)                                  │
   └─────────────────────────────────────────────────────────────────────┘
```

A reader can trace TAINT-01 end to end: host calls `ingest_source` → `Source.metadata` tier stored → denormalized onto `Chunk.metadata` → `retrieve/2` reads chunks (already tiered, no join) → optional scan at retrieve tags the RETRIEVER span → host later calls `Spotlight.render/2` on the retrieved chunks before assembling its own prompt.

### Recommended Project Structure

```
lib/scoria/
├── trust.ex                    # leaf: tiers/0, default_tier/0, tier_key/0,
│                                #   normalize_tier/1, tier/1, trusted?/1, put_tier/2
├── trust/
│   ├── tiered.ex                # defprotocol Scoria.Trust.Tiered
│   ├── scanner.ex               # @behaviour + Scoria.Trust.Scanner.NoOp
│   ├── scan.ex                  # orchestration: bounded Task, monotonic law, error isolation
│   └── verdict.ex               # %Scoria.Trust.Verdict{}
├── mcp/
│   └── envelope.ex              # %Scoria.MCP.Envelope{}, wrap/2, envelope?/1, tier/1,
│                                 #   value/1, scan/1, unwrap/1 + defimpl Trust.Tiered
├── knowledge/
│   └── chunk.ex                 # + defimpl Scoria.Trust.Tiered, delegates to Trust.tier(metadata)
├── spotlight.ex                 # Scoria.Spotlight.render/2
└── spotlight/
    └── marked.ex                # %Scoria.Spotlight.Marked{}
```

### Pattern 1: Fail-closed reader mirrors `Semconv.normalize_reason_code/1`

**What:** Every trust-tier read (chunk, envelope, verdict) normalizes through one function that treats absence as silent-default and junk as logged-default, never raising.
**When to use:** Any place a `"scoria.trust.tier"` string is read out of a jsonb map that may contain legacy/absent/malformed data.
**Example (verified pattern from `observe/semconv.ex:436-455`, adapt for `Scoria.Trust.normalize_tier/1`):**
```elixir
# Source: lib/scoria/observe/semconv.ex:436-455 (Scoria.Observe.Semconv.normalize_reason_code/1)
# Scoria.Trust.normalize_tier/1 should mirror this exact shape (D-03), with two
# behavioral branches instead of one: absent -> SILENT default; present-but-junk -> LOGGED default.
def normalize_reason_code(value) do
  normalized = to_string(value)

  if normalized in @guardrail_reason_codes do
    normalized
  else
    Logger.warning("Unrecognized guardrail reason_code #{inspect(value)}, defaulting to \"unknown\"")

    try do
      :telemetry.execute([:scoria, :observe, :guardrail, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    "unknown"
  end
end
```

### Pattern 2: Registry-gated new attribute keys (mandatory, not optional)

**What:** Any new `scoria.trust.*`/`scoria.spotlight.*` span attribute key must be added to `Semconv.attribute_registry/0`'s compile-time `@attribute_registry` map (semconv.ex L319-347) AND to the exact sorted-list canary test at `test/scoria/observe/semconv_test.exs:274-306`, or `Scoria.Observe.Bounds.enforce/2` silently DROPS the attribute at the tollbooth before it reaches Postgres.
**When to use:** Every new key introduced by D-14 (`technique`, `marked_spans`, `marked_bytes`, `tier` under `scoria.spotlight.*`) and D-21 (`tier`, `scanner`, `reason_code`, `scanned_count` under `scoria.trust.*`).
**Example:**
```elixir
# Source: lib/scoria/observe/semconv.ex:242-256 (existing guardrail_keys/0 pattern to mirror)
@trust_keys [
  tier: "scoria.trust.tier",
  scanner: "scoria.trust.scanner",
  reason_code: "scoria.trust.reason_code",
  scanned_count: "scoria.trust.scanned_count"
]

@spotlight_keys [
  technique: "scoria.spotlight.technique",
  marked_spans: "scoria.spotlight.marked_spans",
  marked_bytes: "scoria.spotlight.marked_bytes",
  tier: "scoria.spotlight.tier"
]

# then merge both key sets' string values into @attribute_registry with their
# declared classes (:enum, :id, :count) exactly as the existing
# @guardrail_keys / guardrail_attributes/1 pair does at semconv.ex:242-275, 458-474.
```

### Pattern 3: Protocol-based leaf/foreign-struct dispatch (D-23, first use in repo)

**What:** `Scoria.Trust` stays dependency-free; `Scoria.Trust.Tiered` protocol dispatches on struct type; `impl` blocks live in the struct's OWN module.
**When to use:** Whenever a leaf module needs to read a tier off a struct defined in a module that must not depend on the leaf (avoiding `Knowledge↔Trust`/`MCP↔Trust` compile cycles).
**Example:**
```elixir
# lib/scoria/trust/tiered.ex
defprotocol Scoria.Trust.Tiered do
  @spec tier(t) :: String.t()
  def tier(item)
end

# lib/scoria/knowledge/chunk.ex — impl added to the OWNING module, not to Trust
defimpl Scoria.Trust.Tiered, for: Scoria.Knowledge.Chunk do
  def tier(%Scoria.Knowledge.Chunk{metadata: metadata}), do: Scoria.Trust.tier(metadata)
end

# lib/scoria/mcp/envelope.ex — same pattern
defimpl Scoria.Trust.Tiered, for: Scoria.MCP.Envelope do
  def tier(%Scoria.MCP.Envelope{tier: tier}), do: Scoria.Trust.normalize_tier(tier)
end
```

### Anti-Patterns to Avoid

- **Wrapping the whole `{:ok, value} | {:error, reason}` tuple in `MCP.Executor`'s success branch:** the `result` bound at `executor.ex:48` is that tagged tuple, not the raw tool value (see `## Verified Code Seams` above) — wrapping it directly would produce `{:ok, %Envelope{value: {:ok, actual_value}}}`, double-nesting and breaking every downstream `Envelope.value/1` accessor's contract.
- **Reusing `Scoria.MCP.TaskSupervisor` for `Scoria.Trust.Scan`'s bounded scanner Task:** creates an undocumented `Knowledge → MCP` dependency (since `Scan` serves both `retrieve/2` and the executor). Add a dedicated `Scoria.Trust.TaskSupervisor` child instead.
- **Adding a `scoria.trust.*` or `scoria.spotlight.*` key to a span's `attributes` map without also editing `Semconv.attribute_registry/0`:** `Bounds.enforce/2`'s registry-only admission for `scoria.`-prefixed keys means the attribute is silently DROPPED, not truncated, not logged as an error — it just never reaches Postgres. The canary test failure at `semconv_test.exs:276` is the ONLY signal; if a task skips updating that literal sorted list, the new keys still work at the Elixir level but the registry test catches the drift (by design, per D-14).
- **Persisting `Verdict.score` anywhere:** D-16/D-21 both explicitly forbid this — `score` is host-only, never touches a trace or a jsonb column. A task that threads `score` through to `step.result_envelope["scoria.taint"]` or a span attribute violates the locked design.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cryptographically-secure nonce generation | A custom PRNG or `:rand`-based token | `:crypto.strong_rand_bytes/1` (D-12, locked) | `:rand` is NOT cryptographically secure in Erlang/OTP; `:crypto.strong_rand_bytes/1` is the OTP-standard CSPRNG call for exactly this use case `[ASSUMED — training knowledge on OTP crypto module guarantees]` |
| Prompt-injection/content-moderation detection | Any classifier, regex-based injection heuristic, or keyword-blocklist scanner | `Scoria.Trust.Scanner` BYO behaviour (host brings Rebuff/LlamaGuard/etc.) | Explicit, repeated scope-doctrine boundary (REQUIREMENTS.md Out-of-Scope table, SEED-010's "Disagreements with the memo" section) — building a detector is the named over-reach anti-pattern this milestone deliberately avoids |
| Property-based fuzz testing infrastructure for a 2-value enum | `stream_data`-based generators for D-19's monotonic law | Exhaustive `ExUnit` enumeration over the 4-combination input space | The full input space is small enough that exhaustive enumeration achieves complete property coverage without a new test dependency — see `## Validation Architecture` |

**Key insight:** Every "don't hand-roll" item in this phase is really the SAME insight stated three ways: the mechanism (tagging, wrapping, marking, seaming) is Scoria's to build; the content judgment (what counts as untrusted, what counts as injection) stays host-owned. The phase's entire design is organized around never letting that line blur, down to the level of which module owns which struct field.

## Common Pitfalls

### Pitfall 1: Wrapping the nested `{:ok, value}` tuple instead of unwrapping first

**What goes wrong:** A task implements D-07 by calling `Envelope.wrap(result, ...)` directly on the `result` variable bound at `executor.ex:48`, producing `{:ok, %Envelope{value: {:ok, actual_value}, ...}}` — every downstream `Envelope.value/1` call then returns a tagged tuple instead of the tool's real payload.
**Why it happens:** CONTEXT.md's D-07 describes the wrap point as "the `{:ok, {:completed, result, duration}}` branch" without stating that `result` is itself `{:ok, value} | {:error, reason}` — this is a genuine gap between the locked decision's prose and the actual code shape, filled by this research's `## Verified Code Seams` finding.
**How to avoid:** Pattern-match `result` into its `{:ok, value}`/`{:error, reason}` shape BEFORE calling `Envelope.wrap/2`, and only wrap the `:ok` leg's `value`.
**Warning signs:** A test asserting `Envelope.value(envelope) == raw_tool_return` fails with the value being `{:ok, raw_tool_return}` instead of `raw_tool_return`.

### Pitfall 2: New `scoria.trust.*`/`scoria.spotlight.*` keys silently dropped by `Bounds`

**What goes wrong:** A task wires span emission code that puts `"scoria.trust.tier"` into a span's `attributes` map but forgets to add the key to `Semconv.attribute_registry/0`'s `@attribute_registry` literal — the attribute compiles fine, the span emits fine, but `Scoria.Observe.Bounds.enforce/2` drops it before persistence (registry-only admission for `scoria.`-prefixed keys, confirmed in `observe/bounds.ex`).
**Why it happens:** The registry edit and the emission-site edit are in two different files with no compiler-enforced link between them; only a test catches the gap.
**How to avoid:** Update `Semconv.attribute_registry/0` (adding both the key-string constants and merging them into `@attribute_registry`) in the SAME task/commit as the emission code, and update the exact sorted-list canary test at `semconv_test.exs:274-306` to include the new keys — this is the deliberate, expected RED-then-GREEN this phase should produce (D-14 calls this out explicitly as intended).
**Warning signs:** `test/scoria/observe/semconv_test.exs`'s registry canary test goes RED with a diff showing new keys present in the emitted span but absent from the pinned list — this is the CORRECT signal to update the pinned list, not a bug to work around.

### Pitfall 3: `Scoria.Trust.Scan` accidentally coupling `Knowledge`/`MCP` through a shared `Task.Supervisor`

**What goes wrong:** A task wires `Scoria.Trust.Scan`'s bounded scanner Task through `Scoria.MCP.TaskSupervisor` (the only existing supervisor with the right shape/reuse-invites-reuse instinct), creating a `Knowledge → MCP` module dependency that D-23's leaf-module discipline was explicitly designed to prevent one layer up.
**Why it happens:** `application.ex` isn't in CONTEXT.md's breadcrumb list at all, so there's no explicit prompt to add a new supervisor; reusing an existing one is the path of least resistance.
**How to avoid:** Add `{Task.Supervisor, name: Scoria.Trust.TaskSupervisor}` to `application.ex`'s children list (mirroring the existing `Scoria.MCP.TaskSupervisor`/`Scoria.Workflow.TaskSupervisor` pattern at L18-19) as an explicit task.
**Warning signs:** `Scoria.Trust.Scan`'s module requires `alias Scoria.MCP.Executor` or similar for supervisor access; a `mix xref` graph check (if one exists in CI) shows `Scoria.Knowledge` → `Scoria.MCP`.

### Pitfall 4: Chunk trust reverting to `untrusted` on re-embed

**What goes wrong:** `reembed_source/2`/`reindex_source/2` re-derive chunk trust from a stale default instead of the persisted `Source.metadata["scoria.trust.tier"]` value, silently reverting a host's earlier `set_source_trust/3` call back to `untrusted` on the next re-embed.
**Why it happens:** `reembed_source/2` (knowledge.ex L103-110) currently only re-embeds vectors (`backend.upsert_chunk_embeddings/2`) — it does NOT touch `Chunk.metadata` at all today, so this is a genuinely new code path, not an existing one that "just needs a tweak." A naive implementation might reconstruct chunk attrs from scratch using `Trust.default_tier()` instead of reading the persisted `Source.metadata` value.
**How to avoid:** D-04's red-team fix is explicit: `ingest_source`/`reembed_source`/`reindex_source` must all derive chunk trust FROM the stored `Source.metadata` value, never from a fresh default. This needs an explicit read of `source.metadata["scoria.trust.tier"]` (via `Trust.tier/1`, the fail-closed reader) at each of these three call sites, since `reembed_source/2` doesn't currently touch `Chunk.metadata` and `reindex_source/2` delegates to `reembed_source/2` (knowledge.ex L112-119).
**Warning signs:** A test that sets `trust: "trusted"` on ingest, then calls `reembed_source/2`, then reads chunk metadata again and finds `"untrusted"`.

## Code Examples

### Fail-closed tier reader (D-03, mirroring the verified `normalize_reason_code/1` shape)

```elixir
# Source: adapted from lib/scoria/observe/semconv.ex:436-455 (verified this session)
defmodule Scoria.Trust do
  require Logger

  @tiers ~w(trusted untrusted)
  @tier_key "scoria.trust.tier"

  def tiers, do: @tiers
  def default_tier, do: "untrusted"
  def tier_key, do: @tier_key

  # Absent key -> SILENT untrusted (old rows legitimately lack the key, D-03).
  # Present-but-junk -> untrusted + Logger.warning + telemetry (D-03).
  # Only the exact string "trusted" reads trusted.
  def tier(metadata) when is_map(metadata) do
    case Map.get(metadata, @tier_key) do
      nil -> default_tier()
      "trusted" -> "trusted"
      "untrusted" -> "untrusted"
      junk -> fallback(junk)
    end
  end

  defp fallback(value) do
    Logger.warning("Unrecognized #{@tier_key} #{inspect(value)}, defaulting to \"untrusted\"")

    try do
      :telemetry.execute([:scoria, :trust, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    default_tier()
  end

  def trusted?(metadata), do: tier(metadata) == "trusted"

  def normalize_tier(value) when value in @tiers, do: value
  def normalize_tier(value), do: fallback(value)

  def put_tier(metadata, tier) when is_map(metadata), do: Map.put(metadata, @tier_key, normalize_tier(tier))
end
```

### Monotonic taint resolution (D-19)

```elixir
# Trivial for a binary enum — "if either is untrusted, untrusted" — but expressed
# generically so a future tier addition (if ever) doesn't require touching call sites.
defp most_restrictive(a, b) do
  order = %{"untrusted" => 0, "trusted" => 1}
  if Map.fetch!(order, a) <= Map.fetch!(order, b), do: a, else: b
end
```

## State of the Art

Not applicable in the conventional sense — there is no "old approach being replaced" for this phase; it is net-new mechanism. The one relevant historical-pattern table is prior-art adoption, already fully specified in CONTEXT.md's `<specifics>` section (Perl taint default-on vs Ruby `$SAFE` opt-in; MSRC datamarking; OWASP LLM01 closing-delimiter injection; MCP `CallToolResult`'s single-source-of-truth payload; LangChain `ToolMessage.status`'s dead-metadata anti-pattern). No further research needed here — CONTEXT.md's citations are sufficient and this research found nothing to add or contradict.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:crypto.strong_rand_bytes/1` is the correct OTP-standard CSPRNG call and is available without any dependency addition on the pinned `elixir: "~> 1.19"` toolchain | Standard Stack, Don't Hand-Roll | Low — this is a decades-stable Erlang/OTP stdlib function; if somehow unavailable, `:crypto` app would need adding to `extra_applications` in `mix.exs` (currently only `:logger`), a one-line fix |
| A2 | `Base.encode32/2` accepts a `padding: false` keyword option in the Elixir stdlib version this codebase's `elixir: "~> 1.19"` constraint resolves to | Alternatives Considered | Low — `Base.encode32/2`'s `padding:` option has been stable since early Elixir 1.x; if the API differs, it's a one-line call-site fix, not a design problem |
| A3 | Exhaustive ExUnit enumeration (not `stream_data`) is sufficient to satisfy D-19's "property-tested" language given the binary tier enum | Alternatives Considered, Validation Architecture | Medium — if the planner or a reviewer interprets "property-tested" as requiring an actual PBT library regardless of domain size, this recommendation would need revisiting (add `stream_data` as a `:test`-only dep); does not block correctness, only test-framework choice |

**If this table is empty:** N/A — see above; three low/medium-risk assumptions logged, none touching the locked design surface.

## Open Questions (RESOLVED)

> Both resolved during planning (2026-07-27): Q1 → Plan 55-03 Task 1 (`Spotlight.render/2` re-derives tier via the `Trust.Tiered` protocol per item); Q2 → Plan 55-04 Task 2 (`Scoria.Trust.scan/2` implemented as a thin public delegator to `Scoria.Trust.Scan`, preserving the D-23 leaf constraint). Neither was blocking; both were executor-discretion wiring details.

1. **RESOLVED — Exact field name collision between `Scoria.Spotlight.Marked{tier}` and the D-21 `scoria.spotlight.tier` registry key vs. the D-02 `Scoria.Trust.tier_key/0` = `"scoria.trust.tier"` string**
   - What we know: D-14 names a `tier :enum` field under `scoria.spotlight.*`, distinct from D-02/D-21's `scoria.trust.tier`/`scoria.trust.*` group — these are two different dotted-key namespaces (`scoria.spotlight.tier` vs `scoria.trust.tier`), not a literal string collision.
   - What's unclear: whether `Scoria.Spotlight.Marked.tier` should be sourced by re-reading the same `Trust.tier/1` value already resolved upstream (at `Knowledge.retrieve/2` or wherever the host got the item), or independently re-derived by `Spotlight.render/2` via the `Trust.Tiered` protocol on each input item.
   - Recommendation: `Spotlight.render/2` should call `Trust.Tiered.tier/1` (via the protocol) on each item itself — this is what D-12 implies ("prose/untyped untrusted content ⇒ `:datamark`") and keeps `Spotlight` from requiring a pre-resolved tier as an extra parameter. Left as executor discretion per CONTEXT.md's "private helper names ... executor discretion" carve-out — this is a call-site wiring detail, not a public-API naming question.

2. **RESOLVED — Whether `Scoria.Trust.scan/2` (the public per-leg host-callable function, D-18) and `Scoria.Trust.Scan`'s internal orchestration expose the same or different function signatures**
   - What we know: D-18 names both — a public `Scoria.Trust.scan/2` "also callable per-leg by hosts," and a separate `Scoria.Trust.Scan` module for the internal chokepoint orchestration (Task timeout, error isolation, telemetry, monotonic law).
   - What's unclear: whether `Scoria.Trust.scan/2` (on the leaf module) is a thin public delegator to `Scoria.Trust.Scan`'s internal logic, or a genuinely separate simpler synchronous-only entry point without the bounded-Task machinery.
   - Recommendation: Given D-23's leaf-module constraint ("Scoria.Trust must remain a dependency-free leaf"), `Scoria.Trust.scan/2` living ON the leaf module while calling into `Scoria.Trust.Scan` (a sibling, not a dependency `Trust` requires to compile) is fine IF `Trust.scan/2` is implemented as a thin wrapper that itself has no compile-time dependency on `Scan` beyond a runtime `apply/3` or the public function simply lives on `Scan` and is aliased/documented as `Scoria.Trust.scan/2` in moduledocs without literally being defined in `trust.ex`. This is a naming/delegation-shape decision for the planner, not a blocking ambiguity — flag as a task-level decision point, not a redesign.

## Environment Availability

Skipped — this phase has no external tool/service/runtime dependencies beyond what's already running in every other phase of this codebase (Postgres via `Scoria.Repo`, the standard Elixir/OTP runtime, `:telemetry`). No new CLI, database, or third-party service is introduced.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir `~> 1.19`) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/scoria/trust/ test/scoria/mcp/envelope_test.exs test/scoria/spotlight_test.exs` (new files this phase) |
| Full suite command | `mix test` (project has no dedicated "policy lane" alias for this domain; existing precedent is `mix test --no-start --warnings-as-errors` for guard/contract-only tests, but Trust/Envelope/Spotlight tests need `async: false`/DB access at the `Knowledge`/`MCP.Executor` integration points, so they belong in the normal `mix test` run, not the no-start lane) |

Existing test-support precedent confirmed: `test/support/knowledge_case.exs` (used by `Scoria.Knowledge.RetrievalTest` via `use Scoria.KnowledgeCase, async: false`) is the right `case` template to extend for TAINT-01/TAINT-04's `retrieve/2` integration tests. `Scoria.MCP.ExecutorTest` (`test/scoria/mcp/executor_test.exs`) uses plain `ExUnit.Case, async: false` — mirror this for `Scoria.MCP.Envelope`/executor-integration tests. `Scoria.Observe.SemconvTest` uses `ExUnit.Case, async: true` (no DB) — mirror this for pure `Scoria.Trust`/`Scoria.Spotlight` unit tests that don't touch Ecto.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAINT-01 | `Trust.tier/1` fail-closed: absent key silent-untrusted, junk value logged-untrusted, exact `"trusted"` reads trusted | unit | `mix test test/scoria/trust_test.exs -x` | ❌ Wave 0 |
| TAINT-01 | `ingest_source/2` derives chunk trust from `Source.metadata`, denormalized onto every chunk row | integration (DB) | `mix test test/scoria/knowledge_test.exs --only trust -x` | ❌ Wave 0 |
| TAINT-01 | `reembed_source/2`/`reindex_source/2` preserve (don't revert) a previously-set trust tier | integration (DB) — regression for Pitfall 4 | `mix test test/scoria/knowledge_test.exs --only trust_idempotent -x` | ❌ Wave 0 |
| TAINT-01 | `set_source_trust/3` bulk-UPDATEs chunk rows scoped by `tenant_id`, never cross-tenant | integration (DB) | `mix test test/scoria/knowledge_test.exs --only trust_override -x` | ❌ Wave 0 |
| TAINT-02 | `Envelope.wrap/2` idempotent (no double-wrap on `envelope?/1` guard); total accessors over `Envelope.t() \| term()` | unit | `mix test test/scoria/mcp/envelope_test.exs -x` | ❌ Wave 0 |
| TAINT-02 | `MCP.Executor` success branch wraps `{:ok, value}` correctly (not the tagged tuple — Pitfall 1 regression), `{:error, _}` passes through untouched | integration | `mix test test/scoria/mcp/executor_test.exs --only envelope -x` | ❌ Wave 0 (extends existing file) |
| TAINT-02 | Replay-stub path returns the SAME shape as live execution under the flag (D-10) | integration | `mix test test/scoria/mcp/executor_test.exs --only replay_envelope_parity -x` | ❌ Wave 0 |
| TAINT-02 | Soft-launch flag off = byte-identical `{:ok, value}` return (0.1.3 compat) | regression | `mix test test/scoria/mcp/executor_test.exs --only envelope_flag_off -x` | ❌ Wave 0 |
| TAINT-03 | `:datamark` for prose, `:delimit` for structured/ambiguous; trusted content byte-identical passthrough | unit | `mix test test/scoria/spotlight_test.exs -x` | ❌ Wave 0 |
| TAINT-03 | Nonce/marker verified absent from span, bounded retry (8) falls back to `:delimit` | unit (deterministic — inject a marker-colliding fixture) | `mix test test/scoria/spotlight_test.exs --only marker_collision -x` | ❌ Wave 0 |
| TAINT-03 | `[:scoria, :spotlight, :marked]` telemetry carries counts/enums only, never raw text | unit (telemetry capture) | `mix test test/scoria/spotlight_test.exs --only telemetry -x` | ❌ Wave 0 |
| TAINT-04 | `NoOp` scanner is a true no-op — byte-identical behavior, zero telemetry, at both `retrieve/2` and executor sites | integration | `mix test test/scoria/trust/scan_test.exs --only noop -x` | ❌ Wave 0 |
| TAINT-04 | Monotonic law: scanner may only ADD taint, never launder untrusted→trusted (D-19, exhaustive over 4-combination input space) | unit — exhaustive enumeration serves as the property test (see Alternatives Considered) | `mix test test/scoria/trust/scan_test.exs --only monotonic -x` | ❌ Wave 0 |
| TAINT-04 | Error isolation: scanner raise/throw/exit/`{:error,_}`/timeout all resolve to `untrusted` + correct `reason_code`, run never crashes | unit | `mix test test/scoria/trust/scan_test.exs --only error_isolation -x` | ❌ Wave 0 |
| TAINT-04 | Registration override chain: `Application.get_env` default → per-call context override (mirrors `req_llm_module`) | unit | `mix test test/scoria/trust/scanner_test.exs -x` | ❌ Wave 0 |
| TAINT-04 | `Semconv.attribute_registry/0` canary trips on the 8 new keys; `attribute_registry/0` sorted-list test updated | regression (structural) | `mix test test/scoria/observe/semconv_test.exs --only registry_canary -x` | ✅ exists at `semconv_test.exs:274-306`, needs literal-list update |
| TAINT-04 | `Bounds.enforce/2` admits the new `scoria.trust.*`/`scoria.spotlight.*` keys once registered (regression for Pitfall 2) | unit | `mix test test/scoria/observe/bounds_test.exs --only trust_keys -x` | Check — file likely exists from Phase 53, needs new cases |

### Sampling Rate

- **Per task commit:** the quick-run command scoped to the files that task touched (e.g. `mix test test/scoria/trust_test.exs`).
- **Per wave merge:** `mix test` (full suite) — this phase touches `Semconv`'s compile-time registry attribute and `MCP.Executor`'s success branch, both of which are exercised by dozens of pre-existing tests across `test/scoria/observe/`, `test/scoria/mcp/`, and `test/scoria/knowledge/`; a full-suite run at wave boundaries is the only way to catch cross-cutting regressions (e.g. the registry canary, or `actual_units/3` billing behavior for non-Envelope tools).
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus explicit confirmation that `mix test --warnings-as-errors` (the project's existing WAE convention, confirmed via `mix.exs`'s `scoria.ci`/policy-lane aliases) stays green — this phase adds a first-ever `defprotocol`/`defimpl` pair, which is exactly the kind of change that can trip an unused-callback or missing-impl warning.

### Wave 0 Gaps

- [ ] `test/scoria/trust_test.exs` — covers TAINT-01's `Scoria.Trust` leaf unit behavior
- [ ] `test/scoria/trust/scan_test.exs` — covers TAINT-04's monotonic law + error isolation
- [ ] `test/scoria/trust/scanner_test.exs` — covers TAINT-04's registration/override chain
- [ ] `test/scoria/trust/verdict_test.exs` — covers `Verdict` struct shape/enforce_keys
- [ ] `test/scoria/mcp/envelope_test.exs` — covers TAINT-02's struct/accessors/idempotent wrap
- [ ] `test/scoria/spotlight_test.exs` — covers TAINT-03's technique selection + nonce mechanics
- [ ] Extend `test/scoria/knowledge/retrieval_test.exs` or add `test/scoria/knowledge/trust_test.exs` — covers TAINT-01's ingest/reembed/reindex trust-idempotency (Pitfall 4)
- [ ] Extend `test/scoria/mcp/executor_test.exs` — covers TAINT-02's success-branch wrap ordering (Pitfall 1) + replay-stub parity (D-10) + soft-launch flag on/off
- [ ] Extend `test/scoria/observe/semconv_test.exs` — the registry canary literal-list update (expected, deliberate RED→GREEN per D-14)
- [ ] Framework install: none — ExUnit already present, no new test-only dependency needed (see Alternatives Considered on `stream_data`)

## Security Domain

`security_enforcement` is absent from `.planning/config.json` — treated as enabled per the default. This entire phase IS a security mechanism (untrusted-content taint substrate), so ASVS mapping is unusually direct.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Out of scope — this phase adds no auth surface |
| V3 Session Management | No | Out of scope |
| V4 Access Control | Partial | D-05's `set_source_trust/3` tenant-scoped bulk update mirrors the existing `Scope.visible_to/2`/tenant-scoping discipline already enforced across `Knowledge` — no new access-control surface, but the bulk-update MUST reuse the existing tenant-scope pattern (verified precedent: `knowledge.ex:73`'s `where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id`) to avoid a cross-tenant mutation bug |
| V5 Input Validation | Yes — the core of this phase | `Trust.normalize_tier/1` (closed 2-value enum, fail-closed on anything else); `Verdict`'s `reason_code` normalized against a closed enum before tagging (D-21); `Scoria.Observe.Bounds`'s registry-only key admission (existing, reused, not modified) |
| V6 Cryptography | Yes, narrowly | `:crypto.strong_rand_bytes/1` for the D-12 nonce — never hand-rolled, OTP-stdlib CSPRNG; nonce is NEVER logged/persisted (a locked, security-critical constraint, not just a style choice) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt injection via retrieved/tool-sourced content (OWASP LLM01) | Tampering / Elevation of Privilege | Spotlighting/datamarking (D-12) as a signal-separator (explicitly NOT a full defense — CONTEXT.md's `<specifics>` warns against overselling ASR reduction); real containment is the Phase 57 confluence gate, out of this phase's scope |
| Closing-delimiter injection (attacker content contains the literal marker/boundary string to "close" the untrusted span early) | Tampering | Per-call random nonce (`:crypto.strong_rand_bytes(16)`, D-12), verified absent from the span before use, bounded retries (8) then fall back to `:delimit` |
| Trust-tier laundering (a compromised/buggy scanner upgrades untrusted content to trusted) | Elevation of Privilege | D-19's monotonic law — `most_restrictive(incoming, verdict)` — a scanner mathematically cannot raise trust, only lower it |
| Scanner-failure-as-bypass (a crashing/timing-out scanner silently treats content as trusted by default) | Elevation of Privilege / Denial of Service | D-20's fail-closed error isolation — any scanner failure mode resolves to `untrusted` + a distinguishing `reason_code`, never to `trusted` |
| Cross-tenant trust mutation (a bulk `set_source_trust/3` UPDATE leaks across tenant boundary) | Tampering / Information Disclosure | Mirror the existing verified tenant-scoped `where` pattern from `knowledge.ex:73` in the new bulk-update query |
| PII/free-text leakage via a new trace attribute (a `scan`/`spotlight` telemetry payload accidentally carries raw content) | Information Disclosure | D-14/D-21 both restrict emitted attributes to counts/enums/ids only, no free text — enforced structurally by `Semconv.attribute_registry/0`'s closed 6-class vocabulary (no `:free_text` class exists, confirmed in `semconv.ex`'s own moduledoc and `attribute_classes/0`) |

## Sources

### Primary (HIGH confidence)
- `lib/scoria/knowledge.ex` — full file read, all CONTEXT.md line anchors verified directly
- `lib/scoria/knowledge/chunk.ex`, `lib/scoria/knowledge/source.ex` — full files read
- `lib/scoria/mcp/executor.ex`, `lib/scoria/mcp/tool.ex` — full files read, including the nested-shape correction
- `lib/scoria/observe/semconv.ex`, `lib/scoria/observe/guardrail.ex`, `lib/scoria/observe/span_kind.ex`, `lib/scoria/observe/bounds.ex`, `lib/scoria/observe.ex` — full files read
- `lib/scoria/workflows/step.ex`, `lib/scoria/orchestrator.ex`, `lib/scoria/knowledge/scope.ex` — full files read
- `lib/scoria/application.ex` — read for `Task.Supervisor` children (landmine finding)
- `test/scoria/observe/semconv_test.exs` (L270-320), `test/scoria/observe/conformance_test.exs` (grep) — canary test location and exact pinned-list content confirmed
- `mix.exs` — deps list confirmed (no `stream_data`), test aliases confirmed, no dedicated policy-lane alias for this domain
- `grep -rn "defprotocol\|defimpl" lib/` → zero results — confirmed no existing protocol usage
- `grep -rn "update_all" lib/` → confirmed idiomatic bulk-update precedent at `prompt_registry.ex:114,121`, `sre/relay.ex:108,143`, `semantic_cache/invalidation.ex:115`
- `.planning/phases/55-content-trust-taint-substrate/55-CONTEXT.md` — the 23 locked decisions, authoritative for design
- `.planning/REQUIREMENTS.md` — TAINT-01..04 + scope doctrine + Out-of-Scope table
- `.planning/STATE.md` — v3.7 roadmap sequencing, confirms Phase 55 has no phase dependency
- `.planning/seeds/SEED-010-lethal-trifecta-governance.md` — flagship rationale, scope-doctrine reference (P2/P4)

### Secondary (MEDIUM confidence)
- None used — this research relied entirely on direct codebase verification against CONTEXT.md's already-adjudicated design; no live web/docs lookup was needed since no new external library is introduced.

### Tertiary (LOW confidence)
- `:crypto.strong_rand_bytes/1` and `Base.encode32/2` API-surface claims (A1/A2 in Assumptions Log) are training-knowledge-based, not verified via an OTP/Elixir doc lookup this session — low risk given both are long-stable stdlib APIs already implied as correct by CONTEXT.md's own D-12 (which pins the exact call shape as a locked decision, not something this research introduced).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies, every call verified against stdlib/existing deps in `mix.exs`
- Architecture: HIGH — every named code seam read directly against the working tree; one genuine gap (nested `{:ok,value}` shape) found and documented with evidence, not assumed
- Pitfalls: HIGH — all four pitfalls trace to a verified code-level finding (nested tuple shape, registry-drop-on-missing-key, TaskSupervisor coupling risk, reembed-not-touching-metadata), not speculation

**Research date:** 2026-07-27
**Valid until:** 30 days (stable, no fast-moving external dependency; the only decay risk is the codebase itself changing under this research before planning completes — re-verify line anchors if `execute-phase` doesn't run immediately after `plan-phase`)
