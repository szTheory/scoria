# Phase 23: Ecto-backed Prompt Registry and Lifecycle - Research

**Researched:** 2024-05-18
**Domain:** Prompt Registry, Token Estimation
**Confidence:** HIGH

## Summary

The system currently relies on `Scoria.PromptPolicy` as a configuration layer but lacks a persistent, versioned backend to store prompt structures. This phase introduces an Ecto-backed registry for structured, versioned prompt templates, supporting a lifecycle from `draft` to `active` to `archived`. We will add the `tiktoken` library to compute token bounds before prompts are saved, ensuring they fit within model context windows. We strictly adhere to standard Phoenix and Ecto components per project constraints.

**Primary recommendation:** Create a new Phoenix context `Scoria.Prompts` with an Ecto schema `Scoria.Prompts.Template` to store structured prompts as JSONB maps/embedded schemas, and integrate the hex package `tiktoken` for on-save validation.

<user_constraints>
## User Constraints (from GEMINI.md)

### Locked Decisions
- **Ash Framework:** Do not attempt to integrate with or use the Ash framework. We are strictly all-in on standard Phoenix and Ecto architectures.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REG-01 | System provides an Ecto-backed prompt registry that stores versioned, immutable prompt templates and tracks lifecycle status. | We'll design `Scoria.Prompts.Template` schema with `name`, `version`, `status` fields, and `inserted_at`/`updated_at`. |
| REG-02 | Prompts are modeled as structured maps (System Message, Few-Shot Examples, User Template) supporting variable interpolation, rather than fragile raw strings. | Ecto `embeds_one` or a simple JSONB `:map` field for structured representation will replace raw strings. |
| REG-03 | Registry includes token estimation capabilities (via Elixir Tiktoken port) to warn operators of context window limits before saving. | We will add the `{:tiktoken, "~> 0.4.2"}` dependency to calculate token usage for typical interpolations. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Store Prompt Templates | Database / Storage | API / Backend | Ecto schema handles persistence and queries |
| Prompt Versioning & Lifecycle | API / Backend | Database / Storage | Phoenix Context logic manages immutability and transitions |
| Token Estimation | API / Backend | — | Tiktoken port computes tokens purely in Elixir/Rust NIF |
| Variable Interpolation | API / Backend | — | Text replacement and structured formatting logic |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto_sql | ~> 3.10 | Persistence Layer | Standard DB wrapper in Scoria |
| tiktoken | ~> 0.4.2 | Token Estimation | Standard Elixir NIF bindings for OpenAI's tiktoken |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto.Changeset | ~> 3.10 | Validation | Validating JSONB structured map, token limits |

**Installation:**
```bash
mix deps.add tiktoken
```

## Architecture Patterns

### Recommended Project Structure
```text
lib/
└── scoria/
    ├── prompts/
    │   ├── template.ex          # Ecto schema for prompt templates
    │   └── tokenizer.ex         # Tiktoken estimation wrapper
    └── prompts.ex               # Phoenix Context API API wrapper
priv/
└── repo/
    └── migrations/
        └── [timestamp]_create_prompt_templates.exs
```

### Pattern 1: Structured Ecto Map for Prompts
**What:** Define prompt components as JSONB or embedded schema.
**When to use:** Storing structured prompts instead of strings.
**Example:**
```elixir
schema "scoria_prompt_templates" do
  field :name, :string
  field :version, :integer
  field :status, Ecto.Enum, values: [:draft, :active, :archived], default: :draft
  
  field :system_message, :string
  field :few_shot_examples, {:array, :map}, default: []
  field :user_template, :string
  
  field :variables, {:array, :string}, default: []
  field :estimated_tokens, :integer

  timestamps()
end
```
*Note: Depending on how dynamic the map is, we can use distinct fields or an `embeds_one` macro for the structured data.*

### Anti-Patterns to Avoid
- **Raw string injection:** Using raw interpolated strings opens us up to prompt injection and poor maintainability. We must separate instructions from variable data.
- **Mutable templates:** Templates should be immutable once `active`. Instead of updating an active template, the system should issue a new version (e.g., bumping `:version`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tokenizing | Custom regex / word counting | `tiktoken` | Accurately models LLM token boundaries and sub-word chunking, which standard string length ignores. |
| Version Management | Rolling custom mutable schemas | Append-only / `version` integers | Once active, templates must remain immutable so historical evaluation records stay accurate. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None (New capability) | Create `scoria_prompt_templates` table |
| Live service config | None | |
| OS-registered state | None | |
| Secrets/env vars | None | |
| Build artifacts | None | |

## Common Pitfalls

### Pitfall 1: Tiktoken Compilation Issues
**What goes wrong:** Adding `tiktoken` introduces a Rust NIF dependency, which requires a working Rust toolchain.
**Why it happens:** Rustler needs to compile the bindings during `mix deps.compile`.
**How to avoid:** Precompiled binaries are downloaded via Rustler Precompiled by default. Ensure the version used has precompiled binaries for standard targets (Mac/Linux). Version `0.4.2` supports precompiled NIFs.

### Pitfall 2: Context Window Limits with Variables
**What goes wrong:** Template fits within context size, but variables expand the token count beyond limits during execution.
**Why it happens:** Variables (e.g. `{{user_input}}`) have arbitrary sizes.
**How to avoid:** Token estimation should represent the *template* baseline cost and provide an API for computing *filled* token counts. A warning should trigger if the baseline itself is close to the context limit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Ecto Persistence | ✓ | Project Standard | — |
| Elixir `tiktoken` | Token Estimation | ✗ | ~> 0.4.2 | Requires `mix deps.get` |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test --stale` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REG-01 | Templates can be persisted and transitioned draft->active | integration | `mix test test/scoria/prompts_test.exs` | ❌ |
| REG-02 | Variables are extracted and prompts are structured | unit | `mix test test/scoria/prompts/template_test.exs` | ❌ |
| REG-03 | Token limits are estimated and exposed via Changeset | unit | `mix test test/scoria/prompts/tokenizer_test.exs` | ❌ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Ensure only authorized roles modify templates |
| V5 Input Validation | yes | Ecto Changesets, token limits |
| V6 Cryptography | no | — |

### Known Threat Patterns for Phoenix/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt Injection via Templates | Tampering | Separate instructions from variables. Rely on structured messaging API rather than raw string templating. |

## Sources

### Primary (HIGH confidence)
- `mix.exs` - Dependencies and environment
- `lib/scoria/prompt_policy.ex` - Verified current state

### Secondary (MEDIUM confidence)
- hex.pm - `tiktoken` 0.4.2 availability (checked via `mix hex.search`)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified via project source and Hex
- Architecture: HIGH - Matches standard Phoenix contexts as requested
- Pitfalls: HIGH - Known issues with Rustler precompiled NIFs and LLM variable interpolation
