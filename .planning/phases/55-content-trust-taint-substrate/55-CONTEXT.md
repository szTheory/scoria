# Phase 55: Content Trust & Taint Substrate - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Give untrusted content flowing through Scoria — retrieved knowledge chunks and tool outputs — a **binary trust tier**, keep it **visibly separated from instructions** at prompt assembly via model-agnostic spotlighting, and make it **scannable through a BYO `scan/2` hook** — supplying the missing *untrusted-content leg* that the Phase 57 confluence gate will read.

**In scope:** TAINT-01 (chunk trust tier), TAINT-02 (tool-output envelope), TAINT-03 (spotlighting seam), TAINT-04 (`scan/2` hook + trace tagging). Mechanism only, fail-closed-but-inspectable, **no detector/classifier shipped in-lib**.

**Out of scope (this phase):** the confluence evaluator/gate (Phase 57), tool-declared trifecta classification + per-run rails (Phase 56), moderation/output-scanner eval-seam hooks + `SECURITY-BOUNDARY.md` + Govern UI (Phase 58), and any shipped injection/moderation detector (host-owned, permanently out of scope per scope doctrine).

</domain>

<decisions>
## Implementation Decisions

These decisions were resolved via four parallel research passes (one per requirement) synthesized against an adversarial red-team pass on the reconciled spec. Every public module/function/field name is a Hex-published compatibility commitment. All four areas share ONE trust vocabulary and ONE fail-closed direction (unknown ⇒ untrusted).

### A — Trust vocabulary & chunk trust tier (TAINT-01)

- **D-01:** **Binary tier vocabulary** — a CLOSED enum `~w(trusted untrusted)`, `default_tier() = "untrusted"` (fail-closed). A third/graded tier (`caution`/`quarantined`) is **rejected**: a graded trust level is a content *opinion* the host owns (scope-doctrine violation), and it would force the Phase 57 gate to define a collapse rule. Scanner severity is expressed via `reason_code`/`score` (D-13), never a tier. The gate reads "any `untrusted` on the path" with zero collapse logic. — **Reversibility:** one-way — the enum values and the metadata key string are a published contract read by chunks, envelopes, scan verdicts, and the Phase 57 gate; widening to a 3rd tier later is a breaking change to every reader.
- **D-02:** **Vocabulary lives in one leaf module `Scoria.Trust`** owning: `tiers/0`, `default_tier/0`, `tier_key/0` (= `"scoria.trust.tier"`), `normalize_tier/1`, and the fail-closed reader `tier/1` + `trusted?/1` + writer `put_tier/2`. `Scoria.Trust` **must remain a dependency-free leaf** (see D-05 red-team fix) so `Semconv` can register its key strings BY REFERENCE without a compile cycle. — **Reversibility:** costly — renaming the module/functions later touches every call site and the published API.
- **D-03:** **Fail-closed reader semantics** mirror `Semconv.normalize_reason_code/1`: absent metadata key ⇒ `"untrusted"` **silently** (old rows are legitimately absent); present-but-junk value ⇒ `"untrusted"` + `Logger.warning` + `[:scoria, :trust, :fallback]` telemetry. Only the exact string `"trusted"` reads trusted. This is the false-negative defense (the Ruby `$SAFE`/taint post-mortem: an opt-in tag every reader must remember to check dies — default missing→untrusted so a forgetful reader still fails closed).
- **D-04:** **Trust is a property of the `Source` (provenance), inherited by chunks, denormalized onto `Chunk.metadata` at ingest** (beside the existing scope stamp in `knowledge.ex` ~L78), so retrieval and the Phase 57 gate read one jsonb map with **no Source join** on the hot path. **Red-team fix (persisted source-of-truth):** the canonical tier is **stored on `Source.metadata["scoria.trust.tier"]`**; `ingest_source`/`reembed_source`/`reindex_source` derive chunk trust *from the stored Source value* (a first-create `trust:` opt override only), so re-embedding is **idempotent w.r.t. trust** and does not silently revert a host's declared trust back to `untrusted`. Convention over jsonb — **no new Ecto column, no new `SpanKind`** (v3.6 precedent). — **Reversibility:** one-way — the on-row metadata convention + the denormalization contract are what the Phase 57 gate reads; changing storage shape needs a data migration of existing chunk rows.
- **D-05:** **Host-override API (public):** `Knowledge.create_source(attrs, trust: "trusted")`, `Knowledge.ingest_source(attrs, trust: "trusted")`, and post-hoc `Knowledge.set_source_trust(source, "trusted", scope: ...)` — the last writes `Source.metadata` and **bulk-UPDATEs existing chunk rows scoped by `tenant_id`** (mirror the tenant-scoped update at `knowledge.ex:73`, never cross-tenant). All override values route through `Trust.normalize_tier/1` (a host typo fails closed to untrusted + telemetry, never mints a bogus-trusted row). Reader-side normalization is authoritative for old/junk rows; changeset-side normalization on `Chunk`/`Source` is an optional defense-in-depth, not required.

### B — Tool-output envelope (TAINT-02)

- **D-06:** **Envelope is a struct `Scoria.MCP.Envelope`** with `@enforce_keys [:value, :tier]` and fields `value, tier, provenance, scan, enveloped_at`. A struct (not a plain map, not a tagged tuple) because the `__struct__` stamp is pattern-matchable and cannot collide with the executor's `is_map(result)` introspection of `actual_units`/`actual_cost_usd`; `@enforce_keys` makes a tier-less envelope unconstructable. `provenance` carries only the low-cardinality ids the executor already has (`tool_ref`, `tool_name`, `trace_id`, `workflow_run_id`, `step_id`, `args_fingerprint`) — id/enum class, **no free text**. `scan` is a `nil` slot in Phase 55, populated by the Area-D verdict later. — **Reversibility:** one-way — the struct shape is a published return contract once the soft-launch flag is enabled; downstream readers (Phase 57) pattern-match it.
- **D-07:** **Wrapping happens at the single `MCP.Executor` success choke point**, in the `{:ok, {:completed, result, duration}}` branch (`executor.ex` ~L48-52), **after** `reconcile_budget` and `emit_sre_telemetry` have already read the raw `{:ok, value}` — **this ordering is load-bearing** and must be documented as such. Defense-in-depth: add an `actual_units(_ctx, %Envelope{value: v}, o)` head so a future reorder can't silently mis-bill. Only the success/content leg is enveloped; `{:error, _}` passes through untouched. Uniform-at-the-executor (not opt-in-per-tool) because per-tool wrapping is fail-**open** by omission — a forgetful tool would look trusted.
- **D-08:** **Taint is ALWAYS computed + persisted (inspectable), but the return-SHAPE change is soft-launched.** On every tool success, taint is written to `step.result_envelope` jsonb (`step.result_envelope["scoria.taint"] = %{"tier" => ..., "tool_ref" => ..., "args_fingerprint" => ...}`, convention over jsonb) and to telemetry — so Phase 57 and observability see taint regardless. The **return value** stays `{:ok, value}` (byte-identical to 0.1.3) unless `config :scoria, Scoria.MCP.Envelope, wrap_tool_output: true` is set (default **off**) — then it returns `{:ok, %Envelope{}}`. This is the v3.4 `ReleaseGate` "never brick an adopter, strict/shape change opt-in" precedent. — **Reversibility:** reversible — the flag default and the always-persist behavior can be tuned; the *struct shape* (D-06) is the one-way part.
- **D-09:** **Total accessors are the forward-compatible read path** — `Scoria.MCP.Envelope.wrap/2` (idempotent, guards on `envelope?/1` — no double-wrap), `envelope?/1`, `tier/1`, `value/1`, `scan/1`, `unwrap/1` → `{tier, value}`. All are **total over `Envelope.t() | term()`**: any un-enveloped/unknown value reads `tier ⇒ "untrusted"`, `value ⇒ itself`. Area C and Phase 57 call these accessors and **never** pattern-match the raw shape, so they are flag-agnostic. New Scoria-internal code is written against accessors from day one.
- **D-10:** **Replay/historical-stub path stays uniform under the flag (red-team fix).** `replay_gate` returns a historical-stub result BEFORE `execute_live` (`executor.ex` ~L91-97). When `wrap_tool_output` is **on**, the stub's `result` must be wrapped (`Scoria.MCP.Envelope.wrap(raw, tier: "untrusted", provenance: %{source: :replay_stub})`) so live and replay return the **same shape** — otherwise a Phase 56/57 consumer written against `{:ok, %Envelope{}}` diverges on replay (a correctness bug, not a follow-up). Fail-closed reader still covers the flag-off case.

### C — Spotlighting seam & technique (TAINT-03)

- **D-11:** **Standalone host-called module `Scoria.Spotlight`** (+ result struct `Scoria.Spotlight.Marked{marked, instruction, technique, tier, marked?, spans}`). **Premise correction, verified in code:** `Scoria.Orchestrator` is only an LLM-fallback wrapper taking an already-built prompt; there is **no in-lib chunks→prompt assembly path** (`CitationFormatter` builds anchors, not a prompt body). So the seam must be a thing the **host calls on its untrusted content before it assembles its prompt** — `Scoria.Spotlight.render(items, opts) :: Marked.t()`. Adding an assembly helper to `Orchestrator` is **rejected** (it would force the host to hand Scoria its instruction text → Scoria owns prompt structure → scope-doctrine violation). — **Reversibility:** costly — `Scoria.Spotlight` public API is a Hex commitment.
- **D-12:** **Technique is content-shape-aware, biased to the non-destructive option (red-team fix):** prose/untyped untrusted content ⇒ **`:datamark`** (interleave a per-call random marker char between words + nonce boundary; MSRC-recommended robust minimum, ASR ~50%→<3%); **structured** content (JSON/code tool output) ⇒ **`:delimit`** (nonce boundary only, body untouched so the model can still parse it); **ambiguous content-shape ⇒ `:delimit`** (never datamark — interleaving corrupts structured data the model must parse). `:encode` (base64) is offered but **documented NOT-recommended** (not model-agnostic — small/local models can't reliably decode). Technique overridable via `technique:` opt. **Nonce/marker mechanics (pinned):** nonce = `:crypto.strong_rand_bytes(16)` (≥128-bit) `|> Base.encode32(padding: false)`, fresh per call, **never logged/persisted**; the boundary/marker is **verified absent from the span** for *both* `:delimit` and `:datamark` (bounded retries — e.g. 8 — then fall back to `:delimit`) — defeats closing-delimiter injection. Trusted content passes through **byte-identical**.
- **D-13:** **The paired system-prompt instruction is provided by Scoria as an overridable template, returned as DATA (red-team fix).** `render/2` returns the canonical instruction string on `Marked{instruction}` alongside the marked text (so the two can't drift — you cannot obtain the mark without being handed the words that explain it). Scoria owns the *mechanism* (the instruction wording that makes the mark meaningful) but returns it as data and **never injects a system prompt or decides placement** — the host places it. The default template is **overridable** by the host (so it can fit its own model) — this keeps Scoria from owning prompt *content*.
- **D-14:** **Bounds-safe trace emission** — `render/2` emits `[:scoria, :spotlight, :marked]` with measurements `%{marked_spans, marked_bytes}` and metadata `%{technique, tier}` — **counts/enums only, never the nonce or the raw/marked text**, wrapped `try/rescue -> :ok` (observe-layer discipline: never break host business logic). Optional `scoria.spotlight.*` registry keys (`technique :enum`, `marked_spans :count`, `marked_bytes :count`, `tier :enum`) added to `Semconv.attribute_registry/0` (the canary-test trip is the deliberate SEC-01 guarantee).
- **D-15:** **Known residual (documented, not solved this phase):** a host that reads `chunk.body` raw and self-concatenates bypasses `Spotlight` silently — Scoria never sees the final prompt string and cannot force marking. Mitigation is docs + the `SECURITY-BOUNDARY.md` shared-responsibility statement (Phase 58). No Credo/telemetry nag is built this phase.

### D — `scan/2` hook & trace tagging (TAINT-04)

- **D-16:** **Behaviour `Scoria.Trust.Scanner`** with `@callback scan(content :: binary() | map(), context :: map()) :: {:ok, Scoria.Trust.Verdict.t()} | {:ok, :not_scanned} | {:error, term()}`; shipped default `Scoria.Trust.Scanner.NoOp` returns `{:ok, :not_scanned}`. **Verdict `Scoria.Trust.Verdict`** = `@enforce_keys [:tier]`, fields `tier` (binary, D-01 enum), `score` (float, **host-only, NEVER persisted to a trace**), `reason_code` (atom, normalized vs a closed enum before tagging), `scanner` (module). **No detector ships in-lib** — this is a BYO seam (Rebuff/LlamaGuard-shaped). — **Reversibility:** one-way — the behaviour callback signature and verdict struct are published contracts a host implements against.
- **D-17:** **Registration mirrors the `req_llm_module` precedent:** `Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp)` + a per-call `context[:content_scanner]` override (testable via context injection, `async: true`-safe, no app-env mutation). Default NoOp = **byte-identical current behavior**, zero overhead, nothing emitted.
- **D-18:** **Scan is anchored to the taint-MINTING chokepoints, NOT only `Spotlight.render` (sharpest red-team fix).** A host that assembles its own prompt (the common case per D-15) would never call `render`, making the entire scanner seam **decorative** and TAINT-04 unmet. So scan fires where Scoria mints untrusted content and controls the seam: **(1) `Knowledge.retrieve/2`** (batch-scan the result set — one call, `scanned_count`) and **(2) `MCP.Executor` envelope creation** (scan the tool output). `render/2` may still opportunistically scan but is not the sole trigger. `NoOp` short-circuits at each site (true no-op). Public `Scoria.Trust.scan/2` is also callable per-leg by hosts. Orchestration (Task timeout, error isolation, telemetry, monotonic law) lives in a **separate `Scoria.Trust.Scan` module** — NOT in the leaf `Scoria.Trust` vocab module (D-05 leaf constraint).
- **D-19:** **Monotonic taint law (property-tested):** resolved tier = `most_restrictive(incoming_tier, verdict_tier)` — a scanner may only **ADD** taint (→`untrusted`), **never launder** `untrusted`→`trusted`. With a binary enum this is trivially "if either is untrusted, untrusted." This is the single most security-critical invariant; it gets a dedicated property test. A buggy/hostile scanner cannot upgrade trust.
- **D-20:** **Error isolation fails CLOSED (inverts the observe layer's fail-to-`:ok`):** any scanner `raise`/`throw`/`exit`/`{:error, _}` is caught and converted to `%Verdict{tier: "untrusted", reason_code: :scanner_error}`; a bounded-timeout breach (reuse the `MCP.Executor` supervised-Task discipline) ⇒ `%Verdict{tier: "untrusted", reason_code: :scanner_timeout}`. The run **never crashes** and never *gains* trust from a scanner failure. Scan is synchronous by default (taint must resolve before marking / before Phase 57 reads it).
- **D-21:** **Trace tagging is a fixed-projector `scoria.trust.*` attribute group on the existing span at each minting site — NOT `Guardrail.emit/1`.** A scan is a *classification*, not an allow/block/escalate *decision* (that's the Phase 57 gate — the caller the `Guardrail` moduledoc anticipates). Since D-18 moved scan to `retrieve` (which already emits a RETRIEVER span) and to envelope creation (executor tool telemetry), the `scoria.trust.*` attributes attach to those existing spans — a projector `Semconv.trust_attributes/1` with keys `tier :enum`, `scanner :id`, `reason_code :enum`, `scanned_count :count`, registered in `attribute_registry/0`. **No `score` key** (the numeric detector score never reaches Postgres); `reason_code` normalized against a closed enum (`~w(prompt_injection moderation_flag untrusted_source scanner_error scanner_timeout unknown)`, fallback `unknown`) — same structural leak-immunity as `guardrail_attributes/1`. This also resolves the red-team's "`render/2` has no span handle" objection: tagging happens at the minting sites, which have spans.

### Cross-phase constraint (record now — read by Phase 57)

- **D-22:** **Phase 57's confluence gate MUST distinguish content-untrusted from infra-failure-untrusted via `reason_code`, and MUST NOT blindly inherit Phase 55's fail-closed default (red-team fix — bricking cascade).** Because a scan failure/timeout marks content `untrusted` (D-20) and Phase 57 escalates on untrusted-content, a single misconfigured/slow scanner could otherwise turn Phase 57 into a universal human-gate on 100% of traffic (adopter bricked — violates "never brick"). Phase 57 enforcement branches on `reason_code`; `:scanner_error`/`:scanner_timeout` get a separate, operator-selectable disposition (a config like `content_scanner_infra_fail_open`) distinct from a genuine content verdict. This is a cross-phase invariant, decided here so Phase 57 planning inherits it.

### Module layout (reconciled, red-teamed — no compile cycle)

- **D-23:** `Scoria.Trust` — **leaf** vocab only (enum, `tier_key/0`, `tier/1` over `map()`/`binary()`, `normalize_tier/1`, `put_tier/2`, `default_tier/0`). Depends on nothing. Foreign-struct polymorphism is achieved with a **protocol `Scoria.Trust.Tiered`** whose `impl` blocks live in the OWNING modules (`Knowledge.Chunk`, `MCP.Envelope`) delegating to `Trust.tier(metadata)` — this keeps `Trust` a leaf and avoids the `Knowledge↔Trust` / `MCP↔Trust` compile cycle that a `tier/1` head matching `%Chunk{}`/`%Envelope{}` would create. Separate modules: `Scoria.Trust.Scanner` (behaviour + `NoOp`), `Scoria.Trust.Scan` (orchestration), `Scoria.Trust.Verdict` (struct), `Scoria.MCP.Envelope` (tool envelope + accessors), `Scoria.Spotlight` (+ `.Marked`). `Semconv` registers `Scoria.Trust.tier_key/0` etc. by reference.

### Claude's Discretion

- Exact field names inside `provenance`/`Marked`/`Verdict` beyond those named above, private helper names, and test-file layout — planner/executor discretion, provided the public names in D-01..D-23 are honored.
- Whether the default spotlight instruction template ships as a module attribute vs a function — executor discretion (must be host-overridable per D-13).
- **No UI this phase.** The only operator-observable surface is the `scoria.trust.*`/`scoria.spotlight.*` trace attributes, which the read-only Govern surface renders in **Phase 58** (GOVERN-01). No `/scoria` screen, LiveView, or brandbook/design-system work is in Phase 55 — the UI/UX, accessibility, and creative-direction lenses are N/A here and deferred to Phase 58.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone framing
- `.planning/REQUIREMENTS.md` — TAINT-01..04 (this phase), plus CLASS/RAIL/GATE/HOOK/BOUND/GOVERN (later phases) + scope doctrine + Out-of-Scope table.
- `.planning/ROADMAP.md` §"Phase 55" — goal, success criteria, dependencies (builds on the v3.6 trace substrate).
- `.planning/seeds/SEED-010-lethal-trifecta-governance.md` — the flagship rationale, "what to build" items 1 (content trust/spotlighting) + the breadcrumbs list; adjudicated disagreements (detection is NOT Scoria's).

### Research consulted during this discussion (mine before planning)
- `prompts/ai-architectural-patterns-deep-research.md` — §6 tool-calling, §13 guardrail/safety harness, **Rule 3 "a tool is a loaded interface"** (narrow/typed/reversible tools; expose a safer intermediate), spotlighting.
- `prompts/phoenix-ai-lib-deep-research.md` — Elixir/Phoenix embedded-lib idioms: behaviours, `Application.get_env` module-swap, result/envelope conventions, where seams belong.
- `prompts/sztheory-elixir-dna.md` — architectural DNA: batteries-included-but-composable, Unix-philosophy, operator-first DX, Ecto-native, fail-closed-but-inspectable, zero-config onboarding.

### Code seams this phase touches (breadcrumbs)
- `lib/scoria/knowledge/chunk.ex`, `lib/scoria/knowledge/source.ex`, `lib/scoria/knowledge.ex` (`ingest_source/2` ~L58-101, `retrieve/2` ~L245, scope stamp ~L78, tenant-scoped update ~L73) — trust tier storage + stamping + scan-at-retrieve.
- `lib/scoria/mcp/tool.ex`, `lib/scoria/mcp/executor.ex` (success branch ~L48-52, `actual_units` ~L280-289, `replay_gate` ~L91-97, `build_replay_seam` ~L150-165) — tool-output envelope + scan-at-envelope.
- `lib/scoria/orchestrator.ex` (`req_llm_module` swap precedent) — the config-injection idiom for `content_scanner`.
- `lib/scoria/observe/guardrail.ex` (pure-emitter, fixed-projector, status-always-OK, no-free-text-reason discipline — the pattern the `scoria.trust.*` projector copies but does NOT reuse), `lib/scoria/observe/semconv.ex` (`attribute_registry/0`, `normalize_reason_code/1`, `retrieval_config_attributes/1`, `merge_host_declared/2`), `lib/scoria/observe/span_kind.ex` (fixed 8-value taxonomy — do NOT add a taint kind), `lib/scoria/observe/bounds.ex`, `lib/scoria/observe.ex` (`emit_retriever_span`, `emit_event/1`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Semconv.normalize_reason_code/1` pattern** (`observe/semconv.ex`) — the exact fail-closed "unknown → sentinel + log + telemetry" idiom `Trust.normalize_tier/1` copies.
- **`Observe.Guardrail.emit/1`** — the pure-emitter + fixed-key-projector + status-always-OK + no-free-text discipline the `scoria.trust.*` projector mirrors (copies the pattern; does NOT reuse the module — scan is classification, not decision).
- **`Orchestrator` `Application.get_env(:scoria, :req_llm_module, ReqLLM)`** — the module-swap precedent for `content_scanner`.
- **`Step.result_envelope :map`** (`workflows/step.ex`) — an existing jsonb "envelope" home; taint is persisted here (D-08).
- **`Knowledge.retrieve/2` RETRIEVER span** — the existing span the `scoria.trust.*` scan tags attach to (D-21).

### Established Patterns
- **v3.6 convention-over-columns:** structured data rides existing jsonb `metadata`/`attributes` maps; key strings owned by `Semconv`; `attribute_registry/0` is a closed registry guarded by a canary test (new keys trip it deliberately). No new typed columns, no new `SpanKind`.
- **Payload-bounding law (v3.6):** traces carry IDs/counts/enums, never raw content or free text — enforced structurally by fixed projectors.
- **Fail-closed-but-inspectable (v3.4 `ReleaseGate`):** mechanism ships always-computed + inspectable; strict enforcement / shape change is opt-in; never brick an adopter.

### Integration Points
- Trust tier stamped at `Knowledge.ingest_source/2`; read at `retrieve/2` and by Phase 57.
- Envelope minted at `MCP.Executor` success + replay-stub branches; read by Phase 56/57.
- `content_scanner` invoked at `retrieve/2` + envelope creation; verdict tags the RETRIEVER/tool span.
- `Scoria.Spotlight.render/2` is host-called at prompt-assembly time (Scoria owns no prompt string).

</code_context>

<specifics>
## Specific Ideas

- **Prior art the design deliberately mirrors/avoids:** copy Perl taint's *default-on* tainting (data is untrusted unless explicitly untainted); avoid Ruby `$SAFE`'s opt-in model (removed because the ecosystem ignored `untaint` → false negatives). Copy MSRC datamarking (ASR ~50%→<3%) + per-call random nonce. Avoid fixed delimiters (OWASP LLM01 closing-delimiter injection) and base64-by-default (not model-agnostic). Copy MCP `CallToolResult`'s "one source of truth for the payload" (value lives only at `envelope.value`, never duplicated into two drift-prone fields). Avoid LangChain `ToolMessage.status`'s "dead metadata" — the tier MUST terminate in the Phase 57 gate or it's decorative.
- **Spotlighting is a signal-separator, never "the defense"** — must be documented as such; real containment is blast-radius + the Phase 57 confluence gate. Do not oversell ~<3% ASR as safe.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 56:** tool-declared trifecta classification supplies the per-tool declared tier that the envelope's `default_tier` (currently always `untrusted`) will read; per-run rails.
- **Phase 57:** the confluence evaluator/gate that READS this substrate — including the `reason_code`-branching + infra-fail disposition constraint recorded in D-22.
- **Phase 58:** the read-only Govern surface (renders `scoria.trust.*`/`scoria.spotlight.*`), the moderation + output-scanner eval-seam hooks (separate from `scan/2`, run through `Eval.online_scoring`/`judge_runner`), and `SECURITY-BOUNDARY.md` (states the D-15 host-bypass residual + shared responsibility).
- **Defense-in-depth follow-ups (not blocking):** a Credo/telemetry nudge for raw `chunk.body` access that bypasses `Spotlight` (D-15); changeset-side trust normalization on `Chunk`/`Source` (D-05).
- **Permanently host-owned (out of scope, per scope doctrine):** any injection/moderation detector or classifier; per-user/per-intent tool allowlists; opinionated moderation content policy / output sanitizer.

</deferred>

---

*Phase: 55-content-trust-taint-substrate*
*Context gathered: 2026-07-27*
