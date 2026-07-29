---
created: 2026-07-18T00:00:00Z
title: Flaky warning-inventory capture_parity_test under full-suite ordering
area: testing
files:
  - test/scoria/warning_inventory/capture_parity_test.exs
---

## Problem

`test/scoria/warning_inventory/capture_parity_test.exs:53` ("optimized
compile-only capture catches high-signal unclassified warning (injected)")
fails intermittently under a full `mix test` run depending on seed/ordering
(reproduces on `--seed 0`), but passes cleanly in isolation (2 tests, 0
failures).

Surfaced during the phase 54.1 post-merge test gate. It is **not** a regression
from phase 54.1 — that phase touched only observe/adapter boot-attach wiring and
docs; this test and `lib/scoria/warning_inventory/` were untouched. The test
injects a temporary module (`test/scoria/__ratchet_parity_tmp_test.exs`) and
asserts it appears in the compile-warning offenders list, which is inherently
sensitive to concurrent compilation / suite ordering.

## Solution

Make the parity check order-independent — likely by isolating the temp-module
injection+compile from other tests' compilation (e.g. force sync, unique temp
paths already present, or capture offenders scoped to the injected module rather
than a global snapshot). Confirm it predates phase 54.1 via `git log` on the
test file, then harden the injection/capture so the assertion holds regardless
of seed.

## Notes

- Pre-existing flake; deferred as tracked debt (user decision, phase 54.1 exec).
- Repro: `mix test --seed 0` (fails); `mix test test/scoria/warning_inventory/capture_parity_test.exs` (passes).
