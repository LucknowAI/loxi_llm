# Changelog

All notable changes to Loki LLM are documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Agent tool: `get_settings` — reports the current RAG chunk size and top-K so the model can explain retrieval behavior to the user ([#12](https://github.com/LucknowAI/loxi_llm/issues/12))
- Multimodal foundation: `Model`/`Message` domain support for a companion mmproj vision projector and attached images; `InferenceBackend` extended with `imagePaths`/`mmprojPath`/`supportsVision`; llama.cpp's `mtmd` vision toolkit wired into the native `llama_engine` plugin. No UI yet — this lands the plumbing `#21`'s chat UI builds on. ([#19](https://github.com/LucknowAI/loxi_llm/issues/19), [#20](https://github.com/LucknowAI/loxi_llm/issues/20))
- Multimodal chat UI: attach an image from the gallery to a chat message via a new composer button, gated to vision-capable models; the image is copied into app storage, previewed before sending, and displayed on the sent message. Attachment cleanup runs on remove, re-pick, an unsent pick left on screen dispose, switching away from a vision model, and conversation deletion. Generation is still text-only — the image isn't fed to the model yet. ([#21](https://github.com/LucknowAI/loxi_llm/issues/21))
- Models screen: a full-screen overlay (animation + the loading model's name) now shows while a model loads, and the rest of the screen (other rows, Settings, Sideload) is locked out until it finishes or fails ([#61](https://github.com/LucknowAI/loxi_llm/issues/61))

### Fixed

- Agent Stop now halts a tool-enabled turn after the in-flight generation, prevents further tool/model calls, preserves partial final answers, and records stopped model I/O traces ([#6](https://github.com/LucknowAI/loxi_llm/issues/6))
- Android: sideloading a `.gguf` model no longer throws `PlatformException` from `file_picker` — `.gguf` has no registered Android MIME type, so we now use `FileType.any` and validate the extension ourselves ([#7](https://github.com/LucknowAI/loxi_llm/issues/7))
- Sideload no longer accepts `.task` files — no backend can load MediaPipe bundles since `MediaPipeBackend` was removed, so accepting them only led to a confusing load failure later ([#40](https://github.com/LucknowAI/loxi_llm/issues/40))
- Android: fixed a native crash (`SIGABRT`, "Unexpected empty grammar stack") that could abort the app right after an agent tool call completed — the sampler chain applied the tool-call grammar after top_k/top_p pruning, which could discard the model's only grammar-valid continuation before grammar saw it. The grammar is now applied separately, sampling normally first and only re-sampling grammar-first when needed, matching llama.cpp's own reference sampler ([#43](https://github.com/LucknowAI/loxi_llm/issues/43))
- Android: Gemma 4 GGUF models failed to load (`unknown model architecture: 'gemma4'`) because the vendored `llama.cpp` submodule predated Gemma 4 support. Bumped the submodule to upstream build b10775 (`67a17c17`), which adds the architecture ([#52](https://github.com/LucknowAI/loxi_llm/issues/52))
- Models screen: a model's `loading` status was silently reset back to `downloaded` on every provider rebuild — including the one triggered immediately by starting a load — so no loading feedback was ever actually visible. The stale-state recovery this ran as part of (meant to catch a model left `loading`/`loaded` after a killed app session) now runs only once per app session. Also added a guard preventing a second model load from starting while one is already in flight ([#61](https://github.com/LucknowAI/loxi_llm/issues/61))
- Chat composer: the text field (and, separately, the image attachment) could fail to clear after sending a message whose generation later failed for a reason unrelated to the send itself (e.g. a vision message where fetching the native image marker failed) — the message had already gone through, but the composer behaved as if it hadn't. Both now clear immediately on send and are only restored if the message genuinely never reached the model. A related, more severe bug meant any generation failure permanently wedged the conversation — every later `send()` rethrew the stale error before reaching generation, so no message after the first failure ever got a response. `send()` now recovers its message list from the repository when needed instead of crashing on stale state ([#59](https://github.com/LucknowAI/loxi_llm/issues/59))

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
