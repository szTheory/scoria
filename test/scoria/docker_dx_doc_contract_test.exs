defmodule Scoria.DockerDxDocContractTest do
  use ExUnit.Case, async: true

  @doc_path "docs/docker_dev_dx.md"
  @stale_fixed_port_patterns [
    fixed_localhost_4000: ~r/\b(?:localhost|127\.0\.0\.1):4000(?:\/[^\s)`'"]*)?/i,
    command_context_4000:
      ~r/\b(?:open|visit|browse|browser|go to|curl)\b[^\n]*(?:https?:\/\/)?(?:localhost|127\.0\.0\.1):4000(?:\/[^\s)`'"]*)?/i
  ]
  @browser_or_fallback_context ~r/\b(browser|open|visit|browse|go to|curl|dev-start|start URL|fallback|route)\b/i
  @allowed_4000_qualifiers [
    ~r/docker-internal/i,
    ~r/container/i,
    ~r/traefik/i,
    ~r/service target/i,
    ~r/loadbalancer\.server\.port=4000/i,
    ~r/web:4000/i,
    ~r/127\.0\.0\.1::4000/,
    ~r/docker compose port web 4000/i,
    ~r/\bCI\b/,
    ~r/ephemeral fallback/i,
    ~r/ephemeral loopback/i
  ]

  test "pins Docker and native dev loop reader tokens" do
    docs = docker_dx_docs()

    for fragment <- [
          "make up",
          "make dev",
          "make url",
          "make nuke",
          "ANTHROPIC_API_KEY"
        ] do
      assert_doc_contains!(docs, fragment, "Docker/native dev-DX contract")
    end

    assert_any_doc_fragment!(docs, ["4799", "http://localhost:4799/scoria"], "native URL")
    assert_any_doc_fragment!(docs, ["direnv", "1Password"], "process-scoped secrets setup")
  end

  test "pins latest local UI source of truth and stale-route cleanup" do
    docs = docker_dx_docs()

    for fragment <- [
          "source of truth for the latest local Scoria UI",
          "route printed by `make url`",
          "not aliases for \"latest\"",
          "make down INSTANCE=<project>"
        ] do
      assert_doc_contains!(docs, fragment, "latest-local-UI stale-route contract")
    end
  end

  test "pins cache-table reader strings" do
    docs = docker_dx_docs()

    for fragment <- [
          "mix deps.get",
          "mix deps.compile",
          "app compile only"
        ] do
      assert_doc_contains!(docs, fragment, "Docker cache-table contract")
    end
  end

  test "rejects stale fixed-port browser start guidance" do
    docs = docker_dx_docs()

    assert stale_fixed_port_hits(docs) == [],
           stale_fixed_port_failure(stale_fixed_port_hits(docs))

    assert unqualified_4000_contexts(docs) == [],
           unqualified_4000_failure(unqualified_4000_contexts(docs))
  end

  test "stale URL classifier rejects fixed localhost browser guidance examples" do
    for stale_doc <- [
          "Open http://localhost:4000/scoria in the browser.",
          "visit localhost:4000",
          "curl http://127.0.0.1:4000/scoria",
          "If you need a browser route, use port 4000.",
          "If you need a browser route,\nuse port 4000.",
          "Open the internal browser route on port 4000."
        ] do
      assert stale_fixed_port_hits(stale_doc) != [] or unqualified_4000_contexts(stale_doc) != [],
             "expected stale browser-start guidance to be rejected: #{inspect(stale_doc)}"
    end
  end

  test "qualified Docker-internal 4000 mechanics remain allowed" do
    for allowed_doc <- [
          "Docker-internal container port `4000` is the Traefik service target.",
          "`docker compose port web 4000` prints the ephemeral fallback.",
          ~s(- "127.0.0.1::4000"        # ephemeral fallback; never a fixed port),
          "traefik.http.services.app.loadbalancer.server.port=4000",
          "SHOTS_BASE_URL=http://web:4000/scoria"
        ] do
      assert stale_fixed_port_hits(allowed_doc) == []
      assert unqualified_4000_contexts(allowed_doc) == []
    end
  end

  test "allows the fixed-port anti-footgun copy" do
    anti_footgun =
      "predictable Scoria dashboard route, no `:4000` or `:5432` juggling, scoped cleanup"

    assert stale_fixed_port_hits(anti_footgun) == []
    assert unqualified_4000_contexts(anti_footgun) == []
  end

  defp docker_dx_docs do
    File.read!(@doc_path)
  end

  defp assert_doc_contains!(docs, fragment, contract) do
    assert String.contains?(docs, fragment),
           """
           DOCS-03 lost the #{contract} fragment #{inspect(fragment)} in #{@doc_path}.
           Restore the Docker/native dev-DX contract, or update this guard with Phase 34 rationale.
           """
  end

  defp assert_any_doc_fragment!(docs, fragments, contract) do
    assert Enum.any?(fragments, &String.contains?(docs, &1)),
           """
           DOCS-03 lost the #{contract} fragment set #{inspect(fragments)} in #{@doc_path}.
           Restore the Docker/native dev-DX contract, or update this guard with Phase 34 rationale.
           """
  end

  defp stale_fixed_port_hits(docs) do
    Enum.flat_map(@stale_fixed_port_patterns, fn {name, pattern} ->
      pattern
      |> Regex.scan(docs)
      |> Enum.map(fn match -> {name, List.first(match)} end)
    end)
  end

  defp unqualified_4000_contexts(docs) do
    docs
    |> paragraph_contexts()
    |> Enum.filter(fn {paragraph, _line_number} ->
      String.contains?(paragraph, "4000") and
        Regex.match?(@browser_or_fallback_context, paragraph) and
        not anti_footgun_context?(paragraph) and not allowed_4000_context?(paragraph)
    end)
  end

  defp paragraph_contexts(docs) do
    docs
    |> String.split(~r/\n\s*\n/)
    |> Enum.map_reduce(1, fn paragraph, line_number ->
      next_line_number = line_number + length(String.split(paragraph, "\n")) + 1
      normalized = String.replace(paragraph, ~r/\s+/, " ")

      {{normalized, line_number}, next_line_number}
    end)
    |> elem(0)
  end

  defp anti_footgun_context?(context) do
    Regex.match?(~r/no\s+`:4000`.*juggling/i, context)
  end

  defp allowed_4000_context?(context) do
    Enum.any?(@allowed_4000_qualifiers, &Regex.match?(&1, context))
  end

  defp stale_fixed_port_failure(hits) do
    """
    DOCS-03 found stale fixed-port browser-start guidance in #{@doc_path}: #{inspect(hits)}.
    Use Docker `make up` / `make url` / `http://<instance>.localhost/scoria`,
    or native `make dev` / `http://localhost:4799/scoria`.
    """
  end

  defp unqualified_4000_failure(contexts) do
    """
    DOCS-03 found unqualified `4000` browser/fallback context in #{@doc_path}: #{inspect(contexts)}.
    Qualify Docker-internal mechanics, or point readers to Docker `make up` / `make url`
    / `http://<instance>.localhost/scoria` or native `make dev` / `http://localhost:4799/scoria`.
    """
  end
end
