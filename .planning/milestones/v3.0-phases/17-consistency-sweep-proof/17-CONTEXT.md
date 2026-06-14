# Phase 17: Consistency sweep + proof - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning
**Source:** Advisor-mode discussion (`minimal_decisive`) — user selected all 4 gray areas, four parallel subagent research passes returned, user approved the synthesized decision set as a coherent whole.

<domain>
## Phase Boundary

Phase 17 is the proof-and-documentation sweep that CLOSES the v3.0 Control Room milestone (Phases 11–17). It closes PROOF-01, PROOF-02, PROOF-03 by producing a measurable baseline→final rubric delta per screen, asserting the raw-color-class count is zero, building before/after contact sheets, and documenting the `ui.ex` component catalog + screenshot harness usage in `docs/MAINTAINERS.md`.

**This phase does not do new UI work.** The dashboard is already converted onto the shared `ui.ex` component layer (Phases 12–16), motion/responsive/theme parity already shipped (Phase 16), and the raw-color count is ALREADY 0 (DS-06 drift guard enforces it; `test/support/ds06_baseline.txt` is empty). Phase 17 PROVES and DOCUMENTS that result — it must not regress screens, add net-new backend capability, add new route families or fake data, introduce committed binaries, add new merge-blocking CI lanes, or expand the screenshot/critique harness beyond what the proof needs. If the final audit surfaces a genuine regression, the fix is a small targeted correction, not a re-opening of earlier phase scope.

</domain>

<decisions>
## Implementation Decisions

### Final Audit Method (PROOF-01 delta)
- **D-01:** Use a HYBRID audit, not LLM-only and not deterministic-only. Re-run the existing LLM critique to produce the method-matched per-screen rubric delta, AND commit a deterministic, zero-API-cost checklist that resolves each of the 11 baseline P1 findings. A rubric "delta" is only honest if the final scores are produced by the SAME method as the 2026-06-04 baseline (LLM vision critique); a non-deterministic LLM run alone is not a re-runnable proof in the repo's executable-proof culture — the deterministic P1 checklist supplies that.
- **D-02:** The LLM critique re-run uses the existing harness path unchanged: `mix scoria.ui.shots --critique` → `Scoria.UICritique.critique_screen/3` (ReqLLM vision, the same 9-dimension rubric) over the same 9 screens, canonical `populated · desktop · dark` state. Do not invent a new critique methodology or rubric for the final pass — method-match is the whole point.
- **D-03:** The LLM critique pass is non-deterministic (scores can shift ±1–2 between runs without code changes). Mitigate by stamping the run date and the model id/version into the commit message / report header, the standard practice for an LLM-assisted audit trail. Treat the deterministic P1 checklist — not the raw LLM scores — as the falsifiable proof a future maintainer re-verifies.
- **D-04:** The 11 baseline P1s were predominantly responsive / density / a11y findings directly targeted by Phases 14–16. The resolution checklist maps each P1 → resolving phase + concrete evidence (component/CSS/test). This checklist requires no API key to re-verify.

### Before/After Contact Sheets (PROOF-02)
- **D-05:** Ship a COMMITTED contact-sheet GENERATOR plus a committed markdown index; the rendered images stay gitignored and regenerable. Do NOT commit a montage binary (violates the repo's zero-binary posture) and do NOT ship a markdown-only index whose links point at gitignored PNGs (dead links on any machine but the author's — fails PROOF-02's "document the iteration" intent).
- **D-06:** Extend the existing dev harness rather than inventing a new conceptual surface: either a new `priv/dev/contact_sheet.mjs` or a `--before/--after` (contact-sheet) mode on `priv/dev/shots.mjs`. It must accept the baseline dir and final dir as arguments (e.g. `--before priv/shots/2026-06-04 --after priv/shots/<final-date>`) so a future maintainer can re-run the loop for the next milestone pass by pointing at new dated dirs.
- **D-07:** Commit the generator + a `contact_sheet_index.md` (records the baseline dir, the final dir, and per-screen baseline→final delta notes). The generated HTML/grid output lives gitignored alongside the PNGs under `priv/shots/`, and the generator stays excluded from the shipped Hex package via the existing `mix.exs` `package.files` posture (same treatment as `shots.mjs`).
- **D-08:** A fresh "final" screenshot set must be captured (seed-first → `mix scoria.ui.shots`) into a new dated dir before generating the contact sheet, so the "after" side reflects the Phase-16-complete dashboard. The baseline "before" set already exists on disk at `priv/shots/2026-06-04/`.

### Design-System Component Catalog (PROOF-03)
- **D-09:** Treat `lib/scoria_web/ui.ex` `@moduledoc` / per-component `@doc` + the existing `attr`/`slot` declarations as the catalog SSOT. Backfill the moduledoc and any sparse `@doc` strings so `mix docs` (ExDoc) renders the full, drift-free component reference (attributes, slots, usage) by construction. Do NOT create a standalone hand-written `docs/design_system.md` that would drift from `ui.ex` on every attr/slot change.
- **D-10:** Add a concise "Design-system component catalog" section to `docs/MAINTAINERS.md` that lists the shared components at a glance (table, drawer, modal, field, form_section, notebook, raw_evidence, skeleton, toast, badge, metric, panel, object_header, empty_state, command_palette, flash_group, and any others present in `ui.ex`) and points maintainers to `mix docs` for the full attribute/slot reference. PROOF-03 names `docs/MAINTAINERS.md` explicitly, so the catalog entry-point lives there.
- **D-11:** The harness-usage half of PROOF-03 is ALREADY satisfied by the existing "Screenshot + Critique Harness (dev-only)" section in `docs/MAINTAINERS.md` — verify it stays accurate (e.g. if a contact-sheet command is added, document it there) rather than rewriting it.

### Proof Report Artifact + Raw-Color-Zero Assertion (PROOF-01)
- **D-12:** Consolidate the audit into ONE committed report file under `priv/shots/` (e.g. `priv/shots/gap_register_final.md`, mirroring the committed baseline `priv/shots/gap_register.md`). It holds: (1) the per-screen baseline→final rubric delta table, (2) the deterministic 11-P1 resolution checklist (D-04), and (3) the raw-color-zero section. Do NOT split the proof across a dated subdir + a separate PROOF doc — one citable file for a one-time milestone close.
- **D-13:** Assert raw-color-zero by CITING the existing executable, not by adding a redundant counting script. The report's zero section states the count is 0 and names the enforcement: `test/scoria_web/ds06_drift_guard_test.exs` (the ratchet test, the stale-baseline test, and the `ui.ex`-zero assertion) plus the empty `test/support/ds06_baseline.txt` — any future raw-palette introduction fails `mix test` automatically. The count is already 0 and already guarded; do not re-prove what DS-06 guarantees.

### Claude's Discretion
- Exact filenames (`contact_sheet.mjs` vs a `shots.mjs` flag; `gap_register_final.md` vs an equivalent name), the precise markdown layout of the delta table and P1 checklist, CSS/HTML of the generated contact sheet grid, plan slicing, and which dated dir name the final shots land in are planner/executor discretion within the decisions above.
- The planner may choose whether the final critique run covers all 9 screens or is scoped to screens that had baseline P1s plus a representative sample — but the per-screen delta table must cover the same 9 screens the baseline covered so the delta is complete.
- Whether the MAINTAINERS.md catalog section sits inside or adjacent to the existing harness section is discretion, as long as both the catalog and harness usage are reachable from `docs/MAINTAINERS.md`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope, Requirements, and Prior Decisions
- `.planning/PROJECT.md` — v3.0 Control Room goal, product boundary, personas, UI-only milestone constraints; Phase 17 is the milestone-closing proof phase.
- `.planning/REQUIREMENTS.md` — PROOF-01, PROOF-02, PROOF-03 definitions and traceability (lines ~53–55, 107–109).
- `.planning/ROADMAP.md` — Phase 17 goal, success criteria, dependency on Phase 16, and the "re-run audit / rubric-delta + raw-color → 0 / before-after contact sheets / MAINTAINERS catalog + harness" framing.
- `.planning/STATE.md` — current milestone state (Phase 16 complete, ready to plan Phase 17), accumulated decisions.
- `.planning/phases/16-motion-responsive-theme-parity/16-CONTEXT.md` — explicitly defers final contact sheets, final audit deltas, and MAINTAINERS design-system docs to Phase 17; lists the proof surfaces (`priv/dev/shots.mjs`, `scoria.ui.shots`, DS-06 guard) Phase 17 consumes.
- `.planning/phases/11-evaluation-engine-seed-depth/11-CONTEXT.md` — original screenshot/critique harness decisions, state matrix, rubric dimensions, ready sentinel, dev-only posture, and the baseline-audit design (the loop Phase 17 re-runs).
- `.planning/phases/14-least-iterated-screens-polish/14-CONTEXT.md` and `.planning/phases/15-high-traffic-screens-evidence-adapters/15-CONTEXT.md` — what was converted on the least-iterated and high-traffic screens (provides the "resolved by" evidence for the P1 checklist).
- `.planning/phases/12-design-system-component-layer/12-CONTEXT.md` — the `ui.ex` token-gateway and DS-06 ratchet that the component catalog documents and the zero-claim cites.

### Proof Loop — Harness, Rubric, Audit Artifacts
- `lib/mix/tasks/scoria.ui.shots.ex` — the `mix scoria.ui.shots` task (screenshot pass + `--critique` pass); the audit loop Phase 17 re-runs.
- `lib/scoria/ui_critique.ex` — `Scoria.UICritique.critique_screen/3`, the 9-dimension rubric and ReqLLM vision call used for the baseline and the final delta.
- `priv/dev/shots.mjs` — committed Node/Playwright screenshot harness (dark/light × mobile/desktop × empty/populated/overlay matrix); the contact-sheet generator extends or sits beside this.
- `priv/shots/gap_register.md` — the committed BASELINE audit (2026-06-04: 0 P0, 11 P1, 71 passing); the comparison anchor and the source of the 11 P1s to resolve.
- `priv/shots/2026-06-04/` — on-disk (gitignored) baseline screenshot set; the "before" side of the contact sheets.
- `priv/shots/.gitignore` — encodes the "PNG/JSON gitignored, only `gap_register.md` committed" rule the new artifacts must respect.

### Raw-Color-Zero Proof (DS-06)
- `test/scoria_web/ds06_drift_guard_test.exs` — the executable raw-palette ratchet (ratchet test + stale-baseline test + `ui.ex`-zero assertion); the artifact the zero-claim cites.
- `test/support/ds06_baseline.txt` — currently EMPTY (zero headroom); empty-by-design is the proof there is no remaining raw-palette debt.
- `test/scoria_web/ui_drift_guard_test.exs` — guard against per-component status-color helpers (supporting evidence for consistency).

### Component Catalog Source + Docs Targets
- `lib/scoria_web/ui.ex` — `ScoriaWeb.UI` shared components; the `@moduledoc`/`@doc`/`attr`/`slot` declarations are the catalog SSOT to backfill so `mix docs` renders it.
- `docs/MAINTAINERS.md` — PROOF-03 target; already contains "Screenshot + Critique Harness (dev-only)" usage (verify/extend), needs the new "Design-system component catalog" entry-point section.
- `.planning/phases/12-design-system-component-layer/12-UI-SPEC.md` — component contracts (slots/attrs/tokens/DS-06 regex) — useful cross-check that the catalog matches the design contract.

### Hex Package Hygiene
- `mix.exs` (`package.files`) — explicit `priv/` subdir inclusions that EXCLUDE dev tooling (`priv/dev/`, `priv/shots/`) from the shipped Hex package; new generator + report artifacts must stay excluded, same as `shots.mjs`.

### Brand Voice (for any new copy)
- `brandbook/brand-book.md` — binding brand voice (calm, exact, useful) for any new report/doc/catalog copy; avoid hype/anthropomorphism.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix scoria.ui.shots` + `--critique` already runs the full screenshot and 9-dimension LLM critique loop — the final audit re-uses it verbatim (method-match requirement D-02).
- `priv/dev/shots.mjs` already captures the dark/light × mobile/desktop × state matrix per screen and writes to dated `priv/shots/{date}/` dirs — the contact-sheet generator reads two such dirs (before/after).
- `Scoria.UICritique` already encodes the 9-dimension rubric and writes per-screen findings JSON; the baseline `gap_register.md` aggregation pattern is the template for the final delta report.
- `test/scoria_web/ds06_drift_guard_test.exs` + empty `test/support/ds06_baseline.txt` already PROVE raw-color = 0 executably — the zero-claim cites this rather than re-counting.
- `lib/scoria_web/ui.ex` already declares components with `attr`/`slot`, so `mix docs` will render a structured catalog once moduledocs are backfilled.

### Established Patterns
- Dev-only proof posture: harness/tooling committed to git but EXCLUDED from the Hex package via `mix.exs package.files`; `priv/shots/` captures gitignored except committed `.md` artifacts. New artifacts follow this exactly.
- Executable-proof culture: prose claims are backed by a runnable check (DS-06 ratchet, warning ratchet, lane contracts). The deterministic P1 checklist and the DS-06 citation honor this; the non-deterministic LLM scores are an audit trail, not the falsifiable proof.
- Single committed artifact per shots dir: only `gap_register.md`-style `.md` files are committed out of the gitignored shots tree. The final report (`gap_register_final.md`) and `contact_sheet_index.md` follow that convention.
- `mix docs`/ExDoc as the non-drifting reference surface; SSOT lives in code (`ui.ex` attr/slot/@doc), not parallel prose.

### Integration Points
- Final audit connects through `scoria.ui.shots --critique`, `Scoria.UICritique`, a new committed `priv/shots/gap_register_final.md`, and the baseline `priv/shots/gap_register.md`.
- Contact sheets connect through `priv/dev/shots.mjs` (or a sibling `contact_sheet.mjs`), the on-disk `priv/shots/2026-06-04/` + a new final dated dir, a committed `contact_sheet_index.md`, and `priv/shots/.gitignore` / `mix.exs package.files`.
- Component catalog connects through `lib/scoria_web/ui.ex` moduledocs, `mix docs`/ExDoc, and a new section in `docs/MAINTAINERS.md`.
- Raw-color-zero proof connects through `test/scoria_web/ds06_drift_guard_test.exs`, `test/support/ds06_baseline.txt`, and a citation in the final report.

</code_context>

<specifics>
## Specific Ideas

- The audit delta table covers the same 9 screens as the 2026-06-04 baseline so the "improvement" claim is complete, not cherry-picked.
- The P1 resolution checklist is concrete and falsifiable: each baseline P1 (e.g. "eval_specs — responsive 2/5: fixed sidebar at 375px", "prompts — a11y 2/5: no visible focus indicators") maps to its resolving phase + the component/CSS/test that fixed it (mobile shell + off-canvas drawer from Phase 16, focus-visible hardening from Phase 16, shared-table conversions from Phases 14–15, etc.).
- Contact-sheet generator is re-runnable next milestone: `--before <dir> --after <dir>` so future passes diff new dated dirs with no code change.
- The "after" screenshot set is captured seed-first (`mix run priv/repo/dev_seed.exs` → `mix phx.server` → `mix scoria.ui.shots`) so populated screens render their most-useful state, matching the baseline capture conditions.
- Catalog copy and report copy follow Scoria brand voice — calm, exact, useful; operator-evidence framing; no hype.
- Note the harness's known empty-state limitation (Review Queue, Eval Workbench, Prompt Registry, Workflow Index are not `?tenant=`-scoped → populated-only captures) when assembling per-screen before/after rows, so missing empty-state shots are not misread as a gap.

</specifics>

<deferred>
## Deferred Ideas

- A standing browser-a11y lane (axe across all screens/themes/viewports) and CI visual-regression screenshot baselines — explicitly out of v3.0 scope (deferred in Phase 16); the harness stays dev-only.
- Adding the screenshot/critique or contact-sheet generation to merge-blocking CI — stays a maintainer-invoked dev tool.
- A recurring multi-date audit archive (dated subdirs per audit) — only worth it if a recurring audit cadence is planned; the one-time milestone close uses a single consolidated report.
- A standalone `docs/design_system.md` — rejected in favor of `ui.ex` moduledocs + `mix docs` as the non-drifting SSOT.
- Release `0.1.1` publish via release-please — tracked in PROJECT.md Release Queue, not Phase 17.
- No todo matches were found for Phase 17, so no todos were folded or reviewed.

</deferred>

---

*Phase: 17-consistency-sweep-proof*
*Context gathered: 2026-06-13*
