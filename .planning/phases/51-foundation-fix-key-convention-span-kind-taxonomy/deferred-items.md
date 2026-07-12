# Phase 51 Deferred Items

## Plan 51-03

### Pre-existing flaky test (out of scope)

**File:** `test/scoria/warning_inventory/capture_parity_test.exs`
**Test:** "optimized compile-only capture catches high-signal unclassified warning (injected)"

Full-suite `mix test` run after Plan 51-03's changes (`lib/scoria/observe/telemetry.ex`,
`lib/scoria/observe/buffer.ex`, `test/scoria/observe/buffer_test.exs`) showed 1 failure
in this unrelated warning-inventory ratchet test:

```
Expected the injected high-signal warning to appear in offenders.
Offenders found: []
```

This is a pre-existing, environment-dependent flake in the warning-inventory capture
harness, not caused by Plan 51-03's files. Confirmed:
- The test file has zero relationship to `lib/scoria/observe/*` or the FOUND-01 flush
  logic.
- Running the file standalone (`mix test test/scoria/warning_inventory/capture_parity_test.exs`)
  passes green (2 tests, 0 failures) -- it only fails under full-suite parallel
  `--only __ratchet_compile_only__` subprocess isolation.
- STATE.md already documents this exact test as a known local-env-only artifact:
  "capture_parity_test.exs left unchanged - verify-first reproduction on the release
  head passed, confirming Bucket F was a local-env-only artifact, not a real contract
  break."

Per the executor scope boundary (fix only issues directly caused by the current task's
changes), this is logged here rather than fixed. Plan 51-03's own verification lanes
(`test/scoria/observe/buffer_test.exs`, `test/scoria/observe/telemetry_test.exs`, and
`test/scoria/observe/` full regression) are all green.

## Plan 51-04

### Same pre-existing flaky test recurred (out of scope)

Full-suite `mix test` after Plan 51-04's changes (`lib/scoria/observe/adapters/req_llm.ex`,
`test/scoria/observe/adapters/req_llm_test.exs`, `CHANGELOG.md`) reported `1 failure`
out of 1159 tests. Re-ran `test/scoria/warning_inventory/capture_parity_test.exs` standalone
-- 2 tests, 0 failures -- confirming this is the exact same environment-dependent flake
logged under Plan 51-03 above (only fails under full-suite parallel subprocess isolation,
zero relationship to `lib/scoria/observe/adapters/*`). Plan 51-04's own verification lanes
are all green: `mix test test/scoria/observe/adapters/req_llm_test.exs test/scoria/observe/`
(76 tests, 0 failures) and the CHANGELOG grep gate (`OK`).
