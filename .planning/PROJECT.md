# Project

## Current State

**Name:** Scoria
**Current Milestone:** v1.2 Corpus
**Status:** Shipped
**Last Closeout:** 2026-05-11

Scoria now ships a durable knowledge layer alongside the earlier observability, MCP, operator UX, workflow, and evaluation surfaces. The current baseline includes pgvector-backed retrieval, durable citation anchors, deterministic grounding checks, and trace-first evidence projection inside the existing LiveView dashboard.

## Next Milestone Goals

**Target:** v1.3 Seismograph

The next milestone should harden Scoria into a production-grade control plane with:

- configurable token and cost budgets per tenant or user
- circuit-breaker gating for external effects
- SLO and telemetry integration for the broader `szTheory` ecosystem
- durable audit export for sensitive tool and MCP activity
- automated regression alerts when quality or CI gates dip below baseline

## Milestone History

- v1.0 MVP: Core observability, MCP governance, operator UX, and evaluation flywheel.
- v1.1 Caldera: Durable agent workflows, recovery, and handoffs.
- v1.2 Corpus: RAG primitives, citations, grounding, and evidence projection.
