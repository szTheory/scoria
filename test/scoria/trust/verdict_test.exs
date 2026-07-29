defmodule Scoria.Trust.VerdictTest do
  use ExUnit.Case, async: true

  alias Scoria.Trust.Scan
  alias Scoria.Trust.Scanner
  alias Scoria.Trust.Verdict

  # Fixture for the scanner_tier / plan 57-03 describe block below: echoes
  # whatever tier the caller asks for via context[:verdict_tier], mirroring
  # test/scoria/trust/scan_test.exs's TierEchoScanner.
  defmodule EchoScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, context) do
      {:ok, %Verdict{tier: Map.fetch!(context, :verdict_tier)}}
    end
  end

  describe "@enforce_keys [:tier]" do
    test "constructing without :tier raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("%Scoria.Trust.Verdict{}")
      end
    end

    test "constructing with :tier is valid" do
      verdict = %Verdict{tier: "trusted"}
      assert verdict.tier == "trusted"
      assert verdict.score == nil
      assert verdict.reason_code == nil
      assert verdict.scanner == nil
      assert verdict.scanner_tier == nil
    end

    test "all fields can be populated" do
      verdict = %Verdict{
        tier: "untrusted",
        score: 0.92,
        reason_code: :prompt_injection,
        scanner: MyApp.Scanner,
        scanner_tier: "trusted"
      }

      assert verdict.tier == "untrusted"
      assert verdict.score == 0.92
      assert verdict.reason_code == :prompt_injection
      assert verdict.scanner == MyApp.Scanner
      assert verdict.scanner_tier == "trusted"
    end
  end

  describe "reason_codes/0" do
    test "returns the closed enum" do
      assert Verdict.reason_codes() == [
               :prompt_injection,
               :moderation_flag,
               :untrusted_source,
               :scanner_error,
               :scanner_timeout,
               :unknown
             ]
    end
  end

  describe "normalize_reason_code/1 (D-21)" do
    test "an in-enum atom passes through unchanged" do
      assert Verdict.normalize_reason_code(:prompt_injection) == :prompt_injection
      assert Verdict.normalize_reason_code(:moderation_flag) == :moderation_flag
      assert Verdict.normalize_reason_code(:untrusted_source) == :untrusted_source
      assert Verdict.normalize_reason_code(:scanner_error) == :scanner_error
      assert Verdict.normalize_reason_code(:scanner_timeout) == :scanner_timeout
      assert Verdict.normalize_reason_code(:unknown) == :unknown
    end

    test "an unrecognized atom falls back to :unknown" do
      assert Verdict.normalize_reason_code(:not_a_real_code) == :unknown
    end

    test "a non-atom value falls back to :unknown" do
      assert Verdict.normalize_reason_code("prompt_injection") == :unknown
      assert Verdict.normalize_reason_code(nil) == :unknown
      assert Verdict.normalize_reason_code(42) == :unknown
    end
  end

  describe "scanner_tier evidence field (D-01b, plan 57-03)" do
    test "a scanner returning trusted against an untrusted incoming tier: tier is clamped, scanner_tier holds the scanner's returned value" do
      assert {:ok, %Verdict{tier: "untrusted", scanner_tier: "trusted"}} =
               Scan.scan("content", %{
                 content_scanner: EchoScanner,
                 incoming_tier: "untrusted",
                 verdict_tier: "trusted"
               })
    end

    test "a scanner returning untrusted against a trusted incoming tier: tier is clamped, scanner_tier still holds the scanner's returned value" do
      assert {:ok, %Verdict{tier: "untrusted", scanner_tier: "untrusted"}} =
               Scan.scan("content", %{
                 content_scanner: EchoScanner,
                 incoming_tier: "trusted",
                 verdict_tier: "untrusted"
               })
    end

    test "the NoOp path leaves scanner_tier nil -- distinguishable from a scanner that returned the default tier" do
      assert {:ok, %Verdict{scanner_tier: nil}} =
               Scan.scan("content", %{content_scanner: Scanner.NoOp, incoming_tier: "trusted"})
    end

    test "tier's clamp semantics for a representative set of incoming/scanner pairs are byte-identical to the pre-phase monotonic law" do
      cases = [
        {"trusted", "trusted", "trusted"},
        {"trusted", "untrusted", "untrusted"},
        {"untrusted", "trusted", "untrusted"},
        {"untrusted", "untrusted", "untrusted"}
      ]

      for {incoming, scanner_returns, expected_tier} <- cases do
        assert {:ok, %Verdict{tier: ^expected_tier}} =
                 Scan.scan("content", %{
                   content_scanner: EchoScanner,
                   incoming_tier: incoming,
                   verdict_tier: scanner_returns
                 })
      end
    end
  end
end
