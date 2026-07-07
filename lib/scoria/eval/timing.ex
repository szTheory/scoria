defmodule Scoria.Eval.Timing do
  @moduledoc false

  def mark, do: System.monotonic_time()

  def elapsed_ms(mark) when is_integer(mark) do
    mark
    |> then(&(System.monotonic_time() - &1))
    |> System.convert_time_unit(:native, :millisecond)
  end

  def measure(fun) when is_function(fun, 0) do
    started_at = mark()
    result = fun.()
    {result, elapsed_ms(started_at)}
  end
end
