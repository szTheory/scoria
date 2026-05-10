# Scoria x Scrypath Integration Seeds (RAG)

*These are GSD planted seeds for future milestone ideation regarding Retrieval-Augmented Generation (RAG) and Scrypath.*

## 1. RAG using Scrypath
Scrypath provides full-text search across domain models. Scoria can integrate with Scrypath to seamlessly retrieve domain-specific context and inject it into the prompt payload before generation. This provides an out-of-the-box RAG solution for Phoenix applications using Scoria.

## 2. Tracing and Evaluating RAG
When Scrypath is used as a retrieval source, Scoria should trace the retrieval step (e.g., `RETRIEVER` span in OpenInference terms). This allows operators to see exactly which documents were retrieved, evaluate their relevance, and measure retrieval latency in the LiveView trace explorer.