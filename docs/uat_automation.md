# UAT automation — author phase UATs as tests, not checklists

Phase UAT is automated, not manual. Every user-observable truth a phase claims is
asserted by a test that runs in CI, so phase verification needs **zero human
walkthrough**. There are two tiers; classify each UAT truth into one.

## Tier 1 — server-rendered (default `mix test`, already in CI)

Anything observable in server-rendered HTML — element presence, CSS classes,
ARIA roles, `phx-*` bindings, conditional rendering, async resolution lifecycle —
is asserted with `Phoenix.LiveViewTest` in the phase's existing test files:

- Screen behavior → `test/scoria_web/live/<screen>_live_test.exs`
- Component contracts → `test/scoria_web/ui_component_test.exs`

These are mandatory. They run in the existing `mix test --warnings-as-errors`
lane on every PR. Most UAT truths land here.

## Tier 2 — real browser (`mix scoria.ui.e2e`, `e2e` job in `ci.yml`)

Truths a Floki-based LiveViewTest **cannot** reach — client-side JS execution
(`JS.hide`, `phx-window-keydown`), CSS layout/positioning, animations, and
multi-step re-render in a live browser — go in `priv/dev/e2e/*.spec.mjs`
(`@playwright/test`), driving the dev dashboard (`mix dev.setup` + `mix phx.server`).

- The lane is `testDir`-driven: **add a `.spec.mjs` file and it runs** — no new
  mix task, no CI change.
- Specs share the readiness sentinel via `priv/dev/e2e/lib/ready.mjs`
  (`waitForReady` — `data-scoria-ready="true"` on `<html>`).
- `priv/dev/` is excluded from the Hex package (`mix.exs` `files:` is an
  allowlist), so e2e tooling never ships.

Run locally:

```sh
mix dev.setup
PORT=4010 mix phx.server          # 4010 avoids the local :4000 Docker conflict
mix scoria.ui.e2e --base-url http://localhost:4010/scoria
```

## The `test.fixme` rule — register, never silently skip

A browser truth that is real but **not yet reachable** — a known deferred CSS
defect, a stubbed data source, or an affordance not yet wired into a screen — is
authored as `test.fixme('<ID/reason> — <named unlock>')`. It is listed in the
report (visible, not forgotten) but does not run, so the lane stays green. When
the unlock lands (the fix, the wiring, the seed), flip `fixme` → active **in the
same commit**. Never author a bare assertion that fails today; never omit a known
truth silently.

Example (Phase 12, `priv/dev/e2e/uat.spec.mjs`):

- Active: skeleton loading state resolves in a real browser.
- `fixme`: toast auto/manual dismiss (inbox approval not deterministically
  reachable in the dev app), `CR-01` multi-toast stacking (Phase 15 CSS fix),
  notebook tab-switch (`SRE.remote_invocation_evidence/1` is a stub),
  `WR-03` drawer positioning (Phase 14/15), escape-dismiss (no screen uses the
  `<.modal>`/`<.drawer>` shells yet).

## Verify

```sh
mix test --warnings-as-errors                 # Tier 1 + DS-06 drift guard
mix scoria.ui.e2e --base-url <dev-url>         # Tier 2 (active specs pass, fixme skipped)
```

Both run in CI (`ci.yml`: the `verify` reusable workflow + the `e2e` job; `ci-gate`
requires both).
