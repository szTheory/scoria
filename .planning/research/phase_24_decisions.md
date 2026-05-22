# Phase 24: Trace-to-Dataset Curation via LiveView - Deep Architectural Analysis & Decision

## 1. Context and Goals
**Goal**: Operators must be able to seamlessly promote real production traces into durable, baseline datasets for future testing, completing the "Trace → Annotation → Dataset → CI Gate" flywheel.
**Context**: Scoria is a Phoenix-native AI operations library embodying the "SaaS in a Box" Unix philosophy. It focuses on zero-configuration onboarding, Ecto-native state, and operator-first developer experience (DX) via LiveView dashboards. Scoria strictly relies on standard Phoenix/Ecto and explicitly excludes the Ash framework.

## 2. Lessons Learned from the Ecosystem
Analyzing mature AI operations and evaluation platforms (LangSmith, Braintrust, Langfuse, Arize Phoenix) reveals critical success patterns and common footguns:

### What They Did Right (To Emulate)
- **The Evaluation Flywheel:** The highest-value feature of these platforms is the seamless closed loop: capturing a trace in production, identifying a failure (or success), promoting it to a dataset with annotations, and using that dataset as a baseline in CI.
- **Dataset Versioning & Immutability:** Braintrust and Langfuse emphasize that mutating datasets destroys historical comparison. Datasets must be strictly versioned (e.g., `support_refunds@v1`).
- **Rich Context Preservation:** Evals require more than just string prompts. Platforms succeed when they capture multi-turn chat messages, system prompts, active tools, tool outputs, and structured LLM responses.
- **Explicit Offline vs. Online Evals:** They clearly distinguish offline evaluations (running known datasets in CI) from online scoring (LLM-as-judge on live production traces).

### Footguns (To Avoid)
- **PII Leakage in Test Data:** Promoting a raw production trace directly into a dataset risks embedding Personally Identifiable Information (PII) into CI pipelines permanently. OpenAI's tracing docs warn about Zero Data Retention conflicts.
- **Rigid Schema Traps:** Attempting to model test cases with rigid relational columns breaks down immediately when evaluating varying tool arguments or structured JSON outputs.
- **Disjointed Context:** If the dataset item format differs from the runtime execution arguments, developers write brittle translation layers.
- **Loss of Lineage:** Forgetting where a dataset item came from makes it hard to understand *why* the test case exists.

## 3. Analysis of Proposed Architectural Approaches

### Approach A: Ecto-Backed Relational Datasets (JSONB + Relational Links)
- **Concept**: Use Ecto (`Scoria.Eval.Dataset`, `Scoria.Eval.DatasetItem`) backed by PostgreSQL. Datasets are relational entities, while individual test cases utilize `JSONB` for flexible `input`, `expected`, and `metadata` payloads.
- **Pros for Scoria**:
  - **Idiomatic Elixir/Phoenix**: Perfectly aligns with the Ecto-native DNA.
  - **Operator-First UX**: Enables building rich, interactive LiveView curation modals directly integrated into Scoria's existing Trace Explorer.
  - **Lineage Tracking**: Enables strong foreign key constraints (e.g., `source_trace_id`) ensuring every curated test case is traceable to a real production event.
  - **Queryability**: PostgreSQL `JSONB` allows for complex filtering (e.g., finding all dataset items testing the `lookup_order` tool).
- **Cons for Scoria**:
  - **CI Execution Dependency**: Offline evals require database access. (Mitigation: Provide a Mix task to export Ecto datasets to a static JSON fixture for CI, or simply rely on standard Ecto sandbox tests).

### Approach B: VCR Cassettes / Local Filesystem Storage (JSONL)
- **Concept**: The LiveView "Promote" action writes a `.jsonl` file directly to the repository filesystem.
- **Pros for Scoria**:
  - Trivial offline CI execution (files are just committed to Git).
- **Cons for Scoria**:
  - **Anti-Pattern**: Writing to the local filesystem from a web request in a deployed 12-factor application (e.g., on Fly.io, Heroku) is a massive footgun. Ephemeral filesystems will wipe the datasets on restart.
  - **Terrible UX**: Operators cannot easily curate, tag, or version datasets via a web UI if the source of truth is a transient file on the production server.

### Approach C: Event-Sourced Datasets
- **Concept**: Store dataset mutations as an append-only event stream (e.g., `ItemAdded`, `DatasetVersioned`).
- **Pros for Scoria**:
  - Perfect auditability.
- **Cons for Scoria**:
  - **Over-engineered**: Violates Scoria's "batteries-included but simple" philosophy. Introduces unnecessary complexity for an embeddable library where simple versioning (cloning dataset IDs) suffices.

## 4. One-Shot Recommendations for Phase 24

**Decision:** We are adopting **Approach A (Ecto-Backed Relational Datasets)**. It is the only approach that delivers the required operator UX without breaking 12-factor deployment constraints.

To ensure developer ergonomics, the Principle of Least Surprise, and seamless LiveView integration, we will implement the following cohesive architecture:

### 4.1 Persistence Layer (Ecto)
Create two PostgreSQL-backed Ecto schemas:

*   **`Scoria.Eval.Dataset`**: The versioned collection.
    *   Fields: `name` (string), `version` (string), `description` (string), `tags` (array of strings).
    *   *Constraint*: Unique index on `[:name, :version]`.
    *   *Rule*: Datasets are conceptually immutable. To alter test cases, operators clone the dataset and increment the version.
*   **`Scoria.Eval.DatasetItem`**: The individual test case.
    *   Fields: `dataset_id` (belongs_to), `source_trace_id` (belongs_to, nullable), `input` (JSONB), `expected` (JSONB), `metadata` (JSONB).
    *   *Principle of Least Surprise*: The shape of the `input` JSONB **MUST exactly match** the `args` accepted by `Scoria.Runtime.run/2`. This allows the evaluation engine (Phase 25) to pipe dataset inputs directly into the runtime with zero translation.

### 4.2 The LiveView Curation Workflow (Operator-First UX)
The workflow integrates directly into the `ScoriaWeb.TraceExplorerLive`:

1.  **Inline Action**: Traces and specific turns/spans feature a "Promote to Dataset" button.
2.  **Curation Modal (`ScoriaWeb.DatasetItemPromoteComponent`)**: Clicking the button opens a LiveComponent.
3.  **Auto-Extraction**: The modal extracts the multi-turn context (the `messages` array up to the selected span) and pre-fills the `input` form.

### 4.3 PII Redaction Strategy
Redaction must be explicit and happen *before* the dataset item is persisted.

*   **Pre-fill with Redaction Rules**: When auto-extracting the trace `input`, Scoria will apply its global redaction policy (e.g., stripping known `api_keys`, masking standard email/phone patterns).
*   **Operator Verification**: The Curation Modal presents the extracted `input` payload to the operator.
*   **Manual Masking**: The operator can manually edit the JSON/form to obfuscate specific user details (e.g., changing "Refund John Doe" to "Refund Customer A").
*   *Commitment*: The data is only saved to `ai_dataset_items` once the operator confirms the redacted payload.

### 4.4 Expectation Builders
To make datasets actionable for CI, the Curation Modal must help operators define what "success" looks like for this trace. The `expected` JSONB field will store evaluation criteria.

The LiveView modal will offer the following Expectation Builders (which map directly to Scoria's Scorer primitives):
*   **Exact Match / Substring**: The LLM's final response must contain a specific string (e.g., "I have processed your refund").
*   **Tool Invocation**: Asserts that a specific tool (e.g., `lookup_order`) was called with specific argument schemas.
*   **Structured Output (JSON Schema)**: Asserts that the response matches an expected Ecto Changeset or JSON Schema.
*   **Refusal Validation**: Asserts that the model *correctly refused* an unsafe or out-of-policy request.
*   **LLM-as-Judge Rubric**: Assigns a specific rubric version (e.g., `support_helpfulness@v2`) for online/offline heuristic scoring.

*Schema Example:*
```json
{
  "must_include": ["refund policy"],
  "required_tools": [{"name": "lookup_order"}],
  "refusal": false
}
```

### 4.5 Tagging & Organization
Tagging is crucial for filtering large eval suites.
*   Both `Dataset` and `DatasetItem` have a `tags` array (using PostgreSQL `varchar[]` or `jsonb`).
*   **System Tags**: Auto-applied during promotion (e.g., `source:production`, `model:claude-3-sonnet`).
*   **Operator Tags**: Added via the UI (e.g., `edge-case`, `regression`, `hallucination`, `prompt-injection`).
*   This allows the evaluation runner to execute subsets of datasets (e.g., `mix scoria.eval --tag edge-case`).

## Summary
By storing structurally flexible but strongly linked datasets in Ecto, enforcing redaction in the LiveView promotion modal, and aligning dataset item shapes directly with the Scoria runtime API, we achieve a frictionless, operator-first evaluation flywheel that is idiomatic to the Elixir/Phoenix ecosystem.