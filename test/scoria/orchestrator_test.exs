defmodule Scoria.OrchestratorTest do
  use ExUnit.Case, async: false # async: false because we might need to modify App env

  defmodule ReqLLMStub do
    def generate_text(model, prompt, opts) do
      send(self(), {:req_llm_called, :generate_text, model, prompt, opts})
      
      case model do
        "fail" -> {:error, "failed"}
        "openai:gpt-4o" -> {:ok, %{text: "primary response"}}
        "openai:gpt-4-turbo" -> {:ok, %{text: "fallback response"}}
        "openai:gpt-3.5-turbo" -> {:ok, %{text: "last resort response"}}
        _ -> {:error, "unknown model"}
      end
    end

    def generate_object(model, prompt, schema, opts) do
      send(self(), {:req_llm_called, :generate_object, model, prompt, schema, opts})

      case model do
        "fail" -> {:error, "failed"}
        "openai:gpt-4o" -> {:ok, %{object: %{success: true}}}
        "openai:gpt-4-turbo" -> {:ok, %{object: %{fallback: true}}}
        _ -> {:error, "unknown model"}
      end
    end
  end

  setup do
    # Ensure telemetry is attached for testing
    parent = self()
    handler_id = "orchestrator-test-handler"
    :telemetry.attach_many(
      handler_id,
      [
        [:scoria, :orchestrator, :request, :stop],
        [:scoria, :orchestrator, :fallback]
      ],
      fn name, measurements, metadata, _config ->
        send(parent, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)

    :ok
  end

  describe "generate_text/3" do
    test "returns ok immediately on primary success" do
      result = Scoria.Orchestrator.generate_text("openai:gpt-4o", "hello", req_llm_module: ReqLLMStub)

      assert {:ok, %{text: "primary response"}} = result
      assert_received {:req_llm_called, :generate_text, "openai:gpt-4o", "hello", _}
      assert_received {:telemetry_event, [:scoria, :orchestrator, :request, :stop], %{duration: _}, _}
      refute_received {:telemetry_event, [:scoria, :orchestrator, :fallback], _, _}
    end

    test "falls back to secondary model on primary failure" do
      # Set up a chain for a "fail" model
      old_chains = Application.get_env(:scoria, :fallback_chains, %{})
      Application.put_env(:scoria, :fallback_chains, Map.put(old_chains, "fail", ["openai:gpt-4-turbo"]))
      
      on_exit(fn ->
        Application.put_env(:scoria, :fallback_chains, old_chains)
      end)

      result = Scoria.Orchestrator.generate_text("fail", "hello", req_llm_module: ReqLLMStub)

      assert {:ok, %{text: "fallback response"}} = result
      assert_received {:req_llm_called, :generate_text, "fail", "hello", _}
      assert_received {:req_llm_called, :generate_text, "openai:gpt-4-turbo", "hello", _}
      
      assert_received {:telemetry_event, [:scoria, :orchestrator, :fallback], %{}, %{reason: "failed", primary_model: "fail", target_model: "openai:gpt-4-turbo"}}
      assert_received {:telemetry_event, [:scoria, :orchestrator, :request, :stop], %{duration: _}, _}
    end

    test "exhausts the chain and returns the final error" do
      old_chains = Application.get_env(:scoria, :fallback_chains, %{})
      Application.put_env(:scoria, :fallback_chains, Map.put(old_chains, "fail", ["also_fail", "yet_another_fail"]))
      
      on_exit(fn ->
        Application.put_env(:scoria, :fallback_chains, old_chains)
      end)

      # We need the stub to fail for these too
      # but they fall into the _ -> {:error, "unknown model"} case which is perfect.

      result = Scoria.Orchestrator.generate_text("fail", "hello", req_llm_module: ReqLLMStub)

      assert {:error, "unknown model"} = result
      assert_received {:req_llm_called, :generate_text, "fail", "hello", _}
      assert_received {:req_llm_called, :generate_text, "also_fail", "hello", _}
      assert_received {:req_llm_called, :generate_text, "yet_another_fail", "hello", _}
      
      assert_received {:telemetry_event, [:scoria, :orchestrator, :request, :stop], %{duration: _}, %{reason: "unknown model"}}
    end
  end

  describe "generate_object/4" do
    test "works with structured output" do
      schema = %{type: "object"}
      result = Scoria.Orchestrator.generate_object("openai:gpt-4o", "give me json", schema, req_llm_module: ReqLLMStub)

      assert {:ok, %{object: %{success: true}}} = result
      assert_received {:req_llm_called, :generate_object, "openai:gpt-4o", "give me json", ^schema, _}
    end
  end
end
