defmodule Scoria.Observe.CircuitBreaker do
  @table :scoria_circuit_breakers

  def init_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
      _ ->
        @table
    end
    :ok
  end

  def open?(model_id) do
    now = System.system_time(:millisecond)
    case :ets.lookup(@table, model_id) do
      [{^model_id, :open, _count, last_failure_at}] ->
        timeout = config(:timeout, 30_000)
        now < last_failure_at + timeout
      _ ->
        false
    end
  end

  def record_failure(model_id, opts \\ []) do
    now = System.system_time(:millisecond)
    default_tuple = {model_id, :closed, 0, now}
    
    new_count = :ets.update_counter(@table, model_id, {3, 1}, default_tuple)
    
    threshold = Keyword.get(opts, :threshold) || config(:threshold, 5)
    
    if new_count >= threshold do
      :ets.insert(@table, {model_id, :open, new_count, now})
    else
      :ets.update_element(@table, model_id, {4, now})
    end
    :ok
  end

  def record_success(model_id) do
    :ets.insert(@table, {model_id, :closed, 0, 0})
    :ok
  end

  def sweep_half_open do
    now = System.system_time(:millisecond)
    timeout = config(:timeout, 30_000)
    
    models = :ets.match(@table, {:"$1", :open, :_, :_})
    
    Enum.each(models, fn [model_id] ->
      case :ets.lookup(@table, model_id) do
        [{^model_id, :open, _count, last_failure_at}] ->
          if now >= last_failure_at + timeout do
            :ets.insert(@table, {model_id, :half_open, 0, 0})
          end
        _ ->
          :ok
      end
    end)
    
    :ok
  end

  defp config(key, default) do
    opts = Application.get_env(:scoria, :circuit_breaker_opts, [])
    Keyword.get(opts, key, default)
  end
end
