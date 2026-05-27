defmodule Scoria.WarningBaselineTest do
  use ExUnit.Case, async: true

  alias Scoria.WarningBaseline

  @fixtures Path.join(["test", "fixtures", "warning_baseline"])

  test "valid fixture has no invalid or expired rows on check date" do
    baseline =
      WarningBaseline.load(
        file: Path.join(@fixtures, "valid.md"),
        date: ~D[2026-01-01]
      )

    assert WarningBaseline.accepted_rows(baseline) |> length() == 1
    assert WarningBaseline.invalid_rows(baseline) == []
    assert WarningBaseline.expired_rows(baseline) == []
  end

  test "expired fixture reports expired rows after expiry date" do
    baseline =
      WarningBaseline.load(
        file: Path.join(@fixtures, "expired.md"),
        date: ~D[2026-06-08]
      )

    [row] = WarningBaseline.expired_rows(baseline)
    assert row.surface == "full-suite (non-canonical)"
    assert row.expires == ~D[2020-01-01]
  end

  test "blank owner rows are invalid, not accepted" do
    baseline =
      WarningBaseline.load(
        file: Path.join(@fixtures, "invalid_blank_owner.md"),
        date: ~D[2026-01-01]
      )

    assert WarningBaseline.accepted_rows(baseline) == []
    assert length(WarningBaseline.invalid_rows(baseline)) == 1
  end

  test "resolved section dates do not affect accepted rows" do
    baseline =
      WarningBaseline.load(
        file: Path.join(@fixtures, "resolves_section_trap.md"),
        date: ~D[2026-01-01]
      )

    assert length(WarningBaseline.accepted_rows(baseline)) == 1
    assert WarningBaseline.expired_rows(baseline) == []
  end

  test "row is valid through end of expiry day" do
    baseline =
      WarningBaseline.load(
        file: Path.join(@fixtures, "expired.md"),
        date: ~D[2020-01-01]
      )

    assert WarningBaseline.expired_rows(baseline) == []
  end
end
