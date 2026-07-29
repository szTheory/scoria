defmodule Scoria.Trust.Scan do
  @moduledoc """
  Scan orchestration: resolves the registered `Scoria.Trust.Scanner`,
  invokes it inside a bounded, isolated Task, and enforces the two most
  security-critical invariants of the trust substrate:

    - **the monotonic taint law (D-19)** — `resolved = most_restrictive(incoming_tier, verdict_tier)`.
      A scanner may only ADD taint (→ `"untrusted"`), never launder
      `"untrusted"` back to `"trusted"`. A buggy/hostile scanner cannot
      upgrade trust.
    - **fail-closed error/timeout isolation (D-20)** — any scanner `raise`,
      `throw`, `exit`, `{:error, _}`, malformed return, or a bounded-timeout
      breach resolves to `%Verdict{tier: "untrusted"}` with a distinguishing
      `reason_code` (`:scanner_error` / `:scanner_timeout`). The calling
      process never crashes and never *gains* trust from a scanner failure.

  Lives in its OWN `Scoria.Trust.TaskSupervisor` — deliberately NOT the
  tool-execution supervisor used elsewhere in the codebase — so this module
  can serve both `Knowledge.retrieve/2` and the tool executor's call site
  (Plan 05) without creating an undocumented cross-subsystem dependency
  (D-18, D-23, RESEARCH Pitfall 3).

  Synchronous by default (D-20): taint must resolve before the caller
  proceeds (before marking / before the Phase 57 confluence gate reads it).

  This module deliberately emits no telemetry of its own — trace tagging is
  a fixed-projector `scoria.trust.*` attribute group attached to the
  EXISTING span at each minting site (`Knowledge.retrieve/2`,
  `MCP.Executor`), not a new span/event owned by `Scan` (D-21). Callers
  (Plan 05) read the returned `%Verdict{}` and project it onto their own
  span.
  """

  alias Scoria.Trust
  alias Scoria.Trust.Scanner
  alias Scoria.Trust.Verdict

  @default_timeout 5_000

  @tier_order %{"untrusted" => 0, "trusted" => 1}

  @doc """
  Scans `content` given `context`, resolving to `{:ok, %Verdict{}}` whose
  `tier` obeys the monotonic taint law and whose `reason_code` is
  normalized against the closed enum (D-21). The returned verdict's `score`
  is always `nil` — a scanner's numeric confidence is host-only and never
  threaded past this boundary (D-16, D-21, T-55-18).

  ## Context keys

    - `:content_scanner` — per-call scanner module override, falling back
      to `Application.get_env(:scoria, :content_scanner,
      Scoria.Trust.Scanner.NoOp)` (D-17).
    - `:incoming_tier` — the tier of `content` BEFORE scanning, defaulting
      to `Scoria.Trust.default_tier/0`. The resolved tier can only be equal
      to or MORE restrictive than this value (D-19) — a scanner can never
      make the resolved tier less restrictive than `incoming_tier`.
    - `:timeout` — bounded scan timeout in ms (default `#{@default_timeout}`).

  When the resolved scanner is `Scoria.Trust.Scanner.NoOp`, this is a true
  no-op: no Task is spawned, and `incoming_tier` passes through unchanged
  (D-17).
  """
  @spec scan(binary() | map(), map()) :: {:ok, Verdict.t()}
  def scan(content, context \\ %{}) do
    context = Map.new(context)
    incoming_tier = Trust.normalize_tier(Map.get(context, :incoming_tier, Trust.default_tier()))
    scanner = resolve_scanner(context)

    if scanner == Scanner.NoOp do
      # D-30: no scanner ran, so there is no pre-clamp opinion to carry --
      # `scanner_tier` stays nil, distinguishable from a scanner that
      # genuinely returned the default tier.
      {:ok, %Verdict{tier: incoming_tier, scanner_tier: nil, scanner: Scanner.NoOp}}
    else
      verdict = run_scanner(scanner, content, context)
      # Captured BEFORE most_restrictive/2 folds it against incoming_tier --
      # this is the scanner's PRE-CLAMP opinion (D-01b), carried as evidence
      # only. `tier` below remains the clamped, min-wins value; the Phase 55
      # monotonic law (D-19) is untouched.
      scanner_tier = Trust.normalize_tier(verdict.tier)
      resolved_tier = most_restrictive(incoming_tier, scanner_tier)

      {:ok,
       %Verdict{
         tier: resolved_tier,
         scanner_tier: scanner_tier,
         score: nil,
         reason_code: Verdict.normalize_reason_code(verdict.reason_code),
         scanner: verdict.scanner || scanner
       }}
    end
  end

  defp resolve_scanner(context) do
    Map.get(context, :content_scanner, Application.get_env(:scoria, :content_scanner, Scanner.NoOp))
  end

  # Runs the host scanner inside a bounded, isolated Task on the dedicated
  # Scoria.Trust.TaskSupervisor. async_nolink/2 means a crashing scanner
  # process never propagates to (never crashes) the caller; Task.yield/2 +
  # Task.shutdown/2 enforces the bounded timeout (D-20).
  defp run_scanner(scanner, content, context) do
    timeout = Map.get(context, :timeout, @default_timeout)

    task =
      Task.Supervisor.async_nolink(Scoria.Trust.TaskSupervisor, fn ->
        try do
          scanner.scan(content, context)
        catch
          kind, reason -> {:__scan_caught__, kind, reason}
        end
      end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> to_verdict(result, scanner)
      nil -> fail_closed(:scanner_timeout, scanner)
      {:exit, _reason} -> fail_closed(:scanner_error, scanner)
    end
  end

  # A scanner declining to classify (`{:ok, :not_scanned}`) contributes no
  # opinion -- treat it as maximally trusted so incoming_tier alone decides
  # the outcome via the monotonic law (never adds taint, never removes it).
  defp to_verdict({:ok, %Verdict{} = verdict}, _scanner), do: verdict
  defp to_verdict({:ok, :not_scanned}, scanner), do: %Verdict{tier: "trusted", scanner: scanner}
  defp to_verdict({:error, _reason}, scanner), do: fail_closed(:scanner_error, scanner)
  defp to_verdict({:__scan_caught__, _kind, _reason}, scanner), do: fail_closed(:scanner_error, scanner)
  # Any other shape (nil, a bare map, a malformed tuple, ...) is a
  # malfunctioning scanner -- fail closed rather than guess (D-20).
  defp to_verdict(_malformed, scanner), do: fail_closed(:scanner_error, scanner)

  defp fail_closed(reason_code, scanner) do
    %Verdict{tier: "untrusted", reason_code: reason_code, scanner: scanner}
  end

  defp most_restrictive(a, b) do
    if Map.fetch!(@tier_order, a) <= Map.fetch!(@tier_order, b), do: a, else: b
  end
end
