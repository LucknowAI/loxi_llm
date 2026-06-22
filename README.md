# Loki LLM

100% on-device LLM for Android and iOS — private, offline, no cloud required.

Browse and download models, chat with streaming responses, and ground conversations in your own documents (RAG). Prompts, chats, and documents never leave the device.

## Features

- **Model hub** — curated GGUF catalog, Hugging Face downloads, sideload `.gguf` / `.task` files
- **Dual inference backends** — `flutter_llama` (GGUF) and `flutter_gemma` (MediaPipe `.task`)
- **Chat** — streaming token output, conversation persistence
- **RAG** — import PDF, DOCX, TXT; BGE-small embeddings + ObjectBox HNSW retrieval
- **Settings** — configurable chunk size and top-K retrieval
- **Onboarding** — first-run walkthrough

## Requirements

- Flutter **3.41.0** (managed via [FVM](https://fvm.app/))
- Dart SDK `^3.5.3`
- Android / iOS device or emulator with enough RAM for your chosen model

## Setup

```bash
# Flutter via FVM
fvm install
fvm use

# Dependencies
fvm flutter pub get

# Native submodule (llama.cpp for vendored flutter_llama)
git submodule update --init --recursive

# Code generation (after model/provider changes)
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
fvm flutter run
fvm flutter run -d <device-id>
```

## Test & analyze

```bash
fvm flutter analyze
fvm flutter test
fvm flutter test test/chat_test.dart   # single file
```

## Build

```bash
fvm flutter build apk   # Android
fvm flutter build ios   # iOS
```

## Architecture

Feature-based layout under `lib/`:

| Area | Path | Purpose |
|------|------|---------|
| Core | `lib/core/` | Engine, providers, router, services |
| Models | `lib/features/models/` | Catalog, downloads, model loading |
| Chat | `lib/features/chat/` | Conversations, streaming |
| Documents | `lib/features/documents/` | Ingestion + vector chunks |
| Settings | `lib/features/settings/` | Chunk size, top-K |
| Onboarding | `lib/features/onboarding/` | First-run flow |

Full architectural reference: [docs/PROJECT.md](docs/PROJECT.md)

## Curated models

| Model | Size | Format |
|-------|------|--------|
| Gemma 3 270M IT | ~253 MB | GGUF |
| Phi-3 Mini 4K Q4_K_M | ~2.4 GB | GGUF |
| Llama 3.2 3B Q4_K_M | ~2.0 GB | GGUF |

## Notes

- `flutter_llama` is vendored in `local_packages/` with Android build patches — see [local_packages/README.md](local_packages/README.md).
- `.claude/` is local-only (gitignored) and not part of the repository.
