# Phase 23 Validation

## Requirement Traceability
* **REG-01**: Operator can save a structured prompt template and it persists as an immutable, versioned Ecto record.
* **REG-02**: System captures structured prompt fields instead of raw strings.
* **REG-03**: System calculates and displays token count estimations when saving a prompt.

## Unit Testing
* **Tokenizer (23-01)**: Run `mix test test/scoria/prompt_registry/tokenizer_test.exs` to ensure correct token estimations.
* **Schema (23-02)**: Run `mix test test/scoria/prompt_registry/prompt_template_test.exs` to ensure schema structure, required fields, and status validity constraints.
* **Context (23-03)**: Run `mix test test/scoria/prompt_registry_test.exs` to ensure correct lifecycle management (creation, status transition, and immutable version bumps) via Ecto.Multi.
* **LiveView (23-04)**: Run `mix test test/scoria_web/live/prompt_live_test.exs` to ensure UI properly renders the list of templates, handles form updates to calculate token counts dynamically, and saves via the context.

## Manual Verification Steps
1. Navigate to `/prompts` in the browser.
2. Verify you can see an empty list or existing prompt templates.
3. Click "New" or "Edit" on an existing template.
4. Enter some text into the System Message or User Template fields.
5. Verify that a token count estimate is calculated and displayed dynamically as you type.
6. Click "Save".
7. Verify that the prompt is successfully saved to the database.
8. Verify that if you edited an active prompt, a new version was created instead of overwriting the previous one in-place.