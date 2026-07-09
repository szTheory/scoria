---
id: ci-policy-job-cache-key-mislabel
title: "CI policy job: -test-mix- cache key while compiling under MIX_ENV=dev (WR-01)"
status: completed
created: 2026-06-14
completed: 2026-07-09
priority: medium
resolves_phase: null
tags: [ci, cache, correctness, phase-23, pre-phase-25]
source: "Surfaced by 23-REVIEW.md (WR-01) during Phase 23 code review. Non-blocking advisory; phase goal verified passed (5/5 must-haves)."
---

## Resolution

Resolved by the current CI contract. `.github/workflows/ci-verify.yml` now sets `MIX_ENV: test`
on the `policy` job while retaining the `-test-mix-` cache key, and
`test/scoria/ci_policy_contract_test.exs` pins both the policy env and env-scoped cache-key
segments.

## Why this exists

Phase 23 renamed the `policy` job's cache key in `.github/workflows/ci-verify.yml`
from the neutral `${{ runner.os }}-mix-` to the semantically assertive `-test-mix-`
recipe. But the `policy` job has **no `env: MIX_ENV: test`** at job level, so its
`mix compile --warnings-as-errors` step runs under Elixir's default `MIX_ENV=dev` and
writes artifacts to `_build/dev/`.

Net effect today: harmless — the `build` job runs its own compile under `MIX_ENV=test`
and produces the correct `build-test-env` artifact that downstream jobs consume. The
mislabeling is latent.

## Risk it creates

When Phase 25/26 introduce parallelization / matrix sharding, any consumer that
restores the `test-mix` cache **directly** (rather than the `build-test-env` artifact)
could find a `_build` populated with dev-compiled output under a key that claims to be
test-env. The policy job's WAE gate also only catches dev-env warnings, not test-env.

## Fix options (pick one before Phase 25/26 wire matrix cache consumers)

1. Add `env: { MIX_ENV: test }` to the `policy` job in `ci-verify.yml` so its compile
   and cache key agree (preferred — keeps the policy gate a true test-env WAE check).
2. Or rename the policy job's cache key back to `-dev-mix-` to match what it actually
   writes.

Add/extend a `ci_policy_contract_test.exs` assertion to pin whichever invariant is
chosen (e.g. policy job carries `MIX_ENV: test`, or its key segment matches its env).

## Related

- 23-REVIEW.md also flagged WR-02 (stale `# Two-job topology` comment in `ci.yml:17` —
  now three jobs in ci-verify.yml) and WR-03 (pre-existing contract test name
  `"test job depends on policy and preserves closeout chain order"` now passes only via
  `build`'s transitive `needs: policy`; name is imprecise). Both low-risk; fold into the
  same cleanup pass if convenient.
