# Phase 11: Evaluation Engine + Seed Depth — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 7 new/modified files
**Analogs found:** 6 / 7 (1 file has no Elixir analog — Node script)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/scoria.ui.shots.ex` | Mix task | request-response + file-I/O | `lib/mix/tasks/scoria.warning_inventory.ex` | exact |
| `priv/dev/shots.mjs` | Node script / CLI tool | file-I/O | none (no existing JS tooling in project) | no analog |
| `priv/repo/dev_seed.exs` | seed script | CRUD | `examples/support_copilot/priv/repo/dev_seed.exs` | exact |
| `lib/scoria/ui_critique.ex` (in-harness critique module) | service | request-response | `lib/scoria/eval/judge_runner.ex` | role-match |
| `priv/shots/gap_register.md` | committed artifact | file-I/O | `lib/mix/tasks/scoria.warning_inventory.ex` (generates `.planning/WARNING-INVENTORY.md`) | partial |
| `mix.exs` (`package.files`) | config | transform | `mix.exs` lines 131–149 (current `package` stanza) | exact (in-place modification) |
| `test/scoria/ui_critique_test.exs` | test | request-response | `test/mix/tasks/scoria.eval_test.exs` + `test/scoria/eval/judge_runner_test.exs` | role-match |

---

## Pattern Assignments

### `lib/mix/tasks/scoria.ui.shots.ex` (Mix task, request-response + file-I/O)

**Analog:** `lib/mix/tasks/scoria.warning_inventory.ex`

**Imports / module header pattern** (lines 1–16):
```elixir
defmodule Mix.Tasks.Scoria.WarningInventory do
  use Mix.Task

  @shortdoc "Captures and classifies full-suite warning inventory for maintainers"

  alias Scoria.WarningInventory

  @switches [
    format: :string,
    write: :boolean,
    since: :string,
    scope: :string,
    include_runtime: :boolean,
    quiet: :boolean
  ]
```
Mirror: declare `@switches` as a module attribute, use `use Mix.Task`, put `@shortdoc` before the alias block.

**`run/1` entry point with strict OptionParser** (lines 18–23):
```elixir
  @impl Mix.Task
  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end
```
Use `strict: @switches` (not bare `switches:`) so unknown flags are caught and surfaced immediately.

**`System.cmd/3` shell-out pattern for Node** (lines 214–218 of `scoria.warning_inventory.ex` — git call):
```elixir
  defp git_sha do
    case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> "unknown"
    end
  end
```
Mirror for Node shell-out: pass args as a list (shell injection safety), use `stderr_to_stdout: true`, check exit code, call `Mix.raise/1` on non-zero.

**`Mix.shell().info/1` output pattern** (lines 49–52):
```elixir
    Mix.shell().info("==> Warning inventory baseline check passed")
    Mix.shell().info("==> Wrote .planning/warning-inventory.baseline.json")
```
Use `Mix.shell().info/1` for all task output, never bare `IO.puts`. Reserve `Mix.raise/1` for fatal errors.

**File.write! committed artifact pattern** (lines 140–143):
```elixir
    File.write!(
      ".planning/WARNING-INVENTORY.md",
      render_markdown(rows, metadata)
    )
```
Mirror for `priv/shots/gap_register.md`: use `File.write!` with the absolute-safe relative path. Call `File.mkdir_p!` on the parent dir first.

**Lazy app start — do NOT call `Mix.Task.run("app.start")` for the screenshot pass.** The screenshot pass only calls `System.cmd("node", ...)` — no Ecto, no app needed. Only start the app for the critique pass (ReqLLM needs the application running for config/env). Pattern from `scoria.eval.ex` lines 16–17:
```elixir
  def run(args) do
    # Start the application so we can use Repo
    Mix.Task.run("app.start")
```
Invert: call `Mix.Task.run("app.start")` only inside the `--critique` branch, not at the top of `run/1`.

**`Mix.raise/1` for environment prerequisite errors** (from `scoria.post_publish_smoke.ex` lines 56–64):
```elixir
  defp registry_version! do
    case System.get_env("SCORIA_REGISTRY_VERSION") do
      nil ->
        Mix.raise("""
        SCORIA_REGISTRY_VERSION is required — set to the exact published semver, e.g.:

            SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
        """)
      version ->
        version
    end
  end
```
Mirror for `ANTHROPIC_API_KEY` absence and missing `node` executable: use heredoc `Mix.raise` with actionable copy per the UI-SPEC copywriting contract.

---

### `priv/dev/shots.mjs` (Node script, file-I/O)

**No Elixir analog exists.** The project has a single JS file (`assets/js/scoria.js`) — it is a browser hook file, not a Node CLI script. Use the RESEARCH.md patterns directly.

**Key facts from codebase to mirror:**

1. `assets/js/scoria.js` lines 83–86 — the sentinel set on `phx:page-loading-stop`:
```javascript
  window.addEventListener("phx:page-loading-stop", function () {
    document.documentElement.setAttribute("data-scoria-ready", "true");
  });
```
The harness gates on `document.documentElement.getAttribute('data-scoria-ready') === 'true'`.

2. `assets/js/scoria.js` lines 41–50 — `ThemeToggle` is CSS-only, sets `data-theme` on `document.documentElement`:
```javascript
  Hooks.ThemeToggle = {
    mounted: function () {
      var root = document.documentElement;
      // ...
      this.el.addEventListener("click", function () {
        var next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
        root.setAttribute("data-theme", next);
        try { localStorage.setItem("scoria-theme", next); } catch (e) {}
      });
    },
  };
```
Set `data-theme` directly on `document.documentElement` via `page.evaluate()` — do not click the button. No re-wait on sentinel needed (CSS-only, no LiveView round-trip).

3. No `package.json` / `node_modules` in the project — Playwright runs via `npx playwright`. The script must be a standalone ES module (`import { chromium } from 'playwright'`).

---

### `priv/repo/dev_seed.exs` (seed script, CRUD)

**Analog:** `examples/support_copilot/priv/repo/dev_seed.exs`

**File header / SupportJourney spine pattern** (lines 1–12):
```elixir
# Dev seed — populates the Scoria operator dashboard with realistic data so every
# screen expresses meaningful content. Mirrors the gallery chat flows server-side.
#
#   mix run priv/repo/dev_seed.exs
#
# Safe to run repeatedly (creates additional runs each time).

alias Scoria.SupportJourney

identity = SupportJourney.runtime_identity()

IO.puts("Seeding Scoria dashboard data for tenant #{identity.tenant_id}...")
```
Mirror verbatim structure. For the new seed, extend to:
```elixir
# SupportJourney spine — do not inline these values
tenant_id    = SupportJourney.tenant_id()       # "acme-corp"
session_id   = SupportJourney.session_id()      # "support-session-42"
connector_key = SupportJourney.connector_key()  # "billing"
```

**Idempotent run creation pattern** (lines 14–23, wrap in try/rescue):
```elixir
{:ok, _} =
  Scoria.start_run(identity,
    root_role_id: "support_agent",
    initial_step: %{sequence: 1, kind: "tool", role_id: "support_agent", status: "queued"},
    handlers: %{"tool" => {SupportCopilot.RuntimeHandlers, :lookup_support_ticket}}
  )

IO.puts("  ✓ ticket-lookup run")
```
Use `IO.puts("  ✓ {description}")` for each successful insertion. Use `IO.puts("  ! {thing} skipped: #{Exception.message(e)}")` inside `rescue` blocks for optional lanes.

**try/rescue for optional seed sections** (lines 52–66):
```elixir
try do
  SupportCopilot.Knowledge.ensure_refund_policy_source!()
  # ...
  IO.puts("  ✓ knowledge-lane run")
rescue
  e -> IO.puts("  ! knowledge lane skipped: #{Exception.message(e)}")
end
```
Wrap each domain block (incidents, review candidates, eval specs, prompt templates) in `try/rescue` so one failure does not abort the entire seed.

**Idempotency guard for non-run entities** (use `Repo.get_by` + conditional insert — from RESEARCH.md Pattern 5, confirmed against `Scoria.Eval.OnlineScoreCandidate` schema):
```elixir
existing = Repo.get_by(Scoria.SRE.Incident, dedupe_key: "seed-incident-warning-001")
incident =
  if is_nil(existing) do
    {:ok, i} = Scoria.SRE.IncidentManager.open_incident(%{...})
    i
  else
    existing
  end
```

**Closing banner** (line 84):
```elixir
IO.puts("Done. Open http://localhost:4010/scoria")
```

---

### `lib/scoria/ui_critique.ex` (in-harness critique service, request-response)

**Analog:** `lib/scoria/eval/judge_runner.ex`

**Module-level alias pattern** (lines 1–6 of judge_runner.ex):
```elixir
defmodule Scoria.Eval.JudgeRunner do
  @moduledoc false

  alias Scoria.Eval
  alias Scoria.Eval.EvalRun
  alias ReqLLM.Response
```
Mirror:
```elixir
defmodule Scoria.UICritique do
  @moduledoc false

  alias ReqLLM.Generation
  alias ReqLLM.Message.ContentPart
  alias ReqLLM.Context
  alias ReqLLM.Response
```

**ReqLLM generate call with error handling** (judge_runner.ex lines 109–129):
```elixir
      case orchestrator_module.generate_object(model_spec, prompt, judge_schema(), opts) do
        {:ok, response} ->
          verdict = extract_object(response)
          # ...
          {:cont, {:ok, [score_attrs | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
```
Mirror for `generate_text/3` vision call:
```elixir
  case ReqLLM.Generation.generate_text(model_spec, messages, max_tokens: 2048) do
    {:ok, response} ->
      text = Response.text(response)
      parse_findings_json(text, screen_name)

    {:error, reason} ->
      if is_nil(System.get_env("ANTHROPIC_API_KEY")) do
        Mix.raise("ANTHROPIC_API_KEY is not set. Set it to run the critique pass.")
      else
        Mix.raise("Critique failed for #{screen_name}: #{inspect(reason)}")
      end
  end
```

**ContentPart.image/2 API** (confirmed from `deps/req_llm/lib/req_llm/message/content_part.ex` line 67):
```elixir
  # image(data, media_type \\ "image/png")
  def image(data, media_type \\ "image/png"),
    do: %__MODULE__{type: :image, data: data, media_type: media_type}
```
Usage:
```elixir
  image_part = ContentPart.image(File.read!(png_path), "image/png")
  text_part = ContentPart.text(rubric_prompt)
  messages = [Context.system(system_instruction()), Context.user([text_part, image_part])]
```

**Context.user/2 with content parts list** (confirmed from `deps/req_llm/lib/req_llm/context.ex` lines 239–243):
```elixir
  def user(content, meta) when is_list(content) and is_map(meta) do
    # accepts a list of ContentPart structs
  end
```

**`@moduledoc false` convention**: all internal modules in `lib/scoria/` that are not public API use `@moduledoc false`. JudgeRunner follows this; mirror it for `UICritique`.

**Injecting req_llm_module for testability** (judge_runner.ex lines 66–69):
```elixir
    opts =
      if rlm = fetch(attrs, :req_llm_module),
        do: [req_llm_module: rlm],
        else: []
```
Accept an optional `req_llm_module` parameter (defaulting to `ReqLLM.Generation`) so tests can inject a stub — exactly the pattern used by `JudgeRunnerTest` with `ReqLLMStub`.

---

### `priv/shots/gap_register.md` (committed artifact)

**Analog:** `.planning/WARNING-INVENTORY.md` generated by `lib/mix/tasks/scoria.warning_inventory.ex` lines 155–195

**Markdown rendering pattern** (lines 180–195 of warning_inventory.ex):
```elixir
  defp render_markdown(rows, metadata) do
    """
    # Warning Inventory

    Generated: #{metadata["generated_at"]}
    Git SHA: #{metadata["git_sha"]}
    ...
    """
  end
```
Mirror: build the gap register as a multi-line heredoc string, write it with `File.write!("priv/shots/gap_register.md", content)`. Format is locked in UI-SPEC — use that as the template, not the warning inventory format.

**`File.write!` + `Mix.shell().info` confirmation** (lines 140–152):
```elixir
    File.write!(
      ".planning/WARNING-INVENTORY.md",
      render_markdown(rows, metadata)
    )
    Mix.shell().info("==> Wrote .planning/WARNING-INVENTORY.md")
```

---

### `mix.exs` — `package.files` modification (config, transform)

**Analog:** `mix.exs` lines 131–149 (current `package` stanza — in-place modification)

**Current state** (lines 133–136):
```elixir
    files: [
      "lib",
      "priv",          # <-- bare "priv" ships everything under priv/
      "mix.exs",
```

**Required change** — replace `"priv"` with explicit subdirectory inclusions. Mirror the inclusion-list approach already used for `docs/`:
```elixir
    files: [
      "lib",
      "priv/fixtures",
      "priv/host_app_proof",
      "priv/repo",
      "priv/static",
      # priv/dev intentionally excluded — shots.mjs is not for adopters
      # priv/shots intentionally excluded — screenshot output is not for adopters
      "mix.exs",
      ".formatter.exs",
      "CHANGELOG.md",
      "README.md",
      "LICENSE",
      "docs/adoption_lanes.md",
      ...
    ],
```
Verify the exact current subdirectories under `priv/` with `ls priv/` before writing — the list above reflects the researched state (`fixtures`, `host_app_proof`, `repo`, `static`) but confirm none were added since research.

---

### `test/scoria/ui_critique_test.exs` (ExUnit test, request-response)

**Primary analog:** `test/scoria/eval/judge_runner_test.exs` (same pattern: stub the ReqLLM module, test the business logic without real API calls)

**Test module structure** (judge_runner_test.exs lines 1–7):
```elixir
defmodule Scoria.Eval.JudgeRunnerTest do
  use Scoria.EvalCase, async: false

  alias Scoria.Eval
  alias Scoria.Eval.JudgeRunner

  defmodule ReqLLMStub do
    def generate_object(model_spec, prompt, _schema, _opts) do
      send(self(), {:req_llm_called, model_spec, prompt})
      {:ok, %{object: %{"score" => 1.0, "status" => "passed", ...}}}
    end
  end
```
Mirror for `UICritiqueTest`:
```elixir
defmodule Scoria.UICritiqueTest do
  use ExUnit.Case, async: true

  alias Scoria.UICritique

  defmodule ReqLLMStub do
    def generate_text(_model_spec, _messages, _opts) do
      {:ok, %ReqLLM.Response{...}}  # or a minimal stub struct
    end
  end
```

**`async: false` when app must be started**, `async: true` for pure unit tests. The critique test covers JSON shape validation (pure — no DB, no app start) so use `async: true`.

**Secondary analog:** `test/mix/tasks/scoria.eval_test.exs` lines 1–16 — simple output assertion with `capture_io`:
```elixir
defmodule Mix.Tasks.Scoria.EvalTest do
  use Scoria.EvalCase, async: false

  import ExUnit.CaptureIO

  test "runs safely and parses dataset arg" do
    output = capture_io(fn ->
      Mix.Tasks.Scoria.Eval.run(["--dataset", "00000000-0000-0000-0000-000000000000"])
    end)

    assert output =~ "Starting evaluation"
  end
end
```
Mirror for the Mix task's no-arg invocation test (no running server required):
```elixir
  import ExUnit.CaptureIO

  test "exits with helpful error when --critique flag is set but ANTHROPIC_API_KEY is absent" do
    System.delete_env("ANTHROPIC_API_KEY")
    assert_raise Mix.Error, ~r/ANTHROPIC_API_KEY/, fn ->
      Mix.Tasks.Scoria.UiShots.run(["--critique"])
    end
  end
```

**Test for 9-key findings JSON shape** (unit test, no API call):
```elixir
  @valid_keys ~w(brand_fit consistency hierarchy affordance a11y responsive motion microcopy density)

  test "parse_findings_json/2 returns map with all 9 rubric keys" do
    json = Jason.encode!(%{
      "brand_fit"   => %{"score" => 3, "findings" => []},
      "consistency" => %{"score" => 2, "findings" => ["flash_tone_class uses raw palette"]},
      "hierarchy"   => %{"score" => 4, "findings" => []},
      "affordance"  => %{"score" => 3, "findings" => []},
      "a11y"        => %{"score" => 3, "findings" => []},
      "responsive"  => %{"score" => 4, "findings" => []},
      "motion"      => %{"score" => 3, "findings" => []},
      "microcopy"   => %{"score" => 3, "findings" => []},
      "density"     => %{"score" => 3, "findings" => []}
    })

    result = UICritique.parse_findings_json(json, "test_screen")

    assert is_map(result)
    for key <- @valid_keys do
      assert Map.has_key?(result, key), "missing key: #{key}"
      assert is_integer(result[key]["score"])
      assert is_list(result[key]["findings"])
    end
  end
```

---

## Shared Patterns

### App start — only when needed
**Source:** `lib/mix/tasks/scoria.eval.ex` lines 16–17; `lib/mix/tasks/scoria.release_preview.ex` line 25
**Apply to:** `lib/mix/tasks/scoria.ui.shots.ex` critique branch only

`scoria.eval.ex` calls `Mix.Task.run("app.start")` unconditionally. `scoria.release_preview.ex` calls `Mix.Task.run("loadpaths")` (lighter). For `scoria.ui.shots`, start the app only for the `--critique` branch (ReqLLM needs it), never for the screenshot-only pass.

### `Mix.raise/1` for fatal errors
**Source:** `lib/mix/tasks/scoria.warning_inventory.ex` line 23; `lib/mix/tasks/scoria.post_publish_smoke.ex` lines 58–65; `lib/mix/tasks/scoria.release_preview.ex` lines 44–48
**Apply to:** `lib/mix/tasks/scoria.ui.shots.ex`, `lib/scoria/ui_critique.ex`

```elixir
Mix.raise("missing --dataset option")           # one-liner
Mix.raise("""
  multi-line with actionable instructions
""")                                            # heredoc for complex messages
```

### `Mix.shell().info/1` vs `IO.puts`
**Source:** `lib/mix/tasks/scoria.warning_inventory.ex` lines 106–150; `lib/mix/tasks/scoria.release_preview.ex` lines 31, 48
**Apply to:** All Mix task output in `lib/mix/tasks/scoria.ui.shots.ex`

Use `Mix.shell().info/1` for task progress and results. Use `IO.puts` only in scripts (`priv/repo/dev_seed.exs`) where Mix is not available.

### `System.cmd/3` list-of-args safety
**Source:** `lib/mix/tasks/scoria.warning_inventory.ex` line 215 (`System.cmd("git", ["rev-parse", "HEAD"], ...)`); `lib/mix/tasks/scoria.release_preview.ex` line 36 (`System.cmd("mix", ["hex.build", ...], ...)`)
**Apply to:** `lib/mix/tasks/scoria.ui.shots.ex` Node shell-out

Always pass the command and arguments as a list — never interpolate into a shell string. Add `stderr_to_stdout: true` and `into: IO.stream()` for streaming output:
```elixir
System.cmd("node", [script_path, "--base-url", url, ...],
  stderr_to_stdout: true,
  into: IO.stream()
)
```

### `@switches` module attribute pattern
**Source:** `lib/mix/tasks/scoria.warning_inventory.ex` lines 8–15
**Apply to:** `lib/mix/tasks/scoria.ui.shots.ex`

Declare all CLI switches in a single `@switches` module attribute at the top of the module, then pass `strict: @switches` to `OptionParser.parse/2`.

### `use ExUnit.Case, async: true` for pure unit tests
**Source:** `test/scoria/warning_inventory/baseline_check_test.exs` line 3; `test/scoria_web/ui_drift_guard_test.exs` line 3
**Apply to:** `test/scoria/ui_critique_test.exs`

Tests that only exercise pure Elixir logic (JSON parsing, map key validation) with no DB or app process should use `async: true`. Tests that exercise Mix tasks requiring `app.start` or real DB use `async: false`.

### SupportJourney spine guard comment
**Source:** `examples/support_copilot/priv/repo/dev_seed.exs` lines 8–12 + CONTEXT.md D-09
**Apply to:** `priv/repo/dev_seed.exs`

```elixir
# SupportJourney spine — do not inline these values
tenant_id    = SupportJourney.tenant_id()
session_id   = SupportJourney.session_id()
connector_key = SupportJourney.connector_key()
```
This comment is load-bearing policy: broken calls surface under `mix test` (via `SupportJourneySourceTest`).

### `defmodule ReqLLMStub` injection pattern for tests
**Source:** `test/scoria/eval/judge_runner_test.exs` lines 7–17
**Apply to:** `test/scoria/ui_critique_test.exs`

Define a local `defmodule ReqLLMStub` inside the test module with the same function signature as `ReqLLM.Generation.generate_text/3`. Pass it via an optional parameter (e.g., `req_llm_module: ReqLLMStub`) to avoid real API calls in tests.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/dev/shots.mjs` | Node CLI / automation script | file-I/O | No Node scripts exist in this project. `assets/js/scoria.js` is a browser bundle, not a CLI. Use RESEARCH.md Pattern 3 directly (Playwright state matrix navigation). |

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `examples/support_copilot/priv/repo/`, `lib/scoria/eval/`, `test/mix/tasks/`, `test/scoria/`, `assets/js/`, `deps/req_llm/lib/`, `mix.exs`
**Files read:** 18
**Pattern extraction date:** 2026-06-04
