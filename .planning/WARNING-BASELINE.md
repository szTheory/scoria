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

## Resolved During v2.6

| Surface | Resolved Debt | Resolution Date |
|--------|----------------|-----------------|
| full-suite (non-canonical) | Project-level warning audit; full mix test --warnings-as-errors green in CI | 2026-05-27 |
| workflow/replay LiveView tests | Async teardown noise cleared via render_async sweep | 2026-05-27 |

## Resolved During v2.4

| Surface | Resolved Debt | Resolution Date |
|--------|----------------|-----------------|
| release preview docs lane | `README.md` license reference docs warning and undefined/private `Scoria.Knowledge.Source.t()` docs warning | 2026-05-27 |
