# Plan 14-01 Summary

## Outcome

Implemented the canonical runtime defaults surface for `POLY-01`.

- Added `Scoria.PromptPolicy` as the one public prompt-policy noun with immediate normalization for atom, string, map, and nested constraint input.
- Added `Scoria.Runtime.Defaults` as the app-facing defaults helper behind `config :scoria, Scoria.Runtime, defaults: ...`.
- Wired `Scoria.Runtime.Params.start/2` to stamp the resolved provider, model, and prompt-policy snapshot into run metadata at the public runtime boundary.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/prompt_policy_test.exs test/scoria/runtime/defaults_test.exs`

## Notes

- Defaults stay plain Phoenix config, not a DSL.
- Prompt-policy metadata is stored as durable JSON with stable policy key, prompt ref/version, and governance fields.
