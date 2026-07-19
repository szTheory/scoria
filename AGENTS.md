# Scoria Agent Instructions

## Project Boundary

Scoria is an Elixir/Phoenix library added to an existing Phoenix app. It records durable runs, reviewer-visible traces, approval and eval evidence, connector activity, semantic cache decisions, and optional knowledge base proof inside the host app boundary. The host app owns authentication, authorization, tenant membership, role values, prompts, business truth, product UI, and provider calls.

Do not integrate with or use the Ash framework. Scoria is standard Phoenix, Ecto, LiveView, Mix, and ExUnit.

## Source of Truth

README.md and guides/ are canonical source docs. docs/*.md files are compatibility stubs. doc/ output, including doc/llms.txt, is generated. Edit source docs and tests, not generated doc/ output.

Use these contracts before changing public docs:

- `Scoria.AdopterDocContract` for adopter-facing README and guide constants.
- `Scoria.AiDocContract` for root AI doc paths, headings, sections, and boundary fragments.
- `Scoria.VerificationSuites` for public verification suite command contracts.
- `test/scoria/adoption_surface_test.exs` for public docs and module docs expectations.
- `test/scoria/terminology_contract_test.exs` for vocabulary and stale wording guards.

## Generated Files

Never edit generated `doc/` output. Rebuild it with `mix docs` or the release-preview task when ExDoc configuration changes. Treat generated markdown as an inspection artifact, not as source truth.

If a docs or package contract fails, change source files such as README.md, guides/, mix.exs, lib/mix/tasks/scoria.release_preview.ex, or the focused ExUnit contracts. Keep generated artifacts ignored and rebuildable.

## Setup and Verification

Useful setup commands:

```bash
mix deps.get
mix compile --warnings-as-errors
```

Run the smallest relevant verification suite first:

```bash
mix test.adoption
mix test.runtime_to_handoff
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
mix test.knowledge
mix test.connector
mix scoria.release_preview
```

For Phase 49 docs work, use:

```bash
MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors
MIX_ENV=dev mix docs --warnings-as-errors
MIX_ENV=dev mix scoria.release_preview
```

`mix scoria.release_preview` is the package and docs preview verification suite. `MIX_ENV=dev mix docs --warnings-as-errors` is the maintainer diagnostic shortcut for raw docs warnings.

## Docs Language

Use current Scoria vocabulary: run, trace, reviewer, capability, verification suite, scoped context, semantic cache, optional knowledge base, evidence, and grounding. Legacy names belong only in explicit 0.1.x compatibility notes.

Keep copy calm, exact, and evidence-based. Lead with the Phoenix adopter job and the host/Scoria ownership boundary. Avoid backend topology as the first reader path unless it is a public contract.

Scoria records OpenTelemetry-GenAI / OpenInference-compatible convention keys (`gen_ai.*`,
`server.*`, `openinference.span.kind`) in your host Postgres, pinned to OpenTelemetry GenAI
semantic-conventions schema 1.37.0 (via `req_llm ~> 1.13`; these GenAI conventions are still
experimental upstream). Scoria is not an OpenTelemetry exporter — sending these traces onward
to Langfuse, Datadog, or Arize Phoenix is host-owned and opt-in.

## Public API

Prefer public facade and guide references:

- `Scoria`
- `Scoria.Identity`
- `Scoria.Runtime`
- `Scoria.VerificationSuites`
- `ScoriaWeb.ReviewerSurface`
- `Scoria.Observe.ReviewerBroadcast`
- `Scoria.SemanticCache.Profile`
- `Scoria.SemanticCache`
- `Scoria.Knowledge`
- `Scoria.Connectors`
- `Scoria.Connectors.Auth`
- `Scoria.MCP.Tool`
- `Scoria.Eval`

Keep true internals out of public module docs and root AI docs. Do not make internal modules public only to silence ExDoc warnings.

## Avoid

- Do not create CLAUDE.md, CODEX.md, or additional full root vendor docs for this phase.
- Do not edit generated `doc/` output.
- Do not move maintainer-only commands into README first-run copy.
- Do not make dev-only guides, component-lab material, or prompt research part of the public AI-reader path.
- Do not present deferred future seeds as current shipped capabilities.
- Do not replace reviewer, trace, capability, verification suite, scoped context, or semantic cache with retired wording.
