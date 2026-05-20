defmodule Scoria.Orchestrator do
  @moduledoc """
  Recursive fallback mechanism for LLM requests.
  """

  @doc """
  Generates text with fallback support.
  """
  def generate_text(model, prompt, options \\ []) do
    execute(:generate_text, model, [model, prompt], options)
  end

  @doc """
  Generates a structured object with fallback support.
  """
  def generate_object(model, prompt, schema, options \\ []) do
    execute(:generate_object, model, [model, prompt, schema], options)
  end

  defp execute(type, primary_model, args, options) do
    {req_llm_module, options} = Keyword.pop(options, :req_llm_module, Application.get_env(:scoria, :req_llm_module, ReqLLM))
    
    fallback_chain =
      Application.get_env(:scoria, :fallback_chains, %{})
      |> Map.get(primary_model, [])

    start_time = System.monotonic_time()
    
    metadata = %{
      primary_model: primary_model,
      type: type
    }

    result = attempt_generate(type, [primary_model | fallback_chain], args, options, req_llm_module, primary_model)

    duration = System.monotonic_time() - start_time
    
    case result do
      {:ok, res} ->
        :telemetry.execute([:scoria, :orchestrator, :request, :stop], %{duration: duration}, metadata)
        {:ok, res}

      {:error, reason} ->
        :telemetry.execute(
          [:scoria, :orchestrator, :request, :stop],
          %{duration: duration},
          Map.put(metadata, :reason, reason)
        )
        {:error, reason}
    end
  end

  defp attempt_generate(type, [current_model | rest], args, options, req_llm_module, primary_model) do
    # Replace the model in args (first element)
    call_args = List.replace_at(args, 0, current_model)
    
    # Isolate options: extract existing :req_options and prepend current model's options
    req_options = Keyword.get(options, :req_options, [])
    # Scoria.Req.Steps.req_options(current_model) provides standard headers/auth for the model
    # We want to ensure they don't accumulate, so we take the base options and add the current model's ones.
    
    # Wait, the plan says: "Prepend them with Scoria.Req.Steps.req_options(current_model). Do NOT let options accumulate across retries."
    # If we always start from the original 'options', they won't accumulate.
    
    current_req_options = Scoria.Req.Steps.req_options(current_model) ++ req_options
    current_options = Keyword.put(options, :req_options, current_req_options)
    
    case apply(req_llm_module, type, call_args ++ [current_options]) do
      {:ok, result} ->
        {:ok, result}

      {:error, reason} when rest != [] ->
        next_model = hd(rest)
        
        :telemetry.execute(
          [:scoria, :orchestrator, :fallback],
          %{},
          %{
            reason: reason,
            primary_model: primary_model,
            target_model: next_model
          }
        )
        
        attempt_generate(type, rest, args, options, req_llm_module, primary_model)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
