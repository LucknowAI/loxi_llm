# Loki LLM

**100% on-device AI chat for Android — private, offline, no cloud.**

Download open LLMs and run them entirely on your phone: streaming chat, document
Q&A over your own files (RAG), and a tool-calling agent — all local. Your
prompts, conversations, and documents never leave the device.

![Flutter](https://img.shields.io/badge/Flutter-3.41.0-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android)
![License](https://img.shields.io/badge/license-MIT-green)
![CI](https://github.com/LucknowAI/loxi_llm/actions/workflows/ci.yml/badge.svg)

> **Status:** actively developed. Currently **Android only** (no iOS project yet).

## Features

- **On-device & private** — inference runs locally via `llama.cpp`; no telemetry,
  no accounts, no cloud. Works offline once a model is downloaded.
- **Model hub** — curated GGUF catalog with Hugging Face downloads (with live
  download speed) and sideloading of your own `.gguf` files.
- **Streaming chat** — true token-by-token output with a **Stop** button, and
  per-model prompt templates (Gemma / Phi / Llama) so each model is prompted the
  way it was trained.
- **Document Q&A (RAG)** — import PDF / DOCX / TXT; BGE-small embeddings +
  ObjectBox HNSW retrieval, toggleable per conversation.
- **Tool-calling agent** — an optional per-conversation mode where the model can
  call tools (calculator, date/time, document search) in a bounded loop.
- **Rolling memory** — long conversations are summarized beyond the recent window
  so the model keeps earlier context.
- **Diagnostics** — in-app logs and an optional (off-by-default) Model I/O trace
  log for debugging.

## Screenshots

_Coming soon._ <!-- Add screenshots under docs/screenshots/ and reference here. -->

## Curated models

| Model | Size | Source (GGUF) | License |
|-------|------|---------------|---------|
| Gemma 3 270M IT | ~253 MB | `unsloth/gemma-3-270m-it-GGUF` | [Gemma Terms](https://ai.google.dev/gemma/terms) |
| Phi-3 Mini 4K | ~2.4 GB | `bartowski/Phi-3-mini-4k-instruct-GGUF` | MIT |
| Llama 3.2 3B | ~2.0 GB | `bartowski/Llama-3.2-3B-Instruct-GGUF` | [Llama 3.2 Community License](https://github.com/meta-llama/llama-models/blob/main/models/llama3_2/LICENSE) |

Each model is downloaded from Hugging Face on demand and is governed by its own
license/usage terms, linked above.

## Requirements

- [Flutter **3.41.0**](https://flutter.dev) (managed via [FVM](https://fvm.app/))
- An Android device/emulator with enough RAM for your chosen model (a 3B model
  needs a few GB free)

## Getting started

```bash
# Pin the Flutter version with FVM
fvm install && fvm use

# Fetch Dart dependencies
fvm flutter pub get

# Initialize the native submodule (llama.cpp, used by the GGUF backend)
git submodule update --init --recursive

# Code generation (Riverpod / freezed / ObjectBox) — after changing annotated files
fvm dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
fvm flutter run
```

> Always drive the toolchain through **`fvm`** (`fvm flutter`, `fvm dart`) so you
> use the pinned SDK — a bare `dart`/`flutter` may resolve to a different install.

## Develop

```bash
fvm flutter analyze
fvm flutter test                 # full suite (pure-Dart; no device needed)
fvm flutter test test/eval_test.dart
fvm flutter build apk --debug
```

CI runs `analyze` + `test` on every push/PR — see
[`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Architecture

Feature-first layout under `lib/`:

| Area | Path | Purpose |
|------|------|---------|
| Core engine | `lib/core/engine/` | `InferenceBackend`, chat templates, backend selection |
| Providers | `lib/core/providers/` | Riverpod providers (inference, download, embeddings, ObjectBox) |
| Logging | `lib/core/logging/` | App logs + optional Model I/O trace |
| Models | `lib/features/models/` | Catalog, downloads, load/unload |
| Chat | `lib/features/chat/` | Conversations, streaming, prompt building, memory |
| Agent | `lib/features/agent/` | Tools, registry, bounded agent loop |
| Documents | `lib/features/documents/` | Ingestion, chunking, embeddings, retrieval |

- Deep dive: [docs/PROJECT.md](docs/PROJECT.md)
- Agent design: [docs/agent-harness-architecture.md](docs/agent-harness-architecture.md)

## Privacy

All user data (chats, documents, embeddings, settings, logs) stays on-device.
The only network access is downloading the model files you choose from Hugging
Face. Full details in [PRIVACY.md](PRIVACY.md).

## Tech stack

Flutter · Riverpod · ObjectBox (incl. HNSW vector search) · `go_router` ·
`llama.cpp` (GGUF inference) · ONNX Runtime (BGE-small embeddings).

## Acknowledgements

- [**llama.cpp**](https://github.com/ggml-org/llama.cpp) (MIT) — on-device GGUF inference.
- [**ONNX Runtime**](https://onnxruntime.ai/) — embedding model runtime.
- Model authors: Google (Gemma), Microsoft (Phi-3), Meta (Llama 3.2), and the
  `unsloth` / `bartowski` GGUF quantizations.

Third-party package licenses are listed in-app under **Settings → Open-source
licenses**.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a PR (target branch: **`develop`**). See also
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Loki LLM authors. Bundled/downloaded components (llama.cpp,
the models above, and Dart packages) are governed by their own licenses.
