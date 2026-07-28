defmodule Scoria.Trust.ScanTest do
  use ExUnit.Case, async: true

  alias Scoria.Trust
  alias Scoria.Trust.Scan
  alias Scoria.Trust.Scanner.NoOp
  alias Scoria.Trust.Verdict

  # Test scanner double: returns whatever verdict tier the caller asked for
  # via context[:verdict_tier], so the exhaustive monotonic-law test below
  # can exercise all 4 (incoming, verdict) tier combinations against one
  # scanner module.
  defmodule TierEchoScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, context) do
      {:ok, %Verdict{tier: Map.fetch!(context, :verdict_tier), reason_code: :untrusted_source}}
    end
  end

  defmodule RaisingScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: raise("boom")
  end

  defmodule ThrowingScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: throw(:boom)
  end

  defmodule ExitingScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: exit(:boom)
  end

  defmodule ErrorTupleScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:error, :classifier_unavailable}
  end

  defmodule MalformedScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: :garbage_not_a_verdict
  end

  defmodule SlowScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context) do
      Process.sleep(200)
      {:ok, %Verdict{tier: "untrusted"}}
    end
  end

  defmodule LaunderingScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, %Verdict{tier: "trusted"}}
  end

  defmodule NotScannedScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, :not_scanned}
  end

  defmodule JunkTierScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, %Verdict{tier: "super-duper-trusted"}}
  end

  defmodule ScoringScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, %Verdict{tier: "untrusted", score: 0.987}}
  end

  describe "NoOp true no-op (D-17)" do
    test "resolves to the incoming tier unchanged" do
      assert {:ok, %Verdict{tier: "trusted"}} =
               Scan.scan("content", %{content_scanner: NoOp, incoming_tier: "trusted"})

      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{content_scanner: NoOp, incoming_tier: "untrusted"})
    end

    test "defaults incoming_tier to Trust.default_tier/0 when absent" do
      assert {:ok, %Verdict{tier: tier}} = Scan.scan("content", %{content_scanner: NoOp})
      assert tier == Trust.default_tier()
    end

    test "zero telemetry is captured for the NoOp path" do
      test_pid = self()

      :telemetry.attach_many(
        "scan-noop-telemetry-test",
        [[:scoria, :trust, :scanned], [:scoria, :trust, :fallback]],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("scan-noop-telemetry-test") end)

      {:ok, %Verdict{}} = Scan.scan("content", %{content_scanner: NoOp, incoming_tier: "trusted"})

      refute_receive {:telemetry, _event, _measurements, _metadata}, 50
    end
  end

  describe "monotonic taint law (D-19) -- exhaustive 4-combination enumeration" do
    test "(incoming: trusted, verdict: trusted) resolves trusted" do
      assert {:ok, %Verdict{tier: "trusted"}} =
               Scan.scan("content", %{
                 content_scanner: TierEchoScanner,
                 incoming_tier: "trusted",
                 verdict_tier: "trusted"
               })
    end

    test "(incoming: trusted, verdict: untrusted) resolves untrusted -- scanner adds taint" do
      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{
                 content_scanner: TierEchoScanner,
                 incoming_tier: "trusted",
                 verdict_tier: "untrusted"
               })
    end

    test "(incoming: untrusted, verdict: trusted) resolves untrusted -- laundering is REFUSED" do
      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{
                 content_scanner: TierEchoScanner,
                 incoming_tier: "untrusted",
                 verdict_tier: "trusted"
               })
    end

    test "(incoming: untrusted, verdict: untrusted) resolves untrusted" do
      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{
                 content_scanner: TierEchoScanner,
                 incoming_tier: "untrusted",
                 verdict_tier: "untrusted"
               })
    end

    test "a deliberately malicious scanner attempting to upgrade trust is refused" do
      # LaunderingScanner ALWAYS claims "trusted" no matter the content. On
      # untrusted incoming content this is exactly the attack the monotonic
      # law exists to prevent -- prove the upgrade never lands.
      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("known-malicious-payload", %{
                 content_scanner: LaunderingScanner,
                 incoming_tier: "untrusted"
               })
    end

    test "a junk verdict tier value fails closed to untrusted rather than passing through" do
      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{content_scanner: JunkTierScanner, incoming_tier: "trusted"})
    end
  end

  describe "fail-closed error isolation (D-20)" do
    test "a raising scanner resolves to untrusted + :scanner_error, caller survives" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_error}} =
               Scan.scan("content", %{content_scanner: RaisingScanner, incoming_tier: "trusted"})

      # The test process itself is proof the caller never crashed.
      assert Process.alive?(self())
    end

    test "a throwing scanner resolves to untrusted + :scanner_error" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_error}} =
               Scan.scan("content", %{content_scanner: ThrowingScanner, incoming_tier: "trusted"})
    end

    test "an exiting scanner resolves to untrusted + :scanner_error" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_error}} =
               Scan.scan("content", %{content_scanner: ExitingScanner, incoming_tier: "trusted"})
    end

    test "a scanner returning {:error, _} resolves to untrusted + :scanner_error" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_error}} =
               Scan.scan("content", %{content_scanner: ErrorTupleScanner, incoming_tier: "trusted"})
    end

    test "a scanner returning a malformed (non-Verdict, non-tagged-tuple) value fails closed" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_error}} =
               Scan.scan("content", %{content_scanner: MalformedScanner, incoming_tier: "trusted"})
    end
  end

  describe "fail-closed timeout isolation (D-20)" do
    test "a scanner sleeping past the bounded timeout resolves to untrusted + :scanner_timeout" do
      assert {:ok, %Verdict{tier: "untrusted", reason_code: :scanner_timeout}} =
               Scan.scan("content", %{
                 content_scanner: SlowScanner,
                 incoming_tier: "trusted",
                 timeout: 20
               })
    end
  end

  describe "{:ok, :not_scanned} contributes no opinion" do
    test "incoming tier passes through unchanged when scanner declines to classify" do
      assert {:ok, %Verdict{tier: "trusted"}} =
               Scan.scan("content", %{content_scanner: NotScannedScanner, incoming_tier: "trusted"})

      assert {:ok, %Verdict{tier: "untrusted"}} =
               Scan.scan("content", %{content_scanner: NotScannedScanner, incoming_tier: "untrusted"})
    end
  end

  describe "Scoria.Trust.scan/2 delegator (D-18)" do
    test "returns the same resolved result as Scoria.Trust.Scan.scan/2" do
      context = %{content_scanner: TierEchoScanner, incoming_tier: "trusted", verdict_tier: "untrusted"}

      assert Trust.scan("content", context) == Scan.scan("content", context)
    end
  end

  describe "score is never threaded past the host boundary" do
    test "the resolved verdict's score is always nil, even if a scanner sets one" do
      assert {:ok, %Verdict{score: nil}} =
               Scan.scan("content", %{content_scanner: ScoringScanner, incoming_tier: "trusted"})
    end
  end
end
