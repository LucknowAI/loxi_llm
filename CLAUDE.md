# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build
flutter build apk           # Android
flutter build ios           # iOS

# Lint / static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

This is an early-stage Flutter app (`loki_llm`) for managing and chatting with local LLM models on-device.

### Current structure (`lib/`)

- **`main.dart`** — Entry point and `ModelListPage` widget. Displays a list of hardcoded `Model` objects with download/pause/cancel/load actions. Download is currently simulated with a `Timer`.
- **`model/model.dart`** — Plain `Model` class with `name`, `size`, and mutable `status` fields. The git history indicates `model.freezed.dart` and `model.g.dart` are planned, suggesting a migration to `freezed` + `json_serializable` for immutable models with serialization.
- **`util/downloader.dart`** — Placeholder file for actual model download logic (currently empty).
- **`util/storage.dart`** — Planned but not yet implemented; intended for local persistence.
- **`chat.dart`** — Planned chat UI screen; not yet created.

### Intended flow

1. **Model list screen** (`ModelListPage`) — browse available models, initiate downloads
2. **Download management** — `downloader.dart` will handle actual HTTP downloads with pause/resume/cancel
3. **Storage** — `storage.dart` will persist model metadata and download state locally
4. **Chat screen** (`chat.dart`) — load a downloaded model and interact with it

### Planned dependencies (not yet in pubspec.yaml)

The presence of `model.freezed.dart` / `model.g.dart` in the repo suggests upcoming use of:
- `freezed` — immutable data classes
- `json_serializable` / `freezed_annotation` — JSON serialization
- `build_runner` — code generation (`dart run build_runner build`)

When these are added, run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.freezed.dart` and `.g.dart` files.
