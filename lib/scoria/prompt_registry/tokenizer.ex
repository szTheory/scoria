defmodule Scoria.PromptRegistry.Tokenizer do
  @moduledoc """
  Stateless utility module for accurately estimating token usage of prompt templates.
  Uses Tiktoken under the hood to ensure operators are warned before hitting context limits.
  """

  @default_model "gpt-4o"

  @doc """
  Estimates token usage for a given prompt map or string.

  Returns the integer count of estimated tokens. Returns `0` on error or empty/nil inputs.
  """
  def estimate_tokens(nil), do: 0
  def estimate_tokens(""), do: 0

  def estimate_tokens(text) when is_binary(text) do
    case Tiktoken.encode(@default_model, text) do
      {:ok, tokens} when is_list(tokens) -> length(tokens)
      _ -> 0
    end
  rescue
    _ -> 0
  end

  def estimate_tokens(%{} = prompt_map) do
    sys = Map.get(prompt_map, :system_message) || Map.get(prompt_map, "system_message")
    user = Map.get(prompt_map, :user_template) || Map.get(prompt_map, "user_template")

    parts = [sys, user | extract_few_shot(prompt_map)]

    combined_text =
      parts
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    estimate_tokens(combined_text)
  end

  def estimate_tokens(_), do: 0

  defp extract_few_shot(map) do
    examples = Map.get(map, :few_shot_examples) || Map.get(map, "few_shot_examples")

    case examples do
      examples when is_list(examples) ->
        Enum.map(examples, fn
          ex when is_binary(ex) -> ex
          ex when is_map(ex) ->
            Map.values(ex)
            |> Enum.reject(&is_nil/1)
            |> Enum.join("\n")
          _ -> ""
        end)
      example when is_binary(example) -> [example]
      _ -> []
    end
  end
end
