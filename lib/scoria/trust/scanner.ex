defmodule Scoria.Trust.Scanner do
  @moduledoc """
  The BYO (bring-your-own) content scanner behaviour (D-16).

  Scoria ships no injection/moderation detector or classifier in-lib — this
  is the seam a host wires a scanner (Rebuff/LlamaGuard-shaped) into.
  `Scoria.Trust.Scanner.NoOp` is the shipped default, byte-identical to
  current behavior, zero overhead, nothing emitted (D-17).

  A scanner is invoked by `Scoria.Trust.Scan` (see `Scoria.Trust.scan/2`),
  which enforces the two most security-critical invariants against
  whatever a scanner returns:

    - the monotonic taint law (D-19) — a scanner may only ADD taint, never
      launder `untrusted` back to `trusted`.
    - fail-closed error/timeout isolation (D-20) — a scanner that raises,
      throws, exits, returns `{:error, _}`, or hangs past a bounded timeout
      can never crash the caller and can never cause content to be treated
      as more trusted than it already was.

  Implement this behaviour to register a scanner via
  `config :scoria, :content_scanner, MyScanner` (or a per-call
  `content_scanner:` override) — see `Scoria.Trust.Scan` for the
  orchestration and enforcement.
  """

  @doc """
  Scans `content` (raw binary or a structured map) given a call `context`.

  Returns `{:ok, %Scoria.Trust.Verdict{}}` when the scanner produced a
  verdict, `{:ok, :not_scanned}` when the scanner declines to classify this
  content, or `{:error, term()}` on scanner-internal failure (converted to a
  fail-closed `:scanner_error` verdict by `Scoria.Trust.Scan`).
  """
  @callback scan(content :: binary() | map(), context :: map()) ::
              {:ok, Scoria.Trust.Verdict.t()} | {:ok, :not_scanned} | {:error, term()}

  defmodule NoOp do
    @moduledoc """
    The shipped default `Scoria.Trust.Scanner` — a true no-op.

    Always returns `{:ok, :not_scanned}`, so `Scoria.Trust.Scan` short-circuits
    with zero overhead and no telemetry (D-17): registering no scanner is
    byte-identical to Scoria's current (pre-TAINT-04) behavior.
    """

    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, :not_scanned}
  end
end
