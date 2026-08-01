# Changelog

All notable changes to Loki LLM are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] — 2026-08-01

First stable on-device release.

### Added

- On-device chat with true incremental streaming and Stop button (Android)
- Per-model chat templates (Gemma, Phi, Llama)
- Model hub: curated GGUF catalog, Hugging Face downloads, sideload
- RAG: PDF / DOCX / TXT ingest, BGE-small embeddings, ObjectBox HNSW
- Tool-calling agent mode with `calculator`, `datetime`, `document_search`
- Rolling conversation memory (summary beyond recent window)
- Model I/O trace diagnostics (optional JSONL log)
- In-app log viewer
- `llama_engine` plugin (MIT, vendored llama.cpp)

### Fixed

- Flutter analyze: const constructors in `ChatState` domain tests
