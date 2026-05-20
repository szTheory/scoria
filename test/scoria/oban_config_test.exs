defmodule Scoria.ObanConfigTest do
  use ExUnit.Case, async: true

  test "baseline queues configuration" do
    queues = Application.get_env(:scoria, Oban)[:queues]
    
    assert Keyword.get(queues, :system) == 10
    assert Keyword.get(queues, :inference) == 20
    assert Keyword.get(queues, :evals) == 50
    assert Keyword.get(queues, :compaction) == 10
    assert Keyword.get(queues, :connector_sync) == 10
  end

  test "production runtime config behavior" do
    # In a real environment, Config.Reader would read this. We can evaluate it 
    # to simulate its effect, since it's just an Elixir script.
    
    # Simulate production environment and read config/runtime.exs
    # We will use Config.Reader for this if we want, or just evaluate it.
    
    # We can mock the env vars and evaluate the config.
    System.put_env("OBAN_SYSTEM_CONCURRENCY", "15")
    System.put_env("OBAN_INFERENCE_CONCURRENCY", "25")
    System.put_env("OBAN_EVALS_CONCURRENCY", "55")

    try do
      config = Config.Reader.read!("config/runtime.exs", env: :prod)
      oban_config = get_in(config, [:scoria, Oban, :queues])
      
      assert Keyword.get(oban_config, :system) == 15
      assert Keyword.get(oban_config, :inference) == 25
      assert Keyword.get(oban_config, :evals) == 55
    after
      System.delete_env("OBAN_SYSTEM_CONCURRENCY")
      System.delete_env("OBAN_INFERENCE_CONCURRENCY")
      System.delete_env("OBAN_EVALS_CONCURRENCY")
    end
  end
end
