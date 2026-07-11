# Phase 50: Release readiness and `0.1.3` cut - Pattern Map

**Mapped:** 2026-07-10
**Files analyzed:** 8 (all edits — no new files in this phase)
**Analogs found:** 8 / 8 (this phase is entirely self-referential: every fix conforms to an existing convention already present elsewhere in the same file or a sibling file)

## File Classification

| File to Modify | Role | Data Flow | Closest Analog (in-repo) | Match Quality |
|---|---|---|---|---|
| `priv/repo/dev_seed.exs` (lines 959, 1047) | script/seed (event-driven, one-shot) | request-response (calls a workflow function) | `lib/scoria_web/live/prompt_live/release_workbench_live.ex:117` (the one caller already on the correct 3-arity contract) | exact — same function, same required kwarg shape |
| `test/scoria/ci_policy_contract_test.exs` (`@maintainer_docs`/`@operator_docs` constants + 7 assertions at lines 92-95, 326-329, 494-495, 502-511, 515-524, 601-624, 642) | test/contract | transform (static-file assertion) | Same file's own passing tests (e.g. the `v2.15` breadcrumb test at line 692) and `test/scoria/adoption_surface_test.exs`'s "no stale 0.1.1" pattern | exact — same test file, same assertion idiom, just repointed path/content |
| `guides/maintainers.md` (restore dropped sections under `## Hex release and recovery` at line 109 and `## CI gate map` at line 7) | docs/guide | transform (static content) | The guide's own existing sibling sections (`## Warning baseline and inventory` line 133, `## Installer contract proofs` line 86) for voice/format; pre-Phase-48 `docs/MAINTAINERS.md` (via `git show c40bc630:docs/MAINTAINERS.md`) for exact wording to adapt | exact — same document, restore in current section style |
| `priv/dev/e2e/phase16_parity.spec.mjs` (lines 533, 562, 575; also 513-514, 611/620 dual-locator sites) | test (Playwright e2e) | request-response (browser action assertion) | `priv/dev/e2e/ia_orientation.spec.mjs:160,210,231` (`.filter({ visible: true }).first()` convention) | exact — same suite family, same locator idiom already used for other dual/hidden-element cases |
| `.github/workflows/release-please.yml`, `hex-publish.yml`, `ci.yml`, `ci-verify.yml` (header comment paths, optional D-13 polish) | config (CI workflow) | batch (CI orchestration) | Each file's own existing header-comment convention (`# Maintainer guide: ...` / `# Maintainer narrative: ...`) | exact — same file, same comment line, just repoint path |
| `lib/mix/tasks/scoria.post_publish_smoke.ex` (moduledoc example, optional D-13 polish) | utility/Mix task | request-response (task invocation doc) | Its own moduledoc's adjacent `SCORIA_REGISTRY_VERSION=0.1.0` example line | exact — same doc block, same pattern, bump version literal |
| `mix.exs` (`@hexdocs_url`, optional D-14 polish) | config | transform (metadata) | Its own existing `@version`/`@hexdocs_url`/`@release_docs_url` block | exact — same file, same constant style |
| `README.md` (`docs/MAINTAINERS.md` → `guides/maintainers.md`, referenced by the test at line 511/642) | docs | transform (static content) | README's own already-correct links elsewhere to `guides/reviewer-verification.md` (Phase 48 pattern) | exact — same file, same link convention already used for the sibling guide |

## Pattern Assignments

### `priv/repo/dev_seed.exs` (script/seed, request-response call site)

**Analog:** `lib/scoria_web/live/prompt_live/release_workbench_live.ex:117` (the only other caller of this function, already correct) and the function contract itself.

**Function contract** (`lib/scoria/workflows/prompt_release.ex:13`):
```elixir
def start_release_workflow(template_id, actor_id, attrs) when is_map(attrs) or is_list(attrs) do
  attrs = Map.new(attrs)
  tenant_id = attrs |> fetch_attr(:tenant_id) |> required_id!(:tenant_id)
  ...
```

**Correct caller pattern** (`lib/scoria_web/live/prompt_live/release_workbench_live.ex:117`):
```elixir
case PromptRelease.start_release_workflow(draft_id, actor_id, tenant_id: tenant_id) do
```

**Stale call sites to fix (exact line numbers confirmed via grep):**
```elixir
# priv/repo/dev_seed.exs:959 — BEFORE
{:ok, _release_result} = PromptRelease.start_release_workflow(draft_template.id, "operator-1")
# AFTER (tenant_id already bound earlier in the seed script)
{:ok, _release_result} =
  PromptRelease.start_release_workflow(draft_template.id, "operator-1", tenant_id: tenant_id)

# priv/repo/dev_seed.exs:1047 — BEFORE
{:ok, _} = PromptRelease.start_release_workflow(draft.id, "operator-1")
# AFTER (tenant_id bound at line 991 via SupportJourney.tenant_id())
{:ok, _} =
  PromptRelease.start_release_workflow(draft.id, "operator-1", tenant_id: tenant_id)
```

**Verification convention:** re-run `mix run priv/repo/dev_seed.exs` (or `mix dev.setup`) and grep stdout — the script's own `rescue`-and-`IO.puts("! ... skipped: ...")` pattern (keep this rescue structure; do not remove per CONTEXT D-11/scope fence) must stop printing `start_release_workflow/2 is undefined`, and the `✓ ...` checkmark lines for the rest of each block must appear instead.

---

### `test/scoria/ci_policy_contract_test.exs` (test/contract, transform)

**Analog:** the file's own existing passing assertion idiom (module attribute constants read once, then `assert file_contents =~ "literal string"` throughout the file — see the already-passing `v2.15`/roadmap-breadcrumb test near line 692).

**Constants to repoint** (lines 11-12):
```elixir
# BEFORE
@maintainer_docs "docs/MAINTAINERS.md"
@operator_docs "docs/operator_verification.md"

# AFTER — both constants point at the single canonical guide; do NOT split
# @operator_docs to guides/reviewer-verification.md (that guide carries no
# ratchet/release commands per its own intro — see RESEARCH.md Assumption A2)
@maintainer_docs "guides/maintainers.md"
@operator_docs "guides/maintainers.md"
```

**Assertions that need matching content restored in `guides/maintainers.md`** (exact strings, keep as-is in the test — repair the guide instead, per D-16):
- Line 95: `assert maintainers =~ "RELEASE_PLEASE_TOKEN"`
- Lines 328-329: `assert operator_docs =~ "mix scoria.warning_ratchet.test"` / `"mix scoria.warning_ratchet.check"`
- Lines 506-510: `"## Hex release & recovery"`, `"hex-release--recovery-maintainers"`, `"HEX_API_KEY"`, `"hex-publish.yml"`, `"release-please--"`
- Lines 517-524: `"CI gate map"`, `"policy"`, `` "needs: policy" or "`policy`" ``, `"mix test.semantic_fast_path"`, `"mix test.connector"`, `"mix scoria.warning_inventory.check_baseline"`, `"Version namespaces"`, `"mix scoria.test.install_contract"`
- Lines 610, 615: `"post-publish-smoke.yml"`, `"v2.x"`

**Stale README assertions to fix in the same test file** (lines 511, 642):
```elixir
# BEFORE
assert readme =~ "docs/MAINTAINERS.md"
# AFTER (README already correctly links here per Phase 48)
assert readme =~ "guides/maintainers.md"
```

**Important — do not weaken:** these are content assertions, not path assertions alone. The fix is two-part: (1) repoint the constant, (2) restore the literal dropped content into `guides/maintainers.md` in that guide's current voice.

---

### `guides/maintainers.md` (docs/guide, transform)

**Analog:** the guide's own existing section format — each `## ` heading is followed by short prose + a fenced command block (see `## Warning baseline and inventory` at line 133, `## Installer contract proofs` at line 86).

**Sections needing restored content, keyed to the existing headings:**
- `## Hex release and recovery` (line 109) — currently uses different wording than the test expects (`and` not `&`). Add/restore, in this section: the exact heading anchor form the test checks (`hex-release--recovery-maintainers` is a GFM auto-slug of `## Hex release & recovery` — restoring the `&` heading text will regenerate the matching anchor), plus `HEX_API_KEY`, `hex-publish.yml`, and `release-please--` mentions (the release-branch prefix).
- `## CI gate map` (line 7) — add a "Version namespaces" subsection and ensure `mix test.semantic_fast_path`, `mix test.connector`, `mix scoria.warning_inventory.check_baseline`, `mix scoria.test.install_contract`, `post-publish-smoke.yml`, and `v2.x` all appear somewhere in/after this section (test uses `section_after(maintainer_docs, "## CI gate map")` — same file's own helper, keep content under that heading).
- Anywhere reasonable — restore mention of `RELEASE_PLEASE_TOKEN` (a secrets-setup / recovery detail).

**Drafting reference (not to copy verbatim, adapt to current guide voice):** `git show c40bc630:docs/MAINTAINERS.md` — the pre-Phase-48 canonical content this guide superseded.

---

### `priv/dev/e2e/phase16_parity.spec.mjs` (test, Playwright e2e)

**Analog:** `priv/dev/e2e/ia_orientation.spec.mjs:160,210,231` — the codebase's own established convention for a locator that must resolve to the actually-visible element among duplicates.

**Existing convention to copy** (`priv/dev/e2e/ia_orientation.spec.mjs:160`):
```javascript
const trigger = page.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first();
```
(also lines 210, 231 — same idiom applied to different buttons)

**Sites to fix in `phase16_parity.spec.mjs`** (bare `.first()` on the dual desktop/mobile selector, lines 533, 562, 575):
```javascript
// BEFORE
const toggle = page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first();

// AFTER
const toggle = page
  .locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile')
  .filter({ visible: true })
  .first();
```
Apply the same `.filter({ visible: true })` insertion at all 3 call sites (533, 562, 575). Lines 513-514 (a `toggleSelector` string used inside `page.evaluate`, i.e. plain DOM `querySelector`) and lines 611/620 (already viewport-scoped single-ID locators `#scoria-theme-toggle-mobile` / `#scoria-theme-toggle` used independently) do not need this change — only the combined-selector-plus-bare-`.first()` sites do. Confirm by reading each site's surrounding context before editing since not all 6 grep hits are the same bug.

**Do not use:** `force: true` or fixed `sleep` (explicitly forbidden by D-09/anti-patterns).

---

### `.github/workflows/*.yml` header comments (config, optional D-13 polish)

**Analog:** each file's own existing header-comment line — no cross-file pattern needed, just literal string repoint.

```yaml
# release-please.yml:3 and hex-publish.yml:3 — BEFORE
# Maintainer guide: docs/operator_verification.md#hex-release--recovery-maintainers
# AFTER
# Maintainer guide: guides/maintainers.md#hex-release-and-recovery

# ci.yml:18 and ci-verify.yml:11 — BEFORE
# Maintainer narrative: docs/MAINTAINERS.md — CI gate map + flake policy.
# AFTER
# Maintainer narrative: guides/maintainers.md — CI gate map + flake policy.
```

---

### `lib/mix/tasks/scoria.post_publish_smoke.ex` (utility/Mix task, optional D-13 polish)

**Analog:** the moduledoc's own adjacent example line.
```elixir
# BEFORE
#     SCORIA_REGISTRY_VERSION=0.1.1 mix scoria.post_publish_smoke
# AFTER
#     SCORIA_REGISTRY_VERSION=0.1.3 mix scoria.post_publish_smoke
```

---

### `mix.exs` (config, optional D-14 polish)

**Analog:** its own `@version`/`@hexdocs_url` constant block.
```elixir
# BEFORE
@hexdocs_url "https://hexdocs.pm/scoria"
# AFTER (matches Hex's 2026-06-01 per-package-subdomain change; old form 301s)
@hexdocs_url "https://scoria.hexdocs.pm"
```

## Shared Patterns

### Silent-rescue seed script (keep, do not remove)
**Source:** `priv/repo/dev_seed.exs` (each block wrapped in `try/rescue`, printing `"! <thing> skipped: #{Exception.message(e)}"`)
**Apply to:** Only the two specific `start_release_workflow` call sites — do not restructure the rescue pattern itself (out of scope per CONTEXT.md's "no broad seed-determinism refactor").
**Verification convention:** grep the seed script's own stdout after running it — a swallowed exception looks identical to a clean run unless you check for the `! ... skipped` line.

### Visible-element Playwright locator
**Source:** `priv/dev/e2e/ia_orientation.spec.mjs:160,210,231`
**Apply to:** `priv/dev/e2e/phase16_parity.spec.mjs` theme-toggle sites (533, 562, 575).
```javascript
page.getByRole(...).filter({ visible: true }).first();
// or, for CSS-ID-based dual selectors:
page.locator('#a, #b').filter({ visible: true }).first();
```

### Docs-contract literal-string assertions
**Source:** `test/scoria/ci_policy_contract_test.exs` (module-attribute path constants read once via `File.read!`, then many `assert content =~ "literal"` lines)
**Apply to:** Both the constant repoint and the `guides/maintainers.md` content restoration — the fix must satisfy every listed literal, not just the file path.

### Tenant-scoped workflow call
**Source:** `lib/scoria_web/live/prompt_live/release_workbench_live.ex:117` (`tenant_id: tenant_id` kwarg on `start_release_workflow/3`)
**Apply to:** Both `dev_seed.exs` call sites — this is Phase 44-06's security-hardening contract; the dev seed script must adopt it exactly, not work around it.

## No Analog Found

None. Every file in this phase's scope has a direct in-repo analog (either a sibling call site, sibling test assertion, sibling doc section, or sibling e2e locator) because this is a pure defect-repair phase against already-correct surrounding code — per RESEARCH.md's own framing, "every piece of infrastructure this phase needs already exists and is correctly designed."

## Metadata

**Analog search scope:** `priv/repo/dev_seed.exs`, `lib/scoria/workflows/prompt_release.ex`, `lib/scoria_web/live/prompt_live/release_workbench_live.ex`, `priv/dev/e2e/ia_orientation.spec.mjs`, `priv/dev/e2e/phase16_parity.spec.mjs`, `test/scoria/ci_policy_contract_test.exs`, `guides/maintainers.md`, `.github/workflows/*.yml`, `lib/mix/tasks/scoria.post_publish_smoke.ex`, `mix.exs`
**Files scanned:** 10 (via grep + targeted reads; RESEARCH.md already carried exact file:line detail so exhaustive Glob search was unnecessary)
**Pattern extraction date:** 2026-07-10
</content>
