# Scoria

[![CI](https://github.com/szTheory/scoria/actions/workflows/ci.yml/badge.svg)](https://github.com/szTheory/scoria/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-1.19%2B-4B275F.svg)](https://elixir-lang.org/)
[![Phoenix](https://img.shields.io/badge/Phoenix-1.7%2B-FD4F00.svg)](https://www.phoenixframework.org/)

Scoria is a Phoenix-native AI application quality layer. It gives Elixir teams trace-first observability, durable workflows, knowledge grounding, and an operator dashboard that fits into an existing app instead of fighting it.

If you land here, you probably want one of two things:

- visibility into what your AI app is doing
- a clean way to add approvals, retrieval evidence, and long-running workflow state without building the plumbing yourself

## Install

Add it as a GitHub dependency for now:

```elixir
def deps do
  [
    {:scoria, github: "szTheory/scoria"}
  ]
end
```

Then mount the dashboard in your Phoenix router and run the install task:

```bash
mix scoria.install
```

The dashboard mounts at `/scoria`.

## What you get

- OpenInference-style trace capture and redaction
- durable workflows, handoffs, and recovery
- pgvector-backed knowledge, citations, and grounding checks
- a trace-first LiveView surface for operators

## Status

Scoria is actively evolving. v1.2 ships the knowledge layer, and v1.3 is next.
