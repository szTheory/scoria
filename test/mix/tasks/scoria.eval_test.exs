defmodule Mix.Tasks.Scoria.EvalTest do
  use Scoria.EvalCase, async: false

  import ExUnit.CaptureIO

  test "runs safely and parses dataset arg" do
    # We pass a dummy UUID just to see it parse args and attempt to fetch
    # Since dataset doesn't exist, it will likely log an error or message.
    # We test that it outputs the correct parsing trace.
    output = capture_io(fn ->
      Mix.Tasks.Scoria.Eval.run(["--dataset", "00000000-0000-0000-0000-000000000000"])
    end)

    assert output =~ "Starting evaluation"
  end
end
