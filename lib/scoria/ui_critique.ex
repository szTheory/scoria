defmodule Scoria.UICritique do
  @moduledoc false

  alias ReqLLM.Generation
  alias ReqLLM.Message.ContentPart
  alias ReqLLM.Context
  alias ReqLLM.Response

  @rubric_keys ~w(brand_fit consistency hierarchy affordance a11y responsive motion microcopy density)

  @default_model "anthropic:claude-sonnet-4-5"

  @doc """
  Returns the system instruction for the 9-dimension UI rubric.

  Instructs the model to act as a design-system auditor for the Scoria operator
  dashboard and return a strict JSON object with exactly the 9 rubric keys.
  """
  def system_instruction do
    """
    You are a design-system auditor for the Scoria operator dashboard, a Phoenix LiveView \
    application for AI runtime governance and observability.

    Score the provided screenshot on exactly these 9 dimensions and return ONLY a JSON object \
    with no additional text, explanation, or markdown formatting:

    brand_fit, consistency, hierarchy, affordance, a11y, responsive, motion, microcopy, density

    Each key maps to: {"score": 1-5, "findings": ["specific observation 1", ...]}

    Score semantics:
      1 = critical violation (must fix before release)
      2 = significant gap (high priority)
      3 = acceptable (meets baseline)
      4 = good (above baseline)
      5 = excellent (best practice)

    What each dimension measures:
      brand_fit:    Warm basalt+ember color palette, IBM Plex Sans typography, brand voice \
    ("evidence over intuition"). Scoria brand uses ember (#e65a32) as accent on dark basalt \
    (#11100f) backgrounds with no raw hex or raw palette classes.
      consistency:  Token-only CSS classes used throughout — no raw palette leakage (no \
    stone-*/rose-*/etc.). Shared components used correctly. Design tokens enforced via \
    --scoria-* custom properties.
      hierarchy:    Clear primary/secondary/tertiary visual weight. Page is scannable without \
    reading every word. Data tables and panels have clear scannability.
      affordance:   Interactive elements (buttons, links, inputs) look interactive. Least-surprise \
    behavior — hover/focus states visible, destructive actions clearly distinguished.
      a11y:         Focus-visible on all interactive controls, status not conveyed by color alone, \
    WCAG AA contrast ratios met, keyboard navigation supported.
      responsive:   Usable at 375px mobile and 1280px desktop without horizontal scroll or \
    broken layouts. Critical content accessible on both viewports.
      motion:       Animations use transform/opacity only, ≤200ms duration, no infinite loops, \
    respects prefers-reduced-motion. Transitions feel natural and purposeful.
      microcopy:    Headings, labels, CTAs, empty states, and error messages match the \
    copywriting contract — clear, operator-facing, evidence-first.
      density:      Information per viewport area is appropriate for the task — not too sparse \
    (wastes screen real estate), not too cramped (hard to scan or interact with).

    Return a JSON object ONLY. No markdown code fences. No explanation outside the JSON.
    """
  end

  @doc """
  Critiques a screenshot PNG against the 9-dimension rubric using a Claude vision model.

  Reads the PNG at `png_path`, sends it to the vision model via ReqLLM, and returns a
  validated 9-key findings map.

  Options:
    - `:req_llm_module` — override the ReqLLM generation module (default: ReqLLM.Generation).
      Useful for injecting test stubs.
    - `:model` — override the default model spec (default: #{@default_model}).

  Raises `Mix.Error` with an actionable message if:
    - `ANTHROPIC_API_KEY` is not set
    - The API call fails for any other reason
  """
  def critique_screen(png_path, screen_name, opts \\ []) do
    req_llm_module = Keyword.get(opts, :req_llm_module, Generation)
    model_spec = Keyword.get(opts, :model, @default_model)

    png_binary = File.read!(png_path)
    image_part = ContentPart.image(png_binary, "image/png")
    text_part = ContentPart.text("Score this dashboard screenshot on the 9 rubric dimensions.")

    messages = [
      Context.system(system_instruction()),
      Context.user([text_part, image_part])
    ]

    case req_llm_module.generate_text(model_spec, messages, max_tokens: 2048) do
      {:ok, response} ->
        text = Response.text(response)
        parse_findings_json(text, screen_name)

      {:error, reason} ->
        if is_nil(System.get_env("ANTHROPIC_API_KEY")) do
          Mix.raise("ANTHROPIC_API_KEY is not set. Set it to run the critique pass.")
        else
          Mix.raise("Critique failed for #{screen_name}: #{inspect(reason)}")
        end
    end
  end

  @doc """
  Parses and validates a findings JSON string against the 9-key rubric contract.

  Accepts the raw JSON string from the model response (with optional markdown code
  fences) and `screen_name` for error messages.

  Returns a map with exactly the 9 rubric keys, each containing:
    - `"score"` — integer in the range 1..5
    - `"findings"` — list of strings

  Raises `RuntimeError` if:
    - A required rubric key is missing
    - A score is not an integer
    - A score is outside the 1..5 range
    - The findings value is not a list
  """
  def parse_findings_json(json_string, screen_name) do
    cleaned = strip_code_fences(json_string)
    decoded = Jason.decode!(cleaned)

    Enum.reduce(@rubric_keys, %{}, fn key, acc ->
      case Map.get(decoded, key) do
        nil ->
          raise "UICritique: missing rubric key #{inspect(key)} in findings for screen #{inspect(screen_name)}"

        %{"score" => score, "findings" => findings} when is_integer(score) and is_list(findings) ->
          if score in 1..5 do
            Map.put(acc, key, %{"score" => score, "findings" => findings})
          else
            raise "UICritique: score #{inspect(score)} for key #{inspect(key)} is out of range 1..5 in screen #{inspect(screen_name)}"
          end

        %{"score" => score, "findings" => _findings} when not is_integer(score) ->
          raise "UICritique: score for key #{inspect(key)} must be an integer (1..5), got #{inspect(score)} in screen #{inspect(screen_name)}"

        _other ->
          raise "UICritique: malformed value for key #{inspect(key)} in screen #{inspect(screen_name)} — expected %{\"score\" => integer, \"findings\" => [string]}"
      end
    end)
  end

  # Strips markdown code fences (```json ... ``` or ``` ... ```) from LLM responses
  # that wrap JSON output in code blocks despite being instructed not to.
  defp strip_code_fences(text) do
    text
    |> String.trim()
    |> case do
      "```json\n" <> rest -> rest |> String.trim_trailing("```") |> String.trim()
      "```\n" <> rest -> rest |> String.trim_trailing("```") |> String.trim()
      "```json" <> rest -> rest |> String.trim_trailing("```") |> String.trim()
      "```" <> rest -> rest |> String.trim_trailing("```") |> String.trim()
      other -> other
    end
  end
end
