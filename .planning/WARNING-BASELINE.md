# Warning Baseline (Scoped)

**Created:** 2026-05-27  
**Purpose:** Track accepted warning debt with explicit owner + expiry while `v2.4` keeps canonical lane warnings strict.

## Policy

- Canonical proof surfaces (`compile`, `release_preview`, lane-contract drift tests) should run warning-clean.
- Any remaining warning debt must include **owner**, **reason**, and **expiry**.
- Expired rows are treated as blockers for the next reliability pass.

## Accepted Warning Debt

| Surface | Warning Debt | Reason | Owner | Expires |
|--------|--------------|--------|-------|---------|
| full-suite (non-canonical) | Project-level warning audit has not been rerun after post-`v1.9` support-truth shims | Kept out of canonical lane scope for `v2.4`; tracked for follow-up reliability sweep | scoria-maintainers | 2026-06-07 |
| workflow/replay LiveView tests | Async teardown noise | Known legacy noise accepted at `v1.9` close; still outside canonical lane closeout contract | scoria-web-runtime | 2026-06-30 |

## Resolved During v2.4

| Surface | Resolved Debt | Resolution Date |
|--------|----------------|-----------------|
| release preview docs lane | `README.md` license reference docs warning and undefined/private `Scoria.Knowledge.Source.t()` docs warning | 2026-05-27 |
