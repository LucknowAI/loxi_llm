# Loki LLM

> **100% on-device LLM for Android & iOS** — private, offline, no cloud required.

**Version:** 1.0.0+1 | **Branch:** feature/phase-7-polish-ux | **SDK:** Dart ^3.5.3 / Flutter

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Tech Stack](#3-tech-stack)
4. [Directory Structure](#4-directory-structure)
5. [Data Model](#5-data-model)
6. [Model Lifecycle](#6-model-lifecycle)
7. [Inference Backend Selection](#7-inference-backend-selection)
8. [Chat & RAG Message Flow](#8-chat--rag-message-flow)
9. [Document Ingestion Pipeline](#9-document-ingestion-pipeline)
10. [Navigation & Routing](#10-navigation--routing)
11. [Provider Dependency Graph](#11-provider-dependency-graph)
12. [Testing](#12-testing)
13. [Build & Run](#13-build--run)

---

## 1. Overview

Loki LLM is a Flutter application that runs large language models entirely on-device — no internet connection required after the initial model download. It was built on the principle that AI assistants should respect user privacy: prompts, conversations, and documents never leave the device.

**Key capabilities:**

- Browse and download curated LLM models from Hugging Face (or sideload your own `.gguf` / `.task` files)
- Chat with any downloaded model with real-time token streaming
- Import PDF, DOCX, and TXT documents and ground conversations in their content (RAG)
- Configurable chunking and retrieval settings
- RAM-aware model loading with confirmation guard

---

## 2. Architecture Overview

```mermaid
graph TD
    MAIN["main.dart\n(ProviderScope overrides)"]
    APP["MyApp\n(ConsumerWidget)"]
    ROUTER["appRouterProvider\n(GoRouter)"]
    ONBOARD["OnboardingScreen"]
    SETTINGS["SettingsScreen"]
    SHELL["StatefulShellRoute\n(BottomNavigationBar)"]
    MODELS["ModelsScreen"]
    CHAT["ChatScreen / ConversationScreen"]
    DOCS["DocumentsScreen"]

    MODELS_N["ModelsNotifier"]
    CHAT_N["ChatNotifier"]
    DOCS_N["DocumentsNotifier"]
    INF_N["InferenceNotifier"]
    EMB_S["EmbeddingService"]
    DL_S["DownloadService"]
    FS_S["FileStorageService"]

    OBX["ObjectBox Store"]
    MODEL_REPO["ModelRepository"]
    CONV_REPO["ConversationRepository"]
    MSG_REPO["MessageRepository"]
    DOC_REPO["DocumentRepository"]
    CHUNK_REPO["DocumentChunkRepository\n(HNSW index)"]

    LLAMA["LlamaCppBackend\n(flutter_llama)"]
    MEDI["MediaPipeBackend\n(flutter_gemma)"]
    ONNX["ONNX Runtime\n(BGE-small-en-v1.5)"]

    MAIN --> APP
    APP --> ROUTER
    ROUTER --> ONBOARD
    ROUTER --> SETTINGS
    ROUTER --> SHELL
    SHELL --> MODELS
    SHELL --> CHAT
    SHELL --> DOCS

    MODELS --> MODELS_N
    CHAT --> CHAT_N
    DOCS --> DOCS_N

    MODELS_N --> INF_N
    MODELS_N --> DL_S
    MODELS_N --> MODEL_REPO
    CHAT_N --> INF_N
    CHAT_N --> EMB_S
    CHAT_N --> CHUNK_REPO
    DOCS_N --> EMB_S
    DOCS_N --> DOC_REPO
    DOCS_N --> CHUNK_REPO

    INF_N --> LLAMA
    INF_N --> MEDI
    EMB_S --> ONNX
    DL_S --> FS_S

    MODEL_REPO --> OBX
    CONV_REPO --> OBX
    MSG_REPO --> OBX
    DOC_REPO --> OBX
    CHUNK_REPO --> OBX
```

---

## 3. Tech Stack

| Category | Library | Version | Purpose |
|---|---|---|---|
| **UI Framework** | flutter | SDK | Cross-platform UI |
| **State Management** | flutter_riverpod | ^2.5.1 | Reactive providers, notifiers |
| **State Management** | riverpod_annotation | ^2.3.5 | Code-gen annotations |
| **Immutable Models** | freezed_annotation | ^2.4.4 | Immutable data classes with copyWith |
| **JSON** | json_annotation | ^4.9.0 | JSON serialization |
| **Database** | objectbox | ^4.0.2 | On-device NoSQL + HNSW vector index |
| **Database** | objectbox_flutter_libs | ^4.0.2 | ObjectBox native libs for Flutter |
| **Navigation** | go_router | ^14.3.0 | Declarative routing, deep links |
| **Persistence** | shared_preferences | ^2.3.2 | Settings and onboarding flag |
| **LLM Backend** | flutter_gemma | ^0.11.8 | MediaPipe inference for `.task` files |
| **LLM Backend** | flutter_llama | ^1.1.2 | llama.cpp inference for `.gguf` files |
| **Networking** | dio | ^5.9.2 | Model downloads with progress |
| **File Picker** | file_picker | ^10.3.10 | Sideload models & ingest documents |
| **Storage Paths** | path_provider | ^2.1.5 | App documents directory |
| **RAM Check** | system_info_plus | ^0.0.6 | Query available physical memory |
| **Embeddings** | onnxruntime | ^1.4.1 | Run BGE-small-en-v1.5 ONNX model |
| **Tokenizer** | dart_wordpiece | ^1.1.0 | WordPiece tokenization for BERT models |
| **Doc Parsing** | flutter_pdf_text | ^0.9.0 | Extract text from PDF files |
| **Doc Parsing** | docx_to_text | ^1.0.1 | Extract text from DOCX files |
| **Text Splitting** | langchain | ^0.7.7+2 | `RecursiveCharacterTextSplitter` |
| **Code Generation** | build_runner | ^2.4.9 | Drives freezed / riverpod_generator |
| **Code Generation** | riverpod_generator | ^2.4.3 | Generate provider boilerplate |
| **Code Generation** | freezed | ^2.5.7 | Generate immutable class boilerplate |
| **Code Generation** | json_serializable | ^6.8.0 | Generate `fromJson` / `toJson` |
| **Code Generation** | objectbox_generator | ^4.0.2 | Generate ObjectBox entity bindings |

---

## 4. Directory Structure

```
lib/
├── main.dart                          # App entry point — ProviderScope, store init
├── objectbox.g.dart                   # Generated ObjectBox store code
│
├── core/
│   ├── database/
│   │   └── objectbox_store.dart       # Opens ObjectBox store (async)
│   ├── engine/
│   │   ├── inference_backend.dart     # Abstract base class for LLM backends
│   │   ├── backend_selector.dart      # backendForModel() — format → backend
│   │   ├── llama_cpp_backend.dart     # flutter_llama wrapper (.gguf)
│   │   └── mediapipe_backend.dart     # flutter_gemma wrapper (.task)
│   ├── providers/
│   │   ├── objectbox_provider.dart    # objectBoxStoreProvider
│   │   ├── shared_preferences_provider.dart
│   │   ├── inference_provider.dart    # InferenceNotifier (load/unload)
│   │   ├── embedding_provider.dart    # embeddingServiceProvider
│   │   └── download_provider.dart     # dioProvider, fileStorageServiceProvider
│   ├── router/
│   │   └── app_router.dart            # appRouterProvider, _ScaffoldWithNavBar
│   └── services/
│       ├── download_service.dart      # Dio-based model download with progress
│       ├── embedding_service.dart     # EmbeddingService (ONNX BGE-small)
│       ├── file_storage_service.dart  # Model file path management
│       ├── ram_check_service.dart     # confirmLoad() dialog
│       └── text_extraction_service.dart  # PDF/DOCX/TXT → plain text
│
├── features/
│   ├── models/
│   │   ├── domain/
│   │   │   ├── model.dart             # Model freezed class + recommendationBadge
│   │   │   └── model_status.dart      # ModelStatus enum
│   │   ├── data/
│   │   │   ├── model_catalog.dart     # kCuratedModels list + huggingFaceDownloadUrl
│   │   │   ├── model_entity.dart      # ObjectBox entity for Model
│   │   │   └── model_repository.dart  # CRUD + seed from kCuratedModels
│   │   └── presentation/
│   │       ├── models_notifier.dart   # ModelsNotifier (download/load/sideload)
│   │       └── models_screen.dart     # ModelsScreen UI
│   │
│   ├── chat/
│   │   ├── domain/
│   │   │   ├── message.dart           # Message freezed class
│   │   │   ├── message_role.dart      # MessageRole enum (user/assistant)
│   │   │   └── conversation.dart      # Conversation freezed class
│   │   ├── data/
│   │   │   ├── message_entity.dart    # ObjectBox entity for Message
│   │   │   ├── message_repository.dart
│   │   │   ├── conversation_entity.dart
│   │   │   └── conversation_repository.dart
│   │   └── presentation/
│   │       ├── chat_notifier.dart     # ChatNotifier (send, stream, RAG)
│   │       ├── conversation_list_notifier.dart
│   │       ├── chat_screen.dart       # Conversation list
│   │       └── conversation_screen.dart  # Message thread + input
│   │
│   ├── documents/
│   │   ├── domain/
│   │   │   ├── document.dart          # Document freezed class
│   │   │   └── document_chunk.dart    # DocumentChunk freezed class
│   │   ├── data/
│   │   │   ├── document_entity.dart
│   │   │   ├── document_repository.dart
│   │   │   ├── document_chunk_entity.dart  # @HnswIndex annotation
│   │   │   └── document_chunk_repository.dart  # findSimilar() HNSW search
│   │   └── presentation/
│   │       ├── documents_notifier.dart    # DocumentsNotifier (ingest pipeline)
│   │       └── documents_screen.dart
│   │
│   ├── settings/
│   │   ├── domain/
│   │   │   └── app_settings.dart      # AppSettings (chunkSize, topK)
│   │   └── presentation/
│   │       ├── settings_notifier.dart # SettingsNotifier (SharedPreferences-backed)
│   │       └── settings_screen.dart   # Sliders for chunkSize / topK
│   │
│   └── onboarding/
│       └── presentation/
│           └── onboarding_screen.dart # 3-page PageView + onboarding_complete flag

test/
├── widget_test.dart       # App smoke test
├── engine_test.dart       # InferenceBackend abstractions
├── domain_test.dart       # Freezed model constructors / computed properties
├── chat_test.dart         # ChatNotifier prompt building, state transitions
├── embedding_test.dart    # EmbeddingService init + cosine similarity
├── rag_test.dart          # Document ingestion + HNSW retrieval
├── download_test.dart     # DownloadService progress / cancel
├── settings_test.dart     # SettingsNotifier defaults + mutations
├── onboarding_test.dart   # Onboarding flag read/write
└── polish_test.dart       # Recommendation badges, RAM guard dialog
```

---

## 5. Data Model

```mermaid
erDiagram
    MODEL {
        string id PK
        string name
        string sizeLabel
        int sizeBytes
        string status
        double downloadProgress
        string localPath
        string huggingFaceRepo
        string filename
        string format
    }

    CONVERSATION {
        string id PK
        string title
        string systemPrompt
        bool ragEnabled
        int createdAtMs
        int updatedAtMs
    }

    MESSAGE {
        string id PK
        string conversationId FK
        string role
        string content
        int createdAtMs
    }

    DOCUMENT {
        string id PK
        string name
        string format
        int chunkCount
        int createdAtMs
    }

    DOCUMENT_CHUNK {
        string chunkId PK
        string documentId FK
        string content
        int chunkIndex
        int createdAtMs
        List~double~ embedding
    }

    CONVERSATION ||--o{ MESSAGE : "has"
    DOCUMENT ||--o{ DOCUMENT_CHUNK : "split into"
```

---

## 6. Model Lifecycle

```mermaid
stateDiagram-v2
    [*] --> available : seeded from kCuratedModels

    available --> downloading : downloadModel()
    downloading --> available : cancelDownload()
    downloading --> downloaded : download complete
    downloading --> error : network failure

    downloaded --> loading : loadModel() + RAM confirmed
    loading --> loaded : backend.loadModel() success
    loading --> error : backend throws

    loaded --> downloaded : unloadModel()

    error --> downloading : retry (downloadModel)
    error --> loading : retry (loadModel)
```

---

## 7. Inference Backend Selection

```mermaid
flowchart LR
    MODEL["Model.format"]
    TASK{"format == 'task'?"}
    MEDIA["MediaPipeBackend\n(flutter_gemma)\n.task files — Gemma"]
    LLAMA["LlamaCppBackend\n(flutter_llama)\n.gguf files — any GGUF"]

    MODEL --> TASK
    TASK -- yes --> MEDIA
    TASK -- no --> LLAMA
```

---

## 8. Chat & RAG Message Flow

```mermaid
sequenceDiagram
    actor User
    participant CS as ConversationScreen
    participant CN as ChatNotifier
    participant IN as InferenceNotifier
    participant ES as EmbeddingService
    participant CR as DocumentChunkRepository
    participant IB as InferenceBackend

    User->>CS: types message, taps Send
    CS->>CN: send(userText)
    CN->>CN: persist userMsg to ObjectBox
    CN->>CN: auto-title conversation (first message)
    CN->>CS: state = streaming (streamingText = "")

    alt conversation.ragEnabled && embeddingService.isInitialized
        CN->>ES: embedQuery(userText)
        ES-->>CN: queryVector [384-dim]
        CN->>CR: findSimilar(queryVector, topK)
        CR-->>CN: List<DocumentChunk>
    end

    CN->>CN: _buildPrompt(history, systemPrompt, ragChunks)
    CN->>IN: ref.read(inferenceNotifierProvider)
    IN-->>CN: InferenceBackend
    CN->>IB: backend.generate(prompt)

    loop each token
        IB-->>CN: token string
        CN->>CS: state = streaming (appended token)
    end

    IB-->>CN: onDone
    CN->>CN: persist assistantMsg to ObjectBox
    CN->>CS: state = idle (clearStreaming)
```

---

## 9. Document Ingestion Pipeline

```mermaid
flowchart TD
    FP["FilePicker.pickFiles\n(pdf / docx / txt)"]
    GUARD{"file size\n> 10 MB?"}
    ERR["AsyncError:\n'File too large'"]
    EXTRACT["TextExtractionService\n.extractText()"]
    SPLIT["RecursiveCharacterTextSplitter\nchunkSize (from settings)\noverlap = 50"]
    SAVE_DOC["DocumentRepository.save(doc)"]
    EMBED_LOOP["for each chunk:\nEmbeddingService.embedPassage()"]
    SAVE_CHUNKS["DocumentChunkRepository.saveChunks()\n(HNSW indexed)"]
    DONE["ref.invalidateSelf()\n→ UI refreshes"]

    FP --> GUARD
    GUARD -- yes --> ERR
    GUARD -- no --> EXTRACT
    EXTRACT --> SPLIT
    SPLIT --> SAVE_DOC
    SAVE_DOC --> EMBED_LOOP
    EMBED_LOOP --> SAVE_CHUNKS
    SAVE_CHUNKS --> DONE
```

---

## 10. Navigation & Routing

```mermaid
graph LR
    ROOT["GoRouter\ninitialLocation"]
    OB["/onboarding\nOnboardingScreen"]
    SET["/settings\nSettingsScreen"]
    SHELL["StatefulShellRoute\n(BottomNav)"]
    MOD["/models\nModelsScreen"]
    CHAT["/chat\nChatScreen"]
    CONV["/chat/:conversationId\nConversationScreen"]
    DOCS["/documents\nDocumentsScreen"]

    ROOT -- "onboarding_complete=false" --> OB
    ROOT -- "onboarding_complete=true" --> SHELL
    OB -- "Get Started" --> MOD
    MOD -- "settings icon" --> SET
    SHELL --> MOD
    SHELL --> CHAT
    SHELL --> DOCS
    CHAT --> CONV
```

---

## 11. Provider Dependency Graph

```mermaid
graph TD
    SPREFS["sharedPreferencesProvider\n(ProviderScope override)"]
    OBX["objectBoxStoreProvider\n(ProviderScope override)"]

    ROUTER["appRouterProvider"]
    SETTINGS["settingsNotifierProvider"]

    MODEL_REPO["modelRepositoryProvider"]
    CONV_REPO["conversationRepositoryProvider"]
    MSG_REPO["messageRepositoryProvider"]
    DOC_REPO["documentRepositoryProvider"]
    CHUNK_REPO["documentChunkRepositoryProvider"]

    DIO["dioProvider"]
    FS["fileStorageServiceProvider"]
    DL["downloadServiceProvider"]
    INF["inferenceNotifierProvider"]
    EMB["embeddingServiceProvider"]

    MODELS_N["modelsNotifierProvider"]
    CHAT_N["chatNotifierProvider\n(family: conversationId)"]
    CONV_LIST["conversationListNotifierProvider"]
    DOCS_N["documentsNotifierProvider"]

    SPREFS --> ROUTER
    SPREFS --> SETTINGS
    OBX --> MODEL_REPO
    OBX --> CONV_REPO
    OBX --> MSG_REPO
    OBX --> DOC_REPO
    OBX --> CHUNK_REPO

    DIO --> DL
    FS --> DL
    DL --> MODELS_N
    MODEL_REPO --> MODELS_N
    INF --> MODELS_N
    MODEL_REPO --> INF

    CONV_REPO --> CHAT_N
    MSG_REPO --> CHAT_N
    INF --> CHAT_N
    EMB --> CHAT_N
    CHUNK_REPO --> CHAT_N
    SETTINGS --> CHAT_N

    CONV_REPO --> CONV_LIST

    DOC_REPO --> DOCS_N
    CHUNK_REPO --> DOCS_N
    EMB --> DOCS_N
    SETTINGS --> DOCS_N
```

---

## 12. Testing

| Test File | What It Covers | Notes |
|---|---|---|
| `widget_test.dart` | App smoke test — renders without crash | Stubs ObjectBox + prefs |
| `engine_test.dart` | `InferenceBackend` abstract contract; `backendForModel()` routing | Pure Dart — no native plugins needed |
| `domain_test.dart` | `Model`, `Message`, `Conversation` freezed constructors, computed getters, `copyWith` | Pure Dart |
| `chat_test.dart` | `_buildPrompt` output, streaming state transitions, auto-title logic | Mocks inference backend |
| `embedding_test.dart` | `EmbeddingService` init, `embedQuery` vs `embedPassage` prefix, cosine similarity | Requires ONNX asset in test runner |
| `rag_test.dart` | Full document ingestion pipeline, `findSimilar` returns top-k nearest chunks | Uses ObjectBox in-memory config |
| `download_test.dart` | `DownloadService` progress callbacks, cancel token, file write | Mocks Dio |
| `settings_test.dart` | `SettingsNotifier` defaults, `setChunkSize`, `setTopK` persist correctly | Mocks SharedPreferences |
| `onboarding_test.dart` | `onboarding_complete` flag read on cold start, written after `_finish()` | Mocks SharedPreferences |
| `polish_test.dart` | `recommendationBadge` values, RAM guard dialog threshold | Widget test for dialog |

**Run all tests:**
```bash
flutter test
```

**Run a single file:**
```bash
flutter test test/engine_test.dart
```

**Notes on native stubs:**
- ObjectBox and flutter_llama/flutter_gemma use native code unavailable in the Flutter test host. Tests that exercise these code paths use in-memory ObjectBox configurations or mock the repository/backend abstractions via dependency injection through Riverpod `ProviderScope` overrides.

---

## 13. Build & Run

```bash
# Install dependencies
flutter pub get

# Regenerate code (after model/provider changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>

# Static analysis
flutter analyze

# Run tests
flutter test

# Build
flutter build apk           # Android
flutter build ios           # iOS
```
