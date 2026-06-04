defmodule Scoria.UICritiqueTest do
  use ExUnit.Case, async: true

  alias Scoria.UICritique

  @valid_keys ~w(brand_fit consistency hierarchy affordance a11y responsive motion microcopy density)

  # Builds a valid 9-key findings map for use in tests
  defp valid_findings_map do
    Enum.reduce(@valid_keys, %{}, fn key, acc ->
      Map.put(acc, key, %{"score" => 3, "findings" => ["sample finding for #{key}"]})
    end)
  end

  # ── Stub ReqLLM module injected into critique_screen/3 for the happy-path test ──

  defmodule ReqLLMStub do
    @valid_keys ~w(brand_fit consistency hierarchy affordance a11y responsive motion microcopy density)

    def generate_text(_model_spec, _messages, _opts) do
      findings =
        Enum.reduce(@valid_keys, %{}, fn key, acc ->
          Map.put(acc, key, %{"score" => 4, "findings" => ["stub finding for #{key}"]})
        end)

      json = Jason.encode!(findings)

      # Return a minimal stub that ReqLLM.Response.text/1 can extract text from.
      # Response.text/1 calls Enum.filter on message.content (a list of ContentPart structs),
      # so we wrap the JSON in a proper %ContentPart{type: :text, text: json} list.
      text_part = %ReqLLM.Message.ContentPart{type: :text, text: json}

      response = %ReqLLM.Response{
        id: "stub-id",
        model: "stub-model",
        context: nil,
        message: %ReqLLM.Message{role: :assistant, content: [text_part]}
      }

      {:ok, response}
    end
  end

  # ── parse_findings_json/2 ─────────────────────────────────────────────────────

  describe "parse_findings_json/2" do
    test "returns map with all 9 rubric keys, integer scores, and list findings" do
      json = Jason.encode!(valid_findings_map())

      result = UICritique.parse_findings_json(json, "test_screen")

      assert is_map(result)

      for key <- @valid_keys do
        assert Map.has_key?(result, key), "missing key: #{key}"
        assert is_integer(result[key]["score"]), "score for #{key} is not an integer"
        assert is_list(result[key]["findings"]), "findings for #{key} is not a list"
      end
    end

    test "strips markdown ```json code fence before decoding" do
      json_body = Jason.encode!(valid_findings_map())
      fenced = "```json\n#{json_body}\n```"

      result = UICritique.parse_findings_json(fenced, "fenced_screen")

      assert is_map(result)

      for key <- @valid_keys do
        assert Map.has_key?(result, key), "fenced: missing key #{key}"
      end
    end

    test "strips bare ``` code fence before decoding" do
      json_body = Jason.encode!(valid_findings_map())
      fenced = "```\n#{json_body}\n```"

      result = UICritique.parse_findings_json(fenced, "bare_fenced_screen")

      assert is_map(result)

      for key <- @valid_keys do
        assert Map.has_key?(result, key), "bare fenced: missing key #{key}"
      end
    end

    test "raises with screen name and key when a rubric key is missing" do
      incomplete = Map.delete(valid_findings_map(), "a11y")
      json = Jason.encode!(incomplete)

      assert_raise RuntimeError, ~r/missing rubric key.*a11y.*test_screen/, fn ->
        UICritique.parse_findings_json(json, "test_screen")
      end
    end

    test "raises with screen name and key when score is out of the 1..5 range" do
      bad_score = put_in(valid_findings_map(), ["brand_fit", "score"], 6)
      json = Jason.encode!(bad_score)

      assert_raise RuntimeError, ~r/score.*6.*brand_fit.*out of range/, fn ->
        UICritique.parse_findings_json(json, "test_screen")
      end
    end

    test "raises with screen name and key when score is zero (below range)" do
      bad_score = put_in(valid_findings_map(), ["consistency", "score"], 0)
      json = Jason.encode!(bad_score)

      assert_raise RuntimeError, ~r/score.*0.*consistency.*out of range/, fn ->
        UICritique.parse_findings_json(json, "test_screen")
      end
    end

    test "raises with screen name and key when score is a non-integer number" do
      bad_score = put_in(valid_findings_map(), ["hierarchy", "score"], 3.5)
      json = Jason.encode!(bad_score)

      assert_raise RuntimeError, ~r/score.*hierarchy.*must be an integer/, fn ->
        UICritique.parse_findings_json(json, "test_screen")
      end
    end

    test "accepts integer scores at boundary values (1 and 5)" do
      edge_map =
        Enum.reduce(@valid_keys, valid_findings_map(), fn key, acc ->
          score = if rem(Enum.find_index(@valid_keys, &(&1 == key)), 2) == 0, do: 1, else: 5
          put_in(acc, [key, "score"], score)
        end)

      json = Jason.encode!(edge_map)
      result = UICritique.parse_findings_json(json, "edge_screen")

      assert is_map(result)
      assert map_size(result) == 9
    end

    test "accepts empty findings list (model found no issues in a dimension)" do
      empty_findings =
        Enum.reduce(@valid_keys, valid_findings_map(), fn key, acc ->
          put_in(acc, [key, "findings"], [])
        end)

      json = Jason.encode!(empty_findings)
      result = UICritique.parse_findings_json(json, "empty_findings_screen")

      for key <- @valid_keys do
        assert result[key]["findings"] == []
      end
    end
  end

  # ── critique_screen/3 happy-path via ReqLLMStub ─────────────────────────────

  describe "critique_screen/3 with injected ReqLLMStub" do
    @tag :tmp_dir
    test "returns validated 9-key map when ReqLLMStub returns valid JSON response", %{
      tmp_dir: tmp_dir
    } do
      # Write a minimal stub PNG file so File.read! in critique_screen succeeds
      png_path = Path.join(tmp_dir, "stub_screen.png")
      File.write!(png_path, "fake-png-binary")

      result =
        UICritique.critique_screen(png_path, "stub_screen", req_llm_module: ReqLLMStub)

      assert is_map(result)
      assert map_size(result) == 9

      for key <- @valid_keys do
        assert Map.has_key?(result, key), "critique_screen: missing key #{key}"
        assert is_integer(result[key]["score"])
        assert is_list(result[key]["findings"])
      end
    end
  end
end
