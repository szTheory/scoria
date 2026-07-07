defmodule Scoria.Eval.TimingTest do
  use ExUnit.Case, async: true

  alias Scoria.Eval.Timing

  test "measure/1 returns the function result and non-negative elapsed milliseconds" do
    assert {:ok, latency_ms} = Timing.measure(fn -> :ok end)
    assert is_integer(latency_ms)
    assert latency_ms >= 0
  end

  test "mark/0 and elapsed_ms/1 measure whole-run duration" do
    mark = Timing.mark()
    assert is_integer(mark)
    assert is_integer(Timing.elapsed_ms(mark))
    assert Timing.elapsed_ms(mark) >= 0
  end
end
