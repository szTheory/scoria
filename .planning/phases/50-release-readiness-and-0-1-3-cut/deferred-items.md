# Deferred Items — Phase 50 (release-readiness-and-0-1-3-cut)

Out-of-scope discoveries logged during plan execution. Not fixed in-place per the
executor scope boundary (only auto-fix issues directly caused by the current task's changes).

## D-50-DEF-01 — `mix scoria.release_preview` docs WAE gate is RED (release blocker for plan 04) — RESOLVED

- **Status:** RESOLVED 2026-07-11 in plan-01 follow-up commit `c809241c`.
- **Resolution:** ExDoc only autolinks inline-code spans that *begin* with `mix `. The three
  offending spans in `guides/maintainers.md` (L43/L57/L58) were prefixed with `$ ` — the
  shell-prompt convention already used safely elsewhere in the same file (e.g. L119's
  `$ mix scoria.post_publish_smoke`, which never warned). The span then starts with `$ `, so
  ExDoc skips the task autolink, while the asserted substrings (`mix scoria.warning_ratchet.test`,
  `mix test.adoption`, `mix scoria.post_publish_smoke`) remain byte-present — so no
  `CiPolicyContractTest` assertion changed. The `mix.exs`/`skip_code_autolink_to` route was NOT
  used (confirmed a separate ExDoc code path, per the analysis below).
- **Verification after fix:** `MIX_ENV=dev mix scoria.release_preview` exits 0 with 0 warnings;
  `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs`
  stays green (58 tests, 0 failures). Plan 50-04 must-have truth #1 is unblocked.

- **Discovered during:** plan 50-03, Task 2 verification (`MIX_ENV=dev mix scoria.release_preview`).
- **Symptom:** `mix docs` (invoked by `scoria.release_preview`) fails under `--warnings-as-errors` with 3 identical warnings:
  `reference to a filtered module` at `guides/maintainers.md:43`, `:57`, `:58`.
- **Root cause:** Those three lines reference maintainer-only Mix tasks in backtick code font —
  `mix scoria.warning_ratchet.test` (L43), `mix test.adoption` (L57), `mix scoria.post_publish_smoke` (L58).
  ExDoc 0.40.3 resolves `mix <task>` inline-code references to their task modules
  (`Mix.Tasks.Scoria.WarningRatchet.Test`, `Mix.Tasks.Test.Adoption`, `Mix.Tasks.Scoria.PostPublishSmoke`),
  which are intentionally excluded from the public docs surface via `filter_modules` in `mix.exs`.
  ExDoc then emits `reference to a filtered module`, which the WAE gate treats as an error.
- **Introduced by:** plan 50-01 commit `25ad5233` ("restore dropped canonical maintainer content in guides/maintainers.md").
  RESEARCH.md lines 74 and 110 confirm `mix scoria.release_preview` and `mix docs --warnings-as-errors`
  built clean at research time — this is a post-plan-01 regression, NOT a plan-03 change.
- **Why not fixed in plan 03:** `guides/maintainers.md` is outside plan 03's `files_modified`
  (plan 03 owns `mix.exs`, the 4 workflows, and `scoria.post_publish_smoke.ex`). Two bounded
  in-scope fix attempts in `mix.exs` were made and reverted: adding the resolved module names and
  the bare task strings to the existing `docs_code_autolink_skips/0` list. Neither cleared the
  warning — ExDoc's "reference to a filtered module" warning is a separate code path from
  `skip_code_autolink_to`, so it cannot be suppressed via that mechanism. The fix must live in
  `guides/maintainers.md` (plan 01's file) or in ExDoc config, not in plan 03's surface.
- **Impact:** BLOCKS plan 50-04 must-have truth #1 ("mix scoria.release_preview and
  mix docs --warnings-as-errors build clean on the tip of main after REL-01/02/03 land").
  Docs still GENERATE (`doc/index.html`, `doc/llms.txt` are produced); only the WAE gate trips.
- **Suggested fix (for a plan-01 follow-up or plan-04 pre-step):** In `guides/maintainers.md`,
  rewrite the three `mix <maintainer-task>` backtick references so ExDoc does not autolink them
  to filtered modules (e.g. drop the code-font autolink trigger, or reference them in a form ExDoc
  does not resolve), preserving reader-facing meaning. Alternatively add a targeted ExDoc
  warning-suppression for filtered-module references originating in `guides/maintainers.md`.
  Then confirm `MIX_ENV=dev mix scoria.release_preview` exits 0.
