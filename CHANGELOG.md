# Changelog

All notable changes to Loki LLM are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Android: sideloading a `.gguf` model no longer throws `PlatformException` from `file_picker` — `.gguf` has no registered Android MIME type, so we now use `FileType.any` and validate the extension ourselves ([#7](https://github.com/LucknowAI/loxi_llm/issues/7))
- Sideload no longer accepts `.task` files — no backend can load MediaPipe bundles since `MediaPipeBackend` was removed, so accepting them only led to a confusing load failure later ([#40](https://github.com/LucknowAI/loxi_llm/issues/40))

## [1.1.0] — 2026-08-03

### Added

- Agent tools: `recall_memory`, `list_documents`, `unit_convert`
- Lazy GBNF grammar for more reliable tool-call JSON
- Per-tool enable toggles in Settings
- Unified RAG + agent mode in chat
- Per-iteration fields in Model I/O trace (agent steps, tool results)
- Agent mode gating for Gemma 270M (plain chat only)
- Export or share conversations as Markdown
- Per-message copy on chat bubbles
- Read-aloud on assistant messages (Android) via `TtsService` and `flutter_tts`
- `SpeechTextNormalizer` so Markdown formatting is not spoken literally
- Model load feedback: SnackBar on success, active row highlight, chat banners
- Open-source community docs: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue/PR templates

### Fixed

- Agent-mode native crash during multi-step generation (JNI UTF-8, generation chain lock)
- Model load SnackBar showing the previous model name when switching models
- Switching models without unload now unloads the prior backend and clears its loaded status

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
