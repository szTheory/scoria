defmodule Scoria.GlossaryContractTest do
  use ExUnit.Case, async: true

  @glossary "docs/glossary.md"

  @required_headings [
    "# Glossary",
    "## Core terms",
    "## Legacy and industry equivalents",
    "## Compatibility aliases"
  ]

  @required_terms [
    "run",
    "reviewer",
    "trace",
    "evidence",
    "capability",
    "verification suite",
    "scoped context",
    "semantic cache",
    "knowledge base",
    "grounding",
    "bounded handoff"
  ]

  @legacy_mappings [
    {"operator", "reviewer"},
    {"projected context", "scoped context"},
    {"semantic fast path", "semantic cache"},
    {"optional knowledge", "optional knowledge base"},
    {"adoption/capability lane", "capability"},
    {"proof/verification lane", "verification suite"},
    {"surface-sense evidence", "trace"},
    {"RAG/citation evidence", "unchanged evidence"}
  ]

  @compatibility_aliases [
    "ScoriaWeb.OperatorSurface",
    "Scoria.Observe.OperatorBroadcast",
    "Scoria.VerificationLanes",
    "Scoria.SemanticLane",
    "lane:",
    "lane_key",
    "projected_context:"
  ]

  test "glossary exists with the required D-03 headings" do
    content = File.read!(@glossary)

    for heading <- @required_headings do
      assert content =~ heading
    end
  end

  test "glossary defines every required final term" do
    content = File.read!(@glossary)
    downcased = String.downcase(content)

    for term <- @required_terms do
      assert downcased =~ String.downcase(term),
             "expected glossary to define #{inspect(term)}"
    end
  end

  test "glossary maps legacy vocabulary to final vocabulary" do
    content = File.read!(@glossary)

    for {legacy, final} <- @legacy_mappings do
      assert content =~ legacy, "expected glossary to mention legacy term #{inspect(legacy)}"
      assert content =~ final, "expected glossary to map to #{inspect(final)}"
    end
  end

  test "glossary documents compatibility aliases for the 0.1.x line" do
    content = File.read!(@glossary)

    assert content =~ "0.1.x"

    for alias_name <- @compatibility_aliases do
      assert content =~ alias_name
    end
  end

  test "glossary preserves the evidence and trace boundary" do
    content = File.read!(@glossary)

    assert content =~ "RAG/citation evidence"
    assert content =~ "evidence_refs"
    assert content =~ "surface-sense evidence"
    assert content =~ "trace"
    refute content =~ "trace_refs"
  end
end
