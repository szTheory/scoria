defmodule Scoria.TrustTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Scoria.Knowledge.Chunk
  alias Scoria.Trust
  alias Scoria.Trust.Tiered

  setup do
    handler_id = "trust-test-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scoria, :trust, :fallback],
      fn event, measurements, metadata, _config ->
        send(self(), {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  describe "tiers/0, default_tier/0, tier_key/0" do
    test "expose the closed binary vocabulary" do
      assert Trust.tiers() == ~w(trusted untrusted)
      assert Trust.default_tier() == "untrusted"
      assert Trust.tier_key() == "scoria.trust.tier"
    end
  end

  describe "tier/1 fail-closed reader (D-03)" do
    test "absent key resolves to untrusted silently -- no log, no telemetry" do
      log =
        capture_log(fn ->
          assert Trust.tier(%{}) == "untrusted"
        end)

      assert log == ""
      refute_received {:telemetry_event, _, _, _}
    end

    test "present-but-junk value resolves to untrusted with a warning + fallback telemetry" do
      log =
        capture_log(fn ->
          assert Trust.tier(%{"scoria.trust.tier" => "garbage"}) == "untrusted"
        end)

      assert log =~ "Unrecognized trust tier"
      assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: "garbage"}}
    end

    test "only the exact string \"trusted\" reads trusted" do
      assert Trust.tier(%{"scoria.trust.tier" => "trusted"}) == "trusted"
      assert Trust.tier(%{"scoria.trust.tier" => "untrusted"}) == "untrusted"

      refute_received {:telemetry_event, _, _, _}
    end

    test "case variants and non-string members fail closed" do
      for value <- ["Trusted", "TRUSTED", :trusted, 1, %{}] do
        log =
          capture_log(fn ->
            assert Trust.tier(%{"scoria.trust.tier" => value}) == "untrusted"
          end)

        assert log =~ "Unrecognized trust tier"
        assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: ^value}}
      end
    end
  end

  describe "normalize_tier/1" do
    test "passes through exact tier members" do
      assert Trust.normalize_tier("trusted") == "trusted"
      assert Trust.normalize_tier("untrusted") == "untrusted"
      refute_received {:telemetry_event, _, _, _}
    end

    test "\"Trusted\", nil, and :trusted all fail closed with fallback telemetry" do
      for value <- ["Trusted", nil, :trusted] do
        log =
          capture_log(fn ->
            assert Trust.normalize_tier(value) == "untrusted"
          end)

        assert log =~ "Unrecognized trust tier"
        assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: ^value}}
      end
    end
  end

  describe "put_tier/2" do
    test "stores a valid tier under tier_key/0" do
      assert Trust.put_tier(%{}, "trusted") == %{"scoria.trust.tier" => "trusted"}
      assert Trust.put_tier(%{}, "untrusted") == %{"scoria.trust.tier" => "untrusted"}
    end

    test "a junk value still fails closed to untrusted (never mints a bogus-trusted row)" do
      log =
        capture_log(fn ->
          assert Trust.put_tier(%{}, "bogus") == %{"scoria.trust.tier" => "untrusted"}
        end)

      assert log =~ "Unrecognized trust tier"
      assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: "bogus"}}
    end

    test "preserves other metadata keys" do
      assert Trust.put_tier(%{"foo" => "bar"}, "trusted") == %{
               "foo" => "bar",
               "scoria.trust.tier" => "trusted"
             }
    end
  end

  describe "trusted?/1" do
    test "true only when tier/1 resolves to trusted" do
      assert Trust.trusted?(%{"scoria.trust.tier" => "trusted"})
      refute Trust.trusted?(%{"scoria.trust.tier" => "untrusted"})
      refute Trust.trusted?(%{})

      log =
        capture_log(fn ->
          refute Trust.trusted?(%{"scoria.trust.tier" => "garbage"})
        end)

      assert log =~ "Unrecognized trust tier"
    end
  end

  describe "Scoria.Trust.Tiered protocol" do
    test "Chunk impl delegates to Trust.tier/1 on chunk.metadata" do
      trusted_chunk = %Chunk{metadata: %{"scoria.trust.tier" => "trusted"}}
      assert Tiered.tier(trusted_chunk) == "trusted"

      untrusted_chunk = %Chunk{metadata: %{}}
      assert Tiered.tier(untrusted_chunk) == "untrusted"
    end

    test "a chunk with a junk stored tier still fails closed via the protocol" do
      chunk = %Chunk{metadata: %{"scoria.trust.tier" => "not-a-real-tier"}}

      log =
        capture_log(fn ->
          assert Tiered.tier(chunk) == "untrusted"
        end)

      assert log =~ "Unrecognized trust tier"
    end
  end
end
