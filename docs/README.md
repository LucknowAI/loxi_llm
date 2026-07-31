# Loki LLM — Documentation

This folder contains project documentation for **Loki LLM**, a Flutter application that runs large language models entirely on-device.

## Contents

| Document | Purpose |
|---|---|
| [PROJECT.md](PROJECT.md) | Full architectural reference: tech stack, directory layout, data model, chat/RAG flow, routing, provider graph, testing, build & run |
| [agent-harness-architecture.md](agent-harness-architecture.md) | Target design for the tool-using agent loop: Tool interface, registry, loop, GBNF, context management |


## Quick links

- **Start here:** [PROJECT.md §1 — Overview](PROJECT.md#1-overview)
- **Architecture diagram:** [PROJECT.md §2](PROJECT.md#2-architecture-overview)
- **Build & run commands:** [PROJECT.md §13](PROJECT.md#13-build--run)
- **Agent harness design:** [agent-harness-architecture.md](agent-harness-architecture.md)

## Project at a glance

- 100% on-device LLM inference (no cloud, works offline)
- GGUF inference via `llama_engine` (llama.cpp)
- On-device RAG: BGE-small-en-v1.5 embeddings + ObjectBox HNSW vector index
- PDF / DOCX / TXT ingestion with configurable chunking
- Model hub with curated GGUF catalog + sideload
- Tool-calling agent mode with calculator, datetime, and document search tools

## Repository root

The top-level [README.md](../README.md) covers Flutter bootstrapping; this folder is for deeper architectural and design documentation.
