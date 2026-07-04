defmodule ScoriaWeb.DesignSystemDocContractTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Anti-drift contract for `docs/design_system.md` — D-12, modeled 1:1 on
  `Scoria.DockerDxDocContractTest`.

  `docs/design_system.md` is the maintainer conventions doc: 11 sections, each
  naming a real, existing drift guard that enforces the documented convention
  (the "matched pair" tying PROOF-02 to PROOF-03, per Phase 41 D-10/D-12). This
  contract keeps that pairing honest with three minimal checks, no heavier:

    1. Every guard test path the doc names (`test/..._test.exs`) still exists
       on disk — rename or delete a guard file and this test goes red.
    2. A small sample of the token names the doc cites still appear in
       `assets/css/02-tokens.css` — repoint/remove a cited token and this test
       goes red.
    3. The 11 section headings are pinned present via `String.contains?` — drop
       a section and this test goes red.

  This is `File.read!` only, no DB, `async: true` — mirrors
  `test/scoria/docker_dx_doc_contract_test.exs` exactly.
  """

  @doc_path "docs/design_system.md"
  @tokens_css_path "assets/css/02-tokens.css"

  @required_section_headings [
    "## BEM & CSS selectors",
    "## Tokens",
    "## Page headers",
    "## Stats",
    "## Overlays",
    "## Evidence & code",
    "## Copy controls",
    "## Fixtures",
    "## Motion",
    "## Accessibility",
    "## Screenshot-proof + drift-guard roster"
  ]

  @cited_token_sample [
    "--scoria-text-subtle",
    "--scoria-surface-app",
    "--scoria-text"
  ]

  test "every guard path design_system.md names still exists on disk" do
    docs = design_system_docs()
    guard_paths = guard_paths(docs)

    assert guard_paths != [],
           "design_system.md named zero guard paths — the matched-pair contract has nothing to check."

    for path <- guard_paths do
      assert File.exists?(path), """
      docs/design_system.md names guard #{inspect(path)} that no longer exists.
      Update the doc + this contract together (D-12).
      """
    end
  end

  test "a sample of tokens design_system.md cites still appear in 02-tokens.css" do
    tokens_css = File.read!(@tokens_css_path)

    for token <- @cited_token_sample do
      assert String.contains?(tokens_css, token), """
      docs/design_system.md cites token #{inspect(token)} which no longer appears in
      #{@tokens_css_path}. Update the doc + this contract together (D-12).
      """
    end
  end

  test "pins the 11 required section headings" do
    docs = design_system_docs()

    for heading <- @required_section_headings do
      assert String.contains?(docs, heading), """
      docs/design_system.md lost required section heading #{inspect(heading)}.
      Update the doc + this contract together (D-12).
      """
    end
  end

  defp design_system_docs do
    File.read!(@doc_path)
  end

  defp guard_paths(docs) do
    ~r/(test\/[^\s`]+_test\.exs)/
    |> Regex.scan(docs)
    |> Enum.map(&List.last/1)
    |> Enum.uniq()
  end
end
