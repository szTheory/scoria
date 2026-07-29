defmodule Scoria.MCP.EnvelopeTest do
  use ExUnit.Case, async: true

  alias Scoria.MCP.Envelope
  alias Scoria.Trust
  alias Scoria.Trust.Tiered

  describe "wrap/2" do
    test "wraps a raw value with tier and provenance" do
      envelope = Envelope.wrap("payload", tier: "untrusted", provenance: %{tool_ref: :x})

      assert %Envelope{value: "payload", tier: "untrusted", provenance: %{tool_ref: :x}} = envelope
      assert %DateTime{} = envelope.enveloped_at
      assert is_nil(envelope.scan)
    end

    test "defaults tier to Trust.default_tier/0 when omitted" do
      envelope = Envelope.wrap("payload")

      assert envelope.tier == Trust.default_tier()
    end

    test "normalizes a junk tier value to the fail-closed default" do
      envelope = Envelope.wrap("payload", tier: "super-trusted")

      assert envelope.tier == Trust.default_tier()
    end

    test "is idempotent — wrapping an existing envelope returns it unchanged" do
      envelope = Envelope.wrap("payload", tier: "trusted", provenance: %{tool_ref: :x})

      assert Envelope.wrap(envelope, tier: "untrusted", provenance: %{tool_ref: :y}) == envelope
    end
  end

  describe "envelope?/1" do
    test "true for an envelope, false for anything else" do
      envelope = Envelope.wrap("payload")

      assert Envelope.envelope?(envelope)
      refute Envelope.envelope?("raw")
      refute Envelope.envelope?(%{value: "raw"})
      refute Envelope.envelope?(nil)
    end
  end

  describe "total accessors over t() | term() (D-09)" do
    test "tier/1 reads an envelope's tier, and untrusted for anything else" do
      envelope = Envelope.wrap("payload", tier: "trusted")

      assert Envelope.tier(envelope) == "trusted"
      assert Envelope.tier("raw") == "untrusted"
      assert Envelope.tier(%{}) == "untrusted"
      assert Envelope.tier(nil) == "untrusted"
    end

    test "value/1 reads an envelope's value, and the term itself for anything else" do
      envelope = Envelope.wrap("payload")

      assert Envelope.value(envelope) == "payload"
      assert Envelope.value("raw") == "raw"
    end

    test "scan/1 reads an envelope's scan slot, and nil for anything else" do
      envelope = Envelope.wrap("payload", scan: %{verdict: :clean})

      assert Envelope.scan(envelope) == %{verdict: :clean}
      assert Envelope.scan("raw") == nil
    end

    test "unwrap/1 returns {tier, value} for an envelope and for a raw term" do
      envelope = Envelope.wrap("payload", tier: "trusted")

      assert Envelope.unwrap(envelope) == {"trusted", "payload"}
      assert Envelope.unwrap("raw") == {"untrusted", "raw"}
    end
  end

  describe "@enforce_keys" do
    test "constructing without :tier raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("%Scoria.MCP.Envelope{value: \"v\"}")
      end
    end

    test "constructing without :value raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("%Scoria.MCP.Envelope{tier: \"untrusted\"}")
      end
    end
  end

  describe "Scoria.Trust.Tiered protocol impl" do
    test "delegates to Trust.normalize_tier/1 on the envelope's tier" do
      envelope = Envelope.wrap("payload", tier: "trusted")

      assert Tiered.tier(envelope) == "trusted"
    end

    test "fails closed for a junk stored tier value" do
      envelope = %Envelope{value: "payload", tier: "bogus"}

      assert Tiered.tier(envelope) == "untrusted"
    end
  end
end
