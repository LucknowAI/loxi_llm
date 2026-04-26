# Loki LLM — Documentation

This folder contains project documentation for **Loki LLM**, a Flutter application that runs large language models entirely on-device.

## Contents

| Document | Purpose |
|---|---|
| [PROJECT.md](PROJECT.md) | Full architectural reference: tech stack, directory layout, implementation phases, data model, chat/RAG flow, routing, provider graph, testing, build & run |

## Quick links

- **Start here:** [PROJECT.md §1 — Overview](PROJECT.md#1-overview)
- **Architecture diagram:** [PROJECT.md §2](PROJECT.md#2-architecture-overview)
- **Build & run commands:** [PROJECT.md §14](PROJECT.md#14-build--run)
- **Per-phase changelog:** [PROJECT.md §5 — Implementation Phases](PROJECT.md#5-implementation-phases)

## Project at a glance

- 100% on-device LLM inference (no cloud, works offline)
- Dual inference backends: `flutter_llama` (GGUF) and `flutter_gemma` (MediaPipe `.task`)
- On-device RAG: BGE-small-en-v1.5 embeddings + ObjectBox HNSW vector index
- PDF / DOCX / TXT ingestion with configurable chunking
- Model hub with curated catalog + sideload for arbitrary `.gguf` / `.task` files

## Repository root

The top-level [README.md](../README.md) covers Flutter bootstrapping; this folder is for deeper architectural and design documentation.
