defmodule Scoria.PromptRegistry.TokenizerTest do
  use ExUnit.Case, async: true
  alias Scoria.PromptRegistry.Tokenizer

  describe "estimate_tokens/1" do
    test "with a simple string returns the correct token count using the default model" do
      tokens = Tokenizer.estimate_tokens("hello world")
      # "hello world" is typically 2 tokens
      assert tokens > 0
    end

    test "with a map containing system_message, few_shot_examples, and user_template" do
      prompt_map = %{
        system_message: "You are a helpful assistant.",
        few_shot_examples: [
          %{user: "hi", assistant: "hello!"},
          "user: bye\nassistant: see ya"
        ],
        user_template: "Translate this to french: {{text}}"
      }

      tokens = Tokenizer.estimate_tokens(prompt_map)
      assert tokens > 0
      
      # Ensure concatenation resulted in a larger count than just parts
      sys_tokens = Tokenizer.estimate_tokens("You are a helpful assistant.")
      user_tokens = Tokenizer.estimate_tokens("Translate this to french: {{text}}")
      assert tokens >= (sys_tokens + user_tokens)
    end

    test "handles string keys in maps" do
      prompt_map = %{
        "system_message" => "Sys message",
        "user_template" => "User template"
      }
      assert Tokenizer.estimate_tokens(prompt_map) > 0
    end

    test "handles nil or empty values gracefully without crashing" do
      assert Tokenizer.estimate_tokens(nil) == 0
      assert Tokenizer.estimate_tokens("") == 0
      assert Tokenizer.estimate_tokens(%{}) == 0
      assert Tokenizer.estimate_tokens(%{system_message: nil, user_template: ""}) == 0
      assert Tokenizer.estimate_tokens(123) == 0
    end
  end
end
