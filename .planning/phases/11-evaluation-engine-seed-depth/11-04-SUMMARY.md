---
phase: 11-evaluation-engine-seed-depth
plan: "04"
subsystem: tooling
tags: [hex-packaging, gitignore, maintainer-docs, supply-chain, eval, harness]

# Dependency graph
requires:
  - "11-03 — priv/dev/shots.mjs and lib/mix/tasks/scoria.ui.shots.ex committed (EVAL-01)"
provides:
  - "mix.exs package.files refactored: explicit priv/ subdirs, priv/dev + priv/shots excluded"
  - "priv/shots/.gitignore: ignores */ + *.png + *.json, tracks gap_register.md"
  - "priv/shots/gap_register.md: committed baseline artifact placeholder"
  - "docs/MAINTAINERS.md § Screenshot + Critique Harness: prerequisites, seed-first, --critique, empty-state limitation"
affects:
  - "11-05-PLAN — baseline audit can now commit gap_register.md (gitignore policy in place)"
  - "Phase 17 — PROOF-03 references MAINTAINERS.md harness section"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "mix.exs package.files explicit inclusion list: priv/fixtures + priv/host_app_proof + priv/repo/migrations + priv/repo/knowledge_migrations + priv/static (no bare priv glob)"
    - "priv/shots/.gitignore: */ ignores date-stamped subdirs; *.png *.json ignore captures; !gap_register.md negation preserves committed audit baseline"
    - "Root .gitignore belt-and-suspenders: priv/shots/**/*.png + priv/shots/**/*.json as secondary guard"

key-files:
  created:
    - "priv/shots/.gitignore"
    - "priv/shots/gap_register.md"
  modified:
    - "mix.exs"
    - ".gitignore"
    - "docs/MAINTAINERS.md"

key-decisions:
  - "priv/repo/migrations and priv/repo/knowledge_migrations included in package.files (adopter-required); priv/repo/dev_seed.exs excluded by using explicit migration subdirs instead of bare priv/repo — deviation from open question #2 resolution which said omit priv/repo entirely"
  - "priv/shots/.gitignore uses !gap_register.md negation as belt-and-suspenders even though gap_register.md is not matched by */ or *.png or *.json — explicit for clarity"
  - "gap_register.md seeded with placeholder content documenting the pre-audit known issue (flash_tone_class raw palette) so the committed file is immediately useful"

requirements-completed: [EVAL-03]

# Metrics
duration: 20min
completed: 2026-06-04
---

# Phase 11 Plan 04: Package Hygiene, Gitignore Policy, and Maintainer Docs Summary

**Hex package manifest refactored to explicit priv/ subdirectory inclusions excluding the dev harness; priv/shots gitignore policy committed; docs/MAINTAINERS.md documents harness prerequisites, seed-first workflow, decoupled --critique pass, and the empty-state limitation for 4 non-tenant-scoped screens.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-04
- **Completed:** 2026-06-04
- **Tasks:** 2
- **Files modified:** 3 (mix.exs, .gitignore, docs/MAINTAINERS.md)
- **Files created:** 2 (priv/shots/.gitignore, priv/shots/gap_register.md)

## Accomplishments

- Replaced bare `"priv"` glob in `mix.exs package.files` with explicit subdirectory inclusions: `priv/fixtures`, `priv/host_app_proof`, `priv/repo/migrations`, `priv/repo/knowledge_migrations`, `priv/static` — excluding `priv/dev` (shots.mjs) and `priv/shots` (screenshot output) with inline rationale comments
- Created `priv/shots/.gitignore` that ignores `*/`, `*.png`, `*.json` while tracking `gap_register.md` via `!gap_register.md` negation
- Created `priv/shots/gap_register.md` as the committed baseline audit placeholder (populated by Plan 05 audit run)
- Added belt-and-suspenders `priv/shots/**/*.png` and `priv/shots/**/*.json` entries to root `.gitignore`
- Appended "Screenshot + Critique Harness (dev-only)" section to `docs/MAINTAINERS.md` covering all EVAL-03 documentation requirements
- `mix compile` passes clean after mix.exs change
- `git ls-files priv/dev/shots.mjs` returns the path — committed dev tooling confirmed

## Task Commits

1. **Task 1: mix.exs + gitignore rules** — `f2ac830` (chore)
2. **Task 2: docs/MAINTAINERS.md harness section** — `2529b95` (docs)

## Files Created/Modified

- `/Users/jon/projects/scoria/mix.exs` — `package.files` refactored from bare `"priv"` to explicit subdirectory inclusions. Excludes `priv/dev` and `priv/shots` with documented rationale. Includes `priv/repo/migrations` and `priv/repo/knowledge_migrations` for adopter migration path; excludes `priv/repo/dev_seed.exs` (not needed by adopters).
- `/Users/jon/projects/scoria/.gitignore` — Added `priv/shots/**/*.png` and `priv/shots/**/*.json` as belt-and-suspenders guard outside the primary `priv/shots/.gitignore` policy.
- `/Users/jon/projects/scoria/priv/shots/.gitignore` — Primary gitignore policy for screenshot captures. Rules: `*/` ignores date-stamped subdirs, `*.png` ignores screenshot captures, `*.json` ignores critique findings; `!gap_register.md` explicitly preserves the committed baseline.
- `/Users/jon/projects/scoria/priv/shots/gap_register.md` — Committed baseline artifact placeholder. Includes pre-audit known issue: `flash_tone_class/1` raw palette (DS-05 gap, fix in Phase 12). Populated with scored findings by Plan 05 critique run.
- `/Users/jon/projects/scoria/docs/MAINTAINERS.md` — Appended "Screenshot + Critique Harness (dev-only)" section. Covers: Node.js + Playwright prerequisites (D-02); seed-first workflow (`mix run priv/repo/dev_seed.exs`); screenshot pass (`mix phx.server` + `mix scoria.ui.shots`); decoupled critique pass (`mix scoria.ui.shots --critique`, D-04, needs ANTHROPIC_API_KEY); empty-state limitation for the 4 non-tenant-scoped screens (Review Queue, Eval Workbench, Prompt Registry, Workflow Index — RESEARCH Pitfall 5, resolves open question #1); dev-only posture summary.

## Decisions Made

- Used explicit migration subdirs (`priv/repo/migrations` + `priv/repo/knowledge_migrations`) rather than omitting `priv/repo` entirely — adopter-required migration files must ship; dev_seed.exs is excluded by not including `priv/repo` as a whole (see Deviation below)
- Seeded `gap_register.md` with a placeholder documenting the pre-audit known issue rather than an empty file — provides immediate value and confirms the file is tracked before the critique run

## Deviations from Plan

### Narrowed exclusion instead of omitting priv/repo entirely

**[Rule 2 - Missing critical functionality] priv/repo/migrations must ship to adopters**

- **Found during:** Task 1 — `ls priv/repo/` revealed `migrations/` and `knowledge_migrations/` in addition to `dev_seed.exs`
- **Issue:** Open question #2 resolution said "omit `priv/repo` from package.files entirely." But `priv/repo/migrations` and `priv/repo/knowledge_migrations` contain Ecto migration files that adopters must run via `mix ecto.migrate` — shipping without them would break the adoption path
- **Fix:** Included `priv/repo/migrations` and `priv/repo/knowledge_migrations` explicitly while not including `priv/repo/dev_seed.exs` by listing only the migration subdirs (not the whole `priv/repo` dir). This achieves the security goal (dev_seed.exs excluded) without breaking adopters.
- **Files modified:** `mix.exs`
- **Commit:** f2ac830 (included in Task 1 commit)

The plan explicitly anticipated this: "If priv/repo contains adopter-required files beyond dev_seed.exs, narrow the exclusion instead and note the deviation in the SUMMARY."

## Known Stubs

None — both files are complete implementations. `gap_register.md` contains a placeholder preamble with the pre-audit known issue documented; it will be overwritten with scored findings by the Plan 05 audit pass. This is intentional and expected per the plan (gap register is populated by Plan 05, not Plan 04).

## Threat Flags

No new security-relevant surface beyond what the plan's `<threat_model>` covers:

| Flag | File | Description |
|------|------|-------------|
| T-11-06 mitigated | mix.exs | package.files explicit inclusion list — priv/dev/shots.mjs and priv/shots/ excluded from shipped package; verified via grep acceptance criteria |
| T-11-02 mitigated | priv/shots/.gitignore | */ + *.png + *.json gitignored; only gap_register.md (synthetic data) tracked |
| T-11-SC confirmed | docs/MAINTAINERS.md | No Hex packages installed — Playwright documented as maintainer prerequisite only, no mix.exs change |

## Self-Check: PASSED

- `mix.exs` grep -c '"priv"' returns 0: VERIFIED
- `mix.exs` contains "priv/static" and "priv/fixtures": VERIFIED
- `mix.exs` does not contain "priv/dev" or "priv/shots" as inclusion entries: VERIFIED
- `git ls-files priv/dev/shots.mjs` returns path: VERIFIED
- `grep 'gap_register.md' priv/shots/.gitignore` matches: VERIFIED
- `priv/shots/.gitignore` ignores *.png and *.json: VERIFIED
- `mix compile` exits 0: VERIFIED
- `grep -c 'scoria.ui.shots' docs/MAINTAINERS.md` >= 1 (result: 7): VERIFIED
- `grep 'playwright install chromium' docs/MAINTAINERS.md` matches: VERIFIED
- docs/MAINTAINERS.md mentions --critique flag: VERIFIED
- docs/MAINTAINERS.md mentions ANTHROPIC_API_KEY: VERIFIED
- docs/MAINTAINERS.md documents empty-state limitation for Review Queue / Eval Workbench / Prompt Registry / Workflow Index: VERIFIED
- Commit f2ac830 exists: FOUND
- Commit 2529b95 exists: FOUND

## Next Phase Readiness

- Plan 05 (baseline audit) can commit `gap_register.md` — gitignore policy in place
- `mix scoria.ui.shots --critique` can write per-screen JSON findings — gitignored; gap_register.md tracks
- PROOF-03 (Phase 17) can reference the documented MAINTAINERS.md harness section
- The empty-state limitation for the 4 non-tenant-scoped screens is documented for operators reviewing gap register findings

---
*Phase: 11-evaluation-engine-seed-depth*
*Completed: 2026-06-04*
