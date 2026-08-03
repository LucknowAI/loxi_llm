# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Commands

```bash
fvm flutter pub get
fvm flutter run
fvm flutter run -d <device-id>
fvm flutter analyze
fvm flutter test
fvm flutter test test/<file>_test.dart
dart run build_runner build --delete-conflicting-outputs
fvm flutter build apk
fvm flutter build ios
```

After cloning, initialize submodules:

```bash
git submodule update --init --recursive
```

## Project summary

**Loki LLM** is a Flutter app for on-device LLM inference on Android and iOS. It uses Riverpod for state, ObjectBox for persistence (including HNSW vector search), and `go_router` for navigation.

## Architecture (`lib/`)

- **`main.dart`** — Initializes ObjectBox + SharedPreferences, wraps app in `ProviderScope` with overrides.
- **`core/engine/`** — `InferenceBackend` abstraction; `LlamaCppBackend` (`.gguf`) and `MediaPipeBackend` (`.task`); `backendForModel()` selector.
- **`core/providers/`** — `inferenceNotifierProvider`, `embeddingServiceProvider`, `downloadServiceProvider`, `objectBoxStoreProvider`, `sharedPreferencesProvider`.
- **`core/router/app_router.dart`** — GoRouter: onboarding, settings, tab shell (Models / Chat / Documents).
- **`features/models/`** — `kCuratedModels` catalog, `ModelRepository`, `DownloadService`, `ModelsNotifier`, `ModelsScreen`.
- **`features/chat/`** — Conversations, messages, `ChatNotifier` (streaming + optional RAG), chat UI.
- **`features/documents/`** — PDF/DOCX/TXT ingestion, chunking, embeddings, HNSW retrieval.
- **`features/settings/`** — `chunkSize` and `topK` via SharedPreferences.
- **`features/onboarding/`** — First-run `PageView`; sets `onboarding_complete` flag.

## Key conventions

- Domain models use **freezed** + **json_serializable**; run `build_runner` after changing annotated classes.
- Riverpod notifiers use **riverpod_annotation** / code generation (`.g.dart` files).
- ObjectBox entities live in `data/*_entity.dart`; repositories map entity ↔ domain.
- Only one model loaded at a time via `InferenceNotifier`.
- RAG is per-conversation (`Conversation.ragEnabled`); retrieval failures fall back to vanilla generation.

## Testing

Tests live in `test/`. Native plugins (ObjectBox, llama, gemma, ONNX) are mocked or use in-memory configs where needed. See `docs/PROJECT.md` §12 for coverage map.

## Documentation

- **Architecture deep-dive:** `docs/PROJECT.md`
- **Vendored packages:** `local_packages/README.md`

## Do not commit

- `.claude/` — local AI tooling only (gitignored)
- `.fvm/` — FVM cache (gitignored)
