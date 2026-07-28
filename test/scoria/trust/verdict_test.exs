defmodule Scoria.Trust.VerdictTest do
  use ExUnit.Case, async: true

  alias Scoria.Trust.Verdict

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
    end

    test "all fields can be populated" do
      verdict = %Verdict{
        tier: "untrusted",
        score: 0.92,
        reason_code: :prompt_injection,
        scanner: MyApp.Scanner
      }

      assert verdict.tier == "untrusted"
      assert verdict.score == 0.92
      assert verdict.reason_code == :prompt_injection
      assert verdict.scanner == MyApp.Scanner
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
end
